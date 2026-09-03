import type { FontFace } from "../registry/fonts";
import { glyphScale, layoutText, SizeMode, TextLayout } from "../text/layout";
import { isSpace, WordBreak } from "../text/line-break";
import { truncateLayout } from "../text/truncate";
import { Canvas } from "./canvas";
import { glyphCache } from "./glyph-cache";
import { dequeue, enqueue, Renderable } from "./scheduler";

export interface RenderProps {
	text: string;
	font?: FontFace;
	fallbacks: FontFace[];
	textSize: number;
	sizeMode: SizeMode;
	resolution: number;
	lineHeight: number;
	letterSpacing: number;
	wordBreak: WordBreak;
	wrapped: boolean;
	truncate: boolean;
	transparency: number;
	xAlignment: Enum.TextXAlignment;
	yAlignment: Enum.TextYAlignment;
	automaticSize: Enum.AutomaticSize;
	maxCodepoints?: number;
}

const AssetService = game.GetService("AssetService");
const maxImageSize = 1024;
const imageStep = 64;
const maxResolution = 2;

let warnedBudget = false;

function createImage(width: number, height: number) {
	const image = AssetService.CreateEditableImage({ Size: new Vector2(width, height) }) as EditableImage | undefined;
	if (!image && !warnedBudget) {
		warnedBudget = true;
		warn("fontlib: EditableImage memory budget exhausted, text will not render");
	}
	return image;
}

function capacity(size: number) {
	return math.min(maxImageSize, math.ceil(size / imageStep) * imageStep);
}

function sameFonts(a: FontFace[], b: FontFace[]) {
	return a.size() === b.size() && a.every((font, index) => font === b[index]);
}

function sameProps(a: RenderProps, b: RenderProps) {
	for (const [key, value] of pairs(a)) {
		if (key !== "fallbacks" && b[key] !== value) {
			return false;
		}
	}
	return sameFonts(a.fallbacks, b.fallbacks);
}

function lineOffset(alignment: Enum.TextXAlignment, available: number, width: number) {
	if (alignment === Enum.TextXAlignment.Center) {
		return (available - width) / 2;
	}
	if (alignment === Enum.TextXAlignment.Right) {
		return available - width;
	}
	return 0;
}

function blockOffset(alignment: Enum.TextYAlignment, available: number, height: number) {
	if (alignment === Enum.TextYAlignment.Center) {
		return (available - height) / 2;
	}
	if (alignment === Enum.TextYAlignment.Bottom) {
		return available - height;
	}
	return 0;
}

export class TextRenderer implements Renderable {
	bounds = Vector2.zero;
	onBounds?: (bounds: Vector2) => void;

	private props?: RenderProps;
	private image?: EditableImage;
	private canvas?: Canvas;
	private overlay?: ImageLabel;
	private colorImage?: EditableImage;
	private readonly connection: RBXScriptConnection;
	private destroyed = false;

	constructor(private readonly label: ImageLabel) {
		this.connection = label.GetPropertyChangedSignal("AbsoluteSize").Connect(() => enqueue(this));
	}

	update(props: RenderProps) {
		if (this.props && sameProps(this.props, props)) {
			return;
		}
		this.props = props;
		enqueue(this);
	}

	renderNow() {
		dequeue(this);
		this.render(() => true);
	}

	destroy() {
		this.destroyed = true;
		dequeue(this);
		this.connection.Disconnect();
		this.label.ImageContent = Content.none;
		this.overlay?.Destroy();
		this.image?.Destroy();
		this.colorImage?.Destroy();
		this.overlay = undefined;
		this.image = undefined;
		this.colorImage = undefined;
		this.canvas = undefined;
	}

	render(hasTime: () => boolean) {
		const props = this.props;
		if (this.destroyed) {
			return true;
		}
		if (!props || !props.font) {
			this.clear();
			return true;
		}

		const fitsWidth = props.automaticSize === Enum.AutomaticSize.X || props.automaticSize === Enum.AutomaticSize.XY;
		const fitsHeight =
			props.automaticSize === Enum.AutomaticSize.Y || props.automaticSize === Enum.AutomaticSize.XY;
		const absolute = this.label.AbsoluteSize;
		const width = math.floor(absolute.X);
		const height = math.floor(absolute.Y);
		const resolution = math.clamp(
			math.min(props.resolution, maxImageSize / math.max(1, width), maxImageSize / math.max(1, height)),
			1,
			maxResolution,
		);

		let layout = layoutText(props.text, {
			font: props.font,
			fallbacks: props.fallbacks,
			textSize: props.textSize * resolution,
			sizeMode: props.sizeMode,
			lineHeight: props.lineHeight,
			letterSpacing: props.letterSpacing * resolution,
			wrapWidth: props.wrapped && !fitsWidth ? width * resolution : undefined,
			wordBreak: props.wordBreak,
			maxCodepoints: props.maxCodepoints,
		});

		const content = new Vector2(math.ceil(layout.width / resolution), math.ceil(layout.height / resolution));
		const canvasWidth = math.min(maxImageSize, math.floor((fitsWidth ? content.X : width) * resolution));
		const canvasHeight = math.min(maxImageSize, math.floor((fitsHeight ? content.Y : height) * resolution));
		if (props.truncate) {
			layout = truncateLayout(layout, fitsWidth ? math.huge : canvasWidth, fitsHeight ? math.huge : canvasHeight);
		}

		this.bounds = content;
		this.onBounds?.(content);
		if (fitsWidth || fitsHeight) {
			this.fit(content, fitsWidth, fitsHeight);
		}
		if (canvasWidth <= 0 || canvasHeight <= 0) {
			this.clear();
			return true;
		}

		const canvas = this.surface(canvasWidth, canvasHeight);
		if (!canvas || !this.image) {
			return true;
		}
		const complete = this.paint(canvas, layout, props, hasTime);
		canvas.flush(this.image);
		this.flushColor(canvas, props.transparency);
		return complete;
	}

	private paint(canvas: Canvas, layout: TextLayout, props: RenderProps, hasTime: () => boolean) {
		let complete = true;
		canvas.clear();
		const top = blockOffset(props.yAlignment, canvas.height, layout.height);
		layout.lines.forEach((line, index) => {
			const baseline = math.round(top + index * layout.lineHeight + layout.ascent);
			const lineX = lineOffset(props.xAlignment, canvas.width, line.width);
			for (const glyph of line.glyphs) {
				if (isSpace(glyph.codepoint)) {
					continue;
				}
				const scale = glyphScale(layout, glyph);
				const x = math.round(lineX + glyph.x);
				if (glyph.colored) {
					if (!glyphCache.hasColor(glyph.font, glyph.glyph, scale) && !hasTime()) {
						complete = false;
						continue;
					}
					const bitmap = glyphCache.getColor(glyph.font, glyph.glyph, scale);
					if (bitmap) {
						canvas.drawColor(bitmap, x + bitmap.left, baseline + bitmap.top);
					}
					continue;
				}
				if (!glyphCache.has(glyph.font, glyph.glyph, scale) && !hasTime()) {
					complete = false;
					continue;
				}
				const bitmap = glyphCache.get(glyph.font, glyph.glyph, scale);
				canvas.draw(bitmap, x + bitmap.left, baseline + bitmap.top);
			}
		});
		return complete;
	}

	private flushColor(canvas: Canvas, transparency: number) {
		if (!canvas.hasColor()) {
			if (this.overlay) {
				this.overlay.Visible = false;
			}
			return;
		}
		const overlay = this.overlay ?? this.createOverlay();
		if (!this.colorImage || this.colorImage.Size.X < canvas.width || this.colorImage.Size.Y < canvas.height) {
			this.colorImage?.Destroy();
			this.colorImage = createImage(capacity(canvas.width), capacity(canvas.height));
			if (!this.colorImage) {
				return;
			}
			overlay.ImageContent = Content.fromObject(this.colorImage);
		}
		overlay.ImageRectSize = new Vector2(canvas.width, canvas.height);
		overlay.ImageTransparency = transparency;
		overlay.Visible = true;
		canvas.flushColor(this.colorImage);
	}

	private createOverlay() {
		const overlay = new Instance("ImageLabel");
		overlay.Name = "ColorGlyphs";
		overlay.BackgroundTransparency = 1;
		overlay.BorderSizePixel = 0;
		overlay.Size = UDim2.fromScale(1, 1);
		overlay.ScaleType = Enum.ScaleType.Stretch;
		overlay.ImageRectOffset = Vector2.zero;
		overlay.Parent = this.label;
		this.overlay = overlay;
		return overlay;
	}

	private fit(content: Vector2, fitsWidth: boolean, fitsHeight: boolean) {
		const current = this.label.Size;
		const resized = new UDim2(
			fitsWidth ? 0 : current.X.Scale,
			fitsWidth ? content.X : current.X.Offset,
			fitsHeight ? 0 : current.Y.Scale,
			fitsHeight ? content.Y : current.Y.Offset,
		);
		if (resized !== current) {
			this.label.Size = resized;
		}
	}

	private surface(width: number, height: number) {
		if (this.canvas && this.canvas.width === width && this.canvas.height === height && this.image) {
			return this.canvas;
		}
		if (!this.image || this.image.Size.X < width || this.image.Size.Y < height) {
			this.image?.Destroy();
			this.image = createImage(capacity(width), capacity(height));
			if (!this.image) {
				return undefined;
			}
			this.label.ImageContent = Content.fromObject(this.image);
		}
		this.canvas = new Canvas(width, height);
		this.label.ImageRectOffset = Vector2.zero;
		this.label.ImageRectSize = new Vector2(width, height);
		return this.canvas;
	}

	private clear() {
		if (this.canvas && this.image) {
			this.canvas.clear();
			this.canvas.flush(this.image);
		}
		if (this.overlay) {
			this.overlay.Visible = false;
		}
		this.bounds = Vector2.zero;
		this.onBounds?.(Vector2.zero);
	}
}
