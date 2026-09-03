import type { Directory } from "./directory";

declare const gpos: {
	read: (data: buffer, tables: Directory) => ((left: number, right: number) => number | undefined) | undefined;
};

export = gpos;
