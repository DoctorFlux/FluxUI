# Auction row tooltip readiness — 5 November 2026

The built-in Retail AlreadyKnown painter assumed every tooltip query returned a
table with lines. A missing result raised an error on each auction-row update
and could leave a recycled row showing its previous known-item tint. This is a
reproduced error amplification defect; it has not been identified as the cause
of the user's continuing whole-game freezes on Forever.

The painter now treats missing data or lines as an unresolved item and uses the
existing uncollected appearance. It does not cache that answer. A later normal
row update can immediately detect a known item once its tooltip is available.
Ready tooltips, positive caching, known-item tint/monochrome settings, row
traversal and all options retain their existing behavior. No timer, callback,
native request, settings change or replacement API is added.

## Source contract and client scope

The task's pinned Retail 12.1.5.70783 generated
[GetHyperlink contract](https://github.com/Gethe/wow-ui-source/blob/297d7aaaa736f346b3e036f38ee088eaf7f8c07f/Interface/AddOns/Blizzard_APIDocumentationGenerated/TooltipInfoDocumentation.lua#L337)
declares `MayReturnNothing = true`. Its non-nil return-field declaration applies
when a result is returned. The missing-result fixture therefore exercises an
allowed API outcome. A table without lines is an additional defensive readiness
case, not a claim that the generated schema promises that partial structure.

The edited implementation is gated to `mainline` in the existing manifest.
The Classic implementation is unchanged. No native Forever file-selection or
execution evidence was obtained in this batch. Testing the same painter with
and without a provider object establishes that this UI correction does not
depend on that object; it does not certify the native Syndicator integration,
other client loaders or the unresolved Forever freeze.

## Recovery and source identities

Baseline main: `c1a5f901467ff5015938442c74580d6d4781cbaa`.
The verified external `Mail-auction-publication-20261105T192602Z` checkpoint
preserves 1,527 actual files, 122 accessible on-disk settings and all-ref Git
history. Archive integrity and bundle verification passed. Source ZIP SHA256:
`b4280b64c5734002fc7fe5af4b1f7b0deb3bab940c20b509971fa1a43e577938`.
Archives/settings remain outside AddOns and Git; unsaved game memory is excluded.

Exact `Inventory/Restock/Vendor/FluxAlreadyKnown.lua` SHA256:

| Source | SHA256 |
| --- | --- |
| Baseline | `f8419f125088da4a443065b1577d1e83c153dc3c941b208cf5a3d616d6c5cdbc` |
| Candidate | `ee9042d3a8e3cb6dec70f7658b355b9595ce84b1e80803fbd81f97dd578db6f1` |

## Desktop regression and matched evidence

`lua tests/auction_cold_tooltip.lua` loads the actual Retail module and exercises
its real row painter. Each provider-presence fixture starts with one cached
known-row paint, recycles that row to an uncached item, supplies 500 missing
tooltip replies and one reply without lines, then checks empty/ready/late/newly
learned results, positive caching, tint reset, disabled state and initially
missing/released/replacement views. Native getters are mocked explicitly.

Five fresh-process baseline/candidate pairs alternate execution order. Every
pair produced the same operation counts:

| Both provider-presence fixtures combined | Baseline | Candidate |
| --- | ---: | ---: |
| Errors from 1,000 missing and two incomplete replies | 1,002 | 0 |
| Failed assertions | 6 | 0 |
| Assertions | 48 | 48 |
| Missing-result queries per fixture | 500 | 500 |
| Frames created per fixture | 1 | 1 |
| Added timers/native load requests/continuations | 0/0/0 | 0/0/0 |
| Final positive-cache rows per fixture | 3 | 3 |

The existing active-row regression also passes 156 checks. Four semantic mutants
are rejected: remove the guard, paint missing data as known, put missing data in
the positive cache, and discard ready tooltip lines. Raw stdout, execution order,
process durations and file hashes are in the
[comparison report](validation/auction-cold-tooltip-comparison-2026-11-05.json).
Process duration includes startup
and fixtures and is not native operation latency. The interpreter is Lua 5.4.6;
no WoW profiler preference was changed.

Native client build, active hardware/graphics/profile/addon settings, matched
screenshots, CPU/allocation measurements, operation latency and frame times were
not captured for this change. No native CPU, FPS, secure/taint or pixel-parity
claim follows from these counts.

## Native checks pending

On Retail, record the actual loaded revision, `GetBuildInfo()`, settings and
enabled addon list. Keep existing profiler preferences and match resolution,
UI scale, profile and game state. With built-in AlreadyKnown enabled, inspect
known and uncollected auction rows, scroll into previously unseen results, and
refresh/reuse those rows while metadata becomes available. Confirm no new
tooltip-readiness errors, normal known tint/monochrome and immediate later
classification. Capture equivalent screenshots of ready rows before/after.
Repeat with the external inventory provider enabled and disabled. A separately
loaded standalone AlreadyKnown addon delegates this integration away and must
be recorded. Check actual file selection before attempting acceptance on
Forever or other clients.

Mailbox open/close/looting and auction buy/post/cancel/buyer-sale freezes remain
pending native scenarios. This small correction does not establish their
resolution. No purchases, cancellations, collections or foreground input were
performed by this batch.

## Read-only investigation appendix

The preceding standalone investigation at `e2c6464` also inspected these paths;
none was changed speculatively:

- The manifest excludes the old `Inventory/FluxInv/*` scanner. The loaded
  `LegacyBridge.lua` forwards consumer registrations and facts to the current
  `Flux.Inventory` service. Current scheduler currency tokens use the scoped
  built-in flush rather than the old default full-refresh function.
- Production scheduler/provider/respec replays at 10/100/500 settled money,
  owned-auction and closed-mail notifications kept frame/callback/listener counts
  fixed and drained timers. Closed mailbox reads and money-triggered token-list
  reads stayed zero. GearSetLock rebuilt once per settled pulse, without growing
  the tested resources. These fixtures exclude other full-addon listeners and
  native API internals.
- Actual AlreadyKnown cold recipe/pet/unknown-static-data replays produced no
  item-load continuation registrations, additional frames or timers. Cold rows
  continued querying on normal paints. This did not reproduce the separate
  external-provider continuation accumulation.
- Independent repeated `FluxItemClass.GetInfo` queries for one cold ID made 500
  native loader calls and 1,500 full-info getter calls in 500 queries, with one
  fixed frame. No growing native queue or causal mail/auction route was proven;
  that module's request policy is unchanged.
- If currency-header expansion is modeled as emitting a nil-ID currency update,
  one update sustains a scan loop. Without that modeled side effect it settles.
  Native expansion-to-event causality remains unverified; no currency change was
  made on that assumption.

A literal-only parser inspected the accessible Forever saved tables without
executing their Lua. The 19:00:01 UTC Flux snapshot was 79,111 bytes: two inventory
characters, 18 bag rows, six auction rows, zero mail rows, 33 character-summary
rows, zero pending characters and two gold-ledger rows. Syndicator's 18:57:56 UTC
snapshot was 20,697 bytes with six distinct positive auction IDs and no duplicate
auction IDs or cached mail; its previous snapshot had the same counts. BugTabs
history was empty in both its 19:11:57 UTC snapshot and previous file. These saved
states do not include unsaved live state and do not prove that the current
native session is free of growth or errors. Redacted raw counts/source hashes
remain in the external investigation artifacts.
