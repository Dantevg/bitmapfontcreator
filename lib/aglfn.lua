--[[
	
	AGLFN file reader and utility lib
	by Dante van Gemert
	
	This file reads res/aglfn.txt
	and provides functions for converting between
	unicode code points, AGLFN names and characters
	
]]--

local aglfn = {}

aglfn.codepoints = {}
aglfn.names = {}

local file, err = love.filesystem.newFile( "res/aglfn.txt", "r" )
if not file then error("Could not open res/aglfn.txt: "..err) end

for line in file:lines() do
	if line:sub(1,1) ~= "#" then -- Ignore comments
		local codepoint = tonumber( line:sub(1,4), 16 )
		local name = line:sub(6):match("[^;]+")
		aglfn.codepoints[name] = codepoint
		aglfn.names[codepoint] = name
	end
end

function aglfn.getName(codepointOrChar)
	local codepoint = codepointOrChar
	if type(codepointOrChar) == "string" then
		codepoint = string.byte(codepointOrChar)
	end
	
	return aglfn.names[codepoint]
end

function aglfn.getCodepoint(nameOrChar)
	if aglfn.codepoints[nameOrChar] then
		return aglfn.codepoints[nameOrChar]
	elseif #nameOrChar > 1 then
		error("Invalid char name: "..nameOrChar)
	else
		return string.byte(nameOrChar)
	end
end

function aglfn.getChar(codepointOrName)
	local codepoint = codepointOrName
	if type(codepointOrName) == "string" then
		codepoint = aglfn.codepoints[codepointOrName]
	end
	
	return string.char(codepoint)
end

return aglfn