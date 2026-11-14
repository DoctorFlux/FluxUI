-- Compose navigation views while retaining each control's original Ace root/path.
local _, ns = ...
local N, cache = {}, {}
ns.FluxOptionsNavigation = N
local C = ns.FluxOptionsCatalog
function N.Route(page, sub)
    local alias = C.subAliases[page] and C.subAliases[page][sub]
    alias = alias or C.aliases[page]
    if alias then return alias[1], alias[2] end
    return page, sub
end
local function Set(list)
    local out = {}; for _, key in ipairs(list or {}) do out[key] = true end; return out
end
local function Select(group, spec)
    if not group then return end
    local only, except, args = spec.only and Set(spec.only), Set(spec.except), {}
    local function include(key, option)
        if only and not only[key] or except[key] then return end
        if spec.onlyPrefix and key:sub(1, #spec.onlyPrefix) ~= spec.onlyPrefix then return end
        if spec.exceptPrefix and key:sub(1, #spec.exceptPrefix) == spec.exceptPrefix then return end
        args[key] = option
    end
    for _, plugin in pairs(group.plugins or {}) do for key, option in pairs(plugin) do if args[key] == nil then include(key, option) end end end
    for key, option in pairs(group.args or {}) do if args[key] == nil then include(key, option) end end
    local view = {}
    for key, value in pairs(group) do if key ~= "args" and key ~= "plugins" then view[key] = value end end
    view.args = args
    return view
end
local function ResolveSource(spec)
    local root = FluxOptions and FluxOptions:ResolveModuleOptions(spec.module)
    if not root then return end
    local group = root
    for _, key in ipairs(spec.path or {}) do
        local child
        for _, plugin in pairs(group.plugins or {}) do if plugin[key] then child = plugin[key]; break end end
        child = child or (group.args and group.args[key])
        group = child; if not group then return end
    end
    return { root = root, group = Select(group, spec), path = spec.path or {}, title = spec.title, module = spec.module }
end
function N.Generation(page)
    page = N.Route(page)
    local entry = C.pages[page]; if not entry then return 0 end
    local modules = {}
    if entry.module then modules[entry.module] = true end
    if entry.tabsFrom then modules[entry.tabsFrom] = true end
    for _, source in ipairs(entry.sources or {}) do modules[source.module] = true end
    for _, tab in ipairs(entry.tabs or {}) do for _, source in ipairs(tab.sources) do modules[source.module] = true end end
    local keys = {}; for key in pairs(modules) do keys[#keys + 1] = key end; table.sort(keys)
    local parts = {}; for _, key in ipairs(keys) do parts[#parts + 1] = key .. ":" .. tostring(FluxOptions:GetModuleGen(key)) end
    return table.concat(parts, ";")
end
local function BuildView(tab)
    local view = { type = "group", name = tab.name, args = {}, _fluxSources = {} }
    for _, spec in ipairs(tab.sources or {}) do
        local source = ResolveSource(spec); if source then view._fluxSources[#view._fluxSources + 1] = source end
    end
    if tab.notice then view.args.notice = { type = "description", name = tab.notice, order = 1, width = "full" } end
    if tab.action then
        local action = tab.action
        view.args.open = { type = "execute", name = action.label, order = 2, width = "full", func = function() FluxOptions:ShowConfig(action.page, action.sub) end }
    end
    for index, action in ipairs(tab.externalActions or {}) do
        local target = action
        view.args["external_" .. index] = { type = "execute", name = target.label, order = 4 + index / 100, width = "full",
            desc = "Open this feature's settings outside combat.",
            disabled = function()
                if InCombatLockdown and InCombatLockdown() then return true end
                local owner = _G[target.owner]; return not (owner and type(owner[target.method]) == "function")
            end,
            func = function()
                if InCombatLockdown and InCombatLockdown() then return end
                local owner = _G[target.owner]; if owner and owner[target.method] then owner[target.method]() end
            end }
    end
    if not tab.notice and not tab.action then
        view.hidden = function()
            if #view._fluxSources == 0 then return false end
            for _, source in ipairs(view._fluxSources) do if not ns.FluxOptionsRender.SourceHidden(source) then return false end end
            return true
        end
    end
    return view
end
function N.Resolve(page)
    page = N.Route(page)
    local entry = C.pages[page]; if not entry then return end
    if entry.profiles then return FluxOptions:GetProfilesOptions() end
    if entry.module then return FluxOptions:ResolveModuleOptions(entry.module) end
    if entry.text then return { type = "group", name = entry.name, args = { text = { type = "description", name = entry.text, fontSize = "medium", width = "full" } } } end
    local gen = N.Generation(page)
    if cache[page] and cache[page].gen == gen then return cache[page].group end
    if entry.sources then
        local view = BuildView(entry)
        cache[page] = { gen = gen, group = view }
        return view
    end
    local group = { type = "group", name = entry.name, childGroups = "tab", args = {} }
    local tabs = entry.tabs
    if entry.tabsFrom then
        tabs = {}
        local root = FluxOptions:ResolveModuleOptions(entry.tabsFrom)
        for _, sub in ipairs(ns.FluxOptionsRender.ListSubpages(root, true) or {}) do
            if not (entry.omitTabs and entry.omitTabs[sub.key]) then
                tabs[#tabs + 1] = { key = sub.key, name = sub.name, sources = {
                    { module = entry.tabsFrom, path = { sub.key }, except = entry.tabExcept and entry.tabExcept[sub.key] },
                } }
            end
        end
    end
    for i, tab in ipairs(tabs or {}) do local view = BuildView(tab); view.order = i; group.args[tab.key] = view end
    if entry.checkAvailability then
        group.hidden = function() return #(ns.FluxOptionsRender.ListSubpages(group) or {}) == 0 end
    end
    cache[page] = { gen = gen, group = group }
    return group
end
