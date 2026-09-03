export type WeightName =
	"thin" | "extralight" | "light" | "regular" | "medium" | "semibold" | "bold" | "extrabold" | "black";

export type FontWeight = number | Enum.FontWeight | WeightName;

const aliases: Record<WeightName, number> = {
	thin: 100,
	extralight: 200,
	light: 300,
	regular: 400,
	medium: 500,
	semibold: 600,
	bold: 700,
	extrabold: 800,
	black: 900,
};

const patterns: Array<[string, number]> = [
	["extrablack", 950],
	["ultrablack", 950],
	["extralight", 200],
	["ultralight", 200],
	["extrabold", 800],
	["ultrabold", 800],
	["semibold", 600],
	["demibold", 600],
	["hairline", 100],
	["thin", 100],
	["light", 300],
	["book", 350],
	["medium", 500],
	["bold", 700],
	["black", 900],
	["heavy", 900],
	["regular", 400],
	["normal", 400],
	["roman", 400],
];

export function weightValue(weight: FontWeight): number {
	if (typeIs(weight, "number")) {
		return weight;
	}
	if (typeIs(weight, "EnumItem")) {
		return weight.Value;
	}
	return aliases[weight];
}

export function weightFromName(name: string): number | undefined {
	const normalized = name.lower().gsub("[%s_%-]", "")[0];
	for (const [pattern, value] of patterns) {
		if (normalized.find(pattern, 1, true)[0] !== undefined) {
			return value;
		}
	}
	return undefined;
}
