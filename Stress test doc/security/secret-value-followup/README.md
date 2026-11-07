# Recurring secret-value errors — follow-up, 7 November 2026

The user's additional Forever logs repeat USER-001. The consolidated record now
contains thirteen entries at seven displayed timestamps:12:31:53×2,12:32:26×1,
13:05:58×2,13:09:17×2,13:17:27×2,13:19:19×2 and13:21:18×2. Previously pasted entries in later messages are not
counted again. [Recurrence data](recurrences.json) records that policy. These are
not thirteen identified bugs/frames and do not establish continuous failure between
timestamps. The user does not know the triggering action; do not infer one.

The exact native failure is the OUT fade's arithmetic on `startAlpha`, in
`UIFrameFade_OnUpdate` at FrameUtil.lua:427. Existing production cast and swing
fade functions pass their `GetAlpha()` return to that manager. They remain leading
conditional suppliers, not confirmed attribution to the actual reported frame.
The [original detailed report](../USER-001-FADE.md) retains source identity,
reproduction, alternate native queue callers and feature-preserving proposals.

This follow-up checks the same failure pattern outside fade interpolation:
getter results consumed by Lua arithmetic/comparison, getter-only `pcall` followed
by an unsafe comparison, type-only numeric checks, and restricted anchored
geometry. It distinguishes conditional source failures from actual native errors.
No addon code, game input, settings or profiler operation is changed.

## Results

[Alpha follow-up](../alpha_followup/REPORT.md) records six additional conditional
patterns across seven comparison sites and two glow-library arithmetic sites.
[Geometry follow-up](../related_value_followup/REPORT.md) records one comparison
failure and one internally contained arithmetic-denial case. These are not new
observed native errors or identification of the frame in USER-001.

| ID | Reviewed source | Conditional observation |
|---|---|---|
| ALPHA-01 | Bars/Blizzard.lua:1030 | Native grid suppression compares `GetAlpha()>0` without an access guard |
| ALPHA-02 | UnitFrames/FluxSwingTimer.lua:917 | A redundant alpha comparison can fail even though both branches returnfalse |
| ALPHA-03 | Core/ButtonFX/Charges.lua:135 | Effective alpha passes a number-type check, then is compared to0.4 |
| ALPHA-04 | Core/ButtonFX/Cast.lua:499; Bars/BadgeHost.lua:1230 | Getter pcall succeeds; an unguarded alpha comparison follows outside it |
| ALPHA-05 | ExtraButtonSystem/Engine/Button.lua:2268,2612 | Two cooldown appearance paths compare effective alpha without an access gate |
| ALPHA-06 | LibCustomGlow:717,726; UnitFrames Shared:7297,7300 | Glow recoloring divides unreadable alpha; the threat caller's suppressed failure can leave its applied-band cache ahead of the actual update |
| GEO-01 | UnitFrames/FluxUnitFrames_Shared.lua:2562–2564 | Heal prediction orders an inaccessible width against0 |
| GEO-02 | UnitFrames/FluxUnitFrames_Shared.lua:2306–2325 | Tile arithmetic denial is caught internally; old coordinates remain until a later public sample recovers; no escaping native error is proven |

Alpha evidence: three processes ×125 assertions=375. Geometry and guarded meter/
portrait evidence: five processes ×35 assertions=175. Existing-helper controls:
three processes ×80 assertions=240. These790 assertions include positive controls
and expected bad-path observations; successful evidence capture does not make
those conditional failures a safety pass. Consumed source hashes remain current
and stable at the [focused validation](validation.json).

The review deliberately excludes a Classic/pre-DF ring helper as a leading
Forever cause, an unloaded LibActionButton copy, and a similarly named Details
configuration helper. Meter/portrait guarded controls pass without opaque-value
operations. Do not turn the getter inventory into a count of confirmed errors.

The actual native manager also retires a bad .30s fade after its timer reaches
completion when it is not requeued. The tested .05s steps yield five arithmetic
traps, then an empty queue within1s. A bad row can delay later rows during an
update, but neither source nor the supplied timestamps proves a permanent block.

Reproduce from the addon root:

```powershell
python -B 'Stress test doc/security/alpha_followup/run.py'
python -B 'Stress test doc/security/related_value_followup/run_related_values.py'
lua 'Stress test doc/security/secret-value-followup/guard_controls.lua.txt'
python -B 'Stress test doc/security/secret-value-followup/validate_followup.py'
```

The detailed reports contain feature-preserving proposals and regressions for
every pattern. Native taint, actual fade ownership and pixel parity remain open;
no runtime fix was applied.

## Positive controls for existing safe helpers

[guard_controls.lua.txt](guard_controls.lua.txt) loads the complete existing
`Core/API/Secrets.lua` and `Secrets_Midnight.lua`. Eight model configurations
(Retail/Forever labels × four access policies) test secret-denied, secret with
access=true, access-denied and throwing-predicate paths. `SafeCompare` returns
unknown, `SafeGetNumber` retains an explicit fallback, and `KeepLastNumber`
retains the caller's known public range alpha. Readable controls retain ordinary
threshold and numeric behavior. All240 assertions across three independent runs
pass with zero opaque arithmetic/comparison attempts and unchanged consumed hashes.
[Raw results](guard-controls-results.json).

The opaque tokens and predicate failures are explicit Lua stand-ins. These tests
do not emulate WoW's taint VM or prove native access permission. They show that
the addon already has reusable helpers for a later fix; no new framework is needed.

## Common requirements for later fixes

- Treat `type(value)=="number"`, a successful getter `pcall`, and OOC state as
  insufficient evidence that a value may be compared or used in arithmetic.
- Prefer the existing access helpers before the consuming operation. An unknown
  result needs an explicit caller policy; blindly converting every unknown alpha
  to0/hiding the feature would change behavior.
- For owned fades retain public intended presentation state: cast's already
  forced1 endpoint, swing's range0.4/ordinary1 and mid-fade restart state, existing
  durations, cancellation and completion. Do not read opaque alpha back to
  reconstruct it or reset a widget to try to reveal restricted state.
- For layout, use already public owned dimensions or retain/defer the last valid
  layout when geometry is inaccessible. Do not publish mixed secret/public
  anchors or silently collapse a bar to zero width.
- Do not modify Blizzard's shared fade manager, replace global getters, clear
  other owners' fade queues, strip the visual features, or suppress all errors.

## Source scope and preservation

The current Forever source pin remains9dc84f0d3bbae1768ac3405b3716000bd93eda06,
reference version1.60.1.70862; the installed/in-memory build is unknown. Current
generated geometry files were fetched and matched to local normalized Git blobs
in [contracts.json](contracts.json). GetAlpha and FrameUtil declarations were
rechecked at the same pin. The generated declaration's conditional restriction
does not prove any particular real frame currently returns a secret value.

[source-checkpoint.json](source-checkpoint.json) compares all885 Lua identities
with the earlier full-suite record. Nine files changed outside this audit since
that run. The earlier222/222 result belongs to its captured source; this focused
follow-up does not promote it to whole-addon acceptance of the newer files.
Focused reproducers retain their own before/after hashes and mock/native limits.
MouseoverCast.lua and its existing test changed again during this focused review;
neither is consumed by these alpha/geometry reproducers. This is recorded in the
validation artifact and was preserved without rollback.
