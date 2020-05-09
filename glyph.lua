--[[
	
	Glyph lib
	by Dante van Gemert
	
]]--

local glyph = {}

function glyph.new( width, height, advance )
	if not width or not height or not advance then error("Expected width, height, advance") end
	return setmetatable( {
		width = width,
		height = height,
		advance = advance,
		image = love.image.newImageData( width, height, "r8" ),
	}, {__index = glyph} )
end

-- Returns the contours of the glyph, pixel by pixel
-- TODO: optimize
function glyph:getContours()
	local contours = {}
	
	this.image:mapPixel(function( x, y, v )
		if v == 1 then
			table.insert( contours, {
				name = "contour",
				{ name = "point", attr = {x=x,   y=y,   type="line"} },
				{ name = "point", attr = {x=x+1, y=y,   type="line"} },
				{ name = "point", attr = {x=x+1, y=y+1, type="line"} },
				{ name = "point", attr = {x=x,   y=y+1, type="line"} },
			} )
		end
		
		return v -- Return original colour, as ImageData:mapPixel expects it
	end)
	
	return contours
end

-- Set the pixel at position (x,y) to value
function glyph:setPixel( x, y, value )
	if x < 0 or x >= this.width or y < 0 or y >= this.width then
		error("Coordinates out of range: ("..x..","..y..") does not fit in ("..this.width..","..this.height..")")
	end
	
	this.image:setPixel( x, y, value and 1 or 0 )
end



-- RETURN
return setmetatable( glyph, {
	__call = function( _, ... )
		return glyph.new(...)
	end
} )