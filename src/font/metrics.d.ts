import type { Directory } from "./directory";

export interface Metrics {
	unitsPerEm: number;
	ascender: number;
	descender: number;
	lineGap: number;
	capHeight: number;
	xHeight: number;
	glyphCount: number;
	hMetricCount: number;
	longLoca: boolean;
	weightClass: number;
	italic: boolean;
}

declare const metrics: {
	read: (data: buffer, tables: Directory) => Metrics;
};

export = metrics;
