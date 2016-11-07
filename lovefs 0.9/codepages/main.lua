--f = io.open('KOI8-U.txt')
for line in io.lines('code.txt') do
	for word in line:gmatch("0x%x+") do io.write('\\'..tonumber(word)..'	') end
	print()
end
