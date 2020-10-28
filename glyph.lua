--[[
	
	Glyph lib
	by Dante van Gemert
	
]]--

local aglfn = require "lib/aglfn"
local binding = require "lib/binding"

local glyph = {}

function glyph.new(options)
	if not options then error("Expected options") end
	if not options.unicode and not options.name and not options.char then
		error("Expected unicode or name or char")
	end
	
	options.width, options.height = math.max(options.width or 1, 1), math.max(options.height or 1, 1)
	local imageData = options.imageData or love.image.newImageData( options.width, options.height )
	local unicode = options.unicode or aglfn.getCodepoint( options.name or options.char )
	
	local g = setmetatable( {
		char = options.char or aglfn.getChar(unicode),
		name = options.name or aglfn.getName(unicode),
		unicode = unicode,
		width = options.width,
		height = options.height,
		advance = options.advance or function(self) return self.xOffset + self.imageData:getWidth()+1 end,
		xOffset = 0,
		yOffset = 0,
		components = {},
		isComponentOf = {},
		imageData = imageData,
		images = {},
	}, {__index = glyph} )
	
	if options.outline then
		g:outlineToImage(options.outline)
	end
	
	return binding(g)
end

function glyph.newCombining(options)
	if not options then error("Expected options") end
	if not options.name then error("Expected name") end
	
	options.width, options.height = math.max(options.width or 1, 1), math.max(options.height or 1, 1)
	local imageData = options.imageData or love.image.newImageData( options.width, options.height )
	
	local g = setmetatable( {
		name = options.name,
		width = options.width,
		height = options.height,
		advance = options.advance or function(self) return self.xOffset + self.imageData:getWidth()+1 end,
		xOffset = 0,
		yOffset = 0,
		components = {},
		isComponentOf = {},
		imageData = imageData,
		images = {},
	}, {__index = glyph} )
	
	if options.outline and not options.imageData then
		g:outlineToImage(options.outline)
	end
	
	return binding(g)
end

-- Returns whether the coordinates are within the glyph
function glyph:within( x, y )
	return x-self.xOffset < self.width and y-self.yOffset < self.height
			and x-self.xOffset >= 0 and y-self.yOffset >= 0
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

function glyph:outlineToImage(outline)
	local canvas = love.graphics.newCanvas( self.width, self.height )
	canvas:renderTo(function()
		love.graphics.setColor( 1, 1, 1, 1 )
		for j, contour in ipairs(outline) do
			if #contour == 0 then print(self.name, j) end
			local triangles = love.math.triangulate(contour)
			for i = 1, #triangles do
				love.graphics.polygon( "fill", triangles[i] )
			end
		end
	end)
	self.imageData = canvas:newImageData()
end

-- Set the pixel at position (x,y) to value
function glyph:setPixel( x, y, value )
	x, y = math.floor(x), math.floor(y)
	if not value and not self:within( x, y ) then return end
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
	x, y = x or self.xOffset, y or self.yOffset
	
	-- No change, don't resize
	if width == self.width and height == self.height and x == self.xOffset and y == self.yOffset then return end
	
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

-- like math.min/max for 2 elements, but also accepts nil as first argument
local function min2( a, b )
	return a and math.min( a, b ) or b
end
local function max2( a, b )
	return a and math.max( a, b ) or b
end

-- Resize glyph to fit contents
function glyph:autoresize( x, y )
	local minX, maxX, minY, maxY = x, x, y, y
	
	-- Find bounds in own image
	self.imageData:mapPixel(function( x, y, r, g, b, ... )
		if r ~= 0 and g ~= 0 and b ~= 0 then
			minX = min2( minX, x+self.xOffset )
			maxX = max2( maxX, x+self.xOffset )
			minY = min2( minY, y+self.yOffset )
			maxY = max2( maxY, y+self.yOffset )
		end
		return r, g, b, ...
	end)
	
	-- Expand to fit components
	for _, component in ipairs(self.components) do
		minX = min2( minX, component.x )
		minY = min2( minY, component.y )
		maxX = max2( maxX, component.x + component.glyph.width )
		maxY = max2( maxY, component.y + component.glyph.height )
	end
	
	minX, minY, maxX, maxY = minX or 0, minY or 0, maxX or 0, maxY or 0
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
	table.insert( self.components, binding{glyph = glyph, x = x, y = y, colour = randomColour()} )
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