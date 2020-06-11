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
		xOffset = 0,
		yOffset = 0,
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
		xOffset = 0,
		yOffset = 0,
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
	
	-- Insert contours of own individual pixels
	self.imageData:mapPixel(function( x, y, v, ... )
		if v == 1 then
			table.insert( contours, {
				name = "contour",
				{ name = "point", attr = {x = (x+self.xOffset)*scale,   y = (y+self.yOffset)*scale,   type="line"} },
				{ name = "point", attr = {x = (x+self.xOffset+1)*scale, y = (y+self.yOffset)*scale,   type="line"} },
				{ name = "point", attr = {x = (x+self.xOffset+1)*scale, y = (y+self.yOffset+1)*scale, type="line"} },
				{ name = "point", attr = {x = (x+self.xOffset)*scale,   y = (y+self.yOffset+1)*scale, type="line"} },
			} )
		end
		
		return v, ... -- Return original colour, as ImageData:mapPixel expects it
	end)
	
	-- Insert component glyphs
	for _, component in ipairs(self.components) do
		table.insert( contours, {
			name = "component",
			attr = {
				base = component.glyph.name,
				xOffset = component.x*scale,
				yOffset = component.y*scale,
			}
		} )
	end
	
	return contours
end

-- Set the pixel at position (x,y) to value
function glyph:setPixel( x, y, value )
	x, y = math.floor(x), math.floor(y)
	if not value and (x >= self.width or y >= self.height) then return end
	-- if x < 0 or y < 0 then return end
	
	self:autoresize( x, y ) -- Auto resize if pixel was out of range
	self.imageData:setPixel( x-self.xOffset, y-self.yOffset, unpack(value and {1,1,1,1} or {0,0,0,0}) )
	self:autoresize()
	
	self:regenerateImages() -- To regenerate the image for drawing
end

-- Save glyph as png to proper location
function glyph:saveImage(path)
	self.imageData:encode( "png", path.."/"..ufo.convertToFilename(self.name)..".png" )
end

-- Remove cached images to signal regeneration when needed
function glyph:regenerateImages()
	self.images = {}
	self.image = nil
end

-- Returns a clean version of the glyph (without component glyphs)
function glyph:getCleanImage()
	if not self.image then
		self.image = love.graphics.newImage(self.imageData)
	end
	return self.image
end

-- Updates the (possibly scaled up) image if necessary, and returns it
function glyph:getImage(scale)
	scale = scale or 1
	
	if not self.images[scale] then
		local canvas = love.graphics.newCanvas( self.width*scale, self.height*scale )
		canvas:renderTo(function()
			love.graphics.draw( self:getCleanImage(), 0, self.height*scale, 0, scale, -scale )
			for _, component in ipairs(self.components) do
				love.graphics.setColor( component.colour )
				local x = component.x and component.x*scale or 0
				local y = component.y and (self.height - component.y - component.glyph.height)*scale or 0
				love.graphics.draw( component.glyph:getImage(), x, y, 0, scale, scale )
			end
			love.graphics.setColor( 1, 1, 1 )
		end)
		self.images[scale] = love.graphics.newImage( canvas:newImageData() )
	end
	
	return self.images[scale]
end

-- Resizes the glyph without losing the contents
function glyph:resize( x, y, width, height )
	width, height = width or self.width, height or self.height
	x, y = x or 0, y or 0
	if width == self.width and height == self.height and x == 0 and y == 0 then return end
	
	local canvas = love.graphics.newCanvas( width, height )
	canvas:renderTo(function()
		love.graphics.draw( self:getCleanImage(), self.xOffset-x, self.yOffset-y )
	end)
	self.width, self.height = width, height
	self.xOffset, self.yOffset = x, y
	self.imageData = canvas:newImageData()
	self:regenerateImages()
	
	print("[INFO] Resized glyph "..self.name.." to "..self.width..", "..self.height.." with offset "..self.xOffset..", "..self.yOffset)
end

-- Resize glyph to fit contents
function glyph:autoresize( x, y )
	local minX, minY = x or 0, y or 0
	local maxX, maxY = x or 0, y or 0
	self.imageData:mapPixel(function( x, y, r, g, b, ... )
		if r ~= 0 and g ~= 0 and b ~= 0 then
			minX, minY = math.min( minX, x+self.xOffset ), math.min( minY, y+self.yOffset )
			maxX, maxY = math.max( maxX, x+self.xOffset ), math.max( maxY, y+self.yOffset )
		end
		return r, g, b, ...
	end)
	for _, component in ipairs(self.components) do
		minX = math.min( minX, component.x )
		minY = math.min( minY, component.y )
		maxX = math.max( maxX, component.x + component.glyph.width )
		maxY = math.max( maxY, component.y + component.glyph.height )
	end
	self:resize( minX, minY, maxX-minX+1, maxY-minY+1 )
end

local function randomColour()
	return {
		0.5 + math.random(10)/20,
		0.5 + math.random(10)/20,
		0.5 + math.random(10)/20,
	}
end

function glyph:addComponent( glyph, x, y )
	-- Prevent adding component which has self as component
	for _, component in ipairs(glyph.components) do
		if component.glyph == self then
			print("[INFO] Couldn't add component: component already contains self")
			return false, "Component already contains self, infinite recursion detected"
		end
	end
	table.insert( glyph.isComponentOf, self )
	table.insert( self.components, {glyph = glyph, x = x, y = y, colour = randomColour()} )
	print("[INFO] Added component glyph "..glyph.name.." to "..self.name)
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
					print("[INFO] Removed component "..glyph.name)
					return true -- Remove successful
				end
			end
			
			print("[WARN] Couldn't remove self from component's ("..glyph.name..") list")
			return false
			
		end
	end
	
	-- Component wasn't present, can't remove
	print("[WARN] Couldn't remove component "..glyph.name)
	return false
end



-- RETURN
return setmetatable( glyph, {
	__call = function( _, ... )
		return glyph.new(...)
	end
} )