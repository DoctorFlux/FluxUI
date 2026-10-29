# Modernization status

Updated 29 October 2026. Work continues directly in `_FluxUI` and
`DoctorFlux/FluxUI`. Branch: `codex/modernization-audit-20261029`.
`main` remains `7436820453d2248c84c99fff71507553efc47c19`; no merge or push performed.

## Completed and verified

- [Recovery checkpoint](RECOVERY.md): all 1,177 actual files including original
  untracked/ignored work, all Git refs/history, and 403 relevant private WTF files.
  ZIP contents verified against hashes, while WoW was closed; archives outside AddOns.
- Read Word/Markdown modernization plan, instructions/templates and all 26 supplied
  specifications. [Inventory](FEATURE_INVENTORY.md) and `FEATURE_PARITY.csv` record
  1,384 requirements/control/default/command/binding/saved-root/integration entries
  and 17 explicit discrepancies. Source collection is complete to the documented
  extractor limits; dynamic/native behavioral acceptance is not complete.
- [Ownership map](MODULE_DEPENDENCIES.md): 35 domain/service rows, 14 API migration
  contracts, 22 registration sites, 577 TOC/XML-reachable files, zero missing includes.
- [Client audit](CLIENT_VALIDATION.md): exact installed PE builds, eight distinct
  target rows and 77 version/license reference entries. All five local Blizzard
  source snapshots predate installed builds. No universal support claim.
- **BUG-001 / PERF-001 fixed:** builtin currency events stop reading/writing/requesting
  work after Syndicator takes ownership. Standalone/pending-provider timing remains.
  Runtime commit `2a7de26052e1b9662deef1b606b5ec95ebefe3aa`, tree
  `86ed71c06dc9bc2117fb60e30d5417976506912a`; only runtime file changed is
  `Inventory/Builtin/Currency.lua` (four guards and an ownership comment).
- Full baseline: **81 tests, 722 Lua syntax files, all pass**. Candidate:
  **82 tests, 723 Lua syntax files, all pass**. Five alternating desktop replay pairs
  show 100 stale GetMoney calls and 300/400 scheduler requests per 400-event burst
  reduced to zero, preserving external money and snapshot generation. No timing/FPS
  claim. [Raw evidence and protocol](PERFORMANCE_PROTOCOL.md), `PERFORMANCE_RESULTS.csv`.
- Refreshed source-derived indexes and verification manifest with existing tools;
  corrected stale loader, integration, provider handoff and `/fluxui bliz` prose.
- Documentation validator passed: 756 classified sources, 577 reachable files,
  361 option definitions, 23 saved roots and 12,649 local links. All six CSV ledgers
  have valid row shapes. All 723 current Lua hashes match the tested candidate.
  Original user package and log (42 files) remain byte-for-byte identical to recovery.

## Pending and unverified

Native screenshots, pixel/geometry parity, hardware input, secure/combat/taint,
secret-value display and matched native performance remain pending on every target.
Installed clients were inspected, not launched. No current native CPU/FPS result,
full enabled-addon list, live profile/scene or GPU/RAM capture is available.
Original Wrath 3.3.5 is distinct and unsupported/unverified; modern Wrath and Cata
matching clients were not found. Missing native evidence limits certification,
not independent source work.

The broader modernization is unfinished: generic module teardown/cancellation,
event-dispatch mutation semantics, remaining provider callbacks, API consolidation,
layout/paint/scan/binding profiling and cross-feature native acceptance remain.
Four inert currency callbacks intentionally remain subscribed to the shared bus.
See [prioritized plan](MODERNIZATION_PLAN.md) and [decisions](DECISIONS.md).

## Preservation and next action

The supplied `new docs/` package is retained unchanged as the requirements snapshot
and included with audit records. Original `FluxUI_Sync_Log.txt` is deliberately
untracked and unchanged; no logs/private settings are added to Git. Ignored local
backups/scripts are preserved. Git author was unset; local commits use this repo's
existing DoctorFlux name/GitHub noreply address via command-only configuration.

Next independent task: reproduce `Core.Events` handler-list mutation with actual
dispatch and trace self-unregistering consumers. Establish the intended dispatch
contract and matched resource/count baseline before a separate bounded fix. Native
currency checks can proceed independently using [CLIENT_VALIDATION.md](CLIENT_VALIDATION.md).
