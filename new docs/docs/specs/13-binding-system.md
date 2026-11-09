# Binding system

## Purpose

Let players configure **what a key does under conditions**—targets, forms, hostility, multi-cast extras—not only “put a spell on a bar.” This is the Clicked-style brain behind Flux keys, corner badges, and free chords.

## What the player sees

- Options **Binding** tab with a spellbook-style browser and embedded editor.
- Editor areas covering: Cast, Multi-cast, Targets, Forms, Conditions, Status, Bar & Badges.
- **Key visualizer**: keyboard/mouse map of what is bound, filterable by modifiers and source (binding vs bar vs extra).
- Spellbook hooks to start a binding from the book.
- On the bar: corner badges and status that show how a slot links to binding documents.
- Profiles / per-character binding documents that persist across sessions.

## Behaviors

### Mental model
A binding is a document: action identity + conditions + keys + placement role (action bar, extra grids, utility slots, stance, etc.).

Conditions include ideas such as:

- Targets: self, target, mouseover, focus, pet, cursor, and related
- Hostility / dead-alive filters
- Forms / stealth
- Combat / inventory / other macro-style conditions
- Multi-cast extras and shared keys

Bindings are authored so form and combat flips do **not** require rebuilding the secure click mid-fight. On Midnight, this pairs with secret-value rules: do not recompile from forbidden combat reads—see [03-midnight-constraints.md](03-midnight-constraints.md).

### Chord routing (player-facing)
- Bare key on a Flux column → that column’s **main** (current page)
- **SHIFT-** / **CTRL-** → that column’s mini slots
- **ALT**, Shift+Ctrl, or unbound bases → **free chords** (override pool)

The physical key always “clicks” the main column; modifiers pick which slot content fires. Push-press visuals depress the correct bar button for binding-driven casts.

### Classic extras
- Season of Discovery **engraving/rune** awareness where that client exists
- Pet-book abilities as first-class bindable actions

## Options / customization

**Binding** tab in `/fluxui` — embedded browser/editor (full chrome: [26-options-map.md](26-options-map.md)):

- **Bindings source** — Live (current) / Respec profiles
- Filters: All · Unbound · Default · Customized · On bar / Stance / Extra / Multi-cast · Bar / EBS key only
- **Search...** · sort **ABC** / **Key** · **Show on keyboard**
- Preview saves to Respec only; Sticky across Respec survives Load/Apply
- Equipment slots / Pet category tabs
- Keyboard visualizer prefs (account): Loaded on · Empty off · Extra on · Mouse on · Source All/Binding/Bars/Extra · QWERTY · size 100 · `/fluxbind viz`
- Editor areas: Cast · Multi-cast · Conditions · Targets · Forms · Status · Bar & Badges
- Action Bars also has **Enter Binding Mode** for hover-press assignment

## Relationships

- Installs behavior onto [11-action-bars.md](11-action-bars.md) and [12-extra-button-system.md](12-extra-button-system.md)
- Shares binding mode UX with the action bar
- Key category names also appear in [05-defaults-and-bindings.md](05-defaults-and-bindings.md) (FluxUI keybind list vs deep conditional docs)
- Inspiration → Clicked + ClickedMedia in [90-reference-inspirations.md](90-reference-inspirations.md)

## Client availability

| Client | Availability |
|--------|--------------|
| Era | Full Classic condition set |
| Anniversary | Full |
| Classic | Full (+ runes on SoD-like flavors) |
| Midnight | Full authoring UI; apply/update policies respect combat and secret limits |

## Rewrite intent notes

Clicked’s lesson: **conditional casting is a document**, not a one-line macro the player retypes. Flux adds explicit bar/badge integration and chord routing into the 19-column + minirow layout. Media packs inform clarity of key visualization, not gameplay rules.

## Explicit non-goals

- A full WeakAuras replacement.
- Mid-combat secret-driven loadout switching on Midnight.
- Hiding Blizzard Key Bindings entirely—Flux complements it with deeper documents and still exposes FluxUI named hooks there.
