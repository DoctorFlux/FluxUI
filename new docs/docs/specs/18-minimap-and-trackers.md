# Minimap and trackers

## Purpose

Present a clean **square top-right minimap** with Flux chrome, docked objectives, nearby buffs, and the ability to embed into the Flux Window Map tab—without losing Questie or other pin workflows.

## What the player sees

- Square minimap with Flux border; cleaned Blizzard chrome
- Tracking / calendar via right-click patterns familiar to players
- Instance difficulty and tracking indicators
- Objective tracker docked beside the map (scrollable body on post-DF / Midnight)
- Player buff/debuff frames repositioned near the map
- Optional embed into Flux Window Map tab (minimap vs battlefield map toggle)
- Optional **3×5 extra-action grid** to the left of the embedded map for character-saved spell/item/macro slots
- Questie-aware layout coexistence when Questie is present

## Behaviors

- Combat-safe embed and restore when switching Map tab modes
- Hides the corner cluster when the minimap is embedded and the Map tab is elsewhere
- Keeps the objective tracker visually stable except when embed/layout changes
- Enforcer pass after layout changes so Blizzard Edit Mode / default anchors do not yank pieces back
- Third-party minimap buttons can be promoted into Micro Menu ([17-micromenu.md](17-micromenu.md))
- Buff squeeze cooperates with low-scale / Flux Window layout math ([05-defaults-and-bindings.md](05-defaults-and-bindings.md))

## Options / customization

Mostly **layout-driven** (no large dedicated Minimap options tab):

- Corner vs embed via Flux Window Map mode ([10-flux-window.md](10-flux-window.md))
- Micro menu **Beside minimap** placement + buttons-per-row ([06-layout.md](06-layout.md), [17-micromenu.md](17-micromenu.md))
- Info Frame can sit on minimap top ([16-status-bars.md](16-status-bars.md))
- Character-saved embedded 3×5 extra-action slots when map is embedded
- Questie coexistence automatic when present
- Minimap buttons can fold into Micro **Addon (+)** rather than cluttering the cluster

Full options catalog: [26-options-map.md](26-options-map.md).

## Relationships

- Embed twin of [10-flux-window.md](10-flux-window.md) Map tab
- Border accent → [04-visual-system.md](04-visual-system.md)
- Micro promotion → [17-micromenu.md](17-micromenu.md)
- Info frame can sit on minimap top → [16-status-bars.md](16-status-bars.md)

## Client availability

| Client | Availability |
|--------|--------------|
| Era | Full square map + tracker docking as Classic allows |
| Anniversary | Full |
| Classic | Full |
| Midnight | Full; scrollable objectives body; Edit Mode coexistence care |

## Rewrite intent notes

Minimap is structural HUD, not a skinned circle with fifty buttons. Clean chrome + embed + tracker dock are the product. Pin richness on the battlezone map stays in the Flux Window docs.

## Explicit non-goals

- Replacing Questie or TomTom.
- A fully custom world map.
