import type { Directory } from "./directory";

declare const kern: {
	read: (data: buffer, tables: Directory) => Map<number, number> | undefined;
};

export = kern;
