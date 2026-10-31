# Blizzard nameplate cast bar school themes (31 October 2026)

The existing target/focus school renderer now also paints Blizzard's own
nameplate `CastBarsContainer.castBar` on Retail, Forever, Era and Anniversary.
The native status bar still owns progress, spell text, shield, interrupt state,
important-cast indicators and cast events. Flux adds a noninteractive visual
host and a fill texture anchored to the native fill, using the same palettes,
gradient, halo, leading edge, backdrop and particles as unit-frame cast bars.
No replacement nameplate casting bar or spell-ID list was added.

The initial published pass had a [fill-parent and tip-color defect](CAST_SCHOOL_FILL_TIP_FIX.md).
The follow-up restores the shared unit-frame fill and makes the school color
visible on nameplates; its native visual checks remain pending.

The **Unit frames → Cast bar school themes → Blizzard nameplates** toggle
defaults on in both settings scopes. The shared master and appearance controls
apply to it. Existing saved choices are retained. On Retail/Forever, a secret
spell identity cannot select a school in addon Lua; the theme clears and
Blizzard's own cast bar remains visible. Readable spell identity can use the
existing observed combat-log school or spell-metadata inference. Inference is
a visual estimate and never changes interrupt behavior. The direct combat-log
path remains disabled on restricted clients. Physical, profession and
unidentified casts retain Blizzard's appearance.

## Source and checkpoint

Before edits, main was clean at `026164ab087c47e08ca4531800a023ae11c97ed3`.
No WoW process was visible. Four on-disk `Config.wtf` files were inspected and
copied, along with a verified complete Git history bundle, to the dated
checkpoint outside AddOns at
`C:\Users\mario\.codex\visualizations\2026\10\31\01a191a3-4b2a-7811-bb0f-2b94742680d8\FluxUI-castschool-20261031`.
The bundle SHA-256 is
`d91ebfc64c6d85b5e380b448b5de9706e257217e826c87a7c479b29bac642f42`.

Read-only Gethe `Blizzard_NamePlateCastingBar.lua` snapshot SHA-256 identities:

| Source tree | Version | SHA-256 |
| --- | --- | --- |
| `wow-ui-source-live` | 12.1.0.69283 | `8ae3e4b1766f1855d4300793723eee5c0925752aa3c6e87dbc4dabc27363d263` |
| `wow-ui-source-forever` | 1.60.1.70425 | `71b271438629b826d00a85d1ec12bbdc411994113d0fb6c77af5828080395d5f` |
| `wow-ui-source-classic_era` | 1.15.9.68808 | `8ae3e4b1766f1855d4300793723eee5c0925752aa3c6e87dbc4dabc27363d263` |
| `wow-ui-source-classic_anniversary` | 2.5.6.68775 | `823d816c5fdd40fcebe471343ac2c79b792de060e5e11e252ad7e1e47e3e74db` |

The [Gethe nameplate mixin](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_NamePlates/Blizzard_NamePlateCastingBar.lua)
inherits `CastingBarMixin`; its [XML](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_NamePlates/Blizzard_NamePlateCastingBar.xml)
defines the native status bar and text/shield regions. The
[Blizzard casting mixin](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_UIPanels_Game/Shared/CastingBarFrame.lua)
owns cast start/finish and can receive restricted identities in 12.x. The
user-supplied 12.0.0 through 12.1.0 API change pages informed the secret-value
guard. No external source was copied into Flux.

Candidate SHA-256 identities: `UnitFrames/FluxCastBarThemes.lua`
`3bcfeb2c991b2b92ff6d9623c0399e472b2dd68ad24ad30e3d0386d21d82a093`;
`NamePlates/CastBarSchools.lua`
`2ee9e2190f5ac49fed14bdcf33f05aa1c11456c7a6631e5c5c5a613b44401411`.
The complete desktop report includes normalized hashes for all 755 Lua files.

## Verification and remaining native work

`lua tests/nameplate_castbar_schools.lua`: 48 lifecycle checks across four
client models. `lua tests/castbar_school_themes.lua`: 13,854 school, appearance,
secret and shared-renderer checks across five modeled families. Combined
`tests/run_validation.py`: **110 pass, 0 fail, 755 Lua syntax files** in
`validation/nameplate-castbar-schools-2026-10-31.json`. These are desktop
checks; they establish no native taint, pixel parity or FPS result.

Sequentially test each client without taking foreground input: cast and channel
on target/focus and on enemy nameplates; test Fire/Frost/Arcane/Shadow/Holy/
Nature, hybrids, physical and professions; interrupt, finish/fade, hidden
plate, recycled plate and option toggle. In Retail and Forever combat, verify
both readable and secret spell identities, Blizzard text/shield/important-cast
visibility, `SetUnit` taint and errors. Compare native pixels to the unit-frame
theme at the same scale. Capture matched baseline/candidate profiler samples
before claiming performance parity. All native checks are pending because no
WoW process/window was visible during this edit.
