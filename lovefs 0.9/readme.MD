## This is an old, unmaintained version of loveFS, hosted here for historical and affective reasons. Only usefull if there is no "ffi" access.

Reference:

fs = lovefs(dir[string]) -- if no dir is given, start on UserDirectory

---------------------------------------- lovefs.lua -------------------------------------------------

fs.current -- Current Directory [string] (don't change it, use fs:cd(dir))

fs.drives, fs.files, fs.dirs -- [tables] drives directories and files in current dir

(internal) function fs:loadCp(codepage[string]) -- Load terminal codepage. Use only for testing. Return FALSE if codepage is not supported.

Supported codepages: '737', '775', '850', '852', '855', '866', '8859-1', '8859-2', '8859-4', '8859-5', '8859-7', '8859-15', '8859-16', 'KOI8-R', 'KOI8-U'

(internal) function fs:toUtf8(str) -- translate string to utf-8

(internal) function fs:toCp(str) -- translate string to current codepage

(internal) function fs:path8p3(dir, all) -- return Windows path in 8.3 format

(internal) function fs:run(command) -- Execute command on console

function fs:setParam(param) -- Used by :cd() to populate fs.dirs and fs.files

function fs:ls(param, dir) -- return file list (table and string). Alias: fs:dir(param, dir)

function fs:lsDrives() -- return drives (table)

function fs:lsDirs(param, dir) -- return directories (table and string)

function fs:lsFiles(param, dir) -- return files (table and string)

function fs:exists(name, dir) -- return TRUE if exists.

function fs:isDirectory(name, dir) -- return TRUE if directory.

function fs:isFile(name, dir) return TRUE if is file. 

function fs:cd(dir) -- Change directory. Populate fs.dirs and fs.files with the new directory contents.

Note: if dir is NIL current directory is used

function fs:up() -- same as fs:cd:('..')

function fs:copy(source, dest) -- copy file

function fs:loadImage(source) -- return image

function fs:loadSource(source) --return sound

function fs:loadFont(size, source) --return font

function fs:saveImage(img, dest) -- Need Canvas support. Return FALSE on failure

---------------------------------------- dialogs.lua ------------------------------------------------
Load and Save Dialog using LoveFrames (modified)

dialog = loadDialog(window_fs, filters)

dialog = saveDialog(window_fs, filters)

Example:

fs = fsload()
dialog = loadDialog(fs, {'All | *.*', 'Images | *.jpg *.bmp *.png'})

On close with OK, the path of the chosen file is at fs.selectedFile
