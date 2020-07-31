--[[------------------------------------
LoveFS v0.9
Pure Lua FileSystem Access
Under the MIT license.
copyright(c) 2016 Caldas Lopes aka linux-man
--]]------------------------------------

local lovefs_dir = 'lovefs'
local cp_table = {'737', '775', '850', '852', '855', '866', '8859-1', '8859-2', '8859-4', '8859-5', '8859-7', '8859-15', '8859-16', 'KOI8-R', 'KOI8-U'}

local function strformat(str)
	str = str:gsub('"', '')
	str = string.format('%q',str)
	while str:find('\\\\') do str = str:gsub('\\\\', '\\') end
	while str:find('//') do str = str:gsub('//', '/') end
	return str
end

local function split(str, sep)
	local sep, fields = sep or ":", {}
	local pattern = string.format("([^%s]+)", sep)
	str:gsub(pattern, function(c) fields[#fields+1] = c end)
	return fields
end

local function split_lines(str)
	local t = {}
	for line in str:gmatch("[^\r\n]+") do table.insert(t, line) end
	return t
end

local function join_tables(t1, t2)
	local tb = {}
	for _,v in ipairs(t1) do table.insert(tb, v) end
	for _,v in ipairs(t2) do table.insert(tb, v) end
	return tb
end

local function normalize_utf8(str, always)
	always = always or false
	local str2 = str
	local utfcodes = '194,195,196,197,198,200,203,206,207,208,209,210,226'
	if always or not pcall(function() love.graphics.print(str, 0, 0) end) then
		str2 = ''
		for n = 1, #str do
			if str:byte(n) < 128 then
			str2 = str2..str:sub(n, n)
			else
				if utfcodes:find(tostring(str:byte(n))) then str2 = str2..'?' end
			end
		end
	end
	return str2
end

local function normalize_cp(str)
	local str2 = ''
	for n = 1, #str do
		if str:byte(n) < 128 then str2 = str2..str:sub(n, n)
		else str2 = str2..'?' end
	end
	return str2
end

filesystem = {}
filesystem.__index = filesystem

function filesystem:loadCp(codepage)
	self.tb_utf8, self.tb_cp = nil, nil
	if not codepage then
		if self.os == 'Windows' then
			_, lang = self:run('chcp')
			lang = lang:gsub('\n', '')
		else
			_, lang = self:run('echo $LANG')
			lang = lang:gsub('\n', '')
		end
		codepage = lang
		for _, c in ipairs(cp_table) do
			if lang:find(c) then codepage = c end
		end
	end
	self.cp = codepage
	if not love.filesystem.isFile(lovefs_dir..'/codepages/'..codepage) then
		if self.current then self:cd(self.current) end
		return false
	end
	local count = 128
	self.tb_utf8, self.tb_cp = {}, {}
	for line in love.filesystem.lines(lovefs_dir..'/codepages/'..codepage) do
		if line ~= '' then
			self.tb_utf8[count] = split(line, '\\')
			self.tb_cp[line] = count
		end
		count = count + 1
	end
	if self.current then self:cd(self.current) end
	return true
end

function filesystem:toUtf8(str)
	if not self.tb_utf8 then return normalize_utf8(str) end
	local str2 = ''
	for n = 1, #str do
		if str:byte(n) < 128 then str2 = str2..str:sub(n, n)
		else
			if self.tb_utf8[str:byte(n)] then
			for _, n in ipairs(self.tb_utf8[str:byte(n)]) do
				str2 = str2..string.char(n)
			end
			else str2 = str2..str:sub(n, n)
			end
		end
	end
	return normalize_utf8(str2)
end

function filesystem:path8p3(dir, all)
	dir = dir or self.current
	if not (dir:sub(2,2) == ':') then dir = strformat(self.current..'\\'..dir):sub(2, -2) end
	dir = dir:gsub('/', '\\')
	local tb_dir = split(dir, '\\')
	local dir8p3 = tb_dir[1]
	table.remove(tb_dir, 1)
	while #tb_dir > 1 do
		local r, c = self:run('dir /X /AD '..strformat(dir8p3..'\\'))
		if not r then return self.current end
		local dir_result = split_lines(c)
		local name8p3 = ''
		for _, line in ipairs(dir_result) do
			if line:find('<DIR>') and line:sub(50):find(tb_dir[1]:gsub("[%-]", "%%%0")) then
				if line:sub(37, 45):gsub(' ', '') ~= '' then
					name8p3 = line:sub(37, 45):gsub(' ', '')
				else
					name8p3 = line:sub(50)
				end
			end
		end
		if name8p3 ~= '' then dir8p3 = dir8p3..'\\'..name8p3
		else return self.current end
		table.remove(tb_dir, 1)
	end
	local name8p3 = tb_dir[1]
	if all then
		local r, c = self:run('dir /X /A-D '..strformat(dir8p3..'\\'))
		if not r then return self.current end
		local dir_result = split_lines(c)
		for _, line in ipairs(dir_result) do
			if line:sub(50):find(tb_dir[1]) then
				if line:sub(37, 45):gsub(' ', '') ~= '' then
					name8p3 = line:sub(37, 45):gsub(' ', '')
				else
					name8p3 = line:sub(50)
				end
			end
		end
	end
	return dir8p3..'\\'..name8p3
end

function filesystem:toCp(str)
	if not self.tb_cp then
		if self.os == 'Windows' then return normalize_utf8(str, true)
		else return str end
	end
	local str2 = ''
	for n = 1, #str do
		if str:byte(n) < 128 then str2 = str2..str:sub(n, n)
		else
			if n < #str-1 then
				if self.tb_cp['\\'..str:byte(n)..'\\'..str:byte(n+1)..'\\'..str:byte(n+2)] then
					str2 = str2..string.char(self.tb_cp['\\'..str:byte(n)..'\\'..str:byte(n+1)..'\\'..str:byte(n+2)])
					n = n + 2
				elseif self.tb_cp['\\'..str:byte(n)..'\\'..str:byte(n+1)] then
					str2 = str2..string.char(self.tb_cp['\\'..str:byte(n)..'\\'..str:byte(n+1)])
					n = n + 1
				end
			elseif n < #str then
				if self.tb_cp['\\'..str:byte(n)..'\\'..str:byte(n+1)] then
					str2 = str2..string.char(self.tb_cp['\\'..str:byte(n)..'\\'..str:byte(n+1)])
					n = n + 1
				end
			end
		end
	end
	if self.os == 'Windows' then str2 = normalize_cp(str2) end
	return str2
end

function filesystem:run(command)
	if love._os == 'Windows' then
		console = self.tempdir..os.tmpname()
	else
		console = os.tmpname()
	end
	r = os.execute(self:toCp(command)..' > '.. console)
	c = ''
	for line in io.lines(console) do
		line = self:toUtf8(line)
		if c == '' then c = line
		else c = c..'\n'..line end
	end
	os.remove(console)
	return r, c
end

function filesystem:ls(param, dir)
	dir = dir or self.current
	param = param or ''
	if self.os == 'Windows' then
		local r, c = self:run('cd /D '..strformat(dir)..' & dir /B /A-S-H '..param)
		str = c
	else
		local r, c = self:run('cd '..strformat(dir)..' ; ls -1 '..param)
		str = c:gsub('/', '')
	end
	return split_lines(str), str
end

function filesystem:lsDirs(param, dir)
	dir = dir or self.current
	param = param or ''
	if self.os == 'Windows' then return self:ls('/A-S-HD /ON '..param, dir)
	else return self:ls('-p '..param..' | grep /\\$', dir)
	end
end

function filesystem:lsFiles(param, dir)
	dir = dir or self.current
	param = param or ''
	if self.os == 'Windows' then return self:ls('/A-S-H-D /ON '..param, dir)
	else return self:ls('-p '..param..' | grep -v /\\$', dir)
	end
end

function filesystem:exists(name, dir)
	dir = dir or self.current
	if self.os == 'Windows' then r, c = self:run('cd /D '..strformat(dir)..' & dir '..strformat(name))
	else r, c = self:run('cd '..strformat(dir)..' ; ls '..strformat(name)) end
	return r == 0
end

function filesystem:isDirectory(name, dir)
	dir = dir or self.current
	if self.os == 'Windows' then r, c = self:run('cd /D '..strformat(dir)..' & cd '..strformat(name))
	else r, c = self:run('cd '..strformat(dir)..' ; cd '..strformat(name)) end
	return r == 0
end

function filesystem:isFile(name, dir)
	return self:exists(name, dir) and not self:isDirectory(name, dir)
end

function filesystem:dir(param, dir)
	return self:ls(param, dir)
end

function filesystem:cd(dir)
	dir = dir or self.current
	if self.os == 'Windows' then
		if not (dir:sub(2,2) == ':') then dir = self.current..'\\'..dir end
		dir = strformat(dir)
		r, c = self:run('cd /D '..strformat(dir))
		if r == 0 then
			r, c = self:run('cd /D '..strformat(dir)..' & cd')
			self.current = c:gsub('\n', '')
			self.dirs = self:lsDirs()
			self.files = self:lsFiles(self.param)
			self.all = join_tables(self.dirs, self.files)
			return true
		end
	else
		if not (dir:sub(1,1) == '/' or dir:sub(1,1) == '~') then dir = self.current..'/'..dir end
		dir = strformat(dir)
		r, c = self:run('cd '..dir)
		if r == 0 then
			r, c = self:run('cd '..dir..' ; pwd')
			self.current = c:gsub('//', '/'):gsub('\n', '')
			self.dirs = self:lsDirs()
			self.files = self:lsFiles(self.param)
			self.all = join_tables(self.dirs, self.files)
			return true
		end
	end
	return false
end

function filesystem:up()
	return self:cd('..')
end

function filesystem:setParam(param)
	if param then self.param = param end
	self:cd(self.current)
end

function filesystem:lsDrives()
	if self.os == 'Windows' then
		local str = io.popen('wmic logicaldisk get caption'):read('*all')
		if not str:find('C:') then str = 'default\nA:\nB:\nC:\nD:\nE:\nF:\nG:\nH:\nI:\nJ:\n' end
		tb = split_lines(self:toUtf8(str):gsub(' ', ''))
		table.remove(tb,1)
	elseif self.os == 'Linux' then
		tb = self:lsDirs('', '/media')
		for n, d in ipairs(tb) do tb[n] = '/media/'..tb[n] end
		table.insert(tb, 1, '/')
	else
		tb = self:lsDirs('', '/Volumes')
		for n, d in ipairs(tb) do tb[n] = '/Volumes/'..tb[n] end
		table.insert(tb, 1, '/')	
	end
	return tb
end

function filesystem:copy(source, dest)
	love.filesystem.createDirectory('lovefs_temp')
	if self.os == 'Windows' then
		source = strformat(self:path8p3(self:toCp(source), true)):sub(2, -2)
		dest = strformat(self:path8p3(self:toCp(dest))):sub(2, -2)
	else
		source = strformat(self:toCp(source)):sub(2, -2)
		dest = strformat(self:toCp(dest)):sub(2, -2)
	end
	local inp = assert(io.open(source, "rb"))
    local out = assert(io.open(dest, "wb"))
    local data = inp:read("*all")
    out:write(data)
    assert(out:close())
end

function filesystem:loadImage(source)
	source = source or self.selectedFile
	self.selectedFile = nil
	love.filesystem.createDirectory('lovefs_temp')
	self:copy(source, love.filesystem.getSaveDirectory()..'/lovefs_temp/temp.file')
	return love.graphics.newImage('lovefs_temp/temp.file')
end

function filesystem:loadSource(source)
	source = source or self.selectedFile
	self.selectedFile = nil
	love.filesystem.createDirectory('lovefs_temp')
	self:copy(source, love.filesystem.getSaveDirectory()..'/lovefs_temp/temp.'..source:sub(-3))
	return love.audio.newSource('lovefs_temp/temp.'..source:sub(-3))
end

function filesystem:loadFont(size, source)
	source = source or self.selectedFile
	self.selectedFile = nil
	love.filesystem.createDirectory('lovefs_temp')
	self:copy(source, love.filesystem.getSaveDirectory()..'/lovefs_temp/temp.file')
	return love.graphics.newFont('lovefs_temp/temp.file', size)
end

function filesystem:saveImage(img, dest)
	if not pcall(function() love.graphics.newCanvas(img:getWidth(), img:getHeight()) end) then return false end
	dest = dest or self.selectedFile
	self.selectedFile = nil
	love.filesystem.createDirectory('lovefs_temp')
	love.graphics.setColor(255, 255, 255)
	local canvas = love.graphics.newCanvas(img:getWidth(), img:getHeight())
	love.graphics.setCanvas(canvas)
	love.graphics.draw(img, 0, 0)
	local id = canvas:getImageData()
	local tb = split(dest, '.')
	id:encode('lovefs_temp/temp.'..tb[#tb])
	self:copy(love.filesystem.getSaveDirectory()..'/lovefs_temp/temp.'..tb[#tb], dest)
	return true
end

function lovefs(dir)
	local temp = {}
	setmetatable(temp, filesystem)
	temp.os = love.system.getOS()
	temp.param = ''
	temp.selectedFile = nil
	if temp.os == 'Windows' then
		temp.tempdir = io.popen('echo %TEMP%'):read('*all'):gsub('\n', '')
	else
		temp.tempdir = ''
	end
	temp.home = love.filesystem.getUserDirectory()
	temp.current = temp.home
	dir = dir or temp.home
	temp:loadCp()
	if not temp:cd(dir) then
		if not temp:cd(temp.home) then
			if temp.os == 'Windows' then temp:cd('c:\\')
			else temp:cd('/') end
		end
	end
	temp.drives = temp:lsDrives()
	return temp
end
