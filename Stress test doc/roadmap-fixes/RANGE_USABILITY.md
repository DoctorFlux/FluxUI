# Range, usability and darkening

The complete shared range service and both active painters are exercised by
[the permanent regression](../../tests/range_usability_stress.lua). The dormant
legacy Usability module is not substituted for the active Extra paint path.

| Corrected boundary | Result |
|---|---|
| Invalidation within the same GetTime frame | A changed unit/state can obtain a fresh answer immediately. |
| Rapid mouseover invalidation | Only that unit's memo expires; 1,000 mouseover events retain an unchanged target answer. Cached records are reused. |
| Friendly item range unavailable in combat | Keep an established result only for the same item, unit token and observed unit revision. A new action/target cannot inherit old red. |
| Macro target versus stale hovercast unit | Explicit macro units win; ordinary macros do not accidentally inherit the widget through Lua's `and nil or` idiom. Native utility faces retain their own widget unit. |
| Native per-slot target range event | The target-only payload cannot overwrite a face measured against mouseover/focus. |
| Temporarily unknown usability after changing action | Last-known usability and mana state belong to the selected action, rather than the previous modifier face. |
| Unknown bar usability after range red clears | The independent usable/mana/dim layer is restored instead of keeping stale red. |
| Continuous cursor storm | The shared ticker retains bounded catch-up; per-host demand cannot bypass it or clear red merely because the cursor is moving. |
| Range/usability repaint while a key is held | Painters supply public base RGB to PushPress; the existing pressed factor follows the latest palette and release restores that palette. |

The original palette remains: usable `(1,1,1)`, range `(0.8,0.1,0.1)`,
mana `(0.5,0.5,1)`, unusable `(0.4,0.4,0.4)`. Existing precedence and rank
desaturation remain; conjured-item death/count behavior, charges, equipped
trinkets, consumable counts and utility face selection retain their separate
existing regressions. No assets, sizes, fonts or saved variables were changed.

Three repeated runs each pass **86,872 assertions**, including **540,672 modeled
key-state changes through production Modifier**. There are four requested
client models, all eight masks, overlapping same-frame presses/releases and
world/party/dungeon/raid plus combat state inputs. These are API boundary models,
not hardware or native instance execution. A ten-second continuous mouseover
stream performs 19 real shared-ticker sweeps per client model and parks when
the target disappears. Unchanged palettes issue no additional vertex-color
writes, and 64 same-frame consumers share a range probe.

[Raw repeated evidence and baseline rejections](root-results.json) retain exact
consumed hashes. The captured baseline fails these new acceptance tests; the
candidate passes. The primary native target-event contract is pinned in
[source-pins.json](source-pins.json). Real secret values, secure execution,
native pixels and CPU/FPS remain pending native validation.
