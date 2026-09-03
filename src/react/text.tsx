import React, { forwardRef, useContext, useEffect, useRef } from "@rbxts/react";
import { TextRenderer } from "../render/text-renderer";
import { codepointsInGraphemes } from "../text/graphemes";
import { DefaultsContext } from "./context";
import type { TextProps } from "./types";
import { useFallbackFonts, useFont } from "./use-font";

function assign(target: React.Ref<ImageLabel> | undefined, instance: ImageLabel | undefined) {
	if (typeIs(target, "function")) {
		target(instance);
	} else if (target) {
		(target as React.MutableRefObject<ImageLabel | undefined>).current = instance;
	}
}

export const Text = forwardRef<ImageLabel, TextProps>((props, ref) => {
	const defaults = useContext(DefaultsContext);
	const weight = props.fontWeight ?? 400;
	const italic = props.fontStyle === Enum.FontStyle.Italic;
	const font = useFont(props.font ?? defaults.font, weight, italic);
	const fallbacks = useFallbackFonts(props.fallbackFonts ?? defaults.fallbackFonts, weight, italic);
	const label = useRef<ImageLabel>();
	const renderer = useRef<TextRenderer>();

	useEffect(() => {
		const instance = label.current;
		if (!instance) {
			return;
		}
		const created = new TextRenderer(instance);
		renderer.current = created;
		return () => {
			created.destroy();
			renderer.current = undefined;
		};
	}, []);

	const onBounds = props.onBounds;
	useEffect(() => {
		if (renderer.current) {
			renderer.current.onBounds = onBounds;
		}
	}, [onBounds]);

	useEffect(() => {
		renderer.current?.update({
			text: props.text,
			font,
			fallbacks,
			textSize: props.textSize ?? defaults.textSize,
			sizeMode: props.sizeMode ?? defaults.sizeMode,
			resolution: props.resolution ?? defaults.resolution,
			lineHeight: props.lineHeight ?? defaults.lineHeight,
			letterSpacing: props.letterSpacing ?? 0,
			wordBreak: props.wordBreak ?? defaults.wordBreak,
			wrapped: props.textWrapped ?? false,
			truncate: props.textTruncate === Enum.TextTruncate.AtEnd,
			transparency: props.textTransparency ?? 0,
			xAlignment: props.textXAlignment ?? Enum.TextXAlignment.Left,
			yAlignment: props.textYAlignment ?? Enum.TextYAlignment.Center,
			automaticSize: props.automaticSize ?? Enum.AutomaticSize.None,
			maxCodepoints:
				props.maxVisibleGraphemes !== undefined && props.maxVisibleGraphemes >= 0
					? codepointsInGraphemes(props.text, props.maxVisibleGraphemes)
					: undefined,
		});
	});

	return (
		<imagelabel
			ref={(instance) => {
				label.current = instance;
				assign(ref, instance);
			}}
			Size={props.size ?? UDim2.fromOffset(200, 50)}
			Position={props.position}
			AnchorPoint={props.anchorPoint}
			LayoutOrder={props.layoutOrder}
			ZIndex={props.zIndex}
			Visible={props.visible}
			BackgroundColor3={props.backgroundColor}
			BackgroundTransparency={props.backgroundTransparency ?? 1}
			BorderSizePixel={0}
			ImageColor3={props.textColor ?? defaults.textColor}
			ImageTransparency={props.textTransparency}
			ScaleType={Enum.ScaleType.Stretch}
		>
			{props.children}
		</imagelabel>
	);
});
