These are Blizzard's Retail HUD bar fills, exported as standalone textures for
Flux unit frames on Forever. Forever changes the artwork and sheet positions
behind the same atlas names. Live continues to use its native atlases.

Source: Blizzard Retail 12.1.0.69299, `Interface/HUD/UIUnitFrame2x.blp`,
FileDataID 4642466. Artwork belongs to Blizzard Entertainment.

The source sheet and matching atlas rectangles can be retrieved from:

- https://wago.tools/api/casc/4642466?version=12.1.0.69299
- https://wago.tools/db2/UiTextureAtlasMember/csv?build=12.1.0.69299

Regenerate with `python docs/tools/export_retail_unit_bars.py UIUnitFrame2x.blp`.
The exporter verifies the sheet hash, isolates each named fill, and resamples it
to power-of-two TGA dimensions with alpha preserved. Every output is a complete
bar texture: no runtime sheet cropping, custom Texture objects on status bars, or native
Blizzard frame modifications are involved.
