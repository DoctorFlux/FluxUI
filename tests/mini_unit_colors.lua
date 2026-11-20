-- Actual shared/party color producers and actual FluxBorder factory/materials.
-- Primitive widgets and public unit data are modeled; no native pixel/FPS/taint claim.
local function read(path)
    local f=assert(io.open(path,'rb'));local s=f:read('*a'):gsub('\r\n','\n');f:close();return s
end
local shared=read(arg[1]or'UnitFrames/FluxUnitFrames_Shared.lua')
local party=read(arg[3]or'UnitFrames/FluxUnitFrames_Party.lua')
local borderPrefix=assert(read('tests/border_types.lua'):match('^(.-)for _, forever in ipairs'))
if arg[2]then
    local n;borderPrefix,n=borderPrefix:gsub('source%("FluxBorder.lua"%)','source('..string.format('%q',arg[2])..')')
    assert(n==1,'actual border source override')
end
local model=assert(load(borderPrefix..'\nreturn model','@mini-unit-real-border','t',_G))()
local function span(s,a,b)
    local first=assert(s:find(a,1,true),a);local last=assert(s:find(b,first+1,true),b)
    return s:sub(first,last-1)
end
local classCode=span(shared,'local function ClassColorForUnit(unit)','-- ---------------------------------------------------------------------------\n-- Health Bar')
local tintCode=span(shared,'local PORTRAIT_COMBAT_BORDER_R','-- Unit name on outer border:')
local castChrome=span(read(arg[4]or'UnitFrames/FluxCastBar.lua'),'local function GetCastBarChromeColors(unit, frame)',
    '-- ---------------------------------------------------------------------------\n-- Constants & Configuration')
local partyPaint=span(party,'function Party.PaintChrome','function Party.RefreshChrome')
local partyRefresh=assert(party:match('(function Party%.RefreshChrome%(%).-\nend)'))
local appearance=assert(shared:match('(function FluxUnitFrames_RefreshAppearanceChrome%(%).-\nend)'))
local debuff=read('UnitFrames/FluxUnitFrames_DebuffTint.lua')
local overlayCode=span(debuff,'local function Clone(source, parent)','local function CaptureLabels(frame)')
local readable=assert(debuff:match('(local function BuildReadable%(state%).-\nend)'))
local eligible=assert(debuff:match('(local function Eligible%(frame%).-\nend)'))
local checks,scenes=0,0
local function check(v,m)checks=checks+1;assert(v,m)end
local function close(a,b)return math.abs(a-b)<1e-9 end
local function rgb(actual,color,scale)
    scale=scale or 1
    return actual and close(actual[1],color.r*scale)and close(actual[2],color.g*scale)and close(actual[3],color.b*scale)
end
for _,forever in ipairs{false,true}do for _,style in ipairs{1,2}do for _,mode in ipairs{'atlas','class','custom'}do
    scenes=scenes+1
    local e,B,db,new=model(forever,'none');db.borderType=style;db.borderAccent=mode
    local UF,Party={}, {members={},pets={}}
    e.UF,e.Party,e.Border,e.FluxBorder=UF,Party,B,B
    e.ns={UnitFrames=UF,Border=B,PartyFrames=Party}
    local secret=setmetatable({},{__index=function()error('private field inspected')end,
        __eq=function()error('private value compared')end,__tostring=function()error('private value formatted')end})
    e.IsSecretValue=function(v)return rawequal(v,secret)end;e.issecretvalue=e.IsSecretValue;e.Secret=e.IsSecretValue
    e.API={SafeAccessibleString=function(v)if not rawequal(v,secret)and type(v)=='string'then return v end end}
    local colors={MAGE={r=.2,g=.6,b=.9},PRIEST={r=.85,g=.9,b=1},WARRIOR={r=.7,g=.3,b=.1},DRUID={r=.9,g=.5,b=.15}}
    e.RAID_CLASS_COLORS=colors
    local state={classes={player='MAGE',party1='WARRIOR',target='MAGE',targettarget='PRIEST',focustarget='DRUID'},
        players={player=true,party1=true,target=true,targettarget=true,focustarget=false},combat={},locked=false}
    e.UnitClass=function(unit)return 'unit',state.classes[unit]end
    e.UnitIsPlayer=function(unit)return state.players[unit]end
    e.UnitExists=function()return true end
    e.UnitAffectingCombat=function(unit)return state.combat[unit]or false end
    e.FluxUnitFrames_IsPortraitCombatTintEnabled=function()return true end
    e.InCombatLockdown=function()return state.locked end
    e.SafeBooleanTest=function(v,fallback)if not rawequal(v,secret)and type(v)=='boolean'then return v end;return fallback end
    e.PublicGeometryNumber=function(v)if not rawequal(v,secret)and type(v)=='number'then return v end end
    UF.UsesHudUnitBars=function()return true end
    UF.GetFramePublicLevel=function(f)return f:GetFrameLevel()end
    UF.SetFramePublicLevel=function(f,n)check(not state.locked,'normal/combat paint never writes a protected level');f:SetFrameLevel(n)end
    local m=getmetatable(e.UIParent).__index
    function m:IsShown()return self.shown end
    function m:IsVisible()return self.shown and(not self.parent or self.parent:IsVisible())end
    function m:SetShown(v)self.shown=v and true or false end
    function m:SetAlpha(a)self.alpha=a end
    function m:GetAlpha()return self.alpha or 1 end
    function m:ClearAllPoints()self.points={};self.allPoints=nil end
    local geometry=0
    for _,k in ipairs{'SetPoint','SetAllPoints','SetSize','SetWidth','SetHeight','SetParent','SetFrameLevel','ClearAllPoints'}do
        local original=assert(m[k],k)
        m[k]=function(self,...)geometry=geometry+1;check(not state.locked,'color update must not mutate geometry in combat');return original(self,...)end
    end
    local CastColors=assert(load(table.concat({classCode,partyPaint,partyRefresh,tintCode,appearance,castChrome,
        'return GetCastBarChromeColors'},'\n'),'@actual-mini-class-party-color-and-appearance-policy','t',e))()
    local function frame(unit,parent,portrait)
        local f=new(parent or e.UIParent);f.unit=unit;f._fluxMainPowerAlpha=.65;f:SetFrameLevel(40)
        B:ApplyTo(f,2,2,2,6)
        f.atlasBorderFrame=new(e.UIParent);f.atlasBorderFrame._FluxBorderOwner=f;B:ApplyTo(f.atlasBorderFrame,2,2,2,6)
        f.outerBorderFrame=new(f);B:ApplyTo(f.outerBorderFrame,2,2,2,6)
        if portrait then
            f.PortraitFrame=new(f);f.PortraitFrame:SetFrameLevel(41);B:ApplyTo(f.PortraitFrame,2,2,2,2)
            f.PortraitFrame.bg=f.PortraitFrame:CreateTexture();f.PortraitFrame.bg:Hide()
        end
        f.HealthPowerSeparator=f:CreateTexture();f.PowerAdditionalSeparator=f:CreateTexture()
        f.UpdatePartition=function()end
        return f
    end
    local player=frame('player',e.UIParent,true)
    local target=frame('target',e.UIParent,true)
    local tot=frame('targettarget',target,false)
    local npc=frame('focustarget',e.UIParent,false)
    local pet=frame('pet',player,true)
    local member=frame('party1',e.UIParent,true);member._fluxPartyMember=true;member._fluxPartyClassChrome=true
    local partyPet=frame('partypet1',member,false);partyPet._fluxPartyPet=true;partyPet._fluxPartyOwnerUnit='party1'
    Party.members[1],Party.pets[1]=member,partyPet
    e.ns.PlayerFrame,e.ns.TargetFrame,e.ns.TargetOfTargetFrame,e.ns.PetFrame=player,target,tot,pet
    local function assertClass(f,color)
        for _,surface in ipairs{f,f.atlasBorderFrame,f.outerBorderFrame}do
            check(rgb(surface.FluxBorderFrame.Top.color,color),'mini surface RGB uses its own public owner class')
            check(rgb(surface.FluxBorderFrame.Background.fill,color,.4)or surface==f.atlasBorderFrame,
                'mini backdrop uses its owner class independently of Appearance')
            check(B._pieces[surface.FluxBorderFrame.Top].unitColor==color,'material classification retains the explicit owner color')
        end
    end
    local function assertPetCast()
        local color=colors.MAGE;local paint={CastColors('pet',pet)}
        for i=1,3 do
            local c=({color.r,color.g,color.b})[i]
            check(close(paint[i],c)and close(paint[i+3],c*.4),'pet cast chrome retains owner class after appearance refresh')
        end
    end
    UF.UpdateBorderColors(pet);UF.UpdateBorderColors(partyPet)
    assertClass(pet,colors.MAGE);assertClass(partyPet,colors.WARRIOR)
    assertPetCast()
    check(rgb(pet.HealthPowerSeparator.color,colors.MAGE),'pet resource split uses owner-class RGB')
    check(rgb(pet.PortraitFrame.bg.color,colors.MAGE,.25),'pet manual portrait backdrop is owner-colored in every accent')
    for _,parentPlayer in ipairs{true,false}do
        state.players.target=parentPlayer;UF.UpdateBorderColors(target)
        for _,childPlayer in ipairs{true,false,true}do
            state.players.targettarget=childPlayer;UF.UpdateBorderColors(tot);UF.UpdateBorderColors(npc)
            local record=B._pieces[tot.FluxBorderFrame.Top]
            if childPlayer then
                assertClass(tot,colors.PRIEST)
                check(not record.naturalArt,'PC ToT overrides an NPC parent material')
            else
                check(record.unitColor==nil,'NPC ToT does not inherit its parent class color')
                check(record.naturalArt==B._pieces[npc.FluxBorderFrame.Top].naturalArt,'NPC ToT has main target/focus material policy')
                for i=1,4 do check(close(tot.FluxBorderFrame.Top.color[i],npc.FluxBorderFrame.Top.color[i]),'NPC ToT follows unit policy rather than parent accent')end
            end
        end
    end
    -- Public owner classes can disappear or become restricted; no private token
    -- is indexed and no prepared public class is discarded in favor of accent.
    local oldPlayer,oldParty=state.classes.player,state.classes.party1
    for _,value in ipairs{false,secret}do
        state.classes.player=value or nil;state.classes.party1=value or nil
        local before=geometry;UF.UpdateBorderColors(pet);UF.UpdateBorderColors(partyPet)
        assertClass(pet,colors.MAGE);assertClass(partyPet,colors.WARRIOR)
        assertPetCast()
        check(geometry==before,'owner class unavailability changes no prepared geometry')
    end
    state.classes.player,state.classes.party1=oldPlayer,oldParty
    for _,toggle in ipairs{false,true}do
        member._fluxPartyClassChrome=toggle;Party.RefreshChrome()
        assertClass(partyPet,colors.WARRIOR)
        local wanted=toggle and colors.WARRIOR or nil
        check(B._pieces[member.FluxBorderFrame.Top].unitColor==wanted,'member party-class setting remains authoritative')
    end
    for _,nextMode in ipairs{'custom','atlas','class'}do
        db.borderAccent=nextMode;B:RefreshAppearanceDependents()
        assertClass(pet,colors.MAGE);assertClass(partyPet,colors.WARRIOR)
        assertPetCast()
        check(rgb(pet.PortraitFrame.bg.color,colors.MAGE,.25),'appearance refresh cannot replace the pet portrait backdrop')
    end
    local before=geometry
    state.locked=true;state.combat.pet=true;UF.UpdateBorderColors(pet)
    check(pet.PortraitFrame.FluxBorderFrame.Top.color[1]==1 and close(pet.PortraitFrame.FluxBorderFrame.Top.color[2],.08),
        'existing combat portrait red remains above normal owner colors')
    state.combat.pet=false;UF.UpdateBorderColors(pet)
    check(rgb(pet.PortraitFrame.bg.color,colors.MAGE,.25),'leaving combat restores owner-class portrait plate')
    check(geometry==before,'normal/combat color updates never rebuild or move geometry')
    state.locked=false
    -- Exercise the existing readable dispel overlay producer, not new mini
    -- eligibility. Its independent higher layer survives normal RGB updates.
    e.keys={'TL','TR','BL','BR','Top','Bottom','Left','Right'}
    local Parts,BuildReadable,Eligible=assert(load(table.concat({overlayCode,readable,eligible,'return Parts,BuildReadable,Eligible'},'\n'),
        '@actual-readable-dispel-overlay','t',e))()
    check(Eligible(target)and not Eligible(tot)and not Eligible(pet)and not Eligible(partyPet),'mini dispel eligibility is unchanged')
    local overlay={parts=Parts(target)};BuildReadable(overlay)
    for _,part in ipairs(overlay.parts)do
        for _,t in ipairs(part.textures)do t:SetVertexColor(.6,.1,.8,1)end
        part.host:Show()
        check(part.host:GetFrameLevel()>target:GetFrameLevel(),'existing dispel overlay keeps a higher layer')
    end
    state.players.target=true;UF.UpdateBorderColors(target)
    for _,part in ipairs(overlay.parts)do for _,t in ipairs(part.textures)do
        check(t.color[1]==.6 and t.color[2]==.1 and t.color[3]==.8 and part.host:IsShown(),
            'normal chrome cannot overwrite a separate active dispel overlay')
    end end
end end end
print('Mini unit colors: '..checks..' checks PASS; '..scenes..' real Border/shared/party color scenes; both styles/all accents; owner availability; independent ToT PC/NPC; party setting and appearance; existing combat/dispel priorities. Native pixels/taint/FPS pending')
