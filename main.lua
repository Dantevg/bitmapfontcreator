--[[
	
	Bitmap font creator
	by Dante van Gemert
	
	main file
	
	Project resources:
	- http://unifiedfontobject.org/versions/ufo3/
	- https://scripts.sil.org/cms/scripts/page.php?site_id=nrsi&id=IWS-Chapter08
	- https://notabug.org/pgimeno/Gspot/wiki
	
]]--

function love.load()
	xml = require "lib/xml2lua"
	toXML = require "lib/xml"
	ufo = require "lib/ufo"
	font = require "font"
	gui = require("lib/Gspot"):setComponentMax(255)
	
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