--[[------------------------------------
LoveFS v2.0
Pure Lua FileSystem Access
Under the MIT license.
copyright(c) 2025 Caldas Lopes aka linux-man
--]]------------------------------------

local ffi = require("ffi")

ffi.cdef[[
	struct dirent {
		unsigned long  d_ino;       /* inode number */
		unsigned long  d_off;       /* not an offset */
		unsigned short d_reclen;    /* length of this record */
		unsigned char  d_type;      /* type of file; not supported by all filesystem types */
		char           d_name[256]; /* filename */
	};
]]

ffi.cdef[[
		struct DIR *opendir(const char *name);
		struct dirent *readdir(struct DIR *dirstream);
		int closedir (struct DIR *dirstream);
]]

local function join(tb1, tb2, tb3)
	local tb = {}
	for _,v in ipairs(tb1) do table.insert(tb, v) end
	for _,v in ipairs(tb2) do table.insert(tb, v) end
	for _,v in ipairs(tb3) do table.insert(tb, v) end
	return tb
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

function filesystem:absPath(path)
	if path == '.' then path = self.current end
	if (path:sub(1,2) == '.'..self.sep) then path = self.current..path:sub(2) end
	if not (path:sub(1,1) == '/') then path = self.current..self.sep..path end
	path = path:gsub('\\', self.sep)
	path = path:gsub(self.sep..self.sep, self.sep)
	if #path > 1 and path:sub(-1) == self.sep then path = path:sub(1, -2) end
	return path
end

function filesystem:ls(dir)
	dir = dir or self.current
	dir = self:absPath(dir)
	local tDirs = {}
	local tFiles = {}
	local tOthers = {}
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
			else
				table.insert(tOthers, fn)
			end
			dirent = ffi.C.readdir(hDir)
		end
	end
	ffi.C.closedir(ffi.gc(hDir, nil))
	if #tDirs == 0 then return false end
	removeValue(tDirs, '.')
	removeValue(tDirs, '..')
	if not (self.showHidden) then removeValue(tDirs, 'hidden') end
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
	if not self.showHidden then removeValue(tOthers, 'hidden') end
	table.sort(tFiles)
	table.sort(tOthers)
	return dir, tDirs, tFiles, tOthers, join(tDirs, tFiles, tOthers)
end

function filesystem:updDrives()
	drives = {}
	dir, dirs = self:ls('/media')
	if dir then
		for n, d in ipairs(dirs) do dirs[n] = '/media/'..dirs[n] end
		drives = dirs
	end
	table.insert(drives, 1, '/')
	self.drives = drives
end

function filesystem:copy(source, dest)
	local inp = assert(io.open(source, "rb"))
	local out = assert(io.open(dest, "wb"))
	local data = inp:read("*all")
	out:write(data)
	assert(out:close())
end

--https://github.com/3scale/luafilesystem-ffi/blob/master/lfs_ffi.lua
------------------------------ stat ------------------------------------
local MAXPATH = 4096
local bit = require("bit")
local band, bnot, rshift = bit.band, bit.bnot, bit.rshift
local concat = table.concat

local has_table_new, new_tab = pcall(require, "table.new")
if not has_table_new or type(new_tab) ~= "function" then
	new_tab = function () return {} end
end

local stat_func
local lstat_func

ffi.cdef([[long syscall(int number, ...);]])

local stat_syscall_num
local lstat_syscall_num

ffi.cdef([[
	typedef struct {
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
	} stat;
]])
stat_syscall_num = 4
lstat_syscall_num = 6

if stat_syscall_num then
	stat_func = function(filepath, buf)
		return ffi.C.syscall(stat_syscall_num, filepath, buf)
	end
	lstat_func = function(filepath, buf)
		return ffi.C.syscall(lstat_syscall_num, filepath, buf)
	end
else
	ffi.cdef('typedef struct {} stat;')
	stat_func = function() error("TODO support other Linux architectures") end
	lstat_func = stat_func
end

local STAT = {
	FMT   = 0xF000,
	FSOCK = 0xC000,
	FLNK  = 0xA000,
	FREG  = 0x8000,
	FBLK  = 0x6000,
	FDIR  = 0x4000,
	FCHR  = 0x2000,
	FIFO  = 0x1000,
}

local ftype_name_map = {
	[STAT.FREG]  = 'file',
	[STAT.FDIR]  = 'directory',
	[STAT.FLNK]  = 'link',
	[STAT.FSOCK] = 'socket',
	[STAT.FCHR]  = 'char device',
	[STAT.FBLK]  = "block device",
	[STAT.FIFO]  = "named pipe",
}

ffi.cdef([[
	char* strerror(int errnum);
]])

local function errno()
	return ffi.string(ffi.C.strerror(ffi.errno()))
end

local function mode_to_ftype(mode)
	local ftype = band(mode, STAT.FMT)
	return ftype_name_map[ftype] or 'other'
end

local function mode_to_perm(mode)
	local perm_bits = band(mode, tonumber(777, 8))
	local perm = new_tab(9, 0)
	local i = 9
	while i > 0 do
		local perm_bit = band(perm_bits, 7)
		perm[i] = (band(perm_bit, 1) > 0 and 'x' or '-')
		perm[i-1] = (band(perm_bit, 2) > 0 and 'w' or '-')
		perm[i-2] = (band(perm_bit, 4) > 0 and 'r' or '-')
		i = i - 3
		perm_bits = rshift(perm_bits, 3)
	end
	return concat(perm)
end

local function time_or_timespec(time, timespec)
	local t = tonumber(time)
	if not t and timespec then
		t = tonumber(timespec.tv_sec)
	end
	return t
end

local attr_handlers = {
	access = function(st) return time_or_timespec(st.st_atime, st.st_atimespec) end,
	blksize = function(st) return tonumber(st.st_blksize) end,
	blocks = function(st) return tonumber(st.st_blocks) end,
	change = function(st) return time_or_timespec(st.st_ctime, st.st_ctimespec) end,
	dev = function(st) return tonumber(st.st_dev) end,
	gid = function(st) return tonumber(st.st_gid) end,
	ino = function(st) return tonumber(st.st_ino) end,
	mode = function(st) return mode_to_ftype(st.st_mode) end,
	modification = function(st) return time_or_timespec(st.st_mtime, st.st_mtimespec) end,
	nlink = function(st) return tonumber(st.st_nlink) end,
	permissions = function(st) return mode_to_perm(st.st_mode) end,
	rdev = function(st) return tonumber(st.st_rdev) end,
	size = function(st) return tonumber(st.st_size) end,
	uid = function(st) return tonumber(st.st_uid) end,
}

-- Add target field for symlinkattributes, which is the absolute path of linked target
local get_link_target_path

ffi.cdef('unsigned long readlink(const char *path, char *buf, size_t bufsize);')
function get_link_target_path(link_path)
	local size = MAXPATH
	while true do
		local buf = ffi.new('char[?]', 512)
		local read = ffi.C.readlink(link_path, buf, size)
		if read == -1 then
			return nil, errno()
		end
		if read < size then
			return ffi.string(buf)
		end
		size = size * 2
	end
end

local mt = {
	__index = function(self, attr_name)
		local func = attr_handlers[attr_name]
		return func and func(self)
	end
}
local stat_type = ffi.metatype('stat', mt)

local function attributes(filepath, attr, follow_symlink)
	local buf = ffi.new(stat_type)
	local func = follow_symlink and stat_func or lstat_func
	if func(filepath, buf) == -1 then
		return nil, errno()
	end

	local atype = type(attr)
	if atype == 'string' then
		local value
		if attr == 'target' and not follow_symlink then
			value = get_link_target_path(filepath)
		else
			value = buf[attr]
		end
		if value == nil then
			error("invalid attribute name '" .. attr .. "'")
		end
		return value
	else
		local tab = (atype == 'table') and attr or {}
		for k, _ in pairs(attr_handlers) do
			tab[k] = buf[k]
		end
		if not follow_symlink then
			tab.target =  get_link_target_path(filepath)
		end
		return tab
	end
end

function filesystem:attr(filepath, attr, follow_symlink)
	if(follow_symlink == nil) then follow_symlink = false end
	return attributes(filepath, attr, follow_symlink)
end
------------------------------ end stat --------------------------------
