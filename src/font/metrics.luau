--!native
--!optimize 2

local reader = require(script.Parent.reader)

export type Metrics = {
	unitsPerEm: number,
	ascender: number,
	descender: number,
	lineGap: number,
	capHeight: number,
	xHeight: number,
	glyphCount: number,
	hMetricCount: number,
	longLoca: boolean,
	weightClass: number,
	italic: boolean,
}

local metrics = {}

local function hasBit(value: number, bit: number): boolean
	return bit32.band(value, bit32.lshift(1, bit)) ~= 0
end

function metrics.read(data: buffer, tables): Metrics
	local head = tables.head.offset
	local hhea = tables.hhea.offset
	local maxp = tables.maxp.offset

	local ascender = reader.i16(data, hhea + 4)
	local descender = reader.i16(data, hhea + 6)
	local lineGap = reader.i16(data, hhea + 8)
	local italic = hasBit(reader.u16(data, head + 44), 1)
	local weightClass = 0
	local capHeight = 0
	local xHeight = 0

	local os2 = tables["OS/2"]
	if os2 then
		local base = os2.offset
		weightClass = reader.u16(data, base + 4)
		if os2.length >= 64 then
			italic = italic or hasBit(reader.u16(data, base + 62), 0)
		end
		if ascender == 0 and descender == 0 and os2.length >= 72 then
			ascender = reader.i16(data, base + 68)
			descender = reader.i16(data, base + 70)
			lineGap = reader.i16(data, base + 72)
		end
		if os2.length >= 90 then
			xHeight = reader.i16(data, base + 86)
			capHeight = reader.i16(data, base + 88)
		end
	end

	return {
		unitsPerEm = reader.u16(data, head + 18),
		ascender = ascender,
		descender = descender,
		lineGap = lineGap,
		capHeight = capHeight,
		xHeight = xHeight,
		glyphCount = reader.u16(data, maxp + 4),
		hMetricCount = reader.u16(data, hhea + 34),
		longLoca = reader.i16(data, head + 50) ~= 0,
		weightClass = weightClass,
		italic = italic,
	}
end

return metrics
