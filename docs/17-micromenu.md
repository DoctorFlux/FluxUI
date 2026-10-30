# Micromenu, bag controls and addon buttons

## Nil-center startup correction — 30 October 2026

The user's native stack reaches `MicroMenuContainer:GetEdgeButton` from
`FluxMicroMenu:UpdateLayout()` while `SocialsMicroButton` is still an
unpositioned Blizzard `MicroMenu` child. Classic native
`MicroButton_OnShow` calls `MicroMenuContainer:Layout()` synchronously, and
the edge calculation compares nil centers. The rebuild now reparents every
selected button and stages unused layout children before any native
Show/Hide callback. It finishes hiding unused children after Flux layout,
without replacing Blizzard's `Layout` or `GetEdgeButton`. The expected
result is no nil-center error when the LFG button triggers a rebuild, while
button visibility, order and placement stay the same.

The focused [regression](../tests/micro_menu_nil_center.lua) reproduces the
old nil-center comparison, checks the new callback order and final parking,
and passes. The existing MicroMenu smoke also passes. Full desktop
validation passes **109 tests / 753 Lua syntax files**, zero failures:
[result](validation/micromenu-nil-center-full-2026-10-30.json).
[Exact source hashes](validation/micromenu-nil-center-source-hashes-2026-10-30.json)
identify the candidate against main `57a252e0e2b467cf7788c3f52aa5d1dd8d83779e`.
The pre-edit source archive was preserved outside AddOns as
`flux-micromenu-before-nil-center-20261030.zip` (SHA256
`A1D51607F04F6B58513FF9F89C087001D17691A72F17D89F63C525F74258ED11`);
the dated history bundle remains verified. The read-only Era reference
`MicroMenuContainer.lua` has SHA256
`B64C7406308CC41EC4A6CD833A31C544958E994ED4CC978389195449F76F63A4`;
`Classic/MainMenuBarMicroButtons.lua` has SHA256
`42D1C5FCCB1D5C5678F5032C37664BC04595B415DB8E55F56D8D27D091341860`.
The user's stack establishes the pre-fix failure; native post-fix reload,
LFG appearance, Edit Mode, combat deferral, pixels, taint and frame time
remain pending across the five supported clients.

`FluxMicroMenu` replaces the visible micro-button row with a configurable container of native Blizzard buttons, Flux actions, learned professions and selected minimap-addon shortcuts. [FluxMicroMenu.lua](../MicroMenu/FluxMicroMenu.lua) owns creation/discovery, button art, native/custom hover effects, layout and rebuild. It initially anchors top-left; Layout can select another placement.

## Runtime composition

The core probes actual native buttons, caches discovery and invalidates it when new UI becomes available. Missing client buttons are omitted. Modern/Forever HUD shells and Classic shells use different geometry even when some atlas files exist on both clients. Class portrait/spec glow and custom icon mouseover are separate style paths. `CreateMicroButton`, `GetDiscoveredMicroButtonNames`, `GetDefaultUnifiedRowIds`, `RefreshLayout` and `Rebuild` are the main consumer APIs.

Native button reparenting/visibility and protected geometry can defer until combat ends; `needsUpdate` and refresh/rebuild paths reconcile afterward. Level/talent/portrait events update relevant faces. Layout coordinates with chat, the unit-frame column, minimap embedding, status bars and the unified border, rather than assigning each button an independent saved screen anchor.

## Unified order and three different scopes

[FluxMicroMenuConfig.lua](../MicroMenu/FluxMicroMenuConfig.lua) merges rows under stable IDs:

| Row ID | Source |
|---|---|
| Native/global name | Blizzard or Flux micro button. |
| `M2M:<sourceName>` | Named minimap-addon button. |
| `TSK:<skillKey>` | Individual learned profession. |
| `FluxTradeSkillFlyoutMicroButton` | Profession flyout opener. |

Native visibility cycles **Account / Character / Off** using `FluxUI_DB.MicroMenu.native` and `_FluxUI_CharSavedVars.MicroMenu.native`. Unified ordering follows the **Micro Menu tab's scope**, using the corresponding `unifiedOrderList` and version/initialization fields. Layout placement scope does not select this order. Minimap shortcuts retain their own MinimapToMicro data; professions are always character-specific. These controls must not be described as one universal scope switch.

Normalization migrates older row IDs, removes inappropriate queue-status rows, deduplicates minimap sources, inserts new canonical defaults and preserves valid order. Scope changes copy the relevant order. The [configuration UI](../MicroMenu/FluxMicroMenuConfigUI.lua), embedded by [its AceGUI widget](../MicroMenu/AceGUIWidget-FluxMicroMenuEmbed.lua), renders preview slots, drag ordering, mode cycling, drop targets and reset controls. Right/middle-click on a preview cycles visibility; drag indices refer to the full unified order, not just the filtered visible row.

## Flux action buttons

| Loaded feature | Role |
|---|---|
| [Reload](../MicroMenu/FluxReloadMicroButton.lua) | Reload UI shortcut. |
| [Macro](../MicroMenu/FluxMacroMicroButton.lua) | Opens macro UI through supported client loading. |
| [Config](../MicroMenu/FluxConfigMicroButton.lua) | Opens Flux options. |
| [LFG](../MicroMenu/FluxLFGMicroButton.lua) | Uses available group-finder UI, queue/applicant state and client fallback when a native row is unavailable. |
| [Bag](../MicroMenu/FluxBagMicroButton.lua) | Bag toggle, free ordinary-bag space and equipped bag-slot popup. |
| [Addon](../MicroMenu/FluxAddonMicroButton.lua) | Collects suitable addon/minimap buttons into a clamped popup. |

The bag count excludes keyring/reagent storage when representing ordinary backpack capacity. [Container.lua](../Core/API/Container.lua) supplies the live native total to the micromenu, chat bag button and Flux-owned bag headers through one event-driven subscription path, including late bag readiness after login. It does not wait on inventory snapshots or copy another button's cached text. See the [compatibility verification](47-chat-layout-compatibility.md). Carried-bag IDs for the per-bag breakdown come from inventory compatibility. Left-click toggles bags; right-click opens equipped-bag slots when those slots do not already live inside the bag window. The tooltip supplies ordinary free space and per-bag breakdowns. Changing equipped bags affects popup geometry and counts.

[FluxCombinedBagHeader.lua](../MicroMenu/FluxCombinedBagHeader.lua) adds **owned square equipped-bag slots inside native combined bags** on supported Live/Forever mouse UI, reserving room between search/sort and the item grid. Alternative bag UIs and Forever gamepad mode skip this intervention. This is a header extension, not the shared inventory scanner or the Classic combined-bag implementation.

## Minimap-addon collection and profession buttons

[FluxMinimapToMicro.lua](../MicroMenu/FluxMinimapToMicro.lua) discovers named minimap buttons, resolves friendly names/icons, builds micro proxies and forwards supported source interactions. Per-source account/character/off state and ordering determine whether the source appears directly on the row or remains in the addon popup. It cooperates with `FluxAddonSystem` to prevent duplicate representation. Sources created late need rescanning; unnamed/unsupported sources may not be eligible.

[FluxTradeSkillMicro.lua](../MicroMenu/FluxTradeSkillMicro.lua) enumerates learned professions with compatible spellbook/API fallbacks, keys them stably and opens the relevant skill UI. `_FluxUI_CharSavedVars.MicroMenu.tradeSkills` stores `enabled`, layout mode, global style and per-skill placement. Modes support per-profession configuration, fixed split or global individual/flyout/both behavior. An older account copy can seed character settings. Spell/skill events refresh discovery; movement closes transient popups and combat can defer structural changes.

## Verification and integration

ConsolePort micromenu takeover is suppressed by its own optional compatibility layer. See [integrations](29-integrations.md), [layout](06-layout.md) and [options](26-options-map.md).

Check account/character/off independently from order scope, newly learned skills, late addon buttons, proxy clicks/tooltips, popup clamping, free-space counts, bag replacement, combined-bag search/sort clearance, three layout placements and combat rebuild deferral. The micromenu/bag-slot mock harnesses exercise selected contracts; actual native button clicks, gamepad and optional-addon coexistence need in-game verification.
