import React from "@rbxts/react";
import type { TextDefaults } from "./types";

export const textDefaults: TextDefaults = {
	textSize: 14,
	textColor: new Color3(0, 0, 0),
	sizeMode: "line",
	wordBreak: "normal",
	lineHeight: 1,
	resolution: 1,
};

export const DefaultsContext = React.createContext<TextDefaults>(textDefaults);
