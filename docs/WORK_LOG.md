# Work log

6 November real-client Current experiment rejected: user output showed pane/
owner/saved1/1/1, changed-field metadata true to false and pane/owner _FluxUI.
BugTabs reported2/2; delayed ordinary native specIconID:535/durationSeconds:929
errors at11:20 prove the route taints native state despite desktop guard passes.
Removed operative test/preflight/securecallmethod block. Both preserved slash
commands are now read-only UNSUPPORTED; no further native experiments. Safe
backend normalized SHA256 `c093068e4e1409f87684e2911ad8cf30874feba89222c8d591bb9ba184e74788`
is byte-equal in all five client copies. 126 no-operation/provenance, 561 ownership
and Core focused checks pass. Safe full 166 scripts / 823 syntax checks passes, unchanged
source hashes/membership, corpus `826008fbce898c35a480e1f3752b1bb86e0eb59e71ecfad0d4c8247d369a8039`.
[Safe manifest](validation/meter-rejected-current-removal-2026-11-06.json). Capture-only at 10:36:31Z verified
Forever PID37088/window/Meter visible; a later reload guard refused before any
input because the game was foreground. No agent reload or memory cleanup pass.
Earlier166/823 experiment remains historical/rejected evidence. Reload must
clear retained native objects before fresh acceptance; no settings/history reset.
Use native OOC session selector immediately left of the cog in each header, then Current, not Advanced AutoReset.
Default Current every existing/future meter remains OPEN/unsupported. Preserve
concurrent glow work. [Decisive native record](validation/meter-current-live-checks-2026-11-06.json).

6 November final header and Current probe: header172/threat87 checks pass five
alternating pairs/ten rejected mutants. The earlier heading144/87 five-pair/
eight-mutant report is retained as its own source stage. Full166scripts/823syntax
passes with unchanged source hashes/membership, corpus
`d53d2e5e0c0390aa18ba620a9ab30e713b221b6b952db16060a2feca9eb085ba`.
Title left anchors/baselines are retained; timer uses public heading width and
remaining menu-bounded space. Header controls/art fit14 display units; embedded
Minimize is hidden/excluded and original native geometry/visibility restores.
The user's later explicit status paste still shows Damage+Healing Overall,
superseding the earlier Current reply. Default Current for all existing/future
meters remains OPEN. Implemented only a separately user-invoked, build/OOC/
provenance-guarded one-view native Current experiment plus read-only status.
127 probe/provenance and 561 ownership checks pass; requested native output is
pending, no automatic default/history reset. Scratch ForceTaint_Strong metadata
is not proof of ordinary addon call permission and changed no native config.
Passive08:31 capture showed Advanced Options/new-instance reset, not two-fight
acceptance; later09:57 capture showed town/Map/bags without probe output. No
extra UI input or agent-initiated reload. Prior misclick and process-visibility
correction remain preserved. External T084055 checkpoint preserves1,586 sources /
177 settings/all-ref history. Concurrent glow work is included in the captured
full source manifest and remains preserved. [Manifest](validation/meter-current-selection-probe-2026-11-06.json),
[header pairs](validation/meter-header-controls-comparison-2026-11-06.json).

6 November Forever SAO follow-up: the user tested the prepared Classic LBG
candidate and still saw button glow only after combat. They requested the
button glow to start with the screen overlay and use modern Retail art. Added
Forever-only immediate combat paint for mapped screen, generic SAO button and
native glow events; pre-acquired Retail LCG ProcGlow frame OOC; retained
Classic fallback. Added a compact diagnostic readout and focused tests.
Desktop checks passed; native result, taint and performance are pending.

The user's next in-combat diagnostic reported `screen=0/0`, `modern=158/0/0`
and no button glow. The first diagnostic command had failed inside its readout;
the simplified readout worked after reload. The screen hook is therefore not
the live signal on this client. Added the global SAO overlay-frame state as a
combat-readable source, one coalesced next-frame aura check and registration
fallback; changed the modern frame to stay shown at zero alpha between procs.
Focused checks pass; a new live test is pending.

The global-frame/alpha candidate also failed in the user's next combat test.
Readout: `screen=0/0 notify=330 modern=158/0/0 failed=0 classic=0 aura=7/1
frame=334`. Aura event dispatch and frame access are present; no button show
was attempted. Requested the live SAO overlay keys, `Want(5143)` and bar
matching counters during the proc before changing the association again.

Live check returned `want5143=0`, no SAO `overlaysInUse` keys. Inspected the
installed SAO native event handlers and Forever source-pinned event payloads.
Connected native screen show/hide to the mapped Arcane Missiles button and
fixed an empty-list state override. Focused fixture covers native 400589,
base/ranked spell IDs and hide; 20 signal checks pass. Native retest pending.

Native-event retest failed: `screen=0/1`, `native=0/15/0`, `aura=1/0`,
`modern=158/0/0`, `want5143=0`, `bars=0/342/0/0`. Installed SAO's Forever
secret overlays use Blizzard AuraContainer, bypassing earlier show paths.
First private-table AuraButton hook candidate also failed live with
`container=0/0/0`. Inspected Forever Blizzard slot registry; the latest code
finds the mapped 400589 AuraButtons through the global AuraContainer even
when SAO's private table cannot be captured. Twelve focused tests pass;
native acceptance pending.

6 November heading follow-up: the user confirmed both native meters now use
Current through Blizzard UI, then specified the timer immediately right of each
window title with titles unmoved. Current setup is user-confirmed; no agent enum,
two-fight or reload acceptance is claimed. No global/history reset was performed.
The08:26 live Threat view showed centered heading/clipped timer, motivating a
placement correction using public heading width out of combat and unchanged
title left anchor/baseline. Revised source/tests are still being finalized.
Earlier134skin/85threat/full162/819 results retain their pre-heading scope.
Concurrent glow work and latest user choices remain preserved.

6 November Forever combat glow follow-up: user specified action bar button
glows in combat and confirmed SAO's Missile Barrage screen overlay appears.
Verified installed SAO 2.8.9's show/hide functions, Era/Forever LBG artwork and
18 matching animation setup calls, and the current Forever process/window
(PID 37088, `F:\World of Warcraft\_forever_\Wow.exe`). Before edits, placed
Glow.lua, test, private settings and verified main-history bundle in a dated
external checkpoint. Hooked SAO screen activation after the original for the
missing Forever Arcane Missiles association; secret or unreadable combat icon
data no longer rejects a known spell face. General SAO/native triggers and
Classic-style LBG paint remain. The user reloaded and retested that first
candidate: no button glow in combat, then glow after combat if the proc
remained. SAO calls cached methods on its private table, so the global-name
hook missed them; the corrected candidate hooks those methods. Standalone
EBS buttons also lacked a glow-change subscription, now routed through the
existing `ebs.glow` eval lane. The user retested that private-table candidate:
still no combat glow, followed by a glow that remained after the proc ended.
Added lower-level global `ShowOverlay`/`TerminateOverlay` post-hooks, which do
not require private SAO capture, and live SAO overlay/fade checks to prevent a
stale marker. The user's next live retest still had no combat glow. Flux's
secure Hosts code forbids first combat child/anchor creation; LBG did exactly
that on first proc. Prepared and retained each LBG frame during OOC button
installation, so combat activation and removal play existing Classic animations
without LBG CreateFrame/SetParent/SetPoint. Prepared frames stay with their
button across paging, with skip-birth on the destination. Focused glow 53,
low-level combat signal 5 and EBS refresh 8
checks pass;
full desktop manifest
at [combat evidence](validation/forever-sao-combat-glow-2026-11-06.json).
The current run passes 164 scripts and 821 Lua syntax files; the saved HEAD
EBS.Init fails the new missing-listener assertion.
No window focus, input, reload or settings changes were made by Codex. The
user's first three native retests failed; the prepared-renderer candidate
combat/clear/visual/taint/FPS and
Era/Anniversary acceptance are pending.

6 November Threat timer/current-view follow-up: published main b6cb2c7 was
clean; external Meter-threat-timer-current-view-checkpoint-20261106T080249Z
preserves 1,579 actual sources /177 settings/all-ref history, archives/bundle PASS,
source SHA256 `403e098a8f63b1a6875e6eff2dc0ff9e5727c6bd8d97a89f497e4ae1fbcee8fd`.
Skin134/threat85 pass five alternating pairs/eight mutants; diagnostics42/
ownership561 pass five pairs/seven mutants. Full current suite passes 162 scripts /
819 syntax files with unchanged source hashes/membership, corpus
`d9a7742aeb101cc26b97d45274365f05831f2a599796628a8d396077499b000d`.
At08:05:58UTC two guarded read-only native commands found Forever70790, native
Damage+Healing Overall0, Details false, Meter active and BugTabs0. Reset-on-new-
instance1 is distinct from per-fight Current1. Three root click attempts were
refused before dispatch. One later attempt posted three targeted window messages
without activation/system input; it used stale menu coordinates despite a changed
stock layout. Later capture showed loading; no Current selection/setting was
verified. Input stopped; view-change cause is unknown. No automatic session
setter, reset, profiler preference change or foreground takeover was performed.
Correction: sandbox process isolation hid the live desktop client; the same
PID37088/window remained live. The earlier closed-client inference was wrong.
Raw historical reports/concurrent glow work remain preserved.
[Full manifest](validation/meter-threat-timer-current-view-2026-11-06.json), [native evidence](validation/meter-current-live-checks-2026-11-06.json).

6 November Forever SAO follow-up: user reported no Forever button glow after
the LibButtonGlow renderer change, with Missile Barrage as a reproducible proc
and all SAO-supported spells/procs in scope. Read installed SAO 2.8.9 Mage
definition and saved glow setting (`enabled=true`), plus Forever native glow and
aura API source. Dated external checkpoint holds pre-edit Glow.lua, private
settings and verified main bundle; no client process was running and no game
input or settings changed. Added a source-backed Missile Barrage aura to Arcane
Missiles rank-aware bridge, guarded secret native API/event values, and changed
player-aura refresh to fire only when that proc changes. Generic SAO/native
membership and bar/Extra/badge renderer remain shared. Focused 41 checks pass;
pre-edit Glow.lua fails the Missile Barrage assertion; full desktop suite passes
162 scripts and 819 Lua syntax files. Native proc, art, taint, frame-time and
Era/Anniversary regression remain pending. [Evidence](FOREVER_SAO_GLOW.md),
[manifest](validation/forever-sao-glow-followup-2026-11-06.json).

6 November native secret failures at 07:45/07:55 (specIconID) and 07:57
(durationSeconds) invalidate a blanket taint-safe claim for prior art/grid stages.
The current candidate keeps visual docking/native controls without
direct Lua data/configuration writers. Missing native pane types require explicit
native-control setup; selected sessions remain native, with no reset/data deletion.
Implemented one topmost/leftmost native timer using physical screen geometry,
original native time text/policy, out-of-combat header layout and combat alpha
election. Writer 26/timer 113 focused checks pass in five alternating pairs each;
5/9 mutants are rejected. Frozen source identities and raw samples are recorded
in [writer evidence](validation/meter-native-writer-comparison-2026-11-06.json) and
[timer evidence](validation/meter-single-timer-comparison-2026-11-06.json).
Final full validation passes 162 scripts /819 Lua syntax files with zero failures;
all 819 source hashes/membership remain unchanged (corpus
`5b008deec37a9e32ebf53442630c19012f9ce52a78ae0e7cc46e900552b2e377`).
[Current manifest](validation/meter-timer-native-boundary-2026-11-06.json). The first full run
failed four stale Core meter assertions; only the fixture contract was updated,
without restoring unsafe production setters. Older reports retain their scopes.
External Meter-timer-and-taint-checkpoint-20261106T072904Z preserves 1,571 actual
source files /177 settings/all-ref history, including concurrent raid/glow work;
ZIP/bundle PASS, source SHA256
`7dc36164c7a5abdd83e66e472990ebd560897fbd39ccc7d0aac6dd76c81d4205`.
At 07:31 UTC no WoW process remained; no controlled fresh reload or new live
candidate/taint/visual check ran. Native commands were not issued this turn.
[Boundary record](METER_STANDALONE.md#current-native-configuration-boundary).

6 November FOREVER-SAO-GLOW-01: verified main `a07c449`, the external
`FluxUI-forever-sao-20261106` source/history checkpoint, installed SAO 2.8.9
source hashes and read-only `glow.enabled=true` setting. Edited only the shared
Glow renderer and a focused fixture; preserved unrelated meter/raid work.
Saved pre-edit source fails the bar-render check; candidate passes 25 checks,
and Bars smoke passes 17,454 refresh checks. Full desktop validation: 819/819
Lua syntax, 160/162 scripts; the failures are in-progress meter Core smoke
and native skin assertions (neither script loads Glow.lua).
No native reload, gameplay, input, profiler or settings change. Native visual,
taint and performance acceptance pending. [Record](FOREVER_SAO_GLOW.md).

6 November raid secret mouse follow-up: user stack at 07:08:57 identifies
`Blizzard/Hide.lua:139`, reached from `FluxRaidLayout.lua:778` while hiding the
native grid. Baseline main `a07c449b1783a7bc876943e5909c3573cfec267a` is
present locally; the dated external Meter-texture-checkpoint-20261106T053635Z
and its verified source/history/settings identity remain recorded below.
On-disk Retail WTF Config.wtf and Flux-named settings were found read-only; no
settings were reset or copied into AddOns. Existing unrelated meter work is
preserved. [Forever 70790 source](https://github.com/Gethe/wow-ui-source/commit/eac30af597e5aaa43a60f6675ef5fdcea100375f)
and [Retail 70783 source](https://github.com/Gethe/wow-ui-source/commit/297d7aaaa736f346b3e036f38ee088eaf7f8c07f)
were checked on 6 November; the pinned Forever FrameScript documentation declares
`issecretvalue`, while SimpleScriptRegionAPI declares the mouse getters as bool.
The supplied native stack proves this particular getter can be secret in tainted
execution; declarations alone do not certify addon access or setter behavior.
The focused mouse fixture passes 2,545 checks across five modeled branches and
rejects 14 mutants; raid startup passes 2,073 assertions. Native secure VM,
hit testing, raid/party/combat/Edit Mode, visual and frame-time acceptance remain
pending. [Implementation and checks](49-native-mouse-suppression.md#raid-secret-mouse-follow-up).
Full desktop validation passes 159 scripts / 816 Lua syntax files with zero
failures; [current source manifest](validation/raid-secret-mouse-2026-11-06.json).
Normalized candidate `Blizzard/Hide.lua` SHA256 is
`901e468da994df71b907ebe51b19916410d6c09622c48212045356723711185b`.
The generated source indexes were refreshed and the read-only documentation
validator passes 849 sources / 14,101 local links. No WoW process was running;
native checks were not attempted.
During documentation refresh, the current uncommitted meter artwork candidate
exposed two stale standalone-threat test anchors (old 32-unit header geometry).
Only those assertions were reconciled to its existing 14-unit header; focused
threat now passes 70 checks. The historical 69-check meter reports below retain
their original source scope. No meter runtime behavior was changed in this batch.

6 November installed-art follow-up: clean main baseline
`a07c449b1783a7bc876943e5909c3573cfec267a`. Verified external checkpoint
Meter-texture-checkpoint-20261106T053635Z preserves 1,561 actual files, 175 settings
including Details and all-ref history; source SHA256
`345f0c8fd943cc0780635ef64a470c0c31f7dddc9898ac382cde22560db527ee`.
A helper initially targeted AddOns; its three verified archives were moved
outside before runtime edits, and mirrored copies were verified absent from all
five clients. No backup/private settings are included in Git.
Read-only inspection confirms Forever Details #Details.20261104.15400.172 and
the source nine-piece atlas/Ground/DGround/Accidental mapping. Code references
installed paths without running providers or copying files; fallback remains.
Final hashes, paired results and candidate native inspection are being recorded.
[Requirement](METER_STANDALONE.md#installed-wow-interface-art-references).

5 November one-line/shared appearance follow-up uses actual pre-style checkpoint
Mail-auction-publication-20261105T215820Z: 1,557 files /160 settings/all-ref history,
ZIP/bundle PASS; source SHA256
`d07305d83bef4f45d4e50ff45a8ace8f0c977f81db57d336fa1a1dba37c779ec`.
The user's multiword-wrap and differing-pane reports justify direct one-line
font layout and shared Friz/ArialN fills/header geometry. No native text values
are read; native data/controls/row pools and canvas scale remain.
Skin 54/threat 69 checks, five paired runs/eight mutants pass against that source.
Native-owner 463 checks pass versus 14 baseline failures, five pairs/five mutants.
All four configured panes paint in ordinary/gamepad fixtures; 1,000 native resets
per fixture restore both sessions, with no new frames/timers/content/policy writes.
The old 68-check integration fixture now checks unique physical window resources
and permanent entry hooks rather than treating paint-call count as ownership.
Final desktop validation passes 159 scripts / 816 Lua syntax files; all 816
source hashes and membership are unchanged across the run. [Full source](validation/meter-theme-consistency-2026-11-05.json). Guard SHA256:
`66cb6ac3bf32f8fb90cf2ca37cd0e0d86b8ef1fa6649a9760d8516b435b4d010`.
Raw font/tab-stage 159/816 and its exact hashes remain historical evidence.
After final native reload 22:06:45.511Z, Meter/builtin 7/profile 0/current BugTabs 0
were retained; Friz 15 titles/ArialN 17.5 rows and name/value wrap false/false were
observed and shared header/panel fill inspected. Final OOC native tab handoff passes; actual owned-threat combat rows were not captured, so combat secret/taint and performance remain inconclusive.
[Style pairs](validation/meter-shared-style-comparison-2026-11-05.json),
[native-background pairs](validation/native-meter-background-comparison-2026-11-05.json).

Final native OOC captures (UTC): reload22:06:45.511; Map22:08:39.557,
Respec22:08:58.688 and Buttons22:09:18.418 all report native=false/threat=false;
returnMeter22:09:39.197 reports true/true. Summary22:10:13.490 reports Flux loaded,
Details absent, currentBugTabs0 and Meter/builtin7/profile0. Validated target-window
background commands used no PC foreground, mouse, keyboard or clipboard control;
no profiling preference changed. [Native metadata](validation/native-meter-background-checks-2026-11-05.json).
Shared header/panel fills were visually inspected. Live owned-threat rows were
not captured during the short fight, only pre/post states; combat secret/taint,
matched pixel parity, memory and FPS remain inconclusive/unmeasured.

Earlier font/tab-stage evidence (its native pending notes are superseded by final OOC handoff above):

5 November threat font/quiet-state follow-up: baseline
`db42efb10efb0d39cf991dacc27db606000ad7b3`. Verified external checkpoint
Mail-auction-publication-20261105T213107Z preserves 1,554 actual files, 160 settings
and all-ref history; ZIP integrity and bundle verification pass. Source SHA256:
`a6ffa0fee4832870a4ba2dd20c3f6afc1c2363e8f787be4ed78e5bc2558b8132`.
Font-before-text corrects the exact construction error and permits later geometry
cleanup. Percentage-first readable ordering and combat-only rows match the
intended threat presentation. Focused 65 checks, five original matched pairs,
five font-ready reference pairs and nine rejected mutants pass.
[Raw comparison](validation/threat-font-readiness-comparison-2026-11-05.json).
Full desktop validation passes 159 scripts / 816 Lua syntax files; all 816
source hashes and membership are unchanged across the run.
[Full source manifest](validation/meter-threat-readiness-2026-11-05.json). Native acceptance for that earlier font/tab source was pending; final OOC handoff is recorded in the shared-theme stage above.
Native Forever 1.60.1/70790/interface16001, Details absent and scriptProfile 0 are
observed; Map reload/session FXERR0 and layout 8 construction are partial checks.
Current combat, pixel/taint and performance acceptance remain pending.
The native font-candidate pane constructs fully with ARIALN 15 OUTLINE. Normal
Map/Respec/Buttons handoff then reproduced native-hidden/threat-visible overlays.
Checkpoint Mail-auction-publication-20261105T215012Z preserves that actual font
candidate and records: 1,555 files, 160 settings and all-ref history; integrity PASS,
source SHA256: 6616a4f3a12864b60b2a999923631943cc0b3c313459834b0abdd6eaa7d60f08.
An explicit addon hidden latch now covers onHide-before-activeTab-update ordering.
The final owner regression passes 429 checks versus 19 failures; five alternating
pairs/four mutants reduce 4,000 threat/1,000 root resurrections and 1,000 mixed-Always
repair wakes to 0, with no frame growth/content walks/policy writes and native
timer dispatch retained. [Handoff pairs](validation/native-meter-tab-hide-comparison-2026-11-05.json).
Root and threat runtime SHA256s are 07acfae4ed9090c8e6226e140062e254cfef9ec8ca6fca64033ee71228750a8a
and 478d82e865a9b49ccf720e60b50b7aa66154c9eabd44c2f0ab41a4be268f7cc7.
Final 816-file source guard: 6147668476e15329af4ee536ea2c047296d74a7f9b225649520d948c549a2c32.
No shared skin or 112% canvas change is included; native post-fix handoff/combat
and performance results remain pending.

5 November standalone native meter: feature baseline
`8006494fd5f10b54818471933467b9bb867c6543`. External checkpoint
Mail-auction-publication-20261105T203228Z preserves 1,537 actual files, 122 on-disk
settings and all-ref history; source SHA256
`efe44322cd86f787161b91509af8f63cf4709fdfdeaef72e6f6f750c51b5a537`.
New shared skin and Forever-only independent threat view reuse existing services
and Flux/Blizzard assets. Existing native preset/default IDs remain; three opt-in
threat presets and a maximum three-native-plus-one-owned grid are added.

Final publication preparation: final runtime/manifest bytes match all five
synced client folders (7/7 each). External Meter-native-
settings-20261105T212227Z supplements recovery with 38 native meter/Edit Mode
tables and layout caches; ZIP integrity passes, SHA256
210a34953ed1a01433edd268ec9353d68a10b02d2fc17722e9dea516113b4c9a. Unsaved game
memory excluded. Existing validated wand/cast-bar work is preserved separately
as 92dfb49. These checks used no game input or settings mutation.

Skin 47 checks/five alternating pairs/six mutants pass. Standalone threat 51 and
coherent-sample 510 checks pass with five pairs/11 mutants. Shared sample queries
fall 1,000 to 500 per 500 rows. New skin/pane allocation is reported as feature cost;
500-event bursts coalesce one scan and 80 roster/pet facts remain intact.
[Skin samples](validation/meter-skin-comparison-2026-11-05.json),
[threat samples](validation/standalone-threat-comparison-2026-11-05.json).
Final desktop validation passes 159 scripts / 816 Lua syntax files; all 816
normalized source hashes and file membership match before/after the run.
[Final source manifest](validation/meter-standalone-2026-11-05.json).

The user's empty-tab checkbox diagnosis led to METER-ENABLE-01: native-backend
startup/tab/embed/Show may enable only the public damageMeterEnabled option out
of combat; native events and natural addon readiness remain native. No private
visibility/cache writes, native manual timer update or addon load was added.
Concurrent wand/cast-bar code and continuity entries are preserved separately.
Before the docking follow-up, external checkpoint
Mail-auction-publication-20261105T205512Z preserved all 1,549 current dirty files,
122 settings and all-ref history, source SHA256
`c01241bfe2564ab2baabaecd4023dd06c4c17193fb211e86b3f45e1276a24b32`.
METER-OWNERSHIP-01 now gates native panes before the first Embed;64 checks pass
versus 22 failures in actual T205512 source, five pairs/four mutants. Docking
repair uses native widget aliases, coalesced post-native geometry restoration
and deferred combat cleanup;60 checks pass versus 30 T205512 failures, five
pairs/11 mutants. The 500-burst test schedules one wake per plain/gamepad fixture;
fixture frames stay 4, addon snap writes 76 to 0, native callbacks 4,064 to 4,072.
This adds repair work, not a native performance gain; no extra type/session
setters or entry walks occur. The 22:04 CET user screenshot establishes the
pre-embed Map/floating failure, not the candidate's loaded identity.
[Startup comparison](validation/meter-startup-comparison-2026-11-05.json),
[docking comparison](validation/meter-reload-docking-comparison-2026-11-05.json).
Earlier 68-check feature/enable pairs retain their preDock source identity;
the final 816-file manifest covers the current runtime and all preserved user
changes, including separately committed wand/cast-bar work 92dfb49. Source guard
SHA256: 376815eacb8a9a89cb3cd8b306c482dab0601f73111cdc39dba5e61fcb947cec.
No new native input, reload, profiling or screenshot comparison occurred; all
combat/taint, art/font, frame-time and memory acceptance remains pending.
[Full feature scope](METER_STANDALONE.md).
One background-only capture at 21:56:22 CET verified the same Forever PID 39984
and an in-world Map tab. Meter docking was not visible; loaded code/build was
not queried. No focus/input/reload/profiler change occurred. This single view is
not meter, combat, pixel or performance acceptance.

5 November wand swing theme: started from main `72704d19` with an external
dated source/history bundle and read-only confirmation of Era, Anniversary and
Forever on-disk `Config.wtf`. Pinned Gethe commits `4192ac6`, `68e0a2e` and
`eac30af`. The shared cast renderer accepts an explicit wand-school mask; the
equipped ranged item supplies it from localized damage text, with cold-item
retry and unchanged-item caching. The ranged strip is a StatusBar and its
trough matches the player cast bar. Existing swing timing, cast priority and
settings remain. Focused 13,942-check desktop fixture and full validation
pass; native rendering, combat taint and matched performance remain pending.
[Source and exact identities](SWING_WAND_CAST_THEME.md).

5 November damage meter combat visibility: clean baseline
`72704d19cec2190495acb51d0ab82659e945d71a`. External verified checkpoint
Mail-auction-publication-20261105T202207Z preserves 1,534 actual files, 122
available on-disk settings and all-ref history. Source ZIP SHA256:
`10f43e0b24068defd30e84f170beeb1ab50537a14f7b4acd70c70296959cb946`.
Archive integrity and history verification passed; unsaved game memory excluded.

The user's 21:18:13 stack matches Forever's native secret-duration comparison at
line929. Flux's forced visibility field is read by the native combat event before
the timer traversal. The earlier mock omitted that initial field and traversal.
The follow-up removes the native policy write, checks native visibility before
showing, and retains the Flux host/tab boundary and native timer/entry methods.
Native visibility settings now govern the embedded meter instead of forced Always.
[Exact sources and regressions](METER_COMBAT_VISIBILITY.md).

Focused native-function replay passes 332 checks versus 80 baseline failures / 332.
Five alternating pairs per pinned Retail/Forever source (ten total) and six
rejected mutants pass; native event/timer/text-update counts remain unchanged.
Full desktop validation passes 153 scripts / 808 Lua syntax files; all 808 source
hashes and file membership match before/after the run.
[Full report](validation/meter-combat-visibility-2026-11-05.json).
No game input, foreground, profiling, settings or external addon changes were
used. Native combat/taint, pixels and performance remain pending on Retail and
Forever; other clients retain Details/capability absence. Prior native checks
predate this candidate and cannot establish its acceptance.

5 November minimap mail lifecycle and Retail tooltip readiness: baseline
`c1a5f901467ff5015938442c74580d6d4781cbaa`. Verified external checkpoint
Mail-auction-publication-20261105T194013Z preserves 1,529 actual files, 122
available on-disk settings files and all-ref Git history, including the pending
tooltip work. Source ZIP SHA256:
`a6fb41fd4042442bd9d9c6d5c70320fe9001feadd068312e3b328d0dfb694449`.
Archive integrity and history verification passed; unsaved game memory is
excluded. The minimap production-function replay reproduces 500 frames from
500 layouts and 1,024 from ten unchanged mail events. Reusing the named fallback
retains one frame without changing appearance, native preference or cadence.
Reload is required to discard previously accumulated frames.
[Minimap evidence](MINIMAP_MAIL_LIFECYCLE.md).
Focused 504 checks pass versus 100 failures / 494 baseline attempts; five alternating
pairs and five rejected mutants pass with identical resource counts.
[Raw comparison](validation/minimap-mail-lifecycle-comparison-2026-11-05.json).

The separate Retail tooltip guard passes 48 checks versus six baseline failures;
five alternating pairs reproduce 1,002→0 errors and four semantic mutants are
rejected. Existing active-row checks pass. Combined validation passes
153 scripts / 808 Lua syntax files with an unchanged
808-file source drift guard.
[Full report](validation/minimap-mail-lifecycle-2026-11-05.json),
[tooltip evidence](AUCTION_COLD_TOOLTIP.md).
No game input, foreground control, profiler/settings changes or external addon
edits occurred. Historical 19:15 Forever source/reload checks predate both changes.
Native transactions, flicker, pixels, taint and performance remain pending;
the user's whole-game freeze is not yet accepted as resolved.
Read-only host inspection around 19:45 UTC confirmed the same Forever PID39984;
both runtime candidates matched byte-for-byte in all five synced client folders.
Minimap SHA256 `448c762562c5bb2d62aeca43139d1ca5e42eb56b41ad86f4254caa34f78d670a`;
AlreadyKnown SHA256 `ee9042d3a8e3cb6dec70f7658b355b9595ce84b1e80803fbd81f97dd578db6f1`.
This is on-disk parity, not loaded-candidate or native operation acceptance.

5 November provider row reuse: baseline `7f47a566e573a132dcac4a0e67f8b590cee8d08a`,
Adapter SHA256 `d242e0c07e789197335bde1d0deb27586c41b6fad24560add6846452408df561`.
Verified checkpoint Mail-auction-publication-20261105T183839Z preserved 1,520
actual files, 122 on-disk settings and all-ref history, including newer consumable
work subsequently committed as `e2c6464`; source ZIP SHA256
`b3a39827bbd2e50cc271fce7c5930ea80b1174e3215bc42105b380d36523f55f`.
Only adapter `FillFromList` now reuses matching immutable rows in complete maps.
Focused candidate passes 700 checks; baseline fails 190 of 700. Five alternating
pairs and five rejected mutants pass. Per-region 500 appends construct
125,250→500 rows; source visits remain 250,500. Index-shifting cancellation
constructs 250,000→125,250, stable-suffix cancellation 250,000→500 and clears
250,000→0. Full validation passes 151 scripts / 806 syntax files; the complete
806-file source drift guard matched before/after. Independent review passed
700/210/365 checks and 13 extra edge cases.
[Raw pairs and source hashes](validation/provider-snapshot-row-reuse-comparison-2026-11-05.json),
[full report](validation/provider-snapshot-row-reuse-2026-11-05.json),
[tradeoffs and native steps](PROVIDER_SNAPSHOT_ROW_REUSE.md).

No new native input or profiler change was used for this adapter slice. The
approved Forever reload at 19:15 predates it; source Syndicator/profile0 and all
three loaded addons were subsequently verified with empty caches, without a
transaction test. The user-confirmed 19:18:25 logger error came from an incorrect
diagnostic API probe. Native acceptance remains pending. The private Syndicator
patch is still under review outside Git; installed external files are unmodified
and applying that proposal requires authorization under the read-only rule.

5 November Consumables timer: verified baseline `2c0e7b8`, external all-ref
history checkpoint and on-disk settings before editing. The old button and
config timer ran to full buff expiry after the item had become eligible at
the refresh threshold. Shared refresh deadline now drives button digits,
wisp swipe, and config cell swipe/digits. Five baseline/candidate pairs pass;
full worktree validation passes 150 scripts/805 Lua files. Native checks
pending. [Case record](CONSUMABLE_REFRESH_TIMER.md).

Preserved newer main commits for consumable visibility and bank charge iteration
through `2c0e7b8`. All then-current normalized Lua hashes/file membership match their
combined passing 149-script/804-Lua report; the earlier 147/802 snapshot result
is not relabelled. New external recovery Mail-auction-publication-20261105T183217Z
preserves 1,519 actual files, 122 settings and history including all pending work,
source SHA256 `eb8e2855cc54ad55cfa43a670b4b4d1957f0ffa6c3d6c424c8dbef3ba10d3557`.

5 November native stack follow-up: user trace at 19:19:57 identified
`FluxRestockList.lua:1307` calling missing `FluxRestock.Inv.Bank.ForEachSlot`
while the Consumables config grid queried charges. Verified baseline main
`d71f2b9`, external all-ref history checkpoint and on-disk settings. Switched
to the supported open-stack iterator with character/warband options. Five
baseline/candidate loaded-module pairs pass; full worktree validation passes
149 scripts/804 Lua files. Native fix confirmation pending.
[Case record](RESTOCK_CHARGE_BANK_ITERATOR.md).

5 November consumable config visibility: verified published main `437fda7`,
external all-ref bundle, worktree copy and four Retail/Forever on-disk settings
files before editing. Fixed deferred item save and button-first refresh in the
shared config. Five baseline/candidate desktop pairs pass eight checks each;
full validation passes 148 scripts and 803 Lua files. Native client checks
pending. [Case and hashes](CONSUMABLE_TARGET_DETECTION.md).

5 November renewed report: each Buy or Cancel adds lag to the next operation.
Added explicit operation-count and retained-resource curves to the flow scope;
source/provider audits continue separately from the validated snapshot batch.

Approved native check: Forever70790/interface16001, FluxUI/Syndicator/Baganator
all loaded, source Syndicator, profiler0. Candidate files byte-matched and reloaded
19:15:51 CET; source/marker/profile0 verified19:17. Mail/auction caches0/0 at19:18.
No transaction, profiler toggle or enable change. BugTabs1.4.9 owns capture;
an incorrect BugGrabber method query caused a probe error, not a runtime regression.
Previous foregrounds restored when changed; captures remain private. Transaction,
freeze, rendering, taint and leak acceptance remain pending.

5 November snapshot preparation, desktop validation complete: verified baseline
`437fda79136582282dde0f3989f3cb70c4411bad` and external checkpoint
Mail-auction-publication-20261105T173546Z (1,503 actual files, 122 on-disk settings,
verified all-ref history), source SHA256
`4921e61d4bce4f648bd95b428f7a0acea9eb11dfc99b0c66d1d5b32fd9a31f48`.
Moved built-in mail/auction snapshot preparation inside existing scan budgets,
with private completed maps and atomic publication. Consumer inspection supports
the intentional internal-map identity change; region objects, public Index APIs,
original equality/cadence and publication counts remain. Auction replay passes
5,884 checks versus baseline 144 failures in 5,436; peak metered work 5,216→104,
unchanged fingerprint visits 10,240→0, getter-reentry errors 20→0, publications
20→20. Mail replay passes 8,194 checks versus baseline 25 failures in 8,203.
Arrival normalization remains 1,600 records, with peak per-update constructors
1,600→46; five unchanged scans retain all 8,000 capture rows but fingerprint
fields fall 8,000→0 and normalization stays zero. A quantity change normalizes
1 record instead of 1,600; old-map clears fall 1,600→0 on that change and on the
last two money-only messages. Ten alternating pairs and eight rejected mutants
pass. Full validation passes 147 scripts / 802 Lua syntax files; all 802 current
normalized hashes match the manifest. Independent review accepted both sources
and reentry guards. [Raw comparisons and candidate hashes](validation/builtin-publication-comparison-2026-11-05.json),
[full report](validation/builtin-publication-2026-11-05.json).
No native freeze, latency, allocation-byte or FPS claim.
External Syndicator 289 cold-post callback/retry failure was reproduced read-only
and left unchanged; it does not explain unloaded-provider freezes. No game input,
profiling or enable-flag change was used. [Flow scope](MAIL_AUCTION_REWORK.md),
[mail preparation](BUILTIN_MAIL_PUBLICATION.md),
[auction preparation](BUILTIN_AUCTION_PUBLICATION.md),
[external evidence](EXTERNAL_SYNDICATOR_POSTING.md). Money-update cost inspection
is a separate read-only finding; no money-path runtime change was made.

5 November publication: ordinary push to main completed for runtime
`7a06b85f633d1945b7d6bf615636f486f3d7e627`, tree
`4e31f10131923c3d002faffe8036e631d1537402`; remote read-back matched and
the working tree was clean. All 800 Lua files match the tested manifest.
This final publication record changes documentation only. No native acceptance
is implied by publication or synced on-disk files.

5 November lifecycle follow-up: verified published main baseline
`e860ce6de499a7702b91e8a8d74f115fbc9e0293` and external checkpoint
Mail-auction-lifecycle-20261105T171132Z (1,496 actual files, 75 on-disk settings,
verified all-ref history), source SHA256
`38c16e1f0d1d928ffb6015a89ad10e78f991dc038d0d738f7d3483ace86a0e5e`.
Fixed duplicate/reentrant built-in auction queries and queries after provider
handoff, final-mail job cancellation and work after owning-module disable.
Auction candidate passes 628 checks; baseline fails 72 of 1,330 dynamic checks.
Duplicate queries 714→10, foreign-provider queries 700→0 and reentry queries
278→10. Mail candidate passes 880 checks; baseline fails 330. Disabled requests
90→0, disabled readiness reads 810→0 and missed final cancellation 20→0.
Ten alternating baseline/candidate pairs and eight rejected mutants pass;
full validation passes 145 scripts / 800 Lua syntax files. Counts are mocked operations, not native
latency or a freeze cure. [Raw comparisons](validation/mail-auction-lifecycle-comparison-2026-11-05.json),
[flow coverage](MAIL_AUCTION_REWORK.md), [queries](AUCTION_QUERY_OWNERSHIP.md),
[mail lifecycle](MAIL_JOB_LIFECYCLE.md).

Background host inspection found the prior PID47424 gone and Forever PID25172
started at 17:55 CET. Its candidate identity is unverified; the historical unloaded
probe still does not establish the state during reported freezes. No game input,
profiling or addon-enable mutations were used this batch. Preserve profile0 and
background operation. Native freeze attribution and all-client acceptance remain
pending. Prior three inventory fixes are already published in main `e860ce6`.

5 November built-in inventory phase: baseline `b664bb0b93ac566a34744aec5895e927a7a1ffff`
already committed/pushed to main contains the prior five contract fixes. Verified
external Builtin-inventory-20261105T152153Z checkpoint:1,488 actual files,75 on-disk
settings and all-ref history; source SHA256
`c2a7f2c073d38a90133cff6e5fc494164430338149ef65343ca61ab507ca537a`.
Added bounded/coalesced built-in item loading with late/unknown-slot ownership,
all-zero summary pruning and defensive modern currency termination. The final
corrected fixtures pass790/81/512 checks; five alternating pairs each (15 total)
and12 rejected mutants, plus full143 scripts /798 syntax checks, pass.
Modeled requests/waiters10,000→10, dirty marks/pulses10,200→20 and ambiguous retained
IDs10,020→20. Summary rows2,000→1, zero rows1,999→0 and visits1,999,000→5,998.
Repeated currency replies change13,000 queries/no completion to400 queries/200
completions; actual native bad replies remain unverified. These are desktop
counts, not native CPU, memory-byte, frame-time or freeze-removal measurements.
[Raw comparisons](validation/builtin-inventory-comparison-2026-11-05.json),
[full validation](validation/builtin-inventory-2026-11-05.json),
[item data](BUILTIN_ITEM_DATA.md), [summaries](INVENTORY_SUMMARY_PRUNING.md),
[currency](GOLD_CURRENCY_ITERATION.md).

Earlier native evidence: the user reports re-enabled FluxUI and continued whole-
game freezes on sold auctions, cancellation-to-mail, individual mail items and
Open All's second-last/final transition. The only verified active Forever process
was PID47424. At17:35 CET FXBUILD showed legacy/nil source revision/profile0 and
Syndicator false;17:37 FXLOADED was false/false, FXCLIENT1.60.1/70790/16001 and
FXGLOBALS nil/nil. The observed unloaded client conflicts with the reported
enabled state; final revision20261105.1 and all three changes are native-pending.
No addon flags were changed, no profiler1/heavy frame capture was repeated and
the previous foreground was restored. Private images remain outside Git.

Earlier published phase: the native mail-command guard prevents progression/completion
while C_Mail reports pending, with bounded8s wait and existing cadence retained.
Five matched desktop pairs reproduce360 to0 unsafe requests and40 to0 premature
completions; three mutants rejected. Final full validation:140 scripts /795 Lua
syntax files pass. Earlier139/794 evidence describes the preceding four-fix tree.
The user still reports live sale/mail freezes, including Open All at Processing
Message2 and final mail; no live cure is claimed.
[Guard, source contract and pending native checks](MAIL_NATIVE_COMMAND.md).

5 November follow-up: preserved clean main `8681672` in external
Raid-mail-followup-20261105T132922Z (1,476 actual source files, verified all-ref
history, 127 on-disk Flux settings files). Fixed incomplete raid readiness,
duplicate/stale mail wakes, hidden/disabled mail availability work and quadratic
progressive Syndicator auction rebuilds. Five alternating baseline/candidate
pairs per scenario repeat unchanged counts; 290 raid, 3,140 mail-worker, 380
mail-availability and 365 auction checks pass. Eight mutants are rejected; full
139 scripts / 794 Lua syntax checks pass. Read-only host inspection corrected
the sandbox-limited no-client inference and captured Forever without changing
foreground. Its saved UNKNOWN event predates baseline 868; the fresh user report
contains only reporter execution-limit warnings at 14:53:50, 15:03:09 and 15:27:44.
The user clarified Syndicator is not loaded in this failing runtime; installed
289 is reference evidence, not an enabled-addon observation. Built-in inventory
and the initial warning remain under investigation. No native lag/taint acceptance
is claimed. Approved Forever reload succeeded15:32:54CET; read-only commands confirmed
1.60.1/build70790/interface16001, FluxUI loaded, Syndicator unloaded, raid ready
and scriptProfile0 unchanged. No current-session errors printed at15:35:48.
Saved old history has reporter-only counter50; private four-file archive verified.
A split chat attempt activated shortcuts; atomic final commands succeeded and
restored the previous window. No controlled lag/combat/transaction pass claimed.
The user then confirmed the same freeze after reload. Optional scriptProfile1
reload completed15:41:45 and a 60s CPU capture began15:42:20; a reported crash
while opening many auction mails ended PID38964 and replacement PID33872 started
15:48:36. No new Errors/Logs crash report was found. Capture was lost before save,
so no benchmark was obtained. Restored scriptProfile0 plus reload15:50:55;
15:51:34 chat verified FLUXCLEANUP0 true false. Literal-only comparison against
the private archive preserved the original nil capture root. Previous foreground
restored; no profiling cleanup remains and the foreground exception is complete.
New external native-command-baseline checkpoint at14:53:38UTC preserves1,484
source files and verified settings ZIP; original Git history stays at8681672.
The next native command-pending guard is pending; the 139/794 count above covers
the completed four-fix batch only.
[Raw evidence](RAID_MAIL_AUCTION_FOLLOWUP.md) and
[native mail/auction source comparison](NATIVE_MAIL_AUCTION_REFERENCE.md).

5 November: read all 17 supplied errors (15 Forever icon warnings, two UNKNOWN
header blocks); preserved clean main aa253cc and all newer consumable work in
Meter-header-errors-20261105T125630Z (1,471 files, verified Git history, 127 on-disk
settings). Removed meter renderer interceptions and redundant geometry refreshes;
retained tint/layout. Fixed raid precreation visibility/capacity. Five alternating
pairs, 330 focused checks, five rejected mutants and full 136 scripts / 791 syntax
pass. Documentation passes 824 sources / 13,746 links after correcting a stale
command source line. No game input or settings/profiler change. Native warnings
and UNKNOWN attribution need post-reload acceptance.
[Source hashes, raw samples, tradeoffs and native steps](METER_RAID_NATIVE_OWNERSHIP.md).

5 November: verified main a6cc94d and closed Retail on-disk settings;
created/verified an external all-ref Git bundle and copied account/character
Flux settings outside AddOns. Fixed staff-restricted consumable targeting,
effective button counts, equipment refresh and tooltip explanation while
retaining restock's physical counts. Five fresh baseline/candidate pairs
reproduce/reject the wrong dagger target; 30 focused checks and full 134/789
desktop validation pass. No native interaction or profiler change.
[Source hashes, raw pairs, and native checks](CONSUMABLE_TARGET_DETECTION.md).

5 November: preserved clean main 2dd6cfd in external
Hidden-inventory-work-20261105T121000Z (1,462 files, verified history, 123 on-disk
settings). Reproduced hidden-parent protection/paint work; corrected filtering,
skin root discovery and final-layout reveal refresh. Five matched pairs stable;
260 Baganator / 65 default-bag checks pass, six mutants rejected. Initial core
smoke literal-call check failed after aliasing and was generalized; final 133
scripts / 788 syntax files pass. No native/input/settings/transaction control.
[Raw results and pending acceptance](HIDDEN_INVENTORY_WORK.md).

5 November Syndicator mail/auction snapshots: unchanged mail now compares
normalized records without sorted fingerprint strings; unchanged auction callbacks
retain records/count maps and skip FluxUI publication. Link-only mail metadata now
updates correctly. Five matched desktop pairs:500 sorts/500,000 string keys,
500,000 auction row replacements,500 maps and500 pulses become zero for the
synthetic unchanged burst.80 checks pass, three mutants rejected; full131 scripts/
786 syntax pass. Real changed lists still publish at the original cadence; native
Forever Baganator+Syndicator lag attribution/improvement remains pending.
[Evidence and next checks](MAIL_AUCTION_GUARDS.md#snapshot-change-checks).

5 November mail/auction safeguard: user reports Forever lag with Baganator840
and Syndicator289 on mailbox open/close, auction buying and sales; cannot run
native captures and requested safeguards. Resolved owned item-data completions
now notify consumers once, preserving explicit refreshes, incomplete metadata and
parser retries. Five desktop pairs: stable duplicate burst4,000 junk callbacks,
8,000 selector invalidations and2,000 Baganator timer creates/cancels become zero.
140 checks pass, three mutants rejected; full130 scripts/785 syntax pass.
Actual lag attribution/native improvement remains unverified.
[Evidence and remaining checks](MAIL_AUCTION_GUARDS.md).

5 November clarification: Forever retains Blizzard's ProfessionMicroButton.
Only FluxUI's custom trade-skill buttons, flyout and related options are disabled.
Removed the native-button exclusion/parking added in the preceding batch; the
normal discovery/configuration path restores it without a settings reset.
Adventure Guide remains hidden. Five matched desktop pairs: baseline2 failures
versus0 of54 checks; custom service startup frames remain unchanged (zero per
Forever model). Full129 scripts/784 syntax pass; native bar click/pixel/taint
acceptance remains pending after reload. [Evidence](17-micromenu.md#forever-native-profession-button-restored---5-november-2026).

5 November Forever trade-skill micro removal: the module now exits before
creating buttons/flyout frames or registering scans/events on Forever. The native
ProfessionMicroButton is excluded and parked through the existing micro menu
policy; trade-skill option controls are omitted only there. Saved profession
preferences remain stored; other clients and native profession access stay.
Focused48 checks pass (baseline10 failures); five matched pairs remove4 startup
frames per Forever model, with no startup event/timer work. Full129 scripts/784
Lua syntax pass. Native menu/config/pixel/taint confirmation pending after reload.
[Evidence](17-micromenu.md#forever-trade-skill-micro-removal---5-november-2026).

5 November Forever native bank and micro menu: at the user's request, Forever's
Blizzard bank is excluded from window movement, bank-frame latch scripts, bank
junk/item decoration and native restock-button attachment. Bank tracking remains
on existing BANKFRAME/PIM events; carried-bag and optional Baganator features stay.
The supplied PurchaseBankTab stack confirms a protected native first-tab path,
not the original taint writer. Guide button EJMicroButton is excluded only from
Forever's micro menu via the existing eligibility/parking paths. Focused checks:
168 native-bank and34 guide checks pass; baseline36/8 failures. Full129 scripts/
784 Lua syntax pass. Native bank opening/purchase/taint and guide pixels pending.
[Bank evidence](FOREVER_NATIVE_BANK.md); [micro menu](17-micromenu.md).

5 November Forever reputation click fix: the user confirmed the native
ToggleCharacter("ReputationFrame") call opens Reputation out of combat after
WoW's custom-script prompt. Both bars now call that API directly; the wrong
CharacterMicroButton overlays and Forever early return were removed for these
bars only. Combat guard, other client behavior, tooltips and other proxies remain.
Five desktop pairs: baseline18 failures versus0 of180 checks; full128 scripts/783
syntax pass. Final native bar clicks/taint/gamepad checks remain pending; no
/run macro or confirmation popup is introduced by the addon.
[Evidence and native checks](FOREVER_REPUTATION_CLICK.md).

5 November auction opening regression: the user's Retail stack showed Update
running before the ScrollBox view exists. Both modern highlighting variants now
check GetView before iterating; later initialized updates still paint normally.
The real delegate contract reproduces20 baseline failures versus0 of156 candidate
checks across five client/two provider labels. Five matched pairs retain600 active
visits/200 classifications; no new timers/events. Full127/782 passes; native
reopening and the original Buy spike remain pending.
[Reproduction and evidence](AUCTION_PURCHASE_REFRESH.md#view-initialization-regression).

## 2026-11-05 - auction metadata fan-out

Verified clean main at6d4ceba and dated external source/history/settings
checkpoint Auction-metadata-20261105T081044Z before runtime edits. Traced the
shared global item-data handlers and reproduced unnecessary bag/bank name
harvests, unsolicited session-cache growth and selector/junk invalidations.
Narrowed event ownership while preserving explicit API, cold retries, static
consumers and immediate reagent finalization. No external addon changed, game
input taken or profiler preference modified. Native Buy latency remains pending.

5 November auction metadata: global cache events no longer harvest all bag/bank
names or populate classification records for unrelated auction items. Requested
metadata, failed-load retry, static consumers, explicit completions and immediate
name-only reagent/restock updates are preserved. Five matched desktop pairs:
280,000 name reads and 2,000 container walks become zero for the unrelated burst;
230 checks pass, three mutants rejected; full 127 scripts/782 syntax pass.
The native Buy spike still needs attribution/acceptance across both providers.
[Evidence and next captures](AUCTION_METADATA_WORK.md).

## 2026-11-05 - auction refresh traversal

Verified external source/history/settings recovery at Auction-buy-20261105T075700Z
before edits on clean main24cffd22. Read external Syndicator289 read-only.
5 November auction Buy investigation: active-row highlighting uses the native
view instead of the retained child pool. Five matched desktop pairs:200,600
versus600 traversal visits;200 classifications unchanged;116 checks pass and
two mutants rejected. Full126/781 passes. Native Buy spike and every client/provider
integration remain pending. [Evidence and steps](AUCTION_PURCHASE_REFRESH.md).

## 2026-11-04 - Postal-like mail conveniences

Read repository continuity, Postal v4.3.4 and five local Blizzard mail source
mirrors. Verified a clean main at `1b319d19aa00fffa7e798a66d045e55902af6706`,
made a dated Git bundle outside AddOns, and privately copied 20 available
settings files outside AddOns while no WoW process was visible. The CurseForge
source page and installed license both say All Rights Reserved; no Postal code
was incorporated. The user chose direct UI implementation and explicitly
allowed use of FluxUI inventory services.

Added nine Flux-owned mail modules and an additive `FluxMailDB` root. The
Postal-shaped Open All button delegates to the native take APIs through a
single confirmed action worker; the native Open All button is restored when
the module is disabled. `GetInboxText` invoice is the fifth return, correcting
the outdated Postal assumption. Included category attachment, expiry action,
trade blocking with CVar restoration, module submenus, speed/free-slot options
and named profile snapshots. The full desktop runner passes 122 scripts and
777 Lua syntax files; the generated source inventory was rebuilt. No client
was launched or foregrounded, no game preference was changed, and no native
performance or taint result is claimed. Open requirements and client steps are in
[MAIL_INTEGRATION.md](MAIL_INTEGRATION.md).

User follow-up: the top and Open All dropdowns were not working as expected,
and Select reported completion while leaving attachments. Split the dropdowns
into two menu frames with level-specific routing; restored the Retail menu
button frame level and keep the custom Open All above native redraws. Fixed
the worker to scan all receive slots, including sparse high slots, retry
delayed item metadata, and report remaining mail. Added Shift range and Ctrl
sender selection. Rechecked local Blizzard dropdown/item APIs for Retail,
Forever, Era, Anniversary and MoP; desktop tests cover the shared paths but
native client behavior remains pending. The full 122-script/777-file suite
passes after the corrections.
The user then reported the top arrow still had no usable mouse hit area.
The button now explicitly enables mouse input, registers left-button release,
uses its exact 25x25 hit rect and sits above mail title/close chrome on every
client. The direct button click is covered by a focused desktop test. No WoW
process was visible for native pointer verification.

## 2026-11-04 - Era/Anniversary combined bank

The user requested a bank equivalent of Flux's combined bag, bank bag slot
visibility and purchases, then clarified that Baganator must own both views
when loaded and bank bag slot clicks must never toggle separate bags. Read
continuity/specs, checked the clean main tree, verified the dated external
source/history bundle and on-disk Era/Anniversary settings, and inspected
Gethe's loaded Vanilla/TBC bank paths. Added a ten-column bank window with
native item buttons, purchased bag contents, native slot row and purchase
footer; late Baganator handoff restores original native parents/scripts.
The user's subsequent native trace showed a newly equipped bank bag could
cause Blizzard `ContainerFrame_GenerateFrame` to anchor an item still hosted
by Flux. The opener now returns hosted buttons before opening missing bank
bags and rehosts them afterward. The full-slot state also hides the purchase
button and next-slot cost while retaining current gold. The bank restock button
now anchors beside the new window's bag slot row and returns to Baganator's
view on handoff. Focused Era and Anniversary models pass 33 checks each;
the full desktop suite and native status are in [evidence](CLASSIC_COMBINED_BANK.md).
Native visual, input, taint and performance acceptance remains pending.
Published the complete validated payload to main as
`410f32e3adb29addbe0380952f5caf0b99522bfd`; GitHub main readback matched.

## 2026-11-01 - dim passive equipped trinkets

The user clarified that a trinket without an on-use effect must be dim. The
previous fixture explicitly expected passive trinkets bright. Read current
continuity/source and on-disk settings; verified a dated external source/
history checkpoint and copied closed Retail config outside AddOns. Added a
passive check in the equipped-face paint path and updated the loaded-paint
fixture to distinguish passive, ready on-use and unusable on-use. Baseline
fails at passive; candidate passes 10 focused checks and the isolated
112-test/757-Lua desktop suite. Native acceptance pending.
[Evidence](TRINKET_EQUIPPED_USABILITY.md).

## 2026-10-31 - restore ready equipped trinket color

The user observed that equipped trinkets with a use effect stayed dark while
alive and off cooldown after the combat-grid tint update. Read continuity,
the shared painter and trinket owner; preserved ongoing unrelated chat and
cast work; inspected settings and verified a new external source/history and
closed-client settings checkpoint. The item painter now treats the trinket
menu's managed equipped face as owned without changing other macro faces.
The baseline fails the focused ready-trinket check; the candidate passes eight
trinket and 14 combat-grid checks. Isolated published-source desktop validation
passes 112 tests/757 Lua syntax files. Native acceptance remains pending.
[Evidence](TRINKET_EQUIPPED_USABILITY.md).

## 2026-10-31 - chat durability after teleport

The user reported that the character-button percentage disappears after a
teleport loading screen. The previous candidate scanned immediately on
`PLAYER_ENTERING_WORLD` and hid the label on a transient no-data return.
Checked main, the working tree, continuity records, the dated external
checkpoint's presence and current Retail WTF setting read-only before
editing; no setting override or user data was changed.

The painter now retains the last visible percentage through a bounded
world-entry data gap. Player inventory/equipment events or one 0.5-second
retry restore it; a final retry 1.5 seconds later hides it only if data is
still absent. Stale callbacks from an older world entry do no work. The
focused fixture covers event timing, repeated transitions, full/damaged/
empty/secret data; full 112-test/757-Lua desktop suite passes. Native
teleport, clicks, pixels, combat taint and matched frame time remain pending.
[Evidence](CHAT_CHARACTER_DURABILITY.md). WoW stayed in the background.

## 2026-10-31 - keep default cast appearance for inaccessible schools

The user clarified that item, channel, physical and other casts with no
accessible magic school should keep their default appearance. The earlier
neutral-effect candidate was removed before publication. A read-only audit
of Retail/Forever API declarations found no school in the never-secret
castBarID. The published nameplate channel code could boolean-test a secret
ID with `and/or`; explicit selection now lets the existing fallback run.
The new fixture fails on baseline by borrowing the adjacent empowered field,
then passes 56 nameplate checks with the fix. The shared renderer still passes
13,898 checks. Native secret, pixel, taint and frame-time checks pending.
[Evidence](SECRET_CHANNEL_FALLBACK.md).

## 2026-10-31 - chat character durability percentage

The user reported no percentage under the chat-frame character button. Main
was `0c197f5`; the working tree was initially clean. During inspection,
unrelated cast-bar source/test edits appeared; they were left untouched.
Read contribution/continuity/spec records and checked the dated external
29 October source/history/settings tree and current Retail WTF account
settings read-only. The external checkpoint `.git` was inaccessible to this
sandbox, while prior source/history verification is recorded in this log.
The current account settings have no explicit `chat_btn_durability` override.

The loaded painter hid the label at `lowest >= 100`. It now tracks whether
any equipped slot has readable durability and shows `100%` in that case,
while preserving the hidden state for empty/restricted data. Existing
events, slot scan, secure button, colors and settings remain. Source hashes,
focused cases and pending native checks are in
[CHAT_CHARACTER_DURABILITY.md](CHAT_CHARACTER_DURABILITY.md). The focused
test and full 112-test/757-Lua desktop suite pass; native client checks and
matched performance measurements remain pending. WoW and settings were not
controlled or changed. Regenerated source-derived reference pages and the
verification index from the current workspace; `validate_docs.py` passes
with 790 classified sources and 580 TOC/XML-reachable files.

## 2026-10-31 - lower nameplate cast-school backdrop artwork

The user reported school backdrop art appearing in front of Blizzard
nameplate chrome. Read continuity, current renderer and the read-only
Blizzard NamePlates XML; verified a dated external history/source and
four-settings checkpoint before edits. Moved only nameplate backdrop art
to a separate noninteractive plate-level host, with level reconciliation
while casts run. Unit-frame artwork and fill/edge/halo/particle ownership
remain as before. The focused regression fails on the baseline at the
backdrop-layer assertion and passes after correction; full desktop suite:
112 tests/757 Lua files. Native visual/taint/performance checks pending.
[Evidence](NAMEPLATE_BACKDROP_LAYER.md).

## 2026-10-31 - correct conjured combat-item usability tint

The user reported that mana gem and healthstone stayed bright when the other
combat grid items darkened on death, and asked for other unusable states to
work too. Read continuity and the combat-grid paint path, inspected on-disk
Retail settings, and verified a dated external Git history/source checkpoint.
WoW was closed. The shared paint path now honors death/ghost and reliable
live item usability for those two faces while preserving empty-charge and
loading-screen holds. The loaded-paint fixture fails on baseline and passes
14 candidate checks; full desktop validation passes 111 tests/756 Lua files.
Native tint, clicks, taint, pixels and performance remain pending.
[Evidence](COMBAT_GRID_CONJURED_USABILITY.md).

## 2026-10-31 - repair missing school fill and moving-tip tint

The user observed absent school color on all clients, no unit-frame cast fill
and an uncolored tip glow. Inspected the published renderer, Blizzard cast
source and existing options/tests; verified a fresh external source/history
bundle and copied four closed-client settings files outside AddOns. Restored
fill creation on `TimerBar`, hid/restored the underlying native nameplate fill
and tinted/restored the native Spark. Expanded the shared renderer regression;
it fails on the published source at the wrong fill parent and passes on the
candidate. Full desktop validation passes 110 scripts/755 syntax files.
Native pixels, combat taint and matched frame time remain pending.
[Evidence](CAST_SCHOOL_FILL_TIP_FIX.md).

## 2026-10-31 - school colors and effects on Blizzard nameplate cast bars

The user requested the same school visuals as target/focus on Retail, Forever,
Era and Anniversary nameplates while keeping Blizzard's own cast bar. Read
continuity, current unit/nameplate source and read-only Gethe client snapshots;
verified a dated external Git bundle and copied four closed-client settings
files outside AddOns before editing. Extended the shared renderer for a
Blizzard status bar with a Flux visual host, preserving native progress/text/
shield ownership. Added native nameplate-bar post-hooks and a default-on unit-frame
option. Secret/unknown spell identities fall back to native appearance.
Focused 48-check nameplate model and full 110-test/755-syntax desktop suite
pass. Native client pixels, combat taint and matched frame-time measurements
remain pending. [Evidence](NAMEPLATE_CASTBAR_SCHOOLS.md).

## 2026-10-30 - fix MicroMenu nil-center startup error

The user's stack shows Blizzard `GetEdgeButton` comparing nil centers during
`FluxMicroMenu:UpdateLayout()` after the LFG button starts a rebuild.
Reviewed continuity, on-disk Retail settings, the current code and read-only
Era Blizzard reference; verified the dated history bundle and preserved
pre-edit source/settings outside AddOns. Reordered selected/unused child
parking before native Show/Hide callbacks, with final hiding after layout.
The focused regression reproduces old ordering and passes after the fix;
MicroMenu smoke and full desktop validation pass (109 tests / 753 syntax
files). Native post-fix five-client checks remain pending. Other local work
was preserved. [Evidence](17-micromenu.md).

## 2026-10-30 - retain delayed loot source positions

The user reports lagged loot from mobs/chests arriving after the cursor moves
or another source opens. Read continuity and settings, verified the dated
external Git bundle, and preserved pre-edit source outside AddOns. Added
bounded pending sessions with captured item/currency/money identities and
per-source slot/chat reconciliation. The focused fixture checks two reversed
late item messages, a ten-second duplicate, an uncaptured fast-loot window,
late currency/money, and expired sessions. Full desktop validation passes
108 scripts / 752 Lua syntax files. Native five-client event order, pixels,
taint and frame time remain pending. Unrelated shared work was preserved.
[Evidence](LOOT_CURSOR.md).

## 2026-10-30 - keep loot alerts at the looting cursor position

The user reports that alerts should stay at the cursor's loot position when
the mouse moves. Read current source, continuity and on-disk settings;
verified the dated external history bundle and preserved pre-edit source
outside AddOns. Replaced per-alert shared-anchor movement with one origin
captured at loot-window start and retained per visible row. The focused
fixture covers cursor movement before delayed chat, LOOT_OPENED after
LOOT_READY, a second overlapping loot batch and after-close currency. Full
desktop validation passes 108 scripts / 752 Lua syntax files; exact
candidate hashes are recorded. Native event timing, pixels and frame time
remain pending on all five clients. Unrelated stance work was preserved.
[Evidence](LOOT_CURSOR.md).


## 2026-10-30 - exclude non-loot bag gains from cursor alerts

The user reports crafted and other incoming bag items as false loot alerts.
Read current source, continuity and on-disk Retail settings; verified a fresh
main-history bundle and preserved pre-edit loot source outside AddOns. The
chat fallback now accepts ordinary self-loot only near a loot window, plus
bonus rolls; crafted and pushed forms are excluded. Currency follows the
loot-window gate and currency slots cannot become item alerts. Direct slots,
won rolls, money formatting, defaults and fast pickup remain. Focused fixture
and full desktop validation pass (108 scripts / 752 Lua syntax files);
candidate hashes are recorded. Native classification and five-client checks
remain pending. Unrelated stance work was preserved. [Evidence](LOOT_CURSOR.md).


## 2026-10-30 - correct FluxLoot AceDB callback registration

The user's native stack showed CallbackHandler rejecting a table event name
at FluxLoot line 402. Read current source, continuity and present on-disk
settings; verified the external history bundle and preserved a dated external
pre-fix source archive. The focused test was tightened to CallbackHandler's
receiver/event/method signature and reproduced the old error. Corrected the
one registration call to match FluxOptions. Focused and full desktop checks
pass (107 scripts / 751 Lua syntax files); candidate hashes are recorded.
Native post-fix login and profile changes remain pending on five clients.
[Evidence](LOOT_CURSOR.md).


## 2026-10-30 - denomination art for cursor money alerts

Read current source, continuity and on-disk Retail settings; verified the
external Git bundle and preserved the uncommitted pre-edit loot source in a
dated external archive. Replaced generic money chat rows with localized
positive-amount parsing, white numbers and denomination coin art. The leading
icon switches at 1 silver and 1 gold. The focused fixture exercises both
thresholds, mixed amounts, plural grammar and rejected non-loot chat. Full
desktop validation passes 107 scripts / 751 Lua files; candidate hashes are
recorded. Native five-client pixels, locale, taint and performance remain
pending. [Evidence](LOOT_CURSOR.md).


## 2026-10-30 - cursor loot default follow-up

The user clarified on/on defaults across five clients and a visible
three-second disappearance setting. Verified the earlier external Git history
bundle, inspected present Retail saved variables and preserved the current
uncommitted loot source in a dated external archive before editing. Set the
Flux fast pickup default on, retained the cursor-alert and 3-second defaults,
and renamed the duration control. The focused fixture now loads actual
defaults, exercises the control and checks expiry. Full desktop validation:
107 scripts / 751 syntax files, zero failures. The exact runtime candidate
hashes are recorded; native acceptance remains pending. [Evidence](LOOT_CURSOR.md).


## 2026-10-30 - cursor loot and optional fast pickup

Verified clean main `b68f2545`, a dated external source/history bundle and
present on-disk Retail settings before edits. Inspected the installed
FasterLoot 20261016 and Looti 4.1.2 source/license read-only. Added Tools →
Loot controls, a three-row cursor display and optional LOOT_READY pickup.
The separate FasterLoot addon retains ownership while loaded. Focused mock
event checks pass; full desktop validation passes 107 scripts and 751 Lua
syntax files. Native loot, pixels, taint and performance remain pending for
all five clients. [Evidence](LOOT_CURSOR.md).


## 2026-10-30 - compare historical FluxUI default-settings route

Compared the linked GitHub main file and local Git history: both have the
same pre-fix Sticky Targeting routine. Read older on-disk FluxUI snapshots
without changing them; the 13 August pre-rewrite file used the registered
native negated setting on Retail. Preserved the current source and Git history
in another dated external checkpoint, then added a single-setting native
Controls route with CVar readback and raw fallback. The existing modern
Settings guard for raid/nameplate callbacks stays in force. Focused first-
load tests pass 76 checks. Native behavior and frame time remain pending.
[Evidence](RETAIL_CONTROLS_CAMERA_FIX.md).

## 2026-10-30 - Retail Sticky Targeting and camera audit follow-up

The user supplied native Retail readback `1.900000 / nil / 0` for camera
factor, engine maximum and `deselectOnClick`. Verified the current Gethe Live
Controls/setting source, inspected available on-disk settings and saved a dated
external source/history/settings checkpoint before edits. Added native sticky
CVar to the first-load table and audit, changed the no-maximum Retail camera
fallback to 2.6, and allowed one settings-only retry of an earlier failed
audit. Focused first-load fixture passes 68 checks; post-fix native execution
and performance remain pending because no WoW process/window was visible.
[Evidence](RETAIL_CONTROLS_CAMERA_FIX.md).

## 2026-10-30 - first-load nonbinding settings and chat output

Verified a dated external source/history checkpoint and inspected available
on-disk settings before edits. Moved first-account/new-character setting
passes from `PLAYER_LOGIN` to the first world-entry frame. Added a bounded
post-startup audit for supported CVars and setting packs, including Controls,
character nameplate values and Classic raid CVars. Removed progress and chat
class-color messages; manual reset categories now report completion once.
Focused first-load checks: 60; binding model: 507. Full desktop validation:
106 scripts and 748 Lua files. Native settings, reload scope, taint and frame
time remain pending. [Evidence](NONBINDING_FIRST_LOAD.md).

## 2026-10-30 - Hearthstone selector hover error

The user supplied a native stack trace at `FluxSmartHearthConfig.lua:491`:
hovering the Toy Box selector called a nil `GetItemInfo`. Preserved the current
local source, Git history and two on-disk WTF settings files in a third dated
external checkpoint while WoW was closed. The focused fixture reproduced the
hover failure with the deprecated global unavailable. Replaced the direct
call with the existing `Flux.Item.GetInfo` service and Toy Box name fallback.
The 19-check fixture and full 106-script/748-Lua desktop suite pass. Native
hover, toy choice, secure click, reload persistence and taint need recheck.
[Evidence](HEARTH_CONFIG_TOY_COLLECTION.md).

## 2026-10-30 - Hearthstone panel load-order follow-up

The user still did not see the Hearthstone panel beside Toy Box, unlike the
mount config. Read-only TOC inspection found Hearthstone loads at line 145
before `FLUX_API` exists at line 204. The previous fixture had injected
`FLUX_API`, masking the real early return. Preserved the current local tree
and Git history in a second dated external checkpoint and copied two current
on-disk WTF settings files there while WoW was closed. Then switched the
editor guard to the earlier `Flux.Cap.hasToyBox` and routed the default icon
through the existing resolver with the modern item API. The updated 17-check fixture
fails against the prior guard and passes with the fix. Full desktop validation
passes 106 scripts/748 Lua syntax files; native panel and toy use remain
pending. WoW stayed closed and settings were untouched.
[Evidence](HEARTH_CONFIG_TOY_COLLECTION.md).

## 2026-10-30 - Hearthstone Toy Box config window

The user could not use the Hearthstone config window on toy-collection clients
and needs to choose the Hearthstone toy. Started from clean main
`52659bd8d22559dc0943ddd999e681d84d705d8e`. Verified an external dated
source/history checkpoint; with WoW closed, copied two relevant on-disk WTF
files outside AddOns. The first diagnosis attributed the editor's early return
to `FLUX_API.hasToyBox` requiring a particular journal toggle. Removed that
unrelated gate and made the journal opener use modern or legacy load/show APIs.
The 14-check fixture missed the earlier TOC load-order defect, as documented
above. Native toy selection, actual secure click, reload persistence,
taint and frame time remain pending. No game input or settings changes.
[Evidence](HEARTH_CONFIG_TOY_COLLECTION.md).

## 2026-10-30 - atomic context-aware first-account bindings

The user reported exact native assignment/verification failure and asked for
all keys to clear, apply, verify and save in one pass. Used the dated external
`binding-native-failure-checkpoint-20261030` before edits. Source inspection
found false/nil return handling could reject a correct native action, and
Blizzard's Retail UI supplies per-action binding context that Flux omitted.
Updated the transaction to use context where available, retry only mismatches
up to three times, name unresolved keys, and save/load in one call. Updated the
five-client model for context-required writes, transient failure and nil
successful returns. Focused 507 checks, binding/respec 110 checks and full
105-script/747-Lua desktop suite pass. Process/window and WTF inspection did
not expose the user's open clients. WTF folders appeared transiently during
read-only inspection, including an Era account cache with 117 binding rows and
four bridge rows; that does not prove live state or post-change reload.
Mariosuper Era/Pandasans Retail native verification, taint and frame time
remain pending. [Evidence](BINDING_ATOMIC_CONTEXT.md).

## 2026-10-30 - native binding persistence rewrite

The user reported that first-load keybindings returned to game defaults after
reload. With WoW closed, the Retail account cache measured 29 bytes and only
one modified-click row; character bindings were empty, while SavedVariables
recorded account binding marker 5. Backed up these private settings, source,
tests and Git history outside AddOns. The early SaveBindings call in
ApplyCombatDefaultsPack was consistent with the empty cache, and marker 5 did
not prove a native save.

Replaced the binding pipeline with account-set selection, one preflight scan,
eight-write batches, template verification, SaveBindings/LoadBindings
round-trip verification, success-only version-6 completion and rollback on
failure. Removed the early SaveBindings; modified clicks now save only after
native bindings are available or with the full template. Added a one-time
version-5 empty-cache repair. Focused 501 checks across five client models
and full 105-script/747-Lua desktop validation pass; native acceptance and
performance remain pending. [Evidence](BINDING_PERSISTENCE_REWRITE.md).

## 2026-10-30 - stop full binding replay after reload

The user confirmed Flux prints the exact "Applying keybindings..." message
again after reload. Inspected all production call sites and on-disk account
metadata with WoW closed. Preserved the current source/test/history and
available Era account settings and binding cache in a dated external
checkpoint. The previous successful-save-only marker could remain pending
after a partial native write, authorizing another full reset next login.
Changed the automatic first-account pass to claim version 5 before its first
binding write, migrate old pending markers to consumed, skip when four native
Flux bridge bindings already exist, and ignore overlapping batch requests.
No-write missing registration can still start in the same login. Focused 544
checks across five client models, full 105-script/747-Lua suite pass; native
input and frame time remain pending. [Evidence](ACCOUNT_BINDINGS_ONCE.md).

## 2026-10-30 - account-only automatic keybindings

The user reports that the full keyboard reset still runs on character logins.
Read the linked DoctorFlux/FluxUI repository and local main history: its
original bootstrap was gated by the first-account defaults flag. Inspected
the closed Retail client read-only: the account binding cache has the four
reported bridge commands, while the newer completion table is empty.
Preserved current source/history and account settings in a dated external
checkpoint. Replaced per-character eligibility with one account-wide pending
state captured before account defaults are marked applied. Existing accounts
and prior successful character markers migrate without another reset. Removed
automatic keybind replays from Blizzard Settings reset callbacks. Focused
528-check five-client desktop model and full 105-script/747-Lua suite pass;
native key presses, persistence and frame time remain pending.
[Evidence](ACCOUNT_BINDINGS_ONCE.md).

## 2026-10-30 - one-time binding reset and frame pacing

The user clarified that the full binding setup should run once and requested
an optimized, lag-free path. Created a new external source/history checkpoint;
WoW was closed, and available account/character binding caches and Flux saved
settings were copied outside AddOns. Removed cross-login confirmation and
`UPDATE_BINDINGS` reset replay. A verified successful save now marks the
active scope complete; an earlier pending version-4 marker is accepted
without replay. Combined the registry preflight and clear-list collection
into one scan, and separated clear/apply/save across frames with at most
eight native binding writes per frame. The focused production test passes
521 checks across five modeled clients; native frame time remains pending.
[Evidence](FULL_BINDING_RESET.md).

## 2026-10-30 - full first-load binding reset

The user reported that bridge bindings were still never applied and requested
clearing all keys before setting the full template on every client. Read
continuity, development and binding specifications; preserved the current
source and history in an external dated checkpoint. WoW was closed; the
inspected Retail WTF tree had AddOns.txt files but no binding cache. Replaced
the missing-Flux-key seed with a one-time full active-set clear/apply for old
markers, with registration preflight, supported-command filtering, full
verification before save, late-binding event repair and version-4 cross-login
confirmation. Expanded the production-source test to 521 checks across five
client models and retained the 110-check binding/Respec regression. Full
105-script/747-Lua desktop suite passes. Native input, hotkey labels,
persistence, taint and timing remain pending.
[Evidence](FULL_BINDING_RESET.md).

## 2026-10-30 - full first-load binding reset

The user reported that bridge bindings were still never applied and requested
clearing all keys before setting the full template on every client. Read
continuity, development and binding specifications; preserved the current
source and history in an external dated checkpoint. WoW was closed; the
inspected Retail WTF tree had AddOns.txt files but no binding cache. Replaced
the missing-Flux-key seed with a one-time full active-set clear/apply for old
markers, with registration preflight, supported-command filtering, full
verification before save, late-binding event repair and version-4 cross-login
confirmation. Expanded the production-source test to 521 checks across five
client models and retained the 110-check binding/Respec regression. Full
105-script/747-Lua desktop suite passes. Native input, hotkey labels,
persistence, taint and timing remain pending.
[Evidence](FULL_BINDING_RESET.md).

## 2026-10-30 - grid binding persistence after reload

The user reported that first-load bridge keys did not stay bound after reload.
Found a path where the full first-account keybind batch resumed a queued seed
and finalized version 2 before its delayed verification. Created an external
dated source/history checkpoint and checked the local Gethe Settings binding
set loader. The post-batch/combat path now uses the same provisional and
delayed check as world entry. Version 3 waits for cross-login confirmation;
missing saved Flux commands get repaired and retried, while confirmed
intentional unbinds stay untouched. Focused 37-check simulated reload test
and full 105-script/747-Lua desktop validation pass. Native persistence,
secure clicks and hotkey labels remain pending.
[Evidence](DEFAULT_GRID_BINDINGS.md).

## 2026-10-30 - protected-client raid options

The user selected the taint guard after the native Blizzard raid settings
request. Checked Gethe's CUF profile callbacks and Interface Settings source,
created a dated external source/history checkpoint and checked available WTF
settings. Flux's existing raid options now remain authoritative for live
status text and power-bar chrome on Retail/Forever, and the preview uses the
same options for class colors, power, health text and auras. Classic retains
native reads; no native raid writes were added. Nine focused tests, raid
startup/aura smoke, Edit Mode safety and the full 105-script/747-Lua desktop
suite pass. Native appearance, Settings values, protected execution and
performance remain unverified. [Evidence](RAID_OWNED_SETTINGS.md).

## 2026-10-30 - protected-client raid options

The user selected the taint guard after the native Blizzard raid settings
request. Checked Gethe's CUF profile callbacks and Interface Settings source,
created a dated external source/history checkpoint and checked available WTF
settings. Flux's existing raid options now remain authoritative for live
status text and power-bar chrome on Retail/Forever, and the preview uses the
same options for class colors, power, health text and auras. Classic retains
native reads; no native raid writes were added. Nine focused tests, raid
startup/aura smoke, Edit Mode safety and the full 105-script/747-Lua desktop
suite pass. Native appearance, Settings values, protected execution and
performance remain unverified. [Evidence](RAID_OWNED_SETTINGS.md).

## 2026-10-30 - raid profile and nameplate defaults

The user reported that Blizzard raid power bars, class colors and frame size
did not apply, and requested nameplate size `2` instead of `3`. Read continuity,
the defaults writer and local Gethe source; verified main and on-disk settings
availability. Preserved the three affected sources and verified Git history in
an external dated checkpoint. No private settings or WoW process were changed.

The Classic raid profile helper previously returned success when no active
profile existed. It now keeps work pending, completes the full raid pack after
profile load and retries briefly after first world entry. Retail/Forever native
compact-frame callbacks remain excluded by the existing taint guard. Updated
both nameplate default tables to `2` and added a one-time old-`3` migration
that retains other sizes. Classic native frame size now applies even with Flux
raid frames enabled. Focused 15 checks, existing 363-check five-client
Edit Mode guard regression and full 104-script/746-Lua desktop validation pass.
Native all-client settings/taint/pixel checks remain pending.
[Evidence](RAID_NAMEPLATE_DEFAULTS.md).

## 2026-10-30 - same-login grid binding correction

The user reported the first repair required another reload, then that it was
not assigning the keys at all. Read current repository continuity and Gethe
binding-set source; inspected available on-disk settings read-only; preserved
the current candidate and verified Git history in a second external checkpoint.
The old path saved a completion marker at `PLAYER_LOGIN`, before later native
binding-set selection could be checked, and excluded Blizzard's stock `Y`
achievement action from smart mount replacement.

Moved the seed to first world entry, added a second in-login verification and
bounded retries, upgraded old markers to version `2`, and allowed stock `Y`.
After the user reported both grids' labels absent, traced the refresh to an
unused legacy button list and a sparse module array. The live EBS registry and
dense loaded-module list now refresh labels and secure click owners. Focused
29 binding and 7 hotkey checks and full 103-script/745-Lua desktop validation
pass. No WoW window or settings were controlled. Native first-load key clicks, labels and
combat/taint on each client remain pending. [Evidence](DEFAULT_GRID_BINDINGS.md).

## 2026-10-30 - missing default grid bindings

The user reported Hearthstone, teleport and mount grid keys missing after
first-login defaults, then confirmed those keys should be set by the defaults.
Read continuity and binding owners, preserved other working-tree changes and
made an external dated source/history checkpoint; its Git bundle verified.
Read-only Retail on-disk inspection found two binding caches, one with the four
reported Flux commands and one without; the target keys were unbound in the
latter. No account names, private settings or game state were exported.

Added a one-time, active-binding-set seed for missing Flux commands, preserving
custom target keys and alternate assignments. It queues behind bulk setup or
combat and refreshes the existing secure override owners. Focused 21 checks,
prior 42/110 defaults/binding checks and full 102-script/744-Lua desktop suite
pass. Native key clicks and all-client verification remain pending; no WoW
process, setting or profiler was controlled. [Source/evidence](DEFAULT_GRID_BINDINGS.md).

## 2026-10-30 - first-login defaults on new characters

Read repository rules, continuity, defaults/persistence specs and current
runtime. Preserved the large pre-existing working tree. Created an external
dated source/history checkpoint before runtime edits; verified its Git bundle
and confirmed 11 on-disk account WTF files were available. Read Gethe branch
versions for Live, Forever, Era, Anniversary and MoP and the Live Controls/CUF
source. No WoW process, settings, input or profiler was touched.

New-character setup now filters `FLUX_DEFAULTS` and nameplate bitfields by
client-reported character CVar scope. It keeps raid/chat setup and preserves
account CVars/bindings. First-account and new-character seen flags require their
respective setup to succeed; the new-character marker waits for its queued CVar
job. The focused regression passes 42 checks; binding regression passes 110.
At the user's direction, removed the
untracked obsolete `tests/minecraft_appearance.lua`; the fresh full suite then
passes 101 scripts/743 Lua syntax files. Generated source and verification
indexes were refreshed. Native all-client acceptance and performance remain
pending. See [the exact-source record](DEFAULTS_FIRST_LOGIN.md).

## 2026-10-30 — merchant chat coin denominations

User reported `Repaired for 3494236c` and requested denomination amounts with
gold/silver/copper symbols for all vendor chat. Read continuity and vendor specs;
preserved unrelated working-tree changes. Verified the dated external 1,307-file
source ZIP against its recorded SHA-256 and the complete Git bundle; Retail on-disk
settings were present. Changed the three merchant money chat paths to use explicit
coin textures and denomination math, retaining transaction accounting/messages.
Focused chat and vendor identity tests pass. Full desktop validation passes 100
scripts/741 Lua syntax files with zero failures. Native texture rendering is
pending; no client, settings, profiler or sync interaction.

## 2026-10-30 — scale follow-up: portrait and strip

User reported displaced 3D portrait and unit frame overlap with the action
strip. Preserved newer vehicle/durability and status-bar work. Before editing,
verified an external 1,307-file source ZIP and complete Git bundle plus presence
of on-disk Retail settings. Corrected portrait offset double scaling, converted
focus chat/aura coordinates, normalized strip top and player bottom anchor
across frame scales, and refreshed the model/camera only when scale changes.
Player and target also apply the corrected anchor on first creation.
Focused production tests pass 23 checks, including 50% and 135% strip clearance;
portrait camera control passes 1,191 checks. Full desktop suite passes 99
scripts/740 Lua syntax files. Native pixels, clicks, combat/taint and FPS
remain pending. No game, settings, profiler or sync interaction.

## 2026-10-30 — whole unit-frame scale

Read continuity, options and unit-frame requirements; preserved the concurrent
vehicle-seat changes. Baseline main `021b524893229fece34eff503a8ac1cf66388363`.
Verified a fresh dated external 1,303-file source archive and complete Git
history bundle, plus presence of on-disk Retail settings, before editing.
Added 50–200% shared player/target and independent focus scale controls to the
existing unit-frame scope/defaults. Root frames, satellites, detached chrome,
class resources and micro-menu target cap follow scale; combat uses the existing
deferred layout pass. The production-bridge regression passes 17 checks and
the full desktop validation report is linked in [the scale record](UNIT_FRAME_SCALE.md).
Native geometry, input, combat/taint, pixels and performance remain pending.
No game, settings, profiler or sync interaction.

After the user supplied a screenshot showing an unscaled border and overlap
with the action strip, traced the atlas border to its `UIParent` host. Matched
its effective scale to the unit root and added clearance when the player or
side-by-side target grows beyond 100%. The 100% Y anchor remains unchanged.
Full 98-script/739-Lua suite passes after the correction; native pixels and
click acceptance remain pending.

## 2026-10-30 — vehicle seat layout

Read continuity and QoL specifications on clean main `021b524893229fece34eff503a8ac1cf66388363`.
The dated external `Publish-unit-power-20261030T101822` source/history checkpoint
is recorded in the publication ledger; on-disk Retail WTF settings remain present.
Changed only the Flux-owned seat indicator: micro menu position 2 puts its top-left
at the screen corner; parent scale 0.7 reduces artwork and seat hit areas together.
Other menu positions keep the durability anchor. Combat deferral and native
stock-indicator ownership remain. Focused layout check and the original
97-script/738-Lua desktop suite passed. Native geometry/input/taint and client pixels pending.
No client, settings, profiler or sync interaction. Candidate source SHA-256
`5a460a55026dcc320a2308299028c908b939a5135d5098a890638e9d525dff83`.

User screenshot showed the frame still low. The first condition wrongly required
status position 2 as well; existing defaults use menu 2/status 3. Removed that
extra gate and expanded the regression to cover menu 2 with status 1, 2 and 3.
Focused regression passes. A 98-script/739-Lua suite passed, but parallel unit
frame edits changed source afterward and the documentation validator reports
their verification manifest stale. Native screenshot recheck remains pending.
Revised source SHA-256: `d55b22025caad3edbc96931fe9ae9681affb39c4105c1ad6cf9f1acb9820fd64`.

User clarified that top-left micro/status chrome must stay fixed, with vehicle
seats and equipment durability together below it. The durability owner now
reserves the scaled seat width and chooses the lower visible top-left chrome;
vehicle seats anchor to its left. Empty chrome starts the pair at the screen
top-left, with prior PvP clearance retained. Focused production-slice checks
cover menu only, status only, both, neither, PvP, load order and combat.
Full actual-file desktop validation passes 99 scripts/740 Lua syntax files;
generated source inventory and documentation validation pass. This includes
the preserved concurrent unit-frame scale changes; it does not establish
native rendering or input.
Candidate source SHA-256: seats `12bbd63adfdffc520a646be83ea9a36a888cf36d3029ce9bde3892270149c06d`;
status owner `8312374088485e5bbe9811f02960eda627e1163ff6412b6c1b38c83325c09b44`.
Native geometry, input, taint and pixels remain pending.

## 2026-10-30 — unit power visibility

Read the continuity/specification records; verified clean main
`058efb8192b537d73e7e1e7f1a7e6afe2fbde575`, the dated external
source/history/settings checkpoint and present on-disk Retail settings before
runtime edits. Inspected Gethe's `live` UI source and local client contracts.
Flux-owned main and raid frames now hide known zero-maximum power bars and let
health fill the inner region; power returns on capacity changes. After user
feedback that Live/Forever health still looked split, verified source annotations
and placed full-height health behind a power layer with native secret-safe alpha.
Raid combat reanchoring waits for regeneration. Existing
health-only satellites require no change. [Details](UNIT_POWER_VISIBILITY.md).
Follow-up: health text now follows full-height HP for absent/restricted power;
known positive power keeps the split-area text anchor. The Flux separator starts
transparent and follows max-power alpha. Verified the existing dated external
source/history/settings checkpoint still exists; Retail on-disk `Config.wtf`
changed outside this work and was not opened for writing.

Focused models pass. Full desktop validation passes 96 scripts / 737 Lua files.
Native checks across clients, secure combat, restricted values and pixels remain
pending. WoW remained in the background; no settings/profiler/diagnostic or
other addon state changed. Main contains uncommitted source, test and records.

## 2026-10-29 — teleport counts and interrupted casts

User confirms Retail interrupted teleport/portal lag and unwanted reagent-free
count. Read continuity/travel requirements, inspected clean main b45eb5e and
verified fresh external source/history/on-disk Retail settings before edits.
BUG-012/PERF-011 uses native count text, clears reagent-free legacy digits, stops
fabricating runes from opaque text, skips reagent construction for eligibility
and restores the host without popup/key rebuild. No settings/default/cadence or
other flyout-owner changes. [Exact identities/limits](TELEPORT_CAST_WORK.md).

527 assertions: baseline 14 failures, candidate zero. Three rejected mutations.
Five alternating desktop pairs: per 100 integrated casts, tooltip calls 2,000 -> 0
and popup rebuild boundaries 100 -> 0, zero variation. Full 95 scripts / 736 Lua
files pass. Native reported-hitch resolution/combat/taint/pixels and general
custom flyouts pending. WoW/profile/diagnostic/settings untouched; no foreground
input, sync job, commit or push. Existing history preserved.

## 2026-10-29 â€” audit baseline and first provider fix

Inspected actual main `7436820`, remote, manifests, tests, diagnostics, documentation
and supplied Word/Markdown plans/templates/specifications. Initial tracked tree was
clean; `new docs/` and sync log were untracked. No root/ancestor instructions existed.
Merged durable rules without modifying supplied documents. Read-only audits
covered all supplied specs, lifecycle ownership and installed clients/references.

Before repository edits, created and verified source ZIP (1,177 files), Git history
bundle and private settings ZIP (403 files), while no WoW process was running. See
`RECOVERY.md`. Created the current change branch; main was preserved.

Ran `python tests/run_validation.py --output docs/validation/modernization-baseline-2026-10-29.json`:
81 tests passed; 722 Lua syntax files, zero failures. Lua/luac 5.4.6, Python 3.10.6.
Existing historical P0 fixes remain regression controls, not reimplemented work.

Reproduced BUG-001 in real Store/Currency/Syndicator adapter code with native APIs
and unrelated regions mocked. Before editing runtime, added a focused test and
captured `lua tests/currency_provider_handoff.lua --measure` output: 150 checks,
50 failures. A 400-event burst after Ready reads builtin money 100 times, requests
300/400 redundant refreshes and overwrites provider money 999 with 654. Saved
standalone ledger was already protected by Store; the shared snapshot was not.

Added four provider guards and an ownership comment in Currency.lua. Preserved
the baseline source as a nonloaded `.txt` fixture with matching checkpoint hash.
Targeted candidate and existing late-inventory regression passed. Five alternating
baseline/candidate process pairs each exercised five capability models and five
400-event repetitions. Candidate passed 150 checks every invocation; all stale
read/request/generation counts became zero with zero range. Four shared-bus callbacks
remain subscribed; external update and standalone timing checks pass. Raw samples
and identities are in `validation/currency-provider-comparison-2026-10-29.json`.

Ran `python tests/run_validation.py --output docs/validation/modernization-candidate-2026-10-29.json --sync-docs`:
82 tests passed; 723 syntax files, zero failures. Independent diff review found no
actionable correctness defect and confirmed limits of the mocked evidence.
Runtime/test/fixture committed separately as `2a7de26052e1b9662deef1b606b5ec95ebefe3aa`,
tree `86ed71c06dc9bc2117fb60e30d5417976506912a`. Initial commit attempt found no Git
author configuration; retry used this repository's existing DoctorFlux name/noreply
address through command-only settings, without changing global/local config.

Created feature/options/default/command/integration inventory (1,384 rows, all 26
specs, 17 discrepancies), client/reference matrix, ownership/dependency/API maps,
prioritized implementation plan and performance protocol/results. Refreshed existing
generated references with `python -B docs/tools/build_reference.py`: 756 Lua/XML
sources, 577 reachable, 361 option definitions, 519 defaults. Corrected stale prose
about load order, OptionalDeps, provider timeout/global item wrappers and `/fluxui bliz`.
The generated diff includes previously stale references, not additional runtime work.

`python -B docs/tools/validate_docs.py` passed: 756 classified sources, 577 reachable,
361 setting definitions, 23 saved roots and 12,649 valid local links. All six CSV
ledger row shapes passed. All 723 current Lua files match the candidate manifest;
the 42 original supplied-package/log files match the recovery hashes byte-for-byte.
`git diff --check` passed. Generated/explanatory reference refresh is committed
separately from the new audit, continuity and preserved requirements package.
The later full staged check flags the supplied specs' intentional Markdown
two-space line breaks and their verbatim CSV copies. They are preserved; the
staged check passes with end-of-line whitespace excluded. No source normalization
was applied to the user's package to silence those warnings.

No native clients launched, no settings mutated, no reference addon copied or edited,
and no deploy/sync to another installation. Native visual/input/secure/taint/secret,
CPU, allocations, latency and frame-time/FPS acceptance remains pending. Larger
architecture/lifecycle migration is unfinished. Next investigation is event-dispatch
mutation and its actual consumers, with a separate baseline before any fix.

## 2026-10-29 continuation â€” deferred scans and mail completion

Resumed on `201bc83`; tracked tree was clean and only the original sync log was
untracked. Read instructions, status, decisions, ownership/performance records and
relevant inventory specs. Preserved verified checkpoints at 09:32 and 09:41 UTC
outside AddOns, including actual files, Git history and private WTF while WoW was
closed. Main stayed at `7436820` throughout.

Production event-dispatch replay confirmed skipped handlers under removal and
inconsistent same-event additions. Traced the real Ev alias through Context:
DisarmEvents is called only from Unsubscribe, with no production caller found.
Recorded the latent API issue and six reproducible sequences in
`EVENT_DISPATCH_AUDIT.md`; no shared dispatcher changes were justified for this batch.

Prioritized BUG-002 after reproducing real Store/Mail/Auctions/Adapter handoff:
queued/partial builtin scans overwrite external snapshots after Ready. Unchanged
provider mail fingerprints can leave that corruption in place. Verified all 723
previously tested Lua hashes before reusing the existing full baseline, captured
new focused baseline (210 checks/42 failures), then added execution-time ownership
checks and cancellation in the two StepScan callbacks. Mailbox/open state, retry
and standalone close behavior remain. Five alternating pairs report zero variation:
queued/partial mail reads 105/56 to zero, auctions 71/38 to zero, stale publication
one to zero. Existing inventory pipeline passes 1,732 checks; full candidate passes
83 scripts/724 syntax files. Runtime/test/fixtures committed as `05e9f79`.

Separately reproduced BUG-003 for SendMail and ReturnInboxItem using controlled
post-hooks/events and actual local Syndicator 288 API/Main.lua returned references.
Completion after Ready appended directly to provider-owned alt mail. Portable tests
model that verified contract without adding an external fixture dependency. The
next baseline verifies all 724 tested Lua hashes and preserves the current Mail
fixture. Focused baseline: 410 checks/8 failures. A single ownership condition now
routes stale completion through existing failure cleanup before destination lookup.
Five alternating pairs pass all 410 candidate checks; four success cases change
one provider lookup/foreign row append to zero. Each action's 100 standalone cycles
retain one frame, zero subscriptions and 50 valid credits before/after. Independent
reviews found no actionable issue. Committed separately as `ab4e658`.

Commands/results:

- `lua tests/deferred_inventory_handoff.lua`: 210 checks pass; baseline `--measure`
  with both retained fixture arguments reports 42 expected failures.
- `lua tests/pending_mail_provider_handoff.lua`: 410 checks pass; baseline with
  `--source tests/fixtures/pending_mail_provider_before.txt --measure` reports 8 failures.
- `lua Inventory/_tmp_inventorylag_smoke.lua`: 1,732 checks pass across seven models.
- `python tests/run_validation.py --output docs/validation/deferred-inventory-full-2026-10-29.json --sync-docs`:
  83 scripts and 724 syntax files pass, before BUG-003.
- `python tests/run_validation.py --output docs/validation/pending-mail-full-2026-10-29.json --sync-docs`:
  final 84 scripts and 725 syntax files pass. All final Lua bytes match its manifest.
- Matched samples and exact commands/source hashes are preserved in the deferred
  inventory and pending mail comparison JSONs; continuation-identities pins both
  commit/trees and final normalized corpus. Process durations are not native CPU/FPS.

Updated parity, ownership/API/dependency, client, plan, performance, continuity and
recovery records. No new abstraction, native API replacement, settings migration,
client deployment, push or merge. Original user package/log remains preserved.
Native visual/input/secure/taint/performance results remain pending. Next source
investigation is auction/guild/Void query/request work after Ready; it is currently
an unmeasured finding rather than a claimed fixed defect.

Final reference regeneration reports 758 classified sources/577 reachable;
`python -B docs/tools/validate_docs.py` passes with 361 settings, 23 saved roots and
12,685 valid local links. All six CSV ledgers have valid row shapes and all 725 Lua
hashes match final validation. The 41 supplied package files match the original
archive. The sync log grew to 142,774 bytes before this continuation (09:30:44 UTC);
it matches both new checkpoints and was left untouched/untracked. This explains the
initial final-preservation check's mismatch against the older 111,922-byte log;
no rollback or overwrite was performed. Whitespace checks pass with intentional
verbatim Markdown line breaks retained.

## 2026-10-29 continuation â€” Windows enable/disable (user excludes provider queries)

Resumed on `f1a3bc7`, same modernization branch, with only the original sync log
untracked. Read durable records, lifecycle/feature/API/client/performance records,
Windows requirements/options, actual Catalog/Engine/Init, existing tests and runner.
The user explicitly excluded auction, guild-bank and void callback investigation;
no runtime edits were made in those domains.

Before edits, created and hash-verified a fresh external checkpoint at 10:07:52 UTC:
1,219 actual source files, all Git refs/history, and 403 private settings files with
WoW closed. Rechecked all 725 Lua hashes against the previous passing full report
before reusing that baseline. Main remains `7436820`; no push/merge/deployment.

Production mover/options replay reproduced BUG-004/PERF-003: disabled startup still
runs catalog discovery and native attachment, Player Spells keeps polling, and the
public SetEnabled(false) leaves a scaling driver able to change saved scale.
Captured 220 checks/108 failures before editing. The two-file runtime diff gates
Scan by existing settings, hides/shows the panel watcher through Refresh and calls
Refresh for both public enable outcomes. Existing options setter already uses it.
No saved data migration, new framework or native API replacement.

Commands and evidence:

- `lua tests/window_mover_disabled.lua --baseline --measure`: 108 expected failures
  in 220 checks using retained pre-fix source fixtures. Initial baseline was captured
  from unchanged runtime before applying the fix. Measure mode deliberately exits 0.
- `lua tests/window_mover_disabled.lua`: 220 checks pass, including real options and
  module startup, event/delayed discovery, 100 enable/disable cycles, scale persistence,
  public disable during scaling and combat-deferred Apply.
- `lua WindowMover/_tmp_charactercombatsmoke.lua`: passes existing modeled Forever
  mouse/gamepad hook isolation and combat recovery controls.
- Five alternating fresh-process pairs: disabled-start discovery 24 to zero,
  resolution calls 2,546 to zero, hooks seven to zero. After enabled startup, 20
  disabled event scans/2,120 resolves and 100 polls in ten modeled seconds become
  zero. Public disable stops post-disable saved scale change and both update loops.
  Count ranges are zero; 100 cycles retain seven fixture frames/hooks and scale 1.2.
- `python tests/run_validation.py --output docs/validation/window-mover-full-2026-10-29.json --sync-docs`:
  85 scripts/726 syntax files, zero failures. These are desktop mocks, not native
  UI/secure/taint/secret/FPS acceptance. Process durations are advisory only.

Runtime/test/fixtures committed separately as `19c40a0c84212b24fdf221a9653a4116d32f9020`,
tree `92973edadfdd5ebfc5935621bc2b77f1e0655066`. Review of the small runtime diff
confirmed enabled geometry paths/restriction guards are unchanged.  Evidence/native steps are in
`WINDOW_MOVER_LIFECYCLE.md`; current baseline/candidate hashes and matched outputs
are pinned in `validation/window-mover-comparison-2026-10-29.json`.

Latest documentation validation passes: 759 classified sources, 577 reachable,
361 setting definitions, 23 SavedVariables roots and 12,704 local links. All six
CSV ledgers have valid row shapes (1,384 parity, 35 ownership, 18 API contracts,
eight client, 77 reference and 109 performance rows). All 726 current Lua hashes
match full validation; all 42 supplied package/log files match the fresh checkpoint.
Generated references were refreshed with the existing tools. Whitespace checks pass
with intentional verbatim Markdown hard breaks retained.

## 2026-10-29 â€” repository editorial cleanup

Baseline f57fc79; main unchanged. Before edits, verified a fresh external source,
history and private settings checkpoint at 10:19 UTC with WoW closed. Retired editor
plans, prompts/templates, original Word plan, old handoffs, ignored local backups
and sync log into that checkpoint. Replaced useful rules/tasks with conventional
contribution and development documentation. Retained all 26 specifications and the
Markdown implementation plan; three terminology edits preserve gameplay requirements.

Rewrote conversational comments in 39 Lua files across bars, binding, window/map,
extra buttons, inventory/restock, layout, menu, minimap, other helpers, Respec and
unit frames. Existing lexer comparison against recovered sources proves identical
non-comment tokens and exact string bytes for every changed Lua file. Data, licenses,
assets, saved roots, manifests and runtime behavior are preserved. Historical capture
numbers remain unchanged; only process descriptions/optional branch metadata changed.

Evidence: validation/comment-cleanup-tokens-2026-10-29.json. No new runtime benchmark
is needed for identical executable code; native acceptance remains at its prior status.

Final checks use `python tests/run_validation.py --output docs/validation/editorial-cleanup-full-2026-10-29.json --sync-docs`, the existing
reference builder and documentation validator. The final source manifest supersedes
intermediate reports made before the last inline comment edit. Libraries/assets/
manifests (318 files) and historical measurement values were byte/value checked;
38 retired original files match the external checkpoint. All six CSV ledgers retain
valid row shapes. Explicit development-tool markers are absent from actual addon
files outside Git; legitimate game labels/item names/local variables are retained.

Editorial validation completed: 85 desktop tests and 726 Lua syntax checks pass;
all current Lua hashes match the final report. Documentation validation passes
with 759 classified sources, 577 reachable files, 361 setting definitions,
23 SavedVariables roots and 12,709 local links. All six CSV ledgers are valid.
The final scope scan covers 1,195 actual files and finds zero development-tool
markers outside Git. Native acceptance retains its prior pending status.

## 2026-10-29 â€” queued merchant purchase identity

Resumed on 07b11ce with a clean working tree, same branch and main 7436820. Read
contribution/status/development/decision records, vendor ownership/performance
records, supplied vendor requirements, production seller/classifier/buyer and tests.
The auction, guild-bank and void-storage callback audits remain deferred.

Before edits, verified a fresh external checkpoint at 10:40:48 UTC: 1,195 source
files, Git history/refs and 403 private settings files while WoW was closed. Verified
all 726 previous Lua hashes before reusing the 85-script full baseline.

BUG-005 reproduction executes production FluxVendorBuy through public restock and
merchant event handlers. After the initial eight purchases, replacing slot 9 and
removing slot 10 causes wrong/empty purchases on the next bag pulse, even after the
index rebuild. Baseline: 660 checks/36 failures. Added one execution-time identity
condition using the existing resolver; no new service or settings change. Invalid
tasks leave the queue before purchase/accounting while valid trailing tasks continue.

Validation:

- `lua tests/vendor_slot_identity.lua --source tests/fixtures/vendor_buy_slot_before.txt --measure`:
  retained baseline records 36 expected failures; measure mode deliberately exits 0.
- `lua tests/vendor_slot_identity.lua`: all 660 checks pass. Four merchant API/identity
  models, manual/tier targets, pulses before/after index rebuild, same-pass changes,
  fresh request recovery, merchant close and stable 40-target queues are covered.
- `lua Inventory/Restock/Junk/_tmp_junksmoke.lua`: existing sale/protection/visual
  regression passes; no seller code changes.
- Five alternating process pairs: all 20 metric cases have zero count variation.
  Each changed tail goes from one wrong + one empty purchase to zero; valid trailing
  purchases remain two. Stable 40-item queues retain five passes/eight-call budget
  and one event frame; each valid purchase adds one ID or link identity read.
- `python tests/run_validation.py --output docs/validation/vendor-slot-full-2026-10-29.json --sync-docs`:
  86 scripts/727 syntax files, zero failures. Native screenshots/input/taint/security,
  resource costs, latency and FPS remain pending; fixture money is simulated.

Runtime/test/fixture committed as cdd752abd060588bc1602e880d997a60dd0b34a9, tree
d18478f458e670f18931c070a00d53a708387fee. Source review confirms only the invalid-task
condition/comment changed; purchase math/UI/defaults/restriction guards are preserved.
Evidence and exact native steps are in VENDOR_PURCHASE_IDENTITY.md. No new native
client run, settings mutation, deployment, push or main change.

Merchant identity documentation validation passes: 760 classified sources, 577
reachable files, 361 setting definitions, 23 SavedVariables roots and 12,733 local
links. All six ledgers have valid row shapes (1,384 parity, 35 ownership, 19 API,
eight client, 77 reference and 118 performance rows). All 727 Lua hashes match
the full report. Requirements/libraries/assets/manifests (346 files) match the fresh
checkpoint, and the development-tool marker scan remains clear outside Git.

## 2026-10-29 â€” finite merchant stock budget

Resumed on 0d05acc with a clean working tree, same branch and main 7436820. Read
contribution/development/status/decisions, vendor requirements/ownership/performance
records, production quantity/queue code and existing tests. Read-only local Blizzard
12.1.0.69283 merchant source and existing bulk-buy code confirm separate zero-stock
handling; no reference code/assets were copied. Deferred callback scope is unchanged.

Before edits, verified an external source/history/private-settings checkpoint at
10:54:48 UTC while WoW was closed. All 727 Lua hashes matched the prior 86-script
full report before baseline reuse. Extended the existing merchant harness instead
of creating another fixture framework; retained the pre-edit runtime as a nonloaded
source fixture. Baseline stock replay: 177 checks, 39 failures.

Changed ComputeRestockPurchaseQty to cap zero stock. RunBuyPass now reserves finite
submitted quantities on the existing shared index entry, preventing reuse within
and across passes/duplicate entries. The reservation is not native acknowledgement.
Settings, UI, cadence, unlimited/nil helper semantics and other affordability math
remain. Normal index refresh/new request can buy replenished stock.

Commands/results:

- `lua tests/vendor_slot_identity.lua --stock-only --source tests/fixtures/vendor_stock_before.txt --measure`:
  39 expected baseline failures; measure mode deliberately exits zero.
- `lua tests/vendor_slot_identity.lua --stock-only`: 177 checks pass.
- `lua tests/vendor_slot_identity.lua --identity-only`: original 660 checks pass.
- Default execution: 837 checks pass. Existing junk smoke passes.
- Five alternating fresh-process pairs: all 20 metric cases have zero count range.
  Zero-stock rejection calls 5 to zero; finite stock 3/max stack 2 rejections 4 to zero,
  actual units 2 to 3 and accounted/actual copper 50/10 to 15/15. Across-pass stock
  rejection calls 2 to zero; unlimited 40 purchases/five passes and one event frame
  remain. No extra merchant-info reads. Money values are simulated, not native losses.
- `python tests/run_validation.py --output docs/validation/vendor-stock-full-2026-10-29.json --sync-docs`:
  86 scripts/727 syntax files, zero failures. Native screenshots/input/taint/security,
  CPU/resources/latency/frame times/FPS remain pending; no speedup is claimed.

Runtime/test/fixture committed as b505bb880aeefbab414d957d8d7fbee6820c20a8, tree
cc067974b724c82188d52f24a9800ad485ca261e. Small runtime diff reviewed for ownership,
negative/nil sentinels and shared-entry capacity. Evidence/native steps are in
VENDOR_STOCK_BUDGET.md. No settings mutation, client deployment, push or main change.

Finite-stock documentation validation passes: 760 classified sources, 577
reachable files, 361 setting definitions, 23 SavedVariables roots and 12,750 local
links. All six ledgers have valid row shapes (1,384 parity, 35 ownership, 20 API,
eight client, 77 reference and 129 performance rows). All 727 current Lua hashes
match the full report; requirements/libraries/assets/manifests (346 files) match
the checkpoint. The development-tool marker scan remains clear outside Git.

## 2026-10-29 â€” vendor-open junk availability

User reports lag simply opening a vendor on Classic Era and requests all-client
coverage. First/repeated-open behavior and automation settings are unknown. Kept
main and the deferred auction/guild-bank/void-storage callback scope unchanged.
Inspected current contribution/status/decision records and actual merchant/junk/
inventory source before editing. Preserved the clean 9e17e28 baseline at 11:14:06 UTC
in a verified external source/history/private-settings checkpoint with WoW closed.
All prior 727 Lua hashes matched the 86-script full report before baseline reuse.

Production availability calls repeatedly walked unchanged non-junk bags. BUG-007/
PERF-004 adds two scalar values to the existing junk owner, keyed by reliable bag
generation and cleared by existing rule/item/list/slot invalidation. Native-positive
precedence, cold gray fallback, unready retries, UI cadence and automation remain.
No new frames/hooks/timers/subscriptions/settings. The native hitch is not certified
fixed; other open-path work remains unmeasured.

Commands/results:

- `lua tests/vendor_open_work.lua --source tests/fixtures/vendor_open_junk_before.txt --measure`:
  265 checks, seven expected baseline failures; measure mode exits zero.
- `lua tests/vendor_open_work.lua`: all 265 checks pass across Era, Anniversary,
  modern Wrath Classic, Cata, Mists, Retail and Forever fixtures. Real buyer events,
  inventory/junk modules and extracted production UI availability callbacks run;
  rendering/layout/restock data/other integrations are modeled or excluded.
- Five alternating fresh-process pairs, all automation off: each legacy fixture's
  first-open slot reads 300 to 200; 25 unchanged reopens 5,000 to zero. Retail/Forever
  360 to 240 and 6,000 to zero. All counts have zero trial range. Buyer event frame
  remains one, native junk-count queries remain 182 on modern fixtures/zero legacy.
- Existing junk seller smoke passes; merchant stock/identity controls retain 837
  checks. `python tests/run_validation.py --output docs/validation/vendor-open-full-2026-10-29.json --sync-docs`:
  87 scripts/728 syntax files, no failures. Every current Lua hash matches the report.
- Native builds/settings/addon list, screenshots/input/combat/taint/secrets, CPU/
  memory/latency/frame times/FPS remain pending. Process timings include fixture
  startup and do not measure native vendor-open latency.

Runtime/test/nonloaded fixture: `e02139ab1c6b8099b02fb4506ff150a50d6555ef`, tree
`0a23a38a04809c0a087089586cb5842496fb5c64`. Focused evidence and exact native steps:
[VENDOR_OPEN_WORK.md](VENDOR_OPEN_WORK.md). No settings reset, deployment or push.

Vendor-open documentation validation passes: 761 classified sources, 577 reachable
files, 361 setting definitions, 23 SavedVariables roots and 12,769 local links. All
six ledgers have valid row shapes (1,384 parity, 35 ownership, 21 API, eight client,
77 reference and 157 performance rows). All 728 Lua hashes match the full report.
The checkpoint comparison finds no missing files and preserves 348 specification/
library/asset/manifest files byte-for-byte. Explicit development-tool markers remain
absent across 1,218 actual files outside Git. Legacy fixture labels share one API
route; Retail/Forever share another, rather than proving seven native contracts.

## 2026-10-29 — Quick Join anchor cycle

User supplied the native QuickJoinToastButton:SetPoint cycle at FluxChatFrame.lua
line 1248; client/build unspecified. Current branch was clean; main remained
7436820453d2248c84c99fff71507553efc47c19. Read current rules/records, chat options/
specification, both layout owners and existing tests. A fresh verified external
checkpoint at 11:47:07 UTC (12:47 Copenhagen) covers all 1,218 files, Git history
and 403 private settings files with WoW closed. All 728 baseline Lua hashes match
the previous full 87-script report.

The column anchors Channels below Quick Join. Its older social callback reverses
that dependency, reproducing the supplied failure. BUG-008 adds a six-line owner
guard when either button belongs to the column; the surrounding normal layout
still reconciles it. Native fallback, defaults/settings, dimensions, click scripts
and 0/0.1/1-second retry deadlines remain. No runtime hooks/timers/frames added.

Extended the existing column test with a cycle-aware parent/anchor graph and
bottom-point geometry, executing actual social and retry callbacks with the column.
Baseline passes the original 1,311 checks, then fails 448 of 508 ownership checks.
Candidate passes all 1,819, including four existing rejected mutations. Other chat
layout/startup/retry controls pass. Five alternating fresh-process pairs across
Live/Forever, both sides: cycle failures per three queued callbacks 3 to zero;
retry callbacks 3 to 3; burst frames zero to zero. Candidate reaches/reuses the
existing combat waiter that baseline exceptions prevent from being queued.

Commands: `lua tests/chat_column_layout.lua --source tests/fixtures/chat_quickjoin_before.txt --measure`,
`lua tests/chat_column_layout.lua`, `lua tests/idle_layout_retries.lua`,
`lua tests/chat_layout.lua`, `lua tests/chat_startup.lua`.
`python tests/run_validation.py --output docs/validation/chat-quickjoin-full-2026-10-29.json --sync-docs`:
87 scripts/728 syntax files pass. Measure mode deliberately exits zero for the
known failing baseline. Native rendering/input/security/CPU/resources/latency/frame
times/FPS remain pending; preventing an exception is not measured native speedup.

Runtime/test/nonloaded fixture: `5198ded001dde5bbc3fc5d6011239652cbe79dac`, tree
`ffeca6fce85ff9606c7dab3f38b065bdbfdfeb70`. [Evidence and native steps](CHAT_QUICKJOIN_ANCHOR.md).
No client sync/deployment, settings reset, main update or push. Vendor-open native
hitch confirmation remains pending; deferred callbacks remain outside this batch.

Chat-anchor documentation validation passes: 761 classified sources, 577 reachable
files, 361 setting definitions, 23 SavedVariables roots and 12,788 local links.
All six ledgers have valid row shapes (1,384 parity, 35 ownership, 22 API, eight
client, 77 reference and 173 performance rows). All 728 Lua hashes match the full
report. The fresh checkpoint comparison finds no missing files or unexpected
changes and preserves 348 specification/library/asset/manifest files byte-for-byte.
Explicit development-tool markers remain absent across 1,225 actual files outside
Git. Main remains unchanged; native acceptance remains pending.

## 2026-10-29 — repeated vendor tier work

Continued on the clean existing branch; main and deferred callback scope unchanged.
User clarified that the Era spike occurs on every same-vendor reopening. Read-only
Era hashes matched the earlier junk/buyer/chat fixes. Era Config.wtf saves
scriptProfile=1; active runtime state was not observed and no preference was changed.
Fresh verified external checkpoint at 12:04:44 UTC / 13:04 Copenhagen includes all
1,225 files, history and 403 private settings files with WoW closed. Verified all
728 baseline Lua hashes against the prior 87-script suite.

A blanket index skip would suppress consumable reference seeding. Instead, PERF-005
moves live usability after classification in two vendor tier loops, retaining
reference discovery, level/skill checks on matching contenders, thresholds, ties,
Well Fed/food-water rules, retries and UI timing. No new resources or caches.
Classification before level rejection can shift cold work; native cost remains
pending.

`lua tests/vendor_tier_work.lua --baseline --measure`: 340 checks, 12 expected
baseline failures; measure mode exits zero. Candidate passes 340. Actual production
buyer/index/post-index seed and Score/tier modules run with classification/native
facts modeled. Five alternating pairs cover legacy/modern APIs and 20/200 listings.
Large-vendor initial seed info/ownership lookups 1,000 to 10 each; separate status
2,000 to 20 each. After the cadence clarification, added 25 same-vendor reopens with
retained food/water refs and three unoffered families: 15,000 info and ownership
lookups each to zero (small vendor 1,500 each to zero). Classification counts remain;
all count ranges zero, buyer frame one and purchases zero. These are service calls,
not native CPU/cache misses or FPS.

Bag-tier controls pass 16,527 checks; merchant identity/stock 837 and junk availability
265. Final `python tests/run_validation.py --output docs/validation/vendor-tier-full-2026-10-29.json --sync-docs`:
88 scripts/729 syntax files pass. The final full run includes the repeated-open
extension. Native pixels/input/taint/security/CPU/memory/latency/frame times/FPS remain
pending. No sync/deployment/settings reset/push or main update.

Runtime `17628269f0e3b7fbeb1b8c2d7f9c7196829e67f3`, tree `0c681c46987fc5b136274bba59e5e5bb3dd90990`.
Repeated-open test carrier `e7ec46a4070c132ff8bf6033d6bef5e2c92f90aa`, tree
`4507ccd1456e42f9acdea0e2be4aaad073ff72ae`. [Evidence/native procedure](VENDOR_TIER_WORK.md).

Vendor-tier documentation validation passes: 762 classified sources, 577 reachable
files, 361 setting definitions, 23 SavedVariables roots and 12,807 local links.
All six ledgers have valid row shapes (1,384 parity, 35 ownership, 23 API, eight
client, 77 reference and 217 performance rows). All 729 current Lua hashes match
the full report. The fresh checkpoint comparison preserves 348 specification/
library/asset/manifest files byte-for-byte, with no missing files or unexpected
changes. Explicit development-tool markers remain absent across 1,234 actual files
outside Git. Main remains unchanged; native repeated-open acceptance is pending.

## 2026-10-29 — native Era vendor tier counts

Continued on the existing clean branch at d3bce5b; main stayed
7436820453d2248c84c99fff71507553efc47c19. Read current contribution rules,
requirements, diagnostics and affected tier sources/tests. Fresh verified external
checkpoint at 12:35:23.862522 UTC covers 1,234 actual files, history and 403 private
WTF files. Both clients were running: on-disk settings only, not a quiescent state.
Verified all 729 baseline Lua hashes against the prior complete report.

User authorized native vendor commands, then requested ordinary PC use with WoW
in the background. Clean foreground Era 1.15.9.70576 capture with four reopenings,
three automations temporarily off and profile=1 reproduces a 333 ms maximum UI
interval. GetRestockTargetItems: four calls / 1,281.123 inclusive ms; GetTierCount:
20 / 707.280 ms; cached-bank getter: 20 / 457.873 ms. 5,250 tooltip calls expose
unrelated live usability checks in those count loops. Earlier interrupted captures
are excluded; this one pilot is attribution, not five full-window matched pairs.

PERF-006 moves tier membership ahead of live usability in the existing two count
functions. Retains matching live gates, caches, quantities, inferior protection,
strict/loose bank semantics, vendor-first deduplication and live fallback. No new
runtime resources/settings; no auction, guild-bank or void callback edits.
Runtime/test/nonloaded fixture commit `013bf40db1d5b57c238ac3ac377e8ced98446fd1`,
tree `4f0d827bb26bba3ee8b20e21de891596fad0e98b`.

`lua tests/tier_count_work.lua --source tests/fixtures/tier_count_match_before.txt --measure`:
1,710 checks with ten expected baseline performance failures. Candidate passes all
1,710; five alternating fresh-process pairs reduce initial/repeated legacy live
checks 1,350/33,750 to 17/425; modern 1,500/37,500 to 18/450. Bank-store reads remain.
Existing tiers 16,527 checks, vendor tiers 340, stock/identity 837 and junk 265 pass.
Full `python tests/run_validation.py --output docs/validation/tier-count-full-2026-10-29.json --sync-docs`:
89 scripts, 730 syntax files, zero failures.

Native comparison continued without activating Era: original loaded references
versus exact source-derived local candidate count functions, one warm pass, query
cache invalidation and five alternating pairs. Median CPU per five kinds:
bags 132.199 -> 15.237 ms; cached bank 118.897 -> 22.517 ms. Tooltip calls 455 -> 5
and 450 -> 5. Quantities identical in every pair; personal-bank results all zero.
Native positive-bank/warband acceptance remains pending. Net memory deltas include
harness and GC and are not allocation measurements. No native API replaced.

Original three automation flags restored true, profiler preference remains 1;
temporary sampler/namespaces cleared by reload and diagnostic SavedVariable exports
removed. User's existing sync delivered candidate source, verified before reload.
WoW remains in the background; no further focus/input access. Full vendor after
latency, matched pixels/input, unprofiled FPS, cold work, taint/security and other
clients remain pending. [Evidence and exact steps](TIER_COUNT_WORK.md).

Tier-count documentation validation passes: 763 classified sources, 577 reachable,
361 setting definitions, 519 literal defaults, 23 saved roots and 12,824 local links.
Six ledgers have valid shapes: 1,384 parity, 35 ownership, 24 API, eight client,
77 reference, 242 performance. All 730 normalized Lua hashes match the full report;
raw/normalized candidate hashes match committed source and the native probe hash
matches the exported source-derived chunk. Checkpoint comparison preserves 361
specification/library/asset/manifest/XML files byte-for-byte, with no missing or
unexpected changes. Explicit development-tool markers remain absent across 1,244
actual files outside Git. Main unchanged; native after whole-vendor acceptance
remains pending. No additional foreground/game input used during final file work.


## 2026-10-29 — objective tracker first-module scroll gap

User screenshot shows Campaign below an empty gap while fully scrolled up; requested
Retail and Forever coverage. Baseline HEAD e1132d0948906acef72be9e4c28dff60a5736931
was clean. Verified external source/history checkpoint
`tracker-checkpoint-20261029T141542Z` preserves 1,244 actual files and all Git refs.
No settings modified; WoW remained in the background. Existing sync was left alone.

The supplied Retail native XML reserves topModulePadding=38; its OnLoad callback
captures Frame.Update before Flux hooks and directly invokes ContainerMixin.Update.
The previous container after-hook was Forever-only, so Retail restored the blank
header gap and bypassed scroll sync. Both clients now share that after-hook, with
a combat early return. Deferred sync repairs the first module before its unchanged-
height shortcut. Native padding/providers remain untouched. SizeScrollContent also
restores zero after a child-rectangle refresh, removing the positive-offset-only gate.

New tests/objective_tracker_scroll.lua replays the supplied native Retail/Forever
container and frame code, including the callback captured before hooks. Original
source: 11 failures among 40 checks; candidate: all 40 pass. Covers Campaign/Quests,
equal-height section replacement, overwritten anchors, wheel targets, preserved
scroll offsets, shortened lists, zero restoration and Questie ownership. Existing
combat and Questie smoke checks pass. Full validation: 90 scripts, 731 Lua syntax
files, zero failures in validation/objective-tracker-scroll-2026-10-29.json.
These are desktop dispatch/geometry results using reference trees; installed-client
rendering, secure execution and taint remain pending. No native performance claim.

## 2026-10-29 — whole-addon Retail performance and resource audit

Preserved the pre-existing uncommitted tracker correction/test/docs in a verified
external actual-file checkpoint at 14:39:06 UTC (15:39 Copenhagen): 1,246 files,
all Git history, 403 private on-disk WTF files while Retail ran. Verified all 731
baseline Lua hashes against the 90-script tracker report. Main unchanged.

Whole-addon ownership/recurring map covers 577 reachable files and 26 source
folders. Native Retail 12.1.5.70575/interface120105/project1, level81 Mage in
Stormwind, built-in inventory, three loaded addons, original profiler0. Five
20-second background profile1 captures after 30-second warm-up: median addon CPU
30.772 ms/s (30.107-37.046). All ten endpoints retain 14,742 total frames, 1,449
Flux-source frames, 458 visible, 212 registered OnUpdates and one shared subscriber;
eight sampled public cache sizes unchanged. Requested-capture memory grows after
GC; ordinary gameplay leak rate is not inferred. Nameplate/assistant CPU remains
for separate matched timing-preserving work. No foreground/mouse/clipboard control.

BUG-009/PERF-007 replay reproduces repeated readiness/combat frame allocations.
Runtime/test/fixture `6ac4389` reuses owners; five alternating desktop pairs reduce
203 frames to 3 with one hook/101 geometry writes unchanged. 2,050 checks pass,
20 baseline failures. Cleared requests disarm regen. Same timeout and six-pixel
anchor; native loot/combat trigger remains pending.

BUG-010/PERF-008 runtime/test/fixture `3046478` clears completed/cancelled full
capture snapshot and timer references. Five alternating desktop pairs retain
20 -> 0 full snapshots / 10,000 -> 0 frame rows per model; 400 checks after 200
baseline failures. Existing capture 383 checks/12 rejected mutations pass. The
full current actual-file suite passes 92 scripts/733 syntax files, including the
preserved pending tracker test. New runtime commits exclude that separate work.

Source checks find existing mirror-timer installation guards; corrected stale QoL
prose, with no duration runtime change. Binding/macro/spell/visual cache controls
retained; older inspect GUID TTL without eviction remains an unmeasured candidate.
Incomplete long-upload private native comparison was discarded after truncation;
no missing candidate result invented. Follow-up uses direct file-loaded capture
calls. Native foreground FPS/pixels/input/taint, long-session/private-cache churn,
other clients and full interaction acceptance remain pending. Excluded callbacks
untouched. [Detailed evidence](RETAIL_PERFORMANCE_AUDIT.md).

Native direct follow-up completed five actual file-loaded20-second profile1
captures. Post-GC addon memory24,105->24,928 KiB across retained reports versus
24,115->64,565 KiB before; median capture-associated delta186 versus7,860 KiB.
Endpoint gaps90-235sec versus22sec and changed camera/frame totals(14,588 versus
14,742) prevent strict gameplay/CPU/FPS causal acceptance. After CPU21.315 ms/s
median is context, not a claimed speedup. A later failed scripted export was also
discarded. Original profiler0 restored and temporary SavedVariable/namespaces
cleared by normal reload. WoW remains open in the background; no native API replaced.
Public raw samples and commands contain no private settings/account names.

## 2026-10-29 — shared Social offset, reload and all-tab geometry

User supplied cropped alignment reference, requested a slight downward adjustment,
then reported reload/tab-only recovery and Combat Log displacement. Fresh verified
15:32 UTC checkpoint includes1,263 actual files, history and403 on-disk WTF files
while Retail ran. All prior tracker/audit work preserved; main unchanged.

Final shared inset8 UI units uses existing primary tab-height service in column
owner coordinates. Relative height survives a provisional chat rectangle moving
later at login without another tab selection. All holder placement now anchors to
ChatFrame1 instead of selected Combat Log/Global/custom window geometry. Selected
Copy target, buttons/actions/art, settings, native ownership, scales, overflow,
combat waiter and three retry deadlines remain. No new runtime resource/framework.
Commits78fe4e7 and7f13000; exact identities/raw results in CHAT_COLUMN_ALIGNMENT.md.

Expanded actual column/social fixture:1,311 original plus508 ownership plus190 new
checks=2,009 passing; frozen baseline fails100 new assertions. Five alternating
pairs have zero count variation;100 layouts add no frames, same point writes;
shared tab-height reads are explicit correctness overhead. Existing chat layout165,
startup478 and retries5,869 controls pass. Final whole actual-file suite92 scripts/
733 syntax files passes, including the preserved pending tracker test.

Native Retail12.1.5.70575/interface120105/profile0 geometry has Social8 units below
menu/tab top (was33); measured surrounding rectangles unchanged. A private untouched
post-reload image was inspected before chat/tab input. Seven native out-of-combat
General1/Global3/CombatLog2 selections sample identical visible Social left57.600/
top361.059 after2seconds without further chat input; original observed tab restored.
No OS activation/mouse/clipboard/native API replacement. Temporary geometry/tab
exports removed by normal reload; original profile0 retained. Other native clients,
combat/taint and full-screen pixel/FPS acceptance remain pending.

Final combined verification:92 scripts/733 normalized Lua hashes pass. Source
inventory766, reachable577, setting definitions361, literal defaults519, saved
roots23, local links12,868. Ledger shapes valid:1,384 parity/35 ownership/28 API/
eight clients/77 references/308 performance/26 audit-domain rows. Protected361
files remain byte-identical; tracker source/test preserved. Explicit development-
tool markers absent across1,271 actual files outside Git. Main unchanged. Native
temporary data removed; original profile0 retained. Generated records remain with
the user's separate pending tracker work; focused runtime/evidence commits exclude it.

## 2026-10-29 - PERF-009 and original-plan continuation

Reviewed actual branch/main/dirty tree, contribution/status/decision/work records,
supplied original plan and relevant nameplate/action-bar specifications. Confirmed
all26 specification requirement ledgers remain available; added explicit original
stage-gate tracking and restored root continuity files as the user requested.
Verified external actual-file/history/settings recovery before runtime edits.
Preserved the unrelated pending objective-tracker source/test/docs.

Reproduced duplicate countdown discovery and temporary per-aura level tables in
real Core/Countdown replay. Runtime `efca305` reuses the current poll's discovered
region and unrolls the same guarded three level reads; no cross-poll cache or new
resource. Five alternating desktop pairs retain same text/anchor/level/frame counts
while discovery halves and measured transient desktop heap falls.1,160 checks,
100 remove/re-add cycles and5 mutation controls pass. The first full run exposed an
existing source guard tied to the exact two-argument helper spelling; adjusted it
to accept optional arguments while retaining label-before-fade ordering. Full
rerun passes93 scripts/734 syntax files; no unexplained runtime failure remains.

At the user's reminder, executed background Retail12.1.5.70575 real-widget native
checks and full-addon20s before/after windows after30s scheduled warm-up. Frozen
baseline file loaded by normal reload; candidate restored in normal folder and
loaded by normal reload. Source transport changed header comment punctuation only;
exported source executable lines/literals and full ASCII diagnostic probe verified.
Five alternating2,000-update native widget pairs: medians33.371 ->31.712ms; all raw
samples/ranges retained, one candidate slower. Geometry/font/alpha/hide-reuse match;
BugTabs counts0 before, after fixture and after candidate window. Private baseline/
candidate screenshots retained outside Git. Camera/mount/plate density changed,
so full-addon performance/pixel comparison is inconclusive. Legacy CPU is
unavailable with profile0; do not interpret its zero as no addon work.

Native diagnostics/root/globals/temporary frames removed by normal reload; original
profile0 unchanged and WoW stays open in background. No mouse/clipboard/activation,
API replacement, settings reset, new addon/repo, deferred callback audit or main
change. Actual protected aura rendering/security/FPS, long sessions and other
clients remain pending. Updated stage/evidence/client/parity/performance/API records.

## 2026-10-29 - PERF-010, action bars and player auras

Inspected current branch/main/dirty work, root rules/continuity, original action/
unit/minimap requirements, manifests, current paint/watch/API/auras and existing
regressions. Verified fresh external recovery of1,284 actual files/history and404
on-disk settings files with both clients/sync running. Preserved pending tracker
source/test/records. Read the supplied sync script as context; did not execute or
modify it. Actual timeout1s despite60s text remains external measurement load.

PERF-010 `677d85c` shares one activation boolean within existing highlight/Flush
batches. False is explicit, direct callers stay fresh and next-spell helper keeps
its guard. No cache/resource/framework/cadence change. Real-source regression1420
checks covers100 toggles per branch, state/identity, minirow construction, cleanup,
geometry and combat effects. Frozen baseline20 work failures; five alternating
fresh-process pairs have identical operation/resource budgets except activation
5800 ->100 disabled/5900 ->200 enabled. Five mutations rejected. Full94 scripts/
735 syntax files pass. Native aura smoke, player ownership and17454 bar-refresh
checks/19 mutations retain their scope.

Logged in requested Retail/Era characters using observed normal warning dismissal,
Reconnect and Enter World controls; same-account sessions conflict, so tests ran
serially. No OS activation/mouse/foreground keyboard/clipboard, credentials,
restriction bypass or API/script replacement. Retail12.1.5.70575/project1 and
Era1.15.9.70576/project2(SoD) each pass five alternating real57-button inactive-
highlight pairs. Exact received ASCII source/probe strings verify;5800 ->100 calls
per100 passes, medians5.303 ->2.728ms Retail/8.568 ->3.079ms Era. All57 button
shapes and native aura root anchors/scales/visibility match; matched-run errors0.
Root native OnEvent references stable during baseline observations. Separate20s
complete-addon windows after30s warm-up remain inconclusive for overall CPU/FPS.
Native player aura inclusive idle cost is small; no aura rewrite justified.

Verified577 potentially reachable source files equal on Era baseline. Existing
mirror lagged the temporary version; copied only verified Paint.lua between the
known versions and restored candidate in normal source/Era, byte-equal. No second
addon/repo or extra mirror job. Restored Retail profile0/root nil and Era profile1/
pre-existing diagnostic report, deep-equal after reload. Temporary namespaces and
closures cleared; both processes left open, Era in world, Retail warning dismissed.
Updated ownership/client/parity/API/performance/original-plan records. Actual active
combat/secure input, dense/restricted aura and long-session acceptance stays pending.

## 2026-10-29 - complete GitHub publication preparation

User requested uploading the complete current addon, then explicitly authorized
main. Inspected working tree/rules/continuity/remotes and preserved a fresh external
checkpoint including dirty/untracked files/history and404 on-disk settings files.
Checked/fetched GitHub main at7436820; existing development history descends from
it. Audited outgoing files/history for private credentials/account paths/archives;
no findings. No force push, game interaction, settings change or new sync job.

Included the formerly pending tracker source/test/chapter/API row and historical
focused report in73ca9d2. Focused40 checks pass; the prior complete report's735 Lua
hashes match the actual combined source. Rerun the full publication suite, reconcile
generated references and validate docs before pushing both main/development refs.
Private recoveries/settings/captures and ignored helper files remain local. Current
native limitations and remaining optimization gates are not promoted to complete
by this upload. Git ref verification establishes publication outcome.

Publication outcome: atomic push advanced GitHub main from7436820 to421c05a and
created the retained development branch at the same payload. Remote refs read
back exact; local main clean and0 ahead/behind. All735 runtime/test Lua hashes
still match the passing94-script report. This completion receipt adds docs only;
no game interaction or source/settings change during upload.

## 2026-10-29 - main-only current local snapshot

User requested main only, then clarified that the actual local files must all be
uploaded. Found newer uncommitted teleport source/test/docs, preserved them in a
verified external recovery covering1,302 actual files/history and404 on-disk
settings files. Both branch refs equaled b45eb5e; deleted the fully merged branch
locally/remotely. Main retains every published commit.

Inspected the local teleport delta and existing evidence. Its full95-script/
736-Lua report exactly matches current code; focused527 checks pass again. Include
this local fix and all current records, run the fresh local-snapshot suite, refresh
references and publish only main. No older checkout, runtime rewrite, force push,
new branch, private data upload, game input/settings or sync-job change.

## 2026-10-30 - unit power separator and text follow-up

User observed a middle border after target/ToT changes, misplaced text on
resource units, and a missing ToT split border. Retained the existing full-height
health layer. Reapplied separator alpha after partition and border-color paint,
kept restricted-max health text in the upper health area, and removed a Lua
truthiness test of a secret maximum. Expanded the focused desktop model with a
separator repaint and ToT zero/positive/secret transitions. Full validation:
96 scripts, 737 Lua syntax files, zero failures. Native all-client geometry,
secret and combat checks remain pending. No game or settings changes.

Follow-up: user specified that HP text should be vertically centered when
there is no resource, with the prior placement when resource returns, and asked
to repair ToT's HP/resource split. Player/target known-zero transitions now
refresh text anchors, including on `UNIT_MAXPOWER`. ToT's UIParent separator
container follows the raised ToT button level in side-by-side placement and
returns to its original level in stacked placement. Focused power and idle
geometry checks pass; full validation again passes 96 scripts and 737 Lua
syntax files. Native pixels remain pending.

Publication: preserved a fresh external source/history checkpoint
`Publish-unit-power-20261030T101822` with 25 changed files and a verified
history bundle. The outgoing archive had no private paths or credential-pattern
matches. GitHub main matched local parent `058efb8`; ordinary push published
`c313dc98a1e782aee1224554c347cd616f3ad7af`, and GitHub ref readback
matched. Native acceptance remains pending; no game or settings interaction.

## 30 October 2026 - combined local updates publication

User requested all current updates on main again. The publication includes the
local unit-frame scale controls and alignment fixes, vehicle/durability placement,
status-bar changes, vendor denomination messages, tests and their records.
The fresh [combined validation](validation/main-publication-2026-10-30.json)
passes 100 scripts and 741 Lua syntax files with zero failures. Native acceptance
retains the pending scope recorded in the feature chapters. No game/settings
interaction or runtime edits were made for publication.

Remote main matched parent `021b524893229fece34eff503a8ac1cf66388363`.
External checkpoint `Publish-all-20261030T104001Z` preserves 1,314 actual local
files and verified Git history. Source ZIP SHA-256:
`f7fb816f0651d264fbd30e9187afb2af8e17170aa39da02580d785b44c5f2176`.
Private archives/settings/captures and ignored local sync helpers stay outside Git.
Publish by ordinary push to main and verify remote identity and worktree status.

## 30 October 2026 - latest local updates publication

User requested another upload of all current local updates to main. This batch
includes first-load nonbinding settings reconciliation, Retail Sticky Targeting
and camera follow-ups, capability detection and Hearthstone editor load-order /
item-info fixes, plus their tests and documentation. The fresh combined report
`docs/validation/main-publication-latest-2026-10-30.json` passes 106 desktop
scripts and 748 Lua syntax files, with zero failures. Native checks retain
their pending status; no game input, settings changes or runtime edits were
performed for publication.

Remote main matched parent `52659bd8d22559dc0943ddd999e681d84d705d8e`.
External checkpoint `Publish-all-20261030T180617Z` preserves 1,350 actual
local files and verified Git history; source ZIP SHA-256
`0c5cb6547bf035eb33ec362603ca544f53079e71f6d31e0e5185d24ef80422d7`.
Private settings/captures/archives and ignored local helpers remain outside Git.
Use an ordinary push on main and verify remote identity and clean status.

## 30 October 2026 - cursor loot publication

User requested uploading all current local updates to main again. Include the
cursor loot and fast-pickup module, Tools / Loot options, money alert coin art,
profile callback correction, tests and evidence. Native post-fix acceptance
remains pending as documented in `docs/LOOT_CURSOR.md`. Publication makes no
runtime edits and does not interact with the game or saved settings.

External checkpoint `Publish-loot-20261030T190738Z` preserves 1,363 actual
local files and verified Git history, including untracked work. Source archive
SHA-256: `ef98ebb61f9e132697f5b69b699b544b82059444c436c4d56c8123cfd8af24d3`.
GitHub main matched parent `b68f2545fa53e83a7eb8482b73e2c0569ecdcc38`.
The combined publication evidence is `docs/validation/loot-publication-2026-10-30.json`.
Private settings, archives, captures and ignored local helpers stay outside Git.
Use an ordinary main push, verify remote identity and preserve history.

Fresh combined desktop validation: **107 scripts /751 Lua syntax files, zero failures**.

## 30 October 2026 - attached stance scale

30 October 2026: attached stance bars now follow player-frame scale, including
immediate slider changes and reload; detached placement restores normal size.
Existing combat deferral is retained. 21 stance and 28 bridge checks pass;
full suite: 108 scripts /752 Lua syntax files, zero failures. Native pixels,
input and taint remain pending (no visible WoW process).

Match effective parent scales at the existing stance anchor/layout entrypoints.
Refresh only the anchor after a player whole-scale change; avoid rediscovery
and binding work for this geometry correction. Source/history/settings recovery
and exact before/after hashes are in [the scale record](UNIT_FRAME_SCALE.md).
No game/settings interaction or competing framework; excluded callbacks unchanged.

## 30 October 2026 - stance, loot and Micro Menu publication

User requested uploading all current local updates to main. The complete payload
includes attached stance scaling, loot source filtering / cursor pinning / delayed
source routing, the Micro Menu nil-center fix, tests and their records. All 753
current normalized Lua hashes exactly match the passing 109-test combined report
`docs/validation/micromenu-nil-center-full-2026-10-30.json`; no Lua file is missing
from that report. Reused this verified combined evidence without rerunning an
unchanged suite. Documentation references and verification index are refreshed.
Native pending checks retain their stated scope; no game/settings interaction
or runtime edits were made for publication.

External checkpoint `Publish-updates-20261030T202520Z` preserves 1,376 actual
local files and verified complete Git history. Source ZIP SHA-256:
`f6351660aa5a58daffb70c8aa9c3d2a70d5774f1eb112d8ae36d4f8070c1025b`.
GitHub main matched parent `57a252e0e2b467cf7788c3f52aa5d1dd8d83779e`.
Private settings/captures/archives and ignored local helpers remain outside Git.
Publish by ordinary push to main, then verify remote identity and clean status.

## 1 November 2026 - GitHub feature overview and current local publication

1 November 2026 GitHub publication: added a root README with a compact feature
overview covering the current inventory, links to all detailed feature controls,
client-specific availability, companion integrations, installation and command
entry points. The complete local payload includes the pending chat durability
loading-screen correction. Fresh combined desktop validation passes 113 scripts
and 758 Lua syntax files; native pending checks retain their recorded scope.

The README describes shipped feature families, not every historical specification
as implemented. Existing detailed feature/options/commands/integration references
remain authoritative for controls and client gates; no new competing inventory
or universal client-certification claim was added. No runtime edits, live game
interaction, settings/profiler changes or excluded callback work in this task.

External checkpoint `Publish-readme-20261101T130027Z` preserves 1,396 actual
files and verified Git history, including all pending/untracked work. Source
archive SHA-256: `5981eedb563317b7e56ea089022528741a966a4ec72ac3672a5c3aef6a6b873f`.
Remote main matched parent `0e73e74a6e782a30fd04289bc84bbf551c440fd8`.
The [fresh publication report](validation/github-readme-publication-2026-11-01.json)
covers the complete local Lua source. Publish all current addon/test/docs and the
new README by ordinary push to main, then read back the remote identity. Private
settings, recoveries, captures and ignored sync helpers stay outside Git.

## 4 November 2026 - publish current local mail work

User requested all current local updates on GitHub main. Include the built-in
mail modules, TOC/settings wiring, tests, README feature summary and existing
implementation/validation records. All 777 current normalized Lua hashes and
the complete Lua file set match the passing 122-script report
`docs/validation/mail-integration-2026-11-04.json`; no runtime edit or repeat
full suite was needed for publication. Mail attachment forwarding, repeat send,
advanced completion and native acceptance retain their documented pending scope.

External checkpoint `Publish-all-20261104T175541Z` preserves 1,421 actual
local files and verified complete Git history, including untracked work.
Source ZIP SHA-256: `fe1f8879d41952e1cc9debc30c000fef49fdcaa6f1dddb09295ca7994e1b76ef`.
GitHub main matched parent `1b319d19aa00fffa7e798a66d045e55902af6706`.
Private recoveries/settings/captures and ignored local helpers remain outside
Git. Use an ordinary push to main; verify remote identity and clean status.
No game, settings, sync-job or profiler interaction during publication.

## 5 November 2026 - Syndicator consumable batch metadata

5 November Syndicator consumables: batched bag callbacks now retain every
added/removed item and dirty bag until publication. This fixes a reproduced
missed selector update for better items and last-use depletion across food,
water, potions and bandages. Five desktop pairs: baseline 200 failures versus
candidate 0 per400 checks; three mutations rejected. Full suite123/778 passes.
Native gameplay, pixels, taint and performance remain pending.

Reuse the existing bag item-set log as the batch lifetime and merge classifications
with the existing inventory helper. Keep last-change getters readable; begin a
fresh classification after publication. No polling, framework, client API change,
settings reset or excluded callback modification. User authorizes publication
to main. [Source/recovery/native limits](SYNDICATOR_CONSUMABLE_UPDATES.md).

## 5 November 2026 - live-zero consumable reset

5 November live-zero follow-up: exhausted food/water/potion/bandage buttons
now reset from reliable live bags before Syndicator's delayed cache callback.
The painter retains the verified count; loading holds and combat deferral
remain. Button-level375 checks pass (baseline200 failures), three mutations
rejected; full124 scripts/779 Lua syntax pass. Native acceptance pending.

The prior notification regression did not cover provider-cache delay. Keep
external inventory ownership but verify these stack counts through the existing
live-count adapter; reuse the shared watcher and existing reset/combat paths.
The previous upload authorization remains applicable to this follow-up.
[Exact source, recovery and limitations](SYNDICATOR_CONSUMABLE_UPDATES.md).
No settings reset, native interaction or excluded callback change.

## 5 November 2026 - utility pet display ownership

5 November utility pet faces: the user clarified a question-mark/wrong-icon
symptom. The manager now owns the selected journal-pet icon and tooltip via
existing override surfaces, with modifier changes, metadata completion and
cleanup. Summon macros/GUID storage remain intact. 920 checks pass (old40
failures), three mutants rejected; full125/780 passes. Native checks pending.

Use the utility manager's resolved display entry and the existing icon/tooltip
override contract. Preserve generic macro parsing, secure summon bodies and
all saved assignments; metadata events reuse the existing refresh queue.
[Recovery, exact sources and limitations](UTILITY_PET_FACES.md).
