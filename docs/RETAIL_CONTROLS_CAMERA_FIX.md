# Retail first-load Sticky Targeting and camera — 30 October 2026

## Historical FluxUI follow-up

The linked [DoctorFlux/FluxUI main source](https://github.com/DoctorFlux/FluxUI/blob/main/FluxDefaultSettings.lua)
matches the pre-fix file in this workspace (Git blob
`b2fdd9ed540542decacbad275e0dd200676e0210`). It does not contain a
separate working implementation. A read-only 13 August 2026 local snapshot,
`__Backup/FluxUI Backup Right before the majoe Rewrite/FluxDefaultSettings.lua`
(SHA256 `1eda5b3100256471c92c3018abea8b202b0362c7db0630f238b8ff13c7c5e057`),
does contain a distinct route: it calls the registered native
`deselectOnClick` setting with the checkbox value `false` and immediate
commit. This matches the [Gethe Live setting transform](https://raw.githubusercontent.com/Gethe/wow-ui-source/live/Interface/AddOns/Blizzard_Settings_Shared/Blizzard_Setting.lua).

The current `BlizzardSettings.Write` service now exposes only that one
registered Controls write on Retail/Forever. `ApplyStickyTargetingOff` uses
it first, verifies the CVar is `1`, and falls back to the raw CVar write if
the setting is unavailable. Already-correct values avoid re-entering the
native setting. General `Settings.SetValue` calls remain guarded on modern
clients, including the protected raid/nameplate callbacks. The historical
snapshot's raw `deselectOnClick=0` writes were not copied because they
conflict with the unchecked checkbox's stored `1` and caused extra writes.
The historical camera helper had the same speculative Retail maximum of 4;
the 2.6 no-maximum fallback from the prior repair remains.

A new dated checkpoint at
`C:/Users/mario/.codex/visualizations/2026/10/30/01a18c7b-9090-77e3-a5e9-25334cbfe0fe/historical-controls-checkpoint-20261030`
preserves the pre-edit local source and Git history outside AddOns. The
pre-edit `FluxDefaultSettings.lua` SHA256 was
`f2d1fd60694d5a48dfe936be9157eaa0146711e09b3105a205830f539d111010`;
the candidate is
`cf42c23c388fbfd0dce36261d3c2be11b0446eb58228a6e305a31c304e181590`.
The candidate `BlizzardSettings/Write.lua` SHA256 is
`de7e3a953bca81abefe7f439a350f69153a2e15b70c76f271896244400e951ad`.
The focused first-load fixture passes 76 checks, including the native
setting route, fallback, no repeated write, and unchanged general guard.
The [full desktop validation](validation/historical-sticky-setting-2026-10-30.json)
passes 106 scripts and 748 Lua syntax checks.
Native post-fix Sticky Targeting, camera acceptance, taint and frame time
remain pending because no WoW process was visible to this workspace.

The user reported that Sticky Targeting stayed on and the first-load audit
failed on `cameraDistanceMaxZoomFactor`. Their Retail readback was
`cameraDistanceMaxZoomFactor=1.900000`, `C_CVar.GetCVarMax=nil` and
`deselectOnClick=0`. This is native pre-fix evidence; post-fix native
acceptance is pending.

The first-load audit did not include `deselectOnClick`, so it could report
success despite Sticky Targeting staying on. The camera helper assumed a
maximum of 4 on Retail 12 when the engine gave no maximum. The user's 1.9
readback is consistent with that request being rejected; the native write
result was not captured. The revised fallback requests 2.6 when the engine
gives no maximum; an engine-reported maximum still takes precedence. Sticky Targeting
now has the native `deselectOnClick=1` value in the account defaults and audit.
Its focused write avoids repeating an already-correct CVar update. A prior
failed first-load audit gets one settings-only retry on the next login for
an already-seen character, without resetting account bindings.

Blizzard's [Live Controls definition](https://raw.githubusercontent.com/Gethe/wow-ui-source/live/Interface/AddOns/Blizzard_SettingsDefinitions_Frame/Controls.lua)
registers Sticky Targeting on `deselectOnClick` and negates the checkbox value.
The [setting implementation](https://raw.githubusercontent.com/Gethe/wow-ui-source/live/Interface/AddOns/Blizzard_Settings_Shared/Blizzard_Setting.lua)
transforms both reads and writes. The existing Retail guard against calling
native `Settings.SetValue` as Flux remains in force.

Before this edit, a dated external checkpoint was saved at
`C:/Users/mario/.codex/visualizations/2026/10/30/01a18c7b-9090-77e3-a5e9-25334cbfe0fe/controls-camera-checkpoint-20261030`.
It contains source copies, Git history, and available on-disk settings outside
AddOns. The baseline `FluxDefaultSettings.lua` SHA256 was
`0cd7d4e7f4de3b3e9197d56eb393559a5b64a70006a1e7fb7ac21461a904bf89`;
the candidate SHA256 is
`f2d1fd60694d5a48dfe936be9157eaa0146711e09b3105a205830f539d111010`.

The focused first-load fixture passes 68 desktop checks. It simulates the
reported Retail camera API returning no maximum, an engine that rejects a
request above 2.6, Sticky Targeting starting at 0, and a prior failed audit
retrying once without the keyboard setup. The binding fixture passes 507
checks. The [full desktop suite](validation/retail-controls-camera-2026-10-30.json)
passes 106 scripts and 748 Lua syntax checks. These tests cannot establish
native camera acceptance, Settings appearance, taint safety or frame time. No WoW process or
window was visible to this workspace, so no background client command was
run. The requested Mariosuper Era and Pandasans Retail checks remain pending.
