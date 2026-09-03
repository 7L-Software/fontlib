import type { FontFace } from "../registry/fonts";

export interface ShapedGlyph {
	glyph: number;
	codepoint: number;
	x: number;
	advance: number;
	font: FontFace;
	colored: boolean;
}

interface Mapped {
	font: FontFace;
	glyph: number;
	codepoint: number;
}

const space = 0x20;
const tab = 0x09;

function isInvisible(codepoint: number) {
	return (
		codepoint === 0x200b ||
		codepoint === 0x200c ||
		codepoint === 0x200d ||
		codepoint === 0xfe0e ||
		codepoint === 0xfe0f
	);
}

function pick(codepoint: number, fonts: FontFace[], previous: FontFace | undefined): Mapped | undefined {
	const lookup = codepoint === tab ? space : codepoint;
	if (isInvisible(codepoint)) {
		const glyph = previous ? previous.face.glyphIndex(lookup) : 0;
		return previous && glyph !== 0 ? { font: previous, glyph, codepoint } : undefined;
	}
	for (const font of fonts) {
		const glyph = font.face.glyphIndex(lookup);
		if (glyph !== 0) {
			return { font, glyph, codepoint };
		}
	}
	return { font: fonts[0], glyph: 0, codepoint };
}

function advanceOf(font: FontFace, glyph: number, codepoint: number, scale: number) {
	let advance = font.face.advance(glyph) * scale;
	if (glyph === 0 && (codepoint === space || codepoint === tab)) {
		advance = font.face.unitsPerEm * 0.25 * scale;
	}
	if (codepoint === tab) {
		advance *= 4;
	}
	return advance;
}

export function shape(codepoints: number[], fonts: FontFace[], emSize: number, letterSpacing: number): ShapedGlyph[] {
	const mapped: Mapped[] = [];
	let previous: FontFace | undefined;
	for (const codepoint of codepoints) {
		const entry = pick(codepoint, fonts, previous);
		if (entry) {
			mapped.push(entry);
			previous = entry.font;
		}
	}

	const glyphs: ShapedGlyph[] = [];
	let x = 0;
	let last: ShapedGlyph | undefined;
	let start = 0;
	while (start < mapped.size()) {
		const font = mapped[start].font;
		const ids: number[] = [];
		let stop = start;
		while (stop < mapped.size() && mapped[stop].font === font) {
			ids.push(mapped[stop].glyph);
			stop++;
		}

		const [substituted, sizes] = font.face.ligate(ids);
		const scale = emSize / font.face.unitsPerEm;
		let source = start;
		substituted.forEach((glyph, index) => {
			const codepoint = mapped[source].codepoint;
			source += sizes[index];
			if (last) {
				x += letterSpacing;
				if (last.font === font) {
					x += font.face.kerning(last.glyph, glyph) * scale;
				}
			}
			const shaped: ShapedGlyph = {
				glyph,
				codepoint,
				x,
				advance: advanceOf(font, glyph, codepoint, scale),
				font,
				colored: font.face.colorLayers(glyph) !== undefined,
			};
			glyphs.push(shaped);
			x += shaped.advance;
			last = shaped;
		});
		start = stop;
	}
	return glyphs;
}
