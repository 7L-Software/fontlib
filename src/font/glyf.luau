--!native
--!optimize 2

local reader = require(script.Parent.reader)
local path = require(script.Parent.Parent.raster.path)

type Path = path.Path

local glyf = {}

local function appendContour(target: Path, xs: { number }, ys: { number }, flags: { number }, first: number, last: number)
	local count = last - first + 1
	if count < 2 then
		return
	end

	local start = nil
	for point = first, last do
		if bit32.band(flags[point], 1) ~= 0 then
			start = point
			break
		end
	end

	local startX, startY
	if start then
		startX, startY = xs[start], ys[start]
	else
		start = last
		startX = (xs[first] + xs[last]) / 2
		startY = (ys[first] + ys[last]) / 2
	end

	path.moveTo(target, startX, startY)
	local controlX, controlY = nil, nil
	for step = 1, count do
		local point = start + step
		if point > last then
			point -= count
		end
		local x, y = xs[point], ys[point]
		if bit32.band(flags[point], 1) ~= 0 then
			if controlX then
				path.quadTo(target, controlX, controlY, x, y)
				controlX = nil
			else
				path.lineTo(target, x, y)
			end
		else
			if controlX then
				path.quadTo(target, controlX, controlY, (controlX + x) / 2, (controlY + y) / 2)
			end
			controlX, controlY = x, y
		end
	end
	if controlX then
		path.quadTo(target, controlX, controlY, startX, startY)
	end
	path.close(target)
end

function glyf.read(data: buffer, tables, longLoca: boolean, glyphCount: number): (number) -> Path?
	local locaBase = tables.loca.offset
	local glyfBase = tables.glyf.offset
	local outlines: { [number]: Path | false } = {}
	local parsing: { [number]: boolean } = {}

	local function location(glyph: number): number
		if longLoca then
			return reader.u32(data, locaBase + glyph * 4)
		end
		return reader.u16(data, locaBase + glyph * 2) * 2
	end

	local function simple(target: Path, offset: number, contourCount: number)
		local ends = table.create(contourCount)
		for index = 1, contourCount do
			ends[index] = reader.u16(data, offset + 10 + (index - 1) * 2)
		end
		local pointCount = ends[contourCount] + 1
		local instructionLength = reader.u16(data, offset + 10 + contourCount * 2)
		local cursor = offset + 12 + contourCount * 2 + instructionLength

		local flags = table.create(pointCount)
		local index = 1
		while index <= pointCount do
			local flag = buffer.readu8(data, cursor)
			cursor += 1
			flags[index] = flag
			index += 1
			if bit32.band(flag, 8) ~= 0 then
				local repeats = buffer.readu8(data, cursor)
				cursor += 1
				for _ = 1, repeats do
					if index > pointCount then
						break
					end
					flags[index] = flag
					index += 1
				end
			end
		end

		local xs = table.create(pointCount)
		local x = 0
		for point = 1, pointCount do
			local flag = flags[point]
			if bit32.band(flag, 2) ~= 0 then
				local delta = buffer.readu8(data, cursor)
				cursor += 1
				x += if bit32.band(flag, 16) ~= 0 then delta else -delta
			elseif bit32.band(flag, 16) == 0 then
				x += reader.i16(data, cursor)
				cursor += 2
			end
			xs[point] = x
		end

		local ys = table.create(pointCount)
		local y = 0
		for point = 1, pointCount do
			local flag = flags[point]
			if bit32.band(flag, 4) ~= 0 then
				local delta = buffer.readu8(data, cursor)
				cursor += 1
				y += if bit32.band(flag, 32) ~= 0 then delta else -delta
			elseif bit32.band(flag, 32) == 0 then
				y += reader.i16(data, cursor)
				cursor += 2
			end
			ys[point] = y
		end

		local first = 1
		for contour = 1, contourCount do
			local last = ends[contour] + 1
			appendContour(target, xs, ys, flags, first, last)
			first = last + 1
		end
	end

	local outline

	local function compound(target: Path, offset: number)
		local cursor = offset + 10
		while true do
			local flags = reader.u16(data, cursor)
			local component = reader.u16(data, cursor + 2)
			cursor += 4

			local dx, dy
			if bit32.band(flags, 1) ~= 0 then
				dx, dy = reader.i16(data, cursor), reader.i16(data, cursor + 2)
				cursor += 4
			else
				dx, dy = reader.i8(data, cursor), reader.i8(data, cursor + 1)
				cursor += 2
			end
			if bit32.band(flags, 2) == 0 then
				dx, dy = 0, 0
			end

			local a, b, c, d = 1, 0, 0, 1
			if bit32.band(flags, 8) ~= 0 then
				a = reader.f2dot14(data, cursor)
				d = a
				cursor += 2
			elseif bit32.band(flags, 64) ~= 0 then
				a = reader.f2dot14(data, cursor)
				d = reader.f2dot14(data, cursor + 2)
				cursor += 4
			elseif bit32.band(flags, 128) ~= 0 then
				a = reader.f2dot14(data, cursor)
				b = reader.f2dot14(data, cursor + 2)
				c = reader.f2dot14(data, cursor + 4)
				d = reader.f2dot14(data, cursor + 6)
				cursor += 8
			end

			local source = outline(component)
			if source then
				path.append(target, source, a, b, c, d, dx, dy)
			end
			if bit32.band(flags, 32) == 0 then
				break
			end
		end
	end

	outline = function(glyph: number): Path?
		if glyph < 0 or glyph >= glyphCount then
			return nil
		end
		local cached = outlines[glyph]
		if cached ~= nil then
			return cached or nil
		end
		if parsing[glyph] then
			return nil
		end

		local start = location(glyph)
		local length = location(glyph + 1) - start
		if length <= 0 then
			outlines[glyph] = false
			return nil
		end

		parsing[glyph] = true
		local offset = glyfBase + start
		local contourCount = reader.i16(data, offset)
		local result = path.new()
		if contourCount >= 0 then
			simple(result, offset, contourCount)
		else
			compound(result, offset)
		end
		parsing[glyph] = nil

		if #result.verbs == 0 then
			outlines[glyph] = false
			return nil
		end
		outlines[glyph] = result
		return result
	end

	return outline
end

return glyf
