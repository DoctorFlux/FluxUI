# Individual unit frames

<!-- STRESS-FIXES-20261107 -->
7 November applied stress fixes: Cast fades use explicit public endpoints; Swing tracks its owned public fade trajectory and cancels stale completions. Health prediction retains full-width/maxHP normalization with public owned dimensions. Native clipping preserves32px striped texture phase. Threat uses an owned MIT-attributed renderer, preserving other addons' shared LibCustomGlow winner. [Evidence](../Stress%20test%20doc/applied-fixes/README.md). Native taint/pixels/performance acceptance remains pending.
<!-- /STRESS-FIXES-20261107 -->

Flux owns custom player, target, target-of-target, focus, focus-target, pet and pet-target frames. Each unit can use Flux or Blizzard presentation. `ns.UnitFrames` (`UF`) contains shared rendering/helpers; unit files construct and bind individual frames. Raid/party cells are a [separate system](15-raid-frames.md).

## Ownership and frame lifecycle

[Shared.lua](../UnitFrames/FluxUnitFrames_Shared.lua) provides `CreateBaseFrame`, health/power/additional-resource creation, portraits, borders, highlights, tooltips, partitioning, sizing, threat and common updates. Individual [Player](../UnitFrames/FluxUnitFrames_Player.lua), [Target](../UnitFrames/FluxUnitFrames_Target.lua), Focus/FocusTarget, TargetOfTarget and Pet/PetTarget files select unit behavior and expose `FluxUnitFrames_ApplyRuntime<Unit>` entrypoints.

Watched-unit visibility distinguishes a real resolved unit from the optional empty target placeholder. Target/ToT refresh together; focus/pet dependents follow their parent units. Pet-target is a narrow vertical health strip rather than a full-size target copy.

[FluxVsBlizzardRuntime.lua](../UnitFrames/FluxUnitFrames_FluxVsBlizzardRuntime.lua) coordinates switching without reload: suppress/mute the appropriate Blizzard frame/widget updates, restore the requested side and refresh related anchors. It watches target/focus/pet/vehicle/world changes and replays blocked work after combat. Per-unit visibility is not a request to indiscriminately destroy Blizzard frames/events.

[OptionsBridge.lua](../UnitFrames/FluxUnitFrames_OptionsBridge.lua) interprets account/character settings through `GetUnitFrameDB`, supplies feature/display predicates and applies frame sizes, portraits, aura layouts, threat, partitions and overall geometry. Placement-specific stored sizes convert to effective dimensions; shared horizontal squeeze is applied without changing the saved dimensions. Layout placement has its own scope; see [layout](06-layout.md).

The Player tab has a shared player/target whole-frame scale and the Focus tab
has an independent scale. Both also scale attached visuals and dependent target
frames; [details and native limits](UNIT_FRAME_SCALE.md).

## Health, resources and feedback

When the displayed unit's main resource has a known maximum of zero, Flux hides
the power bar and extends health through its space. An empty current resource
keeps its bar. Live/Forever place health behind the resource layer and forward
secret maximum power to its alpha, so a secret zero also reveals health. The same rule
applies to Flux raid cells; focus-target and pet-target are already health-only.
Health text centers in the full HP area for a known zero maximum; restricted
maxima keep text in the upper health section. The separator alpha is restored
after partition and chrome repaints. Player/target HP labels move to the
expanded bar's vertical middle for known zero power and restore their nested
corner layout when power returns. ToT's separator container follows its raised
frame level in side-by-side placement;
power text and the Flux separator disappear with a zero maximum.
See [the current validation record](UNIT_POWER_VISIBILITY.md).

Health and power use compatible native APIs, class/resource art and supported percent/display helpers. Shared code owns heal prediction, absorbs/heal absorbs, dead/ghost/AFK labels, disconnect behavior, class/reaction colors, full-resource pulses and secondary resources. Health/power text, level/class/PvP/combat/raid indicators, portrait combat feedback and mouseover highlights are separately gated options.

Secret values must flow to supported display widgets rather than ordinary arithmetic/comparisons. A numeric-looking return is not automatically safe. Shared polling rejects unusable cached values. One poll frame replaces per-unit OnUpdate loops: default health cadence is 0.2s and threat 0.5s, with demand/visibility and combat gating. Event updates still supply the primary state changes. `FluxUI_GetUnitFramePollStats()` exposes the poll inventory.

| Helper | Behavior |
|---|---|
| [HealthLossOverlay](../UnitFrames/FluxHealthLossOverlay.lua) | Trailing damage feedback attached around health value changes; can disable on unsupported bars. |
| [PowerCostOverlay](../UnitFrames/FluxPowerCostOverlay.lua) | Cost prediction, segment art and post-value synchronization around resource updates. |
| [MP5Overlay](../UnitFrames/FluxMP5Overlay.lua) | Older-client mana tick/five-second-rule presentation with relevant power/cast events. |
| [PortraitCombatFeedback](../UnitFrames/FluxPortraitCombatFeedback.lua) | Combat-event text/tint in the portrait region. |
| [ClassPower](../UnitFrames/FluxClassPower.lua) | Supported class resources, position and class-power scale. |
| [ForeverComboPoints](../UnitFrames/FluxForeverComboPoints.lua) / [LegacyComboPoints](../UnitFrames/FluxLegacyComboPoints.lua) | Native-style player combo rows on applicable client/class/form paths, including target-bound points and secret-safe Forever display. |

Player resource rows and nameplate combo rows are independent presentations. ClassPower primarily anchors Blizzard's own supported resource bars above the Flux player frame; the legacy/Forever combo modules supply their separate owned rows. Class-power scale affects unit-frame resources; nameplates have separate geometry. Eligibility and capability gates determine which renderer is active.

## Cast, swing and flight timers

[FluxCastBar.lua](../UnitFrames/FluxCastBar.lua) handles unit casting/channel/empower presentation, latency/timing, interrupt feedback, text and border style. `CreateCastBar`, `RefreshCastForUnit`, `StartCustomTimer` and `StopCustomTimer` serve unit frames and custom timer consumers. `SyncBlizzardCastBars()` avoids simultaneous conflicting presentation.

The shared school renderer also paints [Blizzard's nameplate cast bar](NAMEPLATE_CASTBAR_SCHOOLS.md)
with the same colors and effects when spell identity is readable. The
nameplate remains native-owned and has its own toggle in these unit-frame
settings. Restricted identity keeps the native appearance.
The [31 October fill and tip correction](CAST_SCHOOL_FILL_TIP_FIX.md) keeps
the themed fill on the actual progress bar and matches the moving Spark to
the active school color; native visual acceptance is pending.

[SwingTimer](../UnitFrames/FluxSwingTimer.lua) shares the player's cast-bar slot. Real casts can claim it; `HideForCastBarClaim` and `OnCastBarSlotReleased` coordinate ownership. Applicable Classic clients use combat-log/weapon events; Forever uses its supported swing APIs/events, including ranged/wand/throw variants. Cata/Mists and Live should not be assumed to have the same legacy swing path merely because the file loads.

On Era, Anniversary and Forever, an equipped wand with a readable damage
school now uses the same school fill and effects as a spell cast (for example,
a Fire wand uses Fire cast art). The ordinary swing timer remains for other
weapons or unknown school data. [Implementation and pending native checks](SWING_WAND_CAST_THEME.md).

[FlightPath](../UnitFrames/FluxFlightPath.lua) adds taxi duration tooltips and cast-bar progress, with a route-time database selected by client-specific XML. Lookup prefers faction-scoped account overrides, then supplied static data; character storage remembers node names. `GetFlightTimeForNodes`, `SetOverride` and `ClearOverride` expose this boundary. Flight timing is measured/learned rather than guaranteed exact; missing routes remain unknown. Data is attributed to RestedXP and has separate licensing; see [assets](34-assets.md).

## Auras, threat and integrations

[Auras.lua](../UnitFrames/FluxUnitFrames_Auras.lua) owns target/focus containers, layout, icon counts, tooltips and refresh. [AurasOwn.lua](../UnitFrames/FluxUnitFrames_AurasOwn.lua) identifies/sorts player/pet/vehicle debuffs and computes locked-own sizing with secret/access checks. Buff/debuff density, spacing, own-debuff minimum scale and independent per-unit configuration come through the options bridge.

On supported Midnight/Forever clients, [AurasEngine.lua](../UnitFrames/FluxUnitFrames_AurasEngine.lua) loads Blizzard_AuraContainer and uses engine-owned aura enumeration. Flux styles/configures the supplied buttons; it does not depend on tainted Lua successfully enumerating restricted target auras in combat. `UseEngineAuras`, `AttachEngineAuras`, `SyncEngineAuras` and `PokeEngineAuras` select/reconcile that path. Other clients use the owned Lua-rendered path. This differs from the raid private-aura-container implementation.

Target/focus threat uses `Flux.Threat`, including available Forever lead/situation APIs. Visibility, location and percentage display are independent options; restricted rank/percentage values are omitted or displayed safely. Numeric percentage follows game `threatShowNumeric`, also used by nameplates. [BigDebuffs integration](../UnitFrames/FluxUnitFrames_BigDebuffs.lua) handles portrait/corner placement and frame levels without making that addon mandatory.

[PetAuraTooltip](../UnitFrames/FluxUnitFrames_PetAuraTooltip.lua) adds pet auras on hover with tooltip ownership and deferred refresh. [PlayerSpecClick](../UnitFrames/FluxUnitFrames_PlayerSpecClick.lua) supplies specialization/profile flyouts, selected-profile state and Respec interactions; choosing/arming a profile differs from loading it. [PlayerTransmogClick](../UnitFrames/FluxUnitFrames_PlayerTransmogClick.lua) provides supported outfit/transmog interactions and appropriate click/flyout state. Its shared character-button/player flyout places the draggable clear action first when available; see [transmog actions](48-transmog-actions.md).

## Failure and verification model

Unknown/secret units, unsupported APIs, unresolved aura data and unavailable features are gated rather than treated as ordinary zeroes. Secure geometry/toggle work defers outside combat. Mock tests cover selected aura, combo, scale and style contracts; they cannot verify actual secure execution.

In game, test switching each unit to/from Blizzard, changing targets rapidly, empty placeholders, pet replacement, vehicles, portrait mode, all supported resource types, heal/absorb display, aura sorting and restricted combat, shared cast/swing/flight ownership, hover routing and BigDebuffs absent/present. Exact controls/defaults are in [options](26-options-map.md); remaining uncertainty belongs in [verification](41-verification.md).

The [shared 3D portrait camera](50-portrait-camera-compatibility.md) uses Forever's face-framing algorithm on every client with the required model-camera APIs. Legacy adapters preserve shared camera/event ownership, and missing capabilities retain native fallbacks. Desktop checks cover all five client models; exact visual framing still requires native testing.

The [unit/portrait performance follow-up](53-unit-map-idle.md) avoids rebuilding completed Flux-owned portrait and heal/absorb geometry. Live values and secret updates remain synchronous; native frame suppression and Edit Mode ownership are unchanged.

Current [unit indicator/spec contract](UNIT_FRAME_INDICATORS.md) retains raid-group/name geometry, places status icons above health beside class/spec and keeps the level visible beside resting ZZZ.

## Party player-style frames — 7 November 2026

Party / Raid now includes Show party as raid frames (default on), member scale,
portraits, cast bars, pets, pet scale and Preview party. Turning the first option
off uses the existing player/pet visual factories for four other party members
and their pets. The final member retains the current compact party bottom-right
location; existing compact and raid positions do not move. Mode/scale edits defer
in combat, while prepared existence drivers handle roster and pet transitions.
Buffs and debuffs now fill two rows per column, mirrored right/left, with zero
spacing and uniform configured glyph/slot dimensions. Existing one-to-six counts,
strict dispellable filtering, cooldown/timer, X scale and alpha remain supported.
See [requirements](RAID_HEALKIT_REWORK.md) REQ-RF-44 through REQ-RF-50 and
[evidence](validation/raid-party-mode-2026-11-07.json). Native visual/combat/input/
taint/FPS acceptance remains pending.

Alternate party members have zero vertical layout spacing. Their actual outer
buttons reuse Flux owned party/raid primary/modifier click programs and secure
hover enter/leave/hide cleanup, including keyboard and wheel routes. New focused
checks:535 party mode and210 binding checks on five modeled clients. Full final
suite:213 scripts/876 Lua syntax files PASS; tested corpus unchanged. Native
input, appearance, combat and taint acceptance remain pending.

## Aura countdown threshold — final split, 7 November 2026

UF-AURA-02 supersedes the rejected per-target/focus UF-AURA-01 prototype.
The user briefly requested all aura frames, then explicitly split the scope:

- Unit Frames > General > Show aura timers only below 1 minute covers normal
  player-style party frames, target and focus. Existing unit-frame scope owns
  unitFrames.auraTimersUnderMinute (false default; no settings reset).
- Party / Raid > Show aura timers only below 1 minute covers raid and compact
  party frames, keeping the existing raid key/default and scope.

At remaining>=60 seconds only countdown text blanks; below60 it returns. Icons,
stacks, cooldown swipes, filters/counts, geometry and fonts stay. Player top-right
native auras and pet-tooltip auras are outside the user's final narrowed scope.
The rejected saved per-target/focus keys are left intact but no longer consumed;
no migration or deletion changes user data.

Normal party was rendering through raid's single formatter, so the first
Target/Focus-only option could not affect it. Raid visuals now keep independent
raid and normal-party handles. Production initialization, readable cooldowns,
party preview clocks and normal-party refresh choose the correct owner. General
refresh updates that public party formatter and the target/focus containers;
normal-party options reuse their existing combat-deferred refresh. Raid updates
cannot overwrite the normal-party rules and vice versa. Matching current native
aura text bindings keep their formatter identity; no native child access or
restricted duration read is needed. Native target/focus owns one formatter per
container so ordinary updates and settings changes share its public rules.

Legacy target/focus keeps its0.5s sweep; widget milliseconds now convert to
seconds before GetTime/threshold arithmetic. This related correction is necessary
for accurate countdowns. Hidden long clocks remain tracked so they cross60
without another aura event. No new events/tickers/timers/pools are introduced;
the intentional resource difference is separate owned formatter objects.

36 focused checks execute production General callbacks, scope/config projection,
native rules, legacy milliseconds, family isolation and actual normal-party
native initializer/refresh bindings. Five alternating pairs reject baseline
and pass candidate. Existing raid live-option1696 and aura-renderer12776 checks
also pass. Earlier mock-only per-unit option evidence does not certify the new
scope. User rejected that first implementation; final native visual/secret/
combat/taint/FPS checks remain pending on every client.

[Final paired evidence](validation/unit-aura-minute-split-2026-11-07.json),
[final full run](validation/unit-aura-minute-split-full-2026-11-07.json).
Original five runtime/options owners and the three newly affected raid owners
were preserved externally under unit-aura-minute after rehashing the dated
source/settings/history checkpoint and verifying its history bundle. On-disk
settings remain untouched. No profiler or game input, foreground control or
manual duplicate sync was performed.

Final full validation:214/214 scripts and877 Lua syntax files PASS with unchanged tested corpus;45 other/current file comparisons across five installations match. [Final report](validation/unit-aura-minute-split-final-full-2026-11-07.json). Native final acceptance remains pending.

## Normal party follow-up — 7 November 2026

PARTY-NATIVE-FOLLOWUP-20261107. Normal party mode uses four fixed native unit
slots; their combined height stays inside the current raid column and the full
fourth-slot corner remains unchanged. Show party as raid frames keeps compact
mode available. Player-style settings include member width/height/scale, portraits,
cast bars, class border/backdrop, pets, wider HP-only targets, party aura size,
text size and resource height. Class-colored party target HP is a separate option;
Unit Frames contains equivalent pet-target and focus-target HP toggles.

Default pet is HP-only60x28 with percentage and no name/portrait/resource.
With pet, HP values sit in a top band and both bar texts avoid its width;
without pet, HP text centers. Resource height defaults80 percent, HP text to
values and resource to percentage, with independent values/percent/both/hidden
choices. Value/percentage text is larger; name/level and raised metadata have
separate room. Auras have an extra default1.50 party factor, harmful auras at
portrait top-right, helpful auras right of HP, packed columns and existing rules.

Dead/ghost/AFK/offline HP/resource fills desaturate and gray, then recover.
Range opacity uses the existing raid service and includes all portrait layers
and detached chrome. Threat changes only a transparent outer-border overlay,
using native colors/rules. All UFs use engine SetPortraitTexture for unavailable
3D models; pending model loading can restore3D. Secret alpha is never compared.

User confirms preview works and normal party frames appear. Final217 scripts/880 syntax PASS at the tested snapshot; party runtime
owners remain unchanged. Later unrelated utility/test edits cause global drift.
Final visual/input/combat/secret/taint/FPS acceptance still pending
per client. [Requirements](RAID_HEALKIT_REWORK.md#native-party-follow-up--7-november-2026)
and [evidence](validation/party-native-followup-2026-11-07.json).

## Compact party indicators — 7 November 2026

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

| ID | Requirement | Acceptance |
|---|---|---|
| REQ-RF-63 | Restore and fit class/leader/loot/PVP/tank/level indicators | Implemented; desktop pass, final native pending |
| REQ-RF-64 | Center percentage-only party labels on X with pet present | Implemented; desktop pass, final native pending |
| REQ-RF-65 | Overlay party casts above header text and support on/off | Implemented; desktop pass, final native pending |
| REQ-RF-66 | Party ready check, raid mark, resurrection, summons and raid indicator parity | Implemented; desktop pass, final native pending |
| REQ-RF-67 | Visible HP/resource divider | Implemented; desktop pass, final native pending |

## Player layout for normal party — 7 November 2026

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

| ID | Requirement | Acceptance |
|---|---|---|
| REQ-RF-68 | Party class/spec, cast bar and raid marker use player placement/layout | Shared player factories and shared marker helper;810 party checks PASS; native visual comparison pending |

## Cast timer synchronization — 7 November 2026

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

| ID | Requirement | Acceptance |
|---|---|---|
| REQ-RF-69 | Party/focus/target cast timers match their bars across all five clients, including Retail/Forever | Shared widget/engine clock;379 checks,5 baseline-rejecting pairs,3 rejected mutants; native pending |

## Raid-target marker rendering — 7 November 2026

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

| ID | Requirement | Acceptance |
|---|---|---|
| REQ-RF-70 | Raid-target symbols render and update on party/raid/normal UFs | Sheet assigned and native secret sprite sink;2730 checks and5 baseline-rejecting pairs; native pending |

## Party cast coverage — 7 November 2026

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

| ID | Requirement | Acceptance |
|---|---|---|
| REQ-RF-71 | Party cast covers name/level with on/off option | Raised shared art/icon; covered alpha/restore; active toggle refresh;840 party checks; native pending |

## Party divider edge — 7 November 2026

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

| ID | Requirement | Acceptance |
|---|---|---|
| REQ-RF-72 | Visible party HP/resource divider at actual seam | Power-top anchored;54 real-partition checks/5 pairs; native pixels pending |

## Party divider style — 7 November 2026

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

| ID | Requirement | Acceptance |
|---|---|---|
| REQ-RF-73 | Slightly thicker party divider matching frame border tint | Height4; common accent/class paint and appearance refresh; native style check pending |

## Target-style party separator — 7 November 2026

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

| ID | Requirement | Acceptance |
|---|---|---|
| REQ-RF-74 | Party HP/resource separator matches selected target artwork | Shared exact separator constructor;144 art/geometry checks; native image comparison pending |

## Party aura portrait priority — 7 November 2026

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

| ID | Requirement | Acceptance |
|---|---|---|
| REQ-RF-75 | Party buffs/debuffs draw over portrait icons | Host+90 over indicator+80, below cast+110; live/preview865 checks; native pixels pending |
