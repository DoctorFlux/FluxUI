# Raid frames

## Purpose

Supply Flux compact party/raid frames that feel native to the HUD—groupable, scalable, and compatible with familiar Blizzard compact-unit options—while still allowing BigDebuffs and safe status text under Midnight.

## What the player sees

- Compact party/raid grid using group headers (including reverse columns and main-tank / main-assist column concepts).
- Per-member cells with health, power, auras, role, and status text.
- Optional raid-manager strip.
- Target and mouseover highlights.
- Dispel-type border coloring when enabled.

When enabled, Flux replaces Blizzard party/compact raid presentation for that role.

## Behaviors

- Combat-safe updates and layout changes deferred when needed
- Range fade aligned with Blizzard “fade out of range” expectations
- Status text that remains meaningful when percentage/secret health display rules apply
- BigDebuffs on raid cells when present
- Optional **live world preview** roster for tuning sizes/auras (session-only; clears on reload)
- Mirrored familiar toggles: class colors, power bars, health text, buffs/debuffs, dispellable-only filters

## Options / customization

**Raid frames** tab in `/fluxui` (full rows: [26-options-map.md](26-options-map.md)):

- **Raid frame settings scope** — Account-wide | Character-specific (default Account-wide)
- **Use Flux compact raid / party frames** — on
- **Class-colored names** — off
- **Reset raid frame options to defaults** (Flux sliders only; not Blizzard CVars)

### World Preview
- Show/Hide · Roster size 5–40 step 5 (**40**) · Show MT column on · MT slots **2**
- Demo buffs on (count 3) · debuffs on (count 5)
- Slash: `/fluxui raidpreview` (session-only; clears on reload)

### Sizing / transparency defaults
- Width scale 1 · Height 1.2 · Power 1 · Aura icons 1.4 · Raid manager 0.9
- Base opacity 1 · In range 0.9 · Out of range/offline 0.44 · Aura icon opacity 1
- **Dispel highlight border** — on

### Mirrored Blizzard toggles
Class colors · Power bars · Health text (none/health/perc/healthandpercent) · Show buffs · Show debuffs · **Aura focus** Debuff focused (default) | Buff focused · Only dispellable debuffs

Layout: stacked above the chat column (reference tile on Layout preview).

## Relationships

- Visual identity can share Flux accents → [04-visual-system.md](04-visual-system.md)
- Distinct from individual unit frames → [14-unit-frames.md](14-unit-frames.md)
- Midnight display policy → [03-midnight-constraints.md](03-midnight-constraints.md)
- Defaults packs may touch raid interface settings carefully → [05-defaults-and-bindings.md](05-defaults-and-bindings.md)

## Client availability

| Client | Availability |
|--------|--------------|
| Era | Full compact party/raid concept |
| Anniversary | Full |
| Classic | Full |
| Midnight | Full; status/health presentation must stay display-safe; avoid Settings-preview taint from aggressive CVar thrash |

## Rewrite intent notes

Cells are Flux-owned `SecureUnitButton`s. They do not inherit `CompactUnitFrameTemplate`. Layout, reverse group order, and the chat dock stay the same.

On clients that expose `ContainerPrivateAuraBehaviorMixin` and `C_UnitAuras.AddPrivateAuraAnchor`, buffs, debuffs, and dispel slots are Blizzard private-aura anchors (scalar attributes, same slot counts). Other clients use a small owned icon row. Health and power are percent bars (`UnitHealthPercent` / `UnitPowerPercent` when those exist). Classic clients keep plain health and power math when the values are not secret.

Preview is a designer/player tuning aid, not a permanent fake group.

## Explicit non-goals

- Full VuhDo/Grid2 click-casting suite as a mandatory dependency (Clicked/Flux binding covers casting intent elsewhere).
- Replacing mythic dungeon/priority helper addons.
