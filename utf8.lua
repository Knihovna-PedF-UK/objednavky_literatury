local myutf = {}
local gmatch = unicode.utf8.gmatch
local ubyte = unicode.utf8.byte
-- simulate utf8 function from Lua 5.3
function myutf.codepoint(s, start, stop)
  local t = {}
  local i = 1
  for char in gmatch(s, ".") do
    if i >= start and i <= stop then
      t[#t+1] = ubyte(char)
    end
    i = i + 1
  end
  return table.unpack(t)
end

myutf.char = unicode.utf8.char
myutf.len = unicode.utf8.len

utf8 = utf8 or myutf


	
