# Group roster performance — 8 November 2026

The user reported severe lag while inviting members. This change removes repeated
Flux work on ordinary roster notifications while retaining native membership,
visibility, group ordering, click casting and deferred protected setup.

## Changed paths

- `FluxRaidLayout`: prepared groups take one roster/layout pass. They keep their
  header attributes, child pools and party drivers instead of hiding/reconfiguring
  them. Initial setup, incomplete normal-party readiness, lost native capability and
  explicit option edits keep the full path.
- `FluxRaidUnit`: unchanged cell tokens queue the existing one-frame paint batch.
  New unit tokens still bind immediately; native state/attribute handlers stay intact.
- `FluxUnitFrames_Party`: member/pet show and roster notifications share one paint
  batch. Cast reset/resampling and range wake happen once per batch. Ready checks
  and other immediate indicators retain their event behavior.
- `FluxRaidHealerExtras`: all45pet slots and the optional friendly target retain
  prepared native drivers. Roster changes repaint without relayout/rebind; pending
  option changes still apply out of combat; a previously unavailable optional driver
  retries setup on the next roster notification.
- `FluxMouseoverKeybind`: roster discovery uses one existing0.3-second timer per
  burst and skips stable routing-data rebuilds. New/deferred frames still register;
  real Edit Mode, binding and routing edits keep their refresh path.
- `FluxUnitFrames_DebuffTint`: roster identity invalidation targets party owners;
  target/focus only need friendliness reevaluation and player auras retain UNIT_AURA.
  Known-type and display-only-dispellable checkbox semantics remain unchanged.

## Matched desktop evidence

Five alternating baseline/candidate pairs replay20same-turn notifications under
five client models. Each counter is identical across the five pairs. These model
scenarios are operation counts, not measurements of native invite latency or FPS.
The number of actual roster events emitted by a real invitation is not asserted.

| Replayed work | Before | After |
|---|---:|---:|
| Direct raid-header attribute writes per prepared roster burst |213|0|
| Full party/extra layouts per burst |1each|0|
| Header-child sync passes per burst |3|1|
| Hover frame discovery passes |60|1|
| Binding-key queries on unchanged roster |340|0|
| Binding roster timers |20|1|
| Optional extra-cell rebinds |920|0|
| Optional extra-cell protected writes |5520|0|
| Optional extra-cell paint calls |920|46|
| Raid paint calls after20syncs of40cells |800|40|
| Normal-party/pet paints after8shows plus20roster events |168|8|
| Normal-party cast resets / current-cast samples |80/84|4/4|
| Range wake checks for that normal-party burst |8|1|
| Prepared/extra cell allocations in the replay |0|0|

No new event frame, persistent OnUpdate or ticker is added. Raid painting reuses
its existing batch. Normal party and adjunct paints each have at most one pending
After callback; binding keeps its existing timer cadence. Native aura/secure
internal work is not included in these counts and still needs actual measurement.

## Coverage and boundaries

The focused fixture executes production paths with initial readiness/fallback,
prepared party/raid pools, combat deferral, deferred/new hover registration, real
secure hover programs, Edit Mode routing refresh, optional pet/target state, cast
cleanup and immediate ready checks.163checks pass. Twelve harmful mutations fail;
removing only the redundant outer combat guard remains safe through existing inner
guards and is recorded as a benign control rather than claimed as a rejection.

All35upstream cache files match exact Gethe Git blob SHA values. Fresh source
execution passes255908secure wrap/state/roster/click checks and58native member-order
checks across Retail, Forever, Classic progression, Era and Anniversary. These
execute client source under a desktop model; they do not establish the protected
VM, hardware input, secret-value behavior or actual rendering.

The complete suite passes257scripts and922Lua syntax files. Owned source hashes
match the tested manifest. All five installed copies match through user sync.
Before-source/history recovery holds98runtime files plus47read-only settings
metadata entries outside AddOns; the changed party fixture preimage is verified
against the preceding validation manifest. Older uncommitted work is preserved.
No foreground/input, WTF/profiler writes, manual sync or publication occurred.

Actual invite/join/leave/reorder latency, native CPU/memory/frame-time and pixel/
taint acceptance remain pending. The host has no connected WoW profiling tool;
no closed-client inference or profiler preference change was made. Keep WoW in
the background and use a matched build/addon/profile/scenario if native samples
are collected later.

[Machine evidence](validation/group-roster-performance-2026-11-08.json) contains
exact before/candidate hashes, all35source identities, raw matched samples,
negative controls, focused/full reports and installed-copy results. Continuity
requirement: [REQ-RF-95](RAID_HEALKIT_REWORK.md).
