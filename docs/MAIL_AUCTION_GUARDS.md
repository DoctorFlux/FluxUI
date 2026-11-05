# Mail and auction duplicate metadata safeguards

5 November follow-up: hidden Baganator pools passed `IsShown` under hidden
parents and still received protection/classification/shield work. Shared visible
traversal now filters effective visibility, with tagged skin discovery and bounded
post-layout reveal refresh. The separate default-bag path also avoids closed-frame
Updates. [Evidence, scope and pending mailbox/AH acceptance](HIDDEN_INVENTORY_WORK.md).
The reported live pauses remain unconfirmed as resolved.

## Snapshot change checks

Follow-up: the user still reports mailbox open/close and auction buying/selling
lag on Forever with Baganator and Syndicator. There remains no native capture,
so no claim is made that prior or current changes resolve that live pause.

The Syndicator adapter generated and sorted index/item/count fingerprint strings
on every mail refresh. Auction callbacks unconditionally rebuilt all listing
records/count maps, bumped generation and published, even if canonical facts were
unchanged. The adapter now compares normalized index/itemID/count/link records
against the actual published snapshot. Equal lists return without allocating
fingerprints or replacing records/maps, and equal auction callbacks do not publish.
Actual changes retain the same snapshot builder; auction changes publish directly
and mail keeps its existing0.2s debounce/0.6s cap. Empty lists, sparse indices,
legacy record aliases and normalized IDs/counts remain supported. No native API,
provider callback, sale/purchase operation or third-party addon code was replaced.
No new state table, frame, event, hook, polling or timer was added.

Intentional bug correction: the old mail fingerprint omitted item links, so a
link-only metadata completion could leave the published link stale until a later
quantity/item change. Link differences now rebuild/publish on the existing mail
cadence. The regression explicitly checks that failure and expected update.

Baseline1138fbcc02506fc63cb19c0191ec89fcf5b27e77; verified external recovery
Mail-auction-snapshots-20261105T112252Z preserves1,459 actual files, verified Git
history and123 on-disk settings outside AddOns. Source ZIP SHA256:
`fe86e9ff57864e5fe486a5ea3b7c707c4e88131a83fec18011c1a636bdcfadd5`.
[Exact hash, raw pairs and mutations](validation/syndicator-lists-comparison-2026-11-05.json).
[Full report/source manifest](validation/syndicator-lists-2026-11-05.json).
[Production adapter regression](../tests/syndicator_list_snapshots.lua).

Five alternating fresh-process desktop pairs: five client labels,1,000 mail and
1,000 listing records,100 unchanged checks/callbacks per model after one initial
publication. Baseline25 failures versus candidate0 of80 checks. Across the stable
burst,500 fingerprint sorts and500,000 temporary index strings become0;500,000
auction row replacements,500 count-map replacements and500 FluxUI pulses become0.
These are synthetic sizes/event volumes, not observed user-session data or native
allocations/latency. Three mutants are rejected: ignoring links, ignoring removals,
and unconditional auction publication. Purchase delivery, sold quantity removal,
zero counts, sparse indices, empty data, foreign callbacks and debounce controls
pass. Existing provider-handoff and combined builtin/Syndicator tests pass;
full131 scripts/786 Lua syntax files pass.

The comparison is linear and allocation-free for unchanged snapshots; a changed
list may incur an additional linear comparison before the existing rebuild,
particularly when its first difference is late in iteration. This is a tradeoff,
not a measured native speedup for every changed transaction. Source operations
are cache reads, not additional game API scans. Native CPU/allocation/frame-time,
changed-transaction latency and actual provider event volume are unmeasured.
Wall samples include test startup/controls and are not native operation latency.
Guild-bank and void callbacks remain unchanged. The installed addon versions were
last verified as Baganator840/Syndicator289 and Forever executable1.60.1.70790;
active runtime GetBuildInfo/settings/hardware remain uncaptured.

After sync and /reload, native acceptance remains the four distinct scenarios:
mail opening, mail closing, AH buying and own-auction sales. Verify new/removed
items, quantities, delayed item links, delivery, tooltips and existing mail features
with both integrations enabled. Match baseline/candidate scene/profile/addons and
warm-up/capture durations before interpreting CPU/frame time. If the large pauses
remain, obtain native attribution, including external-addon work; do not keep
assuming unchanged FluxUI snapshots are the sole cause. No foreground/input,
mail take, auction purchase, profiler preference or optional feature was changed
by these tools. The user previously could not run the requested capture.

The user confirms Forever with Baganator and Syndicator: lag on mailbox opening,
closing, buying at AH and when buyers purchase the user's listings. They cannot
run the requested capture and explicitly asked for other safeguards. No connected
native tool is available. The reported live spikes remain unattributed; this batch
fixes a reproduced duplicate-work path rather than claiming complete lag removal.

## Verified failure and change

FluxUI's classifier already rejects unrelated global metadata. However, resolved
owned items still ran the full completion path on every duplicate: both native
metadata events and FluxInv can deliver the same result. Each delivery invalidates
junk/selector consumers. The real Baganator junk bridge cancels/recreates its
refresh timer on each visual notification. Its final refresh was already debounced;
the reproduced cost is redundant notifications, invalidations and timer churn,
not thousands of native Baganator layouts or an observed FPS loss.

The existing pending-load table now distinguishes requested (true) from completed
(false) item data. Automatic completions for resolved records return early only
when static metadata is not pending, no restore/parser retry exists and any restore
record is ready. RequestLoad rearms the item; first completion, explicit public
OnItemDataLoaded calls, failed-load recovery, incomplete bandages and parser retry
without a fresh load keep their existing behavior. Both event names still work.
No native API, inventory provider, mailbox/auction action, setting, timing of actual
state changes or UI is replaced. No new frame, event, timer, hook, polling or table
is added. Completion markers retain one boolean per resolved owned info-cache key
for the same session lifetime; this small bookkeeping cost is not a memory-leak
or native allocation acceptance claim. Foreign item IDs do not acquire markers.

Read-only audit also found EquipmentSetSection already guards unchanged layouts
and Baganator's junk API refresh is already debounced. Those paths were retained.
Mail and auction snapshot callbacks, seller-listing storage and third-party addon
code were not changed. Guild-bank and void-storage callbacks remain excluded.

## Recovery and evidence

Baseline e88adf0303d5daab1c2b2c233d74b23a6bd2c961. External recovery
Mail-auction-guards-20261105T110829Z preserves1,455 actual files, verified Git
history and123 available on-disk settings outside AddOns. Source ZIP SHA256:
`e8cff67ff2b2a0ad0f6f7d05a99a67dc25a7e6d651883387daab33e055bcef56`.
Unsaved in-memory game settings are not included. No preferences/profiling changed.

[Raw pairs, candidate hash, mutations and desktop environment](validation/metadata-idempotence-comparison-2026-11-05.json).
[Full validation and source manifest](validation/metadata-idempotence-2026-11-05.json).
[Regression fixture](../tests/item_metadata_idempotence.lua).

Five alternating fresh-process pairs use the real classifier and FluxUI Baganator
junk bridge, with native metadata/timers mocked. Five client labels, each with and
without that bridge: one warmed owned item,100 repetitions of each of two native
events through two delivery routes. The stable burst is measured separately from
first completion. Across these synthetic scenarios baseline4,000 junk callbacks,
8,000 selector invalidations,2,000 timer creations and2,000 cancellations become0.
These are not observed native Buy/mail event volumes. Counts are identical in all
five pairs. Baseline65 failures of140 checks; candidate0. Three mutants fail:
lost rearm, skipped incomplete/parser retry, and suppressed explicit completion.
The earlier230-check metadata regression and complete130-script/785-Lua suite pass.

Installed executable metadata freshly read: Forever1.60.1.70790; installed TOCs:
Baganator840 and Syndicator289. Exact active GetBuildInfo, complete enabled-addon
list, graphics/profile/hardware and native CPU/allocation/frame-time/latency are
uncaptured. Desktop host/runtime are in the comparison. There is one warm-up
completion; wall times include startup and assertions and are not game latency.
Native provider integration, pixels, taint, FPS and improvement remain pending.
No external addon files/code/assets were edited or copied.

## Pending native validation

Reload after synced files arrive. When testing is possible, record exact client,
settings, addon list, hardware and source identities. Retain Baganator+Syndicator;
check idle mailbox, opening, closing without taking items, collecting mail, buying
one/many auctions, and receiving sold-auction notifications as distinct scenarios.
Use the existing optional `/fluxperf capture 20` then `/fluxperf last`, at least five
matched alternating baseline/candidate runs after30s warm-up. Preserve diagnostic
roots and profiler preferences; enabling CPU profiling is optional and must be
accounted for/restored. Do not sum inclusive overlaps or infer FPS from addon CPU.

Verify current item counts, better-item selection, depleted food/water/potions/
bandages, junk icons, delayed metadata and explicit refresh, mail open-all/select,
contacts/attachments and buyer/seller delivery tracking. Check addon errors/taint,
combat/recovery, timings and matched screenshots. No automatic purchase, mail take,
foreground/input/clipboard operation or feature disabling occurred in this session.
If spikes persist, obtain attribution before changing provider or mail/auction
behavior; the supplied reports alone do not establish the remaining cause.

## Progressive owned-list refresh — 5 November 2026

Syndicator289 publishes each appended owned-auction row. FluxUI now rebuilds the
final available list once through its existing inventory scheduler function,
before listeners. The selected native owned-list event also handles empty final
lists. Ten 500-row desktop models: rebuilds5,000 to10, record writes1,252,500 to5,000;
publications remain10. Five pairs and meaningful regressions pass.

This improves the external-provider full-refresh path only. The current failing
Forever runtime was confirmed Syndicator-unloaded in game; a single sale callback
is linear. Built-in mail/auction scans already debounce and yield; the existing
1,732-check lag smoke test passes. No live lag cause or cure is established.
[Full protocol, reference comparison, native reload and limits](RAID_MAIL_AUCTION_FOLLOWUP.md).
