# Fast Shift / Ctrl / Alt: active Extra and badge consumers

The additional consumer stress tests found no new selection defect within their stated models. They execute current active addon functions for saved utility faces, badges and VFX, beyond testing the modifier bus alone. No addon code, existing tests, TOCs, settings or game state were edited.

| Harness | Assertions per run | Raw consumer events per run | Actual behavior checked |
|---|---:|---:|---|
| `utility_matrix.lua.txt` |808,984|126,045|Complete Assign/Manager/Action/Paint/Charges/HotkeyUtil/Modifier; eight distinct spell/item assignments; prepared physical chord attributes; reagent/stack/charge digits; main timer and charge edge; dynamic hotkey; hidden/reappearing and reassigned host. |
| `vfx_matrix.lua.txt` |546,065|176,470|Complete Cast/Action/Paint/Manager/Modifier; cast, channel, empower, reticle, finish burst, interrupt and proc on current spell/item use-spell identity. |
| `badge_matrix.lua.txt` |153,579|25,260|Complete BadgeHost/Action/Paint/Modifier; conditional reverse faces, count/cooldown, primary/secondary row movement, dormant-row activation in combat, clear/re-enable and pooled badge reuse. |
| **Total** |**1,508,628**|**327,775**|Five labeled client models; events repeat the bounded patterns below. |

[results.json](results.json) contains three deterministic repetitions:9 successful script executions,4,525,884 assertions and983,325 raw consumer-event deliveries across the repeats. These are repeated traces, not983,325 distinct scenarios. Seventeen consumed source/fixture/harness/runner raw hashes match before and after. The results are additional to the parent audit's earlier test counts.

## Input traces and delivery boundaries

Every harness exercises no modifiers plus all seven held combinations of Shift/Ctrl/Alt. Eleven physical-state sequences cover single-key taps, both press orders for every pair, partial releases, representative opposite triple-key press/release orders, and full release back to the normal face. These run both in and out of modeled combat. Every delivered state receives a duplicate event. Further bursts deliver all intermediate states before one modifier-bus update and check the actual final held state after the delivery boundary.

The utility matrix uses eight distinct saved spell/item identities, rather than expecting one repeated face to prove every chord. It checks prepared `type1`/`spell1`/`item1` attributes against the independently selected chord, verifies the final icon and live reagent/stack/charge digit, executes the complete Charges module against cooldown-frame boundary objects, and checks that charge edges disappear when leaving charged spells. Counts and cooldown duration remain correct through partial and full releases. Stale aura-duration, forced-count, pet and outfit ownership fields are rejected. Actual hotkey output retains its intended S-/C-/A- prefix and returns to F6 after release.

Native timer callbacks are explicitly drained for the hotkey helper's existing delayed refresh. The hotkey assertion establishes the final display after that delivery; it does not claim that a0.05-second hotkey refresh becomes instantaneous. The ordinary physical secure action is checked as prepared attributes; native button execution and press/release security belong to the separate Binding/Click audit.

The VFX matrix runs seven separately booted phases against five clients. Matching spell faces and items with a matching use-spell retain/restore the relevant effect; unrelated items/spells clear it. Duplicate events add no `Cast.FollowExtra` call. A hidden owner changes face, then becomes visible and receives a genuine modifier release; that release restores only the matching live effect. This is not a claim about arbitrary native OnShow delivery without a subsequent identity event. Existing independent strip and pet fixture owners remain present.

The badge matrix first moves a previously dormant row into use while combat is active, before any public row warm-up. The real BadgeHost publishes its visual face/count/cooldown without calling the modeled protected `SetAction`. It then prepares both used rows outside combat and stresses their unchanged conditional macro. All old-row badges remain hidden at alpha0 with their owner hidden flag, while the active row has exactly one visible badge with the correct final face. Clearing and re-enabling the same badge assignment reuses all nine initially created badge instances.

## Work and allocation evidence

Per client in the utility matrix:25,209 raw events settle into17,009 modifier delivery boundaries, including8,400 explicitly duplicated states. Icon/count/usable/checked calls are8,410/8,412/9,815/8,412. Actual numeric main cooldown setters run5,610 times; duplicate events do not restart an identical timer. No additional production `CreateFrame` calls or protected writes occur during the modifier stress. Reassigning the same host occurs outside combat and retains its prepared chord identities and hotkey.

Per client and VFX phase:5,042 raw events,3,402 delivery boundaries and1,680 duplicate states. Each phase makes1,604 `FollowExtra` calls, with zero additional frames, modifier-created timers or secure writes. Starting an interrupt phase intentionally allocates one existing cleanup timer; that event-start timer is counted separately and was not misclassified as modifier churn.

Per client in the badge matrix:5,052 raw events settle into3,412 delivery boundaries. Nine badge factory calls occur during setup, with no further badge/frame creation and no stable-body `SetAction` after public preparation. Icon/count/cooldown passes each total20,474. The fixture explicitly bridges the modifier callback to `NotifyModifierPaging` and `RefreshDisplays`; its paint count describes those actual consumer calls, not an observed native Bars/Context callback frequency. Performance-agent work covers actual Bars State/Watch and hotkey coalescing separately.

“No frame creation” does not mean zero Lua allocation: native frame and badge-pool counts are checked, while ordinary Lua tables, option payloads and strings are not counted as native allocations. These operation counts do not establish native CPU/FPS or frame-time savings.

## Exact scope

The harnesses extend the current `tests/utility_mixed_faces.lua` and `tests/utility_modifier_vfx.lua` fixtures by reading their setup code directly. The selected production modules execute; implementation logic is not copied into a second action engine. Native modifier queries, conditional parsing, frame objects, clocks and renderer APIs remain models. Badge creation/geometry/alpha setters and Overlay/Glow rendering are modeled boundaries; the complete BadgeHost/Action/Paint selection functions execute.

The five labels cover Retail live, Forever, Era, Anniversary and progression. Native key-state masking, secret values, protected-frame permissions, input delivery, animation pixels, actual timer scheduling, taint provenance and FPS remain unverified. The explicit badge bridge also does not prove that the parent audit's separately reproduced Context quiet-deadline issue is resolved. Dungeon/raid and mouseover delivery matrices remain in their respective parent audit slices.

No new finding ID or runtime fix is added from this follow-up. Previously reported R2-EBS findings retain their existing qualifications. Replay from the addon root:

```powershell
python "Stress test doc/round-2/extra-buttons/modifier-followup/run_followup.py"
```
