# Blizzard window movement and scaling

`Flux.WindowMover` lets eligible game panels remember a position/scale. It is independent of HUD Layout: action bars, unit frames, minimap, chat, loot/HUD anchors and the unified envelope have their own placement logic. [Init.lua](../WindowMover/Init.lua) registers the module and `/fluxwindows`.

## Catalog, resolution and exclusions

[Catalog.lua](../WindowMover/Catalog.lua) lists candidate frames with client masks, title/frame drag policy, optional addon requirements and special setup/dynamic-size flags. Shared candidates include Character, Inspect, merchant, quest, mail, trade, professions, map, collections, PvP and many dialogs. Classic and modern lists supply their own spellbook/talent/auction/settings/housing candidates. Baganator views are candidates when Baganator exists; native bag rows then skip.

[Resolve.lua](../WindowMover/Resolve.lua) resolves dotted globals such as `HouseEditorFrame.StoragePanel`, validates frame-like objects and finds suitable title/drag handles. Catalog presence does not assert that a particular client currently instantiated the window. `Scan()` retries after addons/entering world plus delayed startup passes.

The blacklist excludes dangerous/global popup/menu frames, HUD systems and named external panels. `FluxCombinedBags` is an explicit permitted panel despite most Flux HUD frames being excluded. Leatrix Maps suppresses the WorldMap candidate. **The current `ShouldSkip` guard skips every catalog entry in Forever gamepad UI**, not just bags; mouse UI follows the normal path. This is an implemented compatibility restriction.

## Interaction and engine

[Engine.lua](../WindowMover/Engine.lua) uses a high-level movable **proxy**, not `StartMoving` on the actual Blizzard panel. Left-drag moves, right-drag scales and middle-click resets the selected panel. Optional SHIFT/CTRL/ALT requirements and lock prevent unintended interactions. Title strips are added only when usable drag handles are missing; clickable buttons/edit boxes/sliders/scroll regions are excluded from accidental drag capture.

During an active gesture a demand-driven driver samples safe cursor coordinates and updates the target. Position is expressed as UIParent bottom-left `x,y`; scale is clamped to 0.5–2.5 and rounded for storage. Snap and screen clamp apply when requested. Plain-number checks reject secret, inaccessible, NaN and infinite coordinates rather than comparing unsafe values.

`Attach(entry)` records frame/spec, hooks permitted handles and layout changes, then applies remembered geometry. `Apply(name, frame)` merges session and saved records, checks suppression/enable policy and applies safe position/scale. `Refresh()` stops active drag, reapplies attached frames and rescans. Disabled saving still retains live session placement until reload; it is not the same as disabling movement.

Dynamic-size windows, notably Forever's growing bag-bank layout, avoid fixed sizing and scale enforcement that would fight the native panel. Position management only leaves the native panel system after an actual stored point exists. Maximized windows cap excessive scale. Edit Mode postpones reconciliation through shared helpers; combat queues per-frame apply work. Drag ends if the target vanishes.

The implementation deliberately avoids OnHide hooks, because native panel hide/gamepad interaction can taint through them. Forever CharacterFrame additionally skips **OnShow, SetPoint and SetScale hooks**: its native open path compares restricted health after layout callbacks run. Saved layout now reapplies through the independent `FluxInfoFrame.AfterCharacterShown` watcher, not a native layout hook. A combat callback queues `windowmover.apply.CharacterFrame` and applies safely after combat. These restrictions are part of the mechanism, not missing cosmetic options; the catalog's separate Forever gamepad exclusion still applies.

## Persistence and settings

`FluxOptions:GetWindowMoverDB()` selects `FluxUI_Options` profile or character `windowMover`. Its **Windows scope is independent of General/Layout**; scope transitions copy the intended fields. Each `frames[name]` record contains optional `x,y,scale`. Runtime `attached`, `suppressed`, `session` and active proxy state are not persisted objects.

Defaults enable mover/scaling/position save/scale save and screen clamp, leave modifier requirement off, use SHIFT if required, disable snap and start unlocked. Controls expose these flags, scope, lock and reset; [options](26-options-map.md) is the exact catalog. `ResetFrame(name)` removes a panel's remembered state and safely resets scale; `ResetAll()` clears mover records. Reopen panels to let Blizzard restore their default placement. This differs from resetting all addon settings.

## Commands and checks

`/fluxwindows` prints status. Subcommands are `lock`, `unlock`, `reset`, `scan`, `smoke` and `help`. `AttachedCount()` and `Smoke()` expose attachment checks. Scan counts reflect successfully attached/current candidates, not proof every catalog entry exists on the client.

The new [character-combat smoke](../WindowMover/_tmp_charactercombatsmoke.lua) runs real mover attachment/layout code with mocked frame hooks. It confirms Forever CharacterFrame leaves native show/hide/SetPoint/SetScale unhooked, registers post-open layout recovery, defers writes during combat and restores them afterward; non-Forever retains its normal hooks. Its gamepad scenario bypasses catalog filtering to test engine isolation, not production gamepad availability. This harness passed during the audit and explicitly does not model WoW's secure execution VM.

In-game checks: Character drag and reload persistence; merchant restock-tab clicks; title drag vs world-map pan; native/Baganator bags; scale/reset/scope/save-off behavior; screen clamp and UI scale; load-on-demand Settings/Player Spells/housing; character open/close and pending changes through combat; dynamic bank growth; and Forever mouse/gamepad mode changes. The smoke command/tests check implementation invariants, not native protected execution or taint propagation. See [verification](41-verification.md).

## Disabled lifecycle correction

BUG-004/PERF-003 (`19c40a0`) makes Scan return zero before catalog/native hook work
when Windows is disabled. Refresh sleeps/resumes the existing Player Spells watcher;
both public SetEnabled outcomes call Refresh, so disable also stops an active gesture.
Re-enable through options discovers panels and restores saved geometry. Existing
permanent hooks and startup event/delayed callbacks remain guarded; saved records
are retained. [Evidence](WINDOW_MOVER_LIFECYCLE.md): 220 focused checks/100 cycles and
85 full-suite scripts/726 syntax files pass. Native screenshots/input/combat/taint
and performance remain pending.
