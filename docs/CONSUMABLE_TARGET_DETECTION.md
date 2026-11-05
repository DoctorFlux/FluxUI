# Configured consumable targets — 5 November 2026

The refresh countdown now stops at the configured threshold. See
[CONSUMABLE_REFRESH_TIMER.md](CONSUMABLE_REFRESH_TIMER.md) for the timer rule
and validation.

Native follow-up: the user supplied a charge-scan exception while opening the
config with an open bank. The restock bank iterator mismatch and its correction
are recorded in [RESTOCK_CHARGE_BANK_ITERATOR.md](RESTOCK_CHARGE_BANK_ITERATOR.md).

## Config visibility follow-up — 5 November 2026

The Retail and Forever config report exposed two editor failure paths. A dropped
item with an uncached name was never saved until a one-shot metadata retry
succeeded; if it did not, the item stayed absent from the preset. Also,
`RefreshUI` updated the live button before rebuilding the saved grid, so any
button update error stopped rendering every configured entry. The editor now
saves a valid cursor item ID immediately, requests metadata for later icon/name
display, rebuilds the saved grid before updating the button, and shows the
window before refreshing it. Saved entries remain listed even when their
effective usable count is zero because of weapon compatibility.

Baseline main `437fda79136582282dde0f3989f3cb70c4411bad` and a verified
external `FluxUI-consumable-config-prechange-20261105.bundle` preserve history.
External worktree/settings archives preserve 22 then-current unrelated edits
and four on-disk `_FluxUI.lua` settings files; no private settings or archives
are in AddOns. Baseline/candidate config source SHA256 values are
`751ef9e986d3a4d363dac4e539054d27ca42a6c4f1251ab40626e34e959ee63e`
and `6a5620341e7794e454b64dc317a7680d03cdd336cdafc02d47e4d5fb8806ea98`.
Five paired desktop fixtures reproduce the old missing-entry behavior and pass
the candidate with eight checks per run; the full desktop validation passes
148 scripts and 803 Lua syntax files. [Comparison and exact hashes](validation/consumable-config-visibility-comparison-2026-11-05.json);
[full validation](validation/consumable-config-visibility-2026-11-05.json).
These mocks establish editor control flow and persistence only. Native Retail,
Forever, Era, Anniversary, and progression checks remain pending: add a cold
item, reload, switch presets, try an incompatible weapon enchant, and inspect
the saved grid, tooltip, errors, secure click, and visual layout. No native
performance or pixel result is inferred from desktop tests.

## Contract and change

| ID | Requirement | Implementation |
| --- | --- | --- |
| CTD-01 | Identify a configured flask, elixir, Well Fed food, or temporary weapon enchant. | Existing weapon-enchant and Well Fed detection remain; the button and config tooltips now label detected categories. Flask/elixir labels use the item name. |
| CTD-02 | Determine a weapon enchant's target type and next equipped slot. | Parse target/restriction wording from the existing item tooltip service; compare equipped weapon class/subclass from `C_Item.GetItemInfoInstant` (legacy global fallback). Keep the existing main-hand/off-hand/ranged target priority. |
| CTD-03 | Treat a staff-only coating as unavailable with a dagger or sword, even when carried. | `GetItemCount` reports zero available charges when no equipped slot matches. `GetPhysicalItemCount` retains the actual carried quantity for restock and explanation. The selector and secure macro use the same compatibility check. |
| CTD-04 | React to weapon swaps without changing protected actions in combat. | `PLAYER_EQUIPMENT_CHANGED` refreshes relevant slots immediately out of combat and queues an update in combat. Existing post-combat application remains the owner. |

Before this change, `CanEnchantApplyToSlot` treated any melee weapon as compatible with every coating. A staff-only item's tooltip could say staff while the selector counted its charges and built a dagger-target macro. The focused baseline reproduces both wrong decisions. The new rule requires subclass 10 for that item; a dagger (15) or sword (7/8) reports zero available charges. A compatible staff in either hand restores the count and selects that slot. A general oil retains the established melee behavior. A missing weapon or unreadable required subclass fails closed until item data or equipment changes.

The button's item list, preset order, refresh threshold, Well Fed equivalence, wisp lock, commands, restock data, and secure click cadence are preserved. A coating without a current target no longer falls back to a plain `/use` action. The tooltip distinguishes available charges from physically carried charges and shows the detected target type and next slot. No saved-variable migration is needed.

## Source and recovery

- Baseline main: `a6cc94d7d1ed584cbfea4cba0392c7efabdf7686`. Baseline `Consumables.lua` SHA256: `1dfe7689915f4416e2463a651d1167c7c0060f44b8a7d539af745f178045419f`.
- Candidate `Consumables.lua` SHA256: `b4d5100232a8e1e0f86d72145c44faa3e7ef2d9d5ed7ea76a2b1fa551c5586f4`; `ConsumablesConfig.lua`: `751ef9e986d3a4d363dac4e539054d27ca42a6c4f1251ab40626e34e959ee63e`; focused fixture: `3abefb0e1e87c5f3272f928ed92756ed9b515de24dae8d7f84787c5028a812e8`.
- A verified `FluxUI-consumable-targets-prechange-20261105.bundle` and copies of the account and relevant character `_FluxUI.lua` settings are outside AddOns and Git, under `C:\Users\mario\.codex\visualizations\2026\11\05\01a1abaa-ae01-75c3-bb94-d6662d0a7a1f`. WoW processes were absent when settings were copied. The earlier dated `Hidden-inventory-work-20261105T121000Z` checkpoint and its archive hash remain documented in [HIDDEN_INVENTORY_WORK.md](HIDDEN_INVENTORY_WORK.md).
- API research used the packaged Gethe source snapshots pinned to Retail `d07eb00237d8891f153215db98a5df880a26cfe5`, Forever `aff0d8cd53bf4d9ef1c1dd2786b94461a276fb16`, and Classic progression `e5d9b3a22c3f0f6f41ebac0e454f4969594261cf`. Their generated declarations include `C_Item.GetItemInfoInstant`, `C_Item.GetItemSpell`, and the weapon subclass values used here. These are source declarations, not runtime certification. The current moving branches could not be resolved through the available web endpoint. [Retail item API](https://github.com/Gethe/wow-ui-source/blob/d07eb00237d8891f153215db98a5df880a26cfe5/Interface/AddOns/Blizzard_APIDocumentationGenerated/ItemDocumentation.lua), [Forever item API](https://github.com/Gethe/wow-ui-source/blob/aff0d8cd53bf4d9ef1c1dd2786b94461a276fb16/Interface/AddOns/Blizzard_APIDocumentationGenerated/ItemDocumentation.lua), [Classic item API](https://github.com/Gethe/wow-ui-source/blob/e5d9b3a22c3f0f6f41ebac0e454f4969594261cf/Interface/AddOns/Blizzard_APIDocumentationGenerated/ItemDocumentation.lua).

## Desktop evidence and native limits

Five fresh baseline/candidate pairs reproduce the baseline dagger target and pass the candidate fixture with zero outcome variation. The candidate fixture checks 30 cases: physical/effective counts, listed and unlisted staff coatings, staff/sword/dagger/off-hand selection, general oil, flask/elixir/food labels, cache reuse, equipment refresh and combat deferral. [Raw pairs and exact hashes](validation/consumable-weapon-targets-comparison-2026-11-05.json). The full [desktop validation](validation/consumable-weapon-targets-2026-11-05.json) passes 134 scripts and 789 Lua syntax files. Harness wall times are process timings, not addon CPU or FPS.

Native acceptance remains pending for Retail, Forever, Era, Anniversary, and supported Classic progression packages. On each available client, use a real staff-restricted coating with a dagger/sword, then a staff in main hand and off hand; verify count zero/restore, tooltip category/type/next target, the correct secure click and no popup or taint. Repeat with a general oil and with flask, elixir and Well Fed food, including depletion, bag moves, equipment swaps in combat and after combat, reload, non-English locales, and unreadable item data. Capture build, addon list, profile, UI scale, profiler preferences, pixels, errors and matched frame time before any performance claim.

The parser recognizes explicit English weapon-type wording in item tooltips. When a tooltip omits the restriction or uses unrecognized wording/localization, it reports that no specific type was detected and retains the existing melee rule; it does not prove universal compatibility. Client cursor-target APIs are not used as a passive pre-click compatibility oracle. Native item-specific results must decide whether any further mappings or localized rules are required.
