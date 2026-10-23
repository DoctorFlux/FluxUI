# Fix priorities and source-backed reproductions

This chapter separates confirmed logic defects, intentional behavior that needs a policy decision, and risks requiring live evidence. The reproductions below used isolated Lua 5.1 API fixtures. They establish selected control flow, not live game behavior; the local simulator is not included in this repository.

## Recommended order

| Priority | Finding and concrete impact | Classification | Fix direction to review |
|---|---|---|---|
| 1 | Changing F5 can cause the next post-login check to reapply all template bindings and CVars, removing unrelated custom keys and saving the set. | Confirmed destructive false positive in a recovery heuristic. Explicit full-template reset itself is intentional. | Separate initial setup/explicit reset from ordinary verification. Do not infer a global reset from one key. Preserve user changes and consider a backup before an explicit full replacement. |
| 2 | Respec binding failure warns but emits success and clears the load checkpoint. A profile can be only partly restored while completion reports success. | Confirmed logic defect for both callback failure and synchronous noncombat rejection. | Propagate failure or an explicit partial-result state. Keep terminal events consistent with restored sections; decide retry/checkpoint behavior separately. |
| 3 | Baganator's global GUID wrapper returns nil for a non-gear item even when the original API would return its GUID. Other callers see this changed result. | Confirmed API-contract mismatch under the fixture; no specific third-party breakage is claimed. | Preserve the original API's result or move the gear-only optimization to an integration-local query. Keep cache invalidation tests. |
| 4 | The CVar-only recovery branch requires four mismatches but has at most two eligible recommendations among its three listed sentinels. It cannot recover through that branch. | Confirmed unreachable condition. Product policy still needs a decision about automatic recovery. | Resolve recovery policy first, then use an achievable threshold over available recommendations or rely on explicit reset events. |
| 5 | Repeated login/world-entry initialization stacks mirror-timer wrappers. With legacy placement enabled, one show/event runs layout three times after three installs. | Confirmed repeat-install behavior under the legacy timer fixture; live cost/taint not measured. | Make installation idempotent per function/frame while handling replacement frames. Verify native execution separately. |
| Policy | Loading Restock deliberately deletes old VendorAuto/global/snapshot stores. Current Restock, Bank and consumable preset targets survive. | Intentional fresh-start upgrade policy, potentially destructive for preferences saved only in old stores. | Decide whether old-only preferences must migrate or be archived. Do not describe all current Chronoboon targets as lost. |

No runtime fix in this table has been applied. Broad architectural rewrites should follow these small behavioral corrections and their tests, rather than precede them.

## Exact source and reproductions

### Automatic binding overwrite

[FluxDefaultSettings.lua](../FluxDefaultSettings.lua#L2055), `VerifyPostLoginDefaults`, treats `GetBindingAction("F5") ~= "FLUXRELOADUI"` as a reset at lines 2069–2074. The same condition also triggers CVar application at line 2101. The normal login handler schedules verification after the grace period.

[ApplyKeybinds](../FluxDefaultSettings.lua#L1860) collects non-template keys at lines 1912–1922, clears them at lines 1974–1977, and saves the current set at line 1958. This broad behavior is appropriate to an explicitly requested complete template reset; its automatic invocation on a customized F5 is the unsafe detection rule.

The isolated local checks seeds F5 and CTRL-F9 as user bindings, calls the real extracted verification and key-application functions, and observes F5 become Flux reload, CTRL-F9 disappear, and SaveBindings run. All changes affect an in-memory fixture table. A control with the expected F5 and matching recommendations leaves the unrelated key intact.

### False Respec success

[FluxRespec_Apply.lua](../Respec/FluxRespec_Apply.lua#L775), `StepSpellBindings`, handles a false callback at lines 808–816 by warning and calling `FinishSuccess`. Synchronous noncombat failure at lines 825–827 also proceeds through StepDone. [FinishSuccess](../Respec/FluxRespec_Apply.lua#L106) clears state/checkpoint and emits `APPLY_DONE(true, "DONE")`.

`SetStatus` at line 103 is an empty function. The code calls `SetStatus("Load failed.")`, but that does not establish a visible failure label. The real inconsistency is the warning versus the success event.

The isolated local checks executes the actual extracted completion/step bodies with an injected binding API returning callback false, synchronous FAILED, success, and IN_COMBAT. Failure cases report success; the success and combat-pending controls behave as expected. This does not reproduce talent learning, gear movement or native protected execution.

### Shared GUID semantics

[BaganatorCompat/Loader.lua](../BaganatorCompat/Loader.lua#L17), `InstallItemIdentityCache`, replaces `C_Item.GetItemGUID` at line 56. Its class filter at lines 66–73 caches false/returns nil for non-Armor/non-Weapon bag items without calling the original.

The fixture's original API supplies a nonempty GUID for a trade-goods fixture. The wrapper returns nil. An Armor control preserves the GUID, caches repeated reads, invalidates on BAG_UPDATE and forwards non-bag locations. The provided Live/Forever ItemDocumentation snapshots describe GetItemGUID returning a non-nil WOWGUID without this class restriction; their native implementation still is outside the lab.

### Sentinel recovery

[VerifyPostLoginDefaults](../FluxDefaultSettings.lua#L2078) lists showTutorials, autoLootDefault and deselectOnClick. The last has no entry in FLUX_DEFAULTS, while the condition at line 2101 requires at least four counted mismatches. The isolated local checks supplies Blizzard defaults for every listed CVar and keeps F5 correct: zero CVar recovery calls occur. This expectation tests the existing recovery intent; it does not decide whether Flux should automatically overwrite a deliberate CVar change.

The four supplied Blizzard SettingsPanel snapshots expose official Settings.Defaulted and Settings.CategoryDefaulted events. Those explicit reset signals are stronger evidence than a single user binding, though a product decision is still needed about reapplying Flux packs after a Blizzard reset.

### Repeated hooks and legacy cleanup

[FluxDurationBars.lua](../Other/FluxDurationBars.lua#L45), `HookMirrorTimerEvents`, wraps the current global show function and current frame OnEvent without installation guards. Both login and world entry call initialization. Under placement 1, the isolated local checks triggers login plus two world entries, then observes three repositions per show and three per frame event. Native callbacks themselves run once. Placement 2 is a control that suppresses layout work. The fixture uses legacy timer contracts; modern clients can provide different native timer UI.

[FluxRestockSettings.lua](../Inventory/Restock/Core/FluxRestockSettings.lua#L99), `DropLegacyStores`, runs from ADDON_LOADED. The isolated local checks loads the full current module and fires that event with legacy-only and current stores populated. Old stores disappear while current Restock target 3, current Bank state and consumable preset target 7 survive. [Consumables.lua](../ExtraButtonSystem/NonCombatGrid/Buttons/Consumables.lua#L1045) prefers active preset targets and can recreate/dual-write legacy VendorAuto fields, so a universal current-target-loss claim would be wrong.
