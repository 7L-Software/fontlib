--!native
--!optimize 2

local reader = require(script.Parent.reader)

local kern = {}

function kern.read(data: buffer, tables): { [number]: number }?
	local record = tables.kern
	if not record or reader.u16(data, record.offset) ~= 0 then
		return nil
	end

	local adjustments: { [number]: number } = {}
	local count = reader.u16(data, record.offset + 2)
	local offset = record.offset + 4
	for _ = 1, count do
		local length = reader.u16(data, offset + 2)
		local coverage = reader.u16(data, offset + 4)
		if coverage // 256 == 0 and bit32.band(coverage, 1) ~= 0 then
			local pairCount = reader.u16(data, offset + 6)
			for index = 0, pairCount - 1 do
				local pair = offset + 14 + index * 6
				local key = reader.u16(data, pair) * 65536 + reader.u16(data, pair + 2)
				adjustments[key] = reader.i16(data, pair + 4)
			end
		end
		if length <= 0 then
			break
		end
		offset += length
	end
	return adjustments
end

return kern
