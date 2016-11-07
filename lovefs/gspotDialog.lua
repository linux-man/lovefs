function filesystem:openDialog(gspot, label, filter)
	label = label or 'Load File'
	self.filter = filter
	self:cd()
	self.dialog = gspot:group(label, {love.graphics.getWidth( )/2 - 200, love.graphics.getHeight()/2 - 200, 400, 400})
	self.dialog.drag = true
	self:updDialog(gspot)
	local button = gspot:button('X', {self.dialog.pos.w - gspot.style.unit, 0}, self.dialog)
	button.click = function(this)
		self:closeDialog(gspot)
	end
	local button = gspot:button('up', {self.dialog.pos.w - gspot.style.unit, gspot.style.unit}, self.dialog)
	button.click = function(this)
		local scroll = self.dScrollGroup.scrollv
		scroll.values.current = math.max(scroll.values.min, scroll.values.current - scroll.values.step)
	end
	local button = gspot:button('dn', {self.dialog.pos.w - gspot.style.unit, self.dialog.pos.h - gspot.style.unit * 2}, self.dialog)
	button.click = function(this)
		local scroll = self.dScrollGroup.scrollv
		scroll.values.current = math.min(scroll.values.max, scroll.values.current + scroll.values.step)
	end
end

function filesystem:closeDialog(gspot)
	self.filter = nil
	gspot:rem(self.dialog)
	self.dialog = nil
end

function filesystem:updDialog(gspot)
	self.dScrollGroup = gspot:scrollgroup(nil, {0, gspot.style.unit * 2, self.dialog.pos.w - gspot.style.unit, self.dialog.pos.h - gspot.style.unit * 4}, self.dialog, 'vertical')
	local hid = gspot:hidden('', {0, 0, self.dialog.pos.w - gspot.style.unit, gspot.style.unit}, nil)
	local img = gspot:text('^', {0, 0, gspot.style.unit, gspot.style.unit}, hid)
	local btn = gspot:text('Up', {gspot.style.unit, 0, self.dialog.pos.w - gspot.style.unit * 2, gspot.style.unit}, hid)
		btn.style.fg = {200, 200, 200, 255}
		btn.enter = function(this)
			btn.style.fg = {255, 255, 255, 255}
		end
		btn.leave = function(this)
			btn.style.fg = {200, 200, 200, 255}
		end
		btn.click = function(this)
			self:up()
			gspot:rem(self.dScrollGroup)
			gspot:rem(self.dDir)
			gspot:rem(self.dFilename)
			gspot:rem(self.dOk)
			self:updDialog(gspot)
		end
		self.dScrollGroup:addchild(hid, 'vertical')

	for _, v in ipairs(fs.dirs) do
		local hid = gspot:hidden('', {0, 0, self.dialog.pos.w - gspot.style.unit, gspot.style.unit}, nil)
		local img = gspot:text(self.sep, {0, 0, gspot.style.unit, gspot.style.unit}, hid)
		local btn = gspot:text(v, {gspot.style.unit, 0, self.dialog.pos.w - gspot.style.unit * 2, gspot.style.unit}, hid)
		btn.style.fg = {200, 200, 200, 255}
		btn.enter = function(this)
			btn.style.fg = {255, 255, 255, 255}
		end
		btn.leave = function(this)
			btn.style.fg = {200, 200, 200, 255}
		end
		btn.click = function(this)
			if self:isDirectory(btn.label) then self:cd(btn.label) end
			gspot:rem(self.dScrollGroup)
			gspot:rem(self.dDir)
			gspot:rem(self.dFilename)
			gspot:rem(self.dOk)
			self:updDialog(gspot)
		end
		self.dScrollGroup:addchild(hid, 'vertical')
	end
	for _, v in ipairs(fs.files) do
		local hid = gspot:hidden('', {0, 0, self.dialog.pos.w - gspot.style.unit, gspot.style.unit}, nil)
		local btn = gspot:text(v, {gspot.style.unit, 0, self.dialog.pos.w - gspot.style.unit * 2, gspot.style.unit}, hid)
		btn.style.fg = {200, 200, 200, 255}
		btn.enter = function(this)
			btn.style.fg = {255, 255, 255, 255}
		end
		btn.leave = function(this)
			btn.style.fg = {200, 200, 200, 255}
		end
		btn.click = function(this)
			if self:isFile(btn.label) then self.dFilename.value = btn.label end
		end
		self.dScrollGroup:addchild(hid, 'vertical')
	end
	self.dDir = gspot:text(self.current, {0, gspot.style.unit, self.dialog.pos.w, gspot.style.unit}, self.dialog)
	self.dFilename = gspot:input('Filename', {gspot.style.unit * 4, self.dialog.pos.h - gspot.style.unit, self.dialog.pos.w - gspot.style.unit * 4, gspot.style.unit}, self.dialog)
	self.dFilename.done = function(this)
		if not (this.value == '') then
			self.selectedFile = self:absPath(this.value)
			self:closeDialog(gspot)
		end
	end
	self.dOk = gspot:button('OK', {self.dialog.pos.w - gspot.style.unit * 4, self.dialog.pos.h - gspot.style.unit, gspot.style.unit * 4, gspot.style.unit}, self.dialog)
	self.dOk.click = function(this, x, y, button)
		if not (self.dFilename.value == '') then
			self.selectedFile = self:absPath(self.dFilename.value)
			self:closeDialog(gspot)
		end
	end
	self.dDir.label = self.current
	self.dFilename.value = ''
end
