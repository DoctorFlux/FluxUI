# Flux Window (Map / Meter / Respec / Buttons)

## Purpose

Provide a fixed **bottom-right hub** for map awareness, damage/threat meters, respec presets, and extra buttons—so those tools live in one docked console instead of floating panels fighting the action strip.

## What the player sees

- A bordered window roughly Battlefield Map–sized (slightly enlarged), docked bottom-right—not freely dragged around the screen.
- Chat-style **tabs** (default order):
  1. **Map** — Zone battlefield map; click again toggles **Map ↔ Minimap** embed. Mode remembered per character.
  2. **Meter** — Damage/threat layout host.
  3. **Respec** — Gear / talent / bars / runes / consumables profiles UI.
  4. **Buttons** — Extra Buttons host surface.
- Accent-tinted active tab; tab order and enable/disable are configurable (at least one tab stays on).
- Window sits above the action-bar strata and can lift with bottom status-bar chrome so strips do not collide.
- Optional **Map Pins**: world-map-like icons (quests, custom pin providers) mirrored onto the battlezone map when enabled.

## Behaviors

### Map tab
- Embeds Blizzard’s battlefield / zone map into the window (hides the standalone battlefield map tab).
- Toggle embeds the Flux minimap instead.
- Combat mouse blocker over tainted pin layers where needed.
- Pin mirroring and third-party pin routing (HereBeDragons / Questie / TomTom-style) when the world map is closed—provider-dependent; some addons that only parent to the world map may not appear.

### Meter tab
- **Preferred backend:** Details! when loaded (Flux profile/layout enforcement, optional threat plugin pane).
- **Fallback on Midnight:** Blizzard’s native damage meter when Details is absent (capped pane count; no Flux threat plugin).
- Layout presets and custom multi-pane grids; right-click opens meter layout options; middle-click cycles presets.
- Details path can accent-tint a WoW-like skin to match Flux borders.

### Respec / Buttons tabs
- Host UIs owned by [23-respec.md](23-respec.md) and [12-extra-button-system.md](12-extra-button-system.md).

### Layout interaction
- When open at low UI scale, becomes the **right hard edge** for horizontal squeeze of the bottom strip ([05-defaults-and-bindings.md](05-defaults-and-bindings.md)).
- Unified border may fill the gap between trinkets and the window ([04-visual-system.md](04-visual-system.md)).

## Options / customization

**FluxWindow** tab in `/fluxui` (full rows: [26-options-map.md](26-options-map.md)):

- Tab chips: drag to reorder; click to on/off (**at least one stays on**)
- **Reset tabs** → Map → Meter → Respec → Buttons, all on
- Meter layout editor when Details! or Midnight Blizzard meter is present (presets, saved layouts, panes, drag splits; Blizzard capped at 3 panes, no threat)
- Map ↔ Minimap mode is per character from the Map tab itself
- Map Pins / world features when available on the map surface

## Relationships

- Visual chrome → [04-visual-system.md](04-visual-system.md)
- Squeeze → [05-defaults-and-bindings.md](05-defaults-and-bindings.md), [11-action-bars.md](11-action-bars.md), [12-extra-button-system.md](12-extra-button-system.md)
- Minimap embed twin → [18-minimap-and-trackers.md](18-minimap-and-trackers.md)
- Respec content → [23-respec.md](23-respec.md)
- Extra Ability HUD often re-anchors near this window → [25-other-qol.md](25-other-qol.md)
- Options tab “FluxWindow” → [26-options-map.md](26-options-map.md)
- Midnight meter policy → [03-midnight-constraints.md](03-midnight-constraints.md)

## Client availability

| Client | Availability |
|--------|--------------|
| Era | Shell + Map/Minimap/Respec/Buttons; Meter if Details |
| Anniversary | Same |
| Classic | Same |
| Midnight | Same + Blizzard meter fallback; threat pane via Details only; display policies for combat data |

## Rewrite intent notes

The hub is **docked and tabbed by design**. Free-moving widgets that recreate Map/Meter/Respec elsewhere fight the sealed console metaphor. Meter ownership is “host and layout,” not “build a parser.”

## Explicit non-goals

- Replacing the full world map experience.
- A Flux-authored combat log meter.
- More than one competing floating battlefield map.
