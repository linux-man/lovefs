# lovefs
## Load and save files outside love.filesystem
###with ffi

The ffi code was mostly adapted (with my sincerest gratitude) from

https://github.com/nyfair/fi-luajit (Windows) and https://github.com/Igalia/pflua (Posix).

To start, (look at the demo)

fs = lovefs(dir[string]) -- if no dir is given, start on UserDirectory

---------------------------------------- lovefs.lua -------------------------------------------------

fs.current -- Current Directory [string] (don't change it, use fs:cd(dir))

fs.drives, fs.dirs, fs.files, fs.all -- drives, directories and files [tables] of current dir

fs.selectedFile --  [string] used by fs:loadImage, fs:loadSource, fs:loadFont and fs:saveImage if no source is given

fs.home -- user directory [string]

fs.filter -- [table] with extensions, like {'jpg', 'png'}. Used by fs:ls to filter files. Don't forget to NIL!

function fs:updDrives() -- update drives list

The next functions accept absolute and relative (to current) paths

function fs:ls(dir) -- return dir (absolute path) [string], tDirs, tFiles, tAll [tables]. Return FALSE if dir don't exist. Alias: fs:dir(dir)

function fs:exists(path) -- return exists, isDirectory, isFile [booleans]

function fs:isDirectory(path) -- return TRUE if is directory.

function fs:isFile(path) return TRUE if is file. 

function fs:cd(dir) -- Change directory. Populate fs.dirs and fs.files and fs.all with the new directory contents. Return TRUE if successful

function fs:up() -- move to parent directory (using cd())

function fs:absPath(path) -- create absolute paths

function fs:loadImage(source) -- return image

function fs:loadSource(source) --return sound

function fs:loadFont(size, source) --return font

function fs:saveImage(img, dest) -- Need Canvas support. Return FALSE on failure

This function only accept absolute paths

function fs:copy(source, dest) -- copy file

---------------------------------------- gspotDialog.lua ------------------------------------------------

fs:openDialog(gspot, label, filter)

fs:closeDialog()

On close with OK, the path of the chosen file is at fs.selectedFile

