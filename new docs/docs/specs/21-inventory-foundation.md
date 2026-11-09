# Inventory foundation

## Purpose

Give Flux a **shared inventory brain**—bags, bank, warband, mail, auctions, equipped, guild/void where the client has them, gold, and currencies—so restock, junk, consumable buttons, salvage, respec protection, gold, and item-currency all agree on what the player owns without each system scanning bags differently.

If **Syndicator** is loaded, Flux uses that addon for this account-wide picture (and does not draw a second set of location lines on tooltips). If it is not, Flux keeps its own last-visit ledger for this character and alts.

## What the player sees

Players rarely open an “Inventory” panel. They feel this system through:

- Accurate restock bag/bank counts and surplus badges
- Junk glow that matches classification
- Combat/NC buttons picking sensible food/water/potion tiers
- Equip-slot flyouts offering alternate gear from bags
- Respec “where is my gear?” (bags / bank / missing)
- Gold ledger / currency awareness on the status strip
- Item tooltips that list **where** a stack lives (this character and alts: bags, bank, mail, auctions, equipped, and guild/void/warband when those exist)

Bag UI itself remains **Blizzard or Baganator**—Flux inventory is the data foundation, not a bag skin.

## Behaviors

Conceptual capabilities:

- Unified store of counts and find/snapshot across bags, bank, warband (where present), equipped, mail, auctions, and (when the client has them) guild bank and void storage
- Last-visit memory for alts: logging an alt (or sending that alt mail) is what teaches Flux they exist
- Mail sent to a **known** alt is counted on that alt without waiting for them to log in
- Change notifications so dependent systems refresh when bags move
- Consumable “best of kind” memory (food/water/bandage/potion tiers, including vendor memory)
- Item classification cache: quality, sellability, restore values, conjured/Well Fed, etc., without tooltip spam
- Equip-slot candidates for paperdoll flyouts
- Safe item mover used by bank restock planning
- Syndicator-style location lines on item (and currency) tooltips, skipped entirely when Syndicator is already doing that job

## Options / customization

Configure via:

- **Status Bars** — inventory awareness (tooltip lines, Shift-only, connected-realm / faction filters, equipped, guild bank) and account gold delete list ([16-status-bars.md](16-status-bars.md), [26-options-map.md](26-options-map.md))
- **Vendor & restock** ([20-vendor-restock-junk.md](20-vendor-restock-junk.md), [26-options-map.md](26-options-map.md))
- **Action Bars** extra-button visibility / utility / flyouts ([12-extra-button-system.md](12-extra-button-system.md))
- **Status Bars** item-currency slots ([16-status-bars.md](16-status-bars.md))
- Baganator bridges when present ([24-baganator-compat.md](24-baganator-compat.md))
- Respec protection ([23-respec.md](23-respec.md))

This foundation is the shared “what do I have / what is best?” picture those options act on.

## Relationships

- Upstream data for Vendor/Junk/Restock, Salvage classification hooks, Respec gear availability, Extra Buttons, Equip flyouts ([25-other-qol.md](25-other-qol.md)), gold strip, and item-currency icons
- Philosophy aligns with Baganator (views) + Syndicator (facts/ledger) → [90-reference-inspirations.md](90-reference-inspirations.md)

## Client availability

| Client | Availability |
|--------|--------------|
| Era | Bags/bank/equip/mail/auctions/gold; no warbank, guild bank, currencies, or void |
| Anniversary | Bags/bank/mail/auctions/gold; guild bank; no warbank or void |
| Classic | Full Classic bank topology; guild bank; void storage while the client still has it |
| Midnight | Bags/bank/warband/mail/auctions/gold/currencies; no void storage |
| Forever | Same as Midnight facts, but the Blizzard bank is Camelot **bags-in-bank** `BankPanel` (up to 9 character + 9 warband tabs, side page tabs). Not live Midnight’s named-tab grid. No reagent bank UI. |

Forever `Enum.BagIndex` sentinels (`Characterbanktab` / `Accountbanktab`) are not scannable bags. Keyring is `-1`; reagent **bag** is `5`. Flux chrome (restock button, junk paint, window mover) must not cover bag slots, purchase row, or fight the 560-wide growing frame.

## Rewrite intent notes

Syndicator’s lesson: **one factual inventory index**. Baganator’s lesson: **views and categories consume facts**. Flux should own facts for its features even when Baganator owns the bag pixels. Prefer Syndicator when present instead of running two ledgers.

## Explicit non-goals

- Shipping a competing full bag addon inside Flux.
- Parsing every tooltip every frame.
- Syndicator’s “search everywhere” window.
- Auction or crafting **queue management** (owned listings and location counts are awareness, not an AH helper).
