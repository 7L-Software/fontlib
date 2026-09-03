export interface TableRecord {
	offset: number;
	length: number;
}

export type Directory = Record<string, TableRecord | undefined>;

declare const directory: {
	read: (data: buffer) => Directory;
};

export = directory;
