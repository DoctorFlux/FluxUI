-- Execute the production macro icon method; metadata/native textures are modeled.
local target=os.getenv('FLUX_MACRO_METADATA_SOURCE')or'ExtraButtonSystem/Engine/Button.lua'
local baseline=false
for i=1,#arg do if arg[i]=='--source'then target=arg[i+1]elseif arg[i]=='--baseline'then baseline=true end end
local function read(path)local f=assert(io.open(path,'rb'));local s=f:read('*a'):gsub('\r\n','\n');f:close();return s end
local source=read(target);local a=assert(source:find('function FluxButton:UpdateTextureMacro()',1,true))
local b=assert(source:find('-- Update texture\nfunction FluxButton:UpdateTexture()',a,true))
source=source:sub(a,b-1)
local checks=0
local function check(ok,label)checks=checks+1;assert(ok,label)end
local function fixture(modern)
    local s={active='Spell1',variant=0,ready=true,info=0,item=0,texture=0,icon=0,shown=0,rank=0,usable=0,parse=0,body=0}
    local e=setmetatable({}, {__index=_G});e._G=e;e.FluxButton={}
    local function spell(token)local n=type(token)=='number'and token or type(token)=='string'and tonumber(token:match('^Spell(%d+)$'));return n end
    e.SecureCmdOptionParse=function(t)s.parse=s.parse+1;return s.active end
    e.GetMacroInfo=function()s.body=s.body+1;return'Test',1,'#showtooltip '..s.active end
    e.C_Spell={GetSpellIDForSpellIdentifier=spell}
    if modern then
        e.C_Spell={GetSpellInfo=function(token)s.info=s.info+1;local id=spell(token);if id and not s.coldSpell then return{spellID=id,name='Spell'..id}end end,
            GetSpellTexture=function(id)s.texture=s.texture+1;return id+1000+s.variant end,
            GetSpellIDForSpellIdentifier=spell}
    end
    e.GetSpellTexture=function(token)s.texture=s.texture+1;local id=spell(token);return id and id+1000+s.variant end
    e.GetItemIcon=function(id)return id+2000+s.variant end
    e.GetItemInfo=function(id)s.item=s.item+1;if s.ready then return'Item'..id,'item:'..id..':'..s.variant end end
    e.C_Item={GetItemInfoInstant=function(token)return type(token)=='string'and tonumber(token:match('^Item(%d+)$'))end}
    e.FluxButtonCore={FormatSpellCastAttribute=function(id)return id and'Spell'..id..'(Rank 1)'end}
    e.FluxSpellRankManager={ApplyRankDesaturation=function()s.rank=s.rank+1 end}
    assert(load(source,'@'..target,'t',e))()
    local icon={SetTexture=function(self,v)s.icon=s.icon+1;self.texture=v end,Show=function(self)s.shown=s.shown+1;self.shown=true end,
        Hide=function(self)self.shown=false end,SetDesaturated=function(self,v)self.desaturated=v end}
    local widget={}
    local button=setmetatable({MacroBody='#showtooltip Spell1',WIcon=icon,Widget=widget,
        UpdateUsable=function()s.usable=s.usable+1 end,GetActionTexture=function()return 999 end},{__index=e.FluxButton})
    return s,e,button
end
for _,family in ipairs{'retail','forever','mists','era','anniversary'}do
 for _,modern in ipairs{true,false}do
    local s,e,button=fixture(modern);local label=family..'/'..tostring(modern)
    for i=1,1000 do button:UpdateTextureMacro()end
    check(button.MacroMode=='spell'and button.SpellId==1 and button.SpellName=='Spell1'and button.SpellNameRank=='Spell1(Rank 1)','macro keeps exact live spell identity/rank')
    check(button.Widget.spellID==1 and button.WIcon.texture==1001 and button.WIcon.shown,'spell identity reaches widget and native icon sink')
    check(s.texture==1000 and s.icon==1000 and s.shown==1000 and s.parse==1000 and s.usable==1 and s.rank==1000,'every original live token/native texture/paint/rank update remains')
    if not baseline and modern then check(s.info==1000,'warm macro metadata is queried once per invocation')end
    print('METRIC|'..label..'_spellInfo|'..s.info)
    print('METRIC|'..label..'_spellTexture|'..s.texture)
    s.active='Spell2';s.variant=40;button:UpdateTextureMacro()
    check(button.SpellId==2 and button.WIcon.texture==1042 and s.usable==2,'next invocation immediately resolves changed castsequence/condition/override facts')
    button.MacroIndex=1;s.active='Spell3';button:UpdateTextureMacro()
    check(s.body==1 and button.SpellId==3 and button.WIcon.texture==1043,'indexed macro rereads current native body')
    button.MacroIndex=nil;s.active='item:201';s.item=0
    for i=1,1000 do button:UpdateTextureMacro()end
    check(button.MacroMode=='item'and button.ItemId==201 and button.ItemName=='Item201'and button.ItemLink=='item:201:40','explicit item macro preserves fresh item metadata')
    if not baseline then check(s.item==1000,'warm explicit item macro uses one metadata read')end
    print('METRIC|'..label..'_itemInfo|'..s.item)
    s.variant=55;button:UpdateTextureMacro()
    check(button.ItemLink=='item:201:55'and button.WIcon.texture==2256,'item link and icon still resolve current invocation data')
    s.ready=false;local before=s.item;button:UpdateTextureMacro()
    check(s.item==before+2 and button.ItemName==nil and button.ItemLink==nil,'cold item metadata preserves the original second link retry')
    s.ready=true;button:UpdateTextureMacro();check(button.ItemName=='Item201'and button.ItemLink=='item:201:55','next original paint recovers loaded item facts')
    s.active='Item202';before=s.item;button:UpdateTextureMacro()
    check(s.item==before+1 and button.ItemId==202 and button.ItemName=='Item202'and button.ItemLink=='item:202:55','named item keeps existing identity and one live lookup')
    button.IconOverrideTexture='Override';before=s.parse;button:UpdateTextureMacro()
    check(button.WIcon.texture=='Override'and button.WIcon.desaturated==false and s.parse==before,'explicit override retains early paint policy')
    button.IconOverrideTexture=nil;s.active='Spell1'
    if modern then
        s.coldSpell=true;button:UpdateTextureMacro()
        check(button.SpellId==1 and button.WIcon.texture==1056,'uncached modern metadata retains legacy texture/identifier fallback')
        s.coldSpell=false;button:UpdateTextureMacro()
        check(button.SpellName=='Spell1','loaded modern metadata is read afresh on the next original call')
        local getter=e.C_Spell.GetSpellInfo;e.C_Spell.GetSpellInfo=function()error('metadata error',0)end
        check(not pcall(button.UpdateTextureMacro,button),'metadata errors keep original propagation policy')
        e.C_Spell.GetSpellInfo=getter
    end
    print('TRACE|'..label..'|'..tostring(button.MacroMode)..'|'..tostring(button.SpellId)..'|'..tostring(button.ItemId)..'|'..tostring(button.WIcon.texture)..'|'..s.usable..'|'..s.rank..'|'..s.icon..'|'..s.parse)
 end
end
print('Macro metadata hotspot: '..checks..' checks PASS; five client families with modern/legacy API models; native latency/FPS/taint NOT RUN')
