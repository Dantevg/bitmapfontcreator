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
local scale, scaleRound = 50, 50

local canvasPos = {}
canvasPos.x = function() return glyphListWidth+16 end
canvasPos.y = function() return 0 end
canvasPos.w = function() return love.graphics.getWidth() - canvasPos.x() - 200 end
canvasPos.h = function() return love.graphics.getHeight() - 50 end
canvasPos.x2 = function() return canvasPos.x() + canvasPos.w() end
canvasPos.y2 = function() return canvasPos.y() + canvasPos.h() end

local glyphPos = { _x=scale, _y=canvasPos.h()-scale }
glyphPos.x = function() return canvasPos.x() + glyphPos._x end
glyphPos.y = function() return canvasPos.y() + glyphPos._y end
glyphPos.w = function() return selectedGlyph.width * scaleRound end
glyphPos.h = function() return selectedGlyph.height * scaleRound end
glyphPos.x2 = function() return glyphPos.x() + glyphPos.w() end
glyphPos.y2 = function() return glyphPos.y() + glyphPos.h() end

local drawingCanvas = false
local draggingAdvanceLine = false

function round(val) -- Round X.5 towards positive infinity
	return val + 0.5 - (val+0.5) % 1 -- equal to math.floor(val+0.5), but faster
end

function love.load(args)
	love.graphics.setDefaultFilter( "nearest", "nearest" ) -- Prevent blurry glyph scaling
	
	-- Load default font
	fnt = font({family = "font"})
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
	gui.fontmakePath = args[1] or "fontmake"
	gui.load(fnt)
	
	fnt:autoCompoundGlyphs(selectedLayer)
end

function love.update(dt)
	require("lib/lovebird").update()
	gui.gspot:update(dt)
	
	-- Update title to match font name
	love.window.setTitle( "Bitmapfontcreator - "..fnt.family )
end

function love.draw()
	love.graphics.clear( 0.1, 0.1, 0.1 )
	
	-- Draw glyph
	love.graphics.setColor( 1, 1, 1 )
	love.graphics.draw( selectedGlyph:getImage(),
		glyphPos.x()+selectedGlyph.xOffset*scaleRound,
		glyphPos.y()-(selectedGlyph.yOffset+selectedGlyph.height)*scaleRound,
		0, scaleRound, scaleRound )
	
	-- Draw pixel aligned lines
	if scaleRound >= 5 then
		love.graphics.setColor( 0.5, 0.5, 0.5, 0.1 )
		for x = canvasPos.x() + (glyphPos._x % scaleRound), canvasPos.x2(), scaleRound do
			love.graphics.line( x, canvasPos.y(), x, canvasPos.y2() )
		end
		for y = canvasPos.y() + (glyphPos._y % scaleRound), canvasPos.y2(), scaleRound do
			love.graphics.line( canvasPos.x(), y, canvasPos.x2(), y )
		end
		
		love.graphics.setColor( 1, 1, 1, 0.2 )
		for x = glyphPos.x(), canvasPos.x2(), scaleRound*5 do
			love.graphics.line( x, canvasPos.y(), x, canvasPos.y2() )
		end
		for y = glyphPos.y(), canvasPos.y(), -scaleRound*5 do
			love.graphics.line( canvasPos.x(), y, canvasPos.x2(), y )
		end
	end
	
	-- Draw glyph baseline and left line
	love.graphics.setColor( 1, 1, 1 )
	love.graphics.line( canvasPos.x(), glyphPos.y(), canvasPos.x2(), glyphPos.y() )
	love.graphics.line( glyphPos.x(), canvasPos.y(), glyphPos.x(), canvasPos.y2() )
	
	-- Draw glyph advance line
	love.graphics.setColor( 0, 0.5, 1, 0.5 )
	love.graphics.line( glyphPos.x()+selectedGlyph.advance*scaleRound, canvasPos.y(),
		glyphPos.x()+selectedGlyph.advance*scaleRound, canvasPos.y2() )
	
	-- Draw font preview
	love.graphics.setColor( 1, 1, 1 )
	local sentence = "The quick brown fox jumps over the lazy dog."
	local x = canvasPos.x()+5
	for i = 1, #sentence do
		local glyph = fnt:getGlyph( selectedLayer, require("utf8").codepoint(sentence,i,i) )
		local ox = glyph.xOffset*2
		local oy = glyph.height*2 + glyph.yOffset*2
		love.graphics.draw( glyph:getImage(), x+ox, love.graphics.getHeight()-55-oy, 0, 2, 2 )
		x = x+glyph.advance*2
	end
	
	gui.gspot:draw()
	
	-- Draw component choosing overlay
	if gui.addingComponent then
		love.graphics.setColor( 0, 0, 0, 0.8 )
		love.graphics.rectangle( "fill", canvasPos.x(), 0, love.graphics.getWidth()-canvasPos.x(), love.graphics.getHeight() )
		love.graphics.setColor( 1, 1, 1 )
	end
end

-- Convert screen coordinates to canvas coordinates
function toCanvasCoords( x, y )
	local insideX = (x >= canvasPos.x() and x < canvasPos.x2())
	local insideY = (y >= canvasPos.y() and y < canvasPos.y2())
	return x-canvasPos.x(), y-canvasPos.y(), (insideX and insideY)
end

-- Convert screen coordinates to glyph image coordinates
function toGlyphCoords( x, y )
	x = (x-glyphPos.x()) / scaleRound
	y = (glyphPos.y()-y) / scaleRound
	local insideX = (x >= 0 and x < selectedGlyph.width)
	local insideY = (y >= 0 and y < selectedGlyph.height)
	return x, y, (insideX and insideY)
end

function isDragging()
	return love.mouse.isDown(3) or love.keyboard.isDown("lctrl")
end

function setCursor( x, y, inside )
	if isDragging() and inside then
		love.mouse.setCursor( love.mouse.getSystemCursor("sizeall") )
	elseif draggingAdvanceLine or (inside and math.abs( glyphPos.x() + selectedGlyph.advance*scaleRound - x ) < 10) then
		love.mouse.setCursor( love.mouse.getSystemCursor("sizewe") )
	else
		love.mouse.setCursor( love.mouse.getSystemCursor("arrow") )
	end
end

-- Forward love2d events to Gspot GUI
function love.keypressed(key)
	gui.gspot:keypress(key)
end

function love.textinput(key)
	gui.gspot:textinput(key)
end

function love.mousepressed( x, y, btn )
	if gui.addingComponent and x > canvasPos.x() then return end
	gui.gspot:mousepress( x, y, btn )
	
	local _, _, inside = toCanvasCoords( x, y )
	setCursor( x, y, inside )
	
	drawingCanvas = inside
	if inside and not isDragging() then -- Click within canvas boundaries
		if math.abs( glyphPos.x() + selectedGlyph.advance*scaleRound - x ) < 10 then
			draggingAdvanceLine = true
		else -- Draw and update previews
			x, y = toGlyphCoords( x, y )
			selectedGlyph:setPixel( x, y, btn==1 )
			gui.updatePreviews()
		end
	end
end

function love.mousereleased( x, y, btn )
	gui.gspot:mouserelease( x, y, btn )
	
	drawingCanvas = false
	draggingAdvanceLine = false
	setCursor( x, y, select( 3, toCanvasCoords(x,y) ) )
end

function love.wheelmoved( x, y )
	gui.gspot:mousewheel( x, y )
	
	-- Zoom if mouse isn't over GUI
	if love.mouse.getX() > canvasPos.x() and love.mouse.getX() < canvasPos.x2()
			and love.mouse.getY() > canvasPos.y() and love.mouse.getY() < canvasPos.y2() then
		scale = math.min( math.max( 1, scale + y*scale*0.05 ), 100 )
		scaleRound = math.floor(scale)
	end
end

function love.mousemoved( x, y, dx, dy )
	local _, _, inside = toCanvasCoords( x, y )
	setCursor( x, y, inside )
	x, y = toGlyphCoords( x, y )
	
	if draggingAdvanceLine then
		selectedGlyph.advance = round(x)
	elseif inside and drawingCanvas then -- Drag draw if mouse is within canvas boundaries
		if isDragging() then
			glyphPos._x = glyphPos._x + dx
			glyphPos._y = glyphPos._y + dy
		elseif love.mouse.isDown(1) then
			selectedGlyph:setPixel( x, y, true )
			gui.updatePreviews()
		elseif love.mouse.isDown(2) then
			selectedGlyph:setPixel( x, y, false )
			gui.updatePreviews()
		end
	end
end

function love.resize()
	gui.resize( love.graphics.getWidth(), love.graphics.getHeight() )
	gui.updatePreviews(true)
end

function love.directorydropped(path)
	print("Loading font")
	fnt = font.load(path)
	
	selectedLayer = fnt.layers[1]
	selectedGlyph = selectedLayer.glyphs[1]
	
	gui.load(fnt)
end