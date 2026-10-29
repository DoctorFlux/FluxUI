# Nameplates

## Purpose

On Classic-family clients, add light Flux overlays to Blizzard nameplates—threat tint/rank, targeting feedback, optional level text, and clearer aura countdown digits—without replacing the nameplate system wholesale.

On Forever (camelot), show a secret-safe threat rank/% overlay that uses the same numeric as the target frame (`UnitThreatPercentageOfLead` while tanking; `threatShowNumeric`). Leave Blizzard Progressive / Flash / Health Bar Color to the game's Nameplates options.

On Live Midnight, keep Blizzard threat/level plates and only replace aura countdown digits with the same Flux overlay as Classic.

## What the player sees (Classic / pre-Dragonflight intent)

- Blizzard nameplates with Flux **threat border tint** and rank / percentage under health where configured
- Red border feedback when an enemy player targets you
- Optional “Lvl. N” (or skull) on Modern-style plates
- Smaller buff/debuff countdown digits for readability (same 12px overlay on every client)

Flux does **not** invent a full nameplate replacement suite (no Plater clone as the product goal).

## Behaviors

- Does not set nameplate CVars as its primary job (defaults packs may still recommend packs separately)
- Overlays stay parented so they follow world draw order
- Does not wrap or replace the entire aura list pipeline
- **Classic family (Era / Anniversary / Classic):** Flux threat overlays plus “Lvl. N” (Modern style) and 75% aura countdown digits. Classic family wins if a camelot probe misfires.
- **Retail post-DF / Midnight (live):** no Flux threat or Lvl overlay (Blizzard plates). Aura countdown uses the same taint-safe 12px Flux overlay as Classic; Settings preview plates are skipped.
- **Forever:** secret-safe Flux threat rank/% overlay, no Lvl overlay, same 12px aura countdown overlay (preview plates skipped).

## Options / customization

**Nameplates** tab in `/fluxui` (full rows: [26-options-map.md](26-options-map.md)):

### Post–Dragonflight / Midnight (live)
Threat/level extras stay informational — retail uses Blizzard plates. Buff/debuff countdown uses the Flux overlay (same size as Classic).

### Forever
- **Threat visibility** — In group only (**default**) | Always | Never
- **NPC threat rank/%** — on
- **Show threat percentage** — on (game `threatShowNumeric`)
- **Enemy player targeting you** — on
- Blizzard Progressive / Flash / Health Bar Color remain in the game Nameplates options
- Aura countdown size is a fixed product constant (reload); no live slider in options today

### Classic / pre-DF
- **Threat visibility** — In group only (**default**) | Always | Never
- **NPC threat border + rank/%** — on
- **Enemy player targeting you** — on
- **Show level overlay (Modern style)** — on
- Aura countdown size is a fixed product constant (reload); no live slider in options today

Recommended nameplate CVar packs may still come from `/fluxdefaults` ([05-defaults-and-bindings.md](05-defaults-and-bindings.md)).

## Relationships

- Defaults nameplate packs → [05-defaults-and-bindings.md](05-defaults-and-bindings.md)
- Secret-value policy → [03-midnight-constraints.md](03-midnight-constraints.md)
- Matrix row → [02-multi-client-matrix.md](02-multi-client-matrix.md)

## Client availability

| Client | Availability |
|--------|--------------|
| Era | Full (threat, Lvl overlay, 12px countdown) |
| Anniversary | Full (threat, Lvl overlay, 12px countdown) |
| Classic | Full (threat, Lvl overlay, 12px countdown) |
| Midnight | Countdown overlay only — no Flux threat / Lvl |
| Forever | Secret-safe rank/% overlay + countdown overlay; no Lvl |

## Rewrite intent notes

Nameplates are a **Classic comfort feature**. Do not block the Midnight rewrite on rebuilding automated threat overlays. If Midnight later exposes safe display hooks, treat them as additive.

## Explicit non-goals

- Plater / ThreatPlates feature parity.
- Combat branching on secret nameplate values on Midnight.
- Hiding Blizzard nameplates to draw a fully custom unit stack in the world.
