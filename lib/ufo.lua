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

local function tag( name, attr )
	local s = "<"..name
	for k, v in pairs( attr or {} ) do
		s = s.." "..tostring(k)..'="'..tostring(v)..'"'
	end
	return s..">"
end

function ufo.toXML( data, level )
	if type(data) ~= "table" then error("Expected table") end
	level = level or 0
	if level > 128 then error( "Max table depth (128) reached (recursive tables are not supported)" ) end
	
	local s = tag( data.name, data.attr )
	
	if #data == 1 and type(data[1]) ~= "table" then
		s = s..tostring( data[1] )
	else
		for _, v in ipairs(data) do
			if type(v) == "table" then
				s = s.."\n"..string.rep( "    ", level+1 )..ufo.toXML( v, level+1 )
			else
				s = s.."\n"..string.rep( "    ", level+1 )..tostring( v )
			end
		end
		s = s.."\n"..string.rep( "    ", level )
	end
	
	return s.."</"..data.name..">"
end

local xmlTypes = {
	string = "string",
	number = "integer",
}

function ufo.array( input, xmlType )
	if type(input) ~= "table" then error("Expected table") end
	
	local data = {name = "array"}
	
	for _, v in ipairs(input) do
		table.insert( data, {name = xmlType, v} )
	end
	
	return data
end

function ufo.dict(input)
	if type(input) ~= "table" then error("Expected table") end
	
	local data = {name = "dict"}
	
	for k, v in pairs(input) do
		table.insert( data, {name = "key", tostring(k)} )
		table.insert( data, {name = xmlTypes[type(v)], v} )
	end
	
	return data
end

function ufo.plist(input)
	if type(input) ~= "table" then error("Expected table") end
	
	local data = {
		name = "plist",
		attr = {version = "1.0"},
		unpack(input),
	}
	
	return data
end

return ufo