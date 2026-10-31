# Individual unit frames

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

[SwingTimer](../UnitFrames/FluxSwingTimer.lua) shares the player's cast-bar slot. Real casts can claim it; `HideForCastBarClaim` and `OnCastBarSlotReleased` coordinate ownership. Applicable Classic clients use combat-log/weapon events; Forever uses its supported swing APIs/events, including ranged/wand/throw variants. Cata/Mists and Live should not be assumed to have the same legacy swing path merely because the file loads.

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
