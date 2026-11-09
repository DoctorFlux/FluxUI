# School cast fill and tip color correction — 31 October 2026

The user reported that school color was absent on nameplates and that the
unit-frame cast bar had no visible fill on all clients. The moving tip glow
also retained Blizzard's default color.

## Cause and correction

The first nameplate integration changed the shared renderer's fill creation
from `TimerBar:CreateTexture(...)` to an expression that selected the **outer
cast frame** for unit frames. That put the school fill on the wrong frame and
below the progress bar's chrome. For nameplates, the added school texture was
on Blizzard's status bar, but its original status-bar fill remained opaque and
could cover the school color. The native Spark stayed white.

The school fill now always belongs to `TimerBar` on unit frames and Blizzard
nameplates. While a theme is active, the renderer hides the native source
texture and paints the school fill at the same progress geometry; it restores
the original source alpha when the theme clears. The native Spark is tinted
to the theme's bright color, following the same rotating component color as
the Flux leading-edge glow for hybrid schools. Its prior vertex color is
restored on disable, interruption and hide. Blizzard still owns progress,
text, shield, indicators and cast lifecycle. No saved variable or option
default changed in this correction.

## Source and validation

Baseline main commit: `3ded6a17084cc10589cf2387e98c21aede26f5cd`.
Baseline `UnitFrames/FluxCastBarThemes.lua` SHA-256:
`3bcfeb2c991b2b92ff6d9623c0399e472b2dd68ad24ad30e3d0386d21d82a093`.
Candidate SHA-256:
`f91dc4842aac20b142e4cd69148a93d92fa0ce96c823f42d541dc074b6745ce9`.
The verified complete Git bundle and four closed-client `Config.wtf` copies
are outside AddOns at
`C:\Users\mario\.codex\visualizations\2026\10\31\01a191a3-4b2a-7811-bb0f-2b94742680d8\FluxUI-castfill-fix-20261031`.
Bundle SHA-256:
`2ea7d63370386dcd7000bf1729abd9a24532b88c2eb852ae141797f1e032d562`.

The expanded `tests/castbar_school_themes.lua` checks the actual fill parent,
source alpha and native Spark tint/restoration on unit and nameplate bars.
Run against the baseline source, it fails at “school fill shares the actual
unit-frame progress bar”; against the candidate it passes 13,873 checks.
The full desktop suite passes **110 scripts / 755 Lua syntax files / zero
failures** in `validation/cast-school-fill-tip-2026-10-31.json`.

Native acceptance remains pending. On each client, verify a readable Fire,
Frost and hybrid cast on target/focus and a Blizzard nameplate, including
cast start, progress, channel, completion, interrupt, option disable/re-enable
and plate reuse. Check that the tip color follows each school and that
Blizzard text, shield and important-cast markers remain visible. In Retail
and Forever combat, verify secret identity fallback and `SetUnit` taint.
Capture matched frame-time samples before any performance claim. No visible
WoW process/window was available for this correction; desktop checks do not
establish native pixels, taint safety or FPS.
