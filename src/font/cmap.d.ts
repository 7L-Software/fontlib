import type { Directory } from "./directory";

declare const cmap: {
	read: (data: buffer, tables: Directory) => (codepoint: number) => number;
};

export = cmap;
