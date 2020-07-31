# lovefs-noffi

This is an old, unmaintained version of loveFS, hosted here for historical and affective reasons. Only usefull if there is no "ffi" access (like in the case of love pre-11.)

### Reference:

```lua
-- if no dir is given, start on UserDirectory
fs = lovefs(dir[string])
```

## [lovefs.lua](lovefs.lua)

### members

```lua
-- Current Directory [string] (don't change it, use fs:cd(dir))
fs.current

-- [tables] drives directories and files in current dir
fs.drives
fs.files
fs.dirs
```

### methods

```lua
-- Used by :cd() to populate fs.dirs and fs.files
fs:setParam(param)

-- return file list (table and string). Alias: fs:dir(param, dir)
fs:ls(param, dir)

-- return drives (table)
fs:lsDrives()

-- return directories (table and string)
fs:lsDirs(param, dir)

-- return files (table and string)
fs:lsFiles(param, dir)

-- return TRUE if exists.
fs:exists(name, dir)

-- return TRUE if directory.
fs:isDirectory(name, dir)

-- return TRUE if is file. 
fs:isFile(name, dir)

-- Change directory. Populate fs.dirs and fs.files with the new directory contents.
-- Note: if dir is NIL current directory is used
fs:cd(dir)

-- same as fs:cd:('..')
fs:up()

-- copy file
fs:copy(source, dest)

-- return image
fs:loadImage(source)

--return sound
fs:loadSource(source)

--return font
fs:loadFont(size, source)

-- Need Canvas support. Return FALSE on failure
fs:saveImage(img, dest)
```

#### internal

These are for internal-use, but you might need them for something:

```lua
-- Load terminal codepage. Use only for testing. Return FALSE if codepage is not supported.
-- Supported codepages: '737', '775', '850', '852', '855', '866', '8859-1', '8859-2', '8859-4', '8859-5', '8859-7', '8859-15', '8859-16', 'KOI8-R', 'KOI8-U'
fs:loadCp(codepage[string])

-- translate string to utf-8
fs:toUtf8(str)

-- translate string to current codepage
fs:toCp(str)

-- return Windows path in 8.3 format
fs:path8p3(dir, all)

-- Execute command on console
fs:run(command)
```

### [dialogs.lua](dialogs.lua)

Load and Save Dialog using LoveFrames (modified.)

```lua
-- create a load-dialog
dialog = loadDialog(window_fs, filters)

-- create a save-dialog
dialog = saveDialog(window_fs, filters)
```

Example:

```lua
fs = fsload()
dialog = loadDialog(fs, {'All | *.*', 'Images | *.jpg *.bmp *.png'})
```

On close with OK, the path of the chosen file is at `fs.selectedFile`
