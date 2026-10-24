# Action bars

`Flux.Bars` owns the bottom strip, secure click surfaces, pet/stance bars and hover-to-bind mode. Blizzard action slots store content; Flux-owned widgets provide presentation and clicks. [Init.lua](../Bars/Init.lua) is the entrypoint. Current TOC loading, rather than older engine terminology in comments, establishes the implementation.

## Structure and startup

There are **19 columns**: 12 page-dependent native columns and 7 static columns. Every column has main, `sec` and `tert` hosts: 57 surfaces. `Bars.hosts[column]`, `GetHost`, `GetMain`, `ForEach` and `ForEachHost` are the registry/traversal API. Minis are half-size.

`Start()` runs once outside combat: prepare stock bars; start vehicle handling; create strip/state headers; build main/mini hosts; install clicks/drivers/watches; start program-face translation, cast effects and layout; apply slots/options. [Hosts.lua](../Bars/Hosts.lua) chooses modern `ActionBarButtonTemplate` or art-only `ActionButtonTemplate` plus the secure action template. Forever deliberately uses the latter even with modern native UI, preserving its native collector methods. Stock `ActionButton1–12` stay suppressed. Columns 13–19 borrow Blizzard commands exposed by `Hosts.BindingCommand()` while displayed labels remain Action Buttons 13–19.

Initial visual constants are 44px buttons, 0 padding, 4px margin, 1.24 scale and 4px vertical offset. [Strip.lua](../Bars/Strip.lua) adds shared squeeze/scaling and gamepad adjustments. Effective geometry also depends on current layout/options.

## Pages, modifiers and promotion

[SlotMath.lua](../Bars/SlotMath.lua) is the pure model; [State.lua](../Bars/State.lua) reproduces it in restricted handlers. They must agree.

| At-rest surface | Columns 1–12 | Columns 13–19 |
|---|---|---|
| Main | `(page - 1) * 12 + column` | Slots 13–19 |
| SHIFT mini | Slots 61–72 | Slots 49–55 |
| CTRL mini | Slots 25–36 | Slots 37–43 |

**Native page** covers ordinary page, forms/stances, stealth variants, vehicle/possess/override and supported skyriding states. Six headers cover main/sec/tert × dynamic/static columns. **Modifier selection** resolves at keypress from pre-stamped SHIFT/CTRL attributes through `SecureButton_GetModifiedAttribute`. It does not wait for the modifier state driver. A modifier hub/child updates keep visible identities and `host.slot` synchronized. This distinction is essential when combat starts with a modifier held.

[Layout.lua](../Bars/Layout.lua) reserves all twelve native columns, including empty positions, and packs eligible static columns. Promotion can put mini content into an empty ordinary main. One available mini can serve both modifier paths; two minis can use promoted-main/remaining-mini behavior. Hover, drag and binding mode expand the compact view. `ApplyMappings()` changes slot relationships; `ApplyVisual()` changes anchors/visibility. Structural Show/Hide/SetPoint work defers through combat; already-created surfaces have safe reveal/alpha paths.

## Input and compiled overlays

[Clicks.lua](../Bars/Clicks.lua) routes keys through `KeyBind` clicks on clients using click wraps. Forever retains visible mouse-up clicks and hidden key-down proxies; binding installation targets `FluxActionStripKey<column>` with `LeftButton` when wraps are unavailable. Shared `Flux.ButtonFX.Click` controls mouse/key-down/hold-release behavior, with empower attributes reasserted as required. Binding changes invalidate key caches.

[BindingMode.lua](../Bars/BindingMode.lua) adapts LibKeyBound: hover a main/mini/pet/stance/combat/noncombat/utility/trinket surface and press a key. It registers appropriate commands, forces relevant empty slots visible and dims unrelated columns. Activation is combat-locked. This simple assignment mode is separate from [conditional binding authoring](13-binding-system.md).

[SlotProgram.lua](../Bars/SlotProgram.lua) stores compiled programs by **action slot ID**. Simple peer/badge conditionals can use temporary visible-host macro attributes; sequence/petattack/multi-cast programs delegate through hidden `FluxSlotClick_<slot>` secure buttons. `ApplyMap`, `ApplyHoverMap`, reassert and queue-flush methods skip unchanged programs. Native slot content remains distinct from these overlays.

[ProgramFace.lua](../Bars/ProgramFace.lua) translates displayed macro identity so icon/count/cooldown/usability/range and badges follow the apparent action. It indexes body requirements and receives shared context updates. [MacrotextDisplay.lua](../Bars/MacrotextDisplay.lua) is an adapter to `Flux.Context`, not an independent mouseover scanner.

## Paint, effects and native flyouts

[Paint.lua](../Bars/Paint.lua) owns labels, icons, counts, cooldowns, tint, checked/flash/equipped state, hotkeys and assisted-combat highlights. Dirty hosts batch through `Flush(tokens)`. Shared action/secret wrappers keep restricted values out of Lua comparisons and pass them to supported display widgets.

[BadgeHost.lua](../Bars/BadgeHost.lua) maps up to three alternate-action corner previews per slot onto every surface that can display it. Form, occupancy, cooldown, macro identity and per-binding policies control visibility. Combat visibility uses alpha; structural writes defer. Badge ordering differs from macro clause ordering.

[Effects.lua](../Bars/Effects.lua) transfers proc overlays by action identity across main/mini widgets so paging does not restart the birth animation. Shared cast effects follow the column. [Flyout.lua](../Bars/Flyout.lua) attaches native Blizzard SpellFlyout; custom item/utility flyouts use EBS instead.

[SpellRank.lua](../Bars/SpellRank.lua) desaturates lower learned ranks, offers explicit/automatic rank-up, maintains a blacklist and reconciles affected binding/spellbook displays. Rank support is gated for applicable Classic/Forever clients; Live Midnight does not use this rank workflow.

## Pet and hybrid stance bars

The [pet bar](../Bars/Pet/Init.lua) is 5×2 EBS widgets using `BONUSACTIONBUTTON1–10`. It follows player/stance or alternate HUD placement, pet/vehicle visibility and binding-mode overrides. Watches separate full refresh from cooldown/usability updates.

Forever's pet visibility driver uses `[pet,nobonusbar:5]show;hide` for legacy control encounters; other clients use `[pet,novehicleui]show;hide`. The pet driver's compatibility policy remains independent of the main bar's secure-paging probe.

The [stance shell](../Bars/Stance/Init.lua) combines true forms, class extras and custom slots. Hidden Blizzard donors retain native secure behavior; EBS faces provide Flux presentation. `Order.lua` persists per-character order, hidden keys and additions. `Extras.lua` discovers class helpers, deduplicates form abilities and tracks active auras/pets. Visual aura changes repaint instead of rebuilding discovery/layout. Options support reorder/hide and cursor-added slots.

## Configuration and verification

`FluxOptions:GetActionbarsDB()` selects account/character settings; stance order/custom slots remain per character. `ApplyPerformanceSettings()` configures distinct queues: action range 0.25, extra range 0.18, macro mouseover 0.07, macro-usability minimum 0.05 and optional action-usability minimum 0 by default. [Options](26-options-map.md) records exact controls.

`/fluxbars` reports state; `<column>` prints surfaces; `page`/`paging` prints the secure chain; `mo`/`mouseover` prints targeting; `smoke` runs slot-math assertions. The [local smoke harness](../Bars/_tmp_barsmoke.lua) checks mapping/selected lockdown contracts, not live protected execution.

Vehicle abilities page onto the first 12 Flux columns. Blizzard vehicle/override chrome differs from suppressed unused bars; modern Settings hooks avoid replacing taint-sensitive globals. Verify vehicles, forms, held modifiers at combat entry, mouse/wheel hovercast, native flyouts, promotion and identity-stable effects in game on each family.

All twelve native main positions remain shown even when empty, so control actions never require a protected Show/Hide or repacking during combat. Temporary pages own these mains regardless of held SHIFT/CTRL or mini promotion; the ordinary mapping returns on exit. Temporary page contents do not alter ordinary promotion flags.

The implementation treats every page numbered 11 or higher as temporary. The first twelve mains bypass saved macro/click programs on those pages, while secondary/tertiary hosts and static columns retain their own mappings. Promotion discovery checks ordinary pages 7–10 rather than temporary control content. Modern clients also include supported override/vehicle/possess/shapeshift driver clauses; Forever uses bonus page 5 to reach action page 11 (slots 121–132).

Forever retains v8's native `SecureActionButton_OnClick`, mouse-up registration and hidden key-down proxies. Ordinary native actions are not wrapped in routing macros. `Restricted.PagingWorks()` separately executes a small setup-time snippet to check whether the client's repaired secure environment works; it does not infer support from the deliberately removed public `loadstring_untainted` global. After success, the bar headers register through captured native attribute-driver functions and handle both entry and exit in combat. Other modules keep their existing compatibility policy. Forever's driver uses `[bonusbar:5]` for Mind Control / Chess and excludes the unsupported vehicle/override/possess/shapeshift macro options. A failed probe retains the legacy OOC fallback; that engine cannot perform secure combat paging. `/fluxbars page` reports `securePaging`.

Forever strip widgets use the art-only `ActionButtonTemplate` with the same secure click handler, avoiding temporary replacement of native collector methods. Native collector event delivery stays active. When secure paging is available, native stance suppression also uses restricted frame handles instead of reparenting the Edit Mode bar.

[The Forever control regression](../Bars/_tmp_forevercontrolsmoke.lua) executes the supplied native `SecureStateDriver` and `SecureTemplates` with Flux's actual state, click, key-proxy and layout modules. It compares ordinary mapping with the supplied v8 backup and checks empty positions, combat control entry/exit, normal pages 1/2/6, held modifiers, promotion, macro restoration, native collector ownership and a failed engine probe. It models protected writes and input edges; it does not model the game's taint engine or replace an in-game encounter test.

## Stock grid events and combat bag pickup

The supplied Forever source matches the reported bag-pickup stack: `PickupContainerItem → ACTIONBAR_SHOWGRID → SetShowGrid → UpdateVisibility → UpdateActionBarLayout → ManageFramePositions → RightManagedFrameContainer:SetSize`. Alpha-hidden Blizzard bars still received grid events and entered Edit Mode layout during combat; deferring Flux's own grid cleanup did not prevent that native dispatch. The stack establishes this trigger but does not identify the first taint write.

[Blizzard.lua](../Bars/Blizzard.lua) unregisters only recognized action/pet grid events named by each replaced bar's `showGridEventName` and `hideGridEventName`, including the main bar. Suppression runs before neutralization, handles aliases and late `Blizzard_ActionBar` loads across clients, and coalesces combat requests until regeneration. It checks current registrations independently of the unused-bar visibility flag. Flux grid listeners remain active; native controller/paging events, vehicle bars, layout methods and managed-frame tables retain their existing ownership.

Run `lua Bars/_tmp_stockgridsmoke.lua` from the addon root. The fixture executes the supplied native action-grid and layout methods plus Flux's actual suppression and combat queue. It reproduces the original dispatch with a modeled protected resize, then checks action/pet show/hide events, aliases, missing capabilities, repeated setup, event re-registration, late loading, combat deferral and Forever gamepad mode. Four client snapshots are exercised; MoP coverage uses an explicit compatibility fixture backed by Era methods, since no MoP snapshot was supplied. Native taint, hardware input and saved Edit Mode anchor geometry remain outside the fixture.

In-game acceptance remains pending: start a fresh Forever session with `/console taintLog 2` and `/reload`, reproduce combat bag pickup/cancel and bag transfers, and inspect `Logs/taint.log` for the first taint attribution and any blocked resize. Disable logging afterward with `/console taintLog 0`. Repeat in a clean session with Flux disabled when attributing the original taint. Verify normal action assignment outside combat, pet grids, forms, possession, vehicles and Edit Mode on each supported client, including keyboard/gamepad modes where available. A fresh reload is required to discard taint retained from older loaded code.

## Possession and override layout — 23 October 2026

The user reported `ActionBarController_UpdateAll → StanceBar:Update → HideOverride → UpdateActionBarLayout → RightManagedFrameContainer:SetSize` during possession/override transitions on Forever and Retail. The stack identifies the blocked operation, not the first taint writer. A shared source-level cause exists in Flux's boss/arena positioning: it wrote `ignoreInLayout = true` while the stock container could still be parented to the native right-side layout. `BaseLayoutMixin:AddLayoutChildren` reads that field before testing whether a child is shown; even a hidden container therefore exposes an addon-owned layout value to the protected resize.

[Boss positioning](../Other/FluxBossFramePosition.lua) and [arena positioning](../Other/FluxArenaFramePosition.lua) now reparent the Flux-positioned container to `UIParent` outside combat instead of writing `ignoreInLayout`. Native layout methods, system settings, scripts and managed-frame tables retain their ownership. The existing position-manager opt-out remains. Edit Mode exit and top-level UI restoration queue reapplication after the native pass; encounter events during combat defer positioning until regeneration.

[Vehicle refresh](../Bars/Vehicle.lua) now captures namespaced `C_ActionBar` APIs with legacy-global fallbacks and includes possession, bonus and temporary-shapeshift states in its change signature. Possession entry/exit no longer disappears behind an unchanged vehicle/override signature. Out-of-combat repair detects a stale possession page; combat action attributes remain owned by the existing secure drivers. The Lua temporary-token resolver now uses page 11 when no usable index exists, matching its restricted counterpart. Existing temporary-page modifier/promotion rules and native cancel-possession controls remain in effect.

[The possession-layout regression](../tests/possession_layout.lua) executes both supplied branches' native controller, stance visibility, Edit Mode positioning and LayoutFrame methods. A field-ownership/lockdown model rejects the former hidden-child policy and checks 40 combat control transitions per branch, native page completion, combat deferral, Edit Mode and UI restoration. [Bar refresh tests](../tests/bars_refresh_regression.lua) also cover possession-only changes, bonus possession, temporary shapeshifts, override, vehicle, exit, coalescing, stale-page repair and both API surfaces. [The validation run](validation/possession-control-2026-10-23.json) passed 711 Lua syntax checks and all 73 standalone tests. These are desktop/source fixtures, not WoW's taint VM. Fresh `/reload` checks of Mind Control/possession, override/vehicle entry and exit, held modifiers, cancel controls and Edit Mode remain required in Retail and Forever; this change does not establish that every possible native layout taint is resolved.
