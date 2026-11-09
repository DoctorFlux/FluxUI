# Objective tracker cannot scroll fully up

8 November 2026; TRACKER-TOP-20261108. The reported failure was scrolling only,
not tracker placement. A second Forever screenshot confirmed Blizzard's All
Objectives tracker; the earlier Questie screenshot was superseded. Questie files
were inspected read-only and remain unchanged.

## Reproduced failure and correction

At the apparent top, the native scroll offset was already zero. The content and
tracker heights were1276.847290, viewport height640.666687, and API range863.694641.
The scroll body's/content's top was1051.333252, while the tracker and first quest
module's top was1276.847290, despite correct zero-offset anchors. All relevant
local scales were1, effective scale0.5625.

The inner native tracker still had screen clamping enabled. Its long content
extended below the screen, so the engine pushed it upward to keep its bottom
on-screen. The scroll viewport then clipped the first quests, even at offset0.
An isolated live toggle reproduced/corrected the fault: disabling only the inner
clamp aligned all top edges, reduced the range to approximately636.18 and restored
the Quests header plus the missing first objectives. Refreshing the scroll
rectangle or reapplying its existing anchor alone did not fix it.

`Minimap/FluxObjectiveTrackerScroll.lua` now releases the inner screen clamp when
the Flux viewport is created or reasserted. The fixed outer viewport remains
screen-clamped and its body continues clipping overflowing content. Position,
width, scale, header, textures, wheel step and quest interactions are unchanged.

Two related native-profile recovery gaps were reproduced in desktop source
replays: the temporary100000-unit layout height could survive the cached-height
return, and re-docking did not guarantee another sync without a quest event.
The existing guarded settlement helper now runs on the cached path, and native
anchor recovery requests the existing coalesced sync. Re-docking defers through
the shared Edit Mode service while the editor owns its frames. Combat and Questie
ownership guards remain in place. No new ticker, frame, event or OnUpdate.

## Verification and limits

- [Before/after raw runs and source identities](validation/tracker-top-comparison-2026-11-08.json): five alternating baseline/candidate source-model pairs; candidate62 checks PASS, baseline rejects. Actual pinned Retail/Forever frame/container/anchor functions are replayed; widgets and secure execution remain modeled.
- [Whole suite](validation/tracker-top-full-2026-11-08.json):260 scripts and926 Lua syntax files PASS. [Manifest comparison](validation/tracker-top-source-guard-2026-11-08.json) shows no source drift.
- Forever1.60.1 build70862: live clamp-toggle reproduction, matched UI geometry and screenshots, reload of the permanent source, native wheel-handler down90/back0, inner clamp false/outer clamp true/top gap0, and BugTabs0. These establish the exercised native UI paths; sustained combat, hardware wheel routing and other native clients remain separate acceptance cases.

Primary references are the pinned [Forever container](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_ObjectiveTracker/Blizzard_ObjectiveTrackerContainer.lua) and [Retail container](https://github.com/Gethe/wow-ui-source/blob/297d7aaaa736f346b3e036f38ee088eaf7f8c07f/Interface/AddOns/Blizzard_ObjectiveTracker/Blizzard_ObjectiveTrackerContainer.lua).
The frame/container files used by the tests match their pinned blobs byte-for-byte
after line-ending normalization. Native screenshots remain in the external
checkpoint area; private account/character settings are not published.

No profiler preference was changed. Native CPU/memory/allocation/FPS and matched
hardware/addon-list performance captures are unavailable; geometric correction and
desktop operation checks do not establish an FPS improvement.

During validation, only native preset layouts were listed. The user confirmed
they **deliberately deleted FluxUI**. This was not a persistence failure.
The subsequent request now explicitly requires automatic creation when FluxUI is
missing; see [current profile policy](COOLDOWN_VIEWER_DEFAULTS.md).
