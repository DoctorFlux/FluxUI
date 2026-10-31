# Nameplate overlays and chrome

`Flux.NamePlates` adds threat/level/combo/countdown and casting-school presentation around existing Blizzard nameplates. It does not create a replacement nameplate suite. Current behavior is defined by [Core.lua](../NamePlates/Core.lua), [Threat.lua](../NamePlates/Threat.lua), [Level.lua](../NamePlates/Level.lua), [Countdown.lua](../NamePlates/Countdown.lua), [ComboPoints.lua](../NamePlates/ComboPoints.lua) and [CastBarSchools.lua](../NamePlates/CastBarSchools.lua).

## Lifecycle and ownership

Core tracks `activeUnits` from `NAME_PLATE_UNIT_ADDED/REMOVED`, reconciles existing plates on entering world and dispatches module `Added`, `Removed`, `Refresh` and periodic `Poll` methods. One hidden/visible driver runs only while plates are active. Group/combat changes refresh policies. Module errors route to the error handler without abandoning every module.

Flux text/border hosts parent to the nameplate itself, not UnitFrame/its children, and release to UIParent on removal. Preview unit tokens are excluded. Unit tokens, object access and displayed values are checked for secrets where applicable. Reuse/removal must clear retained per-unit state and tint.

`TintPlateChrome`/`ResetPlateChrome` recolor native borders, level indicators and selection regions. Level/countdown code fades native artwork/digits, client-specific Core code changes selected anchors/visibility, and cast-school styling adds a fill texture to the native casting bar. These side effects require native taint checks; see [findings](40-findings.md).

## Blizzard casting bar school themes

The shared [unit-frame school renderer](../UnitFrames/FluxCastBarThemes.lua)
now paints Blizzard's `CastBarsContainer.castBar` on Retail, Forever, Era and
Anniversary. Its noninteractive visual host follows the native bar; Blizzard
continues to own progress, text, shield, indicators, cast events and fading.
The **Blizzard nameplates** toggle under Unit frames → Cast bar school themes
defaults on. Secret or unresolved spell identity preserves Blizzard's fill.
Desktop lifecycle and renderer checks pass; native combat taint, pixel parity
and frame time remain pending. [Exact record](NAMEPLATE_CASTBAR_SCHOOLS.md).
The [fill/tip correction](CAST_SCHOOL_FILL_TIP_FIX.md) hides Blizzard's
underlying fill only during a readable school theme and tints its native
Spark to the school; both restore when the theme clears.
The [backdrop layer correction](NAMEPLATE_BACKDROP_LAYER.md) puts school
artwork at the plate level behind native cast and health chrome, while fill,
tip, halo and particle effects keep their existing hosts.
The [secret-channel fallback correction](SECRET_CHANNEL_FALLBACK.md) selects
the channel spell ID without boolean-testing it; an inaccessible or nonmagic
school keeps the default native appearance.

## Threat and level

Threat polls at 0.25s. Account settings in `FluxUI_DB.nameplateThreat` default to NPC border on, enemy-player-targeting-you on and group-only visibility. `always|group|never` controls whether the overlay participates. Enemy players targeting the player receive red chrome; NPCs consult `Flux.Threat` for eligibility, values/status, rank and colors. A short 0.6s grace avoids immediate visual clearing on transient missing threat. Native numeric-threat policy also gates text.

`IsThreatSupported()` currently checks for `C_NamePlate`; it does **not** categorically exclude Live. Effective results still depend on `Flux.Threat` returning eligible, displayable information. Forever uses its specialized frame/status display helpers. Consequently the old claim “Live countdown only” was too strong for current code; supporting a path statically is also not proof that live combat APIs provide numeric data.

Level polls at 0.25s. `IsLevelSupported()` excludes Live and permits other clients with nameplates, including Forever. The “Lvl. N”/skull overlay is omitted for simplified, minion, minus and name-only plates and when using Classic health-bar artwork that keeps native level presentation. Difficulty color uses native content-difficulty helpers where possible. Restricted levels can pass to formatted display instead of numeric comparisons. The setting defaults enabled.

Core additionally fades Forever native level art, extends supported health geometry and repositions CC/loss-of-control icons. Forever health readouts move inside the bar with style-dependent center/right alignment. Live hides native level frames without extending the bar. These update paths skip Settings-open/preview contexts. They are more invasive than an additive text host and require live taint checks.

## Countdown and target combo resources

Countdown polls at 0.1s. Flux-owned text hosts overlay native aura cooldowns at a fixed `16 * 0.75 = 12px`. Native digits are faded with text-color alpha only after a Flux label is available; Flux does not set their font/scale or replace aura mixins. It reuses native labels, including secret strings supported by SetText, or computes time only when values are readable and duration is at most 60 seconds. Computed labels use whole seconds above ten and tenths below. Missing labels restore native digits. Size is a code constant, not a live options slider.

Combo points load only for the TOC-listed Vanilla/TBC/classic/camelot game types. The current-target-only row uses Flux-owned client artwork and shared Forever rendering where supported, without requiring the Flux player/target frame enabled. It follows target, point/form and plate reuse/removal events. Other plates receive no combo row; eligibility keeps zero-point sockets for supported rogue/Cat forms.

## Configuration and validation

`FluxNamePlates_RefreshFromDB` and `FluxNamePlateThreat_RefreshFromDB` apply option changes. Numeric percentage shares game `threatShowNumeric` with unit frames. Nameplate CVar defaults are a separate explicit [defaults feature](05-defaults-and-bindings.md), not something every overlay refresh should be assumed to rewrite.

Verify each supported style/client, secret numeric text, group policy, player target detection, threat clearing/reuse, native border restoration, minion omissions, zero/transfer combo points, countdown recovery and Settings previews. Current comments, old docs and capability gates disagree in places; observed behavior belongs in [verification](41-verification.md), not inferred “full support” claims.

## Countdown work reduction

PERF-009 `efca305` passes the current poll's discovered native text region to label/
alpha handling and reads the same three frame levels without a temporary table.
No region/level is cached between polls. Five matched desktop pairs halve discovery
calls and remove measured temporary allocations with the same text/anchor writes,
font, levels and 0.1s timing. 1,160 checks include 100 plate lifecycle cycles.
Native Retail real-widget geometry/alpha/reuse checks pass with zero recorded errors;
actual protected aura rendering/combat/secret values remain pending. [Evidence](NAMEPLATE_COUNTDOWN_WORK.md).
