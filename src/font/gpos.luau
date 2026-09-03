--!native
--!optimize 2

local reader = require(script.Parent.reader)
local coverage = require(script.Parent.coverage)

type ClassDefinition = {
	format: number,
	first: number,
	classes: { number },
	firsts: { number },
	lasts: { number },
	values: { number },
}

type Rule = {
	coverage: coverage.Coverage,
	class1: ClassDefinition?,
	class2: ClassDefinition?,
	matrix: { [number]: { [number]: number } },
}

local gpos = {}

local function valueRecordSize(format: number): number
	local size = 0
	for bit = 0, 7 do
		if bit32.band(format, bit32.lshift(1, bit)) ~= 0 then
			size += 2
		end
	end
	return size
end

local function xAdvance(data: buffer, offset: number, format: number): number
	local cursor, advance = offset, 0
	for bit = 0, 7 do
		local mask = bit32.lshift(1, bit)
		if bit32.band(format, mask) ~= 0 then
			if mask == 4 then
				advance = reader.i16(data, cursor)
			end
			cursor += 2
		end
	end
	return advance
end

local function readClasses(data: buffer, offset: number): ClassDefinition?
	local format = reader.u16(data, offset)
	if format == 1 then
		local first = reader.u16(data, offset + 2)
		local count = reader.u16(data, offset + 4)
		local classes = table.create(count)
		for index = 0, count - 1 do
			classes[index + 1] = reader.u16(data, offset + 6 + index * 2)
		end
		return { format = 1, first = first, classes = classes, firsts = {}, lasts = {}, values = {} }
	elseif format == 2 then
		local count = reader.u16(data, offset + 2)
		local firsts, lasts, values = table.create(count), table.create(count), table.create(count)
		for index = 0, count - 1 do
			local range = offset + 4 + index * 6
			firsts[index + 1] = reader.u16(data, range)
			lasts[index + 1] = reader.u16(data, range + 2)
			values[index + 1] = reader.u16(data, range + 4)
		end
		return { format = 2, first = 0, classes = {}, firsts = firsts, lasts = lasts, values = values }
	end
	return nil
end

local function classOf(definition: ClassDefinition?, glyph: number): number
	if not definition then
		return 0
	end
	if definition.format == 1 then
		return definition.classes[glyph - definition.first + 1] or 0
	end
	local firsts, lasts = definition.firsts, definition.lasts
	local low, high = 1, #firsts
	while low <= high do
		local middle = (low + high) // 2
		if glyph < firsts[middle] then
			high = middle - 1
		elseif glyph > lasts[middle] then
			low = middle + 1
		else
			return definition.values[middle]
		end
	end
	return 0
end

function gpos.read(data: buffer, tables): ((number, number) -> number?)?
	local record = tables.GPOS
	if not record then
		return nil
	end
	local base = record.offset
	local adjustments: { [number]: number } = {}
	local rules: { Rule } = {}

	local function readPairs(offset: number)
		local format = reader.u16(data, offset)
		local set = coverage.read(data, offset + reader.u16(data, offset + 2))
		if not set then
			return
		end
		local format1 = reader.u16(data, offset + 4)
		local format2 = reader.u16(data, offset + 6)
		local size1, size2 = valueRecordSize(format1), valueRecordSize(format2)

		if format == 1 then
			local setCount = reader.u16(data, offset + 8)
			for coverageIndex = 0, setCount - 1 do
				local first = coverage.glyphAt(set, coverageIndex)
				local set = offset + reader.u16(data, offset + 10 + coverageIndex * 2)
				local cursor = set + 2
				for _ = 1, reader.u16(data, set) do
					local second = reader.u16(data, cursor)
					local adjustment = xAdvance(data, cursor + 2, format1)
					if first and adjustment ~= 0 then
						local key = first * 65536 + second
						adjustments[key] = (adjustments[key] or 0) + adjustment
					end
					cursor += 2 + size1 + size2
				end
			end
		elseif format == 2 then
			local class1 = readClasses(data, offset + reader.u16(data, offset + 8))
			local class2 = readClasses(data, offset + reader.u16(data, offset + 10))
			local count1 = reader.u16(data, offset + 12)
			local count2 = reader.u16(data, offset + 14)
			local matrix = {}
			local cursor = offset + 16
			for first = 0, count1 - 1 do
				local row = {}
				for second = 0, count2 - 1 do
					local adjustment = xAdvance(data, cursor, format1)
					if adjustment ~= 0 then
						row[second] = adjustment
					end
					cursor += size1 + size2
				end
				matrix[first] = row
			end
			rules[#rules + 1] = { coverage = set, class1 = class1, class2 = class2, matrix = matrix }
		end
	end

	local features = base + reader.u16(data, base + 6)
	local lookups: { [number]: boolean } = {}
	for index = 0, reader.u16(data, features) - 1 do
		local feature = features + 2 + index * 6
		local tag = reader.tag(data, feature)
		if tag == "kern" or tag == "dist" then
			local list = features + reader.u16(data, feature + 4)
			for lookup = 0, reader.u16(data, list + 2) - 1 do
				lookups[reader.u16(data, list + 4 + lookup * 2)] = true
			end
		end
	end

	local lookupList = base + reader.u16(data, base + 8)
	for index in lookups do
		local lookup = lookupList + reader.u16(data, lookupList + 2 + index * 2)
		local kind = reader.u16(data, lookup)
		for subtable = 0, reader.u16(data, lookup + 4) - 1 do
			local offset = lookup + reader.u16(data, lookup + 6 + subtable * 2)
			if kind == 2 then
				readPairs(offset)
			elseif kind == 9 and reader.u16(data, offset) == 1 and reader.u16(data, offset + 2) == 2 then
				readPairs(offset + reader.u32(data, offset + 4))
			end
		end
	end

	if next(adjustments) == nil and #rules == 0 then
		return nil
	end

	return function(left: number, right: number): number?
		local adjustment = adjustments[left * 65536 + right]
		local matched = adjustment ~= nil
		adjustment = adjustment or 0
		for _, rule in rules do
			if coverage.indexOf(rule.coverage, left) then
				matched = true
				local row = rule.matrix[classOf(rule.class1, left)]
				adjustment += (row and row[classOf(rule.class2, right)]) or 0
			end
		end
		return if matched then adjustment else nil
	end
end

return gpos
