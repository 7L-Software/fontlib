--!native
--!optimize 2

local reader = require(script.Parent.reader)

export type Table = { offset: number, length: number }
export type Directory = { [string]: Table }

local directory = {}

local function fontStart(data: buffer): number
	local signature = reader.tag(data, 0)
	if signature == "ttcf" then
		return reader.u32(data, 12)
	end
	if signature == "OTTO" then
		error("CFF outlines are not supported")
	end
	if signature ~= "\0\1\0\0" and signature ~= "true" then
		error("not a TrueType font")
	end
	return 0
end

function directory.read(data: buffer): Directory
	local base = fontStart(data)
	local size = buffer.len(data)
	local count = reader.u16(data, base + 4)
	local tables: Directory = {}
	for index = 0, count - 1 do
		local record = base + 12 + index * 16
		local offset = reader.u32(data, record + 8)
		local length = reader.u32(data, record + 12)
		if offset + length <= size then
			tables[reader.tag(data, record)] = { offset = offset, length = length }
		end
	end
	if not tables.glyf or not tables.loca then
		error("font has no glyf outlines")
	end
	return tables
end

return directory
