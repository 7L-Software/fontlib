import type { Directory } from "./directory";

declare const gsub: {
	read: (data: buffer, tables: Directory) => ((glyphs: number[]) => LuaTuple<[number[], number[]]>) | undefined;
};

export = gsub;
