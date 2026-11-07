# Related secret getter boundaries — 7 November 2026

The recurring USER-001 Forever fade report prompted a separate search for the
same general mistake: inspecting a native getter result before establishing
that Lua may read it. This follow-up does **not** identify the fade owner or the
first taint writer. Its two geometry cases are separate conditional findings,
not extra occurrences of the user's FrameUtil error.

All work in this follow-up is confined to this new folder. The audit issued no
addon source/test, game, input, saved-settings or profiler writes. No broad
current-addon pass is claimed: consumed files have exact before/after hashes,
and unrelated concurrent source changes remain in the root preservation record.

## Evidence

```powershell
python 'Stress test doc/security/related_value_followup/run_related_values.py'
```

[results.json](results.json) records five successful processes, identical metrics
and no hash drift in consumed files. Each run has 35 assertions: **175 assertions
across five runs**. One conditional comparison failure and one internally
contained conditional arithmetic failure are expected observations per run.
The harness catches the former so the remaining scenarios continue.

The harness executes exact production fragments, including the complete
`UF.UpdateHealPrediction` painter, the actual overlay helper and the actual
meter/portrait guard helpers. It also loads the complete current secret helper
files. Synthetic widget getters return either normal values or a table with
explicit comparison/arithmetic traps. **That table is not a WoW secret number
or native taint VM.** It cannot reproduce secret booleans, primitive-number type
behavior, all equality rules, engine permission checks or native propagation.
The tests establish the stated conditional code path, not its real-client
frequency or reachability on the user's particular frame.

Root freshly retrieved the declarations at Forever commit
`9dc84f0d3bbae1768ac3405b3716000bd93eda06`, source version `1.60.1.70862`.
This runner independently matches the external local files to those Git blobs:

| Declaration | Pinned contract | Git blob |
|---|---|---|
| [SimpleFrame GetAlpha](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_APIDocumentationGenerated/SimpleFrameAPIDocumentation.lua#L276) | `SecretReturnsForAspect = Alpha`; `SetAlpha` accepts secret arguments when tainted. A native display sink does not grant Lua comparison permission. | `07debf919e8b4d43087306d2eccfb8e18e8f2c82` |
| [SimpleScriptRegion GetHeight/GetWidth](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_APIDocumentationGenerated/SimpleScriptRegionAPIDocumentation.lua#L161) | GetHeight at161 and GetWidth at323 have `SecretWhenAnchoringSecret`; these values are not unconditionally public geometry. | `e244d9eba05238cd1260a10ce34a14d07f7a6ae9` |
| [SimpleScriptRegionResizing GetPoint](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_APIDocumentationGenerated/SimpleScriptRegionResizingAPIDocumentation.lua#L65) | `SecretWhenAnchoringSecret`; a returned anchor/offset cannot be assumed readable from the getter name. | `6425c8deefe565688f200fbff9d46c364a8f539b` |

The geometry annotation is conditional. It proves that the injected opaque
contract is permitted by the source declaration in some anchoring contexts;
it does not prove that the user's health-bar width was secret during any report.

## GEO-01: heal-prediction width compared without a secret gate

**Status: conditional production-path failure reproduced; native occurrence
unobserved.**

The modern/Forever path in
[FluxUnitFrames_Shared.lua:2562](../../../UnitFrames/FluxUnitFrames_Shared.lua#L2562)
reads `healthBar:GetWidth()`, then tests `barWidth > 0` at2564 before applying
absorb geometry. There is no value-access/secret gate for that comparison.

The full painter passes with width120, hides the absorb with width0, and exits
safely when the prediction owner is missing or both options are disabled. With
the explicit opaque native-width stand-in, it fails at the exact production
line2564 before the absorb's SetWidth/Show. The stack is retained in the results.
This is a different consumer from FrameUtil427; the supplied user stack does not
connect the two.

Future direction: keep the absorb's amount/max-health values on their existing
native StatusBar sinks. Use existing public configured geometry or a permitted
native anchoring/clipping route for width, or guard the read and retain the last
public intended geometry until an appropriate layout opportunity. Establish the
correct unknown-width policy before implementation. Converting an inaccessible
width to0 and hiding the absorb would lose a visible feature; wrapping the whole
painter in pcall would merely hide the failure.

Regression requirements: positive/zero/public/inaccessible width; missing owner;
prediction/absorb options separately and together; native getter returning
inaccessible width after a prior public sample; heal/absorb changes during combat;
health fill0/full, overlay overflow and disable/re-enable; all supported unit
frames and target/mouseover changes. Native tests must determine whether the
actual Health frame can enter secret anchoring in the reported client/context.

## GEO-02: secret-dependent tile geometry still enters arithmetic

**Status: conditional arithmetic denial contained internally; possible stale
presentation, not an uncaught native error proven here.**

[RefreshTiledOverlayTexCoords:2306-2325](../../../UnitFrames/FluxUnitFrames_Shared.lua#L2306)
recognizes unreadable dimensions for caching, clears its public dimension
cache, but still calculates `w / tileSize` and `h / tileSize` inside pcall before
SetTexCoord. The same file's
[AnchorOverlayToStatusBarFill:2292](../../../UnitFrames/FluxUnitFrames_Shared.lua#L2292)
anchors this overlay to the live fill, making the conditional native geometry
contract relevant to this class of overlay.

With normal96×32 dimensions and tile32, the helper writes correct3×1 coordinates;
a second unchanged call avoids a duplicate write. If the width getter supplies
an opaque value **and arithmetic is denied**, the trap fires inside the existing
pcall. No error escapes the helper, no new SetTexCoord occurs, previous
coordinates remain, and public geometry caches are cleared. A later public
64×32 sample restores correct2×1 coordinates. Hidden/missing overlays exit safely.

The annotation alone does not establish whether division is denied, permitted
or propagated for every secret dimension in every native caller context. The
test makes denial explicit; it does not generalize USER-001's alpha arithmetic
failure to all geometry arithmetic. The source comment near2509 saying all
secret arithmetic is safe is likewise not an operation-specific permission
contract.

Future direction: audit the exact native texture/tiling capability and existing
art setup, then choose a geometry path that preserves tile size without Lua
inspection of restricted dimensions. Possible bounded approaches include an
already supported native tiling/wrap path or retained public tile geometry with
native anchors until geometry becomes readable. These remain design candidates;
visual parity and current client permissions must decide. Do not remove stripe
art, silently freeze it permanently, reset the widget to recover data, or claim
that pcall makes the dimension readable.

Regressions should include new/reused overlays, changing public dimensions,
public→inaccessible→public transitions, conceal/show, health fill changes,
overflow/reverse-fill, UI scaling and tiled-art pixel comparisons. This follow-up
does not certify native SetTexCoord access or that either candidate preserves
the current appearance without implementation and native verification.

## Guarded paths checked and retained as controls

The following uses of getters/caches are **not** reported as additional errors:

- [Meter header:162-200](../../../Battlezonemap/FluxMeterSkin.lua#L162) stores an
  opaque alpha without inspecting it and forwards it back to native SetAlpha on
  restore. Its height logic rejects inaccessible dimensions before comparison.
  The test performs zero opaque operations; a missing getter uses its public
  default.
- [Meter PublicPoints:340](../../../Battlezonemap/FluxMeterSkin.lua#L340) rejects
  inaccessible offsets before geometry arithmetic/equality. The readable
  anchor control remains intact.
- [Meter TrackTimer:762](../../../Battlezonemap/FluxMeterSkin.lua#L762) rejects
  secret alpha through FiniteNumber rather than treating it as a plain timer
  value. A public .8 alpha is tracked; a missing getter exits safely.
- [Meter SetMenuVisible:621](../../../Battlezonemap/FluxMeterSkin.lua#L621)
  multiplies .92 only into public alpha; opaque alpha passes unchanged to the
  native setter. Hiding uses public0. Storing an opaque value is not itself a
  taint error when the code only forwards it to an allowed sink.
- [Portrait visibility:3969](../../../UnitFrames/FluxUnitFrames_Shared.lua#L3969)
  guards its alpha comparison. Opaque alpha causes no compare; ordinary nearly
  transparent alpha and a missing getter keep their existing behavior.
- Actual current number helpers reject a secret stand-in even when
  `canaccessvalue` returns true. KeepLastNumber retains a previous plain value.
  This supports reusing existing services with an explicit per-feature unknown
  policy. It does not endorse a blanket default0 or reading the widget back.

Bars/Blizzard's direct GetAlpha comparison was independently inspected and is
covered by the separate alpha follow-up. It is not assigned a duplicate finding
ID here. Native width, anchor, alpha, taint provenance and the actual queued fade
owner remain separate acceptance questions.
