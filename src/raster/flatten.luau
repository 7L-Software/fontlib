--!native
--!optimize 2

local path = require(script.Parent.path)

type Path = path.Path

local flatten = {}

local function quadSteps(ddx: number, ddy: number, tolerance: number): number
	local count = math.ceil(math.sqrt(math.sqrt(ddx * ddx + ddy * ddy) / (4 * tolerance)))
	return math.clamp(count, 1, 64)
end

local function cubicSteps(m: number, tolerance: number): number
	local count = math.ceil(math.sqrt(3 * m / (4 * tolerance)))
	return math.clamp(count, 1, 100)
end

function flatten.polylines(p: Path, a: number, b: number, c: number, d: number, tolerance: number): { { number } }
	local coords = p.coords
	local result = {}
	local current: { number }? = nil
	local cursor = 1
	local x, y = 0, 0

	local function finish()
		if current and #current >= 6 then
			result[#result + 1] = current
		end
		current = nil
	end

	for _, verb in p.verbs do
		if verb == path.MOVE then
			finish()
			local px, py = coords[cursor], coords[cursor + 1]
			cursor += 2
			x, y = a * px + c * py, b * px + d * py
			current = { x, y }
		elseif verb == path.LINE then
			local px, py = coords[cursor], coords[cursor + 1]
			cursor += 2
			x, y = a * px + c * py, b * px + d * py
			if current then
				current[#current + 1] = x
				current[#current + 1] = y
			end
		elseif verb == path.QUAD then
			local c1x, c1y = coords[cursor], coords[cursor + 1]
			local px, py = coords[cursor + 2], coords[cursor + 3]
			cursor += 4
			local cx, cy = a * c1x + c * c1y, b * c1x + d * c1y
			local nx, ny = a * px + c * py, b * px + d * py
			if current then
				local steps = quadSteps(x - 2 * cx + nx, y - 2 * cy + ny, tolerance)
				for step = 1, steps do
					local t = step / steps
					local u = 1 - t
					current[#current + 1] = u * u * x + 2 * u * t * cx + t * t * nx
					current[#current + 1] = u * u * y + 2 * u * t * cy + t * t * ny
				end
			end
			x, y = nx, ny
		elseif verb == path.CUBIC then
			local c1x, c1y = coords[cursor], coords[cursor + 1]
			local c2x, c2y = coords[cursor + 2], coords[cursor + 3]
			local px, py = coords[cursor + 4], coords[cursor + 5]
			cursor += 6
			local ax, ay = a * c1x + c * c1y, b * c1x + d * c1y
			local bx, by = a * c2x + c * c2y, b * c2x + d * c2y
			local nx, ny = a * px + c * py, b * px + d * py
			if current then
				local d1x, d1y = x - 2 * ax + bx, y - 2 * ay + by
				local d2x, d2y = ax - 2 * bx + nx, ay - 2 * by + ny
				local m = math.max(math.sqrt(d1x * d1x + d1y * d1y), math.sqrt(d2x * d2x + d2y * d2y))
				local steps = cubicSteps(m, tolerance)
				for step = 1, steps do
					local t = step / steps
					local u = 1 - t
					local uu, tt = u * u, t * t
					current[#current + 1] = uu * u * x + 3 * uu * t * ax + 3 * u * tt * bx + tt * t * nx
					current[#current + 1] = uu * u * y + 3 * uu * t * ay + 3 * u * tt * by + tt * t * ny
				end
			end
			x, y = nx, ny
		elseif verb == path.CLOSE then
			finish()
		end
	end
	finish()
	return result
end

function flatten.bounds(polylines: { { number } }): (number, number, number, number)
	local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
	for _, line in polylines do
		for index = 1, #line, 2 do
			local x, y = line[index], line[index + 1]
			if x < minX then
				minX = x
			end
			if x > maxX then
				maxX = x
			end
			if y < minY then
				minY = y
			end
			if y > maxY then
				maxY = y
			end
		end
	end
	return minX, minY, maxX, maxY
end

return flatten
