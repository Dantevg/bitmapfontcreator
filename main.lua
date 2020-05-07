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
	
]]--

local xml = require "lib/xml2lua"
local font = require "font"
local gui = require("lib/Gspot"):setComponentMax(255)

function love.load()
	canvas = love.graphics.newCanvas()
	
	local fnt = font({name = "My Font!"})
	fnt.author = "Me!"
	print( fnt:generateXML("metainfo") )
end

function love.update(dt)
	gui:update(dt)
end

function love.draw()
	gui:draw()
	love.graphics.draw(canvas)
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