declare const reader: {
	u8: (data: buffer, offset: number) => number;
	i8: (data: buffer, offset: number) => number;
	u16: (data: buffer, offset: number) => number;
	i16: (data: buffer, offset: number) => number;
	u32: (data: buffer, offset: number) => number;
	f2dot14: (data: buffer, offset: number) => number;
	tag: (data: buffer, offset: number) => string;
};

export = reader;
