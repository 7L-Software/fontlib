import type { Directory } from "./directory";

declare const names: {
	read: (data: buffer, tables: Directory) => Map<number, string>;
};

export = names;
