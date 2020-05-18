--[[
	
	Bitmap font creator
	by Dante van Gemert
	
	main file
	
	Project resources:
	- UFO spec: http://unifiedfontobject.org/versions/ufo3/
	- TTF info: https://scripts.sil.org/cms/scripts/page.php?site_id=nrsi&id=IWS-Chapter08
	- GUI lib: https://notabug.org/pgimeno/Gspot/wiki
	- UFO compiler: https://github.com/googlefonts/fontmake
	- Python in Lua: https://labix.org/lunatic-python
	
	- Example ufo font: https://github.com/adobe-fonts/source-sans-pro/tree/master/Roman/Instances/Regular/font.ufo
	
	To compile generated ufo font:
	1. (install googlefonts/fontmake)
	2. fontmake -u test.ufo -o ttf --output-path test.ttf
	
]]--

local xml = require "lib/xml2lua"
local font = require "font"
local gui = require("lib/Gspot"):setComponentMax(255)

local fnt, selectedGlyph, selectedLayer
local redrawGlyph = true
local scale = 50

function love.load()
	love.graphics.setDefaultFilter( "nearest", "nearest" ) -- Prevent blurry glyph scaling
	
	fnt = font({family = "My Font!"})
	fnt.author = "nl.dantevg"
	
	selectedLayer = fnt.layers[1]
	selectedGlyph = selectedLayer.glyphs[1]
	
	print("\n-----\nmetainfo.plist\n")
	print( fnt:generateXML("metainfo") )
	print("\n-----\nfontinfo.plist\n")
	print( fnt:generateXML("fontinfo") )
	print("\n-----\nlayercontents.plist\n")
	print( fnt:generateXML("layercontents") )
	print("\n-----\nglyphs/contents.plist\n")
	print( fnt:generateXML("glyphs_contents", selectedLayer) )
	
	handler = require "lib/xmlhandler/dom"
	xml.parser(handler):parse( fnt:generateXML("metainfo") )
	
	-- GUI
	local actionsList = gui:group( "Actions", {65, love.graphics.getHeight()-50, love.graphics.getWidth()-200-65, 50} )
	actionsList:setfont(12)
	local loadFontButton = gui:button( "Load", {0, 0, 100, 50}, actionsList )
	local saveFontButton = gui:button( "Save", {110, 0, 100, 50}, actionsList )
	loadFontButton.click = function(self)
		
	end
	saveFontButton.click = function(self)
		fnt:save("fnt")
	end
	
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
end

function love.update(dt)
	require("lib/lovebird").update()
	gui:update(dt)
	
	love.window.setTitle( "Bitmapfontcreator - "..fnt.family )
end

function love.draw()
	if fnt then
		love.graphics.draw( selectedGlyph:getImage(), 65, 0, 0, math.floor(scale), math.floor(scale) )
	end
	
	gui:draw()
end

function switchGlyph(char)
	for _, glyph in ipairs( selectedLayer.glyphs ) do
		if glyph.name == char then
			selectedGlyph = glyph
			break
		end
	end
end

-- Forward love2d events to Gspot GUI
function love.keypressed(key)
	gui:keypress(key)
end
function love.textinput(key)
	gui:textinput(key)
end
function love.mousepressed( x, y, btn )
	gui:mousepress( x, y, btn )
	
	x = math.floor((x-65)/scale)
	y = math.floor(y/scale)
	if x >= 0 and x < selectedGlyph.width and y < selectedGlyph.height then
		selectedGlyph:setPixel( x, y, btn==1 )
	end
end
function love.mousereleased( x, y, btn )
	gui:mouserelease( x, y, btn )
end
function love.wheelmoved( x, y )
	gui:mousewheel( x, y )
	
	scale = math.min( math.max( 1, scale + y*scale*0.05 ), 200 )
end