# USER-001: Forever secret startAlpha in shared fade manager

**Status: confirmed user-reported runtime error; actual fading frame and taint
origin remain unresolved. No addon fix applied.** The user confirms Forever and
does not know the preceding action. Combat, world/dungeon/raid, character class,
affected frame and actual runtime build were not supplied. No further context is
assumed, and no native reproduction or diagnostic/input operation was performed
by this audit.

The user supplied the same error twice:

```text
12:31:53 ...nterface/AddOns/Blizzard_SharedXMLBase/FrameUtil.lua:427:
attempt to perform arithmetic on field 'startAlpha'
(a secret number value, while execution tainted by '_FluxUI')
[C]: ?
[Interface/AddOns/Blizzard_SharedXMLBase/FrameUtil.lua]:427:
in function <...FrameUtil.lua:410>
```

The reported time's timezone was not established. Two copies do not establish two
different frames: one active fade can throw on more than one manager update.

Follow-up user reports add the same stack at12:32:26 once,13:05:58 twice,13:09:17
twice,13:17:27 twice,13:19:19 twice and13:21:18 twice: thirteen consolidated reported entries at seven displayed timestamps in total.
Later re-pastes of previously supplied timestamps are not counted again. The action
remains unknown. Original test JSON preserves its initial two-report capture;
[follow-up recurrence data](secret-value-followup/recurrences.json) records the
additional entries. Repeated timestamps do not establish different affected
frames or continuous failure between the reports.

The [wider follow-up](secret-value-followup/README.md) tests related alpha and
geometry consumers and native fade timeout behavior. Without requeueing, a bad
fade can still retire when its public duration elapses; the stack alone does not
establish an infinite manager failure. Additional conditional findings are kept
separate from attribution of this user's fade error.

## Exact source identity and failure boundary

Fresh read-only GitHub connector retrieval used Forever commit
`9dc84f0d3bbae1768ac3405b3716000bd93eda06`, reference version `1.60.1.70862`.
That version identifies the source snapshot, not a captured user runtime build.

- [FrameUtil.lua](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_SharedXMLBase/FrameUtil.lua), Git blob `a1fe94ae627fe3c694d5c38df9f0d1a54eecb84d`.
- [SimpleFrame API declaration](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_APIDocumentationGenerated/SimpleFrameAPIDocumentation.lua), Git blob `07debf919e8b4d43087306d2eccfb8e18e8f2c82`: `GetAlpha` at line276 has `SecretReturnsForAspect = Alpha`.

The external local FrameUtil source matches the freshly retrieved Git blob after
CRLF→LF normalization. [Raw results](user-001-fade-results.json) records the full
commit/URL/blob, normalization, local Git blob, source hashes and repeated tests.
The source stays in the existing external reference tree; no upstream runtime
file is vendored into this documentation folder.

`UIFrameFadeOut` copies its `startAlpha` argument into a fresh fade record at
lines383–389. `UIFrameFade` assigns that record to `frame.fadeInfo`, inserts the
frame in shared `FADEFRAMES` and arms its manager. `UIFrameFade_OnUpdate`, defined
at line410, later processes every queued frame. **Line427 is specifically the
OUT branch**, which subtracts `endAlpha` from `startAlpha` during interpolation.

This locates the failing consumer precisely. It does not identify the caller
that originally queued the fade, the frame at the current index, the first
writer that made the alpha inaccessible, or the earlier operation that supplied
the tainted execution path. The asynchronous manager stack has already lost the
original registration stack.

The error establishes an inaccessible number at that runtime operation. A
`SetAlpha` sink may accept an opaque value without allowing Lua arithmetic on a
later `GetAlpha` result. Setting a plain alpha first is not evidence that reading
it back grants data access. Likewise `pcall`, a zero-delay timer or an OOC test
cannot certify removal of taint or secrecy.

## Candidate ranking based on actual call sites

| Rank | Candidate | Evidence matching the sink | What is still missing |
|---|---|---|---|
| Leading direct supplier | `UnitFrames/FluxCastBar.lua:1291`, `StartCastBarFadeOut` | Sends `self:GetAlpha()` directly to `UIFrameFadeOut`; no value-access gate. Production forces `SetAlpha(1)` immediately before that getter. Hold expiration at `:2275` starts a 0.75s normal or 0.30s interrupt fade. | Identity of the user's fading frame, whether that getter returned a secret value in the real context and native provenance |
| Leading direct supplier | `UnitFrames/FluxSwingTimer.lua:1167`, `StartSwingFadeOut` | Sends `swingFrame:GetAlpha()` directly to `UIFrameFadeOut`; no value-access gate. Fade duration1.0s; started by several linger/completion paths. | Whether a swing bar existed/was fading and its real alpha/provenance at the reported time |
| Lower direct match | `UnitFrames/FluxLegacyComboPoints.lua:104`, `:120` and `NamePlates/ComboPoints.lua:82` | These direct calls use IN fades with omitted endpoints defaulting to public0/1, rather than the reported OUT input. Legacy player combo is explicitly disabled on Forever by `Core/FluxAPI/Actions.lua:494`; Forever nameplate points use their Modern branch. | A different downstream native animation callback/transition would need its own evidence; these calls alone do not explain427 |
| Shared native queue/indirect paths, not excluded | Native chat fades, map/reticle/tab fades or other addons/native code sharing the manager | The same native queue can contain frames registered outside the two Flux suppliers. The pinned native chat file contains OUT fades that read `GetAlpha` on scrollbars, tabs and button frames. Flux also configures chat/layout/native alpha; a native caller may execute in an altered provenance context. | Loaded family path, actual queue/frame and registration/provenance evidence. No supplied stack ties this report to chat, map or another integration |

This is a ranking for investigation, not a conclusion that the cast or swing
module caused the observed error. The report deliberately leaves both leading
suppliers open. Source enumeration found no production addon replacement of the
global `UIFrameFade*`, `UIFrameFlash*` or `FADEFRAMES` identifiers; direct fade
callers are concentrated in the four files above. The
[alpha inventory](user-001-alpha-inventory.csv) records650 relevant lexical rows
including getters, setters, booleans, fade record fields, comments and native
alpha writes. They are not650 detected problems.

## Conditional production-code reproducer

Run from the repository root:

```powershell
python 'Stress test doc/security/run_user_001.py'
```

The harness executes the exact production `StartCastBarFadeOut` and
`StartSwingFadeOut` function fragments and the cryptographically matched pinned
native manager. Frames and timers are mocked. **A table with an arithmetic
metamethod trap represents an opaque alpha; it is not a WoW secret number or a
taint VM.** The explicit condition is that the selected getter supplies an
unreadable alpha.

Three independent runs each perform33 assertions and demonstrate:

- Readable controls interpolate normally with original normal/interrupt/swing durations and existing completion timers.
- Each leading supplier reaches the exact native line427 when its getter returns the opaque stand-in. Repeating that manager update reproduces a second error.
- A bad early fade row aborts that update before a later healthy row is processed, illustrating a conditional shared-manager impact; it does not prove an observed FPS spike.
- Experiment-only in-memory endpoint substitutions avoid the getter and arithmetic trap while retaining the tested durations. They do not modify or accept production code or native visuals.

The harness catches expected failures so the other scenarios continue. It uses
`xpcall` only to capture test evidence, not as a proposed production suppression
fix. Source hashes before/after are unchanged for the files consumed by the
focused reproducer. Other concurrent addon changes are handled by the root
corpus checkpoint; this focused result does not accept their behavior.

Existing cast-school tests mock `UIFrameFadeOut` as a no-op
(`tests/castbar_school_themes.lua:200`). Those passes do not exercise native
fade interpolation. The new source-pinned conditional trace fills that specific
test gap without claiming that every cast or native fade is now validated.

## Feature-preserving options for later fixing

1. **Cast endpoint, smallest conditional change:** the existing code deliberately
   forces alpha1 immediately before fading. If native frame evidence identifies
   this supplier, use that known public starting endpoint instead of reading
   it back. Retain0.35s finish hold,1.0s interrupt hold,0.75s normal fade and0.30s
   interrupt fade, existing cancellation/restart rules, release callbacks and
   every unit's artwork/visibility. A native comparison must still confirm the
   intended alpha behavior in the affected context.
2. **Swing endpoint/state:** preserve its existing out-of-range alpha0.4, ordinary
   alpha1,1.0s duration and fade restarts. A blanket start1 would brighten an
   out-of-range or partly faded bar. If this supplier is confirmed, retain an
   addon-owned public presentation/fade state, including current interpolation
   on restart, or use a compatible local animation owner with public endpoints.
   Reuse existing timers/owners rather than introducing a new global service.
3. **When the queued frame is native:** preserve that frame's native fade and
   locate the earlier Flux callback/writer that changed provenance or supplied
   an inaccessible endpoint. Adjust that specific boundary. Do not replace the
   shared fade manager, iterate/clear other owners' `FADEFRAMES`, monkey-patch
   `GetAlpha`, recover secret values, or suppress all native fade errors.

These are documented options only. Preserving visible fade and range behavior
rules out silently removing fades or forcing every alpha to a constant.

Later regressions should cover readable/inaccessible getter contracts; normal,
failed and interrupted casts; channel/empower; player/target/focus/party/pet bars;
cast→swing handoff; OOR0.4→in-range1; repeated fade interruption/restart; target
and mouseover swaps; rapid modifier changes; disable/hide/reload; simultaneous
healthy and failing fade owners; and independent native chat/map fades. Test
world/dungeon/raid and OOC/combat per actual client build. Native taint and pixel
acceptance remain pending under the user's current simulation-only instruction.
