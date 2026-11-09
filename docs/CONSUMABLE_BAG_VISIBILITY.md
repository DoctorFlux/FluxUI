# Grid bag counts and craft visibility

8 November 2026: the user clarified that healing-potion/bandage buttons were
remaining visible with no carried items and no currently affordable craft.
Forever healing-potion crafting must use First Aid. The earlier report about
missing items is retained as a separate metadata-notification finding.

| Requirement | Result |
|---|---|
| Auto uses carried items or a currently affordable cached recipe | Shared craft timer now refreshes visibility alongside the existing right-click action. |
| Stored items/materials do not count as carried | Existing bag-only scope is retained; reliable live reagent counts supersede delayed positive snapshots. |
| Syndicator can publish later | Existing native bag notification invalidates its craft cache and schedules the same bounded refresh, including empty output slots. |
| Forever healing potions use First Aid | Existing First Aid skill-line routing is retained and checked against stale Alchemy rows. Bandages and other client profession routes remain. |
| Metadata readiness reaches both grids | Preserve pending classification before invalidation and pass it to the existing selector callback. |
| Existing options and secure behavior | Off avoids native craft refresh work; Always retains placeholders. Protected action/visibility changes defer through existing combat handling. |

The primary reproduced failure used a provider snapshot with four reagents while
native bags had one or zero and the recipe needed two. Crafting used the larger
snapshot count, and an empty output slot did not receive the native craft
refresh. Auto could therefore retain a craft-only button that the client could
not use. The candidate reads the shared live bag count when reliable, invalidates
the old craftability cache on the existing native notification, and refreshes
visibility in the existing 0.10-second coalescer (0.30-second burst limit).
Other callbacks can mask the visibility omission after a regular provider pulse;
that is not a direct native reproduction or a guarantee about every stale icon.

The secondary defect lost the pending-classification flag when metadata cache
invalidation ran before selector notification. A later poll or bag event could
mask it. The flag now survives that handoff; no new polling service is added.

Four runtime owners changed: Inventory/Craft.lua, Inventory/FluxItemClass.lua,
Inventory/FluxConsumableBest/Scan.lua and Engine/ConsumableBind.lua. Existing
inventory snapshots, provider ownership, recipe selection, restock quantities,
settings/profiles, bindings, artwork, count/latch rules and secure restrictions
remain. No new frame, event subscription, permanent hook, ticker or saved root
was added. The shared native bag observer and craft timer are reused.

The external checkpoint Consumable-bag-detection-20261108T071724Z covers 2,248
actual source files, 179 accessible on-disk settings and verified all-ref history.
Unsaved game memory is excluded; no settings/profiler or game input was changed.
Exact baseline/candidate/test hashes, source pins, raw repeated samples and
negative controls are in the comparison record. Host timing is diagnostic:
user PC load is uncontrolled, and these workloads do different valid work.
They do not certify native CPU, memory, frame time, latency, rendering or FPS.

Validation: 1,030 metadata/bag checks and 439 craft/visibility checks across
five client models with builtin and Syndicator paths. The actual potion,
bandage and mana-potion modules and visibility policy are exercised. Off/Auto/
Always, both potion profession routes, better-tier promotion, bank/warband/mail/
auction-only copies, count-only materials, delayed publication, duplicate events
and combat deferral are covered. Final full-suite/copy results are recorded below.

Final full validation:251/251 scripts and915 Lua syntax files PASS; source
hashes unchanged throughout. Five alternating pairs per component reject the
baseline(100metadata/45craft assertions) and pass all1,469candidate checks;
six faulty mutations reject. Existing zero-reset375 and consumable1475 checks
also pass. All16 existing client file copies match through user continuous sync;
three read passes, no manual copy/second overwrite. Native candidate checks
remain pending; no new game input, settings/profiler writes, commit or push.
After that completed full/doc run, independent unit-frame files changed.
The four consumable owners and both tests remain at their tested hashes; those
later edits and current global generated freshness require their own validation.
No later whole-addon pass is inferred. See the recorded post-run drift list.

Native acceptance remains pending on all clients. Forever process/path/window
was observed read-only; no candidate-load or native operation result is inferred.
Connected Witchcraft/UIForever/computer-use tools were absent. Background-only
input rules remain; no casts, crafting, transactions, reload or focus changes
were automated.

After a normal out-of-combat reload, use Auto mode and test a learned recipe:

1. With no output item and insufficient carried materials, confirm the slot hides.
2. Add enough carried materials; confirm the craft-only slot and correct recipe.
   On Forever the healing-potion route must be First Aid, not Alchemy.
3. Reduce a reagent below the recipe cost while keeping the same item ID in bags;
   confirm Auto hides. Put the remaining materials in bank/warband and repeat.
4. Carry one output item without materials; confirm it shows and counts only that
   carried stack. Move the stack out of bags; confirm it hides outside combat.
5. Repeat with Syndicator enabled/disabled, recipe/profession changes, bag gains,
   better tiers and a loading screen. Confirm active combat writes defer to regen.
6. Check explicit Always/Off and existing crafting/restock clicks. Record build,
   item/recipe IDs, addon list, new errors and observed timing before acceptance.

- [Matched comparisons](validation/consumable-bag-detection-comparison-2026-11-08.json)
- [Full validation](validation/consumable-bag-detection-full-2026-11-08.json)

- [Verified client file copies](validation/consumable-bag-detection-client-copy-2026-11-08.json)
