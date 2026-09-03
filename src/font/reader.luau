--!native
--!optimize 2

local reader = {}

function reader.u8(data: buffer, offset: number): number
	return buffer.readu8(data, offset)
end

function reader.i8(data: buffer, offset: number): number
	local value = buffer.readu8(data, offset)
	if value >= 0x80 then
		return value - 0x100
	end
	return value
end

function reader.u16(data: buffer, offset: number): number
	return buffer.readu8(data, offset) * 256 + buffer.readu8(data, offset + 1)
end

function reader.i16(data: buffer, offset: number): number
	local value = buffer.readu8(data, offset) * 256 + buffer.readu8(data, offset + 1)
	if value >= 0x8000 then
		return value - 0x10000
	end
	return value
end

function reader.u32(data: buffer, offset: number): number
	return bit32.byteswap(buffer.readu32(data, offset))
end

function reader.f2dot14(data: buffer, offset: number): number
	return reader.i16(data, offset) / 16384
end

function reader.tag(data: buffer, offset: number): string
	return buffer.readstring(data, offset, 4)
end

return reader
