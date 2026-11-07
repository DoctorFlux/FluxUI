# Security, protected operations and combat ownership audit

**New user error:** [USER-001: Forever secret fade alpha](USER-001-FADE.md) records
the user's two native `FrameUtil.lua:427` errors separately from the simulated
SEC findings. The exact OUT sink is source-pinned; actual frame/action/combat and
taint origin remain unknown. Conditional fragment tests reach the same sink from
both cast and swing suppliers. No production fix or native agent test was made.

Date: 7 November 2026. Scope: documentation and standalone desktop Lua only. No
addon code, existing test, settings, native client, profiler preference, or
foreground input was changed by this audit. The harness has a `.lua.txt` suffix
so it does not enlarge the existing runner's `*.lua` corpus.

The experiments execute the actual `Restricted.lua`, `Combat.lua`,
`FluxRespec_ActionBars.lua` and `FluxRespec_Apply.lua` modules. Frames, action
slots, cursor APIs, combat state and native functions are mocks. The findings
below are reproducible control-flow/API ownership defects, **not native taint
errors**. No screenshot, FPS, secure hardware dispatch, true secret value or
instance restriction is simulated accurately enough to certify those properties.

Run from the repository root:

```powershell
python 'Stress test doc/security/run_security.py'
```

[Raw repeated evidence](security_results.json) records five independent processes,
raw stdout, desktop elapsed time, Lua version, and source hashes before/after.
Every sample executes 121 assertions and reproduces 21 observations across three
finding groups. A successful harness run means the observations reproduced;
**it does not mean security passed**. All five requested-client/extra-progression
models are covered where the implementation branch applies.

## SEC-01: Forever driver shims intercept other addons' native APIs

**Priority: high integration/security risk; reproduced API interference.**

Production locations: `Core/Capabilities.lua:112`,
`Core/Engine/Restricted.lua:142`, `:334`, `:344`, `:393`, `:400`, `:430`.

Forever sets `Cap.hasRestrictedClosures=false`. `Restricted.lua` then replaces
seven global Blizzard entry points: register/unregister attribute driver,
register/unregister state driver, register/unregister unit watch and unit-watch
registered query. The replacements accept Flux-named frames only, rather than
forwarding foreign frame operations to the captured original APIs. Original
attribute-driver functions are retained for the separate paging probe, but that
does not make the global adapter transparent.

The production module was loaded with original APIs and native-call counters.
The public registration functions from the [pinned Forever source](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_RestrictedAddOnEnvironment/SecureStateDriver.lua)
were also executed before the Flux adapter: these three requests made five native
manager attribute calls. Their local body matches the refreshed source blob
`4861b5fd4a3249c97f1a2fea45a4c13833d5117c`, verified by the root audit; this is
source execution with a mocked manager, not the native secure VM.

After loading the Flux adapter, state-driver and unit-watch requests on `OtherAddonSecureButton`, plus
a state-driver request on an unnamed frame, all returned `false`: three rejected
requests and zero original calls. The same requests use their untouched original
APIs in the Retail/Era/Anniversary/progression control models.

This is an existing deliberate workaround for historical Forever restricted
execution problems, not a newly introduced change. The current source comment
explains why Flux avoids writing the native driver manager; that useful
restriction must be retained. The demonstrated problem is its global reach.
Blizzard or optional addons calling these globals after Flux loads can lose
their driver/watch behavior. Which real integrations do so, and whether the
global assignments propagate taint into a blocked native path, require native
loading/provenance evidence; neither is claimed here.

**Future fix without losing features:** inventory all owned callers and route
them through the existing addon-local `Flux.Restricted` adapter. Preserve the
repaired paging probe and fallback visibility behavior. Remove the global
replacement only after owned callers have migrated, and validate foreign native
calls against the pinned current Forever source and client. Merely wrapping a
native function in a new addon global still changes provenance; do not treat a
`pcall` or automatic forwarding as taint certification.

**Regression:** Flux named/unnamed ownership, foreign named/unnamed protected
frames, native manager identity, callers loaded before/after Flux, paging probe
success/failure, combat visibility and target/pet despawn, optional Clicked/Clique
and native compact frames. Retain each client's different restriction contract.

## SEC-02: Respec can report successful completion after failed/deferred bars

**Priority: high correctness/recovery defect; reproduced with production owners.**

Production locations: `Respec/FluxRespec_Apply.lua:106`, `:724`, `:742`, `:744`,
`:751`, `:867`; `Respec/FluxRespec_ActionBars.lua:506`, `:526`, `:535`, `:565`.

`StepBars` calls the action owner through `pcall`, discards the success/error and
return values, then advances the pipeline. The action owner also ignores failed
`PlaceAction` and per-slot calls. Its combat path returns `false` while retaining
a future restore, but the orchestrator still reaches `FinishSuccess`, emits
`APPLY_DONE(true)` and clears the load checkpoint.

Experiments loaded both entire production modules and used a mismatching saved
profile. An injected stance setter error reached this false-success outcome in
all five models. Injected spell-pickup failure, action-placement failure, and
combat deferral reached it in Era, Anniversary and the extra progression model.
Those Classic failures left zero completed placements while the pipeline still
reported success. The stance error can happen after a Classic slot placement;
the report does not claim rollback of already committed changes.

The injected API denial is a controlled failure signal, not a discovered native
taint error. The missing result propagation is confirmed regardless of the
original error's cause. Retail/Forever native action-slot restore is skipped by
the selected capability model; their relevant reproduced case is stance failure.

**Future fix without losing features:** give the existing action owner a clear
completion/failure/deferred contract, propagate failed slot operations, wait for
deferred completion before advancing, and retain the bars checkpoint on failure.
Use the existing Respec callback/generation conventions already used for spell
bindings. Preserve profile sections, stance order, custom entries, all saved
roots and existing explicit user actions. Do not suppress the underlying error
or claim that a successful `pcall` means the requested slot was restored.

**Regression:** synchronous success, failure return, thrown setter, pickup denial,
placement denial, partial success, combat defer/reentry, missing API, disabled or
uncaptured bars, Retail/Forever stance-only path, checkpoint recovery, and exactly
one correctly valued `APPLY_DONE` notification.

## SEC-03: queued Classic action restore outlives cancellation and mutable data

**Priority: high correctness/ownership defect; reproduced with production owners.**

Production locations: `Respec/FluxRespec_ActionBars.lua:532`, `:541`, `:547`, `:552`;
`Respec/FluxRespec_Apply.lua:115`, `:177`.

The action owner's module-local `pendingSnap` stores the input snapshot by
reference. Its independent regen watcher has no connection to the Respec
operation's cancellation/generation. A completed bars-only pipeline still has
future protected work waiting; mutating the profile entry from spell 133 to 116
changes what is later applied at regen. Calling Cancel after false completion
cannot remove that detached work.

A stronger separate scenario keeps the actual pipeline running by also deferring
spell bindings. Calling the production `Apply.Cancel` settles the running
operation as cancelled and cancels its binding callback. The detached action
owner nevertheless writes spell 133 to slot 1 on regen. Both cases reproduce in
Era, Anniversary and progression. No protected action was attempted by the mock
while its combat flag was set.

**Future fix without losing features:** detach the queued snapshot and attach
the existing operation generation/cancellation owner to pending bar work. Cancel
only that owner's pending operation, settle its callback once and unregister an
idle watcher. Recheck lockdown when the callback executes; retain the most recent
explicit request and preserve already committed talent/gear changes. Avoid a new
global queue/framework.

**Regression:** cancel while bindings/bars wait; profile edit after queueing;
replacement A→B, profile deletion, repeated regen, combat reentry, empty slots,
stance-only snapshots, cancellation callback reentrancy and no stale writes.

## Combat burst result and future optimization

Production locations: `Core/Engine/Combat.lua:34`, `:81`, `:120`, `:136`.

Per client model, each sample submits 100,000 same-key `Defer` requests, 10,000
distinct named jobs and 10,000 light/heavy `RegenDefer` jobs: 120,000 requests per
model, 600,000 per sample, 3,000,000 across five samples. Same-key requests retain
one pending owner and execute only the latest callback. Entering combat halfway
through a distinct-job flush retains exactly the remaining 5,000 jobs; subsequent
flush completes them once. This part passed its stated mock invariants.

`RegenDefer` schedules one next-frame drain, but that drain executes all 10,000
distinct callbacks in the same simulated frame. This is a **burst-risk candidate**,
not a measured live workload or FPS result. The interface deliberately supports
multiple functions, so blindly replacing it with one same-key callback would
discard required work.

For later optimization, identify actual producers and duplicate ownership first.
Coalesce only callbacks proved equivalent; if native samples show a spike, drain
distinct expensive jobs under a measured per-frame budget while preserving
ordering, combat reentry, cancellation, deferred completion and final features.
Store matched native traces before deciding a budget. Desktop elapsed times in
the JSON measure the full synthetic process, not client frame time or addon CPU.

## Native taint evidence still required

Static inspection also covered the owned click proxy, native mouse suppression,
binding apply guard, hover registration and snippets, utility manager combat
queue and Respec protected ownership. Existing production guards and wrapper-only
native frame rules are evidence of intended design, not proof that every caller
is safe. Native taint remains **NOT RUN** for every requested client and context.

| Boundary | Desktop evidence | Native acceptance that remains open |
|---|---|---|
| Native globals/state/unit watch | SEC-01 proves interference under Forever capability policy | Actual globals' provenance, manager calls, optional addon load order, protected operations |
| Binding and utility secure hosts | Existing focused suites and input-agent stress execute prepared snippets/dispatch with mocks | Hardware click edges, true secure VM, protected frame propagation and every client build |
| Native mouse suppression/Edit Mode | Production ownership suite verifies mock deferral/script owners | Native callback provenance, real compact frame restrictions and combat/Edit Mode transitions |
| SecureClickProxy | Source checks OOC mutation guards and separate polling owner | Native click target ownership, secret geometry, combat entry/exit and panel open/close |
| Nameplate native region writes | Performance audit counts repeated work | Region protection, forbidden access, real secret values and native blocked/forbidden errors |
| Respec action/cancel recovery | SEC-02/03 prove result/cancellation defects | Native API denial reason, slots/stance parity and combat transition execution |

World, dungeon and raid restrictions cannot be established by naming a desktop
loop "dungeon" or "raid". Native checks are intentionally deferred by the user's
simulation-only instruction. When new user error text arrives, retain the exact
stack and client/build, map it to these boundaries, add a separate reproducer and
continue the remaining suite. Do not treat silence in historical logs as proof
that no new taint can occur.

## Expanded remaining-surface audit

The follow-up read-only sweep covers Mail, CharacterInfo, Other, WindowMover,
Minimap, NamePlates, Inventory, BaganatorCompat, Salvage and AddonOptions, plus the
initial binding/secure/core owners. [Module triage](module_triage.csv) inventories
663 non-test/non-temporary Lua files, of which 575 are reachable through the
current TOC/XML graph, including conditional entries. Of these, 62 files have
manual review of named ownership/writer boundaries. The rest have lexical
screening only. **A lexical screen, a test reference, and TOC reachability are
not a full behavioral review or a security pass.** The exact per-file limits,
hashes, loading conditions, token line locations and test associations are
retained rather than describing every file as fully tested.

Rebuild that reproducible inventory with:

```powershell
python 'Stress test doc/security/build_triage.py'
```

The [summary](module_triage_summary.json) reports subsystem counts. Scanning
includes strings and comments, so a token's presence alone is not an active
unsafe call. TOC/XML reachability does not resolve every runtime client/capability
condition. Library and unreferenced source files remain distinguishable from
reachable code. Guild-bank and void-storage callbacks remain outside the
requested audit scope under AGENTS.md; a lexical occurrence does not mean those
callbacks were reviewed or exercised.

| Surface | Actual boundary inspected | Evidence and practical limit |
|---|---|---|
| Mail | `Mail/Select.lua:117` job generations and cancellable/noncancellable wakes; `:173` native pending-command gate; `:198` mailbox close/current-owner checks; `QuickAttach.lua:8` OOC/cursor/bound/locked gates | Extended production lifecycle stress below; native mail permission and callback provenance pending |
| Character panels | `PaperDollSecondaryName.lua:308` Forever post-open service; `PaperDollEquipFlyout.lua:152` combat gate; `TacoTip.lua:40`, `ItemLevel.lua:283`, `PaperDollQuality.lua:151` native hooks; client-gated stat panels | Existing native writer exemptions are retained; full stat calculations and actual taint not certified |
| Other widgets and diagnostics | `FluxDurationBars.lua:64` native function replacement; `FluxEquipSlotFlyout.lua:318` owned click dispatch into guarded candidates; `FluxInputDebug.lua:6` value guard; `FluxPerfCapture.lua:548` release/stop owner | Existing mirror/order and diagnostics tests cover their stated desktop scope only; diagnostics stayed off |
| Window mover | `Engine.lua:177` permission check, `:295` deferred Apply, `:729` hook exemptions, `:816` attach, `:910` enabled scan gate | Existing disabled/combat/layout suite; late native panel/chrome protection and real callback provenance pending |
| Minimap/tracker | `FluxMinimap.lua:393` wheel handler and `:629` OOC indicator layout; `FluxObjectiveTrackerScroll.lua:1138` conditional native wrapper and `:1160` update hooks; `FluxBuffDebuffFrames.lua:11` combat/Edit Mode guard | Mail lifecycle and tracker fixtures establish local ownership/order only; true native secret/restriction behavior pending |
| Nameplates | `Core.lua:670` Forever native plate styling, `:783` active update hook; `Countdown.lua:166` access gates and copy-label parent/layout | Repeated work quantified by performance audit; real native regions, secrets and combat restrictions pending |
| Inventory/equip | `FluxEquipSlotCandidates.lua:478` OOC equip/unequip, `FluxItemMover.lua:2037` action owner and `:3425` runner, `Restock/FluxRestock_Inv.lua:555` lock-aware adapters | Existing single-action/lock/quantity/pacing tests; not every 3500-line mover transition or native operation permission proved |
| Vendor/bank | `FluxVendorBuy.lua:1153` bounded merchant/identity/wallet buy pass; `FluxBankRestock.lua:2193` close cleanup; `FluxBankRestockButton.lua:845` authoritative native lifecycle | Existing footer/close/reopen/identity fixtures; historical unresolved native bank reproduction remains unresolved by these desktop runs |
| Baganator | `Loader.lua:17` optional initialization/retry; `FluxBaganator_ItemViews.lua:28` deferred reveal; `GearSetContext.lua:76` instance override; `CategoryIcons.lua:163` scoped width wrapper | Third-party instance behavior and ownership inspected; current external runtime integration remains native-only |
| Salvage | `FluxSalvage_Overlay.lua:68` deferred queue, `:414` callback ownership, `:680` OOC tooltip gate, `:776` modifier gate; `FluxSalvage_Tooltip.lua:154` carried-bag/forbidden guard | Extended production strict-mutation lifecycle stress below; actual secure template/driver/native click remains pending |
| Options | `FluxOptionsShell.lua:726` guarded escape binding/regen restoration; `FluxOptionsActionBars_Bindings.lua:29` combat disabling and delayed recheck; `FluxOptionsRender.lua:342` own confirmation dialog | Own pooled rows and bindings reviewed; full interactive options tree, all setter consumers and native popup taint remain pending |

No additional native taint error was established in this expansion. Concrete
source boundaries needing native verification are listed in
[native review queue](native_review_queue.csv). These are **review items**, not
eight additional confirmed errors. For example, a custom `StaticPopupDialogs`
entry is not by itself evidence of a taint failure, and a native function wrapper
cannot be certified safe merely because an ordinary Lua fixture preserves its
return value. Each queue item records how a later fix can preserve current
features if native evidence confirms a failure.

## Extended Mail and Salvage lifecycle stress

Run:

```powershell
python 'Stress test doc/security/run_surface_lifecycle.py'
```

[Raw evidence](surface_lifecycle_results.json) contains three independent runs,
each with 100,000 explicit assertions, 20,000 mail close/reopen cycles and 5,000
Salvage OOC/combat/regen cycles. Across three runs that is 300,000 assertions,
60,000 mail cycles and 15,000 Salvage cycles. Consumed production/test/harness
hashes remained identical before and after.

The mail extension reuses the existing real Settings/Select/OpenAll fixtures,
exercising both `C_Timer.After` and `NewTimer`, OpenAll and Select owners, and
five existing client labels. Every cycle opens a fresh inbox state, starts one
native action, closes the mailbox, injects the stale money acknowledgement and
advances twenty simulated seconds past old deadlines. No additional action
occurs after close, no active wake remains, and controls are reused. The client
labels share this API fixture; they do not add absent server/client behavior.

The Salvage extension loads the complete real overlay under the established
strict-mutation fixture for five client models. Each cycle prepares an owned
bag-slot action OOC, hides it and disarms the update, enters modeled combat,
rejects tooltip/modifier arming, queues one ordinary deferred callback, then
replays regen both while locked and after unlock. The callback runs once after
unlock, controls are reused, and no permanent update remains. The model's traps
cover only the protected operations implemented by that fixture. Native taint,
hardware salvage execution, real item consumption, FPS and secure templates
remain untested.
