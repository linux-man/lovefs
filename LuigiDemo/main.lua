require 'lovefs/lovefs'
Layout = require 'luigi.layout'
require 'lovefs/luigiDialog'

local layout = Layout(
{flow = 'x',
	{style = 'btn', id = 'loadImage', text = 'Load Image'},
	{style = 'btn', id = 'loadSound', text = 'Load Sound'},
	{style = 'btn', id = 'loadFont', text = 'Load TrueType'},
	{style = 'btn', id = 'saveImage', text = 'Save Image'},
}
)

layout:setStyle(
{
	btn = {
		type = 'button',
		width = 200,
		height = 48,
		align = 'center middle'
	}
}
)

layout.loadImage:onPress(function (event)
	fs:loadDialog(Layout, 'Load Image', {'All | *.*', 'Jpeg | *.jpg *.jpeg', 'Png | *.png', 'Bmp | *.bmp', 'Gif | *.gif'})
	save = false
end)

layout.loadSound:onPress(function (event)
	fs:loadDialog(Layout, 'Load Sound', {'Sound | *.mp3 *.wav', 'All | *.*'})
	save = false
end)

layout.loadFont:onPress(function (event)
	fs:loadDialog(Layout, 'Load TrueType', {'TrueType | *.ttf', 'All | *.*'})
	save = false
end)

layout.saveImage:onPress(function (event)
	fs:saveDialog(Layout, 'Save Image')
	save = true
end)

function love.load()
	fs = lovefs()
	layout:show()
	layout.saveImage.width = 0
end

function love.update(dt)
	if fs.selectedFile then
		ext = fs.selectedFile:match('[^'..fs.sep..']+$'):match('[^.]+$')
		if save then
			if newImage then fs:saveImage(newImage) end
			save = false
		elseif ext == 'jpg' or ext == 'png' or ext == 'bmp' then
			newImage = fs:loadImage()
			layout.saveImage.width = 200
		elseif ext == 'mp3' or ext == 'wav' then
			sound = fs:loadSource()
			sound:play()
		elseif ext == 'ttf' then
			font = fs:loadFont(32)
			if font then love.graphics.setFont(font) end
		end
	end

end

function love.draw()
	love.graphics.setColor(255, 255, 255)
	if newImage then
		love.graphics.draw(newImage, 0, 0, 0, math.min(800 / newImage:getWidth(), 600 / newImage:getHeight()), math.min(800 / newImage:getWidth(), 600 / newImage:getHeight()))
	end
	love.graphics.print('LoveFS Demo', 5, 550)
end
