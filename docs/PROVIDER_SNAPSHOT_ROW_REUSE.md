# Provider mail/auction snapshot row reuse — 5 November 2026

The [progressive-operation audit](PURCHASE_GROWTH_AUDIT.md) found repeated
normalized-record allocation in FluxUI's provider adapter. Every changed full
mail or owned-auction list cleared its index and constructed all rows again.
Five hundred separately settled purchases accumulating 500 real mail facts
constructed 125,250 normalized records. Callback, frame and timer counts stayed
stable; this was repeated work over legitimate facts, not a demonstrated leak or
the cause of the native freeze. The user also reports freezes without Syndicator.

Only the shared private FillFromList function changes. Changed mail/auction lists
now prepare a fresh index/count map, reusing the previous normalized row at the
same index when item ID, quantity and link match exactly. Changed rows receive
fresh records. The completed maps replace the previous maps together, followed
by the existing generation increment. Previous records/maps are never modified.
The region object stays stable. An unchanged list still returns before map
preparation through the existing ListMatchesSnapshot guard.

This uses the previously audited internal map ownership: mail/auction maps are
read on demand by Index and are not exposed by GetSnapshot or cached by current
consumers. There is no new public service, retained historical index, append-only
fast path, event, timer, poller or global API replacement. Existing synchronous
RebuildMail/RebuildAuctions return values, callback filters, readiness ownership,
auction scheduler tier and mail debounce/notifications remain unchanged.

Sparse positions, reordered lists, removals, duplicate IDs, zero quantities,
legacy count/link aliases and invalid IDs retain the original normalization and
count semantics. Only ID/count/link determine equality, as before; icon, quality,
expiration and auction ID alone do not add publications. Provider records and
saved settings stay provider-owned. Guild-bank and void-storage callbacks are
unchanged. Installed Syndicator is read-only and not part of this patch.

## Source and recovery

Baseline main: `7f47a566e573a132dcac4a0e67f8b590cee8d08a`.
Baseline Adapter.lua SHA256:
`d242e0c07e789197335bde1d0deb27586c41b6fad24560add6846452408df561`.
Candidate Adapter.lua SHA256:
`670b74340e9e82f4498529e597db00941c8c3f8a8fa71ea7f4857c2ad636976f`.
Regression SHA256:
`f996be6d3ef7fcde6650cd4d4da219ec059f4811f89762796eca62777e4fb62a`.

Before editing, the verified external Mail-auction-publication-20261105T183839Z
checkpoint preserved 1,520 actual source files, 122 available on-disk settings and
all-ref history, including unrelated in-progress consumable changes. Source ZIP
SHA256:
`b3a39827bbd2e50cc271fce7c5930ea80b1174e3215bc42105b380d36523f55f`.
Its source-extracted provider-row-reuse-baseline.lua and raw baseline/candidate
stdout remain outside AddOns/Git. Unrelated consumable files/tests were preserved.

## Regression and measured scope

```powershell
lua tests/provider_snapshot_row_reuse.lua
lua tests/provider_snapshot_row_reuse.lua '<checkpoint>/provider-row-reuse-baseline.lua'
lua tests/auction_refresh_batching.lua
lua tests/deferred_inventory_handoff.lua
lua Inventory/_tmp_inventorylag_smoke.lua
```

The focused regression loads the real Adapter and Scheduler. A Lua debug line
hook meters the actual normalized-record constructor site; isolated source-map
iteration and wipe wrappers meter row visits/clears. It uses mocked provider data,
native events, timers and Store, with one diagnostic scheduler listener. This
does not count every Lua instruction, table allocation, byte or native cost.
Provider/native timing and the complete addon listener fanout are outside scope.

| Separately settled append operations, each region | Baseline constructed rows | Candidate constructed rows | Source row visits, both |
| --- | ---: | ---: | ---: |
| 10 | 55 | 10 | 110 |
| 100 | 5,050 | 100 | 10,100 |
| 500 | 125,250 | 500 | 250,500 |

These curves are measured independently for mail and owned auctions. At operation
500, constructor count for that operation falls from 500 to 1. Unchanged refreshes
preserve maps/generation and construct no normalized rows in both versions.
The original one-publication-per-settled-operation behavior remains.

| Cancellation scenario | Baseline constructed rows | Candidate constructed rows |
| --- | ---: | ---: |
| 10 listings, remove first each time and append returned mail | 100 | 55 |
| 100 listings, same index-shifting control | 10,000 | 5,050 |
| 500 listings, same index-shifting control | 250,000 | 125,250 |
| 500 listings, remove last each time and append returned mail | 250,000 | 500 |

Removing the first listing shifts every following index, so those auction rows
cannot reuse their former per-index record. Accumulated mail rows still reuse
correctly. The stable-index control additionally reuses the remaining auction
rows. That control clears 250,000 old map entries in the baseline and zero in the
candidate. It retains all 500 returned items and removes every owned listing.
The change does not reorder provider facts to manufacture reuse.

Regression-first execution against the exact baseline fails 190 of 700 checks;
the candidate passes all 700. Coverage includes prior-generation coherence during
source reads, immutable shared rows, exact sparse/zero/link/reorder/removal counts,
metadata equality, current-character changes, foreign callbacks, separate mail
and auction cadence, coalesced bursts, direct synchronous rebuilds and absent,
pending, Ready and duplicate-Ready provider states. Five client labels and both
bag-addon presence labels exercise the same production adapter with legacy/modern
auction-event routing; these labels are not native-client or real Baganator tests.
Existing batching passes 365 checks, deferred handoff 210 and inventory smoke
1,732. Five alternating fresh-process pairs and five rejected mutations are in
the [raw comparison](validation/provider-snapshot-row-reuse-comparison-2026-11-05.json).
The [full report](validation/provider-snapshot-row-reuse-2026-11-05.json) passes
151 scripts / 806 syntax files. Its source-drift guard verifies that every Lua
file and file-set member stayed unchanged throughout the run.

## Limits and native checks

The existing full-list equality validation and reconciliation still visit O(N)
facts. Recorded source-row visits do not decrease. Every changed generation now
temporarily holds a second index map; its count map was already newly allocated
in the baseline. This trades temporary map storage for reuse of unchanged record
tables and avoids clearing the old index. No total allocation-byte, retained-byte,
overall CPU, FPS or native freeze-removal claim follows from these counts.

Native transaction acceptance remains pending: Buy-to-mail arrival with the
mailbox closed/open; sale/cancel removal and returned-mail counts; individual,
bulk and final-mail collection; repeated visits and current-character changes;
profiles, tooltips and bag UI under supported clients with/without the external
provider and bag addon. This patch affects only the provider-ready adapter and
cannot fix a standalone path that does not use it. Native frame time, memory/leak
behavior, secure execution, taint and pixel parity remain separate checks under
[the flow record](MAIL_AUCTION_REWORK.md). No game input, profiler change, settings
reset or external-addon modification was used for this batch.
