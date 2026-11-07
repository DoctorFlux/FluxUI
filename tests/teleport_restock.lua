-- Actual travel-button and shared reagent-editor replay; no native secure VM.
local source, popupSource = 'ExtraButtonSystem/NonCombatGrid/Buttons/TeleportPortal.lua', 'ExtraButtonSystem/FlyoutEngine/Popup.lua'
for i=1,#arg do if arg[i]=='--source' then source=arg[i+1] elseif arg[i]=='--popup' then popupSource=arg[i+1] end end
local function read(p) local f=assert(io.open(p,'rb'));local s=f:read('*a');f:close();return s end
local measure=false;for i=1,#arg do if arg[i]=='--measure' then measure=true end end
local checks,failures=0,0
local function check(ok,s) checks=checks+1;if not ok then failures=failures+1;print('FAIL '..s)end end
local function boot(client)
 local s={lines={},scans=0,frames=0,combat=false,targets={[17031]=12,[17032]=8},saved=0,known={},portals={},reagents={},cache={},flyouts=0}
 local e=setmetatable({},{__index=_G});e._G=e;e.SlashCmdList={};e.REAGENTS='Reagents';e.UIParent={};e.GetTime=function()return 10 end;e.InCombatLockdown=function()return s.combat end
 e.GetSpellInfo=function(id)return 'Teleport: Test',nil,id end;e.GetSpellTexture=function(id)return id end;e.GetItemIcon=function(id)return id end;e.GetItemInfo=function(id)return s.cache[id] end
 if client=='Forever' or client=='Retail' then e.C_Item={GetItemInfo=function(id)return s.cache[id]end}end
 e.C_Timer={After=function()end};e.IsShiftKeyDown=function()return s.shift end;e.IsControlKeyDown=function()return false end;e.IsAltKeyDown=function()return false end
 e.Flux={Client={isCamelot=client=='Forever'},Secrets={SafeAccessibleString=function(v)return type(v)=='string' and v or nil end},Inventory={GetCount=function()return 0 end},EBS={Flyout={}}}
 local methods={}
 function methods:RegisterEvent()end;methods.RegisterUnitEvent=methods.RegisterEvent
 function methods:SetScript(k,f)self.scripts[k]=f end
 function methods:HookScript(k,f)self.hooks[k]=f end
 function methods:SetAttribute(k,v)assert(not s.combat,'protected write');self.attrs[k]=v end
 function methods:GetAttribute(k)return self.attrs[k]end
 function methods:SetText(v)self.text=v end;function methods:GetText()return self.text end
 function methods:Show()self.shown=true end;function methods:Hide()self.shown=false end;function methods:IsShown()return self.shown end
 function methods:SetFocus()self.focus=true end;function methods:ClearFocus()local f=self.focus;self.focus=false;if f and self.scripts.OnEditFocusLost then self.scripts.OnEditFocusLost(self)end end
 function methods:GetFrameLevel()return 10 end;function methods:GetName()return self.name end
 for _,k in ipairs({'SetSize','SetPoint','SetFontObject','SetJustifyH','SetJustifyV','SetAutoFocus','SetNumeric','SetMaxLetters','SetTextColor','SetFrameLevel','HighlightText','SetOwner','ClearLines','SetFrameStrata','SetClampedToScreen','ClearAllPoints'})do methods[k]=function()end end
 function methods:SetSpellByID(id)s.scans=s.scans+1;self.spell=id;for i=1,8 do e['FluxNCTeleportPortalSpellScannerTextLeft'..i]=nil end;for i,t in ipairs(s.lines[id] or {})do e['FluxNCTeleportPortalSpellScannerTextLeft'..i]={GetText=function()return t end}end end
 function methods:NumLines()return #(s.lines[self.spell]or{})end
 e.CreateFrame=function(kind,name,parent)s.frames=s.frames+1;return setmetatable({name=name,parent=parent,attrs={},scripts={},hooks={}},{__index=methods})end
 e.FluxVendorAuto={GetRestockTargetForItem=function(id)return s.targets[id]or 0 end,SetRestockTarget=function(id,n)s.targets[id]=n;s.saved=s.saved+1 end}
 e.FluxInv={RegisterListener=function(_,fn,opts)s.listener=fn;s.listenerOptions=opts end,Spells={GetReagents=function(id)return s.reagents[id]end,IsBlacklistedReagent=function()return false end,GetReagentItemIDs=function()error('global reagent scan')end}}
 assert(load(read(popupSource),'@'..popupSource,'t',e))('test',{Flux=e.Flux})
 assert(load(read(source),'@'..source,'t',e))()
 local m=e.FluxNCTeleportPortal;s.m=m;s.e=e
 m.GetKnownTeleportSpells=function()return s.known end;m.GetKnownPortalSpells=function()return s.portals end;m.GetMode=function()return s.mode or m.MODE_TELEPORT end
 m.GetSpellForModifier=function()return s.active or s.known[1]or s.portals[1]end;m.ShowFlyout=function()s.flyouts=s.flyouts+1 end
 m.HasAnyTeleportSpell=function()return #s.known>0 end;m.HasAnyPortalSpell=function()return #s.portals>0 end
 local w=e.CreateFrame('Button');local count=e.CreateFrame('FontString');local b={Widget=w,WCount=count,UpdateTextCount=function()count:SetText('native')end};m._button=b;s.btn=b
 return s
end
if measure then
 for _,client in ipairs({'Forever','Era','Anniversary','Classic','Retail'})do
  local s=boot(client);s.known={{spellID=3561,name='Teleport: Test'}};s.lines[3561]={'Travel'};s.reagents[3561]={{itemID=17031,name='Rune'}}
  for i=1,100 do s.m.BuildReagentActions()end
  local beforeScans,beforeFrames=s.scans,s.frames;local started=os.clock();local total=0
  for i=1,1000 do local a=s.m.BuildReagentActions();total=total+#a;assert(a[1]['$itemId']==17031)end
  print(('MEASURE %s %.3f %d %d %d %d'):format(client,(os.clock()-started)*1000,s.scans-beforeScans,s.frames-beforeFrames,total,beforeFrames))
 end
 return
end
for _,client in ipairs({'Forever','Era','Anniversary','Classic','Retail'})do
 local s=boot(client);local m=s.m;s.known={{spellID=3561,name='Teleport: Test'}};s.lines[3561]={'Reagents: Rune of Teleportation'}
 -- Cold item cache, no warmed per-spell list: explicit rune text is evidence.
 local a=m.BuildReagentActions();check(#a==1 and a[1]['$itemId']==17031,client..' cold-cache teleport rune')
 s.lines[3561]={'No Rune of Teleportation is required'};a=m.BuildReagentActions();check(#a==0,client..' flavor text is not a reagent cost')
 s.lines[3561]={'No reagent cost'};s.reagents[3561]={{itemID=17031,name='Rune of Teleportation'}}
 a=m.BuildReagentActions();check(#a==1 and a[1]['$itemId']==17031,client..' existing spell reagent service')
 s.reagents[3561]={{itemID=6265}};a=m.BuildReagentActions();check(#a==0,client..' excludes uncached Soul Shard')
 s.btn.Widget.attrs.type='macro';s.btn.Widget.attrs.macrotext='/cast Teleport: Test'
 s.reagents[3561]={{itemID=17031,name='Rune'}};m.SetupClickHandlers(s.btn)
 check(s.btn.Widget.attrs.type=='macro' and s.btn.Widget.attrs.macrotext=='/cast Teleport: Test',client..' primary cast unchanged')
 check(s.btn.Widget.attrs.type2=='macro' and s.btn.Widget.attrs.typerelease2=='macro',client..' right click consumes both phases')
 local click=s.btn.Widget.hooks.OnMouseDown;click(s.btn.Widget,'RightButton');local box=s.btn.Widget.editBox
 check(box and box:IsShown() and box:GetText()=='12',client..' opens existing item target')
 if box then
  box:SetText('25');box.scripts.OnEnterPressed(box);check(s.targets[17031]==25 and s.saved==1,client..' commits persistent target once');check(s.btn.WCount:GetText()=='native',client..' restores native count')
  click(s.btn.Widget,'RightButton');box:SetText('9');box.scripts.OnEscapePressed(box);check(s.targets[17031]==25 and s.saved==1,client..' Escape cancels')
  click(s.btn.Widget,'RightButton');box:SetText('0');box:ClearFocus();check(s.targets[17031]==0 and s.saved==2,client..' focus-loss zero clears target')
 end
 local frames=s.frames;s.combat=true;click(s.btn.Widget,'RightButton');check(s.frames==frames and (not box or not box:IsShown()),client..' combat does not open editor');s.combat=false
 s.known[2]={spellID=3562,name='Teleport: Other'};m.SetupClickHandlers(s.btn);click(s.btn.Widget,'RightButton');check(s.flyouts==1,client..' multiple destinations retain flyout')
 local oldBox=s.btn.Widget.editBox
 s.known={};s.portals={{spellID=10059,name='Portal: Test'}};s.mode=m.MODE_PORTAL;s.active=s.portals[1];s.reagents[10059]={{itemID=17032,name='Rune of Portals'}};m.SetupClickHandlers(s.btn);click(s.btn.Widget,'RightButton');box=s.btn.Widget.editBox;check(box and box:GetText()=='8',client..' portal selects portal target');check(box==oldBox,client..' editor reused across modes')
 s.reagents[10059]={};s.lines[10059]={'Travel with no reagent cost'};m.SetupClickHandlers(s.btn);check(s.btn.Widget.attrs.type2==nil,client..' reagent-free spell keeps original secondary action');check(not box or not box:IsShown(),client..' face change closes stale editor')
 s.reagents[10059]={{itemID=6265}};m.SetupClickHandlers(s.btn);check(s.btn.Widget.attrs.type2==nil,client..' Soul Shard has no restock gesture')
 s.reagents[10059]={{itemID=17032,name='Rune'}};s.listener({regions={spells=true},changedItemIDs={}});check(s.btn.Widget.attrs.type2=='macro',client..' warmed spell map enables right click')
 s.combat=true;s.listener({regions={spells=true},changedItemIDs={}});check(m._pendingUpdate,client..' warm result defers protected setup in combat');s.combat=false
 s.reagents[10059]={{itemID=17020,name='Powder'},{itemID=17032,name='Rune'}};check(m.GetRightClickReagentItemID()==17032,client..' rune target preferred when multiple costs exist')
 s.reagents[10059]={{itemID=17020,name='Arcane Powder'},{itemID=6265}};a=m.BuildReagentActions();check(#a==1 and a[1]['$itemId']==17020,client..' other required reagent retained without Soul Shard')
 s.reagents[10059]={};s.lines[10059]={setmetatable({},{__index=function()error('opaque text indexed')end})};a=m.BuildReagentActions();check(#a==0,client..' unreadable text is not guessed')
 -- Locale-specific rune name, confirmed from the rune item itself.
 s.e.FluxInv=nil;s.e.REAGENTS='Composants';s.cache[17032]='Rune des portails';s.lines[10059]={'Composants: Rune des portails'};a=m.BuildReagentActions();check(#a==1 and a[1]['$itemId']==17032,client..' localized rune evidence')
 local kid=s.e.CreateFrame('Button');kid._fluxFlyoutDef={isReagent=true,item=17031};kid.WCount=s.e.CreateFrame('FontString');s.e.Flux.EBS.Flyout.Popup.ToggleReagentRestockEdit(kid);check(kid.editBox and kid.editBox:IsShown(),client..' original reagent-row editor remains available')
 s.cache[17032]=nil;s.lines[10059]={'Composants: |Hitem:17032|h[Unknown Rune]|h'};a=m.BuildReagentActions();check(#a==1 and a[1]['$itemId']==17032,client..' localized cold-cache linked rune')
end
print(('teleport restock: %d checks, %d failures'):format(checks,failures));assert(failures==0)
