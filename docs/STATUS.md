# Development status

31 October nameplate backdrop correction: school artwork now draws from a
Flux host at the plate's frame level, behind Blizzard cast and health chrome.
The unit-frame backdrop, school fill and tip keep their existing placement.
The focused layer regression rejects the previous source; full desktop
validation passes 112 tests/757 Lua files. Native pixels, taint and frame
time remain pending. [Evidence](NAMEPLATE_BACKDROP_LAYER.md).

31 October combat grid usability: mana gem and healthstone now darken while
dead/ghost and respect a live unusable item result once bags settle. Focused
14-check loaded-paint regression and full 111-test/756-Lua desktop validation
pass. Native tint, clicks, taint, pixels and performance remain pending.
[Evidence](COMBAT_GRID_CONJURED_USABILITY.md).

31 October cast-school correction: the first nameplate integration put the
unit-frame fill on its outer frame and left Blizzard's nameplate fill opaque.
The shared renderer now paints on the actual progress bar, hides/restores the
native fill and tints/restores the moving tip spark to the school. The focused
regression fails against the previous source and passes after correction;
full desktop validation passes 110 tests/755 Lua files. Native pixels,
combat taint and performance remain pending. [Evidence](CAST_SCHOOL_FILL_TIP_FIX.md).

31 October 2026: Blizzard's nameplate casting bars now receive the shared
unit-frame school colors and effects on Retail, Forever, Era and Anniversary
when spell identity is readable. Secret/unknown identities retain native
appearance. The native status bar remains the cast owner. Focused 48-check
nameplate model and full 110-script/755-Lua desktop validation pass; native
combat taint, pixels and performance are pending. [Evidence](NAMEPLATE_CASTBAR_SCHOOLS.md).

Latest publication batch (30 October): all local stance-scale, loot-source and
Micro Menu fixes included for main. All 753 Lua hashes match the passing
109-test combined report. Native acceptance remains pending.

MicroMenu nil-center correction (30 October 2026): selected and unused
native children leave Blizzard's MicroMenu before Flux shows or hides them,
preventing the reported `GetEdgeButton` nil-center path in the desktop
regression. Full validation passes 109 tests / 753 syntax files. Native
post-fix reload and five-client placement/taint/performance remain pending.
[Evidence](17-micromenu.md).

Delayed loot correction (30 October 2026): closed mob/chest sessions retain
their cursor origin for 30 seconds. Matching item, currency and money reports
use the saved source even after another source opens; late slot/chat reports
are deduplicated. Desktop validation: 108 scripts / 752 syntax files pass.
Native five-client event order, placement and performance remain pending.
[Evidence](LOOT_CURSOR.md).

Cursor-position correction (30 October 2026): loot rows now retain the
cursor snapshot from LOOT_READY/LOOT_OPENED; later rows and overlapping loot
batches cannot move earlier rows when the mouse moves. Focused desktop and
full validation pass: 108 scripts / 752 Lua syntax files. Native five-client
pixels and event timing remain pending. [Evidence](LOOT_CURSOR.md).


Loot-source correction (30 October 2026): cursor alerts now exclude crafted,
pushed/rewarded and ordinary outside-window bag gains; loot slots, bonus and
group rolls remain. Currency requires a recent loot window. Focused desktop
checks and full validation pass: 108 scripts / 752 Lua syntax files. Native
classification and five-client acceptance remain pending.
[Evidence](LOOT_CURSOR.md).


30 October 2026: attached stance bars now follow player-frame scale, including
immediate slider changes and reload; detached placement restores normal size.
Existing combat deferral is retained. 21 stance and 28 bridge checks pass;
full suite: 108 scripts /752 Lua syntax files, zero failures. Native pixels,
input and taint remain pending (no visible WoW process).
[Evidence and native steps](UNIT_FRAME_SCALE.md).

Current publication batch (30 October): all local cursor loot, fast pickup,
options, coin art and callback updates are included for main. Native checks
retain their pending scope in the loot chapter.

Cursor loot callback correction (30 October 2026): the user's native startup
trace showed CallbackHandler received a table instead of an event string.
FluxLoot now uses the same receiver/event/method order as FluxOptions. The
focused fixture reproduced the old failure and passes after the fix; full
desktop suite: 107 scripts / 751 Lua syntax files, zero failures. Native
post-fix login and profile switching remain pending. [Evidence](LOOT_CURSOR.md).


Cursor money alerts (30 October 2026): received gold, silver and copper now
show coin symbols with white numbers; the leading icon reflects the highest
denomination. Localized money templates are parsed once at load. Focused
checks and full desktop validation pass (107 scripts / 751 Lua files).
Native five-client art, locale, taint and performance remain pending.
[Evidence](LOOT_CURSOR.md).


Cursor loot default follow-up (30 October 2026): fast pickup and cursor alerts
now both default on for all five supported clients. The duration control is
explicitly **Disappear after (seconds)**, default 3 seconds. Existing saved
values remain intact. [Evidence](LOOT_CURSOR.md).
Focused and full desktop checks pass: 107 scripts / 751 syntax files;
native validation remains pending.


Cursor loot (30 October 2026): Tools → Loot now offers independent fast pickup
and cursor alerts with simple money, currency, rarity and duration settings.
The installed FasterLoot retains pickup ownership while loaded. Focused
desktop event checks and full validation pass: 107 scripts / 751 Lua syntax
files. Native five-client loot, pixels, taint and performance remain pending.
[Evidence](LOOT_CURSOR.md).

Latest publication batch (30 October 2026): current first-load settings and
Hearthstone fixes included for main. Combined desktop validation: 106 scripts,
748 Lua syntax files, zero failures. Native acceptance remains pending.

Historical Sticky Targeting follow-up (30 October 2026): the linked GitHub
main file matches the pre-fix local routine. An older dated local FluxUI
snapshot used Blizzard's registered negated Controls setting. The current
Retail path now uses that exact native setting for Sticky Targeting only,
with CVar readback/fallback; protected raid/nameplate Settings callbacks
remain guarded. Focused desktop checks: 75. Native acceptance is pending.
[Evidence](RETAIL_CONTROLS_CAMERA_FIX.md).

Retail Sticky Targeting/camera follow-up (30 October 2026): the user observed
`deselectOnClick=0`, camera factor `1.9` and no engine CVar maximum after the
first-load audit failed. The audit now includes the native sticky CVar; the
Retail camera fallback is 2.6 when the engine reports no maximum. A failed
audit gets one settings-only retry on the next login. Focused desktop checks:
68. Native post-fix acceptance and frame time are pending.
[Evidence](RETAIL_CONTROLS_CAMERA_FIX.md).

First-load nonbinding defaults (30 October 2026): account and new-character
passes now run after first world entry and reconcile supported settings after
native startup. Controls, nameplate scope, Classic raid CVars and quiet
completion are covered by 60 focused checks; the 106-script/748-Lua desktop
suite passes. Native client acceptance and frame time remain pending.
[Evidence](NONBINDING_FIRST_LOAD.md).

Hearthstone selector hover follow-up (30 October 2026): the user's native
stack trace reports a nil `GetItemInfo` at selector hover. The handler now
uses the existing `Flux.Item` service and Toy Box name fallback. The corrected
19-check fixture reproduces the old error and passes with the fix; full
106-script/748-Lua desktop validation passes. Native hover, selection, secure
use and persistence remain pending. [Evidence](HEARTH_CONFIG_TOY_COLLECTION.md).

Hearthstone config follow-up (30 October 2026): the user still saw no panel
beside the Toy Box. The first regression had injected `FLUX_API` before its
actual TOC load. The editor now gates on the already-loaded `Flux.Cap`, so its
window and command register before the later API bootstrap. The corrected
17-check fixture fails against the prior code and passes after the fix; full
106-script/748-Lua desktop validation passes. Native visibility and toy use
remain pending. [Evidence](HEARTH_CONFIG_TOY_COLLECTION.md).

Earlier Hearthstone Toy Box config attempt (30 October 2026): the Toy Box
capability no longer requires a particular Collections Journal toggle function.
This alone did not register the editor because `FLUX_API` loaded later.
The journal loader/opener accepts modern and legacy APIs. The first 14-check
desktop regression missed the TOC load-order defect; native toy
selection, persistence, secure use, pixels and frame time remain pending.
[Evidence](HEARTH_CONFIG_TOY_COLLECTION.md).

Binding atomic-context follow-up (30 October 2026): after the user's native
assignment failure report, the first-account keyboard transaction now clears,
assigns, verifies and saves in one call. Modern clients use Blizzard's action
binding context; only unresolved keys receive up to three immediate attempts.
The failure message names the key. Focused 507 checks and full 105-script/
747-Lua desktop validation pass. Mariosuper Era and Pandasans Retail native
checks remain pending because neither WoW process/window was visible to this
workspace; transient WTF files were read-only evidence only. [Evidence](BINDING_ATOMIC_CONTEXT.md).

Binding persistence rewrite (30 October 2026): Retail's closed account
binding cache contained only a modified-click row while saved marker 5 claimed
completion. The startup combat-settings pack had called SaveBindings before
native keys were loaded. The rewritten first-account pass now saves only after
the template is assigned, reloads the native account set, verifies it and then
records saved6, then confirms version 6 after the next login. Existing
version-5 empty caches get one migration
repair. Focused 501 checks and full 105-script/747-Lua desktop suite pass;
native reload acceptance remains pending.
[Evidence](BINDING_PERSISTENCE_REWRITE.md). This supersedes earlier gates.

Binding repeat follow-up (30 October 2026): the user still saw the exact
"Applying keybindings..." line after reload on existing accounts. The previous
code retained `account = "pending"` when a pass wrote keys but failed its final
verification/save, so another reload could start another full clear. The
automatic attempt is now consumed before its first `SetBinding`; old pending
markers and existing native bridge bindings suppress another pass. New
accounts still start on the first world-entry frame. 544 focused checks and
105-script/747-Lua full desktop validation pass; native acceptance pending.
[Evidence](ACCOUNT_BINDINGS_ONCE.md). This supersedes the earlier success-only
retry description below.

Account-only binding correction (30 October 2026): the user reports automatic
keybinding setup on every login/character. The earlier marker was scoped to
the active character set. A first-account bootstrap now owns the only
automatic full keyboard pass; completed accounts and new characters skip it.
Blizzard Settings reset callbacks no longer replay Flux keybindings. The
closed Retail account cache contained all four bridge commands while the
newer completion table was empty, so this existing account migrates without
a new reset. Focused 528 checks and the 105-script/747-Lua desktop suite pass;
native acceptance remains pending. [Evidence](ACCOUNT_BINDINGS_ONCE.md).

One-time binding correction (30 October 2026): the user clarified that the
full reset must happen only once and asked to avoid lag. Version 4 now marks
the active binding set complete after one verified save. Subsequent logins
skip the registry scan and writes; late `UPDATE_BINDINGS` no longer replays
the reset. One registry scan and at most eight binding writes per frame are
modeled in 521 focused checks. Native timing and input remain pending.
[Evidence](FULL_BINDING_RESET.md). This supersedes the earlier binding
completion notes below.

Full binding reset follow-up (30 October 2026): the user reports that bridge
keys still never assigned and explicitly requests clearing all bindings before
applying the complete Flux template on every client. The active native account
or character set now gets a one-time batched clear/apply, full supported
template check, save and version-4 cross-login verification. Late native
binding changes trigger bounded same-login repair. Focused 521 checks across
five modeled clients and full 105-script/747-Lua validation pass; native key
presses and persistence remain pending. [Evidence](FULL_BINDING_RESET.md).

Full binding reset follow-up (30 October 2026): the user reports that bridge
keys still never assigned and explicitly requests clearing all bindings before
applying the complete Flux template on every client. The active native account
or character set now gets a one-time batched clear/apply, full supported
template check, save and version-4 cross-login verification. Late native
binding changes trigger bounded same-login repair. Focused 521 checks across
five modeled clients and full 105-script/747-Lua validation pass; native key
presses and persistence remain pending. [Evidence](FULL_BINDING_RESET.md).

Binding persistence follow-up (30 October 2026): the first-account batch could
commit the bridge-key completion marker before its late native-set check.
Version 3 keeps that marker pending until a following login confirms the saved
commands survived; lost keys are repaired and saved again. Old version-2
markers recheck. Focused 37 checks and the 105-script/747-Lua desktop suite
pass; native reload persistence remains pending. [Evidence](DEFAULT_GRID_BINDINGS.md).

Raid settings follow-up (30 October 2026): the user chose to retain the
Retail/Forever native compact-frame taint guard. Flux-owned live raid cells
and preview now use Flux class colors, power bars, health text and aura options
even when Blizzard CVars differ; existing own frame sizing still applies on
world entry. Blizzard's Interface values remain native-owned. Nine focused
checks and the 105-script/747-Lua desktop suite pass; native first-load,
combat and Edit Mode acceptance is pending. [Evidence](RAID_OWNED_SETTINGS.md).

Raid settings follow-up (30 October 2026): the user chose to retain the
Retail/Forever native compact-frame taint guard. Flux-owned live raid cells
and preview now use Flux class colors, power bars, health text and aura options
even when Blizzard CVars differ; existing own frame sizing still applies on
world entry. Blizzard's Interface values remain native-owned. Nine focused
checks and the 105-script/747-Lua desktop suite pass; native first-load,
combat and Edit Mode acceptance is pending. [Evidence](RAID_OWNED_SETTINGS.md).

Raid/nameplate defaults follow-up (30 October 2026): Classic native raid
profiles now retry when the active profile is not ready, then reapply the raid
CVar pack after loading. Medium nameplate size `2` replaces the old `3` in
both default sources; existing `3` values migrate once while other sizes are
retained. Retail/Forever native compact-frame writes remain guarded for taint
safety. Focused 15 checks and full 104-script/746-Lua desktop validation pass;
native all-client acceptance remains pending. [Evidence](RAID_NAMEPLATE_DEFAULTS.md).

Same-login grid binding follow-up (30 October 2026): the user observed that
the prior repair still did not assign bridge-button keys on first load. The
seed now runs at first world entry, verifies again shortly after, retries
unavailable native sets within the login, replaces stock achievement `Y`, and
upgrades old completion markers. Grid hotkey refresh now uses the live EBS
registry and visits every loaded combat module. Focused 29 binding and 7 label
checks and full 103-script/745-Lua desktop validation pass; native first-load
clicks and labels on all clients remain pending.
[Evidence](DEFAULT_GRID_BINDINGS.md).

Default grid binding follow-up (30 October 2026): first-account, new-character
and previously seen binding sets now seed missing Flux template commands without
clearing custom keys. The reported Hearthstone/teleport/mount keys were absent
from one on-disk Retail binding cache. Focused 21 checks and full 102-script/
744-Lua desktop suite pass; native click and all-client acceptance remain
pending. See [the binding record](DEFAULT_GRID_BINDINGS.md).

First-login defaults follow-up (30 October 2026): a new character now receives
only client-reported character-stored Flux CVars and nameplate bitfields, plus
existing raid/chat setup. Account values and custom keys stay untouched; failed or deferred
character CVar work leaves the character unseen until completion. Focused 42 checks and
full desktop validation pass: 101 scripts/743 Lua syntax files. Native first
account/new-character checks on every client remain pending. See
[the defaults record](DEFAULTS_FIRST_LOGIN.md).

Current publication batch (30 October 2026): all local scale, vehicle/durability,
status-bar and vendor message updates are included for main. Fresh combined
validation passes **100 scripts /741 Lua syntax files, zero failures**.
See [publication record](GITHUB_PUBLICATION.md). Native pending checks remain pending.

Vendor chat follow-up (30 October 2026): repair, standalone junk sale and net
vendor money lines now show gold/silver/copper denominations with matching coin
symbols. The reported 3,494,236 copper displays as 349 gold, 42 silver, 36 copper.
Focused chat and existing vendor identity checks pass; full desktop validation
passes 100 scripts/741 Lua syntax files. Native chat texture rendering remains
pending. No game or settings interaction.

Unit-frame scale follow-up (30 October 2026): corrected portrait centering and
focus alignment for scaled frame coordinates. Player and side-by-side target
now clear the action strip at both smaller and larger sizes; scaled strip
coordinates are converted to UIParent space. The 3D portrait reframes only
when scale changes. Focused 23 checks and the full 99-script/740-Lua desktop
suite pass; native geometry, pixels and combat/taint remain pending.

Latest unit-frame scale (30 October 2026): Unit Frames now has a shared
player/target whole-frame scale and a separate focus scale, each 50–200% with
100% default. Attached cast bars, auras, portraits, indicators, dependent
target frames and supported class resources follow the parent scale. The
focused production-bridge check passes; full desktop validation and native
acceptance are recorded in [the scale chapter](UNIT_FRAME_SCALE.md).

Latest vehicle/durability layout (30 October 2026): the 70%-scale seat indicator
sits left of the equipment durability frame. When either visible micro menu or
status strip occupies the top-left, both sit below the lower chrome frame while
the strip stays fixed. With clear chrome they start at the screen top-left; a
top-left PvP widget keeps its clearance. Focused source-driven anchor checks
and the full 99-script/740-Lua desktop suite pass. Native seat art, click
geometry, combat and all-client pixels remain
pending. No game, settings or profiler interaction.

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
Published to GitHub main in `c313dc98a1e782aee1224554c347cd616f3ad7af`;
no game/settings interaction.

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
