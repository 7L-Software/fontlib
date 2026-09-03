--!native
--!optimize 2

local reader = require(script.Parent.reader)
local coverage = require(script.Parent.coverage)

type Ligature = { glyph: number, components: { number } }
type Subtable = { coverage: coverage.Coverage, sets: { { Ligature } } }

local wanted = { ccmp = true, liga = true, rlig = true }

local gsub = {}

local function readLigatures(data: buffer, offset: number): Subtable?
	if reader.u16(data, offset) ~= 1 then
		return nil
	end
	local set = coverage.read(data, offset + reader.u16(data, offset + 2))
	if not set then
		return nil
	end
	local setCount = reader.u16(data, offset + 4)
	local sets = table.create(setCount)
	for index = 0, setCount - 1 do
		local setOffset = offset + reader.u16(data, offset + 6 + index * 2)
		local ligatureCount = reader.u16(data, setOffset)
		local ligatures = table.create(ligatureCount)
		for position = 0, ligatureCount - 1 do
			local ligature = setOffset + reader.u16(data, setOffset + 2 + position * 2)
			local componentCount = reader.u16(data, ligature + 2)
			local components = table.create(componentCount - 1)
			for component = 1, componentCount - 1 do
				components[component] = reader.u16(data, ligature + 4 + (component - 1) * 2)
			end
			ligatures[position + 1] = { glyph = reader.u16(data, ligature), components = components }
		end
		sets[index + 1] = ligatures
	end
	return { coverage = set, sets = sets }
end

local function matchAt(subtable: Subtable, glyphs: { number }, index: number): Ligature?
	local coverageIndex = coverage.indexOf(subtable.coverage, glyphs[index])
	local set = coverageIndex and subtable.sets[coverageIndex + 1]
	if not set then
		return nil
	end
	for _, ligature in set do
		local components = ligature.components
		local fits = index + #components <= #glyphs
		if fits then
			for position, component in components do
				if glyphs[index + position] ~= component then
					fits = false
					break
				end
			end
		end
		if fits then
			return ligature
		end
	end
	return nil
end

local function apply(subtable: Subtable, glyphs: { number }, sizes: { number }): ({ number }, { number })
	local output, outputSizes = {}, {}
	local index = 1
	while index <= #glyphs do
		local ligature = matchAt(subtable, glyphs, index)
		if ligature then
			local consumed = 0
			for position = 0, #ligature.components do
				consumed += sizes[index + position]
			end
			output[#output + 1] = ligature.glyph
			outputSizes[#outputSizes + 1] = consumed
			index += #ligature.components + 1
		else
			output[#output + 1] = glyphs[index]
			outputSizes[#outputSizes + 1] = sizes[index]
			index += 1
		end
	end
	return output, outputSizes
end

function gsub.read(data: buffer, tables): ((glyphs: { number }) -> ({ number }, { number }))?
	local record = tables.GSUB
	if not record then
		return nil
	end
	local base = record.offset
	local features = base + reader.u16(data, base + 6)
	local lookupIndices: { [number]: boolean } = {}
	for index = 0, reader.u16(data, features) - 1 do
		local feature = features + 2 + index * 6
		if wanted[reader.tag(data, feature)] then
			local list = features + reader.u16(data, feature + 4)
			for lookup = 0, reader.u16(data, list + 2) - 1 do
				lookupIndices[reader.u16(data, list + 4 + lookup * 2)] = true
			end
		end
	end

	local ordered = {}
	for index in lookupIndices do
		table.insert(ordered, index)
	end
	table.sort(ordered)

	local lookupList = base + reader.u16(data, base + 8)
	local subtables: { Subtable } = {}
	for _, index in ordered do
		local lookup = lookupList + reader.u16(data, lookupList + 2 + index * 2)
		local kind = reader.u16(data, lookup)
		for subtable = 0, reader.u16(data, lookup + 4) - 1 do
			local offset = lookup + reader.u16(data, lookup + 6 + subtable * 2)
			local parsed
			if kind == 4 then
				parsed = readLigatures(data, offset)
			elseif kind == 7 and reader.u16(data, offset + 2) == 4 then
				parsed = readLigatures(data, offset + reader.u32(data, offset + 4))
			end
			if parsed then
				subtables[#subtables + 1] = parsed
			end
		end
	end
	if #subtables == 0 then
		return nil
	end

	return function(glyphs: { number }): ({ number }, { number })
		local sizes = table.create(#glyphs, 1)
		for _, subtable in subtables do
			glyphs, sizes = apply(subtable, glyphs, sizes)
		end
		return glyphs, sizes
	end
end

return gsub
