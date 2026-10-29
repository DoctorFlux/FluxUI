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
| Quick Join anchor cycle | `5198ded` | 508 new ownership checks plus 1,311 existing column checks; native fallback retained |
| Vendor tier candidate checks | `1762826` | 340 checks; live usability runs after matching; reference discovery retained |

Latest behavior-changing runtime commit: `17628269f0e3b7fbeb1b8c2d7f9c7196829e67f3`,
tree `0c681c46987fc5b136274bba59e5e5bb3dd90990`. Validation candidate with repeated-open tests:
`e7ec46a4070c132ff8bf6033d6bef5e2c92f90aa`, tree `4507ccd1456e42f9acdea0e2be4aaad073ff72ae`.
Latest full suite: **88 desktop scripts and 729 Lua syntax files, zero failures**.
All current Lua hashes match the [full report](validation/vendor-tier-full-2026-10-29.json).

The user confirms a major Era spike on **every reopening of the same vendor**.
[PERF-005 evidence](VENDOR_TIER_WORK.md) moves live usability checks after tier
matching without suppressing discovery/reference seeding. Five matched pairs show
15,000 item-info service lookups and 15,000 ownership lookups becoming zero across
25 opens of a 200-listing food/water fixture with three unoffered reference families.
Classification calls remain; no native FPS/latency improvement is established.
**The reported live spike remains unverified after this change.** Era's saved
Config.wtf has scriptProfile=1; compare profiled and unprofiled native runs.
Previous fixes were present in the Era install at the pre-edit read-only check.

[BUG-007](VENDOR_OPEN_WORK.md) retains the earlier junk-availability cache and its
265 checks. [BUG-008](CHAT_QUICKJOIN_ANCHOR.md) retains 1,819 chat column checks;
native rechecks remain pending. No UI/settings/profiling preference was changed.

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
- [Ownership map](MODULE_DEPENDENCIES.md): 35 service/domain rows and 23 API
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
Prioritize matched repeated-open Era traces with profiling overhead separated;
remaining classification, Already Known, reagent-name and layout work need native
attribution before another change. Chat native checks remain pending. See
[development tasks](DEVELOPMENT.md).

Vendor-tier documentation validation passes: 762 classified sources, 577 reachable
files, 361 setting definitions, 23 SavedVariables roots and 12,807 local links.
All six ledgers have valid row shapes (1,384 parity, 35 ownership, 23 API, eight
client, 77 reference and 217 performance rows). All 729 current Lua hashes match
the full report. The fresh checkpoint comparison preserves 348 specification/
library/asset/manifest files byte-for-byte, with no missing files or unexpected
changes. Explicit development-tool markers remain absent across 1,234 actual files
outside Git. Main remains unchanged; native repeated-open acceptance is pending.
