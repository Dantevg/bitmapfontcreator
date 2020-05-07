--[[
	
	Font handling lib
	by Dante van Gemert
	
]]--

local ufo = require "lib/ufo"

local font = {}

function font.new(options)
	if not options then error("Expected options") end
	return setmetatable( {
		name = options.name or "",
		author = options.author or "",
		layers = {
			{name = "public.default", directory = "glyphs", glyphs = {}}
		},
	}, {__index = font} )
end

-- Generates contour points from image
function font.getContourPoints(contour)
	
end



-- XML FILE OUTPUT
-- Generates output files as described in:
-- http://unifiedfontobject.org/versions/ufo3/

font.outputfiles = {}

-- http://unifiedfontobject.org/versions/ufo3/metainfo.plist/
function font.outputfiles.metainfo(fnt)
	if type(fnt.author) ~= "string" or #fnt.author < 1 then
		return false, "Author name must be present and not empty"
	end
	
	return ufo.plistHeader.."\n"..ufo.toXML(
		ufo.plist(
			ufo.dict{
				creator = fnt.author,
				formatVersion = 3,
			}
		)
	)
end

-- http://unifiedfontobject.org/versions/ufo3/fontinfo.plist/
function font.outputfiles.fontinfo(fnt)
	local info = {}
	
	local function insertIfPresent( name, data )
		if data then
			table.insert( info, {name = name, data} )
		end
	end
	
	insertIfPresent( "familyName", fnt.family )
	if fnt.version then
		insertIfPresent( "versionMajor", fnt.version[1] )
		insertIfPresent( "versionMinor", fnt.version[2] )
	end
	insertIfPresent( "year", fnt.year )
	
	insertIfPresent( "copyright", fnt.copyright )
	insertIfPresent( "trademark", fnt.trademark )
	
	insertIfPresent( "unitsPerEm", fnt.unitsPerEm )
	insertIfPresent( "descender", fnt.descender )
	insertIfPresent( "xHeight", fnt.xHeight )
	insertIfPresent( "capHeight", fnt.capHeight )
	insertIfPresent( "ascender", fnt.ascender )
	
	insertIfPresent( "note", fnt.note )
	
	return ufo.plistHeader.."\n"..ufo.toXML(
		ufo.plist(info)
	)
end

-- http://unifiedfontobject.org/versions/ufo3/layercontents.plist/
function font.outputfiles.layercontents(fnt)
	if type(fnt.layers) ~= "table" or #fnt.layers < 1 then
		return false, "Layers must be present and not empty"
	end
	
	local hasGlyphsDir = false
	
	local layers = {}
	for _, v in ipairs(fnt.layers) do
		if not v.name or #v.name < 1 then
			return false, "Layer name must be present and not empty"
		end
		if not v.directory or #v.directory < 1 then
			return false, "Layer directory must be present and not empty"
		end
		if string.sub( v.directory, 1, 7 ) ~= "glyphs." and v.directory ~= "glyphs" then
			return false, "Non-default layer directory must start with 'glyphs.'"
		end
		if v.name == "public.default" and v.directory ~= "glyphs" then
			return false, "Layer name 'public.default' may only be used for directory 'glyphs'"
		end
		if v.directory == "glyphs" then hasGlyphsDir = true end
		table.insert( layers, ufo.array(
			{v.name, v.directory},
			"string"
		) )
	end
	
	if not hasGlyphsDir then
		return false, "Default 'glyhps' dir must be present"
	end
	
	return ufo.plistHeader.."\n"..ufo.toXML(
		ufo.plist(
			ufo.array(layers, "array")
		)
	)
end

-- http://unifiedfontobject.org/versions/ufo3/glyphs/contents.plist/
function font.outputfiles.glyphs_contents( fnt, layer )
	if not layer then error("Expected layer") end
	if type(layer.glyphs) ~= "table" then
		return false, "No glyphs present in layer"
	end
	
	local glyphs = {}
	
	for _, v in pairs(layer.glyphs) do
		glyphs[v.name] = v.path
	end
	
	return ufo.plistHeader.."\n"..ufo.toXML(
		ufo.plist(
			ufo.dict(glyphs)
		)
	)
end

function font.outputfiles.glif( fnt, glyph )
	if not glyph then error("Expected glyph") end
	
	if not glyph.name or #glyph.name < 1 then
		return false, "Glyph name must be present and not empty"
	end
	
	local xml = {
		name = "glyph",
		attr = {name = glyph.name, format = 2}
	}
	
	if glyph.unicode then
		table.insert( xml, {name = "unicode", attr = {hex = glyph.unicode}} )
	end
	
	if glyph.outline then
		local outline = {name = "outline"}
		if glyph.outline.contour then
			table.insert( xml, {
				name = "contour",
				font.getContourPoints(glyph.outline.contour),
			} )
		end
		table.insert( xml, outline )
	end
	
	return ufo.xmlHeader.."\n"..ufo.toXML(xml)
end

function font:generateXML( what, ... )
	if not font.outputfiles[what] then
		error("No such output type")
	end
	
	return font.outputfiles[what]( self, ... )
end



-- RETURN
return setmetatable( font, {
	__call = function( _, ... )
		return font.new(...)
	end
} )