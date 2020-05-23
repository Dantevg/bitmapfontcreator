--[[
	
	Glyph lib
	by Dante van Gemert
	
]]--

local aglfn = require "lib/aglfn"

local glyph = {}

function glyph.new(options)
	if not options then error("Expected options") end
	local imageData = options.imageData or love.image.newImageData( options.width, options.height )
	imageData:mapPixel(function() return 0, 0, 0 end)
	
	local unicode = options.unicode or aglfn.getCodepoint( options.name or options.char )
	return setmetatable( {
		char = options.char or aglfn.getChar(unicode),
		name = options.name or aglfn.getName(unicode),
		unicode = unicode,
		width = options.width or imageData:getWidth(),
		height = options.height or imageData:getHeight(),
		advance = options.advance or (options.width or imageData:getWidth())+1,
		imageData = imageData,
		image = love.graphics.newImage(imageData),
	}, {__index = glyph} )
end

-- Returns the contours of the glyph, pixel by pixel
-- TODO: optimize
function glyph:getContours(scale)
	local contours = {}
	
	self.imageData:mapPixel(function( x, y, v, ... )
		if v == 1 then
			table.insert( contours, {
				name = "contour",
				{ name = "point", attr = {x=x*scale,     y=y*scale,     type="line"} },
				{ name = "point", attr = {x=(x+1)*scale, y=y*scale,     type="line"} },
				{ name = "point", attr = {x=(x+1)*scale, y=(y+1)*scale, type="line"} },
				{ name = "point", attr = {x=x*scale,     y=(y+1)*scale, type="line"} },
			} )
		end
		
		return v, ... -- Return original colour, as ImageData:mapPixel expects it
	end)
	
	return contours
end

-- Set the pixel at position (x,y) to value
function glyph:setPixel( x, y, value )
	if x < 0 or x >= self.width or y < 0 or y >= self.height then
		error("Coordinates out of range: ("..x..","..y..") does not fit in ("..self.width..","..self.height..")")
	end
	
	self.imageData:setPixel( x, y, unpack(value and {1,1,1} or {0,0,0}) )
	
	self.image = nil -- To regenerate the image for drawing
end

-- Save glyph as png to proper location
function glyph:saveImage(path)
	self.imageData:encode( "png", path.."/"..ufo.convertToFilename(self.name)..".png" )
end

-- Updates the image if necessary, and returns it
function glyph:getImage()
	if not self.image then
		self.image = love.graphics.newImage(self.imageData)
	end
	return self.image
end

-- Resizes the glyph without losing the contents
function glyph:resize( width, height )
	width, height = width or self.width, height or self.height
	
	local newImageData = love.image.newImageData( width, height )
	newImageData:mapPixel(function( x, y )
		if x < self.imageData:getWidth() and y < self.imageData:getHeight() then
			return self.imageData:getPixel(x,y)
		else
			return 0, 0, 0
		end
	end)
	
	self.width, self.height = width, height
	self.imageData = newImageData
	self.image = nil
end



-- RETURN
return setmetatable( glyph, {
	__call = function( _, ... )
		return glyph.new(...)
	end
} )