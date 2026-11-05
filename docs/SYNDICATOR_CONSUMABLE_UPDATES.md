# Syndicator consumable update batching — 5 November 2026

## Failure and intended behavior

With external Syndicator enabled, several `BagCacheUpdate` callbacks can land
before one scheduled Flux inventory publication. The adapter accumulated item
diffs but replaced the change classification and dirty-bag list each time.
A newly acquired better consumable followed by an unrelated count update thus
looked count-only. Removal of the last consumable followed by an unrelated
nonconsumable acquisition lost the removed consumable ID. The real best-item
listener can reject both notifications and leave selection stale.

Food, water, healing potions, mana potions and bandages should receive every
relevant acquisition/removal from the batch, along with current counts. Flux
now merges the bag classification through its existing `MergeChangeKind` helper
and unions dirty bags while the existing bag item-set log is pending. Taking
the item sets ends that batch; the next update replaces rather than inherits
its classification. Public last-change getters remain readable afterward.

Only `Inventory/Syndicator/Adapter.lua` changes at runtime. The fix uses the
existing scheduler, selector, button consumers and secure combat deferral.
It adds no frames, events, polling, timers or settings. Ordinary nonempty
count changes still avoid selector scans. Prepared combat actions and
load-screen reliability rules retain their existing behavior; a pending
protected identity change still waits until allowed.

## Source, reference and recovery

Baseline: `223e95024727ad2935a52bba3f0ddc6a4cfef7eb`. Exact candidate hashes,
raw baseline/candidate runs and reference hashes are in the
[comparison](validation/syndicator-consumable-comparison-2026-11-05.json).
The user-supplied Forever Syndicator installation is version **289**, license
**All Rights Reserved**. Its API and bag-cache dispatch were inspected read-only;
no companion code, assets, settings or localization were copied or changed.
The adapter's personal-bank behavior and the excluded auction/guild-bank/
void callbacks were not changed or exercised by this regression.

Verified external checkpoint `Syndicator-grid-20261105T062052Z` contains
1,421 actual source files, complete Git history and 133 available on-disk
Flux/Syndicator/config settings files outside AddOns. Source archive SHA-256:
`3a714094ffece5114b31fb768acf757dc58e139b72b35fde86470b575295143d`.
The starting worktree was clean. No client input, sync changes, profiler
changes or settings reset occurred.

## Verification and performance limits

The [source-driven regression](../tests/syndicator_consumable_updates.lua)
loads the production adapter, inventory context/fan-out and real best-item
listener. Provider caches, frames and timer delivery are mocked; the final
selector recompute is counted rather than replacing its production callback
with a second ranking implementation. All five requested kinds run under
Retail, Forever, Era, Anniversary and Mists flag models.

Five alternating matched fresh-process pairs each run 400 assertions. Baseline
fails 200; candidate passes all 400. Tests cover acquisition, last-use removal,
full/incremental cache changes, current zero/nonzero counts, public metadata,
foreign characters and resetting batch metadata. A 200-callback burst owes one
selection scan and retains the final count, with no added subscriptions or
retained timers. Three mutations (dropped identities, dirty bags or removals)
are rejected. Ordinary nonempty stack changes still request zero scans.

Full [desktop validation](validation/syndicator-consumable-updates-2026-11-05.json)
passes **123 scripts /778 Lua syntax files**, including existing bar/button,
provider-readiness and load-hold regressions. No WoW process or connected native
client tool was available. Native builds, addon/settings snapshots, screenshots,
allocation/CPU, operation latency and frame-time samples are unavailable for
this change. Recorded subprocess wall times include fixture startup/assertion
cost and do not establish addon CPU, native response latency or FPS gains.
Native performance/visual/taint acceptance remains pending.

## In-game regression steps

1. Reload with Syndicator enabled. Record client build, UI scale/profile,
   companion version and addon list; preserve existing profiler preferences.
2. For each of food, water, healing potion, mana potion and bandage, carry a
   lower tier, acquire a usable higher tier and loot/move unrelated items in
   the same burst. Check the icon/action promotes after the normal queued
   update, counts agree with bags, and supported modifier swap faces agree.
3. Use/remove the last preferred item while acquiring/moving another item.
   Check count zero and the next valid tier, conjure action or placeholder
   according to the feature's existing settings. Reacquire and repeat.
4. Repeat stack splits/merges, vendor/mail/bank transfers and several fast
   updates; verify ordinary count changes do not change the selected item.
5. Repeat during combat and after a teleport/reload: count display may refresh
   while protected action changes wait for combat exit; load-screen item
   retention should still recover. Check keys, clicks and taint errors.
6. Repeat a matched case without Syndicator and on each supported client.
   Use equal scenes/profile/resolution for screenshot comparisons. Capture
   repeated matched baseline/candidate runs before making performance claims.
