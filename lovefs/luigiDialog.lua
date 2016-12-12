--[[------------------------------------
LoveFS Luigi Dialogs v1.0
Pure Lua FileSystem Access - Loveframes interface
Under the MIT license.
copyright(c) 2016 Caldas Lopes aka linux-man
--]]------------------------------------

local path = string.sub(..., 1, string.len(...) - string.len('luigiDialog'))..'images/'
local widgetHeight = 26
local maxScroll = 0
local nFiles = 0

local function closeDialog(self)
	self.dialog:hide()
	self.dialog = nil
end

local function updDialog(self)
	for n = 1, nFiles do
		table.remove(self.dialog.files)
	end
	self.dialog.filename.value = ''
	nFiles = #self.dirs + #self.files + 1
	local el = {type = 'button', style = 'up', text = '..'}
	self.dialog:createWidget(el)
	el:onPress(function (event)
		self:up()
		updDialog(self)
	end)
	self.dialog.files:addChild(el)
	for _, v in ipairs(self.dirs) do
		local el = {type = 'button', style = 'dir', text = v}
		self.dialog:createWidget(el)
		el:onPress(function (event)
			self:cd(event.target.text)
			updDialog(self)
		end)
		self.dialog.files:addChild(el)
	end
	for _, v in ipairs(self.files) do
		local el = {type = 'button', style = 'file', text = v}
		self.dialog:createWidget(el)
		el:onPress(function (event)
			self.dialog.filename.value = event.target.text
			self.dialog.filename:reshape()
		end)
		self.dialog.files:addChild(el)
	end
	
	maxScroll = nFiles * widgetHeight - self.dialog.files:getHeight()
	self.dialog.files.scrollY = 0
	self.dialog.files:reshape()
	self.dialog.slidey.value = 1
	self.dialog.current.text = self.current
end

local function init(self, Layout, label)
	self:cd()
	self.dialog = Layout(
		{type = 'submenu', width = 600, height = 400,
			{style = 'default', type = 'panel', align = 'middle center', text = label},
			{style = 'default', flow = 'x',
				{style = 'comboButton', id = 'drives', text = 'Change Drive'},
				{style = 'default', align = 'middle left', id = 'current'},
			},
			{padding = 0, flow = 'x',
				{id = 'files', padding = 0, flow = 'y', scroll = true}, 
				{id = 'slidey', type = 'slider', width = 24, value = 1, flow = 'y'}
			},
			{flow = 'x', style = 'default',
				{style = 'comboButton', id = 'filters', text = 'All | *.*'},
				{style = 'default', align = 'middle left', type = 'text', id = 'filename', text = ''},
				{style = 'dialogButton', id = 'cancelButton', text = 'Cancel'},
				{style = 'dialogButton', id = 'okButton', text = 'OK'}
			}
		}
	)

	self.dialog:setStyle(
		{
			default = {
				height = widgetHeight,
				margin = 0
			},
			dialogButton = {
				type = 'button',
				width = 80,
				height = widgetHeight,
				margin = 0
			},
			comboButton = {
				type = 'button',
				width = 140,
				height = widgetHeight,
				margin = 0
			},
			up = {
				type = 'button',
				align = 'left middle',
				icon = path..'up.png',
				height = widgetHeight,
				margin = 0
			},
			dir = {
				align = 'left middle',
				icon = path..'folder.png',
				height = widgetHeight,
				margin = 0
			},
			file = {
				align = 'left middle',
				icon = path..'file.png',
				height = widgetHeight,
				margin = 0
			}
		}
	)

	self.dialog.drives:onPress(function (event)
		local menu = {isContextMenu = true}
		for i, drive in ipairs(self.drives) do
			menu[#menu + 1] = {text = drive}
		end
		self.dialog:createWidget({type = 'menu', menu })
		menu.menuLayout:onPress(function (event)
			self.dialog.drives.text = event.target.text
			self:cd(event.target.text)
			updDialog(self)
		end)
		menu.menuLayout:placeNear(self.dialog.drives:getX(), self.dialog.drives:getY() + self.dialog.drives:getHeight())
		menu.menuLayout:show()
	end)

	self.dialog.slidey:onChange(function (event)
		self.dialog.files.scrollY = (1 - event.value) * maxScroll
		self.dialog.files:reshape()
	end)

	self.dialog.files:onWheelMove(function (event)
		self.dialog.slidey.value = 1 - self.dialog.files.scrollY / maxScroll
	end)

	self.dialog.cancelButton:onPress(function (event)
		closeDialog(self)
	end)

	self.dialog.okButton:onPress(function (event)
		if not(self.dialog.filename.value == '') then
			self.selectedFile = self:absPath(self.dialog.filename.value)
			closeDialog(self)
		end
	end)
end

function filesystem:loadDialog(Layout, label, filters)
	if self.dialog then closeDialog(self) end
	label = label or 'Load File'
	init(self, Layout, label)
	self.dialog.filename.type = 'panel'
	if filters and type(filters) == "table" then
		self.dialog.filters:onPress(function (event)
			local menu = {isContextMenu = true}
			for i, f in ipairs(filters) do
				menu[#menu + 1] = {text = f}
			end		
			self.dialog:createWidget({type = 'menu', menu })
			menu.menuLayout:onPress(function (event)
				self.dialog.filters.text = event.target.text
				self:setFilter(event.target.text)
				updDialog(self)
			end)
			menu.menuLayout:placeNear(self.dialog.filters:getX(), self.dialog.filters:getY() + self.dialog.filters:getHeight())
			menu.menuLayout:show()
		end)
		self.dialog.filters.text = filters[1]
		self:setFilter(filters[1])
	else
		self.dialog.filters.text = '*.*'
		self:setFilter(nil)
	end
	updDialog(self)
	self.dialog:show()
end

function filesystem:saveDialog(gspot, label)
	if self.dialog then closeDialog(self) end
	label = label or 'Save File'
	init(self, Layout, label)
	self.dialog.filters.width = 0
	self:setFilter(nil)
	updDialog(self)
	self.dialog:show()
end
