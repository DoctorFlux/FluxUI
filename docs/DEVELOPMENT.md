# Development tasks

14 November `ADDON-PUBLICATION-20261114`: the user requested publication of the
full current addon snapshot to DoctorFlux/FluxUI on main, including completed
auction, consumable, UI/options and casting/inventory work. Preserve all newer
source and licenses. This task updates documentation, the stale commerce renderer
regression and Git state. The regression permits fewer hidden-row writes while
retaining native repair, opacity, reentry and exact-error propagation checks;
addon runtime code, settings and client/profiler state remain under their owners.

Both author and committer must be DoctorFlux
`<100806234+DoctorFlux@users.noreply.github.com>`, with no co-author trailers.
The existing identity hooks remain active. Five identity regressions and all four
prior reachable commits passed; GitHub's pre-upload contributor API lists only
DoctorFlux. Check the new main history and contributor/workflow state after push.
GitHub has no contributor blacklist; enforce publication metadata at each upload.

Current source evidence: 365 fresh desktop scripts passed; 52 auction/shared-grid
dependents were replayed after the last concurrent UI edits, with all Lua stable.
The index retains 14 unchanged meter/threat observations from their owner instead
of rerunning them. All 1067 syntax hashes match current files; 379 passing
observations are recorded. The adapted commerce test rejects four compiled
harmful controls. Existing native
acceptance gaps remain; publishing establishes no new native/performance result.
External source/history/index checkpoint: 2794 files and
113 settings metadata entries; no private settings copied.
No branch/reset/force push/tag/repository replacement. [Publication record](validation/addon-publication-2026-11-14.json).

Keep remaining native feature/performance acceptance under the existing task owners.

14 November — current AH build is r27 (AHR-105/106). Opening Restock starts
one shortage-only preparation. Filled targets are skipped; passive bag/mail/
profession changes refresh counts without replacing choices, canceling searches
or reviving completed work. Matching purchase receipts still prepare the next
shortage. Buy next can start again after later stock changes; purchases remain
player presses. Explicit modern Scan all is still full pricing; old AH per-item.

Loot & Items → Restock: healing/mana AH upgrade prompts default on; bandage off.
Saved independent choices retain current-tier crafting/direct restock. Compact
native Keep / Block labels now fit; passive paints preserve native enabled states.
76 affected scripts/82 syntax PASS; 440 checks/20 profiles; 3 matched trials and
11 compiled harmful controls. Other verification records are historical, not a
full rerun. External `explicit-restock-20261114T090141Z`: 2780 files/history,
129 settings metadata; 5 installed copies match 6 runtime files read-only.

Next: user-ready reload, then native shortage opening, stable upgrade cards,
text fit/controller and purchases. No native input/reload/profiling this slice.
Preserve the other agent's meter work and test ownership. [Evidence](validation/auction-passive-refresh-2026-11-14.json).

14 November — AHR-104 is current: all healing/mana potion tiers use actual
minimum restore, including buttons, crafting, vendor memory, AH and automatic
junk. Minimum 600 beats 500 even if the latter's maximum is higher. Existing AH
approval and per-purchase player presses remain; compact r26 controls stay.

Saved refs/vendor records and positive thresholds migrate from verified parsed
facts. `savedHealPotionTierBasis` / `savedManaPotionTierBasis` mark minimum-valued
thresholds. Unknown old facts stay saved but cannot rank/promote as verified
minimum candidates. Potion cache stores effect text/axes/minima; legacy maximum
alone is unresolved. Food/water/bandage ranking and manual Junk precedence stay.
74 affected scripts/79 syntax; 510 minimum checks/50 profiles; 10 harmful controls
PASS. Global verification labels other test results historical; no full rerun.
External `potion-minimum-20261114T083404Z`: 2778 files/history; 129 settings metadata.

Next: user-ready reload and native minimum-tooltip/button/AH acceptance checks,
without choosing an upgrade or buying for the user. No native client input or
profiling was used in this slice. Preserve the other agent's meter work and its
test/verification ownership. [Evidence](validation/potion-minimum-restore-2026-11-14.json).

Full validation: 365 scripts and 1053 Lua syntax files PASS; complete current Lua manifest verified.

14 November meter recovery: `METER-CONTROL-RECOVERY-20261114` restores direct
type/layout/tab/setup choices, required windows and Current defaults using only
existing native menu descriptions/original Pick with provenance guards. No native
menu generation/opening/private setters or history reset. 476 control checks,
12 focused scripts, both pinned native menu replays and 7 harmful controls PASS.
Next: existing user-native route, reload outside combat and reselect the layout;
verify matching types/Current, two fights, manual history, drilldown/controller.
Native VM/taint/pixels/CPU/FPS NOT RUN. Preserve tooltip/header fixes, current main
and concurrent work. [Requirements](METER_STANDALONE.md#meter-control-recovery--14-november-2026);
[evidence](validation/meter-control-recovery-2026-11-14.json).

14 November — current AH build is r26 (AHR-102/103). Upgrade cards are 44px with
candidate icon/Upgrade above Keep/Blacklist; details are in tooltips. Order:
healing, mana, bandage, spell reagents, consumable configuration, then others.
Both real merged targets and virtual no-reference proposals use that order and
keep independent actions. Auction scripts/1053 syntax; 1220 inline, 672 confirmation
and 780 geometry checks; 8 harmful controls PASS. The verified recovery/load list
remains intact. Existing source checkpoint is external in
`compact-upgrades-20261114T080946Z` (2776 files/history; 129 settings metadata).

The user explicitly assigned meters to another agent. Leave meter inspection,
testing and changes to that agent while working on this AH task.

Next native check: after the user's crafting is finished and they choose to
reload/reopen AH, inspect the compact text fit, hover details, three independent
choices, next row and scrolling. Check controller/native other-client behavior
separately; desktop geometry is not pixel or input certification. The background
capture showed active crafting and AH closed; no input/reload was sent. No
upgrade decision or purchase was made for the user. Do not rerun old recovery
scripts on newer work. [Evidence](validation/auction-compact-upgrades-2026-11-14.json).

14 November — current source is r25 with inline multi-item upgrades and shared
exclusions; the unrequested source/load-list rollback has been recovered.

365 scripts/1053 syntax files PASS; full normalized source manifest matches.
Keep the recovered TOC entries for options Skin, meters/threat, mail, auction,
party and cast helpers. Before versions and verified archives are external in
`restock-shared-blacklist-20261114T072300Z`; recovery scripts are historical,
guarded operations, not commands to rerun on newer work. Writer remains unknown.

Next safe native checks: wait until the user is idle, then open recovered options
and inspect healing/mana/bandage inline choices without accepting for the user.
Verify multiple independent actions, scrolling/controller, saved tier changes,
mail/vendor/bank/craft follow-up and explicit purchase receipts separately.
Keep Forever in the background; never send a chat probe without verifying current
empty input. The last attempt produced no output during player movement and was
excluded. Meter skin/Threat visibility after reload is observed; it does not prove
options/input/taint/other-client parity or FPS. No agent purchase/upgrade/reload.

Settings: Loot & Items → Restock contains the default-on Discolored filter and
manual item blacklist; Loot & Items → Vendor has 3 default-on carried-upgrade junk
protections. Manual Junk wins. Old AH still prepares one item/whole stack per
player press, with no full Scan all restock control. [Current evidence](validation/auction-inline-upgrades-2026-11-14.json),
[recovery evidence](validation/flux-source-recovery-2026-11-14.json).

14 November Forever potion discovery and upgrade approval (AUCTION-POTION-BROWSE-20261114;
AHR-93–95), build AH-restock-potion-browse-20261114-r24. Upgrade/Keep current now
precedes any saved tier, inherited policy or previous-item junk change. Decline,
Escape, combat, closing and stale callbacks preserve current state; buying needs
its own player press. This supersedes AHR-92's automatic promotion.

Independent health/mana range parsing avoids mixed axes and cooldown/level
digits. A completed empty modern phrase browse gets one name-free potion-category
fallback. An unsent request owns no results; the ready event wakes its existing
bounded wait and native unavailability is shown explicitly. Dynamically linked
spell text loads once per item/job; late text can revive a negative parse once.
Loaded item metadata is no longer re-requested by the pending classifier, which
otherwise repeatedly lost retry evidence to duplicate metadata events. Known
unusable items are rejected before parsing. No new potion-name/tier/ID catalogue;
old AH remains per-item only. Existing price/vendor/buy owners and limits remain.

Actual Forever1.60.1.70938 background test: normal Buy was empty too and the native
queue was unready. Fresh Mario Super character login restored62 catalogue rows.
Native text parsed Superior Healing900 health at level35 and Greater Mana900
mana at requiredlevel31. r24 Restock now displays an upgrade from Greater Healing
to Superior Discolored Healing at22s93c/unit. Its Upgrade/Keep current prompt is
left unanswered; the current5/5 target remains unchanged. No buy/upgrade decision
was submitted. Native mana prompt follows the healing choice and remains pending.
Other clients, accepted native tier/junk persistence, buys/receipts, controller,
taint and CPU/FPS remain unverified. Earlier misfocused/protected exploratory
probes are excluded from acceptance; errors retained, no addon disabled.

Confirmation672/20 and restore/browse388/20 focused checks PASS. Three matched
before/after trials per20 models for each regression retain raw outcomes.
363 scripts/1051 syntax;15 harmful controls;complete current Lua manifest PASS. Four verified external source/history checkpoints
(2769/2770/2771/2771 files), each129 settings metadata; no private contents copied.
All five installed copies match five runtime files read-only; no manual sync.
Main/.githooks/concurrent work retained. Explicit background testing authorization
used; no foreground/global input/clipboard, settings/profiler write or publication.
[Requirements/native scope](AUCTION_RESTOCK.md#forever-empty-browse-and-restore-amounts);
[exact sources and acceptance](validation/auction-potion-browse-2026-11-14.json).

14 November usable potion upgrades (AUCTION-POTION-TIER-20261114; AHR-92), build
AH-restock-potion-tier-20261114-r20: per-item AH preparation now checks stronger
usable healing/mana tiers even when weaker potions fill the target. A real
eligible listing promotes the saved tier and fills the full stronger target;
the next purchase still needs a player press. Old AH remains per-item only.
Fresh kind catalogues are reused at the same level; character-level changes
invalidate usable-only coverage so newly usable tiers can be found immediately
on the next preparation. Caps/No limit, restrictions/vendor policy, target0 and
native gesture guards remain. New240/20 checks and existing potion580, speed492,
price820, craft836 and scan284 checks PASS. Three matched before/after trials
per20 models retain raw tier/query observations. 361 scripts/1049 syntax;3 controls;complete current Lua manifest PASS.
The obsolete filled-legacy-idle assertion was updated; safety checks retained.
Verified external2767-file source/history checkpoint and 129 settings metadata;
private contents not copied. No new event/timer/poll/frame/settings. Main/.githooks
and concurrent work retained. No foreground/input/clipboard, settings/profiler
write, manual client sync or publication. Native eligibility/search/tier display,
buying/provider coexistence/controller/taint/CPU/FPS remain NOT RUN; existing
user-native test route retained.
[Requirements/native checks](AUCTION_RESTOCK.md#usable-potion-tier-upgrades-during-per-item-scans); [evidence](validation/auction-potion-tier-2026-11-14.json).

14 November restock mail cadence (AUCTION-MAIL-SPEED-20261114; AHR-91), build
AH-restock-mail-speed-20261114-r19: the existing Opening Speed sets the interval
between restock take requests, including0. Reply time is no longer added; an
acknowledged batch does not wait for a full inbox rescan before every attachment.
Initial snapshot and live header/COD/GM/item/quantity/receipt/free-space/native
command checks remain. Snapshot publication wakes the same worker. Successful
message compaction preserves cadence; abort/failure resets it. Setting changes
update an active deadline. Ordinary Select/Open All settings/behavior remain.
Focused940/20, existing mail3100 and automation1260 PASS. Three matched trials
per20 models at six speeds; simulated200msreply with0.5speed gives requests at
0/0.5/1.0 versus0/0.7/1.4. These are desktop timestamps, not native throughput.
360 scripts/1048 syntax;5 controls;complete current Lua manifest PASS. Verified external2765-file source/history checkpoint
and 129 settings metadata; no private contents copied. No new event/frame/ticker/
poller; existing timers and48-read/1ms/8s scan bounds retained. Main/.githooks and
concurrent work preserved. No foreground/input/clipboard, settings/profiler write,
manual client sync or publication. Native collection/throughput/taint/CPU/FPS
remain NOT RUN; retain the user-native test route.
[Requirements/native checks](AUCTION_RESTOCK.md#restock-mail-opening-speed); [evidence](validation/auction-mail-speed-2026-11-14.json).

13 November duplicate system debuffs (UNIT-DEBUFF-OVERLAP-20261113; UDO-01–03):
user confirms the two XP icons show the same effect. The larger native own group
now also requires a player-origin flag; exact PLAYER/!PLAYER ownership filters,
other-player effects, own sizes and separate same-spell instances remain.
100 focused checks PASS; exact baseline and four harmful variants rejected;
359 scripts/1,047 syntax PASS with the complete current Lua manifest verified.
Native filter overlap is a hypothesis, not captured C behavior; actual XP removal,
player/pet/vehicle metadata, pixels/tooltips/controller/taint/CPU/FPS NOT RUN.
Verified external 2,758-file source/history checkpoint; 70 settings metadata entries,
no private values copied. One native predicate; no new driver/resources/settings.
Direct correction/user-native route retained; reload OOC and retarget. No game
input/focus/clipboard, settings/profiler writes, manual sync or publication.
[Requirements/native steps](14-unit-frames.md#duplicate-system-debuffs--13-november-2026); [evidence](validation/unit-debuff-overlap-2026-11-13.json).

13 November steady craft completion and measured restock work (AUCTION-CRAFT-STEADY-20261113;
AHR-89/90), build AH-restock-craft-steady-20261113-r18: known same-job craft items
remain visible/disabled during bag settlement; reliable counts update in place
and completion hides once. Actual service/driver/storm/HUD regression412/20
passes, including coalesced outputs, partial/no-output cancellation and unsafe
tokens. A public observed cast can hold presentation only, never credit inventory
or authorize another craft. Legacy name-mismatch fallback remains native UNKNOWN.
Data1900/20: an80-row refresh cuts deficit/bag reads160→80 and mail reads320→80;
service carried reads275→250 per25 refreshes. UI63063 plus render1020/integration290
pass: identical paints do no avoidable setter/layout/show/hide work; quantity-only
updates avoid reflow. Three matched trials per20 data/service and5 proc-enabled
UI profiles; counts are desktop work, not native timing/atlas/FPS evidence.
358 scripts/1046 syntax;16 controls;complete current Lua manifest PASS. Verified external2758-file source/history checkpoint
and 129 settings metadata; private contents not copied. One job-owned START
observer; no new timer/poller. Old per-item AH, modern full scan, settings and
native click/receipt owners preserved. Main/.githooks/concurrent work retained;
no foreground/input/clipboard, settings/profiler write, manual sync or publication.
Native ordering/art/controller/taint/CPU/FPS remain NOT RUN; existing user-native
test route retained.
[Requirements/native checks](AUCTION_RESTOCK.md#stable-craft-completion-and-restock-work); [evidence](validation/auction-craft-steady-2026-11-13.json).

13 November 20:38/20:39 secret texture and tooltip follow-up
(TOOLTIP-VISUAL-FOLLOWUP-20261113; CLASS-TIP-01–03): both class-icon paths now
filter UnitClass filenames through the existing safe-string helper before
concatenation. Restricted class data hides stale art until public data returns;
ordinary art/fallback/corners/settings remain. 560 icon and 766 diagnostic checks
PASS; checkpoint concatenation fails; four harmful variants rejected. Full
355 scripts/1,043 syntax PASS. External 2,753-file source/history checkpoint and
129 settings metadata verified; private contents not copied. The new color error
names _FluxUI taint, but the originating field/build/reload status are unknown.
Tooltip resolution remains UNRESOLVED. Existing taint logs predate this report.
Reload out of combat; if it recurs run /fluxinput tooltip and hover within three
seconds, then share the printed field/writer/build lines. Opt-in metadata only;
no native tooltip data/actions/hooks, logging/profiler change or idle driver.
Prior diagnostics/settings/roots retained. Native class/tooltip resolution,
pixels/controller/taint/CPU/FPS NOT RUN. No client control/sync/publication.
[Requirements and steps](SECRET_TOOLTIP_METER_ERRORS.md#secret-class-texture-and-tooltip-provenance-follow-up);
[evidence](validation/tooltip-visual-followup-2026-11-13.json).

13 November 20:29 world-cursor tooltip follow-up (WORLD-TOOLTIP-20261113;
WORLD-TIP-01–04): binding ownership, spellbook hints, protected-gear flags and
consumable separators use private weak-key tables. Native clear/hide callbacks
no longer write these fields on shared GameTooltip. Content/deduplication,
HUD/cadence, native APIs/processors, input owners and settings remain. 115 new
bookkeeping checks; 66 spellbook checks; five pre-fix source cases and five harmful
variants rejected. Full suite: 353 scripts and 1,041 syntax checks PASS. Verified
external checkpoint: 2,750 files/history and 129 settings metadata entries;
private contents not copied.
Gethe Retail/Forever pins rechecked. The report lacks originating taint/source/
build attribution;native resolution is NOT RUN. Reload out of combat and retest
world units before/after addon hovers and in combat. Existing user-native route
retained;native pixels/controller/taint/CPU/FPS pending. No new frame/hook/event/
timer/poll or client/input/settings/profiler/publication operation.
[Requirements and native steps](SECRET_TOOLTIP_METER_ERRORS.md#world-cursor-follow-up-at-202955);
[evidence](validation/world-tooltip-state-2026-11-13.json).

13 November old auction-house per-item flow (AUCTION-LEGACY-ITEM-20261113; AHR-88),
build AH-restock-legacy-item-20261113-r17: old AH has no Scan all restock control
or bulk-scan backend. The main action prepares one shortage and its relevant
recipe inputs/current potion kind, buys one listing per player press, then
prepares the next after its receipt. Even retained full-scan requests use this
path. Old help describes Search then Buy; modern explicit full scans remain.
Saved settings, caps, excess policy and native purchase/receipt guards are
preserved. 352 scripts/1040 syntax PASS with complete current
Lua manifest; three harmful controls rejected. Initial obsolete price-policy
fixture failure and its correction are retained in evidence. Verified external
2750-file source/history checkpoint and95 settings metadata;
private contents not copied. No new event/timer/poller; one fewer old-AH button.
Main/.githooks and concurrent work retained; no foreground/input, settings or
profiler writes, manual client sync or publication. Native transactions, layout,
controller, taint and CPU/FPS remain NOT RUN; use the existing native test route.
[Requirements/native checks](AUCTION_RESTOCK.md#old-auction-house-per-item-searches); [evidence](validation/auction-legacy-item-2026-11-13.json).

13 November meter title alignment (METER-TITLE-20261113; METER-TITLE-01–03):
native labels recover Threat's five-pixel inset/shared baseline when the initial
width is zero, the first hidden pane opens or native anchors/width reset. Combat
resize uses existing deferred header refresh. One guarded show hook per native
session pane; no new frame/texture/timer/event/poll. Original geometry restores
on release; native localized text/menu/input/controller owners and saved data
remain. 206 skin checks PASS; exact checkpoint baseline rejects 25 new cases
(27 final failures including two hook-count expectations). Full352 scripts/
1040 syntax PASS with complete current Lua manifest verified. External2748-file
source/history checkpoint and76 settings metadata verified; private contents
not copied. Prior direct implementation/user-native test route retained.
Native pixels/localized clipping/input/controller/taint/CPU/FPS NOT RUN. No
foreground/input/clipboard control, settings/profiler writes, manual sync or
publication. Reload out of combat and compare reopened pane titles with Threat.
[Fix and native steps](METER_STANDALONE.md#header-alignment-recovery--13-november-2026);
[evidence](validation/meter-title-2026-11-13.json).

13 November fast auction restock and usable pending item buttons
(AUCTION-SPEED-READY-20261113; AHR-81–87), build AH-restock-speed-ready-20261113-r16:
routine preparation prices the next shortage and its recipe inputs, then prepares
the next item after its receipt. Explicit Scan all restock retains full-list and
filled-target potion upgrades. Three direct purchases take1 query before the
first ready item and3 total, versus4 and6 before, with3 player presses in both
desktop models; these are query counts, not native timing. Item buttons remain
32–44px with exact1px gaps and ordinary pressed art. Only visible actionable
items have private proc glow; busy/submitted/closed/combat states stop it.
Crafting updates remaining planned output quantities automatically. The mailbox
Restock button/adjacent checkbox are removed; settings and the selective worker
remain. Closed-profession mail→bank/vendor progression uses durable owned recipe
facts across serialized reloads. Partial alias/roster responses preserve complete
facts; live crafting still verifies ownership, materials and output. Snapshot
dispatch fixes storm-listener mutation; strict receipt reconciliation protects
new transit from stale mail. Full-bag mail retry is covered by the owner tests.
352 scripts/1040 syntax;complete current Lua manifest PASS. Current harmful controls and exact
source identities are linked below. Verified external2743/2745-file source/history
checkpoints and95 settings metadata each; private values not copied. Main and
.githooks retained; concurrent work preserved. No foreground/input, settings/
profiler write, manual client sync or publication. Native protected transactions,
mail/bank/vendor coexistence, login persistence, proc/pressed art/clipping,
localized/controller behavior, taint and matched CPU/FPS remain NOT RUN. Use the
existing user-managed native test route across all five clients.
[Requirements/native checks](AUCTION_RESTOCK.md#fast-purchases-and-usable-pending-item-buttons); [evidence](validation/auction-speed-ready-2026-11-13.json).

13 November auction follow-up overview (AUCTION-FOLLOWUP-ITEMS-20261113;
AHR-74–80), build AH-restock-followup-items-20261113-r13: every current-step item
has a sorted icon and physical quantity; icons shrink/wrap inside one ordinary
stage hit/focus host. Caption is larger, outlined and contrast-backed. Matching
live bank/vendor/mail contexts glow; cached bank views, closed contexts, waiting,
completion and combat do not. One press delegates all scoped step items through
existing owners, without unrelated targets or duplicate submitted work.
Loot & Items → Restock has independent auction follow-up automation (default off),
compatible with both existing bank/vendor auto settings. No limit defaults on for
new/unset items; existing positive AH caps are preserved. With it off, zero is a
real cap; saved craft/potion source policies retain the mode. Explicit Scan prices
all listed items including full/zero/free-route inputs. Full weaker healing/mana
stock can upgrade its saved tier and fill the entire stronger target. Clear pending
is absent. Grouped Auctionator availability stays distinct from one-item bids.
348 scripts/1036 syntax PASS with complete current Lua manifest;36 harmful controls
rejected. UI16763, actual-owner integration270, automation800, price788 and scan340
checks PASS. Fixed readiness recursion, scoped vendor price fallback and bounded
failed-auto retry. External2729-file source/history checkpoint and95 settings
metadata verified; private values not copied. Concurrent minimap work preserved.
No foreground/input, settings/profiler writes, manual sync or publication. Native
operation/glow/pixels/controller/taint/persistence/CPU/FPS remain NOT RUN; retain
the existing user-managed reproduction across all five clients.
[Requirements and native checks](AUCTION_RESTOCK.md#item-overview-follow-up-automation-and-explicit-price-limits);
[evidence](validation/auction-followup-items-2026-11-13.json).

13 November action counts: desktop acceptance passes for ACR-01–05. Complete native loot/vendor/trade/mail19→20 and1→0→1, spell/item charges, modifier badges, form settle, hidden reveal and combat on all five clients/both inventory providers. Keep native taint/controller/pixels/CPU/FPS pending. [Requirements and read-only comparison](ACTION_COUNT_REFRESH.md).

13 November auction restock recovery (AUCTION-RESTOCK-RECOVERY-20261113;
AHR-66–73), candidate AH-restock-recovery-20261113-r12: waiting is silent;
changed ingredients reprice safely; each ingredient's Count Bank flag controls
AH/vendor quantities and source costs. Latest verified vendor stock replaces the
opposite classification. Saved recipes retain profession, recipe, materials,
output and yield while closed. Modern commodities can buy forty at once; modern
item bids and old listings still require their own native press. Grouped modern
availability is separate from purchased quantity: one five-charge oil reserves
five uses once. Excess stacks apply only to old-AH ordinary items; the control
is hidden on modern AH. Target nine uses/five per item still rounds to two items.
Desktop suite341/1029 PASS with all owned auction hashes matching;26 harmful
controls rejected. Later unrelated source changes are preserved and recorded,
so that captured suite is not a claim about newer global files. Source checkpoint
2699/history and95 settings metadata verified; no private settings copy.
No foreground/input, settings/profiler writes, manual sync or publication.
Old corrupted reservations cannot safely be halved; reconcile from the mailbox.
Native purchase/mail/vendor/bank/craft, pixels/controller/taint and CPU/FPS remain
NOT RUN. Existing user-managed native reproduction retained.
[Requirements and acceptance](AUCTION_RESTOCK.md#silent-waiting-and-changed-ingredient-stock);
[evidence](validation/auction-restock-recovery-2026-11-13.json).

13 November auction workflow: local implementation and40 focused desktop scripts pass; initial336/1024 broad pass predates unrelated concurrent edits.
Complete native acceptance for AHR-57–64 across the five clients; do not infer
secure operation, delivery, rendering/controller or FPS from mocks.
[Requirements and native checklist](AUCTION_RESTOCK.md#integrated-restock-workflow-13-november-2026).

13 November trinket follow-up: implementation and desktop regressions pass;
native held-input/tint, empty/re-equip, shared/swap cooldown completion, flyout,
combat and controller acceptance remain pending. [Task evidence](TRINKET_EQUIPPED_USABILITY.md#13-november-follow-up-intermittent-dark-faces-and-cooldown-overlays).

Current priority, 5 November: [mail and auction performance work](MAIL_AUCTION_REWORK.md)
tracks opening/closing, loot, posting, buyer sales, purchases and cancellation
across all five clients and optional providers. Keep these requirements separate
from unfinished mail features. The snapshot work uses baseline `437fda7`; preserve
newer consumable work through `2c0e7b8` and the combined 149/804 passing source.
Progressive Buy/Cancel cost is tracked in [growth evidence](PURCHASE_GROWTH_AUDIT.md).
Partial Forever source/startup checks passed; matched transaction/freeze captures
remain pending. Leave WoW in the background and preserve enable flags
and profiler0. Earlier dated tasks below retain their historical scope; renewed
auction requests supersede their auction-callback exclusion. Guild-bank and void
callbacks remain excluded.

5 November consumable targets: complete native acceptance for CTD-01 through
CTD-04 in [CONSUMABLE_TARGET_DETECTION.md](CONSUMABLE_TARGET_DETECTION.md),
especially a real staff-only coating versus dagger/sword, off-hand targeting,
English/non-English tooltip wording, combat and secure click. Desktop fixture
passes 30 checks; full 134/789 pass. Do not infer universal item coverage from
the parser or native performance from mock counts.

4 November combined Classic bank: complete native Era and Anniversary
acceptance for [BANK-C01 through BANK-C05](CLASSIC_COMBINED_BANK.md),
including plain-click no-toggle bank bag slots, purchase state, Baganator
handoff and visual/performance comparison. Focused desktop models pass.

1 November trinket tint: verify passive equipped trinkets dim and ready on-use
trinkets stay bright; check use spell restrictions, cooldown, empty slot,
combat input and pixels. Focused 10 checks and isolated 112-test/757-Lua
desktop suite pass; native acceptance pending.
[Evidence](TRINKET_EQUIPPED_USABILITY.md).

31 October equipped trinket tint: verify ready equipped on-use
trinkets stay bright while a genuinely unusable use spell can darken. Check
cooldown, dead/revive, bag flyout, secure clicks, keybinds and swap queue on
each native client. Focused loaded-paint fixtures pass; isolated published-source
desktop suite passes 112 tests/757 Lua files. Native acceptance pending.
[Evidence](TRINKET_EQUIPPED_USABILITY.md).

31 October chat durability teleport follow-up: native teleport/loading-screen
recovery now needs sequential verification on every supported client. Test
normal repairs and gear swaps, repeated world entries, truly unreadable gear,
secure clicks, pixels, combat taint and frame time. Focused timing/event
fixture and full 112-test/757-Lua desktop suite pass.
[Evidence](CHAT_CHARACTER_DURABILITY.md).

31 October secret-channel fallback: verify nameplate channels with secret or
missing spell IDs keep default appearance, while readable magic keeps its
school theme. Explicit ID selection passes a baseline-rejecting 56-check
fixture. Native Retail/Forever combat, pixel and taint checks pending.
[Evidence](SECRET_CHANNEL_FALLBACK.md).

31 October nameplate cast backdrop: artwork now uses a plate-level host below
Blizzard cast/health chrome. A baseline-rejecting layer test and the full
112-test/757-Lua desktop suite pass. Native pixels/taint/performance pending.
[Evidence](NAMEPLATE_BACKDROP_LAYER.md).

31 October chat character durability: verify `100%` under the button on
fully repaired gear, lower percentages after damage, and hidden text when
there is no readable durability. Focused state checks and full 112-test/
757-Lua desktop validation pass; native pixel, equipment-change, secure
input, taint and frame-time checks remain pending.
[Evidence](CHAT_CHARACTER_DURABILITY.md).

31 October combat grid conjured-item usability: verify gem and healthstone
tint in native alive/dead/ghost, full-resource, cooldown and empty/replenished
states alongside other combat items. The loaded-paint fixture passes 14 checks;
full desktop validation passes 111 tests/756 Lua files. Native clicks, taint,
pixels and matched frame time remain pending.
[Evidence](COMBAT_GRID_CONJURED_USABILITY.md).

31 October cast fill/tip correction: shared renderer now parents school fill
to the actual progress bar, hides/restores Blizzard's underlying fill and
tints/restores the native tip Spark. The focused test rejects the published
source; full 110-test/755-syntax desktop suite passes. Native acceptance is
pending. [Evidence](CAST_SCHOOL_FILL_TIP_FIX.md).

31 October Blizzard nameplate cast school themes: same Flux school renderer as
target/focus over Blizzard's own status bar, with a default-on option and
secret-value fallback. The 48-check nameplate model and full 110-test/755-Lua
desktop suite pass; native combat/pixels/performance pending.
[Evidence](NAMEPLATE_CASTBAR_SCHOOLS.md).

30 October MicroMenu nil-center correction: reparent selected and unused
native children before their Show/Hide callbacks can invoke Blizzard
`GetEdgeButton`. [17-micromenu.md](17-micromenu.md) records the regression,
exact source identity and native limits. Full desktop suite: 109 tests /
753 syntax files; post-fix native checks pending.

30 October delayed loot correction: pending source sessions retain the
opening cursor through lagged item/currency/money chat and reconcile late
slot/chat reports. [LOOT_CURSOR.md](LOOT_CURSOR.md) records the fixture,
source hashes and native limits. Full desktop suite: 108 scripts / 752 syntax;
native five-client placement and performance pending.

30 October cursor-position correction: each loot window now retains its
opening cursor origin for all rows, including delayed chat. The two-batch
fixture and exact hashes are in [LOOT_CURSOR.md](LOOT_CURSOR.md). Full desktop
suite: 108 scripts / 752 syntax; native five-client pixels/timing pending.


30 October loot-source correction: cursor alerts now exclude crafted and
pushed gains and gate ordinary self-loot/currency chat to a loot window.
[LOOT_CURSOR.md](LOOT_CURSOR.md) records the focused fixture, exact source
identity and native checks. Full desktop suite: 108 scripts / 752 syntax.


30 October FluxLoot callback correction: user native stack at line 402,
signature-aware regression and exact candidate hashes are in
[LOOT_CURSOR.md](LOOT_CURSOR.md). Focused and full desktop validation pass;
native post-fix login/profile acceptance remains pending.


30 October cursor money alert follow-up: gold/silver/copper symbols, white
numbers and threshold-selected icons are documented in
[LOOT_CURSOR.md](LOOT_CURSOR.md). The focused desktop fixture and full
107-script/751-syntax runner pass; native five-client acceptance remains
pending.


30 October cursor loot: Tools → Loot controls and slot/chat alerts are
documented in [LOOT_CURSOR.md](LOOT_CURSOR.md). Run `lua tests/loot_cursor.lua`
for the focused desktop event model and `python tests/run_validation.py --output
docs/validation/loot-cursor-full-2026-10-30.json` for the full desktop suite.
Native five-client acceptance remains pending.

Current Retail Sticky Targeting check (30 October): exercise the targeted
registered `deselectOnClick` setting route in a native background client when
available. Verify checkbox state, CVar readback, first-load/reload behavior,
manual Controls reset, taint and frame time. The 13 August historical source
informed this change; 76 desktop checks pass. [Evidence](RETAIL_CONTROLS_CAMERA_FIX.md).

Current Retail Controls priority (30 October): verify in a background native
session that `deselectOnClick=1` and camera factor 2.6 persist after the
settings-only retry, then check a second reload, manual Controls reset,
taint and frame time. The user's pre-fix readback was `1.900000 / nil / 0`;
the corrected desktop fixture passes 68 checks. No WoW process was visible
during this repair. [Evidence](RETAIL_CONTROLS_CAMERA_FIX.md).

Current Hearthstone hover follow-up (30 October): verify the selector tooltip
and owned-toy choice in a real Toy Box client. The native stack trace showed
`GetItemInfo` nil at hover; the focused fixture now covers that path with the
global unavailable and passes 19 checks. Native secure use, reload scope,
combat/taint, pixels and frame time remain pending.
[Evidence](HEARTH_CONFIG_TOY_COLLECTION.md).

Current Hearthstone correction (30 October): load the Toy Box on a real client
and verify the panel appears beside it. The editor now uses the core capability
available before its TOC entry; the previous desktop fixture missed that
order and was superseded by a 17-check regression. Then select an owned toy,
reload and confirm the grid button uses it. Native combat/taint, pixels and
frame time remain pending. [Evidence](HEARTH_CONFIG_TOY_COLLECTION.md).

Current Hearthstone follow-up (30 October): verify the Toy Box editor and
owned-toy choice on actual toy-capable clients after reload. Desktop checks
cover the missing journal-toggle capability, opener alternatives, visible
selector and saved item readback; they do not prove native secure item use,
combat/taint or frame time. [Evidence](HEARTH_CONFIG_TOY_COLLECTION.md).

Current binding priority (30 October): verify the one-call context-aware
transaction on Mariosuper (Era) and Pandasans (Retail) once their actual
processes/windows are visible without foreground control. Confirm keys,
reload persistence, no repeat setup, grid labels and frame time.
[Evidence](BINDING_ATOMIC_CONTEXT.md).

Current user priority (30 October): verify the version-6 native binding
transaction on actual clients, especially Retail's empty account-cache
migration and first-load reload persistence. The desktop
[evidence](BINDING_PERSISTENCE_REWRITE.md) cannot certify secure input,
disk persistence, hotkey labels, taint or frame time.

Current user priority (30 October): verify native no-replay on reload and
immediate first-account binding setup after the version-5 attempt gate.
Desktop [evidence](ACCOUNT_BINDINGS_ONCE.md) covers five client models; native
secure keys, saved-variable persistence and frame time remain pending.

Current user priority (30 October): verify account-only automatic keybindings
on native clients. One successful first-account setup must be followed by no
automatic full keyboard reset on character logins or Settings callbacks.
Desktop [evidence](ACCOUNT_BINDINGS_ONCE.md) cannot prove real input,
persistence, protected execution or frame time.

Current user priority (30 October): verify the corrected one-time binding
reset and its native frame time. A successfully saved active scope must never
reset on a later login; desktop tests cover the one-scan/eight-write frame
bound, while real latency, input and persistence still need client checks.
[Evidence](FULL_BINDING_RESET.md).

Current user priority (30 October): native verification of the new full
first-load binding reset on every client and active account/character binding
scope. The user explicitly requested clearing all keys before applying the
Flux template; [desktop evidence](FULL_BINDING_RESET.md) cannot prove actual
key presses, labels, persistence or protected execution.

Current user priority (30 October): finish native all-client checks for
[unit power visibility](UNIT_POWER_VISIBILITY.md) when background-safe access is
available. Verify health/power geometry, combat/taint and restricted values;
the 96-script/737-file desktop suite does not establish these native results.
Main is the current branch; older change-branch/hold instructions below are
historical and superseded by the 29 October user request.

Latest user priority: verify Retail teleport/portal count and interrupted-cast fix
after reload. [BUG-012/PERF-011](TELEPORT_CAST_WORK.md) passes 527 focused checks and
full 95-script / 736-file suite. Native latency/combat/input/pixels and non-travel
custom flyouts remain pending. Keep foreground PC use undisturbed. Older source/
publication/task statements below retain historical scope.

Read [contribution guidelines](../CONTRIBUTING.md), [status](STATUS.md),
[decisions](DECISIONS.md), [work log](WORK_LOG.md) and relevant requirements before
changing a subsystem. Continue in this existing addon and repository.

Objective tracker follow-up: the first-module gap correction now covers saved
native container callbacks on Retail and Forever and runs before the cached-height
sync return. Zero offsets restore after child resizing. The new regression passes
40 checks and the full report passes 90 scripts/731 syntax files. Native checks:
fully scroll up with Campaign plus Quests, remove/re-add Campaign, collapse sections,
resize while scrolled, toggle Questie, and enter/leave combat. Leave WoW in the
background; these live checks remain pending. [Behavior](18-minimap-and-trackers.md).


1. Inspect status/HEAD/main/remotes and preserve newer user edits. Use the current
   change branch; main remains `7436820453d2248c84c99fff71507553efc47c19`.
2. Keep skipping auction, guild-bank and void-storage callback audits. The current
   cached personal/warband count change does not authorize those callbacks.
3. Read [recovery](RECOVERY.md). Eleven verified external checkpoints retain source,
   history and private settings. Latest 12:35 UTC / 13:35 Copenhagen covers d3bce5b,
   1,234 actual files and 403 WTF files. Both clients were running: on-disk settings
   only, not quiescent in-memory state. Preserve a fresh checkpoint before another
   runtime batch if source/settings differ; retired originals stay outside AddOns.
4. Current runtime/test `013bf40db1d5b57c238ac3ac377e8ced98446fd1`, tree
   `4f0d827bb26bba3ee8b20e21de891596fad0e98b`. PERF-006 filters bag/cached-bank tier
   matches before live usability; quantities, live gates/protections/fallback remain.
   1,710 focused checks and full 89 scripts/730 syntax pass. Five alternating native
   Era getter pairs return identical results with lower CPU. Personal-bank native
   outputs are zero; positive/warband parity is desktop-only.
5. **Leave WoW in the background while the user uses the PC.** Do not activate it,
   take keyboard/mouse focus, or repeat the foreground controller without renewed
   coordination. Cleanup is complete: original three automation flags true and
   profiler=1 retained, temporary sampler/namespaces/exports cleared. Edit the normal
   addon folder; the user's existing sync delivers files. No new sync/deployment job.
6. The clean Era 1.15.9.70576 pilot reproduced a 333 ms UI interval across four opens
   and about 320 ms per target build. Getter CPU medians per five kinds fell from
   132.199 to 15.237 ms bags and 118.897 to 22.517 ms cached bank. Whole-vendor after
   remains pending. When foreground testing is convenient, use [exact procedure](TIER_COUNT_WORK.md):
   five matched alternating four-open/20-second windows, same NPC/profile/resolution/
   scale/inventory/addons, 30-second warm-up, separate cold and steady work, profile
   on/off with preference restored. Compare screenshots/input/taint and normal
   allowed transactions separately. Do not infer native FPS from getter CPU.
7. BUG-001 through BUG-008, PERF-005/006 and editorial cleanup retain their documented
   tested scope. Other classification, Already Known, reagent-name or layout work
   needs attribution before edits. Reservations are not native acknowledgement;
   unchanged-ID price/stock changes and delayed/rejected requests remain separate.
   Event mutation is latent with no production unsubscribe trigger; do not redesign
   the shared dispatcher speculatively.
8. Complete [client validation](CLIENT_VALIDATION.md) separately on available targets.
   Era gains only partial native count evidence; pixels, security/taint, unprofiled
   FPS, external providers and other clients remain pending. Desktop mocks do not
   certify real secret values or original Wrath 3.3.5.

Reproduction from the addon root:

```powershell
lua tests/tier_count_work.lua --source tests/fixtures/tier_count_match_before.txt --measure
lua tests/tier_count_work.lua
lua tests/idle_tiers.lua
lua tests/vendor_tier_work.lua
lua tests/vendor_slot_identity.lua
python tests/run_validation.py --output docs/validation/next-check.json
python -B docs/tools/build_reference.py
python -B docs/tools/validate_docs.py
```

Count measure mode exits zero with ten expected failures among 1,710 checks;
candidate passes all. Verify all current Lua hashes against
`docs/validation/tier-count-full-2026-10-29.json` before reusing the full result
(Lua/luac 5.4.6, Python 3.10.6). Some legacy tests need adjacent reference trees;
missing fixtures are not addon failures. Use --sync-docs only with a fresh full run.
Native probe/source hashes and samples are in the focused evidence; its local
candidate bodies are not a replacement for complete addon foreground acceptance.

Update status, decisions, work log, ledgers and these tasks before stopping. No
push/merge to main, settings reset, second addon, rename or release is authorized.

## Next steps after the Retail audit

Current runtime fixes: loot waiter reuse `6ac4389`, capture snapshot release
`3046478`; [evidence](RETAIL_PERFORMANCE_AUDIT.md). Actual current suite passes
92 scripts/733 syntax files including the preserved pending tracker correction.
Use validation/retail-lifecycle-full-2026-10-29.json for current Lua hashes.
Do not stage or overwrite that separate tracker work as part of another fix.

Finish native capture follow-up/cleanup, retaining original profiler=0 and background
PC use. Then prioritize nameplate add/remove/disabled work and assisted-action
same-fact paint traces; preserve timing. Stress options, map, inventory, bindings,
respec and unit/raid resources through real lifecycle cycles and long sessions.
Existing GUID freshness TTL is not an eviction policy; quantify older-client
inspection churn before a cache policy change. Mirror timer idempotence already
exists; no runtime fix needed there. Auction/guild-bank/void callbacks remain
excluded. No whole-addon leak-free/FPS/security certification is established.

```powershell
lua tests/loot_roll_lifecycle.lua
lua tests/perf_capture_retention.lua
lua tests/perf_capture.lua
python tests/run_validation.py --output docs/validation/next-check.json
```

Retail capture follow-up/cleanup is complete; original profile0 restored. Five
actual candidate reports and native endpoint limitations are retained in the audit.
Next prioritize nameplate/assistant work and real lifecycle/long-session stress.
Keep background PC use and preserve the pending tracker work.

## Chat offset/reload/tab follow-up complete

Current runtime7f13000 includes78fe4e7. Use validation/chat-column-alignment-full-2026-10-29.json
for all733 current Lua hashes;92 scripts pass. Social uses shared inset8, relative
tab height for late startup movement and primary dock geometry for every tab.
2,009 column checks cover five branches/both sides/scales and custom tab geometry.
Native Retail General/Global/Combat Log seven-selection coordinates match; untouched
reload inspected before chat input. [Evidence](CHAT_COLUMN_ALIGNMENT.md).

Keep other-client rendering, combat/Edit Mode and broader performance/lifecycle/
long-session acceptance pending. Current native diagnostics are cleaned up and
profiler0 restored. Preserve background PC use, main, deferred callbacks and the
separate uncommitted tracker correction.

## Next tasks after PERF-009

Read [original stage tracker](MODERNIZATION_PROGRESS.md) and root next-session
record. Runtime `efca305` and [full report](validation/nameplate-countdown-full-2026-10-29.json)
cover93 scripts/734 syntax files including preserved pending tracker work. Focused
countdown replay1160 checks, five desktop/native widget pairs; actual restricted
plate-aura/combat/native pixels remain pending. [Exact steps](NAMEPLATE_COUNTDOWN_WORK.md).

Native cleanup is complete: original profile0, diagnostic root nil and normal
candidate file loaded. Leave WoW open in the background. Next attribute assistant
same-fact paint/queries and stress remaining real lifecycle/private-cache churn.
Do not infer leaks/FPS from changed scenes or extend to excluded callbacks.

```powershell
lua tests/nameplate_countdown_work.lua --source tests/fixtures/nameplate_countdown_before.txt --measure
lua tests/nameplate_countdown_work.lua
python tests/run_validation.py --output docs/validation/next-check.json
```

Baseline measure exits0 with15 unmet work budgets; candidate must pass. Preserve
user tracker changes while staging shared/generated records.

## Next after action/aura batch

Current runtime `677d85c`; use validation/action-highlight-full-2026-10-29.json
for735 Lua hashes/94 passing scripts. [Audit/evidence](ACTION_AURA_WORK.md) and
[seven ownership groups](ACTION_AURA_AUDIT.csv). Keep unrelated pending tracker
source/test/docs uncommitted. Main and deferred callback domains remain protected.

Next attribute assisted-host icon/count/cooldown/usable work (Retail baseline
4.814ms/s inclusive) and repeated next-spell reads before sharing facts. Preserve
cadence/identity/animation/input and native aura ownership. Test actual enabled
highlight/combat/paging/modifiers/pet/stance/vehicle/input, dense/restricted aura
churn and long-session caches on exact builds. Do not treat one CPU block or stable
short geometry as FPS/leak-free certification.

Both clients stay open; sessions displace each other, so reconnect/select the named
characters serially after inspecting each window. No foreground takeover. Original
profile0 Retail/1 Era and prior diagnostic roots restored. Existing mirror remains
running unchanged; verify target hashes before reload, with only known test-file
copy if delivery lags. No new sync job or broad manual deployment.

```powershell
lua tests/assisted_highlight_work.lua --source tests/fixtures/assisted_highlight_before.txt --measure
lua tests/assisted_highlight_work.lua
lua Core/_tmp_playeraurassmoke.lua
python tests/run_validation.py --output docs/validation/next-check.json
```

Baseline measure reports20 unmet work budgets and exits0 intentionally; candidate
must pass. Source tokens/settings/features remain the implementation contract.

## Publication handoff

Main publication is now explicitly authorized by the user. Include the complete
addon and tested tracker correction (`73ca9d2`) with current generated records;
older instructions to keep that work uncommitted are superseded. Preserve the
existing development branch and history; no force push or separate release.
Use [publication validation](validation/github-publication-2026-10-29.json) for the
combined735-file/94-script corpus and [publication record](GITHUB_PUBLICATION.md)
for source/recovery scope. The next optimization/native acceptance tasks above
remain pending; uploading is not a claim that every scenario is certified.

## Main-only local snapshot instruction

The user's latest request supersedes earlier branch-retention/unpublished-work
instructions: work on main only and publish the actual current local files,
including the teleport fix and all tests/docs. The redundant branch was removed
locally/remotely; its commits are already in main. Preserve newer local changes,
existing history, native pending scope and ignored/private data. Use
validation/main-local-snapshot-2026-10-29.json for the current95-script/736-file
publication corpus. Do not create another branch unless the user asks later.
