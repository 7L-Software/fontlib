--!native
--!optimize 2

local reader = require(script.Parent.reader)

local names = {}

local wanted = { [1] = true, [2] = true, [4] = true, [6] = true, [16] = true, [17] = true }

local function utf16(data: buffer, offset: number, length: number): string
	local parts = {}
	local cursor = offset
	local stop = offset + length - 1
	while cursor < stop do
		local unit = reader.u16(data, cursor)
		cursor += 2
		local codepoint = unit
		if unit >= 0xD800 and unit <= 0xDBFF and cursor < stop then
			local low = reader.u16(data, cursor)
			if low >= 0xDC00 and low <= 0xDFFF then
				codepoint = 0x10000 + (unit - 0xD800) * 0x400 + low - 0xDC00
				cursor += 2
			end
		end
		if codepoint ~= 0 then
			parts[#parts + 1] = utf8.char(codepoint)
		end
	end
	return table.concat(parts)
end

local function trim(value: string): string
	return (value:gsub("%z", ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

function names.read(data: buffer, tables): { [number]: string }
	local result: { [number]: string } = {}
	local nameTable = tables.name
	if not nameTable or nameTable.length < 6 then
		return result
	end

	local base = nameTable.offset
	local storage = base + reader.u16(data, base + 4)
	local size = buffer.len(data)
	local scores: { [number]: number } = {}
	for index = 0, reader.u16(data, base + 2) - 1 do
		local record = base + 6 + index * 12
		if record + 12 > base + nameTable.length then
			break
		end
		local platform = reader.u16(data, record)
		local language = reader.u16(data, record + 4)
		local id = reader.u16(data, record + 6)
		local length = reader.u16(data, record + 8)
		local offset = storage + reader.u16(data, record + 10)
		if wanted[id] and offset + length <= size then
			local value
			if platform == 0 or platform == 3 then
				value = utf16(data, offset, length)
			else
				value = buffer.readstring(data, offset, length)
			end
			value = trim(value)
			local score = (if platform == 3 then 20 elseif platform == 0 then 15 else 5)
				+ (if language == 0x409 then 5 elseif language == 0 then 2 else 0)
			if value ~= "" and score > (scores[id] or -1) then
				result[id] = value
				scores[id] = score
			end
		end
	end
	return result
end

return names
