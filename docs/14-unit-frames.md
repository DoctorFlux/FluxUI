# Unit frames

## Purpose

Provide Flux-styled (or optional Blizzard) frames for the player and important units—readable health/power, cast, auras, and threat—without requiring a second all-in-one UI pack.

## What the player sees

Custom Flux frames (or Blizzard defaults, per toggle) for:

- Player
- Target
- Target of target
- Focus
- Focus target
- Pet
- Pet target

Typical chrome per unit:

- Optional portrait strip (2D or 3D where available)
- Stacked health / main resource / optional alternate power
- Cast bar
- Auras on target/focus (configurable density)
- Threat chrome on target/focus
- Satellite widgets: class power, combo points, swing timer, flight progress on taxi, etc.

Layout placement of player + target can be stacked or side-by-side via the Layout tab.

## Behaviors

- Heal prediction and absorb display where the client supports them
- Health-loss and power-cost overlays for feedback
- MP5 tick overlay on older clients
- Weapon swing timer on the player cast-bar slot (Classic Era / TBC Anniversary / Wrath: CLEU-accurate; Forever: `PLAYER_SWING` / `C_SwingTimer`, including wand, bow, gun, throw, and crossbow)
- Flight-path duration awareness on taxi tooltips and cast-bar progress
- Portrait combat feedback
- Forever rogues and Cat Form druids: native red combo-point artwork above the
  player frame, following target-bound points. Target unit-frame pips are disabled.
  Empty sockets stay visible at zero points while the class/form is eligible.
  Restricted combat counts go directly to display widgets without Lua comparisons.
- BigDebuffs-friendly portrait/aura layout when that addon is present
- Class/spec icon click for dual-spec or specialization flyout
- Transmog click helper on player
- Empty-target placeholder outline
- On Midnight / Forever: health/power/cast remain **display-oriented** under secret-value rules ([03-midnight-constraints.md](03-midnight-constraints.md))
- Target/focus threat bars read `Flux.Threat` (Forever APIs: situation, lead situation, lead %, detailed values). Rank/% hide when secret; tanking percent prefers lead % over raw %. Numeric % follows the game `threatShowNumeric` option.

## Options / customization

**Unit frames** tab in `/fluxui` (full rows: [26-options-map.md](26-options-map.md)). Placement of player/target: [06-layout.md](06-layout.md).

### General
- **Unit frame settings scope** — Account-wide | Character-specific (default Account-wide)
- Flux vs Blizzard toggles (all on): Player · Target · ToT · Focus* · Focus target* · Pet · Pet target
- Features (on): 3D portraits · Health loss · Power cost · MP5 ticks · Swing timer (Era / Anniversary / Wrath / Forever) · Flight path timers / cast bar / taxi tooltips
- **Threat bar visibility** — Always | In group or raid only (**default**) | Never
- **Show threat percentage** — on (game CVar `threatShowNumeric`; also used on nameplates)
- **Reset unit frame options to defaults**

### Per-unit (defaults)

- **Player class power size:** 50–200%, default 100%. Scales every unit-frame
  class resource, including Classic/Forever combo rows, arcane charges, holy
  power, runes, chi, shards, essence, and totems. Changes wait until combat ends.
  Forever's player combo row is 20% smaller at the default size; nameplates use
  their independent size and position.
- **Player:** portrait on · W 325 · H 100 · split 60%
- **Target:** portrait on · empty placeholder on · W 500 / H 100 (or follow Player in side-by-side) · split 60% · auras size 35 · lock own debuff on · own min 75% · spacing 2 · max buffs 32 / debuffs 16 · threat position Portrait (default)
- **ToT:** W 125 · H 60 · split 60%
- **Focus:** portrait on · W 119 · H 50 · aura size 20 · same lock/spacing/max · threat Portrait
- **Pet:** portrait on · cast bar **off** · auras on mouseover **on** · W 100 · H 50 · split 60%
- **Pet target:** W 23 (vertical strip; height matches pet)

## Relationships

- Accent/cast borders → [04-visual-system.md](04-visual-system.md)
- Squeeze near Flux Window → [05-defaults-and-bindings.md](05-defaults-and-bindings.md)
- Mouseover cast / keybind fix with bars → [11-action-bars.md](11-action-bars.md)
- Raid is separate compact system → [15-raid-frames.md](15-raid-frames.md)
- Vehicle exit / duration bars / loot rolls often anchor near player → [25-other-qol.md](25-other-qol.md)
- Inspiration → TPerl Classic/Retail in [90-reference-inspirations.md](90-reference-inspirations.md)

## Client availability

| Client | Availability |
|--------|--------------|
| Era | Full Classic feature set (swing, MP5, dual-spec click) |
| Anniversary | Full |
| Classic | Full unit chrome; swing timer N/A on post-Cata track (Cata / MoP) |
| Midnight | Full Flux chrome; swing timer N/A; secret-safe display for combat numbers including threat bars; Retail talent/spec click |
| Forever | Same as Midnight for threat bars; swing timer available (`PLAYER_SWING` melee and ranged) |

## Rewrite intent notes

TPerl informs **dense but readable** unit chrome (portraits, auras, threat adjacency)—not a pixel clone. Prefer per-unit Flux-vs-Blizzard toggles so healers can mix preferences.

## Explicit non-goals

- Replacing raid/party compact frames (see Raid frames).
- Built-in boss frames suite as a v1 requirement.
- Combat decision overlays that branch on secret health thresholds on Midnight.
