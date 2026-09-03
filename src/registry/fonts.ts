import face from "../font/face";
import type { Face } from "../font/face";
import { FontWeight, weightFromName, weightValue } from "./weight";

export interface FontFace {
	readonly id: number;
	readonly family: string;
	readonly weight: number;
	readonly italic: boolean;
	readonly face: Face;
}

export interface FontOverrides {
	family?: string;
	weight?: FontWeight;
	italic?: boolean;
}

const faces: FontFace[] = [];
const listeners = new Set<() => void>();

function familyKey(name: string) {
	return name.lower().gsub("[%s_%-]", "")[0];
}

function detectWeight(parsed: Face) {
	if (parsed.weightClass >= 1 && parsed.weightClass <= 1000) {
		return parsed.weightClass;
	}
	return weightFromName(parsed.subfamily) ?? 400;
}

function detectItalic(parsed: Face) {
	const style = parsed.subfamily.lower();
	return (
		parsed.italic ||
		style.find("italic", 1, true)[0] !== undefined ||
		style.find("oblique", 1, true)[0] !== undefined
	);
}

export function registerFont(data: buffer, overrides: FontOverrides = {}): FontFace {
	const parsed = face.parse(data);
	const entry: FontFace = {
		id: faces.size() + 1,
		family: overrides.family ?? parsed.family,
		weight: overrides.weight !== undefined ? weightValue(overrides.weight) : detectWeight(parsed),
		italic: overrides.italic ?? detectItalic(parsed),
		face: parsed,
	};
	faces.push(entry);
	for (const listener of listeners) {
		listener();
	}
	return entry;
}

export function resolveFont(family: string, weight: FontWeight = 400, italic = false): FontFace | undefined {
	const wanted = familyKey(family);
	const target = weightValue(weight);
	let best: FontFace | undefined;
	let bestScore = math.huge;
	for (const candidate of faces) {
		if (familyKey(candidate.family) !== wanted) {
			continue;
		}
		const score = (candidate.italic === italic ? 0 : 10000) + math.abs(candidate.weight - target);
		const preferred =
			best !== undefined &&
			score === bestScore &&
			(target > 500 ? candidate.weight > best.weight : candidate.weight < best.weight);
		if (best === undefined || score < bestScore || preferred) {
			best = candidate;
			bestScore = score;
		}
	}
	return best;
}

export function fontFamilies(): string[] {
	const seen = new Set<string>();
	const families: string[] = [];
	for (const candidate of faces) {
		const key = familyKey(candidate.family);
		if (!seen.has(key)) {
			seen.add(key);
			families.push(candidate.family);
		}
	}
	return families;
}

export function onFontsChanged(listener: () => void) {
	listeners.add(listener);
	return () => {
		listeners.delete(listener);
	};
}
