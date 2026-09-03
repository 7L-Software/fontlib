import type { FontFace } from "../registry/fonts";
import { codepointsOf } from "./codepoints";
import { canBreakBefore, isSpace, WordBreak } from "./line-break";
import { shape, ShapedGlyph } from "./shape";

export type SizeMode = "line" | "em";

export interface LayoutOptions {
	font: FontFace;
	fallbacks?: FontFace[];
	textSize: number;
	sizeMode?: SizeMode;
	lineHeight?: number;
	letterSpacing?: number;
	wrapWidth?: number;
	wordBreak?: WordBreak;
	maxCodepoints?: number;
}

export interface LayoutLine {
	glyphs: ShapedGlyph[];
	width: number;
}

export interface TextLayout {
	lines: LayoutLine[];
	width: number;
	height: number;
	font: FontFace;
	emSize: number;
	ascent: number;
	lineHeight: number;
}

export function emSizeOf(font: FontFace, textSize: number, sizeMode: SizeMode) {
	const face = font.face;
	if (sizeMode === "em") {
		return textSize;
	}
	return (textSize * face.unitsPerEm) / (face.ascender - face.descender);
}

export function glyphScale(layout: TextLayout, glyph: ShapedGlyph) {
	return layout.emSize / glyph.font.face.unitsPerEm;
}

function makeLine(glyphs: ShapedGlyph[], start: number, stop: number): LayoutLine {
	const line: ShapedGlyph[] = [];
	const origin = start < stop ? glyphs[start].x : 0;
	let width = 0;
	for (let index = start; index < stop; index++) {
		const source = glyphs[index];
		const x = source.x - origin;
		line.push({ ...source, x });
		if (!isSpace(source.codepoint)) {
			width = math.max(width, x + source.advance);
		}
	}
	return { glyphs: line, width };
}

function breakLines(glyphs: ShapedGlyph[], maxWidth: number, mode: WordBreak, lines: LayoutLine[]) {
	let start = 0;
	let lastBreak = -1;
	let index = 0;
	while (index < glyphs.size()) {
		const glyph = glyphs[index];
		if (index > start && canBreakBefore(glyphs[index - 1].codepoint, glyph.codepoint, mode)) {
			lastBreak = index;
		}
		const right = glyph.x + glyph.advance - glyphs[start].x;
		if (right > maxWidth && index > start && !isSpace(glyph.codepoint)) {
			const at = lastBreak > start ? lastBreak : index;
			lines.push(makeLine(glyphs, start, at));
			start = at;
			lastBreak = -1;
			index = at;
			continue;
		}
		index++;
	}
	lines.push(makeLine(glyphs, start, glyphs.size()));
}

export function layoutText(text: string, options: LayoutOptions): TextLayout {
	const face = options.font.face;
	const emSize = emSizeOf(options.font, options.textSize, options.sizeMode ?? "line");
	const scale = emSize / face.unitsPerEm;
	const lineHeight = (face.ascender - face.descender) * scale * (options.lineHeight ?? 1);
	const fonts = [options.font, ...(options.fallbacks ?? [])];
	const lines: LayoutLine[] = [];
	let remaining = options.maxCodepoints ?? math.huge;

	for (const paragraph of text.split("\n")) {
		const codepoints = codepointsOf(paragraph, remaining);
		remaining -= codepoints.size();
		const glyphs = shape(codepoints, fonts, emSize, options.letterSpacing ?? 0);
		if (options.wrapWidth === undefined) {
			lines.push(makeLine(glyphs, 0, glyphs.size()));
		} else {
			breakLines(glyphs, options.wrapWidth, options.wordBreak ?? "normal", lines);
		}
		if (remaining <= 0) {
			break;
		}
	}

	let width = 0;
	for (const line of lines) {
		width = math.max(width, line.width);
	}
	return {
		lines,
		width,
		height: lines.size() * lineHeight,
		font: options.font,
		emSize,
		ascent: face.ascender * scale,
		lineHeight,
	};
}
