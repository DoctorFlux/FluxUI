-- The actual icon-divider factory must use the same 16-unit vertical canvas as
-- other border pieces, on atlas and file clients, before style registration.
local function read(p)local f=assert(io.open(p,'rb'));local s=f:read('*a');f:close();return s end
local fixture=assert(read('tests/border_types.lua'):match('^(.-)for _, forever in ipairs'))
local model=assert(load(fixture..'\nreturn model','@class-border-canvas-fixture','t',_G))()
local source=read(arg[1]or'UnitFrames/FluxUnitFrames_Shared.lua')
local a=assert(source:find('    local function CreateIconBorder(parent)',1,true))
local factory=source:sub(a,assert(source:find('    frame.classIconLeftBorder = CreateIconBorder',a,true))-1)
local checks=0
local function check(v,m)checks=checks+1;assert(v,m)end
for _,forever in ipairs{false,true}do for _,atlas in ipairs{'all','none'}do for _,style in ipairs{1,2}do
 local e,b,db,new=model(forever,atlas);db.borderType=style;e.ns={Border=b}
 local make=assert(load(factory..'\nreturn CreateIconBorder','@actual-class-border-factory','t',e))()
 local t=make(new(e.UIParent))
 check(t.width==16,'class splitter retains canonical 16-unit transverse scale')
 check(not t.shown,'creating geometry must not reveal the divider')
 check(b._pieces[t].key=='Left'and b._pieces[t].current==style,'both native/file clients retain current shared art and registration')
end end end
print('Class border canvas: '..checks..' checks PASS; actual factory; atlas/file/Forever/other clients; two styles; canonical width16; hidden registration')
