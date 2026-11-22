-- Reorganize the actual registered builders, including dynamic factory rows.
-- Settings writes use isolated desktop fixtures. No personal saved variables or native UI are used.
local checks = 0
local reportRows = {}
local function check(value, why) checks = checks + 1; assert(value, why) end
local function read(path)
    if path=="AddonOptions/FluxOptionsCatalog.lua"and os.getenv("FLUX_OPTIONS_CATALOG_SOURCE")then path=os.getenv("FLUX_OPTIONS_CATALOG_SOURCE")end
    local f=assert(io.open(path,"rb"));local s=f:read("*a");f:close();return s
end
local function exercise(client)
    local ns={Flux={Client={isForever=client=="forever",isCamelot=client=="forever",isAnyClassic=client:find("classic")~=nil,isPreDF=client:find("classic")~=nil}}}
    local env=setmetatable({unpack=unpack or table.unpack},{__index=_G});env._G=env;env.Flux=ns.Flux
    local frames,entries,roots={},{},{}
    env.CreateFrame=function()
        local f={};function f:RegisterEvent()end;function f:UnregisterEvent()end
        function f:SetScript(key,fn)self[key]=fn end;frames[#frames+1]=f;return f
    end
    env.LibStub=function()return nil end
    env.UnitClass=function()return "Mage","MAGE",8 end
    env.GetLocale=function()return "enUS"end
    env.C_AddOns={IsAddOnLoaded=function()return false end}
    env.FLUX_API={hasFocusUnit=client~="classic_era"}
    env.FluxOptions={RegisterModuleOptions=function(_,id,builder)entries[id]=builder;roots[id]=nil end,
        GetModuleGen=function()return 1 end,GetProfilesOptions=function()return {type="group",args={}}end}
    function env.FluxOptions:ResolveModuleOptions(id)
        if roots[id]then return roots[id]end
        local entry=entries[id];if not entry then return nil end
        roots[id]=type(entry)=="function"and entry()or entry
        return roots[id]
    end
    local function run(path)assert(load(read(path),"@"..path,"t",env))("_FluxUI",ns)end
    run("AddonOptions/FluxOptionsCatalog.lua")
    run("AddonOptions/FluxOptionsRender.lua")
    run("AddonOptions/FluxOptionsNavigation.lua")
    local files={"FluxOptionsBinding","FluxOptionsActionBars","FluxOptionsActionBars_Bar","FluxOptionsActionBars_Bindings","FluxOptionsActionBars_Extra","FluxOptionsActionBars_Stance",
        "FluxOptionsGeneral","FluxOptionsLoot","FluxOptionsLayout","FluxOptionsWindows","FluxOptionsMicroMenu","FluxOptionsChat","FluxOptionsStatusBars","FluxOptionsInfo",
        "FluxOptionsSalvage","FluxOptionsVendor","FluxOptionsBattlezone","FluxOptionsRaidFrame","FluxOptionsUnitFrames","FluxOptionsNameplates"}
    for _,name in ipairs(files)do run("AddonOptions/"..name..".lua")end
    for _,f in ipairs(frames)do if f.OnEvent then f.OnEvent(f,"ADDON_LOADED","_FluxUI")end end
    local minimap = env.FluxOptions:ResolveModuleOptions("fluxwindow").args
    for _, retired in ipairs({"minimapEmbeddedColumns", "minimapEmbeddedScale", "minimapSideColumns", "minimapSideMoveFrames"}) do
        check(minimap[retired] == nil, client .. ": automatic layout removes manual control " .. retired)
    end
    for _, retained in ipairs({"minimapButtonCount", "minimapSideEnabled", "minimapSideScale", "minimapSideStart", "minimapHideInCombat",
        "minimapButtonAutoGrow", "minimapSideHideEmpty", "minimapSideVisibility"}) do
        check(minimap[retained] ~= nil, client .. ": automatic layout retains control " .. retained)
    end
    check(minimap.minimapSideScale.min == 10 and minimap.minimapSideScale.max == 200, client .. ": whole side-grid scale spans10–200percent")
    check(minimap.minimapHideInCombat.hidden == nil, client .. ": combat-hide setting always remains visible")
    check(minimap.minimapHideInCombat.name == ns.FluxOptionsLocale.MINIMAP_HIDE_COMBAT,
        client .. ": combat-hide setting retains localized label")
    check(minimap.minimapSideVisibility.values.always and minimap.minimapSideVisibility.values.mouseover,
        client .. ": visible choices for persistent or mouseover side grid")
    local preferences={sideEnabled=true,autoGrow=false,sideHideEmpty=false,sideVisibility="always",hideInCombat=false}
    env.FluxMinimapButtons={GetSetting=function(_,key)return preferences[key]end,
        SetSetting=function(_,key,value)preferences[key]=value end,CanHideInCombat=function()return true end}
    for key, setting in pairs({minimapButtonAutoGrow="autoGrow",minimapSideHideEmpty="sideHideEmpty",
        minimapSideVisibility="sideVisibility",minimapHideInCombat="hideInCombat"}) do
        local option=minimap[key]
        check(not option.disabled(),client..": optional button control is reachable "..key)
        local value=setting=="sideVisibility" and "mouseover" or not preferences[setting]
        option.set(nil,value)
        check(option.get()==value and preferences[setting]==value,client..": control writes its stable character key "..key)
    end
    env.FluxMinimapButtons=nil
    local function args(group)
        local out={};for _,plugin in pairs(group.plugins or{})do for k,v in pairs(plugin)do out[k]=out[k]or v end end
        for k,v in pairs(group.args or{})do out[k]=out[k]or v end;return out
    end
    local function leaves(group,prefix,out)
        for key,opt in pairs(args(group))do
            local path=prefix.."/"..key
            if opt.type=="group"then leaves(opt,path,out)
            else out[path]=opt end
        end
    end
    local expected,placed,parts={},{},{}
    for _,id in ipairs(ns.FluxOptionsCatalog.sourceModules)do
        local root=env.FluxOptions:ResolveModuleOptions(id);check(root~=nil,client..": registered source "..id)
        leaves(root,id,expected)
    end
    local function scan(view,page,sub)
        for _,source in ipairs(view._fluxSources or{})do
            local prefix=source.module
            for _,key in ipairs(source.path)do prefix=prefix.."/"..key end
            local found={};leaves(source.group,prefix,found)
            for path,opt in pairs(found)do
                check(expected[path]==opt,client..": moving preserves original option identity "..path)
                placed[path]=placed[path]or{};placed[path][#placed[path]+1]=page.."/"..(sub or "")
                parts[path]=source.part
            end
        end
        for key,opt in pairs(view.args or{})do if opt.type=="group"then scan(opt,page,key)end end
    end
    for id,entry in pairs(ns.FluxOptionsCatalog.pages)do
        local locations=0
        for _,group in ipairs(ns.FluxOptionsCatalog.groups)do for _,page in ipairs(group.pages)do if page==id then locations=locations+1 end end end
        check(locations==1 and not entry.hiddenNavigation,client..": canonical page is visible in exactly one sidebar category "..id)
        local group=ns.FluxOptionsNavigation.Resolve(id)
        check(group~=nil,client..": canonical page "..id)
        if entry.module then local found={};leaves(group,entry.module,found);for path in pairs(found)do placed[path]={id.."/"}end
        else scan(group,id)end
    end
    local missing={}
    for path in pairs(expected)do if not placed[path]then missing[#missing+1]=path end end
    table.sort(missing);check(#missing==0,client..": unmapped original settings: "..table.concat(missing,", "))
    local paths={};for path in pairs(expected)do paths[#paths+1]=path end;table.sort(paths)
    for _,path in ipairs(paths)do
        local destinations=placed[path]
        check(#destinations==1,client..": one primary location for "..path)
        local opt=expected[path]
        reportRows[#reportRows+1]={client,path,destinations[1],opt.type,type(opt.name)=="string"and opt.name or "(dynamic label)"}
    end
    local function at(path,page,sub)
        local want=page.."/"..sub;local matches=placed[path]or{}
        check(#matches==1 and matches[1]==want,client..": canonical placement "..path.." -> "..want)
    end
    at("unitframes/unitPlayer/enableSwingTimer","ufUnits","unitPlayer")
    at("unitframes/unitPlayer/enableFlightPathTimers","ufUnits","unitPlayer")
    at("unitframes/unitPlayer/enableFlightPathCastBar","ufUnits","unitPlayer")
    at("unitframes/unitPlayer/enableFlightPathTooltips","ufUnits","unitPlayer")
    at("nameplates/questOverlayEnabled","ufNameplates","extras")
    at("nameplates/visibilityMode","ufNameplates","extras")
    run("BlizzardSettings/Write.lua")
    local combat, writes, bitWrites, refreshes = false, 0, 0, 0
    local native = { nameplateShowEnemies = "0", nameplateShowFriendlyNpcs = "1", nameplateSelectedScale = "1.1" }
    local modern = client == "live" or client == "forever"
    env.Enum = modern and {
        NamePlateSize = { Small = 0, Medium = 1, Large = 2 },
        NamePlateCastBarDisplay = { SpellName = 1 },
        NamePlateInfoDisplay = { CurrentHealthValue = 2 },
    } or nil
    if modern then
        native.nameplateSize, native.nameplateCastBarDisplay, native.nameplateInfoDisplay = "1", "2", "4"
    end
    local readableBits = { nameplateCastBarDisplay = {}, nameplateInfoDisplay = {} }
    env.InCombatLockdown = function() return combat end
    env.FluxNamePlates_RefreshFromDB = function() refreshes = refreshes + 1 end
    env.C_CVar = {
        GetCVar = function(key) return native[key] end,
        SetCVar = function(key, value) writes = writes + 1; native[key] = value end,
        GetCVarBitfield = function(key, index)
            return readableBits[key][index] == true
        end,
        SetCVarBitfield = function(key, index, enabled)
            bitWrites = bitWrites + 1
            readableBits[key][index] = enabled
        end,
    }
    local plateOptions = entries.nameplates().args
    check(not plateOptions.style_enabled and not plateOptions["style_np.renderer"] and writes == 0,
        client .. ": opening settings never selects a renderer or rewrites native defaults")
    check(plateOptions.style_size.hidden() == not modern and plateOptions.cast_SpellName.hidden() == not modern,
        client .. ": unsupported native CVar or enum controls are omitted")
    plateOptions.visible_friendly.set(nil, false)
    check(native.nameplateShowFriendlyNpcs == "0" and native.nameplateShowEnemies == "0" and writes == 1,
        client .. ": a visibility change writes only the selected native stream")
    combat = true
    plateOptions.visible_enemies.set(nil, true)
    check(writes == 1 and native.nameplateShowEnemies == "0" and plateOptions.visible_enemies.disabled(),
        client .. ": combat blocks native visibility writes")
    combat = false
    if modern then
        plateOptions.style_size.set(nil, 2)
        plateOptions.cast_SpellName.set(nil, true)
        check(native.nameplateSize == "2" and plateOptions.style_size.get() == 2
            and native.nameplateCastBarDisplay == "2" and readableBits.nameplateCastBarDisplay[1] and bitWrites == 1,
            client .. ": native size uses its enum and cast settings write one bit")
        plateOptions.style_CurrentHealthValue.set(nil, true)
        check(readableBits.nameplateInfoDisplay[2] and bitWrites == 2
            and env.FluxUI_DB.nameplateAppearance.healthText.CurrentHealthValue == true,
            client .. ": the published health defaults yield to an explicit native text choice")
    end
    check(plateOptions.aura_countdown.get() == "middle" and plateOptions.font_countdownSize.get() == 12,
        client .. ": defaults preserve the published centered 12 px native overlay")
    plateOptions.aura_countdown.set(nil, "below")
    plateOptions.font_countdownSize.set(nil, 16)
    check(env.FluxUI_DB.nameplateAppearance.auraCountdown == "below"
        and env.FluxUI_DB.nameplateAppearance.countdownSize == 16 and refreshes == 2,
        client .. ": overlay controls save and refresh without changing native CVars")
    at("loot/fast","lootItems","loot")
    for path in pairs(expected)do
        if path=="vendor/vendor/autoRestock"or path=="vendor/vendor/autoBankRestock"or path=="vendor/vendor/autoMailRestock"or path=="vendor/vendor/autoAuctionFollowup"then at(path,"lootItems","restock")
        elseif path:find("vendor/vendor/",1,true)==1 then at(path,"lootItems","vendor")
        elseif path:find("vendor/restock/",1,true)==1 then at(path,"lootItems","restock")end
    end
    at("actionbars/extra/consumableSwapFoodWater","actionbars","buttons")
    for path in pairs(expected)do if path:find("actionbars/extra/",1,true)==1 then at(path,"actionbars","buttons")end end
    at("fluxwindow/meterEditor","fluxwindow","damageMeter")
    at("layout/preview","layout","")
    at("layout/layoutSettingsScope","layout","")
    at("layout/resetLayout","layout","")
    at("unitframes/general/useFluxPlayer","ufGeneral","general")
    at("binding/browser","bindings","browser")
    for path in pairs(expected)do if path:find("actionbars/bindings/",1,true)==1 then at(path,"bindings","settings")end end
    local names={};for _,tab in ipairs(ns.FluxOptionsCatalog.pages.fluxwindow.tabs)do names[#names+1]=tab.name end
    check(table.concat(names,"|")=="General|Damage Meter",client..": damage meter is inside Flux Window")
    check(not ns.FluxOptionsCatalog.pages.qol,client..": Quality of Life page removed")
    for path in pairs(expected)do
        local module=path:match("^([^/]+)/")
        if path:find("statusBars/invTip",1,true)==1 then at(path,"lootItems","loot")
        elseif module=="chat"or module=="info"or module=="statusBars"or module=="windows"then at(path,module,"")end
    end
    check(ns.FluxOptionsNavigation.Resolve("layout")==roots.layout and roots.layout.args.preview.dialogControl=="FluxLayoutPreview",client..": restored Layout retains original scope/reset and embedded preview source")
    names={};for _,tab in ipairs(ns.FluxOptionsCatalog.pages.actionbars.tabs)do names[#names+1]=tab.name end
    check(table.concat(names,"|")=="Bars|Extra Buttons|Stance Order",client..": related bars and buttons share one parent")
    names={};for _,tab in ipairs(ns.FluxOptionsCatalog.pages.lootItems.tabs)do names[#names+1]=tab.name end
    check(table.concat(names,"|")=="Loot|Vendor|Restock",client..": Loot & Items has focused feature tabs")
    local function tabs(page)
        local names = {}
        for _, tab in ipairs(ns.FluxOptionsCatalog.pages[page].tabs) do names[#names+1] = tab.name end
        return table.concat(names, "|")
    end
    check(tabs("ufGeneral")=="General|Cast Bars",client..": cast bar themes are inside General")
    check(tabs("ufUnits")=="Player|Target|Focus|Pet|Target of target|Focus target|Pet target",
        client..": Individual Frames has one selector for all unit types")
    check(tabs("ufPartyRaid")=="Party|Raid",client..": group frames share one two-tab editor")
    check(tabs("ufNameplates")=="Plate|Extras|Cast Bar|Auras|Targeting|Visibility|Fonts",
        client..": Nameplates has the reference settings categories")
    local nameplateTabs = { style="style", extra="extras", cast="cast", aura="auras", target="targeting", visible="visibility", font="fonts" }
    for path in pairs(expected)do
        if path:find("unitframes/partyRaid/partyStyle/",1,true)==1 then at(path,"ufPartyRaid","party")
        elseif path:find("unitframes/partyRaid/",1,true)==1 then at(path,"ufPartyRaid","raid")
        elseif path:find("unitframes/unitTarget/unitTargetOfTarget/",1,true)==1 then at(path,"ufUnits","unitTargetOfTarget")
        elseif path:find("unitframes/unitPet/unitPetTarget/",1,true)==1 then at(path,"ufUnits","unitPetTarget")
        elseif path:find("unitframes/unitPet/",1,true)==1 then at(path,"ufUnits","unitPet")
        elseif path:find("unitframes/unitFocus/focustarget",1,true)==1 or path:find("unitframes/unitFocus/focusTarget",1,true)==1 then
            at(path,"ufUnits","unitFocusTarget")
        elseif path:find("unitframes/general/",1,true)==1 then at(path,"ufGeneral","general")
        elseif path:find("unitframes/castBarThemes/",1,true)==1 then at(path,"ufGeneral","castBars")
        elseif path:find("nameplates/",1,true)==1 then
            local prefix = path:match("^nameplates/(%l+)_")
            at(path,"ufNameplates",nameplateTabs[prefix] or "extras")
        end
    end
    local frameParts = {
        ["general/settingsScope"] = "scope",
        ["general/raidSettingsScope"] = "scope",
        ["general/useFluxPlayer"] = "layout",
        ["general/use3DPortraits"] = "portrait",
        ["general/auraTimersUnderMinute"] = "auras",
        ["unitPlayer/playerHealthText"] = "health",
        ["unitPlayer/playerLevel"] = "name",
        ["unitPlayer/playerPowerText"] = "power",
        ["unitPlayer/playerClassPower"] = "classResource",
        ["unitPlayer/playerAbsorb"] = "absorbs",
        ["unitPlayer/playerCastBar"] = "cast",
        ["unitPlayer/playerRaidIcon"] = "indicators",
        ["unitTarget/targetShowBuffs"] = "buffs",
        ["unitTarget/targetAuraOwnDebuffMinScale"] = "debuffs",
        ["unitTarget/unitTargetOfTarget/totWidth"] = "layout",
        ["unitFocus/focusWidth"] = "layout",
        ["unitFocus/focusHeight"] = "layout",
        ["unitFocus/focusFrameScale"] = "layout",
        ["unitFocus/focustargetHealthText"] = "health",
        ["unitPet/petShowTooltipAuras"] = "auras",
        ["unitPet/unitPetTarget/petTargetWidth"] = "layout",
        ["partyRaid/partyStyle/partyAsRaid"] = "layout",
        ["partyRaid/partyStyle/auraScale"] = "auras",
        ["partyRaid/partyStyle/healthText"] = "health",
        ["partyRaid/partyStyle/targetWidth"] = "attached",
        ["partyRaid/partyStyle/preview"] = "preview",
        ["partyRaid/nameUseClassColor"] = "name",
        ["partyRaid/displayPowerBar"] = "power",
        ["partyRaid/showHealPrediction"] = "absorbs",
        ["partyRaid/maxBuffs"] = "buffs",
        ["partyRaid/displayOnlyDispellableDebuffs"] = "debuffs",
        ["partyRaid/auraIconScale"] = "auras",
        ["partyRaid/rangeAlphaOutOfRange"] = "opacity",
        ["partyRaid/previewGroup/rosterSize"] = "preview",
    }
    for path, part in pairs(frameParts) do
        check(parts["unitframes/"..path] == part, client..": preview opens "..part.." for "..path)
    end
    local nav=ns.FluxOptionsNavigation
    local compactLink = nav.Resolve("ufPartyRaid").args.party.args.open
    local openedPage, openedSub
    function env.FluxOptions:ShowConfig(pageId, subKey) openedPage, openedSub = pageId, subKey end
    compactLink.func()
    check(openedPage == "ufPartyRaid" and openedSub == "raid" and compactLink.buttonText~=compactLink.name,
        client..": party has a distinct button that opens the shared compact editor")
    local function previewRoute(page, sub, part, dest, targetSub, wantPage, wantSub, wantPart)
        local destPage, destSub, destPart = nav.FramePartRoute(page, sub, part, dest, targetSub)
        check(destPage==wantPage and destSub==wantSub and destPart==wantPart, client..": preview route "..page.."/"..part)
    end
    previewRoute("ufGeneral","general","layout","ufUnits","unitPet","ufUnits","unitPet","layout")
    previewRoute("ufGeneral","castBars","auras",nil,nil,"ufGeneral","general","auras")
    previewRoute("ufUnits","unitTarget","attached",nil,nil,"ufUnits","unitTargetOfTarget","layout")
    previewRoute("ufUnits","unitFocus","attached",nil,nil,"ufUnits","unitFocusTarget","layout")
    previewRoute("ufMini","unitPet","attached",nil,nil,"ufUnits","unitPetTarget","layout")
    previewRoute("ufUnits","unitFocusTarget","health",nil,nil,"ufUnits","unitFocusTarget","health")
    previewRoute("ufPartyRaid","party","portrait",nil,nil,"ufPartyRaid","party","portrait")
    previewRoute("ufPartyRaid","party","attached",nil,nil,"ufPartyRaid","party","attached")
    previewRoute("ufPartyRaid","party","buffs","ufRaid",nil,"ufPartyRaid","raid","buffs")
    previewRoute("ufPartyRaid","party","debuffs","ufPartyRaid","raid","ufPartyRaid","raid","debuffs")
    previewRoute("ufPartyRaid","raid","preview",nil,nil,"ufPartyRaid","raid","preview")
    local render = ns.FluxOptionsRender
    local raidSearch, raidTab = render.Search(nav.Resolve("ufPartyRaid"), "maximum buffs")
    local partySearch, partyTab = render.Search(nav.Resolve("ufPartyRaid"), "party member scale")
    local miniSearch, miniTab = render.Search(nav.Resolve("ufUnits"), "class-colored pet target hp")
    local castSearch, castTab = render.Search(nav.Resolve("ufGeneral"), "enable school themes")
    check(raidSearch>0 and raidTab=="raid" and partySearch>0 and partyTab=="party"
        and miniSearch>0 and miniTab=="unitPetTarget" and castSearch>0 and castTab=="castBars",
        client..": shared search finds original settings in the consolidated tabs")
    check(nav.Resolve("ufUnits").args.unitFocusTarget.hidden() == (not env.FLUX_API.hasFocusUnit),
        client..": moved focus target retains the parent capability gate")
    local focusTargetHint = ns.FluxOptionsCatalog.HelpText(expected["unitframes/unitFocus/focusTargetDesc"].name)
    check(focusTargetHint:find("Party target width", 1, true), client..": Focus target identifies the shared vertical width setting")
    local groups={};for _,group in ipairs(ns.FluxOptionsCatalog.groups)do groups[group.id]=group end
    check(groups.hud.label=="HUD"and table.concat(groups.hud.pages,"|")=="layout|chat|info|micromenu|fluxwindow|statusBars",client..": HUD sidebar contains Layout and five requested feature entries")
    check(groups.unitframes.label=="Unit Frame"and groups.combat.label=="Combat"and groups.lootItems.label=="Loot & Items",client..": separate sidebar category headers")
    check(table.concat(groups.unitframes.pages,"|")=="ufGeneral|ufUnits|ufPartyRaid",client..": Unit Frame has three sidebar entries")
    check(ns.FluxOptionsCatalog.pages.lootItems.sidebarSubpages and ns.FluxOptionsCatalog.pages.lootItems.tabs[3].icon=="Interface\\Icons\\INV_Misc_Bag_10",client..": Vendor/Restock are sidebar children with a working stock bag icon")
    local order={};for _,group in ipairs(ns.FluxOptionsCatalog.groups)do order[#order+1]=group.id end
    check(table.concat(order,"|")=="combat|lootItems|utilities|hud|unitframes|system",client..": requested sidebar category order; footer last")
    check(table.concat(groups.combat.pages,"|")=="actionbars|bindings|ufNameplates"
        and ns.FluxOptionsCatalog.pages.ufNameplates.category=="Combat",client..": Combat owns Nameplates")
    check(table.concat(groups.utilities.pages,"|")=="windows|professions",client..": Utilities owns Windows and Professions")
    check(table.concat(groups.system.pages,"|")=="settings|profiles|patchNotes|credits",client..": system-page order")
    check(not ns.FluxOptionsCatalog.pages.macros and not ns.FluxOptionsCatalog.pages.keybindings and #ns.FluxOptionsCatalog.pages.bindings.tabs==2,client..": one Bindings page retains both tools")
    for _,old in ipairs({{"keybindings",nil,"settings"},{"actionbars","bindings","settings"},{"binding",nil,"browser"},{"macros",nil,"browser"}})do
        local page,sub=ns.FluxOptionsNavigation.Route(old[1],old[2]);check(page=="bindings"and sub==old[3],client..": legacy binding destination preserved "..old[1])
    end
    local page,sub=ns.FluxOptionsNavigation.Route("vendor","salvage")
    check(page=="professions"and sub=="settings",client..": old salvage link routes to Professions")
    local buttons=nav.Resolve("actionbars").args.buttons
    check(#buttons._fluxSources==1 and buttons._fluxSources[1].module=="actionbars",client..": Extra Buttons reuses its original complete group")
    check(buttons._fluxSources[1].group.args.extraButtonVisibilityPanel.dialogControl=="FluxExtraButtonVisibilityPanel" and not buttons.args.buttonVisibility,client..": one original visibility editor without duplicate per-feature controls")
    check(not ns.FluxOptionsCatalog.pages.swingTimer,client..": Swing Timer is part of Unit Frames")
    local oldRoutes={{"actionbars","consumables","actionbars","buttons"},{"actionbars","trinkets","actionbars","buttons"},
        {"actionbars","travel","actionbars","buttons"},{"swingTimer","settings","ufUnits","unitPlayer"},
        {"qol","lootItems","lootItems","loot"},{"lootItems","settings","lootItems","loot"},{"vendor","restock","lootItems","restock"},
        {"qol","combat","ufNameplates"},{"qol","interface","windows"},{"unitframes","castBarThemes","ufGeneral","castBars"},
        {"unitframes","partyRaid","ufPartyRaid","raid"},{"nameplates","settings","ufNameplates"},{"unitframes","appearance","ufGeneral","general"},
        {"unitframes","unitTarget","ufUnits","unitTarget"},{"unitframes","unitFocus","ufUnits","unitFocus"},
        {"unitframes","unitPet","ufUnits","unitPet"},{"ufMini","unitPet","ufUnits","unitPet"},{"fluxwindow","settings","fluxwindow","general"},
        {"unitframes","unitTargetOfTarget","ufUnits","unitTargetOfTarget"},{"unitframes","unitFocusTarget","ufUnits","unitFocusTarget"},
        {"unitframes","unitPetTarget","ufUnits","unitPetTarget"},{"unitframes","party","ufPartyRaid","party"},
        {"ufMini","unitPetTarget","ufUnits","unitPetTarget"},{"ufMini",nil,"ufUnits","unitPet"},
        {"ufParty","appearance","ufPartyRaid","party"},{"ufRaid","buffs","ufPartyRaid","raid"},{"ufCastBars",nil,"ufGeneral","castBars"},
        {"qol","windows","windows"},{"qol","chat","chat"},{"qol","info","info"},{"qol","microMenu","micromenu"},
        {"qol","fluxWindow","fluxwindow","general"},{"qol","statusBars","statusBars"},{"qol","damageMeter","fluxwindow","damageMeter"},
        {"fluxwindow","damageMeter","fluxwindow","damageMeter"},{"qol",nil,"windows"}}
    for _,route in ipairs(oldRoutes)do
        local page,sub=nav.Route(route[1],route[2]);check(page==route[3]and sub==route[4],client..": consolidated old route "..route[1].."/"..tostring(route[2]))
    end
    local combat,launches=false,0
    env.InCombatLockdown=function()return combat end
    env.FluxSmartMountConfig={OpenMountJournal=function()launches=launches+1 end}
    local launch=nav.Resolve("actionbars").args.buttons.args.external_2
    combat=true;launch.func()
    check(launch.disabled()and launches==0,client..": settings launchers cannot open native collections in combat")
    combat=false;launch.func()
    check(not launch.disabled()and launches==1,client..": settings launcher resumes outside combat")
    check(ns.FluxOptionsCatalog.HelpText("on the Layout tab; General -> Settings scope")=="in HUD > Layout; Settings > Settings scope",client..": displayed help follows moved settings")
end
for _,client in ipairs({"live","forever","classic","classic_era","classic_anniversary"})do exercise(client)end
if os.getenv("FLUX_OPTIONS_NAVIGATION_REPORT")then
    local file=assert(io.open(os.getenv("FLUX_OPTIONS_NAVIGATION_REPORT"),"wb"))
    file:write("client,source_path,destination,setting_type,label\n")
    for _,row in ipairs(reportRows)do
        local fields={};for _,value in ipairs(row)do fields[#fields+1]='"'..value:gsub('"','""'):gsub("[\r\n]"," ")..'"'end
        file:write(table.concat(fields,",").."\n")
    end
    file:close()
end
print("Options navigation: "..checks.." checks; actual builders mapped across five client contracts; native rendering pending")
