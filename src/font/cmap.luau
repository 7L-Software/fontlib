--!native
--!optimize 2

local reader = require(script.Parent.reader)

local cmap = {}

local function choose(data: buffer, base: number): (number?, number?)
	local count = reader.u16(data, base + 2)
	local best4, best12, any4, any12
	for index = 0, count - 1 do
		local record = base + 4 + index * 8
		local platform = reader.u16(data, record)
		local encoding = reader.u16(data, record + 2)
		local offset = base + reader.u32(data, record + 4)
		local format = reader.u16(data, offset)
		local unicode = platform == 0 or platform == 3
		if format == 12 then
			any12 = any12 or offset
			if unicode and (platform == 0 or encoding == 10) then
				best12 = best12 or offset
			end
		elseif format == 4 then
			any4 = any4 or offset
			if unicode and (platform == 0 or encoding == 1 or encoding == 0) then
				best4 = best4 or offset
			end
		end
	end
	return best4 or any4, best12 or any12
end

function cmap.read(data: buffer, tables): (number) -> number
	local offset4, offset12 = choose(data, tables.cmap.offset)
	assert(offset4 or offset12, "font has no unicode cmap")

	local starts, ends, deltas, rangeOffsets, rangeBases = {}, {}, {}, {}, {}
	local segmentCount = 0
	if offset4 then
		local doubled = reader.u16(data, offset4 + 6)
		segmentCount = doubled // 2
		local endBase = offset4 + 14
		local startBase = endBase + doubled + 2
		local deltaBase = startBase + doubled
		local rangeBase = deltaBase + doubled
		for index = 0, segmentCount - 1 do
			starts[index + 1] = reader.u16(data, startBase + index * 2)
			ends[index + 1] = reader.u16(data, endBase + index * 2)
			deltas[index + 1] = reader.i16(data, deltaBase + index * 2)
			rangeOffsets[index + 1] = reader.u16(data, rangeBase + index * 2)
			rangeBases[index + 1] = rangeBase + index * 2
		end
	end

	local groupStarts, groupEnds, groupGlyphs = {}, {}, {}
	local groupCount = 0
	if offset12 then
		groupCount = reader.u32(data, offset12 + 12)
		for index = 0, groupCount - 1 do
			local group = offset12 + 16 + index * 12
			groupStarts[index + 1] = reader.u32(data, group)
			groupEnds[index + 1] = reader.u32(data, group + 4)
			groupGlyphs[index + 1] = reader.u32(data, group + 8)
		end
	end

	local function fromGroups(codepoint: number): number
		local low, high = 1, groupCount
		while low <= high do
			local middle = (low + high) // 2
			if codepoint < groupStarts[middle] then
				high = middle - 1
			elseif codepoint > groupEnds[middle] then
				low = middle + 1
			else
				return groupGlyphs[middle] + codepoint - groupStarts[middle]
			end
		end
		return 0
	end

	local function fromSegments(codepoint: number): number
		local low, high = 1, segmentCount
		while low <= high do
			local middle = (low + high) // 2
			if codepoint < starts[middle] then
				high = middle - 1
			elseif codepoint > ends[middle] then
				low = middle + 1
			else
				local rangeOffset = rangeOffsets[middle]
				if rangeOffset == 0 then
					return (codepoint + deltas[middle]) % 65536
				end
				local glyph = reader.u16(data, rangeBases[middle] + rangeOffset + (codepoint - starts[middle]) * 2)
				if glyph == 0 then
					return 0
				end
				return (glyph + deltas[middle]) % 65536
			end
		end
		return 0
	end

	local cache: { [number]: number } = {}
	return function(codepoint: number): number
		local cached = cache[codepoint]
		if cached then
			return cached
		end
		local glyph = 0
		if codepoint <= 0xFFFF and segmentCount > 0 then
			glyph = fromSegments(codepoint)
		end
		if glyph == 0 and groupCount > 0 then
			glyph = fromGroups(codepoint)
		end
		cache[codepoint] = glyph
		return glyph
	end
end

return cmap
