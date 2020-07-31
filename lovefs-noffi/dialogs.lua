--[[------------------------------------
LoveFS Dialogs v0.8
Pure Lua FileSystem Access - Loveframes interface
Under the MIT license.
copyright(c) 2012 Caldas Lopes aka linux-man
--]]------------------------------------

require 'loveframes'

local lovefs_dir = 'lovefs'

local function normalize(str)
	local str2 = ''
	for n = 1, #str do
		if str:byte(n) < 128 then str2 = str2..str:sub(n, n) end
	end
	return str2
end

dialog = {}
dialog.__index = dialog

function dialog:refresh()
	self.current:SetText(self.window_fs.current)
	self.list:Clear()
	local i = loveframes.Create('button')
	i:SetSize(405, 25)
	i.image = up
	i:SetText('..')
	i.groupIndex = 1
	i.OnClick = function(object)
		self.window.selectedFile = ''
		self.window_fs:cd(object:GetText())
		self:refresh()
	end
	self.list:AddItem(i)
	for _, d in ipairs(self.window_fs.dirs) do
		local i = loveframes.Create('button')
		i:SetSize(405, 25)
		i.image = folder
		i:SetText(d)
		i.groupIndex = 1
		i.OnClick = function(object)
			self.window.selectedFile = ''
			if self.fileinput then self.fileinput.text ='' end
			self.window_fs:cd(object:GetText())
			self:refresh()
		end
		self.list:AddItem(i)
	end
	for _, f in ipairs(self.window_fs.files) do
		local i = loveframes.Create('button')
		i:SetSize(405, 25)
		i.image = file
		i:SetText(f)
		i.groupIndex = 1
		i.OnClick = function(object)
			if self.window_fs:isFile(object:GetText()) then
				self.window.selectedFile = object:GetText()
				if self.fileinput then self.fileinput.text = normalize(self.window.selectedFile) end
			end
		end
		self.list:AddItem(i)
	end	
end

function dialog:default()
	folder = love.graphics.newImage(lovefs_dir..'/folder.png')	
	file = love.graphics.newImage(lovefs_dir..'/file.png')	
	up = love.graphics.newImage(lovefs_dir..'/up.png')	

	self.window = loveframes.Create('frame')
	self.window:SetSize(415, 395)
	self.window:Center()
	self.window.selectedFile = ''
	--self.window:SetModal(true) --multichoice and tooltip don't play well with SetModal

	local drives = loveframes.Create('multichoice', self.window)
	local tooltip = loveframes.Create('tooltip')
	tooltip:SetObject(drives)
	tooltip:SetPadding(5)
	tooltip:SetOffsets(5, -5)
	tooltip:SetText('Drives')
	drives:SetPos(5, 25+5)
	drives:SetSize(100, 25)
	drives:SetListHeight(100)
	drives:SetPadding(0)
	drives:SetSpacing(0)
	drives.OnChoiceSelected = function(object, choice)
		self.window.selectedFile = ''
		self.window_fs:cd(choice)
		self:refresh()
	end		
	local _, drive
	for _, drive in ipairs(self.window_fs.drives) do
		drives:AddChoice(drive)
	end
	drives:SetChoice(self.window_fs.drives[1])
	
	self.current = loveframes.Create('button', self.window)	
	local tooltip = loveframes.Create('tooltip')
	tooltip:SetObject(self.current)
	tooltip:SetPadding(5)
	tooltip:SetOffsets(5, -5)
	tooltip:SetText('Current Directory')
	self.current:SetPos(100+10, 25+5)
	self.current:SetSize(300, 25)
	self.current.image = folder
	self.current.checked = true
	self.current.enabled = false

	self.list = loveframes.Create('list', self.window)
	self.list:SetPos(5, 60)
	self.list:SetSize(405, 300)
	self.list:SetDisplayType('vertical')
	self.list:SetPadding(0)
	self.list:SetSpacing(0)

	local cancel = loveframes.Create('button', self.window)
	cancel:SetPos(410-75-80, 360+5)
	cancel:SetSize(75, 25)
	cancel:SetText('Cancel')
	cancel.OnClick = function(object)
		self.window:Remove()
		self = nil
	end
	local ok = loveframes.Create('button', self.window)
	ok:SetPos(410-75, 360+5)
	ok:SetSize(75, 25)
	ok:SetText('OK')
	ok.OnClick = function(object)
		if self.window.selectedFile ~= '' then
			if self.window_fs.os == 'Windows' then self.window_fs.selectedFile = self.window_fs.current..'\\'..self.window.selectedFile
			else self.window_fs.selectedFile = self.window_fs.current..'/'..self.window.selectedFile end
			self.window:Remove()
			self = nil
		end
	end
end

function loadDialog(window_fs, filters)
	local temp = {}
	setmetatable(temp, dialog)
	temp.window_fs = window_fs
	temp:default()
	local tb_filters = {}
	local _, v
	if filters then for _,v in ipairs(filters) do table.insert(tb_filters, v) end end
	temp.window:SetName('Load File')

	local filter = loveframes.Create('multichoice', temp.window)
	local tooltip = loveframes.Create('tooltip')
	tooltip:SetObject(filter)
	tooltip:SetPadding(5)
	tooltip:SetOffsets(5, -5)
	tooltip:SetText('Filter')
	filter:SetPos(5, 360+5)
	filter:SetSize(245, 25)
	filter:SetListHeight(100)
	filter:SetPadding(0)
	filter:SetSpacing(0)
	filter.OnChoiceSelected = function(object, choice)
		if choice:find('|') then window_fs:setParam(choice:sub(choice:find('|') + 1))
		else window_fs:setParam(choice) end
		temp:refresh()
	end	
	local _, f
	for _, f in ipairs(tb_filters) do
		filter:AddChoice(f)
	end
	filter:SetChoice(tb_filters[1])
	if tb_filters[1]:find('|') then window_fs:setParam(tb_filters[1]:sub(tb_filters[1]:find('|') + 1))
	else window_fs:setParam(tb_filters[1]) end
	temp:refresh()
	return temp
end

function saveDialog(window_fs)
	local temp = {}
	setmetatable(temp, dialog)
	temp.window_fs = window_fs
	temp:default()
	temp.window:SetName('Save File')

	temp.fileinput = loveframes.Create('textinput', temp.window)
	local tooltip = loveframes.Create('tooltip')
	tooltip:SetObject(temp.fileinput)
	tooltip:SetPadding(5)
	tooltip:SetOffsets(5, -5)
	tooltip:SetText('Filename')
	temp.fileinput:SetPos(5, 360+5)
	temp.fileinput:SetSize(245, 25)
	temp.fileinput.OnTextChanged = function(object, text)
		temp.window.selectedFile = object:GetText()
	end
	temp:refresh()
	return temp
end
