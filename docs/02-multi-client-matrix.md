# Client detection and implementation matrix

This is a source-confirmed routing matrix, not a live-client certification. "Implemented" means a selected code path exists. See [41-verification.md](41-verification.md) for source/mock/in-game distinctions.

## Targets and families

[_FluxUI.toc](../_FluxUI.toc) advertises interface numbers `120100, 16001, 11509, 20506, 50504` and names Midnight, Forever, Era, Anniversary and MoP Classic. Metadata is not evidence of the newest available game patch.

| Runtime | Detection in [Client.lua](../Core/Client.lua) | Module family |
|---|---|---|
| Era | `WOW_PROJECT_CLASSIC`. | `era` |
| Anniversary/TBC | `WOW_PROJECT_BURNING_CRUSADE_CLASSIC`; `isTBC` and `isAnniversary` share this classification. | `anniversary` |
| Mists progression | Mists project; retained Wrath/Cata handling shares the family. | `classic` |
| Live Midnight | Mainline, major version ≥12, not Forever. | `midnight` |
| Forever/Camelot | Non-Classic runtime below major 12 with validated Camelot flag, legacy mainline version, timed-signal API or matching stats-pane evidence. | `midnight` |

Wrath/Cata branches remain in wrappers/filters; that alone does not establish separate currently supported packages. Forever sets `isRetail`, `isMidnight` and `isPostDF` despite a legacy-looking version. `gameType` is `camelot`, `classic` or `live`.

[Client_Camelot.lua](../Core/Client_Camelot.lua) validates the runtime before adding compatibility globals. TOC filtering alone is insufficient. The [client guard smoke](../Core/_tmp_clientguardsmoke.lua) includes mocked Retail 12.1.5 and stray Forever-looking APIs/flags; that version is a test input, not a deployment assertion.

## Flag compatibility

| Flag | `Flux.Client` | Legacy `FLUX_API` |
|---|---|---|
| `isClassic` | Wrath/Cata/Mists. | Era. |
| `isClassicEra` | Era. | Era. |
| `isAnyClassic` | Era/TBC/Wrath/Cata/Mists. | Same set. |
| `isForever`/`isCamelot` | Forever. | Follows validated Core classification where available. |
| `isPostDF` | Major ≥10 or Forever. | Same broad policy. |

The legacy [Client.lua](../Core/FluxAPI/Client.lua) exports separate namespace/API flags. Do not treat identically named properties as interchangeable.

## Major implementation paths

| System | Era | TBC | Mists | Live Midnight | Forever |
|---|---|---|---|---|---|
| Kernel/options/accent/layout | Shared. | Shared. | Shared. | Settings safety. | Variable-setup delay and gamepad variants. |
| Bars/grids/trinkets/pet/stance | Classic paths. | Classic paths. | Classic paths. | Modern actions/secure wraps. | Bar-only secure paging probe; native mouse-up/key-down policy remains. Other consumers retain the legacy restricted policy. |
| Rank controls | Enabled. | Enabled. | Disabled. | Disabled. | Low-rank API probe; modern book location. |
| Skyriding | Off. | Off. | Off. | Capability on. | Explicitly excluded. |
| Swing overlay | Enabled, API/event probe. | Enabled. | Disabled. | Disabled post-DF. | Native swing path when available. |
| Focus | Native ability/frame probe. | Probe. | Probe. | Probe. | Probe. |
| Aura enumeration | Available API/fallback. | Same. | Same. | Secret-access gates and specialized display. | Same backend family; distinct aura/UI handling. |
| Unit/raid frames | Classic paths. | Classic paths. | Progression paths. | Secret-safe display/native paths. | Separate token/recycled-row/aura handling. |
| Nameplate threat/level | Custom path when C_NamePlate exists. | Same. | Same. | Threat path supported; level explicitly disabled. | Threat and level paths supported, with secret guards. |
| Aura countdown | Capability path. | Same. | Same. | Native/secret-safe durations. | Capability path. |
| Tracker scroll | Native dock or enabled Questie tracker. | Same. | Available native/Questie path. | Post-DF viewport. | Questie owns the visible dock when enabled; keyboard native dirty/layout callbacks defer through combat even when its tracker is hidden. Gamepad container update stays native. |
| Meter | Details if installed. | Details. | Details. | Details or available native backend. | Details/Forever threat path; actual backend probe. |
| Threat normalization | Accessible values, Classic /100. | Same. | Same. | No /100; generic secret rows can skip. | Dedicated secret display rows, no /100. |
| Bank | Legacy slots/bags/keyring. | Same. | Progression/reagent probe. | Unified character/account tabs where available. | Unified API with bags-in-bank layout/sentinels. |
| Flux combined bag | Unless alternative UI. | Unless alternative UI. | No Era/TBC replacement branch. | Native/alternative integration. | Native/gamepad-sensitive integration. |
| Vendor/restock/junk/Salvage | Available operations. | Same. | Same. | Bank/tooltip-specific routes. | Bank/gamepad-specific routes. |
| Respec | Classic talent/bar/gear paths. | Classic paths. | Progression API paths. | Retail loadouts; different bar snapshot policy. | Native system probes; not every live feature follows isRetail. |
| Character Info | Classic stats/paperdoll. | TBC stats/paperdoll. | Native/progression hooks. | CharacterStatsPane rows. | ScrollBox rows and shared combat stat pins. |
| WindowMover | Catalog probes. | Same. | Same. | Modern geometry/exclusions. | Dynamic bank drag-only in keyboard mode; all catalog entries skipped in native gamepad mode. |
| Companion integrations | Conditional. | Conditional. | Conditional. | Conditional. | Conditional, additional safeguards. |

Sources: [Capabilities.lua](../Core/Capabilities.lua), [legacy capabilities](../Core/FluxAPI/Capabilities.lua), [Threat.lua](../Core/API/Threat.lua), [Classic combined bag](../Inventory/Builtin/FluxClassicCombinedBag.lua). Details belong to [system chapters](00-README.md).

## Forever details retained from the working tree

**Shared stats:** [FluxInfoFrame.lua](../StatusBars/FluxInfoFrame.lua), `_CamelotCombatStatKey`/`_FoldCamelotCombatPins`, uses one Hit/Crit/Haste value and pin per stat, folding older melee/ranged/spell pins while preserving order. [RetailPane.lua](../CharacterInfo/RetailPane.lua) hooks recycled ScrollBox row initialization. Other clients retain their own providers/pin behavior.

**Bank:** `Cap.UsesPlayerBagsInBank` probes the native function with Camelot fallback. BankFrame/BankPanel names do not imply live Midnight's named tabs. Sentinels are not scan containers; Forever's account sentinel can share -3 with the traditional reagent constant. `EnumerateBankTabIDs` combines purchased/enum IDs until absent, capped at 32, without hardcoding five tabs. The restock button anchors near search rather than over bottom bag slots, and WindowMover avoids scale/point fights with growing bank height. See [inventory](21-inventory-foundation.md) and [windows](28-window-mover.md).

**Gamepad:** native input-style API/enum and shown-bar probes distinguish HUD style from hardware connection. A style change prints a reload request because bag/tracker hooks were chosen at load. Click proxies, dropdowns, native collectors and protected panels add further constraints. WindowMover.ShouldSkip currently skips every catalog entry in Forever gamepad mode, not only bags.

**Secure paging is a separate capability:** `hasRestrictedClosures` remains false for Forever's existing callers. Bars call `Restricted.PagingWorks()` outside combat, execute a small snippet and cache the observed result in `Cap.hasSecureBarPaging`. A positive result enables captured native attribute drivers without changing ordinary mouse/key edges; failure leaves the OOC paging fallback. The public absence of `loadstring_untainted` does not establish that the already-captured restricted engine is broken. `/fluxbars page` prints both policies. Temporary pages (11 and above) take priority over ordinary promotion/compiled overlays on native main columns. [Action bars](11-action-bars.md) explains the page and input contracts.

**Questie has two independent integrations:** the enabled tracker takes the objective dock on Era/Anniversary/Forever; pins follow World Map visibility/filter settings independently of that tracker setting. Where native quest providers exist, the HBD router accepts only Forever's `HereBeDragonsQuestie-Pins-2.0`; Live's native-provider path is left alone. Older maps without native quest providers retain broader supported HBD routing. [Flux Window](10-flux-window.md) and [minimap/trackers](18-minimap-and-trackers.md) describe ownership transitions.

TOC gates, client flags, capabilities, runtime checks and addon readiness all participate. Some probes refresh after login. Existence does not prove safe/populated behavior in every UI/combat state. See [03-midnight-constraints.md](03-midnight-constraints.md) and [07-runtime-architecture.md](07-runtime-architecture.md).
