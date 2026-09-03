import type { Directory } from "./directory";

declare const hmtx: {
	read: (data: buffer, tables: Directory, hMetricCount: number, glyphCount: number) => buffer;
};

export = hmtx;
