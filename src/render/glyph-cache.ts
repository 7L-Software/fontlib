import type { Face } from "../font/face";
import blit from "../raster/blit";
import fill from "../raster/fill";
import flatten from "../raster/flatten";
import type { FontFace } from "../registry/fonts";

export interface GlyphBitmap {
	width: number;
	height: number;
	left: number;
	top: number;
	coverage: buffer;
}

export interface ColorBitmap {
	width: number;
	height: number;
	left: number;
	top: number;
	rgba: buffer;
}

interface Entry {
	bitmap: GlyphBitmap | ColorBitmap;
	lastUsed: number;
	bytes: number;
}

const empty: GlyphBitmap = { width: 0, height: 0, left: 0, top: 0, coverage: buffer.create(0) };
const tolerance = 0.2;
const foreground = 0xffff;

function key(font: FontFace, glyph: number, scale: number) {
	return `${font.id}:${glyph}:${math.round(scale * 4096)}`;
}

function colorKey(font: FontFace, glyph: number, scale: number) {
	return `c:${key(font, glyph, scale)}`;
}

function rasterize(face: Face, glyph: number, scale: number): GlyphBitmap {
	const outline = face.outline(glyph);
	if (!outline) {
		return empty;
	}
	const polylines = flatten.polylines(outline, scale, 0, 0, -scale, tolerance);
	if (polylines.isEmpty()) {
		return empty;
	}
	const [minX, minY, maxX, maxY] = flatten.bounds(polylines);
	const left = math.floor(minX) - 1;
	const top = math.floor(minY) - 1;
	const width = math.ceil(maxX) + 1 - left;
	const height = math.ceil(maxY) + 1 - top;
	return { width, height, left, top, coverage: fill.coverage(polylines, -left, -top, width, height) };
}

class GlyphCache {
	private entries = new Map<string, Entry>();
	private bytes = 0;
	private tick = 0;

	constructor(private readonly budget: number) {}

	has(font: FontFace, glyph: number, scale: number) {
		return this.entries.has(key(font, glyph, scale));
	}

	hasColor(font: FontFace, glyph: number, scale: number) {
		return this.entries.has(colorKey(font, glyph, scale));
	}

	get(font: FontFace, glyph: number, scale: number): GlyphBitmap {
		const existing = this.touch(key(font, glyph, scale));
		if (existing) {
			return existing as GlyphBitmap;
		}
		const bitmap = rasterize(font.face, glyph, scale);
		this.store(key(font, glyph, scale), bitmap, bitmap.width * bitmap.height);
		return bitmap;
	}

	getColor(font: FontFace, glyph: number, scale: number): ColorBitmap | undefined {
		const layers = font.face.colorLayers(glyph);
		if (!layers) {
			return undefined;
		}
		const existing = this.touch(colorKey(font, glyph, scale));
		if (existing) {
			return existing as ColorBitmap;
		}

		const parts = layers.map((layer) => ({ layer, bitmap: this.get(font, layer.glyph, scale) }));
		let left = math.huge;
		let top = math.huge;
		let right = -math.huge;
		let bottom = -math.huge;
		for (const { bitmap } of parts) {
			if (bitmap.width === 0) {
				continue;
			}
			left = math.min(left, bitmap.left);
			top = math.min(top, bitmap.top);
			right = math.max(right, bitmap.left + bitmap.width);
			bottom = math.max(bottom, bitmap.top + bitmap.height);
		}
		if (left === math.huge) {
			return undefined;
		}

		const width = right - left;
		const height = bottom - top;
		const rgba = buffer.create(width * height * 4);
		for (const { layer, bitmap } of parts) {
			if (bitmap.width === 0) {
				continue;
			}
			const [red, green, blue, alpha] =
				layer.palette === foreground ? [255, 255, 255, 255] : font.face.palette(layer.palette);
			blit.color(
				rgba,
				width,
				height,
				bitmap.coverage,
				bitmap.width,
				bitmap.height,
				bitmap.left - left,
				bitmap.top - top,
				red,
				green,
				blue,
				alpha,
			);
		}
		const bitmap: ColorBitmap = { width, height, left, top, rgba };
		this.store(colorKey(font, glyph, scale), bitmap, width * height * 4);
		return bitmap;
	}

	clear() {
		this.entries.clear();
		this.bytes = 0;
	}

	private touch(key: string) {
		this.tick += 1;
		const entry = this.entries.get(key);
		if (entry) {
			entry.lastUsed = this.tick;
			return entry.bitmap;
		}
		return undefined;
	}

	private store(key: string, bitmap: GlyphBitmap | ColorBitmap, pixelBytes: number) {
		const bytes = pixelBytes + 64;
		this.entries.set(key, { bitmap, lastUsed: this.tick, bytes });
		this.bytes += bytes;
		if (this.bytes > this.budget) {
			this.evict();
		}
	}

	private evict() {
		const ordered = [...this.entries];
		ordered.sort((a, b) => a[1].lastUsed < b[1].lastUsed);
		const target = this.budget * 0.75;
		for (const [key, entry] of ordered) {
			if (this.bytes <= target) {
				break;
			}
			this.entries.delete(key);
			this.bytes -= entry.bytes;
		}
	}
}

export const glyphCache = new GlyphCache(16 * 1024 * 1024);
