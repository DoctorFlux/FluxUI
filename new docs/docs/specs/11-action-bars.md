# Action bars

## Purpose

Own the primary combat button strip: one smart bottom bar that pages with forms, stealth, vehicles, and (on Midnight) skyriding—while keeping SHIFT/CTRL layers, proc feedback, and corner badges readable under heavy key mashing.

## What the player sees

- A single **19-column** bottom bar: **12 main page slots + 7 “page 2” slots** on the same row (not Blizzard’s multi-bar strip layout).
- Each column can expose a **main button** plus **SHIFT and CTRL minirows** (secondary / tertiary), above or below the main row.
- **Smart promotion**: empty main faces can show content promoted from minirows so the bar stays compact until hover/drag expands layers.
- Class-colored / accent Flux border chrome on the strip.
- Up to **three corner badges per action slot** previewing alternate actions the main face is not currently showing.
- Separate **pet bar** (5×2) and **hybrid stance bar** (true forms + spell extras), placed near the player frame or stacked with status/window when the player frame is off.
- Vehicle exit control near the player frame; Retail Extra Ability HUD re-anchored near the Flux Window rather than fighting the bottom chrome.
- Blizzard default action bars are hidden/suppressed while Flux owns the strip.
- Blizzard’s own Key Bindings UI treats the strip as **Action Buttons 1–19** under the primary Action Bar header. Extra-bar show/hide options are suppressed on Classic-family clients because Flux owns one 19-column bar, not Blizzard’s multi-bar layout. Midnight still names buttons 13–19 correctly; extra-bar *sections* in Key Bindings may remain so Retail Settings preview stays untainted.
- **The Flux strip stays on screen in a vehicle.** Vehicle, possess, and override abilities page onto those same 12 columns. Blizzard’s vehicle/override bar stays Blizzard-owned (not hidden by Flux) so vehicle chrome keeps working; Flux must not Hide or EnableMouse it, or taint rides into its `SetAttribute` path.

## Behaviors

### Paging and combat states
Secure state flipping (Bartender-style intent) for the first 12 columns across:

- Stances / forms (bonus bars)
- Stealth-augmented forms (e.g. prowl / shadow dance feel)
- Vehicle / possess / override
- Dragonriding / skyriding-style bonus page (Midnight)
- Optional modifier temporary page switches

Vehicle/possess content pages **onto Flux buttons** (keys stay on Flux). The native driver uses a Bartender-style `possess` token resolved at page time with `GetVehicleBarIndex()`, so SHIFT/CTRL minirow invert follows the live vehicle page. The Flux strip does not hide to “make room.” Blizzard’s override/vehicle bar is left alone so it can show and update; hiding it taints layout.

### Feedback (glow / cast / checked)
Identity-owned visual feedback so effects follow the **spell or item the player sees**, across:

- Main ↔ SHIFT/CTRL mini paging
- Bar ↔ corner badge swaps
- Macro condition flips

Includes proc / SAO-style glow, cast/channel/interrupt/reticle overlays where the client supports them, and checked/active state—with **continuity across paging** so animations do not restart awkwardly mid-mash.

### Input
- **Binding mode**: hover a button, press a key; works on main bar, minirows, pet, stance, combat/NC grids, trinkets; dims unused columns.
- **Mouseover cast**: keybinds cast on the unit under the cursor (synced with Blizzard mouseover preference).
- Mouse-button / wheel keys still fire correctly while hovering unit frames.
- Horizontal **squeeze** with grids/trinkets when the Flux Window crowds the right edge.

### Stance and pet
- Stance: drag reorder and hide/show slots per character; dedup so the same ability is not shown twice as form + extra; pet bar repositions when stance layout changes.
- Pet: shows with pet, hides in vehicle UI; participates in binding mode; shares VFX language.

## Options / customization

**Action Bars** tab in `/fluxui` (full rows: [26-options-map.md](26-options-map.md)):

- **Action bar scope** — Account-wide | Character-specific (default Account-wide)
- **Enter Binding Mode** · **Reset keybindings to Flux defaults** (combat-locked)
- **Minirow position** — Top (default) | Bottom
- **Enable action bar VFX** — on (pre-DF / Classic clients)
- **Mouseover cast** — on (matches spell book)
- Classic: **Auto rank up** (off) · **Rank up all spells** · blacklist panel
- Performance intervals: range **0.25**, extra-button range **0.18**, mouseover **0.07**, macro usable **0.05**, action usable **0** (0 = off)
- Stance bar slot order — always per character; drag reorder; right-click hide/show; reset
- Extra button visibility grid + NC flyout panel + utility slots (see [12-extra-button-system.md](12-extra-button-system.md))
- Stance placement also on **Layout** ([06-layout.md](06-layout.md))

## Relationships

- Key names and squeeze → [05-defaults-and-bindings.md](05-defaults-and-bindings.md)
- Badges and macros ↔ [13-binding-system.md](13-binding-system.md)
- Grids / trinkets / utilities ↔ [12-extra-button-system.md](12-extra-button-system.md)
- Envelope ↔ [04-visual-system.md](04-visual-system.md)
- Respec can snapshot/restore bar content on Classic → [23-respec.md](23-respec.md)
- Vehicle / Extra Ability → [25-other-qol.md](25-other-qol.md)
- Inspiration → Bartender4 (+ glow packages) in [90-reference-inspirations.md](90-reference-inspirations.md)

## Client availability

| Client | Availability |
|--------|--------------|
| Era | Full (Classic glow language, no skyriding page) |
| Anniversary | Full |
| Classic | Full |
| Midnight | Full paging including skyriding; Retail glow language; secret-safe display only for combat decisioning. Action Button 13–19 labels apply; extra-bar Key Bindings sections may still list |

## Rewrite intent notes

Match Bartender4’s mental model of **one authoritative bar with state paging**, plus Flux-specific 19-column layout, minirows, badges, and identity-stable glows. Glow packages (including modern glow-effect refs) inform feedback quality, not a particle theme for the whole UI.

## Explicit non-goals

- Keeping Blizzard multi-bar strips visible alongside Flux.
- Rotation helpers that read secret combat state on Midnight.
- Per-button free-float positioning as the default (console strip first).
