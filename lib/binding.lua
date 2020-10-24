--[[
	
	Binding proxy table lib
	by Dante van Gemert
	
	A simple Lua helper for javafx-like property bindings
	
]]--

local binding = {}

function binding.new( tbl )
	-- Create a proxy table
	local proxy = {}
	local mt = {}
	
	mt.__index = function( _, k )
		local v = rawget( tbl, k )
		if v then
			if type(v) == "function" then return v(proxy) else return v end
		elseif tbl[k] then
			return tbl[k]
		end
	end
	
	mt.__newindex = function( _, k, v )
		if type(v) == "function" then
			rawset( tbl, k, v )
		else
			rawset( tbl, k, function() return v end )
		end
	end
	
	return setmetatable( proxy, mt )
end

return setmetatable( binding, {
	__call = function(_, ...)
		return binding.new(...)
	end
} )