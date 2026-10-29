# Event dispatch mutation audit

Audited 2026-10-29 at baseline commit `201bc8382f9fa6b5d9906200e3331a4ad90c2f13`, after the currency handoff fix. The current Events implementation has a reproducible mutation defect in its public callback API. The audit did not establish an active gameplay path that triggers it, so a dispatcher rewrite is deferred behind reproduced provider handoff failures.

No runtime file was changed for this audit. Checkpoint `FluxUI-recovery-20261029T0932Z` preserves the current files before the next runtime batch. Raw-byte source hashes used for the replay:

| Source | SHA-256 |
|---|---|
| `Core/Engine/Events.lua` | `9c8d593abc270abe4f5e6d403e9f0c93eb3c593c2f1c2b4acc3a4556ae813454` |
| `Core/Engine/Context.lua` | `67b4063ebd6c71ef2724dd8d4a19bf30480a40320475240da832e79e3f112ef7` |

## Reproduction and interpretation

The replay loads the real [Events implementation](../Core/Engine/Events.lua) with only native frame creation and event validity mocked. It invokes the actual dispatcher callback directly. Lua 5.4.6 executes this as a desktop API test; it is not a native event trace or a reproduced player-facing failure.

| Scenario | First dispatch | Second dispatch | Interpretation |
|---|---|---|---|
| A removes itself; B and C remain | `A,C` | `B,C` | B is skipped when `table.remove` shifts B into the already-visited slot. |
| A removes upcoming B | `A,C` | `A,C` | Removed B does not run; C remains reachable in this case. |
| A adds D once | `A,B,C` | `A,B,C,D` | The numeric loop's initial limit delays D until the next dispatch. |
| A removes B and adds D once | `A,C,D` | `A,C,D` | D unexpectedly runs in the first dispatch because removal freed a slot inside the original loop limit. |
| A unregisters all and registers D | `A` | `D` | The current list is wiped and replaced; the new list runs next time. |
| A invokes nested dispatch; nested A removes itself | `A1,A2,C2,C1` | `B1,C1` | B is skipped in both outstanding dispatches sharing the mutated list. |

`1` and `2` identify outer and nested calls, not WoW frames. These are deterministic callback sequences. No native CPU, allocations, latency or FPS measurements were collected, and the audit makes no performance claim.

## Actual consumer trace

The fresh `_FluxUI.toc`/XML closure contains 577 files. Source search covered its reachable addon-owned Lua files and the broader repository for aliases and indirect names. It found one active source consumer of `Flux.Events.Unregister`:

- [Context.lua](../Core/Engine/Context.lua), lines 533-550: `Context.DisarmEvents` assigns `local Ev = Flux.Events` and calls `Ev.Unregister` for mouseover, target, combat start/end and focus events.
- The only call to `Context.DisarmEvents` found in the current active addon source is `Context.Unsubscribe`, line 296, after the subscriber count reaches zero.
- No current production invocation of `Context.Unsubscribe` or external invocation of `Context.DisarmEvents` was found. The active subscription at [ProgramFace.lua](../Bars/ProgramFace.lua), lines 1544-1546, is installed once by `ProgramFace.Start` and has no corresponding unsubscribe path.
- Context's event callbacks request deferred refresh work through the existing timer/scheduler pipeline; they do not currently unregister themselves directly.

Other similarly named methods are different owners: `Flux.Modifier.Unregister`, `Flux.Identity.Unregister`, `Flux.Inventory.Unregister`, `FluxBtn.Unregister`, and `FluxRestock.Inv`/`FluxRespec.Inv` forwarding to inventory listener removal. The inactive `Inventory/FluxInv` and legacy extra-button event engines are not the central Events dispatcher. `Flux.Engine.Events` is an alias published by Events.lua; no additional active unregister caller through that alias was found.

This is a static consumer audit. It cannot exclude externally injected Lua, optional addons calling exported tables, or synthesized dynamic field names. It does establish that no normal in-repository self-removal trigger was demonstrated. Keep the finding classified as a **latent API defect**, not a measured hotspot or confirmed gameplay regression.

Searches from the addon root:

```powershell
rg -n 'Events\.Unregister|Ev\.Unregister|Engine\.Events' -g '*.lua' -g '!libs/**' -g '!new docs/**'
rg -n '(Unsubscribe|DisarmEvents|ArmEvents)\(' -g '*.lua' -g '!libs/**' -g '!new docs/**'
rg -n '\.Unregister\b|\[\s*["'']Unregister' -g '*.lua' -g '!libs/**' -g '!new docs/**'
```

## Contract and implementation recommendation

Before adding teardown paths that can remove handlers during an event, specify these rules: preserve registration order, call each still-registered entry at most once per dispatch, skip entries removed before their turn, and start newly registered entries with a subsequent dispatch. A nested invocation is a new dispatch and may see registrations that existed when that invocation began. Existing duplicate registration remains multiple entries; unregistering a function currently removes all matching entries and should retain that meaning.

For those rules, a future bounded implementation can retain stable array positions during dispatch, mark removals with `false` tombstones, and compact when the outermost invocation completes. Keeping tombstones non-nil preserves array length; capturing each invocation's starting limit prevents appended callbacks from joining that invocation. A per-list dispatch depth is required for nesting, and clearing/re-registering must not let cleanup of an old list overwrite a new list. Measure the added steady-state bookkeeping before accepting it.

Copying the listener array for every event is simpler but allocates on hot events and requires separate removal checks to satisfy immediate cancellation. Copy-on-write on mutation avoids steady-state copies but still needs a defined relationship between old dispatch snapshots and later removal. Neither approach is justified solely to shrink the function. Existing pcall callback error reporting should remain; it is not a mechanism for hiding skipped subscribers.

Prioritize concrete pending-mail/auction work that can execute after provider ownership changes. Return to this dispatcher defect when adding a real teardown consumer or when a native/source trace demonstrates impact. Extend the regression set with duplicate handlers, removing a previously-run handler, nested clears/re-registers, callback errors and resource counts before changing the shared service.

## Standalone replay

Pipe the following Lua block to `lua -` from the addon root. In PowerShell, wrap the block in a single-quoted here-string (`@'` and `'@`) and pipe it. It writes no repository files.

```lua
local function harness()
    local env = setmetatable({}, { __index = _G }); env._G = env
    env.wipe = function(t) for k in pairs(t) do t[k] = nil end end
    env.C_EventUtils = { IsEventValid = function() return true end }
    local frames = {}
    env.CreateFrame = function()
        local f = { scripts = {}, events = {} }
        function f:RegisterEvent(e) self.events[e] = true end
        function f:UnregisterEvent(e) self.events[e] = nil end
        function f:SetScript(k, fn) self.scripts[k] = fn end
        function f:Hide() end
        frames[#frames + 1] = f
        return f
    end
    local ns = { Flux = { Client = {} } }
    assert(loadfile("Core/Engine/Events.lua", "t", env))("_FluxUI", ns)
    local function fire(depth)
        frames[2].scripts.OnEvent(frames[2], "TEST", depth or 1)
    end
    return ns.Flux.Events, fire
end
local function run(name, setup)
    local e, fire = harness()
    local out = {}
    local function note(s) out[#out + 1] = s end
    setup(e, fire, note)
    fire()
    local first = table.concat(out, ",")
    out = {}
    fire()
    print(name .. ": first=[" .. first .. "] second=[" .. table.concat(out, ",") .. "]")
end
run("self-remove", function(e, fire, n)
    local a; a = function() n("A"); e.Unregister("TEST", a) end
    e.Register("TEST", a)
    e.Register("TEST", function() n("B") end)
    e.Register("TEST", function() n("C") end)
end)
run("remove-next", function(e, fire, n)
    local b = function() n("B") end
    e.Register("TEST", function() n("A"); e.Unregister("TEST", b) end)
    e.Register("TEST", b)
    e.Register("TEST", function() n("C") end)
end)
run("add", function(e, fire, n)
    local added = false
    e.Register("TEST", function()
        n("A")
        if not added then added = true; e.Register("TEST", function() n("D") end) end
    end)
    e.Register("TEST", function() n("B") end)
    e.Register("TEST", function() n("C") end)
end)
run("remove-next-and-add", function(e, fire, n)
    local added = false
    local b = function() n("B") end
    e.Register("TEST", function()
        n("A"); e.Unregister("TEST", b)
        if not added then added = true; e.Register("TEST", function() n("D") end) end
    end)
    e.Register("TEST", b)
    e.Register("TEST", function() n("C") end)
end)
run("clear-and-register", function(e, fire, n)
    e.Register("TEST", function()
        n("A"); e.Unregister("TEST")
        e.Register("TEST", function() n("D") end)
    end)
    e.Register("TEST", function() n("B") end)
    e.Register("TEST", function() n("C") end)
end)
run("nested-self-remove", function(e, fire, n)
    local a
    a = function(_, depth)
        n("A" .. depth)
        if depth == 1 then fire(2) else e.Unregister("TEST", a) end
    end
    e.Register("TEST", a)
    e.Register("TEST", function(_, depth) n("B" .. depth) end)
    e.Register("TEST", function(_, depth) n("C" .. depth) end)
end)
```
