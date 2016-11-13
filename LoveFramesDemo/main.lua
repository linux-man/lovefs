loveframes = require("LoveFrames")
require 'lovefs/lovefs'
require 'lovefs/loveframesDialog'

function love.load()
	fsload = lovefs()
	fssave = lovefs()

	btload = loveframes.Create('button', window)	
	btload:SetPos(0,0)
	btload:SetSize(200, 40)
	btload:SetText('Load Image')
	btload.OnClick = function(object)
		fsload:loadDialog(loveframes, nil, {'All | *.*', 'Jpeg | *.jpg *.jpeg', 'Png | *.png', 'Bmp | *.bmp', 'Gif | *.gif'})
	end

	btlsnd = loveframes.Create('button', window)	
	btlsnd:SetPos(200,0)
	btlsnd:SetSize(200, 40)
	btlsnd:SetText('Load Sound')
	btlsnd.OnClick = function(object)
		fsload:loadDialog(loveframes, nil, {'All | *.*', 'Sound | *.mp3 *.wav'})
	end

	btlttf = loveframes.Create('button', window)
	btlttf:SetPos(400,0)
	btlttf:SetSize(200, 40)
	btlttf:SetText('Load TrueType')
	btlttf.OnClick = function(object)
		fsload:loadDialog(loveframes, nil, {'All | *.*', 'TrueType | *.ttf'})
	end

	btsave = loveframes.Create('button', window)	
	btsave:SetPos(600,0)
	btsave:SetSize(200, 40)
	btsave:SetText('Save Image (as png)')
	btsave.OnClick = function(object)
		fssave:saveDialog(loveframes)
	end
end

function love.update(dt)
	if fsload.selectedFile then
		ext = fsload.selectedFile:match('[^'..fsload.sep..']+$'):match('[^.]+$')
		if ext == 'jpg' or ext == 'png' or ext == 'bmp' then
			newImage = fsload:loadImage()
		elseif ext == 'mp3' or ext == 'wav' then
			sound = fsload:loadSource()
			sound:play()
		elseif ext == 'ttf' then
			font = fsload:loadFont(32)
			if font then love.graphics.setFont(font) end
		end
	end
	btsave.visible = newImage ~= nil
	if fssave.selectedFile then
		fssave:saveImage(newImage)
	end
	loveframes.update(dt)
end

function love.draw()
	love.graphics.setColor(255, 255, 255)
	if newImage then
		love.graphics.draw(newImage, 0, 0, 0, math.min(800 / newImage:getWidth(), 600 / newImage:getHeight()), math.min(800 / newImage:getWidth(), 600 / newImage:getHeight()))
	end
	if font then love.graphics.setFont(font) end
	love.graphics.print('LoveFS Demo', 5, 550)
	loveframes.draw()
end

function love.mousepressed(x, y, button)
	loveframes.mousepressed(x, y, button)
end

function love.mousereleased(x, y, button)
	loveframes.mousereleased(x, y, button)
end

function love.keypressed(key, unicode)
	loveframes.keypressed(key, unicode)
end

function love.keyreleased(key, unicode)
	loveframes.keyreleased(key)
end

function love.textinput(text)
	loveframes.textinput(text)
end
