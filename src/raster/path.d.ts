export interface Path {
	verbs: number[];
	coords: number[];
}

declare const path: {
	MOVE: 0;
	LINE: 1;
	QUAD: 2;
	CUBIC: 3;
	CLOSE: 4;
	new: () => Path;
	moveTo: (p: Path, x: number, y: number) => void;
	lineTo: (p: Path, x: number, y: number) => void;
	quadTo: (p: Path, controlX: number, controlY: number, x: number, y: number) => void;
	cubicTo: (p: Path, x1: number, y1: number, x2: number, y2: number, x: number, y: number) => void;
	close: (p: Path) => void;
	append: (target: Path, source: Path, a: number, b: number, c: number, d: number, e: number, f: number) => void;
};

export = path;
