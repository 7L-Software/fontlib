import type { Directory } from "./directory";
import type { Path } from "../raster/path";

declare const glyf: {
	read: (
		data: buffer,
		tables: Directory,
		longLoca: boolean,
		glyphCount: number,
	) => (glyph: number) => Path | undefined;
};

export = glyf;
