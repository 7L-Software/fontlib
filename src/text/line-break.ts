export type WordBreak = "normal" | "keepAll" | "breakAll";

function codepointSet(text: string) {
	const set = new Set<number>();
	for (const [, codepoint] of utf8.codes(text)) {
		set.add(codepoint);
	}
	return set;
}

const closing = codepointSet(".,!?:;)]}」』』〕〉》、。・…'\"’”%");
const opening = codepointSet("([{「『〔〈《‘“");

export function isSpace(codepoint: number) {
	return codepoint === 0x20 || codepoint === 0x09 || codepoint === 0xa0 || codepoint === 0x3000;
}

function isIdeographic(codepoint: number) {
	return (
		(codepoint >= 0x1100 && codepoint <= 0x11ff) ||
		(codepoint >= 0x2e80 && codepoint <= 0x9fff) ||
		(codepoint >= 0xa960 && codepoint <= 0xa97f) ||
		(codepoint >= 0xac00 && codepoint <= 0xd7ff) ||
		(codepoint >= 0xf900 && codepoint <= 0xfaff) ||
		(codepoint >= 0xff00 && codepoint <= 0xffef) ||
		(codepoint >= 0x20000 && codepoint <= 0x3134f)
	);
}

export function canBreakBefore(previous: number, following: number, mode: WordBreak) {
	if (isSpace(following)) {
		return false;
	}
	if (isSpace(previous)) {
		return true;
	}
	if (closing.has(following) || opening.has(previous)) {
		return false;
	}
	if (mode === "breakAll") {
		return true;
	}
	if (mode === "keepAll") {
		return false;
	}
	return isIdeographic(previous) || isIdeographic(following);
}
