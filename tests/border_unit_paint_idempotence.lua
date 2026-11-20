-- Public-identical unit tint reuses prepared paint; opaque alpha stays native.
local function read(p)local f=assert(io.open(p,'rb'));local s=f:read('*a');f:close();return s end
local prefix=assert(read('tests/border_junctions.lua'):match('^(.-)local J=fixture%(%)'))
prefix=prefix:gsub('read%("Core/BorderJunctions.lua"%)',function()return 'read("Core/BorderJunctions.lua").."\\n_G.__clipped=clipped"'end,1)
local fixture=assert(load(prefix..'\nreturn fixture','@unitpaint-idempotence-fixture','t',_G))()
local checks=0
local function check(v,m)checks=checks+1;assert(v,m)end
for _,style in ipairs{1,2}do
 local j,new,piece,flush,objects,lock,choose,_,e=fixture();choose(style,'class')
 local root=new(e.UIParent);root.unit='focus';root._FluxBorderStatic=true
 local h=piece(root,'Top',{0,-9,100,17});local v=piece(root,'Left',{41,-40,16,80})
 h:SetVertexColor(.2,.6,.9,1);v:SetVertexColor(.2,.6,.9,1);flush()
 local entry=e.__clipped[h];check(entry and entry.active,'actual static source is connected')
 local alphaReads,colorWrites,alphaWrites=0,0,0
 local m=getmetatable(root).__index
 local ga,vc,sa=m.GetAlpha,m.SetVertexColor,m.SetAlpha
 function m:GetAlpha()if self.decorative then alphaReads=alphaReads+1 end;return ga(self)end
 function m:SetVertexColor(...)if self.decorative then colorWrites=colorWrites+1 end;return vc(self,...)end
 function m:SetAlpha(...)if self.decorative then alphaWrites=alphaWrites+1 end;return sa(self,...)end
 local function reset()alphaReads,colorWrites,alphaWrites=0,0,0 end
 local function fields()
  local list,seen={},{}
  for _,t in ipairs(entry.pool)do if not seen[t]then list[#list+1]=t;seen[t]=true end end
  for _,listeners in j._ColorLists(h)do
   for _,t in ipairs(listeners)do if t._junctionOwnerOp and not seen[t]then list[#list+1]=t;seen[t]=true end end
  end
  check(#list>0,'actual active fields include fragment or junction listeners');return list
 end
 local function opacity(field,value)
  if field._fallbackEnabled==false then return 0 end
  return value
 end
 local solves,reads,count=j.stats.solves,j.stats.geometryReads,#objects
 for _,combat in ipairs{false,true}do
  lock(combat);reset()
  for _=1,100 do h:SetVertexColor(.2,.6,.9,1);flush()end
  check(alphaReads==0 and colorWrites==0 and alphaWrites==0,'public-identical author write performs no derived repaint/native alpha read')
  check(h:GetAlpha()==0,'identical native recolor still suppresses its exposed source')
  reset();for _=1,100 do h:SetAlpha(1);flush()end
  print('DIRECT_ALPHA_WORK',style,combat,alphaReads,alphaWrites)
  check(alphaReads==0 and alphaWrites==0,'public-identical native alpha does no derived work')
  check(h:GetAlpha()==0,'identical authored alpha still suppresses the original')
  reset();h:SetAlpha(.4);flush();check(alphaReads>0,'changed native alpha reaches derived paint')
  for _,t in ipairs(fields())do check(t:GetAlpha()==opacity(t,.4),'changed native alpha remains exact')end
  reset();for _=1,100 do h:SetAlpha(.4);flush()end
  check(alphaReads==0 and alphaWrites==0,'fractional public-identical native alpha stays static')
  h:SetAlpha(1);flush()

  h:Hide();h:SetVertexColor(.2,.6,.9,1);flush()
  for _,t in ipairs(fields())do check(t:GetAlpha()==0,'same color cannot revive a hidden original source')end
  h:Show();h:SetVertexColor(.2,.6,.9,1);flush()
  for _,t in ipairs(fields())do check(t:GetAlpha()==opacity(t,1),'show restores prepared fields independently of repeated color')end
  reset();h:SetVertexColor(.9,.1,.05,.6);flush()
  check(colorWrites>0 and alphaReads>0,'real RGB or alpha transition still paints derived fields')
  for _,t in ipairs(fields())do check(t.color[1]==.9 and t.color[2]==.1 and t.color[3]==.05,'real red/class tint reaches every derived field')end
  h:SetVertexColor(.2,.6,.9,1);flush()
 end
 check(j.stats.solves==solves and j.stats.geometryReads==reads and #objects==count,'public paint and source visibility never solve/read geometry/allocate')
 local secret=setmetatable({}, {__eq=function()error('private alpha compared')end,__lt=function()error('private alpha ordered')end,__le=function()error('private alpha ordered')end,__tostring=function()error('private alpha formatted')end})
 e.issecretvalue=function(x)return rawequal(x,secret)end
 for _=1,3 do reset();h:SetVertexColor(.2,.6,.9,secret);flush()
  check(alphaWrites>0,'every opaque alpha author write reaches prepared native alpha sinks')
  for _,t in ipairs(fields())do check(rawequal(t.alpha,opacity(t,secret)),'opaque opacity remains opaque at each enabled native sink')end
 end
 reset();h:SetVertexColor(.2,.6,.9,1);flush()
 check(alphaWrites>0,'public recovery after opaque alpha cannot be skipped as identical')
 for _,t in ipairs(fields())do check(t:GetAlpha()==opacity(t,1),'public opacity is restored after private transition')end
 check(j.stats.solves==solves and j.stats.geometryReads==reads and #objects==count,'opaque scalar alpha and recovery remain paint-only')
 for _=1,3 do reset();h:SetAlpha(secret);flush()
  check(alphaWrites>0,'every direct opaque alpha write reaches native fields')
  for _,t in ipairs(fields())do check(rawequal(t.alpha,opacity(t,secret)),'direct opaque alpha is never compared or replaced on enabled fields')end
 end
 reset();h:SetAlpha(1);flush();check(alphaWrites>0,'direct public recovery after opaque alpha paints')
 for _,t in ipairs(fields())do check(t:GetAlpha()==opacity(t,1),'direct alpha recovery remains exact')end
 h:Hide();h:SetAlpha(1);flush()
 for _,t in ipairs(fields())do check(t:GetAlpha()==0,'same authored alpha cannot revive a hidden source')end
 h:Show();flush()
 check(j.stats.solves==solves and j.stats.geometryReads==reads and #objects==count,'direct native alpha changes and recovery remain prepared paint only')
 -- Private RGB retains the existing retirement/recovery path, after combat.
 lock(false);h:SetVertexColor(secret,.6,.9,1);flush();h:SetVertexColor(.2,.6,.9,1);h:SetAlpha(1);flush()
 entry=e.__clipped[h];check(entry and entry.active and h:GetAlpha()==0,'private RGB retirement recovers through the existing native guarded path')
 -- A real geometry change initializes fresh fields before their first repaint.
 h.rect[3]=130;j:Invalidate(true);flush();entry=e.__clipped[h]
 check(entry and entry.active,'rebuild commits a current active source entry')
 reset();h:SetVertexColor(.2,.6,.9,1);flush()
 check(alphaReads==0 and colorWrites==0 and alphaWrites==0,'fresh rebuilt fields need no redundant identical repaint')
 for _,t in ipairs(fields())do check(t:GetAlpha()==opacity(t,1) and t.color[1]==.2,'rebuilt source fields retain initialized public color and alpha')end
end
print('UnitPaint public idempotence: '..checks..' checks PASS; native source suppression; changed RGB/alpha; source visibility; private scalar native sinks/recovery; private RGB retirement; rebuilt fields; both styles. Native taint/FPS pending.')
