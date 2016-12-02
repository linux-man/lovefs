--[[------------------------------------
LoveFS LoveFrames Dialogs v1.1
Pure Lua FileSystem Access - Loveframes interface
Under the MIT license.
copyright(c) 2016 Caldas Lopes aka linux-man
--]]------------------------------------

local path = string.sub(..., 1, string.len(...) - string.len('loveframesDialog'))..'images/'
local folderImg = love.graphics.newImage(path..'folder.png')
local fileImg = love.graphics.newImage(path..'file.png')
local upImg = love.graphics.newImage(path..'up.png')
local dDir
local list
local fileinput

local function updDialog(self, lf)
	dDir:SetText(self.current)
	list:Clear()
	local i = lf.Create('button')
	i:SetSize(405, 25)
	i.image = upImg
	i:SetText('..')
	i.groupIndex = 1
	i.OnClick = function(object)
		self.dialog.selectedFile = nil
		self:up()
		updDialog(self, lf)
	end
	list:AddItem(i)
	for _, d in ipairs(self.dirs) do
		local i = lf.Create('button')
		i:SetSize(405, 25)
		i.image = folderImg
		i:SetText(d)
		i.groupIndex = 1
		i.OnClick = function(object)
			self.dialog.selectedFile = nil
			if fileinput then fileinput.text ='' end
			self:cd(object:GetText())
			updDialog(self, lf)
		end
		list:AddItem(i)
	end
	for _, f in ipairs(self.files) do
		local i = lf.Create('button')
		i:SetSize(405, 25)
		i.image = fileImg
		i:SetText(f)
		i.groupIndex = 1
		i.OnClick = function(object)
			if self:isFile(object:GetText()) then
				self.dialog.selectedFile = object:GetText() print(fileinput)
				if fileinput then fileinput:SetText(object:GetText()) end
			end
		end
		list:AddItem(i)
	end	
end

local function close(self)
	self.dialog:Remove()
	self.dialog = nil
	dDir = nil
	list = nil
	fileinput = nil
end

local function init(self, lf, label)
	self.dialog = lf.Create('frame')
	self.dialog:SetName('Load File')
	self.dialog:SetSize(415, 395)
	self.dialog:Center()
	self.dialog:SetModal(true)
	self.dialog.OnClose = function(object)
		close(self)
	end

	local drives = lf.Create('multichoice', self.dialog)
	local tooltip = lf.Create('tooltip')
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
		self.dialog.selectedFile = nil
		self:cd(choice)
		updDialog(self, lf)
	end

	for _, drive in ipairs(self.drives) do
		drives:AddChoice(drive)
	end
	drives.text = 'Change Drive'
	
	dDir = lf.Create('button', self.dialog)	
	local tooltip = lf.Create('tooltip')
	tooltip:SetObject(dDir)
	tooltip:SetPadding(5)
	tooltip:SetOffsets(5, -5)
	tooltip:SetText('Current Directory')
	dDir:SetPos(100+10, 25+5)
	dDir:SetSize(300, 25)
	dDir.image = folderImg
	dDir.checked = true
	dDir.enabled = false

	list = lf.Create('list', self.dialog)
	list:SetPos(5, 60)
	list:SetSize(405, 300)
	list:SetDisplayType('vertical')
	list:SetPadding(0)
	list:SetSpacing(0)

	local cancel = lf.Create('button', self.dialog)
	cancel:SetPos(410-75-80, 360+5)
	cancel:SetSize(75, 25)
	cancel:SetText('Cancel')
	cancel.OnClick = function(object)
		close(self)
	end
	local ok = lf.Create('button', self.dialog)
	ok:SetPos(410-75, 360+5)
	ok:SetSize(75, 25)
	ok:SetText('OK')
	ok.OnClick = function(object)
		if self.dialog.selectedFile then
			self.selectedFile = self.dialog.selectedFile
			close(self)
		end
	end
end

function filesystem:loadDialog(lf, label, filters)
	label = label or 'Load File'
	self:cd() 
	init(self, lf, label)
	local tb_filters = {}
	if filters then for _,v in ipairs(filters) do table.insert(tb_filters, v) end end

	local filter = lf.Create('multichoice', self.dialog)
	local tooltip = lf.Create('tooltip')
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
		self:setFilter(choice)
		updDialog(self, lf)
	end	
	if filters and type(filters) == "table" then
		for _, f in ipairs(filters) do filter:AddChoice(f) end
		filter:SetChoice(tb_filters[1])
		self:setFilter(tb_filters[1])
	else
		filter:SetChoice('*.*')
		self:setFilter(nil)
	end

	updDialog(self, lf)
end

function filesystem:saveDialog(lf, label)
	self.filter = nil
	label = label or 'Load File'
	self:cd()
	init(self, lf, label)

	fileinput = lf.Create('textinput', self.dialog)
	local tooltip = lf.Create('tooltip')
	tooltip:SetObject(fileinput)
	tooltip:SetPadding(5)
	tooltip:SetOffsets(5, -5)
	tooltip:SetText('Filename')
	fileinput:SetPos(5, 360+5)
	fileinput:SetSize(245, 25)
	fileinput.OnTextChanged = function(object, text)
		self.dialog.selectedFile = object:GetText()
	end
	updDialog(self, lf)
end
