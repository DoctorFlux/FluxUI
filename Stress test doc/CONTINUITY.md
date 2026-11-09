# Audit continuity — 7 November 2026

9 November focus colors (FOCUS-TARGET-COLORS-20261109): compact focus now
uses the shared target color painter for its own focused unit instead of the
party/player accent policy. Main/portrait/outer/atlas borders, backdrops, compact
divider, cast shell/icon and threat shell follow target's class/NPC palette;
combat portrait red restores those colors. Party class-color controls remain
party-only; focus layout, HP/resource fills, aura options and settings remain.
21,985 focused checks across five client models and 66 portrait-restore checks
pass; five old-source rejects/candidate passes and 10 matching installed source
copies retained. External 2382-file/history checkpoint verified; 120 settings
metadata entries read-only. No new frame, event, timer, polling or settings;
native pixels/taint/performance pending. All 268 scripts and 935 syntax files
PASS with no source drift.
[Scope and evidence](../docs/UNITFRAME_COMBAT_TRANSITIONS.md#focus-colors--9-november-follow-up).

9 November NAMEPLATE-QUEST-COMPACT-20261109: user requested shorter/smaller quest
tags with contained icon. Quest font/icon10; host12; total icon/padding16; topY+3
keeps centreY-3 matching threat/level.371focused plus existing combo/cast checks
PASS; no new resources, quest/provider changes or game interaction. Native
visual check remains user-owned.
[Compact record](../docs/validation/nameplate-quest-compact-2026-11-09.json).


9 November unit-frame combat transitions (UNITFRAME-COMBAT-20261109): target
click host now retains prepared mouse input under native visibility; compact
focus-target width survives global squeeze and deferred combat sizing. Party
widths are verified through modeled combat roster transitions. Focus/party/pet
vertical strips support shields and heal absorbs through shared full-height
native sinks/clipping, existing options and safe events. 285 visibility/30 width/
2785 vertical/1035 party checks pass, plus existing menu/geometry checks. Five
baseline-reject/candidate-pass pairs per fault retained; all 267 scripts and 934 syntax files
PASS, no source drift; 20 installed runtime copies match.
External verified 2362-file/history checkpoint and 120 settings metadata retained.
Four display frames per strip plus modern calculator and one target native
visibility registration are explicit feature costs; no new poll/ticker/event
frame. Native clicks/taint/pixels/performance pending on all five clients; no
connected test tool, game input, settings/profiler writes or publication.
[Scope, sources and steps](../docs/UNITFRAME_COMBAT_TRANSITIONS.md).

9 November NAMEPLATE-QUEST-PROGRESS-20261109: existing nameplate Core/defaults/
options add own default-enabled quest kill/loot counters, exact requested TOPLEFT
at BOTTOMLEFT0,+4 and centreY -3 matching threat/level, Questie association/native fallback and duplicate-marker policy.
311 focused/seven rejected controls; full suite evidence under docs/validation.
Native acceptance user-owned and NOT RUN; no FPS/taint/pixel inference, game input,
sync or publication. External source/history checkpoint verified before runtime.
See [feature](../docs/19-nameplates.md#quest-kill-and-loot-progress--9-november-2026).


<!-- STRESS-FIXES-20261107 -->
7 November stress fixes (STRESS-FIXES-20261107): the user authorized implementation after the audit/proposal phase. Applied public fade ownership, secret-safe alpha/geometry handling, local Forever driver adapters, accurate/cancellable Respec completion, input invalidation, mutation-safe event delivery, retained FIFO scheduler work, bounded combat drains, raid/nameplate work reduction, hidden-watch suspension, bounded range freshness and auction retry churn. Settings, saved roots, commands, artwork and foreign library ownership are preserved. Combined desktop validation: 232/232 scripts and 896 Lua syntax files PASS; post-suite Lua hashes match. No game input, WTF/profiler writes, commit, push or manual cross-install copy was performed. USER-001 actual failing frame/first taint source, native taint, pixels and CPU/FPS remain pending. Visible character-button polling and coherent auction publication after quiet are intentional safety limits, not claimed eliminated costs. [Current implementation record](applied-fixes/README.md). Earlier no-edit authorization statements below are historical.
<!-- /STRESS-FIXES-20261107 -->

Fix-proposal phase requested: "lets find fixes before we apply them". See
`fix-proposals/README.md` and its workspace/verification records. Fresh frozen
external baseline contains975 source/license/text files, unchanged during capture.
Nine external prototype files were prepared; live files remain unchanged. Full
existing222/222 baseline and222/222 combined prototype checks pass with stable
identities. Minimal cast public endpoint and redundant swing read are concrete;
broader Swing ownership is a held prototype. Alpha reader and glow candidates
retain getter-denial/unknown-appearance/winning-library gates. Shared glow-cache
change must not be applied independently of the corrected winning renderer.
The native remaining-span GEO-01 experiment was rejected by a50px→33.33px
snapshot-mismatch countermodel; no GEO-01/02 geometric edit is selected. Native
USER-001 owner/taint/pixels remain unconfirmed. No application/sync/input/settings/
profiler/branch/commit/push is authorized by this proposal phase.

Follow-up USER-001: further logs at12:32:26,13:05:58,13:09:17,13:17:27,13:19:19 and13:21:18 are consolidated
with12:31:53 as thirteen entries atseven timestamps; repeated pastes are not counted
again. The action/frame remains unknown. See `security/secret-value-followup/README.md`
for the wider alpha/geometry review, existing-helper controls and current source
checkpoint. Nine files differ from the prior full-suite snapshot due to external
work; the earlier whole-suite pass stays tied to its manifest. This audit still
authorizes tests/reports only, with no runtime or game/settings/profiler changes.
Focused follow-up delivers ALPHA-01..06, GEO-01 (conditional comparison failure)
and GEO-02 (contained arithmetic denial/recovery case), plus guarded controls;
790 assertions about modeled behaviors in total. These are not eight new native
errors. Focused consumed hashes match and validation passes. The actual USER-001
frame and first taint cause remain unresolved; no further user context is known.

This is an audit-only delta to the existing `docs/STATUS.md`, `docs/DECISIONS.md`,
`docs/WORK_LOG.md`, `NEXT_SESSION.md` and parity/client/performance ledgers. Those
files were read before work. The current user instruction forbids addon edits,
so this audit writes its continuity and ledger additions in this new folder.
Do not merge these additions into existing files or implement the fixes without
the later fix request.

## Snapshot and work completed

- Existing repository, `main`, HEAD `75cf2bcba83adfea0501934f4eeb2a980c46fdf8`.
  The user's substantial dirty working tree is preserved. HEAD alone is not the
  tested source identity; use `evidence/baseline.json` and per-run manifests.
- Fresh external checkpoint: source archive, working diff, recent Git history,
  private settings metadata and seven current upstream source snapshots. Exact
  external path is in `evidence/baseline.json`; no backup/settings archive placed
  in AddOns. Metadata for 45 settings files was read; their content was not copied.
- Four current Gethe branches resolved once and pinned, including separate Era
  and Anniversary. Seven targeted local files match current source after CRLF
  normalization. Other historical fixtures retain their own version limits.
- Canonical `tests/run_validation.py` ran without `--sync-docs`: 222/222 scripts,
  885 Lua syntax files, zero failures. Three full captures retain initial,
  intermediate and latest sources; latest full run has identical885-file
  before/after hashes. Existing doc validation initially passed; an intermediate
  check reports6 stale entries after concurrent Manager/input-fixture changes.
  Other work refreshed those files; final readonly check PASS with15131 links.
  This audit issued no existing-doc generation/write. New audit-folder validation passes.
- New input/security/performance harnesses and repeated raw outputs are retained.
  Lua harnesses end `.lua.txt` so they do not become addon-inventory candidates.
- Seven findings: SEC-01/02/03, INPUT-001/002, LOGIC-01/02. Eight separate
  performance/freshness candidates: PERF-01..07 and PERF-SEC-01. All remain open.
- USER-001 was reported during testing: two Forever FrameUtil.lua:427 secret
  startAlpha arithmetic errors at12:31:53. User confirms Forever and does not know
  the triggering action. Preserve the native report, candidate ranking and
  desktop/native distinction in `security/USER-001-FADE.md`; no fix applied.
- Independent peer review confirms service edge cases while limiting their
  current-feature reachability. No falsely promoted ordinary auction failure.
- Every TOC/XML-reachable source is indexed; performance driver candidates and
  security writer/guard triage retain module coverage and unknowns.

## Decisions and constraints retained

- Tests and documentation now, feature-preserving fixes later. No runtime fixes,
  new frameworks, changed cadence, appearance, commands, integrations or saved
  roots are authorized by this task.
- User explicitly selected simulation here, outside the game. Do not ask again
  about Witchcraft/UIForever for this audit. Native taint/secret/protected-state,
  input, rendering, FPS and native dungeon/raid rules remain not run.
- Keep WoW in the background. No foreground, mouse, keyboard, clipboard,
  reconnect, character selection or diagnostic/profiler command was used.
- Preserve all concurrent edits. The final preservation report records external
  documentation/settings changes and four Lua source/test changes: Paint.lua,
  utility_mixed_faces.lua, UtilitySlots/Manager.lua and utility_secure_input.lua.
  A complete canonical rerun passes on the latest manifest, unchanged through
  that run. Earlier stress tests keep their original identities; utility secure
  stress has3 fresh passes for Manager/fixture, and the changed Paint.lua body
  is not consumed by the standalone stress reproducers. No audit tool
  writes those existing files; never revert drift to make a report pass.
- Auction scenarios are in scope. Guild-bank and void-storage callbacks receive
  no new callback experiment or change under repository restrictions.
- Source/test pass does not certify every native client or every branch. Retain
  the 284 loaded paths without a literal test reference as discovery/coverage
  follow-up, not 284 proven unexecuted files or a fabricated coverage percentage.
- Existing licenses and useful ownership/restriction explanations remain intact.

## Later fix order and acceptance

1. Resolve Respec completion/cancellation (SEC-02/03) with the existing operation
   owner, detached snapshot and accurate checkpoint/completion behavior.
2. Migrate Forever-owned driver calls to the existing local adapter before
   restoring native globals (SEC-01); preserve safe fallback/paging constraints.
3. Preserve monotonic invalidation union and correct child-vararg traversal
   (INPUT-001/002) without extra recurring work or unsafe hierarchy inspection.
4. Harden service reentry and dispatch mutation (LOGIC-01/02), prioritizing their
   demonstrated caller reachability and avoiding per-event snapshot allocation.
5. Measure native hotspots only if requested; use the eight performance proposals
   and their exact work-count baselines. Preserve features, cadence and atomic
   snapshots. Do not trade safe native provenance for fewer polling calls.

Before implementing, compare source hashes, retain a new external checkpoint,
read the detailed finding/regression, and create an actual failing regression
against the latest production code. The audit's anomaly-confirming harnesses may
need expectation reversal once a fix is implemented; do not silently turn those
observations into a clean pass. Native acceptance remains a separate decision.

## Resume and error intake

Read this file, `README.md`, `REQUIREMENTS.md`, `SCENARIOS.md`, `SOURCES.md` and
the relevant detailed finding. Verify the actual branch/head and production
hashes, then run the affected standalone script using `RUNBOOK.md`. Continue
independent tests after individual failures. New user stacks go into the error
intake process, with exact client/build/context and an isolated reproducer where
possible. USER-001 is the first stack received; frame/action/combat/instance state
remain unknown. Do not ask the user to guess after they answered that they do not know.

<!-- NPQ-FULL-CURRENT -->
Latest full checkout:263/265 standalone scripts PASS;932Lua syntax PASS.
Concurrent unit-frame changes produced two mock failures: `public_geometry_writers.lua`
needs `DeferProtected` in its test double; `raid_party_frames.lua` needs
`SetClipsChildren` in its test double. Both reproduce separately. This quest task
did not edit those owners or tests. Earlier265/265 captures retain their exact
source scope externally. Quest checks311PASS, seven harmful controls rejected;
full current source identities/failures are retained in the quest validation JSON.
<!-- /NPQ-FULL-CURRENT -->
