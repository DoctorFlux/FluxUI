# Options rework — 9 November 2026

Change ID: OPTIONS-REWORK-20261109. Baseline main `26f886e3ea5371b196ab235d2dace0c156002285`.
User chose **Implement directly** on 9 November; no preliminary mock-up.

Latest compatibility fix (REQ-OPT-34): the user reported Classic Era failing in
`NineSlice.ApplyLayout` while opening settings. `PortraitFrameMixin:SetBorder`
exists on Classic but its portrait NineSlice layout does not. The Classic XML
draws separate border textures; Mainline/Forever initialize their NineSlice from
the native child OnLoad. `CreateWindow` now leaves this initialization to each
client's original template, removing the unconditional layout-name override.
The previous stub accepted any border name and missed this defect. Tests now
execute real pinned layout/lookup/apply/portrait and Classic OnLoad methods.
All five client contracts remain required; native retest is still pending.

Latest placement correction (REQ-OPT-33): **Inventory awareness** now lives inside
**Loot & Items → Loot**. Status Bars excludes that section. The original controls,
callbacks, saved fields and Status Bars storage scope remain unchanged; the
existing source selectors move the section without a separate sidebar entry.

Latest HUD correction (9 November, REQ-OPT-30 through32): remove the Quality of
Life sidebar page. **HUD** is a collapsible sidebar header with **Layout, Chat,
Info, Micro Menu, Flux Window, Status Bars** entries and fitting icons. Windows
moves to Utilities alongside Professions. Layout is visible again and uses the
original scope, reset and `FluxLayoutPreview` editor. Flux Window has **General**
and **Damage Meter** tabs; actual Meter-tab right-click opens the latter and
expands a minimized HUD header. The general Flux Window shortcut selects General
explicitly, independent of the previously active tab. Old QoL links redirect.
No saved data, feature builder, skin or game-input behavior changes.

Earlier consolidation and bug-fix request (9 November): Unit Frame now has
**General, Individual Frames, Party Frames, Raid Frames, Cast Bars, Nameplates**
sidebar entries. General merges shared appearance. The user chose **four unit tabs
inside Individual Frames**: Player, Target, Focus, Pet. Loot & Items is a sidebar
header containing **Loot, Vendor, Restock**; Restock has the native bag icon.
Quality of Life has **Windows, Chat, Info, Micro Menu, Flux Window, Status Bars,
Damage Meter** tabs. Raid preview choices/entry start at ten members; the explicit
party preview remains five. Forever's background cover disables inherited tiling
and restores visibility/alpha on resize. Sidebar headers minimize/expand, search
temporarily reveals matches, and clearing search restores the minimized state.
These are explicit follow-up requirements, REQ-OPT-23 through29; no new background
goal was created after the user cleared it.

Earlier sidebar clarification (9 November): **Unit Frame is a framed sidebar
header like Combat**. General, Appearance, Player, Target, Focus, Pet, Party Frames,
Raid Frames, Cast Bars and Nameplates are individual clickable rows beneath it,
each with a fitting icon. Selecting a row opens that section directly; Unit Frame
has no horizontal tab strip or category button. REQ-OPT-22 corrects the earlier
interpretation of category as a single page. Existing internal `unitframes` and
subpage IDs, callbacks, scopes and saved data remain.

Earlier category correction (9 November): **Unit Frame** is an independent
top-level sidebar category beside Quality of Life, with all ten existing frame
tabs inside it. Combat contains **Action Bars, Bindings, Keybindings**. REQ-OPT-21
supersedes the earlier placement of Unit Frames inside Combat. The internal
`unitframes` key and all source callbacks/aliases stay unchanged.

Earlier Unit Frames clarification (9 November): Combat contains **Unit Frames,
Action Bars, Bindings, Keybindings**. The user explicitly confirmed moving
Quality of Life's Combat content into Unit Frames. Unit Frames is reorganized
into **General, Appearance, Player, Target, Focus, Pet, Party Frames, Raid Frames,
Cast Bars, Nameplates**. Individual-unit child targets remain with their parent.
REQ-OPT-18/19/20 cover these new placements and retain every original control,
source context, scope and old settings link. Earlier four-tab QoL and Utilities
placements below are historical; current QoL has Interface, Status Bars and
Damage Meter, while Utilities contains Loot & Items and Professions.

Latest sorting clarifications (9 November) are part of the active goal:
consumables, Trinket Menu, travel buttons and extra-button visibility belong in
**Action Bars > Extra Buttons**. Flight-path display settings and Swing Timer
belong in **Unit Frames**. **Bindings** is the spell/item/macro browser;
**Keybindings** remains separate. **Loot & Items** gets its own sidebar page
with **Loot, Vendor & Junk, Restock** tabs; the Restock tab also holds its vendor
and bank automation switches.
The user permits functional FluxUI organization instead of literal Naowh labels.
The supplied compact framed style, fitting icons, client-native skins and Escape
entry remain required. Earlier ten-tab and seven-tab arrangements are superseded.
The reported Meter-tab right-click regression must open Damage Meter settings.

The later supplied 180×675 sidebar screenshot is the accepted layout reference:
compact gold-text rows, framed Adventure / Combat / Utilities headers, search
above the list, and framed system buttons fixed at the bottom. The user explicitly
requests a fitting icon beside each name. REQ-OPT-10 adds this requirement on
every client, including Forever; it supersedes the interim icon-free Forever
list styling. [Reference identity and before-source checkpoint](validation/options-sidebar-reference-2026-11-09.json).

Use the supplied Naowh Forever 1.2.19 as a read-only design reference for
navigation, tabs, grouped settings and search across the entire FluxUI. Its own
code and artwork are all rights reserved; this implementation uses original
FluxUI code and Blizzard assets, with no copied reference source or media.

| Requirement | Implementation / observable acceptance | State |
|---|---|---|
| REQ-OPT-01 | Sidebar, subpage tabs, grouped/collapsible controls for every existing catalog page; existing callbacks and embedded editors remain reachable | Implemented; desktop PASS; native visual/editor acceptance pending |
| REQ-OPT-02 | Forever native portrait/window/inset art; other clients use their loaded native templates, including existing Era/Anniversary targets | Implemented; five pinned source contracts; native pixels pending |
| REQ-OPT-03 | Search setting names and descriptions across pages; select a matching subpage without constructing every editor | Implemented; cross-page/tab and hidden/getter checks PASS |
| REQ-OPT-04 | Escape menu FluxUI Settings button; repeated rebuilds show one entry and return opens the common shell | Implemented; lazy-load/rebuild/click/gamepad-order models PASS; native pending |
| REQ-OPT-05 | Preserve saved roots, profiles, commands, confirmation, validation, hidden/disabled conditions, protected-change deferral and existing Escape ownership | Builders/defaults/data untouched; existing regression suite PASS; native persistence/taint pending |
| REQ-OPT-06 | Responsive resizing, scrolling, tooltips, empty search feedback and close/reopen cleanup | Implemented; full lifecycle model PASS; native input/clipping pending |
| REQ-OPT-07 | Initial literal reference category/tab names; fixed system footer | Literal taxonomy superseded by REQ-OPT-11/13 at user's request; compact style and footer retained |
| REQ-OPT-08 | Place settings with their matching feature, retaining source context | Locations follow latest functional taxonomy; one primary source-leaf location and original object/root/info-path checks PASS |
| REQ-OPT-09 | Preserve previous settings links after moves | Implemented; route aliases and action-bar helper updated; native entry interactions pending |
| REQ-OPT-10 | Match the supplied compact framed sidebar and show fitting icons beside feature/system names | Implemented: 24-unit feature rows, 18-unit framed headings, 22-unit framed system rows and 16-unit icons; model checks PASS; actual pixels pending |
| REQ-OPT-11 | Consolidate Action Bars, extra buttons, Consumables, Trinket Menu, Travel and utility/stance controls | Implemented as Bars, Extra Buttons and Stance Order; one original complete Extra Buttons group; placement checks PASS |
| REQ-OPT-12 | Bindings is the spell/item/macro browser; Keybindings is a separate page | Separate sidebar pages superseded by REQ-OPT-36; both tools retained as tabs |
| REQ-OPT-13 | Organize actual FluxUI features rather than retain empty reference placeholders | Implemented; three QoL tabs, Combat and Utilities groups; no misleading Macros/Glimmer/crosshair/library pages |
| REQ-OPT-14 | Keep Swing Timer and flight-path display settings in Unit Frames | Implemented in Unit Frames > Player; no separate Swing Timer page; original objects retained |
| REQ-OPT-15 | Flux Window Meter-tab right-click opens Damage Meter settings | Dedicated accessor replaces stale generic Flux Window destination; actual OnClick-to-shell regression PASS |
| REQ-OPT-16 | Loot & Items has its own sidebar page | Implemented under Utilities; loot, vendor/junk and restock retained; old links redirect |
| REQ-OPT-17 | Give Loot & Items focused tabs | Loot, Vendor & Junk, Restock; both restock switches sit with targets/editor; original declarations and old routes retained |
| REQ-OPT-18 | Earlier Combat grouping of Unit Frames with bars and bindings | Unit Frame placement superseded by REQ-OPT-21; Combat retains Action Bars, Bindings, Keybindings |
| REQ-OPT-19 | Move QoL Combat settings into Unit Frames, as explicitly confirmed | Cast Bars and Nameplates tabs; QoL Combat and original links redirect; exact original-leaf locations PASS |
| REQ-OPT-20 | Reorganize Unit Frames settings and tabs | Ten focused tabs; General setup/scopes versus Appearance; Party versus Raid; original nested callbacks, hidden/disabled gates and Nameplates dependency invalidation PASS; native visual/input pending |
| REQ-OPT-21 | Unit Frame is its own category with the singular label and all frame sections | Singular label retained; category presentation clarified by REQ-OPT-22 |
| REQ-OPT-22 | Unit Frame is a framed sidebar header | Header retained; ten earlier rows consolidated by REQ-OPT-25 |
| REQ-OPT-23 | Include Vendor and Restock under Loot & Items | Loot, Vendor, Restock sidebar children with icons; original source objects/scopes retained |
| REQ-OPT-24 | Raid preview minimum is ten | Choices/get/set and raid Show/Toggle enforce10–40; old5 remains unchanged merely reading settings; explicit party preview stays5; combat guard retained |
| REQ-OPT-25 | Merge unit entries and General/Appearance | General includes appearance; Individual Frames has user-selected Player/Target/Focus/Pet tabs; old links redirect to correct pane/tab |
| REQ-OPT-26 | QoL needs focused per-feature tabs | Superseded by REQ-OPT-30/32: focused HUD entries and Flux Window tabs; original leaves retain one destination |
| REQ-OPT-27 | Background remains when resizing smaller | Forever atlas disables native rock tiling and restores visibility/alpha; cover bounds/resize models PASS; other client backgrounds retained; native verification pending |
| REQ-OPT-28 | Restock icon is visible | Uses existing native bag texture; child icon/label/click model PASS; native pixels pending |
| REQ-OPT-29 | Minimize sidebar categories | Click framed headers; +/- state, search reveal/restore, explicit-link expansion and fixed footer tested; state retained while window instance exists; no new SavedVariables |
| REQ-OPT-30 | Replace QoL with HUD sidebar category and move remaining features appropriately | HUD contains Layout/Chat/Info/Micro Menu/Flux Window/Status Bars; Windows moves to Utilities; all canonical pages are visible in exactly one sidebar category; original objects/aliases/scopes preserved |
| REQ-OPT-31 | Restore old Layout under HUD | Original layout builder/independent scope/reset and preview widget retained; sidebar click, acquire/width/hide/release lifecycle checked; native drag/resize/persistence pending |
| REQ-OPT-32 | Damage Meter belongs inside Flux Window and Meter right-click opens it | General/Damage Meter tabs; actual production right-click-to-shell and minimized-HUD expansion checked; general shortcut remains explicit; old QoL routes redirect |
| REQ-OPT-33 | Inventory Awareness belongs inside Loot | Original `statusBars/invTip*` controls appear once in Loot & Items > Loot; Status Bars excludes them. Search, original callback context and Syndicator disabled gates pass; no schema/scope migration or new sidebar row |
| REQ-OPT-34 | Opening settings works on every client, including reported Era nil-layout failure | Remove unconditional SetBorder override; retain native Mainline/Forever NineSlice and Classic texture initialization. Real pinned Lua reproduces old failure on progression/Era/Anniversary and passes candidate on all five; native input/pixels/controller retest pending |
| REQ-OPT-35 | Sidebar order: Combat, Loot & Items, Utilities, HUD, Unit Frame | Catalog order and full shell/placement checks PASS; fixed footer retained |
| REQ-OPT-36 | Combine Bindings and Keybindings | One Bindings entry with Bindings and Keybindings tabs; original browser/actions/scopes, old routes and cross-tab search retained; desktop PASS |
| REQ-OPT-37 | Shared threat warning visibility: Always, In raid, In party, Off | Existing threatBarVisibility key and Unit Frame scope own both pages and target/focus/nameplate gates; legacy values retained; desktop PASS |
| REQ-OPT-38 | Raid/party behavior agrees on nameplates and target | Shared Flux.Threat gate covers all four bar positions and NPC/player nameplate warnings; party includes raids, raid-only excludes parties; desktop PASS; native pending |

Native source pins (resolved 9 November): Retail/live
`297d7aaaa736f346b3e036f38ee088eaf7f8c07f` (12.1.5/70783), Forever
`9dc84f0d3bbae1768ac3405b3716000bd93eda06` (1.60.1/70862), Classic progression
`e5d9b3a22c3f0f6f41ebac0e454f4969594261cf` (5.5.4/70631).
Existing additional targets retained: Era `4192ac60067fc55566182291bc67c85dd9b6794d`
(1.15.9/70576), Anniversary `68e0a2ec559d9761dfc4e7f864c3944f9d758a49`
(2.5.6/70577). [Exact pinned files and reference hashes](validation/options-source-pins-2026-11-09.json).
Native templates load through Blizzard_SharedXML's `[Family]` includes, with
Forever `[Game]` NineSlice overrides. MainMenuFrameMixin's button pool is reset
by GameMenuFrame.InitButtons; integrate through a secure post-hook, never through
RegisterGameMenuEscHandler. Existing Flux.Client detection remains canonical.

Recovery: [verified source/history checkpoint](validation/options-checkpoint-2026-11-09.json).
120 on-disk settings metadata entries inspected read-only; no live/quiescent
settings backup or settings/profiler write claimed. Work remains in existing main.

Implementation: catalog, common shell, renderer/widgets, native skin helper,
game-menu integration and TOC ordering. No reference-addon source/media copied.
The menu entry follows native Options in mouse mode. In gamepad mode it stays at
the native append position so visual order matches the navigation array; native
reset/setup updates the wrap links. No shared Escape handler registration.

Initial validation: `lua tests/options_rework.lua` passed 240 checks across five modeled
clients with the complete production shell/renderer/widgets. Old shell and old
renderer each fail the corresponding native-window/card assertion, with evidence
retained outside AddOns. Existing dynamic-range (298), Escape/menu (121) and core
smoke checks pass. The full suite passes 271 scripts and 940 syntax files. These
are desktop contracts, not game rendering, secure VM or performance measurements.
One native card frame per rendered section, an empty-state frame per built page,
native template children, two utility buttons and one short-lived login/addon-load
event driver are explicit feature costs. No new polling, ticker or OnUpdate;
search evaluates declarations only while requested. Row-owned accent callbacks
are now removed on release so closed pages stop receiving appearance work.

## Earlier literal-reference pass (superseded taxonomy)

The user explicitly approved reorganizing settings to match the reference.
Current navigation is documented in [the options map](26-options-map.md), with
every original declaration's destination in
[the generated placement ledger](validation/options-navigation-map-2026-11-09.csv).
`FluxOptionsNavigation` composes views over the original option objects; the
renderer retains each object's original root and info path. Source-builder
generation changes invalidate dependent views. No saved schema or profile was
migrated. Existing extra-button visibility controls now also appear with their
consumable, trinket, travel and action-bar features through the same visibility
owner; its class/client availability and valid mode lists remain authoritative.

Settings, Profiles, Patch Notes and Credits stayed in a fixed sidebar footer.
That intermediate pass retained all ten reference tab labels and their order;
only modules with FluxUI functionality received feature pages. Missing
Glimmer/crosshair/smart-macro systems had explanatory links. The latest functional
sorting removes those empty placeholders and retains four implemented QoL tabs.
Unit Frames is an additional FluxUI feature under Combat. Foreground/game input
remains untouched.

The second fidelity pass uses Forever's native `MinimalTabTemplate` (Options tab
art), `MinimalSliderTemplate`, and available Journeys background artwork. Other
clients retain their family templates. Native tab `Text` ownership and slider
thumb ownership are checked explicitly. The global accent still configures HUD
appearance; navigation help now points to the reorganized pages.

Earlier focused checks: **4,908 navigation checks** using the real registered
builders across five client models, plus **421 complete shell/widget lifecycle
checks**. Three deliberately harmful catalogs are rejected: wrong category name,
lost consumable setting, and moved flight settings sourced from the wrong parent.
[Negative controls](validation/options-navigation-controls-2026-11-09.json).
These checks establish declaration coverage and callbacks, not real native UI.
Full current-suite and documentation results are recorded in the navigation
validation report. The earlier 271/940 result remains historical.

The compact sidebar is 220 UI units wide to make room for the requested icons.
All feature/system icons use their catalog entries, with 16-unit artwork,
6-unit text gaps, and smaller native fonts. Forever no longer hides those icons.
Headings and fixed footer buttons use framed dark backgrounds with bronze edges
on Forever and neutral edges on other clients. Search text matches the reference.
These dimensions and source-based checks do not establish native screenshot
parity or the actual user's UI scale.

Before this follow-up, a new external 2,410-file source/history checkpoint was
verified; 120 settings metadata entries were inspected read-only.
[Recovery](validation/options-fidelity-checkpoint-2026-11-09.json).

Testing choice: **Witchcraft in-game**, explicitly selected 9 November. No
Witchcraft MCP tool is connected; neither Forever nor Retail has
`Witchcraft/Witchcraft.toc`, and the Codex MCP configuration has no Witchcraft
entry. No installation, MCP reconfiguration, helper-addon generation, daemon
launch, client restart, foreground/input or sharing change was performed.
Current Witchcraft source inspected at
`6b4140914dc8f2d724f75ebedbefe04b37f98868`; setup generates 3,000 helper addons,
needs a complete game restart, and sharing starts enabled. It can attach real
assistant sessions; all enabled addons can send agent input/read output. Setup
authorization is still required under the connected-client skill. Native
rendering, gamepad input, settings persistence, combat/taint and performance remain
NOT RUN. Native acceptance remains pending. The user subsequently cleared the
background goal; these implementation follow-ups do not create a new one.

Next action after authorized setup: install/connect the documented Witchcraft
route without taking foreground control, then have the user run `/witch bindprobe`
outside combat and reproduce the following while error snapshots are available:

1. Reload outside combat, open Escape → FluxUI Settings and verify the Forever
   native portrait border, inset backgrounds, gold navigation and native tabs.
2. Visit all six HUD sidebar entries, Flux Window's General/Damage Meter tabs,
   all six Unit Frame sidebar entries
   and the four Individual Frames tabs, all three
   Action Bars tabs, Bindings,
   Keybindings, Loot & Items, Windows and Professions. In HUD > Layout, verify
   the original preview can move/size displays and retain its independent scope.
   Verify restock in the Loot & Items > Restock entry, salvage in Professions, the browser in Bindings, physical-key
   actions in Keybindings, Swing Timer / flight paths in Unit Frames > Player,
   and Party Frames / Raid Frames editors and their independent scope in General;
   check appearance in General, Cast Bars and Nameplates, then all four system pages.
   Minimize each sidebar header, search for a hidden entry, clear search and verify
   its minimized state restores. Check Vendor/Restock entries and icon, resize the
   window smaller/larger, and verify the raid preview minimum10 / party preview5. Right-click
   the Flux Window Meter tab and verify HUD > Flux Window > Damage Meter opens,
   including when HUD is minimized. Verify the general Flux Window shortcut
   opens General even after using Damage Meter. Confirm no QoL sidebar entry.
3. Search a setting on another page; verify its subpage opens. Fold a section,
   search inside it, clear search and check the fold restores. Test no matches.
4. Resize narrow/wide, scroll sidebar/content/tabs and hover tooltips; check text
   and controls for clipping. Change one reversible value and restore it.
5. Close/reopen with Escape; a dropdown consumes its first Escape. Verify native
   casting/targeting cancellation still works after closing. Repeat menu rebuilds.
6. Reload and verify profile/settings retention. Repeat relevant visual/input
   checks on Retail, Classic progression, Era and Anniversary separately.

Read-only native observation: the host confirms Forever process49960 at the
expected executable/window. A PrintWindow capture1906x1032 shows active gameplay
and the game foreground; no settings window is open. No focus/input/reload was
sent, and no candidate visual pass, Lua-error pass or FPS result is inferred. The
private screenshot stays outside AddOns. New collection/trinket settings launchers
are guarded outside combat; existing HUD behavior is unchanged. Full final suite:
275 scripts /945 Lua syntax PASS, with no current corpus drift.

## Current functional sorting and Meter-link correction

Action Bars has three tabs: **Bars, Extra Buttons, Stance Order**. Extra Buttons
uses the original complete extra-button group once, with its visibility editor,
consumable swap controls, travel flyouts and utility slots. There are no duplicate
per-feature visibility selectors. Existing Trinket Menu, mount and hearthstone
configuration launchers remain available there and are guarded outside combat.
Swing Timer and all three flight-path display options remain in Unit Frames >
Individual Frames > Player. Loot & Items is a sidebar header with **Loot, Vendor,
Restock** entries. Vendor and bank restock switches are beside the existing targets/editor
in Restock; their callbacks still use the original vendor root/info paths.
HUD now owns Layout, Chat, Info, Micro Menu, Flux Window and Status Bars. Damage
Meter is a tab inside Flux Window; Windows is under Utilities. Combat contains
Action Bars, Bindings and Keybindings; Unit Frame is its own top-level category.
Utilities also contains Professions. Unit Frames owns the former QoL Combat settings.
Bindings and Keybindings remain distinct. Every original declaration has one
primary destination and retains its original object, root, handler and info path.
Old intermediate IDs redirect to their consolidated pages. No saved schema moved.

The user's reported Meter right-click opened Interface because the old
`OpenToFluxWindowTab()` accessor still targeted general Flux Window settings.
The click now uses `OpenToDamageMeterTab()` to select `fluxwindow/damageMeter`,
while `OpenToFluxWindowTab()` explicitly selects `fluxwindow/general` instead of
the remembered meter tab. Old `qol/damageMeter` still redirects. Tooltip wording follows the
correct destination. The regression executes the actual production Meter click,
window forwarding method and options accessor through the complete shell on all
five client models; restoring the old destination fails that check.

Earlier merged-layout validation: **5,847 real-builder placement checks**, **877 complete
shell checks**, **280 raid option/session checks**, and **78 party contracts**.
Thirteen controls reject old QoL grouping, split General/Appearance, lost Focus,
missing Vendor/Restock sidebar rows/icon, non-clickable headers, lost minimized
search state, stale direct source generation, old five-member raid UI/runtime,
old/unrestored background behavior and forgotten minimize state on reopen. Old source fails; three fresh candidate
processes pass each source-overlay harness. These are functional checks, not
native timings. [Controls](validation/options-merged-layout-controls-2026-11-09.json).
[Earlier complete corpus, owned identities and copies](validation/options-merged-layout-2026-11-09.json).
[Verified source/history recovery and metadata](validation/options-merged-layout-checkpoint-2026-11-09.json).
Native visual/input/persistence/taint/performance remain NOT RUN; selected
Witchcraft setup is still unavailable and its earlier approval request unanswered.

## Unit Frames organization — current user-confirmed layout

Unit Frame is a collapsible sidebar header. Each entry opens its own pane:

| Sidebar entry | Controls |
|---|---|
| General | Frame selection, unit/party scopes, reset actions, shared portraits/overlays, aura timers and threat |
| Individual Frames | Player, Target, Focus and Pet tabs; each keeps its own geometry/text/auras/icons/casting; child targets stay with their parents; Player keeps Swing Timer/flight paths |
| Party Frames | Player-style party mode/layout, portraits, casts, pets and five-member preview |
| Raid Frames | Compact raid/party appearance, bars, auras, sizing, range, highlights and10–40-member preview |
| Cast Bars | School/spell themes and per-unit theme application |
| Nameplates | All original nameplate options, including quest progress |

Loot & Items is its own collapsible header with Loot, Vendor and Restock entries.
Combat keeps Action Bars, Bindings and Keybindings; Utilities keeps Professions.
The four unit tabs and per-feature QoL tabs use the existing native tab widgets.
All original controls retain their raw source roots, handlers, info paths and
scopes. New standalone navigation views use direct source declarations and their
original module generations. Old `unitframes`/subpage links resolve to the new
panes; no data/schema migration is needed.

Raid preview5 was previously reachable from both dropdown and generic entry.
The dropdown/get/set now normalize10–40 in increments of5. Reading a legacy5
shows10 without rewriting saved data; explicit raid Show promotes it to10. Generic
raid Toggle switches an active five-member party preview into a ten-member raid
preview. Explicit ToggleParty passes its five-member request through unchanged.
Combat still rejects Show before size changes. Defaults remain40.

The native Forever portrait background is a tiled rock texture in pinned XML.
Using a cropped atlas while retaining those flags is a plausible cause of the
reported resize disappearance; native reproduction is still pending. The cover
now explicitly disables both tiling flags after SetAtlas, and restores Show/alpha1
after applying the crop. Existing size hooks are reused. Restock replaces the
unverified crate path with the native bag texture already used elsewhere.

Category minimize state is in-memory for the existing window instance, survives
close/reopen, and adds no saved root. Headers remain visible with +/− indicators.
Search reveals matching children without changing the remembered minimized state;
clearing search restores it. Explicit links open their minimized parent. Header
clicks preserve sidebar scroll, while ordinary selection/resize keeps the active
row in view. No foreground/input/profiler/private-settings writes or native setup
were performed.

## HUD correction — current validation

HUD has six direct sidebar entries. The former QoL page is removed; Windows
belongs to Utilities. Flux Window alone has General/Damage Meter tabs. Layout
uses the unmodified original builder/editor. The top HUD Editor shortcut remains.
Every canonical page must now appear in exactly one visible sidebar category;
the previous mapping check included hidden pages, which missed Layout's omission.

Current focused checks: **6,057 real-builder placement checks** and **1,217 complete
shell checks** across five client models. The latter executes the actual Layout
builder and its scope/reset callbacks with an engine-primitive preview host,
including acquire/width/hide/release ownership. It executes the actual Meter
right-click through its forwarding helper/accessor to the shell, tests minimized
HUD expansion, distinct general selection, and meter search. These checks do
not emulate the actual preview drawing/drag engine or native secure input.

Five controls reject the previous QoL catalog, absent Layout sidebar row, Meter
shortcut pointing to General, the previous remembered General shortcut, and
meter controls duplicated into General. Three fresh candidate processes pass
each focused harness. Full **275 scripts / 945 Lua syntax files PASS**; all current
Lua hashes match the full manifest. Existing client mirrors match via the existing
sync, without manual synchronization. No new driver resources or saved fields.
[Current identities/results](validation/options-hud-2026-11-09.json),
[controls](validation/options-hud-controls-2026-11-09.json),
[recovery checkpoint](validation/options-hud-checkpoint-2026-11-09.json).
Native acceptance remains NOT RUN on the previously selected Witchcraft route.

## Classic Era border regression — 9 November

The supplied Era stack reaches CreateWindow → SetBorder → ApplyLayout with nil
userLayout. All three Classic families inherit the method, but their Classic
NineSliceLayouts table has no PortraitFrameTemplate entry. Their XML supplies
separate border textures plus the native high-resolution texture OnLoad. Retail
and Forever instead apply their layout during NineSlicePanelMixin:OnLoad. Keeping
that native initialization removes the invalid assumption without introducing a
custom fallback, changing client detection, or swallowing the native error.

The old complete-shell fixture merely recorded the requested string, so it
accepted the invalid operation. It now executes the actual native layout table,
NineSlice lookup/apply/OnLoad, portrait title/border mixins, and Classic texture
OnLoad on engine primitives. Candidate1,253 checks pass across five client models
in three fresh processes; each old-source Classic run reproduces nil userLayout.
This proves those source contracts, not native engine rendering or secure input.

28 exact upstream Git blobs at the existing task pins cover the Lua, template
XML and family TOC load paths. Relevant local Lua/XML mirrors match; three local
TOC files differ from the pin and are recorded separately rather than treated as
exact evidence. [Sources](validation/options-native-border-sources-2026-11-09.json),
[controls](validation/options-native-border-controls-2026-11-09.json),
[current identities/full results](validation/options-native-border-2026-11-09.json).

Controller assessment: this change concerns decorative border initialization.
It adds no focus target, hit region, input catcher, binding or hint. Existing
window/close/tab/navigation lifecycle and Forever focus mixin remain; native
controller reachability and input acceptance are NOT RUN on all clients.
Localization: no visible label or tooltip is added or changed by this fix.
After reload, retest opening from the chat shortcut, slash command and Escape
entry on Era; check the border, resize, close/reopen and Lua errors. Repeat on
Anniversary, progression, Retail and Forever. Do not treat source-model passes
as native visuals/taint/controller/performance acceptance. No game control was used.

The verified Skin file is installed in all five client folders. The four other
copies still matched the exact old baseline, so the current all-client fix was
installed through approved filesystem escalation after source-only backup. Only
FluxOptionsSkin.lua was copied; all resulting bytes match the candidate. No
settings or other runtime files were synchronized. Native post-reload acceptance
is still pending and the unrelated party/raid testing pause is preserved.

## 13 November sidebar, bindings and shared threat warnings

OPTIONS-SHARED-THREAT-20261113 implements REQ-OPT-35 through REQ-OPT-38.
The sidebar now reads Combat → Loot & Items → Utilities → HUD → Unit Frame,
followed by the unchanged fixed footer. Group identities drive category metadata;
there are no numeric group-position assumptions. One Bindings sidebar entry has
Bindings (the full spell/item/macro browser) and Keybindings tabs. Old binding,
macros, keybindings and actionbars/bindings links still select the matching tool.
Search can leave the Keybindings tab to reveal the complete macro browser.

Threat warning visibility replaces Threat bar visibility in General. Nameplates
uses the same factory/callbacks; its separate native threatWarning dropdown is
removed. Existing scoped unitFrames.threatBarVisibility stays authoritative:
`always` = Always, `raid` = In raid, `group` = In party, `never` = Off. In party
includes raids, retaining the old group behavior; In raid excludes ordinary
parties. Legacy threatBarGroupOnly remains the fallback and is maintained on
explicit selection. Reading the control does not migrate saved values. Existing
nameplateThreat.visibilityMode data/defaults are retained for recovery/older
readers but no longer control the runtime warning gate. No settings reset.

Flux.Threat owns the single gate used by nameplate NPC threat/rank/percent and
enemy-player targeting warnings, plus target/focus portrait, left, right and
between bars. The former between-bar exception is intentionally removed: it
now hides when the shared context is excluded. Other numeric, border, native
nameplate-bit, party/raid highlight and placement controls retain their purposes.
Explicit selections request the native warning CVar using the existing numeric
mapping/guard; blocked/unavailable native writes do not change saved Flux intent.
The CVar existence probe now calls Flux.CVar.Get with its actual dot signature;
the former extra self argument could miss a CVar when only the wrapper existed.
No login/read-time CVar write, new event, ticker, frame, hook or poll is added.

English labels/help use an addon-local fallback catalog; other translations and
localized layout are not claimed. Existing direct implementation and user-run
native testing choices remain selected. Existing sidebar buttons, tab buttons,
dropdown, scrolling, Escape/back and browser acquisition/release paths are used;
controller acceptance must verify focus acquisition, tab switching, dropdown
selection, return from the editor and close without changing user bindings.
This work adds no controller focus target type or input capture.

Validation: 870 shared-warning checks, 6,272 original-builder placement checks
and 1,243 complete shell checks across live, Forever, Classic progression and
the existing Era/Anniversary models PASS. Desktop suite snapshot: 316 scripts and
997 Lua syntax files PASS. These are desktop results, not client certification.
Fresh upstream lookups failed (web fetch unavailable; shell DNS unavailable);
retained dated Gethe pins and existing addon API wrappers were used, with no new
native API dependency or TOC contract.

A dated external checkpoint verifies 2,609 source files plus the Git history;
141 available settings-file metadata entries were inspected without copying or
editing live settings contents. Exact before/candidate hashes and source guard:
[validation evidence](validation/options-shared-threat-2026-11-13.json). No client
input/focus, profiler change, manual synchronization, commit or publication.

Separate inventory work arrived during validation. The suite snapshot includes
that work; three unrelated inventory/test files changed afterward. This task
leaves those files intact. All seven runtime owners and four tests for this
request match their validated hashes; focused checks were repeated on the final
owned source. The snapshot does not certify later unrelated edits.

Native acceptance remains NOT RUN on every client: reload after user-managed
synchronization; inspect the category order and both binding tools, change the
shared visibility from each page, and check solo/party/raid on nameplates plus
target/focus in all four positions. Confirm Off clears warnings, both pages
retain the same choice across reload and scope/profile changes, the browser
editor remains usable, and native warnings reflect permitted CVar changes.
Actual pixels, combat/taint, controller operation and FPS remain pending.
