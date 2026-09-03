import blit from "../raster/blit";
import type { ColorBitmap, GlyphBitmap } from "./glyph-cache";

export class Canvas {
	private readonly alpha: buffer;
	private readonly rgba: buffer;
	private color?: buffer;

	constructor(
		readonly width: number,
		readonly height: number,
	) {
		this.alpha = buffer.create(width * height);
		this.rgba = buffer.create(width * height * 4);
		buffer.fill(this.rgba, 0, 255);
	}

	clear() {
		buffer.fill(this.alpha, 0, 0);
		if (this.color) {
			buffer.fill(this.color, 0, 0);
		}
	}

	draw(bitmap: GlyphBitmap, x: number, y: number) {
		if (bitmap.width === 0) {
			return;
		}
		blit.coverage(this.alpha, this.width, this.height, bitmap.coverage, bitmap.width, bitmap.height, x, y);
	}

	drawColor(bitmap: ColorBitmap, x: number, y: number) {
		if (!this.color) {
			this.color = buffer.create(this.width * this.height * 4);
		}
		blit.image(this.color, this.width, this.height, bitmap.rgba, bitmap.width, bitmap.height, x, y);
	}

	hasColor() {
		return this.color !== undefined;
	}

	flush(image: EditableImage) {
		blit.alpha(this.alpha, this.rgba, this.width * this.height);
		image.WritePixelsBuffer(Vector2.zero, new Vector2(this.width, this.height), this.rgba);
	}

	flushColor(image: EditableImage) {
		if (this.color) {
			image.WritePixelsBuffer(Vector2.zero, new Vector2(this.width, this.height), this.color);
		}
	}
}
