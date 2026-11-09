# Respec (profiles and presets)

## Purpose

Let a character store and load named **playstyle profiles**—gear, talents/loadouts, SoD runes, action bars (Classic), consumables, utility, bindings, and Info Frame pins—from the Flux Window Respec tab, with strong protection so set pieces are not sold or disenchanted by accident.

## What the player sees

### Profiles
Named per-character profiles that **Save** a snapshot of checked parts:

- Gear (enchant/gem/rune-aware identity)
- Talents — Classic tree learn / dual-spec swap; Retail talent loadouts on Midnight
- SoD runes (where applicable)
- Action bars (Classic; stance-bar order only on Retail loadout clients)
- Consumables preset name (links to NC consumable presets)
- Utility / binding snapshots
- Info Frame pins (character-panel pinned stats plus FPS / durability / ping)

**Save and Load are masked.** Each section and each gear/rune slot has a checkbox. Unchecked parts are not written on Save (last saved data stays) and are not applied on Load (your current setup stays). Example: only Finger 1/2 + Trinket 1/2 checked → Save updates jewelry only, Load swaps jewelry only.

Toggling a checkbox is stored immediately; you do not need to press Save just to change the mask. With **No profile** selected, the same checks stay enabled and become the mask for the next Save (new profile).

Load equips from bags (and bank when the bank is open). Two rings or trinkets with the same name each need their own copy — Flux matches by item id / enchant, not the display name.

On Retail and Forever, a profile’s gear also maps to a **Blizzard equipment set** of the same name (16-character cap). The profile dropdown and spec icon use that set’s icon.

### Presets
- **Equipment presets** — named gear-only sets (save/equip), with the same per-slot include checks; on Retail/Forever they share a Blizzard equipment set of the same name (icon in the Gear dropdown)
- **Rune presets** (SoD) — runes plus bars/utility bundle; per-rune include checks; may switch dual-spec

### UI surfaces
- Flux Window **Respec** tab as the home UI (same overlay layout: header + gear strip + summary rows)
- Section checkboxes on Gear, Runes, Consumables, Talents, Utility slots, Spell bindings, Action Bars, Info Frame
- Corner checkboxes on gear and rune icons (right-click also toggles)
- Gear availability: equipped / bags / bank / missing (included slots only)
- Shield overlays on protected bag/equipped pieces; paperdoll guards; tooltip notes
- Baganator categories/sections for profiles and protection when present

## Behaviors

### Load Profile orchestrator (player story)
Typical order: Info Frame (if included) → talents + gear in parallel → rune engrave clicks → bars → consumables → utility → bindings.

- Skips sections and slots that are unchecked, and steps that already match
- On set-capable clients: `UseEquipmentSet` when the linked set would not touch an unchecked slot, then Flux fills leftovers from bags (enchants, duplicate jewelry, bank)
- Trainer-needed messaging when Classic talents require it
- Combat-deferred application
- Bank withdraw only on explicit Equip/Load (no silent auto-withdraw on bank open)
- Selecting a profile in the dropdown does **not** apply Info Frame pins or the consumable list; Load does

### Save Profile
- Recaptures only checked sections and slots from the live character
- Unchecked snapshot fields keep their last saved data
- No profile: Save creates a profile using the include mask you already toggled
- Gear included on Retail/Forever: create or update a Blizzard set of the same name; unchecked slots are ignored on that set (left alone)

### Blizzard equipment sets (Retail / Forever)
`C_EquipmentSet` — max **10** sets, names **16** letters. Era / Anniversary stay Flux pickup-equip.

- **Same name:** Flux profile/preset name is the Blizzard set name (truncated to 16). Character-pane sets are **imported into the Gear dropdown** on login (name, icon, items) even if Flux never saved them; Save updates that set.
- **Cap full:** a *new* name cannot create a set. Flux keeps its snapshot and equips from bags. Updating an adopted/existing set does not need a free slot.
- **Icon:** profile spec picker (and preset first-equipped-item icon) is pushed into the Blizzard set; the Gear/profile dropdowns show the live set icon and name. Renaming in the character pane renames the Flux profile/preset to match.
- **Delete:** Flux deletes the Blizzard set only if Flux created it. Adopted pre-existing sets are unlinked, not deleted.
- A profile and a preset that share a name share one Blizzard set (last Save wins).
- Extra Button equipment-set actions (`/equipset`) are unchanged.

### Protection (default on)
Blocks vendor sell, sell-junk, and disenchant on bag/equipped pieces needed by any saved profile/preset (items still stored in the snapshot, including currently unchecked slots). Integrates with Vendor/Junk and Salvage.

## Options / customization

Respec UI lives primarily in the Flux Window **Respec** tab (not a huge Ace options subtree). Related options:

- FluxWindow tab chips include Respec ([10-flux-window.md](10-flux-window.md), [26-options-map.md](26-options-map.md))
- Binding tab **Bindings source** can target Respec profiles; Preview saves to Respec only; Sticky across Respec
- Vendor/Junk/Salvage respect gear-set **protection** (default on in Respec product behavior)
- Consumable preset names link to NonCombat consumables / Extra Buttons
- Slash: `/fluxrespec`

Profile/preset CRUD, icons, apply-mask checks, Blizzard set sync, apply flow, and protection toggles are in the Respec surface itself.

## Relationships

- Hosted in [10-flux-window.md](10-flux-window.md)
- Bars snapshot → [11-action-bars.md](11-action-bars.md)
- Bindings snapshot → [13-binding-system.md](13-binding-system.md)
- Consumables / utility slots → [12-extra-button-system.md](12-extra-button-system.md)
- Pinned stats → character panel + [16-status-bars.md](16-status-bars.md) Info Frame
- Gear facts → [21-inventory-foundation.md](21-inventory-foundation.md)
- Sell/DE guards → [20-vendor-restock-junk.md](20-vendor-restock-junk.md), [22-salvage.md](22-salvage.md)
- Bag UI bridge → [24-baganator-compat.md](24-baganator-compat.md)

## Client availability

| Client | Availability |
|--------|--------------|
| Era | Classic talents + bars + gear + consumables/bindings |
| Anniversary | Same family; SoD runes only when engraving is enabled |
| Forever | Retail-style loadouts + stance-bar layout + Blizzard equipment-set sync |
| Midnight | Retail loadouts + gear + consumables/bindings + Blizzard equipment-set sync; skip Classic bar slot snapshot |

## Rewrite intent notes

Respec is an **orchestrated, maskable save and load**, not five unrelated buttons. Protection is part of the feature, not an afterthought—Scrap/Restocker automation must never eat a saved set.

## Explicit non-goals

- Replacing Raidbots or full sim-driven gear planners.
- Auto-swapping profiles from secret combat state on Midnight.
- Forcing ItemRack-style always-on player-frame set flyouts (Flux has a separate equip flyout QoL).
- Snapshotting Extra Button **category grids** (utility slots only).
- Replacing Blizzard’s character-pane Equipment Manager UI.
