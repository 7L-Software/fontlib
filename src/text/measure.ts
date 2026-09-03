import type { FontFace } from "../registry/fonts";
import { layoutText, SizeMode } from "./layout";
import type { WordBreak } from "./line-break";

export interface MeasureOptions {
	font: FontFace;
	fallbacks?: FontFace[];
	textSize: number;
	sizeMode?: SizeMode;
	lineHeight?: number;
	letterSpacing?: number;
	wrapWidth?: number;
	wordBreak?: WordBreak;
}

export function measureText(text: string, options: MeasureOptions) {
	const layout = layoutText(text, options);
	return new Vector2(layout.width, layout.height);
}
