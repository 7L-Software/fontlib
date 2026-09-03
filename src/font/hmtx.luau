--!native
--!optimize 2

local reader = require(script.Parent.reader)

local hmtx = {}

function hmtx.read(data: buffer, tables, hMetricCount: number, glyphCount: number): buffer
	local base = tables.hmtx.offset
	local advances = buffer.create(glyphCount * 2)
	local last = 0
	for glyph = 0, math.min(hMetricCount, glyphCount) - 1 do
		last = reader.u16(data, base + glyph * 4)
		buffer.writeu16(advances, glyph * 2, last)
	end
	for glyph = hMetricCount, glyphCount - 1 do
		buffer.writeu16(advances, glyph * 2, last)
	end
	return advances
end

return hmtx
