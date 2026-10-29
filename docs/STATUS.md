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

Latest behavior-changing runtime commit: `cdd752abd060588bc1602e880d997a60dd0b34a9`,
tree `d18478f458e670f18931c070a00d53a708387fee`. Latest full suite: **86 desktop scripts and
727 Lua syntax files, zero failures**. All current Lua hashes match the
[full report](validation/vendor-slot-full-2026-10-29.json).

[BUG-005 evidence](VENDOR_PURCHASE_IDENTITY.md) records the reproduced wrong-item
purchase, before/after counts and added identity-query cost. Five alternating pairs
remove invalid purchases while stable queues retain 40 purchases over five passes.
Native acceptance remains pending. The earlier editorial cleanup and its source
comparison remain historical evidence for that separate change.

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
- [Ownership map](MODULE_DEPENDENCIES.md): 35 service/domain rows and 19 API
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
The next independent investigation may cover sold-out stock/affordability metadata
for unchanged merchant item IDs, or another reproduced issue outside those domains.
Those candidates are not yet reproduced defects. See [development tasks](DEVELOPMENT.md).

Editorial validation completed: 85 desktop tests and 726 Lua syntax checks pass;
all current Lua hashes match the final report. Documentation validation passes
with 759 classified sources, 577 reachable files, 361 setting definitions,
23 SavedVariables roots and 12,709 local links. All six CSV ledgers are valid.
The final scope scan covers 1,195 actual files and finds zero development-tool
markers outside Git. Native acceptance retains its prior pending status.

Merchant identity documentation validation passes: 760 classified sources, 577
reachable files, 361 setting definitions, 23 SavedVariables roots and 12,733 local
links. All six ledgers have valid row shapes (1,384 parity, 35 ownership, 19 API,
eight client, 77 reference and 118 performance rows). All 727 Lua hashes match
the full report. Requirements/libraries/assets/manifests (346 files) match the fresh
checkpoint, and the development-tool marker scan remains clear outside Git.
