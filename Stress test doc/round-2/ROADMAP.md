# Round 2 roadmap

**Historical audit roadmap.** This round originally changed documentation and
test harnesses only. The user later authorized implementation; the current
[implementation and acceptance record](../roadmap-fixes/README.md) and
[25-group status](../roadmap-fixes/finding-status.json) supersede the open status
below. Native acceptance/coverage gates remain pending in their stated scope.
The user originally requested an audit before further code edits.
Use [FINDINGS.csv](FINDINGS.csv) to filter the 25 finding groups, then read the
linked owner report before implementing one. They include conditional models,
API edges, performance candidates and dormant code; they are not 25 observed
native taint errors.

## Completed audit baseline

- [x] Capture current main, dirty state and exact source identities outside AddOns.
- [x] Resolve current Era, Anniversary, Retail live and Forever source pins.
- [x] Run the current 232-script suite and compile all 896 Lua files.
- [x] Screen all 929 classified Lua/XML sources and 599 loaded paths; no missing load references.
- [x] Review extra buttons, bars, bindings/badges and remaining domains, with qualified production replays.
- [x] Add explicit rapid Shift/Ctrl/Alt press/release, overlap, release-order and combat scenarios.
- [x] Make no audit-issued runtime, existing-test, TOC, art or settings edits; preserve and revalidate independent changes.

The source screen is not branch coverage. Native secure execution, actual secret
values, pixels, hardware input and CPU/FPS remain future validation gates.

## Batch 1 — action correctness and cancellation

| Task | Finding(s) | Feature-preserving change to prepare | Acceptance before completing |
|---|---|---|---|
| B1.1 | R2-BIND-06, R2-BIND-02 | Give distinct normalized chords distinct world/hover pool identities; parse literal minus without losing modifier meaning. Reconcile retired overrides and existing pooled frames. | Exhaust punctuation and modifier combinations, locale keys, world/hover payloads, reapply/reuse and removal. `ALT-=` and `ALT-/` must execute their distinct prepared payloads; `-` and `SHIFT--` must round-trip. Keep native key timing and saved bindings. |
| B1.2 | R2-CORE-05 | Bind pending and active equipment work to a cancellable operation identity, including regen, deferred item-lock work and later bank continuations. Keep the orchestrator's current stale-callback checks. | Cancel pending and active swaps; no later pickup/equip after cancellation. Replace A with B without letting A alter B. Do not undo already committed gear or clear another owner's cursor. Verify real native item-lock/bank timing later. |
| B1.3 | R2-CORE-04 | Carry missing requested gear into truthful completion/recovery state while retaining valid partial swaps and disabled/uncaptured section behavior. | All-missing, partial, unavailable bank, duplicates, jewelry peers, empty slots, two-hand/off-hand, already matching and later retry. Success must reflect the stated completed scope; incomplete requested gear must not silently clear recovery. |
| B1.4 | R2-BIND-01 | Give each held press a release owner, or explicitly release the old column before handing off the shared poller. | Q/E overlap with every modifier/release order, duplicate down/up, mouse/key overlap, hide/reuse and combat. Every released column returns to its correct tint/press state; retain checked/reticle behavior and avoid one new driver per key. |
| B1.5 | R2-DOM-03 | Prepare secure salvage geometry/attributes before combat; freeze or defer prohibited anchor/size/attribute changes while locked. Keep permitted visuals and prepared actions functional. | Visible→combat, hidden→combat, modifier spam, owner loss/reuse, secure driver OnShow and regen. Strict guard must see no protected writes. Native visibility/protection must be checked separately before claiming taint resolution. |

B1.1 and B1.2 can be prepared independently. B1.3 should share the equipment
completion contract with B1.2. B1.5 is a priority review gate because its current
combat denial is from a strict model, not a captured native incident.

## Batch 2 — timer and asynchronous ownership

The common `R2-TIMER` family is one mechanism across multiple owners:
R2-DOM-06, R2-EBS-05 and R2-CORE-01/02/03. `C_Timer.After` has no declared return.
Do not mechanically replace every timer: some owners need cancellation, others
only a public scheduled flag and generation, and existing guards already stop
some stale work.

| Task | Owners | Required result |
|---|---|---|
| B2.1 | Status/Info integrated layout and Details resize (R2-DOM-06) | One pending latest pass per owner; bounded border/PVP/layout/configuration work, retained combat/detached/placement checks and final settle. |
| B2.2 | Mount spell/skill refresh (R2-EBS-05) | One pending 0.3 s bag refresh per owner, preserving the capability and combat gates. Investigate the separate 0.5 s refresh path without dropping meaningful state/readiness updates. |
| B2.3 | Equipment, gear and rune hover pickers (R2-DOM-06, R2-CORE-01) | Leave, explicit hide, replacement and teardown invalidate queued show/hide work; preserve delays, alternatives, context menus and scroll padding. |
| B2.4 | Restock panel bag refresh (R2-CORE-02) | Merge valid count contexts and deliver a bounded latest refresh. Old panel work cannot revive after hide/reopen or target a replacement widget. Preserve bank-organization/provider deferrals. |
| B2.5 | Talent spec watcher and learn continuation (R2-CORE-03) | Cancelling A prevents its timeout from retiring B's watcher. B completes once after its own event; preserve top-level generation guards, learning cadence and safe cancelled-state rejection. |

Use real nil-return `After` semantics in future permanent tests. If a cancellable
object is chosen, verify its native object/method contract rather than relying
on a test-only table type. Do not introduce global timer overrides or a second
scheduler framework. Check normal, reentrant, cancellation, late completion,
combat entry, hidden owner, reuse and absent-capability controls for every owner.

## Batch 3 — context and tooltip lifetime

| Task | Finding(s) | Required result |
|---|---|---|
| B3.1 | R2-CORE-06 | Full modifier/target/focus/combat/form display requests have bounded delivery while mouseover continues. Narrow-only traffic retains its economical throttle. Preserve independent Utility/EBS/UF-hover bypasses; do not change secure click payloads to repair a display deadline. |
| B3.2 | R2-DOM-01 | Pending proxy tooltips belong to the current hovered, enabled owner and cannot reappear after leave/replacement. Remove unsafe shared capture assumptions without losing native or LibDBIcon callback behavior. Verify shared `GameTooltip.Show` provenance separately. |
| B3.3 | R2-DOM-02 | Reuse each owned proxy and install one native icon hook per original icon, with bounded rebuild scheduling. Disable/re-enable cycles cannot add permanently retained hook chains. Keep layout, clicks, provider callbacks and tooltip behavior. |

B3.1 acceptance must use an indexed mouseover-dependent program, no UF-hover
bypass and an unchanged-slot conditional bar display. Independent explicit badge
refresh tests cannot certify that the whole Context deadline is fixed.

## Batch 4 — measured work reduction

| Task | Finding(s) | Preserve while optimizing |
|---|---|---|
| B4.1 | R2-MOD-01 | First measure the actual combat host-index walk. The large out-of-combat setter count comes from a forced unsupported fallback; repaired current Forever uses secure paging. Preserve same-frame key/click correctness, pages/forms, occupancy, program edits and native attribute effects. Do not blindly debounce setters or diagnose ordinary current FPS from the fallback countermodel. |
| B4.2 | R2-DOM-05 | One metadata retry owner per vendor panel/list generation. Preserve late valid item data, list selection, spinner state, merchant reopen and full eventual rendering; hidden or replaced panels stop old retries. |
| B4.3 | R2-EBS-03, R2-EBS-02 | Reuse the existing mount collection cache with real invalidation/readiness and verify stable per-client vendor identities. Retain vendor preference, native localized names, middle click and saved mount assignments. Do not adopt an unverified dormant ID table. |
| B4.4 | R2-EBS-06 | On clients where cast VFX can be disabled, keep cheap reticle/cancel observation but avoid unnecessary owner/face scans. Retain checked/channel/cleanup behavior and the modern always-enabled policy. |

Operation counts establish what work runs. Record matched real-client timing,
allocation and FPS samples later before claiming a native performance gain.
Some work must remain immediate or visible; avoiding feature loss takes priority
over forcing a zero count. EBS hotkey coalescing is a passing control and should
retain its current one-pending-timer behavior.

## Batch 5 — conditional API safety and lower-reach contracts

| Task | Finding(s) | Gate |
|---|---|---|
| B5.1 | R2-BIND-04 | Guard nil/secret vertex colors before arithmetic; use public owned presentation state where available. Native icon/aspect reach is unconfirmed. Preserve readable tint and other painters; do not invent an unknown color. |
| B5.2 | R2-DOM-04 | Guard frame-level arithmetic at the caller and reconcile public owned level facts. First verify affected native aspect provenance. Include all level writers, parent raises/restores, initial construction, reuse and native layering before accepting a cache. |
| B5.3 | R2-EBS-04 | Separate desired cooldown cache from successfully applied state, retrying only on normal owner paints. The current failure is injected; preserve duration/numeric/charge readiness and avoid a new retry poller. |
| B5.4 | R2-BIND-03 | Reentrant supersession must settle each accepted callback exactly once and keep the latest owner. Ordinary automatic UI reach is not established; retain direct API and pipeline controls. |
| B5.5 | R2-BIND-05 | Define safe direct combat-clear semantics while preserving current caller guards. A public API edge is reproduced; do not present it as an ordinary current Binding taint incident. |
| B5.6 | R2-EBS-01 | Keep the dormant typo separate from live macro execution. Establish a live owner before porting behavior; any eventual legacy cleanup must preserve licenses and client packaging. |

## Batch 6 — acceptance and remaining coverage

- [ ] Promote each authorized fix's focused reproduction into a meaningful
  permanent regression using native-like API return/permission contracts.
- [ ] Keep readable-state parity controls, unknown/secret/nil cases, queued
  cancellation, hidden/reuse and callback ownership. Reject the original defect
  for the expected reason; a green reproducer can intentionally confirm a bug.
- [ ] Re-run the full suite, syntax, TOC/load and documentation validation with
  exact before/after source identities and no source drift.
- [ ] Re-run all three modifier layers: core bus, actual bar/binding consumers
  and actual EBS/utility/badge consumers. Their counts are separate scenarios,
  not one additive end-to-end benchmark.
- [ ] Extend unreferenced/indirect source and optional integration branches from
  the [module matrix](MODULE_MATRIX.csv). Lexical references are not branch coverage.
- [ ] When native testing is chosen, verify each requested client/build in combat
  and out, world/dungeon/raid, real key/click behavior, render parity, native taint
  logs and matched CPU/FPS. Preserve settings/profiler preferences and background
  PC use. No such native test is authorized or performed by this audit.
- [ ] Recheck the previous USER-001 Forever `FrameUtil/startAlpha` report after
  the prior fixes are loaded. Its actual owner/first taint cause and recurrence
  remain unknown; these new findings do not establish its attribution.

Each future implementation batch needs an external source/history checkpoint,
current settings availability, exact source identities and a regression plan.
Keep the repository on main and preserve newer work. Guild-bank and void-storage
callbacks remain excluded. No settings reset, feature removal, native API
replacement or broad error concealment is proposed.
