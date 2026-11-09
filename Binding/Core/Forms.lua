-- Binding/Core/Forms.lua
-- Form/stance tokens for per-form sub-profiles.
--
-- Tokens come from the Actionbars stance map (FluxStateDriver:GetClassStances),
-- plus the implicit "noform" token. Each token knows:
--   * its bar PAGE (LAB state; 0 -> page 1)  — main-row slot routing
--   * its live shapeshift FORM INDEX          — [form:N] macro conditions
--   * whether it is a stealth-augmented form  — [stealth] macro condition

local addonName, ns = ...

local Forms = {}
ns.FluxBindingForms = Forms
_G.FluxBindingForms3 = Forms

local tokens = nil        -- ordered token list
local tokenInfo = nil     -- token -> { name, pageState, stanceIndex, virtual, stealth }
local formIndexByToken = nil -- token -> live GetShapeshiftForm index

local function StanceDriver()
    return ns.FluxStateDriver or _G.FluxStateDriverModule
end

local function BuildTokenList()
    tokens = { "noform" }
    tokenInfo = {
        noform = { name = "No Form", pageState = 0, stanceIndex = nil },
    }
    local drv = StanceDriver()
    local stances = drv and drv.GetClassStances and drv:GetClassStances()
    if type(stances) == "table" then
        for _, stance in ipairs(stances) do
            if stance.id then
                tokens[#tokens + 1] = stance.id
                tokenInfo[stance.id] = {
                    name = stance.name or stance.id,
                    pageState = tonumber(stance.state) or 0,
                    stanceIndex = stance.index or nil, -- bonusbar index (false for virtual)
                    virtual = stance.virtual and true or false,
                    -- prowl / shadowdance style tokens ride the base form + stealth
                    stealth = (stance.id == "prowl" or stance.id == "shadowdance") or nil,
                    baseToken = (stance.id == "prowl") and "cat" or nil,
                }
            end
        end
    end
end

--- Live shapeshift indexes: match stance tokens to GetShapeshiftFormInfo rows
--- by name so [form:N] conditions stay correct as forms are learned.
local function RebuildFormIndexes()
    formIndexByToken = {}
    if not GetNumShapeshiftForms or not GetShapeshiftFormInfo then return end
    local n = GetNumShapeshiftForms() or 0
    for i = 1, n do
        local _, nameOrActive, activeOrCastable, spellID = GetShapeshiftFormInfo(i)
        -- classic: icon, name, isActive, isCastable ; retail: icon, active, castable, spellID
        local name
        if type(nameOrActive) == "string" then
            name = nameOrActive
        elseif spellID then
            if C_Spell and C_Spell.GetSpellInfo then
                local si = C_Spell.GetSpellInfo(spellID)
                name = si and si.name
            elseif GetSpellInfo then
                name = GetSpellInfo(spellID)
            end
        end
        if name and tokenInfo then
            for token, info in pairs(tokenInfo) do
                if info.name == name and not formIndexByToken[token] then
                    formIndexByToken[token] = i
                end
            end
        end
    end
    -- prowl rides cat's form index
    if tokenInfo and tokenInfo.prowl and formIndexByToken and formIndexByToken.cat then
        formIndexByToken.prowl = formIndexByToken.cat
    end
end

local function Ensure()
    if not tokens then
        BuildTokenList()
        RebuildFormIndexes()
    end
    return tokens, tokenInfo
end

function Forms.Invalidate()
    tokens = nil
    tokenInfo = nil
    formIndexByToken = nil
end

function Forms.GetTokens()
    return (Ensure())
end

function Forms.GetTokenInfo(token)
    Ensure()
    return tokenInfo[token or "noform"]
end

function Forms.HasMultipleForms()
    Ensure()
    return #tokens > 1
end

--- Bar page (LAB state) the main row shows while in this form. 0 -> page 1.
function Forms.PageForToken(token)
    Ensure()
    local info = tokenInfo[token or "noform"]
    local page = info and tonumber(info.pageState) or 0
    if page < 1 then page = 1 end
    return page
end

--- Macro bracket condition ("form:3", "bonusbar:N,stealth", "noform") or nil when
--- the class has no forms / the token has no resolvable client condition.
function Forms.MacroCondition(token)
    Ensure()
    token = token or "noform"
    if #tokens <= 1 then return nil end
    if token == "noform" then
        return "noform"
    end
    local info = tokenInfo[token]
    if not info then return nil end
    local parts = {}
    local formIdx = formIndexByToken and formIndexByToken[token]
    if formIdx then
        parts[#parts + 1] = "form:" .. formIdx
    else
        -- Retail / paging fallback when shapeshift index is unknown (virtual
        -- tokens, skyriding, etc.): use bonusbar from the stance map.
        local bb = tonumber(info.stanceIndex)
        if bb and bb > 0 then
            parts[#parts + 1] = "bonusbar:" .. bb
        elseif token == "skyriding" or token == "dragon" then
            parts[#parts + 1] = "bonusbar:5"
        end
    end
    if info.stealth then
        parts[#parts + 1] = "stealth"
    end
    if #parts == 0 then return nil end
    return table.concat(parts, ",")
end

--- True when this token has a usable macro condition tag for the client.
function Forms.TokenHasMacroCondition(token)
    return Forms.MacroCondition(token) ~= nil
end

--- True when this character has multiple forms AND at least one non-noform
--- token can be expressed in macro conditions (form:/bonusbar:/noform).
function Forms.HasMacroConditionForms()
	Ensure()
	if #tokens <= 1 then return false end
	for _, tok in ipairs(tokens) do
		if tok ~= "noform" and Forms.MacroCondition(tok) then
			return true
		end
	end
	-- noform alone still counts as a condition when multi-form
	return Forms.MacroCondition("noform") ~= nil
end

--- Compact form gates for a subset of tokens that share one overlay.
--- Pure form:N indexes merge to one "form:1/3" (255-char budget). noform,
--- stealth, and bonusbar each stay their own bracket. Caller omits gates
--- entirely when the overlay covers every form this slot serves.
function Forms.ConditionGroupsForTokens(tokenList)
	Ensure()
	local idxSet, idxOrder = {}, {}
	local leftover = {}
	for i = 1, #(tokenList or {}) do
		local tok = tokenList[i]
		local cond = Forms.MacroCondition(tok)
		local idx = cond and cond:match("^form:(%d+)$")
		if idx then
			idx = tonumber(idx)
			if idx and not idxSet[idx] then
				idxSet[idx] = true
				idxOrder[#idxOrder + 1] = idx
			end
		else
			leftover[#leftover + 1] = tok
		end
	end
	table.sort(idxOrder)
	local groups = {}
	if #idxOrder > 0 then
		local parts = {}
		for i = 1, #idxOrder do
			parts[#parts + 1] = tostring(idxOrder[i])
		end
		groups[#groups + 1] = { "form:" .. table.concat(parts, "/") }
	end
	for i = 1, #leftover do
		local cond = Forms.MacroCondition(leftover[i])
		local parts = {}
		if cond then
			for part in cond:gmatch("[^,]+") do
				parts[#parts + 1] = part
			end
		end
		-- Unresolvable tokens must not emit an unconditional clause.
		if #parts > 0 then
			groups[#groups + 1] = parts
		end
	end
	return groups
end

--- Current form token (stealth-aware for prowl-style virtual tokens).
function Forms.GetCurrentToken()
    Ensure()
    if #tokens <= 1 then return "noform" end
    local formIdx = GetShapeshiftForm and GetShapeshiftForm() or 0
    if not formIdx or formIdx == 0 then
        return "noform"
    end
    local match
    for token, idx in pairs(formIndexByToken or {}) do
        if idx == formIdx then
            local info = tokenInfo[token]
            if info and info.stealth then
                if IsStealthed and IsStealthed() then
                    return token
                end
            else
                match = match or token
            end
        end
    end
    return match or "noform"
end

--- Icon for the form strip.
function Forms.GetTokenIcon(token)
    Ensure()
    if token == "noform" or not token then
        return 136116 -- Spell_Nature_WispSplode-ish neutral; class portrait handled by UI
    end
    local idx = formIndexByToken and formIndexByToken[token]
    if idx and GetShapeshiftFormInfo then
        local icon = GetShapeshiftFormInfo(idx)
        if icon then return icon end
    end
    return 134400
end

-- Rebuild live indexes when forms are (un)learned.
local ev = CreateFrame("Frame")
ev:RegisterEvent("UPDATE_SHAPESHIFT_FORMS")
ev:RegisterEvent("PLAYER_ENTERING_WORLD")
ev:SetScript("OnEvent", function()
    if tokens then
        RebuildFormIndexes()
    end
end)
