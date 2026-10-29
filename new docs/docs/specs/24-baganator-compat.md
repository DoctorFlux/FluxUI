# Baganator compatibility

## Purpose

When **Baganator** is loaded, bridge Flux economy and respec features into Baganator’s bag/bank views so junk, gear sets, consumable presets, protection, and bank restock feel native there—without requiring Baganator for Flux to function.

## What the player sees (only if Baganator present)

| Bridge | Player-visible effect |
|--------|------------------------|
| Junk | Coin icon, grey highlight, junk category fed by Flux junk rules |
| Gear sets | Respec profiles/presets as equipment-set categories |
| Equipment Set section | Distinct “Equipment Set” section vs normal Equipment |
| Category icons | Profile/preset icons on set headers |
| Consumable presets | Section per NC consumable preset |
| Protection | Click guards on protected gear-set slots |
| Category vendor block | No bulk vendor/transfer of Flux set categories / protected slots |
| Gear set shield | Shield on protected items at vendor/DE contexts |
| Gear set context | Fade protected items at vendor like unsellable |
| Bank restock | Flux bank restock control anchored near Baganator Transfer |

## Behaviors

- Entire compat layer is inert without Baganator
- Uses shared traversal of Baganator item buttons/views
- Flux remains source of truth for junk rules, protection, and restock targets; Baganator is the view
- Syndicator-style facts may already power Baganator ecosystems; Flux inventory foundation still serves Flux features even if Syndicator is also present

## Options / customization

No large standalone Baganator options tab — behavior follows:

- **Vendor & restock** junk / restock / bank restock ([20-vendor-restock-junk.md](20-vendor-restock-junk.md), [26-options-map.md](26-options-map.md))
- Respec protection and set categories ([23-respec.md](23-respec.md))
- NonCombat consumable presets ([12-extra-button-system.md](12-extra-button-system.md))

Players configure those Flux systems; Baganator reflects them.

## Relationships

- Junk/restock → [20-vendor-restock-junk.md](20-vendor-restock-junk.md)
- Inventory facts → [21-inventory-foundation.md](21-inventory-foundation.md)
- Profiles/protection → [23-respec.md](23-respec.md)
- Consumable sections → [12-extra-button-system.md](12-extra-button-system.md)
- Inspiration → Baganator + Syndicator in [90-reference-inspirations.md](90-reference-inspirations.md)

## Client availability

| Client | Availability |
|--------|--------------|
| Era | If Baganator supports the client |
| Anniversary | If supported |
| Classic | If supported |
| Midnight | If supported |

## Rewrite intent notes

Treat Baganator as the preferred **bag skin partner**, not a hard dependency. All Flux economy features must work on Blizzard bags too; compat is additive polish.

## Explicit non-goals

- Forking or re-skinning Baganator inside Flux.
- Requiring Syndicator install for Flux gold ledger (nice-to-have import only).
- Breaking Baganator categories that users created manually.
