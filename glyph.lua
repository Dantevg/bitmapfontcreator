--[[
	
	Glyph lib
	by Dante van Gemert
	
]]--

local aglfn = require "lib/aglfn"

local glyph = {}

function glyph.new(options)
	if not options then error("Expected options") end
	local imageData = options.imageData or love.image.newImageData( options.width, options.height )
	local unicode = options.unicode or aglfn.getCodepoint( options.name or options.char )
	
	return setmetatable( {
		char = options.char or aglfn.getChar(unicode),
		name = options.name or aglfn.getName(unicode),
		unicode = unicode,
		width = options.width or imageData:getWidth(),
		height = options.height or imageData:getHeight(),
		advance = options.advance or (options.width or imageData:getWidth())+1,
		imageData = imageData,
		images = {},
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
	
	self.imageData:setPixel( x, y, unpack(value and {1,1,1,1} or {0,0,0,0}) )
	
	self.images = {} -- To regenerate the image for drawing
end

-- Save glyph as png to proper location
function glyph:saveImage(path)
	self.imageData:encode( "png", path.."/"..ufo.convertToFilename(self.name)..".png" )
end

-- Updates the (possibly scaled up) image if necessary, and returns it
function glyph:getImage(scale)
	scale = scale or 1
	
	if not self.images[scale] and scale == 1 then
		self.images[scale] = love.graphics.newImage(self.imageData)
	elseif not self.images[scale] then
		local canvas = love.graphics.newCanvas( self.imageData:getWidth()*scale, self.imageData:getHeight()*scale )
		canvas:renderTo(function()
			love.graphics.draw( self:getImage(), 0, 0, 0, scale, scale )
		end)
		self.images[scale] = love.graphics.newImage( canvas:newImageData() )
	end
	
	return self.images[scale]
end

-- Resizes the glyph without losing the contents
function glyph:resize( width, height )
	width, height = width or self.width, height or self.height
	self.width, self.height = width, height
	local canvas = love.graphics.newCanvas( width or self.width, height or self.height )
	canvas:renderTo(function()
		love.graphics.draw( self:getImage() )
	end)
	self.imageData = canvas:newImageData()
	self.images = {}
end



-- RETURN
return setmetatable( glyph, {
	__call = function( _, ... )
		return glyph.new(...)
	end
} )