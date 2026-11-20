-- Actual Food/Water event registration, inventory, spellbook and bind paths.
-- Pass a dated checkpoint for a matched old/current work-count comparison.
local function Read(path)
    local file=assert(io.open(path,"rb"))
    local source=file:read("*a")
    file:close()
    return (source:gsub("\r\n","\n"))
end
local foodPath="ExtraButtonSystem/NonCombatGrid/Buttons/Food.lua"
local waterPath="ExtraButtonSystem/NonCombatGrid/Buttons/Water.lua"
local prior=arg[1]
local fixture=Read("ExtraButtonSystem/Engine/_tmp_consumablesmoke.lua")
fixture=fixture:sub(1,assert(fixture:find("-- PLAYER_LOGIN bag priming",1,true))-1)
local function Boot(family, useBus, archived)
    local env=setmetatable({arg={[0]="ExtraButtonSystem/Engine/_tmp_consumablesmoke.lua"}},{__index=_G})
    if archived and prior then
        env.io={open=function(path,...)
            local normalized=path:gsub("\\","/")
            for _,source in ipairs({foodPath,waterPath}) do
                if normalized:sub(-#source)==source then
                    return io.open(prior.."/"..source:gsub("/","-"),...)
                end
            end
            return io.open(path,...)
        end}
    end
    local boot=assert(load(fixture.."\nreturn boot","@consumable-roster-fixture","t",env))()
    local s=boot(family,family=="era" or family=="anniversary")
    local e,create=s.env,s.env.CreateFrame
    function e.CreateFrame(...)
        local frame=create(...)
        local name="Fixture"..#s.frames
        function frame:GetName() return name end
        function frame:UnregisterEvent(event) self.events[event]=nil end
        return frame
    end
    e._FluxUI_CharSavedVars={food={preferRecuperate=false}}
    local known={{101,"Conjure Food"},{102,"Conjure Water"},{103,"Conjure Refreshment"},{104,"Ritual of Refreshment"}}
    if family=="retail" or family=="forever" then
        e.C_SpellBook={
            GetNumSpellBookSkillLines=function()return 1 end,
            GetSpellBookSkillLineInfo=function()return {itemIndexOffset=0,numSpellBookItems=#known} end,
            GetSpellBookItemInfo=function(i)return {spellID=known[i][1],name=known[i][2]} end,
        }
    else
        e.GetNumSpellTabs=function()return 1 end
        e.GetSpellTabInfo=function()return nil,nil,0,#known end
        e.GetSpellBookItemName=function(i)return known[i][2],nil,known[i][1] end
    end
    e.GetSpellInfo=function(id)
        for _,entry in ipairs(known) do if id==entry[1] or id==entry[2] then return entry[2] end end
    end
    e.IsInGroup=function()return s.group~="solo" end
    e.IsInRaid=function()return s.group=="raid" end
    s.group="solo"
    local keys={
        FLUXGRID_FOOD_OR_RECUP="F1",FLUXMAGE_CONJURE_FOOD="F2",
        FLUXGRID_WATER_OR_COMBINED="F3",FLUXMAGE_CONJURE_WATER="F4",
    }
    e.GetBindingKey=function(name)return keys[name] end
    e.ClearOverrideBindings=function(widget)
        assert(not s.combat,"binding clear in combat")
        widget.overrides={}
    end
    e.SetOverrideBindingClick=function(widget, _, key, name, click)
        assert(not s.combat and widget:GetName()==name,"binding write must target its owned button")
        widget.overrides[key]=click
    end
    if useBus then
        e.Flux.AfterLoad=function(callback) callback() end
        s.load("Core/Engine/SpellBook.lua")
    end
    s.load("Inventory/CreateSpells.lua")
    s:set(0,1,117,5)
    s:set(0,2,159,7)
    s:bags()
    local food,foodModule=s:button("food",false,foodPath)
    local water=s:button("water",false,waterPath)
    s:event("PLAYER_ENTERING_WORLD")
    s:advance(12)
    assert(food.ItemId==117 and water.ItemId==159,"initial stock is bound")
    assert(food.Widget.overrides.F2 and water.Widget.overrides.F4,"initial conjure bindings are installed")
    local usage={rc=0,bind=0,foodUpdate=0}
    local bridge=s.bridge
    local rc,bind,update=bridge.ApplyRightClickSpell,bridge.ApplyUseAndConjureBindings,foodModule.Update
    bridge.ApplyRightClickSpell=function(...)
        usage.rc=usage.rc+1
        return rc(...)
    end
    bridge.ApplyUseAndConjureBindings=function(...)
        usage.bind=usage.bind+1
        return bind(...)
    end
    foodModule.Update=function(...)
        usage.foodUpdate=usage.foodUpdate+1
        return update(...)
    end
    local function Reset()
        usage.rc,usage.bind,usage.foodUpdate=0,0,0
    end
    local function Fingerprint(includeMiddle)
        local all={}
        for _,button in ipairs({food,water}) do
            all[#all+1]=table.concat({button.ActionType,button.ActionValue,button.ItemId,button.WCount.value},":")
            local entries={}
            for _,fields in ipairs({button.Widget.attrs,button.Widget.overrides}) do
                for key,value in pairs(fields) do
                    -- The old Food refresh cleared the existing middle-click
                    -- suppression on the first roster change. Check it separately.
                    local middle=button==food and (key=="type3" or key=="typerelease3" or key=="macrotext3")
                    if includeMiddle or not middle then entries[#entries+1]=key.."="..tostring(value) end
                end
            end
            table.sort(entries)
            all[#all+1]=table.concat(entries,",")
        end
        return table.concat(all,"|")
    end
    return s,usage,Reset,Fingerprint,food,water,known,keys
end

for _,family in ipairs({"retail","forever","mists","era","anniversary"}) do
    for _,bus in ipairs({true,false}) do
        local old,a,resetOld,oldFace=Boot(family,bus,true)
        local new,b,resetNew,newFace,food,water,known,keys=Boot(family,bus,false)
        for _,group in ipairs({"party","raid","solo"}) do
            resetOld();resetNew()
            local initial=newFace(true)
            local pending=#new.timers
            for _,s in ipairs({old,new}) do
                s.group=group
                for _=1,20 do s:event("GROUP_ROSTER_UPDATE") end
                s:advance(.3)
            end
            assert(newFace(true)==initial,"roster events preserve all candidate stock and bindings")
            assert(oldFace()==newFace(),"same stock, use, conjure, ritual and restock bindings")
            assert(food.Widget:GetAttribute("macrotext3")=="/stopmacro","food keeps its middle-click suppression")
            assert(b.rc==0 and b.bind==0 and b.foodUpdate==0 and #new.timers==pending,"roster alone does no food/water work")
            if prior then assert(a.rc>=21 and a.bind>=21 and a.foodUpdate==20,"baseline repeats obsolete work") end
            print(("CONSUMABLE_ROSTER %s bus=%s group=%s rc=%d/%d binds=%d/%d food=%d/%d")
                :format(family,tostring(bus),group,a.rc,b.rc,a.bind,b.bind,a.foodUpdate,b.foodUpdate))
        end
        resetNew()
        new.combat=true
        new:event("GROUP_ROSTER_UPDATE")
        new:advance(.3)
        assert(not food._pendingKeybindUpdate and not water._pendingKeybindUpdate,"roster alone creates no queued combat binds")
        keys.FLUXGRID_FOOD_OR_RECUP,keys.FLUXGRID_WATER_OR_COMBINED="F5","F6"
        new:event("UPDATE_BINDINGS")
        new:advance(.3)
        assert(food._pendingKeybindUpdate and water._pendingKeybindUpdate,"real combat binding changes remain deferred")
        new.combat=false
        new:event("PLAYER_REGEN_ENABLED")
        new:advance(.3)
        assert(food.Widget.overrides.F5 and water.Widget.overrides.F6,"deferred bindings apply after combat")
        assert(not food.Widget.overrides.F1 and not water.Widget.overrides.F3)
        new:set(0,1,117,3)
        new:set(0,2,159,4)
        new:bags()
        assert(food.WCount.value=="3" and water.WCount.value=="4","inventory still drives counts")
        known[#known+1]={205,"Conjure Food (Rank 8)"}
        known[#known+1]={206,"Conjure Water (Rank 8)"}
        resetNew()
        new:event("SPELLS_CHANGED")
        new:advance(.65)
        local _,foodRank=new.env.FluxInv.Spells.GetPreferredFoodConjureSpell()
        local _,waterRank=new.env.FluxInv.Spells.GetPreferredWaterConjureSpell()
        assert(foodRank==205 and waterRank==206 and b.rc>=2,"spellbook change still rebinds both conjure actions")
    end
end
print("Food and Water roster replay passes 30 join/convert/leave bursts and all binding, combat, spellbook and bag controls.")
