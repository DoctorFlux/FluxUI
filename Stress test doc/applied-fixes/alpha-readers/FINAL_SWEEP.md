# Bounded final alpha sweep

Read-only review found **no additional actionable alpha comparison/arithmetic failure** in the requested remaining locations. No runtime file was edited by this sweep.

| Location | Actual consuming behavior |
|---|---|
| `Blizzard/Hide.lua:259` | Cache alpha for restoration; numeric alpha, including opaque alpha, is passed back to `SetAlpha`. No numeric comparison/interpolation is performed here. |
| `Battlezonemap/FluxMeterSkin.lua:181,640,766` | Header/menu alpha is preserved and forwarded. Menu multiplication only occurs for a public number; otherwise alpha forwards unchanged. Timer alpha passes a finite/public guard before tracking. |
| `UnitFrames/FluxCastBarThemes.lua:617,847` | Cache source alpha and restore it through the display setter. No ordering, division or interpolation consumes the cached value. |
| `UnitFrames/FluxUnitFrames_Shared.lua:4062` | Portrait predicate short-circuits on `IsSecretValue` before the small-alpha comparison. This remains an existing guarded control. |
| `UnitFrames/FluxUnitFrames_Party.lua:137` | Cast-cover cache uses secrecy/type checks before selecting a readable alpha or its existing owner-default restore policy. No opaque arithmetic/comparison is introduced. |
| `RaidFrame/FluxRaidLayout.lua:936,983` | Suppression rejects secret values before caching; restoration tests secrecy before equality through short-circuit evaluation. |
| Classic combined-bank cached alpha | The reviewed alpha values are saved/restored through display setters. Guild-bank and void-storage callback work remains outside this sweep. |

The current inspected Forever SimpleFrame/SimpleRegion declarations mark `GetAlpha` with alpha secrecy metadata; `GetEffectiveAlpha` additionally declares `RequiresScriptObjectAlphaAccess`. A hypothetical throwing getter can be simulated for any function, but that alone does not establish a new native defect on these already owned/nonforbidden `GetAlpha` receivers. Their native permissions still belong to client acceptance; this review does not reopen existing guarded/opaque-forwarding controls without new evidence.

Additional fade-call review:

- `FluxLegacyComboPoints.lua:104` calls `UIFrameFadeIn` without alpha endpoints. The native IN path supplies public0→1 defaults.
- The LegacyComboPoints and NamePlates combo-highlight calls supply `mode="IN"`, duration and callback fields, with no frame-alpha getter or opaque endpoint. Native defaults again supply0→1.
- The Era/Anniversary native `ComboPointShineFadeIn` callback starts an IN fade with public defaults. Its `ComboPointShineFadeOut` calls the OUT wrapper without endpoints, supplying public1→0 defaults. This Classic callback claim is limited to those inspected families; it is not substituted for Forever's different Camelot combo implementation.
- Cast OUT currently supplies explicit1→0. Swing OUT supplies the repaired tracked public start and explicit0 endpoint.

[Machine evidence](final-sweep.json) retains hashes and raw outputs for20 passing native-source Lua controls: four endpoint/default controls for each of the four local FrameUtil family files, and two Classic shine-callback controls for Era and Anniversary. A mocked frame getter throws if read; these paths complete without calling it. This is a bounded desktop control, not native taint, event-delivery, pixel or performance certification.
