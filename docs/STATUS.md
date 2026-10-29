# Development status

Updated 29 October 2026. Repository: DoctorFlux/FluxUI; addon: `_FluxUI`.
Work continues on the existing change branch. Main remains
`7436820453d2248c84c99fff71507553efc47c19`; no merge or push performed.

## Implemented fixes

| Change | Runtime commit | Verified scope |
|---|---|---|
| Currency provider handoff | `2a7de26` | 150 focused checks; builtin callbacks preserve external snapshots |
| Deferred inventory scans | `05e9f79` | 210 checks; stale queued/partial work cancels after ownership transfer |
| Pending mail completion | `ab4e658` | 410 checks; no writes into provider-owned recipient data |
| Disabled window mover | `19c40a0` | 220 checks and 100 toggle cycles; discovery/polling/gestures stop |
| Queued merchant item identity | `cdd752a` | 660 focused checks; changed/missing listings are skipped before purchase |
| Finite merchant stock budget | `b505bb8` | 177 stock checks; zero caps buying and shared finite stock is reserved |
| Repeated vendor junk availability | `e02139a` | 265 checks across seven API fixtures; unchanged availability reuses bag generation |

Latest behavior-changing runtime commit: `e02139ab1c6b8099b02fb4506ff150a50d6555ef`,
tree `0a23a38a04809c0a087089586cb5842496fb5c64`. Latest full suite: **87 desktop scripts and
728 Lua syntax files, zero failures**. All current Lua hashes match the
[full report](validation/vendor-open-full-2026-10-29.json).

The user reports a hitch simply opening a vendor on **Classic Era**; other clients
have not been tested by the user. [BUG-007/PERF-004 evidence](VENDOR_OPEN_WORK.md)
reproduces redundant junk-availability scans in seven API fixtures. Five matched
pairs reduce Era slot-info reads from 300 to 200 on the first open and from 5,000
to zero across 25 unchanged reopens. Retail/Forever fixture counts fall from
360 to 240 and 6,000 to zero. Native count queries and callback cadence remain.
**The reported native hitch is not yet confirmed fixed.** Native CPU, frame times,
pixels/input/security and cross-client acceptance remain pending.

[BUG-006 evidence](VENDOR_STOCK_BUDGET.md) retains 177 stock plus 660 identity checks.
Its finite budget reserves submitted requests, not native acknowledgement. Earlier
fix/cleanup reports retain their own source identities and historical scope.

## Editorial cleanup

Editor-specific plans, prompts/templates, original Word planning file, old handoff
files, local backup trees and the sync log were archived outside the addon. Useful
working rules and tasks now live in [CONTRIBUTING.md](../CONTRIBUTING.md) and
[DEVELOPMENT.md](DEVELOPMENT.md). Runtime comments use direct technical language;
39 edited Lua files retain identical executable tokens and strings. Licenses,
third-party attribution, gameplay names and actual supported features remain intact.
Original requirements and raw records are preserved in [recovery](RECOVERY.md).

## Requirements and evidence

- [Feature inventory](FEATURE_INVENTORY.md): 1,384 ledger rows covering all 26
  product specifications, controls/defaults, commands, bindings, saved roots and
  integrations; 17 documented discrepancies remain explicit.
- [Ownership map](MODULE_DEPENDENCIES.md): 35 service/domain rows and 21 API
  contracts. Source closure: 577 reachable files, zero missing includes.
- [Client validation](CLIENT_VALIDATION.md): eight distinct client rows and 77
  reference/version/license entries. Installed executables were inspected; their
  metadata is not native acceptance.
- [Performance protocol](PERFORMANCE_PROTOCOL.md), [provider lifecycle](PROVIDER_HANDOFF_LIFECYCLE.md)
  and [Windows lifecycle](WINDOW_MOVER_LIFECYCLE.md) retain measured operation counts,
  exact source identities and raw samples. No native FPS improvement is claimed.

## Pending work

Native screenshots/geometry, real input, combat/protected execution, taint, secret
values and matched native performance remain pending on every target. Broader
service consolidation, lifecycle ownership and performance work remain unfinished.
Event-dispatch mutation is a documented latent defect with no current production
unsubscribe trigger found; do not redesign it without an actual consumer.

Auction, guild-bank and void-storage callback audits are deferred by user direction.
Prioritize matched Era first/repeated vendor-open traces and the remaining cold
classification, merchant index, Already Known and layout candidates if the hitch
persists. These remaining candidates are unmeasured. See [development tasks](DEVELOPMENT.md).

Vendor-open documentation validation passes: 761 classified sources, 577 reachable
files, 361 setting definitions, 23 SavedVariables roots and 12,769 local links. All
six ledgers have valid row shapes (1,384 parity, 35 ownership, 21 API, eight client,
77 reference and 157 performance rows). All 728 Lua hashes match the full report.
The checkpoint comparison finds no missing files and preserves 348 specification/
library/asset/manifest files byte-for-byte. Explicit development-tool markers remain
absent across 1,218 actual files outside Git. Legacy fixture labels share one API
route; Retail/Forever share another, rather than proving seven native contracts.
