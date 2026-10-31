# Work log

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
