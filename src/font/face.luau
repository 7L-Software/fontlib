--!native
--!optimize 2

local directory = require(script.Parent.directory)
local metrics = require(script.Parent.metrics)
local hmtx = require(script.Parent.hmtx)
local cmap = require(script.Parent.cmap)
local glyf = require(script.Parent.glyf)
local kern = require(script.Parent.kern)
local gpos = require(script.Parent.gpos)
local names = require(script.Parent.names)
local colr = require(script.Parent.colr)
local cpal = require(script.Parent.cpal)
local gsub = require(script.Parent.gsub)
local path = require(script.Parent.Parent.raster.path)

export type Face = {
	unitsPerEm: number,
	ascender: number,
	descender: number,
	lineGap: number,
	capHeight: number,
	xHeight: number,
	glyphCount: number,
	weightClass: number,
	italic: boolean,
	family: string,
	subfamily: string,
	fullName: string,
	postScriptName: string,
	glyphIndex: (codepoint: number) -> number,
	advance: (glyph: number) -> number,
	kerning: (left: number, right: number) -> number,
	outline: (glyph: number) -> path.Path?,
	hasColor: boolean,
	colorLayers: (glyph: number) -> { colr.Layer }?,
	palette: (index: number) -> (number, number, number, number),
	ligate: (glyphs: { number }) -> ({ number }, { number }),
}

local face = {}

function face.parse(data: buffer): Face
	local tables = directory.read(data)
	local info = metrics.read(data, tables)
	local advances = hmtx.read(data, tables, info.hMetricCount, info.glyphCount)
	local pairs = gpos.read(data, tables)
	local legacy = kern.read(data, tables)
	local labels = names.read(data, tables)
	local colorLayers = colr.read(data, tables)
	local colors = cpal.read(data, tables)
	local ligatures = gsub.read(data, tables)

	local function advance(glyph: number): number
		if glyph < 0 or glyph >= info.glyphCount then
			return 0
		end
		return buffer.readu16(advances, glyph * 2)
	end

	local function kerning(left: number, right: number): number
		if pairs then
			local adjustment = pairs(left, right)
			if adjustment then
				return adjustment
			end
		end
		if legacy then
			return legacy[left * 65536 + right] or 0
		end
		return 0
	end

	local function palette(index: number): (number, number, number, number)
		local base = index * 4
		if not colors or not colors[base + 4] then
			return 0, 0, 0, 255
		end
		return colors[base + 1], colors[base + 2], colors[base + 3], colors[base + 4]
	end

	local function ligate(glyphs: { number }): ({ number }, { number })
		if ligatures then
			return ligatures(glyphs)
		end
		return glyphs, table.create(#glyphs, 1)
	end

	local function noLayers(): nil
		return nil
	end

	return {
		unitsPerEm = info.unitsPerEm,
		ascender = info.ascender,
		descender = info.descender,
		lineGap = info.lineGap,
		capHeight = info.capHeight,
		xHeight = info.xHeight,
		glyphCount = info.glyphCount,
		weightClass = info.weightClass,
		italic = info.italic,
		family = labels[16] or labels[1] or "",
		subfamily = labels[17] or labels[2] or "",
		fullName = labels[4] or "",
		postScriptName = labels[6] or "",
		glyphIndex = cmap.read(data, tables),
		advance = advance,
		kerning = kerning,
		outline = glyf.read(data, tables, info.longLoca, info.glyphCount),
		hasColor = colorLayers ~= nil,
		colorLayers = colorLayers or noLayers,
		palette = palette,
		ligate = ligate,
	}
end

return face
