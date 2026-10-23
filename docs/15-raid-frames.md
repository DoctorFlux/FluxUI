# Compact raid and party frames

Flux owns compact party/raid cells and their layout while reading familiar Blizzard raid settings. Cells are **Flux-owned secure unit buttons**, not inherited Blizzard CompactUnitFrameTemplate cells. [FluxRaidFrame.xml](../RaidFrame/FluxRaidFrame.xml) loads compat, visuals, layout, unit paint, orchestration, preview and BigDebuffs support, then declares the cell template and event driver.

## Components and data flow

| Component | Ownership |
|---|---|
| [Compat](../RaidFrame/FluxRaidCompat.lua) | `FluxRaidCompat`, `FluxRaidState`, client-safe value/unit/range helpers and reverse-column math. |
| [Layout](../RaidFrame/FluxRaidLayout.lua) | Group/MT-MA headers, chat-stack placement, roster configuration, Blizzard-grid suppression/restoration, pet-battle state driver and deferred work. |
| [Visuals](../RaidFrame/FluxRaidVisuals.lua) | Tunables, cell geometry/chrome, aura options/containers, highlights and setup compatibility. |
| [Unit](../RaidFrame/FluxRaidUnit.lua) | Bind a unit, register relevant events and update health/power/prediction/name/status/role/ready-check/auras/range. |
| [Orchestrator](../RaidFrame/FluxRaidFrame.lua) | Option application and roster/CVar/scale/target/role/ready-check event dispatch. |

`FluxRaid_OnLoad` initializes tunables/layout, registers supported events defensively, installs pet-battle visibility and schedules initial option application. `FluxRaid_BindUnit` and secure unit attribute changes bind cells. `FluxRaid_PaintUnit` supplies a full refresh; targeted event reasons avoid redoing all work.

Group columns reverse their visible order around the chat dock. Main-tank/main-assist columns and target mini-cells use separate size/spacing math; `ComputeReverseColumnLayout` centralizes the calculation. Layout changes queue through `FluxRaid_QueueWork` during combat and drain on `PLAYER_REGEN_ENABLED`. Roster changes and display/UI scale changes can independently require reconfiguration. Blizzard party/compact presentation is suppressed while Flux owns that role and restored when disabled.

## Health, status and range

Cells contain health/power bars, heal-prediction/absorb regions, name/status text, role/center/ready-check/raid-target icons, selection/mouseover/aggro highlights and aura hosts. Where available, `UnitHealthPercent` and `UnitPowerPercent` drive percent bars. Older plain values use guarded arithmetic. Dead/offline/status labels and health-text modes must avoid comparisons on secret values.

Range alpha uses the supported native/boolean display path when available and safe compat fallback otherwise. Current `FluxRaid_ApplyRangePollInterval` is a compatibility no-op and the range/MT-MA poll-stat getters return zero; do not describe a configurable active custom polling engine from those symbol names. Base/in-range/out-of-range opacity remains a real presentation setting.

## Auras and private-container boundary

On clients exposing `ContainerPrivateAuraBehaviorMixin` and both public private-aura anchor APIs, buffs, debuffs and dispel slots use a **dedicated child container with scalar settings**. Blizzard exclusively owns that child's attribute handler. Flux's unit-change hook stays on the secure unit button; it must not replace the private container's restricted handler.

Settings updates preserve anchors, while unit reassignment/clearing explicitly updates their binding after combat. `ConfigurePrivateAuras`, `UpdatePrivateAuraUnit` and `SyncPrivateAuraSettings` separate construction, identity and settings. This distinction preserves useful existing behavior documented before this rewrite.

Other clients use a small Flux-owned icon row. Buff/debuff focus changes organization; enabled/icon-count/size/alpha settings control display. **Only dispellable debuffs** restricts icons to the player's dispel filter, including boss/role/priority debuffs that a normal Blizzard row might retain as exceptions. The fallback uses `HARMFUL|RAID` and safe dispel facts. Private-container clients do not expose their hidden aura values for arbitrary Lua classification; the fallback dispel highlight deliberately hides where it cannot read safely.

[BigDebuffs integration](../RaidFrame/FluxRaidFrame_BigDebuffs.lua) maps Flux cells into that addon's supported attachment paths. It waits for the addon and respects combat/private-aura boundaries. BigDebuffs is optional, not a substitute cell owner.

## Options and live preview

`FluxOptions:GetRaidFrameDB()` selects account/character settings. Controls include enable Flux raid/party, class-colored names, sizing, manager size, opacity, aura scale/focus and dispel border. Familiar Blizzard toggles remain CVars: class colors, power, health text, aura display and dispellable filtering. Resetting Flux sizing is different from resetting Blizzard CVars. Exact labels/defaults are in [options](26-options-map.md).

[Preview.lua](../RaidFrame/FluxRaidPreview.lua) provides session-only synthetic cells for 5–40 members, optional MT slots and demo buff/debuff counts. `Show`, `Hide`, `Toggle` and `RefreshFromOptions` update the preview. `/fluxui raidpreview` toggles it. It clears on reload and is not an actual raid roster or evidence that protected real-unit behavior works.

## Verification

Check party→raid→solo, group ordering, MT/MA counts/targets, roster reassignment during combat, pet-battle visibility, CVar changes, resize/scale, disabling Flux ownership, range/offline alpha, ready checks and target highlights. On secret clients verify private aura anchors persist across settings changes but rebind on unit changes; on Classic verify dispellable-only filtering and owned icons. BigDebuffs needs absent/present cases.

The [raid aura smoke harness](../RaidFrame/_tmp_raidaurassmoke.lua) executes reference private-aura methods with mocked registration and explicitly cannot prove taint/protected execution. Live validation remains separate in [verification](41-verification.md).
