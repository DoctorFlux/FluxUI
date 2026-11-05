# Mail and auction duplicate metadata safeguards

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
