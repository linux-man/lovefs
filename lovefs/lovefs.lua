--[[------------------------------------
LoveFS v2.0
Pure Lua FileSystem Access
Under the MIT license.
copyright(c) 2025 Caldas Lopes aka linux-man
--]]------------------------------------

local ffi = require("ffi")

local osx = ffi.os == "OSX" or nil
local linux = ffi.os == "Linux" or nil
local win = ffi.os =="Windows" or nil

local function findValue(tb, value)
	for _, v in ipairs(tb) do
		if v == value then return true end
	end
	return false
end

filesystem = {}
filesystem.__index = filesystem

local path = (...):match(".+/")
if win then require (path .. "lovefs_win")
elseif osx then require (path .. "lovefs_osx")
elseif linux then require (path .. "lovefs_linux")
else error('Platform not supported') end

function filesystem:switchHidden()
	self.showHidden = not self.showHidden
	self:cd()
end

function filesystem:setFilter(filter)
	self.filter = nil
	if type(filter) == "table" then
		self.filter = filter
	elseif type(filter) == "string" then
		local t = {}
		f = filter:sub((filter:find('|') or 0) + 1)
		for i in string.gmatch(f, "%S+") do
			i = i:gsub('[%*%.%;]', '')
			if i ~= '' then table.insert(t, i) end
		end
		if #t > 0 then self.filter = t end
	end
	self:cd()
end

function filesystem:dir(dir)
	return self:ls(dir)
end

function filesystem:cd(dir)
	current, tDirs, tFiles, tOthers, tAll = self:ls(dir)
	if current then
		self.current = current
		self.dirs = tDirs
		self.files = tFiles
		self.others = tOthers
		self.all = tAll
		return true
	end
	return false
end

function filesystem:up()
	self:cd(self.current:match('(.*'..self.sep..')'))
end

function filesystem:exists(path)
	path = self:absPath(path)
	dir = self:absPath(path:match('(.*'..self.sep..')'))
	name = path:match('[^'..self.sep..']+$')
	--ext = name:match('[^.]+$')
	dir, dirs, files, others, all = self:ls(dir)
	if dir then
		return findValue(all, name), findValue(dirs, name), findValue(files, name)
	end
	return false
end

function filesystem:isDirectory(path)
	exists, isDir = self:exists(path)
	if exists then return isDir
	else return false end
end

function filesystem:isFile(path)
	exists, isDir, isFile = self:exists(path)
	if exists then return isFile
	else return false end
end

function filesystem:loadImage(source)
	source = source or self.selectedFile
	self.selectedFile = nil
	source = self:absPath(source)
	love.filesystem.createDirectory('lovefs_temp')
	self:copy(source, love.filesystem.getSaveDirectory()..'/lovefs_temp/temp.file')
	return love.graphics.newImage('lovefs_temp/temp.file')
end

function filesystem:loadSource(source)
	source = source or self.selectedFile
	self.selectedFile = nil
	source = self:absPath(source)
	love.filesystem.createDirectory('lovefs_temp')
	--local name = path:match('[^'..self.sep..']+$')
	local ext = source:match('[^'..self.sep..']+$'):match('[^.]+$')
	self:copy(source, love.filesystem.getSaveDirectory()..'/lovefs_temp/temp.'..ext)
	return love.audio.newSource('lovefs_temp/temp.'..ext, 'static')
end

function filesystem:loadFont(size, source)
	source = source or self.selectedFile
	self.selectedFile = nil
	source = self:absPath(source)
	love.filesystem.createDirectory('lovefs_temp')
	self:copy(source, love.filesystem.getSaveDirectory()..'/lovefs_temp/temp.file')
	return love.graphics.newFont('lovefs_temp/temp.file', size)
end

function filesystem:saveImage(img, dest)
	if not pcall(function() love.graphics.newCanvas(img:getWidth(), img:getHeight()) end) then return false end
	dest = dest or self.selectedFile
	dest = self:absPath(dest)
	self.selectedFile = nil
	love.filesystem.createDirectory('lovefs_temp')
	love.filesystem.remove('lovefs_temp/temp.file')
	love.graphics.setColor(255, 255, 255)
	local canvas = love.graphics.newCanvas(img:getWidth(), img:getHeight())
	love.graphics.setCanvas(canvas)
	love.graphics.draw(img, 0, 0)
	love.graphics.setCanvas()
	local id = canvas:newImageData()
	id:encode('png', 'lovefs_temp/temp.file')
	self:copy(love.filesystem.getSaveDirectory()..'/lovefs_temp/temp.file', dest)
	return true
end

function lovefs(dir)
	local temp = {}
	setmetatable(temp, filesystem)
	temp.selectedFile = nil
	temp.filter = nil
	temp.showHidden = false
	temp.home = love.filesystem.getUserDirectory()
	temp.current = temp.home
	temp.sep = package.config:sub(1,1)
	dir = dir or temp.home
	if not temp:cd(dir) then
		if not temp:cd(temp.home) then
			if not temp:cd('c:'..sep) then
				temp:cd(sep)
			end
		end
	end
	temp:updDrives()
	return temp
end
