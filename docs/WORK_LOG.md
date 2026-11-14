# Work log

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

14 November LHO actual producer audit reproduces two unresolved synthetic
counterexamples using installed Syndicator code: cold closed-bank completion5→0,
and an old cold-mail job overwriting newer inbox facts (including equal-cardinality
wrong IDs). Three baseline repeats/three isolation pairs per fault/three extra
controls;38checks/run. External41 files unchanged. No bank/mail remedy applied.
Native tri-state count/provenance and persisted handoff need proof; header counts
alone cannot validate mail identities. User requires native populated-mail timing
before a fallback-delay decision; the available empty mailbox cannot establish it.
[Causal evidence and pending decisions](validation/lag-hotspots-provider-counterexamples-2026-11-14.json).

14 November lag continuation: after the fresh 2,792-file source/history checkpoint and 375-script/1,063-syntax baseline gate, three commerce owners reduce recipe-scan allocations, select only relevant modern output aliases and reuse warm owned bag facts within a capacity call. Three paired source comparisons pass 770 focused checks/set and reject 13 compiled harmful controls. Affected installed checks pass 61 scripts with all 1,065 Lua hashes stable in that run; independent review reproduces 770 checks. Every profession native scan, craft invalidation and publication remains; aliases, partial/closed recipes, public overrides, cold bag retries and existing link return values remain. Desktop timings and allocation samples establish their modeled scope; no profession/vendor native CPU or FPS comparison is claimed. Keep the earlier full run historical until a new combined run seals current source.
[Source comparison and limits](validation/lag-hotspots-commerce-continuation-2026-11-14.json).

14 November LHO empty-mailbox native observation: user opened the mailbox;
Forever70938 reports inbox0, Flux mail0, Syndicator source, reliabletrue and no
pending native mail command. Three 1,000-call GetInboxNumItems trials take
0.0418/0.0405/0.0398ms. Same-session _FluxUI native profiler counters over12.922s
increase230 for >1ms and0 for >5/10/50/100/500/1000ms; nested counters are not summed.
This is an unpaired existing-city observation, not a before/after FPS result or
populated/cold-mail latency measurement. No mail/item operations, activation,
profiler preference changes or persistent probes. User requires in-game measurement
before accepting the stale-mail fallback delay; that decision remains pending.
[Exact scope and readouts](validation/lag-hotspots-empty-mailbox-2026-11-14.json).

14 November casting/inventory lag (LAG-HOTSPOTS-20261114; LHO-01–13):
pre-edit 367 scripts/1,055 syntax PASS with unchanged source; external 2,781-file
source/history checkpoint and 125 settings metadata entries, no private copy.
Eight measured slices now change eleven runtime owners: protected cast/VFX helpers,
same-call macro metadata, dirty-bank aggregation/publication retries, merged potion
needs, live mail capacity, bulk merchant queue retirement and hidden merchant paints.
Three pairs/slice; 46,925 focused checks/set; 71 compiled harmful controls rejected.
Final 375 scripts/1,063 syntax PASS; full source stable throughout. Craft/pending
integration adds 380 checks/120 scenarios. Independent reviews caught and fixed
two bank retry/reentry cases; native getters slowed the AH paint experiment, so
original UI bytes were restored. All 257 assets/XML/TOCs, 85 options/bindings,
7 defaults/settings owners and 5 license files unchanged; all 55 owned files match
across five installed copies read-only; external Syndicator's 41 files unchanged.
Forever70938 native watch:2 gaps52–55ms,0observedFluxcallbacks>10ms,0newLuaerrors;
not FPS attribution. After user reload and a specific foreground exception, food
rank4 starts/stops were submitted; Interrupted and eight Pumpernickel/count8 are
observed with cast cleared. No buying/selling/deletion, craft materials, focus
activation, profiler preferences, manual sync or publication. Other native timing,
provider-off/client/pixel/controller acceptance remains pending. Documentation validator PASS.
[Requirements, remaining acceptance and evidence](LAG_HOTSPOT_OPTIMIZATION.md).

14 November `AUCTION-PASSIVE-REFRESH-20261114` / AHR-105/106, build
`AH-restock-explicit-start-20261114-r27`: opening the Restock tab prepares missing
targets once. Filled known items/tiers are skipped. Bag, mail and profession
updates refresh counts without canceling a search, replacing upgrade choices or
restarting completed work. A user-started initial stock-loading wait can resume;
matching purchase receipts still prepare the next shortage. Buying and upgrading
retain their separate player choices. An actual setting edit can replan once.

Loot & Items → Restock now has independent AH upgrade prompt options: healing
and mana on by default, bandages off. Saved choices are per character. Turning
one off keeps its current-tier direct/crafting restock and rejects stale upgrade
actions. The compact native actions read Keep / Block, with full tooltip labels;
unchanged enabled states are not rewritten on passive refreshes.

The explicitly requested modern Scan all restock remains a full pricing action.
Old AH remains per-item scan/buy without Scan all. The latest opening-shortages
request supersedes earlier filled-tier discovery on opening, not manual scans.
76 affected scripts/82 syntax files PASS; 440 passive checks/20 client-provider
models; 3 matched baseline/candidate trials and 11 compiled harmful controls.
Other test observations remain historical; no whole-suite or meter test rerun.
All 5 installed copies match the 6 runtime files read-only. Verified external
checkpoint: 2780 source files/all-ref history and 129 settings metadata entries;
no private contents copied/restored. Main/.githooks and concurrent work retained.

Native flicker, text fit, controller, protected input/taint and performance remain
NOT RUN. No client input/reload, upgrade acceptance, purchase or profiler change.
Reload when ready. Meter work remains with its separate agent. [Evidence](validation/auction-passive-refresh-2026-11-14.json).

14 November `POTION-MINIMUM-RESTORE-20261114` / AHR-104: healing and mana
potion tiers use their minimum restore across the whole addon. A larger maximum
cannot promote a lower-floor potion: 500–1500 loses to 600–800; 650–700 can upgrade.
The shared classifier supplies minimum health/mana/effective values; maximum
metadata remains available. Food, water and bandage ranking is preserved.

Potion buttons, Best ranking, cached recipes, vendors, AH choices and automatic
junk use the same floor. Old saved potion refs/vendor observations and restock
thresholds migrate only after verified classification. Unknown old facts remain
saved but cannot compete/promote as verified minima. Potion-only cached effect
text/axes preserve floors across tooltip gaps. Targets/price limits/manual Junk
priority and explicit AH choice/purchase presses remain under existing owners.

74 affected scripts and 79 syntax files PASS; 510 checks/50 minimum-ranking models,
388/20 restore checks; 10 compiled harmful controls rejected; 3 matched trials.
Global verification is explicitly incremental: other test observations remain
historical, not a whole-suite rerun. Meters are excluded and left to their agent.
Five installed copies match the 5 runtime files read-only. External checkpoint 2778
source/history files and 129 accessible settings metadata verified; no private
contents copied/restored. Main/.githooks/newer work retained; no publication.

Minimum-ranking native acceptance is NOT RUN. Existing background test preference
continues; no client input/reload, purchase, upgrade acceptance or profiler change.
Reload when ready to apply the new shared logic. [Evidence](validation/potion-minimum-restore-2026-11-14.json).

Full validation: 365 scripts and 1053 Lua syntax files PASS; complete current Lua manifest verified.

14 November `METER-CONTROL-RECOVERY-20261114`: audited the supplied Damage Taken /
Dispels placeholder screenshot and lost Current defaults. The current meter files
match the 14 November recovery checkpoint; 13 November's explicit selection
withdrawal is the cause. Restored the narrow selection functions and setup action
without replacing whole files or losing tooltip/header/newer work.

Fresh Gethe Retail/Forever pins remain 297d7aaaa736f346b3e036f38ee088eaf7f8c07f /
bebcb6bf309cf41b41bd74f8ca651e6a105b2676. Native-generated caches and original
proxy Pick preserve native data/responders; provenance checks reject modified
fields/methods and misleading New Window labels. No private setters/menu cache
writes/history reset. 476 control checks and both exact native menu replays,
12 focused scripts, 3 matched baseline-fail/candidate-pass pairs and 7 compiled
harmful controls PASS. Scope is desktop behavior/provenance, not native VM/FPS.

Verified external checkpoint `meter-recovery/checkpoint-20261114T081300Z`:
2771 source files/all-ref history, main/.githooks, 53 settings metadata entries;
no private settings contents copied/restored. No client control/input/clipboard,
profiler write, manual sync or publication. Existing user-native test route:
reload outside combat, choose Dispels/Interrupts layouts, verify Current/two fights
and later manual Overall/history. Native/controller/taint/pixels/CPU/FPS NOT RUN.
[Requirements](METER_STANDALONE.md#meter-control-recovery--14-november-2026);
[exact evidence](validation/meter-control-recovery-2026-11-14.json).

14 November `AUCTION-COMPACT-UPGRADES-20261114` (AHR-102/103), build
`AH-restock-compact-upgrades-20261114-r26`: upgrade cards now occupy 44px instead
of 174px. A 24px candidate icon sits beside Upgrade; Keep and Blacklist form the
second action row. Candidate name, restore comparison, unit price and current
funds remain in the native tooltip. Each candidate still needs its own choice.

Cell order is healing potion, mana potion, bandage, spell reagents, consumable
configuration, then other items. Preset/source metadata drives ordering; names
and item IDs break ties only within each group. Merged manual/preset targets and
virtual proposals without a saved tier retain preset priority. Proposals stay
bound to row identity while sorting. No new API, saved-root/default change or
automatic purchase was introduced; old-AH per-item behavior remains.

Inline 1220/20, confirmation 672/20 and geometry 780/20 checks PASS; 8 compiled harmful
controls rejected with 3 matched baseline/candidate trials per regression.
All auction scripts and 1053 syntax files PASS; owned source hashes and recovered
TOC retained. The wider run has a separate meter failure; the user assigned meter
work to another agent. No further meter inspection, testing or changes in this task.
Verified external checkpoint 2776 files/history and 129 settings metadata; no private
values copied. Four runtime files plus two relevant tests changed. Five installed
copies match read-only. Native capture found the user crafting with AH closed;
no input/reload was sent. Native compact pixels/fonts/controller/other-client
acceptance and CPU/FPS remain pending. [Evidence](validation/auction-compact-upgrades-2026-11-14.json).

14 November `AUCTION-INLINE-UPGRADES-20261114` / AHR-96–101 is current,
build `AH-restock-inline-upgrades-20261114-r25`. Healing, mana and bandage
upgrade choices are independent controls on their cells; no modal prompt.
Accepting changes the saved tier only. Three default-on global settings keep
weaker items until a better usable tier is carried; explicit manual Junk wins.
The shared item blacklist and default-on `discolored` healing-name substring
toggle affect Best, the healing button, AH planning and junk replacement checks.
No item-ID/full-name tier catalogue was added. Buying still needs a player press.

`FLUX-SOURCE-RECOVERY-20261114` recovered an unrequested source replacement
around 08:32 Copenhagen: 79 whole Lua files, lost fixes in 4 shared files and 45
TOC load entries. This restores chat anchor ownership, options Skin loading,
meter/threat presentation and other verified fixes while retaining the new work.
Writer remains unknown; the user reports no other writer known. Existing outward
sync is not evidence of the cause. No checkout/reset or saved settings restore.

Final 365 scripts/1053 syntax files PASS. Inline 880/20 profiles, shared button
exclusions 240/10 profiles and global junk 1230/30 scenarios PASS; 22 compiled
harmful changes rejected. Chat's reported source fails in 3 repeated comparisons;
recovered source passes. All 91 checked files match across five installations.
Two external source/history checkpoints 2772/2773 files and 129 settings metadata
each verified; private values/archives remain outside AddOns. Main/.githooks and
existing dirty work retained; no commit/push.

Forever background observation after a reload shows the meter skin and Threat
pane restored. A chat diagnostic produced no result while the player moved and
is excluded from acceptance; input tests stopped. Options opening, new inline
native interactions, accepted upgrades, real buys, controller, other clients,
taint and CPU/FPS remain pending. No agent purchase/upgrade/reload was sent.
See [inline evidence](validation/auction-inline-upgrades-2026-11-14.json) and
[source recovery](validation/flux-source-recovery-2026-11-14.json).
This supersedes the older r24 modal and explicit automatic-Junk description below.

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

13 November side-grid border/layering (MINIMAP-SIDE-BORDER-20261113;
REQ-MBL-24/25): the screenshot's clarified defect was minimap cluster/clock
layering over buttons. The screen-side root/gate/native-template widgets now use
HIGH; embedded mode restores MEDIUM. Actual FluxBorder is applied once to a
mouse-disabled decorative host inside the existing secure visibility gate.
Border/backdrop inherit hover and secure combat hiding, scale and inactive/empty
grid visibility. The backdrop stays above native chrome but below buttons, with
border below existing flyout arrows. Native map/clock frames and handlers, grid
geometry, saved settings/actions and dynamic minimum behavior are preserved.
2794 actual border/arrow checks,30 atlas/legacy-scale cases,seven harmful controls,
three paired layer trials and nine existing integration scripts PASS. Broad
snapshot:341 pass/four unrelated auction failures;1033 syntax PASS. Concurrent
auction work is preserved; the snapshot is not a claim about later global files.
External2724-file source/history checkpoint and99 settings metadata verified;
private values not copied. No new poll/event/driver;one lazy host plus the shared
border's two frames/normal textures. Native visual/input/taint/controller/CPU/FPS
remain NOT RUN; reload out of combat and use the retained user-native route.
No foreground/input, settings/profiler write, manual sync or publication.
[Requirements and acceptance](MINIMAP_EXTRA_LAYOUT.md#screen-side-border-and-minimap-clock-layering);
[evidence](validation/minimap-side-border-2026-11-13.json).

13 November action/badge/extra counts (ACTION-COUNT-REFRESH-20261113; ACR-01–05): normal bars now receive light bag-count publications; validated spell-use events refresh count/tint through existing coalesced lanes. Count-held form settle also restores badge tint. Two watch owners; no new frame/timer/poll/hook/scan or secure action change. Read-only Gethe five-client pins and Bartender4/LibActionButton/installed ButtonForge comparison retained. 666 focused checks across five client models/both providers; three exact checkpoint pairs reject224 old failures; seven harmful controls rejected. Full343scripts/1031syntax PASS with current complete manifest. External2712-file source/history checkpoint and47 settings metadata verified; private values not copied. Concurrent auction/minimap work preserved. Native event delivery/operation/taint/pixels/controller/CPU/FPS NOT RUN; existing user-native route retained. No foreground/input, settings/profiler writes, manual sync or publication.
[Requirements, comparison and native steps](ACTION_COUNT_REFRESH.md); [evidence](validation/action-count-refresh-2026-11-13.json).

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

13 November dynamic minimap buttons (MINIMAP-DYNAMIC-20261113; REQ-MBL-22/23)
supersedes the earlier growth/movement choices: Dynamic button count keeps the
configured count as a saved minimum. With fifteen full slots, carrying offers
sixteen; cancel/drop elsewhere returns to fifteen; filling the preview keeps
sixteen. Deleting assignments compacts toward the minimum, including interior
holes, without renumbering saved indices. Both layouts share this behavior;
hide-empty may still hide screen-side minimum placeholders. The independent
movement control is removed: Always shown automatically reserves room for
minimap/Questie/objectives/auras; mouseover overlays their normal dock. The old
sideMoveFrames value stays saved but is ignored. Cursor observation also covers
active embedded dynamic layouts; no new frame/timer/poll/native API is added.
10480 dynamic checks/30 layout-scale cases/six harmful controls, paired baseline
and candidate (three trials per layout), nine existing integration scripts and
full 342 scripts/1030 syntax PASS for the captured snapshot. Later concurrent
action-count edits stale global evidence; task-owned source identities match.
External 2706-file source/history checkpoint
and 99 settings metadata verified; private values not copied. Native input/taint/
pixels/persistence/controller/CPU/FPS remain NOT RUN. No foreground/input,
settings/profiler write, manual sync or publication. Reload outside combat and
follow the retained user-managed native reproduction route.
[Current requirements and acceptance](MINIMAP_EXTRA_LAYOUT.md#dynamic-minimum-and-automatic-frame-movement);
[evidence](validation/minimap-dynamic-2026-11-13.json).

13 November minimap extra-button visibility (MINIMAP-VISIBILITY-20261113;
REQ-MBL-18–21): optional screen-side empty-slot filtering preserves numbered
assignments and reveals one drop target while carrying an action. Optional shared
auto-growth adds one slot after a full successful drop, up to 120. Movement can
be disabled for minimap/Questie/objectives/auras. Always shown or mouseover mode
combines with the existing secure combat-hide toggle; hover freezes during
combat and embedded buttons ignore side-only visibility/empty filtering. Defaults
retain the current layout. One 0.1s hover ticker runs only in active side mouseover
mode and stops in combat/embedded/disabled/always mode; cursor observation is
scoped to active side hide-empty mode. No input-capturing frame is added.
4540 focused checks/15 scale cases/5 harmful controls and eight existing
layout/options/action/ownership scripts PASS. Full 341 scripts/1029 syntax PASS;
two transient auction failures during concurrent edits passed on the full rerun.
Verified external 2697-file source/history checkpoint and 99 settings metadata;
no private settings copy, foreground/input, settings/profiler write, manual sync
or publication. Native input/taint/pixels/controller/persistence/CPU/FPS remain
NOT RUN; reload out of combat and follow the retained user-managed reproduction.
[Requirements and acceptance](MINIMAP_EXTRA_LAYOUT.md#empty-slots-automatic-growth-and-optional-overlay-visibility);
[evidence](validation/minimap-visibility-2026-11-13.json).

13 November mailbox restock tooltip (MAIL-RESTOCK-TOOLTIP-20261113; AHR-65):
Restock and Auto help now clear/add one wrapped white line instead of passing
boolean true in SetText's numeric alpha slot. Owner/anchor/localized help and
hover/leave behavior are preserved; no settings or input actions change.
Strict native-argument hover regressions fail before the fix and pass after it:
3160 mail checks/20 profiles,21 Select,18 OpenAll,880 lifecycle,654 follow-up and
300 workflow checks PASS; full338scripts/1026syntax PASS with current manifest
verified. Restoring the bad call fails the
intended alpha assertion. External2695-file source/history checkpoint and95
settings metadata verified; private settings not copied. No foreground/input,
settings/profiler writes, manual sync or publication. Native hover retest pending.
[Fix and acceptance](AUCTION_RESTOCK.md#mailbox-tooltip-argument-correction);
[evidence](validation/mail-restock-tooltip-2026-11-13.json).

13 November tooltip/meter errors (SECRET-UI-20261113): Flux unit/pet/raid/preview
hovers now use one private reusable native-template tooltip; shared GameTooltip
state and health mixin methods stay native. Meter menus/configuration remain
with actual Blizzard dropdown clicks; addon generation/open/pick removed. Saved
layout requests/history/segments retained. Automatic native type/window/Current
application is intentionally pending a verified clean route. Meter106checks,
three baseline pairs/three harmful controls;tooltip three baseline pairs/two
harmful controls;337 scripts/1025 Lua syntax files PASS.
External2690-file source/history checkpoint and127 settings metadata verified;
36 pinned source records. Reload needed to clear previously tainted objects.
Native secret/taint/pixels/controller/CPU/FPS NOT RUN; user retest retained. No
client control, settings/profiler writes, manual sync or publication.
[Requirements, sources and acceptance](SECRET_TOOLTIP_METER_ERRORS.md).

13 November integrated restock workflow (AUCTION-WORKFLOW-20261113; AHR-57–64)
implements shortage-only scanning, compact scrolling cells/coin price editing,
and temporary recipe targets through normal vendor/bank owners. Mailbox Restock
and saved Auto collect acknowledged matching items through Postal's space/speed/
command gates. Complete empty native inbox proof clears private pending, saved
collection job and Collect restock mail HUD. Partial loaded inboxes collect
visible matches while keeping inaccessible receipts. Native failure/index shifts
cannot claim delivery; inbox removal and delayed bag arrivals credit once.
Saved recipes/source plans survive reload; shared bank/vendor-owned inputs,
physical charges, direct targets and recipe budgets remain protected. Manual clear
preserves real mail/permanent targets and rejects transactions/commodity quotes.
Current focused40scripts, owned syntax and26 harmful controls PASS with no restock
source drift. Initial full336scripts/1024syntax PASS; later shared-tree sweeps
changed during unrelated Bars/meter/raid/unit work, which is preserved. Carry
that global validation separately; do not claim current whole-tree acceptance.
Latest combined sweep334/336: unrelated Bars smoke/contract failures. Docs checker
reports7 stale unrelated generated-source/view entries after concurrent edits.
Refresh global validation once that work settles; scoped restock40 remains PASS.
External2684-file source/history checkpoint and95 settings metadata verified;
private settings not copied. Existing implementation/user-native choices retained.
Native operation, pixels/controller, delivery, taint/CPU/FPS remain NOT RUN on all
five clients. Read-only installed-file checks find all15 changed runtime files
matching Forever/MoP/Era; no manual synchronization was performed. No client focus/
input, settings/profiler writes or publication.
[Behavior](AUCTION_RESTOCK.md#integrated-restock-workflow-13-november-2026);
[evidence](validation/auction-workflow-2026-11-13.json).

13 November Blizzard party dispel setting (PARTY-BLIZZARD-DISPEL-20261113): both
party styles and their previews honor Blizzard's dispellable-only checkbox through
a read-only per-frame predicate, retaining Flux's existing strict option and raid
scope. Existing CVar events refresh visible party auras, including combat; hidden
owners stay retired. 418 focused checks and the full 338-script/1,026-Lua-syntax
run PASS; the complete current Lua manifest and documentation validate. External 2,694-file source/history checkpoint and 183 settings
metadata entries verified. Native pixels/combat/taint/controller/CPU/FPS NOT RUN;
existing user retest retained. No client control or settings/profiler writes.
[Behavior and native checks](PARTY_DEBUFF_VISIBILITY.md#blizzards-dispellable-only-checkbox--13-november-2026).

13 November vendor catalogue and AH discounts (AUCTION-VENDOR-ROUTES-20261113;
AHR-52–56): the user accepted a bundled catalogue combined with learned vendor
data, without item-name exceptions. All five selected client types have their
own source profile. Across seven retained profiles:15,327 stock/15,310 prices;
Retail3710/3693,Forever849,MoP3005,Era862,TBC1708. Only selected maps allocate.
All11,617 legacy raw prices/counts match their client build; Retail3710 stock
records derive from pinned current world-vendor/condition data plus ItemSparse.
MIT/GPL notices, compact public inputs and reproducible generator are retained.
Learned stock/prices override catalogue assumptions. Unlimited goods stay hidden
unless fresh usable AH unit prices are strictly lower; equal/dearer/owned/stale/
historical offers cannot authorize buying. Known stock without price stays out.
Repair/sell/manual-only configured visits learn through the existing paced index.
Every recipe input is priced; actual whole-stack invoices decide vendor vs AH,
and stable per-plan routes/prices preserve mixed-source quantities and budgets.
Physical-unit bundle normalization, exact fractions, invoices and affordability
avoid rounding ties/underbuys; vendor-only temporary targets never leak into AH.
Pending-only mail/vendor/craft HUD, combat hiding, saved closed-profession recipes,
charges, source ownership and one action per press remain. Full332scripts/1019
syntax PASS;complete current Lua manifest verified. Focused30990catalog/1170price/
1130queue/600route/415learning checks and16 harmful controls PASS. External2670-file
source/history checkpoint and95currently present settings metadata verified;
private settings not copied. Native buying/crafting/discounts/access/HUD/controller/
delivery/taint/CPU/FPS remain NOT RUN. Existing direct implementation/user-native
choices retained. No client focus/input,settings/profiler writes,sync or publication.
[Behavior](AUCTION_RESTOCK.md#vendor-catalogue-observations-and-auction-discounts);
[evidence](validation/auction-vendor-routes-2026-11-13.json).

13 November restock follow-up (AUCTION-FOLLOWUP-20261113;AHR-46–51): one ordinary
HUD button beside the extra-action area follows acknowledged restock purchases
through matching mail, missing vendor materials and exact recipe batches. Jobs
survive reload, hide in combat and remove demand subscriptions when complete.
Each action requires a press; callbacks only prepare state. Current vendor
identity/price/wallet and exact live craft output/reagents/allocation are checked;
shared direct targets and partial charged copies stay protected. Authoritative
owned-take proof handles net physicalbags1→1 after an old last charge is used.
Closed/wrong profession native data can no longer override complete saved learned
recipes for cost comparison; exact execution still requires live proof.
854state/1692driver/209UI/848charactercache/824crafting checks PASS;fiveclient
models with optional providers. Full327scripts/1012syntax PASS with current
complete Lua manifest verified. External2663-file source/history checkpoint,
103settings metadata entries and26pinned profession blobs verified. No newtimer/
poller/nativebinding;one lazy ordinary button. Native permission,placement,
gamepad,delivery,taint/FPS remain NOT RUN;Forever directopening is unverified.
Existing implementdirect/user-native choices remain;no foreground/input,
private settings/profiler writes,manualsync,commit or publication.
[Behavior](AUCTION_RESTOCK.md#follow-up-button-and-closed-profession-recipes);
[evidence](validation/auction-followup-2026-11-13.json).

13 November auction purchase/charges (AUCTION-PURCHASE-CHARGES-20261113;AHR-41–45):
an unmatched item-completion event no longer turns potion1 into extra cloth38.
Live commodity shortages rebuild before quoting (38→2 even with excess enabled).
Selected price-editor cells have a thick gold outline and warm fill. Charge
targets reuse Registry capacity:9uses/5per item buys2physical=10uses; recipe
ingredients/prices remain physical. New reservation itemCount/unitScale facts
reconcile delivery and target/material role changes without rebasing active
transaction units; legacy records retain their fallback. Shared direct/craft
invoices charge only recipe share to the crafting budget; surplus stays included.
14,292 charge checks;400 full purchase-flow checks;743 receipt checks PASS across
five client models/optional providers. Seven harmful controls rejected; full
324scripts/1,006syntax PASS and complete current source manifest verified.
Seven existing runtime owners;no new event/timer/hook/poller/interactive frame.
External2,654-file source/history checkpoint and103settings metadata verified.
Four concurrent minimap/options changes preserved. Native purchase/charge/mail/
controller/pixel/taint/FPS checks remain pending; earlier Forever BLOCKED is not
certified fixed. Existing wrong predictions require one normal mailbox refresh;
no Clear pending or cache pruning. No foreground/input/settings/profiler writes,
manual sync,commit or publication. Build AH-purchase-charges-20261113-r8.
[Behavior](AUCTION_RESTOCK.md#purchase-identity-selection-and-charged-items);
[evidence](validation/auction-purchase-charges-2026-11-13.json).

13 November combat-hide scope (MINIMAP-SIDE-COMBAT-20261113;REQ-MBL-17): the setting
stays visible while embedded and applies only to normal-map screen-side buttons.
Embedding removes the existing combat driver; embedded grid remains visible in
combat. Saved hideInCombat persists and resumes on returning to the side layout.
UI label/help clarify that scope; capability gating and deferred protected layout
remain. Two runtime owners;no new frame,event,timer,hook,poll or native API.
50,034 grid/113 map/2,287 aura/168 flyout/6,407 options checks PASS;three matched
runs reject exact baseline and3harmful controls. Full snapshot 324 scripts/1,006
syntax PASS;task files remain current. Concurrent later auction edits are preserved;
global source freshness remains pending for that unrelated work. External
2,652-file source/history checkpoint and103settings metadata verified. Native
pixels/input/controller/persistence/taint/FPS NOT RUN;user-native route retained.
No client control,private settings/profiler writes,sync,commit or publication.
[Requirement](MINIMAP_EXTRA_LAYOUT.md#combat-hiding-applies-only-to-the-screen-side-grid); [evidence](validation/minimap-side-combat-2026-11-13.json).


13 November side-grid scale normalization (MINIMAP-SCALE-BASIS-20261113;REQ-MBL-16):
new displayed 100% is the previous 85% size and remains the default. The slider is
10–200%, effective frame scale0.085–1.7. Legacy explicit scales convert by /0.85
without rounding or rewriting records; new choices mark version2 to prevent repeat
conversion. Old values beyond the new ceiling are capped by new200%;raw data stays.
Automatic columns, zero padding, shared actions, aura/flyout geometry and combat
queues retained. Two runtime owners; no new frame/event/timer/hook/poll/native API.
50,007 grid checks;113 map/2,287 aura/168 flyout/6,397 options checks PASS. Three
actual checkpoint comparisons preserve9,408 geometry fields/run for old25–170 and
new100=old85;four harmful controls rejected. Full322scripts/1,004syntax PASS and
current manifest verified. External2,644-file source/history checkpoint and103
settings metadata entries verified;no private contents copied. Native pixels,
input/controller/persistence/taint/FPS remain NOT RUN;existing user-native route
retained. No client control,settings/profiler file write,sync,commit or publication.
[Current requirement](MINIMAP_EXTRA_LAYOUT.md#scale-normalization-100-equals-the-previous-85); [evidence](validation/minimap-scale-basis-2026-11-13.json).


13 November automatic minimap grids (MINIMAP-AUTO-LAYOUT-20261113;REQ-MBL-12–15):
both layouts now choose columns and largest fitted button size from count/space.
Embedded minimap size is automatic; embedded columns/map-size and side-column
controls removed. Screen-side whole-grid scale remains 25–200%, default100%; every scale refits
above Flux Window. User screenshot gap follow-up removes container/screen/start/
window padding and fractional-row slack. Completed side columns touch the window;
embedded buttons touch the map. Map/tracker/aura reservation follows scaled width. Downward side
column order, shared numbered actions, widget reuse, hidden-tab/window state,
flyouts and combat deferral retained. Retired saved keys preserved but ignored;
sideScale preserved and extended. Three runtime owners; no new frame,event,timer,
ticker,hook,polling or native API.48,866grid/113map/2,287aura/168flyout checks;6,397
options-navigation checks;three matched pairs/scenario;11 external and4 map harmful
controls PASS. Full322scripts/1,004syntax PASS,current complete manifest verified.
Fresh external2,638-file source/history checkpoint and103settings metadata verified.
Existing dated Gethe pins/direct implementation/user-native route retained;native
pixels/input/taint/controller/persistence/FPS NOT RUN. No client control,private
settings/profiler write,manual sync,commit or publication.
[Current requirements](MINIMAP_EXTRA_LAYOUT.md#current-behavior-automatic-grids-and-screen-side-grid-scale); [evidence](validation/minimap-auto-layout-2026-11-13.json).


13 November screen-side resize/aura follow-up (MINIMAP-SIDE-AURA-20261113;
REQ-MBL-10–11): the existing 25–100% button-size slider now scales after height
fitting, so crowded 120-slot layouts respond at 50%/25%. Defaults, shared actions,
column order/bounds and saved setting identities stay intact. Beside-map buttons
now reserve the same left offset for native BuffFrame/DebuffFrame. Existing aura
placement runs from shared strip layout before the hidden branch, restoring old
positions for below/off/embedded states. Native aura content/style/input remains
Blizzard-owned; combat/Edit Mode guards retained. Two runtime owners; no new frame,
event, timer, ticker, hook or polling. 3,415 resize +1,855 aura checks, three matched
pairs per scenario and five harmful controls PASS; full 322 scripts/1,004 syntax
PASS with the complete current Lua manifest verified. Documentation validator PASS.
23 narrow Gethe records/21 Git blobs verified at retained source pins. Fresh
external 2,630-file/source-history checkpoint and 69 settings metadata entries
verified; no private contents copied. Direct implementation/user-native route
retained; native pixels/input/controller/persistence/taint/FPS NOT RUN. No client
control, settings/profiler write, manual sync, commit or publication.
[Requirements and native checks](MINIMAP_EXTRA_LAYOUT.md#follow-up-screen-side-resizing-and-aura-placement); [evidence](validation/minimap-side-aura-2026-11-13.json).


13 November trinket visual recovery (TRINKET-DARKENING-20261113; TD-01–04):
held presses restore the newest public usability color; empty/re-equipped faces
invalidate stale tint; equipped cooldown refreshes share slot data and one paint
cache. Passive trinkets remain dim; real cooldowns stay visible. Two runtime owners,
no new frame/event/timer/hook/poll. 245 integrated checks across five models;
exact checkpoint fails 55 checks; five regressions rejected. Existing 10/1,563 focused checks
and 321 scripts/1,003 syntax checks PASS with documented final test refresh. Verified
external source/history checkpoint (2,627 files) and seven Retail settings metadata entries;
15 fresh source records. Native pixels/input/controller/taint/FPS/memory NOT RUN;
user-native reproduction/direct implementation retained. No client control,
private settings/profiler write, sync, commit or publication.
[Task evidence and native checks](TRINKET_EQUIPPED_USABILITY.md#13-november-follow-up-intermittent-dark-faces-and-cooldown-overlays).

13 November Syndicator continuity (SYNDICATOR-SYNC-20261113; SYN-SYNC-01-05):
while delegated, FluxUI saves Syndicator's live v2 root by reference, including
alts/deletions. Next standalone startup imports detached facts once; later reloads
retain standalone changes. Exact three-way field/container comparisons update
unchanged stale external data; independent external edits/deletions and current
native cash/tokens win. No scan timestamps are fabricated. Dense slots, offsets,
capacities and list/auction metadata retained; no phantom bank tabs.
Transition-only notifications refresh views/search without alt live-player changes;
guild/void callbacks unchanged. No new frame/event/timer/subscription/poll; existing
scanner records capacity without extra native queries. 309 focused checks and three
harmful controls PASS across five desktop models; full snapshot320 scripts/1002
syntax PASS, task sources still match. A new concurrent trinket recovery test after
suite enumeration now passes200 checks after its separate source edits; unrelated
work preserved and whole-workspace freshness remains pending. External2612-file/source-history checkpoint and58
settings metadata entries verified; Syndicator290 read-only reference, ARR preserved.
Native persistence/Baganator pixels/taint/CPU/FPS pending; existing user reproduction
route retained. No client input/focus, private settings/profiler write, manual
installation sync, commit or publication.
[Requirements and native checks](SYNDICATOR_SYNC.md); [evidence](validation/syndicator-sync-2026-11-13.json).

13 November saved character recipes (CHARACTER-RECIPES-20261113; CRP-01–06): existing
profession SavedVariables now retain complete learned material/output/yield/slot
facts for AH and future shared consumers. Filtered and partial scans preserve
known facts; explicit unlearn removes them; unknown learned state and NPC/legacy
linked knowledge are rejected. Output-based per-character queries deduplicate
modern aliases. Proven deterministic recipes work after closing/reloading the
profession; uncertain grades still require native operation proof. Finished-item
caps include crafting/vendor acquisition cost;0 stays unlimited. Selected missing
vendor inputs create temporary per-character targets in the ordinary vendor list.
They sum shared requirements, subtract bags/mail once, survive the vendor trip
and reload, and retire on completion/invalidation without changing permanent
targets. Live vendor price ceilings protect the plan; permanent base targets
still buy independently. Pure temporary rows are read-only; no new controls.
704 new recipe checks;20 models;17 harmful controls;320 scripts/1002 syntax PASS at captured run;17,229 combined auction/recipe checks. Five repeated
work models:4→2 schematic reads,4→2 duplicate-free catalogue rows,0→1 usable
closed-profession AH variants. These are work models, not native time/FPS.
Scoped guard:5 existing runtime files and1 new test;2,609-file external checkpoint
and47 settings metadata entries verified. Concurrent unrelated workspace edits
are retained and listed separately; captured full-run scope is explicit.
Open each relevant profession once after updating to populate the new facts.
Current native capture/reload/vendor/coexistence/controller/taint acceptance and
the prior Forever purchase BLOCKED resolution remain pending. No client input,
private settings/profiler write, manual sync, commit or publication.
Global documentation validation remains pending solely for concurrent
Syndicator sync source/evidence edits; owned recipe/restock hashes remain verified.
[Behavior/API](CHARACTER_RECIPES.md);[evidence](validation/character-recipes-2026-11-13.json).

13 November minimap layouts (MINIMAP-LAYOUT-20261113; REQ-MBL-01–09): shared character
slots now support 1–120 buttons; embedded columns auto-fit beside a 40–100% square
right-aligned map. Optional normal-map side layout defaults off; 1/2 columns retain
44-point buttons when space permits; 3+ fit two-column width and can shrink further.
Fill down the rightmost column to above Flux Window, then continue left. Start
below map or beside it from screen top; native/Questie docks reserve matching room.
Secure combat-hide option covers buttons/arrows/open flyouts and releases Escape;
unsupported secure engines explain unavailable. All structural changes defer;
queued combat embed/restore reconciles correctly. Hidden slots keep actions and
widgets; existing cadence/input/integrations retained. 760 focused checks; 22 harmful
controls; exact old baseline rejected; combined 320 scripts/1002 syntax PASS (319/1001
full run plus one concurrently added test checked separately). Final owned sources pass scoped retests; unrelated concurrent
inventory edits leave global freshness pending. 46 fresh Gethe source
records/36 Git blobs verified; Forever pin now bebcb6bf309cf41b41bd74f8ca651e6a105b2676.
External 2608-file/source-history checkpoint and 69 settings metadata verified.
Eight task runtime owners; unrelated concurrent inventory work preserved. No new
addon poll/ticker/timer. Direct implementation/user-native route retained; native
pixels/input/persistence/controller/taint/FPS/memory NOT RUN. No client control,
settings/profiler write, manual sync, commit or publication.
[Requirements and native checks](MINIMAP_EXTRA_LAYOUT.md); [evidence](validation/minimap-layout-2026-11-13.json).


13 November options follow-up (OPTIONS-SHARED-THREAT-20261113; REQ-OPT-35–38):
sidebar order is Combat → Loot & Items → Utilities → HUD → Unit Frame. Bindings
and Keybindings share one Bindings entry with two original-tool tabs; old links,
macro search and editor lifecycle remain. Threat warning visibility renames the
existing scoped threatBarVisibility setting; General/Nameplates share Always,
In raid, In party, Off. Party includes raids; raid-only excludes parties. All
nameplate and target/focus positions share one gate; between-bar exception removed.
Old nameplate values/legacy keys preserved. Explicit changes request the existing
guarded native warning CVar; wrapper CVar-presence call signature corrected.
870 warning/6,272 placement/1,243 shell checks; suite snapshot316 scripts/997 syntax PASS.
External2,609-file/source-history checkpoint and141 settings metadata entries
verified. Seven runtime owners changed; no new driver/event/timer/hook/poll.
Direct implementation/user native reproduction retained; native pixels, persistence,
combat/taint, controller and FPS NOT RUN. No client input/focus, private settings/
profiler write, manual sync, commit or publication. Fresh source lookup unavailable;
existing dated pins retained; no new native API contract.
[Requirements and acceptance](OPTIONS_REWORK.md#13-november-sidebar-bindings-and-shared-threat-warnings);
[evidence](validation/options-shared-threat-2026-11-13.json).

12 November potion discovery stall (AUCTION-POTION-STALL-20261112; AHR-38–40): the new
screenshot remains Finding stronger usable potions. The real parser reproduced
a spent shared-budget failure that the earlier classification stub missed. Each
deferred AH batch now renews that budget (still at most8 IDs). Potion results mark
whether restore is known; name-only placeholders retry until real tooltip data
arrives and cannot be ranked as restore1. Known unusable potions are skipped first.
Native ADDED browse payloads now contribute later rows and cumulative unique-key
progress, preserving the initial catalog instead of repeatedly reading its first
batch. Read-only /fluxah debug adds search phase/term/results/page/deadline.
Five repeated desktop work models: baseline refs100/101,734 load requests and
timeout; candidate refs201/300,30 requests and ready. Simulated elapsed times are
not native measurements. 552 potion/16525 auction checks;20 restock/15 receipt models;6 new harmful controls;314 scripts/995 syntax PASS.
Four existing runtime/test files changed;0 new; external2,608-file source/history
checkpoint and47 settings metadata entries verified. Existing UI, settings,
unquoted terms, price/usability/shared tiers and per-press buying are preserved.
User native reproduction route/direct implementation remain selected. Current
native retest and earlier Forever purchase BLOCKED resolution remain pending.
No client input/focus, private settings/profiler write, manual sync or publication.
[Current behavior](AUCTION_RESTOCK.md);[evidence](validation/auction-restock-potion-stall-2026-11-12.json).

12 November auction density/source/potion correction (AUCTION-DENSE-STOCK-20261112; AHR-28–37)
replaces the recipe/cost pane with a full-width paged grid and Direct/Craftable
labels (24cells at modeled800×600), retaining three money fields and one Buy next.
Old/unacknowledged pending attempts are pruned; real receipt/private/provider
incoming credits still reconcile once. Only typed unlimited merchant supply
excludes an item; limited/unknown/price-only/extended-cost records stay eligible.
Food/water are absent, including manual entries; vendor spell reagents use that
same unlimited-supply rule. All listed eligible items, including full/zero targets,
are price-scanned. Optional Auctionator public hints and guarded unit-price/history
write-back coalesce one notification; historical prices never authorize buys.
Plain unquoted partial healing potion / mana potion searches collect all native
result pages, validate usability/live offers/caps, choose stronger tiers and update
the real shared reference/tier. Weaker bag/bank stock cannot fill the stronger
target. Original caps survive a scrubbed ref; unknown metadata holds potion buys.
Craft preference, exact yields/shared inputs, price caps and one transaction per
press remain. 16413 focused checks;20 restock/15 receipt models;41 harmful controls;314 scripts/995 syntax PASS; 226 pinned upstream blobs verified.
Source guard:15 existing changed runtime/test files and4 new since the verified
2,602-file external checkpoint;47 settings metadata entries, no private values.
Earlier Forever mouse BLOCKED failures and screenshot defects remain prior native
evidence; current live purchases/pixels/coexistence/controller/taint/FPS NOT RUN.
No client input/focus, manual sync, settings/profiler write, commit or publication.
[Behavior and remaining native checks](AUCTION_RESTOCK.md);
[current evidence](validation/auction-restock-dense-potions-2026-11-12.json).

12 November auction follow-up (AUCTION-AUTO-CRAFT-TAB-20261112; AHR-10–27) supersedes the
initial popup/two-press/zero-disables/clear-pending design below. Real AH tab uses
shared restock cells/current icons and three currency fields; top edge/height
match neighboring tabs. Whole-list/material planning is automatic; cell selection
only edits. One press quotes/confirms one qualifying transaction; next needs a new
press. Zero/unset is unlimited. Saved Prefer crafting materials toggle is in AH
and Vendor→Restock; equal/cheaper learned recipes use exact missing inputs/yield,
vendor costs/shared stock and finite parent budgets. Incoming inbox plus transit
credit reconciles automatically (19/20 feathers +1 pending blocks rebuy); there is
no Clear pending UI/API. Built-in inventory now publishes confirmed AH purchases
to its mail snapshot/ledger immediately, including other auction controls; provider
Ready handoff stays inert. Prediction/private transit credit counts once and an
early empty inbox cannot discard the own reservation. Proven owned failures and
synchronously blocked calls release their own credits without phantom delivery.
13078 focused checks;20 restock/15 receipt models;34 harmful controls;312 scripts/991 syntax PASS;202 upstream Git blobs verified;
source guard permits10 existing changed files/5 new files in this follow-up;
shared cells/professions/Syndicator adapter remain byte-identical. Built-in Mail/
Auctions are intentionally extended. External2,595/2,598-
file source/history checkpoint and47 settings metadata entries verified.
Two prior Forever mouse-click BLOCKED failures remain native evidence; direct
calls/action-before-disable candidate has NOT passed native retest. No-search,
pixels, transactions/coexistence, persistence, controller, taint and FPS acceptance
pending. Auctionator345/TSM4.15.6/Syndicator290 inspected read-only at explicit request;
ARR notices preserved; no copied code. No client focus/input, settings/profiler
write, manual sync or publication. Reload after user-managed synchronization.
[Current behavior and native checks](AUCTION_RESTOCK.md).

12 November auction restock (AUCTION-RESTOCK-20261112; AHR-01–09): native-API
standalone implementation for Retail/Forever/MoP and Era/Anniversary. One action
button searches/quotes/buys; every purchase requires a press. Per-item saved unit
caps include active presets; known vendor stock excluded, unclassified items need
an explicit cap. Legacy default fits whole stacks; optional excess shows surplus
and total. Charge/tier/bank math and persistent pending-mail reservations prevent
duplicate refill. Competing queries/quotes yield; partial batches request more
selected-item rows. No Auctionator source/dependency or new inventory provider.
6,496 focused checks/20 models;12 harmful controls; full309 scripts/986 syntax PASS;
all final manifest hashes match. 87 pinned Git blobs verified. External2,587-file
source/history checkpoint and47 WTF metadata entries; private settings not copied.
Four new modules,one test;three existing runtime files changed;all other existing
Lua/XML/TOC bytes preserved. Direct implementation selected12November; prior
user native reproduction route retained. Native transactions/addon coexistence,
pixels/controller/persistence/taint/FPS NOT RUN. Reload after user-managed sync;
use Vendor→Restock→Auction restock & prices, `/fluxah` or auction-house button.
No foreground/input, settings/profiler-file write, manual sync or publication.
[Requirements and remaining native acceptance](AUCTION_RESTOCK.md).

11 November all-consumable audit (CONSUMABLE-ALL-BUTTON-AUDIT-20261111;
CGLC-23 through CGLC-27): all seven real Create paths and both grid count methods
run together across five models, both providers and two gem policies. Repeated
loading, charged remnants, isolated depletion/refill and regen placeholders PASS.
2,580 checks; old native-failing source 940/current 0 in three matched pairs;
ten harmful controls rejected. One shared watcher; 100 use signals coalesce to
one immediate and one 100ms settle callback, 14 recounts; 100 unrelated events add 0;
idle 12s adds 0 scans/timers. Full 308 scripts/981 syntax PASS; manifest current.
No production Lua/XML/TOC changes; one new test. External 2,585-file source/history
checkpoint and 55 settings metadata entries verified; 75 installed runtime copies
match user sync. Current repair native acceptance/FPS/taint/pixels/input remains
NOT RUN. No client focus/input, settings/profiler write, manual sync or publication.
[Coverage, source ownership and native limits](COMBAT_GRID_LIVE_COUNTS.md#all-seven-real-button-modules-audited-together).

11 November native loading-hold fix (CONSUMABLE-LOAD-END-20261111;CGLC-19 through
CGLC-22): failing-state capture proves food 1 with every source 0 while inventory
is reliable and Best's loading latch remains open. Ordinary bag events cannot
release it. One Inventory handler now completes unfinished loads on validated
optional LOADING_SCREEN_DISABLED, restarts cancelled existing slot refresh and
reuses bounded portal recovery. Normal PEW/duplicate completion add no work;
newer loads remain protected. All seven kinds/providers/five models covered.
2,230 checks; exact checkpoint fails 660; three matched pairs and five controls;
full 307 scripts/980 syntax PASS with current manifest. One runtime owner and
one test added; one event subscription; no new frame/ticker/timer call site,
background polling, settings or action writes. Five pinned blobs and external
2,583-file source/history checkpoint verified; 55 settings metadata entries;
all five installed runtime copies match via user sync. Prior candidate FAILED
natively; new handler symptom/taint/pixels/input/FPS acceptance NOT RUN. Reload
and retest loading/depletion; retain /fluxinv buttons output during recurrence.
No foreground/input, profiler write, manual sync, commit or publication.
[Native evidence and completion recovery](COMBAT_GRID_LIVE_COUNTS.md#native-capture-loading-completion-left-open).

11 November consumable screenshot follow-up (COUNT-SOURCE-RECONCILIATION-20261111;
CGLC-14 through CGLC-18): all seven kinds and other assigned item faces share
count-source/recovery corrections. Actual world entry releases an orphaned
open loading latch; startup during real loading remains held. The existing
portal timer publishes inventory count recovery even without an identity change.
A valid carried-only modern zero no longer falls through to a stale deprecated
positive; missing/error and extended-bank compatibility remain. Optional
`/fluxinv buttons` captures physical slots, APIs, provider/text/hold facts once;
no automatic polling, new event/frame/timer/hook, settings or protected writes.
2,104 hold/diagnostic +245 source checks PASS; exact checkpoint fails 583/150;
three matched pairs per workstream and eight harmful controls rejected.
Full 306 scripts/979 syntax PASS; normalized manifest current; four runtime
owners only and two new tests. 22 fresh pinned Gethe blobs verified; external
2,580-file source/history checkpoint and 55 settings metadata entries. All 20
installed runtime copies match via user sync. User's healthy Syndicator/reliable/
no-hold sample and unbound gem do not explain the intermittent screenshot.
Follow-up food/water probe prints no rows; raw API agreement is unverified.
Native candidate symptom/pixels/taint/input/FPS remains NOT RUN; reload and
capture `/fluxinv buttons` during recurrence before another reload. No client
input, settings/profiler write, manual sync or publication.
[Requirements and remaining native acceptance](COMBAT_GRID_LIVE_COUNTS.md#screenshot-follow-up-count-sources-and-loading-holds).

10 November profession fill/glow correction (TRADESKILL-CAST-FILL-FIX-20261110;
TCAST-06–08): user reports missing fill and excessive flare, then requests a
visible skill-up-style glow after softening. Animated fill now belongs directly
to TimerBar ARTWORK7; an opaque native mask follows progress with black-outside
wrap. Flare is explicitly above fill at OVERLAY0 and below native text/shields;
60% intensity and 44x14 instead of 53x16 at 18px bar height. Glow persists through
the existing completion fade. No new frames, drivers, events, timers, hooks,
options or data; one clip frame removed, one mask added per themed bar.
455 focused checks; exact old clipped implementation plus seven harmful variants
rejected; full 304 scripts/977 syntax PASS; current source attested.
Six mask-API blobs verify at the retained Retail/Forever pins. External 2,578-file
source/history checkpoint and four settings metadata entries verified. Initial
native failure is user evidence; candidate pixels/taint/input/controller/FPS
NOT RUN. Direct implementation/user retest retained; reload OOC and craft.
No client input/focus, settings/profiler writes, manual sync or publication.
[Correction and remaining acceptance](TRADESKILL_CAST_THEMES.md#fill-and-visible-glow-correction).


10 November profession cast themes (TRADESKILL-CAST-THEMES-20261110; TCAST-01–05):
readable tradeskill casts now use Blizzard's animated profession rank-bar fill
and optional flare on capable Forever/Retail clients. Recipe API plus native
profession enum selects the kit; unknown/restricted data and absent art keep
the ordinary cast. Existing master/unit/colors/edge/glow controls and complete
cast/channel/completion/interruption lifecycle retained. No new Lua driver,
event, timer, hook, options, text or saved data. Focused five-client models PASS;
old behavior and five harmful controls rejected; full 304 scripts /
977 syntax PASS with current source manifest. Fourteen fresh pinned Gethe
blobs verified. External 2,574-file/source-history checkpoint; four settings
metadata entries only. Direct implementation/user reproduction retained.
Native pixels/taint/input/controller/FPS NOT RUN; reload OOC and craft with
two professions. No client input/focus, settings/profiler write, manual sync
or publication. [Requirements, implementation and checks](TRADESKILL_CAST_THEMES.md).


10 November focus without resource (FOCUS-NO-RESOURCE-20261110): the compact focus
divider now follows resource opacity, including focused-unit chrome refreshes.
No-resource focus retains full HP with no dividing line; empty current power
with positive capacity keeps its bar/divider. Native opaque alpha passes
directly; combat geometry stays deferred. Two exact-baseline regressions
rejected; 22,015 color checks and full 304 scripts / 976 syntax PASS.
One runtime owner; dated external source checkpoint and history verified;
four Retail settings metadata entries read-only. Direct implementation/user
reproduction retained. Native pixels/taint/input NOT RUN; reload OOC and
focus units with/without resources. No new driver, settings or binding; no
client input, preference write, manual sync or publication. [Evidence](validation/focus-no-resource-2026-11-10.json).


10 November party HP/resource fit (PARTY-HEALTH-FIT-20261110): player-style party health
now stops above the resource bar at the existing two-unit gap instead of
extending behind it on HUD clients. Planned prediction geometry matches;
known no-resource units still expand health. Main/compact-focus layouts and
combat deferral remain. 396 fit checks reject the exact checkpoint; 675
combat-join checks and full 304 scripts / 976 syntax PASS.
One runtime owner; external 2,566-file/history checkpoint and 26 settings
metadata entries verified. Direct implementation/user reproduction retained.
Native pixels, combat/taint and input NOT RUN; reload OOC and check a party.
No new input/focus targets, options, strings or runtime drivers. No client
input, settings/profiler writes, manual sync or publication. Fresh upstream
heads unavailable; existing dated pins retained. [Evidence](validation/party-health-fit-2026-11-10.json).


10 November passive pass 3 (PASSIVE-PERFORMANCE-PASS3-20261110; PP3-01–06;
PP3-H01–12): twelve new hotspots across eight loaded runtime owners. Core numeric/
aura/checked helpers reuse callbacks; Index avoids normalized tables and full
first-location result construction. Mana/swing owned styles settle without slowing
live movement/values; raid flags recycle after paint. Active Classic character
calculations drop unused metadata/palette work; quality keeps every query/sink.
Three pairs/workstream; 99,781 focused checks/set; 57 harmful controls rejected.
Full 303 scripts / 975 syntax PASS; source stable throughout. One obsolete rebind
mutation now breaks both cleanup steps; unchanged functional assertion rejects it.
Generated 1,008 sources / 607 reachable / 427 settings / 24 saved roots. Documentation validator PASS.
21 source records / 10 Git blobs verified; canonical native fade replay and
35 setter-return checks. 252 appearance files / 80 options-binding sources unchanged.
Fresh party/vendor fixes and inactive character copies are byte-preserved.
Concurrent ConsumableBind/Paint and use-event test edits are retained and included
in the combined full run; other runtime owners match the checkpoint. External
2,561-file/history checkpoint; settings
metadata only. Native FPS/memory/pixels/taint/input pending; no input, preferences/
profiler write, manual sync or publication. Unrelated party/raid work stays paused.
[Findings, comparisons and native limits](PASSIVE_PERFORMANCE_PASS3.md).

10 November combat grid use/depletion follow-up (COMBAT-GRID-USE-EVENTS-20261110;
CGLC-07–13): user confirmed dark gem1 after use on Forever/Syndicator; wants dark0
in combat and next owned item/empty placeholder OOC for all seven kinds/providers.
Cooldown-only notifications and wrong nonblank cached digits now refresh. Shared
watch has one immediate plus one100ms settle pass; no idle ticker or predicted
decrement. Reliable exhausted gem clears sticky face; gem/stone selection and
charge/refill recovery use existing owners. Tint follows displayed item, including
prepared macro faces. Combat actions and loading holds remain.
1219use +672transition +2175prior checks PASS; three matched pairs each workstream;
12harmful controls rejected. Full304scripts/976syntax PASS; entire source manifest
matches. Hidden340-check trace/budgets and unrelated-bag zero-scan behavior retained.
Three runtime owners; two new tests; two existing fixture expectations updated to
the clarified behavior.22exact Gethe records; external2566-file/history checkpoint;
33initial+22Anniversary settings metadata only. All15installed runtime copies match
through user sync; no manual propagation. Candidate native symptom/taint/pixels/
input/FPS remains NOT RUN; reload and user retest required. No input/focus,
settings/profiler write, manual sync or publication.
[Correction, regression and native steps](COMBAT_GRID_LIVE_COUNTS.md).

10 November party debuff visibility (PARTY-DEBUFF-VISIBILITY-20261110; PDV-01–05):
enemy target/focus tint is revoked immediately; friendly tint remains. Player-style
party icons have rectangular type borders. Both party styles get a Salvage-style
type-colored glow only for native/readable dispellable auras, with an atlas fallback.
18,618 tint / 408 visibility / 11,410 aura checks PASS; two focused runs and six
new controls. Full 298 scripts / 970 syntax PASS; current manifest matches.
Native pixels/combat animation/taint/input/FPS NOT RUN. Three runtime
owners only; concurrent inventory edits preserved. External 2,551-file history/source
checkpoint and 61 settings metadata entries verified. No input, settings/profiler
write, manual sync or publication; direct/user reproduction route retained.
[Requirements, sources and acceptance](PARTY_DEBUFF_VISIBILITY.md).

10 November vendor Junk tab freeze fix (VENDOR-JUNK-TAB-FREEZE-20261110):
two runtime owners; name snapshots remove comparator loads; visual/item completions
share the existing 200 ms retry; reentrant/unchanged scroll painting is suppressed.
Three matched pairs across five client models: 400 cold entries request
13,768→1,200 loads; 400 completions rebuild 400→1 times and paint 6,834→17 rows.
85 focused checks PASS; four harmful controls rejected; vendor/timer regressions PASS.
Full run: 295 scripts PASS, two raid-aura failures amid concurrent unrelated edits;
969 syntax PASS. No clean current full-suite or native freeze/FPS/pixels/taint/input
acceptance claimed. Concurrent edits retained; exact Junk sources match full run.
External 2,545-file/history checkpoint verified; four settings metadata entries only.
No input/focus, settings/profiler write, manual sync or publication. Reload and
user-performed vendor/Junk retest pending. Fresh upstream commit lookup unavailable.
[Cause, fix, evidence and native limits](VENDOR_JUNK_TAB_FREEZE.md).

10 November combat grid live counts (COMBAT-GRID-LIVE-COUNTS-20261110;
CGLC-01–06): food/water/bandage/potions/gem/healthstone reach zero with both
providers. Syndicator's native fallback now includes both conjured kinds;
count/tint and ownership use live carried copies while metadata delays publishing.
Same-frame bag bursts coalesce; combat actions and loading holds remain.
Three matched pairs: 2,175 checks PASS; checkpoint rejects 244; seven harmful
controls rejected. Forty provider burst fixtures: recounts2,500→40, native count
queries2,500→159; no combat scans/rebinds/new frames. Existing craft/hidden-button
regressions pass. Full suite completed297scripts/969syntax PASS; task source hashes
match; unrelated subsequent/concurrent vendor/raid edits retain separate acceptance.
Final docs check has four stale inventory/verification records in concurrently edited
raid/debuff owners; own task sources match all passing focused checks.
Twenty-two pinned Gethe records verified across five clients. External2,550-file/
history checkpoint;33settings metadata entries read-only. Native input/pixels/taint/
FPS/memory NOT RUN; no client input, settings/profiler write, manual sync or publication.
User-managed Retail-only writes and prior party/raid native pause retained.
[Fix, comparisons and native steps](COMBAT_GRID_LIVE_COUNTS.md).

10 November additional passive optimization (PASSIVE-PERFORMANCE-PASS2-20261110;
PP2-01–06, PP2-H01–10): ten new hotspots across eight runtime files. Combat
class-resource retry storms coalesce; synchronous cast text shares a revision-guarded
clock sample; raid prediction uses scalars. Parked Extra Buttons stop checked/count/
metadata work, with count/tint/equipped state refreshed before first visible paint.
Core protected/range helpers and meter timer election reuse functions; collector
keeps linear child snapshots and all discovery cadence with fewer pattern matches.
Three pairs/workstream; 783 focused checks/set; 60 harmful controls rejected.
Full 295 scripts / 967 syntax PASS; exact source matches. Generated 1,000 sources,
607 reachable files, 427 settings and 24 SavedVariables roots. Documentation validator PASS.
25 pinned records / 20 Git blobs verified; Forever advanced to 4cd0ab752a77.
252 appearance files / 80 options-binding sources and all other runtime owners
unchanged, including prior combat/resource fixes. External 2,543-file/history
checkpoint; settings metadata only. Native FPS/memory/pixels/taint/input pending;
no client input, preferences/profiler writes, manual sync or publication. Guild/
void callbacks and unrelated party/raid feature work remain excluded.
[Findings, comparisons and limits](PASSIVE_PERFORMANCE_PASS2.md).

10 November resource-effects follow-up (RESOURCE-EFFECTS-PERFORMANCE-20261110;
RFX-01–06): power ghost bursts coalesce at the original After0 boundary;
1,000 same-frame paints queue 1 callback instead of 1,000; unchanged public sinks
retry only when needed. Secret animation Lua callbacks fall 120→0 in 0.5 s/240 Hz.
Prepared shown helper containers use texture visibility and active-only drivers;
shared spark guards geometry before arithmetic; eligible HUD main bars prewarm
unchanged pulse trees. Bounded dormant allocation tradeoff recorded, no idle driver.
Three pairs/workstream; 122 Shared/168 PCO checks; 9+12 controls; 3×84 combined
checks and 2 disconnection controls. Full 290 scripts/962 syntax PASS; source attested.
Documentation validator PASS: 995 sources, 607 reachable files, 16,146 local links.
88 pinned records/54 blobs and 50 ownership checks; Frame Show/Hide correction.
Earlier partition/value painter and all other runtime owners byte-preserved.
252 appearance files/80 options-binding sources unchanged; external 2,539-file/history
checkpoint; settings metadata only. No native FX/taint/pixels/FPS/input acceptance,
settings/profiler write, manual sync or publication. Prior scoped pauses remain.
[Changes, tradeoffs and evidence](RESOURCE_EFFECTS_PERFORMANCE.md).

10 November combat-invite power partition correction (POWER-PARTITION-COMBAT-JOIN-20261110;
PWRJOIN-01–06): native user trace exposed protected SetHeight/Show in ordinary
post-reveal painting. Shared partition now defers structural geometry before all
text-anchor/prediction/layout mutations; native reveal and value paints continue.
Absent prepared slots retain unknown resource capability so combat joins have a
ready power bar. Existing queue coalesces per frame; Party retains its regen owner.
675 focused checks/15 cases across five clients; three exact-baseline pairs;
eight harmful controls rejected; full 288 scripts / 960 syntax PASS. Documentation
validator PASS: 993 sources / 607 reachable / 16,131 local links. 44 pinned
source records / 31 blobs verified. Only one runtime file changed; earlier 23
performance owners unchanged. External 2,536-file/history checkpoint; settings
metadata only. No native retest/pixels/taint/FPS claim, input/focus, settings/profiler
write, manual sync or publication. Prior mocks omitted protected child permissions.
[Cause, correction and native limits](POWER_PARTITION_COMBAT_JOIN.md).

10 November passive performance optimization (PASSIVE-PERFORMANCE-OPTIMIZATION-20261110;
PPO-01–06): all 24 audited candidates optimized with preserved nominal cadence,
features and tested geometry/input/lifecycle behavior. Three exact-checkpoint pairs
per workstream; 23 runtime files, seven new tests. Full 287 scripts / 959 syntax
PASS; current source matches validation and comparison hashes. Documentation
validator PASS: 992 sources / 607 reachable / 16,117 local links; records current. Native reset reads,
secret sinks, sparse-slot probes and complete provider validation remain where
correctness requires them. 31 pinned source records / 25 unique Git blobs verified.
252 appearance/XML/TOC files and 79 options/binding sources byte-preserved.
External 2,525-file/source-history checkpoint; settings metadata only. No native
FPS/pixels/taint/input acceptance, client input, settings/profiler writes, manual
sync, commit or publication. Scoped optimization includes readable raid fallback;
unrelated party/raid feature work and native sessions remain paused.
[Before/after results and constraints](PASSIVE_PERFORMANCE_OPTIMIZATION.md).

10 November passive performance audit (PASSIVE-PERFORMANCE-AUDIT-20261110;
REQ-RPF-01–05): 24 current optimization candidates plus 2 retained feature costs.
Priority: per-mob group/pet threat ranking; per-frame nameplate layout checks;
settled aura styling and explicit native full-aura rebuild requests; idle observers;
mail/provider bursts. 39 synthetic replay scenarios load unchanged production code
or exact verified native methods; five existing focused regressions PASS. Five
fresh Gethe branch pins; 21 source records / 17 unique blobs verified. All 953 Lua
byte identities unchanged. No runtime/settings/profiler/client-input/sync/publication
change; guild/void callbacks excluded. Actual native CPU/FPS/taint/pixels/memory
remain NOT RUN. Existing generated minimap docs/verification have 10 stale issues;
unrelated generated records not regenerated. Party/raid implementation/native-test
pause preserved. [Findings and optimization order](PASSIVE_PERFORMANCE_AUDIT_2026-11-10.md).

10 November built-in minimap target/focus tracking (MINIMAP-TRACKING-20261110;
REQ-MT-01–06): native tracking-menu extension restores actual hidden Target/Focus
entries on capable Retail/Forever clients. Target defaults on; Focus stays native
until chosen; character choices survive reload/world resets with a bounded 3s retry.
Native show-all, existing rows, game-rule restrictions and enabled standalone owner
remain. Classic family without GetTrackingFilter stays inactive; enum names alone
never fabricate markers. One shared world subscription/menu modifier; no new frames,
tickers/OnUpdate/global hooks.412 focused checks x3; 8 harmful controls rejected;
full 280 scripts / 952 syntax PASS;33 source records / 26 exact Git blobs at five fresh pins.
External 2,510-source/history checkpoint and 46 read-only settings metadata entries.
Native markers/input/controller/pixels/taint/persistence/FPS NOT RUN. Prior direct
implementation/user reproduction retained. User confirms running sync program and
explicitly requests Retail-only writes; no manual cross-client install or publication.
No game input/focus or private-settings/profiler writes. Party/raid work stays paused.
[Requirements and evidence](MINIMAP_TARGET_FOCUS.md).

10 November NPC-to-window speed audit (NPC-WINDOW-OPENING-AUDIT-20261110;
REQ-VG-09): user locates delay before bank/vendor appearance. Current selection
already runs in the same gossip event without an added timer/icon lookup/UI
allocation.29exact pinned native blobs verify normal startup-loaded panels and
Forever direct show registrations;no extra preloader justified. No runtime or
settings changes, new frames/events/timers/hooks, input/focus/profiler operation
or publication. All950Lua identities and4installed gossip copies still match the
279-script passing source;no full rerun. Actual native click→response→first-draw
latency remains unmeasured;network/native/other-addon contributions unresolved.
Native timing is required before promising any additional opening-speed gain.
Earlier paused party/raid work remains paused.
[Exact source evidence and limits](validation/npc-window-opening-audit-2026-11-10.json).

10 November bank/vendor gossip checkbox and immediate selection follow-up
(BANK-VENDOR-GOSSIP-20261110; REQ-VG-05–08): separate Auto open bank defaults off;
vendor preference survives. One native checkbox appears lower-left beside Goodbye
for one available bank/vendor choice without quests. Checking saves that service
and opens now; Shift reveals it later to disable. Icons prime at login;automatic
selection runs in the same event with0asset lookups/0checkbox allocations/no added
timer. Pending refreshes cannot duplicate selection. Server/native latency/FPS
remain unmeasured. One lazy reused checkbox;two shared lifecycle subscriptions
are now required even with automation off;Forever adds its valid refresh event.
No new timers/tickers/hooks/OnUpdate/protected propagation setters.702focused x3;
10harmful controls and old source rejected;6237navigation/1253shell/36data checks;
full279scripts/950syntax PASS.82exact Gethe source blobs at existing five pins.
External2505-source/history checkpoint and105read-only settings metadata entries.
Three tested files installed inForever/progression/Era/Anniversary after approved
escalation;12copies verified;originals external. Reload required. Native NPC/
input/controller/pixels/taint/persistence/latency NOT RUN. Prior direct-design and
user reproduction choices retained. No game input/focus, private-settings/
profiler writes or publication. Paused party/raid native work remains paused.
[Requirements and evidence](20-vendor-restock-junk.md#bank-and-vendor-gossip-checkbox--10-november-2026).

10 November single-choice vendor gossip (VENDOR-GOSSIP-20261110; REQ-VG-01–04):
Loot & Items → Vendor → Automation has Auto open vendor, off by default and
per-character. On GOSSIP_SHOW it immediately selects only a sole available vendor
icon choice without quests; Shift preserves gossip. Uses native orderIndex;
Blizzard retains its own automatic selection and confirmations. One shared event
only while enabled; zero new frames/timers/tickers/hooks/OnUpdate. Retail inactive.
Fresh Gethe sources: all five pinned commits and 46 exact blobs; 321 focused
checks in three fresh runs; six harmful controls rejected; full279 scripts and
950 syntax PASS. Options navigation6222/shell1253/data-integrity36 PASS. External
2495-source/history checkpoint verified;105 settings metadata entries read-only.
Four verified feature files installed in Forever/progression/Era/Anniversary after
approved filesystem escalation;16 copies match and originals backed up externally.
Native NPC/input/controller/taint/pixels/persistence/performance NOT RUN; reload
required. Prior direct implementation/user native reproduction route retained.
No foreground/input, private-settings/profiler writes or publication. Earlier
paused party/raid native work remains paused.
[Behavior, source identities and evidence](20-vendor-restock-junk.md#single-choice-vendor-gossip--10-november-2026).

9 November Classic border fix (OPTIONS-NATIVE-BORDER-20261109; REQ-OPT-34):
Era error traced to inherited SetBorder with absent PortraitFrameTemplate layout.
Removed forced layout call; each client retains native template initialization.
Old regression stub missed this; real pinned native Lua now runs in the full shell.
Old source reproduces userLayout nil on progression/Era/Anniversary; candidate
passes1,253 checks across five models in three fresh processes.28 exact upstream
Git blobs verified with load/XML contracts. Decoration only; no focus/input/text/
settings/controller integration change. Native Era/other client retest pending;
no game input/focus, profiler/settings writes or publication. After approved
filesystem escalation, only the verified Skin file was installed in Forever,
progression, Era and Anniversary; all five copies match. Prior files backed up externally.
[Evidence](validation/options-native-border-2026-11-09.json).

9 November Forever native performance follow-up (FOREVER-NATIVE-PERFORMANCE-20261109;
REQ-RF-99): actual background-client preview stress completed with explicit
targeted diagnostic-input authorization. Solo/OOC only; server combat/roster APIs
untouched. Cold40-member preview196.1003ms, warm11.1176ms; warm party4.8791ms.
These single trials do not measure live joins or an FPS improvement. Fixed secret
resource-pulse geometry arithmetic and permission-gated vendor checkbox mouse
setters, reusing the combat queue.185 pulse/285 vendor/17050 tint checks PASS;
three vendor pairs and four harmful controls; full276 scripts/946 syntax PASS.
Ten exact API blobs;15 installed file copies match. Old debuff reader is absent.
Diagnostic18:07 errors were my lost-table readback after reload; commands guarded,
original performance report restored with3843 equal values, preview/prefs restored.
Real combat joins/leaves/subgroups and merchant input remain pending. Final client
foreground preflight caused no input. Source/history checkpoints and private
recovery data remain external; no manual sync or publication.
[Detailed evidence and limitations](FOREVER_NATIVE_PERFORMANCE.md).

9 November Inventory Awareness placement (OPTIONS-AWARENESS-20261109; REQ-OPT-33):
Inventory Awareness is inside Loot & Items > Loot, removed from Status Bars.
Original controls/callbacks/storage scope/Syndicator delegation remain. No new
sidebar entry or gameplay driver.6,207 placement/1,242 complete-shell checks PASS;
previous catalog rejected by both harnesses. Native acceptance remains NOT RUN.
[Evidence](validation/options-awareness-2026-11-09.json).

9 November HUD correction (OPTIONS-HUD-20261109; REQ-OPT-30 through32):
HUD replaces the Quality of Life sidebar page and contains Layout, Chat, Info,
Micro Menu, Flux Window and Status Bars. Windows moves to Utilities. Layout is
visible again with its original independent scope/reset and preview editor.
Flux Window contains General/Damage Meter tabs; actual Meter right-click opens
Damage Meter and expands minimized HUD. General shortcut selects General explicitly.
Old QoL links redirect; original sources/scopes/data/skins and other categories stay.
6,057 real-builder/1,217 complete-shell checks PASS across five models; five old or
harmful controls rejected and three fresh candidate runs each; full275 scripts /
945 syntax PASS with exact current corpus. External2,477-source/history checkpoint
verified;43 read-only settings metadata entries. Native visuals/drag/persistence/
input/taint/FPS NOT RUN; Witchcraft unavailable. No input/focus, settings/profiler
writes, manual sync, publication or new background goal.
[Current requirements and evidence](OPTIONS_REWORK.md).

9 November merged layout and follow-up fixes (OPTIONS-MERGED-LAYOUT-20261109):
General includes Appearance; Individual Frames has user-selected Player/Target/
Focus/Pet tabs. Unit Frame retains six sidebar entries. Loot & Items is a header
with Loot/Vendor/Restock; Restock uses the native bag icon. QoL has seven per-feature
tabs. Raid preview starts at10; explicit party preview stays5; legacy reads do not
reset data and combat entry stays guarded. Header buttons minimize/expand; search
reveals/restores state and old links expand parents. Forever background restores
visibility/alpha and disables inherited rock tiling on resize; other client skins
remain. 5,847 builder/877 shell/280 raid option-session/78 party checks PASS;
13 controls, three fresh candidate overlay runs each; full275-script/945-syntax
PASS. External2,468-source/history checkpoint and43 settings metadata entries.
Native visuals/input/persistence/taint/FPS pending. No game input/focus, private
settings/profiler writes, manual sync, publication or new background goal.
[REQ-OPT-23 through29 and evidence](OPTIONS_REWORK.md).

9 November all-client combat roster audit (COMBAT-GROUP-LIFECYCLE-20261109;
REQ-RF-98/83): checked current Blizzard secure header, visibility and event-manager
code across Retail, Forever, progression, Era and Anniversary. No new runtime
gap found. New regression executes the full native event-to-next-update manager
plus four callback orders:247385 checks over1800 transitions per run;three repeated
passes;six harmful controls rejected;50 exact source blobs and30 contracts.
Both party styles, solo/group/raid conversions, full/sparse/empty raids, subgroup
moves, MT changes, hidden parents, pets/targets and leave cleanup are covered.
Full274 scripts/944 syntax PASS; all current Lua matches the manifest and existing
runtime matches the external2463-source/history checkpoint.43 settings metadata
entries read-only;25 installed runtime copies match. No runtime change, game input,
settings/profiler write, manual sync or publication. Native taint/input/pixels/
latency acceptance remains NOT RUN. Preparation must complete before combat;
prepared roster changes do not wait for combat exit. [Mechanism, sources and
acceptance](COMBAT_GROUP_LIFECYCLE.md).

9 November sidebar header clarification (OPTIONS-UNIT-FRAME-SIDEBAR-20261109):
Unit Frame is now a framed sidebar header like Combat, with General, Appearance,
Player, Target, Focus, Pet, Party Frames, Raid Frames, Cast Bars and Nameplates as
ten clickable child rows with fitting icons. Each opens its section directly;
there is no category button or horizontal frame tab strip. One row is selected;
search/counts/hidden gates apply per child; short windows scroll above the fixed
footer. Original source roots/info paths/scopes/aliases and data remain. 5,832
real-builder +876 production-shell checks across five models; nine controls;
full273-script/943-syntax PASS. Verified external2,458-source/history checkpoint
and43 read-only settings metadata entries. Native acceptance remains NOT RUN;
no input/focus, settings/profiler writes, manual sync or publication.
[REQ-OPT-22, current hierarchy and evidence](OPTIONS_REWORK.md).

9 November steady party performance (PARTY-STEADY-PERFORMANCE-20261109;
REQ-RF-97): bar/prediction traffic now uses the existing shared painters without
full chrome/font/cast-cover rebuilds. Pet prediction is corrected, UNIT_PET is
owner-scoped, unchanged power text anchors are reused, and cold appearance events
refresh metadata immediately. Features, settings, range cadence and secure
roster/binding drivers remain. Five matched pairs/model remove936 full chrome,
800 pet style and3280 power-anchor operations in the replay; actual native lag
and FPS remain unmeasured.305 focused,1035 party and163 roster checks PASS;
full273 scripts/943 syntax PASS.51 exact upstream blobs across all five clients;
external2456-source/history checkpoint and43 read-only settings metadata entries.
All five installed copies match through existing sync. No game input, settings/
profiler writes, manual sync or publication. Prior manual testing route retained;
native latency/pixels/taint acceptance still pending. [Details and evidence](PARTY_STEADY_PERFORMANCE.md).

9 November combined quest objectives (NAMEPLATE-QUEST-LAYOUT-20261109): kill and
loot counters now share one horizontal 12-unit row, including additional objectives.
Badges fit full counts at the existing10-unit font/icon size and extend left when
the plate narrows or centered threat grows. No second row over casts; actual
native style clearance remains pending. Existing0.25s poll adjusts changed geometry
without quest rescans or settled anchor writes. No new driver resources/settings.
1,261 focused checks across five models plus8 actual threat-module checks PASS;
three old/new pairs and three harmful controls; full272-script/942-syntax PASS.
Verified external2,455-source/history checkpoint and87 settings metadata entries.
Prior direct implementation/local-check choice retained; user performs native
pixels/casts/combat/taint checks. No game input, settings/profiler writes, manual
sync or publication. [Requirements and evidence](19-nameplates.md#combined-objectives-and-dynamic-width--9-november-follow-up).

9 November category correction (OPTIONS-UNIT-FRAME-CATEGORY-20261109): Unit Frame
is now an independent top-level category beside Quality of Life, with that exact
singular label and all ten frame tabs. Combat contains Action Bars, Bindings and
Keybindings. Internal IDs, original builders, settings, scopes, aliases and icon
remain. 5,782 placement +441 shell checks across five models PASS; both wrong
nesting/name controls rejected. Native acceptance remains pending; no game input,
settings/profiler writes, manual sync or publication. REQ-OPT-21 supersedes the
earlier Combat nesting. [Current requirements and evidence](OPTIONS_REWORK.md).

9 November Unit Frames options organization (OPTIONS-UNITFRAMES-20261109): user
confirmed moving QoL Combat content into Unit Frames. Combat now contains Unit
Frames, Action Bars, Bindings and Keybindings; Utilities contains Loot & Items
and Professions. Unit Frames has General, Appearance, Player, Target, Focus, Pet,
Party Frames, Raid Frames, Cast Bars and Nameplates. Shared appearance is separated
from setup/scopes, party-style controls from compact raid/party controls; child
targets remain with their parents. Every original option object/root/info path,
handler, scope, reset, hidden/disabled condition and saved schema remains. Old
links redirect. 5,777 real-builder placement +441 complete-shell checks across
five models PASS; seven harmful controls rejected; full272-script/942-syntax PASS.
Native rendering/input/persistence/taint/performance remain NOT RUN; prior Witchcraft
setup request remains unanswered. Verified external2,447-file source/history
checkpoint and43 read-only FluxUI settings metadata entries. No foreground/input,
settings/profiler writes, manual sync or publication. The earlier native blocked
audit predates this new user-authorized implementation work.
[Requirements, current tab map and validation](OPTIONS_REWORK.md).

9 November RestedXP battlefield pins (RXP-PINS-20261109): Forever now admits
standard HereBeDragons-Pins-2.0 alongside Questie through the existing Map Pins
bridge. Original guide icons/style/tooltips and source settings remain; World Map
priority, guide-owner removal, combat deferral and toggle restoration are covered.
RestedXP v4.11.35 / HBD minor 17 inspected read-only; route lines/arrow unchanged. Six
old/new pairs reject the old rule and pass the candidate, including installed-HBD
provider replay. Full 272-script / 942-syntax validation PASS. Existing sync copied
the runtime change to Forever; no manual sync, settings/profiler writes or game
input. Verified external 2,438-file source/history checkpoint; 60 settings metadata files.
Native pixels/taint/FPS NOT RUN; prior Witchcraft route unavailable on this host.
[Requirements, exact sources and native steps](10-flux-window.md#restedxp-pins--9-november-2026).

9 November functional options sorting (OPTIONS-SORTING-20261109): latest user
clarifications are recorded in the active goal and supersede earlier taxonomy.
Action Bars has Bars, Extra Buttons and Stance Order. Consumables, Trinket Menu,
travel buttons, visibility and utility slots share the original Extra Buttons
group; Swing Timer and flight-path settings stay in Unit Frames > Player.
Loot & Items has its own Utilities sidebar page with Loot, Vendor & Junk and
Restock tabs; restock switches are grouped with the targets/editor. Bindings and Keybindings remain
separate; Quality of Life has four implemented tabs. The Meter right-click now
opens Damage Meter through a dedicated accessor; the real OnClick-to-shell route
passes and restoring the old destination fails. Compact framed icons, native
client skins and Escape entry remain. Original option identities, callbacks,
saved schemas and old links are retained. 5,158 mapping +391 shell checks across
five models; eight negative controls rejected; related meter/window checks PASS.
Full suite:272 scripts/942 syntax PASS. Native visuals/input/persistence/taint/FPS
NOT RUN; selected Witchcraft setup approval remains pending. No foreground/input
control, private settings/profiler writes, manual sync or publication.
[Current requirements and evidence](OPTIONS_REWORK.md).

9 November supported combat text audit (DEBUFF-BINDING-AUDIT-20261109): renewed
user request checked against35 freshly fetched pinned Gethe files across Retail,
Forever, Classic progression, Era and Anniversary.16 checks execute the actual
Retail/Forever Lua validators: native dispel Texture registration rejects a
FontString; aura animations reject external health/resource targets. Native type
text supports content/symbols; duration text exposes only temporal color inputs;
direct aura color lookup requires aura access. No supported binding was found for
the existing numeric labels while Retail/Forever aura data is restricted. The
all-client combat numeric-color requirement remains OPEN; no runtime workaround
was installed. Prior forbidden read stays removed; portrait/native border path,
readable Classic colors, options and saved data remain. Existing focused17,050
checks PASS; owned runtime/test hashes unchanged from the correction. No new
native operations, settings/profiler writes, sync, publication or performance claim.
[Source findings and remaining requirement](UNITFRAME_DEBUFF_COMBAT.md#supported-route-audit--renewed-request).

9 November supplied sidebar reference: accepted180x675 screenshot now drives compact framed categories, 24-unit feature rows, fixed22-unit system buttons and16-unit fitting icons on every client including Forever. Earlier icon-free styling superseded. User category relocation is implemented with4908 actual-builder mapping checks and421 complete-shell checks PASS; prior source objects/roots/info paths, valid mode lists and saved data retained. Quality of Life10tabs;Adventure/Combat/Utilities;fixed Settings/Profiles/Patch Notes/Credits. Native art/input/persistence/taint/performance NOT RUN; Witchcraft setup approval remains pending. No game input, settings/profiler writes, manual sync or publication. [Requirements and accepted reference](OPTIONS_REWORK.md).

9 November options category clarification (OPTIONS-NAVIGATION-20261109): user explicitly authorizes moving settings to match the reference. Quality of Life has all10 reference tabs; Adventure/Combat/Utilities groups and fixed Settings/Profiles/Patch Notes/Credits footer. Original controls have one primary location each; original roots/info paths/owners and saved data remain. 4898 real-builder mapping checks and266 full-shell checks PASS across five desktop clients; three harmful catalogs rejected. Forever Options tabs/minimal sliders/list headers/scroll art and Journeys backdrop use native assets; other client families retain native templates. Native pixels/input/persistence/taint/performance remain NOT RUN; selected Witchcraft setup still awaits approval. No game input/settings/profiler writes/manual sync/publication. [Requirements and placement map](OPTIONS_REWORK.md).

Craft-tier final evidence note: documentation checker reports four stale
records for concurrent options test edits after the second full run. Preserved
those edits; exact craft runtime/test hashes remain validated. Whole-tree
documentation acceptance is pending; see craft-tier source guard/report.

9 November craftable consumable tiers (CRAFT-TIER-FALLBACK-20261109): bandage,
healing-potion and mana-potion Auto slots now use the highest ranked affordable
learned recipe. Lower tiers remain available when stronger recipes lack bag
materials; material gains promote normally. Supersedes the old top-only rule.
1,609 focused checks across five client models and builtin/Syndicator; three
baseline/candidate pairs reject old source with 540 failures and pass candidate.
Full 272-script/942-syntax validation PASS twice; owned sources unchanged.
Concurrent options source changes preserved and checked; see source guard.
Existing cache/dependencies, profession routing, owned outputs and settings remain;
no new driver resources. Verified external 2,417-source/history checkpoint and
116 read-only settings metadata entries. Five installed source copies match.
No game input, settings/profiler writes, manual sync or publication. Native
clicks/pixels/taint/performance pending; no connected native tool.
[Requirements, evidence and native steps](CONSUMABLE_CRAFT_TIERS.md).

9 November forbidden debuff Texture read (DEBUFF-FORBIDDEN-READ-20261109):
user13:45:15 native GetVertexColor failure rejects the previous color bridge;
reported client/build unspecified. Removed both descendant getter operations,
retained Texture reference and prepared color objects. Keep portrait border-parent
layer fix on all five clients and native dispel border ownership. Numeric colors
use readable types and restore normal color during aura restrictions; the original
restricted numeric-color requirement remains OPEN. Fixture now rejects registered
Texture descendant access too:17,050 focused checks;five baseline forbidden-error
rejects/candidate passes;three controls;full271scripts/940syntax PASS with complete
current Lua corpus match. All five installed runtime copies match via existing
sync. External2411-source/history checkpoint and120 settings metadata verified.
No new frame/event/hook/timer/polling or suppression;no game input/settings/profiler
writes/manual sync/publication. Post-correction native error absence, portrait
pixels and taint/performance remain pending. Original desktop result is historical
rejected evidence, not native acceptance.
[Correction, source restrictions and native steps](UNITFRAME_DEBUFF_COMBAT.md).

Earlier DEBUFF-COMBAT-COLORS-20261109 is REJECTED by the user's13:45:15 native forbidden-object error. Its desktop mock allowed an inaccessible registered Texture. Retained comparisons are historical evidence only; see the [correction and open requirement](UNITFRAME_DEBUFF_COMBAT.md).

9 November options rework (OPTIONS-REWORK-20261109): replaced HUD-tinted options chrome with the running client's native portrait/inset/tab skin; reference-style grouped navigation, collapsible settings and cross-page search across all 15 existing pages. Added Escape > FluxUI Settings; existing commands, builders, data and embedded editors retained. 240 focused lifecycle checks across five desktop client models and full271-script/940-syntax checks PASS; native pixels/input/persistence/taint/performance remain NOT RUN. User chose Witchcraft in-game; it is neither installed nor connected, so setup authorization/client restart remain needed. No game input, private settings/profiler writes, manual sync or publication. [Requirements, source pins and resume steps](OPTIONS_REWORK.md).

9 November current-addon publication: include all current non-ignored source, assets, documentation and validation on main. External 2400-file source/history checkpoint and166 on-disk settings files verified. Existing full270-script/937-Lua PASS report matches the complete current Lua manifest; five publication-policy tests pass. DoctorFlux author/committer and no co-author trailers are required by active hooks. Native acceptance limitations remain unchanged.

9 November native bag item targeting (BAG-ITEM-TARGETING-20261109): matched
Forever saved12:44:34/count3 report and pinned70862 native right-click body;
user clarified an item targeting another item. First taint writer unresolved;
no speculative interaction fix. Added bounded `/fluxinput bags` before/10-second
metadata;574 focused checks and five related suites PASS, old-source rejection.
External2395-source/history checkpoint verified;120 settings metadata entries.
Host verified running Forever window read-only; no input/settings/profiler writes,
manual sync or publication. Full270-script/937-syntax validation PASS; complete Lua corpus unchanged.
User lacks original items; latest verbose log has no matching bag/action trace
or saved bag capture. No new crate required. [Future reproduction](BAG_ITEM_TARGETING.md).

9 November Baganator junk activation (BAGANATOR-JUNK-ACTIVATION-20261109):
user explicitly requested the addon fix after the detector diagnosis. The junk
bridge now selects FluxUI once per active Baganator profile, retains the previous
detector in additive profile metadata, emits the normal setting notification and
refreshes widgets/searches/layout. Later manual choices persist; inactive profiles,
consumable ranking, Useful/restock/conjured/gear protections remain. One BagShow
callback; no new frame/timer/polling.403 focused checks; five old/new pairs reject
old code (162 failures) and pass candidate. Full269 scripts/936 syntax files PASS;
source corpus unchanged after validation. Native coins/categories and actual
settings persistence pending user reproduction; no connected native tool.
Verified external2389-file/history checkpoint and56 read-only settings metadata.
No game input, on-disk settings/profiler writes, manual sync or publication.
[Requirements, sources and acceptance](BAGANATOR_JUNK_ACTIVATION.md).

9 November Baganator missing consumable junk (BAGANATOR-JUNK-DETECTOR-20261109):
read-only diagnosis found Forever Baganator846 saved DEFAULT junk detector
RXPGuides; sampled FluxUI inferior switches are enabled. Baganator calls one
selected plugin; registering FluxUI does not activate it over RXPGuides.
Select General > Junk detection > FluxUI, reopen bags and verify lower potions,
bandages, food and water against a better usable carried tier. Preserve explicit
Useful/manual restock/conjured protections. Saved disk state is not a live-session
observation. Existing combat1020checks and junk/Baganator smoke PASS; native
selection/coins/category acceptance pending user reproduction. No runtime edit,
settings write, game input, profiler change or publication; no new performance
claim. [Exact inspected sources and checks](validation/baganator-junk-detector-2026-11-09.json).

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
[Scope and evidence](UNITFRAME_COMBAT_TRANSITIONS.md#focus-colors--9-november-follow-up).

9 November quest badge compact follow-up (NAMEPLATE-QUEST-COMPACT-20261109):
user requested shorter/smaller tags and an icon that fits inside without crowding
threat. Quest-only count font12->10, icon12->10, host14->12; total horizontal
padding/icon space28->16 with2-unit left/gap/right insets and1-unit vertical icon
clearance. TOPLEFT Y+3 preserves centreY-3 shared with threat/level; row spacing16.
Quest associations/progress, optional Questie policy and native fallback unchanged.
371 focused checks plus existing combo/cast-school regressions and syntax PASS.
Full267-script/934-syntax verification PASS with no source drift; native visual
check remains user-owned.
External current source/history checkpoint verified;87 settings metadata inspected.
No game input, settings/profiler writes, manual sync or publication.
[Feature and acceptance](19-nameplates.md#quest-kill-and-loot-progress--9-november-2026).


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
[Scope, sources and steps](UNITFRAME_COMBAT_TRANSITIONS.md).

9 November rejected cast bar (CAST-REJECTED-20261109): terminal failure/stop
feedback now requires an active visible cast/channel. Cooldown and other rejected
attempts cannot summon an idle bar or replace finish/interrupt/custom-timer state.
Valid interruption/completion, secret-safe routing and appearance retained.
24,775 focused checks across five clients; five baseline/candidate pairs and
three rejected controls; party215/timer379 and full267-script/934-syntax checks
PASS with no source drift. Five mirrored runtime
copies match. Native input/events/taint/pixels/performance pending; no connected
test tool, client/settings/profiler interaction or manual sync. Verified external
2,364-file/history checkpoint and125 read-only settings metadata entries.
[Scope and evidence](CAST_REJECTED_ATTEMPTS.md).

9 November nameplate quest progress (NAMEPLATE-QUEST-PROGRESS-20261109):
added default-enabled own kill/loot icon and current/required counts, TOPLEFT at
health-container BOTTOMLEFT 0,+4 (14-high host centreY -3, matching threat/level); additional objectives stack down. Inline existing
Core/defaults/options; no new runtime module or quest database. Questie lookup
and ready/update notifications; native tooltip + active-objective fallback;
duplicate Questie world-nameplate option disabled and old markers cleared.
Two exact supplied default icon textures with original restriction notice.
311 focused checks, baseline rejection and seven harmful controls PASS; six related
regression scripts PASS and four owned Lua identities unchanged; latest full263/265 scripts PASS with two
unrelated unit-frame mock failures;932Lua syntax PASS. Five desktop contracts; native render/combat/taint/CPU/FPS
pending. User chose direct implementation and will test in-game. External dated
source ZIP/history bundle verified;87 on-disk settings metadata entries inspected.
No game input/settings/profiler/sync/publication. Existing dirty work preserved.
[Requirements and acceptance](19-nameplates.md#quest-kill-and-loot-progress--9-november-2026).


9 November menu press input (MENU-PRESS-20261109): food/water/bandage/healing
potion/mana gem/mana potion/healthstone/trinket HUD mouse and use/conjure bindings
now activate on press. Shared wrapped policy ignores release CVar for HUD keys;
Forever unwrapped policy honors onDown with native AnyDown. Ordinary hosts retain
their existing policy. 4,284 focused checks across five existing clients; five
baseline-reject/candidate-pass pairs and two rejected Forever controls. All five
mirrored runtime hashes match.
Native physical input/combat/taint/pixels/performance pending; no connected test
tool, client interaction, settings/profiler writes or manual sync. External dated
2,351-file/history checkpoint and125 settings metadata verified. Full265-script/
932-syntax validation PASS; no source drift. Result linked in [scope and evidence](MENU_PRESS_INPUT.md).

9 November repository replacement completed per explicit request. Verified
2,340-file source ZIP,166-file on-disk settings ZIP and all-ref bundle externally;
preserved original index/config and both patches. Exported remote metadata;
zero issues/pulls/releases/tags/forks. GitHub device authorization completed for
the required deletion scope. Deleted old1416752820, created new1451123700 at the
same URL, and pushed fresh main root be90cdcc2f14 with2,344 files. Verified exact
remote tree, no parents, DoctorFlux author/committer and sole main branch; only
DoctorFlux in contributor API. Local main adopted that verified snapshot without
changing working files. Identity workflow42587961744 succeeded; five policy tests
and actual hook rejection pass. Lua manifest unchanged from263/930 PASS;
docs963sources/602reachable/15630links PASS. No runtime/settings changes or force
push. The CLI unexpectedly copied its device code despite no clipboard flag;
reported promptly. Later browser opening was explicitly authorized by the user.
Completion records are a normal follow-up publication commit.
Final repeat-push check reproduced an empty-input hook rejection on an already
up-to-date main. Allow that no-op while retaining complete checks for real
updates; regression and actual dry-run checks pass.
[Evidence](validation/repository-publication-2026-11-09.json).

9 November FOCUS-SECURE-VISIBILITY-20261109: preserved actual-file/history/settings
checkpoint before three runtime-owner edits. Replaced focus alpha-only watch
with existing native visibility service; paired lifecycle registration/removal;
retained prepared combat clicks. Broadened native unit-menu routing after user
reported player callback failures despite target success. Kept dependent menus
and native focus macros per explicit choice. Source verification covered20
primary blobs; local references stayed read-only, including a documented test
adjustment for Forever's no-argument native ClearFocus responder.70/670/620
focused checks PASS; five alternating before/after pairs and three old-owner
controls retained; full263 scripts/930 syntax PASS; manifest stable;15 synced
runtime copies match. Guarded background reload/read and native focus/clear test
passed on Forever70862 with BugTabs0, no foreground change and empty focus
restored. User confirms player-menu and combat macro acceptance. No profiling,
binding/settings changes, new polling, commit or push. Native group-menu,
physical hit testing, pixels/performance and other clients still pending.
[Report](FOCUS_SECURE_VISIBILITY.md).

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
checks, five repeated scenarios and four harmful controls pass. Full260-script/926-Lua validation and documentation959-source/601-load-closure
checks pass with zero source drift;15 installed source files match. Forever70862 public-save metadata
PASS; user reports the prior two-copy build worked. The final guarded reload was refused before input because WoW was foreground.
Single-profile native reload/persistence/save/combat/pixels and other clients
remain pending.
Keep WoW background; do not interrupt auction/mail/trade or gameplay. No profiler
change, native preset patch, commit or push. [Requirements/evidence](COOLDOWN_VIEWER_DEFAULTS.md).

8 November Edit Mode ownership (EDIT-MODE-NATIVE-20261108): read both logs,
current state and fresh five-client pins; verified external source/history/settings
checkpoint. Corrected four existing owners; actual-owner/native-method regression
and evidence-retention tests reject old code.295 focused; full259/924 PASS with
stable Lua corpus;22 blobs/60 exact native excerpts and20 installed copies verified.
User-operated Forever save/viewer reports no new errors; saved snapshots absent.
Background command guards refused before input; read-only capture left focus
unchanged. No automated saves/reloads/settings/profiling/gameplay. New cooldown
reference/default goal recorded; implementation in progress.
[Evidence](EDIT_MODE_NATIVE.md).

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

8 November universal mouseover (UNIVERSAL-MOUSEOVER-20261108): verified main
and external source/history/settings checkpoint before changing three runtime
owners. Preserved all existing dirty work, including Apply's prior pool-name fix.
Reproduced compiler gating/free-chord/extra and click-polarity failures against
the actual archived sources. Added tests with 916 assertions, native/fallback
modifiers, explicit rules, flags, form/rank, equipment extras and badge contracts;
five pairs reject203 old assertions and pass current; each old owner rejects
independently. Existing native4984/binding3210/bar suites pass. Full258 scripts/
923 syntax PASS; no Lua source drift. Fifteen fresh upstream blobs and15 installed
copy hashes recorded. Host process/window and read-only screenshot verify Forever;
foreground guard prevented input. No gameplay, reload, settings/profiler write,
focus/clipboard control or publication. Native checks remain pending.
[Evidence and steps](UNIVERSAL_MOUSEOVER.md).

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
verified external checkpoint2264source/188on-disk settings/history on main;
preserved unrelated work. Three runtime owners now use actual carried upgrades
for automatic marks/rules/display/availability/pending sales. Added1020checks;
five matched pairs reject baseline720failures and pass candidate; four controls
reject. Five optimization pairs remove6000warm redundant count queries with no
warm bag walks. Final255scripts/920syntax PASS
with unchanged source; earlier independent debuff-tint changes retained.
Twelve destination copies match via user sync. Native pending; no game input,
settings/profiler writes, commit or push. Source documentation and15,439local
links also PASS. [Results](CARRIED_COMBAT_CONSUMABLE_JUNK.md).

8 November stable owned grid buttons (GRID-STABLE-OWNED-20261108): external
checkpoint Craft-grid-placeholder-20261108T090008Z verified2258source files,
179on-disk settings and history; unrelated main work retained. Changed only the
classifier rejection query, potion eligibility and existing owned-slot gate.
Added620transition/craft/zero/mode/combat checks; five alternating matched pairs
reject baseline224assertions and pass candidate, with three negative controls.
Placeholder calls36 ->0; visibility transitions76 ->0; rebinds20 ->0 across30cases.
Full253/253scripts and917syntax PASS; source guard unchanged. Twelve installed
copies match via existing continuous sync. Native pending; no input/reload,
profiler/settings writes, commit or push. Generated documentation/source coverage
and15,410local links also PASS. [Results](CONSUMABLE_CRAFT_IDENTITY.md).

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
Fresh external checkpoint/history and 45 read-only settings metadata entries kept;
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
and constant layout arithmetic. External history/source checkpoint verified and 45
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
Full run:894 syntax PASS; 229/230 scripts PASS. The sole failure is the
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
no manual client copy performed. Source/history checkpoint and 45 on-disk Flux settings metadata entries verified
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
Final meter checks: all11 focused meter/threat scripts PASS; 220 native-control
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
Final workspace refresh after unrelated UnitFrames changes:207 scripts/869
Lua syntax PASS with unchanged corpus; the earlier206/868 raid run is retained.
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

7 November class travel/restock: inspected current main, rules/specifications
and travel/reagent/preset owners; preserved concurrent aura work. Verified three
external source/history/settings checkpoints. Reproduced cold rune, Soul Shard,
missing editor and preset-classification failures. A final audit found native
spellbook flyout costs were skipped; extended existing Core.Spell fallbacks and
indexed known children with override selection/deduplication. Four runtime files
reuse existing persistence/editor/index; no new polling.
130 travel + 47 scanner/list/facade checks; 16 faulty mutations rejected; five
alternating pairs per component. Warmed travel fixture: 1,000 tooltip scans to
zero, unchanged reagent results; raw host samples retained, no native FPS claim.
Scoped replay passes all six required scripts with unchanged reagent sources.
The last whole-addon run passed 200 of 204 scripts and all 866 syntax files;
four raid-test failures and unrelated source drift prevent a whole-tree PASS.
All four runtime files match the four existing client copies (16 hashes). A
manual-copy verification stopped during active continuous sync; three later
read passes confirmed every candidate, with external destination backups.
Documentation validation also remains blocked by concurrent raid edits: one stale source-inventory entry and three verification hashes. The checker made no edits; reagent source/test hashes remain matched.
Baseline background transport completed without a visible FX marker in the busy
auction/craft capture; native candidate checks pending. No test purchases,
settings/profiler change, new branch or commit/push.
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

7 November background/native follow-up: verified current main and new external
Unit-secret-followup-20261106T224752Z checkpoint (1683 actual files/179 settings;
ZIPs/all-ref history verified). Forever background name probes showed earlier
fix functions loaded/profile0/BugTabs0; later short count also0. Read-only
captures show user-driven auction/mail/casting activity, not measured latency.
Reproduced restricted cooldown comparisons through actual BadgeHost; retained
scalar/tuple/public output rules and added public metadata for restricted timers.
Removed proven unused PCO width snapshots; active ghost/animation bodies intact.
150 new checks/10 mutants; final199/861 full validation PASS, unchanged source.
Five matched pairs/client or power scenario record counts/raw host intervals;
no native FPS claim. Copied five files to four clients with external backups,
20 hashes match. User reloaded and performed ordinary combat; native cleanup
marker=nil and BugTabs0 afterward. Combat frame/action/cooldown/threat rendering
observed; direct restricted-case/swap/pixel/performance/other-client checks pending.
An app-switch helper change was auto-review rejected and not run; original
strict background guard retained. Interrupted probes are unexecuted and not
acceptance; no verified owned draft remained in later captures. No commit/push.
[Case](UNIT_STATE_SECRETS.md#follow-up-badges-and-unused-power-snapshots).

6 November unit-state errors: verified actual main/dirty source and external
Secret-unit-state-20261106T215659Z checkpoint (1674 files/197 settings plus all-ref
history; archives verified). Reproduced Name/ProgramFace/overlay failures with
actual modules; corrected predicate order and readable identity caches. Review
also caught opaque-start/public-finish feedback and pet replacement, now covered.
Four new scripts:344 checks/23 mutants; final197-script/859-Lua suite PASS with
unchanged source. Public names/key formats and feedback work/resource counts
preserved in five alternating desktop pairs; safety gates add host overhead.
Copied only five runtime files to four existing clients after verified external
backups;20 hashes match. Exact Forever host/window verified; capture succeeded,
background reload refused before input because game was active. No profiler or
settings change, native acceptance, random-freeze resolution or commit/push claim.
User reports TacoTip unloaded and chose read-only; no third-party edit.
[Case](UNIT_STATE_SECRETS.md), [samples](validation/unit-state-secret-comparison-2026-11-06.json).

6 November TacoTip error audit: inspected current tree/continuity and preserved
newer raid/aura changes. Read installed0.9.4 source/license and compared native
Backdrop size callback/arithmetic. The owned overlay is a source-matched suspect;
exact native frame remains unverified. Existing Flux tooltip integration does
not implement its border. Desktop fragment replay reproduces secret-width
arithmetic; no native safety or performance claim. Requested scope clarification
before any third-party edit; the user chose read-only. No TacoTip changes are planned. No runtime or game changes from that audit.
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

6 November native follow-up: after the background guard again refused input
before sending any command, the user ran the read-only map probe with Map
visible and pasted `FXMAP true true 0`. Recorded as user-reported native
provenance/error acceptance only. No hot restoration of native fields, reporter
suppression, profiler change or physical input was used. Requested a fresh
optional600-second spike watch to investigate any remaining random freeze.
[After](validation/map-provider-native-after-2026-11-06.json).

6 November map batches completed: verified external recovery checkpoints
Random-spike-resume-20261106T170042Z and Map-provider-combat-before-20261106T171453Z.
Actual normal Map tab activation changed shared method provenance from secure
to_FluxUI. Fixed detached quest/waypoint callback and handler retention, stale
quest timers, then removed shared native overrides and guarded owned restricted
acquisition.31/36 focused checks and mutation regressions pass; five alternating
pairs retain exact source/count/raw host-clock scope.193 scripts/855 syntax pass
with unchanged corpus. Preserved old copies externally and copied this one
changed runtime file to all four existing client installs. Forever reloaded
17:28:52UTC; native post-activation probe blocked while game foreground, with
no completed command on the ready attempt. No native performance or all-client
acceptance claim. [Case](MAP_PROVIDER_LIFECYCLE.md).

6 November resumed at the user's request. Verified fresh external source,
all-ref history and on-disk settings checkpoint Random-spike-resume-20261106T170042Z
(1,660 actual files /190 settings, ZIPs and bundle verified). New Forever process
and exact window were verified; no active watch and live scriptProfile=0.
Normal Map tab activation changed shared native pin methods from secure to
_FluxUI tainted. Meter tab restored; no FPS or causal freeze claim. Fixing
owned-provider detach leaks first, then reviewing restricted pin ownership.
[Native baseline](validation/map-provider-native-baseline-2026-11-06.json).

6 November user-requested pause: stopped audit agents and all further native
input/runtime work. Preserved final191/853 no-drift desktop validation and the
current local main work. The v2 native watch ended early at a reload/logout
boundary after239.516s; recorded one3185ms gap with2.2509ms nearest Flux time,
plus12 later SetPassThroughButtons blocked-action repeats. Exact freeze cause
is not established. A shared native-map mixin rewrite is an unsafe source lead
requiring owned-provider lifecycle verification; no map change was made.
NEXT_SESSION.md records exact next steps. No lag-batch commit or push.

6 November Forever badge handoff follow-up: user accepted main↔mini glow in
combat, but reported bar→badge glow disappearance and missing badge icon on
combat row swap. Verified the dated external badge-handoff source/history
checkpoint and existing SAO saved-setting key. Traced reverse badge candidate
omission, clipped proc border, and dormant badge without ActionType/SpellId.
Changed badge preparation/show/hide and combat-only visual face paint. Old
BadgeHost fails the new icon fixture; candidate passes 11/25/7 focused paging,
preparation and row-swap checks plus 77 glow checks. Full desktop run passes
190 scripts / 852 Lua syntax files. After `/reload`, user confirmed modern
glow following bar↔badge both ways and clearing at proc end, plus badge
icon/count/cooldown following the action main↔mini during combat. Taint,
pixels, matched frame time, other procs and clients remain unverified.
[Case](FOREVER_SAO_GLOW.md#badge-handoff-and-combat-row-icon-follow-up-current).

Native follow-up16:29UTC: ExtraButtons, CombatGrid and NonCombatGrid enabled;
current-session BugTabs errors0; profiler0. Watchv2 confirmed running600s /
200ms in Forever; completion/save and analysis pending.
[Startup](validation/ebs-glow-startup-native-2026-11-06.json),
[arming](validation/forever-random-spikes-v2-armed-2026-11-06.json).

6 November random-spike evidence and bounded fixes: preserved external
Random-spike-diagnosis-20261106T143953Z and
Random-spike-finer-capture-20261106T153942Z source/history/settings checkpoints.
Reproduced1000 duplicate same-frame EBS layout callbacks and coalesced them to1
while preserving reasons, reentrancy and direct Flush. Added exclusive owned
callback timing observers and optional bounded watchv2 in existing FluxPerf.
Cached only unchanged writes to the stance module's owned aura text; formatting,
expiry, native digit reconciliation and per-frame response remain intact.
Focused checks:89 layout,1066 observers,119 watch,2075 aura text. The frozen
v2 full-tree run passed186 scripts /848 Lua syntax files before concurrent glow
changes. Read and preserved the user's native seven-gap watch and120-second
CPU profile; scriptProfile0 was independently read live. Specific random-spike
cause, leaks and native optimization acceptance remain pending.

Preserved the newer Grid-startup-error-20261106T161936Z checkpoint
(1638 actual files,184 settings, verified ZIPs/all-ref bundle) before checking
reported Paint3403 startup errors. Saved history has 3 records/38 repeats,
all before the current file; Retail/Forever disk copies match. A diagnostic
using unavailable debug.getinfo failed separately and was replaced by a
nil-safe read-only probe. Background guards block input whenever WoW is active.
[RANDOM_SPIKES.md](RANDOM_SPIKES.md) records scope and remaining checks.

6 November Forever SAO main/mini and badge follow-up: user confirmed the
previous secure slot starts the Retail glow during combat, then reported failed
modifier and badge handoff. Verified external
`FluxUI-forever-secure-proc-paging-20261106` checkpoint and existing enabled
SAO setting. Prepared potential row/badge destinations OOC and added alpha-only
face gating in the existing effects owners. Saved Effects.lua fails the new
first assertion; candidate paging model passes 9, glow model 77, and full
desktop runner 187 scripts / 849 Lua syntax files. Native handoff, clearing,
taint, pixels and frame time remain pending.
[Case](FOREVER_SAO_GLOW.md#mainmini-and-badge-handoff-follow-up-newest).

6 November Forever SAO combat glow: verified external
`FluxUI-forever-secure-proc-20261106` source/history checkpoint and read the
installed SAO glow-enabled setting. Compared Gethe Retail/Forever/Era/
Anniversary button alert flow and Forever secure AuraContainer source.
Added a filtered 400589 secure slot with Retail flipbook animation to resolved
Arcane Missiles widgets; removed duplicate readable fallback once prepared.
Focused tests pass 69 checks, full runner 186 scripts / 848 Lua syntax files.
Installed Forever Glow.lua matches the repository hash. Native combat and
proc-end validation are pending.
[Case](FOREVER_SAO_GLOW.md#secure-auracontainer-button-animation-candidate-latest).

6 November consumable follow-up: verified external all-ref checkpoint at
`48ea994`; inspected Retail/Forever settings read-only. Added public aura-delta
tracking, direct readable flask scan, weapon-enchant events and modern API
fallback. Five paired loaded-module runs: 46 baseline / 66 candidate checks;
candidate binds the next secure item action for flask and weapon cases. Timer
35 and weapon-target 30 checks pass. Full desktop runner passes 185 scripts /
847 Lua files. Read-only docs checker reports 23 stale generated entries in
this and concurrent raid/performance work; native acceptance is pending.
[Case](CONSUMABLE_REFRESH_TIMER.md#aura-and-weapon-enchant-follow-up--6-november-2026).

6 November consumable aura advance: verified external all-ref bundle at
`ef813e0`; read-only Retail/Forever settings inspection. Five baseline/candidate
loaded-module pairs reproduce the 200 ms wait and pass immediate advance on
modern/legacy aura APIs (11/22 checks each). Existing refresh/weapon fixtures
pass 35/30; all 845 Lua files pass syntax. Native results remain pending.
[Details](CONSUMABLE_REFRESH_TIMER.md#immediate-advance-after-aura-gain--6-november-2026).

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

6 November Well Fed refresh follow-up: prechange main `582d868` and a verified
external all-ref bundle preserved; installed settings were inspected read-only.
The previous source failed a loaded-module alternate Well Fed aura fixture.
The candidate finds it, reuses its public ID, and shows the shared 25 minute
timer in the button/config until the 5 minute threshold. Focused timer and
weapon-target fixtures pass 35/30 checks; native client results are pending.
[Details](CONSUMABLE_REFRESH_TIMER.md#well-fed-follow-up--6-november-2026).

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

6 November runtime inventory and scope decision: main was clean at
`0f2e3fdaddb2105eea6afdd1058b96e85308180a`. External
Meter-runtime-inventory-20261106T113256Z preserves 1,596 actual sources,
177 settings files and all-ref history; ZIP/bundle checks pass. Source archive
SHA256: `3eebba4234ea4d02b899dde9d3e4e479319e05bd34845a57d26165d633ff01f5`.
User live `FXDM` returned the eight documented methods; corrected `FXCV` showed
only enable/show-UI and new-instance reset, then `FXCV DONE`. The original helper
macro concatenated nil help and caused its own 12:27:14 RunScript error. It was
acknowledged and corrected; scratch checks cover nil help/nil command and the
user's corrected query succeeded. No addon runtime edit or setting change.
Separate user reports at 11:45:22 (durationSeconds:929) and 11:45:26
(specIconID:535) remain native taint evidence. Inventory after a reload request
is not an explicit loaded fingerprint or error-clean acceptance. The 30-second
background read-only attempt at 11:25:15 UTC was refused before the first posted
message and zero characters were typed. Native cleanup/combat checks remain pending.
The user explicitly chose every native feature preserved and automatic Current
left blocked. Its implementation is frozen; no substitute/manual setup completion,
writer/reset or new experiment. Concurrent glow state preserved.
[Scope](METER_STANDALONE.md#automatic-current-requirement-and-supported-api-gap), [source audit](validation/meter-automatic-current-capability-2026-11-06.json).

6 November supported-route audit: main was clean at
`d4a45fbdc63229074af97853d7ec871cbb857162`. External
Meter-supported-current-audit-20261106T110157Z preserves 1,595 actual sources,
177 settings files and all-ref history; ZIP and bundle checks pass. Source archive
SHA256: `c6f2d2a58c8c226c42e7e16f3e486e714a612d406edd47a76953cf50ba860e50`.
Fresh Forever 70790 and Retail 70783 source at the pinned commits matched the
prior audit. Native owner/factory defaults are Overall; public DamageMeter APIs,
Edit Mode fields, Advanced Options and XML supply no Current default/setter.
The native session menu calls the already rejected private setter. An owned
Current renderer cannot promise combat source drilldown with the audited GUID/
query restrictions. Automatic Current for every existing/future pane remains
OPEN; manual selection is not completion. No runtime edit or new experiment.
Passive captures at 11:02:01 and 11:06:07 UTC found Forever PID 37088/window
341447356 and host executable 70790, with game foreground. The guarded reload
wait expired before any input or completed command. Loaded identity, cleanup and
combat/two-fight acceptance remain pending. No settings, profiler or hardware
changes. Concurrent glow state preserved. [Audit](validation/meter-automatic-current-capability-2026-11-06.json).

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

Options native-readiness audit (9 November): all twelve owned runtime/test files
remain identical to the sorting evidence; their Lua identities also match the
later 272-script/942-syntax RestedXP validation. Current tools, all five installed
client folders and MCP headers confirm no Witchcraft connection/installation.
Read-only host verification and PrintWindow show Forever gameplay with settings
closed; no native candidate appearance/input pass is inferred. No input/focus,
settings/profiler writes or setup changes. Required native acceptance remains
open; see `validation/options-native-readiness-2026-11-09.json`.


Native continuation17:40UTC: Forever background readback confirms zero session errors, solo/OOC, profiling0, all three merchant input toggles configured, party v7 ready/secure with four hidden solo members. No runtime/settings/gameplay changes. User reports a real test party/raid with combat roster changes is unavailable now; actual combat/grouped acceptance remains pending. First consecutive unavailable-scenario audit; goal active. See FOREVER_NATIVE_PERFORMANCE.md and its validation JSON.

9 November goal blocker audit3: actual combat roster and grouped performance acceptance remain unavailable after three consecutive goal turns. User cannot arrange the real test group now. Goal blocked pending that scenario; no new runtime, input, settings or profiler changes. Completed evidence and exact pending checks remain in FOREVER_NATIVE_PERFORMANCE.md.
