# Round 2 — remaining addon domains

This round found **six new finding groups**. No addon source, existing tests,
TOC, settings, profiler preferences or game input was changed. All new files
are confined to this folder. Prior stress fixes and the newer minimap/utility
work are the baseline, not findings to count again.

The baseline is main `1fd463f4de4bbff659f4e402c6f31138c49765b4`, including the
existing dirty minimap clock/calendar change. [The root snapshot](../baseline.json)
preserves the exact source identities externally. Every one of this review's
304 domain Lua files matches that snapshot; all consumed before/after hashes
also match. [results.json](results.json) contains raw output, source hashes,
contracts and five repeated runs. Five probes total **143 assertions per run,
715 across five repetitions**, all passing their stated observations/controls.
An observation asserting that an existing path fails is not a repaired test.

These probes execute actual production owner functions; the salvage probe loads
the complete module using the existing strict fixture. Synthetic frames, timer
queues and explicit opaque tables are not WoW's native secure/secret-value VM.
**Native errors observed:0.** Work counts are desktop operation counts, not
FPS, memory bytes or measured client CPU. The root's separate fresh232-script /
896-Lua passing baseline is in [existing-suite.json](../existing-suite.json).

## New findings

### R2-DOM-01 — proxy tooltip callbacks outlive hover ownership

**Reproduced asynchronous ownership bug; native presentation/taint pending.**
`MicroMenu/FluxMinimapToMicro.lua:1302` creates delayed positioning work;
the standard-handler capture at1365/1389 also waits for a frame. OnLeave at1559
hides the tooltip without invalidating those callbacks. Enter→leave→callback
therefore shows a tooltip for the departed proxy. Both the LibDBIcon and standard
handler paths reproduce this using the complete real create/rebuild functions.

The standard path also temporarily assigns a wrapper to shared
`GameTooltip.Show`; the ordinary callback restores the saved reference. This
audit proves that assignment, not native taint or its connection to USER-001.
Other owners can use the tooltip during this interval, so future work needs an
ownership-safe capture design as well as stale-callback cancellation.

Future fix: retain a hover operation identity and check it before every delayed
tooltip mutation. Invalidate it on leave/hide/disable/rebind. Reuse bounded owned
work instead of creating a frame per delayed hover. Prefer broker tooltip APIs;
verify standard-handler capture alternatives against real third-party handlers
before claiming that removing the shared wrapper preserves every integration.

Acceptance: rapid A→B→none, leave before capture/position, hidden or rebound
proxies, synchronous/asynchronous third-party handlers, and no old operation
hiding a newer tooltip. Preserve all lines/colors, anchors and click forwarding.

### R2-DOM-02 — minimap conversion cycles accumulate hooks/resources

**Reproduced work/resource growth; client memory/CPU unmeasured.**
Disabled proxies are removed from the global lookup at
`MicroMenu/FluxMinimapToMicro.lua:1094`. Re-enabling creates another proxy at1168
and installs another pair of non-removable icon hooks at1272/1280. Each callback
looks up the current proxy, so all old callbacks paint the newest proxy.

500 enable/disable cycles plus a final enable produce501 proxy creation requests
and1002 icon hooks. A single original icon SetTexture invokes501 current-proxy
update entries. The unchanged-enabled control reuses its proxy over500 further
rebuilds. The whole sequence also requests1501 one-shot rebuild frames. These
are resource requests and callback counts, not estimated memory usage.

Future fix: privately retain/reuse proxies by original button identity while
removing their discovery aliases when disabled. Install one hook per original
icon and dispatch only to its current enabled proxy. Coalesce rebuild work on
one owned frame. This needs explicit original-button replacement handling.

Acceptance:10000 conversion/reorder cycles with bounded proxy/hook counts and
one update per icon change; preserve disabled discovery exclusion, account/
character settings, order, tooltips, icon updates and original click behavior.

### R2-DOM-03 — visible salvage overlay keeps protected anchor work in combat

**Conditional protected-write denial reproduced in the existing strict mock;
native combat visibility/denial has not been observed. Priority: review first.**
The secure overlay arms its update at
`Salvage/FluxSalvage_Overlay.lua:419`. Every0.03s it calls
`AnchorOverlayToOwner` at453. That function reaches protected ClearAllPoints
at200 without a combat guard. The modifier event also calls it at841.

The new scenario uses the unchanged strict full-module fixture: arm a real bag
slot action out of combat, keep the overlay shown, then enter combat. Each of
1000 update ticks attempts the protected mutation; the modifier event does too.
This occurs in all five policy fixtures. Hidden-in-combat, visible out-of-combat
and postcombat hide/driver cleanup controls pass. The existing permanent test
starts its combat scenario with the overlay hidden, leaving this transition
untested. The actual client's overlay visibility and protection provenance
during combat remain necessary native checks.

Future fix: prevent every insecure protected geometry/attribute mutation while
locked. On clients with suitable native secure drivers, prepare combat visibility
before combat. On compatibility fallbacks, skip protected anchor refresh while
locked and coalesce legal postcombat reconciliation. Do not conceal repeated
blocked calls inside pcall or add another polling recovery driver.

Acceptance: visible-before-combat, modifier release/repress, native secure
show/hide, gear locks, owner changes, and zero insecure protected writes. Resume
one reconciliation after combat; retain action payloads, colors, geometry and
hidden idle behavior on every actual client capability path.

### R2-DOM-04 — remaining FrameLevel getters enter Lua arithmetic

**Conditional secret-value contract risk, not a native error attributed here.**
`UF.UpdatePortraitCombatTint` at
`UnitFrames/FluxUnitFrames_Shared.lua:5391/5396` adds offsets to native outer,
root or portrait levels. Private threat raising at7369 uses native border/root
levels at7375/7377 before adding glow/text offsets. The guarded
`SetFrameLevelIfChanged` cannot protect arithmetic already performed by callers.

Complete production consumers hit five explicit opaque arithmetic traps across
those distinct branches. Public controls retain the normal border/glow/text
ordering, and the already guarded setter itself performs zero opaque operations.
The modern/Forever generated GetFrameLevel declaration permits a secret return
for its FrameLevel aspect; this audit has **not** established that these actual
Flux frames acquire that aspect. Classic opaque levels are not asserted.

Future fix: record intended public levels at actual owned constructors and parent
writers, then derive the existing offsets. Extend the existing narrow ledger
where ownership is established; guard getters before arithmetic. Do not invent
zero levels, change foreign renderers, or assume every level getter is secret.

Acceptance: public/missing/inaccessible values,40→70 parent changes, normal/combat
portrait tint, private threat start/stop/raise and label priority; preserve exact
layering and native child propagation. Confirm native aspect reachability before
calling this a client error.

### R2-DOM-05 — concurrent vendor metadata retries multiply full refreshes

**Reproduced work amplification; native cost unmeasured.**
The Junk panel's SetSubTab/QueryItems at
`Inventory/Restock/Junk/FluxVendorJunkPanel.lua:404/422` and Restock panel's
OnTabSelected/QueryItems at
`Inventory/Restock/Vendor/FluxVendorRestockPanel.lua:922/869` each start another
0.2s retry when metadata is unavailable. No pending-owner flag merges chains.

For either panel,1/50/250 entrypoint calls retain1/50/250 independent callbacks.
Six query passes then produce6/300/1500 list-refresh and metadata-request entries.
This models a valid listed item whose data has not arrived; it does not require
an invalid item ID. Hidden-panel guards stop work, and completion drains all
chains. The issue is amplification while the panel is visible, not hidden work.

Future fix: one pending metadata retry per panel plus identity invalidation on
hide/tab/list replacement. Reuse data-completion events and bounded retry/backoff
where needed, retaining recovery for late metadata and all saved entries.

Acceptance: repeated tab/edit/drop/query calls, unavailable/cached/late data,
removal/re-addition, merchant reopen and provider transitions. Bound requests
independently of trigger count while preserving selection, spinner and complete
eventual rendering.

### R2-DOM-06 — four owners treat native After as a cancellable/pending token

**Reproduced API-contract misuse with distinct owner effects.**

| Owner | Source | Production observation with native no-return After |
|---|---|---|
| Status integrated notifications | `StatusBars/FluxStatusBar.lua:2516` |1000 requests queue1000 callbacks and3000 border/PVP dependency entries. |
| Info integrated cooldown | `StatusBars/FluxInfoFrame.lua:4760` | After the immediate first layout,1000 requests queue1000 layout entries. |
| Details size debounce | `Battlezonemap/FluxDetails.lua:1394` |1000 resize events produce1000 grid passes and1000 configure passes despite one installed hook. |
| Equip flyout show/hide | `Other/FluxEquipSlotFlyout.lua:284/509` | Enter→leave at20ms still invokes Show for the departed anchor at60ms.1000 rapid enters invoke1000 pending Show targets. |

The generated C_Timer.After contract has no return value. Assigning its result
leaves the pending/cancellation fields nil, so guards and cancellation do not
work. The Show target was counted at its production caller boundary; this probe
does not certify native flyout presentation. Details detach and layout combat
guards remain effective controls. Core's timer compatibility file preserves the
native function when it exists, so an addon shim does not provide a handle on
these four clients.

Future fix: use existing NewTimer handles or an independent pending boolean and
operation generation with After. Preserve the immediate first pass, combat/
placement/embed gates and existing0.32/0.2/0.05/0.06/0.25s cadence. A stale callback
must not clear a replacement operation's token. Test cancel/replace, nested
requests, force refresh, placement changes, detach/re-embed and hover A→B→none.

Fresh primary contracts for all four target pins are in
[timer-contracts.json](../timer-contracts.json). This is one underlying finding
group with four active owners, not four independent native error reports.

## Coverage and limits

[module-coverage.csv](module-coverage.csv) maps every domain to the actual bounded
paths checked; [coverage.json](coverage.json) lists each file/hash, TOC client
gates and lexical hints. The counts below are **not execution percentages**.

| Domain | Lua files triaged | TOC reachable | Bounded manual file reviews |
|---|---:|---:|---:|
| UnitFrames |38|38|3|
| RaidFrame |13|12|2|
| NamePlates |7|6|1|
| Inventory |98|83|7|
| Mail |9|9|6|
| Salvage |16|16|1|
| Minimap |7|5|2|
| MicroMenu |15|13|2|
| Battlezonemap |16|14|5|
| CharacterInfo |27|24|3|
| Other |40|18|5|
| StatusBars |6|6|4|
| BaganatorCompat |12|12|3|

The lexical scan covers driver/timer/hook/getter/protected-writer hints in304
files;44 files received the bounded function reviews named in the matrix.
Confirmed active findings require TOC ownership and actual production probes.
For example, the old `Inventory/FluxInv/FluxInv_Events.lua` queue can overwrite
contexts, but it is not TOC reachable; the live LegacyBridge routes to the
already fixed Inventory service. It is not reported as an active new defect.
The old `Other/FluxCharacterStats` dump is likewise not a live owner.

Bounded checks also inspected mail worker/action generations and watchdogs,
provider readiness, raid visible-work ticker cancellation, finite map startup
watchers, nameplate prior write guards, the minimap clock/calendar lifecycle,
and Baganator NewTimer cancellation controls. No new defect was established in
those specific paths. This statement does not certify their whole domains.
Guild-bank and void-storage callbacks remain excluded.

The root freshly verified current Gethe source pins/versions in
[upstream-pins.json](../upstream-pins.json): Live12.1.5.70783,
Forever1.60.1.70862, Era1.15.9.70576 and Anniversary2.5.6.70577. Native
GetFrameLevel's aspect contract and protected ClearAllPoints declaration are
checked against exact local blobs at the pinned Forever commit:
[GetFrameLevel](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_APIDocumentationGenerated/SimpleFrameAPIDocumentation.lua#L421),
[ClearAllPoints](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_APIDocumentationGenerated/SimpleScriptRegionResizingAPIDocumentation.lua#L22).
Their annotations support the conditional scenarios, not a claim that the user
encountered those values or native denials.

The micro proxy and most timer owners have no client-specific branch. Four
labels on an identical branch do not emulate four game engines. Salvage's five
policy models include the additional progression compatibility fixture. No
probe reproduces native combat/dungeon/raid security, real secret primitive
semantics, third-party UI pixels or live CPU/FPS. Those remain separate native
acceptance work; none of these findings identifies USER-001's first taint writer.

Run the read-only evidence again with:

```powershell
python 'Stress test doc/round-2/remaining-domains/run_audit.py'
```

[findings.json](findings.json) supplies per-finding priorities, exact sources,
evidence, feature-preserving options and acceptance requirements for the unified
future roadmap. No proposed fix has been applied in this round.
