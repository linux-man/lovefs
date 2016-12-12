--[[------------------------------------
LoveFS Gspot Dialogs v1.2
Pure Lua FileSystem Access - Loveframes interface
Under the MIT license.
copyright(c) 2016 Caldas Lopes aka linux-man
--]]------------------------------------

local path = string.sub(..., 1, string.len(...) - string.len('gspotDialog'))..'images/'
local folderImg = love.graphics.newImage(path..'folder.png')
local fileImg = love.graphics.newImage(path..'file.png')
local upImg = love.graphics.newImage(path..'up.png')
local dScrollGroup
local dDir
local dFilename
local dOK
local drives
local filter

local function closeColGroup(colGroup)
	if colGroup then
		for _, opt in ipairs(colGroup.children) do
			if not (opt.label == '=' or opt.label == '-') then opt:hide() end
		end
		colGroup.view = false
		colGroup.control.label = '='
	end
end

local function closeDialog(self)
	self.filter = nil
	self.dialog.Gspot:rem(self.dialog)
	self.dialog = nil
	dScrollGroup = nil
	dDir = nil
	dFilename = nil
	dOK = nil
	drives = nil
	filter = nil
end

local function updDialog(self)
	local gspot = self.dialog.Gspot
	if dScrollGroup then gspot:rem(dScrollGroup) end
	if drives then gspot:rem(drives) end
	dScrollGroup = gspot:scrollgroup(nil, {0, gspot.style.unit * 2, self.dialog.pos.w - gspot.style.unit, self.dialog.pos.h - gspot.style.unit * 4}, self.dialog, 'vertical')

	drives = gspot:collapsegroup('Change Drive', {0, gspot.style.unit, gspot.style.unit * 8, gspot.style.unit}, self.dialog)
	drives.tip = 'Drives'
	for i, drive in ipairs(self.drives) do
		local option = gspot:option(drive, {0, gspot.style.unit * i, drives.pos.w, gspot.style.unit}, drives, i)
		option:hide()
		option.click = function(this)
			this.parent:toggle()
			this.parent.label = this.label
			this.parent.value = this.value
			self:cd(this.label)
			updDialog(self)
		end
	end
	drives.view = false
	drives.control.label = '='
	drives.control.click = function(this) this.parent:toggle() end

	local hid = gspot:hidden('', {0, 0, self.dialog.pos.w - gspot.style.unit, gspot.style.unit}, nil)
	local img = gspot:image('', {0, 0, gspot.style.unit, gspot.style.unit}, hid, upImg)
	local btn = gspot:text('..', {gspot.style.unit, 0, self.dialog.pos.w - gspot.style.unit * 2, gspot.style.unit}, hid)
		btn.style.fg = {200, 200, 200, 255}
		btn.enter = function(this)
			btn.style.fg = {255, 255, 255, 255}
			closeColGroup(drives) 
			closeColGroup(filter) 
		end
		btn.leave = function(this)
			btn.style.fg = {200, 200, 200, 255}
		end
		btn.click = function(this)
			self:up()
			updDialog(self)
		end
		dScrollGroup:addchild(hid, 'vertical')

	for _, v in ipairs(self.dirs) do
		local hid = gspot:hidden('', {0, 0, self.dialog.pos.w - gspot.style.unit, gspot.style.unit}, nil)
		local img = gspot:image('', {0, 0, gspot.style.unit, gspot.style.unit}, hid, folderImg)
		local btn = gspot:text(v, {gspot.style.unit, 0, self.dialog.pos.w - gspot.style.unit * 2, gspot.style.unit}, hid)
		btn.style.fg = {200, 200, 200, 255}
		btn.enter = function(this)
			btn.style.fg = {255, 255, 255, 255}
			closeColGroup(drives) 
			closeColGroup(filter) 
		end
		btn.leave = function(this)
			btn.style.fg = {200, 200, 200, 255}
		end
		btn.click = function(this)
			if self:isDirectory(btn.label) then self:cd(btn.label) end
			updDialog(self)
		end
		dScrollGroup:addchild(hid, 'vertical')
	end
	for _, v in ipairs(self.files) do
		local hid = gspot:hidden('', {0, 0, self.dialog.pos.w - gspot.style.unit, gspot.style.unit}, nil)
		local img = gspot:image('', {0, 0, gspot.style.unit, gspot.style.unit}, hid, fileImg)
		local btn = gspot:text(v, {gspot.style.unit, 0, self.dialog.pos.w - gspot.style.unit * 2, gspot.style.unit}, hid)
		btn.style.fg = {200, 200, 200, 255}
		btn.enter = function(this)
			btn.style.fg = {255, 255, 255, 255}
			closeColGroup(drives) 
			closeColGroup(filter) 
		end
		btn.leave = function(this)
			btn.style.fg = {200, 200, 200, 255}
		end
		btn.click = function(this)
			if self:isFile(btn.label) then dFilename.value = btn.label end
		end
		dScrollGroup:addchild(hid, 'vertical')
	end
	dDir.label = self.current
	dFilename.value = ''
end

local function init(self, gspot, label)
	self:cd()
	self.dialog = gspot:group(label, {love.graphics.getWidth( )/2 - 200, love.graphics.getHeight()/2 - 200, 400, 400})
	self.dialog.drag = true

	dDir = gspot:text(self.current, {gspot.style.unit * 8, gspot.style.unit, self.dialog.pos.w - gspot.style.unit * 8, gspot.style.unit}, self.dialog)
	dDir.tip = 'Current Directory'

	dOk = gspot:button('OK', {self.dialog.pos.w - gspot.style.unit * 4, self.dialog.pos.h - gspot.style.unit, gspot.style.unit * 4, gspot.style.unit}, self.dialog)
	dOk.click = function(this, x, y, button)
		if not (dFilename.value == '') then
			self.selectedFile = self:absPath(dFilename.value)
			closeDialog(self)
		end
	end

	local button = gspot:button('X', {self.dialog.pos.w - gspot.style.unit, 0}, self.dialog)
	button.click = function(this)
		closeDialog(self)
	end
	local button = gspot:button('up', {self.dialog.pos.w - gspot.style.unit, gspot.style.unit}, self.dialog)
	button.click = function(this)
		local scroll = dScrollGroup.scrollv
		scroll.values.current = math.max(scroll.values.min, scroll.values.current - scroll.values.step)
	end
	local button = gspot:button('dn', {self.dialog.pos.w - gspot.style.unit, self.dialog.pos.h - gspot.style.unit * 2}, self.dialog)
	button.click = function(this)
		local scroll = dScrollGroup.scrollv
		scroll.values.current = math.min(scroll.values.max, scroll.values.current + scroll.values.step)
	end
end

function filesystem:loadDialog(gspot, label, filters)
	if self.dialog then
		closeDialog(self)
	end
	label = label or 'Load File'
	init(self, gspot, label)
	
	filter =  gspot:collapsegroup('*.*', {0, self.dialog.pos.h - gspot.style.unit, gspot.style.unit * 8, gspot.style.unit}, self.dialog)
	filter.tip = 'Filters'
	if filters and type(filters) == "table" then
		for i, f in ipairs(filters) do
			local option = gspot:option(f, {0, gspot.style.unit * i, filter.pos.w, gspot.style.unit}, filter, i)
			option:hide()
			option.click = function(this)
				this.parent:toggle()
				this.parent.label = this.label
				this.parent.value = this.value
				self:setFilter(this.label)
				updDialog(self)
			end
		end
		filter.label = filters[1]
		self:setFilter(filters[1])
	else
		self:setFilter(nil)
	end
	filter.view = false
	filter.control.label = '='
	filter.control.click = function(this) this.parent:toggle() end

	dFilename = gspot:input(nil, {gspot.style.unit * 8, self.dialog.pos.h - gspot.style.unit, self.dialog.pos.w - gspot.style.unit * 12, gspot.style.unit}, self.dialog)

	dFilename.textinput = function(this, key) end	
	dFilename.keypress = function(this, key) end	

	updDialog(self)
end

function filesystem:saveDialog(gspot, label)
	if self.dialog then
		closeDialog(self)
	end
	label = label or 'Save File'
	self.filter = nil
	init(self, gspot, label)

	dFilename = gspot:input('Filename', {gspot.style.unit * 4, self.dialog.pos.h - gspot.style.unit, self.dialog.pos.w - gspot.style.unit * 8, gspot.style.unit}, self.dialog)

	dFilename.done = function(this)
		if not (this.value == '') then
			self.selectedFile = self:absPath(this.value)
			closeDialog(self)
		end
	end

	updDialog(self)
end
