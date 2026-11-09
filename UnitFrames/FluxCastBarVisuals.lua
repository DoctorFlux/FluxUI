-- Visual inference never writes to the authoritative school lookup. Public
-- spell metadata lets new/overridden abilities pick a look without ID lists.
local _, ns = ...
local Visuals = {}
ns.CastBarVisuals = Visuals
local Schools = ns.CastBarSchools
local cache, requested, cacheCount = {}, {}, 0

local function query(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, value = pcall(fn, ...)
    if ok then return Schools.Plain(value) end
end

local function text(value)
    value = Schools.Plain(value)
    if type(value) ~= "string" or value == "" then return nil end
    return value:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|A.-|a", ""):lower()
end

local function has(words, term)
    return words and words:find("%f[%a]" .. term .. "%f[%A]") ~= nil
end
local function any(words, terms)
    for _, term in ipairs(terms) do if has(words, term) then return true end end
    return false
end

local schoolTerms,localizedTerms
local function terms()
    if schoolTerms then return schoolTerms end
    schoolTerms,localizedTerms = {},{}
    local labels={}
    for _, entry in ipairs(Schools.Terms) do
        local localized = labels[entry[1]]
        if localized==nil then
            localized=text(query(C_Spell and C_Spell.GetSchoolString or GetSchoolString, entry[1])) or false
            labels[entry[1]]=localized
        end
        schoolTerms[#schoolTerms+1] = {mask=entry[1], english=entry[2], localized=localized,descriptionOnly=entry[3]}
        if localized then
            local previous=localizedTerms[localized]
            if previous==nil then localizedTerms[localized]=entry[1]
            else
                -- Identical localized labels (notably Chaos variants) do not
                -- prove extra schools. Retain only their common components.
                local common=0
                for _,bit in ipairs({1,2,4,8,16,32,64}) do
                    if math.floor(previous/bit)%2==1 and math.floor(entry[1]/bit)%2==1 then common=common+bit end
                end
                localizedTerms[localized]=common
            end
        end
    end
    return schoolTerms
end

local function union(a, b)
    local result = a or 0
    for _, bit in ipairs({1,2,4,8,16,32,64}) do
        if math.floor(b/bit)%2==1 and math.floor(result/bit)%2==0 then result=result+bit end
    end
    return result
end

local function descriptionMask(description)
    local mask = 0
    -- Infer only the damage clause in English, not resistance/absorb buffs or
    -- a secondary tooltip paragraph about a different spell's damage school.
    if not description then return nil end
    local excluded=any(description,{"absorb%a*","absorp%a*","resistan%a*","immun%a*"})
    local locale=query(GetLocale) or "enUS"
    local englishLocale=type(locale)=="string" and locale:sub(1,2)=="en"
    local entries=terms()
    if excluded then return nil end
    local clauses={}
    for damage in description:gmatch("([%a%s,%-%/]+)%s+damage") do clauses[#clauses+1]=damage end
    local damageText=table.concat(clauses," ")
    for _,entry in ipairs(entries) do
        if has(damageText,entry.english) then
            local school=entry.mask
            if entry.english=="chromatic" and localizedTerms.chromatic then school=localizedTerms.chromatic end
            mask=union(mask,school)
        end
    end
    if not englishLocale then
        for label,school in pairs(localizedTerms) do
            if school>0 and description:find(label,1,true) then mask=union(mask,school) end
        end
    end
    if has(description,"damage") then
        if any(description,{"all magic schools","all schools of magic","all schools"}) then mask=union(mask,126) end
        if any(description,{"all seven schools","all damage schools","all damage types"}) then mask=127 end
    end
    return mask>0 and mask or nil
end

local function metadata(id, name)
    if type(id)~="number" then return {name=text(name)} end
    local cached=cache[id]
    if cached then return cached end
    local spellName=query(C_Spell and C_Spell.GetSpellName,id)
    if not spellName then spellName=query(GetSpellInfo,id) end
    local description=query(C_Spell and C_Spell.GetSpellDescription or GetSpellDescription,id)
    local info={name=text(spellName or name),description=text(description),localizedName=spellName,
        helpful=query(C_Spell and C_Spell.IsSpellHelpful or IsHelpfulSpell,id),
        harmful=query(C_Spell and C_Spell.IsSpellHarmful or IsHarmfulSpell,id)}
    info.inferredMask=descriptionMask(info.description)
    if not info.inferredMask and not info.description and info.name and info.harmful==true then
        local named=0
        for _,entry in ipairs(terms()) do
            if not entry.descriptionOnly and has(info.name,entry.english.."%a*") then named=union(named,entry.mask) end
        end
        if named>0 then info.inferredMask=named end
    end
    -- A visual motif is not an authoritative school report. These are broad
    -- words, not individual spell names or IDs, and also cover future spells.
    if not info.inferredMask and not info.description and info.harmful==true
        and any(info.name,{"lightning","thunder","electric%a*"}) then info.inferredMask=8 end
    local base=query(C_Spell and C_Spell.GetBaseSpell,id)
    if type(base)=="number" and base~=id then info.base=base end
    if cacheCount>=1024 then cache={};cacheCount=0 end
    cache[id]=info;cacheCount=cacheCount+1
    if not requested[id] and C_Spell and C_Spell.RequestLoadSpellData
        and query(C_Spell.IsSpellDataCached,id)==false then
        requested[id]=true
        pcall(C_Spell.RequestLoadSpellData,id)
    end
    return info
end

local function flavor(info,mask)
    local magic=mask-mask%2
    if magic==124 and not has(info.name,"chromatic") and not has(info.description,"chromatic") then return "chaos" end
    if magic==126 then return "chaos" end
    -- Volcanic has its own look only for the exact Fire/Nature combination.
    if magic==12 then return "volcanic" end
    if magic==8 and (has(info.name,"lightning") or has(info.description,"lightning")) then return "lightning" end
end

function Visuals.Resolve(record, options)
    if not record or record.trade==true then return nil end
    local id,name=Schools.Plain(record.id),Schools.Plain(record.name)
    local info=metadata(id,name)
    local school,schoolSource=Schools.Resolve(id)
    if not school and info.base then school,schoolSource=Schools.Resolve(info.base) end
    if not school then school,schoolSource=Schools.Resolve(nil,info.localizedName or name) end
    -- A hidden profession flag alone cannot authorize inference. Public known
    -- spell identity or explicit helpful/harmful unit-spell metadata can.
    if record.tradeUnknown and not school and info.harmful~=true and info.helpful~=true then return nil end
    local mask=school
    if options.inferVisuals~=false then
        -- Client descriptions can change between expansions/patches while a
        -- runtime cache entry stays the same. Adapt the look, never the
        -- recorded school; direct combat-log data takes precedence over hints.
        if info.inferredMask and schoolSource~="combatlog" and schoolSource~="alias" then mask=info.inferredMask end
        -- Class and helpfulness do not establish a school: mounts, item uses,
        -- and other utility casts can be helpful on every class.
    end
    if not mask or mask==1 then return nil end
    local profile=flavor(info,mask)
    if (profile=="lightning" or profile=="volcanic") and options.spellVisuals==false then profile=nil end
    return {mask=mask,schoolMask=school,schoolSource=schoolSource,inferred=school~=mask,profile=profile}
end

function Visuals.Invalidate(id)
    id=Schools.Plain(id)
    if type(id)=="number" then
        local cached=cache[id]
        if cached then cache[id]=nil;cacheCount=cacheCount-1 end
        return cached~=nil
    end
    cache,cacheCount,schoolTerms,localizedTerms={},0,nil,nil
    -- Keep load-request deduplication: failed spell-data loads must not loop.
end
