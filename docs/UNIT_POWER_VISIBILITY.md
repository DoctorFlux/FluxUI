# Unit-frame power visibility — 30 October 2026

## Behavior

Flux player, target, target-of-target, focus and pet frames hide their main
resource bar when the displayed unit has a known maximum power of zero. Their
health bar then fills the available inner height, and the health/power separator
hides. A current value of zero with a positive maximum keeps the normal split.
Focus-target and pet-target were already health-only. Flux raid cells use the
same maximum-power rule and expand health into the power strip. The existing
raid option to hide all power bars still takes precedence. Blizzard-owned unit
and compact raid frames retain their own behavior when selected in options.

The maximum is obtained from `UnitPowerMax` for the active `UnitPowerType`.
Only a nonsecret numeric result is compared. On Live/Forever, health occupies
the full inner height behind the power bar. The power bar and separator accept
`UnitPowerMax` through `SetAlpha`, an allowed secret-value sink: zero makes the
resource layer transparent and a positive maximum keeps it visible. Its fixed
frame anchor preserves the usual power position; health text and the raid icon
use separate anchors. Health text centers across the full bar for a known zero
maximum; positive and restricted maxima keep it in the health section. The raid
icon retains its upper-area anchor. Player/target HP labels use their original
horizontal positions at the vertical middle when the maximum is known zero;
regaining a resource restores their nested corner positions. ToT's separator
container follows its frame level when the side-by-side layout raises ToT above
the target. The power text inherits
the resource layer's alpha, so it vanishes with a zero maximum. The Flux
health/power separator starts transparent and receives the same maximum-power
alpha after partition and border-color repaints, including ToT refreshes. The
restricted maximum is passed directly to `SetAlpha` without testing its truth
value in Lua. A failed or missing maximum keeps the resource
layer visible. The ordinary `UNIT_MAXPOWER`, `UNIT_DISPLAYPOWER`, target and
world-entry refresh paths restore the bar when a unit gains capacity. Flux raid
cells now register `UNIT_MAXPOWER` as well. Raid cell reanchoring is deferred
until `PLAYER_REGEN_ENABLED` when combat is active; power visibility changes
immediately where the existing region path permits them.

## Source and verification

- Baseline: local main `058efb8192b537d73e7e1e7f1a7e6afe2fbde575`.
- Candidate source SHA-256: shared unit frames
  `a77ca73b2ebd70a9ec3892791b486e18906d757097e2d9df487e974f9127da99`;
  target-of-target `2c39e6cbaaa3910da49cec84b40d347e2a87100a387a03203dddc9d4d732b116`;
  raid unit `6ce37a98ef63d1f1a5a47709e21a519e50e2c198724265bb624689ff50386150`;
  raid visuals `76623e13293080e5173c036e304b0cb4833a553b2a4ef322cc468802f6b078aa`.
- External reference: [Gethe WoW UI source](https://github.com/Gethe/wow-ui-source),
  `live` branch as inspected on 30 October 2026; its
  [Personal Resource Display](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_PersonalResourceDisplay/Blizzard_PersonalResourceDisplay.lua)
  uses `UNIT_MAXPOWER` and `UNIT_DISPLAYPOWER` and obtains max power with
  `UnitPowerMax`. Both local Live and Forever generated API documentation mark
  `UnitPowerMax` as conditionally secret and `SimpleRegionAPI.SetAlpha` as
  `AllowedWhenTainted`; `SetVertexColor` also writes the alpha aspect, so the
  separator alpha is reapplied after chrome updates. `SetHeight` accepts secret arguments only from untainted
  code. The local extracted client trees in `CLIENT_MATRIX.csv` remain
  versioned separately and are older than installed executables. No external
  code or assets were copied.
- Pre-edit external checkpoint: `Main-only-recovery-20261029T191346Z`
  contains verified source and history bundles and 404 on-disk settings files.
  Its recorded HEAD predates this change. Retail `WTF/Config.wtf` was present
  on disk before edits. No settings, game state or profiler preferences changed.
- Focused `tests/unit_power_visibility.lua` passes zero-max, zero-current,
  regained power, secret-max alpha forwarding, full-height layering, text-anchor
  transitions, target HP refresh and label placement, separator repaint and ToT
  power/text transitions,
  combat and raid-option models. Full
  [desktop report](validation/unit-power-visibility-2026-10-30.json):
  96 scripts and 737 Lua syntax files pass. These checks do not establish native
  secret handling, secure-combat geometry or pixel parity.

## Native follow-up

For each supported client in `CLIENT_MATRIX.csv`, inspect the actual loaded
build and a Flux-owned unit and raid frame with a power-free NPC/pet, a
zero-current resource, and a unit whose maximum changes. Compare health bounds,
separator, power text, portrait, overlays and click behavior in and out of
combat. Repeat with the raid power-bar option disabled and with Blizzard frame
ownership selected. Record real restricted values and blocked-action/taint
output where available. Native checks are pending because WoW was left in the
background.
