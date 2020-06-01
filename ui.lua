--[[
	
	GUI builder
	by Dante van Gemert
	
	This file generates the GUI
	
]]--

local gui = require("lib/Gspot"):setComponentMax(255)

function updatePreviews() end





-- ACTIONS (bottom)

local actionsList = gui:group( "Actions", {
	glyphListWidth+16, love.graphics.getHeight()-50, 
	love.graphics.getWidth()-200-glyphListWidth-16, 50
} )
actionsList:setfont(12)
local loadFontButton = gui:button( "Load", {0, 0, 100, 50}, actionsList )
local saveFontButton = gui:button( "Save", {110, 0, 100, 50}, actionsList )
local compileFontButton = gui:button( "Compile", {220, 0, 100, 50}, actionsList )

loadFontButton.click = function(self)
	print("Load font")
end

saveFontButton.click = function(self)
	io.write("Saving font... ")
	fnt:save()
	io.write("Done.\n")
end

compileFontButton.click = function(self)
	print("Compile font")
	-- local fontmakePath = love.filesystem.getSource().."/fontmake/fontmake.pyz"
	local path = love.filesystem.getSaveDirectory().."/"..fnt.family
	if not love.filesystem.getInfo(path) then -- Path doesn't exist, save font first
		io.write("Saving font... ")
		fnt:save()
		io.write("Done.\n")
	end
	local command = "fontmake -u "..path..".ufo --output-path "..path..".ttf"
	print("Executing "..command..":\n")
	os.execute(command)
	print("\nDone.")
end





-- FONT OPTIONS (top right)

local fontOptionsList = gui:group( "Font options", {love.graphics.getWidth()-200, 0, 200, love.graphics.getHeight()/2} )
fontOptionsList:setfont(12)
local y = 20

local function addFontOptionElement( location, label )
	local input = gui:input( label or location, {0, y, 200, 20}, fontOptionsList, fnt[location] )
	input.done = function(self)
		fnt[location] = self.value
		print("Set font."..location.." to "..self.value)
		self.Gspot:unfocus()
	end
	y = y+30
end

addFontOptionElement("family", "family name")
addFontOptionElement("author")
addFontOptionElement("style", "variant")
addFontOptionElement("version")
addFontOptionElement("year")
addFontOptionElement("copyright")
addFontOptionElement("trademark")





-- GLYPH OPTIONS (bottom right)

local glyphOptionsList = gui:group( "Glyph options", {
	love.graphics.getWidth()-200, love.graphics.getHeight()/2,
	200,                          love.graphics.getHeight()/2
} )
glyphOptionsList:setfont(12)
y = 20

local function addGlyphOptionElement( location, label, value )
	local input = gui:input( label or location, {0, y, 200, 20}, glyphOptionsList, value )
	input.done = function(self)
		print("Set glyph."..location.." to "..self.value)
		selectedGlyph[location] = tonumber(self.value)
		if self.label == "width" or self.label == "height" then
			selectedGlyph:resize()
			updatePreviews()
		end
		self.Gspot:unfocus()
	end
	input.keypress = function( self, key, code )
		self.Gspot[self.elementtype].keypress( self, key, code )
		self.value = self.value:gsub("%D+", "") -- Remove all non-number characters
	end
	y = y+30
end

-- addGlyphOptionElement( "width", nil, 1 )
-- addGlyphOptionElement( "height", nil, 1 )
-- addGlyphOptionElement( "advance", nil, 1 )

-- local applyToAllButton = gui:button( "Apply to all", {10, y, 180, 20}, glyphOptionsList )
-- applyToAllButton.click = function()
-- 	print("Apply glyph options to all")
-- 	for _, glyph in ipairs(selectedLayer.glyphs) do
-- 		glyph:resize( selectedGlyph.width, selectedGlyph.height )
-- 		glyph.advance = selectedGlyph.advance
-- 	end
-- end
-- y = y+30

local clearGlyphButton = gui:button( "Clear glyph", {10, y, 180, 20}, glyphOptionsList )
clearGlyphButton.click = function()
	print("Clear glyph")
	selectedGlyph.imageData:mapPixel(function() return 0, 0, 0, 0 end)
	selectedGlyph.images = {}
	updatePreviews()
end
y = y+30

local glyphPreview = gui:image( nil, {10, y}, glyphOptionsList, selectedGlyph:getImage() )
local glyphPreview2x = gui:image( nil, {10, y}, glyphOptionsList, selectedGlyph:getImage(2) )
local glyphPreview4x = gui:image( nil, {10, y}, glyphOptionsList, selectedGlyph:getImage(4) )





-- GLYPHS (left)

local glyphsList = gui:scrollgroup( nil, {0, 0, glyphListWidth, love.graphics.getHeight()}, nil, "vertical" )
glyphsList.scrollv.style.hs = "auto"
glyphsList:setfont(24)
local glyphButtons = {}
local glyphCodepoints = {}
local glyphImages = {}

for i, glyph in ipairs(selectedLayer.glyphs) do
	local glyphButton = gui:button(glyph.char, {0, (i-1)*50, 50, 50}, glyphsList )
	glyphButton.click = function(self)
		if not fnt then return end
		print("Selected glyph "..glyph.name)
		selectedGlyph = glyph
		
		-- Reset colours of other elements
		for _, btn in ipairs(glyphButtons) do
			btn.style.hilite = gui.style.hilite
			btn.style.focus = gui.style.focus
			btn.style.fg = gui.style.fg
		end
		
		-- Set this element's colour
		self.style.hilite = {255,255,255,255}
		self.style.focus = {255,255,255,255}
		self.style.fg = {0,0,0,255}
		
		-- Update glyph options
		for _, option in ipairs(glyphOptionsList.children) do
			if option.elementtype == "input" then
				option.value = tostring( selectedGlyph[option.label] )
			end
		end
		updatePreviews()
	end
	
	-- Make sure selected glyph is selected visually, at load
	if glyph == selectedGlyph then
		glyphButton:click()
	end
	
	local glyphCodepoint = gui:text( string.format("0x%X",glyph.unicode), {0, (i-1)*50+35, 50, 50}, glyphsList )
	glyphCodepoint:setfont(10)
	
	local glyphImage = gui:image( nil, {60, (i-1)*50+5, 50, 50}, glyphsList )
	table.insert( glyphButtons, glyphButton )
	glyphImages[glyph] = glyphImage
end

function updatePreviews(all)
	glyphPreview:setimage( selectedGlyph:getImage() )
	glyphPreview2x:setimage( selectedGlyph:getImage(2) )
	glyphPreview2x.pos.x = 20 + selectedGlyph.width
	glyphPreview4x:setimage( selectedGlyph:getImage(4) )
	glyphPreview4x.pos.x = 30 + selectedGlyph.width*3
	
	local maxScale = math.huge
	for _, glyph in ipairs(selectedLayer.glyphs) do
		maxScale = math.min( maxScale, 30/glyph.width, 40/glyph.height )
	end

	if all then
		for glyph, image in pairs(glyphImages) do
			image:setimage( glyph:getImage(math.floor(maxScale)) )
		end
	else
		glyphImages[selectedGlyph]:setimage( selectedGlyph:getImage(math.floor(maxScale)) )
	end
end





-- RETURN

return gui