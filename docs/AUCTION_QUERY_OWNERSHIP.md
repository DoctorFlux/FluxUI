# Built-in auction query ownership — 5 November 2026

## Reproduced failure

Built-in auction handlers can be registered before Syndicator becomes ready.
Their open callbacks still called native owned-auction queries after provider
handoff; the source check inside Refresh happened after those calls. Legacy
interaction-show and auction-show callbacks also queried separately for one
opening. Repeated show callbacks kept querying while the house was already open.

This is a reproduced query-ownership and duplicate-work failure. It does not
establish that repeated show callbacks occur during the user's sale/mail freezes,
or that this correction resolves those freezes.

## Change and preserved behavior

One local open helper checks provider ownership before changing built-in state
or calling native query APIs. It latches an attempted query before entering
native code, preventing synchronous callbacks from duplicating the attempt.
Close resets the latch. A refused attempt is not repeatedly retried by duplicate
show events; the next actual close/open allows another attempt. When the API is
absent, no attempt is latched, so later API readiness can still query.

Legacy clients query on the first applicable show callback. Modern clients retain
the existing interaction-show query trigger; standalone auction-show still only
queues a cached-row refresh. Every applicable show callback can refresh those
cached facts through the existing debounce, including changed rows. Explicit
Refresh remains a cache scan rather than another server query. Native UI queries,
sale/post/cancel operations and provider callbacks are unchanged.

The existing narrow native-call protection remains; no broader error suppression
is added. No frame, timer, scheduler, global replacement, setting or saved-data
identity is introduced. No game input or profiler change was made for this work.

## Source identity and client scope

Baseline: `e860ce6de499a7702b91e8a8d74f115fbc9e0293`. Verified external checkpoint
`Mail-auction-lifecycle-20261105T171132Z`: 1,496 actual files, 75 accessible on-disk
settings and verified all-ref history. Source ZIP SHA256:
`38c16e1f0d1d928ffb6015a89ad10e78f991dc038d0d738f7d3483ace86a0e5e`.
Private settings/archives remain outside AddOns/Git; unsaved memory is excluded.
The selective baseline Auctions.lua SHA256 is
`5465175ed52dfba4c209d1b61a77a8ba23380f73085b22ea9f1111743d58ab2a`.

The regression executes the actual HasLegacyAuctionHouse function with both API
namespaces present: Era selects legacy; other tested client labels respect the
public runtime legacy-client flag. It then loads the real auction module. This
does not turn labels into native client tests. The pinned client/native auction
contracts are listed in [the source reference](NATIVE_MAIL_AUCTION_REFERENCE.md).
Forever/Retail modern show handlers were also checked directly at the existing
pins; no native source or external addon code was copied or modified.

## Desktop evidence

```powershell
lua tests/auction_query_ownership.lua
lua tests/auction_query_ownership.lua '<baseline>/Auctions.lua'
lua Inventory/_tmp_inventorylag_smoke.lua
lua tests/deferred_inventory_handoff.lua
```

Five client labels, each with both show-event orders, cover initial open, fifty
duplicate pairs, changed/unchanged row publication, explicit cache refresh,
duplicate close/reopen, provider handoff, already-ready provider, synchronous
reentry, refusal, missing/late APIs and preserved modern trigger timing.

| Modeled query count across the labelled cases | Baseline | Candidate |
| --- | ---: | ---: |
| Legacy initial open plus fifty duplicate show pairs | 408 | 4 |
| Modern initial open plus fifty duplicate show pairs | 306 | 6 |
| Show queries after provider handoff | 700 | 0 |
| Reentrant-show scenario | 278 | 10 |

The exact baseline fails 72 of 1,330 dynamic checks; the candidate passes all 628.
Totals differ because the fixture checks arguments on each modern query call.
The reentry scenario deliberately models synchronous callback delivery and does
not claim that these exact show events reenter from the native query in game.
Cached counts, generation equality, saved listing records, close cancellation
and scan cadence pass. Existing inventory smoke passes 1,732 checks and deferred
ownership handoff passes 210. The [raw comparison](validation/mail-auction-lifecycle-comparison-2026-11-05.json)
records five alternating pairs per scenario and eight rejected mutations across
both changes. The [full-suite report](validation/mail-auction-lifecycle-2026-11-05.json)
passes 145 scripts / 800 syntax files and identifies the complete Lua corpus.

These are deterministic mocked operation counts, not native query durations,
network measurements, CPU/allocation samples, FPS or frame-time improvement.
Native testing still needs the actual client build, enabled addon/provider list,
source revision and separate open/post/cancel/sale/mail scenarios. Preserve addon
flags, background operation, profiler preferences and diagnostics; do not claim
whole-client freeze removal from this result.
