# Nameplate cast-school backdrop layer — 31 October 2026

The user reported that the school backdrop on Blizzard nameplate cast bars
sat too far forward. The school fill, moving tip and unit-frame themes remain
separate from this placement correction.

## Cause and correction

The nameplate visual proxy sits one frame level above Blizzard's cast bar.
Its `BACKGROUND` textures still rendered above the native bar because frame
level takes precedence over a texture's draw layer. The artwork can extend
above the cast bar into the health-bar area.

Nameplate backdrop textures now live on a noninteractive Flux host parented
to the plate at the plate's own frame level. This places the artwork behind
Blizzard's cast/health chrome while leaving the school fill on Blizzard's
status bar and the halo, edge glow and particles on their existing host.
Hybrid backdrop layers share the lower host. Its parent and level follow
plate changes during a cast. Unit-frame artwork keeps its existing parent,
colors, size, opacity and timing. No saved setting changed.

## Source and validation

Baseline main at inspection: `0c197f517c8d0f1cd0f66bdf0152b7a0431a6138`.
Baseline `UnitFrames/FluxCastBarThemes.lua` SHA-256:
`f91dc4842aac20b142e4cd69148a93d92fa0ce96c823f42d541dc074b6745ce9`.
Candidate SHA-256:
`0125d891ccc24901bfe17d1bd6b06de05cf6e804966a3cddbfaaa289e4f87eda`.
The external verified source/history bundle and four closed-client Config.wtf
copies are at
`C:\Users\mario\.codex\visualizations\2026\10\31\01a191a3-4b2a-7811-bb0f-2b94742680d8\FluxUI-nameplate-backdrop-20261031`.
Bundle SHA-256:
`aa8f779d702d49f203f10f89e37afb999ef137efff4506fc98cff1088222b13a`.
Read-only Blizzard `Blizzard_NamePlates.xml` sets `castBar` frame level 100;
the nameplate health container uses the parent level. No external code was
copied.

The expanded `tests/castbar_school_themes.lua` verifies the backdrop host is
below Blizzard's bar, hybrid layers share it, it follows live plate-level
changes, hides artwork for a secret plate level, and keeps unit-frame backdrop
parenting unchanged. The current test
fails on the baseline source at “nameplate backdrop stays below plate chrome”
and passes with the candidate (13,898 checks). Combined desktop validation:
**112 tests / 757 Lua syntax files / zero failures**, recorded in
`validation/nameplate-backdrop-layer-2026-10-31.json`.

Native visual, combat taint and frame-time checks remain pending because no
WoW process/window was visible. Sequentially test readable single and hybrid
casts on Retail, Forever, Era and Anniversary plates. Confirm backdrop art
stays behind cast text, shield, health text and selection chrome across
target switching, plate reuse, different plate sizes and option toggles.
Retail/Forever secret identity should retain native appearance. Capture
matched native timing before making any performance claim.
