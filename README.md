# lovefs

Load and save files outside `love.filesystem`.

## with ffi

The ffi code was mostly adapted (with my sincerest gratitude) from

* [fi-luajit](https://github.com/nyfair/fi-luajit) (Windows)
* [pflua](https://github.com/Igalia/pflua) (Posix).

`attr` function was adapted from 
* [luafilesystem-ffi](https://github.com/3scale/luafilesystem-ffi/blob/master/lfs_ffi.lua)

```lua
-- dir is [string], if no dir is given, start on UserDirectory
fs = lovefs(dir)
```
## [lovefs.lua](lovefs/lovefs.lua)

### members

```lua
-- Current Directory [string] (don't change it, use fs:cd(dir))
fs.current

-- drives, directories and files [tables] of current dir
fs.drives
fs.dirs
fs.files
fs.others (POSIX links and devices)
fs.all

--  [string] used by fs:loadImage, fs:loadSource, fs:loadFont and fs:saveImage if no source is given
fs.selectedFile

-- user directory [string]
fs.home

-- [table] with extensions, like {'jpg', 'png'}. Used by fs:ls to filter files. Don't forget to NIL!
fs.filter

-- Show or hide hidden files and directories. Default: FALSE
fs.showHidden
```

### methods

```lua
-- update drives list
fs:updDrives() 
```

These functions accept absolute and relative (to current) paths:

```lua
-- return dir (absolute path) [string], tDirs, tFiles, tOthers, tAll [tables]. Return FALSE if dir don't exist. Alias: fs:dir(dir)
fs:ls(dir)

-- return TRUE if exists [boolean]
fs:exists(path)

 -- return TRUE if is directory. [boolean]
fs:isDirectory(path)

 -- return TRUE if is file. [boolean]
fs:isFile(path)

-- Change directory. Populate fs.dirs and fs.files and fs.all with the new directory contents. Return TRUE if successful
fs:cd(dir)

-- move to parent directory (using cd())
fs:up()

-- filter can be [nil, table or string]. sets fs.filter and calls fs:cd().
-- String can be 'File type | *.ext1 *.ext2'
fs:setFilter(filter) 

-- switch fs.showHidden
fs:switchHidden()

-- return absolute paths
fs:absPath(path)

 -- return image. Use fs.selectedFile if no source is given
fs:loadImage(source)

--return sound. Use fs.selectedFile if no source is given
fs:loadSource(source) 

--return font. Use fs.selectedFile if no source is given
fs:loadFont(size, source)

-- Need Canvas support. Return FALSE on failure. Use fs.selectedFile if no source is given
fs:saveImage(img, dest)

-- copy file, this function only accept absolute paths
fs:copy(source, dest)

-- return a table of file attributes
fs:attr(path)

-- return a file attribute value
fs:attr(path, attr)

-- (POSIX systems: follow_Symlink[boolean])
fs:attr(path, [attr or nil], follow_symlink)
```


## dialogs

These are ready-made dialogs for various UI libraries.

Example filter:

```lua
{'All | *.*', 'Image | *.jpg *.png *.bmp', 'Sound | *.mp3 *.wav'}
```

When the user presses OK, the selected file is available in `fs.selectedFile`

### [luigiDialog.lua](lovefs/luigiDialog.lua)

Use this to make a file-browser dialog with [LUIGI](https://love2d.org/wiki/LUIGI).

```lua
-- show a load dialog, without a layout
fs:loadDialog(gui, label, filters)

-- use with a layout
fs:loadDialog(gui.Layout, label, filters)


-- show a save dialog, without a layout
fs:saveDialog(gui, label)

-- use with a layout
fs:saveDialog(gui.Layout, label)
```

### [loveframesDialog.lua](lovefs/loveframesDialog.lua)

Use this to make a file-browser dialog with [loveframes](https://github.com/linux-man/LoveFrames).

```lua
-- show a load dialog
fs:loadDialog(lf, label, filters)

-- show a save dialog
fs:saveDialog(lf, label)
```

### [gspotDialog.lua](lovefs/gspotDialog.lua)

Use this to make a file-browser dialog with [gspot](https://notabug.org/pgimeno/Gspot).

```lua
-- show a load dialog
fs:loadDialog(gspot, label, filters)

-- show a save dialog
fs:saveDialog(gspot, label)
```

### slab

[Slab](https://github.com/coding-jackalope/Slab) has some nice UI elements built-in, that use this library, as well.

### attr example
```lua
require('lovefs')
fs = lovefs()
fs:ls()

print('Current Dir:', fs.current)
for key, value in pairs(fs.all) do
	print(key, value)
	t = fs:attr(fs:absPath(value))
	for _, a in pairs(t) do
		print('\t', _, a)
	end
	print('\t', 'Human readable time')
	print('\t', 'modification', os.date(_, tostring(t['modification'], 'atime')))
	print('\t', 'access', os.date(_, tostring(t['access'], 'atime')))
	print('\t', 'change', os.date(_, tostring(t['change'], 'atime')))
end

-- POSIX Symlinks
print('Following links')
for key, value in pairs(fs.others) do
	print(key, value)
t = fs:attr(fs:absPath(value), nil, true)
	for _, a in pairs(t) do
		print('\t', _, a)
	end
	print('\t', 'Human readable time')
	print('\t', 'modification', os.date(_, tostring(t['modification'], 'atime')))
	print('\t', 'access', os.date(_, tostring(t['access'], 'atime')))
	print('\t', 'change', os.date(_, tostring(t['change'], 'atime')))
end

--[[
attribs = {
"access",
"blksize",
"blocks",
"change",
"dev",
"gid",
"ino",
"mode",
"modification",
"nlink",
"permissions",
"rdev",
"size",
"uid"}

"target" for symlinks
]]--
```
## without ffi

You can also use [lovefs-noffi](./lovefs-noffi), if you need support for pre-ffi love2d (before love 11), or you just want to not use FFI. It has it's own [README](lovefs-noffi/README.md). It uses `popen` to call commands from the OS, so it's a bit slower, but maybe more cross-platform, in some situations.
