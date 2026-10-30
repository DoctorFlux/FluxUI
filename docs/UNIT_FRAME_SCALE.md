# Whole unit-frame scale — 30 October 2026

Unit Frames → Player has **Player + target scale (%)**; Unit Frames → Focus has
**Focus scale (%)**. Both range from 50% to 200%, default to 100%, and use the
existing account or character unit-frame scope. Width and height controls keep
their saved dimensions. The sliders apply immediately outside combat and use
the existing deferred layout pass when changed during combat.

The root scale carries portraits, bars, text, cast bars, auras and child icons.
Target-of-target follows target once, whether parented to target in side-by-side
placement or to UIParent in stacked placement. Focus-target follows focus.
UIParent-hosted separators, atlas borders and the empty target outline receive
the matching effective scale. Player and side-by-side target bottom anchors
convert the action-strip top into frame-local units at both smaller and larger
scales, with four UI units of border clearance; 100% keeps its prior anchor.
The player/target portrait offset is applied once in local units. Focus aligns
its aura/portrait group to chat after converting both frames' effective scales.
Changing scale refreshes the 3D portrait model and camera once; an unchanged
scale does not reload the model. Player and target apply the corrected anchor
when first created, before any later options refresh.
Blizzard-owned class-resource containers above player follow
player's whole-frame scale as well as the existing class-power size control.
The target-side micro-menu cap uses scaled target width and portrait offset.
Blizzard-owned unit frames are outside these controls.

Baseline: local main `021b524893229fece34eff503a8ac1cf66388363`.
Candidate source SHA-256: defaults
`7cee56229f4dedaf0ef331134b38539332d3fcfa7f7f77f8c7d58e083e948f74`;
options `6c4da9ebdf754981f78f2e594ce61a9bf4be7b9ed3d7b6386668dab7b79d6277`;
class power `754d04e54dce37078a44ff8e4b9a9fa4927de7006a2bea7a045b6c2b5b92e4`;
options bridge `54f4b04cb4a4525b1ca7e94f769a2a0e7d99288a8dfcbdef17ea6f20e3615bef`;
focus `25c895e6cf8f9c36f75c7d2fe94f31f1d58ddf5d6a45f5ebaff8bdead71de718`;
player `7c0ebd163d6d7f57a2ee00335a79b3a69d4ae73e8f355d388489440561dc428d`;
target `1cad536d5c653562f22ed6fa9e1e7d314e38aac5ad52a5d25bc73e4f5d9acc28`;
shared frames `2a5d69431897e94f7422fbe1505e7d593ae45dd136919fc931a5afde17435187`;
ToT `ec13317192ed24762b60912df92582456de5a7ed0067de84186762b26ad4d91e`.
Before editing, a verified external source ZIP (1,303 files, SHA-256
`b41dbf432554f2d11af42c1fcab7d4b450900290a01854a4bd8666194a2a6be9`)
and complete Git bundle were saved in the current visualization workspace.
Retail on-disk `WTF/Config.wtf` was present; its contents and the running game
were untouched. Existing vehicle-seat work was preserved.

The focused production-bridge test passes 23 checks covering scale bounds,
dependent frames, detached borders/separators, strip clearance at 50% and 135%,
portrait and focus positioning, camera refresh and both ToT parent layouts.
The full 99-script/740-Lua desktop report is
[unit-frame scale validation](validation/unit-frame-whole-scale-2026-10-30.json).
Native size, attached-element alignment, click areas, combat/taint, focus
availability, class resources and pixels remain pending on each supported
client. Desktop frame doubles do not certify those behaviors or FPS.

Follow-up checkpoint before the 3D portrait/strip correction: external source
ZIP with 1,307 files, SHA-256
`08039b6adc152b6ea7f11e07c0fec1d457b284d27518a8434a667afbeaabedb1`,
and a verified complete Git bundle. On-disk Retail settings were present but
not modified. Concurrent vehicle/durability and status-bar work was preserved.

## Attached stance-bar scale — 30 October 2026

Failure: reducing the player frame left its attached stance bar at full size.
The stance root is parented to UIParent, and its border anchor carries position
without inheriting player scale. It now matches the player's effective scale
relative to its own parent when placed at the player frame. Buttons, borders,
text, effects and click surfaces inherit that root scale once. Detaching or
using a non-Flux player frame restores the stance root to its original scale.
Scale is synchronized before detached pet-height measurements and at anchor
refresh. The unit-frame size pass refreshes the stance anchor after a player
scale change without requesting a button/binding rebuild. Existing combat
deferral applies; unchanged scale avoids SetScale and extra anchor requests.
No new settings, hooks, timers, frames or polling were added.

Baseline: `57a252e0e2b467cf7788c3f52aa5d1dd8d83779e`. The
[raw comparison](validation/stance-player-scale-comparison-2026-10-30.json)
records exact normalized source hashes and the old failure. The new
[stance fixture](../tests/stance_player_scale.lua) passes 21 checks; the
[options bridge fixture](../tests/unit_frame_whole_scale.lua) passes 28.
The [full desktop suite](validation/stance-player-scale-2026-10-30.json) passes
108 scripts and 752 Lua syntax checks. The old source fails the reduced-scale
assertion. Existing bar contract/startup regressions also pass.

Before editing, verified external checkpoint `Stance-scale-20261030T191108Z`
preserved 1,364 source files, complete Git history and 109 on-disk settings
files. Source ZIP SHA256:
`25635059be74307afb1b9aae1392c785b79cbab889b9975545c923cdc95f4d54`.
No WoW process was visible to the workspace. Native client builds, hardware,
addon/settings snapshot, screenshots, timing and CPU/allocation samples for
this change are unavailable; native performance and parity are inconclusive.
Desktop mocks do not establish native pixels, hit areas, FPS or taint safety.

Native regression steps for each supported client: reload outside combat;
place stance beside the Flux player frame and compare 100%, 50%, 75%, 135%
and 200% player/target scale with the same profile, UI scale and resolution.
Check forms/extras, borders, text, click surfaces and bindings; reload at 50%
and confirm retained size. Switch to the detached stance placement and verify
its original size, including status/pet stacking; switch back and confirm
attached size. Disable the Flux player frame and verify fallback placement.
During combat, change the scale and verify protected geometry waits until
combat ends, then recheck input and taint. Capture matched before/after images
and repeated layout-operation timings if performance acceptance is needed.
