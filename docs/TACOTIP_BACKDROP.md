# TacoTip secret backdrop geometry

The user reported two errors at22:42:30 in Blizzard_SharedXML/Backdrop.lua:
SetupTextureCoordinates performs arithmetic on a secret width, with execution
tainted by TacoTip. The three-frame stack does not identify the actual frame
or prove a FluxUI origin. The reported client/build was not specified.

The installed Forever TacoTip0.9.4 (AcidBomb, MIT; libraries separately licensed)
contains a source-matched path: main.lua getOrCreateBackdropFrame creates a
BackdropTemplate child for NineSlice-equipped tooltips and anchors it to the
tooltip. applyTooltipBackdrop applies edgeFile/edgeSize. The native size callback
then reads the inherited dimensions and computes repeated texture coordinates.
A secret-sized tooltip can therefore reach this arithmetic after initial setup.

FluxUI's HUD tooltip module changes anchors; its TacoTip compatibility suppresses
duplicate PaperDoll labels and reads GearScore. Neither implements this border.
No runtime changes to either addon were made during the investigation.

Any future fix belongs to TacoTip's owned renderer. Preserve border assets, size,
colors, opacity and options using a geometry-safe native/declarative layout.
Do not replace shared Blizzard Backdrop functions, coerce secret dimensions,
suppress the reporter or silently disable borders. Guarding only SetBackdrop
leaves later OnSizeChanged calls exposed. Native tiling/art and hover/combat
checks are required before claiming visual or secure-VM acceptance.

The user explicitly chose to keep TacoTip read-only. No TacoTip modifications
are planned, and no scope question remains pending. TacoTip is outside the
FluxUI repository; CONTRIBUTING.md also keeps external references read-only.
Era/Anniversary have a different0.5.1 implementation; Retail/Classic copies were
absent. This investigation does not certify a universal TacoTip fix or attribute
the earlier random freezes.

[Exact hashes and scope](validation/tacotip-backdrop-audit-2026-11-06.json).
[Blizzard backdrop source](https://github.com/Gethe/wow-ui-source/blob/eac30af597e5aaa43a60f6675ef5fdcea100375f/Interface/AddOns/Blizzard_SharedXML/Backdrop.lua).

A private bounded desktop reproduction loads the actual installed factory and
pinned native backdrop functions. Public dimensions and child reuse pass;
arithmetic-rejecting modeled secret width fails both at initial setup and after
a successful public setup/resize. Errors propagate unsuppressed. This establishes
the source path, not native taint/secret-VM or pixel acceptance. Exact hashes and
case results are in the linked audit; source/license/raw output remain external.
