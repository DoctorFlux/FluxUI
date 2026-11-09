# Micro menu

## Purpose

Replace Blizzard’s micro bar with a Flux micro strip that still opens character/spellbook/social systems—plus Flux extras for bags, macros, orphaned minimap icons, config, reload, queue eye, and professions.

## What the player sees

Replacement micro bar buttons such as:

- Character, Spellbook, Talent, Achievement, Quest, Guild, LFG, Collections, Store, MainMenu, Help (as available per client)
- Flux extras: **Bags** (free slots), **Macros**, **Addon (+)** popup for remaining minimap icons, **Config**, **Reload**, **LFG eye** when queue UI exists
- Optional **profession** buttons or a professions flyout

Placement modes:

- Horizontal top-left
- Vertical beside chat
- Collapsible strip on the minimap edge

## Behaviors

- Hides Blizzard micro menu while Flux owns it
- Scans minimap buttons and can **promote** them onto the bar or into the Addon popup
- Profession buttons are always character-scoped
- When stacked with status bars, gold/XP/rep share the micro bar’s width
- ConsolePort micromenu takeover is disabled while Flux micro is authoritative ([25-other-qol.md](25-other-qol.md))
- Config button can open Ace options or a standalone config surface

## Options / customization

**MicroMenu** tab + **Layout** placement — catalog: [26-options-map.md](26-options-map.md), [06-layout.md](06-layout.md).

- **Micro menu bar scope** — Account-wide | Character-specific (default Account-wide): size, spacing, order — **not** Layout placement
- Per-button visibility under icon: Off → Account → Character → Off
- Embedded order/visibility editor
- **Enable trade skill micro buttons** — on (always character)
- **Layout mode** — Per-profession | Fixed split (**default**) | Global
- Global style (if Global): All individual (**default**) | One flyout | Both
- Per-profession: Individual | In flyout | Off (primaries individual, secondaries flyout)
- **Button size** — **0.9** (0.5–1.5) · **Spacing offset** — **−2** (−12…16)
- **Reset layout to defaults** — size/spacing only
- Layout defaults: Beside chat, **2** buttons per row

## Relationships

- Width pairing with [16-status-bars.md](16-status-bars.md)
- Minimap edge placement ↔ [18-minimap-and-trackers.md](18-minimap-and-trackers.md)
- Accent chrome → [04-visual-system.md](04-visual-system.md)
- Options embed widgets → [26-options-map.md](26-options-map.md)

## Client availability

| Client | Availability |
|--------|--------------|
| Era | Full with Era micro set |
| Anniversary | Full |
| Classic | Full |
| Midnight | Full with Retail micro set (Collections/Store/etc. as present) |

## Rewrite intent notes

Micro menu is **navigation chrome**, not another action bar. The Addon (+) escape hatch matters: players should not lose third-party minimap buttons when Flux cleans the minimap.

## Explicit non-goals

- Reimplementing every Blizzard panel.
- Forcing all minimap icons onto the main micro row (popup is intentional).
