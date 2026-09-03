import type { Directory } from "./directory";

export interface ColorLayer {
	glyph: number;
	palette: number;
}

declare const colr: {
	read: (data: buffer, tables: Directory) => ((glyph: number) => ColorLayer[] | undefined) | undefined;
};

export = colr;
