# Shared border canvases

Type 1 uses `Battlefield100.tga`: the eight original BattlefieldMinimap RGBA cells
are unchanged; only gutter samples are extruded for filtering. All clients use the
same controlled coordinates for the original pieces and cropped join fragments.
This avoids native-atlas UV/metadata ambiguity observed as corrupt type-1 fragments.

Type 2 uses `ForeverMetal150.tga` / `ForeverMetal150Tint.tga`, normalized from the
actual WoW Forever 1.60.1.70938 options-window artwork read offline from the user's
installed wowf CASC data. The native bevel is fixed at 150% of type 1's 100% weight.
Canvas coordinates, outward padding and consumer anchors remain fixed. Neutral
RGB retains identical alpha for accents. Global no tint uses the natural gold
sheet; explicit PC unit-class chrome uses neutral material in every accent mode.
Forever NPC target/focus chrome follows the UI accent; other-client NPC families
retain natural artwork. Blizzard Entertainment retains all rights to the original
artwork; the addon's code license does not relicense these assets.

The source is the `c60-2x` family, not the older gray `UIFrameMetal` texture:

| Source FileDataID | Used artwork | Source BLP SHA-256 |
|---|---|---|
| 8069116 | Bottom-left/right corner bevels | `acb0f4d211caa359bf7df3e09ea94da2f96c1c2300bb42226a3786b74465da7f` |
| 8069118 | Bottom edge bevel | `0eeeb8ac629f7980017d6ebd93bf75ef8f284cd76c14513854577f9bea9f111b` |
| 8069114 | Left/right edge bevels | `fa16cf9079e267a54f28a39b573e7d8dd4dbb9d2ee8e07c80aba252cbcade22c` |

`Preview1`, `Preview2` and `Preview2Tint` show complete rectangles in the dropdown
and enlarged tooltip. The current source-profile renderer samples the registered
edge textures directly for T/X joins, with disjoint branch triangles retaining
each branch's exact UVs, color and natural/neutral material. No separate junction
texture is loaded at runtime.

Historical `JunctionWide1`, `JunctionWide2` and `JunctionWide2Tint` contain
20 orientations each: five T/X shapes, two horizontal and two vertical profiles.
Their 32x32 windows retain the complete bevel/shadow in a 512x256 atlas with wide
sampling gutters. Fresh filenames avoid stale native caches from the earlier
16-pixel experiment. These remain build/reference assets for the superseded r1/r2
renderer; they do not establish visual acceptance of the current implementation.

There is no thickness setting, runtime image generation or idle ticker. Earlier
thickness/junction assets remain historical and are not used by the current style
metadata. Additional styles provide a normalized canvas, fixed weight, measured
tracks and preview through the shared metadata; their source art feeds the joins.

Build with [tools/build_border_art.py](../../tools/build_border_art.py). Raster
checks verify original-cell parity, outer padding, cap/edge filtering guards,
natural/neutral alpha and junction profiles. Native GPU, fractional UI-scale,
controller, taint and FPS acceptance of the latest implementation remain pending.
[Requirements](../../docs/CONNECTED_BORDERS.md) and
[exact source/checkpoint/validation evidence](../../docs/validation/border-connections-2026-11-15.json).

R56 uses measured zero-alpha support for the canonical 150% edge cells, including
their half-texel filtering fringe. Original pixels and canvases are unchanged.
The private source profile requires the authored current native handle and exact
canonical UVs; different material/UVs retain the full source footprint. T/X fields
meet at actual per-owner support intersections, with the horizontal aura/strip
crest and curved caps preserved. Added artwork must carry a measured support
contract before transparent padding can be trimmed. See
[shadow proof and limits](../../docs/validation/junction-shadows-2026-11-16.json).
