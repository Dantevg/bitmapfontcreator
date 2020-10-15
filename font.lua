--[[
	
	Font handling lib
	by Dante van Gemert
	
]]--

local utf8 = require "utf8"
local aglfn = require "lib/aglfn"
local ufo = require "lib/ufo"
local xml = require "lib/xml"
local xmlread = require "lib/xmlread"
local glyph = require "glyph"

local font = {}

font.scale = 100

function font.new(options)
	if not options then error("Expected options") end
	
	local fnt = {
		family = options.family or "",
		author = options.author or "",
		height = options.height,
		style = options.style or "regular",
		version = options.version or "1.0",
		layers = {
			{name = "public.default", directory = "glyphs", glyphs = {}}
		},
	}
	
	local function addGlyph(code)
		table.insert( fnt.layers[1].glyphs, glyph{
			char = utf8.char(code),
			unicode = code,
			width = 1,                -- Default empty width
			height = fnt.height or 1, -- Default empty height
			advance = 6,              -- Default empty advance
		} )
	end
	
	local function addCombiningGlyph(name)
		table.insert( fnt.layers[1].glyphs, glyph.newCombining{
			name = name,
			width = 1,                -- Default empty width
			height = fnt.height or 1, -- Default empty height
			advance = 6,              -- Default empty advance
		} )
	end
	
	-- Pre-fill glyphs array with empty glyphs (the ones which have a name in aglfn, at least)
	for i = 32, 255 do
		if aglfn.getName(i) then addGlyph(i) end
	end
	
	-- Pre-fill glyphs array with empty combining glyphs
	addCombiningGlyph("acutecmb")
	addCombiningGlyph("brevecmb")
	addCombiningGlyph("cedillacmb")
	addCombiningGlyph("circumflexcmb")
	addCombiningGlyph("dieresiscmb")
	addCombiningGlyph("gravecmb")
	addCombiningGlyph("ringcmb")
	addCombiningGlyph("tildecmb")
	
	return setmetatable( fnt, {__index = font} )
end

function font.load(path)
	if not path then error("Expected path") end
	local fnt = {}
	
	love.filesystem.mount( path, ".temp" )
	
	font.inputfiles.metainfo( fnt, love.filesystem.read(".temp/metainfo.plist") )
	font.inputfiles.fontinfo( fnt, love.filesystem.read(".temp/fontinfo.plist") )
	font.inputfiles.layercontents( fnt, love.filesystem.read(".temp/layercontents.plist") )
	
	for _, layer in ipairs(fnt.layers) do
		local glyphs = font.inputfiles.glyphs_contents(
			fnt, love.filesystem.read(".temp/"..layer.directory.."/contents.plist")
		)
		for name, path in pairs(glyphs) do
			table.insert( layer.glyphs, font.inputfiles.glif(
				fnt, love.filesystem.read(".temp/"..layer.directory.."/"..path), name
			) )
		end
		table.sort( layer.glyphs, function(a,b)
			-- Compare unicode values when possible, otherwise (for combining glyphs) compare names
			if a.unicode and b.unicode then
				return a.unicode < b.unicode
			else
				return a.name < b.name
			end
		end )
	end
	
	love.filesystem.unmount(".temp")
	
	return setmetatable( fnt, {__index = font} )
end



-- XML FILE INPUT

font.inputfiles = {}

function font.inputfiles.metainfo( fnt, input )
	local metainfo = xml.input.dict( xmlread(input)[2][1] )
	fnt.author = metainfo.creator
end

function font.inputfiles.fontinfo( fnt, input )
	local fontinfo = xml.input.dict( xmlread(input)[2][1] )
	
	fnt.family = fontinfo.familyName
	fnt.style = fontinfo.styleName
	fnt.version = fontinfo.versionMajor.."."..fontinfo.versionMinor
	fnt.year = fontinfo.year
	
	fnt.copyright = fontinfo.copyright
	fnt.trademark = fontinfo.trademark
	
	fnt.unitsPerEm = fontinfo.unitsPerEm
	fnt.descender = fontinfo.descender
	fnt.xHeight = fontinfo.xHeight
	fnt.capHeight = fontinfo.capHeight
	fnt.ascender = fontinfo.ascender
	
	fnt.note = fontinfo.note
end

function font.inputfiles.layercontents( fnt, input )
	local layercontents = xmlread(input)[2][1]
	fnt.layers = {}
	
	for i = 1, #layercontents do
		table.insert( fnt.layers, {
			name = xml.input(layercontents[i][1]),
			directory = xml.input(layercontents[i][2]),
			glyphs = {},
		} )
	end
end

function font.inputfiles.glyphs_contents( fnt, input )
	local glyphs_contents = xml.input.dict( xmlread(input)[2][1] )
	
	return glyphs_contents
end

function font.inputfiles.glif( fnt, input, name )
	local glif = xml.input.attributes( xmlread(input)[2] )
	local options = {name = name}
	
	if glif.unicode then
		options.unicode = tonumber( glif.unicode.hex, 16 )
	end
	if glif.advance then
		options.advance = tonumber( glif.advance.width ) / font.scale
	end
	if glif.image then
		options.imageData = love.image.newImageData( ".temp/images/"..glif.image.fileName )
	end
	if glif.outline then
		-- TODO: read outline to image
	end
	
	return options.unicode and glyph.new(options) or glyph.newCombining(options)
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
	
	return ufo.plistHeader.."\n"..xml.output.toString(
		xml.output.plist({
			xml.output.dict{
				creator = fnt.author,
				formatVersion = 3,
			}
		}, {version = "1.0"})
	)
end

-- http://unifiedfontobject.org/versions/ufo3/fontinfo.plist/
function font.outputfiles.fontinfo(fnt)
	local info = {}
	
	info.familyName = fnt.family
	info.styleName = fnt.style
	if fnt.version then
		info.versionMajor = tonumber( fnt.version:match("[^%.]+") )
		info.versionMinor = tonumber( fnt.version:match("%.(.+)") )
	end
	info.year = fnt.year
	
	info.copyright = fnt.copyright
	info.trademark = fnt.trademark
	
	info.unitsPerEm = fnt.unitsPerEm
	info.descender = fnt.descender
	info.xHeight = fnt.xHeight
	info.capHeight = fnt.capHeight
	info.ascender = fnt.ascender
	
	info.note = fnt.note
	
	return ufo.plistHeader.."\n"..xml.output.toString(
		xml.output.plist({
			xml.output.dict(info)
		}, {version = "1.0"})
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
		table.insert( layers, xml.output.array(
			{v.name, v.directory},
			nil,
			"string"
		) )
	end
	
	if not hasGlyphsDir then
		return false, "Default 'glyhps' dir must be present"
	end
	
	return ufo.plistHeader.."\n"..xml.output.toString(
		xml.output.plist(
			xml.output.array(layers, nil, "array"),
			{version = "1.0"}
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
		glyphs[v.name] = ufo.convertToFilename(v.name)..".glif"
	end
	
	return ufo.plistHeader.."\n"..xml.output.toString(
		xml.output.plist({
			xml.output.dict(glyphs)
		}, {version = "1.0"})
	)
end

function font.outputfiles.glif( fnt, layer, glyph )
	if not glyph then error("Expected glyph") end
	if not glyph.name or #glyph.name < 1 then
		return false, "Glyph name must be present and not empty"
	end
	
	local glif = {
		name = "glyph",
		attr = {name = glyph.name, format = 2},
		{
			name = "outline",
			unpack( glyph:getContours(font.scale) )
		},
		{
			name = "image",
			attr = { fileName = layer.directory.."_"..ufo.convertToFilename(glyph.name)..".png" }
		},
	}
	
	if glyph.advance then
		table.insert( glif, 1, {
			name = "advance",
			attr = { width = glyph.advance*font.scale }
		} )
	end
	if glyph.unicode then
		table.insert( glif, 1, {
			name = "unicode",
			attr = { hex = string.format( "%04x", glyph.unicode ) }
		} )
	end
	
	return ufo.xmlHeader.."\n"..xml.output.toString(glif)
end

function font:generateXML( what, ... )
	if not font.outputfiles[what] then
		error("No such output type")
	end
	
	return font.outputfiles[what]( self, ... )
end

function font:save(path)
	path = path or ""
	
	local info = love.filesystem.getInfo(path)
	if info and info.type ~= "directory" then -- Is a file
		error("Path is not a directory")
	elseif info and info.type == "directory" and path:match("/(.+)") ~= self.family..".ufo" then
		path = path.."/"..self.family..".ufo" -- Is a folder, place .ufo inside folder
	end
	love.filesystem.createDirectory(path) -- Create .ufo directory
	
	love.filesystem.write( path.."/metainfo.plist", self:generateXML("metainfo") )
	love.filesystem.write( path.."/fontinfo.plist", self:generateXML("fontinfo") )
	love.filesystem.write( path.."/layercontents.plist", self:generateXML("layercontents") )
	
	love.filesystem.createDirectory(path.."/images")
	
	for _, layer in ipairs(self.layers) do
		local imagePath = path.."/images"
		local path = path.."/"..layer.directory
		love.filesystem.createDirectory(path)
		love.filesystem.write( path.."/contents.plist", self:generateXML( "glyphs_contents", layer ) )
		for _, glyph in ipairs(layer.glyphs) do
			-- Save image
			local imagePath = imagePath.."/"..layer.directory.."_"..ufo.convertToFilename(glyph.name)..".png"
			glyph.imageData:encode( "png", imagePath )
			
			-- Save glyph xml
			local path = path.."/"..ufo.convertToFilename(glyph.name)..".glif"
			love.filesystem.write( path, self:generateXML( "glif", layer, glyph ) )
		end
	end
	
	return path
end



-- IMAGE OUTPUT

function font:saveImage(path, width, height)
	width, height = width or 64, height or 64
	self:calculateHeight()
	
	local info = love.filesystem.getInfo(path or "")
	if info and info.type == "directory" then
		path = (path and path.."/"..self.family or self.family) -- Is a folder, place .png inside folder
	end
	
	local canvas = love.graphics.newCanvas( width, height )
	local meta = string.format("return {\n\tfile=%q,\n\theight=%d,\n",
		path..".png", self.height)
	meta = meta .. string.format("\tdescription={\n\t\tfamily=%q,\n\t\tstyle=%q,\n\t},\n",
		self.family, self.style)
	meta = meta .. string.format("\ttexture={\n\t\tfile=%q,\n\t\twidth=%d,\n\t\theight=%d,\n\t},\n\tchars={\n",
		path..".png", width, height)
	local x, y = 0, 0
	for _, glyph in ipairs(self.layers[1].glyphs) do
		if glyph.char then -- Is a normal (non-combining) glyph
			if x + glyph.width >= width then
				x = 0
				y = y + self.height + 1
			end
			
			-- Insert metadata
			meta = meta .. string.format("\t\t{char=%q,x=%d,y=%d,ox=%d,oy=%d,width=%d,height=%d,advance=%d},\n",
				glyph.char, x, y, glyph.xOffset, glyph.yOffset, glyph.width, glyph.height, glyph.advance)
			
			-- Insert image
			canvas:renderTo(function()
				love.graphics.draw( glyph:getImage(), x, y )
			end)
			
			x = x + glyph.width + 1
		end
	end
	
	-- Save
	meta = meta .. "\t}\n}\n"
	love.filesystem.write( path.."_meta.lua", meta )
	canvas:newImageData():encode( "png", path..".png" )
end



-- GLYPHS

function font:calculateHeight()
	self.height = 0
	for _, glyph in ipairs(self.layers[1].glyphs) do
		self.height = math.max( self.height, glyph.height )
	end
	return self.height
end

function font:getGlyph( layer, unicode )
	if type(unicode) == "string" then
		unicode = aglfn.getCodepoint(unicode)
	end
	
	for _, glyph in ipairs(layer.glyphs) do
		if glyph.unicode == unicode then return glyph end
	end
end

function font:getGlyphByName( layer, name )
	for _, glyph in ipairs(layer.glyphs) do
		if glyph.name == name then return glyph end
	end
end

function font:autoCompoundGlyphs(layer)
	local glyphs = {
		A = self:getGlyph( layer, "A" ),
		C = self:getGlyph( layer, "C" ),
		E = self:getGlyph( layer, "E" ),
		I = self:getGlyph( layer, "I" ),
		N = self:getGlyph( layer, "N" ),
		O = self:getGlyph( layer, "O" ),
		U = self:getGlyph( layer, "U" ),
		Y = self:getGlyph( layer, "Y" ),
		
		a = self:getGlyph( layer, "a" ),
		c = self:getGlyph( layer, "c" ),
		e = self:getGlyph( layer, "e" ),
		i = self:getGlyph( layer, "i" ),
		n = self:getGlyph( layer, "n" ),
		o = self:getGlyph( layer, "o" ),
		u = self:getGlyph( layer, "u" ),
		y = self:getGlyph( layer, "y" ),
		
		acutecmb = self:getGlyphByName( layer, "acutecmb" ),
		brevecmb = self:getGlyphByName( layer, "brevecmb" ),
		cedillacmb = self:getGlyphByName( layer, "cedillacmb" ),
		circumflexcmb = self:getGlyphByName( layer, "circumflexcmb" ),
		dieresiscmb = self:getGlyphByName( layer, "dieresiscmb" ),
		gravecmb = self:getGlyphByName( layer, "gravecmb" ),
		ringcmb = self:getGlyphByName( layer, "ringcmb" ),
		tildecmb = self:getGlyphByName( layer, "tildecmb" ),
	}
	
	local function combine( base, ... )
		local glyph = self:getGlyph( layer, base )
		if not glyph then return end
		for _, component in ipairs({...}) do
			if component and component[1] then
				glyph:addComponent( unpack(component) )
			end
		end
	end
	
	local function autocombine( name, y )
		combine( name:sub(1,1), { glyphs[name:sub(2)], 0, y or self.height or 0 } )
	end
	
	-- Uppercase
	autocombine("Agrave")
	autocombine("Aacute")
	autocombine("Acircumflex")
	autocombine("Atilde")
	autocombine("Adieresis")
	autocombine("Aring")
	
	combine( "AE", {glyphs.A, 0, 0}, {glyphs.E, 5, 0} )
	
	combine( "Ccedilla", {glyphs.C, 0, 0}, {glyphs.cedillacmb, 0, -2} )
	
	autocombine("Egrave")
	autocombine("Eacute")
	autocombine("Ecircumflex")
	autocombine("Edieresis")
	
	autocombine("Igrave")
	autocombine("Iacute")
	autocombine("Icircumflex")
	autocombine("Idieresis")
	
	autocombine("Ntilde")
	
	autocombine("Ograve")
	autocombine("Oacute")
	autocombine("Ocircumflex")
	autocombine("Otilde")
	autocombine("Odieresis")
	
	autocombine("Ugrave")
	autocombine("Uacute")
	autocombine("Ucircumflex")
	autocombine("Udieresis")
	
	autocombine("Yacute")
	
	-- Lowercase
	autocombine("agrave")
	autocombine("aacute")
	autocombine("acircumflex")
	autocombine("atilde")
	autocombine("adieresis")
	autocombine("aring")
	
	combine( "ae", {glyphs.a, 0, 0}, {glyphs.e, 4, 0} )
	
	combine( "ccedilla", {glyphs.C, 0, 0}, {glyphs.cedillacmb, 0, -2} )
	
	autocombine("egrave")
	autocombine("eacute")
	autocombine("ecircumflex")
	autocombine("edieresis")
	
	autocombine("igrave")
	autocombine("iacute")
	autocombine("icircumflex")
	autocombine("idieresis")
	
	autocombine("ntilde")
	
	autocombine("ograve")
	autocombine("oacute")
	autocombine("ocircumflex")
	autocombine("otilde")
	autocombine("odieresis")
	
	autocombine("ugrave")
	autocombine("uacute")
	autocombine("ucircumflex")
	autocombine("udieresis")
	
	autocombine("yacute")
	autocombine("ydieresis")
end



-- RETURN

return setmetatable( font, {
	__call = function( _, ... )
		return font.new(...)
	end
} )