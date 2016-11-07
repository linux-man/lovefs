package.path = package.path .. ';../?.lua'
gui = require('Gspot/Gspot')
require('lovefs/lovefs')
require('lovefs/gspotDialog')

love.load = function()
	save = false
	fs = lovefs()
	local button = gui:button('Load Image', {0, 0, 200, 40})
	button.click = function(this)
		fs:openDialog(gui, 'Load Image', {'jpg', 'png', 'bmp'})
	end
	local button = gui:button('Load Sound', {200, 0, 200, 40})
	button.click = function(this)
		fs:openDialog(gui, 'Load Sound', {'mp3', 'wav'})
	end
	local button = gui:button('Load TrueType', {400, 0, 200, 40})
	button.click = function(this)
		fs:openDialog(gui, 'Load TrueType', {'ttf'})
	end
	saveButton = gui:button('Save Image (as png)', {600, 0, 200, 40})
	saveButton.click = function(this)
		save = true
		fs:openDialog(gui, 'Save Image')
	end
	saveButton:hide()
end

love.update = function(dt)
	gui:update(dt)
	if fs.selectedFile then
		ext = fs.selectedFile:match('[^'..fs.sep..']+$'):match('[^.]+$')
		if save then
			if newImage then fs:saveImage(newImage) end
			save = false
		elseif ext == 'jpg' or ext == 'png' or ext == 'bmp' then
			newImage = fs:loadImage()
			saveButton:show()
		elseif ext == 'mp3' or ext == 'wav' then
			sound = fs:loadSource()
			sound:play()

		elseif ext == 'ttf' then
			font = fs:loadFont(32)
			if font then love.graphics.setFont(font) end
		end
	end
end

love.draw = function()
	love.graphics.setColor(255, 255, 255)
	if newImage then
		love.graphics.draw(newImage, 0, 0, 0, math.min(800 / newImage:getWidth(), 600 / newImage:getHeight()), math.min(800 / newImage:getWidth(), 600 / newImage:getHeight()))
	end
	love.graphics.print('LoveFS Demo', 5, 550)
	gui:draw()
end

love.mousepressed = function(x, y, button)
	gui:mousepress(x, y, button)
end

love.mousereleased = function(x, y, button)
	gui:mouserelease(x, y, button)
end

love.wheelmoved = function(x, y)
	gui:mousewheel(x, y)
end

love.keypressed = function(key)
	if gui.focus then
		gui:keypress(key)
	end
end

love.textinput = function(key)
	if gui.focus then
		gui:textinput(key)
	end
end
