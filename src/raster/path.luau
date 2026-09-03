--!native
--!optimize 2

export type Path = { verbs: { number }, coords: { number } }

local path = {}

path.MOVE = 0
path.LINE = 1
path.QUAD = 2
path.CUBIC = 3
path.CLOSE = 4

function path.new(): Path
	return { verbs = {}, coords = {} }
end

function path.moveTo(p: Path, x: number, y: number)
	local coords = p.coords
	local count = #coords
	coords[count + 1] = x
	coords[count + 2] = y
	p.verbs[#p.verbs + 1] = path.MOVE
end

function path.lineTo(p: Path, x: number, y: number)
	local coords = p.coords
	local count = #coords
	coords[count + 1] = x
	coords[count + 2] = y
	p.verbs[#p.verbs + 1] = path.LINE
end

function path.quadTo(p: Path, controlX: number, controlY: number, x: number, y: number)
	local coords = p.coords
	local count = #coords
	coords[count + 1] = controlX
	coords[count + 2] = controlY
	coords[count + 3] = x
	coords[count + 4] = y
	p.verbs[#p.verbs + 1] = path.QUAD
end

function path.cubicTo(p: Path, x1: number, y1: number, x2: number, y2: number, x: number, y: number)
	local coords = p.coords
	local count = #coords
	coords[count + 1] = x1
	coords[count + 2] = y1
	coords[count + 3] = x2
	coords[count + 4] = y2
	coords[count + 5] = x
	coords[count + 6] = y
	p.verbs[#p.verbs + 1] = path.CUBIC
end

function path.close(p: Path)
	p.verbs[#p.verbs + 1] = path.CLOSE
end

function path.append(target: Path, source: Path, a: number, b: number, c: number, d: number, e: number, f: number)
	local verbs, coords = target.verbs, target.coords
	local verbCount, coordCount = #verbs, #coords
	for index, verb in source.verbs do
		verbs[verbCount + index] = verb
	end
	local sourceCoords = source.coords
	for index = 1, #sourceCoords, 2 do
		local x, y = sourceCoords[index], sourceCoords[index + 1]
		coords[coordCount + index] = a * x + c * y + e
		coords[coordCount + index + 1] = b * x + d * y + f
	end
end

return path
