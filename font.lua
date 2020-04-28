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
		glyphs = {},
	}, {__index = font} )
end



-- XML FILE OUTPUT
-- Generates output files as described in:
-- http://unifiedfontobject.org/versions/ufo3/

font.outputfiles = {}

-- http://unifiedfontobject.org/versions/ufo3/metainfo.plist/
function font.outputfiles.metainfo(fnt)
	if type(fnt.author) ~= "string" or #fnt.author < 1 then
		return false, "Author name must be present"
	end
	
	return ufo.plistHeader.."\n"..ufo.toXML(
		ufo.plist(
			ufo.dict{
				creator = font.author,
				formatVersion = 3,
			}
		)
	)
end

-- http://unifiedfontobject.org/versions/ufo3/layercontents.plist/
function font.outputfiles.layercontents(fnt)
	
end

function font:generateXML(what)
	if not font.outputfiles[what] then
		error("No such output type")
	end
	
	return font.outputfiles[what](self)
end



-- RETURN
return setmetatable( font, {
	__index = font,
	__call = function( _, ... )
		return font.new(...)
	end
} )