import { useEffect, useState } from "@rbxts/react";
import { FontFace, fontFamilies, onFontsChanged, resolveFont } from "../registry/fonts";
import type { FontWeight } from "../registry/weight";

function useRegistry() {
	const [, setVersion] = useState(0);
	useEffect(() => onFontsChanged(() => setVersion((version) => version + 1)), []);
}

function resolve(font: string | FontFace, weight: FontWeight, italic: boolean) {
	return typeIs(font, "string") ? resolveFont(font, weight, italic) : font;
}

export function useFont(font?: string | FontFace, weight: FontWeight = 400, italic = false): FontFace | undefined {
	useRegistry();
	const family = font ?? fontFamilies()[0];
	return family !== undefined ? resolve(family, weight, italic) : undefined;
}

export function useFallbackFonts(
	fonts: Array<string | FontFace> | undefined,
	weight: FontWeight = 400,
	italic = false,
): FontFace[] {
	useRegistry();
	const resolved: FontFace[] = [];
	for (const font of fonts ?? []) {
		const face = resolve(font, weight, italic);
		if (face) {
			resolved.push(face);
		}
	}
	return resolved;
}
