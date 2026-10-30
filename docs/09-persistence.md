# Persistence, profiles and settings ownership

FluxUI has several persistence domains. An account-wide SavedVariable can contain per-character records; an AceDB `char` table can live inside the account-wide `FluxUI_Options` SavedVariable. The TOC declaration alone does not explain effective feature scope.

The complete declared-name/owner index is [32-saved-variables.md](32-saved-variables.md). This chapter explains how the stores relate and when existing data is copied or migrated.

## Bootstrap and stores

[`_FluxUI.toc`](../_FluxUI.toc) declares nine account-wide and fourteen per-character SavedVariables. [`Core/DB.lua`](../Core/DB.lua) exposes `Flux.DB.GetAccount`, `GetOptions`, `GetChar` and `EnsureAll`:

- `GetAccount` ensures `FluxUI_DB`, a shared legacy settings/state container.
- `GetOptions` ensures the raw `FluxUI_Options` table; it is not the same accessor as the initialized AceDB object.
- `GetChar` ensures `_FluxUI_CharSavedVars`, a legacy per-character settings/state container.
- `EnsureAll`, run through `Flux.AfterLoad`, makes the listed legacy globals into tables if needed. Non-table roots are archived in `FluxUI_DB.__fluxRootRecoveryV1` before shape repair. It does not validate every feature record or define a single addon-wide schema version. Restock has a separate validated/reversible V1 migration; see the [implementation report](43-startup-optimization.md).

`FluxPerfCaptureDB` is declared in the TOC but created by the capture feature rather than the kernel's account-table list. Old binding and inventory names remain declared even when newer systems own the live data. Declaration/retention should not be interpreted as proof that a legacy scanner or schema still drives the UI.

| Store family | Current role |
|---|---|
| `FluxUI_DB` | Account state and multiple legacy feature branches, including defaults application/character flags. |
| `FluxUI_Options` | AceDB backing store: profiles, profile keys, per-character options and global branches. |
| `_FluxUI_CharSavedVars` | Legacy always-per-character state used by features outside, or bridged to, scoped Ace options. |
| `FluxBindingDB3` | Rewritten binding document, schema version 3, per character. |
| `FluxUIInventoryDB` | New inventory foundation's persistent character/location/account facts; see [21-inventory-foundation.md](21-inventory-foundation.md). |
| Other named variables | Flyout favorites, grid/utility slots, trinkets, Salvage, gold, professions, capture and retained compatibility data. Their schemas are feature-owned. |

## FluxUI_DB branch ownership

The account root has no universal schema/default pass beyond ensuring a table. Current directly owned branches are below; related always-character data can live in a different SavedVariable. Exact nested feature structures and other roots are in [32-saved-variables.md](32-saved-variables.md).

| Branch | Initialization/defaults and owner |
|---|---|
| `accountDefaultsApplied` | Absent/false means account setup can run; set true by full defaults apply, cleared by reset. [FluxDefaultSettings](../FluxDefaultSettings.lua). |
| `characters[charKey]` | Empty table when needed, true per encountered character; canonical-key migration by PlayerName. [Defaults](../FluxDefaultSettings.lua), [Name](../Core/API/Name.lua). |
| `defaultFluxBindingsChecked` | Account binding bootstrap state. Version 6 is written only after the native account set passes SaveBindings/LoadBindings, template verification and a later login confirms restored bridge bindings; older version-4/5 attempts are inspected once for missing bridge bindings. Failed transactions use failed6 to prevent a reload loop. [Binding rewrite](BINDING_PERSISTENCE_REWRITE.md). |
| `nameplateSizeDefaultV2` | One-time migration of the prior nameplate size `3` to requested Medium `2`; values other than `3` remain unchanged. Set after the write succeeds or no migration is needed. [Raid/nameplate record](RAID_NAMEPLATE_DEFAULTS.md). |
| `nameplateThreat` | `npcThreatBorder=true`, `enemyPlayerTarget=true`, `visibilityMode="group"`, `levelOverlayEnabled=true`; invalid visibility normalizes. Nested `blizzardThreat` defaults Progressive/Flash/HealthBarColor true. [NamePlates.Core](../NamePlates/Core.lua), [Threat API](../Core/API/Threat.lua). |
| `CharacterStats` | Empty root, then `era`/`progression`/`retail` mode branches and `global` table; paired character root. Detailed stat preferences are feature-owned. [Shared.lua](../CharacterInfo/Shared.lua). |
| `ExtraButtonCategories` | `Account.entries={}`, `Class[class].entries={}`, `Realm[realm].entries={}` when identities exist. Character categories/order/hiding live separately. [ExtraButtons.Core](../ExtraButtonSystem/ExtraButtons/Core.lua), LoadSavedVars/MigrateCategories. |
| `ExtraButtonSettings` | Ensured empty table beside category data; retention does not imply an independently populated current settings schema. [ExtraButtons.Core](../ExtraButtonSystem/ExtraButtons/Core.lua). |
| `MicroMenu` | `native={}`, `unifiedOrderList={}`, `unifiedInitialized=false` on new root; later canonical-order/version logic owns upgrades. Paired character native/order data exists. [FluxMicroMenuConfig](../MicroMenu/FluxMicroMenuConfig.lua). |
| `MinimapToMicro` | `buttons={}`, `orderList={}` for account selections/order, paired character buttons table. [FluxMinimapToMicro](../MicroMenu/FluxMinimapToMicro.lua). |
| `flightPath` | `overrides.Horde={}` and `overrides.Alliance={}`; measured route overrides, with character node names separately stored. [FluxFlightPath](../UnitFrames/FluxFlightPath.lua). |

## AceDB initialization and General scope

[`AddonOptions/FluxOptions.lua`](../AddonOptions/FluxOptions.lua), initialization handler and `EnforceProfileForLogin`, creates `AceDB:New("FluxUI_Options", FluxOptionsDefaults, true)` on this addon's `ADDON_LOADED`. The defaults declaration in [`FluxOptionsDefaults.lua`](../AddonOptions/FluxOptionsDefaults.lua) has three domains:

| Domain | Meaning |
|---|---|
| `profile` | Settings shared by characters on the same Ace profile; includes appearance and account-mode feature branches. |
| `char` | Options keyed to the current character regardless of profile; includes independent scope selectors and character-mode branches. |
| `global` | Account-wide settings outside profiles, including chat copy/link and nameplate-related storage. |

General's account choice selects the profile named `Default`. Character mode selects a canonical `Char - <name> - <realm>` key, using the name service when available. The first General transition to character mode copies `Default` into the character profile and marks it initialized. Switching back selects `Default`; this is a profile switch, not a merge into it.

Character profile enforcement waits until the player identity is ready. The old `Char - Unknown - Unknown` case has a repair path. Initialization can defer enforcement to `PLAYER_ENTERING_WORLD`, avoiding an early unknown-name selection that would redirect a session away from its saved appearance.

Profile callbacks refresh appearance and relevant account-scoped consumers. `OnProfileCopied` has special handling when a copied character-scoped profile lands in `Default`: it redirects that data to the character profile and resets `Default`. This is a meaningful persistence side effect. Arbitrarily named non-Default profiles are treated as character-specific by profile-change callbacks; the General login enforcement still resolves its canonical account/character selection.

## Independent feature scopes

Most major feature scopes do **not** change the active Ace profile. They choose between a branch in `db.profile` and one in `db.char`:

| Feature | Selector in `db.char` | Effective accessor |
|---|---|---|
| Action Bars | `actionbarsSettingsScope` | `GetActionbarsDB()` |
| Layout placement | `layoutSettingsScope` | `GetLayoutDB()` |
| Blizzard windows | `windowMoverSettingsScope` | `GetWindowMoverDB()` |
| Micro Menu settings/order | `microMenuSettingsScope` | `GetMicroMenuDB()` |
| Raid frames | `raidFramesSettingsScope` | `GetRaidFrameDB()` |
| Unit frames | `unitFramesSettingsScope` | `GetUnitFrameDB()` |
| Status bars | `statusBarsSettingsScope` | `GetStatusBarSettingsDB()` |

All default to account mode. In this context "account" means the corresponding branch of the **active profile**, which can itself be a General character profile. It does not invariably mean the literal `Default` profile or a global table shared by every profile.

Feature setters typically deep-copy the currently selected source branch into the destination on a scope transition, then refresh consumers. These switches are not generally two separately retained preference sets that are merely selected without copying. Read the specific setter before relying on a previously stored destination. Action-bar stance order and hidden-slot arrays are explicitly preserved as character data across scope switches.

Micro Menu has three separate concerns:

- Layout tab placement uses `layout` scope.
- Micro Menu size, spacing and unified order use Micro Menu scope.
- Native-button Off/Account/Character selections remain in `FluxUI_DB.MicroMenu.native` and `_FluxUI_CharSavedVars.MicroMenu.native`, independently of either toggle.

`MigrateMicroMenuSettingsScopeFromLayoutOnce` seeds the newer selector from the old layout selector once, guarded by `_fluxMMScopeSplitV1`. The legacy method name `IsMicroMenuLayoutCharacterSpecific` is now an alias for the Micro Menu settings selector; it is not the Layout-tab selector.

Item/currency tracking is always in `db.char.itemCurrency`. `GetItemCurrencyDB` normalizes slots, migrates older scoped status-bar locations once using `_fluxICStorageV1`, and removes stale scoped copies. PVP tracking remains in legacy character storage. These lists should not be assumed to move with Status Bar scope.

## Character identity and migrations

[`Core/API/Name.lua`](../Core/API/Name.lua), `Flux.PlayerName`, centralizes identity because Forever's `UnitName` second return can be a surname rather than a realm. `UsesRegionalUniqueNames` feature-detects that behavior. Display names can hide/show surnames independently of canonical storage identity.

| `GetCharKey(style)` | Shape or intent |
|---|---|
| default / `hyphen` | Full name plus display realm, joined with a hyphen. |
| `inventory` | Full name plus realm token. |
| `acedb` | Full name, space-hyphen-space, realm. |
| `profile` | `Char - <full name> - <realm>`, retaining historical Live/Classic realm handling. |
| `professions` | Realm followed by full name. |

On regional-unique-name clients, `MigrateCurrentCharacterAccountData` computes possible historical first-name-only or surname-as-realm keys and moves current-character records into canonical keys across defaults flags, AceDB tables, gold, inventory, profession memory, favorites and grid settings. It is registered for both `AfterLoad` and `AfterLogin`, and options call it before AceDB initialization.

`MigrateKeyedTable` moves an old entry only when the destination key is absent; it does not merge two existing records. These are targeted identity repairs, not a complete migration of every character or every saved schema.

## Binding and inventory ownership

[`Binding/Core/DB.lua`](../Binding/Core/DB.lua) identifies `FluxBindingDB3` as the live binding source of truth. `DB.VERSION` is 3. It holds UIDs, bindings and action records, form subprofiles, chord stack/badge order, form-page switches and rank-sync names. `SetDocumentOverride` temporarily redirects document access for Respec preview; a preview override is not a second permanent binding store. The header explicitly says the schema was fresh rather than a general migration from the legacy dual database. Feature-specific engraving migration remains separate.

Inventory and Respec persist richer documents and snapshots in their own stores/branches. They consume character identity, binding documents and options but do not become AceDB profile data merely because the options UI edits them. See [13-binding-system.md](13-binding-system.md), [21-inventory-foundation.md](21-inventory-foundation.md) and [23-respec.md](23-respec.md).

## Defaults application state

`FluxUI_DB.accountDefaultsApplied` records full account setup; `FluxUI_DB.characters[charKey]` records encountered characters. [`FluxDefaultSettings.lua`](../FluxDefaultSettings.lua) applies full game settings **and the keyboard template** automatically on first account login. A later new character receives client-reported character-stored CVar defaults, nameplate bitfields and raid/chat setup, without a full keybind wipe or account CVar replay. A separate one-time pass seeds missing Flux commands into the active account/character native binding set while preserving custom keys; it also repairs previously seen characters. Failed or deferred character CVar work leaves its character-seen flag unset until successful completion, allowing a later login retry. Automatic binding verification preserves customized bindings; F5 differences no longer trigger a key or CVar reset. Explicit setup/reset paths remain separate. [Binding details](DEFAULT_GRID_BINDINGS.md).

These flags are distinct from AceDB defaults and profile resets. Clearing one does not remove or reset the others. `/fluxdefaults reset` clears the account-applied flag; `resetchar` clears the current character's seen flag. Commands and exact side effects are described in [05-defaults-and-bindings.md](05-defaults-and-bindings.md).

Persistence has no single addon-wide schema version. For troubleshooting, identify the feature owner, effective profile/scope, canonical character key and migration guard first. Backups and reset testing belong in an isolated test profile/account-data copy; the documentation rewrite itself does not change saved data.

## Runtime compatibility decisions are not new saved profiles

The secure bar probe caches its OOC result until reload and can set `Cap.hasSecureBarPaging`; this is runtime capability state, not a SavedVariable or migration. Pending stock-grid suppression, tracker layout and pin refresh generations are also runtime-only. The recent bar/map/tracker changes introduce no new TOC SavedVariable declaration. Questie's `trackerEnabled` and `TrackerWidth` belong to Questie's own profile, independently of Flux's Map Pins setting and account/character layout selectors. See [API contracts](33-api-and-events.md) and [tracker ownership](18-minimap-and-trackers.md).
