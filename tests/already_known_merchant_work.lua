-- Whole loaded AlreadyKnown owners; merchant/native metadata/painting modeled.
local sourceDir=arg[1]or'Inventory/Restock/Vendor'
local baseline=arg[2]=='--baseline'
local checks=0
local function check(ok,label)checks=checks+1;assert(ok,label)end
for _,family in ipairs({'retail','forever','mists','era','anniversary'})do
 for _,provider in ipairs({'builtin','syndicator'})do
  for _,kind in ipairs({'known','unknown','closed','close-before-deferred','reopen','getter-missing','getter-error','getter-nil','getter-secret-false','reentry','setter-error'})do
   local e=setmetatable({},{__index=_G});e._G=e
   local s={timers={},hooks={},settings=0,links=0,item=0,tooltip=0,paint=0,visibility=0,open=kind~='closed'and kind~='reopen'}
   local db={r=.2,g=.7,b=.3,monochrome=true,enabled=true}
   local known={};if kind=='known'or kind=='setter-error'then for id=100001,100012 do known['item:'..id]=true end end
   local AK={GetSettings=function()s.settings=s.settings+1;return db end,_knownTable=known}
   AK.ShouldRun=function()return AK.GetSettings().enabled end;e.FluxAlreadyKnown=AK
   e.FluxInventoryProvider=provider;e.Syndicator=provider=='syndicator'and{API={}}or nil
   e.strmatch,e.gsub,e.format=string.match,string.gsub,string.format
   e.ITEM_PET_KNOWN,e.ITEM_MIN_LEVEL,e.ITEM_CLASSES_ALLOWED='Already known','Level %d','Classes: %s'
   e.HOUSING_DECOR_OWNED_COUNT_FORMAT='Owned %d';e.SlashCmdList={};e.StaticPopupDialogs={}
   e.NORMAL_FONT_COLOR={WrapTextInColorCode=function(_,v)return v end}
   e.Enum={ItemClass={Miscellaneous=15,Housing=20}}
   e.C_Item={GetItemInfoInstant=function(link)s.item=s.item+1;return tonumber(link:match('item:(%d+)')),nil,nil,nil,1,7,0 end}
   e.C_TooltipInfo={GetHyperlink=function()s.tooltip=s.tooltip+1;return{lines={}}end}
   e.CreateFrame=function()
    local f={};function f:SetScript()end;function f:RegisterEvent()end;function f:SetOwner()end;function f:SetHyperlink()s.tooltip=s.tooltip+1 end
    function f:ClearLines()end;function f:NumLines()return 0 end;function f:GetRegions()return end
    return f
   end
   e.hooksecurefunc=function(target,method,fn)
    if type(target)=='string'then s.hooks[target]=method end
   end
   e.C_Timer={After=function(_,fn)s.timers[#s.timers+1]=fn end}
   e.MerchantFrame={page=1,IsShown=function()s.visibility=s.visibility+1;return s.open end};e.MERCHANT_ITEMS_PER_PAGE=12
   if kind=='getter-missing'then e.MerchantFrame.IsShown=nil
   elseif kind=='getter-error'then e.MerchantFrame.IsShown=function()s.visibility=s.visibility+1;error('getter unavailable')end
   elseif kind=='getter-nil'then e.MerchantFrame.IsShown=function()s.visibility=s.visibility+1;return nil end
   elseif kind=='getter-secret-false'then
    e.MerchantFrame.IsShown=function()s.visibility=s.visibility+1;return false end
    e.issecretvalue=function(value)return rawequal(value,false)end
   end
   e.GetMerchantItemLink=function(index)
    s.links=s.links+1
    if kind=='reentry'and not s.entered then
     s.entered=true;s.open=false;AK.RefreshMerchant();s.open=true
    end
    return'item:'..(100000+index)
   end
   for _,method in ipairs({'SetItemButtonNameFrameVertexColor','SetItemButtonSlotVertexColor','SetItemButtonTextureVertexColor','SetItemButtonNormalTextureVertexColor'})do
    e[method]=function(button,r,g,b)s.paint=s.paint+1;button.color={r,g,b}end
   end
   for i=1,12 do
    local icon={SetDesaturated=function(self,value)
     if kind=='setter-error'then error('native paint error',0)end
     s.paint=s.paint+1;self.desaturated=value
    end}
    e['MerchantItem'..i]={};e['MerchantItem'..i..'ItemButton']={};e['MerchantItem'..i..'ItemButtonIconTexture']=icon
   end
   local owner=family=='retail'and'FluxAlreadyKnown.lua'or'FluxAlreadyKnownClassic.lua'
   assert(loadfile(sourceDir..'/'..owner,'t',e))()
   local hook=assert(s.hooks.MerchantFrame_UpdateMerchantInfo)
   if kind=='setter-error'then
    local ok=pcall(function()hook();for _,fn in ipairs(s.timers)do fn()end end)
    check(not ok,family..' native paint error still propagates')
   else
    for _=1,100 do hook()end
    if kind=='known'or kind=='unknown'then
     if family=='retail'then check(s.links==0 and#s.timers==1,family..' retains its original coalesced next-tick paint')
     else check(s.links==1200 and#s.timers==0,family..' every classic visible callback paints synchronously')end
    end
   end
   if kind=='close-before-deferred'then s.open=false end
   if kind~='setter-error'then for _,fn in ipairs(s.timers)do fn()end end
   print(('WORK %s/%s/%s linkReads=%d,itemReads=%d,tooltipReads=%d,paints=%d,settings=%d,deferred=%d,visibility=%d'):format(
    family,provider,kind,s.links,s.item,s.tooltip,s.paint,s.settings,#s.timers,s.visibility))
   if kind=='known'then
    check(e.MerchantItem1ItemButtonIconTexture.desaturated==true,family..' cached known item stays tinted')
    db.monochrome=false;AK.RefreshMerchant()
    check(e.MerchantItem1ItemButtonIconTexture.desaturated==false,family..' next current settings paint remains live')
   elseif kind=='unknown'then
    check(not e.MerchantItem1ItemButtonIconTexture.desaturated,family..' unknown item has no stale tint')
    AK._knownTable['item:100001']=true;AK.RefreshMerchant()
    check(e.MerchantItem1ItemButtonIconTexture.desaturated,family..' new known fact paints without a negative cache')
   end
   if (kind=='closed'or kind=='close-before-deferred'or kind=='reopen')and not baseline then
    if kind~='close-before-deferred'or family=='retail'then
     check(s.links==0 and s.item==0 and s.tooltip==0 and s.paint==0,family..' verified hidden merchant does no native item/paint work')
    end
   end
   if kind=='reopen'then
    s.open=true;s.timers={};hook();for _,fn in ipairs(s.timers)do fn()end
    check(s.links>=12 and not e.MerchantItem1ItemButtonIconTexture.desaturated,family..' reopening paints current metadata without a stale hidden cache')
   elseif kind=='getter-missing'or kind=='getter-error'or kind=='getter-nil'or kind=='getter-secret-false'then
    check(s.links>=12 and s.paint>=12,family..' unreadable or opaque visibility retains the original paint path')
   elseif kind=='reentry'then
    check(s.entered and s.open and s.links>=12 and not e.MerchantItem1ItemButtonIconTexture.desaturated,family..' nested close/show does not poison following visible callbacks')
   end
   db.enabled=false;local prior=s.links;AK.RefreshMerchant();check(s.links==prior,family..' disabled feature stops metadata and painting')
   local values={}
   for i=1,12 do
    local icon=e['MerchantItem'..i..'ItemButtonIconTexture'];local c=e['MerchantItem'..i..'ItemButton'].color or{}
    values[#values+1]=tostring(icon.desaturated)..':'..tostring(c[1])..':'..tostring(c[2])..':'..tostring(c[3])
   end
   print('TRACE '..family..'/'..provider..'/'..kind..' '..table.concat(values,','))
  end
 end
end
print('AlreadyKnown merchant audit: '..checks..' checks PASS; source/native work counters only; no native FPS or callback cadence change')
