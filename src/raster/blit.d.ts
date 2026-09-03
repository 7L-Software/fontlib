declare const blit: {
	coverage: (
		canvas: buffer,
		canvasWidth: number,
		canvasHeight: number,
		glyph: buffer,
		glyphWidth: number,
		glyphHeight: number,
		x: number,
		y: number,
	) => void;
	color: (
		canvas: buffer,
		canvasWidth: number,
		canvasHeight: number,
		glyph: buffer,
		glyphWidth: number,
		glyphHeight: number,
		x: number,
		y: number,
		red: number,
		green: number,
		blue: number,
		alpha: number,
	) => void;
	image: (
		canvas: buffer,
		canvasWidth: number,
		canvasHeight: number,
		image: buffer,
		imageWidth: number,
		imageHeight: number,
		x: number,
		y: number,
	) => void;
	alpha: (canvas: buffer, rgba: buffer, count: number) => void;
};

export = blit;
