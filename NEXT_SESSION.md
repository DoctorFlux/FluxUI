# Next session

Current publication batch (30 October): all local cursor loot, fast pickup,
options, coin art and callback updates are included for main. Native checks
retain their pending scope in the loot chapter.

FluxLoot callback correction (30 October): verify a real login/reload emits
no `RegisterCallback` event-name error, then change, copy and reset a profile
and confirm loot events follow the selected profile. Repeat on each supported
client when available in the background; preserve settings and profiler
preferences. The user's stack proves the old failure, while desktop fixture
and full suite pass after correction. [Evidence](docs/LOOT_CURSOR.md).


Cursor money alert follow-up (30 October): verify real received amounts on
all five supported clients: copper-only, exactly 1 silver, mixed silver and
copper, exactly 1 gold, and mixed gold/silver/copper. Check white numbers,
coin symbols, threshold-selected leading icon, localized chat variants,
3-second expiry, pixels, taint and frame time. Desktop checks pass; native
acceptance remains pending. [Evidence](docs/LOOT_CURSOR.md).


Cursor loot default follow-up (30 October): verify new profiles on each of the
five supported clients start with fast pickup and cursor alerts on and
**Disappear after (seconds)** at 3. Check that existing saved choices persist
and the installed FasterLoot still owns pickup while enabled. Native checks
remain pending. [Evidence](docs/LOOT_CURSOR.md).


Cursor loot (30 October 2026): verify Tools → Loot on Era, Anniversary,
MoP Classic, Retail Midnight and Forever, sequentially in the background.
Check loot speed with FasterLoot both enabled and disabled, cursor placement,
localized self-loot/money/currency, repeated identical items, group rolls,
rarity, toggles, reload persistence, combat/taint, pixels and frame time.
Desktop event fixture and 107-script/751-Lua suite pass; these do not certify
native acceptance. [Evidence](docs/LOOT_CURSOR.md).


Latest publication batch (30 October 2026): current first-load settings and
Hearthstone fixes included for main. Combined desktop validation: 106 scripts,
748 Lua syntax files, zero failures. Native acceptance remains pending.

Historical Sticky Targeting follow-up (30 October 2026): verify the new
single-setting native Controls route on Pandasans Retail when its process is
available in the background. Check `deselectOnClick=1`, unchecked Settings
checkbox, first-load completion, reload persistence, manual Controls reset,
taint and frame time. The linked GitHub main source itself matches the old
local route; the 13 August local pre-rewrite snapshot supplied the distinct
native setting call. Focused desktop fixture passes 76 checks.
[Evidence](docs/RETAIL_CONTROLS_CAMERA_FIX.md).

Retail Controls follow-up (30 October 2026): check Pandasans in the real
Retail client when available in the background. Verify Sticky Targeting is
unchecked (`deselectOnClick=1`), camera factor reaches the accepted 2.6
fallback, the prior failed audit retries once without keybinding work, and
the next reload stays quiet. Check manual Controls reset, taint and frame
time. Mariosuper Era and other client checks remain pending. The user's
pre-fix Retail values were `1.900000 / nil / 0`; desktop fixture passes 68
checks. [Evidence](docs/RETAIL_CONTROLS_CAMERA_FIX.md).

First-load settings follow-up (30 October 2026): native first-account and
new-character checks are pending. Verify Controls (auto loot, sticky target,
interact, camera), nameplate size 2 and character scope, raid appearance,
quiet single completion, later reload preservation, and manual Reset All /
Reset These Settings. Check Mariosuper Era and Pandasans Retail in the
background when available, plus Anniversary, Mists and Forever. Record
protected-frame taint and frame-time evidence without changing profiler
preferences. Desktop suite: 106 scripts/748 Lua; first-load fixture: 60
checks. [Evidence](docs/NONBINDING_FIRST_LOAD.md).

Hearthstone selector hover follow-up (30 October 2026): the user's native
error at line 491 was a direct `GetItemInfo` call with that global absent.
The selector now uses `Flux.Item.GetInfo` and Toy Box name fallback. Focused
19-check regression and full 106-script/748-Lua desktop suite pass. Verify
hover, owned-toy choice, actual button use and reload persistence in the
native Toy Box client; combat/taint, pixels and frame time remain pending.
[Evidence](docs/HEARTH_CONFIG_TOY_COLLECTION.md).

Hearthstone Toy Box panel follow-up (30 October 2026): the earlier candidate
still showed no panel because `FluxSmartHearthConfig.lua` loads before
`FLUX_API` is initialized. Its guard now reads already-loaded `Flux.Cap`.
The corrected 17-check TOC-order regression and 106-script/748-Lua full
desktop suite pass. Native Toy Box visibility, owned-toy selection, secure
button use and reload persistence remain pending.
[Evidence](docs/HEARTH_CONFIG_TOY_COLLECTION.md).

Earlier Hearthstone Toy Box config attempt (30 October 2026): the Toy Box
capability and journal opener were corrected, but the 14-check fixture missed
the TOC load-order failure. Verify `/fluxhearth config`,
owned-toy selection, button use and account/character persistence after reload
on a real Toy Box client; combat/taint, pixels and frame time remain pending.
[Evidence](docs/HEARTH_CONFIG_TOY_COLLECTION.md).

Atomic binding follow-up (30 October 2026): first-account keys now clear,
assign, verify, save and load in one call, with Blizzard action contexts on
modern clients and three immediate attempts only for wrong keys. Focused 507
checks and 105-script/747-Lua desktop validation pass. The user's Mariosuper
Era and Pandasans Retail clients were not visible in this workspace process
or window view, so native first-login/reload keys, labels, no replay, taint and
frame time remain pending. [Evidence](docs/BINDING_ATOMIC_CONTEXT.md).

Binding persistence rewrite (30 October 2026): first-load Retail account
cache was 29 bytes with no bindings although marker 5 claimed completion.
Source now avoids SaveBindings during PLAYER_LOGIN, selects account bindings
at first world entry, applies and verifies the template, SaveBindings(1),
LoadBindings(1), verifies again, then checks disk persistence on the next
login before recording version 6. Old version-5 empty
cache gets one migration repair. Focused 501 checks and 105-script/747-Lua
desktop suite pass. Native first-load/reload persistence, bridge key presses,
labels, taint and frame time remain pending.
[Evidence](docs/BINDING_PERSISTENCE_REWRITE.md).

Binding repeat follow-up (30 October 2026): the user confirmed the exact
"Applying keybindings..." line repeated after reload on existing clients.
Version 5 now claims a truly new account's first pass before its first native
write. Old pending markers and four already bound Flux bridge commands skip
repeat setup; overlapping requests cannot queue a second clear. The new
account still starts on the first world-entry frame. Focused 544 checks and
105-script/747-Lua desktop validation pass. Native reload/no-replay, bridge
key presses, hotkey labels, persistence and frame time remain pending.
[Evidence](docs/ACCOUNT_BINDINGS_ONCE.md).

Account-only binding correction (30 October 2026): user requires exactly one
automatic full template application on the first load of the whole account.
The previous per-character marker caused repeats; Settings reset callbacks
also had keyboard replay paths. Now only a pending first-account bootstrap
starts a full pass, and completion is account-wide. Existing accounts and
successful old character markers migrate without reset. Focused 528 checks
and full 105-script/747-Lua desktop validation pass. Native first-account
key presses, later character/no-replay, persistence and frame time pending.
[Evidence](docs/ACCOUNT_BINDINGS_ONCE.md).

One-time binding correction (30 October 2026): user requires exactly one
successful full setup per active binding set and no repeated login reset.
Version 4 now marks completion after the verified save, accepts preceding
pending version-4 markers, and removes `UPDATE_BINDINGS` replay. The setup
uses one registry scan and a maximum of eight binding writes per frame, with
clear/apply/save phases separated. Focused 521-check desktop test passes;
native first-load keys, reload persistence and frame time remain pending.
[Evidence](docs/FULL_BINDING_RESET.md).

Full binding reset follow-up (30 October 2026): user explicitly requested
clearing the active native binding set before applying the complete Flux
keyboard template on every client. Version 4 forces one batched full reset
for older markers, verifies the supported template before save, repairs late
native binding-set replacement in the same login and confirms persistence
after a later login. Focused 521 checks and full 105-script/747-Lua desktop
suite pass. Native first-login/reload key presses, grid labels, account and
character sets, combat and taint checks remain pending on each client.
[Evidence](docs/FULL_BINDING_RESET.md).

Binding persistence follow-up (30 October 2026): first-account full keybind
batch could finalize its queued seed before the late native-set check. Version
3 keeps saved Flux keys pending across login sessions and repairs a key lost
on reload before marking success. Old version-2 markers recheck. Focused 35
checks and full 105-script/747-Lua desktop validation pass. Native first
login/reload and actual bridge key/button/label tests remain pending on each
client and binding scope. [Evidence](docs/DEFAULT_GRID_BINDINGS.md).

Protected-client raid settings follow-up (30 October 2026): user chose to keep
the taint guard. Retail/Forever Flux raid cells and preview now follow own
class color, power, health text and aura options despite native CVar values;
existing own frame sizing applies at world entry. Blizzard Interface values
stay native-owned. Nine focused checks and full 105-script/747-Lua desktop
validation pass. Verify first account/new character, real raid cells, combat,
Edit Mode and Settings in native clients before acceptance.
[Evidence](docs/RAID_OWNED_SETTINGS.md).

Protected-client raid settings follow-up (30 October 2026): user chose to keep
the taint guard. Retail/Forever Flux raid cells and preview now follow own
class color, power, health text and aura options despite native CVar values;
existing own frame sizing applies at world entry. Blizzard Interface values
stay native-owned. Nine focused checks and full 105-script/747-Lua desktop
validation pass. Verify first account/new character, real raid cells, combat,
Edit Mode and Settings in native clients before acceptance.
[Evidence](docs/RAID_OWNED_SETTINGS.md).

Raid/nameplate defaults follow-up (30 October 2026): user reported Blizzard
raid power bars, class colors and frame size missing at first login and asked
for Medium nameplate size `2`. Classic profile application now waits for the
active native profile and reapplies its CVar pack after load, with bounded
first-world-entry retries. Both nameplate default tables use `2`; existing
size `3` migrates once, preserving other choices. Retail/Forever native raid
settings remain guarded because addon-owned compact-frame callbacks can taint
protected frames. Focused 15 checks and full 104-script/746-Lua desktop suite
pass. Native first-load checks on every client remain pending.
[Evidence](docs/RAID_NAMEPLATE_DEFAULTS.md).

Same-login binding follow-up (30 October 2026): the user reports no bridge
keys on first load. The revised path writes at first world entry and verifies
again five seconds later before marking the active binding set complete. The
old `true` marker is upgraded to version `2`; stock achievement `Y` can become
smart mount, while custom assignments are retained. The live EBS grid registry
now refreshes hotkey labels, and a dense module list refreshes combat click
owners. Focused 29 binding and 7 label checks and full 103-script/745-Lua
desktop validation pass. Native first-load presses for
Hearthstone `7`, teleport `8`, smart mount `Y`, vendor mount `6`, labels and
combat/taint remain pending on all clients. [Evidence](docs/DEFAULT_GRID_BINDINGS.md).

Default grid binding repair (30 October 2026): missing Flux template keys now
seed once into the current account or character binding set. The reported
Hearthstone (`7`), teleport (`8`), smart mount (`Y`) and vendor mount (`6`)
routes are covered. Existing custom targets and alternate bindings survive;
combat/full-template work defers the seed. Focused 21 checks and full desktop
102 scripts/744 Lua syntax files pass. Reload the affected character for the
one-time repair when native checking is appropriate. Verify actual key clicks,
labels, persistence, combat/taint and every client; no game/settings interaction
was performed. [Evidence](docs/DEFAULT_GRID_BINDINGS.md).

First-login defaults (30 October 2026): new characters apply only CVars and
nameplate bitfields that the active client reports as character-stored, then the
existing raid/chat setup. Full account setup and keyboard-template behavior are
unchanged. The focused 42 checks and full 101-script/743-Lua desktop suite pass.
Native fresh-account/fresh-character behavior across the client roster, queue
completion and secure/visual checks remain pending. The post-login three-sentinel
check still has an unreachable four-mismatch threshold; preserve customized
values when addressing it. [Evidence](docs/DEFAULTS_FIRST_LOGIN.md).

Current publication batch (30 October 2026): all local scale, vehicle/durability,
status-bar and vendor message updates are included for main. Fresh combined
validation passes **100 scripts /741 Lua syntax files, zero failures**.
See [publication record](docs/GITHUB_PUBLICATION.md). Native pending checks remain pending.

Vendor chat amounts now split copper into gold/silver/copper with matching coin
symbols in repair, junk sale and net vendor lines. Full desktop validation passes
100 scripts/741 Lua syntax files; native chat rendering remains pending. The
reported 3,494,236-copper repair should read 349 gold, 42 silver, 36 copper.
Preserve unrelated unit-frame, vehicle and status-bar working-tree changes.

Unit-frame scale follow-up: portrait offsets and focus alignment now use
frame-local coordinates; player and side-by-side target clear the action strip
at 50–200% scale. 3D portrait camera refreshes on an actual scale change.
Focused 23 checks and full 99-script/740-Lua desktop suite pass.
[Evidence](docs/UNIT_FRAME_SCALE.md). Native pixels, click areas and
combat/taint remain pending. Preserve concurrent vehicle/durability and
status-bar changes.

New unit-frame scale controls: Player tab sets shared player/target size;
Focus tab sets focus size (50–200%, default 100%). The root and attached
elements, dependent target frames, detached chrome and class resources scale
together. [Scope and pending native checks](docs/UNIT_FRAME_SCALE.md). The
focused bridge model passes 17 checks; full 98-script/739-Lua report is in that chapter.
Preserve concurrent vehicle-seat work and verify native pixels, hit areas and
combat/taint when background-safe access is available.

Latest vehicle/durability change (30 October 2026): the 70%-scale seat indicator
sits left of equipment durability. If the micro menu or status strip is visible
at the top-left, both indicators sit below the lower strip without moving it.
Otherwise the pair starts at the screen top-left, subject to PvP-widget clearance.
Focused source-driven checks and the full 99-script/740-Lua desktop suite pass.
Native vehicle art, seat clicks, combat,
taint and all-client pixels remain pending. No client/settings interaction.

Latest work (30 October 2026): [unit power visibility](docs/UNIT_POWER_VISIBILITY.md)
hides Flux-owned main/raid power bars for known zero maximum and expands health.
Live/Forever keep full-height health behind power and pass maximum power through
secret-safe alpha; zero current keeps the resource visible. Focus-target and
pet-target were health-only already. Focused models and full 96-script/737-Lua
desktop suite pass; native all-client geometry/combat/taint/secret checks pending.
Health text uses full-height HP for a known zero maximum and stays in the health
section for restricted maxima. The Flux separator restores resource alpha after
partition/chrome repaints, including ToT refreshes; secret maxima are never
tested for truth in Lua. Player/target labels move to the expanded HP bar's
vertical middle for known zero power and restore nested placement on return;
ToT's separator container follows its raised side-by-side frame level. Native
text/border pixels remain pending.
WoW and on-disk settings/profilers were untouched. Source/test/docs were
published on main in `c313dc98a1e782aee1224554c347cd616f3ad7af`.
Preserve newer user changes before further work.

Latest user work: [teleport counts/interruption](docs/TELEPORT_CAST_WORK.md),
BUG-012/PERF-011. User confirms Retail. Candidate uses native count text and
restores the host without popup/binding rebuild. 527 focused checks, three
mutations, five desktop pairs and full 95 scripts / 736 Lua files pass. Native
reload/interrupted casts and comparison with non-travel custom flyouts pending.
No live game/settings changes. This fix is included in the current local-snapshot
publication payload; native acceptance retains its pending scope.

Continue in the existing `_FluxUI` folder/repository. On 29 October 2026 the user
requested that the current local files be uploaded to main, with no other branch.
Work on main only and preserve existing history/newer local edits; no force pushes.
See [publication record](docs/GITHUB_PUBLICATION.md).
Read [status](docs/STATUS.md), [decisions](docs/DECISIONS.md),
[development tasks](docs/DEVELOPMENT.md) and the [original stage tracker](docs/MODERNIZATION_PROGRESS.md).
The formerly pending objective-tracker source/test/records are included in commit
`73ca9d2`. Inspect current status before new work and preserve any newer user edits.

Earlier runtime `677d85c` shares activation within bar paint batches. Current full
workspace evidence: [95 scripts/736 Lua files](docs/validation/main-local-snapshot-2026-10-29.json).
[Action/player-aura audit](docs/ACTION_AURA_WORK.md) has five matched native pairs
per Retail/Era client, exact sources, unchanged57 button/aura-root geometries and
zero recorded matched-run errors. Native highlight was inactive; active combat/
secure input, dense/restricted auras and long-session leak acceptance remain pending.

Next priorities:

1. Attribute assisted-host icon/count/cooldown/usable work and repeated next-spell
   queries before sharing facts. Retail baseline4.814ms/s is inclusive, not a sum
   with its children. Preserve identity, effects and response cadence.
2. Exercise live enabled effects, paging/forms/modifiers/pet/stance/vehicle/input,
   aura expiry/reapply/reuse and combat/Edit Mode on exact builds. Top-right player
   aura data/handlers/style remain Blizzard-owned; no replacement painter.
3. Continue original API/lifecycle/private-cache and long-session gates. Keep
   auction, guild-bank and void-storage callbacks excluded.

Both clients remain open. Account sessions displace each other: test the named
characters sequentially using normal warning dismissal/Reconnect/selection.
Verify current executable/PID/window before messages; do not take foreground or
PC mouse/keyboard/clipboard. Final state: Era in world, Retail reconnect screen.
Original profiler0 Retail/1 Era and prior diagnostic roots restored. The existing
mirror job stays running unchanged (actual timeout1s despite60s text); verify file
hashes before reload and preserve unknown destination changes. No extra sync job.

Reproduction from the addon root:

```powershell
lua tests/assisted_highlight_work.lua --source tests/fixtures/assisted_highlight_before.txt --measure
lua tests/assisted_highlight_work.lua
lua Core/_tmp_playeraurassmoke.lua
python tests/run_validation.py --output docs/validation/next-check.json
python -B docs/tools/build_reference.py
python -B docs/tools/validate_docs.py
```

Baseline measure intentionally exits0 with20 unmet work budgets; candidate must
pass. Feature removal, settings reset, history rewrites and a separate release
remain outside the authorization. Main publication is authorized for this batch.
