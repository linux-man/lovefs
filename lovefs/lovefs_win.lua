--[[------------------------------------
LoveFS v2.0
Pure Lua FileSystem Access
Under the MIT license.
copyright(c) 2025 Caldas Lopes aka linux-man
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
	if not (path:sub(2,2) == ':') then path = self.current..self.sep..path end
	path = path:gsub('/', self.sep)
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
	local fd = ffi.new(WIN32_FIND_DATA)
	local hFile = ffi.C.FindFirstFileW(u2w(dir..'\\*'), fd)
	ffi.gc(hFile, ffi.C.FindClose)
	if hFile ~= INVALID_HANDLE then
		repeat
			local fn = w2u(fd.cFileName)
			if fd.dwFileWttributes == 0x10 or fd.dwFileWttributes == 0x11 or (self.showHidden and fd.dwFileWttributes == 0x2012) then
				table.insert(tDirs, fn)
			elseif fd.dwFileWttributes == 0x20 or fd.dwFileWttributes == 0x2020 then
				table.insert(tFiles, fn)
			end
		until not ffi.C.FindNextFileW(hFile, fd)
	end
	ffi.C.FindClose(ffi.gc(hFile, nil))
	if #tDirs == 0 then return false end
	removeValue(tDirs, '.')
	removeValue(tDirs, '..')
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
	return dir, tDirs, tFiles, tOthers, join(tDirs, tFiles)
end

function filesystem:updDrives()
	drives = {}
	aCode = string.byte('A')
	drv = ffi.C.GetLogicalDrives()
	for n = 0, 15, 1 do
		if not(drv % 2 == 0) then table.insert(drives, string.char(aCode + n)..':\\') end
		drv = math.floor(drv / 2)
	end
	self.drives = drives
end

function filesystem:copy(source, dest)
	ffi.C.CopyFileW(u2w(source), u2w(dest), false)
end

--https://github.com/3scale/luafilesystem-ffi/blob/master/lfs_ffi.lua
------------------------------ stat ------------------------------------
local bit = require("bit")
local band, bnot, rshift = bit.band, bit.bnot, bit.rshift
local concat = table.concat

local has_table_new, new_tab = pcall(require, "table.new")
if not has_table_new or type(new_tab) ~= "function" then
	new_tab = function () return {} end
end

local stat_func
local lstat_func

ffi.cdef([[
	typedef struct {
		unsigned int        st_dev;
		unsigned short      st_ino;
		unsigned short      st_mode;
		short               st_nlink;
		short               st_uid;
		short               st_gid;
		unsigned int        st_rdev;
		int64_t             st_size;
		long long           st_atime;
		long long           st_mtime;
		long long           st_ctime;
	} stat;
	int _stat64(const char *path, stat *buffer);
]])

stat_func = ffi.C._stat64
lstat_func = stat_func

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

local mt = {
	__index = function(self, attr_name)
		local func = attr_handlers[attr_name]
		return func and func(self)
	end
}
local stat_type = ffi.metatype('stat', mt)

local function attributes(filepath, attr)
	local buf = ffi.new(stat_type)
	local func = stat_func or lstat_func
	if func(filepath, buf) == -1 then
		return nil, errno()
	end

	local atype = type(attr)
	if atype == 'string' then
		local value
		value = buf[attr]
		if value == nil then
			error("invalid attribute name '" .. attr .. "'")
		end
		return value
	else
		local tab = (atype == 'table') and attr or {}
		for k, _ in pairs(attr_handlers) do
			tab[k] = buf[k]
		end
		return tab
	end
end

function filesystem:attr(filepath, attr)
	return attributes(filepath, attr)
end
------------------------------ end stat --------------------------------
