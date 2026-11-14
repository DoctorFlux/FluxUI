# Tooltip and native meter ownership — 13 November 2026

## Secret class texture and tooltip provenance follow-up

`TOOLTIP-VISUAL-FOLLOWUP-20261113` records the 20:38:00 texture error and the
20:39:33/20:39:36 world-cursor errors. The color-table report explicitly identifies
execution tainted by `_FluxUI`. It still does not identify the originating
field/write, loaded build or whether the previous changes had been reloaded.
The reload question remains pending. The world-cursor error is **unresolved**;
the previous desktop bookkeeping checks did not establish native resolution.

The direct texture defect is present at the reported line: both class-icon
paths concatenate `UnitClass`'s class filename without checking its access.
They now use the existing `API.SafeAccessibleString` before concatenation.
Secret or inaccessible class data hides the current class icon until a public
class token returns. Ordinary `ClassIcon_`/`Class_` art selection, fallback,
corner/inset, size and enable settings remain. There is no cached class guess,
secret-to-string conversion, new API shim or error suppression.

The retained Retail source pin is
`297d7aaaa736f346b3e036f38ee088eaf7f8c07f` (12.1.5.70783). Its
[UnitClass declaration](https://github.com/Gethe/wow-ui-source/blob/297d7aaaa736f346b3e036f38ee088eaf7f8c07f/Interface/AddOns/Blizzard_APIDocumentationGenerated/UnitDocumentation.lua)
has a unit-identity secrecy condition. The
[tooltip cleanup and colored-line source](https://github.com/Gethe/wow-ui-source/blob/297d7aaaa736f346b3e036f38ee088eaf7f8c07f/Interface/AddOns/Blizzard_SharedXML/SharedTooltipTemplates.lua)
confirms the color-table read and native cleanup fields worth inspecting; this
is a diagnostic lead, not evidence that a specific cleanup field caused the log.
Forever and existing Era/Anniversary/Mists targets retain their earlier pins and
contracts. No installed reference or plugin source was edited.

| ID | Required result | Acceptance |
| --- | --- | --- |
| CLASS-TIP-01 | Both icon paths reject secret/inaccessible class filenames before concatenation | Real icon blocks and real existing safe-string helper; checkpoint fails at concatenation; both guard-removal variants rejected |
| CLASS-TIP-02 | Public icons, legacy fallback, dimensions, corners, settings and recovery retain their behavior | 560 checks across five models and both icon paths/four corner combinations; native rendering pending |
| CLASS-TIP-03 | Capture actual tooltip build and tainted field ownership without touching its data or processing | 766 metadata tests; native-value/action/hook/CVar traps; bounded history and missing-support coverage |

Existing `/fluxinput` gains the opt-in `tooltip` subcommand. It records a
before sample and one sample three seconds later, then stops. The report checks
native tooltip processing/cleanup field and global function provenance with
`issecurevariable`; it does not read line text, colors, unit tokens, `infoList`
contents or call tooltip methods. A known addon-owned field records the security
API return convention; missing/unverified support is reported as unavailable.
The source marker `tooltip-visual-followup-20261113-r1` identifies loaded code.
Chat prints at most twelve tainted field names/writers and a total/build summary.
Only the existing `FluxPerfCaptureDB.tooltipDebug` stores latest/previous bounded
capture pairs, preserving other diagnostics and profiler preferences. Logging
mode is read without changing it. No frame, event, hook or poll is added; the
single timer exists only after an explicit command. The class fix adds no driver.
Diagnostic messages use an English fallback catalog with locale override support;
other translations and native localized/controller input remain untested. Existing
command input and passive displays add no new controller focus owner.

Retail's available taint log was last modified 23 October and Forever's
9 November; neither is evidence of these 13 November failures. No fresh native
taint capture is available. Before editing, external
`tooltip-visual-followup-20261113T195054Z` verified 2,753 files and all-ref history
at main `26f886e3ea5371b196ab235d2dace0c156002285`, plus 129 read-only settings
metadata entries. Private settings were not copied. ZIP SHA256:
`cf55f0b883cf7ba8c7a926d1b2ff281c5ea5d7ee907d99e1585fd04985477bb2`.
Prior recovery roots, user work, saved data and profiler preferences remain.
[Source identities, baseline and controls](validation/tooltip-visual-followup-2026-11-13.json).
Full desktop validation passes 355 scripts and 1,043 Lua syntax files;
[outputs and source manifest](validation/tooltip-visual-followup-full-2026-11-13.json).

Native user steps:

1. Reload out of combat so these disk changes are loaded. Target several player
   classes, including during combat; check current class art, corners and recovery.
2. If the tooltip errors recur, run `/fluxinput tooltip` and hover the failing
   world unit within three seconds, using the same preceding hover sequence.
3. Copy the printed field/writer/build lines. A later reload saves the full
   capture for read-only inspection. Do not clear existing diagnostics or enable
   profiling/logging to run this capture.

Native class-texture resolution, tooltip origin/resolution, pixels, controller,
taint and matched CPU/FPS remain **NOT RUN**. No foreground/input/clipboard
control, client sync, settings/profiler write, reset, commit or publication occurred.

## World-cursor follow-up at 20:29:55

Change `WORLD-TOOLTIP-20261113` follows the new `UnitPlayerControlled` error
through `TooltipDataRules.UnitName`, `TooltipDataHandler` and `SetWorldCursor`.
The report does not supply the running build, exact loaded FluxUI source,
originating taint write or addon attribution. The native outcome remains pending;
the earlier private unit-tooltip fix alone is insufficient evidence of resolution.

The supplied [Gethe source](https://github.com/Gethe/wow-ui-source) was checked
again: Retail remains `297d7aaaa736f346b3e036f38ee088eaf7f8c07f`
(12.1.5.70783), Forever remains
`bebcb6bf309cf41b41bd74f8ca651e6a105b2676` (1.60.1.70938).
[UnitPlayerControlled's declaration](https://github.com/Gethe/wow-ui-source/blob/297d7aaaa736f346b3e036f38ee088eaf7f8c07f/Interface/AddOns/Blizzard_APIDocumentationGenerated/UnitDocumentation.lua#L2578)
allows secret arguments only during untainted execution. The
[native world-cursor method](https://github.com/Gethe/wow-ui-source/blob/297d7aaaa736f346b3e036f38ee088eaf7f8c07f/Interface/AddOns/Blizzard_GameTooltip/Mainline/GameTooltip.lua#L978)
and [processor](https://github.com/Gethe/wow-ui-source/blob/297d7aaaa736f346b3e036f38ee088eaf7f8c07f/Interface/AddOns/Blizzard_SharedXMLGame/Tooltip/TooltipDataHandler.lua#L241)
already supply secure call boundaries. Adding another wrapper or replacing the
global unit/color APIs would not establish clean provenance.

Inspection found remaining addon bookkeeping on the shared `GameTooltip`:
binding ownership, spellbook hint deduplication, gear protection flags and
consumable spacer flags. Binding and gear callbacks wrote those fields even on
native-only clear/hide cycles. These writes are now private weak-key table
entries. The retained bridge/refresh source follows the same ownership rule.
This removes observed Flux writers; source inspection does not prove they were
the original cause of this native report or exclude another addon's involvement.

| ID | Required behavior | Desktop evidence |
| --- | --- | --- |
| WORLD-TIP-01 | Binding clear/hide and refresh do not write metadata on the native tooltip | Native-table write trap; independent tooltip instances; late retry and deduplication |
| WORLD-TIP-02 | Spellbook hints still appear once across duplicate row/Button hovers and return on the next hover | Actual five-client spellbook owner tests with native-table write trap |
| WORLD-TIP-03 | Gear warnings still replace protected merchant/disenchant lines once and reset for the next item | Actual protection callbacks; ordinary items retain native sell-price behavior |
| WORLD-TIP-04 | Consumable help keeps one blank separator per explicit fill | Loaded and retained bridge functions; per-tooltip deduplication and reset |

There are five private weak-key tables across the four loaded owners, plus one
in the retained bridge source. No frame, hook, event, timer, ticker or poll was
added. Existing native processing/global APIs, HUD positioning, refresh cadence,
text/colors, clear/hide owners, input/controller owners and saved settings remain.
No new visible UI or configurable behavior is introduced; the passive tooltip
keeps the accepted appearance and existing direct/user-native testing route.

Before editing, external checkpoint `world-tooltip-20261113T193451Z` verified
2,750 source files and all-ref Git history at main
`26f886e3ea5371b196ab235d2dace0c156002285`. Available settings were hashed
read-only (129 metadata entries); private contents were not copied. Its source
ZIP SHA256 is
`074fb5c4e672a21cc357f3d7983c471fc9171426a071d0e8c7e80d5af82bc308`.
Previous recovery roots and concurrent work are preserved.

The new bookkeeping test passes 115 checks across five desktop models;
spellbook input passes 66, native menu/input 121, unit-tooltip ownership 290 and
Edit Mode ownership 295. Five exact-checkpoint source substitutions fail at the
intended native-field write, and five harmful mutations are rejected. Full
validation passes 353 scripts and 1,041 Lua syntax files. The test runtime is
Lua 5.4.6 built from its official source outside AddOns; it does not emulate
WoW's native secret/taint VM.
[Exact source identities and negative controls](validation/world-tooltip-state-2026-11-13.json);
[full outputs and Lua manifest](validation/world-tooltip-state-full-2026-11-13.json).

Native acceptance remains **NOT RUN**. Reload out of combat to discard the
running session's old objects, then hover world units before and after Flux
action/badge buttons, spellbook rows, protected gear at a merchant/disenchant
context, consumable buttons and Flux unit/raid frames. Repeat the world-unit
hovers in combat. Check normal text/color, health bar, HUD placement, one hint/
warning/separator, dismissal and existing controller hover behavior. If the
error persists after a fresh reload, capture the build and preceding hover path
and use targeted taint diagnostics to identify the originating write. Do not
infer that this stack alone identifies FluxUI. Native pixels, controller,
secret/taint handling and matched CPU/FPS remain pending. No foreground/input/
clipboard control, settings/profiler write, manual sync or publication occurred.

Change `SECRET-UI-20261113` addresses the supplied 13:01 report: native
`UnitPlayerControlled` rejected a secret unit token; `GameTooltip_AddColoredLine`
indexed a secret color table; native meter initialization compared secret
`specIconID`; and the native session timer compared secret `durationSeconds`.
The supplied log identifies FluxUI taint on the meter paths. It does not identify
the originating write, the running build, or the exact loaded FluxUI source.

## Requirements and boundaries

| ID | Required result | Verification boundary |
| --- | --- | --- |
| SECRET-TIP-01 | Flux unit, party, raid and preview hovers keep their unit information without reusing Blizzard's world-cursor tooltip state | Dedicated tooltip and native method/state ownership regressions; native combat and pixels pending |
| SECRET-TIP-02 | Pet aura icons, HUD placement, refresh and dismissal remain attached to the Flux unit tooltip | Production tooltip/pet owner regressions; native mouse/controller and pixels pending |
| SECRET-METER-01 | Flux does not generate, open or pick native meter menus from addon Lua | Native menu ownership regressions; native combat/taint pending |
| SECRET-METER-02 | Existing native session history, Current/Overall choice, type and menu controls remain authoritative | Read-only setup feedback and existing native ownership regressions; native operation pending |

The fix preserves saved data and the existing layout/skin services. It adds no
setting, command or interactive frame. The unit tooltip remains a passive
display; existing hover owners and native menu
controls retain their input roles. The existing direct-implementation and
user-performed native testing choices apply.

## Tooltip correction

Blizzard's `SetWorldCursor` explicitly warns that previous addon tooltip data can
taint the later native `ProcessInfo` call. Flux previously stored its unit data,
GUID/rebuild state and `UpdateTooltip` closure on the shared `GameTooltip`, and
replaced methods on the shared `GameTooltipUnitHealthBarMixin`.

Flux unit hovers now use one reusable, lazily created `FluxUnitTooltip` with the
native `GameTooltipTemplate`. Its unit data, refresh state, pet aura host and
secret-safe health-bar callback belong to that instance. Native `GameTooltip`,
its status-bar script and the shared health mixin retain their original methods.
There is no attempt to inspect a secret health value or change global unit,
color or tooltip-processing APIs.

The extra tooltip instance retains its native child regions and native-template
event registrations. It is allocated once on demand and reused. The existing pet
aura host moves to that tooltip; no new addon ticker or polling loop is added.

## Meter correction and capability limit

14 November: [meter control recovery](METER_STANDALONE.md#meter-control-recovery--14-november-2026)
supersedes the automatic-selection withdrawal below with a narrower cached-only
selection path. No native menu regeneration/opening or private setters return.
The tooltip ownership fixes and the restriction/ownership rationale remain.

The earlier menu-proxy implementation called `GenerateMenu`, `Pick` and
`OpenMenu` from addon Lua. Native `RegisterMenu` stores `menuDescription`;
`OpenMenu` generates the description and stores `menu`. A native responder's
`securecallfunction` boundary does not establish that previously stored data has
clean provenance. Earlier native evidence already rejected the assumption that
an original native function plus a secure call proves configuration safety.

Flux now directs the player to the original visible type, session and settings
dropdown controls. It does not regenerate menu descriptions, invoke responders,
open dropdowns programmatically or synthesize native choices. The native controls
own the available type list and all configuration changes. Requested
Flux layouts remain saved, and a missing native window/type retains explicit
setup feedback instead of mislabeling a different type.

This intentionally withdraws automatic native type/window creation and automatic
Current selection on Flux layout choices. Those capabilities remain pending a
verified clean native route. Select the type and Current through Blizzard's own
dropdowns; use its settings menu to create additional windows. The previous
7 November UI confirmation established visible selection only and did not
certify combat/secret/taint safety. Details behavior and the owned Threat pane
retain their existing owners.

## Sources, recovery and acceptance

Current source pins are Retail `297d7aaaa736f346b3e036f38ee088eaf7f8c07f`
(12.1.5.70783) and Forever `bebcb6bf309cf41b41bd74f8ca651e6a105b2676`
(1.60.1.70938). These are source builds, not a claim about the user's running
client. The existing Era, Anniversary and Mists targets are preserved; their
native operation remains separately untested.

- [Retail world-cursor tooltip](https://github.com/Gethe/wow-ui-source/blob/297d7aaaa736f346b3e036f38ee088eaf7f8c07f/Interface/AddOns/Blizzard_GameTooltip/Mainline/GameTooltip.lua)
- [Retail tooltip processor](https://github.com/Gethe/wow-ui-source/blob/297d7aaaa736f346b3e036f38ee088eaf7f8c07f/Interface/AddOns/Blizzard_SharedXMLGame/Tooltip/TooltipDataHandler.lua)
- [Forever native meter](https://github.com/Gethe/wow-ui-source/blob/bebcb6bf309cf41b41bd74f8ca651e6a105b2676/Interface/AddOns/Blizzard_DamageMeter/DamageMeterSessionWindow.lua)
- [Earlier rejected native Current experiment](METER_STANDALONE.md#threat-timer-and-current-view-diagnosis)

The verified external checkpoint `secret-ui-20261113T120306Z` contains 2,690
source files and all-ref Git history at main
`26f886e3ea5371b196ab235d2dace0c156002285`. Available on-disk settings were
hashed read-only (127 metadata entries); private contents were not copied.
The source ZIP SHA256 is
`7dfba827d167de31ad6c582b0a18ad45b006318b0309db8401e008d7f4d32cc5`.
The checkpoint is outside AddOns in the current visualization workspace.

Focused desktop acceptance passes 290 tooltip ownership/lifecycle checks across
five client models and 468 existing production contract checks with 13 existing
mutation controls. Three exact-checkpoint tooltip comparisons reject the original
shared ownership; two additional targeted mutations are rejected. Meter control
acceptance passes 106 checks; three exact-checkpoint comparisons and three
mutations reject addon menu/cache/configuration operations. These are contract
models, not native secure-VM simulations.

[Exact source identities, focused comparisons and final validation](validation/secret-tooltip-meter-2026-11-13.json).
[Full test outputs and complete Lua manifest](validation/secret-tooltip-meter-full-2026-11-13.json).

Reload is required to discard previously tainted tooltip/meter objects. Disk
edits cannot repair those objects in the running Lua session. Fresh unit/pet/
raid/preview hovers followed by world-cursor tooltips, native meter type/session
selection, source drilldown, two fights and timer rollover need user reproduction.
Native secret handling, taint, pixels, controller behavior, CPU and FPS are
**NOT RUN**. No foreground/input/clipboard control, client sync, saved-variable
or profiler writes, reset, commit or publication was performed.
