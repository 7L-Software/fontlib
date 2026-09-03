import blit from "./raster/blit";
import fill from "./raster/fill";
import flatten from "./raster/flatten";
import path from "./raster/path";

export { fontFamilies, onFontsChanged, registerFont, resolveFont } from "./registry/fonts";
export type { FontFace, FontOverrides } from "./registry/fonts";
export type { FontWeight, WeightName } from "./registry/weight";
export { layoutText } from "./text/layout";
export type { LayoutLine, LayoutOptions, SizeMode, TextLayout } from "./text/layout";
export type { ShapedGlyph } from "./text/shape";
export type { WordBreak } from "./text/line-break";
export { measureText } from "./text/measure";
export type { MeasureOptions } from "./text/measure";
export { truncateLayout } from "./text/truncate";
export { TextRenderer } from "./render/text-renderer";
export { setFrameBudget } from "./render/scheduler";
export type { RenderProps } from "./render/text-renderer";
export { Text } from "./react/text";
export { FontProvider } from "./react/provider";
export { useFont } from "./react/use-font";
export type { FontProviderProps, TextDefaults, TextProps } from "./react/types";
export type { Face } from "./font/face";
export type { Path } from "./raster/path";

export const raster = { path, flatten, fill, blit };
