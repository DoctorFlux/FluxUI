# Defaults and Flux keybind pack

## Purpose

Ship a **recommended game setup** so a fresh character immediately feels like Flux: sensible keys for the bottom console, control/camera/nameplate packs, and layout math that keeps the sealed strip usable at low UI scale when the Flux Window is open.

## What the player sees

- A **FluxUI** category in Blizzard’s Key Bindings UI for Flux-specific actions (mount, hearth, consumables, combat pots, utility slots, trinkets, reload UI, class helpers, etc.).
- The stock **Action Bar** keybind list shows **Action Buttons 1–19** as one strip (the extra seven columns keep their existing extra-bar key names under the hood). Extra-bar keybind buckets (Action Bar 2–8 / 2–5) and page-up/page-down rows are hidden on Era, Anniversary, and Classic. On Midnight the 13–19 rows are still named Action Button 13–19; leftover extra-bar *sections* may still appear in Key Bindings because Retail Settings must not be rewritten.
- Gameplay → Action Bars no longer offers “show extra bar” checkboxes on Classic-family clients. Extra bars stay off in-world on every client so Flux’s one 19-column strip is the bar the player binds.
- Optional apply/reset flows for “Flux defaults” vs leaving Blizzard settings alone.
- At very low UI scale with the Flux Window docked right, the bottom strip and related pieces **narrow (squeeze)** instead of overlapping the window.

## Behaviors

### Keybind pack (concept)

Named binds the player can assign (labels may adapt by class, e.g. conjure helpers):

- Reload UI
- Smart mount / hearth / vendor mount
- Food / water / consumables
- Combat heal pot / bandage / healthstone / mana pot / mana gem
- Assisted Combat (where the client has it)
- Class teleport; mage teleport/portal toggle and conjures
- Utility slots 1–4
- Trinket top / bottom

Most of these are **named hooks** into live Flux buttons (grids, utilities, trinkets)—the Key Bindings UI is how players assign keys; the Extra Button and Action Bar systems perform the clicks.

A default keyboard template can also seed the main action columns and multi-bar style commands so the 19-column bar is usable out of the box.

### Defaults packs

Themed recommendation packs (applied carefully, with combat locking and Retail-safe deferral when Options UI is open):

- Nameplates
- Controls / self & focus cast
- Combat
- Action bars
- Interface / raid
- Camera
- Chat

Install state can track whether critical settings still match Flux defaults (**fresh** vs **modified**).

### Scale and squeeze

- Computes a comfortable UI scale from aspect ratio (ultrawide vs 16:9), with a hard floor around **0.75**.
- When near that floor and the Flux Window occupies the right side, computes **horizontal squeeze** for the action bar, grids, trinkets, and (separately) unit frames / related buff placement so the docked hub remains the hard right boundary.

## Options / customization

There is **no Defaults options tab**. Players use:

- `/fluxdefaults` — apply Flux game-setting / key packs (account or character flows)
- **Action Bars → Reset keybindings to Flux defaults** (+ **Enter Binding Mode**)
- Per-tab **Reset … to defaults** buttons (Layout, Unit frames, Raid frames, Status Bars, Micro size, Extra button visibility, FluxWindow tabs, etc.)
- Ace **Profiles** tab for option-profile create/copy/delete

Full options catalog: [26-options-map.md](26-options-map.md).

## Relationships

- Labels ↔ player Key Bindings category; click targets ↔ [12-extra-button-system.md](12-extra-button-system.md)
- Squeeze boundary ↔ [10-flux-window.md](10-flux-window.md) visibility
- Packs must respect [03-midnight-constraints.md](03-midnight-constraints.md) and Retail settings taint caution
- Visual envelope assumes squeezed geometry still looks sealed → [04-visual-system.md](04-visual-system.md)

## Client availability

| Client | Availability |
|--------|--------------|
| Era | Full keys; gated CVar packs |
| Anniversary | Full keys; gated packs |
| Classic | Full keys; gated packs |
| Midnight | Full keys; some packs deferred/skipped for Settings/nameplate/raid-preview safety; camera max zoom resolved per client. Action Button 13–19 labels apply; extra-bar Key Bindings sections may still list |

## Rewrite intent notes

Defaults are an **onboarding gift**, not a permanent prison. Always allow “modified” play. Squeeze is part of the product promise: the Flux Window must not destroy the action strip on ultrawide min-scale setups.

## Explicit non-goals

- Silently overwriting player keybinds every login.
- Forcing nameplate or raid CVars that break Blizzard Settings preview on modern Retail.
- Documenting implementation of override-binding internals.
