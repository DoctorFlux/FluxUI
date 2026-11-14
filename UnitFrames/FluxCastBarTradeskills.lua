-- Native profession rank-bar artwork, driven by the existing cast lifecycle.
-- No profession selection, recipe scan, saved cache, or Lua animation driver.
local _, ns = ...
local Trades = {}
ns.CastBarTradeskills = Trades
local Schools = ns.CastBarSchools
local views = {}

local function query(fn, ...)
    if type(fn) ~= "function" then return end
    local ok, value = pcall(fn, ...)
    if ok then return Schools.Plain(value) end
end

local function atlas(name)
    local info = query(C_Texture and C_Texture.GetAtlasInfo, name)
    if type(info) == "table" then
        local height = Schools.Plain(info.height)
        if type(height) == "number" and height > 0 then return info, height end
    end
end

function Trades.Resolve(record)
    if not record or record.trade ~= true or record.tradeUnknown then return end
    local id = Schools.Plain(record.id)
    if type(id) ~= "number" or id < 1 or id % 1 ~= 0 then return end
    -- Gate before querying recipes on clients without the animated rank bar.
    if not atlas("Skillbar_Fill_Flipbook_DefaultBlue") then return end
    local info = query(C_TradeSkillUI and C_TradeSkillUI.GetProfessionInfoByRecipeID, id)
    if type(info) ~= "table" then return end
    local profession = Schools.Plain(info.profession)
    if type(profession) ~= "number" then return end
    -- Blizzard's GetAtlasKitSpecifier uses the inverse of this enum. This
    -- also works before the load-on-demand Professions UI has been opened.
    local kit
    for name, value in pairs(Enum and Enum.Profession or {}) do
        if value == profession then kit = name; break end
    end
    if not kit then return end
    local fill = "Skillbar_Fill_Flipbook_" .. kit
    local _, height = atlas(fill)
    if not height then fill = "Skillbar_Fill_Flipbook_DefaultBlue"; _, height = atlas(fill) end
    -- Native rank bars use 34px frames in two columns for a two-second cycle.
    if not height or height % 34 ~= 0 then return end
    local flare = "Skillbar_Flare_" .. kit
    if not atlas(flare) then flare = nil end
    return {kit = kit, fill = fill, rows = height / 34, flare = flare}
end

local function restore(v)
    if v.source then
        v.source:SetAlpha(v.sourceAlpha)
        v.source = nil
    end
    if v.spark then
        v.spark:SetAlpha(v.sparkAlpha)
        v.spark = nil
    end
end

function Trades.Reset(bar)
    local v = views[bar]
    if not v then return end
    restore(v)
    v.animation:Stop()
    v.fill:Hide()
    v.flare:Hide()
    v.record, v.art = nil, nil
end

function Trades.Layout(bar)
    local v = views[bar]
    if not v or not v.art then return end
    local timer = bar.TimerBar
    local source = timer:GetStatusBarTexture()
    if not source then Trades.Reset(bar); return end
    if v.boundSource ~= source then
        v.boundSource = source
        v.mask:ClearAllPoints()
        v.mask:SetAllPoints(source)
        v.flare:ClearAllPoints()
        v.flare:SetPoint("RIGHT", source, "RIGHT", 0, 0)
    end
    local height = timer:GetHeight()
    if height ~= v.height then
        v.height = height
        v.flare:SetSize(44 * height / 18, 14 * height / 18)
    end
end

local function build(bar)
    -- Optional graphics capabilities do not appear later in a session. Keep
    -- an unsupported bar dormant instead of allocating again on each refresh.
    views[bar] = false
    local timer = bar.TimerBar
    if not timer.CreateMaskTexture then return end
    -- Paint directly on the StatusBar, like the working school fill. A
    -- separate equal-level frame does not share the bar's texture ordering.
    local fill = timer:CreateTexture(nil, "ARTWORK", nil, 7)
    fill:SetAllPoints(timer)
    fill:Hide()
    if not fill.SetAtlas or not fill.CreateAnimationGroup or not fill.AddMaskTexture then return end
    local animation = fill:CreateAnimationGroup()
    local flipbook = animation:CreateAnimation("FlipBook")
    if not flipbook.SetFlipBookRows then return end
    animation:SetLooping("REPEAT")
    flipbook:SetOrder(1)
    flipbook:SetDuration(2)
    flipbook:SetFlipBookColumns(2)
    flipbook:SetFlipBookFrameWidth(0)
    flipbook:SetFlipBookFrameHeight(0)
    local mask = timer:CreateMaskTexture()
    -- Black outside the rectangle is essential: clamping its white edge
    -- would reveal the entire animation instead of only current progress.
    if mask:SetTexture("Interface\\Buttons\\WHITE8X8", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE") == false then return end
    fill:AddMaskTexture(mask)
    -- Above the animated ARTWORK fill, below native nameplate text/shields
    -- at OVERLAY sublevel 1. Equal fill/flare layers can obscure the glow.
    local flare = timer:CreateTexture(nil, "OVERLAY", nil, 0)
    flare:SetBlendMode("ADD")
    flare:Hide()
    local v = {mask = mask, fill = fill, flare = flare, animation = animation, flipbook = flipbook}
    views[bar] = v
    return v
end

function Trades.Apply(bar, record, db)
    if db.colors == false then Trades.Reset(bar); return end
    if views[bar] == false then return end
    local v = views[bar]
    -- Resolve at most once per successful cast identity, never per frame.
    local art = v and v.record == record and v.art or Trades.Resolve(record)
    if not art then Trades.Reset(bar); return end
    v = v or build(bar)
    if not v then return end
    local changed = v.record ~= record or not v.art or v.art.fill ~= art.fill
    v.record, v.art = record, art
    if changed then
        v.animation:Stop()
        v.fill:SetAtlas(art.fill, false)
        v.flipbook:SetFlipBookRows(art.rows)
        v.flipbook:SetFlipBookFrames(art.rows * 2)
        if art.flare then v.flare:SetAtlas(art.flare, false) end
    end
    Trades.Layout(bar)
    if not v.art then return end
    local source = bar.TimerBar:GetStatusBarTexture()
    if v.source ~= source then
        restore(v)
        v.source, v.sourceAlpha = source, source:GetAlpha()
    end
    source:SetAlpha(0)
    local native = bar._fluxNativeCast or bar
    local spark = native.Spark
    if spark and spark.GetAlpha and spark.SetAlpha and not v.spark then
        v.spark, v.sparkAlpha = spark, spark:GetAlpha()
    end
    -- Keep the softer skill-up flare with the fill during the owner's normal
    -- completion hold/fade; hide/reset remains the sole lifetime boundary.
    local showFlare = art.flare and db.edge ~= false
    local opacity = math.max(0, math.min(100, tonumber(db.glowOpacity) or 100)) / 100
    v.flare:SetAlpha(0.6 * opacity)
    v.flare:SetShown(showFlare and opacity > 0)
    if v.spark then v.spark:SetAlpha(showFlare and opacity > 0 and 0 or v.sparkAlpha) end
    v.fill:Show()
    if changed and not record.finished then v.animation:Play() end
end

function Trades.Finish(bar, db)
    local v = views[bar]
    if not v or not v.art then return end
    -- Keep the native flipbook under the cast owner's normal completion fade.
    -- Hiding/resetting the cast stops it; no second timer owns its lifetime.
    Trades.Apply(bar, v.record, db)
end
