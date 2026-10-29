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

Latest behavior-changing runtime commit: `19c40a0c84212b24fdf221a9653a4116d32f9020`,
tree `92973edadfdd5ebfc5935621bc2b77f1e0655066`. Its full desktop suite passed
85 scripts and 726 syntax files. The editorial cleanup preserves executable Lua
tokens; [fresh full-suite results](validation/editorial-cleanup-full-2026-10-29.json)
and [token comparisons](validation/comment-cleanup-tokens-2026-10-29.json) identify
the current files. The [scope check](validation/editorial-cleanup-scope-2026-10-29.json)
covers actual addon files, including ignored files and bundled libraries.

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
- [Ownership map](MODULE_DEPENDENCIES.md): 35 service/domain rows and 18 API
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
The next independent investigation may cover vendor/restock slot/protection checks
or another reproduced issue outside those domains. See [development tasks](DEVELOPMENT.md).

Editorial validation completed: 85 desktop tests and 726 Lua syntax checks pass;
all current Lua hashes match the final report. Documentation validation passes
with 759 classified sources, 577 reachable files, 361 setting definitions,
23 SavedVariables roots and 12,709 local links. All six CSV ledgers are valid.
The final scope scan covers 1,195 actual files and finds zero development-tool
markers outside Git. Native acceptance retains its prior pending status.
