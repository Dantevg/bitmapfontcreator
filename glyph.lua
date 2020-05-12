--[[
	
	Glyph lib
	by Dante van Gemert
	
]]--

local glyph = {}

function glyph.new(options)
	if not options then error("Expected options") end
	local imageData = options.imageData or love.image.newImageData( options.width, options.height, "r8" )
	return setmetatable( {
		name = options.name,
		unicode = options.unicode,
		width = options.width or imageData:getWidth(),
		height = options.height or imageData:getHeight(),
		advance = options.advance,
		imageData = imageData,
		image = love.graphics.newImage(imageData),
	}, {__index = glyph} )
end

-- Returns the contours of the glyph, pixel by pixel
-- TODO: optimize
function glyph:getContours()
	local contours = {}
	
	self.imageData:mapPixel(function( x, y, v )
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
	
	self.imageData:setPixel( x, y, value and 1 or 0 )
	
	self.image = nil -- To regenerate the image for drawing
end

-- Save glyph as png to proper location
function glyph:saveImage(path)
	self.imageData:encode( "png", path.."/"..ufo.convertToFilename(self.name)..".png" )
end



-- RETURN
return setmetatable( glyph, {
	__call = function( _, ... )
		return glyph.new(...)
	end
} )