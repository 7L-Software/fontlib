--!native
--!optimize 2

local reader = require(script.Parent.reader)

export type Layer = { glyph: number, palette: number }

local colr = {}

function colr.read(data: buffer, tables): ((glyph: number) -> { Layer }?)?
	local record = tables.COLR
	if not record then
		return nil
	end
	local base = record.offset
	local baseCount = reader.u16(data, base + 2)
	if baseCount == 0 then
		return nil
	end
	local baseRecords = base + reader.u32(data, base + 4)
	local layerRecords = base + reader.u32(data, base + 8)
	local cache: { [number]: { Layer } | false } = {}

	return function(glyph: number): { Layer }?
		local cached = cache[glyph]
		if cached ~= nil then
			return cached or nil
		end
		local result: { Layer } | false = false
		local low, high = 0, baseCount - 1
		while low <= high do
			local middle = (low + high) // 2
			local entry = baseRecords + middle * 6
			local candidate = reader.u16(data, entry)
			if glyph < candidate then
				high = middle - 1
			elseif glyph > candidate then
				low = middle + 1
			else
				local first = reader.u16(data, entry + 2)
				local count = reader.u16(data, entry + 4)
				local layers = table.create(count)
				for index = 0, count - 1 do
					local layer = layerRecords + (first + index) * 4
					layers[index + 1] = { glyph = reader.u16(data, layer), palette = reader.u16(data, layer + 2) }
				end
				result = layers
				break
			end
		end
		cache[glyph] = result
		return result or nil
	end
end

return colr
