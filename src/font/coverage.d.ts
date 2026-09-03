export interface Coverage {
	format: number;
	glyphs: number[];
	firsts: number[];
	lasts: number[];
	indices: number[];
}

declare const coverage: {
	read: (data: buffer, offset: number) => Coverage | undefined;
	glyphAt: (set: Coverage, index: number) => number | undefined;
	indexOf: (set: Coverage, glyph: number) => number | undefined;
};

export = coverage;
