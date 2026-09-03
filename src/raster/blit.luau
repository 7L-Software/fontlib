--!native
--!optimize 2

local blit = {}

local function clip(canvasWidth: number, canvasHeight: number, width: number, height: number, x: number, y: number)
	return math.max(0, -x), math.max(0, -y), math.min(width, canvasWidth - x), math.min(height, canvasHeight - y)
end

local function over(canvas: buffer, index: number, red: number, green: number, blue: number, alpha: number)
	local existing = buffer.readu8(canvas, index + 3)
	if existing == 0 then
		buffer.writeu8(canvas, index, red)
		buffer.writeu8(canvas, index + 1, green)
		buffer.writeu8(canvas, index + 2, blue)
		buffer.writeu8(canvas, index + 3, alpha)
		return
	end
	local weight = existing * (255 - alpha) // 255
	local total = alpha + weight
	buffer.writeu8(canvas, index, (red * alpha + buffer.readu8(canvas, index) * weight) // total)
	buffer.writeu8(canvas, index + 1, (green * alpha + buffer.readu8(canvas, index + 1) * weight) // total)
	buffer.writeu8(canvas, index + 2, (blue * alpha + buffer.readu8(canvas, index + 2) * weight) // total)
	buffer.writeu8(canvas, index + 3, total)
end

function blit.coverage(
	canvas: buffer,
	canvasWidth: number,
	canvasHeight: number,
	glyph: buffer,
	glyphWidth: number,
	glyphHeight: number,
	x: number,
	y: number
)
	local left, top, right, bottom = clip(canvasWidth, canvasHeight, glyphWidth, glyphHeight, x, y)
	for row = top, bottom - 1 do
		local source = row * glyphWidth
		local target = (y + row) * canvasWidth + x
		for column = left, right - 1 do
			local value = buffer.readu8(glyph, source + column)
			if value ~= 0 then
				local index = target + column
				local existing = buffer.readu8(canvas, index)
				if existing == 0 then
					buffer.writeu8(canvas, index, value)
				else
					buffer.writeu8(canvas, index, existing + value - (existing * value) // 255)
				end
			end
		end
	end
end

function blit.color(
	canvas: buffer,
	canvasWidth: number,
	canvasHeight: number,
	glyph: buffer,
	glyphWidth: number,
	glyphHeight: number,
	x: number,
	y: number,
	red: number,
	green: number,
	blue: number,
	alpha: number
)
	local left, top, right, bottom = clip(canvasWidth, canvasHeight, glyphWidth, glyphHeight, x, y)
	for row = top, bottom - 1 do
		local source = row * glyphWidth
		local target = (y + row) * canvasWidth + x
		for column = left, right - 1 do
			local value = buffer.readu8(glyph, source + column) * alpha // 255
			if value ~= 0 then
				over(canvas, (target + column) * 4, red, green, blue, value)
			end
		end
	end
end

function blit.image(
	canvas: buffer,
	canvasWidth: number,
	canvasHeight: number,
	image: buffer,
	imageWidth: number,
	imageHeight: number,
	x: number,
	y: number
)
	local left, top, right, bottom = clip(canvasWidth, canvasHeight, imageWidth, imageHeight, x, y)
	for row = top, bottom - 1 do
		local source = row * imageWidth
		local target = (y + row) * canvasWidth + x
		for column = left, right - 1 do
			local pixel = (source + column) * 4
			local alpha = buffer.readu8(image, pixel + 3)
			if alpha ~= 0 then
				over(
					canvas,
					(target + column) * 4,
					buffer.readu8(image, pixel),
					buffer.readu8(image, pixel + 1),
					buffer.readu8(image, pixel + 2),
					alpha
				)
			end
		end
	end
end

function blit.alpha(canvas: buffer, rgba: buffer, count: number)
	for index = 0, count - 1 do
		buffer.writeu8(rgba, index * 4 + 3, buffer.readu8(canvas, index))
	end
end

return blit
