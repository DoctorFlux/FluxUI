# Salvage

## Purpose

Offer a Molinari-style **hold modifier over a bag item → colored overlay → click to process** workflow for prospecting, milling, disenchanting, lockpicking, Comprehend Scroll, and related profession opens—without a separate salvage addon.

## What the player sees

- While holding the configured modifier over an eligible bag item, a colored overlay appears indicating the salvage action (Comprehend mage-blue, mill green, prospect red, disenchant purple; same on every client)
- Click performs the appropriate action (prospect, mill, crush, scrap, shatter, transmute, disenchant, comprehend, open/lockpick, profession open variants as data allows)
- Tooltip hints communicate eligibility
- Missing the spell or skill, or too-low rank: no glow and no extra “requires” line — Alt-hover does nothing
- Overlay is deferred while combat prevents secure action
- Slash helpers such as `/fsalvage` / `/fluxsalvage` for toggle, status, and options

## Behaviors

- Action choice driven by item→spell data tables plus known player spells
- **Comprehend Scroll** (Forever): a **mage spell you learn**, not a profession. If that spell is known, Alt-hover bag scrolls whose tooltip says `Requires Comprehension (X)`; the Skills-tab **Comprehension** secondary skill rank must meet X (spellbook known-check + `C_SkillInfo` rank, same click as disenchant)
- **Forever mill / prospect / disenchant:** classic Milling (51005), Prospecting (31252), and Disenchant (13262) on the existing herb/ore/gear matchers; also require that profession's skill rank. Too-low rank or missing spell: no overlay.
- Forever combined bags (`ContainerFrameCombinedBags`) feed bag/slot from the item button (`GetBagID` / `GetSlotAndBagID` / `ContainerFrameItemButton.EnterButton`); overlay casts the spell on that slot (not `Item:GetItemLocation()`, not retail `CraftSalvage`)
- Forever casts those spells on the bag slot (not retail `CraftSalvage`)
- Works with Flux inventory change awareness so overlays stay honest when bags move
- Respects respec gear-set protection (do not disenchant protected set pieces) → [23-respec.md](23-respec.md)
- Plays nicely with Baganator bag buttons when that compat layer is present → [24-baganator-compat.md](24-baganator-compat.md)

## Options / customization

**Salvage** tab in `/fluxui` (full rows: [26-options-map.md](26-options-map.md)):

- **Enable salvage overlay** — **on**
- **Modifier key** — Alt | Alt+Ctrl | Alt+Shift — **default: Alt**
- Slash: `/fsalvage` · `/fluxsalvage` (toggle / status / open this tab)

## Relationships

- Inventory foundation → [21-inventory-foundation.md](21-inventory-foundation.md)
- Protection rules → [23-respec.md](23-respec.md)
- Junk/vendor is separate (sell vs craft-process) → [20-vendor-restock-junk.md](20-vendor-restock-junk.md)

## Client availability

| Client | Availability |
|--------|--------------|
| Era | Full for professions that exist |
| Anniversary | Full |
| Classic | Full |
| Midnight | Full for modern profession actions in data |
| Forever | Classic mill/prospect/DE plus Comprehend Scroll (known mage spell + Comprehension secondary skill) |

## Rewrite intent notes

Keep the interaction model obvious: **modifier + click**, color-coded by action family. Data tables may be attributed to upstream Molinari-style lists; the rewrite still reimplements cleanly.

## Explicit non-goals

- Auto-salvaging entire bags without confirmation UX.
- A full crafting UI replacement.
- Bypassing protection on respec gear sets.
