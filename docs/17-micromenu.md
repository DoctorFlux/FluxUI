# Micromenu, bag controls and addon buttons

## Forever native profession button restored - 5 November 2026

The user clarified that Blizzard's own trade-skill/profession button should stay.
The prior exclusion of ProfessionMicroButton was broader than intended. It now
uses the ordinary native eligibility, discovery, saved visibility and layout path;
it is no longer forcibly excluded or parked on Forever. Existing discovery merge
restores a row pruned by the previous build without resetting preferences.
FluxTradeSkillMicro still exits before creating custom profession/flyout frames
or registering events on Forever, and its trade-skill option controls remain
omitted. Adventure Guide stays excluded. Other clients keep their existing behavior.
The previous removal section below is historical; this clarification supersedes
its references to hiding the native profession button.

Baseline dfc2781af138105fbfc1388d354b101338ae5162. Verified external
Forever-native-profession-20261105T103323Z preserves1,453 actual files, history and123
on-disk settings outside AddOns; source ZIP SHA256
`d2ade9bd109da2577758b9e67f2edbd6ba29e4c8535ab00dbf40a28437354fea`.
[Raw pairs and exact runtime hash](validation/forever-native-profession-comparison-2026-11-05.json).
[Full validation/source manifest](validation/forever-native-profession-2026-11-05.json).

Five alternating fresh-process desktop pairs execute the real custom startup,
options builder and native eligibility function with mocked frames/APIs:54 checks,
baseline2 failures versus candidate0. They cover both Forever identity aliases
and four other client labels, restored native profession eligibility, the retained
Adventure Guide exclusion, disabled Forever custom service/options and preserved
preferences/other clients. Startup custom frames remain16 across all models (zero
per Forever model) in both variants. No new frame, event, timer, hook, scan or saved
root. Warm-up0; wall samples include startup/assertions, not native latency.
Full129 scripts/784 syntax files pass. No FPS or native secure/pixel pass is claimed.

After sync and /reload, verify Blizzard's profession button appears according to
saved menu visibility/order and opens its native panel. Confirm no custom profession
icons/flyout/trade-skill settings or Adventure Guide button on Forever. Test late
profession updates, menu layouts, combat/recovery, tooltips, gamepad and taint.
Native acceptance is pending; no foreground/input/clipboard control was taken.

## Forever trade-skill micro removal - 5 November 2026

The user requested no trade-skill micro menu on Forever. Both existing Forever
identity flags now stop FluxTradeSkillMicro before its namespace, frames, timers,
events or skill scanning are created. This removes individual profession buttons
and the shared secondary-skill flyout. ProfessionMicroButton is excluded through
the same local eligibility/optional-button parking used for Adventure Guide, so
no native profession button or empty slot is left. The tradeSkills option entries
are omitted on Forever; the general editor, button sizing and other clients keep
their existing behavior. Stored trade-skill settings/order entries remain intact.
Native profession windows, learned spells, keybinds and crafting APIs are unchanged.
This is an explicit Forever UI removal, not a global capability change or reset.

Baseline0602a31a1ba5d36b04a9a197715ffd0ac5e4c029. External recovery
Forever-tradeskills-20261105T101715Z preserves1,451 actual files, verified history
and123 available on-disk settings outside AddOns (not unsaved in-memory settings).
Source ZIP SHA256:
`daba71d80494274317e19100d4a3259f557aaac906cdcb42ae3037d853e58904`.
[Raw pairs/exact candidate hashes](validation/forever-tradeskills-comparison-2026-11-05.json).
[Full validation/source manifest](validation/forever-tradeskills-2026-11-05.json).

Five alternating fresh-process desktop pairs load the real trade-skill startup,
menu eligibility and options code under mocked native frames/APIs. Two Forever
identity aliases and four other client labels: baseline10 failures, candidate0
of48 checks. Frame counts across six models24 to16: four trade startup frames
removed per Forever identity model. Event/timer registration stays zero on those
models; non-Forever module/options and stored settings controls pass. Zero warmup;
wall times include interpreter startup/assertions and are not native performance.
Full129 scripts/784 syntax files pass. No new frames, timers, event subscriptions,
hooks or settings roots are added; existing native parking handles re-show.

After sync and /reload, confirm no profession icons/flyout or trade-skill controls
in Forever's micro menu, with compact spacing in all menu positions and no late
reappearance after profession updates/combat. Confirm native crafting access still
works and other clients retain their configured profession rows/options. Screenshot,
gamepad, input/taint and native performance checks remain pending; no connected
game runtime or foreground/input/clipboard control was used.

## Forever Adventure Guide exclusion - 5 November 2026

The user explicitly requested no Adventure Guide micro button on Forever.
The local menu eligibility function returns false for EJMicroButton under either
existing Forever/Camelot identity flag, before consulting the shared capability.
This excludes the native row from discovery/configuration/layout and reuses the
existing optional-button parking/re-show hook. No placeholder layout slot is
reserved. Native feature APIs, guide keybinds, other clients, other buttons and
stored row preferences remain intact; no new setting or frame/timer is added.
The existing one-time parking hook applies to this now-excluded button.

[Focused gate/parking pairs](validation/forever-guide-comparison-2026-11-05.json):
34 checks, baseline8 failures versus candidate0 in five matched pairs, including
both Forever aliases, four other client labels, repeat parking, native re-show,
combat mutation guard and unchanged shared capability. APIs/frames are mocked;
no native pixel/taint/performance certification. Existing full menu validation
passes; the complete bank+menu batch passes129 scripts/784 Lua syntax files.
Recovery Forever-guide-20261105T100106Z preserves1,446 actual files/history and123
on-disk settings outside AddOns; ZIP SHA256
24a4540fe6db1afe04e63f17bc6ae11469e6928699ab23b20f5121d9ad972b75.
After sync and /reload: check all three menu layouts, configured row order, late
Blizzard button Show, combat/recovery and compact spacing on Forever; verify the
guide remains as previously configured on Retail and other supported clients.
Native screenshot/layout acceptance remains pending.

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
