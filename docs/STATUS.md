# Modernization status

Updated 29 October 2026. Work continues directly in `_FluxUI` and
`DoctorFlux/FluxUI`. Branch: `codex/modernization-audit-20261029`.
`main` remains `7436820453d2248c84c99fff71507553efc47c19`; no merge or push performed.
Latest runtime: `ab4e658a98a7ce3ee6688ac6170e7e0991325af0`, tree
`67b4890083fe13e242ffbc47c36ff6037a172f82`. Final validation: **84 desktop scripts,
725 Lua syntax files, zero failures**. The continuation changed only Mail/Auctions
runtime code; presentation/settings/TOC/bindings remain untouched.

## Completed and verified

- [Recovery checkpoint](RECOVERY.md): all 1,177 actual files including original
  untracked/ignored work, all Git refs/history, and 403 relevant private WTF files.
  ZIP contents verified against hashes, while WoW was closed; archives outside AddOns.
- Read Word/Markdown modernization plan, instructions/templates and all 26 supplied
  specifications. [Inventory](FEATURE_INVENTORY.md) and `FEATURE_PARITY.csv` record
  1,384 requirements/control/default/command/binding/saved-root/integration entries
  and 17 explicit discrepancies. Source collection is complete to the documented
  extractor limits; dynamic/native behavioral acceptance is not complete.
- [Ownership map](MODULE_DEPENDENCIES.md): 35 domain/service rows, 17 API migration
  contracts, 22 registration sites, 577 TOC/XML-reachable files, zero missing includes.
- [Client audit](CLIENT_VALIDATION.md): exact installed PE builds, eight distinct
  target rows and 77 version/license reference entries. All five local Blizzard
  source snapshots predate installed builds. No universal support claim.
- **BUG-001 / PERF-001 fixed:** builtin currency events stop reading/writing/requesting
  work after Syndicator takes ownership. Standalone/pending-provider timing remains.
  Runtime commit `2a7de26052e1b9662deef1b606b5ec95ebefe3aa`, tree
  `86ed71c06dc9bc2117fb60e30d5417976506912a`; only runtime file changed is
  `Inventory/Builtin/Currency.lua` (four guards and an ownership comment).
- First full baseline: **81 tests, 722 Lua syntax files, all pass**. First candidate:
  **82 tests, 723 Lua syntax files, all pass**. Five alternating desktop replay pairs
  show 100 stale GetMoney calls and 300/400 scheduler requests per 400-event burst
  reduced to zero, preserving external money and snapshot generation. No timing/FPS
  claim. [Raw evidence and protocol](PERFORMANCE_PROTOCOL.md), `PERFORMANCE_RESULTS.csv`.
- Refreshed source-derived indexes and verification manifest with existing tools;
  corrected stale loader, integration, provider handoff and `/fluxui bliz` prose.
- First documentation validator passed: 756 classified sources, 577 reachable files,
  361 option definitions, 23 saved roots and 12,649 local links. All six CSV ledgers
  have valid row shapes. All 723 current Lua hashes match the tested candidate.
  Original user package and log (42 files) remain byte-for-byte identical to recovery.

## Continuation completed

- New verified recovery checkpoints at 09:32 and 09:41 UTC preserve each subsequent
  baseline, dirty audit files, history and fresh private settings. Originals remain.
- [Event audit](EVENT_DISPATCH_AUDIT.md) reproduced callback mutation defects, but
  found no production Context.Unsubscribe call that triggers them. Classified as
  a latent API defect; no dispatcher rewrite or hot-path overhead was introduced.
- **BUG-002/PERF-002**, commit `05e9f79`: mail/auction scans cancel queued/partial
  work at their next callback after Syndicator Ready. All 210 targeted checks pass
  (42 baseline failures). Five matched pairs remove 105/56 stale mail reads and
  71/38 auction reads per queued/partial fixture, plus the stale snapshot publication.
  Intermediate full suite: 83 scripts/724 syntax files, zero failures.
- **BUG-003**, commit `ab4e658`: pending send/return completion releases its payload
  and subscriptions before resolving provider-owned recipient data. All 410 targeted
  checks pass (8 baseline failures). Five matched pairs remove foreign row appends;
  100 standalone cycles per action retain one frame/zero subscriptions/50 valid
  credits. Final complete suite: 84 scripts/725 syntax files, zero failures.
- [Provider lifecycle evidence](PROVIDER_HANDOFF_LIFECYCLE.md), raw comparison JSONs,
  `PERFORMANCE_RESULTS.csv`, and
  [identities](validation/continuation-identities-2026-10-29.json) pin each baseline/
  candidate tree and source hash. All 725 current Lua hashes match the final test
  corpus. Both fixes received independent source/test review. Native status unchanged.
- Final documentation validation passes: 758 classified sources, 577 reachable,
  361 option definitions, 23 saved roots and 12,685 local links. Six CSV ledgers
  have valid row shapes (including 92 performance rows).

## Pending and unverified

Native screenshots, pixel/geometry parity, hardware input, secure/combat/taint,
secret-value display and matched native performance remain pending on every target.
Installed clients were inspected, not launched. No current native CPU/FPS result,
full enabled-addon list, live profile/scene or GPU/RAM capture is available.
Original Wrath 3.3.5 is distinct and unsupported/unverified; modern Wrath and Cata
matching clients were not found. Missing native evidence limits certification,
not independent source work.

The broader modernization is unfinished: generic module teardown/cancellation,
latent event-dispatch mutation semantics, remaining provider callbacks, API consolidation,
layout/paint/scan/binding profiling and cross-feature native acceptance remain.
Four inert currency callbacks intentionally remain subscribed to the shared bus.
See [prioritized plan](MODERNIZATION_PLAN.md) and [decisions](DECISIONS.md).

## Preservation and next action

The supplied `new docs/` package is retained unchanged as the requirements snapshot
and included with audit records. `FluxUI_Sync_Log.txt` is deliberately untracked and
untouched by this work. It grew before this continuation (last write 09:30:44 UTC);
its current 142,774 bytes match both continuation checkpoints. All 41 supplied
package files still match the original recovery hashes. No logs/private settings
are added to Git. Ignored local
backups/scripts are preserved. Git author was unset; local commits use this repo's
existing DoctorFlux name/GitHub noreply address via command-only configuration.

Next independent task: reproduce native-query/request work in auction SHOW,
Guild.OpenVault and Void callbacks after provider Ready. These are source findings,
not yet measured defects. Capture a focused baseline before any fix. Native provider
checks can proceed independently using [CLIENT_VALIDATION.md](CLIENT_VALIDATION.md).
