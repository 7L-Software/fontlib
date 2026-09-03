--!native
--!optimize 2

local reader = require(script.Parent.reader)

local cpal = {}

function cpal.read(data: buffer, tables): { number }?
	local record = tables.CPAL
	if not record then
		return nil
	end
	local base = record.offset
	local entryCount = reader.u16(data, base + 2)
	local records = base + reader.u32(data, base + 8)
	local first = reader.u16(data, base + 12)
	local colors = table.create(entryCount * 4)
	for index = 0, entryCount - 1 do
		local color = records + (first + index) * 4
		colors[index * 4 + 1] = buffer.readu8(data, color + 2)
		colors[index * 4 + 2] = buffer.readu8(data, color + 1)
		colors[index * 4 + 3] = buffer.readu8(data, color)
		colors[index * 4 + 4] = buffer.readu8(data, color + 3)
	end
	return colors
end

return cpal
