--[[------------------------------------
LoveFS v1.2
Pure Lua FileSystem Access
Under the MIT license.
copyright(c) 2020 Caldas Lopes aka linux-man
--]]------------------------------------

local ffi = require("ffi")

ffi.cdef[[
	#pragma pack(push)
	#pragma pack(1)
	struct WIN32_FIND_DATAW {
		uint32_t dwFileWttributes;
		uint64_t ftCreationTime;
		uint64_t ftLastAccessTime;
		uint64_t ftLastWriteTime;
		uint32_t dwReserved[4];
		char cFileName[520];
		char cAlternateFileName[28];
	};
	#pragma pack(pop)
	
	void* FindFirstFileW(const char* pattern, struct WIN32_FIND_DATAW* fd);
	bool FindNextFileW(void* ff, struct WIN32_FIND_DATAW* fd);
	bool FindClose(void* ff);
	bool CopyFileW(const char* src, const char* dst, bool bFailIfExists);
	int GetLogicalDrives(void);
	
	int MultiByteToWideChar(unsigned int CodePage, uint32_t dwFlags, const char* lpMultiByteStr,
		int cbMultiByte, const char* lpWideCharStr, int cchWideChar);
	int WideCharToMultiByte(unsigned int CodePage, uint32_t dwFlags, const char* lpWideCharStr,
		int cchWideChar, const char* lpMultiByteStr, int cchMultiByte,
		const char* default, int* used);
]]

-- TODO: this also applies to other BSDs
if ffi.os == "OSX" then
	ffi.cdef [[
		struct dirent {
			unsigned int d_fileno;     /* inode number */
			unsigned short d_reclen;   /* length of this record */
			char d_type;               /* type of file; not supported by all filesystem types */
			char d_namlen;             /* length of filename */
			char d_name[256];           /* filename */
		};
	]]
else
	ffi.cdef[[
		struct dirent {
			unsigned long  d_ino;       /* inode number */
			unsigned long  d_off;       /* not an offset */
			unsigned short d_reclen;    /* length of this record */
			unsigned char  d_type;      /* type of file; not supported by all filesystem types */
			char           d_name[256]; /* filename */
		};
	]]
end

ffi.cdef[[
		struct DIR *opendir(const char *name);
		struct dirent *readdir(struct DIR *dirstream);
		int closedir (struct DIR *dirstream);
]]

local WIN32_FIND_DATA = ffi.typeof('struct WIN32_FIND_DATAW')
local INVALID_HANDLE = ffi.cast('void*', -1)

local function u2w(str, code)
	local size = ffi.C.MultiByteToWideChar(code or 65001, 0, str, #str, nil, 0)
	local buf = ffi.new("char[?]", size * 2 + 2)
	ffi.C.MultiByteToWideChar(code or 65001, 0, str, #str, buf, size * 2)
	return buf
end

local function w2u(wstr, code)
	local size = ffi.C.WideCharToMultiByte(code or 65001, 0, wstr, -1, nil, 0, nil, nil)
	local buf = ffi.new("char[?]", size + 1)
	size = ffi.C.WideCharToMultiByte(code or 65001, 0, wstr, -1, buf, size, nil, nil)
	return ffi.string(buf)
end

local function join(tb1, tb2)
	local tb = {}
	for _,v in ipairs(tb1) do table.insert(tb, v) end
	for _,v in ipairs(tb2) do table.insert(tb, v) end
	return tb
end

local function findValue(tb, value)
	for _, v in ipairs(tb) do 
		if v == value then return true end
	end
	return false
end

local function removeValue(tb, value)
	for n = #tb, 1, -1 do
		if value == 'hidden' then
			if tb[n]:match('^%..') then table.remove(tb, n) end
		else
			if tb[n] == value then table.remove(tb, n) end
		end
	end
end

filesystem = {}
filesystem.__index = filesystem

function filesystem:absPath(path)
	if path == '.' then path = self.current end
	if (path:sub(1,2) == '.'..self.sep) then path = self.current..path:sub(2) end
	if self.win then
		if not (path:sub(2,2) == ':') then path = self.current..self.sep..path end
		path = path:gsub('/', self.sep)
	else
		if not (path:sub(1,1) == '/') then path = self.current..self.sep..path end
		path = path:gsub('\\', self.sep)
	end
	path = path:gsub(self.sep..self.sep, self.sep)
	if #path > 1 and path:sub(-1) == self.sep then path = path:sub(1, -2) end
	return path
end

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

function filesystem:ls(dir) 
	dir = dir or self.current
	dir = self:absPath(dir)
	local tDirs = {}
	local tFiles = {}
	if self.win then
		local fd = ffi.new(WIN32_FIND_DATA)
		local hFile = ffi.C.FindFirstFileW(u2w(dir..'\\*'), fd)
		ffi.gc(hFile, ffi.C.FindClose)
		if hFile ~= INVALID_HANDLE then
			repeat
				local fn = w2u(fd.cFileName)
				if fd.dwFileWttributes == 16 or fd.dwFileWttributes == 17 or (self.showHidden and fd.dwFileWttributes == 8210) then
					table.insert(tDirs, fn)
				elseif fd.dwFileWttributes == 32 then
					table.insert(tFiles, fn)
				end
			until not ffi.C.FindNextFileW(hFile, fd)
		end
		ffi.C.FindClose(ffi.gc(hFile, nil))
	else
		local hDir = ffi.C.opendir(dir)
		ffi.gc(hDir, ffi.C.closedir)
		if hDir ~= nil then
			local dirent = ffi.C.readdir(hDir)
			while dirent ~= nil do
				local fn = ffi.string(dirent.d_name)
				if dirent.d_type == 4 then
					table.insert(tDirs, fn)
				elseif dirent.d_type == 8 then
					table.insert(tFiles, fn)
				elseif dirent.d_type == 10 then -- handle symlinks
					if self:isDirectory(dir..'/'..fn) then
						table.insert(tDirs, fn)
					else
						table.insert(tFiles, fn)
					end
				end
				dirent = ffi.C.readdir(hDir)
			end
		end
		ffi.C.closedir(ffi.gc(hDir, nil))
	end
	if #tDirs == 0 then return false end
	removeValue(tDirs, '.')
	removeValue(tDirs, '..')
	if not (self.win or self.showHidden) then removeValue(tDirs, 'hidden') end
	table.sort(tDirs)
	if self.filter then
		for n = #tFiles, 1, -1 do
			local ext = tFiles[n]:match('[^.]+$')
			local valid = false
			for _, v in ipairs(self.filter) do
				valid = valid or (ext == v)
			end
			if not (valid) then table.remove(tFiles, n) end
		end
	end
	if not self.showHidden then removeValue(tFiles, 'hidden') end
	table.sort(tFiles)
	
	return dir, tDirs, tFiles, join(tDirs, tFiles)
end

function filesystem:dir(dir)
	return self:ls(dir)
end

if OS == 'Windows' then
    function filesystem:readlink()
        return nil, "could not obtain link target: Function not implemented "
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
else
	ffi.cdef [[
		struct stat{
			unsigned long   st_dev;
			unsigned long   st_ino;
			unsigned long   st_nlink;
			unsigned int    st_mode;
			unsigned int    st_uid;
			unsigned int    st_gid;
			unsigned int    __pad0;
			unsigned long   st_rdev;
			long            st_size;
			long            st_blksize;
			long            st_blocks;
			unsigned long   st_atime;
			unsigned long   st_atime_nsec;
			unsigned long   st_mtime;
			unsigned long   st_mtime_nsec;
			unsigned long   st_ctime;
			unsigned long   st_ctime_nsec;
			long            __unused[3];
		};
		long syscall(int number, ...);
		ssize_t readlink(const char *path, char *buf, size_t bufsize);
	]]
	
	function filesystem:readlink(link_path)
		link_path = link_path or self.current
		local size = 512
        local buf = ffi.new('char[?]', size + 1)
        local read = ffi.C.readlink(link_path, buf, size)
        if read == -1 then
            return nil, "could not obtain link target."
        end
        if read > size then
            return nil, "not enough buffer-size for readlink."
        end
        buf[size] = 0
        return ffi.string(buf)
	end
	
	function filesystem:stat(file)
		file = file or self.current
		local buf = ffi.new('struct stat')
		if ffi.C.syscall(4, file, buf) == -1 then
			return nil, "Could not stat file"
		else
			return {
				dev = buf.st_dev,
				ino = buf.st_ino,
				nlink = buf.st_nlink,
				mode = buf.st_mode,
				uid = buf.st_uid,
				gid = buf.st_gid,
				rdev = buf.st_rdev,
				size = buf.st_size,
				blksize = buf.st_blksize,
				blocks = buf.st_blocks,
				atime = buf.st_atime,
				atime_nsec = buf.st_atime_nsec,
				mtime = buf.st_mtime,
				mtime_nsec = buf.st_mtime_nsec,
				ctime = buf.st_ctime,
				ctime_nsec = buf.st_ctime_nsec
			}
		end
	end

	function filesystem:isDirectory(path)
		local s, err = self:stat(path)
		return bit.band(s.mode, 61440) == 16384
	end

	function filesystem:isFile(path)
		local s, err = self:stat(path)
		return bit.band(s.mode, 61440) == 32768
	end

	function filesystem:isLink(path)
		local s, err = self:stat(path)
		return bit.band(s.mode, 61440) == 40960
	end

	function filesystem:isChar(path)
		local s, err = self:stat(path)
		return bit.band(s.mode, 61440) == 8192
	end

	function filesystem:isBlock(path)
		local s, err = self:stat(path)
		return bit.band(s.mode, 61440) == 24576
	end
end

function filesystem:cd(dir)
	current, tDirs, tFiles, tAll = self:ls(dir)
	if current then
		self.current = current
		self.dirs = tDirs
		self.files = tFiles
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
	dir, dirs, files, all = self:ls(dir)
	if dir then
		return findValue(all, name), findValue(dirs, name), findValue(files, name)
	end
	return false
end

function filesystem:updDrives()
	drives = {}
	if self.win then
		aCode = string.byte('A')
		drv = ffi.C.GetLogicalDrives()
		for n = 0, 15, 1 do
			if not(drv % 2 == 0) then table.insert(drives, string.char(aCode + n)..':\\') end
			drv = math.floor(drv / 2)
		end
	elseif ffi.os == 'Linux' then
		dir, dirs = self:ls('/media')
		if dir then
			for n, d in ipairs(dirs) do dirs[n] = '/media/'..dirs[n] end
			drives = dirs
		end
		table.insert(drives, 1, '/')
	else
		dir, dirs = self:ls('/Volumes')
		if dir then
			for n, d in ipairs(dirs) do dirs[n] = '/Volumes/'..dirs[n] end
			drives = dirs
		end
		table.insert(drives, 1, '/')
	end
	self.drives = drives
end

function filesystem:copy(source, dest)
	if self.win then
		ffi.C.CopyFileW(u2w(source), u2w(dest), false)
	else
		local inp = assert(io.open(source, "rb"))
		local out = assert(io.open(dest, "wb"))
		local data = inp:read("*all")
		out:write(data)
		assert(out:close())
    end
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
	return love.audio.newSource('lovefs_temp/temp.'..ext)
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
	local id = canvas:newImageData()
	id:encode('png', 'lovefs_temp/temp.file')
	love.graphics.setCanvas()
	self:copy(love.filesystem.getSaveDirectory()..'/lovefs_temp/temp.file', dest)
	return true
end

function lovefs(dir)
	local temp = {}
	setmetatable(temp, filesystem)
	temp.win = ffi.os == "Windows"
	temp.selectedFile = nil
	temp.filter = nil
	temp.showHidden = false
	-- luajit support
	if love then
		temp.home = love.filesystem.getUserDirectory()
	else
		temp.home = os.getenv("HOME")
	end
	temp.current = temp.home
	temp.sep = package.config:sub(1,1)
	dir = dir or temp.home
	if not temp:cd(dir) then
		if not temp:cd(temp.home) then
			if temp.win then temp:cd('c:'..sep)
			else temp:cd(sep) end
		end
	end
	temp:updDrives()
	return temp
end
