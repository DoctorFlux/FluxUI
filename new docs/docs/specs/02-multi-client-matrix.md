# Multi-client matrix

## Purpose

FluxUI must feel like **one product** on four Blizzard client families. This matrix records what each system is expected to do per client so the rewrite does not silently assume Retail-only or Classic-only behavior.

## Client families

| Short name | Meaning | Blizzard UI reference tree (concept) |
|------------|---------|--------------------------------------|
| **Era** | Classic Era | `wow-ui-source-classic_era` |
| **Anniversary** | TBC Anniversary / Classic Anniversary | `wow-ui-source-classic_anniversary` |
| **Classic** | Classic 2019 track (currently MoP-era) | `wow-ui-source-classic` |
| **Midnight** | Retail Midnight, currently patch **12.1.0** | `wow-ui-source-live` |
| **Forever** | Camelot / Forever (Midnight-family UI; treated as `Client.isCamelot`) | `wow-ui-source-forever` |

Legend: **Full** = feature works as designed · **Partial** = subset / display-only / different backend · **N/A** = not applicable on that client

Forever ships in the Midnight column below unless a row calls it out (nameplate threat overlays, swing timer, secrets backend, **bank UI**).

Forever’s bank is War Within `BankFrame`/`BankPanel` names with **classic bags-in-bank** layout (`C_Bank.ShouldUsePlayerBagsInBank()`): 8-column pages, bag slots on the frame, character vs warband via right-side page tabs (up to 9+9 tab bag IDs). Live Midnight keeps named tabs and a bottom TabSystem. Flux inventory must enumerate tabs until nil and keep restock/junk/window-mover off that Camelot chrome.

## Matrix by system

| System | Era | Anniversary | Classic | Midnight |
|--------|-----|-------------|---------|----------|
| Visual border / accent | Full | Full | Full | Full |
| Unified bottom envelope | Full | Full | Full | Full |
| Defaults / CVar packs | Partial (gated packs) | Partial | Partial | Partial (safer deferral; some packs blocked) |
| Flux keybind pack | Full | Full | Full | Full (Assisted Combat where present) |
| Scale / horizontal squeeze | Full | Full | Full | Full |
| Flux Window shell | Full | Full | Full | Full |
| Map ↔ Minimap embed | Full | Full | Full | Full |
| Map pins mirroring | Partial | Partial | Partial | Partial (provider-dependent) |
| Meter: Details embed | Full if Details | Full if Details | Full if Details | Full if Details |
| Meter: Blizzard native | N/A | N/A | N/A | Partial (when Details absent) |
| Threat pane in meter | Details path | Details path | Details path | Details path via `Flux.Threat`; skip secret values; no Classic `/100` on Midnight/Forever |
| Action bar 19-col + minirows | Full | Full | Full | Full |
| Stance / form paging | Full | Full | Full | Full |
| Vehicle / possess paging | Full | Full | Full | Full |
| Skyriding / dragonriding page | N/A | N/A | N/A | Full |
| Pet bar | Full | Full | Full | Full |
| Proc / cast glow feedback | Full (Classic-style) | Full | Full | Partial (Retail glow language; identity continuity still required) |
| Corner badges | Full | Full | Full | Full |
| Extra Ability HUD re-anchor | N/A | N/A | N/A | Full |
| Combat / NonCombat grids | Full | Full | Full | Full |
| Trinket menu | Full | Full | Full | Full |
| Binding editor / conditions | Full | Full | Full | Full (no mid-combat rebuild from secret data) |
| Unit frames Flux vs Blizzard | Full | Full | Full | Full (display-safe combat numbers) |
| Swing timer | Full | Full | N/A (post-Cata track) | N/A (post-DF retail) |
| Flight path cast progress | Full | Full | Full | Partial / client-dependent |
| Raid frames | Full | Full | Full | Full (status text display-safe) |
| Status bars gold/XP/rep | Full | Full | Full | Full |
| Honor / Arena on gold strip | Full where exists | Full where exists | Full where exists | Partial / often N/A |
| Account gold ledger | Partial | Partial | Partial | Full (post-DF account gold story) |
| Micro menu replacement | Full | Full | Full | Full |
| Minimap square + embed | Full | Full | Full | Full |
| Objective tracker dock | Partial | Partial | Partial | Full (scroll body post-DF) |
| Nameplate threat / level overlays | Full | Full | Full | Live Midnight: informational / Blizzard plates. Forever: secret-safe Flux threat overlay (no level). Aura countdown overlay on all four. |
| Vendor / junk / restock | Full | Full | Full | Full |
| Already Known tint | Full | Full | Full | Full |
| Bank restock | Full | Full | Full | Full (warband-aware). Forever: bags-in-bank restock button by the search box, not bottom-left over bag slots |
| Salvage overlay | Full | Full | Full | Full |
| Respec profiles (Classic talents) | Full | Full | Full | N/A for Classic trees |
| Respec Retail loadouts | N/A | N/A | N/A | Full |
| Respec action-bar snapshot | Full | Full | Full | Skipped on loadout clients |
| SoD rune presets | N/A / SoD only | N/A | SoD-like only | N/A |
| Baganator bridges | If present | If present | If present | If present |
| Window mover (Blizzard windows) | Full | Full | Full | Full (secret-safe apply). Forever BankFrame: drag only, no scale / SetPoint fight against growing bags-in-bank height |
| Character Info overlays | Full (CSC + paperdoll extras) | Full (TBC CSC + paperdoll extras) | Partial (pane hooks; no Vanilla CSC) | Full (Live `CharacterStatsPane` / Forever ScrollBox row Init pin + ilvl format) |
| ConsolePort coexistence | If present | If present | If present | If present |

## Cross-cutting rules

1. **Capability first** — Each feature asks “does this client have the game systems?” before assuming UI.
2. **Same labels, different guts** — Players see the same Flux Window tabs and option names; backends may differ (e.g. meter).
3. **Midnight combat display** — Health, power, threat ranks, cast progress, and similar may be shown, but Flux must not use them for combat decision branching. Details: [03-midnight-constraints.md](03-midnight-constraints.md).
4. **Optional deps** — Details, Baganator, BigDebuffs, Questie, TacoTip, Compact Raid Frames, ConsolePort change richness, not whether Flux loads.

## Relationships

- Product story → [01-product-overview.md](01-product-overview.md)
- Midnight limits → [03-midnight-constraints.md](03-midnight-constraints.md)
- Per-system detail → docs `10`–`25`

## Rewrite intent notes

Design one options surface and one HUD layout language. Gate expansion-specific pieces (skyriding, warband bank, Retail talent loadouts, Blizzard damage meter) behind clear client rows in this matrix—not behind silent failure.

## Explicit non-goals

- Separate addon packages per client (unless packaging later requires it; the **concept** is one product).
