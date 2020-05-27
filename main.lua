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
	- Unicode reference: https://compart.com/en/unicode/
	
	- Example ufo font: https://github.com/adobe-fonts/source-sans-pro/tree/master/Roman/Instances/Regular/font.ufo
	
	To compile generated ufo font:
	1. (install googlefonts/fontmake)
	2. fontmake -u test.ufo -o ttf --output-path test.ttf
	
]]--

local xml = require "lib/xml2lua"
local xmlread = require "lib/xmlread"
local font = require "font"
local gui

-- local fnt, selectedGlyph, selectedLayer
glyphListWidth = 100
local scale = 50

function love.load()
	love.graphics.setDefaultFilter( "nearest", "nearest" ) -- Prevent blurry glyph scaling
	
	-- Load default font
	fnt = font({family = "test"})
	fnt.author = "nl.dantevg"
	
	-- Select default characters
	selectedLayer = fnt.layers[1]
	selectedGlyph = selectedLayer.glyphs[1]
	
	s = fnt:generateXML("metainfo", selectedLayer)
	t = xmlread.parse(s)
	
	-- Print a welcome message to the terminal
	print("Welcome to BitmapFontCreator")
	print("============================")
	print()
	
	-- Build the GUI
	gui = require "ui"
end

function love.update(dt)
	require("lib/lovebird").update()
	gui:update(dt)
	
	-- Update title to match font name
	love.window.setTitle( "Bitmapfontcreator - "..fnt.family )
end

function love.draw()
	love.graphics.clear( 0.1, 0.1, 0.1 )
	
	if fnt then
		-- Draw glyph background
		love.graphics.setColor( 0, 0, 0 )
		love.graphics.rectangle( "fill", glyphListWidth+16, 0,
			selectedGlyph.width*math.floor(scale),
			selectedGlyph.height*math.floor(scale) )
		
		-- Draw glyph
		love.graphics.setColor( 1, 1, 1 )
		love.graphics.draw( selectedGlyph:getImage(), glyphListWidth+16, 0, 0, math.floor(scale), math.floor(scale) )
		
		-- Draw font preview
		local sentence = "The quick brown fox jumps over the lazy dog."
		local x = glyphListWidth+21
		for i = 1, #sentence do
			local glyph = fnt:getGlyph( selectedLayer, require("utf8").codepoint(sentence,i,i) )
			love.graphics.draw( glyph:getImage(), x, love.graphics.getHeight()-70, 0, 2, 2 )
			x = x+glyph.advance*2
		end
	end
	
	gui:draw()
end

-- Convert screen coordinates to glyph image / canvas coordinates
function toCanvasCoords( x, y )
	x = math.floor((x-glyphListWidth-16)/math.floor(scale))
	y = math.floor(y/math.floor(scale))
	if x >= 0 and x < selectedGlyph.width and y < selectedGlyph.height then
		return x, y
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
	
	x, y = toCanvasCoords( x, y )
	if x then
		-- Clicked within canvas boundaries, draw and update previews
		selectedGlyph:setPixel( x, y, btn==1 )
		updatePreviews()
	end
end

function love.mousereleased( x, y, btn )
	gui:mouserelease( x, y, btn )
end

function love.wheelmoved( x, y )
	gui:mousewheel( x, y )
	
	-- Zoom if mouse isn't over GUI
	if love.mouse.getX() > glyphListWidth+16 and love.mouse.getX() < love.graphics.getWidth()-200
			and love.mouse.getY() < love.graphics.getHeight()-50 then
		scale = math.min( math.max( 1, scale + y*scale*0.05 ), 100 )
	end
end

function love.mousemoved( x, y )
	x, y = toCanvasCoords( x, y )
	
	-- Drag draw if mouse is within canvas boundaries
	if x and love.mouse.isDown(1) then
		selectedGlyph:setPixel( x, y, true )
		updatePreviews()
	elseif x and love.mouse.isDown(2) then
		selectedGlyph:setPixel( x, y, false )
		updatePreviews()
	end
end

function love.resize()
	package.loaded.ui = nil -- "unload" ui
	gui = require "ui" -- reload ui
	updatePreviews(true)
end