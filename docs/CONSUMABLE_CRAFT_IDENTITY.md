# Stable owned grid buttons during loot and crafting

8 November 2026: an already owned combat-grid item briefly returned to its
placeholder after crafting more of the same item. The user also reported slots
hiding/showing after loot and crafting while their item count remained positive.

Two production paths reproduce with mocked native data:

- Item metadata invalidation can leave the tooltip temporarily unavailable.
  Classification returns nil without a pending entry. Potion eligibility treated
  that absence as rejection, cleared the action, then rebound it after data returned.
- A legitimate refresh for loot of another consumable kind can temporarily omit
  the original kind from selection. Auto visibility checked that selection before
  the still-positive item latch, hiding the owned slot. Spending the last craft
  material made this visible because crafting could no longer keep the slot shown.

The classifier now exposes its existing explicit negative-cache state through
IsRejected. Potion eligibility rejects that state, while unavailable data remains
unresolved. The existing KeepConsumableSlot gate validates the latched item's
bag-only count and eligibility before depending on a refreshed selector. It does
not bind a new unknown item; ordinary selection still promotes better items.

Existing Off/Always, crafting/restock clicks, First Aid on Forever, keybindings,
count painting, swap behavior, charge handling, loading holds and combat deferral
remain. A real zero still clears/hides through the existing policy; stored copies
cannot keep it visible. Known wrong-kind, utility-potion and requirement failures
remain excluded. No new events, hooks, frames, timers, polling, saved roots or
assets were introduced. Three runtime owners changed: FluxConsumableClassify,
Best/Score and Engine/ConsumableBind. The Best facade was investigated and is
byte-identical to the recovery checkpoint.

The external checkpoint Craft-grid-placeholder-20261108T090008Z covers 2,258
actual source files, 179 accessible on-disk settings and verified Git history.
Unsaved game memory is excluded. No live input, settings/profiler writes,
reload, transaction, commit or push was performed for this batch.

The regression executes the real item cache/classifier, inventory providers,
selector, craft service, grid modules and visibility gate. Five client API models
(Forever, Retail, Era, Anniversary and progression) each run builtin/Syndicator
paths for healing potion, mana potion and bandage. It observes every placeholder
call and slot transition, rather than checking only the final appearance. It
covers unavailable metadata with positive bags, another-kind loot, last-material
crafting, repeated ordinary crafting, 60 simulated quiet seconds, combat, explicit
modes, stored copies at true zero, and actual negative potion classification.

Five alternating matched pairs each produced:

| Measured desktop operation across 30 scenarios | Baseline | Candidate |
|---|---:|---:|
| Placeholder calls during positive-count transitions | 36 | 0 |
| Main action rebinds during those transitions | 20 | 0 |
| Slot visibility transitions during those transitions | 76 | 0 |
| Selector calls through the craft scenarios, including startup | 134 | 114 |
| Extra selector calls during the second quiet 30 seconds | 0 | 0 |
| Lazy fallback tooltip frames, one per isolated scenario | 30 | 30 |

Operation counts had zero run-to-run variation. Baseline fails 224 of the 620
checks; candidate passes all 620. Three negative controls reject old scoring,
old visibility and ignored negative classification. Full validation passes
253/253 scripts and 917 Lua syntax files; source hashes stayed unchanged during
the run. All 12 existing destination copies match through the user's continuous
sync. These are desktop results, not native timing, allocation, FPS, pixel or
secure/secret-VM acceptance. Host timings are retained as uncontrolled diagnostic
samples only. Exact source/test hashes, outputs and limitations are linked below.

Native acceptance is pending on every client. Connected background WoW test tools
were unavailable; background-only input rules were retained. After an ordinary
out-of-combat reload, record build, item/recipe IDs, mode/profile and addon list:

1. Keep at least one usable healing potion/bandage in bags. Loot unrelated items
   and craft more of the same item, including the final craftable batch. Observe
   every slot throughout: no placeholder, hide/show or temporary layout collapse.
2. Loot/craft a better usable tier: verify normal promotion and current bag count.
3. Remove the final carried copy with no materials left: Auto hides; bank/warband
   copies must not keep it shown. Always retains its placeholder; Off stays hidden.
4. Repeat with Syndicator/Baganator enabled and disabled, during combat gains and
   after combat, preserving normal click/binding behavior. Check BugTabs for errors.

Reproduction: `lua tests/consumable_craft_identity.lua` from the addon root.

- [Matched samples and negative controls](validation/consumable-craft-identity-comparison-2026-11-08.json)
- [Complete validation](validation/consumable-craft-identity-full-2026-11-08.json)
- [Source guard](validation/consumable-craft-identity-source-guard-2026-11-08.json)
- [Existing client copies](validation/consumable-craft-identity-client-copy-2026-11-08.json)
