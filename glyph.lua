--[[
	
	Glyph lib
	by Dante van Gemert
	
]]--

local aglfn = require "lib/aglfn"

local glyph = {}

function glyph.new(options)
	if not options then error("Expected options") end
	if not options.imageData and (not options.width or not options.height) then
		error("Expected imageData or width, height")
	end
	if not options.unicode and not options.name and not options.char then
		error("Expected unicode or name or char")
	end
	
	local imageData = options.imageData or love.image.newImageData( options.width, options.height )
	local unicode = options.unicode or aglfn.getCodepoint( options.name or options.char )
	
	return setmetatable( {
		char = options.char or aglfn.getChar(unicode),
		name = options.name or aglfn.getName(unicode),
		unicode = unicode,
		width = options.width or imageData:getWidth(),
		height = options.height or imageData:getHeight(),
		advance = options.advance or (options.width or imageData:getWidth())+1,
		components = {},
		isComponentOf = {},
		imageData = imageData,
		images = {},
	}, {__index = glyph} )
end

function glyph.newCombining(options)
	if not options then error("Expected options") end
	if not options.imageData and (not options.width or not options.height) then
		error("Expected imageData or width, height")
	end
	if not options.name then error("Expected name") end
	
	local imageData = options.imageData or love.image.newImageData( options.width, options.height )
	
	return setmetatable( {
		name = options.name,
		width = options.width or imageData:getWidth(),
		height = options.height or imageData:getHeight(),
		advance = options.advance or (options.width or imageData:getWidth())+1,
		components = {},
		isComponentOf = {},
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
				{ name = "point", attr = {x = x*scale,     y = y*scale,     type="line"} },
				{ name = "point", attr = {x = (x+1)*scale, y = y*scale,     type="line"} },
				{ name = "point", attr = {x = (x+1)*scale, y = (y+1)*scale, type="line"} },
				{ name = "point", attr = {x = x*scale,     y = (y+1)*scale, type="line"} },
			} )
		end
		
		return v, ... -- Return original colour, as ImageData:mapPixel expects it
	end)
	
	return contours
end

-- Set the pixel at position (x,y) to value
function glyph:setPixel( x, y, value )
	x, y = math.floor(x), math.floor(y)
	if not value and (x >= self.width or y >= self.height) then return end
	if x < 0 or y < 0 then return end
	
	self:autoresize( x, y ) -- Auto resize if pixel was out of range
	self.imageData:setPixel( x, y, unpack(value and {1,1,1,1} or {0,0,0,0}) )
	self:autoresize()
	
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
		local canvas = love.graphics.newCanvas( self.width, self.height )
		canvas:renderTo(function()
			love.graphics.draw( love.graphics.newImage(self.imageData) )
			for _, component in ipairs(self.components) do
				love.graphics.draw( component.glyph:getImage(), component.x or 0, component.y or 0 )
			end
		end)
		self.images[scale] = love.graphics.newImage( canvas:newImageData() )
	elseif not self.images[scale] then
		local canvas = love.graphics.newCanvas( self.width*scale, self.height*scale )
		canvas:renderTo(function()
			love.graphics.draw( self:getImage(), 0, self.height*scale, 0, scale, -scale )
		end)
		self.images[scale] = love.graphics.newImage( canvas:newImageData() )
	end
	
	return self.images[scale]
end

-- Resizes the glyph without losing the contents
function glyph:resize( width, height )
	width, height = width or self.width, height or self.height
	if width == self.width and height == self.height then return end
	print("Resized glyph "..self.name.." to "..width..", "..height)
	
	self.width, self.height = width, height
	local canvas = love.graphics.newCanvas( width or self.width, height or self.height )
	canvas:renderTo(function()
		love.graphics.draw( self:getImage() )
	end)
	self.imageData = canvas:newImageData()
	self.images = {}
end

-- Resize glyph to fit contents
function glyph:autoresize( x, y )
	local maxX, maxY = x or 0, y or 0
	self.imageData:mapPixel(function( x, y, v, ... )
		if v == 1 then
			maxX, maxY = math.max( maxX, x ), math.max( maxY, y )
		end
		return v, ...
	end)
	for _, component in ipairs(self.components) do
		maxX = math.max( maxX, component.x + component.glyph.width )
		maxY = math.max( maxY, component.y + component.glyph.height )
	end
	self:resize( maxX+1, maxY+1 )
end

function glyph:addComponent( glyph, x, y )
	-- Prevent adding component which has self as component
	for _, component in ipairs(glyph.components) do
		if component.glyph == self then
			return false, "Component already contains self, infinite recursion detected"
		end
	end
	table.insert( glyph.isComponentOf, self )
	table.insert( self.components, {glyph = glyph, x = x, y = y} )
	print("Added component glyph "..glyph.name.." to "..self.name)
	return true
end

function glyph:removeComponent(glyph)
	-- Remove component from self list
	for i, component in ipairs(self.components) do
		if component.glyph == glyph then
			table.remove( self.components, i )
			
			-- Remove self from isComponentOf list
			for i = 1, #glyph.isComponentOf do
				if glyph.isComponentOf[i] == self then
					table.remove( glyph.isComponentOf, i )
					print("Removed component "..glyph.name)
					return true -- Remove successful
				end
			end
			
			print("Couldn't remove self from component's ("..glyph.name..") list")
			return false
			
		end
	end
	
	-- Component wasn't present, can't remove
	print("Couldn't remove component "..glyph.name)
	return false
end



-- RETURN
return setmetatable( glyph, {
	__call = function( _, ... )
		return glyph.new(...)
	end
} )