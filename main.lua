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

function love.load()
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
	local glyphsList = gui:scrollgroup( nil, {0, 0, 50, love.graphics.getHeight()} )
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
		end
		table.insert( glyphButtons, glyphButton )
	end
end

function love.update(dt)
	require("lib/lovebird").update()
	gui:update(dt)
end

function love.draw()
	gui:draw()
	
	if fnt then
		love.graphics.draw( selectedGlyph.image, 100, 0 )
	end
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
end
function love.mousereleased( x, y, btn )
	gui:mouserelease( x, y, btn )
end
function love.wheelmoved( x, y )
	gui:mousewheel( x, y )
end