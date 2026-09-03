import React from "@rbxts/react";
import type { FontFace } from "../registry/fonts";
import type { FontWeight } from "../registry/weight";
import type { SizeMode } from "../text/layout";
import type { WordBreak } from "../text/line-break";

export interface TextDefaults {
	font?: string | FontFace;
	fallbackFonts?: Array<string | FontFace>;
	textSize: number;
	textColor: Color3;
	sizeMode: SizeMode;
	wordBreak: WordBreak;
	lineHeight: number;
	resolution: number;
}

export interface TextProps {
	text: string;
	font?: string | FontFace;
	fallbackFonts?: Array<string | FontFace>;
	fontWeight?: FontWeight;
	fontStyle?: Enum.FontStyle;
	textSize?: number;
	sizeMode?: SizeMode;
	resolution?: number;
	textColor?: Color3;
	textTransparency?: number;
	textXAlignment?: Enum.TextXAlignment;
	textYAlignment?: Enum.TextYAlignment;
	textWrapped?: boolean;
	textTruncate?: Enum.TextTruncate;
	lineHeight?: number;
	letterSpacing?: number;
	wordBreak?: WordBreak;
	maxVisibleGraphemes?: number;
	automaticSize?: Enum.AutomaticSize;
	size?: UDim2;
	position?: UDim2;
	anchorPoint?: Vector2;
	layoutOrder?: number;
	zIndex?: number;
	visible?: boolean;
	backgroundColor?: Color3;
	backgroundTransparency?: number;
	onBounds?: (bounds: Vector2) => void;
	children?: React.ReactNode;
}

export interface FontProviderProps {
	defaults?: Partial<TextDefaults>;
	children?: React.ReactNode;
}
