import type { Path } from "./path";

declare const flatten: {
	polylines: (p: Path, a: number, b: number, c: number, d: number, tolerance: number) => number[][];
	bounds: (polylines: number[][]) => LuaTuple<[number, number, number, number]>;
};

export = flatten;
