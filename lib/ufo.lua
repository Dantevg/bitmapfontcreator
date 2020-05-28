--[[
	
	UFO Unified Font Object XML file helper
	by Dante van Gemert
	
	This lib helps generating the XML
	for the files needed for a UFO
	
]]--

local ufo = {}

ufo.xmlHeader = [[
<?xml version="1.0" encoding="UTF-8"?>
]]

ufo.plistHeader = ufo.xmlHeader..[[
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN"
"http://www.apple.com/DTDs/PropertyList-1.0.dtd">
]]

-- Converts the name to a valid filename according to ufo conventions
-- http://unifiedfontobject.org/versions/ufo3/conventions/#common-user-name-to-file-name-algorithm
function ufo.convertToFilename(name)
	local reservedNames = {
		"CON","PRN","AUX","CLOCK$","NUL","A:-Z:","COM1","LPT1","LPT2","LPT3","COM2","COM3","COM4:"
	}
	
	-- Replace illegal characters \001 to \032 and \127, " * + / : < > ? [ \ ] |
	name = name:gsub( "[\z\1-\32\127\"%*%+/:<>%?%[\\|%]]", "_" )
	name = name:gsub( "%u", "%1_" ) -- Insert underscore after every uppercase letter
	name = name:gsub( "^%.", "_" ) -- Replace dot at beginning of name with underscore
	name = name:gsub( "[^%.]+", function(match) -- Avoid DOS-reserved filenames
		for _, reserved in ipairs(reservedNames) do
			if match:upper() == reserved then return "_"..match end
		end
	end )
	
	return name:sub( 1, 255 ) -- Cut off names longer than 255 characters
end

return ufo