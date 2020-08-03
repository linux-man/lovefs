-- run with luajit test.lua

require "lovefs.lovefs"

local fs = lovefs("/")

local path, tDirs, tFiles, tAll = fs:ls()

for i,v in pairs(tDirs) do
    print(v..'/')
end

for i,v in pairs(tFiles) do
    print(v)
end

print("/testlinkfile: ", fs:readlink("/testlinkfile"))