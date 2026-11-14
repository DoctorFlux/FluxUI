-- Production painters with the existing five-client fixture. Engine secrets,
-- animation rendering and actual HARMFUL|RAID membership need native acceptance.
local function read(path)
    local file=assert(io.open(path,"rb"));local source=file:read("*a"):gsub("\r\n","\n");file:close();return source
end
local source=read("tests/raid_healer_auras.lua")
local prefix=assert(source:match("^(.-)\nfor _,client in ipairs"))
local Fixture=assert(load(prefix.."\nreturn Fixture","@party-debuff-fixture","t",_G))()
local checks=0
local function check(value,label)checks=checks+1;assert(value,label)end
local function near(a,b)return math.abs(a-b)<1e-6 end
local function aura(id,kind,canDispel)
    return {name="Aura"..id,spellId=id,auraInstanceID=id,icon=1000+id,sourceUnit="player",canApplyAura=true,
        isHelpful=false,isHarmful=true,isRaid=canDispel,isBossAura=false,isPriorityAura=false,
        isTankRoleAura=false,isHealerRoleAura=false,isDPSRoleAura=false,isNameplateOnly=false,
        canActivePlayerDispel=canDispel,dispelName=kind,duration=30,expirationTime=100,applications=1}
end
local palette={Magic={.2,.6,1},Curse={.6,0,1},Disease={.6,.4,0},Poison={0,.6,0},Bleed={1,.2,.2}}
for _,client in ipairs({"live","forever","classic","classic_era","classic_anniversary"})do
 for _,atlas in ipairs({false,true})do
    local native=client=="live"or client=="forever"
    local e,module,frame,frames,boxes,data=Fixture(native,nil,nil,client)
    frame._fluxPartyMember=true
    e.C_Texture={GetAtlasInfo=function(name)check(name=="UI-HUD-ActionBar-Proc-Loop-Flipbook","Salvage atlas identity");return atlas and {} or nil end}
    check(module.Setup(frame),"party effect prepared before combat")
    local allocated=#frames
    if native then
        check(frame._fluxAuraNative,"native initialization retained")
        local groups=frame._fluxAuraContainers
        local owner=groups.partyDispelGlow
        local slot=owner.slots.partyDispel
        check(slot.filter=="HARMFUL|RAID","native glow selects only the client's dispellable aura filter")
        check(slot.options.candidateFilters.includeDispelTypes.Magic and not slot.options.candidateFilters.includeDispelTypes.None,"missing and unknown types cannot create a native glow")
        local sinks=slot.button.dispelSinks
        check(#sinks==1 and sinks[1].options.style==3 and not sinks[1].options.showWithoutDispelType
            and sinks[1].options.showWhenHarmful and not sinks[1].options.showWhenHelpful,"one native type-color sink; harmful typed auras only")
        local texture=sinks[1].region
        check(texture.points[1][4]==-8 and texture.points[2][4]==8,"glow extends beyond the unclipped party frame")
        local clock=client=="forever"and slot.button.shownAnimation or owner.animations[1]
        check(clock.looping=="REPEAT","repeating engine animation")
        if atlas then
            check(texture.atlas=="UI-HUD-ActionBar-Proc-Loop-Flipbook" and texture.desaturated,"same desaturated effect as Salvage")
            local flip=clock.animations[1]
            check(flip.kind=="FlipBook" and flip.FlipBookRows==6 and flip.FlipBookColumns==5
                and flip.FlipBookFrames==30 and flip.Duration==1,"same thirty-frame one-second Salvage cadence")
        else
            check(texture.texture:find("glow%-border") and #clock.animations==2,"existing glow artwork pulses when atlas is missing")
        end
        local icon=groups.dispel.groups.debuffs.buttons[1]
        check(#icon._fluxPartyDebuffBorders==4 and #icon.dispelSinks==4,"four rectangular aura border edges are registered")
        for _,edge in ipairs(icon._fluxPartyDebuffBorders)do
            check(edge.width==1.5 or edge.height==1.5,"thicker border remains inside clipped icon bounds")
            check(edge.points[1][4]==0 and edge.points[1][5]==0,"colored edge is visible inside the icon")
        end
        module.Update(frame)
        check(owner.shown and owner.unit=="party1" and not groups.dispelBorder.shown,"normal party uses glow instead of raid strips")
        e.restricted=true;e.combat=true
        for i=1,100 do module.Update(frame)end
        check(#frames==allocated and owner.unit=="party1","combat/restricted updates never allocate or inspect private descendants")
        e.UnitCanAttack=function()return true end;module.Update(frame)
        check(not owner.shown and owner.unit=="none","enemy party unit has no dispel glow")
        e.UnitCanAttack=function()return false end;module.Update(frame)
        frame._fluxPartyMember=false;frame.unit="raid1";module.Update(frame)
        check(not owner.shown and groups.dispelBorder.shown,"party to raid retains the original raid strip appearance")
        frame.unit="party2";module.Update(frame)
        check(owner.shown and not groups.dispelBorder.shown,"raid-style party also uses the dispel glow")
        frame.optionTable.displayDebuffs=false;module.Update(frame)
        check(not owner.shown and owner.unit=="none","hide debuffs retires glow owner")
        frame.optionTable.displayDebuffs=true;e.dispelHighlight=false;module.Update(frame)
        check(not owner.shown,"existing highlight option disables glow")
        e.dispelHighlight=true;module.Update(frame);module.Clear(frame)
        check(not owner.shown and owner.unit=="none","clear unbinds glow")
        if client=="live"then check(not clock.playing,"public animation stops with disabled owner")end
    else
        check(not frame._fluxAuraNative,"readable client keeps the existing painter")
        local glow=frame._fluxPartyDispelGlow
        check(glow and not glow.shown,"readable glow is prepared while no aura exists")
        local texture=glow._fluxDispelGlowTexture
        for kind,rgb in pairs(palette)do
            local ordinary,dispel=aura(100,"Disease",false),aura(101,kind,true)
            data.HARMFUL={ordinary,dispel};data["HARMFUL|RAID"]={dispel};data.HELPFUL={}
            e.combat=true;module.Update(frame)
            check(glow.shown,"eligible dispel glows during combat: "..kind)
            check(near(texture.color[1],rgb[1]) and near(texture.color[2],rgb[2]) and near(texture.color[3],rgb[3]),"glow follows the client's exact type palette")
            local borders=frame._fluxAuraCorners.debuffs[1]._fluxPartyDebuffBorders
            check(#borders==4,"readable aura uses the rectangular border")
            local edge=frame._fluxAuraCorners.debuffs[1]
            e.FluxRaidVisuals.SetPartyDebuffBorderType(edge,kind)
            for _,border in ipairs(borders)do check(border.shown and near(border.color[1],rgb[1]),"all four edges use type color")end
            data["HARMFUL|RAID"]={};module.Update(frame)
            check(not glow.shown,"ordinary typed debuff alone never glows")
        end
        data["HARMFUL|RAID"]={aura(102,nil,true),aura(103,"Poison",true)};module.Update(frame)
        check(glow.shown and frame._fluxDispelType=="Poison","untyped aura cannot hide a later typed dispel")
        e.dispelHighlight=false;module.Update(frame);check(not glow.shown,"highlight option clears active readable effect")
        e.dispelHighlight=true;e.UnitIsFriend=function()return false end;module.Update(frame);check(not glow.shown,"unfriendly party unit never glows")
        e.UnitIsFriend=function()return true end;module.Update(frame)
        check(#frames==allocated,"readable aura updates never allocate")
        frame.optionTable.displayDebuffs=false;module.Update(frame);check(not glow.shown,"disabled debuffs clear active readable effect")
        frame.optionTable.displayDebuffs=true;module.Update(frame);module.Clear(frame)
        check(not glow.shown and not glow.animations[1].playing,"clear stops readable glow animation")
    end
 end
end
print("Party debuff visibility: "..checks.." checks PASS; five client models, native/legacy render paths and missing-atlas fallback; native pixels/taint pending")
