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
local gui

-- local fnt, selectedGlyph, selectedLayer
local scale = 50

function love.load()
	love.graphics.setDefaultFilter( "nearest", "nearest" ) -- Prevent blurry glyph scaling
	
	fnt = font({family = "test"})
	fnt.author = "nl.dantevg"
	
	selectedLayer = fnt.layers[1]
	selectedGlyph = selectedLayer.glyphs[1]
	
	print("Welcome to BitmapFontCreator")
	print("============================")
	print()
	
	gui = require "ui"
end

function love.update(dt)
	require("lib/lovebird").update()
	gui:update(dt)
	
	love.window.setTitle( "Bitmapfontcreator - "..fnt.family )
end

function love.draw()
	love.graphics.clear( 0.1, 0.1, 0.1 )
	
	if fnt then
		love.graphics.draw( selectedGlyph:getImage(), 66, 0, 0, math.floor(scale), math.floor(scale) )
	end
	
	gui:draw()
end

function switchGlyph(char)
	for _, glyph in ipairs( selectedLayer.glyphs ) do
		if glyph.char == char then
			selectedGlyph = glyph
			print("Selected glyph "..selectedGlyph.name)
			break
		end
	end
end

function toCanvasCoords( x, y )
	x = math.floor((x-66)/scale)
	y = math.floor(y/scale)
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
		selectedGlyph:setPixel( x, y, btn==1 )
		updatePreview()
	end
end
function love.mousereleased( x, y, btn )
	gui:mouserelease( x, y, btn )
end
function love.wheelmoved( x, y )
	gui:mousewheel( x, y )
	
	if love.mouse.getX() > 65 and love.mouse.getX() < love.graphics.getWidth()-200
	and love.mouse.getY() < love.graphics.getHeight()-50 then
		scale = math.min( math.max( 1, scale + y*scale*0.05 ), 100 )
	end
end
function love.mousemoved( x, y )
	x, y = toCanvasCoords( x, y )
	if x and love.mouse.isDown(1) then
		selectedGlyph:setPixel( x, y, true )
		updatePreview()
	elseif x and love.mouse.isDown(2) then
		selectedGlyph:setPixel( x, y, false )
		updatePreview()
	end
end