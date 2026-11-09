# Decisions

9 November repository replacement: user's explicit delete/recreate request
supersedes preservation of published ancestry for this one operation. Keep the
same URL and existing addon working folder; publish a fresh main snapshot with
DoctorFlux author/committer and no co-author trailers. Preserve old history,
uncommitted/untracked/ignored files and index externally. Preserve all licenses.
Install local metadata hooks plus read-only CI detection; do not promise a
GitHub account blacklist or protection against administrator bypass. Normal
future updates use main and never bypass the guard. [Policy](PUBLICATION.md).

9 November focus input ownership: use the existing Restricted service's tested
native visibility route for focus/focus-target, keeping protected Show/Hide and
click regions under Blizzard during combat. Use native `togglemenu` for ordinary
unit frames; executing addon-written callback attributes had forbidden focus
responders. Do not patch native APIs or add a custom focus menu. Native generic
menus lack an arbitrary dependent-NPC category: user explicitly chose to keep
mini-frame callback menus and use existing native focus bindings/macros there.
Their callback Set Focus entry remains a documented restriction. No new gesture,
binding or reset; unsupported focus clients stay gated. Forever native checks
and user combat/menu acceptance pass; wider native coverage remains pending.
[Decision and regression scope](FOCUS_SECURE_VISIBILITY.md).

9 November remaining native acceptance is blocked by the background-only rule:
Windows repeatedly reports Forever foreground. The latest alias probe refused
before its first key; the bounded35second availability process ended with no
stable non-game foreground and no input. Same condition recurred across three
goal turns; prior native progress is retained, not marked complete. Native slash
entry/Escape source ownership is verified, but no editor interaction ran. Current
261/928 source manifest still matches; no runtime/settings/profiler changes.
Resume with browser/chat continuously active and Forever behind it; verify normal
Edit Mode/custom save, matched previews, resource characters and other clients.
[Blocked audit](validation/cooldown-native-blocker-2026-11-09.json).

9 November native cooldown acceptance: Forever1.60.1/70862/16001 retained
exactly one selected FluxUI profile after a guarded native reload. BugTabs0;
all four sampled aura-map fields secure. All requested settings match the native
active layout. Four viewer positions match planned column offsets and4UI-unit
clearance from current player bounds within0.001units. This mage has no visible
class-resource row; Arcane/combo/form cases and other native clients remain open.
Native custom-save and matched preview pixels are also pending. Full261/928 and
documentation961sources/602reachable PASS. No runtime changes or preferences
changed; no foreground/mouse/clipboard control, gameplay or publication.
[Native evidence](validation/cooldown-native-acceptance-2026-11-09.json).

8 November every Info Frame stat audit (INFO-ALL-STATS-20261108): expanded the
earlier combat fix to all42 built-in keys and unknown dynamic pins.35 additional
keys now have live native display paths or retain public inventory providers;
spell/heal bypass old snapshots and partial CSC scans. Corrected signed AP,
versatility bonus and leech/avoidance totals; preserve compact merging and live
proc expiry. Native sums/scaling can require live component expressions; speed
can use yards/second. Hidden row-only custom stats remain unavailable. Do not
claim universal exact single-number support.645 new +234 prior focused checks;
five baseline rejects/candidate passes and four controls; full261/261 scripts,
928 syntax PASS with no source drift. No new frame/timer/hook/settings;13 native
event registrations reuse existing coalescer. Native acceptance remains OPEN;
no connected test tool. External verified2310-source/history checkpoint and52
read-only settings metadata retained. No game input/settings/profiler/diagnostic
writes or publication. [Scope and limits](INFO_ALL_STATS.md).

8 November cooldown acceptance audit: full current checkout261 scripts/928 Lua
PASS; complete normalized source manifest matches. This supersedes the previous
unrelated verification drift while preserving the newer stat files. All four
accepted images re-inspected; implementation remains unchanged. Completion is
not established: native saved settings/geometry, second reload/custom-save,
class-resource cases and other available clients still need matching evidence.
Forever was verified active/foreground; reload and settings probes refused before
input. Read-only screenshot confirms ongoing play, without changing focus. No
runtime/settings/profiler changes or publication. Keep the full goal active.
[Requirement audit](validation/cooldown-final-audit-2026-11-08.json).

8 November missing FluxUI profile (COOLDOWN-PRESENCE-20261108): latest user
instruction supersedes the earlier deliberate-deletion policy. Check actual native
layout existence, create one FluxUI profile when absent even after a prior save,
and leave an existing profile/custom selection unchanged. Reuse shared readiness,
combat/editor queues; retain recovery data and avoid repeating legacy retirement.
202 focused checks/five alternating baseline-candidate pairs PASS; old source
reproduces the failure. Full260 scripts/926 Lua PASS; owned sources unchanged.
Later unrelated FluxInfoFrame work preserved and its234checks PASS.
Forever70862 guarded reload created/selected exactly one FluxUI; BugTabs0 and
tracker top gap0/clampfalse. Reload persistence pending: foreground guard refused before input. Other clients,
matched visuals/combat/performance remain pending. No profiler change, foreground,
mouse or clipboard control, gameplay, commit or push.
[Evidence](COOLDOWN_VIEWER_DEFAULTS.md).
Documentation checker exposed newer unrelated FluxInfoFrameStats/source changes;
refresh full verification/inventory after that independent batch settles. Preserve
those files; current presence owner/tests still match the passing capture.

8 November tracker top recovery (TRACKER-TOP-20261108): native Forever evidence
confirmed the inner tracker's screen clamp displaced its first quests above the
viewport at scroll offset0. Disable that clamp inside the fixed viewport; settle
cached height and schedule coalesced sync after native profile anchors, deferring
while Edit Mode owns the frame.62 source-model checks/five baseline-candidate
pairs and full260 scripts/926 Lua PASS; source manifest stable. Permanent source
reload and native wheel down90/back0 pass on Forever70862 with BugTabs0; native
profile refresh, sustained combat and other clients remain separate checks.
The earlier deletion was intentional. The subsequent missing-profile request
supersedes that policy: create FluxUI when absent; preserve existing layouts. No settings/profiler changes, foreground/mouse/
clipboard control, gameplay, commit or push. [Evidence](OBJECTIVE_TRACKER_TOP.md).

8 November cooldown defaults (COOLDOWN-DEFAULTS-20261108): latest user choice
is one FluxUI layout for all four native cooldown groups. Single-profile source
and migration implemented; custom/native layouts remain. Only recorded,
unchanged test copies can be retired after exact native export comparison, with
bounded recovery data. Edited/unverifiable profiles stay intact.186 focused
checks, five repeated scenarios and four harmful controls pass. Full validation
and source-copy evidence accompany the batch. Forever70862 public-save metadata
PASS; user reports the prior two-copy build worked. Final single-profile native
reload/persistence/save/combat/pixels and other native clients remain pending.
Keep WoW background; do not interrupt auction/mail/trade or gameplay. No profiler
change, native preset patch, commit or push. [Requirements/evidence](COOLDOWN_VIEWER_DEFAULTS.md).

8 November Edit Mode ownership (EDIT-MODE-NATIVE-20261108): use saved widget
anchor methods under existing editor/combat guards. Supersede the global spec
event opt-out; keep the legacy public helper as a readiness query. Restore native
selector alpha/click/motion when Flux unit ownership ends. Leave native profiles,
scripts, secrets and private aura tables intact. User-reported native success is
separate from loaded-source/taint/performance proof. New cooldown defaults must
preserve custom layouts. [Details](EDIT_MODE_NATIVE.md).

8 November combat numeric-color capability audit
(COMBAT-NUMERIC-TINT-CAPABILITY-20261108; REQ-RF-96): user again requests actual
HP/resource values and percent to match the native border during combat on
player/target/focus/party. Latest branch heads re-resolved for all five clients;
Retail12.1.5.70783 and Forever1.60.1.70862 retain texture-only private dispel-color
sinks. SetDispelTypeText replaces values with a symbol/static label; it does not
color arbitrary live numeric text. Descendant/object-type/access restrictions
prevent registering external numeric fonts or reading private texture colors.
106pinned callback/validator probe checks plus13230existing lifecycle checks pass;
this does not implement the requested restricted-combat text change. Unrestricted
combat coloring remains available; native private border coloring remains. No
runtime changes, new polling/caches, game input or profiler/settings writes.
Exact all-client restricted numeric coloring remains unavailable through verified
exposed APIs and must not be marked complete. [Evidence](COMBAT_NUMERIC_TINT.md).

8 November universal mouseover (UNIVERSAL-MOUSEOVER-20261108): the user's
explicit preference keeps Focus/Self/cursor rules authoritative and applies
mouseover-first to Default/Target. This supersedes the earlier omission of
automatic native-client macro tails: native macros ignore the button's resolved
unit, so the existing compiler must emit compatible mouseover clauses and the
native modifier itself. Reuse protected click adapters and the existing Forever
probe; preserve native plain-action ownership, idle badge policy and deferred
combat writes. No CVar read in restricted snippets, API replacement, new hover
poller or forced settings migration. Range/LOS/cooldown rejection cannot trigger
an automatic retry. [Details](UNIVERSAL_MOUSEOVER.md).

8 November group roster performance (GROUP-ROSTER-PERFORMANCE-20261108;
REQ-RF-95): ordinary invites now reconcile prepared membership without hiding/
reconfiguring all headers or reapplying party/extra layouts. Retry incomplete party/optional-driver setup; keep full startup,
settings and readiness recovery, with combat visibility owned by native drivers.
Reuse the raid paint batch; combine party/pet show+roster paints, cast resampling
and range wake; coalesce optional pet/target paints and hover discovery. Roster
changes skip stable binding-data rebuilds; Edit Mode, settings/routing changes and
deferred combat registration still refresh. Aura checkbox/type/unit isolation stays.
Five matched pairs on five client models have invariant counts:213direct header
attribute writes->0;60hover discovery passes->1;920extra rebinds->0;5520extra protected
writes->0;800raid paints->40;168normal-party/pet paints->8. These are20-event replay
counts, not native FPS or latency measurements.163focused checks and twelve harmful
controls pass/reject; benign redundant-guard removal stays safe via inner guards.
Fresh35pinned upstream blobs verify; native source replays pass255908secure and58
member-order checks in desktop models. Full257/257scripts and922Lua syntax pass;
owned hashes and five installed copies match. New paints use bounded coalesced
After queues; no new ticker/event frame/OnUpdate. Source/history98files and47settings
metadata retained outside AddOns; no game input/profiler/settings writes/publication.
Actual client invite latency, rendering, protected VM/taint and performance pending.
[Evidence](GROUP_ROSTER_PERFORMANCE.md).

8 November friendly aura checkbox policy (FRIENDLY-AURA-POLICY-20261108;
REQ-RF-94): supersedes only RF93's unconditional dispellable-only rule. Checkbox
off now allows known typed harmful debuffs; on restricts to HARMFUL|RAID. Keep RF93
per-unit ownership, event routing and same-token target/focus refresh. Explicit
frame/Flux checkbox false wins over unrelated native CVars; use the relevant
Blizzard preference only without a Flux override. No combined global OR state.
One native owner per chrome part switches its public slot filter in place;
includeDispelTypes skips unknown candidates. Public/legacy bounded scans skip
unknown types too, so an untyped first entry cannot mask a later known one.
Portrait backdrop/fills and saved values remain unchanged. Native private border
colors/public-only numeric tint remain; real game pixels/taint/performance pending.
13270 focused checks pass across five clients/two providers, including both toggle
directions, conflicting settings, known-after-unknown and independent live-unit
palettes. Baseline plus eight controls rejected; five matched correctness pairs
retained. Full256/256scripts and921Lua syntax pass; owned hashes match tested source.
External source/history plus47settings metadata retained; all five installed
copies match via user sync. No game input/settings/profiler writes or publication.
[Evidence](validation/friendly-aura-policy-2026-11-08.json).

8 November Info Frame live combat stats (INFO-COMBAT-STATS-20261108): the user chose
to keep the previously highest category live while combined stats are restricted.
Forever now remembers category identity rather than switching to melee; Retail
Crit/Haste use native getters throughout instead of partial CSC scans. Procs and
expiration stay live; ammo haste and correct hit rating/modifiers are retained.
No cached percentages or new runtime driver/settings. 234 focused checks pass;
five baseline rejects/candidate passes and four negative controls; final
256/256 scripts and 921 Lua syntax files pass with no source drift.
Native secrets/taint/pixels/performance remain pending; prior UIForever preference
retained but no connected testing tool. External verified source/history and
52 read-only settings metadata entries retained. No game input, settings,
profiler, diagnostic-root writes or publication. [Contract](INFO_COMBAT_STATS.md).

8 November friendly dispel isolation (FRIENDLY-DISPEL-ISOLATION-20261108;
REQ-RF-93): supersedes RF92's ordinary-debuff tint fallback. A known type alone
cannot trigger frame color: live chrome/numbers now use only HARMFUL|RAID, the
client player-dispellable filter, even when other debuff icons are visible. Unknown
or non-dispellable effects leave normal colors. Native SetUnit skips unchanged
unit tokens and has no target/focus identity event: explicitly refresh the public
owner on target/focus swaps, roster/world/show/options invalidation. UNIT events
only queue the matching unit or a verified alias; no shared color/strict state.
Regression now gives player, target, focus and party different simultaneous aura
data; covers alias swaps without UNIT_AURA, target=self, hostile/roster changes and
combat no-allocation. 9686 focused checks pass across five clients/two providers;
exact native SetUnit replay, baseline plus six rejected controls and five matched
correctness pairs retained. Full255/255scripts and920Lua syntax pass. Up to three
native owners/frame replace six; addon driver/timers unchanged. Native private
border colors/public-only numeric tint remain as documented; actual game pixels,
secret data, protected VM/taint and CPU/memory/FPS still pending. External verified
source/history plus47settings metadata retained; owned source hashes and all five
installed copies match. No game input/settings/profiler writes or publication.
[Evidence](validation/friendly-dispel-isolation-2026-11-08.json).

8 November friendly debuff chrome (FRIENDLY-DEBUFF-TINT-20261108; REQ-RF-92):
known debuff types tint portrait and HP/resource border overlays plus numeric
value/percent text on friendly player, player-style party and friendly target/focus.
Portrait backdrop and HP/resource fills remain unchanged. Missing/unknown types
keep normal colors. Prefer dispellable types; honor Blizzard showDispelDebuffs and
raidFramesDisplayOnlyDispellableDebuffs plus the party strict option; refresh on
CVAR_UPDATE. Restore on hide, hostile transition, option disable or removal.
Native descendant Texture slots handle private border colors on Retail/Forever;
existing HP/resource FontStrings have no native private dispel-color binding, so
text uses readable known types and restores normal color while restricted. Classic
uses its client display table and guarded public aura data. No private-child reads,
new settings or protected combat construction. Preview uses the same public color
path. 8632 focused checks across five client models/current and legacy providers,
six rejected controls, 255/255 scripts and 920 Lua syntax files pass. Owned hashes
match tested source; all five installed copies match through user sync. One event
driver/coalesced batch; up to six native slot owners per eligible frame; their
native update cost is not measured. Real pixels, secret data, protected VM/taint
and performance acceptance remain pending. External source/history and 47 read-only
settings metadata entries retained; no game input, manual sync or publication.
[Evidence](validation/friendly-debuff-tint-2026-11-08.json).

8 November carried combat-consumable junk (JUNK-CARRIED-COMBAT-20261108):
separate the current-bag junk cutoff from remembered purchase thresholds. A learned
or affordable recipe is not ownership. Apply the cutoff to automatic age rules,
stored marks, pending upgrades, display and inferior sale availability; preserve
explicit lists, manual restock and food/water behavior. Cache candidates in the
existing tier cache, recheck live ownership/usability, and skip equal/lower-tier
count queries. This narrows the supplied spec's memory-based junk policy for
combat consumables under the user's explicit clarification; no settings reset.
[Contract and validation](CARRIED_COMBAT_CONSUMABLE_JUNK.md).

8 November stable owned grid buttons (GRID-STABLE-OWNED-20261108): use the
classifier's explicit negative cache for rejection; missing tooltip/pending state
alone cannot reject an owned potion. Keep a validated, positive bag latch visible
while selection refreshes; explicit modes and eligibility still take precedence.
Reuse existing count, selection and combat deferral services. This avoids adding
retry work or a time-based grace period that could retain real depleted items.
[Reproductions and boundaries](CONSUMABLE_CRAFT_IDENTITY.md).

8 November native combat unit menus (UNIT-COMBAT-MENUS-20261108; REQ-RF-91):
unit-frame hit rectangles now use Blizzard's secure menu action and direct
native callback, including party/pet/vertical targets, raid and MT mini cells.
Target/focus retain their specific native menu; generic slots follow their
current secure unit attribute through combat group changes. Prepare attributes
OOC; defer optional menu edits through the existing queue. Keep native click-
cast and explicit Flux hover-program precedence. No addon popup dispatcher,
new event/frame/polling or saved-data change. Ten source blobs fetched across
Retail, Forever, progression, Era and Anniversary; exact pinned native replay
passes 680 checks and rejects three controls. Existing 1010 party, 182 raid
binding and 310 party hover checks pass; 252/252 scripts and 916 Lua syntax files pass.
Owned final hashes and five installed copies match. Actual hardware/protected
VM/taint/native menu input remains pending. Dated source/history and 45 read-only
settings metadata entries retained. [Evidence](validation/unit-combat-menus-2026-11-08.json).

8 November grid bag/craft visibility (GRID-BAG-CRAFT-20261108): user clarified
that Auto potion/bandage slots stay visible with no carried output and no
currently affordable craft; Forever healing potions must use First Aid.
Reliable live bag reagent counts now override delayed positive snapshots.
The existing native notification invalidates craft cache and reuses the bounded
craft timer to refresh right-click and visibility, including empty output slots;
Off skips that native craft work. Existing Forever FirstAid129 versus Alchemy171
routing is retained/tested. Secondary metadata fix preserves pending state across
cache invalidation before selector notification. Four small runtime edits; no
new frames/events/hooks/tickers/saved roots or settings reset.1,030+439 focused
checks pass across5client models with/without provider; native acceptance pending.
Final full validation:251/251 scripts and915 Lua syntax files PASS; source
hashes unchanged throughout. Five alternating pairs per component reject the
baseline(100metadata/45craft assertions) and pass all1,469candidate checks;
six faulty mutations reject. Existing zero-reset375 and consumable1475 checks
also pass. All16 existing client file copies match through user continuous sync;
three read passes, no manual copy/second overwrite. Native candidate checks
remain pending; no new game input, settings/profiler writes, commit or push.
After that completed full/doc run, independent unit-frame files changed.
The four consumable owners and both tests remain at their tested hashes; those
later edits and current global generated freshness require their own validation.
No later whole-addon pass is inferred. See the recorded post-run drift list.
[Case](CONSUMABLE_BAG_VISIBILITY.md).

8 November Blizzard party debuff borders (PARTY-BLIZZARD-DEBUFF-BORDER-20261108; REQ-RF-90):
latest user clarification replaces the custom red/black rim in REQ-RF-89 with
Blizzard's own type border. Retail/Forever use native colored border atlases;
Classic preserves and tints UI-Debuff-Overlays through client AuraUtil. Native
owners handle restricted types, including the default untyped harmful border.
Readable icons and preview use the same client helpers; type colors remain
independent of the whole-frame dispel-highlight toggle. Layout/opacity/timers/
strict filters/input remain. One border texture replaces the custom edges.
12776 aura, 1010 party, 2944 layout and 1580 native-style routing checks pass;
250/250 scripts and 914 Lua syntax files pass. Final owned hashes and five installed copies
match. Native appearance/taint/performance remain pending. Source/history and
45 read-only settings metadata entries retained. [Evidence](validation/party-blizzard-debuff-borders-2026-11-08.json).

8 November party debuff borders (PARTY-DEBUFF-BORDER-20261108; REQ-RF-89):
normal party debuffs now have a solid dark-backed rim on their existing text
host above the cooldown swipe, including plain/non-dispellable categories.
Native dispel colors remain native-owned; readable and preview edges share
styling. Preserve icon sizes, zero gaps, opacity, timers, filters and input.
12776 aura, 1010 party and 3310 external style/ownership checks pass; full
249/249 scripts and 913 Lua syntax files pass. Final source hashes match the
suite and all five installed copies. Native contrast/pixels/taint/performance
remain pending. Eight textures per prepared party debuff; no new frame,
event, polling or timer. Dated source/history checkpoint and 45 read-only
settings metadata entries retained. [Evidence](validation/party-debuff-borders-2026-11-08.json).

7 November unit names/ToT and party cast lifecycle (UNIT-NAME-PARTY-CAST-20261107;
REQ-RF-87/88): fitted public names now retain their final text/font on repaint,
using unclipped metrics and the actual compact header width. Restricted current
names/surnames use native text sinks; unavailable identity clears old names.
ToT fitting guards restricted label reads and keeps its public fitted result.
Party cast hide/rebind clears stale cast/hold/fade/art/text; show and roster
updates read the current cast. Scoped terminal events accept missing GUIDs while
rejecting distinct readable identities/spells. Existing appearance, finish/
interrupt cadence, options, Flux bindings and saved-name settings remain.
681 name/ToT, 215 cast lifecycle and 1010 party/focus integration checks pass;
379 timer, 55 name-secret and 13942 school checks pass. Both regressions reject
the dated baseline. Full 249/249 scripts and 913 Lua syntax files pass, with
exact final owned hashes and all five installed copies matching. Native
Retail/Forever appearance, real secrets, input, taint and performance remain
pending. Exact existing Gethe pins revalidated; current branch-head lookup was
unavailable, so no latest-build claim. Verified external source/history and
45 settings metadata entries retained; no live settings/input/profiler changes.
[Evidence](validation/unit-name-party-cast-2026-11-07.json).

7 November roadmap implementation (ROADMAP-FIXES-20261107): all25 qualified
round-2 groups now have source fixes and focused desktop acceptance. Bindings
retain distinct punctuation/minus chords, exact modifier truth and latest held
tint; cancellation/reentrant completion belongs to the latest request. Owned
timers/retries/proxies are bounded, salvage defers protected combat writes and
public frame-level/color facts avoid opaque arithmetic. Vendor mount lookup is
localized/cached; disabled optional reticle work stops scanning faces. Range
uses unit-scoped fresh memo answers, action-scoped unknown state and independent
usable/red/pressed layers, retaining existing palette/art/features/saved data.
Full combined validation: 247/247 scripts PASS, 911 Lua syntax files PASS;
exact final suite hashes match. Rapid core/binding/EBS/utility/badge, same-slot
Context and range/usability/darkening replays pass with matched baseline rejects.
Prior Forever startAlpha fade-manager replay passes again. These are desktop
models; native secure VM/real secrets/input/pixels/taint/CPU/FPS remain pending.
Newer consumable, aura, vertical target health, PvP and minimap work is preserved.
External source/history checkpoint plus45 settings metadata entries retained;
no settings reset, foreground/game/profiler/WTF writes, branch, commit or push.
[Evidence](../Stress%20test%20doc/roadmap-fixes/README.md).

7 November universal vertical target health (VERTICAL-TARGET-HEALTH-20261107; REQ-RF-86):
party, compact focus and pet target strips now share HP/color/effect handling.
The loss gap follows the vertical height with native .25/.1/.05/.05 timing;
repeat hits retain the trailing edge. Target replacement, hide, resizing,
healing, max-health changes and zero maximum clear old trails. Secret values
use native StatusBar sinks and generation-cancelled catch-up without arithmetic;
status colors and optional target class colors remain. Effects prewarm OOC even
when disabled; target geometry defers in combat. Existing secure visibility,
Flux hover bindings, sizes/anchors and focus aura packing remain unchanged.
Five pinned Gethe UnitFrame blobs verified. 1243 vertical,995 party/focus,
80 public geometry,46 secret overlay and206 identity checks pass; full 236/236
scripts and 900 Lua syntax checks pass. Exact final owned hashes match the suite.
Native rendering/taint/input/combat/performance acceptance remains pending.
Fresh external source/history checkpoint and 45 read-only settings metadata
entries retained; no live settings/profiler/input or manual mirror actions.
[Evidence](validation/vertical-target-health-2026-11-07.json).

7 November focus aura packing only (FOCUS-AURA-PACKING-ONLY-20261107; REQ-RF-85):
latest user instruction supersedes the target-inclusive width in REQ-RF-82.
Restore original focus body/portrait aura width and remove the right target-strip
extension. Keep full-width native/Lua icon packing so more fit before wrapping;
icon size, spacing, timer/filter controls and corrected header anchor remain.
Target settings no longer resize aura panels. Existing secure combat group reveal
and portrait backdrop restore are retained.1011 geometry/packing,995 party/focus,
66 portrait,47 scale and36 timer-policy checks PASS; 235/235 scripts PASS; 899 syntax files/0 failures.
Owned final hashes match. Native visual acceptance remains pending. No new runtime
resources or saved-data change; unused target-width helper/lookup removed. Fresh
external history/source checkpoint and 45 read-only settings metadata entries kept;
no foreground control, game/WTF/profiler write, manual sync, branch or push.
[Evidence](validation/focus-aura-packing-only-2026-11-07.json).

7 November group visibility/focus row/portrait restore (GROUP-VISIBILITY-FOCUS-ROW-RESTORE-20261107; REQ-RF-82/83/84):
user screenshot shows remaining focus aura mismatch; user explicitly includes the
right target strip and wants more icons per row. Aura halves now cover that full
configured row and attach directly to the compact header (including initial/
re-enable paths), avoiding the old threat-shell reservation. Compact native/Lua
packing uses full width before wrapping. Existing independent icon/caption origin
changes are preserved; native offsets refresh on changes and cache steady writes.
Blizzard SecureStateDriver/SecureGroupHeaders and party/target sources were fetched
at21 exact blobs across5 pins. Native header roster updates require visible parents;
Flux secure group handlers now reveal the prepared parent too. Normal party uses
one added native group driver on the existing hub, removed on disable. Existing
OOC slot preallocation/native leaf visibility remains; no addon combat allocation
or ordinary protected Show/Hide. Party/focus normal portrait paint now hides the
red plate before restoring its theme, including unit-combat exit during lockdown.

1011 aura geometry,995 party/focus,255908 native-source secure-model,1160 pool/
readiness,66 portrait,310 binding,78 restricted,47 scale and36 timer-policy checks
PASS. Old party/portrait source rejects the regressions. 235/235 scripts PASS; 899 syntax files/0 failures;
owned final hashes match. Native current pixels/taint/real combat/input/CPU/FPS
NOT RUN; screenshot is prior user evidence, not current-source acceptance. No new
runtime regions/timer/ticker/global hook; one native driver reuses the hub.
Fresh external checkpoint/history and45 read-only settings metadata entries kept;
independent concurrent edits preserved. No foreground control, game/WTF/profiler
write, manual sync, branch or push. [Evidence](validation/group-visibility-focus-row-restore-2026-11-07.json).

7 November consumable tint and focus aura positioning (CONS-TINT-01;
UF-FOCUS-AURA-02): ready item state now owns the shared tint; reliable native
unknown/false results stay item states rather than being replaced by an
uncastable use-effect spell. Regular items and item macros share native item
range. Empty/mana/unusable/OOR feedback remains; managed item pins survive both
macro-translation cache lanes, and item changes clear stale tint/charge state.
Wisp and buff countdown behavior remains. Recovery fixture now exercises real
item restrictions, with a control rejecting cold-effect false darkening.
User pictures identify focus icons/captions shifted inward/up versus target.
Compact focus content now uses target-derived body-relative origins converted
into panel coordinates, in both Lua and native aura rendering. Exact accepted
panel widths, icon/font sizes and row fitting remain. Creation/re-enable and
relayout share their anchor helper; caption x/y anchors cache unchanged values.
Initial five paired runs reject both old paths and pass75 consumable/939 focus
checks; five final integration runs pass75/1011, retaining newer focus-target
width/full-row packing and cached native placement. Changed-scale anchors also
pass without redundant writes. Full validation:234/234 scripts PASS;898 Lua
syntax checks/0 failures; normalized source manifest and owned hashes match.
1475 consumable smoke,10 trinket,14 conjured and36 timer-policy checks PASS.
No new runtime frame/texture/event/hook/timer/ticker/OnUpdate. User focus/target
images and current verified history/source checkpoint retained externally;121
settings metadata entries read-only. Native pixels/consumable symptom/taint/
combat/FPS acceptance remains NOT RUN. [Evidence](validation/consumable-tint-focus-aura-2026-11-07.json).

7 November exact focus aura width (FOCUS-AURA-EXACT-WIDTH-20261107; REQ-RF-81):
user clarifies remaining mismatch is aura-panel length. Compact focus no longer
adds13 units per half or a -10 buff offset: the pair spans exactly the focus outer
frame, with/without portrait. Its faint battlefield border follows focus body
scale and the same2-unit/corner offsets as FluxBorder; Classic fallback corners
use matching crops/sizes. Icons/timers/captions keep their existing panel scale;
only border geometry follows body scale. Legacy target/focus aura geometry and
focus screen anchor/vertical target remain. Border-scale/corner writes cache;
no new runtime frames/textures/events/hooks/timers/tickers.577 actual geometry/
border checks,975 party-focus,47 anchor/scale and36 timer-policy checks PASS.
Checkpoint source rejects exact width. 233/233 scripts PASS; 897 syntax files/0 failures; owned hashes match.
Native pixel alignment/combat/taint/FPS NOT RUN; user acceptance pending. External
source/history checkpoint and 45 read-only settings metadata entries verified.
No foreground control, game/WTF/profiler write, manual sync, branch or push.
[Evidence](validation/focus-aura-exact-width-2026-11-07.json).

7 November focus anchor/aura scale correction (FOCUS-ANCHOR-AURA-SCALE-20261107; REQ-RF-80):
user rejects the previous focus position above party/raid and aura-panel layout.
The previous unchanged-anchor-code assertion was insufficient: the new compact
body scale changed its screen result. Raid coordinates now convert UIParent to
focus-local units, preserving the original helper/gap; this branch does not
require chat construction. External buff/debuff panels convert public body
metrics to their own inverse-scaled coordinate space before sizing. Their width
tracks half the visible focus plus original transparent border padding; original
icon sizes/spacing/timers/filters and above-header anchors remain. For260x85 at
body scale.4, each panel is82 units rather than185.5. Original transparent16-unit
border nesting remains. Aura artwork sits above status icons and below casts.

47 scale/anchor,265 actual aura geometry,975 party/focus,36 timer-policy and310
binding checks PASS; old source rejects both physical-anchor and panel-width
regressions. 233/233 scripts PASS; 897 syntax files/0 failures; owned final manifest identities match.
Native screen pixels/position/combat/taint/FPS NOT RUN; the earlier user-visible
regression is recorded as rejected, not accepted by prior mock results.
No new runtime frames/textures/events/hooks/timers/tickers; one panel-scale cache
and constant layout arithmetic. External history/source checkpoint verified and45
settings metadata entries read-only; prior complete private recovery retained.
No foreground control, game/WTF/profiler write, manual sync, branch or push.
[Evidence](validation/focus-anchor-aura-fix-2026-11-07.json).

7 November focus party presentation (FOCUS-PARTY-PRESENTATION-20261107; REQ-RF-78/79):
PvP artwork is another35% larger on a scaled noninteractive host, still behind
level text; native/private atlas rendering and timer-below-level policy retained.
Focus now reuses normal-party portrait-left/body fonts, text/status layers,
textured HP/resource separator and raised cast header. Its target is the narrow
vertical HP-only bar on the right, as selected by the user. It keeps the focus
unit/capability/secure visibility and binding paths; it never becomes a party
slot or uses party in-frame aura filtering. Existing external buff/debuff panels
stay above, with their screen-size settings preserved. Focus sizing uses the
normal-party baseline plus independent saved focus proportions/whole scale;
no saved size is reset. The previous focus positioning function is byte-identical
(after line-ending normalization), including chat and placement2 behavior.

970 party/focus and319 badge checks PASS across five source models;28 scale,
80 public geometry,310 binding and78 restricted contracts PASS. 232/232 scripts PASS; 896 syntax files/0 failures.
Owned final manifest drift: []. Focus target partition changes defer through
the existing protected queue in combat; live secure behavior/taint remains pending.
Native pixels/position/aura sizes/portraits/target/CPU/FPS NOT RUN. One generic
badge host per outer frame is reused by normal party; focus adds four text/status
hosts and existing indicator helpers/events/hooks, with no new timer/ticker/global
hook. Exact sources and fresh external history/source checkpoint retained;45
settings metadata entries read-only. No foreground control, game/WTF/profiler
write, manual sync, branch or push. [Evidence](validation/focus-party-presentation-2026-11-07.json).

7 November shared unit-frame PvP correction (UNIT-NATIVE-PVP-BADGE-20261107; REQ-RF-77):
user reports no visible unit-frame change after RF76. Root cause: RF76 only
handled normal party; player/target/focus retained the small status-chain icon.
Their shared outer-frame factory/paint now uses the same full native badge as
party: faction/FFA native atlas size (Classic64x64), prestige50x52/background
and30x30 badge. Badge sits behind level; timer sits below level. Only the player
keeps its real existing countdown; others stay empty as explicitly requested.
Native UnitFrameUtil handles private flag/prestige state; player-only mercenary
check matches native PlayerFrame. Status packing and secondary-name fitting no
longer query or shrink native badge regions. Normal party keeps its existing
layer and now reuses the shared prestige textures. Other roles/layout unchanged.

299 indicator/905 party/78 restricted/206 identity checks PASS. Checkpoint source
rejects the new indicator regression. 232/232 scripts PASS; 896 syntax files/0 failures; final owned
hashes match the suite manifest. Actual badge pixels, flag changes, combat/taint
and CPU/FPS remain pending: user has not accepted this correction in-game.
Two prestige textures per shared outer frame; no extra party prestige pair, new
event/timer/ticker/hook or paint driver. External source/history checkpoint and
45 settings metadata entries verified; prior complete recovery retained.
No foreground control, game/WTF/profiler writes, manual sync, branch or push.
[Evidence](validation/unit-native-pvp-badge-2026-11-07.json).

7 November native party PvP badge (PARTY-NATIVE-PVP-BADGE-20261107; REQ-RF-76):
latest user placement is full client player-frame badge behind level, with timer
slot below level. Badge sits on noninteractive owner+20 layer below level+80 and
auras+90. Modern client UnitFrameUtil.UpdateUnitPvPIndicator owns faction/FFA/
prestige selection and secret-safe texture visibility. Native player XML supplies
prestige50x52/background and30x30 badge; faction atlas uses native size. Classic
uses full64x64 native player UI-PVP faction/FFA texture. No small square packing.
Shared packing/name-budget avoids party icon visibility/width reads, since native
delegates can set private state. Other party role/status icons remain.

Blizzard GetPVPTimer has no unit parameter and native code uses it for player.
User explicitly chose Leave it empty for unsupported member countdowns. Existing
party timer text anchors below level but stays hidden: no guessed timer, copied
player timer, status substitute or new polling. Own player timer is unchanged.
Layout-only calls do not repeat native badge data rendering.

905 party/59 indicator/78 restricted/206 identity checks PASS across existing
five-client models, including legacy faction/FFA/full sizing, restricted fallback,
native delegate routing, prestige dimensions and no foreign GetPVPTimer reads.
232/232 scripts PASS; 896 syntax files/0 failures. New resources: one badge layer/two textures per member; reused icon/
timer; no new event/ticker/timer/global hook. Native badge pixels, secret delegate
execution/combat/taint/FPS pending; no performance claim. Exact source XML/API
blobs and recovery identities retained. No game input, WTF/profiler write, manual
sync, branch or push. [Evidence](validation/party-native-pvp-badge-2026-11-07.json).

<!-- AUDIT-R2-20261107 -->
7 November second addon audit (AUDIT-R2-20261107): documentation/proposals only; no audit-issued runtime, existing-test, TOC, art, settings or profiler edits. Fresh main/source snapshot, four Gethe pins and current232-script/896-Lua pass retained.929 classified sources/599 loaded paths screened. 25 qualified groups:15 active-source behavior/contract reproductions,4 conditional models,2 API edges with ordinary reach unproved,3 work candidates and1 dormant helper. Prioritize punctuation pool-name collisions, cancelled gear work, and the conditional visible-salvage combat path; preserve all features and saved data. Explicit rapid Shift/Ctrl/Alt work includes over10million core state edges per run plus separate actual Binding/EBS/badge consumer matrices. Core bus settles in isolated storms; mixed mouseover can starve full display context; stale press ownership and actual combat index work remain recorded. Large fallback setter counts are an unsupported-paging countermodel, not ordinary repaired Forever. Independent Party/PvP source and fixture edits were preserved and revalidated by the current232/896 suite plus affected probe; initial snapshots remain. New fixes remain OPEN. Native taint/input/pixels/instances/CPU/FPS are not accepted by desktop results; previous USER-001 attribution/recurrence is still unknown. [Audit and roadmap](../Stress%20test%20doc/round-2/README.md).
<!-- /AUDIT-R2-20261107 -->

7 November clock calendar correction (MINIMAP-CLOCK-CALENDAR-20261107): user
clarifies calendar belongs on left-click of the displayed minimap time. Remove
the separate calendar icon, restore GameTimeFrame cleanup, and use runtime
ToggleCalendar availability for the existing clock click/tooltip. Right-click
TimeManager/stopwatch and native mail artwork remain. No new driver or resources.
720 focused checks PASS; prior source rejects. Full 232 scripts / 896 Lua syntax
PASS; post-suite hashes unchanged. Validation is recorded in
[the evidence](validation/minimap-clock-calendar-2026-11-07.json). Direct UI choice
and UIForever preference retained; simulator/native input/visuals/taint/FPS NOT RUN.
Fresh external source/history checkpoint verified;16 settings metadata entries
inspected read-only. No game input, settings write, commit/push or manual sync.

7 November author correction: user explicitly approved the prepared one-time
exception to the no-force-push rule. Main was updated with an exact expected-head
lease from d3db4c5 to e0bcdc2. One old author/committer identity was corrected;
30 commit IDs changed, with every tree, message and timestamp preserved. The
published-history recovery bundle remains verified outside AddOns. GitHub's
author query returns zero old-identity commits; its contributor list was still
cached at capture. Check after the documented refresh period (about24hours),
then contact GitHub Support if it remains incorrect. Future publications keep
DoctorFlux author/committer metadata and the standing no-force-push rule.
Runtime files remain at the passing232-script/896-Lua identities; no native
input, settings or profiler change occurred.
[Correction evidence](validation/attribution-correction-2026-11-07.json).

7 November native minimap indicators (MINIMAP-NATIVE-20261107): user chose direct
implementation and UIForever testing. Reuse Forever's native 32x24 cluster mail
frame/art before the retained fallback; retire late-superseded fallback listeners.
Keep native GameTimeFrame at minimap top-left when ToggleCalendar exists, retaining
size/art, scripts, alerts and disable state. Clock-only clients retain cleanup.
Calendar resumes its native OnUpdate; no new addon driver/event/timer/ticker.
717 focused checks PASS; pre-edit source rejects. Full 232 scripts / 896 Lua syntax
PASS; post-suite Lua hashes unchanged. All five installed owner copies match via
the existing mirror. Gethe Forever 1.60.1.70862, pin 9dc84f0d3bbae1768ac3405b3716000bd93eda06.
External dated source/history checkpoint verified; 16 on-disk settings metadata
entries inspected read-only. UIForever NOT RUN: browser automation unavailable;
clean import ZIP and steps prepared. Native visuals/input/mail/invites/combat/taint
and CPU/FPS pending. No game input/settings write, commit, push or manual sync.
[Evidence](validation/minimap-native-indicators-2026-11-07.json).

7 November publication batch: current local addon updates and audit/test records
were uploaded to main in 7d35d33 with a normal fast-forward push. The newer minimap
records are included in the following documentation commit. Fresh validation passes all
232 scripts and 896 Lua syntax files with unchanged Lua hashes. External recovery
checkpoint GitHub-publication-20261107T135245Z preserves 2,039 actual source files,
179 on-disk settings and all-ref Git history; archives are outside AddOns.
Publication author/committer is DoctorFlux, with no automated co-author trailers.
An older author attribution needs a published-history correction; the standing
no-force-push rule remains until the user explicitly approves that exception.
Native combat/taint, visual and performance checks retain their recorded pending
status. This publication changes no runtime behavior or game/profiler settings.
[Fresh validation](validation/github-publication-2026-11-07.json).

<!-- STRESS-FIXES-20261107 -->
7 November stress fixes (STRESS-FIXES-20261107): the user authorized implementation after the audit/proposal phase. Applied public fade ownership, secret-safe alpha/geometry handling, local Forever driver adapters, accurate/cancellable Respec completion, input invalidation, mutation-safe event delivery, retained FIFO scheduler work, bounded combat drains, raid/nameplate work reduction, hidden-watch suspension, bounded range freshness and auction retry churn. Settings, saved roots, commands, artwork and foreign library ownership are preserved. Combined desktop validation: 232/232 scripts and 896 Lua syntax files PASS; post-suite Lua hashes match. No game input, WTF/profiler writes, commit, push or manual cross-install copy was performed. USER-001 actual failing frame/first taint source, native taint, pixels and CPU/FPS remain pending. Visible character-button polling and coherent auction publication after quiet are intentional safety limits, not claimed eliminated costs. [Applied changes and evidence](../Stress%20test%20doc/applied-fixes/README.md).
<!-- /STRESS-FIXES-20261107 -->

7 November modifier key routing (UTL-CHORD-13): user confirms no-mod works
but modifiers fail. Ordinary utility key overrides now carry their triggering
chord as a distinct virtual button. Wildcard-modifier native payloads and
release types preserve that selection independently of live modifier queries
during dispatch. Click wrappers retain the virtual button and CVar edge;
cached nonwrap keyers inherit its fields. Mouseover uses the same encoded
prefix and retains its native modifier gate. Physical mouse attributes stay
prepared for each chord. Bindings now install after action preparation in
the real slot-update lifecycle; clearing removes all encoded actions.
A masked-dispatch fixture reproduces the prior normal-action fallback;
the engine masking mechanism itself is unobserved. Five baselines fail and
five candidates pass41255 checks; four mutations rejected.12634 face/count/CD,
1473 VFX and4973 mouseover checks PASS; existing320-transition paint budget
unchanged. No new frame/event/timer/ticker/poll. Actual new modifier input/
mouseover/combat/taint/pixels/FPS acceptance remains NOT RUN.
Full run:894 syntax PASS;229/230 scripts PASS. The sole failure is the
unrelated portrait_camera.lua fixture missing GetFramePublicDimensions;
concurrent portrait work is preserved. Utility source owners/tests remain
at their recorded hashes; all five installed copies match via the existing
mirror. Native modifier acceptance is still pending.
[Evidence](validation/utility-chord-routing-2026-11-07.json).

7 November party auras over portrait indicators (PARTY-AURA-PORTRAIT-LAYER-20261107; REQ-RF-75):
normal party aura host was owner+60 below portrait indicators+80. It now uses+90
in the shared live/preview factory, above portrait icons and below cast header+110.
Native and readable rows, cooldowns and duration text inherit that host. Existing
positions/sizing, filters/limits, strict dispels, timer policy and opacity remain.
This changes draw order only; no new frame/event/hook/timer/ticker/recurring work.

865 party checks include live ordering above indicators/below casts and matching
preview ordering on five source models;12776 aura-renderer checks PASS. 228/229 scripts PASS; 893 syntax files/0 failures.
Native overlap/opacity, combat/taint/FPS checks pending per client; no native
performance claim or benchmark for this low-impact change. External dated
source/history/settings retained; no game input/WTF/profiler write, manual sync,
branch or push. [Evidence](validation/party-aura-portrait-layer-2026-11-07.json).
Later unrelated corpus drift: Respec/FluxRespec_Consumables.lua, Respec/FluxRespec_PresetBundle.lua, tests/hover_children_varargs.lua, tests/prediction_public_geometry.lua, UnitFrames/FluxUnitFrames_Shared.lua.

7 November utility execution rework (UTL-EXEC-11; UTL-MO-12): user rejects the
ranked-spell attempt as still nonfunctional. Ordinary spell/item utilities now
prepare native secure action attributes for every exact modifier chord before
combat, removing macro-text/delegate execution. Saved IDs directly drive
icon/count/cooldown/VFX; rank names are used only as native spell cast tokens.
Both keys, base/preferred fallback, combat release, clearing and cursor drops
are covered; special macro/pet/mount/toy/outfit assignments retain their route.
Mouseover follows the existing setting/modifier through shared click-time
target wrappers, using the selected action help/harm gate and clearing unit
afterward. Range follows the same reaction during existing hover cadence.
Forever target wrappers require the existing repaired-VM probe; failed probe
or partial installation retains normal native targeting and is not a
mouseover pass. Existing combat setting deferral remains. No new event,
timer, ticker, OnUpdate or hover driver; existing320-transition paint budget
is unchanged.26962 input,10234 face/count/CD,1033 VFX and4973 mouseover checks
PASS; five old-contract rejections/five candidates and three mutations.
Full222 scripts/885 syntax PASS; tested Lua corpus unchanged; all five installed
client copies match the six runtime owners through the existing mirror.
Actual native casts, mouseover probe, combat/taint/visual/FPS remain NOT RUN.
[Evidence](validation/utility-native-actions-2026-11-07.json).

7 November utility ranked spells (UTL-RANK-10): user reports Arcane Intellect
and other utility spells fail. Read-only saved assignments include Arcane
Intellect(Rank 2). Native CAST prechecks the full ranked string; USE sends a
nonitem string directly to the protected cast function. Ranked/subtext utility
spells now use USE, retaining their exact rank; bare spells retain CAST priority
over same-name items. Mixed ranked/bare slots keep a single stable hidden macro
with mutually exclusive exact-chord lines. Item modifiers, both keys, release
and special assignments remain. No new events/timers/frames/polling or combat
action writes. Five baseline rejections and five candidate15491-check passes
exercise a ranked-lookup miss through five dated native dispatcher/handler
sources. This is a desktop failure model, not confirmation of the native root
cause or spell cast success. Full222 scripts/885 syntax PASS; corpus unchanged;
all five manager copies match. Existing6894 modifier/488 VFX checks PASS.
Native reload/target/mouseover/input/combat/taint/
visual/FPS acceptance is pending. [Evidence](validation/utility-ranked-spells-2026-11-07.json).

7 November utility item cooldown correction (UTL-CD-09): utility slots no longer
claim consumable buff durations as cooldowns. Clear already latched aura fields
before cooldown dispatch, including combat modifier release back to a spell.
The dedicated consumables button keeps its supplied aura countdown; existing
nonutility potion and food/water policy remains. No new timers, events, frames,
polling or protected action writes. Five paired desktop runs reproduce 30
baseline failures and pass 6894 candidate checks each; utility aura lookups
drop from five to zero per run. Full validation: 222 scripts and 885 Lua syntax
files PASS; post-run corpus unchanged. Native cooldown/input/combat/taint/visual/FPS
acceptance remains pending. [Evidence](validation/utility-item-cooldown-2026-11-07.json).

7 November utility conditional macro key fix (UTL-MACRO-08): user reports
Shift item keypress still attempts the normal spell; prior input acceptance is
REJECTED for that native report. Ordinary spell/item slots now execute one
compact conditional macro command with explicit item:ID tokens; native /cast
handles both. The same body supplies display identity. Modifier-specific action
attributes no longer choose the execution branch for these slots. Named macro/
pet/outfit paths retain their prior route. Nonwrap keys now use one cached
AnyDown proxy per bound utility (max4), inheriting prepared host attributes;
visible mouse timing and wrap-client CVar policy remain. This fixes the tested
AnyUp release-order gap: Shift item executes on key-down before Shift is released,
and key-up cannot then run the normal spell. No modifier-time secure rewrites
or new event/timer/ticker/poll. Both keys and explicit modifier chords remain.
Read-only saved slot1 Study/Shift-water and native U binding verified. Actual
five-client SecureTemplates plus CAST/USE handlers replay 11114 checks; saved
setup, cold item no-fallback and early Shift-release cases pass. Five old-source
contract rejections/five candidate passes; isolated pre-proxy timing rejection;
three mutations rejected.6609 count/modifier and488 VFX checks pass; prior
count-paint budgets retained. Full222 scripts/885 syntax PASS; tested
corpus unchanged; all5 manager copies match through existing mirror. No game input,
WTF/profiler writes or settings reset. Native reload/input/combat/taint/FPS
acceptance remains pending; no connected Witchcraft/native input tool.
[Evidence](validation/utility-conditional-macro-key-2026-11-07.json).

7 November target-style party separator (PARTY-TARGET-SEPARATOR-20261107; REQ-RF-74):
user screenshot rejects the flat party line; user selects the bottom-right target
as reference. Party now calls the exact target/player CreateSeparator factory via
UF.CreateBarSeparator: same battlefieldminimap-border-top atlas, or same legacy
texture/crop, and17 logical height including transparent artwork padding. Tint
uses SetVertexColor so recoloring cannot replace artwork with a solid fill. The
underlying shared health/power separator hides when the owned party divider exists
to avoid a doubled/shiny edge. Resource-top seam and existing bar-height controls
remain. Reference screenshot retained externally with hash; new native comparison
is pending. This supersedes RF73's solid four-unit divider appearance.

144 checks compare the actual party construction with the target constructor
across atlas/fallback, HUD/legacy and multiple heights/resource scales; verify
seam coordinates, no bar resizing and no duplicate separator. Five alternating
checkpoint/candidate pairs reject the former flat artwork and pass current code.
840 party checks PASS. 222/222 scripts PASS; 885 syntax files/0 failures. No new frame/event/hook/timer/ticker/driver;
no native CPU/FPS claim. Native pixels/combat/taint pending per client. External
source/history/settings retained; no game input/WTF/profiler write, manual sync,
branch or push. [Evidence](validation/party-target-separator-2026-11-07.json).
Later unrelated corpus drift: ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua.

7 November party divider thickness/tint (PARTY-DIVIDER-STYLE-20261107; REQ-RF-73):
user confirms RF72 divider is visible and requests it slightly thicker with the
same color as the other borders. Height increases3 to4; resource-top anchors,
bar/frame dimensions and opacity stay. Divider and outer borders now use the
same appearance accent or party member class override through Party.PaintChrome.
Existing global appearance refresh repaints live and preview party chrome, so
changing accent/class choices cannot leave the divider at its old hardcoded tint.
No new frame/event/hook/timer/ticker/recurring driver; bounded appearance repaint.

Existing54 real-partition/840 party/59 indicator checks PASS; expectations updated
for height4. 222/222 scripts PASS; 885 syntax files/0 failures. This small visual change adds no new tests/benchmark
that mirror its implementation; no native performance claim. User acceptance is
prior divider presence only; new thickness/tint native visual/combat/taint/FPS
checks remain pending. External source/history/settings retained; no game input,
WTF/profiler write, manual sync, branch or push.
[Evidence](validation/party-divider-style-2026-11-07.json).

7 November utility modifier VFX (UTL-VFX-07): utility face changes now
settle cast/channel/empower/reticle/finish/interrupt through the existing Cast
and Overlay owners. A departed face clears its paint and player owner-bag
membership; returning matching faces resume via existing progress/window
helpers. Context refreshes with unchanged identity skip this work. Macro item
faces resolve their use-spell proc without comparing item art to spell art;
cleared utility slots drop stale proc/cast effects. Existing strip/pet ownership
and pre-DF VFX preference remain. No new event/frame/timer/ticker/poll or secure
action writes; hold/release and prior count work budgets stay unchanged.
578 focused VFX checks across five models,7329 modifier/count checks and11015
native-source input checks PASS; five baseline rejects/five candidate passes;
four mutations rejected. Full222 scripts/885 syntax PASS; tested
corpus unchanged; all15 installed runtime copies match via existing mirror. Native pixels/input/
combat/taint/FPS remain pending; actual drawing and unit data are modeled.
External source/history/settings metadata verified; no game/WTF/profiler/input
control or manual client sync.
[Evidence](validation/utility-modifier-vfx-2026-11-07.json).

7 November party HP/resource divider edge (PARTY-DIVIDER-EDGE-20261107; REQ-RF-72):
user reports divider absent; prior RF67 desktop checks did not validate the HUD seam.
HUD health fills extend behind resource; its bottom is not the seam. The existing
party divider now anchors to Power top with+1 offset, matching the shared two-unit
gap midpoint. Height3, bronze color, opacity, raised layer, bar dimensions, frame
size and existing range/visibility ownership remain unchanged. No new resource
owner/event/hook/timer/ticker or refresh loop; native anchors track resource.

54 checks execute the real shared partition function and production divider
creation across HUD/legacy,35/85/150 height and0.5/0.8/1.5 resource scale. They
resolve divider coordinates against the actual shared separator, and assert no
bar resize. Five alternating checkpoint/candidate runs reject the old HUD edge
and pass current code;840 party checks PASS. 221/221 scripts PASS; 884 syntax files/0 failures. Native seam pixels,
combat/taint/FPS pending per client; no native performance claim. External dated
source/history/settings retained; no game input, WTF/profiler write, manual sync,
branch or push. [Evidence](validation/party-divider-edge-2026-11-07.json).
Later unrelated corpus drift: tests/bank_restock_icon.lua.

7 November default Blizzard bank direct UI lifecycle (BANK-NATIVE-06): user
renews the no-Baganator close/layering fix. Source audit proves a missed path:
restock inventory fireCloseIfGone suppresses its private close callback while
Bank.IsOpen stays true. Earlier tests always delivered that callback. The bank
button now uses BANKFRAME_OPENED/CLOSED directly through the existing shared
Flux.Events dispatcher for native UI, independent of that inventory latch. A raw
close hides immediately, invalidates delayed attaches and blocks manual/stale
inventory-open resurrection until the next real open. Private callbacks remain
for Baganator and as fallback if direct registration is unavailable. Two native
subscriptions, no new frame/timer/ticker/polling or native-script hook.
Native layering now uses at least HIGH and the highest parent/search/panel/close/
NineSlice strata; level clears those children as well as the root. Native parent
and left-of-search position remain. GetControl exposes the actual owned widget
for diagnostics; no command/settings change. Baganator footer remains intact.
Full221 scripts/884 Lua syntax PASS; final bank1780 checks rechecked after a
baseline-fixture refinement. Later unrelated Cast/EBS source drift recorded; no current whole-addon PASS
claimed. Bank runtime owner remains at its tested hash.
All5 installed bank owner hashes match via existing mirror; no manual sync.
Two production mutations (missed close and low strata) rejected.
1780 production checks across five clients/both owners/cold-warm merchant/direct-
events-fallback modes PASS. Includes suppressed inventory close, stale shown
flags, stale open callbacks, HIGH/DIALOG children and reopen. Native ownership168,
visible Baganator260 and combined33 per Era/Anniversary PASS. Prior checkpoint
rejects. Fresh Gethe Forever9dc84f0d3bbae1768ac3405b3716000bd93eda06 (1.60.1.70862)
verifies close function/events/search owner. Native visuals/open-close/purchase/
combat/taint/FPS remain pending; actual hovered-frame evidence still unavailable.
Fresh external source/history/45 on-disk settings metadata verified. No game,
foreground, WTF/profiler or manual-sync operation.
[Evidence](validation/bank-direct-lifecycle-2026-11-07.json).

7 November native bank owner investigation (BANK-NATIVE-05): user confirms
Forever after /reload still shows the control behind/detached from the window
and not disappearing on close. BANK-NATIVE-04 native acceptance is REJECTED;
its desktop checks do not establish actual-client behavior. No further runtime
layout change made yet. Read-only host enumeration confirms two running
_forever_/Wow.exe clients; installed bank source matches current workspace hash.
Available saved BugTabs has no bank/restock error entry, but is not live state.
The current source already parents its native control to BankFrame, making the
actual hovered frame/owner identity necessary before another speculative fix.
User requested to type /fstack, hover the visible restock control and provide
frame names, then disable /fstack. Await this evidence. No connected Witchcraft,
UIForever or computer-use tool exists; no foreground/mouse/keyboard/clipboard
control, game input or WTF/profiler writes. Fresh source/history checkpoint and
45 settings metadata entries verified outside AddOns. Native placement/layering/
hide/taint remain unresolved; preserve the Baganator footer and newer party work.

7 November party cast name/level coverage (PARTY-CAST-COVER-20261107; REQ-RF-71):
latest user correction keeps player-style cast art/icon but requires it over the
party name and level. This supersedes RF68's unmodified cast placement. Shared
cast dimensions/lifecycle remain; shell now anchors across the prepared party
header at owner+110, above name+70 and metadata+80. Name/level alpha conceals
underlying glyphs during casts/holds and restores previous public alpha on hide
or disable. Metadata repaint cannot raise the level over the cast. Show/Hide
callbacks change text alpha only; existing OOC layout prepares geometry.

Party / Raid > Party frames > Show party cast bars retains partyShowCastBar and
combat deferral. Disabling hides an active cast immediately outside combat;
enabling refreshes the current cast through existing CB.RefreshCastForUnit.
840 party/310 binding/379 timer/2730 marker checks PASS; five fresh alternating
baseline/candidate harnesses reject the prior lower/unplaced cast shell and pass
current code. 220/220 scripts PASS; 883 syntax files/0 failures. Markers remain fixed by RF70. No new frame/event/
ticker/timer/secure condition; four layout wrappers and Show/Hide coverage hooks.
Native pixels/toggle/combat/taint/FPS pending per client; no performance claim.
External source/history/settings retained; no game input/WTF/profiler write,
manual sync, branch or push. [Evidence](validation/party-cast-cover-2026-11-07.json).

7 November native bank attachment (BANK-NATIVE-04): user reports the no-Baganator
button below the window and detached during opening/closing. Forever's control
was deliberately a UIParent sibling; it now uses the native BankFrame parent and
existing inside left-of-search anchor, inheriting visibility, movement and scale.
This supersedes the earlier UIParent parent restriction for this owned control.
Native scripts, purchases, mover and item decoration exclusions remain. Visible
ancestor checks hide stale/unattached controls on all clients. Existing two open
retries keep their cadence but use a close/reopen generation token, so stale
callbacks cannot resurrect a closed control. No new frame/event/hook/timer/ticker.
Baganator's full-size inside footer and existing settings/commands are retained.
Full runner:219 scripts PASS,1 unrelated raid_party_frames cast-layout failure;
883 syntax/0 failures. No current whole-addon PASS claimed. Final bank828 checks
rechecked after the hidden-ancestor test extension. All5 installed runtime hashes
match through existing mirror; no manual client copy.
828 production checks across5 clients/both owners/cold+warm merchants PASS,
including parent hide/show without callbacks, close/reopen retries, explicit
hidden-bank attachment and a shown frame under a hidden owner. Prior checkpoint
rejects; current code passes. Native ownership168/visibleBaganator260/combined33
per Era/Anniversary PASS. Fresh dated source/history/45 settings metadata entries
verified externally; no game/WTF/profiler/manual-sync operation. Existing pinned
Gethe9dc84f0d3bbae1768ac3405b3716000bd93eda06 source retains search/template evidence.
Native candidate placement/open-close/purchase/combat/taint/FPS remain pending;
no connected native tool.
[Evidence](validation/bank-native-attachment-2026-11-07.json).

7 November raid-target marker rendering (RAID-MARKER-RENDER-20261107; REQ-RF-70):
raid/normal-party icons hid every secret GetRaidTargetIndex return. Raid textures
also lacked a base sprite sheet: native SetRaidTargetIconTexture sets coordinates,
not the image. Both are fixed. Retail/Forever opaque indices pass directly to
the AllowedWhenTainted native SetSpriteSheetCell sink; no private comparison or
UV arithmetic. Readable markers retain legacy fallback. Sheet is explicitly set;
nil/invalid/removal hides stale icons. Ordinary player/target/focus marker state
uses the same guarded approach instead of index truth tests. Existing player/party
HP-centered geometry, settings, textures and events stay; no new frame/driver.

2730 checks exercise all eight markers, replacement/removal, readable/restricted
indices, six unit tokens, native and legacy paths across five client models.
Five alternating checkpoint/candidate pairs reject the prior missing-sheet path
and pass current code. Existing428 raid runtime/810 party/59 indicator checks PASS.
220/220 scripts PASS; 883 syntax files/0 failures. No native pixels/combat/taint/FPS certification. External dated
source/history/settings retained; no game input/WTF/profiler write, manual sync,
branch or push. [Evidence](validation/raid-marker-render-2026-11-07.json).
Later unrelated source drift: Inventory/Restock/Bank/FluxBankRestockButton.lua, tests/bank_restock_icon.lua.

7 November Baganator full-size inside action row (BANK-ICON-03): user rejects
the22px toolbar button and explicitly requires a location inside the window.
Existing restock control is now36x36 at scale1 in an owned48px bottom row, with
Bank Restock label and full-size auto checkbox. Native tab, currency/reagent/
purchase controls and item layout sit above that row. Existing completed-layout
wrapper releases owned geometry before native sizing; repeated attachment never
accumulates height. Tall windows reuse/shorten their existing scroll viewport;
owned heights restore on hide, locked tab or native/combined handoff. No native
bank placement changes; Forever remains left of search. No settings migration,
new frame/event/hook/timer/ticker; one lazy FontString and transient footer state.
Full220 scripts/883 Lua syntax PASS; current Lua corpus unchanged.
All10 runtime owners across5 installed copies match via existing mirror.
668 production checks cover five clients, both bag owners, cold/warm merchant,
full-size geometry, viewport bounds, exact native completion ordering, repeated
refresh, lock and handoff. Ownership168/visibleBaganator260/combined33 per Era
and Anniversary PASS. Native candidate visuals/input/taint/FPS remain pending;
user reproduction route retained. Baganator843 interfaces inspected read-only;
rights retained, no implementation/art copied. Dated external source/history and
45 on-disk settings metadata verified. No game input/WTF/profiler/manual sync.
[Evidence](validation/bank-restock-footer-2026-11-07.json).

7 November cast timer synchronization (CAST-TIMER-SYNC-20261107; REQ-RF-69):
party/focus/target text could prefer stale cached value/maxValue while the fill
used its StatusBar or engine DurationObject. Restricted duration also selected
a guessed wall clock for text. Shared countdown now reads the bound engine
remaining duration, or actual bar current/max values for readable/manual casts
and channels. This follows all five native CastingBarMixin timer formulas.
Opaque engine remaining duration forwards unchanged to the native formatted-text
sink; font widths are secret-guarded. Unavailable timing clears stale text rather
than estimating. Cast fill, geometry, lifecycle, options and0.05s paint cadence
stay unchanged; no new frame/event/hook/ticker/timer. Player and pet share the fix.

379 focused checks cover five source families, party1/party4/target/focus/player,
casts/channels/delays/replacement, stale caches, engine duration, restricted text
and font geometry. Full production start/update/delay events replay on each
family, including Retail/Forever engine-owned opaque countdowns. Five alternating
checkpoint/candidate pairs reject old code and pass current; three timer mutants
rejected.13942 existing cast theme checks PASS. 219/219 scripts PASS; 882 syntax files/0 failures.
Native rendering/secret sink/combat/taint/FPS remain pending per client; desktop
models do not certify them. Dated external source/history/settings recovery
retained. No game input, settings/profiler write, manual sync, branch or push.
[Evidence](validation/cast-timer-sync-2026-11-07.json).

7 November bank restock slot follow-up (BANK-ICON-02): user rejects the first
icon-only fix and the Forever outside-window placement. Baganator843's toolbar
uses32x22 buttons; resizing only the hit rectangle left fixed64px merchant slot
art at its36px design size. The whole36px control now scales uniformly to the
shorter toolbar edge, including icon, frame, highlight/push and auto toggle.
Native/combined handoff resets scale1. Transfer/Sort/Customise references work.
Forever remains an addon-owned UIParent child but is visually inside BankFrame,
RIGHT of button to LEFT of BankItemSearchBox,4px gap, vertically centered; this
supersedes the previous external TOPRIGHT placement. Native bank hierarchy,
scripts/purchase/movement/decorations stay untouched. Fresh Gethe Forever source
9dc84f0d3bbae1768ac3405b3716000bd93eda06 (1.60.1.70862) verifies Mainline template
and Camelot loading/search owner. Baganator read-only reference retains rights.
Full219 scripts/882 syntax PASS; no current Lua corpus drift.
All five installed bank runtime hashes match via existing mirror; no manual sync.
358 production geometry/lifecycle checks PASS across5 clients/both bag owners/
cold+warm merchant; prior checkpoint rejects. Native ownership168 and combined33
per Era/Anniversary PASS. Native candidate pixels/input/taint/FPS remain pending;
user screenshot reproductions retained; no connected client tool or game input.
External fresh source/history verified;45 on-disk settings metadata read-only.
No new frame/event/hook/timer/ticker. Existing bounded retries/click/drop/tooltip/
auto settings retained.
[Evidence](validation/bank-restock-slot-2026-11-07.json).

7 November player-layout parity for normal party (PARTY-PLAYER-LAYOUT-20261107; REQ-RF-68):
user supersedes the prior portrait-corner class/spec/raid marker layout and
header-overlay cast variant. Class/spec now retain the shared player factory's
anchors, size, borders and visibility; no forced class show or party reparenting.
Party casts use the unwrapped player cast layout including spell icon. The party
cast toggle remains. Player and party share UF.LayoutRaidMarker: center of HP,
90 percent of HP/text-anchor height; party retains secret-guarded marker updates.
Leader/assistant/MT/MA/loot move onto portrait so class/spec header slots are free.
Spec data availability follows the existing provider; no fabricated spec.

810 party and78 restricted checks pass; 218/218 scripts pass; 881 syntax files/0 failures.
No new frame/event/timer/ticker/condition. Four cast wrappers and OnShow hooks
removed. Native pixels/casting/combat/taint/FPS pending on each client. External
source/history/settings recovery retained; no game input/WTF/profiler write,
manual sync, branch or push. [Evidence](validation/party-player-layout-2026-11-07.json).

7 November compact normal-party indicators (PARTY-INDICATORS-20261107, REQ-RF-63..67):
restored class icon; class/spec/PVP/role/raid marker have dedicated portrait corners,
leader/assistant/MT/MA/master loot use a compact header grid, and level has its own
readable corner. Casts cover the header above both text and metadata, with the
existing Party member cast bars toggle; shared cast lifecycle retained. Pet text
hosts use symmetric left/right margins so percentage-only labels center on X.
Party reuses raid ready-check/center-status helpers for ready, resurrection,
incoming summon, leader/loot/raid markers, plus native role atlas. Ready finish
hides without a new timer. A dedicated divider restores the HP/resource seam
independently of the HUD fill's alpha. Party raid markers bypass the older shared
marker truth-test and use the existing secret-guarded raid helper.

800 party,78 restricted-contract,310 binding and59 indicator checks pass on the
existing source models. Whole run: 218/218 scripts pass; 881 Lua syntax files, 0 failures. No native visuals/combat/taint/FPS certification.
Four textures/member, no new frame/ticker/timer/secure condition. External dated
source/history/settings retained; no game input, settings/profiler write, manual
sync, branch or push. [Evidence](validation/party-indicators-2026-11-07.json).

7 November bank restock icon (BANK-ICON-01): user supplied Forever screenshot
showing a small icon and requested all clients with/without Baganator. The bank
icon now fills its own button with a one-pixel inset, following native/combined
and Baganator toolbar sizing instead of copied merchant icon dimensions. The
requested no-Baganator Forever route restores an addon-owned UIParent button
beside BankFrame; no native bank child, script, mover or item decoration changes.
This intentionally supersedes only the prior native-restock suppression. Existing
bounded open retries, close cleanup, click/drop/tooltip/auto settings remain.
312 production-module geometry/lifecycle checks cover five clients, both bag
owners and cold/warm merchant icons; prior checkpoint rejects, candidate passes.
Ownership168, combined33 per Era/Anniversary, charge12 and click784 checks pass.
Full run reports218 scripts/881 Lua syntax PASS at its captured snapshot.
Three unrelated raid/party Lua files subsequently drifted; bank runtime/test
owners remain stable, so no whole-addon PASS is claimed for the changing tree.
All five installed bank runtime copies match through the existing mirror;
no manual client copy performed. Source/history checkpoint and45 on-disk Flux settings metadata entries verified
outside AddOns. No game input, WTF/profiler writes or new recurring driver.
Native candidate pixels/input/taint/FPS remain pending; no connected client tool.
[Evidence](validation/bank-restock-icon-2026-11-07.json).

7 November utility combat release/optimization (UTL-REL-05;UTL-PERF-06):
normal spell/item action, icon and latest count restore on every modifier
release while combat remains active. Partial/full release, counts changed
while held, zero/blank digits and50 repeated cycles are covered. Native input
continues through prepared modifier attributes without visual callbacks or
secure rewrites. Utility display now uses one loop and shared translator paint;
unchanged selected faces and duplicate chord events skip repeated work. Special
pet/outfit cleanup remains; bag/charge updates stay independent. Actual shared
Modifier bus + painter regression passes7329 checks; five-source native input
replay passes11015. Five paired desktop measurements:320 transitions reduce
icon320->120, count640->120, usable660->140, checked640->120; duplicate paints
1120->0. These are scoped callback work counts, not native CPU/FPS measurements.
Prior behavior restored correctly; optimization removes duplicate work. Two
mutations rejected. Full217 scripts/880 syntax PASS at snapshot;
subsequent unrelated native-bank test drift recorded. Utility runtime and all5
installed copies match tested hashes; docs check pending2 bank-test inventory/
verification issues. No whole-current-tree acceptance claimed. Existing events/cadence/
settings unchanged; one transient chord memo; no new recurring driver. Native
input/taint/pixels/FPS remain pending; no game/WTF/profiler/input control.
[Evidence](validation/utility-modifier-release-2026-11-07.json).

7 November utility secure use/cast follow-up (UTL-USE-04): user requires
universal execution as well as the displayed spell/item, including combat.
Exact macro actions now stay on the existing hidden EBS delegate; visible
modifier attributes forward clicks there. The long visual body cannot execute
through an unmapped/right button. Nonwrap clients bind native LeftButton;
wrap clients retain KeyBind. Both assigned keys gain each explicit utility
modifier override, including items, while unassigned bindings stay available.
8135 actual Blizzard-dispatcher desktop checks across5 source trees cover
mouse/two keys/all8 chords/both CVar edges/combat and deferred edits;5 baseline
rejections/5 candidate passes and3 rejected mutations. Prior face/count/pet/
transmog regressions pass. The old bars fixture incorrectly forbade native
LeftButton universally; corrected to follow wrap capability. Full217 scripts/880 Lua syntax PASS; tested corpus unchanged at audit. No new frame/event/timer/ticker owner; existing pool and
bindings owner reused. Actual native secure combat input/taint/pixels/FPS
remain pending: no Witchcraft tool available. No game/WTF/profiler input.
[Evidence](validation/utility-secure-input-2026-11-07.json).

7 November normal-party follow-up (PARTY-NATIVE-FOLLOWUP-20261107,
REQ-RF-51 through REQ-RF-62): fixed native visibility with prepared fixed-token
buttons and Blizzard's built-in state-visibility driver. User confirms player-style
frames appear and preview works. Four fixed rows keep the full stack within the
current raid-column height, with zero gap; the fourth slot retains the old full
party corner. This supersedes the earlier partial-roster last-member relocation.
Pet/target existence changes use native secure drivers; option edits defer.

Party HP/resource text is 15 percent larger with independent name fitting;
pet offset no longer consumes name-header space. Metadata occupies separate
portrait-side slots and a level corner. HP-only 60x28 pets show only percentage;
HP text moves into a top band with a pet and centers without one. Resource height
defaults to 80 percent. Independent values/percent/both/hidden modes default to
HP values and resource percentage. Bigger party auras have their own 1.50 factor;
portrait-side harmful auras preserve strict filters, limits, packed flow and clocks.
HP/resource fills gray for dead/ghost/AFK/offline and recover on status return.
All portrait surfaces inherit alpha; missing 3D models use native SetPortraitTexture
and recover on model loading. Optional player-class HP colors cover own pet target,
party targets and focus target; NPCs retain their normal color. Party class chrome
remains independent of HP. Threat uses only an owned transparent border overlay
with native warning/dead/status rules and GetThreatStatusColor, guarding secrets.

Actual restricted-method regressions cover underscore attributes and inherited
parent handles; $parent fixes invalid relative handles. The secret-alpha portrait
comparison is removed. 760 party, 310 binding, 78 native-contract and 255903 secure
checks pass across five source models, plus existing aura/clock checks. Five fresh
alternating pairs reject the checkpoint alpha branch and pass current code.
Final217 scripts/880 Lua syntax PASS at the tested snapshot. Party runtime
owners remain unchanged; later unrelated utility/runtime-test edits cause global
corpus drift and retain their separate validation. All65 party runtime file
comparisons across five installed copies match through existing sync. No duplicate
copy, new recurring party driver, game input, profiler/WTF write, branch or push.
Dated external source/history and 158 on-disk settings verified. Final visuals,
combat/input/secret/taint/FPS acceptance remains pending separately on each client.
Meter work stays excluded. [Evidence](validation/party-native-followup-2026-11-07.json).

7 November utility spell/item modifier faces (UTL-MIX-01 through UTL-MIX-03):
exact held chords select one action and matching icon/tooltip/cooldown/range,
with the existing preferred-base fallback. Native modifier attributes prepare
outside combat. Utility counts use shared EBS live rules for stacks, item
charges, reagents and spell charges; bag changes repaint during combat without
protected writes. Existing settings/layout/cadence remain; no new recurring
driver. 3269 focused checks, five baseline-rejecting pairs and three rejected
mutations; full215 scripts/878 syntax PASS at the tested snapshot. A later
unrelated UnitFrames/FluxUnitFrames_Party.lua edit causes global corpus drift;
both utility runtime owners remain at their tested hashes. Preserve that work.
Later party-test edits also drift; docs check has5 unrelated party inventory/
view/verification issues and no utility source errors.
All five installed manager copies match through the existing mirror. External
source/history/settings recovery verified; fresh source/history checkpoint and
settings metadata captured. Fresh upstream lookup unavailable; packaged/local
contracts recorded. Native input/pixels/combat/taint/secrets/FPS pending; no
Witchcraft tool available. No game input or WTF/profiler writes.
[Evidence](validation/utility-mixed-faces-2026-11-07.json).

7 November split aura timer policy (UF-AURA-02): user rejected separate
Target/Focus controls, then narrowed the all-frame suggestion to two families.
Unit Frames > General controls normal party + target + focus via the scoped
unitFrames.auraTimersUnderMinute key (default off). Party / Raid independently
controls raid + compact party using its existing key/default. Normal party had
shared raid's formatter; it now binds a separate formatter at native creation
and refresh. Plain clocks and previews choose the same family. At>=60 only text
blanks; icons/swipes/stacks remain. Target/focus native formatter and legacy
sweep also follow General; ms-to-seconds fix retained. Existing combat deferral
and cadence/resources remain; no new event/ticker/timer.36 focused checks plus
1696 raid-option/12776 renderer checks PASS; five paired regressions PASS.
Final 214 scripts/877 syntax PASS; tested corpus unchanged. All nine feature
files match across all five client copies through existing sync; no duplicate
copy performed. Final native visuals/secret/combat/taint/FPS remain pending.
[Evidence](validation/unit-aura-minute-split-2026-11-07.json).

7 November meter menu/tab routes (METER-WINDOW-ROUTES-20261107): fixed the
remaining geometry-only routes in FluxWindow's active Meter-tab cycle and
preset setter. Explicit native tab entry now commits the requested types and
Current; FluxUI options choices switch from Map before committing, so an old
runtime layout cannot be applied instead. Details retains its existing immediate
quiet re-embed path and eleven-preset wrap. No visual/layout/type list change.
If native UI is not ready, one explicit apply intent reuses existing readiness
Embed/retries. The latest working layout wins, it consumes once, and Hide/Cleanup
cancel it. Startup without that explicit intent still does no native type/session
configuration. No new frame/event/hook/timer/ticker; one transient boolean only.
User reloaded and confirmed both routes configure panes and Current automatically
without the setup-pane click. Native acceptance is selected Forever UI/function;
combat/secret/taint/gamepad/other-client/FPS remain pending. Exact source,
paired/focused/full results and source/history/settings recovery are in evidence.
Final focused validation:12 meter/window scripts PASS;404 control checks,
448 per pinned menu replay; five paired baseline rejects/candidate passes and
four rejected mutations. All15 installed runtime hashes match through the
existing mirror. Whole run:876 syntax PASS,212 scripts PASS and1 unrelated
concurrent party-frame fixture failure; global source drift, meter owners stable.
Preserve the unrelated work; no whole-addon PASS is claimed.
Documentation check reports5 unrelated raid/party inventory/verification
issues and no meter-source errors.

No foreground/input control, direct WTF/profiler writes or manual client sync.
[Evidence](validation/meter-window-routes-2026-11-07.json).

7 November Current segment default (METER-LAYOUT-CURRENT-20261107):
explicit FluxUI layout/type/setup choices now default every displayed native
pane to Current through its original Blizzard session-menu radio entry. Native
stored {type=Current,sessionID=nil} data/responders remain untouched; no private
session setter or history reset is called. Already-Current panes skip selection.
All ten presets, unchanged types, Overall/history, same-layout reselection,
manual overrides and historical-ID clearing have focused coverage. Geometry,
menu opening and background events preserve later manual segment choices;
the next layout choice restores Current. Threat remains independent.
User reloaded and confirmed: all native panes switch to Current on layout choice.
Acceptance is selected Forever UI/function only; native combat/secret/taint,
gamepad, other-client execution and FPS remain pending. No new frame/event/hook/
timer/recurring driver, direct WTF writes, profiler change or game input.
Fresh source pins and external source/history/settings recovery verified.
Final validation:212 scripts/875 Lua syntax files PASS with unchanged corpus;
all5 installed backend/layout pairs match. No duplicate sync performed.
Exact paired/focused/full results and source identities are in the evidence.
[Evidence](validation/meter-layout-current-2026-11-07.json).

7 November party mode and aura columns (REQ-RF-44 through REQ-RF-50):
Party / Raid keeps compact mode as default and adds smaller player-style party
frames, portraits/casts, optional player-pet-style companions and scale controls.
Four other members and four pets use shared UF factories; actual outer hit
rectangles register with Flux bindings. The new final member matches the old
compact party bottom-right at every roster count. Existing raid/compact anchors
stay unchanged. Prepared native state conditions handle combat joins/leaves,
raid conversion and pet existence; option edits defer. Preview party uses the
same visual factory and shared aura sample renderer with isolated non-secure
cells. Aura grids fill columns first (top then bottom), debuffs left, buffs
mirrored right. Uniform glyph/slot sizes remove former boss-slot gaps; limits,
strict dispellable-only, X scale, duration and opacity remain supported.
Reported Secure.lua:445 nil call fixed: ordinary cleanup uses owned references;
GetFrameRef remains inside restricted snippets. Five native secure-handler
models reject ordinary getter access. 535 focused party checks, 210 actual binding checks, 12776 aura
checks and full 213-script/876-syntax suite PASS with unchanged tested corpus.
Five fresh alternating pairs reject the prior grid, and five reject the reported
cleanup mutant. Default mode creates no extra live cells; alternate mode uses
8 cells/8 state conditions and existing active-cast work, no new recurring Lua
roster/range driver. Native visuals/input/combat/taint/FPS remain pending on each
client. External dated source/history and158 on-disk settings files verified;
no game input, WTF/profiler writes, manual sync, branch or push. Meter work was
explicitly excluded and no meter files were edited by this task.
Follow-up: zero spacing between new party members; actual outer buttons reuse
the owned party/raid primary/modifier mouse path and existing hover engine.
Final documentation validation and whitespace checks PASS; all12 feature files
match across all5 installed clients through the existing mirror. Native checks
retain the pending scope above.
[Evidence](validation/raid-party-mode-2026-11-07.json).

7 November native meter controls/presets (METER-NATIVE-CONTROLS-20261107):
the previous picker changed only a layout request. Native type rows now come
from Blizzard's actual menu descriptions and use their public Pick selection
API with untouched responders/data. Explicit type/setup/preset/custom/structure
clicks use native menu entries; missing panes use the original New Window entry.
Preset clicks apply every requested native type immediately. Startup, geometry
repair and combat events never select types/create native windows. Existing
session/history and Save controls remain; no private native setter calls return.
Native responses update both the runtime snapshot and matching active editor
slot, with stale layout/type guards. Absorbs is removed from the catalog and
builtin5 now uses HPS. Legacy unavailable requests normalize in working views/
previews only; untouched saved custom layouts retain their original requests
until explicit Save. New builtin10 is Threat/Damage over Interrupts/Healing.
Threat remains a separate owned Content child and consumes zero native windows.
User confirmed native menu/type/Flux-label changes, direct Dispels pane creation,
and finally both Dispels and new Interrupts four-pane presets work immediately.
Acceptance is selected Forever UI/function only; native combat/secret/taint,
gamepad, other-client execution and FPS remain pending. Fresh pinned source,
paired desktop/mutation/full results and exact identities are in the evidence.
Final meter checks: all11 focused meter/threat scripts PASS;220 native-control
checks,256 checks per pinned client menu replay, five baseline-rejecting pairs
and five rejected mutations. All5 installed backend/layout pairs match the final
tested hashes through the existing mirror. The final whole run has874 syntax
PASS,205 scripts PASS and6 unrelated concurrent raid-test failures; global corpus
drift prevents a whole-addon PASS. Meter owners stayed unchanged; preserve the
unrelated raid work. Documentation validation reports19 unrelated unit/raid
inventory/verification issues and no meter-source errors. Native acceptance
remains selected-client UI/function only.
Source/history recovery and available on-disk settings verified; no foreground
control, direct WTF writes, profiler changes or manual client copy operation.
[Evidence](validation/meter-native-controls-2026-11-07.json).

7 November mouseover casting (MOUSEOVER-NATIVE-20261107): the toggle remains
directly in the spellbook. Retail/Forever use Blizzard's actual Click Casting
checkbox with its original click/tooltip handlers; it returns to its original
owner/anchors when Click Casting opens or the book closes. Native state and
modifier are authoritative; unsupported clients retain the custom toggle and
saved preference. Defaults and binding saves no longer reset native state or
modifier. Native slot targeting stays prepared through combat; standalone
spell/item adapters on wrap clients follow the same setting/modifier with the
existing combat deferral. Reuses the shared observer; no new recurring driver.
388 focused checks pass, including actual pinned Blizzard click/target methods;
five baseline rejections/five candidate passes. Final whole-addon run: 211 scripts
and 873 Lua syntax files PASS; complete tested Lua corpus unchanged. Native visuals/input/gamepad/
taint/FPS remain pending. All five installed source sets match through the
existing mirror; no manual copy, game input, WTF/profiler writes or push.
External source/history recovery and settings archive verified before edits.
[Evidence](validation/mouseover-native-2026-11-07.json).

7 November screenshot default preset (REQ-RF-43): user chose member width
0.70, height0.95, power1.00, aura scale1.82, aura X0.50, timer font1.72,
manager1.20 and enabled under-one-minute timers as the default. Both saved
scopes now use these values. Reset sizes copies these eight fields from the
default table, preserving counts/filters/opacity/positions and unrelated data.
Full raid reset uses the same preset; existing explicit custom values are
not migrated. Scale units/rendering remain unchanged, including manager
1.00=70percent native; new default1.20 is effective0.84. Screenshot preserved
externally with hash. Actual scoped reset/refresh checks verify69x42 cells
and10.01x20.02 normal aura geometry; combat changes still defer.
209 scripts/871 syntax PASS with unchanged corpus; five
fresh alternating pairs reject the old all-one default/reset behavior. Eight
other-client files already match; no duplicate copy. No new resource owners
or recurring driver. Separate new native reset check not performed; prior
native renderer acceptances retain their original scope.
[Evidence](validation/raid-screenshot-defaults-2026-11-07.json).

7 November native meter presets (METER-ALL-OPTIONS-20261107): fixed blank
slots when a requested type/window does not already exist in Blizzard's native
configuration. Reserve all exact matches first, then keep unused native panes
accessible for type selection. Mismatched rows have an explicit setup cover;
uncreated slots use the same shared artwork/title/font/color/scale as Damage
and Healing. A native type choice or new-window action triggers one coalesced
layout repair; combat changes defer to the existing regeneration path.
The user chose to keep native meters and configure extra windows once using
Blizzard's menus. No custom renderer, automatic native configuration/creation,
session reset or new recurring driver. Already configured Absorbs and all eleven
enum types skin normally; pinned Retail/Forever native menus omit Absorbs, so
that unavailable selection remains explicitly disclosed. The earlier screenshot
showed the pre-shared-skin setup pane; final native visual/interaction/combat/
taint/FPS acceptance remains pending. 128 focused checks and five alternating
baseline/candidate pairs pass; baseline fails the missing-pane case. Final whole
suite: 209 scripts/871 syntax PASS with unchanged Lua corpus; documentation
validation PASS. Exact identities are in the evidence record. External dated
source/history recovery and existing settings archive verified; fresh settings
metadata only. No game input, settings/profiler writes or manual client sync.
[Evidence](validation/meter-all-options-2026-11-07.json).

7 November Forever talent-group icon (UF-SPEC-03): user's native dump returned
Mage/spec1482/class icon626001/zero points with no dual spec. Forever's loaded
Camelot talent UI uses trait group headers, not Classic specialization tabs.
Resolver now reads active spec group's combat config, tree group display icons
and matching group currency spent; largest investment wins. No profile or
nonmatching profile uses that icon; matching Respec override stays first. No
class placeholder is fabricated for zero/missing data. Single spec works.
59 focused checks; five old-source rejects/five candidate passes. Existing
geometry, events, debounce, settings and other-client policy remain. Native
candidate visual/combat/taint/FPS acceptance pending.
Final rerun: 209/209 scripts and 871 Lua syntax files PASS. The earlier run
caught a concurrent meter-source/test transition; its focused rerun and this
complete rerun pass. The tested unit-frame runtime is unchanged and all five
installed copies match. Native icon/combat/taint/FPS acceptance remains pending.

[Group-icon evidence](validation/forever-talent-group-icon-2026-11-07.json).

7 November MT target opacity (REQ-RF-42): in-range target minis now use
the configured base opacity directly, without the extra member in-range
dimming factor. Unavailable or opaque checkedRange also keeps base opacity
instead of treating an enemy target as far away. A genuinely checked far
result still uses configured out-of-range alpha. Secret checks precede every
checkedRange comparison. Normal member/pet fading and user base transparency
remain. Preview target strip uses the same base opacity. No new range call,
frame/pool/event/ticker/timer. User reloaded: Yes, opacity looks right.
208 scripts/870 syntax PASS, unchanged final corpus; five
fresh alternating pairs reject the previous in-range mini fade. Eight other
client files already match. Earlier manager/highlight and HP-only target
checks remain accepted. Native acceptance is selected-client visual/function
only; broader native combat/taint/other-client/FPS checks remain pending.
[Evidence](validation/raid-mt-opacity-2026-11-07.json).

7 November talent spec-icon follow-up (UF-SPEC-02): fixed client flags lookup
from nonexistent ns.Client to the actual ns.Flux.Client export. The prior mock
supplied the same invented namespace and missed the skipped Forever/Classic
committed-points path. Fixtures now execute Core/Client.lua before resolving
icons, including live point changes and matching/no/nonmatching profile states.
38 checks PASS; five alternating pairs reject all five old-source runs and pass
all five candidates. Existing icon geometry, profile matching, refresh debounce,
events/timers and settings remain. Full 208 scripts/870 syntax PASS, tested runtime hash unchanged. All five
installed runtime copies match; no duplicate sync performed. Native icon
acceptance is still pending.
[Spec evidence](validation/unit-spec-talents-2026-11-07.json).

7 November MT target HP strip (REQ-RF-41): target minis now show only the
target name left and plain HP percent right on one centered row, with no
resource bar and the full strip available to HP. Target percent is separate
from the main member health-text preference and contains no role prefix.
Power events cannot re-enable the target resource bar or query its power.
Pets/full members retain their policies; secure target routing/casts and
reserved mini height remain. The MT preview now includes a pooled target
strip using the same chrome; reused roster samples retire old target strips.
Preview minis skip aura construction. User reloaded: Yes, looks right.
208 scripts/870 syntax PASS with unchanged final corpus;
ten fresh alternating unit/chrome pairs reject the old behavior. Sixteen
other-client files already match. No new event/ticker/timer; at most one
reusable plain target preview per displayed MT owner. Source/history/settings
checkpoint verified with these four runtime owners unchanged despite other
workspace edits during collection. Manager/highlight fixes remain accepted.
Native acceptance is selected-client visual/function; broader combat/taint/
other-client/FPS checks remain pending.
[Evidence](validation/raid-mt-target-2026-11-07.json).

7 November unit indicators/spec: player/target/focus share a fitted grid above
health beside class/spec, including native enum master loot. User rejected moved
raid-group labels, shortened names and the health-inset prototype; final grid
reserves no name width and keeps name-relative group placement. ZZZ animates
beside the visible level with static fallback. Matching Respec profile overrides
live spec; No profile/nonmatching uses the most-invested committed tree on
Era/Anniversary/Forever, then active specialization where available. Fixed the
forward-local resolver and current namespace fields. User Forever loot dump
2,0,1 confirms master loot/ownership API; candidate visual acceptance pending.
Desktop evidence and native pending scope: [unit indicators](UNIT_FRAME_INDICATORS.md).
208 scripts/870 syntax PASS; tested runtime hashes unchanged. All five installed
Shared.lua copies match through the existing mirror; no duplicate copy. Native
visual/combat/taint/FPS acceptance remains pending.
No game input/settings/profiler changes; preserve unrelated main work.

7 November currency clicks (STATUS-CURRENCY-20261107): left-click opens/toggles
native Currency where supported, including Retail and Forever, outside combat.
Right-click opens FluxUI Status Bars settings. Existing no-tab fallback and
item drag/clear actions remain. Verified pinned loaded sources: Retail 297d7aaa
(12.1.5.70783), Forever 9dc84f0d (1.60.1.70862). External source/history/settings
recovery verified; fresh settings metadata read only. 640 currency checks and
180 reputation checks pass; preceding currency source fails 44 checks.
Validation run: 208 scripts and 870 Lua syntax files pass. Later concurrent
unit/raid edits leave documentation inventory/verification stale (12 issues);
currency source still matches its tested hash. The initial run
caught a concurrent unrelated unit-indicator test syntax error, since corrected
by its owner. Existing mirror delivered matching Retail/Forever currency files.
No new recurring resources or performance claim. Native clicks/gamepad/taint
remain pending; no game input, settings/profiler writes or manual client sync.
[Evidence](validation/status-currency-clicks-2026-11-07.json).

7 November manager/hidden native highlights (REQ-RF-39/40): manager1.00
now uses a70percent native baseline, as explicitly requested; saved values
and physical vertical alignment/native X/collapse behavior remain. Hidden
selection/ready-check layers now inherit ancestor opacity, including when
their own alpha is opaque. Original flags/known alphas restore on disable.
Two secure post-hooks catch late native setup/selection updates, including
anonymous pooled children. Unprotected alpha/inheritance changes suppress
late combat highlights; structural changes still defer. Native events,
scripts, parents, visibility, profiles and restricted aura subtrees remain.
206 scripts/868 syntax PASS with unchanged final corpus;
ten fresh alternating pairs reject the previous size/ghost behavior. Twelve
other-client files already match. No new pool/frame/ticker/event or polling.
Five fresh pinned API sources verify the display methods are unprotected.
User reloaded and confirmed: Both fixed. Native acceptance is selected-client
visual/function only; broader native combat/taint/FPS checks remain pending.
[Evidence](validation/raid-manager-overlay-2026-11-07.json).

7 November final live aura width (REQ-RF-38): native width now follows the
slider through scoped refresh. Stored initializer metadata supplies sizes;
out-of-combat styling first checks canaccesstable for all native buttons and
labels. No native size/unit/visibility is read. If native access is denied,
keep the existing icons and geometry and mark pendingWidth for later safe
refresh. Public group layout updates the flow widths. Native source uses
DenyTaintedAccessWhenAurasAreSecret, correcting the earlier blanket assumption
that every styling change needs reload. The external display-sibling attempt
failed native visibility and was rolled back; rejected source/logs remain
external. The guarded replacement was accepted: Live icons resize correctly.
User also accepted preview parity, live timer font, zero-gap side grids,
black outline/shadow and below-one-minute timer policy in earlier checks.
206 scripts/868 syntax PASS, unchanged final corpus; five
fresh alternating pairs reject the old preview-only width callback. Eight
other-client runtime files match; no duplicate copy. Metadata only, no new
frame/pool/event/ticker/timer. Native acceptance is selected-client visual
behavior; other-client/combat/taint/FPS checks remain pending.
[Evidence](validation/raid-live-width-guarded-2026-11-07.json).

7 November live timer/grid/policy (REQ-RF-35..37): timer-font slider now
updates a shared public Font inherited by already registered native labels,
instead of a size captured at reload. Combat changes defer; X width still
requires reload. Buffs remain right and debuffs left, up to three columns
and two rows with zero icon/row gaps. User reloaded and confirmed: Both work.
Added black OUTLINE plus black shadow, and an optional Show aura timers only
below 1 minute toggle (default off in both scopes). One shared numeric
formatter blanks60seconds and above, retaining icons/swipes/stacks without
reading restricted durations. Native bindings and preview/readable clocks
share that formatter. User also confirmed shadow/threshold behavior: Yes, all work.
206 scripts/868 syntax PASS with unchanged final corpus;
ten alternating pairs reject the earlier grid/options behavior. All20
other-client files match; no duplicate copy. One shared Font/formatter,
no new native aura family or addon event/ticker/timer. Other-client native
combat/taint/FPS checks remain pending.
[Evidence](validation/raid-timer-policy-2026-11-07.json).

7 November preview/live parity (REQ-RF-34): user reported differences in
both frames and auras. Live and preview now inherit one visual XML template
with separate secure/plain behavior. Shared owned-health aura bounds and
canonical duration-font projection remove independent sizing rules; preview
side hosts clip like live rows. All health-text modes use one formatter;
offline colors, center host/layer/size, overflow atlas/geometry and prediction
sample colors/order now match live. Readable large aura X scale is corrected.
Positions, joins, ordering, bindings, saved scopes, filters/counts/opacity and
swipes remain. X/font native changes still require the documented reload.
206 scripts/868 syntax checks PASS; unchanged final Lua corpus.
Five fresh alternating pairs reject the old preview. All20 other-client
files already match; no duplicate copy. Two public clip hosts per preview,
no new addon event/ticker/timer. User reloaded and confirmed: Looks consistent
now. Acceptance is selected-client visual/function only; other-client native
combat/taint/FPS checks remain pending.
[Evidence](validation/raid-preview-parity-2026-11-07.json).

7 November aura width/font controls (REQ-RF-33): added Aura width (X) and
Aura duration text size, both 0.50..2.50 with default/reset 1.00 in both
scopes. Preview updates immediately. Live native glyph/text dimensions are
prepared only by their one-time initializer, so these controls explicitly
require /reload; ordinary refresh retains the loaded native width. Normal
and large glyph widths/slots scale together, height stays unchanged, and
duration font size multiplies the fitted text size. Existing overall size,
filters, counts, opacity, swipes and combat deferral remain.
206 scripts/868 syntax checks PASS with unchanged sources;
five alternating baseline/candidate pairs reject missing X scaling. All20
other-client files already match; no duplicate copy performed. No new
pools/events/tickers/timers. Native visuals/combat/CPU/FPS remain pending.
[Evidence](validation/raid-aura-width-font-2026-11-07.json).

7 November aura-only scaling: user explicitly chose to resize only auras,
keeping frame size fixed and permitting larger blocks outside the frame.
Removed the hidden inside-fit cap from actual geometry and the slider;
0.50..2.50 now applies directly, with Blizzard 11px/16.5px at 1.00.
Counts, filters, opacity, swipes, fitted fonts and combat deferral remain.
206 scripts/868 Lua syntax PASS with unchanged sources;
five fresh alternating baseline/candidate pairs reject the old cap. Eight
other-client files already match; no duplicate copy performed. No recurring
resources added. New native visual/combat checks remain pending.
[RAID-AURA-INDEPENDENT-SCALE-20261107](validation/raid-aura-independent-scale-2026-11-07.json).

7 November final native-size contract: user chose all Blizzard default sizes,
then explicitly required no toggle and1.00 as every size slider's native baseline.
Frame/power/aura/manager scales now use source defaults without the earlier1.3,
power0.8 or manager0.85/MT0.9 multipliers. Reset sizes changes only five size keys;
full defaults also1. Existing stored requests remain until reset. Fonts, normal11
and boss/role16.5 squares, insets/bars/indicators follow pinned native equations;
one-pixel joins and half-height minis preserve the native body. Counts/strict
RAID filters/class buffs/Flux casts/visible fitted timers and bronze theme remain.
The screenshot's oversized Offline/health label reproduced cumulative FontString
scaling; absolute Font-object baselines now pass50-refresh/locale regressions.
User reloaded, used Reset sizes and confirmed: Yes, sizing and fonts look right.
206 scripts/868 Lua syntax PASS with unchanged corpus;20 baseline/20candidate pairs and
five font-specific pairs reject the old failures. All five client folders match;
36 other-copy file hashes verified with no duplicate overwrite. Native acceptance
is limited to the selected test client; other-client/combat/taint/FPS checks remain.
Latest Forever source is5987a8e (70840); other four pins unchanged. Preserve all
unrelated main work and preferences; no agent game input/commit/push/WTF writes.
[Native-size record](validation/raid-blizzard-default-sizing-2026-11-07.json).

7 November reagent ownership: actual spell reagent evidence controls Preset
classification. Preserve the existing shared target store, quantities and flags;
no separate preset database or destructive migration. Explicit rune names may
resolve item IDs before cache load; never infer a cost from the spell ID or
unreadable text. Identify Soul Shards by item identity, not the summoning spell's
name. Travel uses the existing reagent index and shared inline editor. Keep
flyout/cast/modifier behavior; single-destination right-click owns target editing.
Include known spellbook flyout children via the existing Core.Spell adapter,
select active overrides and deduplicate; retain legacy routes and add C_Flyout
table fallbacks without replacing any global API.
[Case](TELEPORT_REAGENT_RESTOCK.md).

7 November live aura slider follow-up: user rejected the previous slider
display and clarified that the main frames must be30% taller too. A user-owned
probe at1.45 showed capped12.1px icons; forcing0.50 through the actual scoped
refresh returned public scale0.4767 and the user confirmed normal icons shrank.
That proves prior native scale propagation. New UI exposes the responsive fitted
range with0.01 steps/current dimensions, preserves stored requests until selection,
and refreshes cached bounds without synthetic saved writes. Main heights now
multiply saved scale by1.3 (default43->56; saved1.0:36->47); width remains.
Canonical normal icons10x19.5 fit that height; duration fit and strict1â€“6 limits
remain. Mini targets stay within their18px reservation. 203 scripts/865 Lua syntax PASS,
with all runtime/aura/renderer sources stable during both complete runs;
20 matched baseline runs rejected/20 candidate runs pass. An unrelated teleport
test changed during both runs, and its runtime owner changed that subsystem
afterward. Both raw manifests remain; the global corpus is not called frozen.
All five delivered feature files match the tested manifest; unrelated work stays.
Final new UI/height/native combat/taint/pixels/FPS acceptance is pending all5.
No agent game input, WTF writes, profiler change, commit or push. The user probe
set aura scale0.50; choose the desired new value after reload.
[Live slider record](validation/raid-aura-slider-live-2026-11-07.json).

7 November aura size/count correction: user chose to keep icons inside and
cap their size. Canonical10x15 native creation removes startup-dependent sizing;
live/readable/preview share uniform fitted geometry. User's later x1.30 request
uses the confirmed30%-taller choice:1.00 requests14.3px height vs old11px;
minimum0.50 permits shrinking; inside-fit cap remains. Duration fonts fit the
actual icon rectangle, including m/h/d suffixes at partial clip edges.
New scoped maxBuffs and
maxDebuffs1â€“6 default6; demo counts remain separate. Strict mode retains only
HARMFUL|RAID on every original/tail owner. Exact4/5 across mixed categories uses
lazy clipped native row copies; no native child inspection or handler replacement.
Default native icon pools stay120/cell; both partial sides can add120 once, reused
and unbound while inactive. No new addon recurring work. 200 scripts/862 syntax PASS,
unchanged Lua corpus; five alternating regression pairs per aura/layout/preview
reject15 baseline runs and pass15 candidate runs. Native pixels, logical-visible
clip scheduling, combat/taint/casts and FPS remain pending on all5 clients.
Preserve unrelated work and profiler preferences; no commit/push or game input.
[Size/count record](validation/raid-aura-limits-2026-11-07.json).

7 November badge cooldowns: preserve existing scalar rules and return positions;
append public GCD metadata and use it only when timing is restricted. Unknown
restricted state keeps the badge visible. Do not read charge state or change
bindings, swaps, alpha/layout or proc art. Remove only the proven unused power
snapshot chain; live ghost feedback and its shared anchor helper remain.
Native probes use the original strict background guard; the attempted helper
change for other-app switching was rejected by automatic approval review and
was not executed. No approval bypass or foreground input.
[Case](UNIT_STATE_SECRETS.md#follow-up-badges-and-unused-power-snapshots).

6 November unit identity: test readability before branching, comparing or
formatting API values; cache readable GUIDs only. Keep prior public identity
through restricted samples, using existing identity events to invalidate swaps.
Power-cost watcher owns cast restoration, including pet replacement; Shared
resets health-loss before child paints. Do not add broad error suppression,
replace native APIs, reset settings or remove feedback. Unknown aliases never
select player-only surname behavior. Desktop safety models do not certify
native secret VM or explain the earlier random freezes.
[Case](UNIT_STATE_SECRETS.md).

6 November TacoTip ownership: fix the owning tooltip renderer rather than
adding a shared Backdrop/API workaround to FluxUI. External installed TacoTip
remains read-only by explicit user choice. No third-party edits are planned;
a SetBackdrop-only guard is incomplete because native resize still runs.
[Finding](TACOTIP_BACKDROP.md).

6 November aura text scaling: user returned the native owned-clock probe.
It confirms automatic positive/zero visibility and plain59/1m/30m formatting
for that isolated widget. Known59 measured15.2 inside12px; the previous6px
font floor was insufficient. Duration text now uses proportional SetTextScale
against public sample width/height, before native registration. Text shrinks
below the old floor and grows with larger icons; cached measuring owner,
layout, opacity, swipes and aura filters remain.193 scripts/855 syntax PASS
with unchanged source; five alternating pairs/case reject the old code.
These are logic/source contracts; actual fitted aura pixels, combat/taint/FPS
and other-client execution remain pending. Preserve unrelated work/preferences.
[Text scaling record](validation/raid-aura-text-scale-2026-11-06.json).

6 November aura clock correction: the user rejected the previous display:
duration showed ... and short buffs/debuffs had no swipe. New text uses plain
seconds then m/h/d, with7px preferred/6px fitted font from public sample
measurements on a separate hidden widget. The native cooldown starts visible
before sink registration; an explicit opaque base texture removes inherited
tint alpha. Existing transparency,3Ã—2 layout and aura filters remain.
193 desktop scripts/855 Lua syntax PASS with unchanged corpus; five alternating
pairs/case reject old source and pass the candidate. These are logic/style
contracts, not native glyph or swipe rendering proof. User was given an OOC
owned-widget diagnostic; actual C-widget result and corrected display acceptance
remain pending. Preserve all unrelated map/glow/spike-watch work/preferences.
[Clock correction record](validation/raid-aura-clock-fix-2026-11-06.json).

6 November aura duration follow-up: user confirmed a cooldown swipe over each
buff/debuff with remaining duration text above it. Raised intrinsic swipe
alpha0.3â†’0.75; centered9px outlined/shadowed timers; native labels use one
owned compact formatter when available. Readable timer text now sits above
the swipe and clears on timedâ†’permanent reuse. Alpha settings, icon sizes,
3Ã—2 blocks, eligibility and strict dispel filtering remain. No new frame,
ticker or timer owner; one cached native formatter object.
Final193 desktop scripts/855 Lua syntax PASS with all source hashes and
membership unchanged. Five alternating pairs/case reject the old display
and pass the candidate; raw outputs retained, no native CPU/FPS claim.
New native appearance/combat/taint checks remain pending. Reload and check
a timed buff/debuff plus a permanent buff; preserve the optional spike
watch/profiler preferences and all unrelated map/glow work.
[Duration record](validation/raid-aura-duration-2026-11-06.json).

6 November map ownership: clean up only discarded Flux provider owners;
retain native WorldMap owners and all available provider categories. Native
shared mixins and AcquirePin remain untouched. On canvases with protected
passthrough acquisition, defer only owned RefreshAllData, delayed bonus/quest
and ping work; use the existing Combat service with bounded latest ping args.
Refresh completion precedes ping replay; one failed owner reports normally
without dropping other queued providers. [Case](MAP_PROVIDER_LIFECYCLE.md).

6 November resumed at the user's request. Verified fresh external source,
all-ref history and on-disk settings checkpoint Random-spike-resume-20261106T170042Z
(1,660 actual files /190 settings, ZIPs and bundle verified). New Forever process
and exact window were verified; no active watch and live scriptProfile=0.
Normal Map tab activation changed shared native pin methods from secure to
_FluxUI tainted. Meter tab restored; no FPS or causal freeze claim. Fixing
owned-provider detach leaks first, then reviewing restricted pin ownership.
[Native baseline](validation/map-provider-native-baseline-2026-11-06.json).

6 November pause boundary: honor the user's pause; preserve local main,
all concurrent changes, native evidence and profiler preferences. Resume the
map ownership audit before changing its AcquirePin guard. Do not suppress
protected calls, mute native methods, discard pins, or claim that a nearby
map error caused the earlier gap. No map runtime patch has been accepted.

6 November Forever badge combat paging: prepare proc aura slots on every
badge position of a proc-capable bar slot even when the saved reverse badge
does not name that spell. Let prepared Retail alert art extend beyond the
corner SlotFrame. On badge show/hide, mask or reveal that art from the
published face. Dormant-row badges are visual only; in combat, fill their
spell/item paint fields directly and leave protected action attributes alone.
[Case](FOREVER_SAO_GLOW.md#badge-handoff-and-combat-row-icon-follow-up-current).

6 November random-spike attribution: retain the normal event/ticker/scheduler
owners and attach optional bounded timing observers only while watching.
Preserve existing traces and diagnostics; do not replace global APIs, force GC,
suppress reporters, or equate nearest profiler ticks with exact causality.
Count bursts of small callbacks without summing overlapping inclusive spans.
Global Lua heap changes alone cannot establish a leak. Preserve the user's
choice to leave automatic native Current selection blocked. See
[RANDOM_SPIKES.md](RANDOM_SPIKES.md).

6 November Forever SAO face paging: keep Blizzard's secure aura slot on every
potential main/mini/badge destination prepared outside combat. The existing
column and Extra Button face owner controls only container alpha so the Retail
art follows the displayed Arcane Missiles action during a modifier or reverse
badge swap. Invalidate candidate scans when action slots or programs change;
do not set unit, parent or shown state in combat. Native handoff pending.
[Case](FOREVER_SAO_GLOW.md#mainmini-and-badge-handoff-follow-up-newest).

6 November Forever SAO combat glow: use Blizzard's secure AuraContainer
`AddAuraShownAnimation` to drive the Retail alert flipbook for SAO's 400589
effect, which has no Forever button entry. Resolve button identity and create
the filtered slot outside combat; keep other SAO/native proc paths. Suppress
the old readable 400589 fallback after slot preparation so it cannot leave
post-combat art behind. Native acceptance remains pending.
[Case](FOREVER_SAO_GLOW.md#secure-auracontainer-button-animation-candidate-latest).

6 November consumable follow-up: retain public helpful aura additions by
instance ID so an aura event can change the selected item even when a wrapper
declines the readable index scan. Remove observations on explicit removal or
expiry. Use weapon enchant and player inventory events for temporary enchants;
read the modern paper-doll API when the legacy global is absent. Force a
protected action rewrite only for a selection change and only outside combat.
Native acceptance remains pending. [Case](CONSUMABLE_REFRESH_TIMER.md#aura-and-weapon-enchant-follow-up--6-november-2026).

6 November consumable aura advance: force an immediate selection update only
when a player aura changes the preferred displayed item. Retain coalescing for
unchanged selection and defer protected writes in combat. Fall back to ordinary
`UNIT_AURA` registration when unit-scoped registration fails on older clients.

6 November aura follow-up: the user reported low aura layering and requested
Blizzard raid-frame aura selection. Complete icons, swipes, durations and
counts now sit above names/trim/highlights, with leader/loot/status above
them. Blizzard classifications and priority replace duration/shield rules;
helpful boss/role auras can occupy the debuff side. Public hidden-buff
preferences refresh without protected layout work. The requested strict
six-slot dispel policy and aura transparency remain. Explicit OOC present
class buffs override native hidden-group preferences. The user returned
a Forever stage-b diagnostic showing valid active native binding with15
hidden buff types after reporting no buffs. Stage-c corrects the OOC
class exclusion interaction. The user returned its diagnostic and then
confirmed that it works fully on Forever. This accepts observed aura
behavior only, not combat/taint/FPS or all-client execution. Native owners
still reject ProcessAura.None before supplemental filtering; the126-case
desktop model omits that gate, so complete native assignment is not proven.
Restricted private hideOnPartyFrames parity remains an API limitation.
Final 181 desktop scripts / 843 Lua syntax files pass; source hashes/membership
are unchanged across the run. Five alternating functional pairs per case
reject the old filters/layers and pass the candidate; no native FPS claim.
Native icon pools increase80â†’120 per full cell for native category ordering;
refresh remains bounded. Other clients and native taint/combat/performance
acceptance remain pending. No further runtime changes follow acceptance.
[Exact follow-up source/check record](validation/raid-blizzard-aura-followup-2026-11-06.json).

6 November Well Fed follow-up: preserve the existing buff-equivalence and
refresh-threshold rule. Use a direct helpful-aura index lookup only when the
shared wrapper declines a readable aura, and reuse a discovered public spell
ID. Keep secret aura durations unnumbered; do not invent an expiry. Native
validation remains required for each installed client.

Final border preference: the user requested the same textured bronze as
HealKit after rejecting the plain matte candidate. The final renderer uses
original Blizzard8036209 gold bands at0.85 brightness with normal blending,
excluding dark padding. Rounded caps appear only on exterior grid corners;
shared separators have one owner. Earlier matte validation is historical.
The latest full validation fingerprints cover this native-art implementation;
native visual/secure-input/taint/performance acceptance remains pending.

6 November party/raid rewrite: the HealKit-style candidate retains outer dimensions,
chat docking, reverse group columns and Flux Binding, with the user's later
connected HealKit-style bronze borders,4px vertical overlap, horizontal0 gap,3Ã—2 buffs right /
debuffs left, visible timers/swipes,70% aura transparency and scoped0â€“100% control.
Names are10px; role12px precedes percentage; leadership/loot/marks have their
own layer. Power base isÃ—0.8. Members follow native INDEX/ASC order. Native
headers prepare80 cells and handle combat joins/leaves/subgroup moves;40 shared
conditions manage actual MT target visibility. Strict dispellable-only covers
all six slots; present class buffs show OOC, missing reminders remain off.
The manager is15% smaller, retains native X and uses one invariant full-panel Y
above the grid in collapsed/expanded/hidden/shown states. Native selection and
both ready-check ghost layers suppress/restore without replacing handlers.
Final desktop checks pass 179 scripts / 841 Lua syntax files; complete Lua membership/hashes are unchanged
across the run. Earlier user screenshots and the13:01:05 secret-mouse stack are
rejected-stage evidence. Final native pixels, casts, taint and performance remain
pending. No game input, profiler change, settings reset or other-client sync ran.
[Requirements and limits](RAID_HEALKIT_REWORK.md), [exact source/check record](validation/raid-healkit-rework-2026-11-06.json).

6 November explicit user decision: preserve every native feature and leave
automatic Current blocked. Freeze the Current implementation; do not add a
custom renderer, private/native writer, reset, automatic setting or manual-setup
completion claim. METER-DEFAULT-CURRENT-01 stays OPEN against the supported API
gap. Reopening implementation requires new user direction and supported evidence.
The successful runtime API/CVar inventory corroborates the source audit but does
not prove a loaded-source fingerprint, taint cleanup or combat acceptance. Keep
the assistant's corrected nil-help diagnostic error separate from native errors.
[Current scope](METER_STANDALONE.md#automatic-current-requirement-and-supported-api-gap).

6 November automatic Current scope: manual selection is not accepted as delivery.
Keep METER-DEFAULT-CURRENT-01 OPEN for all existing and future panes. Rechecked
source pins expose no supported automatic session/default route; do not restore
the native setter that already tainted fields or try another call wrapper.
A replacement renderer is not an equivalent solution while source GUID secrecy
and query restrictions prevent a promise of native combat drilldown. Do not
remove those features or substitute a reduced renderer without user agreement.
Preserve native data/history, current appearance and controls. No runtime change
or new native experiment was justified by this read-only audit.
[Evidence](validation/meter-automatic-current-capability-2026-11-06.json), [scope](METER_STANDALONE.md#automatic-current-requirement-and-supported-api-gap).

6 November native VM rejection supersedes the bounded-call experiment. Its
selection changed1/1/1 while native fields acquired Flux provenance, then ordinary
native icon/timer refreshes failed on secrets. Remove the entire operative native
call/preflight path; both legacy test commands now report UNSUPPORTED without an
operation. Do not retry through another wrapper/barrier. Public API presence,
clean original function metadata and desktop guards did not prevent data taint.
Automatic Current remains unsupported/OPEN; native UI owns the session choice.
Reload cleanup is required, without resetting sessions/history or treating synced
disk files as a native taint pass. Safe full166/823/unchanged sources passes;
the reload was refused before input, so loaded cleanup remains pending.
[Evidence](validation/meter-current-live-checks-2026-11-06.json), [safe manifest](validation/meter-rejected-current-removal-2026-11-06.json).

6 November native meter correction: the explicit pasted status says Overall
for Damage and Healing; it overrides the earlier ambiguous Current reply.
METER-DEFAULT-CURRENT-01 remains OPEN for every existing/future native meter.
Ordinary rendering/layout must keep native data/configuration ownership. The
optional user-invoked `/fbm currenttest` is a separate bounded permission
experiment using the original native method/public call boundary after build,
combat, function-owner and field checks, then re-reading configuration/provenance
and BugTabs. No automatic default, callback privilege claim or reset is inferred
from the API's presence, scratch metadata or desktop tests. Native output pending.
Keep title anchors/baselines unchanged, put the timer after the public heading,
pack14-unit header controls/art and hide Minimize while embedded; restore the
original presentation on release. [Scope](METER_STANDALONE.md#threat-timer-and-current-view-diagnosis).

6 November Forever glow revision: use the current Retail proc flipbook on
Forever when its atlases are available, following the user's updated visual
preference. Pre-acquire on secure buttons OOC. For Forever only, SAO and native
proc callbacks paint immediately in combat; ordinary refresh and other clients
retain their existing batching. Keep the Classic LBG path as a capability
fallback. Native acceptance remains pending; see [evidence](FOREVER_SAO_GLOW.md).

The first live readout showed no SAO screen-hook calls despite a visible
overlay. Use SAO's global `SpellActivationOverlayAddonFrame.overlaysInUse`
for the source-backed Missile Barrage association on player UNIT_AURA and a
coalesced next-frame check. Keep the modern glow frame shown but transparent
between procs, since combat `Show()` on its secure-button child may be blocked.
This candidate still requires native verification.

The live SAO frame list was empty during the visible proc. Follow Forever's
source-declared native `SPELL_ACTIVATION_OVERLAY_SHOW`/`HIDE` events for the
missing Missile Barrage button association, with 400589/Arcane Missiles rank
mapping. Keep an active event marker when SAO has no overlay-list entry;
otherwise the empty list incorrectly forces `Want` false. Live event payload
and button rendering remain pending.

Installed SAO uses secure AuraContainer slots for Forever secret overlays.
The first private-table hook attached zero buttons in the live client. Read
the registered static 400589 `includeSpellIDs` filters and AuraButton frames
from the global Blizzard AuraContainer slot registry instead. Hook their
OnShow/OnHide edges OOC; do not inspect secret aura values or replace native
slot logic. Native acceptance remains pending.

6 November Forever combat button glow: use SAO's resolved screen overlay
show/hide as the combat-readable trigger for its Forever Missile Barrage effect,
which omits a button assignment. Keep the general SAO AddGlow/native glow
routes for all other supported buttons. Treat unreadable combat icon values as
unknown for a known spell ID, while requiring a readable match to retain a
nil-ID face. Keep LibButtonGlow artwork/animation, which matches installed Era
SAO, and do not modify SAO or saved settings. The first global-name hook missed
SAO's cached private-table calls; hook the table methods instead. Subscribe
standalone Extra Buttons to shared glow changes on their existing eval lane.
The global-hook candidate failed the user's combat retest; the corrected
private-table candidate also failed and left a stale glow. Add global low-level
SAO screen show/terminate hooks, which cached ShowAllOverlays looks up at call
time and which do not need the private table. Use SAO's live overlay/fade state
when captured to override stale markers. This candidate's native combat and
clear acceptance failed again for combat glow. Prepare and retain one LBG frame
per Forever secure Flux button out of combat, then play/stop that same Classic
animation in combat without child creation, parenting or anchoring. Keep
prepared frames on their own button through paging and skip the birth animation
on the destination. Native combat, clearing and startup-memory acceptance are
pending for this candidate.
[Evidence](FOREVER_SAO_GLOW.md#combat-button-glow-correction).

6 November timer/session correction: include Threat in the same physical
top/left election as native panes. Forward native formatted timer arguments
opaquely into one owned FontString; no text/duration inspection. Threat-only
time is observed current combat from its existing poll, with unknown-start and
history limits. Report actual Current/Overall/history/unavailable; native UI
owns the choice and no private setter/reset is restored. The user confirmed
both meters now use Current; agent enum/two-fight/reload checks remain pending.
The timer must sit immediately right of its title without moving the title;
measure only public heading width out of combat, never actor/native value text.
A sandbox-empty process list does not prove a desktop
client exited; verify host process/window separately. Do not retry native clicks
from stale view coordinates after the layout changes.
[Scope](METER_STANDALONE.md#threat-timer-and-current-view-diagnosis).

6 November Forever SAO follow-up: user testing rejected the renderer-only fix.
SAO 2.8.9's Forever Missile Barrage effect has no button assignment although
its SoD/Wrath definitions glow Arcane Missiles. Add a narrow 400589 aura to
Arcane Missiles bridge, including ranks; keep generic SAO AddGlow and native
glow events for the rest. Refresh only on changed player aura state and guard
secret native values/IDs. Preserve SAO settings and source files. Native
verification remains pending. [Evidence](FOREVER_SAO_GLOW.md).

6 November native ownership correction: private native Lua setters are not an
AddOn-safe configuration API merely because they are callable. Remove Flux writes
to selected types/sessions, bar metrics, flags/locks/minimize and automatic native
pane creation; use existing native-selected panes and explicit setup messages.
Keep native controls available, preserve stored Flux layouts and report the
configuration gap rather than assigning misleading pane types. Preserve chosen
Current/Overall/history; never erase data or blindly migrate Overall to Current.
The single-timer requirement is presentation only: topmost then leftmost native
pane in physical screen coordinates, with stable fallback for unreadable
geometry. Preserve native time formatting/policy; no secret-duration comparison,
reset or secure-call shim. Header layout changes occur out of combat; combat
election changes alpha only. Writer/timer focused checks and the current
162-script/819-Lua full suite pass; fresh native acceptance remains pending.
[Current scope](METER_STANDALONE.md#current-native-configuration-boundary).

6 November Forever SAO glow: use SpellActivationOverlay's installed
LibButtonGlow renderer for Flux-owned proc faces on Forever, including bar,
Extra Button and badge surfaces. Keep membership from the private SAO hooks,
Flux refresh ownership, `skipBirth`, and pooled LBG hide/transfer semantics.
If LBG is unavailable, retain the existing template/LCG path. Do not change
Era/Anniversary paint, SAO files or saved options. [Evidence](FOREVER_SAO_GLOW.md).

6 November raid input: preserve Blizzard compact-frame parents, events and
scripts while Flux raid frames own the grid. Do not compare or save secret mouse
getter values, and do not infer split click/motion policy from a combined getter
when split methods exist. For an originally readable saved state that later has
a secret getter, pass the known setting directly to its native setter out of
combat; keep the existing Edit Mode and combat deferrals. An initially opaque
switch is left untouched because its original input policy cannot be restored.
This intentionally leaves that specific native widget's input unsuppressed until
a readable snapshot is available; native hit testing must be checked.
[Failure and scope](49-native-mouse-suppression.md#raid-secret-mouse-follow-up).

6 November appearance decision: replace the rejected flat approximation with
optional references to the player's installed Details WoW Interface assets.
Preserve the source atlas padding/density and body-relative nine-piece anchors;
do not compress a transparent 128-unit region into a 32-unit header. Keep stock
Friz titles and use the actual Accidental row font when it loads. Probe assets
through native texture/font setters, not addon metadata or file IDs alone.
Do not load Details/SharedMedia or redistribute assets. Missing references use
the previous Flux/Blizzard fallback. Data, wrapping, host/tab ownership, controls
and saved profiles remain. [Scope](METER_STANDALONE.md#installed-wow-interface-art-references).

5 November meter appearance: disable FontString wrapping directly without
GetText or secret-text inspection. Use shared Friz 12 titles/ArialN 14 rows and
consistent panel/row fills; normalize the texture's independent alpha so native
refreshes cannot multiply it away. Match the owned header to native 32 logical
at 0.8 scale (25.6 visual) and retain row geometry/pooling and native controls.
Reapply after native configuration plus one session UpdateBackground posthook;
source windows without that method get no fabricated hook. Released/Details
owners remain inactive. Preserve the player's current builtin 7 choice.
[Appearance scope](METER_STANDALONE.md#one-line-names-and-shared-meter-appearance).

5 November threat follow-up: establish a valid native presentation font before
SetText/SetFormattedText; do not catch and suppress incomplete construction.
Sort readable rows percentage-first with raw-value fallback, matching the
existing threat view. Out of combat clear rows and stop the update driver; keep
the wake events but perform no threat scans. Preserve opaque display/order and
the existing in-combat cadence. Compare quiet work with a separately font-ready
reference, since the published baseline aborts before that scenario can run.
[Evidence](METER_STANDALONE.md#font-readiness-and-quiet-threat-follow-up).
Latch explicit addon Hide before native enforcement because the old tab's onHide
runs before activeTab changes. Native and owned views share the effective-host
gate; only an explicit Embed/Show releases Hide. Keep this state addon-owned,
without changing Blizzard visibility or suppressing native timer dispatch.

5 November standalone meter: reuse the current threat adapter and a small shared
skin service. Recreate the accepted Flux Details look with Flux/Blizzard assets
and the client's ARIALN font; exact reserved art/font identity is not claimed.
Keep native combat-data initialization, duration formatting and menus native.
The independent threat pane belongs to Flux Content, not the native meter root.
Public threat can rank normally; opaque values remain display payloads in stable
roster order without invented ranks or ordinary Lua comparisons.

Retain native presets 1-6/default 1 and Details priority. Add opt-in threat presets
and allow three native panes plus one threat pane, preserving old saved layouts.
Hidden/Details handoff stops owned polling/events; one shared theme posthook is
permanent but releases inactive owners. Native paint/reload restores native
appearance after release; no native script-replacement or undo framework is added.

The user's checkbox report and explicit automatic-enable request authorize the
public damageMeterEnabled CVar to be enabled out of combat for this backend.
Do not write private visibility/cache fields, load Blizzard_DamageMeter from Flux
or manually dispatch native callbacks. Native visibility policy stays native;
the earlier core-only enabled-policy result is historical.
[Requirements and limits](METER_STANDALONE.md).
The enabled Meter tab must own native visibility from startup before the first
Embed; other Flux tabs hide native panes. A disabled Meter tab must leave native
policy alone. Late native anchor restore needs coalesced geometry-only repair
out of combat, with combat work deferred. Both boundaries pass desktop regressions; native reload/combat checks remain pending.

5 November wand swing visuals: use the equipped ranged wand's readable damage
school, not Shoot (5019), as the explicit visual mask for the existing cast
school renderer. Keep the item lookup on equipment/data events and the renderer
on its existing visible-only driver. Unknown, inaccessible and non-wand items
retain the ordinary swing fill. The Classic ranged-slot correction intentionally
changes a previously missed wand label/wind-up path; native cadence and pixels
remain pending. [Evidence](SWING_WAND_CAST_THEME.md).

5 November meter visibility ownership: leave `DamageMeter.visibility` to
Blizzard Edit Mode. Flux must not force Always through a setter or direct field
write; native combat updates read that field before comparing session duration.
Honor native visibility/enabled/content policy while retaining the Flux host/tab
boundary, layout, menus, selections and Details priority. Restoring the player's
native visibility choice intentionally replaces the old forced-Always behavior.
Keep timer/rendering methods native and preserve opaque combat values; do not
add a placeholder, global replacement, privilege shim or error suppression.
Reload before acceptance; remaining native configuration/Show boundaries require
real client checks. [Evidence and native steps](METER_COMBAT_VISIBILITY.md).

5 November minimap mail ownership: reuse the existing named Flux fallback after
the two existing native-frame choices. Do not adopt/reparent Forever's different
32Ã—24 native indicator or alter the accepted 20Ã—15 fallback, anchors, tooltip,
events or timing. The defect is resource ownership: repeated layouts and mail
events created more frames and listeners. A normal reload retires old instances;
the new lookup prevents their recreation. This correction is independent of
inventory provider selection. Native flicker, freeze, pixels and FPS remain
pending. Keep WoW background and external reference addons unmodified.
[Lifecycle record](MINIMAP_MAIL_LIFECYCLE.md).

Treat Retail missing tooltip data as unresolved and uncached, using the existing
uncollected paint until a later normal update has data. Do not add polling,
continuations or broad error suppression. This is a separate reproduced Retail
error-amplification fix, not native Forever freeze acceptance.
[Tooltip contract](AUCTION_COLD_TOOLTIP.md).

5 November provider row reuse: change only FluxUI's shared `FillFromList`.
Prepare complete maps, reuse an immutable previous per-index row only for exact
ID/count/link equality, and swap maps before the existing generation publication.
Keep provider facts, synchronous rebuilds, unchanged guards, callbacks and cadence;
do not reorder facts to improve reuse. Full-list validation/reconciliation remains
O(N); a temporary second index map replaces repeated normalized-record allocation
and old-map clears. Treat native progressive slowdown as unresolved. Preserve
newer consumable work and keep the external Syndicator patch proposal outside Git;
installed reference files remain unchanged until explicit authorization.
[Evidence and acceptance limits](PROVIDER_SNAPSHOT_ROW_REUSE.md).

5 November Consumables countdown: use the active buff's public expiration
minus the configured refresh threshold as the visual deadline for the button,
wisp lock, and config cell. Keep actual item cooldowns separate, and omit an
uncomputable numeric countdown when aura expiration is secret. Share the
calculation from `Consumables.lua`; do not alter buff eligibility or stored
threshold values.

5 November charge scanner: use the restock bank adapter's public
`ForEachOpenStack(opts, callback)` when scanning charge maxima for an open
bank. Include character bank and supported warband stacks. Keep the bag-only
result if the optional iterator is unavailable during partial load. This
corrects the user's native nil-call trace without changing saved data or
button selection policy.

5 November consumable editor: a verified item cursor ID is sufficient to save
the preset entry while metadata loads. Render saved configuration independently
of effective bag usability and before the live button update; display the
window before that refresh. Keep weapon compatibility limited to button
availability and preserve physical inventory/restock counts. No saved-data
migration or client-specific branch is needed.

5 November publication preparation: reuse the mail/auction scan jobs and their
existing per-frame budgets to prepare complete normalized maps before atomic
publication. Retain original equality, scan cadence, stable region objects and
Index results. Change the internal index-map identity only at completed changed
generations: the repository consumer audit found no cached inner mail/auction
index or public GetSnapshot exposure for those regions. This trades temporary
staging maps for removal of unbudgeted final copy/clear/fingerprint bursts; native
getters and downstream listeners remain separate cost boundaries. Buy-to-mail is
a distinct delivery and collection path, not an assumed direct bag update.
Keep external Syndicator's reproduced cold-post callback/retry defect separate
and unfixed here; do not wrap external globals or suppress its errors. Neither
finding attributes or resolves the reported whole-game freeze. No game input or
profiling; preserve background operation and settings.
[Flow scope](MAIL_AUCTION_REWORK.md),
[mail preparation](BUILTIN_MAIL_PUBLICATION.md),
[auction preparation](BUILTIN_AUCTION_PUBLICATION.md),
[external reference](EXTERNAL_SYNDICATOR_POSTING.md).

5 November mail/auction lifecycle: keep Blizzard responsible for posting, sales,
buying, cancellation and confirmation dialogs. Flux's built-in observer must
check provider ownership before a native owned-list query and latch its attempt
before native reentry. Reset that latch on close while preserving modern trigger
timing and cached-fact refreshes. Stop active mail jobs before an empty eligibility
scan, and stop only jobs whose owning module is disabled. Reuse wake cancellation,
settings notifications and existing cadence; leave an issued native command alone.
The reproduced failures justify these small changes, not a claim that whole-game
freezes are fixed. Preserve background operation, profile0 and enable flags while
candidate identity remains unverified in the replacement Forever process.
[Whole flow scope](MAIL_AUCTION_REWORK.md),
[auction details](AUCTION_QUERY_OWNERSHIP.md),
[mail details](MAIL_JOB_LIFECYCLE.md).

5 November built-in inventory follow-up: reuse the item-data service and its lazy
frame, coalesce native loads/callbacks, gate retry work at0.4s/earliest deadline
and cap active attempts at four requests/eight seconds. Keep bounded passive
ownership so late success and unreadable moved items still refresh their bags;
disarm idle work and retire it on external-provider handoff. Prune all-zero
derived character rows after partial bag repopulation, preserving live row
identity and other ownership facts. Stop invalid/repeated modern currency IDs
without a valid-list size cap or changing legacy iteration. These are reproduced
contract corrections, not proof of the native freeze cause. Latest native loaded
flags conflict with the user's re-enabled report; preserve flags and background
operation until clarified. Do not repeat heavy frame captures or profiler1.
[Item-data ownership](BUILTIN_ITEM_DATA.md),
[summary retention](INVENTORY_SUMMARY_PRUNING.md),
[currency contract](GOLD_CURRENCY_ITERATION.md).

5 November native mail readiness: use the public native command-pending flag in
addition to data confirmation, before advancing or finishing a worker. Reuse two
existing wake slots, retain configured minimum speed, stop busy waits at8s and
invalidate a completed foreign command's watchdog. API absence keeps prior
behavior. This corrects reproduced overlap, not the unmeasured freeze/crash cause.
[Evidence and tradeoffs](MAIL_NATIVE_COMMAND.md).

5 November follow-up: make actual raid child capacity the readiness gate and keep
native fallback until safe handoff. Reuse the existing configure/combat queues;
observe only owned frames and preserve native restricted attribute handlers.
Give mail progress/timeout wakes current-run and action identities, preserving
configured cadence and confirmation semantics. Read Copy/Forward availability
without assembling copy text. Batch Syndicator's progressive auction callbacks
inside the existing inventory bucket, before listeners, and use the appropriate
native owned-list event for empty refreshes. Keep direct rebuilds synchronous,
provider readiness/handoff and guild-bank/void scope unchanged. These reproduced
contract failures justify the fixes; they do not identify the live single-sale
stall, BugGrabber warning initiator or UNKNOWN taint writer. Do not suppress error
capture or edit third-party addons to produce a pass. The user reports Syndicator
disabled in the current failing runtime, so treat its installed 289 source as
reference evidence only. Investigate the built-in provider and fresh error history
independently; do not attribute the ongoing stall to the optional provider.
After the same freeze persisted after reload and the heavy capture was lost in
a reported crash, restore scriptProfile0 and the prior nil capture root; do not
repeat that capture. Return to background-only operation after the authorized
exception. Compare native command-pending mail checks across all five pinned
clients before the smallest further guard, and prefer narrower diagnostics that
avoid full EnumerateFrames. That guard remains pending implementation/validation.
[Source, regression and native acceptance limits](RAID_MAIL_AUCTION_FOLLOWUP.md).
[Native mail/auction comparison](NATIVE_MAIL_AUCTION_REFERENCE.md).

5 November: leave Blizzard meter rendering/Init and duration/visibility methods
native; preserve Flux tint with secure after-only hooks and actual selection
changes through native owners. Do not add another secret-field patch, sanitizer
or CVar toggle. Seed secure raid pools only after final capacity and effective
visibility out of combat; reserve bounded upfront resources and restore owned
shown states. The supplied UNKNOWN stack cannot identify a header or taint writer;
record the independent reproduced capacity bug without claiming native attribution.
[Evidence and acceptance limits](METER_RAID_NATIVE_OWNERSHIP.md).

5 November consumable targets: keep the preset and secure-button owners.
Read explicit weapon-type restrictions from the existing item tooltip service,
compare numeric equipped subclasses, and make the button's effective count
zero when no target is verified. Preserve physical counts for restock and defer
protected rewrites in combat. Unknown tooltip wording keeps the existing melee
rule and is labeled as undetected, so native item/locale acceptance stays open.
[Contract and evidence](CONSUMABLE_TARGET_DETECTION.md).

5 November: filter effective visibility in the existing shared Baganator traversal
and native overlay; retain all-button installation and provider ownership. Use
public tagged skin roots, not assumed numeric frame names. Reveal refresh runs
once after layout dispatch because Baganator assigns slots after showing roots;
merchant/BagShow debounce and unified native reveal cadence stay. No per-item
reveal hooks or ViewComplete polling. Default-overlay improvement is separate
from the normally bypassed Baganator path. Native hitch attribution remains open.
[Evidence, lifecycle cost and limits](HIDDEN_INVENTORY_WORK.md).

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

## 5 November 2026 - metadata event ownership

Global item-cache completion is not a container change. Keep the explicit
classification completion API intact, filter only automatic events to owned
records/requests, and resolve pending reagent names from the arriving record.
Retain full visible-item harvesting for real bag/bank/merchant changes. No new
API dependency or notification delay is needed. The desktop reproduction is a
justified optimization, not acceptance of the reported native Buy spike.

5 November auction metadata: global cache events no longer harvest all bag/bank
names or populate classification records for unrelated auction items. Requested
metadata, failed-load retry, static consumers, explicit completions and immediate
name-only reagent/restock updates are preserved. Five matched desktop pairs:
280,000 name reads and 2,000 container walks become zero for the unrelated burst;
230 checks pass, three mutants rejected; full 127 scripts/782 syntax pass.
The native Buy spike still needs attribution/acceptance across both providers.
[Evidence and next captures](AUCTION_METADATA_WORK.md).

## 5 November 2026 - auction refresh pool ownership

The user requested the immediate Buy spike on all clients, with and without
Syndicator. This authorizes the auction purchase path; guild-bank and void
callbacks remain excluded. Use the native active-row iterator, retain the
existing classifier and tint writes, and keep the bounded legacy UI path.
Do not claim this bounded traversal optimization fixes the reported spike: no
native capture exists. Gold refresh duplication and Syn mail publication remain
investigation leads, not proven major hotspots. See [evidence](AUCTION_PURCHASE_REFRESH.md).

## 2026-11-04 - built-in mail source and ownership

- Treat Postal v4.3.4 as a behavior reference. Its installed `LICENSE.txt`
  and CurseForge project mark it All Rights Reserved; do not vendor or adapt
  its files into FluxUI. Keep its saved data separate until a specific
  migration contract is established.
- Keep the native MailFrame and native sending/taking APIs. The Flux Open All
  control uses a single confirmed action worker and restores Blizzard's Open
  All when disabled. Add Flux-owned controls around the frame and use `Flux.Container` and the existing
  inventory character store for bag/alt facts. Do not change inventory's
  Syndicator mail-provider handoff.
- Use the fifth return of `GetInboxText` for invoice detection in each local
  Blizzard mail source mirror. Preserve the user's direct-implementation
  choice; native visual/interaction acceptance remains pending.
  [Evidence](MAIL_INTEGRATION.md).

## 2026-11-04 - combined Classic character bank

- Match the existing Era/Anniversary combined bag with a ten-column bank grid,
  a coin portrait, bank bag slot row and Blizzard's live purchase controls.
  Host native bank buttons under frames with their original container IDs;
  keep Blizzard's bank frame shown for events and purchase state.
- Bank bag slots are for viewing, dragging and equipping only. Plain clicks do
  not open or close bag frames; the combined window displays purchased bag
  contents. Restore the original button scripts and parents on close/handoff.
- Give Baganator exclusive bag and bank UI ownership at startup and late load.
  No saved-variable migration or noncharacter bank callback changes.
  [Evidence](CLASSIC_COMBINED_BANK.md).

## 2026-11-01 - dim equipped passive trinkets

- Apply the equipped-ownership usability fallback only when the managed
  trinket face has an on-use spell. No use spell means an inactive tint,
  regardless of the generic item API's usable result.
- Retain bright ready on-use faces, genuinely unusable spell dimming, secure
  slot actions and combat-grid mana gem/healthstone rules. Native checks remain
  pending. [Evidence](TRINKET_EQUIPPED_USABILITY.md).

## 2026-10-31 - count equipped trinket faces as owned for tint

- For the trinket menu's managed `/use 13|14` item face, preserve the existing
  owned-item usability fallback when native `IsUsableItem` is false. The
  equipped item is absent from bag-only counts.
- Keep use-spell unusability, cooldown paint, empty-slot desaturation,
  secure clicks, keybinds and the combat grid gem/stone rule. Native five-client
  visual, input, taint and performance acceptance remains pending.
  [Evidence](TRINKET_EQUIPPED_USABILITY.md).

## 2026-10-31 - retain chat durability through world-entry data gaps

- Treat a no-data read during `PLAYER_ENTERING_WORLD` as transient for a
  bounded two-second window. Keep the last label, accept player inventory
  and equipment events, and retry after 0.5 and then 1.5 seconds only while
  no readable value has arrived. Expire the label if both retries fail.
- Ignore a retry from an older world entry. Preserve secure button behavior,
  minimum-slot percentage, color, settings and saved data. Native teleport,
  pixel, taint and frame-time checks remain pending.
  [Evidence](CHAT_CHARACTER_DURABILITY.md).

## 2026-10-31 - default appearance for inaccessible cast schools

- Keep native/default cast appearance when the addon cannot establish a
  magic school, including items, physical spells and secret casts. Keep
  readable magic themes and Blizzard nameplate bar ownership.
- Select the channel spell ID with an explicit branch so Lua never tests a
  secret value or borrows the adjacent empowered return field. Do not infer
  a school from `castBarID`; it is only a cast identifier.
  [Evidence](SECRET_CHANNEL_FALLBACK.md).

## 2026-10-31 - place nameplate school artwork behind native chrome

- Parent nameplate backdrop textures to a Flux host at the plate's frame
  level. Follow plate parent/level changes during active casts. Keep the
  Blizzard cast bar as the fill/progress owner and retain higher edge, halo
  and particle effects.
- Preserve unit-frame artwork geometry, opacity, controls and timing. Native
  pixels, combat taint and matched frame time remain pending.
  [Evidence](NAMEPLATE_BACKDROP_LAYER.md).

## 2026-10-31 - show full chat character durability

- Show the character-button percentage for any readable equipped durability,
  including `100%`. Hide it only when no equipped slot supplies readable
  durability. Keep lowest-slot calculation, colors, event cadence, button
  geometry, secure clicks and saved options unchanged.
- Native pixel, equipment-change, combat/taint and frame-time acceptance is
  pending. [Evidence](CHAT_CHARACTER_DURABILITY.md).

## 2026-10-31 - tint conjured combat items from live usability

- Treat death/ghost as unusable for combat mana gem and healthstone faces,
  even when the native item API reports an owned item usable.
- Once bag data is reliable, let the live item usability result darken these
  faces for other situational blocks. Keep the existing empty-charge rule,
  loading-screen hold, visibility policy, secure actions and bindings.
- Use the existing life-event paint lane. Native all-client tint, input,
  taint, pixel and frame-time acceptance remains pending.
  [Evidence](COMBAT_GRID_CONJURED_USABILITY.md).

## 2026-10-31 - restore cast fill geometry and school-colored tip

- Create the school texture on the actual `TimerBar` for both Flux unit bars
  and Blizzard nameplates. Hide and restore the native source texture only
  while school colors are active, preserving progress geometry and native
  cast ownership.
- Tint the native Spark to the school color alongside the Flux leading-edge
  glow; restore its prior vertex color when the theme clears. Keep interrupt
  feedback and all existing options. Native pixels/taint remain pending.
  [Evidence](CAST_SCHOOL_FILL_TIP_FIX.md).

## 2026-10-31 - style Blizzard nameplate casts with shared school themes

- Reuse `CastBarThemes` and the existing observed-school/metadata resolver for
  target, focus and nameplate appearance. Keep Blizzard's nameplate status bar,
  cast lifecycle, text, shield and important-cast indicators as owners.
- Attach a Flux visual host and a fill region to the native status bar. Hook
  each native nameplate bar's cast transitions after Blizzard runs; never replace its
  methods or persist secret identity. Restricted/unknown identities leave the
  native bar visible. Retain the existing appearance controls and add one
  nameplate toggle in unit-frame settings. Native taint, pixels and frame time
  remain pending. [Evidence](NAMEPLATE_CASTBAR_SCHOOLS.md).

## 2026-10-30 - clear Blizzard MicroMenu children before native callbacks

- Reparent selected buttons and stage unused layout children before any
  Show/Hide path in Flux's rebuild. Finish hiding staged children after Flux
  layout. This prevents Blizzard `MicroButton_OnShow` from finding hidden,
  unpositioned children in `GetEdgeButton`.
- Keep Blizzard `Layout` and `GetEdgeButton` untouched, preserve button order,
  settings and the existing combat/Edit Mode deferral. Native post-fix
  validation is pending. [Evidence](17-micromenu.md).

## 2026-10-30 - retain pending loot sources through delayed chat

- Keep each loot session's cursor origin and captured slot identities for 30
  seconds after close, capped at 32 sessions. Match item link and stack count,
  currency ID or money slot before using a source position. Reconcile a late
  slot/chat pair by source so it displays once.
- Allow one item fallback for a window whose slots were emptied before
  capture. Linkless currency keeps the one-second close grace. Source
  attribution is ambiguous when multiple uncaptured sources remain pending;
  native ordering and placement require five-client checks.
  [Evidence](LOOT_CURSOR.md).

## 2026-10-30 - pin each loot batch to its opening cursor position

- Capture the cursor once when a loot window first becomes ready/open, and
  carry that origin through slot and delayed chat rows. Keep each row's own
  UIParent coordinates so another loot window cannot relocate it.
- For bonus/group rolls without a loot window and Preview, use the cursor at
  that alert event. Preserve three-row capacity, 3-second default, controls
  and source filtering. Native click-to-event timing and pixels remain to be
  checked. [Evidence](LOOT_CURSOR.md).


## 2026-10-30 - restrict cursor alerts to loot sources

- Exclude crafted and pushed/rewarded chat forms. Require a current or
  just-closed loot window for ordinary self-loot chat and currency chat;
  keep direct slot clears, bonus rolls and group-roll wins. Do not infer loot
  from bag changes.
- Keep a one-second close grace for chat arriving after LOOT_CLOSED. This is
  a bounded event-order compromise and needs native confirmation. Keep the
  existing fast pickup, money format and settings. [Evidence](LOOT_CURSOR.md).


## 2026-10-30 - register FluxLoot profile callbacks with the AceDB receiver

- Use `FluxOptions.db.RegisterCallback(FluxLoot, event, FluxLoot.Refresh)`,
  following the established FluxOptions call shape. The receiver is FluxLoot;
  the event is a string; the method refreshes event ownership after profile
  changes, copies and resets.
- Keep loot settings, alert appearance and pickup behavior unchanged. The
  user's stack trace is pre-fix native evidence; post-fix native validation
  is still pending. [Evidence](LOOT_CURSOR.md).


## 2026-10-30 - show looted money with denomination coin art

- Parse only the client's own received-money messages using its localized
  money templates. Show white numbers and MoneyFrame gold/silver/copper
  symbols, with a leading copper/silver/gold icon selected at 100 and 10,000
  copper. Skip unparsed or zero messages rather than repeating raw chat text.
- Reuse the coin art already used by Flux vendor chat. Keep item and currency
  alerts, timing, settings and fast pickup unchanged. Native client checks
  remain pending. [Evidence](LOOT_CURSOR.md).


## 2026-10-30 - default cursor alerts and fast pickup on

- The user clarified that both switches should default on for all five
  supported clients. Keep the separate FasterLoot ownership guard while it is
  loaded, so two addons do not call LootSlot for the same LOOT_READY event.
- Name the existing duration control **Disappear after (seconds)** and keep
  its 3-second default. Preserve saved values; do not reset profiles.
  [Evidence](LOOT_CURSOR.md).


## 2026-10-30 - add profile-scoped cursor loot and optional fast pickup

- Keep the installed FasterLoot addon independent; Flux skips its fast pickup
  path while FasterLoot is loaded. Both switches now default on by user
  follow-up. Avoid changing the user's addon list or Auto Loot preference.
- Use existing AceDB and item services, a three-row visible-only display,
  and loot-slot/chat reconciliation for alerts. Keep loot roll positioning and
  auction, guild-bank and void-storage callbacks untouched.
- Treat desktop event fixtures as limited evidence; native acceptance on each
  supported client is still required. [Evidence](LOOT_CURSOR.md).


## 2026-10-30 - use the native negated Sticky Targeting setting on Retail

- The linked GitHub main file is the same pre-fix source. A 13 August local
  snapshot uses `Settings.GetSetting("deselectOnClick"):SetValue(false, true)`.
  Restore that route only for this uncoupled Controls setting, verify raw
  CVar `1`, and retain raw-CVar fallback when the setting is unregistered.
- Keep the general modern `Settings.SetValue` guard for protected raid and
  nameplate callback ownership. Avoid the historical repeated raw `0`
  writes and leave the camera fallback at 2.6 without an engine maximum.
  [Evidence](RETAIL_CONTROLS_CAMERA_FIX.md).

## 2026-10-30 - audit native Sticky Targeting and use a writable Retail camera fallback

- Use `deselectOnClick=1` as the authoritative unchecked Sticky Targeting
  value. Include it in the first-load audit; keep the Retail Settings API
  taint guard and avoid repeated writes when already correct.
- When the engine gives no camera maximum, use 2.6 on Retail rather than
  assuming 4 from its major version. Give accounts with a prior failed
  first-load audit one settings-only retry; do not repeat binding setup.
  [Evidence](RETAIL_CONTROLS_CAMERA_FIX.md).

## 2026-10-30 - complete first-load settings after world entry

- Apply first-account and new-character nonbinding defaults after the first
  world entry, then audit supported values after startup can settle. Keep the
  existing safe-write queue and the protected raid CVar guard.
- Limit mismatch repair to the armed first-load audit, with three attempts.
  Existing completed accounts keep later changes. Report completion once;
  manual reset completion and specific failures remain visible.
  [Evidence](NONBINDING_FIRST_LOAD.md).

## 2026-10-30 - use the item service for Hearthstone selector hover

- The user's native stack trace shows `GetItemInfo` is nil when the selector
  hover handler runs. Use the already-loaded `Flux.Item.GetInfo` and the Toy
  Box name for an uncached toy. Retain the existing help text and fallback.
- Do not install or enable deprecated globals for this panel. The focused
  fixture removes `GetItemInfo` and reproduces the prior failure.
  [Evidence](HEARTH_CONFIG_TOY_COLLECTION.md).

## 2026-10-30 - gate Hearthstone editor on the earlier core capability

- The user's Toy Box still showed no Hearthstone panel. The editor loads at
  TOC line 145; `FLUX_API` is initialized only at line 204. Its original guard
  always returned during normal loading. The prior fixture incorrectly
  supplied that later API at the earlier point.
- Use `Flux.Cap.hasToyBox`, available from `Core/Capabilities.lua` at TOC line
  22. Keep the separate later `FLUX_API` flag for its existing consumers.
  Use the current item icon API before deprecated globals while building the
  panel, so icon lookup cannot abort creation on modern clients.
- Verify the actual load order in the regression, with `FLUX_API` absent.
  Native visibility and secure use remain pending.
  [Evidence](HEARTH_CONFIG_TOY_COLLECTION.md).

## 2026-10-30 - make Toy Box capability independent of journal opening

- The first diagnosis treated the journal-toggle condition in
  `FLUX_API.hasToyBox` as the registration cause. The later TOC audit showed
  `FLUX_API` itself did not exist when the Hearthstone editor loaded.
- Define Toy Box capability by the toy query and ownership APIs. Keep journal
  opening separate, using the available modern or legacy Blizzard loader and
  native Toys-tab opener. Preserve the existing choice store and UI gestures.
- This change alone did not make the panel appear; the earlier core-capability
  decision above completes registration. Native toy selection, reload, secure
  click and performance checks remain pending.
  [Evidence](HEARTH_CONFIG_TOY_COLLECTION.md).

## 2026-10-30 - finish first-account bindings in one native transaction

- The user saw native assignment/verification fail, then default keys return
  after reload. Blizzard's modern keybinding UI passes an action-specific
  context to binding APIs; Flux omitted it.
- Use that context where available, validate resulting actions rather than a
  single API return, retry only wrong keys up to three times, and complete
  clear/assign/save/load in the same call. Keep rollback and the one-account
  marker; do not add an automatic polling loop.
- Native performance, secure input and disk persistence remain pending.
  [Evidence](BINDING_ATOMIC_CONTEXT.md).

## 2026-10-30 - complete bindings only after native save/load verification

- The version-5 attempt gate claimed completion while the Retail account
  binding cache contained no key bindings.
- Remove SaveBindings from the PLAYER_LOGIN combat-settings pack. Apply the
  keyboard at first world entry to the account binding set, then verify
  SaveBindings, LoadBindings and the supported template before marking
  account version 6 complete after the next real login confirms the saved keys.
- Repair older version-4/5 accounts once if native bridge keys are missing.
  Preserve unmarked accounts and already bound accounts. Roll back failures
  and resume only an interrupted unsaved pass.
  [Evidence](BINDING_PERSISTENCE_REWRITE.md).

## 2026-10-30 - consume the automatic attempt before its first binding write

- The user observed full keyboard replay after reload, including accounts that
  had already loaded Flux. A final save/verification failure can leave the old
  `"pending"` marker behind after native keys were changed.
- A new account gets one automatic pass at first world entry; version 5 claims
  that pass before the first `SetBinding`. Failed partial passes do not replay.
  No-write unavailability may retry within the bounded first-login path.
- Treat old pending/completed markers and existing four bridge bindings as
  evidence to skip a repeat. Ignore overlapping full-reset requests while a
  batch is active. Manual `/fluxdefaults keybinds` remains available.
  [Evidence](ACCOUNT_BINDINGS_ONCE.md).

## 2026-10-30 - apply automatic bindings once for the whole account

- The user clarified that automatic keybindings must run on first account
  load only. Keep one account-wide pending/completed state, independent of
  Blizzard's account or character binding-set selection.
- Migrate any successful version-4 character marker to account completion;
  leave existing accounts with no pending first-account setup untouched.
  A failed first-account attempt may retry until its one successful save.
- Remove Flux keyboard replay from Blizzard Settings reset callbacks. Keep
  explicit Flux keyboard reset commands and the batched eight-write limit.
  [Evidence](ACCOUNT_BINDINGS_ONCE.md).

## 2026-10-30 - complete the full binding reset after one successful save

- Apply the full reset once for each active native account or character
  binding set. Mark version 4 complete immediately after verifying and saving
  that set; accept prior version-4 pending saves without another clear.
- Remove automatic replay on `UPDATE_BINDINGS` and cross-login verification.
  A failed or unavailable attempt may retry until one successful save, with
  the existing three-attempt login cap. Explicit user reset commands remain.
- Scan the binding registry once per reset, cap writes at eight per frame and
  separate clear, apply and save phases. Confirmed scopes do no further
  registry scans. Native FPS/latency remains unmeasured.
  [Evidence](FULL_BINDING_RESET.md).

## 2026-10-30 - reset the active native binding set before Flux defaults

- The user explicitly requested a full clear before applying the complete
  template on all clients. This supersedes the general no-forced-reset rule
  for the one-time first-load repair and replaces custom keys in unconfirmed
  account/character binding scopes.
- Require all Flux XML commands to be registered before clearing. Skip native
  template commands missing from that client. Clear all active keys in batches,
  apply the supported template, verify it, then save that active set.
- Upgrade old markers to version 4, verify across login sessions, and react to
  late `UPDATE_BINDINGS` while pending. Bound retries to three per scope per
  login; confirmed scopes preserve later edits. Native acceptance is pending.
  [Evidence](FULL_BINDING_RESET.md).

## 2026-10-30 - reset the active native binding set before Flux defaults

- The user explicitly requested a full clear before applying the complete
  template on all clients. This supersedes the general no-forced-reset rule
  for the one-time first-load repair and replaces custom keys in unconfirmed
  account/character binding scopes.
- Require all Flux XML commands to be registered before clearing. Skip native
  template commands missing from that client. Clear all active keys in batches,
  apply the supported template, verify it, then save that active set.
- Upgrade old markers to version 4, verify across login sessions, and react to
  late `UPDATE_BINDINGS` while pending. Bound retries to three per scope per
  login; confirmed scopes preserve later edits. Native acceptance is pending.
  [Evidence](FULL_BINDING_RESET.md).

## 2026-10-30 - verify default grid bindings across login sessions

- Keep post-batch and post-combat bridge binding seeds provisional until a
  delayed active-set check. A completed seed must survive a following login.
- Recheck earlier completion markers. Repair lost assignments only when their
  target is free or still has a known stock action; preserve custom target
  actions and intentional unbinds after confirmation.
- Preserve account/character binding scope and existing secure override
  refresh. Native first-load/reload checks remain pending.
  [Evidence](DEFAULT_GRID_BINDINGS.md).

## 2026-10-30 - use Flux-owned raid settings on protected clients

- The user chose to retain the Retail/Forever native compact-frame taint
  guard. Do not write native raid CVars or trigger Blizzard Settings/CUF
  callbacks from Flux on these clients.
- Use the existing account/character Flux raid options for live unit chrome,
  status text and preview. Preserve Classic native profile/CVar behavior and
  existing Flux frame dimensions. Keep Blizzard Interface values native-owned.
- Require native first-account/new-character, combat and Edit Mode acceptance
  before claiming game behavior or taint safety. [Evidence](RAID_OWNED_SETTINGS.md).

## 2026-10-30 - use Flux-owned raid settings on protected clients

- The user chose to retain the Retail/Forever native compact-frame taint
  guard. Do not write native raid CVars or trigger Blizzard Settings/CUF
  callbacks from Flux on these clients.
- Use the existing account/character Flux raid options for live unit chrome,
  status text and preview. Preserve Classic native profile/CVar behavior and
  existing Flux frame dimensions. Keep Blizzard Interface values native-owned.
- Require native first-account/new-character, combat and Edit Mode acceptance
  before claiming game behavior or taint safety. [Evidence](RAID_OWNED_SETTINGS.md).

## 2026-10-30 - complete Classic raid profiles and use Medium nameplates

- Keep missing/late Classic active raid profiles pending, then apply the full
  native raid pack after profile load through the existing writer queue.
  Bound the first-world-entry fallback and leave successful profiles alone.
- Set `nameplateSize` to `2` in both defaults sources. Migrate an existing `3`
  once; preserve any other chosen size and retry a failed or deferred write.
- Retain the Retail/Forever compact-frame write guard. Its protected callback
  ownership remains unresolved for automatic Blizzard raid-setting writes;
  native client acceptance remains pending.

## 2026-10-30 - finalize grid bindings after first world entry

- Use the first `PLAYER_ENTERING_WORLD` after login to write the active native
  binding set, then verify it again shortly afterward before persisting the
  completion marker. Queue behind full-template work or combat and retry an
  unavailable set or failed write within the same login.
- Recheck the old `true` marker once using version `2`; permit the known stock
  achievement action on `Y` to yield to smart mount. Preserve custom target
  actions and later intentional unbinds after version `2` is recorded.
- Refresh labels from `Flux.EBS.buttons`, the loaded grid registry, with a
  legacy fallback. Iterate only loaded modules in the bulk secure rebind pass
  so nil optional modules cannot truncate combat refresh.
- Native first-load input and all-client acceptance remain pending.

## 2026-10-30 - seed missing Flux keys on the active binding set

- Continue the full template on first account setup. Once per native binding
  scope, seed only missing Flux commands into free target keys; allow stock
  action buttons 6â€“8 to yield to the existing grid defaults. Preserve custom
  target actions and commands already bound elsewhere.
- Save the active account/character set and refresh secure button overrides.
  Defer through the existing combat and bulk-binding lifecycle. Persist a
  scope marker only after save succeeds, so a user unbind later is respected.
- Include previously seen characters because the earlier new-character path
  marked them seen without assigning per-character Flux keys. Native clicks
  and other clients remain pending.

## 2026-10-30 - first-login defaults by client CVar scope

- Keep the established full account-first setup and keyboard template. For later
  new characters, apply only CVars the active client reports as character-stored,
  plus the existing raid/chat setup. Unknown scope cannot authorize an account
  preference write; existing custom bindings remain untouched.
- Route character CVar and bitfield writes through the existing Blizzard Settings
  write queue and retain Retail/Forever compact-frame restrictions. Deferred or failed
  character CVar work does not mark the character seen before completion.
- Leave the unreachable post-login three-sentinel/four-mismatch check unchanged
  until a repair can avoid replaying all CVars over user preferences. Native
  fresh-character acceptance is pending for each client.

## 2026-10-30 - vendor chat coin amounts

- Keep existing vendor net accounting and repair/junk messages. Format their chat
  amounts into full gold/silver/copper denominations with native coin texture paths.
- Use the shared merchant formatter when the junk/repair module is loaded, while
  keeping standalone vendor loading capable of the same output.
- Desktop string checks do not establish native texture rendering; verify in-game
  chat on each client when background-safe access is available.

## 2026-10-30 â€” portrait and strip scale correction

- Treat `SetPoint` offsets as frame-local. Do not multiply portrait center
  offset by the frame scale again. Normalize chat/aura positions by effective
  scale before moving focus.
- Convert the action strip top to UIParent units, then the player/side-by-side
  target bottom offset to frame-local units. Keep a four-unit clearance when
  scale differs from 100%; preserve the original 100% anchor.
- Refresh a 3D portrait after an actual scale change through the existing
  display-metrics helper. [Evidence](UNIT_FRAME_SCALE.md).

## 2026-10-30 â€” whole unit-frame scale

- Give player and target one multiplier, and focus a separate multiplier, in
  their existing Unit Frames tabs and account/character scope. Keep saved
  width/height and class-power size controls independent.
- Scale root frames so their children inherit it. Match detached separators,
  atlas borders, target placeholder and Blizzard-owned class resources explicitly.
  Clear the action strip edge at changed scales. Avoid a
  second scale on ToT when it is parented to target.
- Use existing combat-deferred sizing refresh. [Behavior and pending native
  checks](UNIT_FRAME_SCALE.md).

## 2026-10-30 â€” vehicle seat corner and scale

- Reserve a seat-width slot to the left of equipment durability. When the
  visible micro menu or status strip occupies the top-left, keep the chrome
  fixed and put both indicators below whichever extends lower. Otherwise start
  the pair at the screen top-left, preserving PvP-widget clearance.
- Scale the parent indicator to 0.7 so native art and seat buttons keep their
  proportions and hit areas. Keep stock indicator mute and vehicle events intact.
- Existing combat deferral and the status owner's anchor refresh continue to
  apply. Focused desktop layout checks pass; native pixels, clicks and taint are pending.

## 2026-10-30 â€” empty unit resource bars

- Use maximum power, never current power, to classify an absent main resource.
  Compare only nonsecret numeric values. On Live/Forever, layer resource over
  full-height health and forward max power to the secret-accepting alpha sink.
  This also hides a secret zero without branching on it in Lua.
- Apply the behavior to Flux-owned unit frames and raid cells. Existing
  health-only satellites and Blizzard-owned frames keep their respective layouts.
- Use existing power events and partition code. Raid max-power changes now
  trigger updates; combat reanchoring waits for regeneration. Preserve the raid
  hide-power setting, overlays, profile data and frame sizes. Keep text/raid-icon
  anchors in their original upper area while health extends underneath.
- After user feedback, center health text across full HP when resource presence
  is absent/restricted, and retain the original split text area for a known
  positive maximum. Keep power text parented under the alpha-controlled bar.
  The Flux separator starts transparent and follows max-power alpha.
- [Desktop evidence and native limits](UNIT_POWER_VISIBILITY.md). Earlier main
  branch holds below are historical; 29 October main-only authorization applies.

## 2026-10-29 â€” teleport counts/interrupted casts

- User confirms Retail. Native display text, including empty, owns this preset's
  count. Inaccessible tooltip text cannot establish Classic rune costs.
- Reuse filtered spell actions for eligibility, skipping reagent/restock rows.
  Restore macro/face/tooltip on unlock; keep complete updates for list/options/
  favorites changes, existing combat deferral and success delay.
- Preserve saved state, known legacy rune counts, click paths and popup styling.
  Other custom flyouts remain unconfirmed; no speculative shared-effect rewrite.
- Verified external source/history/on-disk Retail settings before edits. No live
  game/profile/diagnostic changes or publication. Desktop counts are not native
  hitch-resolution/FPS/taint acceptance. [Evidence](TELEPORT_CAST_WORK.md).

## 2026-10-29

- Modernize the existing `_FluxUI` and repository in place. User's current request
  supersedes fresh-project/no-old-code/separate-repository/rename instructions in
  older specs. Product requirements remain inputs; conflicting current behavior
  is recorded, not silently removed or redesigned.
- Use the current change branch; leave `main` untouched until explicitly
  authorized. Keep the same TOC, public commands, saved roots and profiles. No push
  or merge is part of the first batch.
- Preserve all actual files and Git history outside AddOns before changes, including
  original untracked package/log and ignored local work. Relevant private settings
  remain outside Git. Exact hashes and recovery procedure are in `RECOVERY.md`.
- Reuse the existing source/reference collector, Lua validation runner, performance
  diagnostics and service architecture. Append ledgers, not a competing framework.
  Refresh generated indexes because the baseline references were stale; their larger
  diff is an audit correction, not thousands of runtime changes.
- Select BUG-001 before general lifecycle restructuring: production Currency/Store/
  Adapter replay proves stale builtin snapshot writes after external Ready. Four
  execution-time guards use the existing authoritative provider flag. Keep four
  shared-bus subscriptions inert after handoff; full provider retirement is separate.
- Preserve standalone startup, immediate money updates, token/warband cadence,
  saved ledger and provider callbacks. No appearance/secure-input code changes.
  Deliberate correction: provider-owned money must not be overwritten by a stale
  builtin event; the regression checks this exact failure.
- Runtime fix/test/fixture are a separate commit from requirements/audit/generated
  references. The supplied package is retained verbatim; no user log or settings is
  staged. Commit-only author configuration follows existing repository attribution.
- Desktop deterministic counters are valid operation evidence, not native CPU,
  memory or FPS. Requests are not executed scheduler passes. Historical native
  samples retain original context and cannot certify this candidate.
- PE versions and source version files are recorded separately from native
  GetBuildInfo. Retain original Wrath, modern Wrath and Cata as distinct rows;
  unavailable or unsupported cases are explicit. No TOC compatibility changes yet.
- Correct documentation when direct source evidence resolves it (`OptionalDeps`,
  Ready handoff, native item identity APIs, `/fluxui bliz`). Preserve unresolved
  product differences/defaults until a focused decision or reproduced defect.

## 2026-10-29 continuation â€” deferred provider work

- Followed the next-step event audit rather than assuming a historical finding was
  an active gameplay bug. Production dispatch reproduces skipped callbacks during
  removal, but the only active removal owner is Context.DisarmEvents and no current
  production call to its unsubscribe path was found. Keep this latent API defect
  documented in `EVENT_DISPATCH_AUDIT.md`; defer a hot-path redesign until a concrete
  consumer or lifecycle migration requires it.
- Prioritize BUG-002: queued/partial builtin mail and auction scans can outlive
  Syndicator readiness and overwrite the provider snapshot. Execution-time ownership
  checks belong at the beginning of each existing StepScan, before debounce/time
  checks. Cancel its data and OnUpdate work, preserving mailbox/auction open state,
  standalone scan budgets, close behavior and incomplete-data retries.
- Keep mail-send/return completion and auction/guild query ownership as separately
  tracked follow-ups. This scan fix does not claim complete builtin-provider teardown.
- Reuse the earlier complete 82-test/723-file baseline only after verifying every
  tested Lua hash matches current bytes. Capture the new focused failure before
  runtime edits and run full candidate validation after the change.
- The next controlled replay proved BUG-003 for both SendMail and ReturnInboxItem:
  completion after Ready mutates the exact character table returned by Syndicator.
  Treat loss of ownership like existing failure cleanup before resolving the
  recipient; clear the pending operation and its subscriptions. Keep this separate
  from scan cancellation, with its own checkpoint, baseline and regression.

## 2026-10-29 continuation â€” disabled Windows lifecycle

- User explicitly deferred auction, guild-bank and void-storage callback audits.
  Redirected independent inspection to the documented WindowMover disable behavior.
- Production Catalog/Engine/Init/options replay reproduced disabled attachment and
  polling, plus public SetEnabled(false) retaining an active scale gesture that
  changes saved scale. Fix BUG-004/PERF-003 using the existing Scan and Refresh.
- Gate discovery before native hook setup; hide/show the existing panel watcher
  through Refresh; call Refresh on both public enable outcomes. Keep enabled
  cadence, frame reuse, native protection guards and saved positions/scales.
- Retain existing permanent guarded hooks, startup proxy/driver, two discovery
  event subscriptions and two bounded startup callbacks. Their disabled Scan now
  returns before catalog access. Do not claim complete module teardown.
- Reused the 84-script full baseline only after verifying all 725 Lua source hashes.
  Captured a new verified external source/history/private settings checkpoint before
  edits. Matched desktop counters establish removed work; native input/pixels/taint/
  performance remain pending.

## 2026-10-29 â€” editorial maintenance

- Use conventional contribution guidelines and development tasks instead of editor
  workflow files. Archive original prompts/templates, planning Word file, old handoffs,
  local backup trees and sync log outside the addon before removing active copies.
- Rewrite conversational comments as technical explanations. Preserve every executable
  Lua token/string, native restriction invariant, license and third-party attribution.
- Retain technical specifications, tests, measurement values and revision identities.
  Use factual descriptions of the recorded procedure. Preserve
  original records in the verified checkpoint and omit optional branch metadata.
- Do not rewrite Git history or alter main as part of a working-tree cleanup.

## 2026-10-29 â€” queued merchant purchase identity

- BUG-005 is an active queue correctness issue: production replay buys a replacement
  merchant item or submits an empty slot after listings change. Index refresh alone
  cannot repair retained task references. Protect the operation, not just index build.
- Reuse ResolveMerchantSlotItemID in RunBuyPass's invalid-task condition. Discard a
  missing/mismatched listing before quantity calculation, purchase, wallet debit or
  reporting. Continue valid tasks at the original eight-call budget and cadence.
- Do not relocate stale tasks or restart the session automatically: a fresh normal
  request uses current index/remaining counts. This avoids resubmitting earlier
  purchases while inventory acknowledgements may still be settling.
- Record the extra identity lookup per valid purchase as correctness overhead.
  No native performance improvement is claimed. Unchanged-ID price/stock changes
  and purchase acknowledgement are separate unmeasured candidates.

## 2026-10-29 â€” finite merchant stock budget

- BUG-006 reproduces two related capacity defects: zero availability was uncapped,
  and repeated tasks reused the same finite snapshot count. Treat zero as a cap and
  reserve submitted quantities on the existing shared index entry.
- The shared remaining value is a reservation budget until index refresh, not proof
  of native acceptance. Do not introduce another transaction service or live polling.
  Unrelated rejections, external stock changes and acknowledgement remain separate.
- Preserve unlimited/nil helper semantics, gold/alternate-cost math, eight-call pass
  budget, UI/defaults/settings and normal refresh/new-request recovery. Extend the
  existing merchant harness with focused stock/identity groups rather than duplicate it.
- Exact read-only Blizzard source hashes support API shape/zero-stock interpretation;
  the 12.1.0.69283 snapshot predates installed clients and does not advance native rows.

## 2026-10-29 â€” vendor-open availability work

- Prioritize the user's idle vendor-open hitch, reported only on Era so far. Do not
  assume first-open/repeated-open behavior or automation settings, and do not claim
  native resolution from a desktop reduction.
- BUG-007/PERF-004 reproduces repeated fallback bag walks in the real availability
  path. Cache its exact boolean result under the existing junk owner using reliable
  bag generation and existing rule/item/list/slot invalidation. A classified count
  of zero alone is insufficient for cold gray-item data. Retain native-positive
  precedence, live retry when unready/unreliable, and all callback timing.
- Reuse the junk-smoke boot fixture and production buyer events plus unmodified UI
  availability sections. Document excluded rendering/layout/integrations. Seven API
  fixtures are regression coverage, not native client certification or original
  Wrath support. Keep cold and repeated-open counts separate.
- Retain the buyer frame and native count-query controls; add no timers/subscriptions,
  settings or generic cache service. Native query overhead, CPU/frame times and the
  remaining classification/index/Already Known/layout candidates need live evidence.

## 2026-10-29 â€” Quick Join anchor ownership

- Prioritize the user's concrete native SetPoint error. The column already anchors
  Channels to Quick Join; the old social callback reverses that edge. Existing
  isolated column/retry fixtures did not run the two owners together.
- BUG-008 returns before the fallback reanchor while either button belongs to the
  Flux column. Check both to survive a native reparent of either one. The enclosing
  callback still reconciles through PlaceColumnButtons; unmanaged fallback remains.
- Add parent/anchor cycle detection and correct bottom-point geometry to the existing
  column fixture, then execute real social/hook/retry callbacks there. Retain its
  five-branch controls. No competing owner, global API replacement or broad runtime
  error suppression is needed; preserve column geometry and the three deadlines.
- The baseline combat exception never reaches its existing waiter. The candidate
  reaches that deferral and reuses one waiter; it does not add a new runtime frame
  service. Native geometry, input/taint and performance remain pending.

## 2026-10-29 â€” repeated vendor tier candidates

- User confirms Era spikes on every same-vendor reopening. Read-only hashes showed
  the preceding junk/buyer/chat fixes already installed; do not assume a stale copy.
  Saved scriptProfile=1 is an observation requiring matched unprofiled validation,
  not proof of causality or permission to change the user's preference.
- Preserve merchant discovery/reference seeding. A blanket lazy-index skip can
  suppress that feature. PERF-005 instead filters actual tier matches before live
  usability in best selection and status; non-improving best contenders also skip
  the gate. Matching contenders retain fresh level/skill checks without a new cache.
- Reuse the existing buyer fixture and actual Score/Match/Vendor modules. Extend
  measurement to 25 reopenings with retained food/water refs and unoffered families
  after the user's cadence clarification; retain the source fix and test extension
  as separate reviewable commits.
- Ready-classification calls remain equal in measured runs. Classification now
  precedes level rejection, so cold tooltip cost can differ and needs native checks.
  Service call reductions are not native cache-miss, CPU, latency or FPS results.

## 2026-10-29 â€” native tier count attribution

- The clean Era 1.15.9.70576 four-reopen pilot reproduces a 333 ms UI interval;
  GetRestockTargetItems spends about 320 ms per call. Inclusive bag/bank count and
  tooltip rows identify a measured target; do not sum overlapping timings.
- PERF-006 filters tier membership before live usability in existing bag and cached
  personal/warband count owners. Keep live gates on matches, accounting, caches,
  fallback and protections. No new lifecycle resources or generic service.
- Five alternating native background getter pairs return identical quantities;
  median CPU is 132.199 to 15.237 ms for five bag kinds, 118.897 to 22.517 ms for
  cached-bank kinds. Bank outputs are zero on this character; positive/warband
  parity is desktop-only. Candidate bodies ran as source-derived local functions;
  no public/native API replaced. This is not full-window after acceptance.
- Honor the user's background PC use: no further game activation. Background local
  slash diagnostics preserved focus; original automation values and profiler=1
  restored, temporary exports removed and sampler/namespaces cleared by reload.
  The user's normal sync delivered source; no separate addon or sync job created.
- Native foreground repeated opens, unprofiled FPS, matched pixels, cold work,
  security/taint and other clients remain pending. Keep auction, guild-bank and
  void-storage callbacks deferred. [Evidence](TIER_COUNT_WORK.md).

## 2026-10-29 â€” whole-addon Retail resource audit

- Cover all 26 loaded source domains through current ownership/recurring-driver
  maps. Native idle execution does not exercise every lifecycle or prove leak-free
  operation; keep pending interaction/client scenarios explicit.
- BUG-009/PERF-007 reuses loot combat/readiness frames after production replay proves
  203 allocations across repeated world/combat cycles. Keep 50-update timeout,
  six-pixel anchor, native show hook and no protected writes in combat.
- BUG-010/PERF-008 explicitly releases full requested-capture snapshots and handle
  cycles. Retained-callback replay proves 20 -> 0 snapshots and 10,000 -> 0 frame
  rows per model. Retain the compact report, schema, deadlines and dormant behavior.
- Native Retail baseline has stable frame/public-cache counts but memory increases
  during diagnostics. Attribute requested capture retention before accusing the
  normal HUD. Native CPU ranks nameplates and assisted painting; do not disable
  features or slow update cadence without matched evidence.
- Discard the incomplete long-upload native comparison; no result for its missing
  candidate. Use normal file-loaded API calls for follow-up. Original profiler=0
  must be restored; no game activation, global API replacement or restriction bypass.
- Preserve the existing uncommitted tracker source/test/docs. Keep its changes out
  of the new runtime commits and record actual-file identities separately from HEAD.
  Main and excluded auction/guild-bank/void callbacks remain untouched.

## 2026-10-29 â€” common Social offset and dock ownership

- User-authorized intentional position correction: one eight-unit inset from the
  tab/menu top across client paths, preserving other layout/feature behavior.
- Use existing tab height as a relative offset. An absolute future top against a
  provisional login chat rectangle goes stale after the final pin; no timer/hook
  is needed to follow that movement.
- Anchor the column to primary ChatFrame1 on all tabs. Combat Log/custom native
  rectangles may differ; selected-tab identity remains solely for Copy/action data.
- Preserve Classic ownership/overflow handling, other menu-position fallback,
  scale conversion, combat restrictions and current retry deadlines. No framework.
- Native seven-selection Retail pass plus untouched reload image supports this
  scope. Five desktop branch models are not other-client native certification.

## 2026-10-29 - original stage tracking and countdown work

- Continue the supplied original plan through explicit stage gates; inventories
  and passing desktop checks do not complete all native acceptance.
- PERF-009 keeps the existing NamePlates owner/driver/cadence and removes repeated
  FontString discovery plus per-aura level tables. Reuse only within one poll;
  changing/opaque labels and native digit fallback remain fresh.
- Keep real unprotected native-widget results separate from actual combat aura
  rendering/taint/FPS. Background whole-addon scene changed, so that comparison
  is inconclusive even though errors remain0 and per-window frame counts stable.
- The user again explicitly requested root working rules and next-session records;
  restore those concise files alongside existing contribution/development docs.
  Do not restore retired prompt templates, narrated comments or private artifacts.
- Preserve the separate tracker work and current branch; main and excluded
  callback audits remain untouched. Keep WoW in the background and profile0.

## 2026-10-29 - action batch facts and native player auras

- Sample activation once within an existing bar paint batch. Pass explicit false;
  retain fresh standalone queries and the API helper's independent guard. No
  cross-frame cache, generic framework, animation suppression or slower cadence.
- Keep top-right player aura data/handlers/styles native. Short-idle measurements
  do not justify a competing aura painter or prove dense/restricted churn safe.
- Treat source-derived real-painter matched runs separately from complete-addon
  CPU/FPS. Both native clients use inactive highlight settings; real active combat
  input still requires acceptance. Preserve failed/inconclusive scope honestly.
- The user authorizes normal reconnect/warning dismissal and named character
  selection for testing. Same-account sessions displace each other: run serially,
  validate each executable/window and preserve foreground PC use. No credentials.
- Leave the user-owned mirror job unchanged. Verify each source transition; when
  delayed, copy only the known test file into the existing authorized client.
  Restore each original profiling preference and prior diagnostic report.

## 2026-10-29 - authorized main publication

- The user explicitly authorizes uploading the whole current addon and updating
  main. Preserve the current development branch and complete existing history.
- Include the formerly pending, already-tested objective-tracker change and its
  records; do not leave part of the authorized addon unpublished.
- Fetch/check remote main, fast-forward only when ancestry permits, and push
  ordinary refs without force. Preserve newer remote work if it appears.
- Keep private backups/settings/captures and ignored local helpers out of Git.
  Native pending checks retain their scope despite publication authorization.

## 2026-10-29 - local files authoritative, main only

- User requests no other branch and explicitly authorizes uploading all current
  local addon files. This supersedes the earlier retained-branch decision.
- The development branch equals main at b45eb5e, so remove both local/remote refs
  without losing commits. Keep normal pushes and all existing history.
- Include the newer local teleport fix and its complete tests/docs; do not reset
  the workspace to the previously published revision or omit uncommitted work.
- Keep private recoveries/settings/captures and ignored local helpers outside Git.
  Publication does not change native acceptance results or live game preferences.

## 2026-10-30 - resource separator and text refresh

- Reapply the main separator's maximum-power alpha after partition and border
  color paint; both paths can repaint its alpha aspect after a power update.
- Keep restricted-maximum health text in the health section. Only a known zero
  maximum selects the full-height text area. Do not test secret maxima for
  truth in Lua; pass them directly to `SetAlpha`.
- Include target-of-target loss and return in focused desktop regression checks.
  Native pixel and combat acceptance remain pending.

## 2026-10-30 - expanded HP text and ToT split

- For a known zero maximum, keep player/target HP labels at their existing
  horizontal sides but center them vertically in the expanded health area.
  On resource return, refresh health text anchors so nested placement returns.
- Keep ToT's UIParent separator container ten levels above the ToT button after
  side-by-side placement changes the button's frame level. Restore the original
  button level when returning to the stacked layout.
- Restricted maximum values cannot select a text layout in addon Lua; retain
  the upper HP placement until a nonsecret zero maximum is available.

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

## 1 November 2026 - repository front page

Use a root [README](../README.md) for the requested GitHub-page feature overview.
Keep each feature summary brief and link to the existing full reference; include
client gates, companion-addon ownership and first-setup effects. Publish current
local files on main with history preserved. This is a repository front-page
change; no hosted site, new addon, new branch or separate repository is needed.

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
