# Status bars

## Purpose

Show progression and economy at a glance—experience, reputation, gold, optional PVP currencies, bag token counts, and a small Info strip—aligned with the Micro Menu and bottom console rather than floating Blizzard meters.

## What the player sees

Shared-height strips that can include:

- Gold / currency (optional)
- Experience
- Reputation
- Optional Honor / Arena on older clients
- Up to six **bag item-currency** counts on the gold strip (drag tokens from bags)
- Durability awareness via Info frame
- Optional FPS / ping / pinned stats **Info frame** (placement-dependent)
- PVP capture / objective widgets repositioned to respect Flux layout

## Behaviors

- Version-aware XP/rep presentation
- Abbreviated money text
- Account gold tooltip from a multi-character **gold ledger** (Flux inventory awareness, or Syndicator when that addon is loaded)
- Item tooltips (when Syndicator is not loaded) list where stacks live on this character and alts
- Status strip width follows Micro Menu when those pieces are stacked
- PVP top widgets avoid hugging the wrong screen edge under Flux layouts
- ConsolePort’s competing XP/rep bars are suppressed when Flux status is authoritative ([25-other-qol.md](25-other-qol.md))

## Options / customization

**Status Bars** tab + **General** (Info Frame) + **Layout** placement — catalog: [26-options-map.md](26-options-map.md), [06-layout.md](06-layout.md).

### Status Bars tab
- **Status bar settings scope** — Account-wide | Character-specific (default Account-wide)
- **Show currency (gold) bar** — on
- **Hide experience bar when not gaining XP** — off
- **Bar height** — **18** (10–40)
- **Reset status bar options to defaults**
- Account gold ledger: pick character · delete from ledger
- Inventory awareness: item/currency location lines on tooltips (disabled when Syndicator is loaded)
- Honor / Arena (where supported, per character) — both **off** by default
- Item currency: **Show item currency on gold strip** — on · slot grid (always per character)

### Info Frame (General tab, always per character)
- Show FPS / Durability / Ping — all **on**
- Clear pinned stats (confirm)
- Placement: Layout → Info FPS (default action strip)

## Relationships

- Often shares envelope width with [17-micromenu.md](17-micromenu.md)
- Placement interacts with [04-visual-system.md](04-visual-system.md) unified borders
- Window lift when bottom status chrome is used → [10-flux-window.md](10-flux-window.md)
- Ledger philosophy ↔ Syndicator in [90-reference-inspirations.md](90-reference-inspirations.md) and [21-inventory-foundation.md](21-inventory-foundation.md)
- Item-currency icons on the gold strip use the same inventory counts Extra Buttons use; hovering them shows the shared location tooltip

## Client availability

| Client | Availability |
|--------|--------------|
| Era | Full classic XP/rep/gold; honor/arena where present |
| Anniversary | Full |
| Classic | Full |
| Midnight | Full gold/XP/rep/info; honor/arena often N/A; account gold ledger story strongest |

## Rewrite intent notes

Status bars are **ambient HUD**, not a dashboard of cards. Keep one shared height language. Gold ledger is informational—not a full accounting app.

## Explicit non-goals

- Replacing Details or Blizzard meters (that is the Flux Window Meter tab).
- A second floating data-broker bar farm by default.
