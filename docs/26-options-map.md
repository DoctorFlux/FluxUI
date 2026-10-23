# Options map and settings behavior

Open `/fluxui` or `/fluxoptions` to toggle the standalone settings shell. `/fluxui bliz` / `blizzard` opens the native settings route; `/fluxui raidpreview` toggles the raid preview. The Blizzard addon category also contains a button into the standalone shell.

The catalog, builders and renderer are separate layers. **Sidebar labels below come from the current catalog**, not old chapter names or builder-internal names. [Catalog](../AddonOptions/FluxOptionsCatalog.lua), [bootstrap/accessors](../AddonOptions/FluxOptions.lua), [shell](../AddonOptions/FluxOptionsShell.lua), [renderer](../AddonOptions/FluxOptionsRender.lua).

## Complete-reference companions

- [Setting definition inventory](reference/settings-details.md): every extracted option constructor, factory call and custom-widget registration; exact ranges, getter/setter/action expressions, hidden/disabled gates and source lines.
- [Literal AceDB defaults](reference/defaults.md): every literal leaf in the defaults table, including per-unit display fields.
- [Custom widget controls](35-custom-widget-controls.md): controls inside preview/editor embeds, which cannot be understood from an Ace `dialogControl` placeholder.
- [Saved schemas](32-saved-variables.md): feature-owned defaults, migrations and stores outside AceDB.
- [Command reference](31-commands-and-bindings.md): configuration actions exposed only through slash commands.
- [Binding](13-binding-system.md), [Respec](23-respec.md), and [extra buttons](12-extra-button-system.md): authoring controls in those separate feature windows.

The inventories preserve **source definitions**, including templates expanded per unit/skill/row. Their count is not the number of visible controls for one character. Full field expressions are stored in [inventory.json](reference/inventory.json); shortened excerpts in the Markdown keep it readable.

## Actual sidebar

| Group | Page order | Main implementation |
|---|---|---|
| General | General → Nameplates → Windows → Profiles | [catalog](../AddonOptions/FluxOptionsCatalog.lua) |
| HUD | Layout → Action Bars → Status Bars → Info → Micro Menu → Chat → Unit Frames → Flux Window | [catalog](../AddonOptions/FluxOptionsCatalog.lua) |
| Tools | Inventory → Binding | [catalog](../AddonOptions/FluxOptionsCatalog.lua) |

Party/raid settings are merged into Unit Frames. Vendor/restock/junk and salvage belong to Inventory. Info and Chat have their own pages. There is no separate sidebar Frames group, Raid page, Salvage page or Defaults page in this catalog.

## Rendering and application

Builders or prebuilt tables register through `FluxOptions:RegisterModuleOptions(key,optionsTableOrBuilder)`. The shell builds the selected page/subpage and renders native rows from Ace-style tables. Embedded custom controls remain AceGUI widgets. Profiles comes from bundled AceDBOptions.

The renderer evaluates functions and handler methods; inherits get/set/func/confirm/validate/hidden/disabled down option paths; and respects dialog/gui overrides. Availability therefore depends on both the control and its parent. A source-defined toggle is not proof it is visible or editable on every client.

Group/header order can be overridden by the catalog. The header named **Performance** is placed behind “More options.” A setting callback may update storage, repaint, request queued layout/application or trigger a feature rebuild; writing a field alone is not a universal refresh mechanism. Source callback/gate expressions are in the inventory. Protected changes must follow the owning feature's combat deferral.

## Scopes and default stores

| Setting family | Effective storage / missing-value default |
|---|---|
| General profile | AceDB profile selected by General scope: shared `Default` or character profile. `settingsScope="account"`; accent class, custom RGB white. |
| Action Bars | Independent account/character selector; effective `profile.actionbars` or `char.actionbars`. Default account. Stance order/hidden/custom slots are always `db.char.actionbars`. |
| Layout | Independent `profile.layout` / `char.layout`, default account. |
| Windows | Independent `profile.windowMover` / `char.windowMover`, default account. |
| Micro Menu bar geometry/order | Independent `profile.microMenu` / `char.microMenu`, default account. Per-row Off/Account/Character visibility is a different mechanism; professions are always true character storage. |
| Status Bars | Independent `profile.statusBars` / `char.statusBars`, default account. Honor/Arena are true character settings; item currency is always AceDB `char.itemCurrency`. |
| Unit Frames | Independent `profile.unitFrames` / `char.unitFrames`, default account. |
| Party / raid | Independent `profile.raidFrames` / `char.raidFrames`, default account even though displayed inside Unit Frames. |
| Info content | Always `_FluxUI_CharSavedVars.infoFrame`; its location/cell placement is Layout-scoped. |
| Nameplates | Actual feature store `FluxUI_DB.nameplateThreat`, plus shared threat/CVar accessors; not a General-profile-only setting. |
| Chat | AceDB `global.chatCopyPaste`, account-wide and independent of selected profile. |
| Inventory automation/junk/restock | Mostly `_FluxUI_CharSavedVars.Restock`; feature-specific exceptions below. |
| Salvage | Account `FluxSalvageDB`. |
| Flux Window / meter | True character saved fields/layout owned by FluxWindowFrame/FluxMeterLayout. |
| Binding | Per-character Binding v3 document; KeyVisualizer presentation preferences are AceDB global. |

Independent scopes copy current shared values on first character initialization according to their owner; switching General's profile is not a command to switch all independent selectors. Hearth/mount also have their own shared character-mode flag and stores. Use [persistence](09-persistence.md) for copy/reset semantics.

## General pages

### General

| Control | Values / behavior |
|---|---|
| Settings scope | Account-wide / Character-specific. Selects General's active Ace profile via the owner rather than changing every feature's scope. |
| Accent | Class color (default), Default atlas, Custom. Calls the shared appearance refresh. |
| Custom accent color | RGB picker, defaults white; conditionally relevant to Custom accent. |

Source: [General builder](../AddonOptions/FluxOptionsGeneral.lua).

### Nameplates

| Control | Values / default / effect |
|---|---|
| Threat visibility | always / group / never; group default. |
| NPC threat border + rank/% | Enabled default; actual display still depends on supported/accessible threat data. |
| Show threat percentage | Shared numeric-threat accessor used by both nameplates and target/focus threat bars; fallback enabled. |
| Enemy player targeting you | Enabled default. |
| Blizzard Progressive / Flash / Health Bar Color | Separate bitfield controls for native `nameplateThreatDisplay`, not the same as Flux's overlay. |
| Threat warning | Native CVar modes 0 Off, 1 Party, 2 Raid, 3 Always; hidden if unavailable. Getter reflects current CVar. |
| Modern-style level overlay | Enabled default; only added when level support is reported and ignored in Classic health-bar style. Current code rejects Live Midnight for this overlay but permits Forever. |
| Aura countdown size | Informational text directs editing `FLUX_NAMEPLATE_AURA_COUNTDOWN_SCALE` (default 0.75) then reload. No size slider is exposed here. |

Source: [Nameplates builder](../AddonOptions/FluxOptionsNameplates.lua), [threat API](../Core/API/Threat.lua), [actual behavior](19-nameplates.md). Do not treat the older concept restriction table as current runtime policy.

### Windows

Defaults: enabled, scaling, save position, save scale and screen clamping **on**; lock and require modifier **off**; modifier Shift; snap 0.

Controls expose all of those flags, Shift/Ctrl/Alt selection (disabled until modifier is required), snap 0–64 pixels, and Reset all window positions. Left-drag moves, right-drag scales (50%–250%), middle-click resets. Reset clears saves; reopening lets native layout restore positioning. This page does not drag the Flux HUD. Current Forever gamepad mode skips mover catalog attachment.

Source: [Windows builder](../AddonOptions/FluxOptionsWindows.lua), [WindowMover](28-window-mover.md).

### Profiles

Bundled AceDBOptions supplies current profile display, choose existing/new profile, copy from another profile, delete profile and reset profile controls, with its confirmation and current-profile exclusions. These operate on AceDB profiles; they do not erase all standalone saved roots, Binding v3 or every character-only feature.

Source: [AceDBOptions](../libs/AceDBOptions-3.0/AceDBOptions-3.0.lua), [profile owner](../AddonOptions/FluxOptions.lua).

## HUD pages

### Layout

The page exposes Layout scope, a confirmed reset, and an interactive preview. Defaults:

| Field | Default / alternatives |
|---|---|
| Micro Menu placement | 2: beside chat; alternatives top-left horizontal and minimap strip. Beside-chat/minimap grid defaults two columns; minimap strip collapsed. |
| Status placement | 3: screen-bottom full width; alternatives stacked under micro menu and above action strip. |
| Player/target placement | 2: side by side; alternative player above strip and target top-center. |
| Stance placement | 1: beside player; alternative standalone anchor. |
| Info placement | `actionStrip`; alternatives `statusIntegrated`, `minimapTop`, `screenTopLeft`. |
| Info status cell | `start`; alternatives `middle`, `end`. On stacked bars these mean top/after first/bottom rather than horizontal columns. |

Preview click/drag interactions and relayout dependencies: [Layout](06-layout.md), [widget controls](35-custom-widget-controls.md), [builder](../AddonOptions/FluxOptionsLayout.lua), [preview](../AddonOptions/FluxLayoutPreviewUI.lua).

### Action Bars

The catalog relabels internal Bar subpage as **Bars**. Other subpages are Bindings, Extra and Stance. Their builders assemble through [FluxOptionsActionBars](../AddonOptions/FluxOptionsActionBars.lua).

| Subpage | Controls / defaults |
|---|---|
| Bars | Independent scope; minirows Top (default) / Bottom; old-client cast/target VFX on; mouseover cast on; auto rank-up off and explicit Rank up all spells; spell blacklist embed. VFX and rank controls have client-specific hidden gates. |
| Bindings | Enter Binding Mode; confirmed Reset keybindings to Flux defaults. These affect live/native bindings separately from authored Binding v3 rows. |
| Extra | Reset visibility; per-button visibility widget; food/water→potions-in-combat and potions→food/water-out-of-combat independently off; NC flyout ordering/hiding/favorites; four modifier-aware utility slots. |
| Stance | Reset stance order; character-only native/custom stance slot ordering, hide/remove and assignment editor. |

Mouseover casting delegates to the actual MouseoverCast implementation; its current Forever CVar synchronization is skipped. Old builder descriptions saying the toggle always writes that CVar are not sufficient evidence. See [shared services](08-shared-services.md), [bars](11-action-bars.md), [findings](40-findings.md).

Performance controls apply immediately through `Bars.ApplyPerformanceSettings`:

| Field | Default seconds | Slider min–max / step |
|---|---:|---|
| rangeCheckInterval | 0.25 | 0.10–1.00 / 0.05 |
| extraButtonRangeCheckInterval | 0.18 | 0.10–1.00 / 0.05 |
| mouseoverUpdateInterval | 0.07 | 0.04–0.20 / 0.01 |
| macroUsableMinInterval | 0.05 | 0–0.50 / 0.01 |
| actionUsableMinInterval | 0 | 0–0.50 / 0.01 |

Visibility defaults are listed in [literal defaults](reference/defaults.md). The policy has Off/Auto/Always choices for most rows; Mana Gem/class teleport restrict to Off/Auto and Consumables uses Hidden/Always. Current options IDs exclude Assisted Combat even though its policy/default remains in code. Food/Water normalize Auto to Always; non-mana users also normalize some Always states to Auto. The declared defaults are hearth/food/water/consumables always and most other rows auto. Effective cycles follow normalization, not just the declared mode array. See [widget rules](35-custom-widget-controls.md) for per-row restrictions.

### Status Bars

| Control family | Defaults / scope / action |
|---|---|
| Scope, gold strip, hide non-XP strip, height | Independent Status scope; gold shown; hide-exp false; height 18 with range 10–40. Reset restores owned strip options. |
| Honor / Arena | Both false, true character `PVPTracking`; availability follows the PvP feature gate. Setter synchronizes status-bar tracking. |
| Account gold ledger | Dynamic stored-character select and confirmed delete; operates on the ledger, not an Ace profile reset. |
| Inventory tooltip | Items, currencies, equipped, guild, blank line and race icons enabled; Shift-only, connected-realms-only and same-faction-only disabled. Writes effective Status settings. |
| Item currency | Ace `char.itemCurrency.enabled=true`; cursor-assigned item rows and reorder/clear embed. Current owner caps total rows at 40 and appends a trailing empty row while capacity remains, not the stale six-item introductory text. Row visibility is normalized from item ID. |

Source: [Status builder](../AddonOptions/FluxOptionsStatusBars.lua), [item-currency owner](../StatusBars/FluxItemCurrencyTracking.lua), [widget controls](35-custom-widget-controls.md), [system](16-status-bars.md).

### Info

Show FPS and Ping default on; Durability off. Clear pinned stats removes the pinned list after confirmation. Drag rows to change stat order. These content fields are always character-specific. Cell position selects start/middle/end in the Layout store; the panel's overall placement is changed on Layout.

Pinning starts from Character Info rows rather than a separate comprehensive select in this page. Source: [Info builder](../AddonOptions/FluxOptionsInfo.lua), [InfoFrame](../StatusBars/FluxInfoFrame.lua), [Character Info](27-character-info.md).

### Micro Menu

| Control | Behavior / default |
|---|---|
| Bar scope | Independent size/spacing/unified-order scope; does not change per-row visibility or Layout placement. |
| Embedded row editor | Drag reorder; per-row Off/Account/Character visibility cycles. Account row defaults differ between native and captured minimap buttons. |
| Button size | 0.9; range 0.5–1.5, step 0.05. |
| Spacing offset | -2; range -12–16, step 1. |
| Reset layout | Restores the layout settings through its owner; full factory reset is also available via `/fluxmicro resetall`. |
| Profession enablement | On, always true character storage. |
| Profession layout | `fixedSplit` default; alternatives `perProfession` and `global`. |
| Global profession style | `allIndividual` default; alternatives one flyout / both, relevant in global mode. |
| Per-profession placement | Dynamically built learned-skill controls: Individual / In flyout / Off. Primary skills default individual, others flyout. Rebuilds when learned skills change. |

Source: [builder](../AddonOptions/FluxOptionsMicroMenu.lua), [profession owner](../MicroMenu/FluxTradeSkillMicro.lua), [system](17-micromenu.md).

### Chat

Eight account-global toggles: Social, Channels, Guild, Character Info/durability, Bags, Copy Chat, FluxUI Options, Chat Menu. All default on; individual rows can be disabled when their target button is unavailable. Hiding the chat gear does not remove slash access or the separate micromenu configuration button.

The wider chat-copy schema also contains URL color/message color/fade/max-line fields, but this page exposes the button toggles; absence of a control here is different from absence of an internal setting. [Chat builder](../AddonOptions/FluxOptionsChat.lua), [defaults](reference/defaults.md), [QoL](25-other-qol.md).

### Unit Frames, including party/raid

Master Player/Target/Target-of-target/Focus/Focus-target/Pet/Pet-target switches default on, with focus-capability gates. Unit Frames and Party/raid have separate scope/reset controls. `useFluxRaidFrames` defaults on. Settings switch runtime ownership through the appropriate coordinator; see [unit frames](14-unit-frames.md) and [raid frames](15-raid-frames.md).

Shared unit options include 3D portraits, portrait combat tint, health-loss/power-cost/MP5 overlays, weapon swing timer and flight timers/bar/tooltips, all default on where supported. Pet cast bar defaults off. Threat visibility defaults group; numeric threat is shared with Nameplates.

Per-unit groups expose applicable portrait, cast bar/time, health/power text, level/class/PvP/combat/raid indicators, mouseover, prediction/absorb and class-resource controls. Their exact per-unit defaults differ and are fully listed under `profile.unitFrames.display` and `char.unitFrames.display` in [defaults](reference/defaults.md). A generated toggle helper's true fallback is not a substitute for checking those seeded defaults.

| Sizing / aura controls | Rules |
|---|---|
| Width/height | Unit-specific slider limits and default dimensions; side-by-side placement uses effective pixels and converts to stored design dimensions (0.7 conversion), with placement-specific buckets. |
| Health/resource partition | 35–85%, default 60%; stored as fractions. |
| Class power size | 50–200%, default 100%; displayed as percentage, stored as scale. |
| Target/focus buff/debuff size | 14–56; seeded target 35 / focus 20. |
| Aura spacing | 0–12, default 2. |
| Max buffs / debuffs | 8–40 / 4–24; seeded 32 / 16. |
| Own-debuff sizing | Lock on, minimum scale 75%; slider 50–100%. |
| Threat position | Target/focus portrait or alternative supported position; visibility is a shared setting mirrored in multiple control locations. |
| Pet | Separate portrait/cast/tooltip-aura controls and width/height; pet-target has a compact width control. |

Party/raid controls include class-colored names; preview toggle, roster size, MT-column/slot count and demo buff/debuff toggles/counts; member width/height, power and aura scale, manager scale; frame/range/aura opacity; dispel/aggro/target/mouseover highlights; roles/groups/range fade; class colors/power/prediction; health text; buffs/debuffs, aura focus and dispellable-only filtering.

Important seeded raid values: width 1, height 1.2, power 1, aura 1.4, manager 0.9; base alpha 1, in-range 0.9, out-of-range 0.44, aura alpha 1; preview roster 40, MT enabled/count 2, buff/debuff demos enabled/counts 3/5; aura focus debuff. Exact ranges and gates: [definition inventory](reference/settings-details.md). Source: [merged Unit Frames builder](../AddonOptions/FluxOptionsUnitFrames.lua), [party/raid builder](../AddonOptions/FluxOptionsRaidFrame.lua).

### Flux Window

Tab chips drag to reorder and click to enable/disable, retaining at least one tab. Reset restores Map → Meter → Respec → Buttons, all enabled. Meter editor is conditional on a usable backend. Details takes precedence; native Blizzard layouts use their own pane types/limits (maximum three panes, no threat pane). Presets, named layouts, pane types and split dragging are widget-owned.

Source: [builder](../AddonOptions/FluxOptionsBattlezone.lua), [widget controls](35-custom-widget-controls.md), [Flux Window](10-flux-window.md).

## Tools pages

### Inventory

The page merges vendor/junk automation, item tinting, restock targets and salvage. The native toggles are built from descriptor sections rather than relying on the registered legacy-style grid widget.

| Control family | Defaults / dependencies |
|---|---|
| Auto repair, auto sell, auto restock, auto bank restock | Off in fresh Restock settings. Guild repair first defaults off/personal and is conditionally shown/disabled by capability and repair enablement. |
| Bulk buy / large-purchase confirmation | Both enabled in true character fields. Confirmation toggle disabled if bulk buy is off. |
| Junk rules | Low-level consumables, unusable equipment, inferior non-conjured food/water treatment, destroying unsellable junk and safe batch selling default enabled. Action also depends on selling, item classification and protection. |
| Junk indicators | Bag glow and coin icons default on; callbacks refresh caches/overlays. |
| Already-known tint | Enabled, green RGB 0/1/0, monochrome off. Setter notifies supported merchant/auction/guild views. |
| Restock target editor | Dynamic items, food/water/combat tiers and consumable targets/presets; scope/store varies by row kind. Confirmed Clear all restock targets calls the relevant owner. |
| Salvage | Account-wide overlay enabled; modifier Alt, Alt+Ctrl or Alt+Shift. Profession/spell/rank/protection gates still apply. |

All interaction/default details for quantities, inferior marking, time thresholds, searches, presets, manual junk overrides and row clearing are in [custom widget controls](35-custom-widget-controls.md). Automation flags do not bypass protection, live-bank checks or required user/protected clicks. [Builder](../AddonOptions/FluxOptionsVendor.lua), [salvage builder](../AddonOptions/FluxOptionsSalvage.lua), [defaults/schema](32-saved-variables.md), [economy](20-vendor-restock-junk.md).

### Binding

Embeds the binding browser in a full-height options area. The browser/editor/keyboard visualizer provide action discovery, authored binding rows, targeting/load/action/macro/badge/form controls and application. These are not additional General-profile fields; the active document is per-character Binding v3.

See [binding system](13-binding-system.md), [custom controls](35-custom-widget-controls.md), [schema](32-saved-variables.md), [builder](../AddonOptions/FluxOptionsBinding.lua).

## Reset and verification rules

Each reset affects its named owner and selected scope. Resetting Layout, WindowMover, status settings, stance order, flyout layout, visibility, a profile, restock targets, or the defaults pack are distinct operations. Flyout order/hide reset deliberately preserves favorites. General/AceDB reset does not imply all character roots were erased.

Some labels/descriptions are stale even within current source (for example six item-currency counts and broad Forever mouseover-CVar wording). This chapter follows the actual owner/callback implementation and records discrepancies in [findings](40-findings.md).

No settings were toggled in a live client during this reverse engineering. [Verification](41-verification.md) defines client-specific preview, persistence, reset, reload and combat checks.
