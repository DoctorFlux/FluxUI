# Shared APIs, refresh services and button feedback

<!-- COMBAT-FANOUT-20261116 -->
16 November `COMBAT-FANOUT-20261116`: full combat refreshes/recovery retained with fresh-native icon/trinket geometry guards and protected callback-body reuse. 496 offline scripts PASS/1 new shadow assertion FAIL; 1187 syntax PASS; composed current-source observations; owned runtime stable. Native tests/inspection HELD until explicit user release. [Exact work, native getter tax, CPU regressions/rejected prototypes and scope](validation/combat-fanout-2026-11-16.json).
<!-- /COMBAT-FANOUT-20261116 -->


16 November `COMBAT-TRANSITIONS-20261116`: R51 `prepared-guards-r51` extends
the existing finite combat capture with callback provenance for both combat
events and named/light/heavy defer queues. No extra monitor or default clock is
added; raw frame/native callbacks remain attribution gaps. Preserve queue order,
reentrant lockdown/error handling, live native/private checks and existing cadence.
The101/36/8 consumer source ledgers are distinct from a live registration census.
Combined R51 aggregate474 PASS/0FAIL and1165 syntax PASS follows one legacy
extractor correction/four bounded replays; eight owned runtime files stayed
stable, not one globally frozen sweep. Global690 files/24916 prototypes max57/0fail;
31944 border guard checks PASS. Native R51 remains pending.
[Requirements and evidence](COMBAT_TRANSITION_PERFORMANCE.md).

15 November: range now follows the selected cast target, independently of idle
icons, pinned tooltips and reverse badge token swaps. Plain actions apply the
native friendly/hostile eligibility rule. The reported Frostbolt/friendly-hover
case is confirmed in game. [Rules and scoped validation](CAST_RANGE_TARGETING.md).

15 November: hotkey text and mouse/scroll/space glyphs turn red only for the
existing out-of-range result. Original gray text/white art returns in range;
binding/modifier/size refreshes retain the correct color. No new range probes or
polling. [Four-surface requirements and validation](HOTKEY_RANGE_GLYPHS.md).

16 November frozen border `adaptive-fallback-r50`: dedicated1226/Cost74 PASS,
full467/1157 stable and global Lua5.1 689files/24857prototypes max57/0fail PASS.
Quiet native R50 now measured218.36ms versus R49's207.94ms; hitch/CB36 OPEN.
Unconditional index rejected; adaptive keeps R49
flat publication/buckets≤4 and lazily indexes only queried larger buckets. Numeric/
current-paint/token/budget guards and fresh native coordinates remain. Common24 CPU
mixed+1.43%,56−6.20%; dense−78.12% stress-only. Further native captures require
all owned CPU/docs jobs finished. No native gain or solve optimization is claimed.
[Requirements and evidence](CONNECTED_BORDERS.md).

Historical earlier 15 November exact pre-connection restore: the junction service and all its hooks,
scheduler registration, script/mask capability logic and extra graphics are
removed at the user's request. Shared border code matches the earlier verified
checkpoint, with independent original rendering and original appearance options.
The later paint-only Trinket helper is also reverted. [Current restore and native limits](04-visual-system.md).

15 November 08:58:53 UTC current clock correction: this exact desktop Lua
5.4.6 binary advances `os.clock` while blocked on stdin (0.512s/1.011s),
while whole-child GetProcessTimes CPU was 0.015625s/0s. Earlier `os.clock`
figures therefore measure elapsed time, not isolated CPU. R29
+10.74%/+13.61%/-12.52% and R27 16–38% are matched desktop elapsed results.
Historical CPU labels and raw reports are retained with this overriding
interpretation. R27 104→0 transient bytes/query and other GC-controlled
allocation counts retain their stated scope; no CPU/FPS gain follows.
Future timings must identify their clock and distinguish measured-chunk
elapsed time from independently captured whole-child process CPU.

15 November R33 EBS range helpers (`LHO-EBS-RANGE-WORK-R33-20261115`): Paint now
reuses two private functions while passing this invocation's btn/range owner/unit.
Dynamic public method lookups, item revision/write order, raw errors/arity and
reentry remain. Existing0.18s lane, immediate invalidation, callbacks and native
modeled work are unchanged. Direct232B/probe transient slope is removed; mixed
producer2264→1104B/sequence. Full395/1083 and durable40/295 pass before apply;
native source adoption/event-spike/FPS/taint/pixels/controller remain pending.
The absent-target elapsed path is3ms slower/250000 calls; keep it separate from
quantized whole-child process CPU and the earlier clock correction. No observer
was installed by the failed-before-keys supervised preflight; native halt/hold stay.
[Source, ranges and lifecycle scope](validation/lag-hotspots-native-attribution-2026-11-14.json).

15 November ButtonFX cast equality: `SpellIdsMatch` reuses stateless private
comparison callbacks while retaining protected equality, public matcher/native
reads, errors/reentry and all interrupt/reticle/progress/fade cadence. Five desktop
pairs give modeled CPU 377->306 ms per 200 sequences; allocation 50,961.934->3,919.746
KiB with GC stopped. Full 389 scripts/1,077 syntax PASS; native after-candidate,
taint, pixels/controller and FPS remain pending. [Exact comparison and native scope](validation/casting-equality-work-2026-11-15.json).

14 November casting/inventory lag: Cast/VFX protected callbacks reuse stateless functions while native queries, errors, private timers and paint cadence remain. [Comparisons and limits](LAG_HOTSPOT_OPTIMIZATION.md).

13 November world-cursor tooltip ownership: binding hints/owners, protected-gear decoration and consumable separator bookkeeping live in private weak-key tables. Clear/hide callbacks preserve Blizzard's shared tooltip Lua fields; existing text, HUD positioning and refresh/input owners remain. [Source comparison, regressions and native limits](SECRET_TOOLTIP_METER_ERRORS.md#world-cursor-follow-up-at-202955).

10 November passive pass 3: Checked spell, last-number/coercion and aura-payload helpers reuse functions; existing lookup/access/error policy remains. [Before/after and native limits](PASSIVE_PERFORMANCE_PASS3.md).

10 November passive pass 2: Range/protected helpers reuse function objects with unchanged cache, access and query behavior. [Before/after evidence and native limits](PASSIVE_PERFORMANCE_PASS2.md).

<!-- STRESS-FIXES-20261107 -->
7 November applied stress fixes: Events preserve listener delivery during removal; Scheduler retains nested FIFO callbacks and older paused structural batches, invalidates stale timers, and budgets inventory at 8 callbacks per scheduled flush. Combat RegenDefer budgets 16 distinct jobs per frame with combat reentry pause. Sustained mouseover can no longer starve shared range sweeps indefinitely. [Evidence](../Stress%20test%20doc/applied-fixes/README.md). Native taint/pixels/performance acceptance remains pending.
<!-- /STRESS-FIXES-20261107 -->

The newer shared layer is under `Core/API`, `Core/Engine` and `Core/ButtonFX`. Older HUD code still uses `Core/FluxAPI` and global helper functions. This chapter explains the contracts and data flow; [33-api-and-events.md](33-api-and-events.md) provides a lookup index.

## Adapter contracts

Adapters normalize API generations and selected tuple/table differences. They do not make every returned combat value accessible to Lua. Health, power, cooldown, charge, count and threat values can intentionally pass through to display widgets.

| Adapter | Important behavior | Source |
|---|---|---|
| `Flux.AddOn` | Chooses `C_AddOns` or globals. `Exists` scans the current game type's addon list first; `IsLoaded`, `Load`, `Enable`, metadata/info and loadability are guarded. | [`AddOn.lua`](../Core/API/AddOn.lua) |
| `Flux.Spell` | Cached tuple-style info/name/icon/subtext; conditional/live icons, base/override matching, cast attributes, flyout resolution, cooldown/charge duration objects, current/autorepeat, usability and range. | [`Spell.lua`](../Core/API/Spell.lua) |
| `Flux.Item` | Info/icon/count/spell, usability/equipped/current/range, consumable and charged-mana-gem policy, and cooldown fallback. | [`Item.lua`](../Core/API/Item.lua) |
| `Flux.Container` | Bag/slot validation and normalized item records. Modern API misses can fall back to legacy data; move/use/split APIs share validation. | [`Container.lua`](../Core/API/Container.lua) |
| `Flux.Aura` | Slot/index/instance access plus specialized player/cooldown-aura/duration queries; direct display wrappers for unit health/power. | [`Aura.lua`](../Core/API/Aura.lua) |
| `Flux.Action` | Action occupancy/texture/usability/count/cooldown/charges, Assisted Combat queries and safe collector detachment helpers. | [`Action.lua`](../Core/API/Action.lua) |
| `Flux.Pet`, `Flux.Shapeshift` | Normalize pet/form info and cooldown tuples or tables. Shapeshift identity uses base/override spell matching. | [`Pet.lua`](../Core/API/Pet.lua), [`Shapeshift.lua`](../Core/API/Shapeshift.lua) |
| `Flux.Spec` | Specialization and role fallbacks. Installs a global role shim only for a missing/broken non-Retail native API; does not replace `PlayerUtil.IsPlayerEffectivelyTank`. | [`Spec.lua`](../Core/API/Spec.lua) |
| `Flux.CVar` | Reads and guarded writes; blocks coupled nameplate/raid/target-cast settings on selected clients. The threat bitfield has a specific allowed route. | [`CVar.lua`](../Core/API/CVar.lua) |
| `Flux.Secrets` | Access/secret checks, safe comparison/booleans/GUID/cache/count/aura metadata helpers. | [`Secrets.lua`](../Core/API/Secrets.lua) |
| `Flux.Threat` | Client-aware threat query/display, warning/numeric/bitfield controls, group ranking and meter-row normalization. | [`Threat.lua`](../Core/API/Threat.lua) |
| `Flux.PlayerName` | Names, optional surnames, canonical keys, equality and existing-key migration. | [`Name.lua`](../Core/API/Name.lua) |

Specific distinctions that callers must preserve:

- `Spell.IsUsable` can return `nil, nil` for an unavailable/secret result; this is not the same as a known unusable spell. Spell range is tri-state: in range, out of range, or unknown/not applicable.
- `Spell.GetInfo` caches numeric-ID results. A cold record identified by `IsSpellDataCached` requests loading without caching a permanent miss. `SPELL_DATA_LOAD_RESULT`, icon events and learned-spell events invalidate relevant caches. `GetLiveFace` is separate from an assigned spell's original icon.
- `Item.GetCount` evaluates compatible three/four/five-argument queries and keeps the largest valid count when bank/reagent/account flags are involved. This is an API count helper, distinct from the inventory foundation's stored facts.
- `Item.UsesConsumableCharges` distinguishes stack quantities from charges, including known mana gems and consumer kind context. `Item.GetCooldown` tries modern/container/legacy APIs and prefers the longest accessible remaining timer over zero/GCD stubs; it retains a secret timer candidate when a useful readable timer is absent.
- `Container.GetItemInfo` returns a normalized table when available. Its second return can distinguish an empty slot from a slot whose item data is not yet cached. Bag IDs may be zero or negative; slots must be positive integers. It copies modern records before repairing fields rather than modifying Blizzard tables.
- `Action.OccupancyKey` is type plus ID. A macro displaying a different conditional spell is a display identity change, not a different slot occupant.
- New `Aura.GetSlots` returns the slot list and success/accessibility state. Legacy `SafeGetAuraSlots` preserves its consumers' continuation-token-shaped return list. They should not be interchanged solely because the names sound similar.
- Generic aura enumeration is gated by secret access. `GetPlayerAuraBySpellID` deliberately is not gated the same way, because a specialized query can return a usable nonsecret aura or nil while general access is restricted.

## Event and timer primitives

[`Core/Engine/Events.lua`](../Core/Engine/Events.lua) exposes `Register(event, fn)`, `Unregister(event, fn)`, `RegisterUnit(event, unit, fn)`, validation and owned-frame safe registration. Bus callbacks receive `(event, ...)` and are protected individually. The bus registers an event on its dispatcher only while a handler list exists. `RegisterUnit` creates a separate frame and returns it to the caller; its callback is invoked directly, rather than through the protected central loop.

Event validity is cached. `C_EventUtils.IsEventValid` is preferred; otherwise a probe frame attempts registration. Explicit learned-spell hints avoid registering obsolete events whose error reporting can escape a `pcall`. `RegisterLearnedSpell` combines `SPELLS_CHANGED` and client-appropriate learned-spell names.

[`Timer.lua`](../Core/Engine/Timer.lua) provides `After`, `NewTicker`, `Defer` and `HasPendingPolyfill`. It captures native timers and otherwise uses a local self-disarming wait frame; this newer implementation never assigns into `C_Timer`. The legacy [`Core/FluxAPI/Timers.lua`](../Core/FluxAPI/Timers.lua) separately exports global timer helpers and can install missing global `C_Timer` members. An addon-wide claim that timer globals are never patched would be inaccurate.

[`Ticker.lua`](../Core/Engine/Ticker.lua) runs keyed subscriptions from one shown frame. `Add(key, fn)` replaces the same key, `Remove(key)` uses swap removal, and the frame hides when the count reaches zero. `GetSubscribers` returns a copy for diagnosis. A zero shared ticker count does not account for standalone legacy frames or Blizzard-owned work.

## Tiered refresh and combat deferral

[`Scheduler.lua`](../Core/Engine/Scheduler.lua) accepts `Register(tier, listener)` and `Request(tier, token, callback, reason)`:

```mermaid
flowchart LR
    E[Events and option changes] --> Q[Request tier, tokens and reasons]
    Q --> L[layout]
    L --> D[display]
    D --> V[eval]
    V --> S[structural]
    S --> I[inventory]
    S -->|Combat lockdown| C[Flux.Combat queue]
    C -->|Regen| S
    I -->|More than eight direct callbacks| N[Next-frame continuation]
```

| Tier | Intended work | Actual scheduling contract |
|---|---|---|
| `layout` | Paging/layout fanout | Sets the paging flag; runs first. |
| `display` | Conditional faces, icons, usable/badge paint | Independent request; never implicitly becomes eval. |
| `eval` | Macro/occupancy/binding-plan evaluation | Work requested during layout remains pending and runs after display. |
| `structural` | Secure widget/attribute structure | Deferred through `Flux.Combat` when in lockdown. |
| `inventory` | Inventory-related callbacks | At most eight queued direct callbacks per flush; listeners still run for that bucket. |

Tokens and reasons are sets passed to callbacks/listeners. Repeating a token deduplicates the token, not the callback list. Ordinary buckets execute their callbacks then listeners. A request schedules a next-frame flush through `Flux.Timer.After(0)`. Work is not described as globally single-pass: feature-owned timers, listener costs, requests generated while flushing and combat deferrals still matter.

[`Combat.lua`](../Core/Engine/Combat.lua) has two queue forms:

- `Defer(key, fn)`: named last-writer-wins work, retaining first insertion order for distinct keys. Outside lockdown it attempts `Flush` immediately. A shared key cannot represent an arbitrary list of different jobs.
- `RegenDefer(fn, heavy)`: light/heavy callback lists. `PLAYER_REGEN_ENABLED` flushes named jobs, then schedules those lists for a later frame; light callbacks run before heavy callbacks. This avoids placing all scans on the regen tick.

`HasPending` and `PendingCount` describe the named queue. The list queues and feature-local flags need separate diagnosis.

## Change coalescers and display identity

| Service | Consumer-facing behavior |
|---|---|
| [`FormStorm`](../Core/Engine/FormStorm.lua) | Reads form, bonus, page, stealth and vehicle signatures. Unchanged events are ignored. `OnBurst(key, fn)` runs once next frame; `OnSettled(key, fn)` runs after 0.25 seconds quiet, with a `quiet` boolean describing whether trailing work occurred. Snapshot/burst/settle queries let consumers avoid repeated scans. |
| [`SpellBook`](../Core/Engine/SpellBook.lua) | Keyed `OnChanged` subscribers receive signature-changing spellbook events after a 0.25-second trailing debounce. It holds while FormStorm is open, checks again at 0.1 seconds, and caps holding from the first event at one second. `Sync` warms the signature without notifying. |
| [`Modifier`](../Core/Engine/Modifier.lua) | `Register(key, callback, {fallbackInterval, isActive})` and `Unregister`. Modifier events coalesce onto OnUpdate; optional active fallback intervals keep polling armed only when needed. Also exported as `FluxModifierTracker`. |
| [`Context`](../Core/Engine/Context.lua) | Fingerprints unit-frame peek, modifiers, accessible target/focus identities, mouseover reaction and combat. Subscribers receive kind flags on the display tier; unchanged fingerprints skip work. Mouseover requests coalesce, and short-lived peek polling handles transitions. |
| [`Identity`](../Core/Engine/Identity.lua) | Registers surfaces and publishes the shown `{kind, id}`. Stable signatures skip unchanged notifications. Slot and badge keys have helpers; `SoftSync` republishes current identities without requesting Binding Apply. |
| [`Range`](../Core/Engine/Range.lua) | Registered bar/extra sweeps share memoized spell/item/action probes for one sweep. Default bar interval is 0.25 seconds, extra interval 0.18; arm/disarm follows `needFn`. Mouseover events stamp a burst time instead of walking every host on each hop. |

Context, Identity and range concern what a surface currently shows. Binding documents and action-slot occupancy remain separate sources of truth. This separation lets a target/modifier change repaint a macro's face without recompiling the binding plan.

## Click-time targeting and secure helpers

[`MouseoverCast.lua`](../Core/Engine/MouseoverCast.lua) owns the click-time unit on plain action/spell/item hosts. Live/Classic use secure PreClick/PostClick wraps to pick mouseover, then target, then nil and remove stale unit attributes afterward. Macro/click overlays keep targeting in their compiled body. Legacy continuously evaluated mouseover state drivers are parked rather than rearmed.

Forever retains the legacy no-wrap policy for mouseover targeting, independently of the bar paging probe. `UsesNativeCVar` selects its native mouseover path, and `ApplyNativeCheck` stamps `checkmouseovercast` on plain types. The current `SyncCVar` deliberately does **not** write the Forever CVar: Blizzard's checkbox owns it, and `CVAR_UPDATE` synchronizes the Flux setting. On wrap clients the native CVar is kept off. Changing the Flux setting updates scoped options and the legacy character field, requests a binding recompile, invalidates range and refreshes presentation. The file's opening comments are less specific than this actual implementation.

[`Restricted.lua`](../Core/Engine/Restricted.lua) wraps Execute/WrapScript/snippets/state and unit drivers. Existing Forever callers keep an insecure, event-assisted 0.2-second fallback that does not apply structural attribute changes during combat. Bars separately use `PagingWorks`, `SetPagingSnippet`, `ExecutePaging` and captured native attribute-driver registration: a successful setup-time execution probe enables secure bar paging on repaired Forever builds while preserving v8's mouse/key input policy. A failed probe retains the OOC fallback. [`SecureClickProxy.lua`](../Core/SecureClickProxy.lua) overlays a separately parented secure click/macro button while the owner is hovered; the watcher polls hover without scripting the secure button. These are client-specific integration tools, not a way to bypass protected actions.

[`SpellBookChrome.lua`](../Core/Engine/SpellBookChrome.lua) places Mouseover Cast/rank-up controls in the modern spellbook footer or Classic title row. Rank controls are permitted for Era/TBC/Wrath and a suitable low-rank API, but excluded on Cata/Mists/live Midnight. It can restore missing Forever rank-label/CVar support; the native SettingsDropdown is retained.

## Shared button feedback

`Flux.ButtonFX` is shared by bar hosts, minirows, Extra Buttons and badges. It owns separate presentation objects so native action-button collectors do not dispatch through Flux code into later Blizzard protected buttons.

Collector ownership has a client exception: `Action.LeaveBlizzardCollector()` is true for Forever, and its nil/detach/sweep helpers return without changing native collector methods or registration tables. `WithRegistrationSuppressed(fn)` is now a pass-through despite its historical name. Forever strip widgets use `ActionButtonTemplate, SecureActionButtonTemplate`; other eligible post-DF strip widgets use `ActionBarButtonTemplate, SecureActionButtonTemplate`. [Hosts.lua](../Bars/Hosts.lua) and [EBS Widget.lua](../ExtraButtonSystem/Engine/Widget.lua) agree on that choice. Restoring a temporarily replaced native method would not erase its taint, so the new path avoids the replacement.

| Component | Responsibilities and useful entrypoints |
|---|---|
| [`Charges.lua`](../Core/ButtonFX/Charges.lua) | `Ensure`, `Apply`, `ClearCache`: primary spell/GCD swipe plus charge-recharge edge; duration-object fallback for unreadable numeric timers; accessible scalar signature skips; charge child created only when needed. It paints widget instances without replacing `CooldownFrame_Set`. |
| [`Click.lua`](../Core/ButtonFX/Click.lua) | `SyncCVars`, `MirrorTypeRelease`, `UsesWrap`, `Apply`: secure mouse/key press-release contract and `type*` to `typerelease*` mapping. Forever uses mouse-up visible hosts and hidden key-down proxies owned by bar click code. |
| [`Glow.lua`](../Core/ButtonFX/Glow.lua) | `Want`, `Set`, `Transfer`, `FaceShowsSpell`, `InstallSAO`, `Start`: proc membership from native/community sources; owned glow frames/LCG/fallback art; transfer existing animation between visible hosts instead of restarting the birth animation. Community SAO membership discovery includes guarded upvalue/environment-based compatibility paths. |
| [`Flash.lua`](../Core/ButtonFX/Flash.lua) | `WantSlot`, `WantSpell`, `WantItem`, `Set`, `Start`: auto-attack/auto-shot/wand flash. Melee state uses `PLAYER_ENTER_COMBAT`/`PLAYER_LEAVE_COMBAT`, distinct from general combat lockdown. Active flashes share a ticker. |
| [`Overlay.lua`](../Core/ButtonFX/Overlay.lua) | `Attach`, cast/channel/empower fills, reticle, interrupt/end-burst, checked/pushed chrome, live-state queries, clear/sync/transfer functions. Builds isolated child visuals and chooses native or Classic fallback animation. Resizing respects separate X squeeze and native height. |
| [`Cast.lua`](../Core/ButtonFX/Cast.lua) | `Register`, `Start`, `PickOwners`, `FollowColumn`, `AdoptFace`, `Debug`: one owned spellcast dispatcher for player/pet; resolves shown spell/rank/item/macro identity, selects matching visible owners, and transfers/adopts/clears cast presentation across row or face changes. Pet state is isolated from player state. |

The existing action-slot memo is limited to BeginSlotPass/EndSlotPass. Paint.Flush
and Effects.FlushDirty use the hoisted WithSlotPassCleanup boundary: an outward
error closes a pass begun during that invocation and rethrows the same error
object; a pre-Begin error leaves an unrelated outer pass intact. Successful
callbacks and the existing single-active-pass behavior are retained. The private
live-name native-result helper is also hoisted, with fresh native/formatter lookups
and no cross-query cache. R26 cleanup adds a small measured desktop cost; R27
removes a per-query closure. Native adoption/performance remain unverified after
the halted reload attempt. [Evidence and limits](validation/lag-hotspots-native-attribution-2026-11-14.json).


Cast event handling distinguishes success, ordinary stop/cancel, interrupt, channel and empower endings, and reticle target/clear. Delayed stop cleanup checks generations so an old callback cannot cancel a newer cast. `FollowColumn` reconciles the currently shown face with in-flight presentation. Post-DF VFX remain enabled; pre-DF follows the action-bar `spellCastVFX` option.

These files use client-specific templates, atlas checks and bundled media; visual identity and asset provenance are described in [04-visual-system.md](04-visual-system.md) and [34-assets.md](34-assets.md). `Click2.lua` exists but is not the loaded click implementation.

The Era/Anniversary [combined-bag shim](../Inventory/Builtin/FluxClassicCombinedBag.lua)
now repins only to a locally shown private host after a parent mismatch, and
returns items only while that host still owns them. Two predicates preserve
normal layouts/adoption cadence; no frame, timer, event or API was added. The
five-bag source model remains12 refresh/layout passes and640 HostFor calls.
Retail/Forever/MoP exit this owner; native acceptance remains pending. R28/R29
shortcuts remain unapplied, and R30 confirms existing provider batching rather
than adding another layer. [Decisions and scoped evidence](validation/lag-hotspots-native-attribution-2026-11-14.json).

## Legacy facade and diagnostics

`Core/FluxAPI` supplies cached spell/action wrappers, aura/unit pass-through functions, CVar guards, capability flags, timer globals, tooltip/portrait/micro helpers, talent-group helpers, Edit Mode deferral and bank-paint/transfer staging. `FluxAPI_Boot.lua` publishes exports and reprobes selected state on `PLAYER_LOGIN`. It duplicates some concepts from the newer API; callers must follow their actual contract rather than assume common ownership.

`Flux.Perf` counts passes and captures form/page, bag/drag and regen timings. `Perf.IsIdle` checks the kernel's known ticker/timer/scheduler queues; it is not a full frame-enumeration result. `Flux.HopLag` adds opt-in event/ticker/modifier tracing and the `/fluxhop`/`/fluxlag` overlay. `Other/FluxPerfDebug.lua` inspects broader drivers and `Other/FluxPerfCapture.lua` persists timed captures in `FluxPerfCaptureDB`.

Diagnostics change what is instrumented and can add polling/wrappers while active. Use the [verification procedure](41-verification.md) and exact [command reference](31-commands-and-bindings.md), especially for `/fluxperf`, whose final handler is the later-loaded diagnostic file.

The [idle performance follow-up](45-idle-performance.md) uses a native Forever baseline to guide bounded changes: the mouseover watchdog sleeps without a unit, repeated Forever fallback strings share one parse per sweep, and unit-frame health/threat samples use existing timer wrappers at unchanged deadlines. Timerless clients retain the private unit-frame OnUpdate fallback. `FluxUI_GetUnitFramePollStats` exposes active timer flags; kernel ticker counts alone do not enumerate these timer-driven samples.


Player-only specialization consumers use `Flux.Events.IsPlayerUnitEvent(unit)`.
It rejects only a public unit confirmed different from player; own aliases and
missing, unknown or restricted identity keep the historical refresh. It stores
no unit identity. Group/member-specific consumers continue handling their own
notifications. See [R70 roster review](validation/roster-transitions-2026-11-18.json).
