# Action bars

`Flux.Bars` owns the bottom strip, secure click surfaces, pet/stance bars and hover-to-bind mode. Blizzard action slots store content; Flux-owned widgets provide presentation and clicks. [Init.lua](../Bars/Init.lua) is the entrypoint. Current TOC loading, rather than older engine terminology in comments, establishes the implementation.

## Structure and startup

There are **19 columns**: 12 page-dependent native columns and 7 static columns. Every column has main, `sec` and `tert` hosts: 57 surfaces. `Bars.hosts[column]`, `GetHost`, `GetMain`, `ForEach` and `ForEachHost` are the registry/traversal API. Minis are half-size.

`Start()` runs once outside combat: prepare stock bars; start vehicle handling; create strip/state headers; build main/mini hosts; install clicks/drivers/watches; start program-face translation, cast effects and layout; apply slots/options. [Hosts.lua](../Bars/Hosts.lua) chooses modern `ActionBarButtonTemplate` or Classic `ActionButtonTemplate`. Stock `ActionButton1–12` stay suppressed. Columns 13–19 borrow Blizzard commands exposed by `Hosts.BindingCommand()` while displayed labels remain Action Buttons 13–19.

Initial visual constants are 44px buttons, 0 padding, 4px margin, 1.24 scale and 4px vertical offset. [Strip.lua](../Bars/Strip.lua) adds shared squeeze/scaling and gamepad adjustments. Effective geometry also depends on current layout/options.

## Pages, modifiers and promotion

[SlotMath.lua](../Bars/SlotMath.lua) is the pure model; [State.lua](../Bars/State.lua) reproduces it in restricted handlers. They must agree.

| At-rest surface | Columns 1–12 | Columns 13–19 |
|---|---|---|
| Main | `(page - 1) * 12 + column` | Slots 13–19 |
| SHIFT mini | Slots 61–72 | Slots 49–55 |
| CTRL mini | Slots 25–36 | Slots 37–43 |

**Native page** covers ordinary page, forms/stances, stealth variants, vehicle/possess/override and supported skyriding states. Six headers cover main/sec/tert × dynamic/static columns. **Modifier selection** resolves at keypress from pre-stamped SHIFT/CTRL attributes through `SecureButton_GetModifiedAttribute`. It does not wait for the modifier state driver. A modifier hub/child updates keep visible identities and `host.slot` synchronized. This distinction is essential when combat starts with a modifier held.

[Layout.lua](../Bars/Layout.lua) packs occupied columns left and promotes mini content into empty mains. One available mini can serve both modifier paths; two minis can use promoted-main/remaining-mini behavior. Hover, drag and binding mode expand the compact view. `ApplyMappings()` changes slot relationships; `ApplyVisual()` changes anchors/visibility. Structural Show/Hide/SetPoint work defers through combat; already-created surfaces have safe reveal/alpha paths.

## Input and compiled overlays

[Clicks.lua](../Bars/Clicks.lua) routes keys as `KeyBind` clicks onto the main host. Shared `Flux.ButtonFX.Click` controls mouse/key-down/hold-release behavior, with empower attributes reasserted as required. Binding changes invalidate key caches.

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

The [stance shell](../Bars/Stance/Init.lua) combines true forms, class extras and custom slots. Hidden Blizzard donors retain native secure behavior; EBS faces provide Flux presentation. `Order.lua` persists per-character order, hidden keys and additions. `Extras.lua` discovers class helpers, deduplicates form abilities and tracks active auras/pets. Visual aura changes repaint instead of rebuilding discovery/layout. Options support reorder/hide and cursor-added slots.

## Configuration and verification

`FluxOptions:GetActionbarsDB()` selects account/character settings; stance order/custom slots remain per character. `ApplyPerformanceSettings()` configures distinct queues: action range 0.25, extra range 0.18, macro mouseover 0.07, macro-usability minimum 0.05 and optional action-usability minimum 0 by default. [Options](26-options-map.md) records exact controls.

`/fluxbars` reports state; `<column>` prints surfaces; `page`/`paging` prints the secure chain; `mo`/`mouseover` prints targeting; `smoke` runs slot-math assertions. The [local smoke harness](../Bars/_tmp_barsmoke.lua) checks mapping/selected lockdown contracts, not live protected execution.

Vehicle abilities page onto the first 12 Flux columns. Blizzard vehicle/override chrome differs from suppressed unused bars; modern Settings hooks avoid replacing taint-sensitive globals. Verify vehicles, forms, held modifiers at combat entry, mouse/wheel hovercast, native flyouts, promotion and identity-stable effects in game on each family.
