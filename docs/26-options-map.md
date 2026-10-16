# Options map (`/fluxui`)

## Purpose

One player-facing options app for the whole overhaul. This doc is the **full catalog** of tabs, labels, defaults, and scopes so the rewrite can rebuild every control without guessing.

Mined from the pre–major-rewrite backup’s AddonOptions + Action Bars options surfaces.

**Open:** `/fluxui` · `/fluxoptions`  
**Window:** sidebar groups, about 1000×680, status line shows version + client  
**Also:** Micro Menu **Config** button; `/fluxui raidpreview` for raid world preview  
**`/fluxui bliz`:** opens the same window. On older clients, Blizzard’s AddOns list has a button that opens it. Post-DF retail does not register a Settings canvas.

**No separate “Defaults” tab.** Per-page reset buttons + **Profiles**. Account/character game-setting bootstrap uses `/fluxdefaults` (see [05-defaults-and-bindings.md](05-defaults-and-bindings.md)).

## Sidebar

**General** — General, Windows, Profiles  
**HUD** — Layout, Action Bars (Bars, Bindings, Extra, Stance), Status Bars, Micro Menu, Chat  
**Frames** — Unit Frames (General, Player, Target, Target of Target, Focus, Pet, Pet Target), Nameplates, Raid Frames  
**Tools** — Flux Window, Vendor & Restock, Salvage, Binding

Search filters the sidebar by page name and the open page by control label. Action Bars → Bars keeps range/update intervals behind **More options**.

Nameplate Progressive, Flash, Health Bar Color, and Threat warning are on **Nameplates** only.

## Shared scope model

| Scope control | Affects | Independent of General? |
|---------------|---------|-------------------------|
| General → Settings scope | Active Ace profile (Account-wide vs Character-specific) | — |
| Layout scope | Placement only | Yes |
| Micro menu bar scope | Size, spacing, drag order | Yes (not Layout placement) |
| Action bar scope | Action Bars tab storage | Yes; **stance order always character** |
| Status bar settings scope | Currency on/off, height, hide XP | Yes; **item currency always character** |
| Unit frame settings scope | All Unit frames sub-tabs | Yes |
| Raid frame settings scope | Raid frames Flux options | Yes |
| Vendor & restock / Info Frame / Honor·Arena | Character | N/A |
| Salvage | Salvage saved settings | N/A |

Character-scoped module data is **not** duplicated by Ace profile copy (called out on Unit/Raid scope descriptions).

---

## 1. General

### Settings
- **Settings scope** — Account-wide | Character-specific — **default: Account-wide**  
  Account shares; character copies account on first switch. Action Bars has its own scope.

### Appearance
Accent applies to chrome across the HUD (options window stays neutral).
- **Accent** — Class color | Default atlas (no tint) | Custom color — **default: Class color**
- **Custom accent color** — shown only if Custom — default white

### Info Frame
Always **per-character**. Pin extra stats via Character Info left-click.
- **Show FPS** — **on**
- **Show Durability** — **on**
- **Show Ping** — **on**
- **Clear pinned stats** (confirm)

→ Placement of Info Frame is on **Layout**. Contents also described in [16-status-bars.md](16-status-bars.md). Accent → [04-visual-system.md](04-visual-system.md).

---

## 2. Layout

Full detail: [06-layout.md](06-layout.md).

- **Layout scope** — Account-wide | Character-specific — **default: Account-wide**
- **Reset layout to defaults**
- Click-to-place preview (colored / faded / gray reference)
- Defaults: Micro beside chat (2 columns) · Status screen bottom · Player/Target side by side · Stance beside player · Info on action strip
- **Buttons per row** 1–8 when Micro is multi-column — **default: 2**

---

## Windows

Drag and scale Blizzard windows (Character, bags, map, auction, popups). Flux HUD placement stays on **Layout**.

- **Windows scope** — Account-wide | Character-specific
- **Enable window mover**, lock, scaling, save position, save scale, clamp to screen
- **Require modifier to drag** and modifier key
- **Snap size**
- **Reset all window positions**

---

## 3. FluxWindow

→ [10-flux-window.md](10-flux-window.md)

### Tabs
- Drag chips to reorder; click chip to on/off (**at least one stays on**)
- **Reset tabs** — restores **Map → Meter → Respec → Buttons**, all on

### Meter layout
- Shown if Details! is loaded, or Midnight Blizzard damage meter is available
- Details: full layout editor (presets, saved layouts, panes, drag splits)
- Blizzard meter: same editor + note “Max 3 panes · no threat meter · data may be unavailable…”
- If neither: gray note that meter options appear when a backend is available

---

## 4. Action Bars

→ [11-action-bars.md](11-action-bars.md), [12-extra-button-system.md](12-extra-button-system.md)

### Scope
- **Action bar scope** — Account-wide | Character-specific — **default: Account-wide**

### Key Bindings
- Hover button, press key; Esc clears
- **Enter Binding Mode** (blocked in combat)

### Reset keybindings
- **Reset keybindings to Flux defaults** (confirm; blocked in combat)

### Layout
- **Minirow position** — Top | Bottom — **default: Top**

### Action Bar VFX *(pre–Dragonflight / Classic clients)*
- **Enable action bar VFX** — **default: on**

### Mouseover casting
- Matches spell book setting
- **Mouseover cast** — **default: on**

### Auto Rank up *(Classic Era / TBC / Wrath-style clients)*
- **Auto rank up** — **default: off**
- **Rank up all spells**
- Blacklisted spells panel

### Performance
Behind **More options** on Bars. Lower interval = faster updates, more CPU.
- **Range check interval** — **0.25** (0.1–1.0)
- **Extra button range interval** — **0.18**
- **Mouseover update interval** — **0.07** (0.04–0.2)
- **Macro usable interval** — **0.05** (0 = off)
- **Action usable interval** — **0** (0 = off)  
  Note: macro buttons won’t move minirows unless needed

### Stance bar slot order
Always **per character**. Drag reorder; right-click hide/show. **Reset stance bar order to default**.

### Extra buttons (visibility)
Modes: **O**=Off, **A**=Auto, **+**=Always, **H**=Hidden. **Reset extra button visibility to defaults**.

| Label | Default |
|-------|---------|
| Single-Button Assistant | Off |
| Bandage | Auto |
| Healing Potion | Auto |
| Mana Potion | Auto |
| Mana Gem | Auto |
| Healthstone | Auto |
| Ammo | Auto |
| Hearthstone / Teleport | Always |
| Mount | Auto |
| Class Teleport | Auto |
| Food | Always |
| Water | Always |
| Consumables | Always (Hidden / Always) |
| Trinket Menu | Auto |

### Non-combat flyout panel
Per character: click hide, drag reorder, right-click favorite.

### Utility slots
Drag spell/item/macro/mount/toy; Shift/Ctrl/Alt for modifier variants; drag off to clear.

---

## 5. Vendor & restock

→ [20-vendor-restock-junk.md](20-vendor-restock-junk.md)  
Scope: **this character**.

### Automation
| Control | Default |
|---------|---------|
| Auto repair | off |
| Bulk buy at vendor | on |
| Confirm large bulk purchases | on (same idea as `/buyemall confirm`) |
| Guild bank first | off (hidden if guild repair N/A) |
| Auto sell junk | off |
| Auto restock | off |
| Auto bank restock | off |

### Restock targets
Drag grids; bags/target colors; coin = count bank; `+N` = bank amount. **Clear all restock targets** (confirm).

### Junk detection
| Control | Default |
|---------|---------|
| Low-level consumables | on |
| Unusable equipment | on |
| Sell non-conjured food & water | on |
| Destroy unsellable junk | on |
| Safe batch sell | on |

Legend: **M** = manual, **A** = auto-marked.

### Bag indicators
- Junk glow on bag slots — **on**
- Junk coin icon on bag slots — **on**

### Already known items
Disabled note if standalone AlreadyKnown is loaded.
- **Tint already-known items** — **on**
- **Monochrome tint** — **off**
- **Tint color** — default green

---

## 6. Salvage

→ [22-salvage.md](22-salvage.md)

- **Enable salvage overlay** — **on**
- **Modifier key** — Alt | Alt+Ctrl | Alt+Shift — **default: Alt**
- Slash: `/fsalvage` · `/fluxsalvage`

---

## 7. Raid frames

→ [15-raid-frames.md](15-raid-frames.md)

### Settings
- **Raid frame settings scope** — Account-wide | Character-specific — **default: Account-wide**

### Flux raid / party frames
- **Use Flux compact raid / party frames** — **on**
- **Class-colored names** — **off**
- **Reset raid frame options to defaults** (does not reset Blizzard CVars below)

### World Preview
Full-size world preview; demo fills empty slots; hidden after login/reload. Slash: `/fluxui raidpreview`.
- **Show / Hide Preview**
- **Roster size** — 5…40 step 5 — **default 40**
- **Show MT column** — **on**
- **MT slots** — 1–8 — **default 2**
- Demo Auras: **Buffs** on · **Buff count** 3 · **Debuffs** on · **Debuff count** 5

### Frame sizing (Flux)
| Slider | Default |
|--------|---------|
| Member frame width scale | 1 |
| Member frame height scale | 1.2 |
| Power bar height scale | 1 |
| Aura icon scale | 1.4 |
| Raid manager strip scale | 0.9 |

### Transparency (Flux)
| Slider | Default |
|--------|---------|
| Frame base opacity | 1 |
| Opacity when in range | 0.9 |
| Opacity when out of range / offline | 0.44 |
| Buff / debuff icon opacity | 1 |

### Dispel Highlight
- **Dispel highlight border** — **on**

### Blizzard raid frame CVars (mirrored)
- Class colors · Power bars · Health text (`none` / `health` / `perc` / `healthandpercent`) · Show buffs · Show debuffs
- **Aura focus** — Debuff focused (**default**) | Buff focused
- **Only dispellable debuffs**

Target/mouseover highlight colors exist as product defaults but are **not** exposed as options rows today—rewrite may choose to expose them.

---

## 8. Unit frames

→ [14-unit-frames.md](14-unit-frames.md)

Nested sub-tabs: General · Player · Target · Target of target · Focus · Pet · Pet target.

### General → Settings
- **Unit frame settings scope** — Account-wide | Character-specific — **default: Account-wide**

### Flux vs Blizzard (all **on** by default)
Player · Target · Target of target · Focus* · Focus target* · Pet · Pet target  
(*Focus rows hidden if the client has no focus unit)

**Reset unit frame options to defaults**

### Features (defaults **on** unless noted)
- 3D portraits
- Health loss overlay · Power cost overlay · MP5 / mana tick overlay (player) · Weapon swing timer (player; toggle hidden on post-DF retail and post-Cata classic)
- Flight path timers · Flight path cast bar (player) · Flight path taxi map tooltips
- **Threat bar visibility** — Always | In group or raid only (**default**) | Never
- **Show threat percentage** — **on** (game `threatShowNumeric`; nameplates use the same option)
- Nameplate Progressive, Flash, Health Bar Color, and Threat warning are on **Nameplates**, not this page

### Player

- **Class power size** — 50–200%, default **100%**; applies to every unit-frame class resource after combat.
- Show portrait strip — **on**
- Width **325** (150–600) · Height **100** (40–200)
- Health / resource split % — **60** (35–85)

### Target
- Show portrait strip — **on**
- Empty target placeholder — **on**
- Side-by-side Layout: size follows Player (Width/Height hidden); else Width **500** · Height **100**
- Health split **60%**
- **Auras:** buff/debuff size **35**; lock own debuff **on**; own min scale **75%**; spacing **2**; max buffs **32**; max debuffs **16**
- **Threat:** visibility (same choices); position Portrait overlay (**default**) | Between chrome and auras | Left/Right (vertical)

### Target of target
- Width **125** · Height **60** · Health split **60%**

### Focus *(if available)*
- Portrait **on** · Width **119** · Height **50** · split **60%**
- Auras: sizes **20**; lock **on**; min scale **75%**; spacing **2**; max 32/16
- Threat position (same choices; default Portrait)

### Pet
- Portrait **on** · Show cast bar **off** · Show auras on mouseover **on**
- Width **100** · Height **50** · split **60%**

### Pet target
- Width **23** (12–48) — vertical strip; height matches pet

---

## 9. Nameplates

→ [19-nameplates.md](19-nameplates.md)

Blizzard nameplate threat (Progressive, Flash, Health Bar Color, Threat warning) is edited here only.

### Post–Dragonflight / Midnight retail
Threat/level extras are Classic / Forever only; post-DF uses Blizzard plates.

**Buff / debuff countdown**
- Size is a fixed product constant (reload to apply); no live slider in options today.

### Forever
**Threat**
- **Threat visibility** — In group only (**default**) | Always | Never
- **NPC threat rank/%** — **on**
- **Show threat percentage** — **on** (game `threatShowNumeric`)
- **Enemy player targeting you** — **on**

**Buff / debuff countdown**
- Size is a fixed product constant (reload to apply); no live slider in options today.

### Pre-DF / Classic
**Threat**
- **Threat visibility** — In group only (**default**) | Always | Never
- **NPC threat border + rank/%** — **on**
- **Enemy player targeting you** — **on**

**Level**
- **Show level overlay (Modern style)** — **on**

**Buff / debuff countdown**
- Size is a fixed product constant (reload to apply); no live slider in options today.

---

## 10. Status Bars

→ [16-status-bars.md](16-status-bars.md)

Intro: shared height; placement on Layout; item tracking always per character.

- **Status bar settings scope** — Account-wide | Character-specific — **default: Account-wide**
- **Show currency (gold) bar** — **on**
- **Hide experience bar when not gaining XP** — **off**
- **Bar height** — **18** (10–40)
- **Reset status bar options to defaults**

### Account gold (multi-character tooltip)
- **Stored character** (dropdown)
- **Delete selected character from ledger** (confirm)

### Inventory awareness
When Syndicator is loaded, location lines on tooltips come from that addon (these toggles are disabled).
- **Show item locations on tooltips** — on
- **Show currency locations on tooltips** — on (hidden on Era)
- **Only while Shift is held** — off
- **Connected realms only** — off
- **Same faction only** — off
- **Include equipped items** — on
- **Include guild bank** — on (hidden when the client has no guild bank)
- **Blank line before inventory block** — on
- **Show race / gender icons** — on

### Honor & Arena *(clients that support)*
Per character.
- **Show Honor on status bar** — **off**
- **Show Arena Points on status bar** — **off**

### Item currency (bag counts)
Always **per character**.
- **Show item currency on gold strip** — **on**
- Slot grid (drag/reorder/assign/clear) — default one empty slot

---

## Chat

Show or hide buttons on the chat column. A button is hidden from this page when that button does not exist on the client.

- Social, Channels, Guild, Character Info, Bags, Copy Chat, FluxUI Options, Chat Menu

URL color, message color, fade, and max lines are stored on `global.chatCopyPaste` and are not rows yet.

---

## 11. MicroMenu

→ [17-micromenu.md](17-micromenu.md)

Intro: drag order; under-icon strip cycles **Off → Account → Character → Off** (separate from bar scope).

### Micro menu bar scope
Account-wide | Character-specific — **default: Account-wide**  
(size, spacing, unified order; **not** Layout placement; trade skills always character)

### Editor
Embedded micro menu config preview (order + visibility).

### Trade skills *(always character)*
- **Enable trade skill micro buttons** — **on**
- **Layout mode** — Per-profession | Fixed split (primary + secondary flyout) (**default**) | Global
- **Global style** (if Global) — All individual (**default**) | One flyout | Both
- Per-profession: Individual button | In flyout | Off (primaries → individual, secondaries → flyout by default)

### Size
- **Button size** — **0.9** (0.5–1.5)
- **Spacing offset** — **−2** (−12…16)
- **Reset layout to defaults** — size 90%, spacing −2 only

---

## 12. Binding

→ [13-binding-system.md](13-binding-system.md)

Full embedded browser/editor (not Ace rows).

Chrome labels include:
- **Bindings source** — Live (current) / Respec profiles
- Filters: All · Unbound · Default · Customized · On bar / Stance / Extra / Multi-cast · Bar / EBS key only
- **Search...** · sort **ABC** / **Key** · **Show on keyboard**
- Notes: Preview saves to Respec only; Sticky across Respec survives Load/Apply
- Unbound hint; Equipment slots / Pet category tabs

**Keyboard visualizer** (account-wide prefs):
- Checks: **Loaded** (on) · **Empty** (off) · **Extra** (on) · **Mouse** (on)
- Source: All | Binding | Bars | Extra
- Layout **QWERTY**, size **100**
- Status may reference `/fluxbind viz`

Deep editor areas: Cast · Multi-cast · Conditions · Targets · Forms · Status · Bar & Badges (and related).

---

## 13. Profiles

Ace **Profiles** tab: create / copy / delete / reset for the active Ace profile. Does not clone every character-only module store.

---

## Player-facing commands (product)

| Command | Role |
|---------|------|
| `/fluxui` · `/fluxoptions` | Open options |
| `/fluxui bliz` · `blizzard` | Same FluxUI options window |
| `/fluxui raidpreview` | Raid world preview |
| `/fluxwindow` | Flux Window helpers |
| `/fluxrespec` | Respec helpers |
| `/fsalvage` · `/fluxsalvage` | Salvage toggle / status / options |
| `/flyout` | Custom flyout macros |
| `/buyemall` · `/buyemall confirm` | Bulk buy / confirm large buys |
| `/alreadyknown` | Already Known helpers |
| `/fluxhearth` · `/fluxconsumables` · `/fluxtrinket` | Extra-button helpers |
| `/fluxbind viz` | Key visualizer |
| `/fluxdefaults` | Apply Flux game-setting / key packs |

Debug / performance traces are out of scope for the rewrite bible.

---

## Stored but not exposed as options rows today

- Chat copy/paste colors, fade, and max lines (`global.chatCopyPaste`)
- Raid target/mouseover highlight colors (defaults only)

Rewrite may expose these under Other / Raid if desired.

## Relationships

- Every system doc’s Options section should match this catalog
- Layout detail → [06-layout.md](06-layout.md)
- Defaults packs → [05-defaults-and-bindings.md](05-defaults-and-bindings.md)

## Explicit non-goals

- Hiding critical toggles behind undocumented slash commands only
- Separate Classic-only vs Retail-only options addons
- Documenting library/Ace internals
