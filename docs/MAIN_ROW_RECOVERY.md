# Main-row action routing recovery

22 November. The shared slot model and secure handler now prevent the
confirmed page-2 overlap. Columns 1–7 retain their base slots, columns
8–12 use 20–24 and fixed 13–19 keep their own slots. The five client
models verify the corrected routes. Native verification and the earlier
report of unexpected contents in correctly routed slots remain open.
[Current validation](CLIENT_VALIDATION.md#action-strip-page-two-ownership).

## 15 November recovery commands

The 15 November request was to restore main buttons 1-19, especially fixed 13-19, on Forever,
and checking the other clients against the existing docs. Connected borders
remain cancelled. The current candidate adds explicit recovery/audit commands;
it does not run them automatically or choose replacement player spells.

## Documented contract

The sources of intent are [Action bars](11-action-bars.md),
[the supplied specification](../new%20docs/docs/specs/11-action-bars.md) and
[default keys](05-defaults-and-bindings.md).

| Requirement | Normal page 1 main row | Other states | Status |
|---|---|---|---|
| MR-01: nineteen main columns | Actions1-19 | First 12 follow current page/form/control | Offline native-calculator model PASS |
| MR-02: fixed extra seven | Columns13-19 use13-19 | No ordinary/form/control page offset | Offline five-family model PASS |
| MR-03: correct key/mouse route | Key and native mouse calculation agree | SHIFT native61-72/static49-55; CTRL native25-36/static37-43; control pages preserve native main | Offline model PASS |
| MR-04: preserve contents/preferences | No PlaceAction/PickupAction or raw binding save/reset | Existing slot programs and binding profile owner retained | Offline negative guards PASS |
| MR-05: operator-only recovery | Existing State/Layout/Clicks/Paint services | Out of combat; neutral modifiers; complete 19-button/header preflight | Implemented;native execution deferred |
| MR-06: acceptance | Expected actions visible/cast on all 19 | Native input/taint/controller/client differences | PENDING;user cannot test in game yet |

Blizzard's native CalculateAction and modified-attribute helpers have identical
normalized function bodies at the five pinned Retail/Forever/Classic/Era/Anniversary
source commits. The installed five routing-source sets also matched before this
candidate. Frame GetID remains 0 so explicit action attributes own routing; it is
not the displayed column number.

## Evidence and implementation

The user initially supplied a page 2 dump: dynamic column 6 and static column 18
both used 18. Page1 restored the first issue, but later 13-19 remained reported
wrong. The 18/19 dumps show correct top-level action 18/19 and ID0, which do not
prove native click/key resolution or correct player-stored spell contents.

The offline regression reproduces a hidden mismatch: a more specific action1
or *action1 can make the native mouse calculator return 6 while action=18 looks
correct. A hidden key proxy can also shadow its parent's action. This is a
reproduced recovery case, not confirmation of the live session's root cause.

[Bars/Init.lua](../Bars/Init.lua) adds two explicit commands:

- `/fluxbars restore` preflights all nineteen main widgets/headers; reattaches through
  State.Attach; clears obsolete mouse-specific action selectors; restores inherited
  proxy routing and ID0; invalidates occupancy/key signatures; uses the existing
  mapping/state/key owners; reindexes display slots; notifies the binding profile owner; repaints the main row.
- `/fluxbars audit` reads all nineteen expected/host/attribute/native-click/proxy
  slots, effective key routes, action IDs/names and shown/native icon IDs. It is
  read-only and guards combat, held modifiers, private values and denied getters.

The recovery retains the active page and normal program/promotion rules. It
preserves stored action contents, macros and raw bindings. It cannot recreate
unknown original spell placements from a source-code backup. No speculative
replacement action list or automatic page reset is introduced.

## Secure-paging review

15 November secure-paging recovery review: `/fluxbars restore` now calls the
existing slot indexer after secure force-apply. When the native action attribute
was already correct, its unchanged value did not fire the index callback, leaving
a stale display/tooltip slot behind. The archived command fails that case; the
current command passes 9,448 checks across five client families and fallback plus
secure-header paths. Driver/attribute transport is modeled; native casting and
taint remain unverified. Seven routing owners match the pre-connection ZIP byte
for byte and all 35 installed copies after newline normalization. The user still
cannot test in game; live recovery remains open.

## Validation and installation

The recovery model executes actual Init/State/Layout/Hosts/Clicks code and native
slot-calculator methods with modeled widget transport. It corrupts metadata,
parents, mouse-specific slots, key-proxy slots, cached occupancy and override
routes, then checks all 19 and page/modifier transitions across five families.
9,448 functional checks across fallback and secure-header paths PASS; protected-write assertions also remain active.
The read-only audit has 700 checks. Six harmful recovery mutations are rejected;
seven focused scripts including 25,920 existing Forever control-model checks PASS.
Full offline validation: 399 scripts and 1,087 Lua syntax files PASS.

Only Bars/Init.lua was copied to the verified active Forever addon, after hash
checks and an external source backup. Other installed clients were inspected
read-only. No native command, foreground/input, settings/profiler or saved-action
write was performed. Both commands require the new Lua source to be loaded.
In-game testing is explicitly deferred at the user's request; the goal remains
open. The second unavailable-native acceptance audit is recorded in the validation
JSON. Required future checks include actual mouse/key casting for 1-19, modifiers,
forms/control entry/exit, conditional bindings, controller and secure/taint behavior.
[Exact identities and reports](validation/main-row-recovery-2026-11-15.json).
