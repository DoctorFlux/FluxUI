-- Whole production Cast owner; existing utility fixture models native endpoints.
local source=arg[1]or'Core/ButtonFX/Cast.lua';local mode='functional'
local function read(path)local f=assert(io.open(path,'rb'));local v=f:read('*a'):gsub('\r\n','\n');f:close();return v end
local text=read('tests/utility_modifier_vfx.lua')
text=text:sub(1,assert(text:find('    start("cast", 101);',1,true))-1)
text=text:gsub('local sourceRoot = arg%[1%]','local sourceRoot = nil',1)
local marker='for _, family in ipairs({ "live", "forever", "classic", "classic_era", "classic_anniversary" }) do'
local a,b=assert(text:find(marker,1,true))
text=text:sub(1,a-1)..'local function fixture(family)'..text:sub(b+1)
text=text:gsub('local function loadFile%(path%)','local function loadFile(path)\n        if path=="Core/ButtonFX/Cast.lua" then return assert(load(read('..string.format('%q',source)..'), "@Core/ButtonFX/Cast.lua", "t", env))("_FluxUI", ns)end',1)
local fixture=assert(load(text..'\nreturn s,env,flux\nend\nreturn fixture','@r27-whole-owner-fixture','t',_G))()
local function find(fn,wanted,seen)
 seen=seen or{};if seen[fn]then return end;seen[fn]=true
 for i=1,100 do local k,v=debug.getupvalue(fn,i);if not k then break end;if k==wanted then return v end end
 for i=1,100 do local k,v=debug.getupvalue(fn,i);if not k then break end;if k~='_ENV'and type(v)=='function'then local got=find(v,wanted,seen);if got then return got end end end
end
local function make(family)
 local s,e,f=fixture(family)
 return s,e,f,assert(find(f.ButtonFX.Cast._frame.scripts.OnEvent,'LiveCastName'),'actual private helper reachable')
end
local checks,cases=0,0
local function eq(a,b,label)checks=checks+1;assert(a==b,label..' differs')end
local function pack(...)return{n=select('#',...),...}end
local function tuple(name,id)return name,nil,nil,nil,nil,nil,nil,nil,id end
assert(mode=='functional')
for _,family in ipairs({'live','forever','classic','classic_era','classic_anniversary'})do
 local s,e,f,live=make(family);local trace={};local opaque=setmetatable({},{__tostring=function()error('must not inspect opaque error')end})
 local function reset()trace={}end
 local function result(value,unit,expected,label)
  local before=#trace;local values=pack(live(unit));eq(values.n,1,label..' arity');eq(values[1],expected,label..' answer');cases=cases+1
  print('TRACE '..family..' '..label..' '..table.concat(trace,',',before+1))
 end
 e.UnitCastingInfo=function(unit)trace[#trace+1]='cast:'..tostring(unit);return tuple('CastRaw',101)end
 e.UnitChannelInfo=function(unit)trace[#trace+1]='channel:'..tostring(unit);return tuple('ChannelRaw',202)end
 f.Spell.FormatCastAttribute=function(id)trace[#trace+1]='format:'..id;return 'Token'..id end
 result(nil,nil,'Token101','default-cast');eq(table.concat(trace,','),'cast:player,format:101','cast short circuit')
 reset();result(nil,'pet','Token101','pet-cast');eq(table.concat(trace,','),'cast:pet,format:101','pet normalization')
 reset();result(nil,'target','Token101','foreign-unit');eq(table.concat(trace,','),'cast:player,format:101','foreign normalization')
 e.UnitCastingInfo=function(unit)trace[#trace+1]='newcast:'..unit end
 reset();result(nil,'player','Token202','live-native-replacement');eq(table.concat(trace,','),'newcast:player,channel:player,format:202','dynamic native function')
 e.UnitCastingInfo=function(unit)trace[#trace+1]='errorcast:'..unit;error(opaque,0)end
 reset();result(nil,'pet','Token202','protected-cast-error');eq(table.concat(trace,','),'errorcast:pet,channel:pet,format:202','protected fallback')
 e.UnitCastingInfo=function(unit)trace[#trace+1]='cast:'..unit;return tuple('RawFallback',101)end
 f.Spell.FormatCastAttribute=function(id)trace[#trace+1]='emptyformat:'..id;return ''end
 reset();result(nil,'player','RawFallback','empty-token-fallback');eq(#trace,2,'raw name short circuit')
 f.Spell.FormatCastAttribute=function(id)trace[#trace+1]='errorformat:'..id;error(opaque,0)end
 reset();result(nil,'player','RawFallback','protected-format-error');eq(#trace,2,'format error preserves raw')
 f.Spell.FormatCastAttribute=nil
 reset();result(nil,'player','RawFallback','missing-format');eq(#trace,1,'no formatter lookup call')
 e.UnitCastingInfo=function(unit)trace[#trace+1]='emptycast:'..unit;return tuple('',nil)end
 e.UnitChannelInfo=function(unit)trace[#trace+1]='emptychannel:'..unit end
 reset();result(nil,'player',nil,'no-live-name');eq(table.concat(trace,','),'emptycast:player,emptychannel:player','both empty endpoints')
 e.UnitCastingInfo=nil;e.UnitChannelInfo=nil
 reset();result(nil,'player',nil,'missing-native');eq(#trace,0,'missing endpoints not called')
 -- Native callback reentry retains independent unit arguments and current public formatter.
 local depth=0
 f.Spell.FormatCastAttribute=function(id)return'Token'..id end
 e.UnitCastingInfo=function(unit)
  if depth==0 then depth=1;eq(live('pet'),'Token202','reentry pet unit');depth=0;return tuple('Outer',101)end
  eq(unit,'pet','inner unit independent');return tuple('Inner',202)
 end
 result(nil,'player','Token101','reentrant-native')
 e.UnitCastingInfo=function(unit)f.Spell.FormatCastAttribute=function(id)return'Replaced'..id end;return tuple('Current',303)end
 result(nil,'player','Replaced303','formatter-replaced-during-native')
end
do
 local s,e,f,live=make('forever');e.UnitCastingInfo=function()end;e.UnitChannelInfo=function()end
 for i=1,200 do live('player')end
 collectgarbage('collect');collectgarbage('stop');local before=collectgarbage('count')
 for i=1,5000 do live('player')end
 local growth=collectgarbage('count')-before;collectgarbage('restart')
 checks=checks+1;assert(growth<1,'temporary query allocation grows across 5000 calls')
 print(('Cast live-name allocation: %.6f KiB / 5000 calls; desktop model only'):format(growth))
end
print(('Cast live-name work: %d cases / %d checks PASS; native FPS/taint/pixels NOT RUN'):format(cases,checks))
