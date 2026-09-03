import type { Directory } from "./directory";

declare const cpal: {
	read: (data: buffer, tables: Directory) => number[] | undefined;
};

export = cpal;
