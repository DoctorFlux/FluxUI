# Remaining test failure resolution — 23 October 2026

Both remaining failing scripts now pass. The full desktop suite passes **44 of 44 scripts**; all **681 Lua files** pass syntax checking. Four regression scripts supplement the existing suite. No script was skipped or marked as an expected failure.

The [before capture](validation/before-test-failure-resolution-2026-10-23.json) preserves the 38/40 result, including Bars' 26 failed source assertions and Core's missing-atlas assertion. The [final capture](validation/startup-2026-10-23.json) records every result and normalized Lua hash. Existing working-tree changes were retained; no player SavedVariables or running-game bindings were modified.

## Runtime corrections

| Defect | Correction and preserved behavior |
|---|---|
| Salvage assumed the proc atlas existed when native shine was unavailable. | [Overlay](../Salvage/FluxSalvage_Overlay.lua) probes atlas support and reuses its texture as a translucent family-colored fill if unavailable or unusable. Native shine and supported flipbook animation retain their existing behavior. Secure actions, modifiers, item positioning and gear protection remain intact. |
| Native boolean alpha returned before invisible MT/MA minis synchronized mouse interaction. | [MiniAlpha](../RaidFrame/FluxRaidUnit.lua) continues to the existing combat-guarded mouse update after native alpha. Failed native alpha uses the existing readable fallback. Protected mouse changes still wait out of combat. |
| Dirty hosts caused independently requested paint lanes on other hosts to be discarded. | [Paint.Flush](../Bars/Paint.lua) updates dirty hosts once, then sends coalesced lanes to the remaining hosts. Dirty-only passes stay narrow; empty main buttons still paint their keys. |
| Form settling cleared held companion events without replaying all requested lanes. | [Watch](../Bars/Watch.lua) snapshots and clears held icon, cooldown, usable, checked and count requests, then replays them once, including quiet settles. Existing Context routing and one shared Extra-face refresh are preserved. |

These restore intended behavior without adding/removing options, changing saved preferences, resetting bindings or simplifying client-specific features.

## Coverage mapping

Core's original missing-atlas assertion is unchanged. Bars' obsolete checks depended on file location, local variable names, fixed-length source slices, old full repaint calls or square geometry. Their replacements execute the current production paths. The helper fails if a fixture cannot load, errors, or does not return the required coverage key; it caches each result only within that smoke invocation. All other smoke checks remain active.

| Original Bars assertions | Executable coverage |
|---|---|
| Blanket ban on clearing press-and-hold | Real State snippet distinguishes wrapped hosts, Forever hosts and hidden key proxies. |
| Raid tooltip guard and invisible-mini mouse behavior | Relocated tooltip delegation, missing tokens, native/legacy/failed/secret alpha, combat and recovery. |
| Three vehicle refresh token strings | Real vehicle routing updates count, cooldown, equipped and companion lanes; protected queue waits for regen and preserves native fallback/Forever collectors. |
| Classic-only stance parenting | Actual client/capability policy, including Forever fallback and secure paging combinations. |
| `watch` / `healthBits` rejected by identifier whitelist | Actual frame identity for six script-owner sites; native frames reject `SetScript`. Queued settings work remains combat-safe and flushes once. |
| Form/page promotion restamping | Production State and Watch behavior for promoted minirows and temporary control pages, preserving any-state occupancy. |
| Burst/settle repaint, Context force strings and shared Extra translation | Actual Watch, FormStorm, Context and ProgramFace dispatch; held events, unchanged fingerprints and fallback routes; one refresh rather than duplicate translation/layout. |
| Two icon event registration strings | Actual spell/icon event delivery reaches the appropriate display owners. |
| Ban on question-mark badge fallback | Existing unresolved/unlearned occupied corner remains visible, then adopts the resolved icon. |
| SpellFX comment and square stance dimensions | Native 44px authored VFX, per-axis squeeze, persistent SlotFrame size and repeat stability. |

The new scripts are [bars_contract_regression.lua](../tests/bars_contract_regression.lua), [bars_refresh_regression.lua](../tests/bars_refresh_regression.lua), [blizzard_script_ownership.lua](../tests/blizzard_script_ownership.lua) and [salvage_overlay.lua](../tests/salvage_overlay.lua). Their mutation controls reject **37 deliberately introduced regressions**: 19 refresh/promotion, nine contract, six ownership and three Salvage. Each requires the intended assertion to fail, so a syntax/mock error cannot count as successful regression detection. Five-client fixtures cover Live, Era, Anniversary, progression Classic and Forever policies; the refresh fixture also distinguishes secure/insecure paging and Context/fallback routes.

## Validation and limits

Run from the addon root:

```text
python -B tests/run_validation.py --output docs/validation/startup-2026-10-23.json --sync-docs
python -B docs/tools/build_reference.py
python -B docs/tools/validate_docs.py
git -c core.safecrlf=false diff --check
```

The full run includes syntax, smoke, lifecycle, migration, combat-deferral and compatibility fixtures, including both repaired smoke scripts. Generated documentation/source evidence and whitespace checks pass. Lua 5.4.6 was used; luacheck is not installed.

These are desktop mocks and source checks. Real secret values, secure VM/taint, hardware input, native rendering and performance still require the five-client scenarios in the [startup report](43-startup-optimization.md#client-source-checks-and-required-game-acceptance). No in-game test or performance improvement is claimed here.
