--[[
	
	Bitmap font creator
	by Dante van Gemert
	
	main file
	
]]--

function love.load()
	gui = require("lib/Gspot"):setComponentMax(255)
	
	canvas = love.graphics.newCanvas()
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