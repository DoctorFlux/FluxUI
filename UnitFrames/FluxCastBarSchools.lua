-- School definitions, not spell definitions. IDs are learned only from readable
-- runtime combat-log reports, never bundled or saved between sessions.
local _, ns = ...
local Schools = {}
ns.CastBarSchools = Schools

-- Physical stays in reported school data; visuals use only the six magic bits.
Schools.Terms = {
    {1,"physical"}, {2,"holy"}, {4,"fire"}, {8,"nature"}, {16,"frost"}, {32,"shadow"}, {64,"arcane"},
    {3,"holystrike"}, {5,"flamestrike"}, {6,"radiant"}, {9,"stormstrike"}, {10,"holystorm"},
    {12,"volcanic"}, {17,"froststrike"}, {18,"holyfrost"}, {20,"frostfire"}, {24,"froststorm"},
    {33,"shadowstrike"}, {34,"twilight"}, {36,"shadowflame"}, {40,"plague"}, {48,"shadowfrost"},
    {65,"spellstrike"}, {66,"divine"}, {68,"spellfire"}, {72,"astral"}, {80,"spellfrost"}, {96,"spellshadow"},
    {28,"elemental"}, {84,"chimeric"}, {106,"cosmic"}, {62,"chromatic"}, {124,"chaos"},
    {6,"holyfire"}, {34,"shadowlight"}, {40,"shadowstorm"}, {72,"spellstorm"},
    {126,"all magic schools",true}, {126,"all schools of magic",true},
    {126,"all schools",true},
    {127,"all seven schools",true}, {127,"all damage schools",true}, {127,"all damage types",true},
}

local function plain(value)
    local api = ns.API
    local secret = ns.Flux and ns.Flux.Secrets
    local test = api and api.IsSecretValue or secret and secret.IsSecretValue or issecretvalue
    if test and test(value) then return nil end
    local access = api and api.CanAccessValue or secret and secret.CanAccessValue
    if access and not access(value) then return nil end
    return value
end
Schools.Plain = plain

local learned, aliases, aliasNames, aliasMasks, aliasSources = {}, {}, {}, {}, {}
local learnedCount = 0
local learnedOrder,nextLearned={},1
local function refreshAlias(name)
    if not name then return end
    local sources=aliasSources[name]
    local value
    for _,candidate in pairs(sources or {}) do
        if value==nil then value=candidate elseif value~=candidate then value=false;break end
    end
    aliases[name]=value
    if sources and not next(sources) then aliasSources[name]=nil end
end
local function spellName(id)
    local fn=C_Spell and C_Spell.GetSpellName or GetSpellInfo
    if type(fn)~="function" then return end
    local ok,name=pcall(fn,id)
    name=ok and plain(name) or nil
    if type(name)=="string" and name~="" then return name end
end

local function updateAlias(id)
    local mask=learned[id]
    if not mask then return end
    local name,old=spellName(id),aliasNames[id]
    if name==old and aliasMasks[id]==mask then return end
    if old then aliasSources[old][id]=nil end
    aliasNames[id],aliasMasks[id]=name,mask
    if name then
        aliasSources[name]=aliasSources[name] or {}
        aliasSources[name][id]=mask
    end
    refreshAlias(old)
    if name~=old then refreshAlias(name) end
    return name,old
end

function Schools.Resolve(spellID,name,tradeSkill)
    if tradeSkill~=nil and plain(tradeSkill)==nil then return nil end
    if plain(tradeSkill) then return nil end
    spellID=plain(spellID)
    if type(spellID)=="number" and learned[spellID] then return learned[spellID],"combatlog" end
    name=plain(name)
    if type(name)=="string" and aliases[name] then return aliases[name],"alias" end
end

function Schools.Learn(spellID,mask)
    spellID,mask=plain(spellID),plain(mask)
    if type(spellID)~="number" or spellID<1 or spellID%1~=0
        or type(mask)~="number" or mask<1 or mask>127 or mask%1~=0 then return false end
    if learned[spellID]==mask then return true end
    if not learned[spellID] then
        if learnedCount>=2048 then
            local oldest=learnedOrder[nextLearned]
            local oldName=aliasNames[oldest]
            if oldName then aliasSources[oldName][oldest]=nil;refreshAlias(oldName) end
            learned[oldest],aliasNames[oldest],aliasMasks[oldest]=nil,nil,nil
        else
            learnedCount=learnedCount+1
        end
        learnedOrder[nextLearned]=spellID
        nextLearned=nextLearned%2048+1
    end
    learned[spellID]=mask
    updateAlias(spellID)
    return true
end

function Schools.InvalidateAliases(id)
    id=plain(id)
    if type(id)=="number" then return updateAlias(id) end
    -- General spellbook changes do not erase observed schools. New reports
    -- and targeted load events update aliases without scanning a spell list.
end
