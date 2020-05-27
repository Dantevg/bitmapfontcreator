-- XML reading function
-- Adapted from http://lua-users.org/wiki/LuaXml

local xmlread = {}

xmlread.patterns = {
	tag = "<(/?)([%w:]+)(.-)(/?)>",
	args = "([%-%w]+)=([\"'])(.-)%2",
	whitespace = "^%s*$",
}

function xmlread.parseargs(input)
	local args = {}
	for key, _, value in string.gmatch( input, xmlread.patterns.args ) do
		args[key] = value
	end
	return args
end

function xmlread.parse(input)
	local stack = {}
	local top = {}
	table.insert( stack, top )
	local i, closing, name, args, empty
	local s, e = 1, 1
	
	while true do
		i, e, closing, name, args, empty = string.find( input, xmlread.patterns.tag, s )
		if not i then break end
		local text = string.sub( input, s, i-1 )
		if not string.find( text, xmlread.patterns.whitespace ) then
			table.insert( top, text )
		end
		
		if empty == "/" then -- Empty element
			table.insert( top, { name = name, args = xmlread.parseargs(args) } )
		elseif closing == "/" then -- Ending tag
			local toclose = table.remove(stack)
			top = stack[#stack]
			if #stack < 1 then error("Nothing to close with "..name) end
			if toclose.name ~= name then error("Trying to close "..toclose.name.." with "..name) end
			table.insert( top, toclose )
		else -- Starting tag
			top = { name = name, args = xmlread.parseargs(args) }
			table.insert( stack, top )
		end
		
		s = e+1
	end
	
	local text = string.sub( input, s )
	if not string.find( text, xmlread.patterns.whitespace ) then
		table.insert( stack[#stack], text )
	end
	if #stack > 1 then
		error("Unclosed "..stack[#stack].name)
	end
	return stack[1]
end

return setmetatable( xmlread, {
	__call = function(_,...)
		xmlread.parse(...)
	end
} )