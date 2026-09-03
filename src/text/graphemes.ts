export function codepointsInGraphemes(text: string, count: number) {
	let codepoints = 0;
	let seen = 0;
	const [valid] = pcall(() => {
		for (const [start, finish] of utf8.graphemes(text)) {
			if (seen >= count) {
				break;
			}
			const [length] = utf8.len(text.sub(start, finish));
			codepoints += typeIs(length, "number") ? length : 0;
			seen += 1;
		}
	});
	return valid ? codepoints : count;
}
