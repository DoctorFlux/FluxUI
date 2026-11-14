# Profession cast-bar themes

Change: `TRADESKILL-CAST-THEMES-20261110`, 10 November 2026.

Tradeskill casts previously bypassed the spell-school renderer and retained the
ordinary fill. They now use the animated artwork from Blizzard's profession
level bar when the installed client supplies it. This intentionally changes
profession cast appearance; spell-school inference and combat-log data remain
separate. Existing direct implementation and user reproduction choices apply.

| Requirement | Result and acceptance |
|---|---|
| TCAST-01: native profession theme | Same `Skillbar_Fill_Flipbook_<kit>` and optional `Skillbar_Flare_<kit>` as the native level bar; all 13 profession enum entries modeled on Retail/Forever. Actual installed art/pixels pending. |
| TCAST-02: correct profession | Readable cast recipe ID through `C_TradeSkillUI.GetProfessionInfoByRecipeID`, then inverse `Enum.Profession`, matching Blizzard's kit selection. No current-window guess, recipe scan, English-name matching or bundled spell IDs. |
| TCAST-03: lifecycle and layout | Player/target/focus/pet and shared nameplate hosts; casts/channels; completion hold/fade; hide/interruption; following magic cast; source replacement and exact alpha restoration covered. Native timing, pixels and taint pending. |
| TCAST-04: controls and fallback | Existing master, unit/nameplate, colors, edge and glow controls. Missing specific fill uses Blizzard's DefaultBlue; missing flare retains normal Spark. Unknown/secret identity or profession, malformed atlas, absent art or unsupported graphics keeps ordinary appearance. |
| TCAST-05: ownership and work | Two regular textures, one native mask and one native FlipBook animation per capable bar; no extra frame. Native engine animates; no new OnUpdate/ticker/timer/event/hook. Hide/reset stops animation. Unsupported graphics stay dormant after one attempt. |

Implementation: [profession artwork](../UnitFrames/FluxCastBarTradeskills.lua),
[shared cast lifecycle](../UnitFrames/FluxCastBarThemes.lua),
[load order](../_FluxUI.toc) and
[regressions](../tests/castbar_school_themes.lua).
Pre-existing cast timing and all unrelated working-tree changes are retained.

The full-width animated texture belongs directly to TimerBar at ARTWORK
sublevel 7, matching the working school fill. An opaque rectangular mask follows
the native progress texture using black-outside wrap modes; no Lua reads progress
width or restricted timing. Flare uses OVERLAY sublevel 0, above the animated fill
and below native nameplate text/shields at sublevel 1. The native level-bar
animation contract is 34px per row, two columns and a two-second cycle; rows come
from actual atlas height. Both fill and glow remain through the cast owner's
completion hold/fade. No second fade timer is introduced.

The existing colors switch controls the profession fill; edge/glow controls
control the optional flare. School-only gradient, particles and backdrop controls
continue to govern magic themes. No new control or visible string is needed, and
no settings identity, default, saved root, profile or binding changes.

All added regions are decorative textures and a mask; no input frame is added.
There are no new controller focus stops, activation handlers or prompts. Existing
input/navigation paths remain the owners. Actual native controller/input checks
are NOT RUN; desktop frame/layer assertions are not pixel or taint certification.

## Source evidence and recovery

Fresh Gethe heads resolved once for this task:

| Client | Commit | Source version | Rank-bar owner |
|---|---|---|---|
| Retail | `297d7aaaa736f346b3e036f38ee088eaf7f8c07f` | 12.1.5.70783 | [Blizzard_Professions](https://github.com/Gethe/wow-ui-source/blob/297d7aaaa736f346b3e036f38ee088eaf7f8c07f/Interface/AddOns/Blizzard_Professions/Blizzard_ProfessionsRankBar.lua) |
| Forever | `4cd0ab752a77164f654ccbca9d0c1fe8dafceebe` | 1.60.1.70888 | [Blizzard_ProfessionsTemplates](https://github.com/Gethe/wow-ui-source/blob/4cd0ab752a77164f654ccbca9d0c1fe8dafceebe/Interface/AddOns/Blizzard_ProfessionsTemplates/Blizzard_ProfessionsRankBar.lua) |

Fourteen exact source Git blobs verify against these pinned trees, including
rank-bar XML/TOCs, kit selection, profession API/types and FlipBook setters.
Source presence and asset naming do not prove installed-client availability or
addon operation; the implementation probes the relevant art/API and falls back.
The packaged skill query used older Forever evidence only as a routing lead;
implementation contracts use the fresh pins above. No Blizzard artwork is copied
or distributed; the client supplies it. Third-party assets/licenses are unchanged.

External checkpoint `tradeskill-casts-20261110T194353Z` preserves all 2,574
pre-edit files and verified Git history at `26f886e3ea5371b196ab235d2dace0c156002285`.
Its absolute location is in the evidence JSON. Four available Retail settings
files were hashed read-only; no private settings were copied. Existing checkpoints,
diagnostic roots, preferences and background clients remain untouched.

## Validation and remaining native acceptance

The focused production-code fixture checks profession identity, every enum kit,
native animation parameters, progress clipping/layers, unit toggles, source/Spark
restoration, unsupported-client fallback, secret fields and lifecycle cleanup.
Twenty repeated refreshes reuse each successful cast's metadata and animation;
no Lua animation driver is added. Exact old shared-renderer behavior and five
harmful variants fail these assertions. These are functional/work-count results,
not native FPS, CPU or memory measurements. Full results and source hashes:
[task evidence](validation/tradeskill-cast-themes-2026-11-10.json) and
[full suite](validation/tradeskill-cast-themes-full-2026-11-10.json).

Native acceptance is pending on Forever and Retail: reload out of combat; craft
with two professions, including Cooking or another secondary profession; verify
the fill matches each native level bar and the tip flare follows progress.
Check a normal spell afterward, cancel a craft, and test the existing theme/unit/
colors/edge/glow controls. Verify completion fade, readable text and chrome on
target/focus/nameplates where visible. Confirm Lua errors/taint, keyboard/controller
input and normal FPS in the same scenario. Clients without the native rank-bar
assets should retain their ordinary craft appearance. No client input/reload,
manual propagation, settings/profiler write or publication was performed here.

## Fill and visible glow correction

`TRADESKILL-CAST-FILL-FIX-20261110`, TCAST-06 through TCAST-08. The user's native
reproduction found no visible fill and an excessive end glow. Subsequent feedback
asks to retain the glow and resemble the profession bar's skill-up animation,
and reports the softened glow is no longer visible. The initial desktop tests
did not model the separate frame's native texture ordering/clipping; their pass
was not native visual acceptance. Exact native client/build/profession was not
captured, so the engine-level failure mechanism remains an inference.

The fill now paints directly on the StatusBar and uses a native progress mask.
The flare explicitly paints above the fill and remains below native text/shields.
Its final baseline intensity is 60%, scaled by the existing glow option, with a
slightly smaller 44x14 footprint instead of 53x16 at an 18px bar height. The early
30% / 32x10 attempt is superseded by the user's request for a visible glow.
The moving glow stays with the animated fill throughout the ordinary completion
hold/fade, preserving the skill-up look without a new timer or animation owner.

TCAST-06 requires direct native fill ownership and progress masking; TCAST-07
requires a visible softer glow above the fill; TCAST-08 requires the native
animated profession appearance and glow through completion. The final fixture
passes 455 profession checks and 14,397 combined school/cast checks. The exact
previous clipped implementation and seven harmful variants are rejected,
including missing masks, full-width masks, white mask edges, bright/oversized
flares, glow below the fill and early glow removal. Full 304 scripts /
977 syntax PASS; all current Lua fingerprints match the report. These are
placement/lifecycle assertions, not native pixel or secure-VM certification.

Six additional source blobs for CreateMaskTexture, AddMaskTexture and texture
wrap contracts verify against the same two pinned trees above. A new external
`tradeskill-fill-fix-20261110T195852Z` checkpoint preserves 2,578 files and full
history; four settings files were hashed read-only. Prior checkpoints remain.
No other Lua/XML/TOC bytes changed from that checkpoint. No saved-data, settings,
binding or controller/input changes; no client focus/input, manual sync or
publication. Native candidate art/taint/input/FPS remains NOT RUN. User retest:
reload OOC, craft with two professions, verify the visible native fill and softer
moving glow through completion, cancel a craft, then cast a normal magic spell.

[Follow-up evidence](validation/tradeskill-cast-fill-fix-2026-11-10.json) and
[final full suite](validation/tradeskill-cast-fill-fix-full-2026-11-10.json).
