-- WoW Lua 5.1 limits one function to 60 captured locals. The desktop compiler
-- accepts more, so verify the real service and its captured helper graph too.
local function read(p)local f=assert(io.open(p,'rb'));local s=f:read('*a');f:close();return s end
local prefix=assert(read('tests/border_junctions.lua'):match('^(.-)local J=fixture%(%)'))
if arg[1]then
 local source=read(arg[1])
 prefix=prefix:gsub('read%("Core/BorderJunctions.lua"%)',function()return string.format('%q',source)end)
end
local fixture=assert(load(prefix..'\nreturn fixture','@upvalue-limit-fixture','t',_G))()
local j=fixture();local seen={};local count,largest=0,0
local function visit(fn)
 if seen[fn]then return end;seen[fn]=true
 local info=debug.getinfo(fn,'uS')
 if info.what~='Lua'then return end
 count=count+1;largest=math.max(largest,info.nups)
 assert(info.nups<=60,string.format('WoW Lua5.1 capture limit: %s:%d has%d upvalues',info.short_src,info.linedefined,info.nups))
 for i=1,info.nups do local _,v=debug.getupvalue(fn,i);if type(v)=='function'then visit(v)end end
end
for _,fn in pairs(j)do if type(fn)=='function'then visit(fn)end end
assert(count>50,'actual border service helper graph must be inspected')
print(string.format('Border Lua upvalues: %d functions PASS; maximum=%d, conservative desktop limit60 including_ENV; native reload still required',count,largest))
