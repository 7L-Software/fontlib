--!native
--!optimize 2

local reader = require(script.Parent.reader)

export type Coverage = {
	format: number,
	glyphs: { number },
	firsts: { number },
	lasts: { number },
	indices: { number },
}

local coverage = {}

function coverage.read(data: buffer, offset: number): Coverage?
	local format = reader.u16(data, offset)
	local count = reader.u16(data, offset + 2)
	if format == 1 then
		local glyphs = table.create(count)
		for index = 0, count - 1 do
			glyphs[index + 1] = reader.u16(data, offset + 4 + index * 2)
		end
		return { format = 1, glyphs = glyphs, firsts = {}, lasts = {}, indices = {} }
	elseif format == 2 then
		local firsts, lasts, indices = table.create(count), table.create(count), table.create(count)
		for index = 0, count - 1 do
			local range = offset + 4 + index * 6
			firsts[index + 1] = reader.u16(data, range)
			lasts[index + 1] = reader.u16(data, range + 2)
			indices[index + 1] = reader.u16(data, range + 4)
		end
		return { format = 2, glyphs = {}, firsts = firsts, lasts = lasts, indices = indices }
	end
	return nil
end

function coverage.glyphAt(set: Coverage, index: number): number?
	if set.format == 1 then
		return set.glyphs[index + 1]
	end
	for position, first in set.firsts do
		local start = set.indices[position]
		if index >= start and index <= start + set.lasts[position] - first then
			return first + index - start
		end
	end
	return nil
end

function coverage.indexOf(set: Coverage, glyph: number): number?
	if set.format == 1 then
		local glyphs = set.glyphs
		local low, high = 1, #glyphs
		while low <= high do
			local middle = (low + high) // 2
			local candidate = glyphs[middle]
			if glyph < candidate then
				high = middle - 1
			elseif glyph > candidate then
				low = middle + 1
			else
				return middle - 1
			end
		end
		return nil
	end
	local firsts, lasts = set.firsts, set.lasts
	local low, high = 1, #firsts
	while low <= high do
		local middle = (low + high) // 2
		if glyph < firsts[middle] then
			high = middle - 1
		elseif glyph > lasts[middle] then
			low = middle + 1
		else
			return set.indices[middle] + glyph - firsts[middle]
		end
	end
	return nil
end

return coverage
