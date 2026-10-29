# Extra button system

## Purpose

Surround the main action bar with **utility HUD**: combat consumables, out-of-combat travel/food helpers, trinkets, flyouts, and player-built button categories—ButtonForge-style secure buttons that still feel native to the Flux console.

## What the player sees

### Combat Grid
Compact combat consumables row, typically:

- Healing potion, bandage, healthstone
- Mana potion, mana gem
- Ammo (where relevant)
- Optional Single-Button Assistant (often off by default)

Visibility: **Off / Auto / Always** (auto hides when irrelevant). Dedicated Flux keybinds.

### Non-Combat Grid
Out-of-combat utilities:

- Smart mount (+ vendor mount toggle)
- Hearth / smart hearth
- Class teleport / portal (mage TP↔portal toggle, conjure food/water/ritual, etc.)
- Food / water (or combined)
- Consumables flyout-style button
- **Four utility slots** (drag spell/item/macro/mount/toy; modifier variants; binds as Utility 1–4)

### Trinket Menu
Two equipped trinket slots plus bag flyout, combat swap queue awareness, keybinds (commonly including modifier + mousewheel). Visibility Off/Auto/Always.

### Flyouts
Popup grids for bag items, mounts, favorites, and generators—openable from macros / NC flyout panel with per-character hide, reorder, and favorite.

### Extra Buttons (categories)
Player-built **category windows** of custom buttons with account / class / realm / character scopes—reorderable and hideable personal utility palettes beyond the auto grids.

### Buttons tab
Categories and hosts also surface inside the Flux Window **Buttons** tab ([10-flux-window.md](10-flux-window.md)).

All of the above share Flux button chrome: usability tint, range, counts, tooltips, corner-badge visuals where linked, and the same feedback language as the main bar.

## Behaviors

- Layout shares action-bar **squeeze and alignment** so the bottom HUD reads as one piece under the unified border.
- Auto visibility policies hide empty or irrelevant combat/NC slots without making the strip jump wildly.
- Consumable picks cooperate with inventory “best of kind” memory and restock tiers ([21-inventory-foundation.md](21-inventory-foundation.md), [20-vendor-restock-junk.md](20-vendor-restock-junk.md)).
- Binding mode from the action bar also covers these grids and trinkets.
- FluxUI keybind category entries click into these live widgets ([05-defaults-and-bindings.md](05-defaults-and-bindings.md)).

## Options / customization

Configured on the **Action Bars** tab (visibility / flyout / utility) — catalog: [26-options-map.md](26-options-map.md).

### Extra button visibility defaults

| Label | Default |
|-------|---------|
| Single-Button Assistant | Off |
| Bandage · Healing Potion · Mana Potion · Mana Gem · Healthstone · Ammo | Auto |
| Hearthstone / Teleport · Food · Water · Consumables | Always |
| Mount · Class Teleport · Trinket Menu | Auto |

Modes: Off / Auto / Always (Consumables: Hidden / Always). **Reset extra button visibility to defaults**.

Also: Non-combat flyout panel (per character hide/reorder/favorite); four **Utility slots** with modifier variants; Flux Window **Buttons** tab hosts category palettes.

## Relationships

- Sealed with [11-action-bars.md](11-action-bars.md) and [04-visual-system.md](04-visual-system.md)
- Key hooks → [05-defaults-and-bindings.md](05-defaults-and-bindings.md)
- Conditional casting / badges → [13-binding-system.md](13-binding-system.md)
- Consumable quality ↔ [20-vendor-restock-junk.md](20-vendor-restock-junk.md), [23-respec.md](23-respec.md) consumable presets
- Hosted in Flux Window Buttons tab → [10-flux-window.md](10-flux-window.md)
- Inspiration → ButtonForge (Era / post-DF / TBC) in [90-reference-inspirations.md](90-reference-inspirations.md)

## Client availability

| Client | Availability |
|--------|--------------|
| Era | Full (ammo, Classic consumables, conjures) |
| Anniversary | Full |
| Classic | Full |
| Midnight | Full grids/trinkets/utilities; Assisted Combat bind where present; no Classic-only ammo assumptions |

## Rewrite intent notes

ButtonForge’s lesson is **first-class custom buttons** with flyouts and clear binding—not a second action-bar addon. Keep grids opinionated (combat vs non-combat) so players are not configuring twenty empty bars.

## Explicit non-goals

- Replacing the 19-column main bar with only freeform ButtonForge bars.
- Inventory management UI (that is Blizzard/Baganator + Flux inventory foundation).
- Controller-specific bar replacement (ConsolePort coexistence is separate).
