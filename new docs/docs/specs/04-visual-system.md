# Visual system (borders, accents, unified layout)

## Purpose

Give every Flux surface one recognizable chrome language so the HUD feels like a single console—not a pile of floating boxes with mismatched edges.

## What the player sees

- **Flux border package** — Corner and edge framing in a Battlefield Map–inspired style, with optional dark fill behind content.
- **Accent modes**
  - Class color
  - Natural atlas / texture colors
  - Custom RGB
- Accent can tint **border only** or **border + backdrop**.
- **Unified bottom envelope** — One continuous border around NonCombat grid → Action Bar → Combat grid → Trinket Menu, extending toward the Flux Window when open.
- **Gap fills** — Matching backdrop tint where pieces leave visual holes (e.g. between trinkets and the Flux Window, or between NonCombat and Combat when the Info Frame sits elsewhere).
- Optional second envelope when Micro Menu and Status Bars sit side-by-side in the classic stacked layout.

## Behaviors

- Appearance changes in options **live-update** already bordered Flux surfaces.
- The unified envelope watches which bottom pieces are shown and whether action-bar minirows are expanded (content present or drag-over), then repositions to match.
- Some Status Bar placements disable the micro/status unified border so layouts do not double-frame awkwardly.
- Older clients without modern atlases still get a consistent legacy texture packing so Classic and Retail feel related.

## Options / customization

- **General → Appearance → Accent** — Class color (default) | Default atlas | Custom color (+ **Custom accent color**)
- The options window uses the same Flux border and accent fill as the other panels. Accent also colors the selected sidebar row, the active subpage underline, toggle-on, and slider fill.
- Layout placements that change which envelopes are drawn — [06-layout.md](06-layout.md) (Info on strip vs status vs minimap; Status under micro / above bar / screen bottom; Micro placements)
- Full catalog: [26-options-map.md](26-options-map.md)

## Relationships

- Softens edges of [11-action-bars.md](11-action-bars.md), [12-extra-button-system.md](12-extra-button-system.md), [10-flux-window.md](10-flux-window.md), [16-status-bars.md](16-status-bars.md), [17-micromenu.md](17-micromenu.md), [18-minimap-and-trackers.md](18-minimap-and-trackers.md), cast bars on [14-unit-frames.md](14-unit-frames.md).
- Meter skins in the Flux Window can pick up the same accent tint when Details uses a WoW-like skin.
- Scale/squeeze math in [05-defaults-and-bindings.md](05-defaults-and-bindings.md) assumes this sealed bottom strip geometry.

## Client availability

| Client | Availability |
|--------|--------------|
| Era | Full (legacy texture path if needed) |
| Anniversary | Full |
| Classic | Full |
| Midnight | Full |

## Rewrite intent notes

Accent + sealed bottom strip are **core brand**. If the first impression does not read as one console, the visual system has failed—even if every widget works.

## Explicit non-goals

- Per-widget random border styles with no shared accent.
- Freely movable decorative frames that break the docked console metaphor.
- Glow-heavy “neon UI” as the default identity (proc glows on bars are gameplay feedback, not the chrome theme).
