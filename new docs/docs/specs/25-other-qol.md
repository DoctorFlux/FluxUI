# Other quality-of-life

## Purpose

Collect smaller Flux behaviors that complete the HUD—chat setup, vehicle exit, Extra Ability placement, equip flyouts, character panel stats, duration bars, loot rolls, and coexistence with ConsolePort—without each needing a top-level product pillar.

## What the player sees / Behaviors

| Piece | Player-facing behavior |
|-------|------------------------|
| Trade Food / Water | On trade window (especially mages): quick Trade Food / Trade Water; left-click add stack, right-click conjure where relevant |
| HUD tooltip anchor | GameTooltip prefers sitting above the Flux Window; removed from Edit Mode clutter |
| Extra Ability HUD | Retail zone Extra Ability re-anchored near the Flux Window so it does not fight the bottom strip; stays off Blizzard’s bottom layout manager |
| Vehicle exit | Leave-vehicle control above the player frame (taxi / vehicle). Flux action strip stays visible and pages vehicle abilities; Blizzard’s vehicle bar is not hidden |
| Duration bars | Breath/fatigue-style mirror timers repositioned unless side-by-side layout forbids it |
| Loot rolls | Group loot roll frames above the player frame |
| Chat first-login | Positions/sizes/groups chat sensibly on first setup |
| Chat copy/paste | Copy/paste convenience for chat (ChatCopyPaste-style intent) |
| Equip slot flyout | ItemRack-style alternate gear menu from paperdoll slots using inventory candidates |
| Character Info overlays | Blizzard CharacterFrame stays. Era/Anniversary: dual-dropdown stats over `CharacterAttributesFrame`, quality borders, helm/cloak, wrist Item LvL + GearScore, TacoTip suppress. Live: ilvl `%.1f`, short Crit/Haste, click-to-pin on `CharacterStatsPane`. Forever: same pin/ilvl hooks on `CharacterStatsPaneScrollBox` list rows (`CharacterStatFrameScrollBoxBaseElementMixin.Init`; not the pet box). Click-to-pin feeds the Info Frame with Forever combat APIs (haste/hit/HP/movement). |
| ConsolePort coexistence | When ConsolePort (and related packages) load: suppress CP XP/rep/status bars so Flux Status Bars stay authoritative; disable CP micromenu takeover; leave other CP systems alone; defer reparent/hide work until out of combat |
| Perf debug | Developer performance debug (not a player feature) |

## Options / customization

Most pieces are automatic or lightly gated by **Layout** / **Unit frames** / **Status Bars** / **General** ([26-options-map.md](26-options-map.md), [06-layout.md](06-layout.md)).

- Chat copy/paste exists as a product feature but has **no options tab** today (rewrite may expose it)
- Character Info overlays keep Blizzard’s window and tabs; extras are panel-local (CSC dropdowns, quality, helm/cloak, wrist ilvl/GS, pane pin hooks)
- ConsolePort coexistence is automatic when detected (suppress CP status/micromenu takeover)
- Extra Ability / vehicle exit / duration / loot anchors follow Layout and unit-frame placement
- Related slashes: `/flyout`, `/fluxwindow`, and extras like `/fluxhearth` / `/fluxconsumables` / `/fluxtrinket`

## Relationships

- Extra Ability + tooltip ↔ [10-flux-window.md](10-flux-window.md)
- Vehicle exit / duration / loot ↔ [14-unit-frames.md](14-unit-frames.md)
- Equip flyout ↔ [21-inventory-foundation.md](21-inventory-foundation.md)
- Character Info overlays ↔ [16-status-bars.md](16-status-bars.md) (Info Frame click-to-pin)
- ConsolePort ↔ [16-status-bars.md](16-status-bars.md), [17-micromenu.md](17-micromenu.md)
- Nameplates (Classic overlays) live in [19-nameplates.md](19-nameplates.md) even though historically filed under “Other”

## Client availability

| Piece | Era | Anniversary | Classic | Midnight |
|-------|-----|-------------|---------|----------|
| Trade food/water | Full | Full | Full | Full |
| Extra Ability HUD | N/A | N/A | N/A | Full |
| Vehicle exit | Full | Full | Full | Full |
| Duration / loot anchors | Full | Full | Full | Full |
| Chat helpers | Full | Full | Full | Full |
| Equip flyout | Full | Full | Full | Full |
| Character Info overlays | Full (CSC dropdown + paperdoll chrome) | Full (TBC CSC rows + paperdoll chrome) | Partial (stats pane hooks if present; no Vanilla CSC dropdown) | Full (Live pane / Forever ScrollBox pin + ilvl; no CSC dropdown) |
| ConsolePort compat | If present | If present | If present | If present |

## Rewrite intent notes

Keep these as **thin, purposeful QoL**—easy to recreate—rather than expanding them into new major systems. ConsolePort policy is coexistence, not a Flux controller UI. Character Info stays an overlay on Blizzard’s window (CSC on Era/Anniversary, pane/ScrollBox hooks on Live/Forever).

## Explicit non-goals

- Building a Flux-native controller bar stack.
- A full chat replacement addon.
- A Flux-owned Character Info replacement (paperdoll, reputation, skills, honor, currency stay Blizzard).
- Mandatory gear-score culture; character stats are optional clarity.
