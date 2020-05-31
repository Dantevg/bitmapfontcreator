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

local font = require "font"
local gui

-- local fnt, selectedGlyph, selectedLayer
glyphListWidth = 100
local scale = 50
local canvasPos = {}
canvasPos.x = function() return glyphListWidth+16 end
canvasPos.y = function() return 0 end
canvasPos.w = function() return love.graphics.getWidth() - canvasPos.x() - 200 end
canvasPos.h = function() return love.graphics.getHeight() - 50 end
canvasPos.x2 = function() return canvasPos.x() + canvasPos.w() end
canvasPos.y2 = function() return canvasPos.y() + canvasPos.h() end

local draggingAdvanceLine = false

function round(val) -- Round X.5 towards positive infinity
	return val + 0.5 - (val+0.5) % 1 -- equal to math.floor(val+0.5), but faster
end

function love.load()
	love.graphics.setDefaultFilter( "nearest", "nearest" ) -- Prevent blurry glyph scaling
	
	-- Load default font
	fnt = font({family = "test"})
	fnt.author = "nl.dantevg"
	
	-- Select default characters
	selectedLayer = fnt.layers[1]
	selectedGlyph = selectedLayer.glyphs[1]
	
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
	
	-- Draw glyph background
	love.graphics.setColor( 0, 0, 0 )
	love.graphics.rectangle( "fill", glyphListWidth+16, 0,
		selectedGlyph.width*math.floor(scale),
		selectedGlyph.height*math.floor(scale) )
	
	-- Draw glyph
	love.graphics.setColor( 1, 1, 1 )
	love.graphics.draw( selectedGlyph:getImage(), glyphListWidth+16, 0, 0, math.floor(scale), math.floor(scale) )
	
	-- Draw pixel aligned lines
	love.graphics.setColor( 0.3, 0.3, 0.3, 0.5 )
	for x = canvasPos.x()+math.floor(scale), canvasPos.x2(), math.floor(scale) do
		love.graphics.line( x, canvasPos.y(), x, canvasPos.y2() )
	end
	for y = canvasPos.y()+math.floor(scale), canvasPos.y2(), math.floor(scale) do
		love.graphics.line( canvasPos.x(), y, canvasPos.x2(), y )
	end
	
	-- Draw glyph advance line
	love.graphics.setColor( 0, 0.3, 0.5 )
	love.graphics.line( canvasPos.x()+selectedGlyph.advance*math.floor(scale), canvasPos.y(),
		canvasPos.x()+selectedGlyph.advance*math.floor(scale), canvasPos.y2() )
	
	-- Draw font preview
	love.graphics.setColor( 1, 1, 1 )
	local sentence = "The quick brown fox jumps over the lazy dog."
	local x = glyphListWidth+21
	for i = 1, #sentence do
		local glyph = fnt:getGlyph( selectedLayer, require("utf8").codepoint(sentence,i,i) )
		love.graphics.draw( glyph:getImage(), x, love.graphics.getHeight()-70, 0, 2, 2 )
		x = x+glyph.advance*2
	end
	
	gui:draw()
end

-- Convert screen coordinates to canvas coordinates
function toCanvasCoords( x, y )
	local insideX = (x >= canvasPos.x() and x < canvasPos.x2())
	local insideY = (y >= canvasPos.y() and y < canvasPos.y2())
	return x-canvasPos.x(), y-canvasPos.y(), (insideX and insideY)
end

-- Convert screen coordinates to glyph image coordinates
function toGlyphCoords( x, y )
	x = (x-canvasPos.x()) / math.floor(scale)
	y = (y-canvasPos.y()) / math.floor(scale)
	local insideX = (x >= 0 and x < selectedGlyph.width)
	local insideY = (y >= 0 and y < selectedGlyph.height)
	return x, y, (insideX and insideY)
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
	
	local _, _, inside = toCanvasCoords( x, y )
	
	if inside then -- Click within canvas boundaries
		if math.abs( canvasPos.x() + selectedGlyph.advance*math.floor(scale) - x ) < 10 then
			draggingAdvanceLine = true
		else -- Draw and update previews
			x, y = toGlyphCoords( x, y )
			selectedGlyph:setPixel( x, y, btn==1 )
			updatePreviews()
		end
	end
end

function love.mousereleased( x, y, btn )
	gui:mouserelease( x, y, btn )
	
	draggingAdvanceLine = false
end

function love.wheelmoved( x, y )
	gui:mousewheel( x, y )
	
	-- Zoom if mouse isn't over GUI
	if love.mouse.getX() > canvasPos.x() and love.mouse.getX() < canvasPos.x2()
			and love.mouse.getY() > canvasPos.y() and love.mouse.getY() < canvasPos.y2() then
		scale = math.min( math.max( 1, scale + y*scale*0.05 ), 100 )
	end
end

function love.mousemoved( x, y )
	local _, _, inside = toCanvasCoords( x, y )
	
	if draggingAdvanceLine or (inside and math.abs( canvasPos.x() + selectedGlyph.advance*math.floor(scale) - x ) < 10) then
		love.mouse.setCursor( love.mouse.getSystemCursor("sizewe") )
	else
		love.mouse.setCursor( love.mouse.getSystemCursor("arrow") )
	end
	
	x, y = toGlyphCoords( x, y )
	
	if draggingAdvanceLine then
		selectedGlyph.advance = round(x)
	else -- Drag draw if mouse is within canvas boundaries
		if inside and love.mouse.isDown(1) and not draggingAdvanceLine then
			selectedGlyph:setPixel( x, y, true )
			updatePreviews()
		elseif inside and love.mouse.isDown(2) and not draggingAdvanceLine then
			selectedGlyph:setPixel( x, y, false )
			updatePreviews()
		end
	end
end

function love.resize()
	package.loaded.ui = nil -- "unload" ui
	gui = require "ui" -- reload ui
	updatePreviews(true)
end

function love.directorydropped(path)
	fnt = font.load(path)
	
	selectedLayer = fnt.layers[1]
	selectedGlyph = selectedLayer.glyphs[1]
	
	package.loaded.ui = nil -- "unload" ui
	gui = require "ui" -- reload ui
	updatePreviews(true)
end