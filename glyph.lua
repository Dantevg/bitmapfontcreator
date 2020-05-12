--[[
	
	Glyph lib
	by Dante van Gemert
	
]]--

local glyph = {}

function glyph.new(options)
	if not options then error("Expected options") end
	return setmetatable( {
		name = options.name,
		unicode = options.unicode,
		width = options.width,
		height = options.height,
		advance = options.advance,
		image = options.image or love.image.newImageData( options.width, options.height, "r8" ),
	}, {__index = glyph} )
end

-- Returns the contours of the glyph, pixel by pixel
-- TODO: optimize
function glyph:getContours()
	local contours = {}
	
	self.image:mapPixel(function( x, y, v )
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
	if x < 0 or x >= self.width or y < 0 or y >= self.width then
		error("Coordinates out of range: ("..x..","..y..") does not fit in ("..self.width..","..self.height..")")
	end
	
	self.image:setPixel( x, y, value and 1 or 0 )
end

-- Save glyph as png to proper location
function glyph:save(path)
	self.image:encode( "png", path.."/"..ufo.convertToFilename(self.name)..".png" )
end



-- RETURN
return setmetatable( glyph, {
	__call = function( _, ... )
		return glyph.new(...)
	end
} )