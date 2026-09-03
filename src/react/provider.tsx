import React, { useContext, useMemo } from "@rbxts/react";
import { DefaultsContext } from "./context";
import type { FontProviderProps } from "./types";

export function FontProvider(props: FontProviderProps) {
	const parent = useContext(DefaultsContext);
	const overrides = props.defaults;
	const value = useMemo(() => ({ ...parent, ...overrides }), [parent, overrides]);
	return <DefaultsContext.Provider value={value}>{props.children}</DefaultsContext.Provider>;
}
