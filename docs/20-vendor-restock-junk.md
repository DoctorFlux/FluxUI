# Vendor, restock, and junk

## Purpose

Automate merchant and bank hygiene the way Scrap + Restocker players expect: sell junk safely, repair, restock consumables to targets, refill from bank, and tint already-known collectibles—without a separate junk addon.

## What the player sees

### Merchant integration
- Checkboxes and panels on the Blizzard merchant frame: automation toggles, restock panel, junk Useful/Junk lists, repair cluster
- Bag glow and coin icons on junk slots
- Already Known tint on learned scrolls/pets/mounts/toys/etc. at vendor, AH, guild bank (disabled if a standalone AlreadyKnown addon is loaded)

### Restock targets
- Drag items into grids showing bags-vs-target (green/red feedback)
- Optional “count bank” with bank surplus badge
- Preset lists for spell reagents from the spell book
- **Tier restock** for food, water, bandage, heal/mana potions: target quantity, mark inferior tiers as junk, bank count flags

### Junk (Scrap-style)
- Auto rules: poor quality, low-level consumables, unusable gear, destroy unsellable junk, safe batch sell
- Conjure filter: with Conjure Food/Water, mark non-conjured food/water as junk (Well Fed excluded)
- Manual junk and protected lists; restock targets skip auto-junk
- Inferior-tier / auto-marked tags in UI (e.g. manual vs auto marks)
- Merchant Junk tab: Useful / Junk lists with drag/drop

### Bulk buy
- Shift+click vendor → BuyEmAll-style quantity window (optional confirm for large buys)

## Behaviors

Per-character automation on merchant/bank open:

- Auto repair (optional guild bank first)
- Auto sell junk
- Sellable gray items share the same rule in the Junk list, bag indicators, and
  sell queue, regardless of item level or bind type. Useful marks, restock
  targets, conjured consumables, and saved gear protections remain respected.
- Selling tracks pending stacks across bag updates. Each attempt uses one
  container API path; it does not also sell through the cursor or start a
  competing native bulk sale. A final live scan picks up relocated junk.
- Auto restock listed items to targets
- Auto bank restock (refill bags from bank toward targets when bank opens)
- Inventory foundation supplies counts, classification, and movers ([21-inventory-foundation.md](21-inventory-foundation.md))
- Consumable “best” memory feeds inferior-tier junk marks and Extra Button consumable picks ([12-extra-button-system.md](12-extra-button-system.md))
- Respec gear-set protection blocks selling/disenchanting protected pieces ([23-respec.md](23-respec.md))
- Baganator shows Flux junk/protection affordances when present ([24-baganator-compat.md](24-baganator-compat.md))

## Options / customization

**Vendor & restock** tab in `/fluxui` — **per character** (full rows: [26-options-map.md](26-options-map.md)):

### Automation
Auto repair **off** · Bulk buy **on** · Confirm large bulk purchases **on** · Guild bank first **off** · Auto sell junk **off** · Auto restock **off** · Auto bank restock **off**

### Restock targets
Drag grids; bags/target colors; count-bank coin; bank surplus `+N`. **Clear all restock targets**.

### Junk detection (defaults on)
Low-level consumables · Unusable equipment · Sell non-conjured food & water · Destroy unsellable junk · Safe batch sell  
Legend: **M** = manual, **A** = auto-marked.

### Bag indicators
Junk glow **on** · Junk coin icon **on**

### Already known
Tint **on** · Monochrome **off** · Tint color green (disabled if standalone AlreadyKnown is loaded)

Merchant frame also hosts junk / restock / repair checkboxes in-world. Baganator reflects these when present ([24-baganator-compat.md](24-baganator-compat.md)).

## Relationships

- Inventory counts/class → [21-inventory-foundation.md](21-inventory-foundation.md)
- Combat/NC consumable buttons → [12-extra-button-system.md](12-extra-button-system.md)
- Gear protection → [23-respec.md](23-respec.md), [24-baganator-compat.md](24-baganator-compat.md)
- Inspiration → Scrap + Restocker in [90-reference-inspirations.md](90-reference-inspirations.md)

## Client availability

| Client | Availability |
|--------|--------------|
| Era | Full |
| Anniversary | Full (anniversary vendor data where relevant) |
| Classic | Full |
| Midnight | Full; warband/bank topology via inventory foundation |

## Rewrite intent notes

Scrap’s lesson: **confident junk classification + bag feedback + safe sell**. Restocker’s lesson: **target quantities and bank refill**. Flux merges them into one Vendor & restock surface tied to consumable tiers and Extra Buttons.

## Explicit non-goals

- A full auction-house sniper.
- Replacing Baganator as the bag UI.
- Auto-selling gear that belongs to saved respec sets.
