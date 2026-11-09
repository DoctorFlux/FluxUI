# FluxUI Concept Documentation (Rewrite Bible)

This folder is the **concept-only** specification for rebuilding FluxUI from scratch.

It describes what the addon is for, what the player sees, how systems behave, how pieces relate, and what works on which World of Warcraft client. It is intentionally **not** a coding guide.

## Why this exists

The plan is a full rewrite that keeps the **ideas and player experience** of FluxUI (as captured in the pre–major-rewrite backup) while discarding old structure and implementation. These docs are the shared source of truth for that rewrite.

**Source of concept truth:** the pre–major-rewrite backup only — not the current `_FluxUI` code tree.

## Hard rules for readers and writers

- Describe **behaviors, UX, options, relationships, and client limits** only.
- Do **not** prescribe APIs, secure-handler recipes, file layouts, function names, or “how to code it.”
- Do **not** treat old FluxUI source as something to port line-by-line.
- Reference addons (Bartender4, ButtonForge, Clicked, Scrap, Restocker, Baganator, Syndicator, TPerl, etc.) are **inspiration for intent**, not code to copy.
- When Retail Midnight (12.x) restricts combat-sensitive logic, document the **product outcome** (display-only, unavailable, Classic-only), not workarounds.

## How to read this set

1. Start with [01-product-overview.md](01-product-overview.md) for the whole HUD story.
2. Read [02-multi-client-matrix.md](02-multi-client-matrix.md) and [03-midnight-constraints.md](03-midnight-constraints.md) before designing combat UI.
3. Read [04-visual-system.md](04-visual-system.md), [05-defaults-and-bindings.md](05-defaults-and-bindings.md), and [06-layout.md](06-layout.md) for chrome and placement.
4. Walk systems in number order (`10`–`25`), then the full options catalog [26-options-map.md](26-options-map.md), inspirations, and glossary.
5. When rebuilding a feature, match its **Options** section to the real `/fluxui` labels in `26`.

## Document index

| Doc | Topic |
|-----|--------|
| [00-README](00-README.md) | How to use this set |
| [01-product-overview](01-product-overview.md) | Whole product story |
| [02-multi-client-matrix](02-multi-client-matrix.md) | Era / Anniversary / Classic / Midnight |
| [03-midnight-constraints](03-midnight-constraints.md) | Secret values as product limits |
| [04-visual-system](04-visual-system.md) | Borders, accents, unified envelope |
| [05-defaults-and-bindings](05-defaults-and-bindings.md) | Defaults, keybind pack, scale/squeeze |
| [06-layout](06-layout.md) | Layout tab click-to-place placements |
| [10-flux-window](10-flux-window.md) | Map / Meter / Respec / Buttons hub |
| [11-action-bars](11-action-bars.md) | Main bar, paging, minirows, glows, badges |
| [12-extra-button-system](12-extra-button-system.md) | Combat/NC grids, trinkets, flyouts |
| [13-binding-system](13-binding-system.md) | Conditional casting and key routing |
| [14-unit-frames](14-unit-frames.md) | Player / target / focus / pet family |
| [15-raid-frames](15-raid-frames.md) | Party and raid compact frames |
| [16-status-bars](16-status-bars.md) | Gold, XP, rep, info strip |
| [17-micromenu](17-micromenu.md) | Replacement micro bar |
| [18-minimap-and-trackers](18-minimap-and-trackers.md) | Minimap, buffs, objectives |
| [19-nameplates](19-nameplates.md) | Nameplate overlays |
| [20-vendor-restock-junk](20-vendor-restock-junk.md) | Vendor, restock, junk sell |
| [21-inventory-foundation](21-inventory-foundation.md) | Shared inventory awareness |
| [22-salvage](22-salvage.md) | Prospect / mill / DE-style overlay |
| [23-respec](23-respec.md) | Load profiles and presets |
| [24-baganator-compat](24-baganator-compat.md) | Bag UI bridges |
| [25-other-qol](25-other-qol.md) | Chat, vehicle, extras, character panel |
| [26-options-map](26-options-map.md) | Full `/fluxui` options catalog (every label/default) |
| [90-reference-inspirations](90-reference-inspirations.md) | What we borrow from each ref |
| [99-glossary](99-glossary.md) | Shared terms |

## Standard section template (system docs)

1. **Purpose**
2. **What the player sees**
3. **Behaviors**
4. **Options / customization**
5. **Relationships**
6. **Client availability**
7. **Rewrite intent notes**
8. **Explicit non-goals**

## Out of scope

- Implementation plans, libraries, or file trees for the new addon
- Porting or diffing old Lua into the rewrite
- Copying reference-addon internals
