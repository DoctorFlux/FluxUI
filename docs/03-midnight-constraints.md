# Midnight constraints (product limits)

## Purpose

Retail Midnight (patch family **12.0.x → 12.1.0**) introduced **secret values** and related combat restrictions. This document states what that means for FluxUI as a **product**: what players can still get, what must become display-only, and what must not be promised on Midnight.

Living references (do not freeze patch trivia into the rewrite):

- [Patch 12.0.0/API changes](https://warcraft.wiki.gg/wiki/Patch_12.0.0/API_changes)
- [Patch 12.0.1/API changes](https://warcraft.wiki.gg/wiki/Patch_12.0.1/API_changes)
- [Patch 12.0.5/API changes](https://warcraft.wiki.gg/wiki/Patch_12.0.5/API_changes)
- [Patch 12.0.7/API changes](https://warcraft.wiki.gg/wiki/Patch_12.0.7/API_changes)
- [Patch 12.1.0/API changes](https://warcraft.wiki.gg/wiki/Patch_12.1.0/API_changes)
- [Secret Values](https://warcraft.wiki.gg/wiki/Secret_Values)

Current shipping target when this bible was written: **12.1.0**.

## What secret values mean for players

Blizzard’s stated aim is to limit addons doing complex **decision-making** from combat information, while still allowing **look-and-feel** customization.

For FluxUI that translates to:

| Allowed intent | Disallowed intent |
|----------------|-------------------|
| Show health, power, cast, and aura chrome that looks good | Compare combat numbers to choose cooldowns, targets, or rotations |
| Theme bars, borders, fonts, layouts | Branch UI logic on “is health below X%” using secret combat data |
| Pass display values into engine-accepted progress/color surfaces | Build custom combat meters from restricted combat-log registration |
| Keep bindings and macros authored **out of combat** | Rebuild secure combat behavior mid-fight from secret unit state |

## Product rules for the rewrite

1. **Display is first-class** — Unit frames, raid frames, cast bars, and status text may continue to *look* like Flux, using paths the game allows for showing secret-aware values.
2. **No combat AI** — Flux does not become a combat assistant that reads secret health/power/auras to decide actions. Assisted Combat, if present, is Blizzard’s feature surfaced as a bind—not Flux logic.
3. **Author ahead of time** — Binding conditions, restock lists, junk rules, and respec profiles are configured outside the secret decision problem; they must not depend on reading forbidden combat state to recompile mid-fight.
4. **Meters and threat** — Prefer embedding Details! or Blizzard’s native Midnight meter. Flux’s job is layout, skinning, and tab hosting—not inventing a CLEU-based meter.
5. **Nameplates** — Classic-style threat rank / level overlays that require branching on combat data stay **Classic / pre-Midnight**. On Midnight, do not promise custom threat decision overlays; stick to safe display or leave Blizzard plates alone.
6. **Settings safety** — Some Retail options/CVar writes that historically tainted nameplate or raid preview UIs should be treated as carefully deferred or skipped; players still get Flux defaults where safe.
7. **Classic unchanged in spirit** — Era, Anniversary, and Classic clients keep fuller logic where those clients still allow it. Midnight constraints are not an excuse to gut Classic features.

## Impact by Flux system (summary)

| System | Midnight product stance |
|--------|-------------------------|
| Action bars / glows / badges | Keep look, paging, and feedback; do not invent secret-based rotation helpers |
| Binding | Keep Clicked-style authoring; apply outside combat; no secret-driven mid-fight rebuild |
| Unit / raid frames | Keep Flux chrome; health/power/status are display-oriented |
| Nameplates | No Classic-style branching overlays; informational options only |
| Meter tab | Details or Blizzard embed; layout editor; no home-grown CLEU meter |
| Vendor / restock / junk | Unaffected in principle (inventory/merchant, not combat secrets) |
| Salvage / Respec / Micro / Minimap | Unaffected in principle |

## Relationships

- Client matrix → [02-multi-client-matrix.md](02-multi-client-matrix.md)
- Frames → [14-unit-frames.md](14-unit-frames.md), [15-raid-frames.md](15-raid-frames.md), [19-nameplates.md](19-nameplates.md)
- Meter hosting → [10-flux-window.md](10-flux-window.md)
- Binding philosophy → [13-binding-system.md](13-binding-system.md)

## Rewrite intent notes

Treat Midnight as a **capability gate**, not a second product. Document player-visible “works / display-only / unavailable” in each system doc. Re-check wiki patch notes when Blizzard loosens or tightens which displays accept secrets.

## Explicit non-goals

- Teaching how to bypass secret values
- Promising pre-Midnight WeakAura-style combat decision packs inside Flux
- Freezing a single patch’s API list as permanent gospel without revalidation
