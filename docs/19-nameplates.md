# Nameplate overlays and chrome

13 November shared threat warnings: **Threat warning visibility** in Unit Frame
→ General and Nameplates uses the existing Unit Frame scope/key. Choices are
Always, In raid, In party, Off; In party includes raids. Nameplates and every
target/focus bar position share one gate, including the between-bar strip. Old
independent nameplate visibility data is retained but no longer gates warnings.
870 warning checks and 316-script/997-syntax desktop suite snapshot PASS; native
pixels/combat/controller/persistence/FPS NOT RUN.
[Requirements and acceptance](OPTIONS_REWORK.md#13-november-sidebar-bindings-and-shared-threat-warnings).
## Quest kill and loot progress — 9 November 2026

NAMEPLATE-QUEST-PROGRESS-20261109 adds the default-enabled **Show quest kill / loot
progress** option in `/fluxui` → Nameplates. The user chose direct implementation
and local checks; they will perform in-game testing. These are user requirements,
not instructions to import the supplied reference addons or their databases.

| Requirement | Implementation | Acceptance |
|---|---|---|
| REQ-NPQ-01: own kill/loot icon with current/required | Existing Core module reads incomplete `monster`/`item` objectives; adjacent badges such as kill `2/8` and loot `1/5` share one row; completed objectives disappear. | Desktop data/painter checks pass; actual mobs pending. |
| REQ-NPQ-02: top-left anchored to plate bottom-left; same Y as threat/level | Each 12-unit badge anchors `TOPLEFT` to the health container `BOTTOMLEFT` at Y `+3`, retaining centre Y `-3`. The strip begins at X `0` when it fits and extends left when needed; no downward stacking. Existing level/threat anchors stay unchanged. | Dynamic geometry checks pass; native pixels and simultaneous threat/casts pending. |
| REQ-NPQ-03: compatible with Questie, without a database | Reads Questie 12.6.4 `QuestieTooltips.lookupByKey["m_" .. npcID]`; refreshes associated objective via its existing `Update`; uses public quest-ready/update callbacks. | Same-NPC batching, startup and callback lifecycle pass; installed-client integration pending. |
| REQ-NPQ-04: Blizzard fallback with Questie absent | Reads native unit quest tooltip blocks and verifies exact objective text and active quest membership against `C_QuestLog.GetQuestObjectives`; older clients use one private hidden tooltip. No inferred item drop sources or text-based mob-name guesses. | Modern/legacy and localized counter models pass. Clients that expose no native association cannot identify that mob without Questie; native coverage pending. |
| REQ-NPQ-05: same default icons with/without Questie | Two unchanged 2,564-byte supplied Questie textures, `Texture/QuestSlay.blp` and `Texture/QuestLoot.blp`. | Exact SHA-256/reference comparison recorded; native appearance pending. |
| REQ-NPQ-06: disable Questie's duplicate nameplate icon | Writes only `Questie.db.profile.nameplateEnabled=false` and calls `QuestieNameplate:HideCurrentFrames`, matching its option setter. Target-frame/tracker/map settings stay independent. | Existing markers, profile changes and reenable controls pass; native pending. |

Compact follow-up requested later on 9 November: reduce the quest count font
and icon from12 to10, host height14 to12, and horizontal icon/padding allowance
from28 to16 units (2 left,10 icon,2 gap,2 right). The icon is vertically centred
with1-unit clearance. This shortens the tag while retaining centreY-3 alongside
threat/level and the existing16-unit row spacing. Threat/level geometry and
quest data behavior remain unchanged.371 focused checks include icon containment,
compact count geometry and alignment; native overlap/legibility remains for the
user's in-game check. [Compact evidence](validation/nameplate-quest-compact-2026-11-09.json).

### Combined objectives and dynamic width — 9 November follow-up

NAMEPLATE-QUEST-LAYOUT-20261109 supersedes the earlier downward stacking. A mob
serving both kill and loot objectives keeps both icons and exact counters on one
horizontal row, for example `[kill 2/8] [loot 1/5]`. Additional objectives use that
same row. Each badge fits its actual text plus the existing 16-unit icon/padding
allowance; font and icon remain 10 units and height remains 12. Nothing shrinks,
wraps, truncates or discards progress to fit.

| Requirement | Implementation | Acceptance |
|---|---|---|
| REQ-NPQ-07: combined kill/loot must not create another row over casts | Adjacent objectives share Y `+3`; four units separate host boxes, including their expanding artwork. | Five models cover two/three objectives and completion; native casts pending. |
| REQ-NPQ-08: fit available space without unreadably small content | Reserve the actual centered threat label's half-width and six units of separation. Keep X `0` when the entire strip fits; otherwise extend it left of the plate. Long counters grow at the existing font size. | Narrow/wide plates, hidden/long threat, long counts and exact progress pass. |
| REQ-NPQ-09: respond to geometry without quest rescans | Existing 0.25s poll checks width and the threat module's public painted-width record; only changed layout writes anchors. Missing/secret/nonfinite native width uses the exterior left lane. | 1,000 settled polls per model add no quest queries, text/frame allocations or anchor writes. |

Threat exposes its own last painted width and visibility state; the quest module
does not read threat values or anchored threat-widget geometry. `FitPlate` returns
the public width it already calculated. Health width is checked before arithmetic;
Retail/Forever `GetWidth` can be secret when anchoring is secret. Fresh pinned
`SimpleScriptRegionAPIDocumentation.lua` and native nameplate sources were inspected
for Retail `297d7aaaa736f346b3e036f38ee088eaf7f8c07f`, Forever
`9dc84f0d3bbae1768ac3405b3716000bd93eda06` and Classic progression
`e5d9b3a22c3f0f6f41ebac0e454f4969594261cf`. Existing Era/Anniversary gates and
quest-provider contracts remain; native runtime access is not certified by source.

The fresh external checkpoint verifies 2,455 source files, history and 87 settings
metadata files. Settings were inspected read-only; no live settings-content backup
is claimed. No new frame driver, event, hook, ticker, saved setting or cast-bar
mutation was added. The existing host pool expands only to the objective peak.
1,261 focused checks across five models and eight actual threat-module integration
checks pass; three baseline/candidate pairs reject the old stacking and pass the
candidate, and three harmful controls fail. Full validation: 272 scripts and 942
Lua syntax files pass. [Exact sources and evidence](validation/nameplate-quest-layout-2026-11-09.json).

The prior direct-implementation/local-check choice still applies. Native pixels,
cast clearance in each nameplate style, combat/taint and CPU/FPS remain pending
the user's in-game check. Reload, inspect a casting mob with both objectives and
visible threat/level, narrow/widen the plate, then complete one objective. Confirm
the row stays readable and extends left when crowded. No game input or settings/
profiler writes were performed.

Implementation stays in [Core.lua](../NamePlates/Core.lua), the existing defaults
and options files. No new runtime Lua/TOC entry, quest database or quest saved
variables. The setting is `FluxUI_DB.nameplateThreat.questOverlayEnabled`; prior
settings remain. Disabling Flux's option releases hosts and event subscriptions;
the permanent Questie callbacks become inert. It stops enforcing Questie's
setting but does not silently turn Questie's marker back on. Users may enable
that marker in Questie's options after disabling this overlay.

The shared active-nameplate driver runs at 0.25s. Quest events coalesce, with
three bounded follow-up polls for asynchronous quest state. A batch shares
Questie objectives across equal NPC IDs and native objective reads across quest
IDs. Settled polls perform no quest/tooltip queries or text/frame allocations;
they check visibility transitions and the duplicate-marker preference. Hosts pool
at the peak visible row count and release on removal. No independent ticker,
OnUpdate frame, global native hook or forced dependency was added.

Public GUIDs, objective tables and counters are required. Secret/invalid data
clears old badges. Modern secret-enforcing clients skip instance lookups before
Questie or native tooltip rebuilding; leaving the instance refreshes public world
data. The fallback does not promise full Questie database coverage. Party-member
quest progress, ambiguous legacy quest titles, unrelated objectives and NPCs
without verified native quest blocks do not produce badges.

Source evidence was resolved on 9 November from Gethe's requested repository:

| Client | Pinned source | Relevant declaration/loading |
|---|---|---|
| Retail 12.1.5.70783 | [`297d7aaaa736f346b3e036f38ee088eaf7f8c07f`](https://github.com/Gethe/wow-ui-source/tree/297d7aaaa736f346b3e036f38ee088eaf7f8c07f) | `QuestLogDocumentation.lua`: objectives/membership; `TooltipInfoDocumentation.lua`: GetUnit with restricted-token annotation; `Blizzard_NamePlates.toc` loads the shared unit frame. |
| Forever 1.60.1.70862 | [`9dc84f0d3bbae1768ac3405b3716000bd93eda06`](https://github.com/Gethe/wow-ui-source/tree/9dc84f0d3bbae1768ac3405b3716000bd93eda06) | Same contracts; Camelot nameplate overrides selected by the native TOC; instance access gated. |
| Classic progression 5.5.4.70631 | [`e5d9b3a22c3f0f6f41ebac0e454f4969594261cf`](https://github.com/Gethe/wow-ui-source/tree/e5d9b3a22c3f0f6f41ebac0e454f4969594261cf) | Quest objectives declared; GetUnit absent from generated C_TooltipInfo; legacy tooltip capability path retained. |

The packaged API-query snapshot was only a research index; the current pins above
are the evidence for this task. Generated declarations do not prove permitted
runtime operation or native quest coverage. Existing Era/Anniversary load gates
are unchanged and their legacy contracts are exercised by mocks, without claiming
a new native build certification. QuestieTrace and QuestieDB were references only
and are not dependencies. See [icon provenance](../Texture/QuestIcons-NOTICE.txt):
the supplied default BLPs have no asserted redistribution license; their source
notice is retained and this task does not publish them.

[Focused evidence](validation/nameplate-quest-progress-2026-11-09.json) includes
311 checks, seven rejected harmful controls, baseline rejection and exact identities.
[Full verification](validation/nameplate-quest-progress-full-2026-11-09.json) is
desktop-only. Final six related quest/nameplate/Questie regression scripts pass with no drift in the four owned Lua files. Native geometry, actual quest associations, reload/profile behavior,
combat/taint and matched CPU/FPS remain pending; no game input, sync, settings or
profiler operation was performed.

User acceptance: reload the updated installation; inspect an active kill quest,
an item-drop quest and a mob serving both; progress each and complete/abandon it.
Repeat with Questie disabled, then loaded: Flux should retain its own rows and
Questie's separate world-nameplate marker should be off. Confirm bottom-left
placement with level/threat/casts and each chosen style; then toggle Flux's quest
option off/on and move between world/instance without stale counts. This copy
was changed only in the existing Retail workspace; no other installation was
overwritten.

<!-- STRESS-FIXES-20261107 -->
7 November applied stress fixes: Public native alpha/anchor/visibility comparisons suppress stable repeated writes. Opaque/unknown cases retain repair writes; no unsafe native hook or permanent assumption about native state is added. [Evidence](../Stress%20test%20doc/applied-fixes/README.md). Native taint/pixels/performance acceptance remains pending.
<!-- /STRESS-FIXES-20261107 -->

`Flux.NamePlates` adds threat/level/combo/countdown and casting-school presentation around existing Blizzard nameplates. It does not create a replacement nameplate suite. Current behavior is defined by [Core.lua](../NamePlates/Core.lua), [Threat.lua](../NamePlates/Threat.lua), [Level.lua](../NamePlates/Level.lua), [Countdown.lua](../NamePlates/Countdown.lua), [ComboPoints.lua](../NamePlates/ComboPoints.lua) and [CastBarSchools.lua](../NamePlates/CastBarSchools.lua).

## Lifecycle and ownership

Core tracks `activeUnits` from `NAME_PLATE_UNIT_ADDED/REMOVED`, reconciles existing plates on entering world and dispatches module `Added`, `Removed`, `Refresh` and periodic `Poll` methods. One hidden/visible driver runs only while plates are active. Group/combat changes refresh policies. Module errors route to the error handler without abandoning every module.

Flux text/border hosts parent to the nameplate itself, not UnitFrame/its children, and release to UIParent on removal. Preview unit tokens are excluded. Unit tokens, object access and displayed values are checked for secrets where applicable. Reuse/removal must clear retained per-unit state and tint.

`TintPlateChrome`/`ResetPlateChrome` recolor native borders, level indicators and selection regions. Level/countdown code fades native artwork/digits, client-specific Core code changes selected anchors/visibility, and cast-school styling adds a fill texture to the native casting bar. These side effects require native taint checks; see [findings](40-findings.md).

## Blizzard casting bar school themes

The shared [unit-frame school renderer](../UnitFrames/FluxCastBarThemes.lua)
now paints Blizzard's `CastBarsContainer.castBar` on Retail, Forever, Era and
Anniversary. Its noninteractive visual host follows the native bar; Blizzard
continues to own progress, text, shield, indicators, cast events and fading.
The **Blizzard nameplates** toggle under Unit frames → Cast bar school themes
defaults on. Secret or unresolved spell identity preserves Blizzard's fill.
Desktop lifecycle and renderer checks pass; native combat taint, pixel parity
and frame time remain pending. [Exact record](NAMEPLATE_CASTBAR_SCHOOLS.md).
The [fill/tip correction](CAST_SCHOOL_FILL_TIP_FIX.md) hides Blizzard's
underlying fill only during a readable school theme and tints its native
Spark to the school; both restore when the theme clears.
The [backdrop layer correction](NAMEPLATE_BACKDROP_LAYER.md) puts school
artwork at the plate level behind native cast and health chrome, while fill,
tip, halo and particle effects keep their existing hosts.
The [secret-channel fallback correction](SECRET_CHANNEL_FALLBACK.md) selects
the channel spell ID without boolean-testing it; an inaccessible or nonmagic
school keeps the default native appearance.

## Threat and level

Threat polls at 0.25s. Account settings in `FluxUI_DB.nameplateThreat` default to NPC border on, enemy-player-targeting-you on and group-only visibility. `always|group|never` controls whether the overlay participates. Enemy players targeting the player receive red chrome; NPCs consult `Flux.Threat` for eligibility, values/status, rank and colors. A short 0.6s grace avoids immediate visual clearing on transient missing threat. Native numeric-threat policy also gates text.

`IsThreatSupported()` currently checks for `C_NamePlate`; it does **not** categorically exclude Live. Effective results still depend on `Flux.Threat` returning eligible, displayable information. Forever uses its specialized frame/status display helpers. Consequently the old claim “Live countdown only” was too strong for current code; supporting a path statically is also not proof that live combat APIs provide numeric data.

Level polls at 0.25s. `IsLevelSupported()` excludes Live and permits other clients with nameplates, including Forever. The “Lvl. N”/skull overlay is omitted for simplified, minion, minus and name-only plates and when using Classic health-bar artwork that keeps native level presentation. Difficulty color uses native content-difficulty helpers where possible. Restricted levels can pass to formatted display instead of numeric comparisons. The setting defaults enabled.

Core additionally fades Forever native level art, extends supported health geometry and repositions CC/loss-of-control icons. Forever health readouts move inside the bar with style-dependent center/right alignment. Live hides native level frames without extending the bar. These update paths skip Settings-open/preview contexts. They are more invasive than an additive text host and require live taint checks.

## Countdown and target combo resources

Countdown polls at 0.1s. Flux-owned text hosts overlay native aura cooldowns at a fixed `16 * 0.75 = 12px`. Native digits are faded with text-color alpha only after a Flux label is available; Flux does not set their font/scale or replace aura mixins. It reuses native labels, including secret strings supported by SetText, or computes time only when values are readable and duration is at most 60 seconds. Computed labels use whole seconds above ten and tenths below. Missing labels restore native digits. Size is a code constant, not a live options slider.

Combo points load only for the TOC-listed Vanilla/TBC/classic/camelot game types. The current-target-only row uses Flux-owned client artwork and shared Forever rendering where supported, without requiring the Flux player/target frame enabled. It follows target, point/form and plate reuse/removal events. Other plates receive no combo row; eligibility keeps zero-point sockets for supported rogue/Cat forms.

## Configuration and validation

`FluxNamePlates_RefreshFromDB` and `FluxNamePlateThreat_RefreshFromDB` apply option changes. Numeric percentage shares game `threatShowNumeric` with unit frames. Nameplate CVar defaults are a separate explicit [defaults feature](05-defaults-and-bindings.md), not something every overlay refresh should be assumed to rewrite.

Verify each supported style/client, secret numeric text, group policy, player target detection, threat clearing/reuse, native border restoration, minion omissions, zero/transfer combo points, countdown recovery and Settings previews. Current comments, old docs and capability gates disagree in places; observed behavior belongs in [verification](41-verification.md), not inferred “full support” claims.

## Countdown work reduction

PERF-009 `efca305` passes the current poll's discovered native text region to label/
alpha handling and reads the same three frame levels without a temporary table.
No region/level is cached between polls. Five matched desktop pairs halve discovery
calls and remove measured temporary allocations with the same text/anchor writes,
font, levels and 0.1s timing. 1,160 checks include 100 plate lifecycle cycles.
Native Retail real-widget geometry/alpha/reuse checks pass with zero recorded errors;
actual protected aura rendering/combat/secret values remain pending. [Evidence](NAMEPLATE_COUNTDOWN_WORK.md).

<!-- NPQ-FULL-HISTORICAL -->
Historical initial-progress capture (superseded by the layout validation above):
Latest full checkout:263/265 standalone scripts PASS;932Lua syntax PASS.
Concurrent unit-frame changes produced two mock failures: `public_geometry_writers.lua`
needs `DeferProtected` in its test double; `raid_party_frames.lua` needs
`SetClipsChildren` in its test double. Both reproduce separately. This quest task
did not edit those owners or tests. Earlier265/265 captures retain their exact
source scope externally. Quest checks311PASS, seven harmful controls rejected;
full current source identities/failures are retained in the quest validation JSON.
<!-- /NPQ-FULL-HISTORICAL -->

Historical freshness note: independent unit-frame work continued after that capture.
The last documentation check reported only inventory/verification freshness for
`tests/raid_party_frames.lua`; refresh whole-project evidence after that batch.
Six related quest/nameplate/Questie scripts pass and this feature's four owned
Lua identities remain unchanged. See the quest validation JSON for scope.
