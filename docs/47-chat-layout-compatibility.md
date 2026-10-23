# Chat layout compatibility — 23 October 2026

The earlier startup optimization exposed a pre-existing chat pinning defect. Era and Anniversary retained the first beside-chat rectangle indefinitely, even when squeeze, action-strip and micromenu dimensions changed later. They also skipped the shared vertical alignment. All clients ignored explicit changes inside a 24-unit tolerance, even with a forced refresh.

[FluxChatFrame.lua](../Other/FluxChatFrame.lua) now reconciles the settled, UIParent-anchored menu rectangle on all five clients. Unchanged measurements still avoid frame writes; subpixel noise uses a 0.5-unit tolerance. Explicit refreshes restore native position/size drift. Horizontal and minimap menu layouts, bag-drag holds, settings, channels and saved configuration remain supported. Protected chat geometry waits for combat to end and reconciles once; ordinary permitted display updates continue.

The user confirmed the corrected chat rectangle in the open Era client. Read-only native measurements before and after reload were:

| Rectangle, chat units | Before | Corrected |
|---|---:|---:|
| Left | 84.2 | 87.2 |
| Bottom | 126.8 | 142.1 |
| Width | 223.6 | 404.3 |
| Height | 170.0 | 195.4 |
| Effective scale / UIParent | 1.000 | 1.000 |

These are rounded layout observations, not performance measurements or universal default coordinates. The corrected width follows the current saved squeeze/layout configuration.

## Button column

[FluxChatCopyPaste.lua](../Other/FluxChatCopyPaste.lua) previously raised Era/Anniversary's native strip by a fixed 55 units; progression Classic used tab-top alignment. The first attempted common top alignment was too low for Classic's taller complete stack. That candidate was rejected: the native strip measured 258.6 units high and its Options button extended below the action-strip floor.

The corrected placement starts from the Live/Forever background-top alignment and raises pre-DF columns only as much as their measured full height requires to clear the edit-box floor. Era and Anniversary keep their native button-frame ownership; progression Classic keeps the holder path. Buttons retain their artwork, dimensions, order, labels, toggles and click scripts. Missing background art has a safe fallback. Live/Forever keep their current alignment, and a stale legacy flag cannot opt Forever into Classic fitting.

Column geometry and reparenting defer during combat, including direct native strip hooks. One reusable waiter reconciles pending layout after combat; repeated requests and combat cycles do not allocate additional waiters. Classic social layout also avoids native protected layout during combat.

The final fitted column needs a native reload/height check after synchronization. The prior too-low candidate is not accepted as final native verification.

## Shared free-bag-slot count

The chat bag button previously copied the micromenu FontString. An early backpack-only value could outlive its underlying data: the micromenu relied on inventory snapshot notifications once its listener was registered, while chat reconciled on its own timers. A reload masked the readiness/order dependency.

[Container.lua](../Core/API/Container.lua) now provides one live ordinary-bag total and keyed display subscriptions. It uses Blizzard's C_Container.CalculateTotalNumberOfFreeBagSlots, present in the native API documentation on all five branches. The readable legacy fallback counts only backpack and worn bags, excluding reagent, keyring and bank containers. Native API functions and inventory snapshot semantics are unchanged.

The chat button, micromenu button, Live/Forever owned bag-header counter and Era/Anniversary owned combined-bag counter subscribe to that total. Their tooltips/initial header creation use the same getter. Native Blizzard bag controls keep their own implementation, which uses the same native total API; alternative bag addons retain ownership of their views. Forever's gamepad controls are not altered.

Login/world entry, native bag changes, BAG_UPDATE_DELAYED, bag equipment changes and the player's inventory changes trigger a shared next-frame reconciliation. This works independently of detailed inventory scans and optional inventory providers. New consumers initialize from current data; later readiness events replace a provisional login total without reopening the bag or reloading. If the client has not supplied equipped-bag data yet, no addon can infer that unavailable capacity.

One reusable event frame and at most one pending callback serve all subscribers. Event bursts are coalesced; unchanged totals do not rewrite displays; there is no idle polling or recurring retry timer. Count text and low-space color still update during combat without touching protected geometry.

[bag_free_slots.lua](../tests/bag_free_slots.lua) executes the production core and each display subscription across all five client models. It reproduces backpack-only login followed by native bag readiness, without an inventory snapshot notification or reload. It checks bag swaps, world changes, slot-only changes, full bags, late UI creation, duplicate registrations, observer failures, combat-safe display updates, timerless behavior, native API ownership, reagent/bank exclusion and missing/secret/throwing native totals. A 200-event burst creates one pending callback. Four targeted regressions are rejected. The existing chat timer fixture remains coverage for the older-core compatibility fallback.

## Five-client optimization coverage

The optimization scope continues to include `live`, `classic_era`, `classic_anniversary`, `classic` and `forever`. Existing production-backed fixtures run their common paths across those five models; Forever-only compatibility work remains branch-specific.

| Area | Automated evidence |
|---|---|
| Startup readiness, combat entry and recovery | [startup_lifecycle.lua](../tests/startup_lifecycle.lua), secure/HUD/raid/unit-frame startup fixtures |
| Conditional mouseover and restricted-driver work | [idle_bars.lua](../tests/idle_bars.lua), including native paths on other clients and Forever fallback |
| Unit polling and missing-unit portraits | [idle_units.lua](../tests/idle_units.lua), five branches and timer capabilities |
| Clock, marquee and stat discovery | [idle_hud.lua](../tests/idle_hud.lua), shared paths on five branches and Forever-specific row discovery |
| Embedded map work | [idle_map.lua](../tests/idle_map.lua), five branches |
| Diagnostics with optional native profiling APIs | [perf_capture.lua](../tests/perf_capture.lua), five branches and missing/error/secret results |
| Chat press/bag scheduling | [idle_chat.lua](../tests/idle_chat.lua), shared handlers with Classic/modern shells and native timer behavior |
| Horizontal information layout | [idle_info_layout.lua](../tests/idle_info_layout.lua), branch-independent production layout against retained pre-optimization behavior |
| Chat startup rectangle and button placement | [chat_layout.lua](../tests/chat_layout.lua), [chat_column_layout.lua](../tests/chat_column_layout.lua), five branches |
| Consistent live bag totals and login readiness | [bag_free_slots.lua](../tests/bag_free_slots.lua), four actual display subscriptions across five branches |

The new rectangle fixture checks late dependencies, all menu placements, small explicit changes, unchanged refreshes, native drift, unavailable menu geometry, drag holds, protected combat calls and exactly-once regen reconciliation. The column fixture checks both sides, native/holder ownership, complete tall stacks, safe fallback, stale legacy flags, preserved actions and repeated combat deferral. Eight targeted regressions are rejected across the two new fixtures.

The [full validation record](validation/chat-layout-2026-10-23.json) contains syntax results, per-script output and normalized source hashes. Native observations this turn cover Era chat geometry and the rejected first column candidate. The Era process was no longer available for the final fitted-column and cold-login count check. Fresh login, reconnect, combat/taint acceptance and native verification on the other four clients remain required; passing mocks do not establish those results. No new FPS gain is claimed.

## Native source contracts

Blizzard's current primary chat frame uses its Edit Mode path rather than ordinary floating-window position restoration. The chat implementations and background/strip ownership were checked against [Era](https://github.com/Gethe/wow-ui-source/blob/classic_era/Interface/AddOns/Blizzard_ChatFrameBase/Classic/FloatingChatFrame.lua), [Anniversary](https://github.com/Gethe/wow-ui-source/blob/classic_anniversary/Interface/AddOns/Blizzard_ChatFrameBase/Classic/FloatingChatFrame.lua), [progression Classic](https://github.com/Gethe/wow-ui-source/blob/classic/Interface/AddOns/Blizzard_ChatFrameBase/Classic/FloatingChatFrame.lua), [Live](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_ChatFrameBase/Mainline/FloatingChatFrame.lua) and [Forever](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_ChatFrameBase/Mainline/FloatingChatFrame.lua). No Blizzard API or widget method is globally replaced by this change.
