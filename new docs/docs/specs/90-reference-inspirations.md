# Reference inspirations

## Purpose

Name the external addons that informed FluxUI’s **intent**, and state what to borrow conceptually for the rewrite. This is not permission to copy code.

## Core inspirations by Flux system

### Action bars — Bartender4 (+ modern glow packages)

**Borrow:** One authoritative bar owner; stance/form/vehicle/override paging; hide Blizzard bars; polished button feedback; optional glow continuity under paging.

**Flux-specific:** 19-column layout with page-2 on the same row; SHIFT/CTRL minirows; smart promotion; corner badges; sealed console squeeze with grids/trinkets.

Refs: `Bartender4ModernGlowEffects`, `Bartender4 Fixed`.

### Extra buttons & binding badges — ButtonForge

**Borrow:** First-class custom buttons for spells/items/macros; flyouts; clear keybindability; category-like organization; badge-like secondary faces.

**Flux-specific:** Opinionated Combat vs NonCombat grids, trinket menu, four utility slots, Flux Window Buttons tab, shared VFX with the main bar.

Refs: ButtonForge Classic Era, post-Dragonflight, TBC Anniversary.

### Binding documents — Clicked (+ ClickedMedia)

**Borrow:** Conditional casting as editable documents; targets/forms/conditions/multi-cast; key visualization clarity; spellbook-driven binding creation.

**Flux-specific:** Chord routing into 19-col + minirows; deep Bar & Badges integration; Respec snapshot of bindings.

Refs: `Clicked`, `ClickedMedia`.

### Vendor / junk / restock — Scrap + Restocker

**Borrow (Scrap):** Junk classification rules, bag indicators, Useful/Junk lists, safe sell, merchant integration.

**Borrow (Restocker):** Target quantities, reagent lists, bank refill toward targets, merchant restock automation.

**Flux-specific:** Tier consumables tied to Extra Buttons and ConsumableBest; Already Known; BuyEmAll-style bulk buy; respec gear protection interplay.

Refs: `Scrap`, `Restocker`.

### Inventory facts & bag views — Syndicator + Baganator

**Borrow (Syndicator):** Shared factual inventory/character economy index mindset; gold across characters.

**Borrow (Baganator):** Category sections, transfer UX, bag/bank views that other systems can decorate.

**Flux-specific:** Flux-owned foundation for restock/junk/respec even when Baganator is absent; dedicated compat bridges when it is present.

Refs: `Baganator`, `Syndicator`.

### Unit frames — TPerl

**Borrow:** Dense readable unit chrome; portraits; aura panels; threat adjacency; pet/ToT/focus family completeness.

**Flux-specific:** Per-unit Flux-vs-Blizzard toggles; Layout placement with the sealed HUD; Midnight display-safe combat numbers; flight/swing/class-power satellites as client allows.

Refs: `TPerl_Classic2019`, `TPerl_Retail`.

### Salvage interaction — Molinari-style

**Borrow:** Modifier-held overlay → click to process profession actions on bag items.

**Flux-specific:** Integrated protection with respec sets; options under Flux Salvage tab; inventory-aware eligibility.

### Other noted ports (intent only)

- Chat copy/paste convenience (ChatCopyPaste-style)
- Equip flyouts (ItemRack-style)
- BuyEmAll-style vendor bulk purchase UI
- Already Known tint behavior

## Blizzard UI reference trees

Use these to understand **what each client ships**, not to paste into Flux:

| Client | Reference tree |
|--------|----------------|
| Classic Era | `wow-ui-source-classic_era` |
| TBC Anniversary | `wow-ui-source-classic_anniversary` |
| Classic (MoP-era) | `wow-ui-source-classic` |
| Retail Midnight | `wow-ui-source-live` |

## How to use this doc during the rewrite

1. Read the Flux system doc first (`10`–`25`).
2. Skim the matching inspiration row here for the **player feeling** to preserve.
3. Implement new code against current client UI sources and Midnight constraints.
4. Never treat reference addon source as a patch base.

## Explicit non-goals

- Vendoring reference-addon code into Flux.
- Matching reference addon options pixel-for-pixel.
- Supporting every optional dependency as required.
