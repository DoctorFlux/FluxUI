# Client and reference validation — 29 October 2026

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
Documentation check is blocked by eight stale inventory/verification entries
from concurrent unit-frame/public-geometry source changes; no utility error was
reported. Preserve that work and refresh its global records when stable.
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
Final preset hashes and8 other-client copies remain matched. Global docs
validation is pending18 stale-view/verification issues caused by newer
unrelated meter/binding/core edits; checker made no edits. Preserve those
changes and do not infer whole-current-tree PASS from the209/871 snapshot.
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
Final scoped audit: all7 raid runtime files and28 other-client copies match
tested identities. Global docs validation remains pending because concurrent
UnitFrames/FluxUnitFrames_Shared.lua and tests/unit_spec_icon.lua edits made
the generated interfaces and verification index stale; checker made no edits.
Preserve those newer unrelated changes; do not infer whole-current-tree PASS.
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

7 November class travel/reagent presets: five travel capability models and
modern/legacy actual scanner/list/facade cases pass 130 + 47 checks; 16 faulty
mutations rejected. Native flyout children, C_Flyout-only APIs, active overrides,
unlearned children and deduplication are covered in desktop fixtures.
Scoped replay passes all six required scripts with unchanged reagent sources.
The last whole-addon run passed 200 of 204 scripts and all 866 syntax files;
four raid-test failures and unrelated source drift prevent a whole-tree PASS.
All four runtime files match the four existing client copies (16 hashes). A
manual-copy verification stopped during active continuous sync; three later
read passes confirmed every candidate, with external destination backups.
Forever process/window was verified; baseline transport completed but no FX
marker appeared with auction/crafting panels open. Native result is inconclusive;
candidate editor/click/pixel/vendor checks remain pending on every client.
No foreground input, test purchases or profiler changes.
[Case](TELEPORT_REAGENT_RESTOCK.md).

7 November final user check: after reload the user confirmed, Yes, height and
normal auras work, for the taller frames and normal aura/duration-text slider.
All five client folders match the tested feature files;20 destination hashes
verified. This task performed no second overwrite because those exact candidates
were already installed. Other-client native execution, combat/taint and FPS
remain pending; this is visual/function acceptance in the selected test client.
[Native acceptance](validation/raid-aura-slider-live-2026-11-07.json).

7 November live aura slider follow-up: user rejected the previous slider
display and clarified that the main frames must be30% taller too. A user-owned
probe at1.45 showed capped12.1px icons; forcing0.50 through the actual scoped
refresh returned public scale0.4767 and the user confirmed normal icons shrank.
That proves prior native scale propagation. New UI exposes the responsive fitted
range with0.01 steps/current dimensions, preserves stored requests until selection,
and refreshes cached bounds without synthetic saved writes. Main heights now
multiply saved scale by1.3 (default43->56; saved1.0:36->47); width remains.
Canonical normal icons10x19.5 fit that height; duration fit and strict1–6 limits
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
maxDebuffs1–6 default6; demo counts remain separate. Strict mode retains only
HARMFUL|RAID on every original/tail owner. Exact4/5 across mixed categories uses
lazy clipped native row copies; no native child inspection or handler replacement.
Default native icon pools stay120/cell; both partial sides can add120 once, reused
and unbound while inactive. No new addon recurring work. 200 scripts/862 syntax PASS,
unchanged Lua corpus; five alternating regression pairs per aura/layout/preview
reject15 baseline runs and pass15 candidate runs. Native pixels, logical-visible
clip scheduling, combat/taint/casts and FPS remain pending on all5 clients.
Preserve unrelated work and profiler preferences; no commit/push or game input.

Installed the five tested Lua files into all four existing client copies after
external guarded backups; all20 destination hashes match the tested source.
Retail remains the working copy. No game input/settings/profiler change.
Reload outside combat to test the new normal-aura sizes and limits.
[Size/count record](validation/raid-aura-limits-2026-11-07.json).

7 November follow-up: five capability models cover readable legacy cooldown
rules and modern restricted metadata; action/badge row-swap, proc and secure
snippet regressions pass.150 new checks/10 mutants; final199scripts/861syntax.
Five files copied to four existing client copies,20 hashes match. Actual Forever
background probes of the preceding identity candidate: functions loaded,
profile0, three BugTabs samples0, TacoTipfalse/Syndicatortrue/Baganatortrue.
New batch: user reload plus observed ordinary combat; cleanup marker nil and
BugTabs0 afterward. Restricted badge transitions; swaps; matched pixels; native
performance and other-client acceptance remain pending. [Case](UNIT_STATE_SECRETS.md#follow-up-badges-and-unused-power-snapshots),
[native record](validation/unit-state-native-followup-2026-11-06.json).

6 November restricted identity candidate: actual-module fixtures cover Retail,
Forever, Era, Anniversary and Classic API shapes;344 focused checks/23 mutants,
final197 scripts/859 syntax pass. Five files copied to the four existing client
copies,20 checksums match. Forever1.60.1/build70790/interface16001 host/window
reverified; only read-only capture succeeded. Native reload refused before input
because WoW was foreground. Native combat/secret VM/taint/pixels/performance are
pending on every client; desktop counts certify none of those. User reports
TacoTip unloaded. [Case](UNIT_STATE_SECRETS.md), [native record](validation/unit-state-secret-native-2026-11-06.json).

6 November TacoTip backdrop error: user stack shows secret-width arithmetic
under TacoTip; report client/frame not identified. Installed Forever0.9.4 has a
source-matched owned backdrop path, reproduced with modeled secret geometry.
Era/Anniversary0.5.1 differ; Retail/Classic copies absent. No runtime change or
native acceptance; the user chose read-only, with no edits planned.
[Audit](TACOTIP_BACKDROP.md).

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
Installed the three changed Lua files in each of the four existing client copies
after external backups; all12 destination hashes match the tested source.
XML/TOCs/settings and profiler preferences remain unchanged. Reload and inspect
actual aura text for final native fitting acceptance.

[Text scaling record](validation/raid-aura-text-scale-2026-11-06.json).

6 November aura clock correction: the user rejected the previous display:
duration showed ... and short buffs/debuffs had no swipe. New text uses plain
seconds then m/h/d, with7px preferred/6px fitted font from public sample
measurements on a separate hidden widget. The native cooldown starts visible
before sink registration; an explicit opaque base texture removes inherited
tint alpha. Existing transparency,3×2 layout and aura filters remain.
193 desktop scripts/855 Lua syntax PASS with unchanged corpus; five alternating
pairs/case reject old source and pass the candidate. These are logic/style
contracts, not native glyph or swipe rendering proof. User was given an OOC
owned-widget diagnostic; actual C-widget result and corrected display acceptance
remain pending. Preserve all unrelated map/glow/spike-watch work/preferences.
Installed the four corrected runtime files into all four existing client copies
after guarded external backups; all16 destination hashes match. The earlier
Forever diagnostic-only file was preserved and replaced by this tested candidate.
The user may check the new display directly after reload; the owned diagnostic
is optional if the display remains wrong. New native acceptance is pending.

[Clock correction record](validation/raid-aura-clock-fix-2026-11-06.json).

6 November aura duration follow-up: user confirmed a cooldown swipe over each
buff/debuff with remaining duration text above it. Raised intrinsic swipe
alpha0.3→0.75; centered9px outlined/shadowed timers; native labels use one
owned compact formatter when available. Readable timer text now sits above
the swipe and clears on timed→permanent reuse. Alpha settings, icon sizes,
3×2 blocks, eligibility and strict dispel filtering remain. No new frame,
ticker or timer owner; one cached native formatter object.
Final193 desktop scripts/855 Lua syntax PASS with all source hashes and
membership unchanged. Five alternating pairs/case reject the old display
and pass the candidate; raw outputs retained, no native CPU/FPS claim.
New native appearance/combat/taint checks remain pending. Reload and check
a timed buff/debuff plus a permanent buff; preserve the optional spike
watch/profiler preferences and all unrelated map/glow work.
Installed only the four changed raid runtime files in each of the four existing
Forever/Classic client copies after external backups. All16 destination hashes
match the tested source; TOCs/settings and profiler preferences are unchanged.
The new native display remains pending a user reload/retest.

[Duration record](validation/raid-aura-duration-2026-11-06.json).

6 November Forever70790 user native confirmation after candidate reload and
Map activation: `FXMAP true true 0`; both queried native method fields secure,
current-session BugTabs errors0. Agent-observed Map rendering is separate from
this user-reported probe. Other fields/clients, matched pixels, right-click and
combat recovery are not certified. [After](validation/map-provider-native-after-2026-11-06.json).

6 November map provider candidate: native Forever70790 baseline normal Map
activation tainted shared native methods and BF AcquirePin.31 detach/36 combat
model checks preserve all11 available layers and legacy capability cadence;
193/855 complete desktop PASS with frozen hashes. Candidate file installed in
existing Retail/Forever/Era/Anniversary/Classic copies, previous files preserved
externally. Forever reload observed, post-activation provenance/input/combat and
other-client native acceptance pending. [Case](MAP_PROVIDER_LIFECYCLE.md).

6 November Forever badge follow-up: native user report confirms modern proc
glow follows main↔mini combat paging. Bar→badge loses glow, and an action-bar
badge loses its icon/display on main↔mini combat swap. The new candidate
prepares reverse badge slots, allows the Retail border to extend beyond the
corner, and paints dormant badge spell/item fields in combat without secure
attribute writes. Desktop baseline rejects the icon regression; candidate
passes 190 scripts / 852 syntax files. After `/reload`, the user confirmed
bar↔badge glow in both directions, proc-end clearing, and badge icon/count/
cooldown during main↔mini combat swaps. Taint, pixels, frame time, other
procs and clients remain unverified.
[Evidence](FOREVER_SAO_GLOW.md#badge-handoff-and-combat-row-icon-follow-up-current).

Native follow-up16:29UTC: ExtraButtons, CombatGrid and NonCombatGrid enabled;
current-session BugTabs errors0; profiler0. Watchv2 confirmed running600s /
200ms in Forever; completion/save and analysis pending.
[Startup](validation/ebs-glow-startup-native-2026-11-06.json),
[arming](validation/forever-random-spikes-v2-armed-2026-11-06.json).

6 November Forever random-spike capture: actual1.60.1 build70790 watch600s,
scriptProfile0, retained7 gaps /0 central spans>=10ms. Two nearest Flux ticks
were214/181ms; longest gaps had little addon billing. The user's120-second
profile1 capture provides function rankings only, not causal or matched FPS
acceptance. Original profile0 restored and read live. Desktop layout/observer/
watch/aura fixtures cover their stated scope only. Watchv2 and new grid/glow
startup regression native checks are pending; other clients need separate runs.
[Evidence](RANDOM_SPIKES.md).

6 November Forever SAO paging follow-up: user confirmed in-combat Missile
Barrage proc art on Arcane Missiles after the first secure AuraContainer change.
The same user test found main/mini modifier and badge/action-bar handoff
incorrect. The follow-up prewarms possible faces OOC and gates art by displayed
face in the existing refresh path. Paging model rejects baseline and passes 9
candidate checks; full desktop validation passes 187 scripts / 849 Lua syntax
files. Native handoff, proc-end, taint, pixels and frame time remain pending;
Era/Anniversary/Retail paths were not changed by this Forever-only branch.
[Evidence](FOREVER_SAO_GLOW.md#mainmini-and-badge-handoff-follow-up-newest).

6 November Forever SAO secure proc glow candidate: Gethe Retail/Forever
action buttons use the same alert template; Forever's secret aura visibility
and animation registration are owned by Blizzard AuraContainer. The new
filtered 400589 slot uses that secure path on resolved Arcane Missiles
surfaces. Desktop checks pass 186 scripts / 848 Lua syntax files, including
69 focused glow checks. Forever native combat appearance, clearing, paging,
taint, pixels and frame time remain pending; other clients retain their
existing paths and need regression checks.
[Evidence](FOREVER_SAO_GLOW.md#secure-auracontainer-button-animation-candidate-latest).

6 November consumable follow-up: five matched loaded-module baseline/candidate
runs pass 46/66 checks for Well Fed, flask aura, weapon enchant, event route,
actual item action and secure item attribute. Refresh-timer and weapon-target
fixtures pass 35/30; full desktop runner passes 185 scripts and 847 Lua files.
The native client/window could not be verified from this
sandbox, so Retail, Forever, Era, Anniversary and progression latency, secure
input, taint and visuals remain pending. Settings and profiler preferences were
left untouched. [Evidence](CONSUMABLE_REFRESH_TIMER.md#aura-and-weapon-enchant-follow-up--6-november-2026).

6 November consumable aura advance: modern/legacy loaded-module pairs confirm
immediate next-item selection after Well Fed aura gain (22 candidate checks
each, five repeated pairs). Ordinary `UNIT_AURA` registration is retained as
the legacy fallback; combat changes queue until exit. Native Retail, Forever,
Era, Anniversary and progression acceptance remains pending.
[Evidence](CONSUMABLE_REFRESH_TIMER.md#immediate-advance-after-aura-gain--6-november-2026).

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
Native icon pools increase80→120 per full cell for native category ordering;
refresh remains bounded. Other clients and native taint/combat/performance
acceptance remain pending. No further runtime changes follow acceptance.
Shared documentation verification remains pending because an unrelated concurrent
ExtraButtonSystem/Layout.lua edit postdates the recorded shared test source.
The accepted aura hashes remain unchanged; its earlier frozen181/843 check is
retained. Do not overwrite the concurrent work or imply a current full-tree pass.

[Exact follow-up source/check record](validation/raid-blizzard-aura-followup-2026-11-06.json).

6 November Well Fed refresh candidate: a loaded-module fixture covers alternate
food aura discovery, learned spell ID reuse, and the 25 minute countdown at a
5 minute refresh threshold (35 checks). Weapon target regression passes 30.
Native Retail, Forever, Era, Anniversary and progression checks remain pending;
see [case record](CONSUMABLE_REFRESH_TIMER.md#well-fed-follow-up--6-november-2026).

Final border preference: the user requested the same textured bronze as
HealKit after rejecting the plain matte candidate. The final renderer uses
original Blizzard8036209 gold bands at0.85 brightness with normal blending,
excluding dark padding. Rounded caps appear only on exterior grid corners;
shared separators have one owner. Earlier matte validation is historical.
The latest full validation fingerprints cover this native-art implementation;
native visual/secure-input/taint/performance acceptance remains pending.

6 November party/raid rewrite: the HealKit-style candidate retains outer dimensions,
chat docking, reverse group columns and Flux Binding, with the user's later
connected HealKit-style bronze borders,4px vertical overlap, horizontal0 gap,3×2 buffs right /
debuffs left, visible timers/swipes,70% aura transparency and scoped0–100% control.
Names are10px; role12px precedes percentage; leadership/loot/marks have their
own layer. Power base is×0.8. Members follow native INDEX/ASC order. Native
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

6 November user decision: preserve every native feature and leave automatic Current blocked. User-supplied runtime inventory matches the eight documented meter functions and lists the enable/reset-on-new-instance CVars. The first inventory macro failed on missing help text; the corrected nil-safe macro completed. These metadata reads do not establish native combat safety or cleared taint. No runtime files changed. [Evidence](validation/meter-automatic-current-capability-2026-11-06.json).

6 November automatic Current requirement: manual session selection is not an accepted solution. The renewed pinned-source audit found no supported selection/default API on Forever 70790 or Retail 70783. The private setter remains rejected, and a replacement renderer has unresolved combat drilldown parity. No runtime files changed. Captures verified Forever; after the user confirmed background readiness, the Windows background guard still refused reload before any input. Reload cleanup, two-fight behavior and automatic defaults have no new native acceptance. [Capability evidence](validation/meter-automatic-current-capability-2026-11-06.json).

6 November actual Forever70790 native result: FAIL. Current selection became
pane/owner/saved1/1/1, with changed-field metadata true to false and _FluxUI
provenance; BugTabs2/2 plus delayed11:20 ordinary specIconID:535/durationSeconds:929
errors reject the experiment. Operative call removed; both test commands now
read-only UNSUPPORTED. Safe disk backend matches all five clients, but reload
cleanup and fresh loaded-source/ordinary combat/native secret checks remain
pending.126 no-operation/provenance and561 ownership/Core focused checks pass;
safe full166/823 passes unchanged sources ([manifest](validation/meter-rejected-current-removal-2026-11-06.json)).
Capture-only10:36:31Z confirmed the live native window/Meter; subsequent reload
was refused before input. No cleaned-memory/native acceptance is claimed.
Prior166/823 experimental source remains historical/rejected evidence. Automatic Current OPEN/unsupported; native UI session selector→Current
is distinct from Advanced AutoReset. No history/settings reset.
[Native failure](validation/meter-current-live-checks-2026-11-06.json), [scope](METER_STANDALONE.md#threat-timer-and-current-view-diagnosis).

6 November current native meter status: the explicit pasted DamageDone:Overall /
HealingDone:Overall overrides the earlier ambiguous Current reply. Automatic
Current for every existing/future meter is OPEN; two-fight/reload behavior remains
unverified. The optional guarded Forever70790 `/fbm currenttest` native output
is required/pending; desktop127-probe/561-ownership checks do not prove client
call permission or secret safety. Header172/threat87 and full166/823 pass stated
desktop scopes with unchanged sources. Native header/Minimize/timer geometry,
combat/taint/pixels/FPS and other clients remain pending. Passive captures did
not show the requested output or two fights. Preserve latest settings/history,
BugTabs, background-only rules and concurrent glow. [Scope](METER_STANDALONE.md#threat-timer-and-current-view-diagnosis),
[full manifest](validation/meter-current-selection-probe-2026-11-06.json).

6 November Forever proc candidate: user confirmed the prewarmed Classic LBG
frame still only glowed after combat. The revised Retail ProcGlow frame and
same-callback SAO/native button paint pass desktop checks only. A fresh
`/reload` and live Missile Barrage show/clear retest is pending. Era and
Anniversary native regression, atlas/pixel match, taint and frame time remain
pending; no desktop result is treated as in-client acceptance. See
[Forever SAO glow](FOREVER_SAO_GLOW.md).

Native readout from the direct-callback candidate: SAO screen hooks 0/0,
prepared Retail frames 158, show calls 0. The global-frame aura sampling and
alpha-only reveal candidate has not yet been tested in client.

Subsequent native retest also failed for the global-frame/alpha candidate:
combat readout had aura events 7, frame reads 334, Retail frames 158, shows 0.
The next requested read-only client check is SAO's active overlay IDs and
Flux's spell/button match during the visible proc.

That check returned `want5143=0` with no SAO overlay-list keys. The native
screen show/hide event candidate is installed on disk but has not yet received
an in-client acceptance test. If it fails, record `native` event counts and
ID from the readout during the proc.

Native-event retest and private-table AuraContainer hook both failed:
native show0/hide15, then AuraButton hooks0. The global Blizzard slot-registry
candidate is installed and requires a fresh in-client combat show/clear test.

6 November Forever combat button glow candidate: the user confirmed SAO's
Missile Barrage screen overlay appears in combat, while action bar button glow
does not. The user's first reload/retest still had no combat button glow,
with glow appearing after combat while the proc remained. SAO cached its
screen functions on a private table; the global-name hook missed those calls.
The corrected candidate hooks the table methods and subscribes standalone
Extra Buttons to glow changes on the existing eval lane. Flux accepts unknown
icon texture for a known spell ID. The
Classic Era SAO LibButtonGlow artwork and animation declarations match the
Forever paint route. The user retested the private-table candidate and still
saw glow only after combat, with stale glow after proc end. The newest
candidate adds global low-level SAO show/termination hooks and checks live
overlay/fade state. The user retested that signal candidate and still saw no
combat glow. Flux now prepares and retains each Classic LBG frame on its secure
button OOC, then plays existing animations without first-combat parenting.
Focused glow 53, low-level signal 5 and EBS refresh 8-check
desktop fixtures
pass; the full
[combat manifest](validation/forever-sao-combat-glow-2026-11-06.json) passes
164 scripts and 821 Lua syntax files. Elevated read-only host inspection found Forever PID
37088 and the exact WoW window; Codex sent no input or reload. The user's
first three live tests rejected the earlier candidates; the prepared-renderer disk code
still needs native combat verification. Pixels, taint,
frame time and Era/Anniversary regression remain pending.

6 November current Forever70790 evidence: host inspection confirms the same
PID37088/window remained live; sandbox-empty enumeration did not prove an exit.
At08:05:58UTC read-only native checks found Damage+Healing Overall0, Details false,
Meter active and BugTabs0. New-instance-reset1 does not select per-fight Current1.
Three initial native UI attempts were refused before dispatch; one final attempt
posted three targeted messages without activation/system input, but used stale
coordinates after a stock-layout change. Later loading capture did not confirm
Current or any setting change. The user later confirmed both native meters
now use Current. Setup is user-confirmed; agent enum/two-fight/reload checks
remain pending. The08:26 view showed centered Threat title/clipped timer;
revise the timer immediately after unchanged titles before final acceptance.
Earlier full162/819/unchanged sources is pre-heading stage evidence.
Native combat/secret/taint/pixels/FPS and other clients remain pending.
[Current scope](METER_STANDALONE.md#threat-timer-and-current-view-diagnosis), [native evidence](validation/meter-current-live-checks-2026-11-06.json).

6 November Forever SAO follow-up: user testing confirmed no button glow after
the earlier renderer correction. Installed SAO 2.8.9 Forever Missile Barrage
defines aura 400589's screen overlay but omits an Arcane Missiles button; Flux
now reads that aura for the base spell and its ranks, while generic SAO and
native glow paths cover other supported spells/procs. Secret native values and
event IDs are guarded. Focused 41 checks and the follow-up 162-script/819-file
desktop suite pass; native proc/visual/taint/frame-time and Era/Anniversary
regression checks are pending. [Source and scope](FOREVER_SAO_GLOW.md).

6 November current Forever 70790 candidate is not natively accepted. Reported
specIconID/durationSeconds failures under Flux taint require removal of direct
native Lua configuration writers, not just a texture correction. The candidate
removes those writers; native controls
must select missing pane types/row options and Current/Overall/history; their
state is not silently overwritten or reset. One native timer is implemented by
physical screen geometry without reading durations. Writer 26/timer 113 focused
checks pass (five pairs each, 5/9 mutants); final full validation passes
162 scripts /819 Lua syntax files with all source hashes/membership unchanged.
[Current manifest](validation/meter-timer-native-boundary-2026-11-06.json).
These models do not certify the native secure VM.
The 07:31 UTC sandbox-empty process result did not prove an exit; the same
Forever process/window was later verified live. Older captures/passes are
stage-specific. Other-client native behavior remains unverified.
[Current capability limits](METER_STANDALONE.md#current-native-configuration-boundary).

6 November Forever SAO glow candidate: installed SpellActivationOverlay 2.8.9,
interface 16001, saved glow enabled. Source route and focused 25-check fixture
pass for bar, Extra Button and badge faces; pre-edit source fails. Native
proc/paging/clear/pixel/taint and frame-time acceptance is pending on Forever.
Era and Anniversary routes are unchanged in source, with native regression
checks pending. Its earlier SAO-stage run passed 160/162 scripts; the current
combined validation passes all 162 scripts /819 syntax files after meter fixes.
[Evidence](FOREVER_SAO_GLOW.md).

6 November raid input: the user supplied a native secret-boolean failure at
`Hide.lua:139` during `FluxRaidLayout` native-grid hiding. Desktop mouse and
startup fixtures pass across five modeled client branches; this does not prove
native secret handling or protected setter legality. Normal reload plus party,
raid, Edit Mode, combat roster, input hit testing and enable/disable restoration
are pending on Forever and Retail; the other installed clients remain pending.
Preserve existing BugTabs roots and scriptProfile preference. [Raid record](49-native-mouse-suppression.md#raid-secret-mouse-follow-up).

6 November current Forever installation includes Details #Details.20261104.15400.172
(interface 16001); presence is separate from addon load state. The exact atlas/
fill/font mapping is read-only evidence, not proof of file loading in the game.
The new native backend references these installed files without loading Details
or SharedMedia; absent assets use the existing fallback per client. Final
candidate native inspection is pending. Fresh-process preflight captured only
the previous flat presentation; it cannot accept this candidate.
[Current scope](METER_STANDALONE.md#installed-wow-interface-art-references).
Other-client native, combat/taint and whole-UI pixel claims remain unverified.

5 November shared theme: source fixes one-line text and panel/header consistency
without reading native text or replacing rendering. Skin 54/threat 69 checks,
five style pairs/eight mutants and native-owner 463 checks/five pairs/five mutants
pass. Final desktop validation passes 159 scripts / 816 Lua syntax files; all 816
source hashes and membership are unchanged across the run. [Final manifest](validation/meter-theme-consistency-2026-11-05.json).
Forever 70790/interface16001 post-style reload 22:06:45Z retains Meter/builtin 7,
Details absent, scriptProfile 0/current BugTabs 0. Friz 15 title, ArialN 17.5 row and
name/value CanWordWrap=false are observed; shared header/panel fill inspected.
Final OOC native tab handoff passes; actual owned-threat combat rows were not captured, so combat secret/taint and performance remain inconclusive. Other clients retain prior route/validation limits.
[Exact stage scope](METER_STANDALONE.md#one-line-names-and-shared-meter-appearance).

Final Forever OOC handoff passes: Map/Respec/Buttons both views hidden, returning
Meter both visible; currentBugTabs0, Details absent, builtin7/profile0 retained.
[Exact background captures](validation/native-meter-background-checks-2026-11-05.json). Native name/value wrap flags are false and
shared header/panel fills inspected. No actual owned-threat combat row was
captured; do not certify that case, combat secrets/taint, native FPS or other clients.

Earlier font/tab-stage evidence (its native pending notes are superseded by final OOC handoff above):

5 November threat readiness: strict font-before-text replay reproduces the
native first-title error; candidate 65 checks, five original pairs, five
font-ready lifecycle pairs and nine mutants pass. Native Forever 1.60.1/70790/
interface16001, Details absent and scriptProfile 0 are current observations.
Map reload/session FXERR0 and layout 8 construction are partial checks only;
native combat, opaque values, taint, screenshots and frame times remain pending.
Full desktop validation passes 159 scripts / 816 Lua syntax files; all 816
source hashes and membership are unchanged across the run.
[Full source manifest](validation/meter-threat-readiness-2026-11-05.json). Native acceptance for that earlier font/tab source was pending; final OOC handoff is recorded in the shared-theme stage above.
[Exact scope and native follow-up](METER_STANDALONE.md#font-readiness-and-quiet-threat-follow-up).
Other clients retain prior routes; no new native certification follows.
The native font-candidate title/body is ready with ARIALN 15 OUTLINE, but normal
Map/Respec/Buttons switches exposed an owned-threat overlay while native panes
were hidden. The owner fix passes 429 checks/five pairs/four mutants versus 19
baseline failures. That stage preceded final OOC handoff, which now passes;
actual owned-threat combat and secret/taint acceptance stay inconclusive.

5 November standalone meter: Forever 1.60.1.70790 gains a Flux/Blizzard-asset
native skin and an independent optional threat pane when Details is absent.
Retail 12.1.5.70783 uses the native skin/enable path; standalone threat remains
Forever-only. Era, Anniversary and progression retain Details/capability absence;
generated API presence does not make their pinned native meter TOCs load.
[Full requirements and native checklist](METER_STANDALONE.md).

Skin 47 checks/five pairs/six mutants and threat 51 plus sample 510 checks/five
pairs/11 mutants pass. Opaque values are display payloads without false ranks;
80 player/pet facts, scrolling and hidden/Details cleanup are covered by mocks.
Final desktop validation passes 159 scripts / 816 Lua syntax files; all 816
normalized source hashes and file membership match before/after the run.
[Final source manifest](validation/meter-standalone-2026-11-05.json).

The user-reported checkbox diagnosis supports automatic out-of-combat enable of
the public damageMeterEnabled option; native visibility/cache and UI loading
remain native. Current candidate operation is not observed in game. Reload and
verify exact client/build/settings, disabled-startup and combat-deferred enable,
all old/new/custom layouts, source windows, timers, scrolling, group/pet churn,
native secret/taint, Edit Mode/gamepad and Details takeover. Match screenshots
against the approved reference. No native input, profiling or pixel comparison
ran; original Wrath and unavailable clients remain separate. A background-only
21:56:22 CET capture showed the same Forever process with Map active, not native
Meter docking. No loaded-code/build query or reload ran; this is partial visual
context only, not native meter/docking/combat acceptance. Separately, the user's
22:04 CET screenshot establishes floating native Damage/Healing on Map after
reload before first Meter selection. Startup ownership and late-anchor repair
need candidate native checks; that screenshot is not loaded-source proof.

5 November wand school swing candidate: Era 1.15.9.70576, Anniversary
2.5.6.70577 and Forever 1.60.1.70790 use pinned Gethe source and a shared
cast-school renderer on equipped wands. The focused production-module fixture
passes 13,942 checks; full desktop validation passes. No native reload,
gameplay, pixel comparison, taint check or frame-time capture was run.
Test Fire/Frost and unknown-school wands, weapon swaps, Shoot timing, option
toggle, cast interruption/slot ownership and localization sequentially in the
background. [Exact scope and source links](SWING_WAND_CAST_THEME.md).

5 November damage meter combat follow-up: the user-supplied duration warning
matches Forever1.60.1.70790 line929; Retail12.1.5.70783 has the same native
comparison at line930. Flux no longer writes the native Edit Mode visibility
field. It honors the native policy while retaining the host/tab visibility
boundary; timer and entry methods remain native.
[Pinned source contracts, policy and native checklist](METER_COMBAT_VISIBILITY.md).

Focused native-function replay passes 332 checks versus 80 baseline failures / 332.
Five alternating pairs per pinned Retail/Forever source (ten total) and six
rejected mutants pass; native event/timer/text-update counts remain unchanged.
Full desktop validation passes 153 scripts / 808 Lua syntax files; all 808 source
hashes and file membership match before/after the run.
[Full report](validation/meter-combat-visibility-2026-11-05.json).
No current native input, reload, profiler or settings changes occurred. Reload
before candidate acceptance and record exact build, loaded revision, addon list,
profile, hardware, resolution and scale. Test combat timer/rows and every native
visibility policy, group/content gates, host/tab changes, pane controls, source
windows, Edit Mode and Details takeover. Native taint, pixels and frame times
remain pending; other native setters are separate unverified provenance paths.
Pinned progression 5.5.4.70631, Era 1.15.9.70576 and Anniversary 2.5.6.70577 meter
TOCs select standard rather than their game types. Keep Details/capability
fallback, not a promise of native meter availability. Original Wrath remains
distinct and is not newly certified.

5 November minimap/mail follow-up: Forever's pinned native XML places mail at
`MinimapCluster.IndicatorFrame.MailFrame`, whereas the existing Flux lookup
checked older native locations and omitted its own named fallback. The corrected
lookup reuses that fallback with the same 20×15 appearance and cadence. Actual
production-function replay reproduces frame/listener growth without an inventory
provider. This is source/desktop evidence, not a native rendering or FPS result.
[Exact lifecycle scope and steps](MINIMAP_MAIL_LIFECYCLE.md).
Focused 504 checks pass versus 100 baseline failures / 494 attempts; five alternating
pairs and five rejected mutants pass.

A reload is required to retire previously retained frames. No new foreground
control, game input or profiling occurred. All new native client/provider/bag
transaction, minimap flicker, geometry, protection and performance checks remain
pending. The approved 19:15 Forever reload predates this fix. Retail tooltip
readiness separately passes 48 checks, five matched pairs and four mutants;
its Forever loader selection remains unverified. Original Wrath stays distinct
and unsupported by these native claims. Combined validation passes
153 scripts / 808 Lua syntax files with an unchanged
808-file source drift guard.
[Full report](validation/minimap-mail-lifecycle-2026-11-05.json),
[Retail tooltip scope](AUCTION_COLD_TOOLTIP.md).
Read-only host/file checks around 19:45 UTC verified the same Forever PID39984
and both runtime candidates byte-identical in all five synced client folders.
Loaded-code identity was not checked; on-disk parity is not native acceptance.

5 November provider snapshot row reuse, baseline `7f47a566`: the real Adapter/
Scheduler fixture passes all 700 checks; its exact baseline fails 190 of 700.
Five alternating pairs and five rejected mutants cover mail and owned-auction
rows, sparse/count/link semantics, immutable prior generations, cadence, direct
synchronous rebuilds, provider readiness and legacy/modern event routing. Full
151 scripts / 806 Lua syntax files pass. The complete 806-file source membership
and normalized hashes remain identical before/after validation, including the
newer consumable changes through `e2c6464`.
[Row-reuse scope and native checklist](PROVIDER_SNAPSHOT_ROW_REUSE.md),
[matched evidence](validation/provider-snapshot-row-reuse-comparison-2026-11-05.json).

Only private FillFromList changes: it prepares completed maps and reuses immutable
rows at the same index when ID/count/link match. The unchanged early guard,
synchronous Rebuild APIs, notifications and configured cadence remain. Full
prefix validation still visits O(N) facts. Temporary index maps are a storage
tradeoff, not proof of lower native CPU, memory bytes, FPS or freeze removal.
All five client/provider/bag transaction, pixel, protection and leak checks remain
pending for this new Adapter. The approved 19:15 Forever reload/source check with
Syndicator/profile0 and empty caches predates this code and cannot accept it.
The user-provided BugTabs1.4.9 report at 19:18:25 confirms the one-off diagnostic
BugGrabber/nil probe failure, not a native FluxUI runtime regression. No new game
input or settings/profiler change was used. The external provider is unchanged;
its separate private patch is not installed and requires separate authorization
after validation. Original/modern Wrath remain distinct and unverified.

5 November Consumables refresh timer: shared button/wisp/config countdown
uses public buff expiration minus refresh threshold. Five paired loaded-module
fixtures pass baseline and candidate (14/25 checks); full 150-script/805-Lua
desktop validation passes. Retail, Forever, Era, Anniversary, and progression
native confirmation remains pending, including visual and combat checks.
[Timer evidence](CONSUMABLE_REFRESH_TIMER.md).

5 November user native trace: open-bank charge detection in the Consumables
config called an absent restock-bank method and stopped grid construction.
The shared adapter call now uses `ForEachOpenStack` with character/warband
options. Five paired loaded-module baseline/candidate runs and full
149-script/804-Lua desktop validation pass. Retail, Forever, Era,
Anniversary, and progression in-game confirmation is pending; the supplied
stack establishes the baseline failure, not candidate acceptance. See
[charge scan evidence](RESTOCK_CHARGE_BANK_ITERATOR.md).

5 November consumable config visibility: shared editor path saves a valid
dropped item ID before its name loads and renders saved entries before the live
button update. Five baseline/candidate desktop pairs (eight checks each) and
full 148-script/803-Lua validation pass. Retail and Forever native verification
is pending, as are Era, Anniversary and progression client checks. Inspect
reload persistence, zero-effective-count weapon enchant visibility, tooltips,
secure click, and actual layout. See [case record](CONSUMABLE_TARGET_DETECTION.md).

5 November built-in snapshot preparation, baseline published `437fda7`: auction
and mail production fixtures pass 5,884 and 8,194 checks. Five alternating pairs
per fixture, eight rejected mutants and final full 147 scripts / 802 Lua syntax
files pass. The auction baseline fails 144 of 5,436 dynamic checks; the final mail
baseline fails 25 of 8,203. Client/provider labels are shared contracts with mocked
native APIs, not native client or provider certification. See
[auction preparation](BUILTIN_AUCTION_PUBLICATION.md),
[inbox preparation](BUILTIN_MAIL_PUBLICATION.md),
[raw comparison and source hashes](validation/builtin-publication-comparison-2026-11-05.json)
and [complete flow scope](MAIL_AUCTION_REWORK.md).

Both sources stage normalized index/count maps inside existing scan budgets and
publish only completed changed generations. Region objects, public Index APIs,
original equality and cadence remain. The intentional internal byIndex map
identity change follows the consumer search; current callers neither retain
those inner maps nor expose mail/auction regions through GetSnapshot. Staging
adds temporary maps; reduced preparation bursts do not establish lower total
native CPU, memory bytes or FPS improvement.

Partial native startup/source check: the user approved brief read-only access to
Forever PID 39984, the verified Forever executable, with MarioSuper in world.
At 19:14 CET, GetBuildInfo returned 1.60.1/build70790/interface16001 (build date
Nov3), and FluxUI, Syndicator and Baganator all reported loaded. At 19:15:37,
the source was Syndicator, itemDataRevision was 20261105.1 and scriptProfile was 0.
Byte parity of both changed source files plus Init was verified before the
19:15:51 reload. At 19:17:31, source/revision/profile0 were confirmed again;
at 19:18, cache mail and auction counts were both zero. This is partial startup
and source evidence, not acceptance of the changed built-in scan paths: the
active source was Syndicator. The older 17:37 unloaded setup is separate history.

No Buy, cancel, loot, enabling/disabling or profiling was performed. Previous
windows were restored and no further foreground work is planned. The user
identifies BugTabs1.4.9; BugGrabberDB was nil. One GetSessionId diagnostic failed because of an incorrect probe assumption;
that failure is not a native FluxUI regression.
Error history and logger settings were not cleared or changed; private raw
captures remain outside Git. All native transactions, freeze removal, taint,
pixels and long-session retention remain pending across clients/providers/bags,
including Buy-to-mail and final Open All. The [external Syndicator cold-post
finding](EXTERNAL_SYNDICATOR_POSTING.md) remains read-only and unfixed. Original
and modern Wrath remain distinct and unverified. No native freeze cure is claimed.

5 November mail/auction lifecycle candidate, baseline `e860ce6` already published:
real auction modules pass 628 checks and real Settings/Select/OpenAll modules
pass 880 checks. Five alternating pairs per fixture, eight rejected mutants and
full 145 scripts / 800 Lua syntax files pass. The two fixes prevent duplicate or
foreign-provider owned-list queries, permit final-mail cancellation and stop a
job when its owning module is disabled. Client labels, timer variants and provider
states exercise shared contracts, not native client emulation.
[Query ownership](AUCTION_QUERY_OWNERSHIP.md),
[mail job lifecycle](MAIL_JOB_LIFECYCLE.md) and
[full flow/ownership matrix](MAIL_AUCTION_REWORK.md).

Background host inspection found only Forever PID 25172, started at 17:55 CET.
The 17:37 unloaded observation below belongs to an earlier process; it does not
establish the current loaded state. No current candidate identity, transactions
or freeze removal have been verified. No game input, profiling or settings
mutation occurred in this phase. All five clients still need native mail/auction
and provider/bag acceptance with and without supported Syndicator/Baganator
configurations, including the last two messages, owner disable/profile changes,
reopen, post/buy/cancel and naturally observed sales. Original and modern Wrath
remain separate and unverified. Desktop query/action counts cannot certify
native CPU, allocations, latency, taint, rendering or FPS.

5 November built-in inventory/currency candidate, baseline `b664bb0`: production
module fixtures pass 790 metadata-ownership, 81 summary-pruning and 512 currency
iteration checks. Five alternating pairs per scenario and twelve rejected mutants
are recorded; final full validation passes 143 scripts / 798 Lua syntax files.
The metadata labels cover shared client/provider contracts, not native emulation.
Modern currency structures are source-verified for Forever/Retail; the three
legacy branches retain their existing code. Original/modern Wrath remain distinct
and unverified. See [item data](BUILTIN_ITEM_DATA.md),
[summary retention](INVENTORY_SUMMARY_PRUNING.md) and
[currency iteration](GOLD_CURRENCY_ITERATION.md).

Earlier inventory-phase native observations: the user
reports re-enabling FluxUI and whole-game freezes during many buyer sales with a
delayed spike, auction cancellation followed by mailbox entry, Open All from two
messages to one, and individual attachment mail. Read-only checks at 17:35 CET
returned a legacy/nil source marker; direct checks at 17:37 showed both addon
loaded flags false and Flux/FluxUI globals nil. The only observed game was Forever
PID 47424, reporting 1.60.1 / 70790 / interface16001, scriptProfile0 and Syndicator
unloaded. The exact candidate tree is therefore not verified as loaded, despite
the user's re-enable report. Previous window restored; no enabling or CPU capture
was performed. All new native feature, transaction, protection, pixel, retention
and performance acceptance remains pending. The next permitted check must verify
`Flux.Inventory.itemDataRevision == "20261105.1"` before interpreting results.
Historical startup observations and earlier phase results below do not certify
this candidate.

Latest phase: the native mail-command guard prevents progression/completion
while C_Mail reports pending, with bounded8s wait and existing cadence retained.
Five matched desktop pairs reproduce360 to0 unsafe requests and40 to0 premature
completions; three mutants rejected. Final full validation:140 scripts /795 Lua
syntax files pass. Earlier139/794 evidence describes the preceding four-fix tree.
The user still reports live sale/mail freezes, including Open All at Processing
Message2 and final mail; no live cure is claimed.
[Guard, source contract and pending native checks](MAIL_NATIVE_COMMAND.md).

Latest native outcome: the user confirmed the same freeze after reload with
Syndicator unloaded. A later optional60s CPU capture was lost before save when
the old process exited during reported bulk mail. No new crash report identifies
a cause. Profile0 and the prior nil capture root were restored/verified15:51:34;
foreground returned. This is failed/inconclusive operational evidence, not a
benchmark pass. See [capture details and cleanup](RAID_MAIL_AUCTION_FOLLOWUP.md).

5 November raid/mail/auction follow-up: baseline `8681672`; shared loaded-module
contracts pass 290 raid, 3,140 mail-worker, 380 mail-detail and 365 auction checks;
full 139 scripts / 794 Lua syntax pass. Five alternating pairs per scenario and
eight rejected mutants cover incomplete raid pools, duplicate/stale mail wakes,
hidden/disabled detail work and progressive Syndicator auction lists. Client and
provider labels are shared-contract models, not native-client emulation.

Sandbox process enumeration initially hid the game; host inspection confirmed
Forever 1.60.1.70790 and a background 1906 by 1032 auction/bag capture without
changing focus. Approved reload completed15:32:54CET. Native commands confirmed
1.60.1/build70790/interface16001, FluxUI loaded and Syndicator unloaded; at15:35:48
raid setup ready, scriptProfile0 and no current-session error messages printed.
Prior windows were restored after successful checks. This is partial startup
sanity only; the full addon list remains uncaptured. All-client mailbox loot,
secure raid/pet-battle behavior, native errors, pixels and matched performance
remain pending. The stored UNKNOWN event predates the previous correction; the
new reporter warnings still do not identify an initiating addon. Original and
modern Wrath remain separate and uncertified.
The user subsequently reports Syndicator is not loaded in the current failing
session, while AH/mail lag and reporter warnings at 15:03:09 and 15:27:44 remain.
This differs from the installed-provider source fixture; it does not establish an
active Syndicator route. The runtime enabled-addon list is still uncaptured.
[Exact source pins, observations and remaining steps](RAID_MAIL_AUCTION_FOLLOWUP.md).

5 November meter/header ownership: compared Forever 1.60.1.70790 and Retail
12.1.5.70783 native meter paths; checked visible-header allocation gate on pinned
Era 1.15.9.70576, Anniversary 2.5.6.70577 and MoP 5.5.4.70631 sources too. Shared
capability/absence mocks pass 180 meter + 150 raid checks; full 136/791 pass.
No secret VM, native rendering or secure CreateFrame acceptance is simulated.
Native reload/taint/pixels and UNKNOWN header attribution remain pending;
original/modern Wrath remain distinct and uncertified.
[Exact commits and native checklist](METER_RAID_NATIVE_OWNERSHIP.md).

5 November consumable target detection: a generic 30-check loaded-module
desktop fixture verifies staff-only mismatch/count zero, staff/off-hand
selection, general oil, categories, cached metadata and equipment/combat
refresh. Five baseline/candidate pairs reproduce the old dagger target.
All native clients still need real item/tooltips, protected clicks, combat,
locale, pixels, taint and matched performance checks.
[Exact scope](CONSUMABLE_TARGET_DETECTION.md).

5 November hidden inventory: freshly read executables Era 1.15.9.70576,
Anniversary 2.5.6.70577, MoP 5.5.4.70631, Retail 12.1.5.70783, Forever
1.60.1.70790. Installed Baganator 840/Syndicator 289 references checked read-only.
Shared-contract desktop checks: 260 integration + 65 native-bag pass; full 133/788
pass. Labels do not emulate native clients/providers. Native timings, secure
behavior, pixels and mailbox/AH lag improvement remain pending in every provider
configuration; original/modern Wrath remain distinct and uncertified.
[Reproduction and per-client checklist](HIDDEN_INVENTORY_WORK.md).

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

5 November auction metadata: global cache events no longer harvest all bag/bank
names or populate classification records for unrelated auction items. Requested
metadata, failed-load retry, static consumers, explicit completions and immediate
name-only reagent/restock updates are preserved. Five matched desktop pairs:
280,000 name reads and 2,000 container walks become zero for the unrelated burst;
230 checks pass, three mutants rejected; full 127 scripts/782 syntax pass.
The native Buy spike still needs attribution/acceptance across both providers.
[Evidence and next captures](AUCTION_METADATA_WORK.md).

5 November auction Buy investigation: active-row highlighting uses the native
view instead of the retained child pool. Five matched desktop pairs:200,600
versus600 traversal visits;200 classifications unchanged;116 checks pass and
two mutants rejected. Full126/781 passes. Native Buy spike and every client/provider
integration remain pending. [Evidence and steps](AUCTION_PURCHASE_REFRESH.md).

5 November utility pet faces: the user clarified a question-mark/wrong-icon
symptom. The manager now owns the selected journal-pet icon and tooltip via
existing override surfaces, with modifier changes, metadata completion and
cleanup. Summon macros/GUID storage remain intact. 920 checks pass (old40
failures), three mutants rejected; full125/780 passes. Native checks pending.
[Evidence and native steps](UTILITY_PET_FACES.md).

5 November live-zero follow-up: exhausted food/water/potion/bandage buttons
now reset from reliable live bags before Syndicator's delayed cache callback.
The painter retains the verified count; loading holds and combat deferral
remain. Button-level375 checks pass (baseline200 failures), three mutations
rejected; full124 scripts/779 Lua syntax pass. Native acceptance pending.
[Evidence and native steps](SYNDICATOR_CONSUMABLE_UPDATES.md).

5 November Syndicator consumables: batched bag callbacks now retain every
added/removed item and dirty bag until publication. This fixes a reproduced
missed selector update for better items and last-use depletion across food,
water, potions and bandages. Five desktop pairs: baseline 200 failures versus
candidate 0 per400 checks; three mutations rejected. Full suite123/778 passes.
Native gameplay, pixels, taint and performance remain pending.
[Evidence and exact native checks](SYNDICATOR_CONSUMABLE_UPDATES.md).

4 November built-in mail: all five local Blizzard mirrors declare `MAIL_SHOW`,
`MAIL_CLOSED`, `MAIL_SEND_SUCCESS` and native Open All; Retail/Forever use
`Blizzard_MailFrame`, Era/Anniversary/MoP use the Classic MailFrame path.
Retail/Forever inbox redraw differs (`InboxFrame:Update()` on Forever), so
Flux selected checkboxes hook the available method or global function. The
local mirrors are older than some installed builds; bundled live/forever/
classic commit pins are inventory evidence only. Focused desktop checks 67;
full suite 118 scripts/768 syntax files, zero failures. Native per-client
mailbox open/close, actual item/money operations, visual placement, combat
taint and timing remain pending. [Evidence](MAIL_INTEGRATION.md).

4 November Era/Anniversary combined bank: inspected versioned Gethe Vanilla
and TBC bank source mirrors and their loaded TOC paths; installed clients are
newer and upstream mirror commits are unavailable. Loaded-module desktop
models pass 33 checks each for native button/container IDs, six/seven bank
bag slots, compact purchase controls, no-toggle slot clicks, drag/drop,
restock attachment, late Baganator
handoff and close/restore. The full suite result is in
[evidence](CLASSIC_COMBINED_BANK.md). Native screenshots, item operations,
purchase confirmation, taint, FPS and frame time are pending.

1 November passive trinket correction: the user's intended rule is dim for an
equipped trinket with no on-use spell and bright for a ready on-use trinket.
Baseline fails the new passive check; candidate passes 10 focused checks and
112 isolated desktop tests/757 Lua syntax files. Native five-client use
effect, cooldown, click, pixel and taint acceptance remains pending.
[Evidence](TRINKET_EQUIPPED_USABILITY.md).

31 October equipped trinket tint: the user's native observation is that an
equipped, ready trinket with a use effect stays dark while alive. The
baseline loaded-paint test reproduces this, the candidate passes 8 focused
checks, and combat gem/stone controls pass 14 checks. Isolated published-source
desktop validation passes 112 tests/757 Lua syntax files. Five-client native
ready/cooldown/dead/revive tint, clicks, keybinds, pixels and taint remain
pending. [Evidence](TRINKET_EQUIPPED_USABILITY.md).

31 October chat durability teleport follow-up: focused desktop events model
empty durability at world entry, first/late return, player-only inventory
refresh, expiry and repeated teleports. Full 112-test/757-Lua suite passes.
Native loading-screen recovery, clicks, pixels, combat taint and frame time
remain pending on all five supported clients.
[Evidence](CHAT_CHARACTER_DURABILITY.md).

31 October secret-channel fallback: Retail/Forever unit API declarations
confirm cast identity can be secret; castBarID supplies no magic school.
Explicit channel-ID selection keeps the native/default bar when identity
cannot be read. Baseline rejects the 56-check nameplate fixture; the shared
renderer passes 13,898 checks. Native combat, pixels, taint and frame time
remain pending. [Evidence](SECRET_CHANNEL_FALLBACK.md).

31 October chat character durability: the loaded painter distinguishes
readable full durability from absent/restricted values. The focused desktop
fixture covers `100%`, `75%`, `0%`, secret and empty readings; full
112-test/757-Lua validation passes. Native character-button text, equipment
changes, pixels, clicks, combat/taint and frame time remain pending on every
supported client. [Evidence](CHAT_CHARACTER_DURABILITY.md).

31 October nameplate backdrop: desktop renderer checks place single/hybrid
artwork below native chrome, including plate-level changes during a cast;
the prior source fails the new layer assertion. Full 112-test/757-Lua suite
passes. Native four-client pixels, combat taint and frame time remain pending.
[Evidence](NAMEPLATE_BACKDROP_LAYER.md).

31 October combat grid conjured-item tint: the user's native observation is
that mana gem and healthstone stay bright while other combat items darken on
death. The corrected loaded-paint desktop fixture passes 14 checks, baseline
fails at dead gem, and the full 111-test/756-Lua suite passes. Actual Retail,
Forever, Era, Anniversary and MoP Classic death/revival, full-resource,
cooldown, count, input, pixel and taint checks remain pending.
[Evidence](COMBAT_GRID_CONJURED_USABILITY.md).

31 October cast fill/tip follow-up: the user reported missing color and
unit-frame fill on all clients. The desktop regression fails against the
published source and passes with progress-bar parenting, native source
hide/restore and school Spark tint. Full 110-test/755-Lua suite passes.
Native all-client pixels, combat taint and frame time remain pending.
[Evidence](CAST_SCHOOL_FILL_TIP_FIX.md).

31 October nameplate cast-school styling: desktop 48-check native-bar lifecycle
model plus shared renderer checks pass on Retail, Forever, Era and Anniversary
branches; full 110-test/755-Lua validation passes. Native client cast/channel,
secret fallback, interrupt/fade, native text/shield visibility, `SetUnit` taint,
pixel parity and matched performance checks remain pending.
[Evidence](NAMEPLATE_CASTBAR_SCHOOLS.md).

30 October MicroMenu nil-center correction: the user's native Classic-path
stack identifies a pre-fix `GetEdgeButton` failure during Flux's LFG rebuild.
The focused desktop model reproduces old callback ordering and passes with
selected/unused children moved before Show/Hide; full suite passes 109 tests /
753 Lua syntax files. The read-only Era reference confirms synchronous
`MicroButton_OnShow` layout, but the stack does not name the user's build.
Native post-fix reload, Edit Mode, placement, combat, pixels, taint and frame
time remain pending on Era, Anniversary, MoP Classic, Retail Midnight and
Forever. [Evidence](17-micromenu.md).

30 October delayed loot correction: desktop fixture checks two closed
mob/chest sources with reversed late item messages, a ten-second duplicate,
fast-loot capture race, late currency/money, and session expiry. Full suite
passes 108 scripts / 752 Lua syntax files. Native event order, source
attribution, UI scale, pixels, taint and frame time remain pending on Era,
Anniversary, MoP Classic, Retail Midnight and Forever.
[Evidence](LOOT_CURSOR.md).

30 October cursor-position correction: desktop fixture verifies the cursor
snapshot at LOOT_READY/LOOT_OPENED, delayed item/currency rows, and two
overlapping batches with separate retained positions. Full suite passes
108 scripts / 752 Lua syntax files. Native click-to-event timing, UI scale,
pixels, taint and frame time remain pending on Era, Anniversary, MoP Classic,
Retail Midnight and Forever. [Evidence](LOOT_CURSOR.md).


30 October loot-source correction: desktop fixture excludes crafted,
pushed/rewarded and outside-window self-loot chat while retaining slot,
bonus and won-roll loot; currency follows the loot-window gate. Full suite
passes 108 scripts / 752 Lua syntax files. Native event order, source
classification, taint, pixels and frame time remain pending on Era,
Anniversary, MoP Classic, Retail Midnight and Forever.
[Evidence](LOOT_CURSOR.md).


30 October 2026: attached stance bars now follow player-frame scale, including
immediate slider changes and reload; detached placement restores normal size.
Existing combat deferral is retained. 21 stance and 28 bridge checks pass;
full suite: 108 scripts /752 Lua syntax files, zero failures. Native pixels,
input and taint remain pending (no visible WoW process).
[Evidence and native steps](UNIT_FRAME_SCALE.md).

30 October FluxLoot callback correction: the user's native stack identifies
the pre-fix CallbackHandler argument shift at line 402. A signature-aware
desktop fixture reproduces the error against the old call and passes with
the corrected receiver/event/method order; full suite passes 107 scripts /
751 Lua syntax files. Native post-fix login and profile change/copy/reset
remain pending on all five supported clients. [Evidence](LOOT_CURSOR.md).


30 October cursor money follow-up: desktop checks pass for localized positive
money parsing, gold/silver/copper symbols, white numbers and exact 1 silver/
1 gold leading-icon thresholds. Full suite passes 107 scripts / 751 syntax
files. Native money text, icons, pixels, taint and frame time remain pending
on Era, Anniversary, MoP Classic, Retail Midnight and Forever.
[Evidence](LOOT_CURSOR.md).


30 October cursor loot default follow-up: the shared default table now starts
fast pickup and cursor alerts on, with 3-second expiry, on all five supported
clients. The desktop fixture exercises the actual default and option control.
Native new-profile, existing-profile and FasterLoot coexistence checks remain
pending. [Evidence](LOOT_CURSOR.md).


30 October cursor loot: the new profile-scoped fast pickup and cursor alerts
have a focused desktop event fixture and a passing 107-script/751-Lua full
suite. Native loot behavior, locale parsing, cursor pixels, FasterLoot
coexistence, combat/taint and frame time are pending for Era, Anniversary,
MoP Classic, Retail Midnight and Forever. No client or profiler was changed.
[Evidence](LOOT_CURSOR.md).


30 October historical Sticky Targeting follow-up: the linked GitHub main
source matches the pre-fix local routine. The older 13 August snapshot uses
the registered negated setting on Retail; the current targeted route passes
76 desktop checks. Native Retail/Forever checkbox value, reload persistence,
taint and frame time remain pending; no WoW process was visible.
[Evidence](RETAIL_CONTROLS_CAMERA_FIX.md).

30 October Retail Controls/camera report: the user's native pre-fix readback
was camera factor `1.900000`, engine maximum `nil`, Sticky Targeting CVar
`deselectOnClick=0`, with first-load verification failing on the camera.
The revised 68-check desktop fixture passes; post-fix Retail acceptance is
pending. No WoW process/window was visible for a background check. Era and
other clients remain native pending. [Evidence](RETAIL_CONTROLS_CAMERA_FIX.md).

30 October first-load settings follow-up: the five-client source-driven
desktop suite passes 60 first-load checks and 507 binding checks; full
validation passes 106 scripts/748 Lua. Native Controls, nameplates, raid
appearance, single completion message, reload preservation, Settings reset,
taint and frame time remain pending for all clients. No WoW process was
visible; no client was controlled. [Evidence](NONBINDING_FIRST_LOAD.md).

30 October Hearthstone selector native report: the Toy Box choice selector's
hover handler threw at line 491 because the client's `GetItemInfo` global was
nil. The new source-driven fixture reproduces that failure and passes 19
checks after using the shared item service and Toy Box name fallback. Full
desktop validation passes 106 scripts/748 Lua files. The user's report
establishes the hover error, not successful toy selection or native post-fix
acceptance. Hover, choice, secure use, reload persistence, combat/taint and
pixels remain pending. [Evidence](HEARTH_CONFIG_TOY_COLLECTION.md).

30 October Hearthstone panel follow-up: the user reports the panel remained
absent beside Toy Box. The previous fixture supplied `FLUX_API` before its
actual TOC position and could not prove registration. A corrected 17-check
source-driven fixture verifies the editor registers using earlier `Flux.Cap`
while `FLUX_API` is absent; full desktop validation passes 106 scripts/748
Lua syntax files. Native panel visibility, toy selection/use, reload scope,
combat/taint and pixels remain pending on each Toy Box client.
[Evidence](HEARTH_CONFIG_TOY_COLLECTION.md).

30 October Hearthstone Toy Box config: a source-driven desktop fixture passes
14 checks for a toy-capable client without `ToggleCollectionsJournal`, modern
Collections loading, editor visibility, owned-toy selection/readback and a
second native opener. Full validation passes 106 scripts/748 Lua syntax files.
Every Toy Box client still needs native Toy Box opening, tab switching, toy
choice, actual Hearthstone button use, reload/scope persistence and combat/
taint checks. Basic fallback on non-toy clients remains to be checked natively.
No WoW process was visible or controlled. [Evidence](HEARTH_CONFIG_TOY_COLLECTION.md).

30 October atomic-context binding follow-up: the five-client production-source
model passes 507 checks, with 105 scripts/747 Lua files passing the full desktop
suite. Mariosuper Era and Pandasans Retail were requested for native testing,
but no WoW process/window was visible in the workspace. Client WTF folders
appeared only transiently during read-only inspection, so they cannot prove
the live client state or a post-change reload.
Actual first-login/reload persistence, bridge clicks, grid labels, no replay,
taint and frame time remain pending. [Evidence](BINDING_ATOMIC_CONTEXT.md).

30 October binding persistence rewrite: 501 focused checks across five
modeled clients verify first-account native account-set save/load, empty-cache
version-5 repair, reload preservation, rollback and eight-write batches.
Full 105-script/747-Lua desktop suite passes. Actual client disk persistence,
bridge key presses, labels, taint and frame time remain pending.
[Evidence](BINDING_PERSISTENCE_REWRITE.md).

30 October binding repeat correction: 544 focused desktop checks across five
modeled clients cover first-account same-login application, strict no-replay
after partial writes/save failure, old pending marker migration, lost account
marker with existing native bridge keys, overlap suppression and the
eight-write frame bound. Full 105-script/747-Lua suite passes. Actual client
reload, binding persistence, hotkey labels and secure input remain pending.
[Evidence](ACCOUNT_BINDINGS_ONCE.md).

30 October account-only binding correction: 528 focused desktop checks across
five modeled clients cover first-account arming, single global completion,
old-marker migration, no character/binding-set replay, Settings callback
isolation and the eight-write frame bound. Full 105-script/747-Lua suite
passes. Actual first-account keys, later character behavior, persistence and
frame time remain pending. [Evidence](ACCOUNT_BINDINGS_ONCE.md).

30 October one-time binding correction: 521 focused desktop checks cover a
single full reset, completed-scope no-scan/no-write behavior across reload,
one registry scan and at most eight binding writes per frame on five modeled
clients. Native first-load keys, persistence, secure clicks, labels, combat
and actual frame time remain pending. [Evidence](FULL_BINDING_RESET.md).

30 October full binding reset: 521 focused desktop checks cover all-key clear,
supported Flux template apply, active-set save, late native replacement,
cross-login confirmation, combat and failure paths across five client models.
The full 105-script/747-Lua suite passes. Actual first-login/reload bindings,
secure key presses, hotkey labels, account/character scope and taint remain
pending on every client. [Evidence](FULL_BINDING_RESET.md).

30 October binding persistence: 35 focused desktop checks now cover a Flux
bridge assignment lost on reload, repair, and cross-login completion. The
full 105-script/747-Lua suite passes. Native first login, first reload,
account/character binding sets, real bridge clicks and both grids' hotkey
labels remain pending on every client. [Evidence](DEFAULT_GRID_BINDINGS.md).

30 October protected-client raid options: nine focused checks cover Flux-owned
class colors, power bars and health text against conflicting native CVars,
preview ownership and retained Classic reads. The full 105-script/747-Lua
desktop suite passes. Native first-login/new-character appearance, Blizzard
Settings values, real protected raid cells, combat and Edit Mode remain
pending. [Evidence](RAID_OWNED_SETTINGS.md).

30 October raid/nameplate follow-up: 15 focused desktop checks cover late
Classic raid profile completion and Medium nameplate defaults/migration;
104 scripts/746 Lua files pass in full validation. Native Classic power bars,
class colors and frame size, all-client nameplate size and Retail/Forever
protected raid behavior remain pending. [Evidence](RAID_NAMEPLATE_DEFAULTS.md).

30 October same-login binding follow-up: the prior repair did not assign keys
on the user's first load; the user also reports missing combat/noncombat grid
labels. The revised world-entry and delayed check pass 29 focused binding
checks; the live EBS hotkey refresh passes 7 focused checks. Full validation
passes 103 scripts/745 Lua files.
Each client still needs a first-load native check of `7`, `8`, `Y`, `6`, labels,
binding-set persistence and combat/taint. [Evidence](DEFAULT_GRID_BINDINGS.md).

30 October grid binding follow-up: the active native binding-set seed passes
21 desktop checks for default grid commands, custom-key preservation, account/
character scopes and deferred work. Full validation passes 102 scripts/744 Lua
files. Every client in `CLIENT_MATRIX.csv` still needs a reload on a suitable
test character, actual key click and hotkey label checks, persistence across
reload and combat/taint observation. [Evidence](DEFAULT_GRID_BINDINGS.md).

30 October first-login defaults: 42 production-source checks cover modern table,
tuple and legacy CVarInfo shapes, character/account/missing scopes and filtered
nameplate bitfields. The full 101-script/743-Lua desktop suite passes. For every
client in `CLIENT_MATRIX.csv`, native fresh-account and new-character CVar
classification/application, queue completion, bindings, Settings UI, combat and
taint remain pending. Gethe branch versions and exact candidate source identities
are in [the defaults record](DEFAULTS_FIRST_LOGIN.md). No client was controlled.

30 October vendor chat: desktop checks cover full denominations and gold, silver,
copper texture tokens for gain, expense and manual repair. The existing vendor
identity fixture passes. Native chat texture rendering and merchant transaction
checks remain pending on every client; no game interaction was performed.

30 October scale follow-up: desktop checks now cover 50% and 135% player
clearance, portrait centering, focus/chat mixed scales and conditional 3D
portrait refresh. Full 99-script/740-Lua suite passes. Native portrait crop,
action-strip clearance, hit areas, combat and pixels remain pending for every
client in `CLIENT_MATRIX.csv`. [Scale record](UNIT_FRAME_SCALE.md).

30 October whole unit-frame scale: the focused production-bridge model covers
dependent roots, detached chrome and both ToT parent layouts; full desktop
validation is in [the scale record](UNIT_FRAME_SCALE.md). Each client in
`CLIENT_MATRIX.csv` still needs native player/target/focus size, class resource,
cast/aura/indicator alignment, hit-area, combat/taint and pixel checks. No
client was controlled for this change.

30 October vehicle/durability layout: [the seat owner](../Other/FluxVehicleSeats.lua)
and [durability owner](../StatusBars/FluxStatusBar.lua) pass source-driven desktop
checks for menu-only, status-only, both and clear top-left chrome, PvP clearance,
load order, 70% seat scale and combat deferral. All clients in
`CLIENT_MATRIX.csv` have desktop coverage from the full 99-script/740-Lua suite;
native seat/durability art, click target, combat/taint and pixel checks remain
pending for this change.

30 October unit-frame follow-up: [zero-maximum resource behavior](UNIT_POWER_VISIBILITY.md)
passes desktop models and the 96-script/737-Lua full suite. Native checks are
pending for every client in `CLIENT_MATRIX.csv`, including combat, restricted
values, raid cells and pixels. Prior native results below do not certify this change.

[BUG-012/PERF-011 teleport follow-up](TELEPORT_CAST_WORK.md): user confirms Retail.
527 desktop assertions pass, including native display empty/opaque models and
legacy rune controls. Full 95 scripts/736 syntax files pass. No native input,
reload or capture this batch. Actual interruption latency/combat/taint/pixels and
non-travel custom-flyout comparisons remain pending.

This record began as a local installation/source audit. Era now has a native vendor attribution capture and five alternating background getter pairs; full visual/security and whole-vendor after acceptance remain pending. [Native evidence](TIER_COUNT_WORK.md). [CLIENT_MATRIX.csv](CLIENT_MATRIX.csv) records installed executable versions separately from `_FluxUI.toc` interface declarations, reference-source versions, and test status. [REFERENCE_MANIFEST.csv](REFERENCE_MANIFEST.csv) pins inspected metadata/license files; its hashes identify those files, not entire upstream packages.

## Installed roster and evidence limits

The requested Era, Anniversary, MoP, Retail, and Forever executables are accessible. Their Windows PE FileVersion values are respectively `1.15.9.70576`, `2.5.6.70577`, `5.5.4.70631`, `12.1.5.70575`, and `1.60.1.70685`. These values are installation facts, not executed `GetBuildInfo()` results or evidence of successful addon loading. Era runtime GetBuildInfo confirms 1.15.9 / 70576 / interface 11509. Its numeric project ID was not recorded; other runtime build/interface values remain pending.

The supplied spec calls Retail 12.1.0. The installed executable is 12.1.5.70575 and Flux's advertised interface remains 120100. All five named local Blizzard source trees are older than the corresponding installed executable. Do not silently relabel their builds or use them to certify current native callback contracts. They have no `.git` directory; upstream commit IDs are unpinned.

Modern Wrath and retained Cata remain separate rows with no matching installed executable found in the inspected immediate client directories. `_Ascension/Wow.exe` and `Ascension.exe` report `3, 3, 5, 12340`; this is a custom original-3.3.5 installation, not modern Wrath Classic. The supplied original Wrath UI tree has a descriptive README but no pinned build/commit. Current project-constant branches and filtered files do not establish original-3.3.5 support. Keep that row unsupported/unverified pending an explicit adapter and native validation; do not copy the addon to that client as part of this audit.

Other executables observed, outside the primary acceptance roster: `_beta_/WowB.exe` 12.0.1.66220, `_ptr_/WowT.exe` 12.1.7.70493, `_classic_era_ptr_/WowClassicT.exe` 2.5.6.70006, and `TurtleWoW/WoW.exe` 1.12.1.5875. Folder labels alone are insufficient to classify a client. No new deployment was made to any installation.

## Optional providers and local references

Retail's active AddOns root contains no top-level Syndicator, Baganator, Details, or Questie folder. Read-only reference availability is different from enabled-addon state: `__AddonsForRef/Syndicator` is version 267. Current Syndicator 288, Baganator 839, Details `#Details.20261015.15339.172`, and Questie 12.3.1 are present under both Era and Anniversary. AddOns.txt and private character settings were not used to infer an enabled load list. Record the actual loaded list in each native run.

Syndicator 288 source exposes `API.IsReady`, `GetCurrentCharacter`, `GetCharacter`, `GetWarband`, and the `Ready`, `BagCacheUpdate`, `CurrencyCacheUpdate`, and `WarbandCurrencyCacheUpdate` callbacks used by Flux. Its callbacks publish current-character identity and dirty bag maps in the expected source shapes. This verifies inspected API spelling/shapes only. Flux's adapter retains built-in facts while waiting, changes `Inv.source` to `syndicator` on `Ready`, proxies the account store, and avoids duplicate location tooltip lines. Baganator readiness is separate: its deferred bridge waits for `Baganator.API` and installs categories, gear protection, and bank controls.

The currency handoff audit found that four built-in currency event callbacks remain registered after `Store.SetUsesSyndicator(true)`. Before the fix, `PLAYER_MONEY` can still write the shared currency snapshot and the other callbacks schedule unnecessary inventory work. The modernization change addresses this narrowly; the root work log/performance ledger records its regression and before/after results. Native confirmation is still required. This does not claim all built-in provider resources have been retired; other region callbacks, timers and permanent mail hooks need their own lifecycle checks.

The continuation fixes two more deferred ownership paths: mail/auction scans now
cancel on their next callback after handoff, and pending send/return completion
discards builtin attribution before resolving a provider-owned character table.
See [provider lifecycle evidence](PROVIDER_HANDOFF_LIFECYCLE.md). Its desktop checks
do not change native acceptance status. Add queued/partial scans, forced final
inbox scan/retries, known-alt send/return success/failure and late Ready between
capture and completion to native scenarios where naturally reproducible. Preserve
standalone mailbox-open behavior and all existing interaction timing. Auction/guild/
void event ownership still needs separate evidence.

The baseline documentation contained several discrepancies corrected in this batch. `29-integrations.md` and `90-reference-inspirations.md` listed external companions in TOC OptionalDeps, but the actual TOC declares only Blizzard_UnitFrame and Blizzard_CompactRaidFrames. `21-inventory-foundation.md` and `29-integrations.md` described a Syndicator timeout/session fallback; the current adapter performs Ready-driven handoff. `29-integrations.md` described global Baganator item-identity wrappers, while current `BaganatorCompat/Loader.lua` leaves Blizzard item identity APIs intact, as `24-baganator-compat.md` already documented. Related stale architecture/command descriptions in `07-runtime-architecture.md` and `31-commands-and-bindings.md` are reconciled with the loaded source. The preserved baseline and supplied specifications retain the prior wording as evidence; these corrections do not restore obsolete runtime behavior.

Reference copies were inspected read-only. MoveAny, EllesmereUI, the local Bartender4 variant, Scrap, Syndicator, and Baganator contain reserved-rights notices. Clicked includes GPLv3. ButtonForge, Buffet, Restocker, and TrinketMenu did not supply a verified root-level reuse grant in the inspected files; bundled-library licenses do not license their host addons. ThreatClassic2 2.67 declares MIT in its TOC, but it is not assumed to be the requested `classicthreat`. ItemRack and a package named `classicthreat` were not found in the inspected reference/primary addon locations. No new code or assets were copied.

## Desktop checks actually executed

On 29 October 2026, from this checkout:

```powershell
lua tests/late_inventory.lua
lua tests/optional_startup.lua
lua Inventory/_tmp_inventorylag_smoke.lua
```

All exited 0 on Lua 5.4.6. The adapter test passed absent/pending/ready/repeated-readiness cases; optional startup passed BigDebuffs late initialization/idempotency/combat deferral; the inventory harness reported 1,732 checks across mocked Retail, Forever, Mists, Cata, Era, Anniversary and Wrath, for built-in and Syndicator pipelines. These particular harnesses do not load `Inventory/Builtin/Currency.lua` and do not cover the new currency regression. Their unchanged source inputs are in the recovered baseline; the final validation report identifies the candidate corpus and whole-suite result. They do not execute the installed provider addons or certify native WoW behavior.

Historical native captures remain under `docs/validation/`, including Retail and Forever CPU/presentation samples. They describe earlier trees/configurations and do not become before/after evidence for this change. Keep their original timestamps, build values and limitations. No current FPS, frame-time, taint, secret-value or pixel-parity result is claimed.

## Native acceptance procedure

Use one `_FluxUI` identity and the same saved profile for baseline/candidate, sequentially. Keep the recovery archive outside Interface/AddOns. Before any sequential source swap, close WoW, preserve the current working tree and relevant WTF data, and select only the recorded addon revision without resetting user changes. Do not enable a second addon copy. Initial baseline is commit `7436820453d2248c84c99fff71507553efc47c19` plus the recovered actual-file manifest; obtain the candidate identity from `STATUS.md` and the result ledger.

1. For each available primary client, record `/dump GetBuildInfo()` and `/dump WOW_PROJECT_ID`, hardware/driver/OS, loaded addons with versions, character/class/spec, zone/camera, keyboard or gamepad mode, resolution, render/UI scale, graphics settings, fonts, Flux options/profile, and profiling settings. Treat unavailable API outputs as unavailable rather than inventing a value.
2. Capture baseline screenshots at the same UI state: full idle HUD; Flux Window Map/Meter/Options; native and Flux unit-frame modes; bags/bank; currency/gold strip and tooltips. Repeat equivalent candidate screenshots and compare pixels and frame geometry. Keep mouse position, selected target, combat state, buffs, animation phase and scroll positions matched; document masks for unavoidable dynamic regions. Check option defaults/scopes, input edges, hover timing, held modifiers, menus, binds, slash commands and reload persistence.
3. Validate standalone inventory with Syndicator/Baganator disabled through the normal addon UI, then reload. `/fluxinv` should report `source=builtin` and eventual readiness. Observe gold and token changes, bank deposits/withdrawals where supported, item counts and location tooltips. Close/reopen bags and bank and traverse a loading screen. Restore the original addon selection after this scenario.
4. Enable the installed external Syndicator normally and reload with the same profile. `/fluxinv` should eventually report `source=syndicator`, `ready=yes`, and `syndicator=yes` in the store line. With `/fluxstartup on` followed by `/reload`, the startup report can expose the provider-ready milestone. A naturally fast Ready event may not exercise delayed handoff: mark that case unobserved rather than forcing provider globals or manipulating protected game APIs.
5. For the currency fix, after confirmed Syndicator ownership, earn/spend a recorded small amount of money through ordinary gameplay and open/close the bank; exercise a token update where available. Verify Flux gold/currency displays and tooltips follow provider updates once and do not regress to a stale built-in snapshot. In the standalone scenario verify those same native events still update immediately. Duplicate callback counts require a narrowly scoped diagnostic/native trace; visual correctness alone does not measure eliminated work.
6. Add Baganator and repeat bank/restock, gear-set shields and protection, junk/consumable categories, live versus cached-bank checks and profile reload. Repeat late native frame loads and combat entry/exit. Check existing Questie tracker/map ownership and Details meter behavior with their recorded versions; absent dependencies must retain supported standalone behavior. Do not execute destructive junk sales or equipment changes merely to populate a benchmark; use controlled items and reversible operations appropriate to the scenario.
7. Measure startup, steady idle and burst scenarios separately. For CPU captures, use `/console scriptProfile 1`, `/reload`, 30 seconds warm-up, then `/fluxperf capture 30` and `/fluxperf last`. Run at least five matched baseline/candidate pairs, alternating order, preserving each raw capture before the next overwrites the last-result slot. Record `/fluxstartup` separately and disable it with `/fluxstartup off` when done. Repeat unprofiled runs using `/console scriptProfile 0` and `/reload`; restore original profiling preferences afterward. If the client lacks a capture API, record that result explicitly.
8. Preserve raw samples and report variation, resource counts, CPU attribution, available memory deltas and operation latency. The capture's one-second FPS samples and recent profiler averages do not supply a frame-time distribution or reliable tails. Use a separately documented native frame-time trace where available; otherwise those fields remain pending. Never sum overlapping inclusive timings or equate reduced addon CPU with improved FPS.
9. Check Lua errors, blocked actions and taint attribution while exercising secure bindings, vehicle/possess/form transitions and combat-deferred operations. If collecting taint logs, record prior logging state and restore it afterward. Retail/Forever secret-value behavior must be observed through supported display APIs, without replacing globals or hiding illegal calls. Record each client/scenario as passed, failed, inconclusive, unavailable or pending with artifacts.

Reproduction of the read-only installation metadata:

```powershell
Get-Item 'F:\World of Warcraft\_retail_\Wow.exe' | ForEach-Object { $_.VersionInfo.FileVersion }
Get-Content '..\__AddonsForRef\wow-ui-source-live\version.txt'
Get-FileHash '..\__AddonsForRef\wow-ui-source-live\version.txt' -Algorithm SHA256
```

Use the corresponding verified path in the CSV for other clients/references. No native row can move to passed solely because these commands or desktop mocks pass.

## Windows lifecycle continuation — native checks pending

BUG-004/PERF-003 changes only mover discovery/watcher/disable lifecycle. The desktop
suite passes 85 scripts/726 syntax files and its focused production-code replay
passes 220 checks, including 100 toggle cycles. These do not advance any native
client row. Follow [Windows native steps](WINDOW_MOVER_LIFECYCLE.md): disabled reload,
late panel discovery, options/public API disable and re-enable, gesture cancellation,
saved geometry/scopes, protected combat Apply and matched screenshots/input. Capture
matched native startup/idle/burst performance with profiling overhead accounted for.
Auction/guild-bank/void callback audits are currently deferred by user direction.

## Queued merchant identity — native acceptance pending

BUG-005 uses the existing item-ID/link resolver before a queued purchase. The desktop
replay passes 660 checks and the full suite 86 scripts/727 syntax files; no native
client row advances. Follow [merchant identity native checks](VENDOR_PURCHASE_IDENTITY.md):
stable manual/automatic restock, naturally changed/missing listings before/after
index refresh, normal fresh-request recovery, quantities, money, tier/alternate-cost
behavior, close/reopen, input/combat/taint and matched screenshots/performance. No
native API replacement or forced live-data manipulation is part of the procedure.

## Finite merchant stock — native acceptance pending

BUG-006 caps zero availability and reserves finite submitted quantities on shared
merchant index entries. Desktop stock/identity replay passes 837 checks, with the
full 86-script/727-syntax suite passing. No native client row advances. Follow
[stock native checks](VENDOR_STOCK_BUDGET.md) for sold-out/limited/unlimited merchants,
partial funds and alternate costs, cross-pass/shared targets, replenishment/new
requests, real acceptance/error totals, screenshots/input/combat/taint and matched
startup/idle/purchase profiling. Reservations do not certify native acknowledgement.

## Vendor-open hitch — native attribution recorded; after acceptance pending

The user reports a spike on every Era vendor reopening. A clean four-reopen capture
now confirms a 333 ms maximum UI interval on 1.15.9.70576 with automation off and
profiling=1. [PERF-006](TIER_COUNT_WORK.md) records attribution and native getter
comparisons; whole-vendor after acceptance remains pending.
BUG-007/PERF-004 removes a desktop-reproduced redundant junk scan contributor. Seven
API fixtures pass 265 checks and the full suite 87 scripts/728 syntax files. This
advances no native client row. Original Wrath 3.3.5 is not covered by the modern
Wrath fixture. Follow [vendor-open native procedure](VENDOR_OPEN_WORK.md): Era first,
matched first/repeated opens without actions, recorded settings/addons and raw
frame-time evidence, cold data/protection/Useful controls, standalone/external
provider readiness, then each available client. Compare pixels/input/cadence and
profiling overhead. Do not deploy to another installation without authorization.

## Quick Join SetPoint cycle — native recheck pending

The user's stack names the social callback and a Channels frame on FluxCCPChatColumn;
no affected client/build was specified. BUG-008 reproduces and fixes that reversed
anchor dependency in production-backed Live/Forever Quick Join fixtures on both
sides. Existing five-branch column controls remain; the full 87-script/728-syntax
suite passes. No native row advances. Follow [chat native steps](CHAT_QUICKJOIN_ANCHOR.md)
for reload, native alerts, tab/side changes, Social/Channels visibility, Edit Mode,
combat/regen, matched screenshots/geometry, input/taint and profiling. Clients with
only FriendsMicroButton retain their separate path. Original Wrath is unverified.

## Repeated Era vendor spike — prior PERF-005 scope

User confirms every same-vendor reopening spikes. Prior junk/buyer/chat sources
matched the Era install before this batch; no sync was performed. Saved Config.wtf
has scriptProfile=1; runtime state was unobserved in that prior batch. [PERF-005](VENDOR_TIER_WORK.md)
reduces repeated usability work in legacy/modern API fixtures: 340 checks, five
matched pairs and full 88 scripts/729 syntax pass. No native row advances. Prioritize
matched repeated-open profiling on/off runs, retaining the original preference;
record actual build/profile/addons and raw hitch evidence. Check reference discovery,
levels/skills, cold rejected items, thresholds, ties, pixels/input/combat/taint.

## Era native count comparison — partial pass

Actual runtime 1.15.9.70576 / interface 11509, level 60 Mage, built-in inventory,
recorded addon list/hardware/settings. Five alternating background baseline/local
candidate pairs preserve all getter results and reduce measured CPU. [PERF-006
protocol and raw samples](TIER_COUNT_WORK.md). Personal-bank outputs are all zero;
positive bank and warband quantities are desktop-only. User's normal sync delivered
candidate source; original automation flags and profiler=1 restored. WoW stays in
the background without further foreground access.

Only Era's matrix row gains this partial native result. Full repeated-open after,
matched screenshots/input, cold work, unprofiled FPS, security/taint, external
providers and other clients remain pending. Original Wrath remains unverified.

## Retail native idle and resource audit — partial evidence

Retail is now observed running 12.1.5.70575, interface120105, project1, level81 Mage
in Stormwind. Five background profile1 idle captures and ten GC/frame censuses
record actual addons/settings/hardware. Frame/public-cache sizes stay stable while
requested diagnostics retain memory; [audit](RETAIL_PERFORMANCE_AUDIT.md) separates
that observation from a normal HUD leak claim. Source fixes reuse loot waiters and
release full capture snapshots. Original profiler=0 is restored after measurement;
no game activation or public/native API replacement. Complete foreground FPS,
visual/input/taint/secrets, combat/loot, long sessions, external providers and other
clients remain pending. This partial row does not certify all Retail features.

## Shared chat column follow-up

Retail BUG-011 native partial pass: Social gap8 UI units, untouched post-reload screenshot inspected before chat/tab input, and seven General/Global/Combat Log selections with identical visible coordinates. Profiler0 restored; temporary exports removed. [Evidence](CHAT_COLUMN_ALIGNMENT.md). Custom-tab desktop checks do not certify other native clients or combat/taint.

## Countdown native follow-up

PERF-009 Retail 12.1.5.70575 / interface 120105 / project 1: five alternating
real-widget pairs retain identical owned-widget geometry, alpha and hide/reuse,
with zero recorded errors. Median elapsed time per 2,000 updates is 33.371 ->
31.712 ms; one candidate pair is slower. Full-addon scene changes make its separate
before/after capture inconclusive. Profile 0 stays unchanged and diagnostics are
removed by normal reload. [Exact evidence and remaining steps](NAMEPLATE_COUNTDOWN_WORK.md).
Other clients have desktop controls only for this batch; actual plate-aura pixels,
secret values, combat/taint, foreground FPS and long-session acceptance remain pending.

## Action-bar/player-aura follow-up

PERF-010 runs sequentially on Retail12.1.5.70575/interface120105/project1 and
Era1.15.9.70576/interface11509/project2 (SoD realm). Requested characters verified.
Five alternating real57-button pairs per client reduce activation calls5800 ->100
per100 passes. Button shapes and native player-aura root anchors/scales/visibility
match; recorded errors0. Native highlight setting is inactive; enabled combat
painting and protected input still need real gameplay checks. Small short-idle
native aura CPU readings do not certify dense/restricted aura churn or leak-free
sessions. [Evidence](ACTION_AURA_WORK.md). Original profile0 Retail/1 Era restored;
Retail diagnostic root nil and Era prior report restored, deep-equal. Sessions
conflict on this account: both processes stay open but testing is sequential.
