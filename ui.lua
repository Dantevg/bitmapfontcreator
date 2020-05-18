--[[
	
	GUI builder
	by Dante van Gemert
	
	This file generates the GUI
	
]]--

local gui = require("lib/Gspot"):setComponentMax(255)





-- ACTIONS (bottom)

local actionsList = gui:group( "Actions", {65, love.graphics.getHeight()-50, love.graphics.getWidth()-200-65, 50} )
actionsList:setfont(12)
local loadFontButton = gui:button( "Load", {0, 0, 100, 50}, actionsList )
local saveFontButton = gui:button( "Save", {110, 0, 100, 50}, actionsList )

loadFontButton.click = function(self)
	
end

saveFontButton.click = function(self)
	fnt:save("fnt")
end





-- FONT OPTIONS (top right)

local fontOptionsList = gui:group( "Font options", {love.graphics.getWidth()-200, 0, 200, love.graphics.getHeight()/2} )
fontOptionsList:setfont(12)
local y = 20

local function addFontOptionElement( location, label )
	local input = gui:input( label or location, {0, y, 200, 20}, fontOptionsList, fnt[location] )
	input.done = function(self)
		fnt[location] = self.value
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

local glyphOptionsList = gui:group( "Glyph options", {love.graphics.getWidth()-200, love.graphics.getHeight()/2, 200, love.graphics.getHeight()/2} )
glyphOptionsList:setfont(12)
y = 20

local function addGlyphOptionElement( location, label, value )
	local input = gui:input( label or location, {0, y, 200, 20}, glyphOptionsList, value )
	input.done = function(self)
		selectedGlyph[location] = tonumber(self.value)
		if self.label == "width" or self.label == "height" then
			selectedGlyph:resize()
		end
		self.Gspot:unfocus()
	end
	input.keypress = function( self, key, code )
		self.Gspot[self.elementtype].keypress( self, key, code )
		self.value = self.value:gsub("%D+", "") -- Remove all non-number characters
	end
	y = y+30
end

addGlyphOptionElement( "width", nil, 1 )
addGlyphOptionElement( "height", nil, 1 )
addGlyphOptionElement( "advance", nil, 1 )





-- GLYPHS (left)

local glyphsList = gui:scrollgroup( nil, {0, 0, 50, love.graphics.getHeight()}, nil, "vertical" )
glyphsList.scrollv.style.hs = "auto"
glyphsList:setfont(24)
local glyphButtons = {}

for i = 32, 126 do
	local glyphButton = gui:button( string.char(i), {0, (i-32)*50, 50, 50}, glyphsList )
	glyphButton.click = function(self, x, y, button)
		if not fnt then return end
		switchGlyph(self.label)
		
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
			option.value = tostring( selectedGlyph[option.label] )
		end
	end
	table.insert( glyphButtons, glyphButton )
end





-- RETURN

return gui