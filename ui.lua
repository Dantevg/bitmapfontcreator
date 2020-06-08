--[[
	
	GUI builder
	by Dante van Gemert
	
	This file generates the GUI
	
]]--

local gui = {}

gui.elements = {}

function gui.updatePreviews() end





-- ACTIONS (bottom)

function gui.actions(fnt)
	gui.elements.actionsList = gui.gspot:group( "Actions", {
		glyphListWidth+16, love.graphics.getHeight()-50, 
		love.graphics.getWidth()-200-glyphListWidth-16, 50
	} )
	gui.elements.actionsList:setfont(12)
	local loadFontButton = gui.gspot:button( "Load", {0, 0, 100, 50}, gui.elements.actionsList )
	local saveFontButton = gui.gspot:button( "Save", {110, 0, 100, 50}, gui.elements.actionsList )
	local compileFontButton = gui.gspot:button( "Compile", {220, 0, 100, 50}, gui.elements.actionsList )
	
	loadFontButton.click = function(self)
		print("Load font")
	end
	
	saveFontButton.click = function(self)
		io.write("Saving font... ")
		fnt:save()
		io.write("Done.\n")
	end
	
	compileFontButton.click = function(self)
		print("Compile font")
		-- local fontmakePath = love.filesystem.getSource().."/fontmake/fontmake.pyz"
		local path = love.filesystem.getSaveDirectory().."/"..fnt.family
		if not love.filesystem.getInfo(path) then -- Path doesn't exist, save font first
			io.write("Saving font... ")
			fnt:save()
			io.write("Done.\n")
		end
		local command = "fontmake -u "..path..".ufo --output-path "..path..".ttf"
		print("Executing "..command..":\n")
		os.execute(command)
		print("\nDone.")
	end
end





-- FONT OPTIONS (top right)

function gui.fontOptions(fnt)
	gui.elements.fontOptionsList = gui.gspot:group( "Font options", {love.graphics.getWidth()-200, 0, 200, love.graphics.getHeight()/2} )
	gui.elements.fontOptionsList:setfont(12)
	local y = 20
	
	local function addFontOptionElement( location, label )
		local input = gui.gspot:input( label or location, {0, y, 200, 20}, gui.elements.fontOptionsList, fnt[location] )
		input.done = function(self)
			fnt[location] = self.value
			print("[INFO] Set font."..location.." to "..self.value)
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
end





-- GLYPH OPTIONS (bottom right)

local glyphComponentY
function gui.glyphComponents(y)
	y = y or glyphComponentY
	glyphComponentY = y
	
	gui.elements.glyphComponentsList = gui.gspot:group( "Components", {10, y, 180, 100}, gui.elements.glyphOptionsList )
	gui.elements.glyphComponentsList.style.bg = {40, 40, 40, 255}
	local addComponentButton = gui.gspot:button( "Add", {0, 0, 40, 20}, gui.elements.glyphComponentsList )
	addComponentButton.click = function(self)
		gui.addingComponent = true
	end
	
	for i, component in ipairs(selectedGlyph.components) do
		local componentGroup = gui.gspot:group( nil, {0, i*20, 180, 20}, gui.elements.glyphComponentsList )
		gui.gspot:text( component.glyph.name, {0, 0, 100, 20}, componentGroup )
		local xInput = gui.gspot:input( "", {118, 0, 20, 19}, componentGroup, component.x )
		xInput.done = function(self)
			print("[INFO] Set component "..component.glyph.name.." x offset to "..self.value)
			component.x = self.value
			selectedGlyph:regenerateImages()
			selectedGlyph:autoresize()
			gui.updatePreviews()
			self.Gspot[self.elementtype].done(self)
		end
		
		local yInput = gui.gspot:input( "", {139, 0, 20, 19}, componentGroup, component.y )
		yInput.done = function(self)
			print("[INFO] Set component "..component.glyph.name.." y offset to "..self.value)
			component.y = self.value
			selectedGlyph:regenerateImages()
			selectedGlyph:autoresize()
			gui.updatePreviews()
			self.Gspot[self.elementtype].done(self)
		end
		
		local removeBtn = gui.gspot:button( "-", {160, 0, 20, 19}, componentGroup )
		removeBtn.click = function()
			selectedGlyph:removeComponent( component.glyph )
			gui.gspot:rem(gui.elements.glyphComponentsList)
			gui.glyphComponents()
		end
	end
end

function gui.glyphOptions(fnt)
	gui.elements.glyphOptionsList = gui.gspot:group( "Glyph options", {
		love.graphics.getWidth()-200, love.graphics.getHeight()/2,
		200,                          love.graphics.getHeight()/2
	} )
	gui.elements.glyphOptionsList:setfont(12)
	y = 20
	
	local function addGlyphOptionElement( location, label, value )
		local input = gui.gspot:input( label or location, {0, y, 200, 20}, gui.elements.glyphOptionsList, value )
		input.done = function(self)
			print("[INFO] Set glyph."..location.." to "..self.value)
			selectedGlyph[location] = tonumber(self.value)
			if self.label == "width" or self.label == "height" then
				selectedGlyph:resize()
				gui.updatePreviews()
			end
			self.Gspot:unfocus()
		end
		input.keypress = function( self, key, code )
			self.Gspot[self.elementtype].keypress( self, key, code )
			self.value = self.value:gsub("%D+", "") -- Remove all non-number characters
		end
		y = y+30
	end
	
	-- addGlyphOptionElement( "width", nil, 1 )
	-- addGlyphOptionElement( "height", nil, 1 )
	-- addGlyphOptionElement( "advance", nil, 1 )
	
	-- local applyToAllButton = gui.gspot:button( "Apply to all", {10, y, 180, 20}, gui.elements.glyphOptionsList )
	-- applyToAllButton.click = function()
	-- 	print("Apply glyph options to all")
	-- 	for _, glyph in ipairs(selectedLayer.glyphs) do
	-- 		glyph:resize( selectedGlyph.width, selectedGlyph.height )
	-- 		glyph.advance = selectedGlyph.advance
	-- 	end
	-- end
	-- y = y+30
	
	local clearGlyphButton = gui.gspot:button( "Clear glyph", {10, y, 180, 20}, gui.elements.glyphOptionsList )
	clearGlyphButton.click = function()
		print("[INFO] Clear glyph")
		selectedGlyph.imageData:mapPixel(function() return 0, 0, 0, 0 end)
		selectedGlyph:regenerateImages()
		selectedGlyph:autoresize()
		gui.updatePreviews()
	end
	y = y+30
	
	gui.glyphComponents(y)
	
	y = y+110
	
	gui.elements.glyphPreview = gui.gspot:image( nil, {10, y}, gui.elements.glyphOptionsList, selectedGlyph:getImage() )
	gui.elements.glyphPreview2x = gui.gspot:image( nil, {10, y}, gui.elements.glyphOptionsList, selectedGlyph:getImage(2) )
	gui.elements.glyphPreview4x = gui.gspot:image( nil, {10, y}, gui.elements.glyphOptionsList, selectedGlyph:getImage(4) )
end





-- GLYPHS (left)

function gui.glyphs(fnt)
	gui.elements.glyphsList = gui.gspot:scrollgroup( nil, {0, 50, glyphListWidth, love.graphics.getHeight()-50}, nil, "vertical" )
	gui.elements.glyphsList.scrollv.style.hs = "auto"
	gui.elements.glyphsList:setfont(24)
	gui.elements.glyphButtons = {}
	gui.elements.glyphImages = {}
	
	local y = 0
	for _, glyph in ipairs(selectedLayer.glyphs) do
		if glyph.char then
			local glyphButton = gui.gspot:button(glyph.char, {0, y*50, 50, 50}, gui.elements.glyphsList )
			glyphButton.click = function(self)
				if not fnt then return end
				if gui.addingComponent then
					gui.addingComponent = false
					selectedGlyph:addComponent( glyph, 0, 0 )
					gui.gspot:rem(gui.elements.glyphComponentsList)
					gui.glyphComponents()
					return
				end
				
				print("[LOG]  Selected glyph "..glyph.name)
				selectedGlyph = glyph
				
				-- Reset colours of other elements
				for _, btn in ipairs(gui.elements.glyphButtons) do
					btn.style.hilite = gui.gspot.style.hilite
					btn.style.focus = gui.gspot.style.focus
					btn.style.fg = gui.gspot.style.fg
				end
				for _, btn in ipairs(gui.elements.combiningGlyphButtons) do
					btn.style.hilite = gui.gspot.style.hilite
					btn.style.focus = gui.gspot.style.focus
					btn.style.fg = gui.gspot.style.fg
				end
				
				-- Set this element's colour
				self.style.hilite = {255,255,255,255}
				self.style.focus = {255,255,255,255}
				self.style.fg = {0,0,0,255}
				
				-- Update glyph options
				for _, option in ipairs(gui.elements.glyphOptionsList.children) do
					if option.elementtype == "input" then
						option.value = tostring( selectedGlyph[option.label] )
					end
				end
				gui.gspot:rem(gui.elements.glyphComponentsList)
				gui.glyphComponents()
				glyph:regenerateImages()
				glyph:autoresize()
				gui.updatePreviews()
			end
			
			-- Make sure selected glyph is selected visually, at load
			if glyph == selectedGlyph then
				glyphButton.style.hilite = {255,255,255,255}
				glyphButton.style.focus = {255,255,255,255}
				glyphButton.style.fg = {0,0,0,255}
			end
			
			local glyphCodepoint = gui.gspot:text( string.format("0x%X",glyph.unicode), {0, y*50+35, 50, 50}, gui.elements.glyphsList )
			glyphCodepoint:setfont(10)
			
			local glyphImage = gui.gspot:image( nil, {60, y*50+5, 50, 50}, gui.elements.glyphsList )
			table.insert( gui.elements.glyphButtons, glyphButton )
			gui.elements.glyphImages[glyph] = glyphImage
			
			y = y+1
		end
	end
end





-- COMBINING GLYPHS LIST

function gui.combiningGlyphs(fnt)
	gui.elements.combiningGlyphsList = gui.gspot:scrollgroup( nil, {0, 50, glyphListWidth, love.graphics.getHeight()-50}, nil, "vertical" )
	gui.elements.combiningGlyphsList.scrollv.style.hs = "auto"
	gui.elements.combiningGlyphsList:setfont(12)
	gui.elements.combiningGlyphButtons = {}
	
	y = 0
	for _, glyph in ipairs(selectedLayer.glyphs) do
		if not glyph.char then
			local glyphButton = gui.gspot:button(glyph.name, {0, y*50, 100, 50}, gui.elements.combiningGlyphsList )
			glyphButton.click = function(self)
				if not fnt then return end
				if gui.addingComponent then
					gui.addingComponent = false
					selectedGlyph:addComponent( glyph, 0, 0 )
					gui.gspot:rem(gui.elements.glyphComponentsList)
					gui.glyphComponents()
					return
				end
				
				print("[LOG]  Selected glyph "..glyph.name)
				selectedGlyph = glyph
				
				-- Reset colours of other elements
				for _, btn in ipairs(gui.elements.combiningGlyphButtons) do
					btn.style.hilite = gui.gspot.style.hilite
					btn.style.focus = gui.gspot.style.focus
					btn.style.fg = gui.gspot.style.fg
				end
				for _, btn in ipairs(gui.elements.glyphButtons) do
					btn.style.hilite = gui.gspot.style.hilite
					btn.style.focus = gui.gspot.style.focus
					btn.style.fg = gui.gspot.style.fg
				end
				
				-- Set this element's colour
				self.style.hilite = {255,255,255,255}
				self.style.focus = {255,255,255,255}
				self.style.fg = {0,0,0,255}
				
				-- Update glyph options
				for _, option in ipairs(gui.elements.glyphOptionsList.children) do
					if option.elementtype == "input" then
						option.value = tostring( selectedGlyph[option.label] )
					end
				end
				gui.gspot:rem(gui.elements.glyphComponentsList)
				gui.glyphComponents()
				glyph:regenerateImages()
				glyph:autoresize()
				gui.updatePreviews()
			end
			
			-- Make sure selected glyph is selected visually, at load
			if glyph == selectedGlyph then
				glyphButton.style.hilite = {255,255,255,255}
				glyphButton.style.focus = {255,255,255,255}
				glyphButton.style.fg = {0,0,0,255}
			end
			
			table.insert( gui.elements.combiningGlyphButtons, glyphButton )
			
			y = y+1
		end
	end
	
	if not gui.elements.glyphTypeSelector or gui.elements.glyphTypeSelector.label ~= "Combining" then
		gui.elements.combiningGlyphsList:hide()
	end
end





-- GLYPH NORMAL/COMBINING SELECTOR

function gui.combiningSelector(fnt)
	gui.elements.glyphTypeSelector = gui.gspot:button( "Normal", {0, 0, glyphListWidth+16, 50} )
	gui.elements.glyphTypeSelector:setfont(12)
	
	gui.elements.glyphTypeSelector.click = function(self)
		if self.label == "Combining" then
			self.label = "Normal"
			gui.elements.combiningGlyphsList:hide()
			gui.elements.glyphsList:show()
			print("[LOG]  Selected normal glyphs")
		else
			self.label = "Combining"
			gui.elements.glyphsList:hide()
			gui.elements.combiningGlyphsList:show()
			print("[LOG]  Selected combining glyphs")
		end
	end
end





-- FUNCTIONS

function gui.updatePreviews(all)
	gui.elements.glyphPreview:setimage( selectedGlyph:getImage() )
	gui.elements.glyphPreview2x:setimage( selectedGlyph:getImage(2) )
	gui.elements.glyphPreview2x.pos.x = 20 + selectedGlyph.width
	gui.elements.glyphPreview4x:setimage( selectedGlyph:getImage(4) )
	gui.elements.glyphPreview4x.pos.x = 30 + selectedGlyph.width*3
	
	local maxScale = math.huge
	for _, glyph in ipairs(selectedLayer.glyphs) do
		maxScale = math.min( maxScale, 30/glyph.width, 40/glyph.height )
	end
	
	if all then
		for glyph, image in pairs(gui.elements.glyphImages) do
			image:setimage( glyph:getImage(math.floor(maxScale)) )
		end
	else
		if selectedGlyph.char then
			gui.elements.glyphImages[selectedGlyph]:setimage( selectedGlyph:getImage( math.floor(maxScale) ) )
		end
	end
end

function gui.updateGlyphComponents()
	-- Empty old glyph components list
	for _, glyphComponentElement in ipairs(gui.elements.glyphComponentsList.children) do
		if glyphComponentElement.elementtype ~= "button" then
			gui.gspot:rem(glyphComponentElement)
		end
	end
	
	-- Fill glyph components list
	for i, component in ipairs(selectedGlyph.components) do
		local componentGroup = gui.gspot:group( nil, {0, i*20, 180, 20}, gui.elements.glyphComponentsList )
		gui.gspot:text( component.glyph.name, {0, 0, 100, 20}, componentGroup )
		local btn = gui.gspot:button( "-", {160, 0, 20, 20}, componentGroup )
		btn.click = function()
			selectedGlyph:removeComponent( component.glyph )
			gui.updateGlyphComponents()
		end
	end
end

function gui.load(fnt)
	gui.gspot = require("lib/Gspot"):setComponentMax(255)
	gui.actions(fnt)
	gui.fontOptions(fnt)
	gui.glyphOptions(fnt)
	gui.glyphs(fnt)
	gui.combiningGlyphs(fnt)
	gui.combiningSelector(fnt)
end

function gui.resize( width, height )
	-- Reload glyphs lists because scrollgroups don't react to size changes
	gui.gspot:rem(gui.elements.glyphsList)
	gui.gspot:rem(gui.elements.combiningGlyphsList)
	gui.glyphs(fnt)
	gui.combiningGlyphs(fnt)
	
	gui.elements.actionsList.pos.y = height-50
	gui.elements.actionsList.pos.w = width-200-glyphListWidth-16
	gui.elements.fontOptionsList.pos.x = width-200
	gui.elements.fontOptionsList.pos.h = height/2
	gui.elements.glyphOptionsList.pos.x = width-200
	gui.elements.glyphOptionsList.pos.y = height/2
	gui.elements.glyphOptionsList.pos.h = height/2
end





-- RETURN

return gui