# Auction item-data fan-out

The user reports a large pause immediately at auction Buy, especially Retail and
Forever, and requires every supported client with builtin inventory or Syndicator.
This batch fixes a reproduced source of unnecessary work in the global metadata
path. Attribution of the user's actual pause remains pending native capture.

## Failure and intended behavior

`GET_ITEM_INFO_RECEIVED` and `ITEM_DATA_LOAD_RESULT` are global item-cache events,
not proof that bags or bank changed. FluxInv sent every successful completion to
`Spells.OnVisibleItemsChanged`, which harvested every carried/banked item name,
even with no unresolved reagent. The classifier's own event frame and FluxInv also
sent unrelated IDs to its full completion method. That populated permanent session
info records and notified junk/consumable consumers for unrelated auction items.
The source inspection establishes these costs; it does not establish the event
volume or timing of a specific native purchase.

The candidate has two narrow ownership changes:

- Global classification events reconcile existing records and this service's
  pending requests only. Explicit `OnItemDataLoaded` callers retain the full API.
  Pending requests survive failed loads until a successful metadata result; failed
  events do not invalidate ready records. Completed requests leave the pending set.
- The spell metadata lane resolves the arriving item's name only when spell
  tooltip names are pending. A matching reagent updates reagent ownership and
  finalizes the active restock set immediately, without a container harvest.
  Actual bag/bank/merchant changes retain `OnVisibleItemsChanged` and its harvest.

No feature, option, default, saved root, summon/use action, macro, integration,
layout or update cadence was removed. No secure attributes/global APIs were
replaced. There is one service-owned pending-request table and no new frame,
event, hook, timer, polling loop or external dependency. Existing duplicate routes
for relevant IDs remain; this batch does not defer their notifications.

## Recovery, identities and desktop evidence

Baseline: `6d4ceba90badc5f8ca4e11c4ac464621e61e36b1` on clean main.
External `Auction-metadata-20261105T081044Z` preserves 1,436 actual files,
verified Git history and 123 available on-disk settings files, outside AddOns.
Source ZIP SHA256:
`14845360ffeac1299fe8fd07aabb91f4d11c1fc026ed092b8a24d9c6a6a206b3`.
No private settings were committed and no profiler preference was changed.

[Raw pairs, mutations, host/runtime and normalized candidate hashes](validation/auction-metadata-comparison-2026-11-05.json).
[Complete validation report and source manifest](validation/auction-metadata-2026-11-05.json).
[Regression command/source](../tests/auction_metadata_work.lua).

Five alternating fresh-process baseline/candidate pairs load the real classifier,
spell resolver and event router. Native APIs and provider state are mocked. Each
of five client labels and two provider labels delivers both global events for 50
unrelated successful item IDs, with 80 carried and 200 bank IDs. The scenario is
synthetic; it is not an observed Buy event volume. Across those ten combinations:

| Operation/resource count | Baseline | Candidate |
| --- | ---: | ---: |
| Item-name reads | 280,000 | 0 |
| Bag/bank collection walks | 2,000 | 0 |
| Full-info builds | 500 | 0 |
| Unsolicited retained info records | 500 | 0 |
| Junk notifications | 2,000 | 0 |
| Broad consumable invalidations | 4,000 | 0 |

Every pair has identical operation counts: zero variation. Baseline fails 90 of
230 checks; candidate passes all 230. Requested metadata, retry after failure,
static-only consumers, explicit completion, name-only reagent completion, warm
active-restock finalization and actual container-change harvesting pass. Era and
Anniversary models also exercise the legacy item-name fallback. Three mutations
are rejected: bypassing the classifier guard, dropping requested completions and
dropping reagent completions. Full suite: 127 scripts and 782 Lua syntax files
pass. No native client/provider integration is certified by labels or mocks.

Lua 5.4.6 desktop host, zero warm-up, one scenario per fresh process. Raw wall
times include startup and assertions and are not game operation latency. Native
CPU, allocation, frame time, FPS, secure behavior, taint, screenshots and leak
acceptance remain unavailable. Avoided retained records demonstrate narrower
cache ownership; they do not prove absence of all memory leaks. Modern/original
Wrath and Cata receive no new native compatibility promise.

## Native acceptance and next investigation

No visible WoW process or connected game runtime tool was available in this
session. No foreground, keyboard, mouse or clipboard control was taken. Reload
each running synced client to load the candidate. Preserve all diagnostic roots
and profiler preferences before captures, then restore them afterwards.

Use the matched scenarios in [auction capture steps](AUCTION_PURCHASE_REFRESH.md#native-checks-still-needed):
Retail and Forever first, then Era, Anniversary and MoP; builtin, Syndicator and
Syndicator+Baganator separately where installed. Record exact GetBuildInfo, hardware,
profile/settings, addon list and source identity. Warm up 30 seconds; at least five
alternating baseline/candidate captures each for idle AH, one Buy and repeated Buy.
Use `/fluxperf capture 20` and `/fluxperf last`; existing optional CPU rankings
include `FluxItemClass` and `FluxInv.Spells` methods. Capture metadata event counts
and timestamps rather than assuming the synthetic volume occurs in game.

Check food/water/potions/bandages on new/better items and depletion, delayed spell
reagent metadata and max-rank migration, junk overlays/counts, actual bag/bank
changes and both metadata events including failed/retried loads. Match screenshots
and interaction timing; check secure actions/errors/taint and delivery counts.
Nothing is accepted as native pass yet. If the pause persists, attribute the
remaining Buy-time gold/status refresh, mail publication and native/external AH
work separately. Guild-bank and void-storage callbacks remain excluded.
