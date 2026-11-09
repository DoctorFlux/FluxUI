# Individual unit frames

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

9 November focus visibility/menu ownership (FOCUS-SECURE-VISIBILITY-20261109):
focus/focus-target native visibility hides protected mouse descendants instead
of leaving an alpha-zero hit region; paired lifecycle prevents disabled watches
from resurrecting frames. Existing native service/probes reused. Ordinary unit
menus use `togglemenu`; dependent-target callback menus are retained, with native
focus keys/macros per user choice. Their callback focus entry remains restricted.
No binding, layout or appearance settings changed.70/670/620 focused checks and
full263/930 PASS. Forever background reload/native macro state/error checks pass;
user confirms player menu and combat focus macros. Other native clients/group
menus, physical pointer routing and matched pixels remain pending.
[Behavior, restrictions and regressions](FOCUS_SECURE_VISIBILITY.md).

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

7 November name/ToT fitting replays final public text/font after refresh, measures unclipped width and sends restricted current names/surnames to native text sinks. Party cast state resets on hide/roster rebind and refreshes on show; routed stops with missing identity complete. 681 name/215 cast/1010 integration checks; full 249/913 pass. Native appearance/taint pending. [Evidence](validation/unit-name-party-cast-2026-11-07.json).

7 November vertical target strips share the HP/status/class-color and health-loss path across party, compact focus and pet targets. The red trail uses height, resets on identity/layout lifecycle changes, and uses native sinks for restricted values. 1243 targeted checks and full 236/900 pass; native visuals/taint/performance pending. [Evidence](validation/vertical-target-health-2026-11-07.json).

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

## Native party PvP badge — 7 November 2026

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

| ID | Requirement | Acceptance |
|---|---|---|
| REQ-RF-76 | Client-native full PvP badge behind level; timer below, empty when unsupported | Native delegate/art; layer20 below level80;905 checks; user accepts empty party countdown; native pixels pending |

## Shared native PvP badge correction — 7 November 2026

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

| ID | Requirement | Acceptance |
|---|---|---|
| REQ-RF-77 | Full native PvP badge behind level on player/target/focus and party; available timer below | Shared renderer;299 indicator and905 party checks; actual client visual acceptance pending |

## Focus party presentation — 7 November 2026

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

| ID | Requirement | Acceptance |
|---|---|---|
| REQ-RF-78 | Increase full native PvP badge further | Host scale1.35;319 badge checks; native pixels pending |
| REQ-RF-79 | Party-style focus with right vertical target; previous position and separate top aura panels | Actual focus initializers exercised;970 combined checks; positioning function retained; native placement pending |

## Focus anchor and aura scale correction — 7 November 2026

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

| ID | Requirement | Acceptance |
|---|---|---|
| REQ-RF-80 | Focus remains above party/raid; independent top aura panels fit visible body |47 physical scale/anchor and265 panel checks; user native acceptance pending |

## Exact focus aura width — 7 November 2026

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

| ID | Requirement | Acceptance |
|---|---|---|
| REQ-RF-81 | Both aura halves match the new focus outer-frame length |577 geometry/corner checks against actual FluxBorder definition; native width acceptance pending |

## Group reveal, focus aura row and portrait restore — 7 November 2026

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

| ID | Requirement | Acceptance |
|---|---|---|
| REQ-RF-82 | Full focus/target aura row without reserved gap; use available row width |1011 actual geometry/native contract checks; screenshot follow-up pending |
| REQ-RF-83 | Prepared party/raid appears after joining during combat |Native secure parent reveal; existing preallocation/slot drivers;995 party and255908 secure checks; native taint pending |
| REQ-RF-84 | Party/focus red portrait backdrop clears when combat ends |66 actual shared renderer/Party.PaintChrome checks; old source rejects |

## Focus aura packing without expansion — 7 November 2026

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

| ID | Requirement | Acceptance |
|---|---|---|
| REQ-RF-85 | Keep original focus aura width; fit more per row without target-strip expansion |1011 geometry/packing checks; supersedes only the width extension in REQ-RF-82; native appearance pending |
