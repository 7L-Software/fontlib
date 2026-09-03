const replacement = 0xfffd;
const carriageReturn = 0x0d;

function decodeLossy(text: string, limit: number) {
	const codepoints: number[] = [];
	for (let index = 1; index <= text.size() && codepoints.size() < limit; index++) {
		const [byte] = text.byte(index);
		if (byte < 0x80) {
			if (byte !== carriageReturn) {
				codepoints.push(byte);
			}
		} else if ((byte & 0xc0) !== 0x80) {
			codepoints.push(replacement);
		}
	}
	return codepoints;
}

export function codepointsOf(text: string, limit: number): number[] {
	const codepoints: number[] = [];
	const [valid] = pcall(() => {
		for (const [, codepoint] of utf8.codes(text)) {
			if (codepoints.size() >= limit) {
				break;
			}
			if (codepoint !== carriageReturn) {
				codepoints.push(codepoint);
			}
		}
	});
	return valid ? codepoints : decodeLossy(text, limit);
}
