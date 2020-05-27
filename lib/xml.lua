--[[
	
	XML lib
	by Dante van Gemert
	
	Converts:
		- lua tables to XML
		- XML output from xml2lua to lua tables
	
]]--

local xml = {}



-- XML TO LUA

xml.input = {}

function xml.input.string(input)
	return input[1]
end

function xml.input.integer(input)
	return tonumber(input[1])
end

function xml.input.array(input)
	local array = {}
	
	for i = 1, #input do
		table.insert( array, xml.input( input[i] ) )
	end
	
	return array
end

function xml.input.dict(input)
	local dict = {}
	
	for i = 1, #input, 2 do
		dict[ input[i][1] ] = xml.input( input[i+1] )
	end
	
	return dict
end

function xml.input.plist(input)
	local plist = {}
	
	table.insert( plist, xml.input( input._children[1] ) )
	
	return plist
end

setmetatable( xml.input, {__call = function( _, input )
	if not xml.input[input._name] then error("Incompatible xml element: "..input._name) end
	return xml.input[input._name](input)
end} )

--[[ function xml.input.string(input)
	return input._children[1]._text
end

function xml.input.integer(input)
	return input._children[1]._text
end

function xml.input.array(input)
	local array = {}
	
	for i = 1, #input._children do
		table.insert( array, xml.input( input._children[i] ) )
	end
	
	return array
end

function xml.input.dict(input)
	local dict = {}
	
	for i = 1, #input._children, 2 do
		dict[ input._children[i]._children[1]._text ] = xml.input( input._children[i+1] )
	end
	
	return dict
end

function xml.input.plist(input)
	local plist = {}
	
	table.insert( plist, xml.input( input._children[1] ) )
	
	return plist
end

setmetatable( xml.input, {__call = function( _, input )
	if not xml.input[input._name] then error("Incompatible xml element: "..input._name) end
	return xml.input[input._name](input)
end} ) ]]



-- LUA TO XML

xml.output = {}

xml.output.types = {
	string = "string",
	number = "integer",
}

local function tag( name, attr )
	local s = "<"..name
	for k, v in pairs( attr or {} ) do
		s = s.." "..tostring(k)..'="'..tostring(v)..'"'
	end
	return s..">"
end

function xml.output.toString( data, level )
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

function xml.output.array( input, attr, xmlType )
	if type(input) ~= "table" then error("Expected table") end
	
	local data = {
		name = "array",
		attr = attr,
	}
	
	for _, v in ipairs(input) do
		table.insert( data, {name = xmlType, v} )
	end
	
	return data
end

function xml.output.dict( input, attr )
	if type(input) ~= "table" then error("Expected table") end
	
	local data = {
		name = "dict",
		attr = attr,
	}
	
	for k, v in pairs(input) do
		table.insert( data, {name = "key", tostring(k)} )
		table.insert( data, {name = xml.output.types[type(v)], v} )
	end
	
	return data
end

function xml.output.plist( input, attr )
	if type(input) ~= "table" then error("Expected table") end
	
	local data = {
		name = "plist",
		attr = attr,
		unpack(input),
	}
	
	return data
end



-- RETURN

return xml