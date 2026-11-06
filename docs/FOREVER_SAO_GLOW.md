# Forever SpellActivationOverlay button glow — 6 November 2026

**FOREVER-SAO-GLOW-01:** When the installed SpellActivationOverlay activates a
spell, its glow must appear on matching Flux action bar, Extra Button and badge
faces. It must clear on deactivation or a changed face, transfer with paging,
and keep the existing animation cadence. Era and Anniversary behavior stays on
their existing renderer.

The installed Forever companion is SpellActivationOverlay 2.8.9 (TOC interface
16001). Its `components/glow.lua` keeps `GlowingSpells` private, calls
`AddGlowNumber`/`RemoveGlow`, and paints its buttons with LibButtonGlow. The
saved `SpellActivationOverlayDB.glow.enabled` is `true` (read only). Flux already
captures the private namespace and distributes membership through `Glow.Want`.
Its paint path tried a native alert template first and could accept a shown
frame without a visible SAO glow. That render result did not match Forever's
installed companion. The correction uses the companion's LibButtonGlow renderer
for Flux faces on Forever, with the existing template/LCG fallback if the library
is unavailable. It moves the LBG owner flag with a transferred overlay and lets
LBG release its own pooled frame on hide. `skipBirth` finishes its intro when a
spell was already active. No SAO globals, protected attributes, settings or
companion files are changed; the established events and refresh cadence remain.

Source identities (SHA-256): installed `SpellActivationOverlay.toc`
`c564aab5f5cfcbc1d37768ef06a392f59bc7666296e9d73e7abfd12bbf54a366`;
installed `components/glow.lua`
`f2fd1e234fdaefe996ba846716fb8fd4a2fcd7ed7fc29680ee5a303227709671`;
installed `libs/LibButtonGlow-1.0/LibButtonGlow-1.0.lua`
`7c34efbb281b95e83d043b16cf17752d315a053d4eda5c777c51e1079d0986e9`.
Main baseline is `a07c449b1783a7bc876943e5909c3573cfec267a`; the dated
external `FluxUI-forever-sao-20261106` checkpoint holds the pre-edit Glow.lua
(SHA-256 `6062c9b9310b2980eb2c0a98e6daef6fe8d2d2a4e2a49cc98c16ea4a01dbdb2c`)
and a verified all-ref history bundle
(SHA-256 `f8ce33384b6f1e982a2a6aa2d303ad7224a5dae8e1a5c4fe9687996b662d5e9d`).
The previously recorded [Forever UI source checkpoint](https://github.com/Gethe/wow-ui-source/commit/eac30af597e5aaa43a60f6675ef5fdcea100375f)
is retained; the installed SAO files above are the integration contract here.

`lua tests/forever_sao_glow.lua` passes 25 checks for private SAO membership,
bar/Extra/badge LBG paint, fade reversal, skipBirth and transfer/hide ownership.
The same fixture fails on the saved pre-edit source at the bar-render assertion.
`lua Bars/_tmp_barsmoke.lua` passes 17,454 refresh checks and its existing
contract/owner checks. Earlier SAO-stage validation: 819 Lua syntax files pass;
160/162 scripts pass. The two failures are `Core/_tmp_coresmoke.lua` meter
centering/gamepad anchor assertions and `tests/native_meter_skin.lua` title/menu
assertions in unrelated in-progress meter work. Neither script loads Glow.lua.
The subsequent combined [meter/native-boundary run](validation/meter-timer-native-boundary-2026-11-06.json)
passes all 162 scripts /819 syntax files with unchanged source hashes.
These desktop fixtures establish code paths, not actual
pixel output or client security. Native checks remain pending: reload Forever
with SAO enabled, trigger a real proc on each face type, compare SAO art on a
stock button, test paging and macro/icon changes, then verify clearing, taint
and frame time. Test Era and Anniversary separately for regression. Leave WoW
in the background and keep the saved profiler and diagnostic roots intact.
