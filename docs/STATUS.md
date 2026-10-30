# Development status

Latest unit-frame change (30 October 2026): Flux-owned main and raid power bars
hide for a known zero maximum; health fills the freed space. On Live/Forever,
full-height health sits behind a resource layer whose alpha accepts secret max
power directly. A zero current value keeps its bar. [Behavior and limits](UNIT_POWER_VISIBILITY.md).
Health text now uses the full-height anchor for a known zero maximum; restricted
maxima keep text in the health section. The Flux separator reapplies power alpha
after partition/chrome repaint, including ToT changes; power text follows the
resource layer's alpha. Player/target HP labels move to the vertical middle
for known zero power and restore their nested positions when power returns.
ToT separator chrome now follows its raised side-by-side frame level.
Focused checks and the full desktop suite pass: 96 scripts, 737 Lua syntax files.
Native client geometry, combat/taint and secret-value acceptance remain pending.
Main working tree contains this uncommitted change; no game/settings interaction.

Latest follow-up: [BUG-012/PERF-011](TELEPORT_CAST_WORK.md) corrects teleport/portal
counts and removes reagent scans/popup rebuilds from interrupted-cast recovery.
User confirms Retail. 527 focused checks, three rejected mutations and five
desktop pairs pass; integrated 100 casts reduce tooltip calls 2,000 -> 0 and
popup rebuilds 100 -> 0. Full 95 scripts / 736 syntax files pass. Native hitch
resolution/combat/taint/pixels and other custom flyouts remain pending. No game,
settings or profiler changes; working-tree fix unpublished.

Updated 29 October 2026. Repository: DoctorFlux/FluxUI; addon: `_FluxUI`.
Work continues on the existing change branch. Main remains
`7436820453d2248c84c99fff71507553efc47c19`; no merge or push performed.

## Implemented fixes

Objective tracker follow-up: Retail and Forever now correct the first visible
module after saved native callbacks and unchanged-height syncs; scroll-child
resizing also restores zero offsets. [Regression](../tests/objective_tracker_scroll.lua):
40 checks pass (11 failures against the baseline). Latest
[full validation](validation/objective-tracker-scroll-2026-10-29.json): 90 desktop
scripts and 731 Lua syntax files, zero failures. Native rendering/taint remains
pending; the runtime vendor identities below retain their historical scope.

| Change | Runtime commit | Verified scope |
|---|---|---|
| Currency provider handoff | `2a7de26` | 150 focused checks; builtin callbacks preserve external snapshots |
| Deferred inventory scans | `05e9f79` | 210 checks; stale queued/partial work cancels after ownership transfer |
| Pending mail completion | `ab4e658` | 410 checks; no writes into provider-owned recipient data |
| Disabled window mover | `19c40a0` | 220 checks and 100 toggle cycles; discovery/polling/gestures stop |
| Queued merchant item identity | `cdd752a` | 660 focused checks; changed/missing listings skipped before purchase |
| Finite merchant stock budget | `b505bb8` | 177 stock checks; zero caps buying and finite stock reservations are shared |
| Repeated vendor junk availability | `e02139a` | 265 checks across seven API fixtures; reliable bag generation reused |
| Quick Join anchor cycle | `5198ded` | 508 ownership plus 1,311 original column checks; native fallback retained |
| Vendor tier candidate checks | `1762826` | 340 checks; matching before live usability; discovery retained |
| Bag/cached-bank tier count checks | `013bf40` | 1,710 checks; five native Era background getter pairs preserve results with lower CPU |

Latest runtime/test commit `013bf40db1d5b57c238ac3ac377e8ced98446fd1`, tree
`4f0d827bb26bba3ee8b20e21de891596fad0e98b`. Latest full suite: **89 desktop scripts
and 730 Lua syntax files, zero failures** in the [full report](validation/tier-count-full-2026-10-29.json).
All current Lua hashes must match that report before reusing its results.

## Era vendor evidence

The user's every-reopening hitch is reproduced on **Era 1.15.9.70576 / interface
11509**. One clean four-reopen pilot records a 333 ms maximum UI interval and
about 320 ms per restock target build, with automation off and scriptProfile=1.
It identifies unrelated live usability/tooltip checks in bag and cached personal-
bank tier counts. [PERF-006](TIER_COUNT_WORK.md) filters membership before the live
gate without adding caches/resources or changing quantities/UI timing.

Five alternating native background getter pairs return identical quantities.
Median inclusive CPU per five kinds: **bags 132.199 -> 15.237 ms**, **cached bank
118.897 -> 22.517 ms**. Native bank outputs are all zero; positive bank/warband
quantities have desktop coverage only. Raw samples, variation, hardware/addons,
settings and source-derived local probe are recorded. No public/native API replaced.
These results establish getter improvement, not whole-vendor after latency or FPS.

WoW stays in the background at the user's request; no further foreground access.
Original auto-sell/repair/restock flags are restored true; profiler preference
remains 1. Temporary sampler/namespaces cleared by reload and diagnostic exports
removed. The user's existing sync delivered candidate source; equality verified.
Latest recovery preserves on-disk WTF while both clients ran, not unsaved state.

Prior [vendor candidates](VENDOR_TIER_WORK.md), [junk availability](VENDOR_OPEN_WORK.md),
[stock reservations](VENDOR_STOCK_BUDGET.md) and [chat anchors](CHAT_QUICKJOIN_ANCHOR.md)
retain their separate source identities and scope. Reservations are not native
purchase acknowledgement; the chat native recheck remains pending.

## Editorial cleanup

Editor-specific plans, prompts/templates, original Word planning file, old handoffs,
local backup trees and sync log remain archived outside the addon. Working rules
live in [CONTRIBUTING.md](../CONTRIBUTING.md) and [DEVELOPMENT.md](DEVELOPMENT.md).
Earlier comment cleanup preserved executable Lua tokens/strings. Licenses,
third-party attribution, gameplay names and supported features remain intact.
Original requirements/raw records are preserved in [recovery](RECOVERY.md).

## Requirements and evidence

- [Feature inventory](FEATURE_INVENTORY.md): 1,384 parity rows covering all 26
  specifications, controls/defaults, commands, bindings, saved roots and integrations;
  17 discrepancies remain explicit.
- [Ownership map](MODULE_DEPENDENCIES.md): 35 domain/service rows and 24 API contracts.
  Load closure remains 577 reachable files with no missing includes.
- [Client validation](CLIENT_VALIDATION.md): eight distinct client rows and 77
  reference/version/license entries. Only Era gains partial native count evidence;
  original Wrath is distinct from modern Classic and remains unverified.
- [Performance protocol](PERFORMANCE_PROTOCOL.md): 242 result rows retain source
  identities, matched samples, limits and pending native acceptance.

## Pending work

Full foreground vendor after timing, matched screenshots/geometry/input, unprofiled
FPS, startup/cold work, native allocations/resource enumeration, combat/taint and
Retail secret-value checks remain pending. Background cadence cannot certify
foreground FPS. Preserve original profiling preferences when testing overhead.

When foreground testing is convenient, follow [exact vendor steps](TIER_COUNT_WORK.md).
Attribute any remaining hitch before another optimization. Other clients, external
provider readiness and native positive-bank/warband parity still need tests. Broader
service consolidation/lifecycle work remains unfinished. Event-dispatch mutation
is latent with no production unsubscribe trigger; avoid speculative redesign.

Auction, guild-bank and void-storage callback audits remain deferred by user
instruction. Continue in the existing folder/branch and leave main unchanged.
See [development tasks](DEVELOPMENT.md).

Final documentation validation passes: 763 classified sources, 577 reachable files,
361 setting definitions, 519 literal defaults, 23 SavedVariables roots and 12,824
local links. All six ledgers have valid shapes (1,384 parity, 35 ownership, 24 API,
eight client, 77 reference and 242 performance rows). All 730 normalized Lua hashes
match the full report. Checkpoint comparison preserves 361 specification/library/
asset/manifest/XML files byte-for-byte, with no missing files or unexpected changes.
Explicit development-tool markers remain absent across 1,244 actual files outside
Git. Main remains unchanged; complete native after acceptance remains pending.

## Retail audit — latest actual-file validation

[Whole-addon audit](RETAIL_PERFORMANCE_AUDIT.md) indexes 577 reachable files across
26 domains. BUG-009/PERF-007 `6ac4389` fixes accumulating loot waiters; BUG-010/PERF-008
`3046478` releases full optional capture snapshots/handle references. Five desktop
pairs preserve geometry/report controls: loot frames 203 -> 3, retained capture
snapshots 20 -> 0 per model. Focused checks 2,050 / 400; existing capture 383 with
12 rejected mutations. Latest actual-file suite is **92 scripts / 733 Lua files,
zero failures**: [full report](validation/retail-lifecycle-full-2026-10-29.json).
It includes the preserved, uncommitted tracker correction; older vendor corpus
counts above retain their historical scope.

Native Retail 12.1.5.70575 / interface 120105, project 1: five 20-second background
captures, median addon CPU 30.772 ms/s (30.107-37.046), stable 14,742 total / 1,449
Flux-source frames and eight sampled public cache sizes. Memory rises during the
requested diagnostics; native follow-up is scoped to snapshot release, not a claim
that ordinary UI leaks at that rate. Nameplate/assistant work needs further matched
attribution. Foreground FPS, combat/taint/pixels, private-cache churn, multi-hour
sessions and other clients remain pending. Original profiler preference is 0;
restore it after probes. WoW remains in the background, main unchanged, excluded
callbacks untouched. Existing tracker source/test changes remain uncommitted.

Retail follow-up complete: five direct file-loaded candidate captures retain compact
reports with824 KiB block growth versus40,450 KiB before. Unequal memory endpoint
gaps, camera activity and frame totals make strict gameplay/CPU/FPS comparisons
inconclusive. [Raw follow-up](validation/retail-idle-native-after-2026-10-29.json).
Original profiler0 restored and temporary diagnostics removed; WoW stays open in
the background. Normal HUD leak-free acceptance remains pending.

## Chat column — latest runtime and validation

BUG-011 alignment/reload `78fe4e7`, all-tab anchor `7f13000`: Social uses one eight-
UI-unit tab-row inset on every client path. The relative offset follows late login
pins; one primary-dock anchor prevents Combat Log/Global/custom-tab rectangle
changes from moving buttons. Copy still targets the selected tab. [Evidence](CHAT_COLUMN_ALIGNMENT.md).

Current actual-file report is [chat validation](validation/chat-column-alignment-full-2026-10-29.json):
92 scripts/733 syntax files pass, including2,009 column checks. Five alternating
pairs preserve layout point/frame counts; native Retail seven General/Global/Combat
Log selections have identical visible coordinates. Untouched reload screenshot
inspected before chat/tab input. Other native clients/combat/taint/full pixel/FPS
acceptance remain pending. Main unchanged; original profile0 and empty diagnostic
root restored; WoW stays in background. Separate pending tracker work preserved.

Final combined verification:92 scripts/733 normalized Lua hashes pass. Source
inventory766, reachable577, setting definitions361, literal defaults519, saved
roots23, local links12,868. Ledger shapes valid:1,384 parity/35 ownership/28 API/
eight clients/77 references/308 performance/26 audit-domain rows. Protected361
files remain byte-identical; tracker source/test preserved. Explicit development-
tool markers absent across1,271 actual files outside Git. Main unchanged. Native
temporary data removed; original profile0 retained. Generated records remain with
the user's separate pending tracker work; focused runtime/evidence commits exclude it.

## Latest: original-plan continuation and PERF-009

Current runtime/test commit `efca305c76a87f9db36db12a1a2400272a253633`, tree
`1aa4627d774e10515dc52681b0cb527dba4ab60b`. [Original stage tracker](MODERNIZATION_PROGRESS.md)
keeps all26 specifications and remaining exit gates explicit. Countdown now reuses
one poll's native text-region lookup and avoids the temporary frame-level table.
UI/cadence/settings/resources are unchanged. [Evidence](NAMEPLATE_COUNTDOWN_WORK.md).

Five desktop pairs halve modern/legacy lookups20,000 ->10,000 per10,000 updates;
1,160 checks and five rejected mutations pass. Native Retail12.1.5.70575 has five
alternating real-widget pairs: median33.371 ->31.712ms per2,000 updates, identical
owned-widget geometry/alpha/hide-reuse and0 recorded errors. One candidate pair is
slower. Actual restricted aura pixels/combat/secret values and other clients remain
pending. Complete-addon background scene changed; no FPS/overall speedup claim.

Latest actual-file [full report](validation/nameplate-countdown-full-2026-10-29.json):
**93 scripts /734 Lua syntax files, zero failures**. It includes the preserved
uncommitted tracker correction. Candidate source is restored in the normal addon
folder and loaded natively. Profile0 unchanged; diagnostic root/globals/frames
removed by normal reload; WoW stays open in background. Main and deferred callbacks
remain untouched. Root continuity files restored as explicitly requested.

## Latest: action-bar/player-aura batch

Runtime/test `677d85c0f0a476c252e65e5703ca20b78d98528b`, tree
`05fa9fc0de4f874a9c99cc7d49887890f610ba08`. PERF-010 samples activation once per
existing paint batch; direct updates stay fresh. [Audit](ACTION_AURA_WORK.md).
1,420 focused checks/100 toggle cycles per branch/five rejected mutations pass.
Latest actual-file [full report](validation/action-highlight-full-2026-10-29.json):
**94 scripts /735 Lua syntax files, zero failures**, including preserved pending
tracker work. No feature/settings/cadence/geometry reduction or new resource.

Native Retail and Era each pass five alternating real57-button inactive-highlight
pairs:activation calls5800 ->100 per100 passes, identical button and player-aura
root geometry, zero recorded matched-run errors. Median elapsed5.303 ->2.728ms
Retail,8.568 ->3.079ms Era. Whole-addon CPU/FPS comparison is inconclusive; actual
active combat/secure input, dense/restricted aura churn and long sessions pending.
Player aura data/handlers/style remain Blizzard-owned. Original profiler0 Retail/
1 Era restored; temporary data removed and Era prior report deep-equal after cleanup.
Both processes remain open; Era is in world, Retail warning dismissed/reconnect.
Account sessions conflict, so tests run serially. Main/deferred callbacks and the
user's separate pending tracker changes remain untouched.

## Main publication authorization and combined workspace

The user authorized the complete upload to GitHub and updating main on29 October
2026. Earlier main holds/pending-tracker notes above describe historical batches.
The objective-tracker source/test and focused records are now committed in
`73ca9d2`; all combined runtime changes retain the previously passing735 Lua hashes.
A fresh [publication suite](validation/github-publication-2026-10-29.json) and current
generated references cover the complete work. [Publication record](GITHUB_PUBLICATION.md)
retains recovery, source identity, exclusions and non-force-push policy. Native
pending acceptance remains unchanged. Preserve the development branch/history.

Publication completed: payload `421c05a` is on GitHub main and the retained
development branch, verified by reading both remote refs. The complete addon,
tracker fix, tests and current references are included. No force push, private
settings/captures, archive upload or live game changes. All 735 Lua hashes match
the fresh 94-script report; native pending checks retain their recorded scope.

## Latest publication scope: local snapshot, main only

The user now requires main only and upload of the current local files, including
the teleport fix that was not part of b45eb5e. The identical development branch
was removed locally/on GitHub without losing commits. Earlier branch-retention
notes are historical and superseded. Current source matches the95-script/736-file
teleport corpus;527 focused checks pass again. [Fresh publication validation](validation/main-local-snapshot-2026-10-29.json)
records the complete local snapshot. All current code/test/docs belong in main;
private backups/settings/captures remain local. Native pending checks are unchanged.
