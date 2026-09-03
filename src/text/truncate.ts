import type { FontFace } from "../registry/fonts";
import { LayoutLine, TextLayout } from "./layout";
import { isSpace } from "./line-break";
import { ShapedGlyph } from "./shape";

interface Ellipsis {
	glyphs: ShapedGlyph[];
	width: number;
}

function ellipsisFor(font: FontFace, emSize: number): Ellipsis {
	const face = font.face;
	const scale = emSize / face.unitsPerEm;
	const glyphs: ShapedGlyph[] = [];
	const codepoints = face.glyphIndex(0x2026) !== 0 ? [0x2026] : [0x2e, 0x2e, 0x2e];
	let x = 0;
	for (const codepoint of codepoints) {
		const glyph = face.glyphIndex(codepoint);
		const advance = face.advance(glyph) * scale;
		glyphs.push({ glyph, codepoint, x, advance, font, colored: false });
		x += advance;
	}
	return { glyphs, width: x };
}

function ellipsize(line: LayoutLine, ellipsis: Ellipsis, maxWidth: number): LayoutLine {
	const glyphs = [...line.glyphs];
	while (glyphs.size() > 0) {
		const last = glyphs[glyphs.size() - 1];
		if (!isSpace(last.codepoint) && last.x + last.advance + ellipsis.width <= maxWidth) {
			break;
		}
		glyphs.pop();
	}
	const tail = glyphs[glyphs.size() - 1];
	const origin = tail ? tail.x + tail.advance : 0;
	for (const glyph of ellipsis.glyphs) {
		glyphs.push({ ...glyph, x: origin + glyph.x });
	}
	return { glyphs, width: origin + ellipsis.width };
}

export function truncateLayout(layout: TextLayout, maxWidth: number, maxHeight: number): TextLayout {
	const maxLines = math.max(1, math.floor(maxHeight / layout.lineHeight + 0.001));
	const dropped = layout.lines.size() > maxLines;
	const lines = dropped ? layout.lines.move(0, maxLines - 1, 0, []) : [...layout.lines];
	const lastIndex = lines.size() - 1;
	if (!dropped && lines[lastIndex].width <= maxWidth) {
		return layout;
	}

	lines[lastIndex] = ellipsize(lines[lastIndex], ellipsisFor(layout.font, layout.emSize), maxWidth);
	let width = 0;
	for (const line of lines) {
		width = math.max(width, line.width);
	}
	return { ...layout, lines, width, height: lines.size() * layout.lineHeight };
}
