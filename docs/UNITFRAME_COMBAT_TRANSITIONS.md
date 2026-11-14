# Unit-frame combat clicks, target-strip width and absorbs

10 November native counterexample: the secure roster reveal remained valid, but
its ordinary power repaint reached blocked partition SetHeight/Show. Earlier
roster tests stubbed these painters; their results did not prove end-to-end child
geometry permissions. The shared path is corrected and strict production-path
coverage added. Native post-fix acceptance remains pending.
[Correction and exact evidence](POWER_PARTITION_COMBAT_JOIN.md).

9 November 2026 · UNITFRAME-COMBAT-20261109.

The user reported an unusable target right-click menu in combat, a wide focus-target
strip when setting focus in combat, the equivalent party risk, and missing absorbs
on the focus/party vertical HP strips. Preserve the existing accepted layout,
menu actions, click-cast precedence, settings, cadence and native focus capability
gates. This corrects the existing design; no mock-up or redesign is needed.
The established UIForever preference remains; no connected Witchcraft/UIForever
or computer-use tool is available. Native acceptance below is pending.

## Corrections

- Target: an empty target could disable its protected mouse host outside combat,
  especially on Forever's compatibility watch. Acquiring a target in combat could
  restore alpha while mouse input remained disabled. Reuse the existing Restricted
  service and its native-handler probe to put the outer click host under
  `[@target,exists] show; hide`. Keep prepared mouse input and native `togglemenu`;
  native visibility releases the empty hit rectangle. The separate empty-target
  outline retains its existing ownership and option. Feature disable/re-enable
  still hides/shows the parent. Old Forever builds failing both handler probes
  retain the previous fallback and are not certified by this fix.
- Focus-target: construction stored a 119-unit base width before matching the
  configured narrow party-target width. A later global squeeze/layout refresh
  restored that old width, and combat metrics could not resize it. Record the
  actual strip width and exclude this compact strip from horizontal squeeze.
  Coalesce blocked metrics through the existing combat queue, replaying the
  latest configured dimensions and anchor. Party targets already own fixed
  prepared dimensions; regressions verify all four through combat roster changes.
- Vertical strips: share damage-shield and heal-absorb display across focus,
  party targets and the existing pet-target helper. Shields start at the live
  health-fill top, extend upward into missing health, and spill downward over
  current health through a native fill-texture clip. Heal absorbs bite downward
  from the health edge. Full-height StatusBar normalization avoids width/health
  compression. Use existing shield/heal-absorb art and existing per-unit options.
  Refresh on absorb and heal-absorb events as well as health/identity/show paths;
  safe registration handles client event availability. Expiry, zero maximum,
  disconnect, death and option-off hide overlays.

Retail/Forever pass native calculator amounts and maxima directly to StatusBars;
no opaque arithmetic, fill measurements, secret identity caches or protected
input-time edits are introduced. Clamp damage to missing health and maximum
health for the two segments; clamp total heal absorb to current health. Older
clients use existing safe getters, with missing native APIs yielding no overlay.
Each strip preallocates four ordinary display frames (three StatusBars and one
clip); modern strips also prewarm one native calculator. Preview strips use the
same resources. No event frame, OnUpdate, ticker or polling cadence is added.
The target adds one native visibility registration on its existing click host.
These are feature costs, not a performance-improvement claim.

## Exact source and recovery

Work remains on main; unrelated local work is preserved. Before runtime changes,
external checkpoint `unitframe-checkpoint-20261109T104332Z` preserved 2362 actual files and all-ref
history. ZIP CRC and bundle verification passed; 120 read-only on-disk
settings metadata entries were inspected. Settings and unsaved game memory were
not changed. [Checkpoint and baseline hashes](validation/unitframe-combat-checkpoint-2026-11-09.json).

Fresh Gethe branch heads were resolved once and downloaded by commit. Native
SecureTemplates and SecureStateDriver files used in the desktop replays match
all five pinned files completely. Client-specific FrameXML TOCs,
SecureTemplates.xml, the restricted-environment TOC, Unit API definitions,
StatusBar sinks and calculator contracts/enums were inspected. Source declarations
and loading evidence do not certify native execution or protected-VM behavior.
No Blizzard implementation was copied into addon runtime files.

| Existing client | Pinned upstream | Source build | Native acceptance |
| --- | --- | --- | --- |
| Retail | [297d7aaaa736](https://github.com/Gethe/wow-ui-source/tree/297d7aaaa736f346b3e036f38ee088eaf7f8c07f) | 12.1.5.70783 | Pending |
| Forever | [9dc84f0d3bba](https://github.com/Gethe/wow-ui-source/tree/9dc84f0d3bbae1768ac3405b3716000bd93eda06) | 1.60.1.70862 | Pending |
| Classic progression | [e5d9b3a22c3f](https://github.com/Gethe/wow-ui-source/tree/e5d9b3a22c3f0f6f41ebac0e454f4969594261cf) | 5.5.4.70631 | Pending |
| Classic Era | [4192ac60067f](https://github.com/Gethe/wow-ui-source/tree/4192ac60067fc55566182291bc67c85dd9b6794d) | 1.15.9.70576 | Pending |
| Anniversary | [68e0a2ec559d](https://github.com/Gethe/wow-ui-source/tree/68e0a2ec559d9761dfc4e7f864c3944f9d758a49) | 2.5.6.70577 | Pending |

[Full source paths and SHA256s](validation/unitframe-combat-upstream-2026-11-09.json).
The existing Era/Anniversary support is retained in addition to Retail, Forever
and progression; clients lacking native focus retain the existing capability gate.

## Desktop evidence and remaining checks

- `lua tests/focus_secure_visibility.lua`: 285 checks on five exact native driver
  replays, including target clear/acquire cycles, prepared mouse state, stable
  registration and zero insecure combat mouse writes. Existing focus enable/
  disable and visibility checks remain. Baseline reproduces Forever's disabled
  input after an empty target; candidate passes.
- `lua tests/focus_target_combat_width.lua`: 30 checks on five client models.
  Repeated global refresh, combat focus acquisition and a deferred option change
  preserve the configured strip width. Baseline restores the wide size.
- `lua tests/unit_vertical_target_health.lua`: 2,785 checks on five clients and
  six target tokens. Covers vertical damage/loss feedback, small/large shields,
  overflow clipping, heal absorbs, option-off, expiry, opaque native value sinks,
  layout deferral, identity/reset and zero event-time frame allocation.
  Baseline has no visible shield path.
- `lua tests/raid_party_frames.lua`: 1,035 checks, including all four prepared
  party target widths/heights through native modeled combat roster transitions.
- Existing menu regressions retain 620 combat-menu and 670 native-menu checks;
  public geometry writers retain 80 checks with inaccessible native dimensions.

Five alternating baseline/candidate pairs for each reported fault and exact
four-owner hashes are retained in the [comparison](validation/unitframe-combat-comparison-2026-11-09.json).
Harness wall times are raw uncontrolled desktop durations, not CPU/FPS or native
latency measurements. [Full validation](validation/unitframe-combat-full-2026-11-09.json)
passes all 267 scripts and 934 Lua syntax files. The [source guard](validation/unitframe-combat-source-guard-2026-11-09.json)
verifies no source drift. All [20 installed runtime copies](validation/unitframe-combat-client-copies-2026-11-09.json)
match through the existing user sync; other installations were read-only. Native pixels,
secure-VM/taint, hardware clicks and matched performance remain **NOT RUN** on
all five clients. No game input, foreground/mouse/keyboard/clipboard control,
settings/profiler writes, manual client sync or publication occurred.

After `/reload` outside combat, verify on each available client: clear the target,
enter normal combat and acquire a target, then right-click its frame; repeat
clear/acquire, menu opt-out, native click casting and modified Flux bindings.
Set/clear focus with an existing native binding/macro during combat while focus
has a target; inspect the narrow strip immediately and after combat. Repeat on
all party targets during ordinary join/leave and target changes. Gain/consume/
expire shields at low/full HP, verify overflow and heal-absorb direction, toggle
absorbs outside combat and check death/offline/rebind plus BugTabs/taint.
Compare matched screenshots and optional performance captures separately.

## Focus colors — 9 November follow-up

FOCUS-TARGET-COLORS-20261109: the user reported focus inheriting the player's
colors. Compact focus intentionally reuses party geometry, but its PaintChrome
route also inherited partyClassColor and the global player accent. Delegate its
chrome paint to the existing target/focus UpdateBorderColors owner, and keep
portrait restoration on that same unit-specific path. Tint the compact divider
from the target palette too. The focused unit supplies the class identity;
Forever NPCs retain native gold and other NPCs the existing untinted target
palette. A different-class player target and focus can correctly differ.
All ordinary party colors and focus layout, HP/resource fill art, aura behavior,
combat portrait red, focus gating, settings and bindings are preserved.

No new native API, frame, hook, event, timer or polling is introduced. The
[existing five pinned source contracts](validation/unitframe-combat-upstream-2026-11-09.json)
remain applicable. The external [2382-file/history checkpoint](validation/focus-target-colors-checkpoint-2026-11-09.json)
passed ZIP CRC and bundle verification before editing; 120 on-disk settings
metadata entries were inspected without edits. Unsaved game memory is excluded.
Two production owners changed: Shared and Party; exact baseline/candidate hashes
and five alternating rejecting/passing pairs are in the [comparison](validation/focus-target-colors-comparison-2026-11-09.json).

`lua tests/focus_target_colors.lua` passes 21,985 assertions across five client
models, three global accents, both party class-color choices, multiple classes,
NPCs, opaque class tokens and repeated combat/restoration transitions. It loads
the actual target color helpers, compact routing and portrait restoration;
asserts border/backdrop/cast/threat/divider equality against target for the same
unit type; and verifies no player-class query. Baseline fails the first focus/
target portrait-color comparison. `unit_portrait_combat_restore.lua` retains
66 checks with updated focus class restoration. All [ten installed runtime copies](validation/focus-target-colors-client-copies-2026-11-09.json)
match via existing user sync; this task only read the other installations.
All 268 scripts and 935 syntax files PASS in the [full-suite report](validation/focus-target-colors-full-2026-11-09.json);
the [source guard](validation/focus-target-colors-source-guard-2026-11-09.json) confirms no Lua source drift.

Native visual/taint/performance acceptance remains pending; the established
UIForever preference is retained and no connected client/simulator tool is
available. No game input, foreground/mouse/keyboard/clipboard control, profiler/
settings writes, manual sync or publication occurred. After an out-of-combat
reload, focus and target the same player/NPC and compare all chrome colors;
change to a different-class focus, cycle combat portrait red and verify its
normal palette returns. Repeat with Appearance custom/class/atlas and party
class-color settings. Native CPU/FPS and matched screenshot claims are not made.
