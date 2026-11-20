# Cast completion appearance

Current change `CAST-GREEN-FINISH-20261116` follows the user's 16 November
instruction: “for finished cast just make it a green”. It supersedes the earlier
muted-gold completion choice in `CAST-COMPLETION-20261116`; that dated validation
record remains historical evidence for its exact source.

| ID | Requirement | Implementation and acceptance |
|---|---|---|
| CFIN-01 | A plain green successful finish | All shared unit-frame successful casts use UI-StatusBar tinted `.12,.86,.15`. No striped full success atlas. Player, target, focus, pet and party share this path. |
| CFIN-02 | Preserve completion and timer behavior | Ordinary casts detach engine duration and finish full; channels finish empty. The existing .35-second success hold and .75-second fade remain. Name/icon stay with that fade; time clears and spark hides. |
| CFIN-03 | Complete school and profession casts consistently | Active school/profession art remains; success releases its effects, animation and captured alpha through the existing Reset owner. The green underlying success fill becomes visible. Appearance refresh cannot revive a finished theme identity. The following cast starts its active art normally. Native nameplate completion remains with its existing owner. |
| CFIN-04 | Restore protected-cast chrome | On success/failure/interruption, clear the completed cast's not-interruptible flag, restore normal unit/global chrome and hide its shield without changing the terminal fill. Success text returns to the normal inset. Custom timers cannot inherit the previous protected cast's warning. Active protected casts retain their red/shield cue. |
| CFIN-05 | Preserve failures and replacement casts | Modern interrupted art and Classic red, their hold/fade, rapid recasts, stale-event/fade rejection, unit clearing and swing-slot release retain existing ownership. |
| CFIN-06 | Keep geometry and work stable | No fill/icon/border layout change, border rebuild, new region, driver, hook, event, timer, setting, saved root or visible string. The existing text inset and paint/reset paths are reused. |

The shared implementation is in [FluxCastBar.lua](../UnitFrames/FluxCastBar.lua).
The current fix changes that one runtime file. The profession/school renderers
retain their public Finish behavior for other owners; successful unit casts now
release active effects with Reset. Existing timings, casts, channels and options
remain. This does not add midcast interruptibility-event handling.

User validation: after being asked to reload and check successful casts including
crafting for green fill and cleared terminal warning/effects, the user answered
“Green finish looks right”. This is a user-reported visual pass, not an agent
capture or per-client native test. No fresh build, FPS, GPU or taint measurement
was collected.

The user explicitly reopened in-game testing during this task. The earlier
general native-testing hold is superseded; WoW must remain in the background,
and prior input/gameplay restrictions still apply. Connected game-control/error
MCP tools are unavailable in this session, so this visual reproduction was
performed by the user. No automated input, live Lua or profiling was performed.

The fill and shield are decorative and add no controller focus stops. Existing
mouse/keyboard/controller routes, localized spell names, settings and saved data
remain. Offline tests cover five client models and native-source replacement;
actual-client cross-version input/taint/performance acceptance remains pending.

See [current exact sources and scoped evidence](validation/cast-green-finish-2026-11-16.json),
[earlier completion evidence](validation/cast-completion-2026-11-16.json),
[school fill ownership](CAST_SCHOOL_FILL_TIP_FIX.md) and
[profession themes](TRADESKILL_CAST_THEMES.md).

17 November active-cast follow-up: crafting warning/icon and border-fit corrections
retain this green completion contract. See [overlay and active-cast requirements](UNIT_OVERLAY_ATTACHMENTS.md) and [current scoped evidence](validation/unit-overlays-active-casts-2026-11-16.json).
