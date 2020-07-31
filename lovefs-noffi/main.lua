loveframes = require("loveframes")
require 'lovefs/lovefs'
require 'lovefs/dialogs'

function love.load()
	fsload = lovefs()
	fssave = lovefs()
	fslsnd = lovefs()
	fslttf = lovefs()

	btload = loveframes.Create('button', window)	
	btload:SetPos(0,5)
	btload:SetSize(200, 25)
	btload:SetText('Load Image')
	btload.OnClick = function(object)
		l = loadDialog(fsload, {'All | *.*', 'Jpeg | *.jpg *.jpeg', 'PNG | *.png', 'Bitmap | *.bmp', '*.gif'})
	end

	btsave = loveframes.Create('button', window)	
	btsave:SetPos(200,5)
	btsave:SetSize(200, 25)
	btsave:SetText('Save Image')
	btsave.OnClick = function(object)
		if img then s = saveDialog(fssave) end
	end

	btlsnd = loveframes.Create('button', window)	
	btlsnd:SetPos(400,5)
	btlsnd:SetSize(200, 25)
	btlsnd:SetText('Load Sound')
	btlsnd.OnClick = function(object)
		s = loadDialog(fslsnd, {'All | *.*', 'Sound | *.mp3 *.wav'})
	end

	btlttf = loveframes.Create('button', window)	
	btlttf:SetPos(600,5)
	btlttf:SetSize(200, 25)
	btlttf:SetText('Load TrueType')
	btlttf.OnClick = function(object)
		t = loadDialog(fslttf, {'All | *.*', 'TrueType | *.ttf'})
	end
end

function love.update(dt)
	if fsload.selectedFile then
		img = fsload:loadImage()
	end
	if fssave and fssave.selectedFile then
		fssave:saveImage(img)
	end
	if fslsnd.selectedFile then
		sound = fslsnd:loadSource()
		sound:play()
	end
	if fslttf.selectedFile then
		font = fslttf:loadFont(32)
	end
	loveframes.update(dt)
end

function love.draw()
	love.graphics.setColor(255, 255, 255)
	if img then
		love.graphics.draw(img, 0, 0, 0, math.min(800 / img:getWidth(), 600 / img:getHeight()), math.min(800 / img:getWidth(), 600 / img:getHeight()))
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
