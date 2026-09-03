--!native
--!optimize 2

local fill = {}

local function drawLine(acc: { number }, width: number, height: number, x0: number, y0: number, x1: number, y1: number)
	if math.abs(y0 - y1) <= 1e-9 then
		return
	end
	local dir = 1
	if y0 > y1 then
		dir = -1
		x0, y0, x1, y1 = x1, y1, x0, y0
	end

	local dxdy = (x1 - x0) / (y1 - y0)
	local x = x0
	if y0 < 0 then
		x -= y0 * dxdy
	end
	local yStart = math.max(0, math.floor(y0))
	local yEnd = math.min(height, math.ceil(y1))

	for y = yStart, yEnd - 1 do
		local lineStart = y * width
		local dy = math.min(y + 1, y1) - math.max(y, y0)
		local xNext = x + dxdy * dy
		local d = dy * dir
		local xa, xb = x, xNext
		if xa > xb then
			xa, xb = xb, xa
		end
		local xaFloor = math.floor(xa)
		local xai = math.max(0, xaFloor)
		local xbCeil = math.ceil(xb)
		local xbi = math.min(width, xbCeil)

		if xbi <= xai + 1 then
			local xmf = 0.5 * (x + xNext) - xaFloor
			local index = lineStart + xai + 1
			acc[index] += d - d * xmf
			acc[index + 1] += d * xmf
		else
			local s = 1 / (xb - xa)
			local xaf = xa - xaFloor
			local a0 = 0.5 * s * (1 - xaf) * (1 - xaf)
			local xbf = xb - xbCeil + 1
			local am = 0.5 * s * xbf * xbf
			local index = lineStart + xai + 1
			acc[index] += d * a0
			if xbi == xai + 2 then
				acc[index + 1] += d * (1 - a0 - am)
			else
				local a1 = s * (1.5 - xaf)
				acc[index + 1] += d * (a1 - a0)
				for xi = xai + 2, xbi - 2 do
					acc[lineStart + xi + 1] += d * s
				end
				local a2 = a1 + (xbi - xai - 3) * s
				acc[lineStart + xbi] += d * (1 - a2 - am)
			end
			acc[lineStart + xbi + 1] += d * am
		end
		x = xNext
	end
end

function fill.coverage(polylines: { { number } }, offsetX: number, offsetY: number, width: number, height: number): buffer
	local area = width * height
	local acc = table.create(area + width + 8, 0)
	for _, line in polylines do
		local count = #line
		local px, py = line[count - 1] + offsetX, line[count] + offsetY
		for index = 1, count, 2 do
			local x, y = line[index] + offsetX, line[index + 1] + offsetY
			drawLine(acc, width, height, px, py, x, y)
			px, py = x, y
		end
	end

	local out = buffer.create(area)
	local sum = 0
	for index = 1, area do
		sum += acc[index]
		local value = math.abs(sum)
		if value > 1 then
			value = 1
		end
		buffer.writeu8(out, index - 1, math.floor(value * 255 + 0.5))
	end
	return out
end

return fill
