# Feature inventory and specification reconciliation

Audit date: 29 October 2026. Implementation baseline: `7436820` in the existing `_FluxUI` repository, with original supplied requirements and the sync log preserved in external recovery archives. The current addon is the implementation base. This inventory records requirements and current source; it does not certify native feature or visual parity.

The [parity ledger](FEATURE_PARITY.csv) has 1,384 rows: 308 specification sections, 361 option definitions, 44 factory sites, 519 literal defaults, 80 command registrations/handlers, 25 bindings, 23 SavedVariables roots, 15 integrations and 9 current-only feature groups. It records every nonempty heading section in all 26 supplied specifications. Each row carries its source location, baseline identity, owner, and verification state. Specification rows retain requirements and source-file SHA-256 values, including contradictions and historical methodology. Editorially updated terminology carries both current and archived original hashes. A captured requirement is not an implemented/tested requirement.

The existing reference remains the detailed inventory rather than introducing a second documentation framework:

| Surface | Complete source inventory and behavioral explanation |
|---|---|
| Options, scopes, defaults, reset behavior | [Options map](26-options-map.md), [definition/factory sites](reference/settings-details.md), [literal defaults](reference/defaults.md), [persistence](09-persistence.md) |
| Embedded editors and controls outside ordinary option rows | [Custom widget controls](35-custom-widget-controls.md), covering preview, visibility, utility, stance, favorites, item currency, Info ordering, inventory targets, micro menu, meter, binding and Respec |
| Slash commands, aliases, subcommands and replacement handlers | [Commands and bindings](31-commands-and-bindings.md), [declaration evidence](reference/declarations.md); corrections below take precedence over stale explanatory prose |
| Native binding entries and authored conditional bindings | [Commands and bindings](31-commands-and-bindings.md), [Binding](13-binding-system.md), `Bindings.xml` |
| Saved roots, schema owners and migration/reset distinctions | [SavedVariables](32-saved-variables.md), [persistence](09-persistence.md) |
| Source/load/client gates and callable interfaces | [Source coverage](30-source-coverage.md), [inventory](reference/inventory.json), [API/events](33-api-and-events.md), [interface index](reference/interfaces.md) |
| Optional providers, readiness, ownership and fallback | [Integrations](29-integrations.md), the integration rows below, and `INTEGRATION-*` ledger entries |
| Textures, fonts, sounds, localization and data | [Assets](34-assets.md), [source asset manifest](reference/inventory.json) |

Fresh read-only collection before runtime edits found 755 Lua/XML sources, 577 TOC/XML-reachable files, 361 option-table definitions, 44 option-factory call sites, 519 literal defaults, 46 reachable slash-alias registration sites, and 23 SavedVariables roots. Definitions include groups, headers and descriptions, not just interactive controls. Dynamic factory calls can emit multiple client/unit-specific controls. Alias registration sites include repeated definitions and do not imply 46 distinct effective commands. The companion source indexes must be regenerated after a source change; these counts describe the frozen audit input.

The current extractor classifies `tests/*.lua` as inactive source unless its filename matches the older smoke-harness convention. Therefore an inactive-source count is not proof of dead runtime code. TOC reachability, source declarations and test names also do not establish successful native execution. Custom editors and dynamically generated rows require the behavioral inventory and native walkthrough in addition to lexical extraction.

## Feature and ownership coverage

| Feature family | Behavior retained and primary owner | Supplied requirement |
|---|---|---|
| Product identity | `_FluxUI` folder/TOC/title, shared HUD, settings/profile roots, first-load/reload behavior; Core and all owners | [Overview](../new%20docs/docs/specs/01-product-overview.md) |
| Client adapters and restrictions | Separate Retail, Forever, Era, Anniversary, MoP, retained Cata/Wrath paths; capability and secret-display policies; Core/Client, Core/API and legacy facade | [Clients](../new%20docs/docs/specs/02-multi-client-matrix.md), [Midnight](../new%20docs/docs/specs/03-midnight-constraints.md) |
| Chrome/assets | Accent modes, borders/backdrops, gap fills, fonts/textures, sealed bottom/micro envelopes, live appearance refresh; FluxBorder and Layout | [Visuals](../new%20docs/docs/specs/04-visual-system.md) |
| Defaults and setup | Keyboard template, CVar packs, account/character setup flags, confirmed resets, scale/squeeze; FluxDefaultSettings | [Defaults](../new%20docs/docs/specs/05-defaults-and-bindings.md) |
| Layout | Click-to-place preview; micro/status/player-target/stance/Info placements, columns and independent scope; AddonOptions and Layout | [Layout](../new%20docs/docs/specs/06-layout.md) |
| Flux Window | Docked Map/Meter/Respec/Buttons, tab ordering/enablement, minimap embed, provider pins, multi-pane meter and fallback; Battlezonemap | [Window](../new%20docs/docs/specs/10-flux-window.md) |
| Action bars | Nineteen columns, three layers, promotion/paging, vehicle/possess/override/flight, pet/stance, binding mode, identity-continuous VFX, counts/cooldowns/range; Bars and ButtonFX | [Bars](../new%20docs/docs/specs/11-action-bars.md) |
| Extra buttons | Combat/utility consumables, travel/hearth/mount/conjure helpers, four modifier slots, flyouts/favorites, trinkets/queues, scoped category palettes; ExtraButtonSystem | [Extra buttons](../new%20docs/docs/specs/12-extra-button-system.md) |
| Conditional bindings | Per-character documents, target/form/load/action conditions, multi-cast, chord routing, secure compilation, editor/browser/keyboard view, spellbook hooks, Respec retention; Binding | [Binding](../new%20docs/docs/specs/13-binding-system.md) |
| Unit frames | Player/target/ToT/focus/focus-target/pet/pet-target, native ownership toggles, portraits, auras, prediction/absorbs, resource overlays, class power, threat, cast/swing/flight, spec/transmog actions; UnitFrames | [Unit frames](../new%20docs/docs/specs/14-unit-frames.md) |
| Raid/party | Secure headers/cells, roster/MT layouts, native ownership, private or owned aura paths, range/alpha, highlights, status text and session preview; RaidFrame | [Raid](../new%20docs/docs/specs/15-raid-frames.md) |
| Status/Info | Gold/XP/reputation/PvP, ledger, item currencies, FPS/ping/durability/pinned stats, order and placement; StatusBars | [Status](../new%20docs/docs/specs/16-status-bars.md) |
| Micro navigation | Native actions and bags/macros/config/reload/queue/addon popup, promoted minimap icons, profession layouts, per-row visibility/order; MicroMenu | [Micro menu](../new%20docs/docs/specs/17-micromenu.md) |
| Minimap/trackers | Square map, embed/restore, objective/Questie ownership, buffs/debuffs, minimap buttons and embedded extra grid; Minimap | [Minimap](../new%20docs/docs/specs/18-minimap-and-trackers.md) |
| Nameplates | Threat/target/level/countdown overlays, client gates, native region cooperation and preview exclusions; NamePlates | [Nameplates](../new%20docs/docs/specs/19-nameplates.md) |
| Vendor/bank economy | Repair, bulk buying/confirmation, junk/manual protection/inferior tiers, restock/reagents/targets, bank planning and live execution, bag indicators/known tint; Inventory/Restock | [Vendor](../new%20docs/docs/specs/20-vendor-restock-junk.md) |
| Inventory facts | Built-in versus Syndicator ownership, snapshots, caches, mail/auction/equipment/guild/void/currency facts, alt ledger/tooltips, craft/classification/best-consumable/gear queries; Inventory | [Inventory](../new%20docs/docs/specs/21-inventory-foundation.md) |
| Salvage | Modifier overlay, profession/rank checks, action tables, Forever Comprehend, protected gear exclusion, native/Baganator buttons; Salvage | [Salvage](../new%20docs/docs/specs/22-salvage.md) |
| Respec | Masked profile/preset save/load, talents/runes/gear/bars/consumables/utility/bindings/Info, equipment-set synchronization and protection; Respec | [Respec](../new%20docs/docs/specs/23-respec.md) |
| Baganator views | Junk/protection/set/preset categories, icons/shields/context, guarded category operations and bank-restock control; BaganatorCompat | [Baganator](../new%20docs/docs/specs/24-baganator-compat.md) |
| QoL and native windows | Chat buttons/tabs/copy, trades, tooltip/extra-ability/vehicle/duration/loot anchors, equipment flyouts, Character Info, WindowMover, ConsolePort coexistence; Other/CharacterInfo/WindowMover/ConsoleportCompat | [QoL](../new%20docs/docs/specs/25-other-qol.md) |
| Settings application | Native options shell, scope selectors, independent reset operations, profiles and every custom control; AddonOptions | [Options](../new%20docs/docs/specs/26-options-map.md) |
| References/terminology | Attribution, licenses, reference boundaries and shared terms; source notices and reference manifest | [Inspirations](../new%20docs/docs/specs/90-reference-inspirations.md), [Glossary](../new%20docs/docs/specs/99-glossary.md) |

The supplied [specification README](../new%20docs/docs/specs/00-README.md) is also recorded in the ledger. Its rewrite methodology is historical. The user's current request governs implementation; the feature content remains a requirements source.

## Discrepancies requiring explicit reconciliation

No runtime behavior is changed merely to make it match older prose. Preserve current behavior while product differences are resolved with the user or with a reproduced defect and a focused regression check. D12, D13 and the outdated explanatory prose in D17 were corrected in this batch; the table retains their baseline statements for traceability.

| ID | Supplied or older statement | Current evidence | Disposition |
|---|---|---|---|
| D01 | Spec README: fresh rewrite, discard implementation, backup is only truth. Existing docs README: current source always wins. | User explicitly requests in-place selective modernization and reconciliation of every specification with current behavior. | Both absolute source-precedence rules are superseded by the user; preserve both evidence sources and record differences. |
| D02 | Product/options/QoL specifications expose `/flyout`. | Registration is in `ExtraButtonSystem/Flyout/FluxFlyoutCore.lua`, which is absent from the active TOC closure; loaded implementation uses FlyoutEngine. | Required historical command has no active registration. Do not silently promise it or load the competing old engine. Restoration requires a focused compatibility decision. |
| D03 | Spec options/sidebar has a Frames group, separate Raid, Vendor and Salvage, and Info controls in General. | `AddonOptions/FluxOptionsCatalog.lua` has General/HUD/Tools; Raid is inside Unit Frames, Inventory combines vendor/salvage, and Info has its own page. | Preserve actual navigation and all reachable controls; old layout is not an authorization to redesign. |
| D04 | Spec Status/Options says durability is on by default. | `AddonOptions/FluxOptionsInfo.lua:11` and `StatusBars/FluxInfoFrame.lua` seed `showDurability=false`; owner also contains a one-time migration. | Preserve existing default/migration and stored user preference; document difference, do not force an enable/reset. |
| D05 | Spec Status says up to six item-currency counts. | `StatusBars/FluxItemCurrencyTracking.lua:8` caps the total slot rows at 40; an empty add row is appended only while capacity remains. | Preserve current capacity and item order; cap is not six. |
| D06 | Spec Layout lists three Info placements. | `AddonOptions/FluxLayoutPreviewUI.lua` also supports `screenTopLeft`; Info has status-cell/order controls. | Preserve additive current controls and storage. |
| D07 | Spec Extra/Options lists Single-Button Assistant visibility row and broad Off/Auto/Always modes. | `FluxExtraButtonVisibility.GetOptionsIds` excludes assisted combat; Mana Gem/Class Teleport restrict modes; Food/Water normalize Auto. | Retain current supported rows and normalization; separately track omitted historical row. |
| D08 | Specs say Live has no Flux threat overlay and Forever no level overlay. | `NamePlates/Core.lua:74` permits threat when C_NamePlate exists; IsLevelSupported excludes Live but permits Forever. Later code also modifies native regions despite the opening comment. | Source policy differs from spec; native secret/preview acceptance remains pending. No silent restriction expansion or removal. |
| D09 | Spec Visual says options uses shared accent; spec Options says options stays neutral. | Current shell/border infrastructure themes the options window and selected controls. | Supplied specs conflict internally. Preserve captured current pixels; no restyle. |
| D10 | Spec inventory describes facts only and excludes shipping a competing full bag UI. | `Inventory/Builtin/FluxClassicCombinedBag.lua` is loaded and provides a combined native-button bag window on Era/Anniversary when alternative bags are absent. | Preserve existing combined-bag feature and alternative-bag gating. Do not delete it from the inventory. |
| D11 | Spec defaults describes optional onboarding and suggests never overwriting bindings each login. | `FluxDefaultSettings.lua` has account-first setup, selective new-character setup, explicit reset paths and sentinel recovery; some paths clear/reseed native keys. | Preserve current customized-binding protections. Test before changing setup/migration; old wording is not proof of non-destructive behavior. |
| D12 | `docs/29-integrations.md` lists companions in TOC OptionalDeps. | Actual `_FluxUI.toc` lists only Blizzard_UnitFrame and Blizzard_CompactRaidFrames; Camelot separately depends on Blizzard_CombatLog. Companions are runtime-probed. | Correct documentation, not the manifest. Load order/readiness must be tested explicitly. |
| D13 | `docs/31-commands-and-bindings.md` says `/fluxui bliz` opens native settings. | `FluxOptions:OpenBlizzardOptions` at `AddonOptions/FluxOptions.lua:1588` calls `ShowConfig()`, agreeing with supplied spec. | Correct descriptive reference; preserve actual same-shell behavior. |
| D14 | Historical findings describe global C_Item replacements and destructive legacy-store deletion as current. | Source has newer fixes; historical findings are explicitly dated and must be rechecked against current Baganator/Restock ownership. | Do not reapply historical repairs from prose alone. Current source/tests and focused reproduction decide work. |
| D15 | Source API/classic aliases and old matrix imply the same client family semantics or universal Full support. | New/legacy API facades differ; exact loaded files and runtime capability checks determine actual routes. Original 3.3.5 differs from modern Wrath Classic. | Keep separate client rows and pending native checks. TOC interface declarations are not exact tested build numbers. |
| D16 | All retained source is treated as executable/old source as dead. | TOC/XML reachability, runtime guards, current-only features and test harnesses differ from directory contents. | No deletion based on filename or lexical unused classification. Audit load references and callers first. |
| D17 | `docs/21-inventory-foundation.md` and `docs/29-integrations.md` describe a three-second Syndicator timeout and no takeover after built-in starts. | Current `Inventory/Syndicator/Adapter.lua`, `Adapter.Start`, immediately starts built-in facts while waiting; `Ready` calls `Bind`, which selects Syndicator. `Inventory/Init.lua` also retries on its late addon load. | Preserve current immediate availability and late provider handoff. Audit all built-in callback/timer lanes for stale work after the source changes; no silent timeout restoration. |

Current-only features also remain requirements: cross-client cast-school themes; transmog clear/outfit actions; loading-screen inventory/grid recovery; native spellbook/input ownership; unit-resource watcher/spark reuse; current chat-tab visibility fix; diagnostics; Character Info/WindowMover controls. `CURRENT-*` rows link their owners and existing regression harnesses. This list complements the exhaustive current source/control indexes rather than narrowing the feature scope to the old package.

## Optional integration acceptance

| Integration | Required scenarios; all native checks pending |
|---|---|
| Syndicator | Absent; loaded and ready before Flux; loaded but not ready; late addon load; Ready after built-in facts started; login and late cache events. Verify one provider owns facts, no duplicate tooltip ledger, matching counts, and no stale bank mutation permission. |
| Baganator | Absent and present; ready/late API; normal and cached bank views; existing user categories; Flux junk/protection/preset categories; bank-restock handoff. Verify other categories/configuration survive and shared item APIs remain native. |
| Details/native meter | Details ready/late/absent, no backend, native fallback, rapid tab changes and combat. Verify pane/geometry ownership, hidden-tab work and no duplicate meters. |
| Questie/HBD | Tracker on/off/collapsed, late provider loading, world map open/closed, Flux map/minimap switching, combat and loading screen. Verify correct tracker and pin ownership. |
| BigDebuffs/TacoTip | Present/absent, supported owned/private aura hosts, unit enable/disable, CharacterFrame show/hide. Verify single aura/stat presentation and no lost native interaction. |
| ConsolePort/Clicked/Clique | Present/absent and native keyboard/gamepad modes; hardware key/mouse/wheel activation in and out of combat. Verify intended shared ownership and unchanged unrelated companion actions. |
| SpellActivationOverlay/AlreadyKnown | Present/absent, late readiness, feature disable/re-enable, native/client gates. Verify single feedback/tint owner. |
| Bagnon/Bagnonium/Masque | Alternative bag ownership probe and native fallback; Masque is probe-only unless an actual registration is established. Do not infer a skin integration from detection alone. |

Reference addons such as Bartender4, Button Forge, Clicked, Buffet, Restocker, Scrap, TrinketMenu, ItemRack, classicthreat, MoveAny and EllesmereUI are not automatically runtime dependencies. Version/license/source provenance belongs in the reference manifest before importing additional code or assets.

## Parity procedure

For each changed owner, select its `SPEC-*`, `OPTION-*`, `FACTORY-*`, `DEFAULT-*`, `COMMAND-*`, `BIND-*`, `SAVED-*`, `CURRENT-*` and integration rows. Record a reproduced failure and expected behavior before an intentional bug fix. Attach actual targeted test output; source discovery alone stays `source inventory only`.

Before native comparison, record exact client build, resolution, UI scale, profile/scopes, fonts, game state, installed addon versions and the frozen baseline tree. Capture the baseline and candidate sequentially under the same `_FluxUI` identity. Exercise the same key/mouse/drag/modifier sequence at the same timings, including disabled/hidden states, reload, late providers and combat deferral. Save screenshots and geometry observations, then compare matched images. Repeat with restored settings rather than resetting profiles. Report rendering/input/taint differences separately from desktop mocks and measured CPU/resource changes.

No matched native screenshots or native interaction run was available to this audit. Visual and native ledger fields remain pending. A passing desktop harness may validate the modeled branch only; it cannot certify the WoW secure VM, real secrets, hardware input, native rendering or FPS.

The first implementation batch, **BUG-001 / PERF-001**, affects `INTEGRATION-Syndicator`: built-in currency event callbacks continued to read money, overwrite the shared snapshot and schedule work after Syndicator took ownership. Four provider checks stop that stale work while preserving synchronous built-in behavior before handoff and external cache updates afterward. The [production-source handoff harness](../tests/currency_provider_handoff.lua) runs 150 checks across five client capability models: the baseline fails 50, and the candidate fails none. [Matched operation samples](validation/currency-provider-comparison-2026-10-29.json) show 100 unnecessary money reads and 300/400 requests per 400-event baseline burst becoming zero in the candidate. These are deterministic desktop operation counts; native CPU, timing, rendering and full integration acceptance remain pending.

**BUG-002 / PERF-002**, runtime commit `05e9f79`, prevents queued or partial built-in mail/auction scans from overwriting Syndicator snapshots after Ready. Each scan now checks ownership before its due-time check, clears queued/partial state and detaches OnUpdate; mailbox/auction open state and standalone debounce, final inbox-close capture, retries and scan budgets remain unchanged. The [handoff harness](../tests/deferred_inventory_handoff.lua) passes 210 checks; the `201bc83` baseline fails 42. Five alternating [matched replay pairs](validation/deferred-inventory-comparison-2026-10-29.json) show queued/partial mail reads of 105/56 and legacy/modern auction reads of 71/38 becoming zero, with no stale publication or snapshot generation change. These are mocked API-call counts. The [complete candidate suite](validation/deferred-inventory-full-2026-10-29.json) passes 83 tests and 724 Lua syntax files. `SPEC-21-L3`, `SPEC-21-L9`, `SPEC-21-L23` and `SPEC-21-L50` receive only this targeted partial coverage; native acceptance and other behaviors in those sections remain pending. Snapshot ownership corruption is reproduced; a visible tooltip/Respec defect has not been established.

**BUG-003**, runtime commit `ab4e658a98a7ce3ee6688ac6170e7e0991325af0`, prevents a pending send/return success callback from appending to an external provider's character record after handoff. The existing failure-cleanup branch now also cancels attribution when Syndicator owns the store, clearing the pending payload and all completion-event subscriptions before any destination lookup. The [pending-mail harness](../tests/pending_mail_provider_handoff.lua) passes 410 checks; its `05e9f79` baseline fails 8. Five alternating [matched replay pairs](validation/pending-mail-comparison-2026-10-29.json) show each of four successful send/return cases dropping from one provider lookup, one appended row and three incorrectly credited items to zero; failed-operation controls remain zero. For each action, 100 standalone success/failure cycles retain one reusable frame, zero outstanding completion subscriptions and 50 correct credits. Count variation is zero across the matched runs. The [final complete suite](validation/pending-mail-full-2026-10-29.json) passes 84 tests and 725 Lua syntax files. `SPEC-21-L23` records targeted partial coverage; native behavior and unrelated inventory requirements remain pending. Remaining ownership paths are tracked in the [provider lifecycle audit](PROVIDER_HANDOFF_LIFECYCLE.md).

## Latest focused Windows correction

BUG-004/PERF-003 (`19c40a0`) reconciles the existing Enable window mover option with
its lifecycle. Disabled discovery now avoids new native attachments, the panel
watcher sleeps and the public disable entrypoint stops active gestures before
further saved writes. Enabled interaction and saved geometry are retained. The
Windows requirement/enable control rows link the 220-check regression and 100-cycle
resource controls; other Windows requirements retain their previous verification
status. [Evidence and native steps](WINDOW_MOVER_LIFECYCLE.md). Latest full suite:
85 scripts/726 syntax files pass. Native feature/visual acceptance remains pending.

## Editorial maintenance

Three specification passages now use ordinary gameplay terminology without changing
their requirements. Their ledger rows and source hashes follow the edited Markdown;
original text remains in the external checkpoint. Prompt/template and Word planning
artifacts were retired outside the addon; the 26 specifications, implementation
plan and all feature requirements remain available. No feature/default was removed.

## Queued merchant purchase correction

BUG-005 (`cdd752a`) addresses an operation-time identity gap: retained queue slots can
buy unrelated items after merchant listings change, including after index refresh.
Manual/tier restock requirement rows receive only this focused coverage. The guard
skips stale tasks while preserving valid purchases, and a normal fresh request fills
remaining targets. [Evidence](VENDOR_PURCHASE_IDENTITY.md): 660 checks, five matched
pairs and a complete 86-script/727-syntax pass. Other vendor requirements and all
native feature/visual acceptance retain their previous status.

## Finite merchant stock correction

BUG-006 (`b505bb8`) gives the restock target/behavior rows additional partial coverage:
zero availability stops buying and finite submitted quantities share one index-entry
budget. This avoids known over-stock requests and their false accounting in the
modeled cases; reservations are not native acknowledgement. [Evidence](VENDOR_STOCK_BUDGET.md):
177 stock checks plus 660 identity controls, full 86 scripts/727 syntax pass, five
matched pairs. Other vendor requirements and all native/visual acceptance retain
prior status. No option/default/feature was removed.

## Vendor-open junk availability

BUG-007/PERF-004 (`e02139a`) gives `SPEC-20-L9` and `SPEC-20-L20` targeted partial
coverage: repeated no-junk availability checks reuse reliable unchanged inventory
without losing cold gray fallback or rule/item/Useful invalidation. Seven API
fixtures pass 265 checks and five matched count pairs; full suite passes 87 scripts/
728 syntax files. The user's Era idle-open hitch remains unverified natively.
Other requirements and all native/visual statuses remain pending or retain their
previous evidence. [Scope and native checks](VENDOR_OPEN_WORK.md).

## Quick Join anchor ownership

BUG-008 (`5198ded`) adds targeted partial coverage to `SPEC-26-L406`: social/channel
visibility, missing controls and fallback placement retain their behavior while
column-owned buttons avoid the reversed dependency that caused SetPoint failure.
The combined column regression passes 1,819 checks; the full suite passes 87 scripts/
728 syntax files. Other Chat requirements and native/visual acceptance remain
pending. [Evidence](CHAT_QUICKJOIN_ANCHOR.md). No option/default was removed.
