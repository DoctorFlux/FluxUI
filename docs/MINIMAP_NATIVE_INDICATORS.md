# Native minimap mail and calendar

7 November 2026, `MINIMAP-NATIVE-20261107`. The user requests Forever's mail
icon and a minimap calendar when supplied by the client, chooses direct
implementation, and selects UIForever for visual testing.

## Source and behavior

Gethe Forever commit `9dc84f0d3bbae1768ac3405b3716000bd93eda06` reports
1.60.1.70862. Its [minimap TOC](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_Minimap/Blizzard_Minimap.toc)
selects Camelot mail/indicator/calendar templates alongside Mainline minimap XML
and calendar logic. The [mail template](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_Minimap/Camelot/MinimapMailFrameTemplate.xml)
is 32x24 with `ui-hud-minimap-mail-icon`; the indicator template constructs
`MinimapCluster.IndicatorFrame.MailFrame`. Flux now selects that native frame
before the fallback, preserving legacy global/Minimap-key priority. Its native
hide script remains. Existing Flux event/tooltip ownership and always-show-unread
policy remain: the native mail event method calls its parent's `Layout`, which
cannot be assumed after reparenting to Minimap. No shared API is replaced.

The [calendar template](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_Minimap/Camelot/GameTimeFrameTemplate.xml)
is 23x23 with `ui-hud-minimap-calendar-button`. Mainline GameTime.xml creates
the global `GameTimeFrame`; the [calendar bootstrap](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_Calendar/Blizzard_Calendar_Bootstrap.lua)
supplies `ToggleCalendar`. Flux retains the native control when that function
exists, anchors it at TOPLEFT with the existing border inset, and reparents it to
Minimap so embedded visibility follows naturally. Native size, art, scripts,
invite indicators and disabled state remain. It adds no click replacement or
addon polling driver. Showing the native calendar resumes its own OnUpdate;
this is a feature cost, with native CPU/FPS unmeasured. Clock-only clients keep
their previous hiding policy. Repositioning uses the existing combat guard.

Additional source checks: Retail `297d7aaaa736f346b3e036f38ee088eaf7f8c07f`
loads Mainline GameTime.xml; progression Classic
`e5d9b3a22c3f0f6f41ebac0e454f4969594261cf` loads Wrath GameTime.xml for
Mists and defines ToggleCalendar in Mists UIParent.lua. Its Vanilla/TBC TOC paths
use GameTime_NoCalendar. These are source checks, not new runtime passes.

## Validation and recovery

[Source identities](validation/minimap-native-source-2026-11-07.json),
[regression evidence](validation/minimap-native-indicators-2026-11-07.json) and
[full suite](validation/minimap-native-indicators-full-2026-11-07.json) retain
exact source hashes and raw output. The extended existing mail harness passes
717 checks and rejects the pre-edit source. Coverage includes native cluster
selection, retained fallback, late native handoff, repeated cleanup/layout,
calendar script identity and click dispatch, hidden cluster/map, combat deferral
and clock-only absence. Mocks do not render native textures or execute the real
calendar. Full desktop validation passes 232 scripts / 896 syntax files, with
unchanged post-suite Lua hashes. All five installed runtime copies match through
the existing mirror; no manual copy was performed.

Before editing, an external dated checkpoint preserved 2040 actual files and
verified Git history; 16 available Forever/Retail settings metadata entries were
inspected read-only. No settings, profiler preferences, game input or foreground
state was changed. No saved-data/schema/TOC change or new branch is required.

## UIForever handoff and pending client checks

The user selected [UIForever Forever](https://uiforever.com/app?flavor=forever).
The homepage confirmed Forever available on 7 November; this environment has no
browser automation tool or installed Playwright/Puppeteer runtime. Execution,
simulator build, screenshots, visual comparison and diagnostics are **NOT RUN**.
A clean `_FluxUI` ZIP with runtime load closure, media and licenses was prepared
outside AddOns; its exact path/hash are in the regression evidence.

1. In UIForever, choose ADDONS → Choose ZIP and import the prepared ZIP with
   fresh settings. Allow the base UI/assets to finish loading.
2. Verify the native mail envelope with mail present and absent. Check hover,
   repeated mail state changes and no duplicate icon after reload.
3. Verify the top-left calendar, hover/click, invite alert and enabled/disabled
   states supported by the simulator. Record unsupported emulation separately.
4. Switch corner/embedded Map modes and another Flux tab; confirm both indicators
   follow visibility. Repeat at the normal viewport/UI scale and a smaller size.
5. Capture Errors/Missing APIs and Developer build, plus representative screenshots.
   Do not change production code solely for an emulator stub.

Actual client mail delivery, calendar/invite operations, combat/taint, native
pixels, persistence and CPU/FPS remain pending even after simulator success.
