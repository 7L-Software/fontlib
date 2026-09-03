import type { ColorLayer } from "./colr";
import type { Path } from "../raster/path";

export interface Face {
	readonly unitsPerEm: number;
	readonly ascender: number;
	readonly descender: number;
	readonly lineGap: number;
	readonly capHeight: number;
	readonly xHeight: number;
	readonly glyphCount: number;
	readonly weightClass: number;
	readonly italic: boolean;
	readonly family: string;
	readonly subfamily: string;
	readonly fullName: string;
	readonly postScriptName: string;
	readonly glyphIndex: (codepoint: number) => number;
	readonly advance: (glyph: number) => number;
	readonly kerning: (left: number, right: number) => number;
	readonly outline: (glyph: number) => Path | undefined;
	readonly hasColor: boolean;
	readonly colorLayers: (glyph: number) => ColorLayer[] | undefined;
	readonly palette: (index: number) => LuaTuple<[number, number, number, number]>;
	readonly ligate: (glyphs: number[]) => LuaTuple<[number[], number[]]>;
}

declare const face: {
	parse: (data: buffer) => Face;
};

export = face;
