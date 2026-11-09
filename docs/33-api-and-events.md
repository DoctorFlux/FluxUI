# Shared APIs, notifications and identifiers

These are internal cross-system contracts observed in the current implementation. This documentation adds no addon API and does not turn every exported global into a supported external integration surface. Use [shared services](08-shared-services.md) for implementation detail and the [generated interface/event index](reference/interfaces.md) to find declarations or registration sites.

## Namespaces and lifetime

| Surface | Contract |
|---|---|
| `ns.Flux` / `_G.Flux` | Same kernel table. Owns client/API wrappers, engines and newer systems. Defined before the other Core files. |
| `Flux.API` and direct `Flux.Spell/Item/Container/...` | Current compatibility wrappers. Direct fields and subtable entries are assigned by their owner; do not assume an arbitrary name exists in both forms. |
| `ns.API`, `FluxAPICompat`, `FLUX_API` | Retained compatibility facades used by older HUD code. They have their own initialization and sometimes different semantics. |
| `FluxOptions` | Ace addon/settings owner. Its DB accessor methods select the effective scope and initialize/migrate stores. |
| Feature globals | `FluxBinding`, `FluxBindingDB3API`, `FluxInv`, `FluxConsumableBest`, `FluxRespec`, `FluxVendorAuto`, `FluxBankRestock`, `FluxSalvage`, etc. Some point to live facades over newer code; a name alone does not identify an old implementation. |

In particular, `Flux.Client.isClassic` means Wrath/Cata/Mists, while `FLUX_API.isClassic` means Era. Use the exact facade's definitions and [client matrix](02-multi-client-matrix.md). [Kernel](../Core/Flux.lua), [current client](../Core/Client.lua), [legacy client](../Core/FluxAPI/Client.lua), [legacy bridge](../Inventory/LegacyBridge.lua).

## Lifecycle and module contracts

| Interface | Inputs / outputs and ownership |
|---|---|
| `Flux.AfterLoad(fn)` | Run after this addon's ADDON_LOADED and all TOC source execution; run immediately if already loaded. Calls use Safecall. |
| `Flux.AfterLogin(fn)` | Run when the kernel login phase starts, or immediately if already started. Forever startup may defer this phase beyond the raw event. |
| `Flux.Module.Register(name,spec)` | Spec can provide `clients`, `capabilities`, `requiredAddons`, `optional`, `OnLoad`, `OnEnable`, `OnDisable`. Registration does not mean eligible/enabled. |
| `Module.Enable/Disable/IsEligible/IsEnabled/List` | Ordered registry and enable flags. Required addons must already be loaded; optional metadata does not block. It is not the lifecycle owner for every feature. |
| `Flux.Safecall(fn,...)` | Protected invocation/error reporting. This does not grant access to protected WoW operations. |

Sources: [kernel](../Core/Flux.lua), [module registry](../Core/Module.lua).

## Event bus and refresh scheduling

| Interface | Callback / behavior |
|---|---|
| `Events.Register(eventName,fn)` | Callback receives `fn(event,...)`. Returns success boolean; invalid/unavailable event names are rejected. Multiple registrations append. |
| `Events.Unregister(eventName,fn)` | Remove the matching function; omitted function clears the event's listeners. |
| `Events.RegisterUnit(eventName,unit,fn)` | Separate unit-event frame, returned to caller; false on invalid/failed registration. The callback receives `(event,...)`; it is a direct invocation, unlike the protected central bus. |
| `Events.SafeRegister(frame,event)`, `SafeRegisterUnit(frame,event,...)` | Validate then register on a feature-owned frame, returning success. They do not take over the frame's handler. |
| `Scheduler.Register(tier,fn)` | Callback receives token-set and reason-set on a tier flush. |
| `Scheduler.Request(tier,token,fn,reason)` | Merge token/reason sets, append optional work function, schedule next-frame flush. Tier order: layout → display → eval → structural → inventory. |
| `Scheduler.BeginPaging/EndPaging/IsPaging` | Shared paging phase indicator. Pending display/eval work is retained for later lanes. |
| `Combat.Defer(key,fn)` | Outside lockdown, execute immediately; in lockdown, retain one job per key, replacing earlier same-key work. |
| `Combat.RegenDefer(fn,heavy)` | Separate list-based post-regen queue; light/heavy work is drained after combat on a deferred frame. |
| `Ticker.Add(key,fn)`, `Remove(key)` | Keyed subscribers to a shared OnUpdate; callback takes elapsed time. Shared driver disarms when its subscriber list is empty. Other addon drivers may remain active. |
| `Timer.After(duration,callback)`, `NewTicker(duration,callback,iterations)`, `Defer(callback)` | Wrapper/fallback timing primitives. Cancellation behavior depends on the actual returned handle; After is not documented as a cancellable native NewTimer. Legacy FLUX_API also polyfills missing global timer APIs. |

Sources: [Events](../Core/Engine/Events.lua), [Scheduler](../Core/Engine/Scheduler.lua), [Combat](../Core/Engine/Combat.lua), [Ticker](../Core/Engine/Ticker.lua), [Timer](../Core/Engine/Timer.lua), [legacy timers](../Core/FluxAPI/Timers.lua).

Scheduler tokens are merged identities, not a guarantee that all appended callbacks deduplicate. The inventory per-flush callback cap is eight, while registered tier listeners follow their own loop. Same-key combat replacement is not equivalent to merging all queued operations.

## Display context, modifiers, identity and range

| Interface | Contract |
|---|---|
| `Modifier.Register(key,callback,opts)` / `Unregister(key)` | Keyed modifier bus, with owner-defined active gating. Consumers use it to avoid independent permanent modifier polling. |
| `Context.Subscribe(fn)` / `Unsubscribe(fn)`, `Request(force,opts)`, `RequestMouseover()` | Fingerprint-gated display-context notification. This lane does not itself compile every binding or mutate secure attributes. |
| `SpellBook.OnChanged(key,fn)`, `Sync()` | Keyed spellbook change notifications after coalescing/signature checks. |
| `Identity.Register(key,surface)`, `Publish(key,kind,id)` | Publisher for the **shown** action face. Publish returns whether kind/id changed; same signature skips notifications. |
| `Identity.Get(key)`, `GetRecord(key)`, `OnChange(fn)` | Get returns kind/id; record is `{kind,id}`; notification is `fn(key,kind,id)`. `SoftSync()` republishes current identities to listeners without binding Apply. |
| `Range.RegisterSweep(key,needFn,sweepFn)` | Demand-aware named range surface; shared range service owns arming and memoization. |
| `Range.CheckSpell/CheckItem/CheckAction` | Compatibility results must preserve unavailable/unknown states; consumers must not convert every non-true result into an out-of-range claim. See each wrapper and paint caller. |
| `Range.Invalidate()`, `InvalidateSweep(key)`, `Sync()` | Refresh cached context/surfaces and synchronize demand. |

Identity keys are `slot:<actionSlot>` and `badge:<actionSlot>:<index>`. These are different from binding placement IDs such as `ab:45`, `stance:2`, or `extra:…`. A displayed spell, original action occupancy and binding row UID are also different identifiers.

Sources: [Modifier](../Core/Engine/Modifier.lua), [Context](../Core/Engine/Context.lua), [SpellBook](../Core/Engine/SpellBook.lua), [Identity](../Core/Engine/Identity.lua), [Range](../Core/Engine/Range.lua), [binding placement](../Binding/Core/Placement.lua).

## Restricted execution and bar paging

`Flux.Restricted` and `Flux.Engine.Restricted` refer to the same helper table, but its general and bar-only policies deliberately differ. Sources: [Restricted.lua](../Core/Engine/Restricted.lua), [capabilities](../Core/Capabilities.lua), [bar state](../Bars/State.lua), [click policy](../Core/ButtonFX/Click.lua).

| Interface | Contract |
|---|---|
| `Restricted.Works()` | General capability policy. Returns false when `Cap.hasRestrictedClosures` is false; this remains the Forever policy for existing non-bar consumers. |
| `Restricted.PagingWorks()` | General support returns true directly. Otherwise only Forever/Camelot can run an OOC `SecureHandlerBaseTemplate` execution probe. An OOC result is cached until reload; an in-combat refusal is not cached. `Cap.hasSecureBarPaging` records that Forever probe and may remain nil on other clients. |
| `SetPagingSnippet(frame,name,body)`, `ExecutePaging(frame,body)` | Refuse setup from insecure Lua during lockdown or after a failed paging probe. With a valid caller-supplied frame they return the protected native call's status/result. Native callbacks already installed OOC own combat page changes. |
| `RegisterPagingDriver(frame,state,values)`, `UnregisterPagingDriver(frame,state)` | OOC only. Use the captured native attribute-driver functions with `state-<state>` when paging works and the entrypoint exists; otherwise delegate to the existing state-driver wrapper. |
| `Bars.State.UsesSecurePaging()` | Alias of the bar capability decision, separate from click wrapping and `Restricted.Works`. Inspect with `/fluxbars page`; successful paging does not enable Forever mouseover wraps or change key/mouse edges. |
| `Action.LeaveBlizzardCollector()` | Forever collector no-touch policy. Nil/detach/sweep paths return without changing those native collectors. `WithRegistrationSuppressed(fn)` now directly returns `fn()`; its old name does not imply temporary method replacement. |

Native main columns and saved slot programs are separate contracts. Temporary pages (`page >= 11`) suppress ordinary compiled macro/click overlays on the first twelve main hosts, ignore modifier promotion for those mains and preserve ordinary promotion flags for exit. Static columns 13–19 keep their own slot mapping. Failed probes require reload to attempt the probe again; an OOC fallback cannot be described as secure combat paging.

## Inventory facts and consumer callbacks

`Flux.Inventory` supplies snapshots and query methods over builtin or Syndicator-backed facts. Important entrypoints include `GetSource()`, `IsReady()`, `GetCount()`, `GetLiveCount()`, `Find()`, store/ledger facades and the listener registration below. Read [inventory](21-inventory-foundation.md) for exact query options and live/remembered region behavior.

`Inv.Register(key,fn,opts)` registers a keyed listener. `opts` supports `tier="instant"|"light"|"scan"|"heavy"`, `regions`, `deferHeavy`, and `sync`. `Inv.Unregister(key)` removes it. The dispatched callback receives the context built by Notify:

```lua
{
  regions = ..., source = ..., tier = ..., time = ...,
  changeKind = ...,
  addedItemIDs = ..., removedItemIDs = ..., dirtyBags = ...,
  touchedItemIDs = ..., changedItemIDs = ..., force = ...
}
```

Count-only change, item-ID occupancy change, item-data completion and forced refresh are distinct inputs. Do not assume every notification means the whole inventory changed. The wrapper can queue heavy work during startup/bag/mail storms. `IsReliable()`, `IsLoginHold()`, `SnapshotLooksCollapsed()`, and `ShouldDeferHeavyWork()` inform consumers that apparent emptiness may be transient.

`RegisterStormSettled(key,fn)` is keyed; `OnStormSettled(fn)` is a different listener facility. `RegisterBankStateListener(key,fn)`, `IsBankLive()`, `CanTakeFromBank()` and Baganator live-bank latches distinguish a remembered bank view from actionable bank access.

Sources: [notification context and registration](../Inventory/Init.lua#L715), [query index](../Inventory/Index.lua), [builtin/Syndicator adapters](21-inventory-foundation.md).

## Binding and Respec contracts

The live binding document API is `FluxBindingDB3API` / `ns.FluxBindingDB3`. `Ensure()` can return a preview override; `EnsureLive()` cannot. `SetDocumentOverride(doc)` installs/removes the preview. Rows, chord stacks, form profiles and placement identities are documented in [saved schemas](32-saved-variables.md) and [binding](13-binding-system.md).

`FluxBinding.RequestApplyAll(reason)` requests coalesced compilation/application. Authoring state can change before protected runtime application finishes. Consumers needing completion must use the actual snapshot/apply callback paths in [Binding/Respec.lua](../Binding/Respec.lua), including combat deferral and sticky-row preservation. Merely requesting Apply is not an acknowledgement.

Respec's local event bus is `FluxRespec.On(event,fn)` / `Fire(event,...)`; it is not the WoW event bus. Events include `PROFILES_CHANGED`, `ACTIVE_CHANGED`, `TALENTS_APPLIED`, `RUNE_QUEUE_CHANGED` and `APPLY_DONE`. Profile selection, profile capture and profile application are separate operations. In current code, downstream binding failure can still lead to `APPLY_DONE(true,"DONE")`; that event cannot by itself prove every subsystem succeeded. [Apply orchestration](../Respec/FluxRespec_Apply.lua), [findings](40-findings.md).

## Options, UI and integration contracts

`FluxOptions:RegisterModuleOptions(key,optionsTableOrBuilder)` accepts an Ace-style options table or deferred builder. The catalog chooses visible pages, the shell chooses a page/subpage and the renderer evaluates the table. Accessors such as `GetActionbarsDB()`, `GetRaidFrameDB()`, `GetUnitFrameDB()`, `GetLayoutDB()`, `GetWindowMoverDB()`, `GetMicroMenuDB()` and `GetStatusBarSettingsDB()` own scope selection. Use them instead of directly caching a guessed profile branch.

The renderer inherits `get`, `set`, `func`, `confirm`, `validate`, `hidden` and `disabled` down option paths. String-valued members can resolve through a handler; native rendering retains custom AceGUI `dialogControl` embeds. [Options map](26-options-map.md), [widget controls](35-custom-widget-controls.md), [renderer](../AddonOptions/FluxOptionsRender.lua).

Optional integrations can replace ownership rather than simply add decoration. In particular, Syndicator delegates inventory storage, ConsolePort suppresses selected micromenu/status ownership, Baganator installs hooks/global item-API wrappers, and the meter chooses an available backend. Their readiness/failure contracts belong to the [integration matrix](29-integrations.md).

`addonTable.FluxQuestie:IsTrackerEnabled()` selects tracker ownership from Questie's loaded profile and `trackerEnabled == true`, independently of the current frame's visibility. `RequestLayout(delay)` coalesces layout requests; combat marks pending work for regen. A collapsed Questie tracker still owns the dock. `TrackerWidth` is a Questie preference; this integration does not introduce another Flux profile scope. [Tracker owner](../Minimap/FluxQuestie.lua).

`FluxBattlefieldMapPinRouter:IsLibrarySupported(name)` gates pin routing independently of tracker ownership. With `QuestDataProviderMixin`, only Forever's `HereBeDragonsQuestie-Pins-2.0` route is accepted; older clients without native quest providers can use the broader supported library set. `RequestRefresh()` coalesces to the next frame and invalidates stale work on uninstall. Original World Map icon objects move between owners, so release must precede acquisition; the World Map has priority while open. [Pin router](../Battlezonemap/FluxBattlefieldMapPinRouter.lua).

## Reading the generated index

[interfaces.md](reference/interfaces.md) contains registration sites and syntactically declared function candidates for reachable production source. It includes table-local methods, preserves dynamic expressions and omits some assigned aliases/generated definitions. It is useful for finding callers and implementations, not a complete evaluated namespace or proof that every callback runs.

[contracts.json](reference/contracts.json) records curated source fragments used by the documentation checker. The checker verifies their presence and source freshness; humans still need to review whether the prose matches the function body and callers.
