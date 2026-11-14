# Native meter skin and standalone threat pane

## Meter control recovery — 14 November 2026

Full validation: 365 scripts and 1053 Lua syntax files PASS; complete current Lua manifest verified.

`METER-CONTROL-RECOVERY-20261114` addresses the lost Current defaults and the
reported Damage Taken header over a requested Dispels setup pane. The audit
traces these behaviors to the 13 November `SECRET-UI-20261113` removal of native
selection helpers. The 14 November source recovery restored that already-limited
version; repeating that recovery would retain the same missing controls.

This section supersedes the meter capability withdrawal below. Its tooltip
ownership correction and the later header alignment fix remain required. The
existing direct-implementation and user-performed native testing choices apply.

| ID | Required result | Acceptance |
| --- | --- | --- |
| MCR-01 | Preset, custom, structure, type, Meter-tab and setup choices apply their requested native types | Production control regressions; native operation pending |
| MCR-02 | Every displayed native pane defaults to Current after an explicit layout/type choice | Mixed Overall/history, same-layout reselection and historical-ID regressions; native rollover pending |
| MCR-03 | A required extra native window is created through its original menu entry, within Blizzard's three-window limit | Native menu/window regression; Threat remains independent |
| MCR-04 | Later manual Overall/history choices survive geometry, background refresh and ordinary reopen | No background selection or history reset; existing lifecycle regressions |
| MCR-05 | Selection consumes only existing native menu descriptions with verified field/method provenance | Missing or tainted cache refuses selection; no native menu regeneration or direct configuration setter calls |
| MCR-06 | Existing appearance, saved layouts, native localized text and input ownership remain | Desktop preservation checks; native pixels, localization and controller checks NOT RUN |

The selection path reads Blizzard's existing `menuDescription` cache after
`issecurevariable` checks. It resolves the original local menu proxy methods
through their native metatable and checks the fields used for selection. The
original proxy `Pick` fetches its original responder/data through native
`SecureCallResponder`; Flux supplies no replacement type/session data. Current
uses the original native `{type=Current, sessionID=nil}` entry. Native setup owns
initial cache creation and newly created windows.

Flux does not call `GenerateMenu`, `RegisterMenu`, `OpenMenu`,
`DropdownButton:Pick`, private configuration setters or copied responders.
Unavailable or tainted descriptions retain truthful setup feedback; reload
outside combat and reselect the layout. These guards are observable provenance
checks, not certification of WoW's secure VM. There is no new event, hook,
timer, ticker or recurring driver. Existing coalesced layout work remains.

Retail source pin `297d7aaaa736f346b3e036f38ee088eaf7f8c07f` and Forever pin
`bebcb6bf309cf41b41bd74f8ca651e6a105b2676` were rechecked. The
[native menu selection implementation](https://github.com/Gethe/wow-ui-source/blob/bebcb6bf309cf41b41bd74f8ca651e6a105b2676/Interface/AddOns/Blizzard_Menu/Menu.lua)
supports custom `Pick` callers; the
[native meter menus](https://github.com/Gethe/wow-ui-source/blob/bebcb6bf309cf41b41bd74f8ca651e6a105b2676/Interface/AddOns/Blizzard_DamageMeter/DamageMeterSessionWindow.lua)
own the type, Current and New Window entries. Other established clients and the
Details backend retain their existing paths.

The external `meter-recovery/checkpoint-20261114T081300Z` preserves 2,771 source
files and all-ref Git history on main with `.githooks`. Available settings were
hashed into 53 metadata entries; no private contents were copied or restored.
No client input, foreground/clipboard control, settings/profiler write, manual
sync, reset or publication is part of this recovery.

Native acceptance remains NOT RUN: reload outside combat, choose the Dispels and
Interrupts presets, verify matching titles/data and Current in every pane, then
test two fights and manual Overall/history through reopen and layout reselection.
Check native/Flux controller reachability, focus, activation, back and selection
indication through the existing controls. No new focus targets or bindings are
introduced; controller, combat/taint, localized clipping, pixels and CPU/FPS need
separate client evidence. Desktop results and exact identities are recorded in
[recovery evidence](validation/meter-control-recovery-2026-11-14.json).

## Header alignment recovery — 13 November 2026

`METER-TITLE-20261113` follows the supplied screenshot: Damage Done, Healing Done
and Dispels can retain the native dropdown offset while Threat keeps the intended
five-pixel left inset and shared baseline. Threat in the screenshot is the accepted
appearance; the existing direct-implementation and user-performed native testing
choices continue to apply.

| ID | Required result | Acceptance |
| --- | --- | --- |
| METER-TITLE-01 | Every native type label uses Threat's existing header inset and baseline, including initially unresolved panes | Actual skin regression at four scales; native screenshot comparison pending |
| METER-TITLE-02 | Reopen, anchor/width resets and combat deferral recover alignment | Hidden first show, unchanged cached dimensions, combat resize and deferred refresh regressions |
| METER-TITLE-03 | Native wording, menus, timers, input ownership and saved settings survive | Existing native skin/ownership/timer tests; actual localized/controller/combat operation pending |

The skin now accepts a public zero initial label width, retries alignment on
`OnShow`, and checks actual label anchors and width before reusing its cached
layout. Combat-time resize queues the existing out-of-combat header refresh.
Saved original geometry is restored on release, including an initial zero width;
released hooks remain idle. One guarded show hook per native session pane is added;
there is no new frame, texture, timer, ticker, event registration or polling loop.
The native type label remains a passive region inside its original dropdown.
Native mouse/keyboard/controller handlers, focus owners, labels and action hints
remain unchanged; no decorative region becomes a focus target.

Retail `297d7aaaa736f346b3e036f38ee088eaf7f8c07f` (12.1.5.70783) and Forever
`bebcb6bf309cf41b41bd74f8ca651e6a105b2676` (1.60.1.70938) were resolved from
Gethe/wow-ui-source for this task. Their `DamageMeterSessionWindow.xml` declares
the native label's LEFT-to-arrow and RIGHT-to-session anchors; the Lua getter
returns that region and the native type setter supplies its localized text.
These are source builds; the running client build was not captured. The existing
Era, Anniversary and Mists targets/Details backend are preserved and unchanged.

- [Retail native header template](https://github.com/Gethe/wow-ui-source/blob/297d7aaaa736f346b3e036f38ee088eaf7f8c07f/Interface/AddOns/Blizzard_DamageMeter/DamageMeterSessionWindow.xml)
- [Retail native label owner](https://github.com/Gethe/wow-ui-source/blob/297d7aaaa736f346b3e036f38ee088eaf7f8c07f/Interface/AddOns/Blizzard_DamageMeter/DamageMeterSessionWindow.lua)
- [Forever native label owner](https://github.com/Gethe/wow-ui-source/blob/bebcb6bf309cf41b41bd74f8ca651e6a105b2676/Interface/AddOns/Blizzard_DamageMeter/DamageMeterSessionWindow.lua)

Verified external checkpoint `meter-title-20261113T181737Z` preserves all 2,748
source files and all-ref Git history on main. Available settings were read and
hashed into 76 external metadata entries; private contents were not copied.
No client input, foreground/clipboard control, settings/profiler write, manual
sync, commit or publication occurred. The supplied screenshot establishes the
reported visual defect; no candidate native capture was made. After an
out-of-combat reload, reopen Meter, switch panes/layouts and confirm the title
insets and baselines match Threat before/after a fight. Native pixel parity,
localized clipping, menus/controller operation, taint and CPU/FPS remain NOT RUN.

[Exact source identities and desktop results](validation/meter-title-2026-11-13.json).
[Full validation report](validation/meter-title-full-2026-11-13.json).

13 November SECRET-UI-20261113 supersedes earlier automatic native meter
selection claims: Blizzard controls own types/window creation/Current; Flux
keeps saved layout requests with explicit setup feedback. Unit/pet/raid/preview
hover state is isolated from the world-cursor tooltip. Reload/native retest
required. [Fix, capability limit and evidence](SECRET_TOOLTIP_METER_ERRORS.md).

## FluxUI menu and Meter-tab routes — 7 November 2026

7 November meter menu/tab routes (METER-WINDOW-ROUTES-20261107): fixed the
remaining geometry-only routes in FluxWindow's active Meter-tab cycle and
preset setter. Explicit native tab entry now commits the requested types and
Current; FluxUI options choices switch from Map before committing, so an old
runtime layout cannot be applied instead. Details retains its existing immediate
quiet re-embed path and eleven-preset wrap. No visual/layout/type list change.
If native UI is not ready, one explicit apply intent reuses existing readiness
Embed/retries. The latest working layout wins, it consumes once, and Hide/Cleanup
cancel it. Startup without that explicit intent still does no native type/session
configuration. No new frame/event/hook/timer/ticker; one transient boolean only.
User reloaded and confirmed both routes configure panes and Current automatically
without the setup-pane click. Native acceptance is selected Forever UI/function;
combat/secret/taint/gamepad/other-client/FPS remain pending. Exact source,
paired/focused/full results and source/history/settings recovery are in evidence.
Final focused validation:12 meter/window scripts PASS;404 control checks,
448 per pinned menu replay; five paired baseline rejects/candidate passes and
four rejected mutations. All15 installed runtime hashes match through the
existing mirror. Whole run:876 syntax PASS,212 scripts PASS and1 unrelated
concurrent party-frame fixture failure; global source drift, meter owners stable.
Preserve the unrelated work; no whole-addon PASS is claimed.
Documentation check reports5 unrelated raid/party inventory/verification
issues and no meter-source errors.

No foreground/input control, direct WTF/profiler writes or manual client sync.

| ID | Requirement | Acceptance |
| --- | --- | --- |
| METER-WINDOW-ROUTES-01 | Native layout cycle and preset setter apply types/Current rather than geometry alone | Actual production handlers replayed; user confirms automatic Meter-tab cycling |
| METER-WINDOW-ROUTES-02 | FluxUI choice made while Map is active applies the new layout | Switch to Meter before commit; user confirms both routes |
| METER-WINDOW-ROUTES-03 | First explicit Meter-tab entry applies the current request | Actual inactive-tab OnClick replay; native-ready and delayed-ready cases |
| METER-WINDOW-ROUTES-04 | Delayed explicit choice completes without a later setup click | Existing Embed/retry consumes latest one-shot intent; cancellation and no-background-write cases pass |

The screenshot's HPS header and Damage Taken prompt came from the old tab cycle
calling `ReembedQuiet` after changing the preset. The full type/Current commit
was previously wired only to the editor. The shared explicit-choice helper now
routes native cycle/setter calls to `CommitUserLayout`, while Details keeps its
original immediate `ReembedQuiet` behavior. The first physical Meter-tab entry
also commits; ordinary programmatic startup/show/resize does not impose new
native data defaults. A planning-only `SetMeterPresetIndex(..., false)` remains
planning-only until an explicit apply/tab choice.

The native application mechanism is unchanged: original menu descriptions/data/
responders and public native Pick. The pending flag records only user intent;
no private setters or polling are introduced. A delayed first click uses the
latest layout supplied to the existing readiness Embed, then clears its flag
before native application. Later ordinary embeds preserve manual segment
overrides. Hide/Cleanup retire pending intent, and tab OnClick remains combat
blocked. No reset/history deletion is added.

Desktop tests execute the actual production cycle/setter/OnClick source with the
existing real layout/backend fixtures. They reproduce HPS-to-Damage Taken cycling,
options on Map, inactive tab entry, planning-only setter, delayed latest-wins
application, one-shot consumption/cancellation and unchanged Details routing.
Pinned native menu replay and native ownership/provenance/startup/window tests
retain their stated scope; no secure-VM, native performance or pixel claim.

[Evidence](validation/meter-window-routes-2026-11-07.json).

## Current segment on layout choice — 7 November 2026

7 November Current segment default (METER-LAYOUT-CURRENT-20261107):
explicit FluxUI layout/type/setup choices now default every displayed native
pane to Current through its original Blizzard session-menu radio entry. Native
stored {type=Current,sessionID=nil} data/responders remain untouched; no private
session setter or history reset is called. Already-Current panes skip selection.
All ten presets, unchanged types, Overall/history, same-layout reselection,
manual overrides and historical-ID clearing have focused coverage. Geometry,
menu opening and background events preserve later manual segment choices;
the next layout choice restores Current. Threat remains independent.
User reloaded and confirmed: all native panes switch to Current on layout choice.
Acceptance is selected Forever UI/function only; native combat/secret/taint,
gamepad, other-client execution and FPS remain pending. No new frame/event/hook/
timer/recurring driver, direct WTF writes, profiler change or game input.
Fresh source pins and external source/history/settings recovery verified.
Final validation:212 scripts/875 Lua syntax files PASS with unchanged corpus;
all5 installed backend/layout pairs match. No duplicate sync performed.
Exact paired/focused/full results and source identities are in the evidence.

| ID | Behavior | Acceptance |
| --- | --- | --- |
| METER-LAYOUT-CURRENT-01 | Every mapped native pane becomes Current after preset/custom/structure/type/setup choice | Implemented; user confirms selected Forever UI/function |
| METER-LAYOUT-CURRENT-02 | Original native session data, history and manual controls retained | Original menu entry Pick; no private setter/reset; manual override lasts until next layout choice |

This supersedes prior instructions that every new native pane must be manually
set to Current after choosing a layout. It uses the working native menu-selection
path rather than the rejected private-setter/securecallmethod experiment. The
legacy `/fbm currenttest` diagnostics remain read-only UNSUPPORTED for that old
experiment. Startup/background/resize do not impose a segment policy; the native
window's saved Current choice persists normally and Blizzard owns fight rollover.

Pinned [Forever session menu](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_DamageMeter/DamageMeterSessionWindow.lua#L396)
and [Retail session menu](https://github.com/Gethe/wow-ui-source/blob/297d7aaaa736f346b3e036f38ee088eaf7f8c07f/Interface/AddOns/Blizzard_DamageMeter/DamageMeterSessionWindow.lua#L396)
create the Current radio with native `{type=Enum.DamageMeterSessionType.Current,
sessionID=nil}` metadata. Flux finds that original entry and uses the existing
public menu Pick helper. It compares no combat duration/value, never edits the
entry/data/responder, and excludes owned Threat/unused native windows. Current
panes with nil IDs do not regenerate their session menu or select again. A pane
reporting Current with a historical ID still selects the canonical native entry.

Desktop scope:352 control checks,388 per pinned client menu replay,11 focused
meter/threat scripts; five alternating baseline/candidate pairs and four negative
mutations. All ten presets start with mixed Overall/history and verify every
displayed native pane becomes Current. Later manual Overall survives geometry,
and reselecting the same layout restores Current with only one needed selection.
Native user confirmation covers the UI/function result; secure VM/combat/taint,
gamepad, native performance and other-client execution remain pending.

[Evidence](validation/meter-layout-current-2026-11-07.json).

## Direct native choices and one-click presets — 7 November 2026

7 November native meter controls/presets (METER-NATIVE-CONTROLS-20261107):
the previous picker changed only a layout request. Native type rows now come
from Blizzard's actual menu descriptions and use their public Pick selection
API with untouched responders/data. Explicit type/setup/preset/custom/structure
clicks use native menu entries; missing panes use the original New Window entry.
Preset clicks apply every requested native type immediately. Startup, geometry
repair and combat events never select types/create native windows. Existing
session/history and Save controls remain; no private native setter calls return.
Native responses update both the runtime snapshot and matching active editor
slot, with stale layout/type guards. Absorbs is removed from the catalog and
builtin5 now uses HPS. Legacy unavailable requests normalize in working views/
previews only; untouched saved custom layouts retain their original requests
until explicit Save. New builtin10 is Threat/Damage over Interrupts/Healing.
Threat remains a separate owned Content child and consumes zero native windows.
User confirmed native menu/type/Flux-label changes, direct Dispels pane creation,
and finally both Dispels and new Interrupts four-pane presets work immediately.
Acceptance is selected Forever UI/function only; native combat/secret/taint,
gamepad, other-client execution and FPS remain pending. Fresh pinned source,
paired desktop/mutation/full results and exact identities are in the evidence.
Final meter checks: all11 focused meter/threat scripts PASS;220 native-control
checks,256 checks per pinned client menu replay, five baseline-rejecting pairs
and five rejected mutations. All5 installed backend/layout pairs match the final
tested hashes through the existing mirror. The final whole run has874 syntax
PASS,205 scripts PASS and6 unrelated concurrent raid-test failures; global corpus
drift prevents a whole-addon PASS. Meter owners stayed unchanged; preserve the
unrelated raid work. Documentation validation reports19 unrelated unit/raid
inventory/verification issues and no meter-source errors. Native acceptance
remains selected-client UI/function only.
Source/history recovery and available on-disk settings verified; no foreground
control, direct WTF writes, profiler changes or manual client copy operation.

| ID | Requirement | Final behavior/evidence |
| --- | --- | --- |
| METER-NATIVE-CONTROLS-01 | Choose each native type directly in FluxUI | Enumerated original native radio entries; direct Pick; user confirms type/pane/label update |
| METER-NATIVE-CONTROLS-02 | Preset/custom layout applies all native windows without setup clicks | At most three copied desired slots applied once per explicit user choice; user confirms both four-pane presets immediately work |
| METER-NATIVE-CONTROLS-03 | Offer only supported native types | Current ten native types; no Absorbs catalog/preset; builtin5 HPS; saved unavailable requests repaired in working/preview only |
| METER-NATIVE-CONTROLS-04 | Threat/Damage above Interrupts/Healing | New stable builtin10; original IDs retained; user confirms native result |
| METER-THREAT-ISOLATION-01 | Threat does not consume a native meter window | Existing independent owned pane retained; mixed-layout routing fixture and user native Max3/Current2 output |

This supersedes the earlier manual-only setup/launcher instructions below.
The private type/session/row/default configuration boundary remains: no direct
native setters, copied responders, replacement native functions, secret-value
comparisons or automatic startup/combat configuration are introduced. Instead,
the documented native menu API explicitly accounts for custom implementations:
[Pick in Menu.lua](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_Menu/Menu.lua#L903)
and [native radio input](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_Menu/MenuTemplates.lua#L137).
Each click re-resolves the actual window/entry. Native stored menu data remains
the responder's input; Flux does not supply an enum to a native private setter.
Matching panes skip redundant selection. Native new windows retain their native
default session, and existing Current/Overall/history preferences are retained.

The earlier skinned placeholder and three menu-launcher stage were insufficient
for the requested direct choices. User verified the launcher menu and native type
response, then clarified that individual type rows and immediate complete preset
application were required. Both are implemented and functionally confirmed in
Forever 1.60.1.70862 (executable metadata); no fresh GetBuildInfo probe. User read-
only `/fbm api` returned native Max3/Current2 before third-pane activation. That
does not indicate Threat used a native slot. A host read-only process/window
check verified the running Forever path; no focus/input/clipboard operation.

Desktop evidence executes the actual picker OnClick handlers, backend and pinned
native dropdown/Pick methods in ordinary widget/proxy mocks. It checks all offered
presets, direct choices, selected row/column, native creation, maximum capacity,
stale responses, combat deferral, handoff/cleanup and legacy serialized-data
preservation. Paired process times are not native performance; the failing
baseline exits earlier. A separate production Threat fixture verifies all three
native menus route correctly around the fourth owned pane. No new frames/events/
hooks/tickers are added relative to the setup candidate; its Frame becomes a
Button, and native changes reuse the existing two root hooks/geometry coalescer.

[Final evidence](validation/meter-native-controls-2026-11-07.json).

## All native types and preset setup — 7 November 2026

7 November native meter presets (METER-ALL-OPTIONS-20261107): fixed blank
slots when a requested type/window does not already exist in Blizzard's native
configuration. Reserve all exact matches first, then keep unused native panes
accessible for type selection. Mismatched rows have an explicit setup cover;
uncreated slots use the same shared artwork/title/font/color/scale as Damage
and Healing. A native type choice or new-window action triggers one coalesced
layout repair; combat changes defer to the existing regeneration path.
The user chose to keep native meters and configure extra windows once using
Blizzard's menus. No custom renderer, automatic native configuration/creation,
session reset or new recurring driver. Already configured Absorbs and all eleven
enum types skin normally; pinned Retail/Forever native menus omit Absorbs, so
that unavailable selection remains explicitly disclosed. The earlier screenshot
showed the pre-shared-skin setup pane; final native visual/interaction/combat/
taint/FPS acceptance remains pending. 128 focused checks and five alternating
baseline/candidate pairs pass; baseline fails the missing-pane case. Final whole
suite: 209 scripts/871 syntax PASS with unchanged Lua corpus; documentation
validation PASS. Exact identities are in the evidence record. External dated
source/history recovery and existing settings archive verified; fresh settings
metadata only. No game input, settings/profiler writes or manual client sync.

For the one-time setup, open an existing native meter's settings menu and choose
its new-window action, then use that window's title/type menu to choose the
missing view (Interrupts, Dispels, Damage Taken, etc.). FluxUI docks it without
reopening the Meter tab. Repeat type selection when changing a preset's requested
types; Blizzard owns each window's saved type. There are at most three native
windows. FluxUI does not label another type's values as the requested type.

Native Current/Overall/history, source drilldowns, row configuration, values,
cadence and existing skin remain native. Public status distinguishes requested
and actual types and counts setup panes. Setup chrome is pooled (at most three
frames, each with a background/text and shared skin pieces when no native window
exists); it hides on match and releases skin membership on cleanup. Two permanent
guarded root posthooks reuse the existing geometry timer; stable refreshes create
no frames/timers and do not walk rows or write native configuration.

Fresh pinned sources: [Retail 297d7aaa](https://github.com/Gethe/wow-ui-source/blob/297d7aaaa736f346b3e036f38ee088eaf7f8c07f/Interface/AddOns/Blizzard_DamageMeter/DamageMeterSessionWindow.lua)
and [Forever 9dc84f0d](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_DamageMeter/DamageMeterSessionWindow.lua).
Their `DAMAGE_METER_CATEGORIES` omit Absorbs although the enum/native renderer
contains it. Existing Absorbs windows are supported; automatic creation/selection
of an unavailable native option is not claimed. Earlier exact-match-only setup
instructions below are historical; the visible in-place setup flow supersedes them.

[Evidence](validation/meter-all-options-2026-11-07.json).

The requested behavior is Blizzard damage/healing meters with the familiar
Flux Details appearance and a standalone Forever threat pane. The current art
request references optional installed Details files without loading its code;
when files are absent, Flux/Blizzard fallback remains available. This extends the separately validated
[native visibility correction](METER_COMBAT_VISIBILITY.md).

## Accepted design and requirements

The 5 November flat recreation below is historical: the user rejected it on
6 November in favor of METER-WOW-SKIN-01. Existing resource/identity results keep
their exact earlier scope; no visual acceptance is transferred to the new art.

The existing Flux Details embed is the visual reference. The user approved
recreating it with FluxUI and Blizzard assets on 5 November 2026. Details'
[license at the inspected commit](https://github.com/Tercioo/Details-Damage-Meter/blob/3161ab438dd2f2d25b81c4e04c98843c57912b09/LICENSE)
reserves its artwork and bundled font; neither is copied. The recreation uses
class-tinted chrome, the built-in status-bar texture, outlined light text and
green local-player names. An exact artwork/font match is not claimed.

| ID | Required behavior | Owner | Acceptance |
| --- | --- | --- | --- |
| METER-SKIN-01 | Recreate Flux Details styling without Details assets or runtime dependencies | `FluxMeterSkin` | 47 focused checks pass; native screenshots pending |
| METER-SKIN-02 | Keep native initialization, data rendering, durations, menus and secret-value handling native | Skin and native embed | Identity/access-trap regressions pass; native combat pending |
| METER-ENABLE-01 | Automatically enable Blizzard's public damage-meter option for the Flux native backend; defer writes during combat and let native events own initialization | Native embed/startup | Disabled-startup and first-tab fixtures pass; native acceptance pending |
| METER-THREAT-01 | Offer one independent threat pane on Forever when Details is absent | `FluxThreatMeter`, existing `Flux.Threat` | 51 standalone checks pass; native combat pending |
| METER-THREAT-02 | Support up to three native panes plus one threat pane; retain existing preset IDs, defaults and saved layouts | `FluxMeterLayout`, native embed | Catalog/editor/save fixtures pass; native reload pending |
| METER-THREAT-03 | Preserve group/pet facts, target/targettarget selection and opaque values; never label roster order as a secret-derived threat rank | Threat service and pane | Public/opaque, full-roster and scrolling fixtures pass |
| METER-LIFECYCLE-01 | Coalesce event bursts; stop polling and unnecessary subscriptions when hidden or superseded by Details | Owned threat pane | Hidden/handoff, repeated Show and bounded-pool fixtures pass |
| METER-PARITY-01 | Preserve the Details backend and absent-native-meter behavior on other clients | Backend selection | Combined 159 scripts / 816 Lua files pass; native acceptance pending |
| METER-DOCK-01 | Recover cached Flux geometry after late native anchor restoration, outside combat | Native embed | 60 checks and five pinned-source pairs pass; native reload pending |
| METER-OWNERSHIP-01 | Keep native meters hidden on Map/other tabs from startup, before any Meter embed | Native startup visibility | 64 checks and five matched pairs pass; native reload pending |

## Boundaries

Blizzard owns combat-session data, row initialization and duration formatting.
Flux owns the theme, grid and independent threat view. The threat view reads the
existing threat adapter; it does not manufacture a Blizzard damage-meter type
or require a Details plugin object. Its parent is Flux Content rather than the
native meter root so native meter policy cannot accidentally own its lifecycle.

Native scale and pane geometry stay under the existing embed. The owned threat
view compensates its fonts, icons and row height for that scale. Recreating a
theme does not justify writing native Edit Mode visibility or replacing native
rendering methods. Native child Show/Refresh and per-session configuration
remain explicit combat acceptance boundaries.

The user confirmed the empty Meter tab was resolved by enabling Blizzard's
damage-meter option, then requested automatic availability. Flux may enable the
public `damageMeterEnabled` CVar outside combat for its native backend. It must
not write Blizzard's private visibility/cache fields, manually dispatch native
callbacks or load the native UI itself. Blizzard's CVar events and bootstrap
remain responsible for initialization. Details and unsupported-client paths
must not change that CVar.

Readable threat values can be ranked normally. Opaque values remain display
payloads: no comparisons, sorting, arithmetic, formatting through ordinary Lua
or false numeric rank are permitted. Hidden views must cease recurring work;
their next reveal refreshes from current facts.

## Source and recovery

Feature baseline: `8006494fd5f10b54818471933467b9bb867c6543` on main. Verified
external checkpoint `Mail-auction-publication-20261105T203228Z` preserves 1,537
actual files, 122 accessible on-disk settings files and all-ref history. Source
archive SHA256: `efe44322cd86f787161b91509af8f63cf4709fdfdeaef72e6f6f750c51b5a537`.
Unsaved game memory is excluded. A concurrently edited cast-bar theme file is
outside this feature batch and must be preserved.

Forever source is pinned to `eac30af597e5aaa43a60f6675ef5fdcea100375f`
(1.60.1.70790); Retail to `297d7aaaa736f346b3e036f38ee088eaf7f8c07f`
(12.1.5.70783). Classic progression, Era and Anniversary retain capability
detection and their existing Details route; the pinned native meter TOCs do not
load for those game types. Original Wrath is a separate, unverified target.

## Verification and native limits

Five matched pairs and six rejected mutants cover the recreated skin. In the
measured native-window fixture it adds four rails, six initial font styles and
one shared appearance hook. Five hundred repeated entry/window styling pairs
add no further frames, textures or hooks. Release removes active theme owners
and hides the added chrome; native repaint/reload restores native paint rather
than a general undo layer. [Skin samples and identities](validation/meter-skin-comparison-2026-11-05.json).

The standalone pane passes 51 checks and the shared sample correction passes
510, versus four baseline sample failures. Five matched pairs and eleven
rejected mutants cover the pair of changes. Five hundred queued threat events
produce one scan in the fixture; all 80 raid/player-pet facts remain available.
The viewport row pool is bounded by real facts and reused through 500 resize
cycles. Hidden, superseded and cleaned-up views issue no further threat queries
in these fixtures. Existing abbreviation boundaries and Forever's readable
values above 100 percent are preserved. Opaque cohorts retain group order with
no numeric rank prefix. [Threat samples and identities](validation/standalone-threat-comparison-2026-11-05.json).

The shared Forever row now uses the detailed sample already returned by the
existing frame-display adapter. This removes a second query and mixed-instant
rows: 500 populated rows issue 1,000 baseline queries versus 500 candidate
queries. Empty/unavailable samples and other clients retain their contract.
These counts are not native CPU, allocation bytes, latency or FPS measurements.
The new pane and skin add resources; an absent baseline view is not a performance
improvement. Blizzard retains its own events and data work; hiding Flux's owned
threat pane does not claim to stop the native shared UI service.

The user subsequently supplied a 22:04 CET screenshot with Map active and native
Damage/Healing panes at the top-left after reload. Before this fix, visibility
ownership began only at the first Meter embed. Ownership now begins when the
Flux host and enabled Meter tab are ready. Native visibility/Show after-hooks
hide meters outside that host/tab even before the first embed. Disabling the
Meter tab preserves the native standalone route; explicit Cleanup releases
ownership until another embed. Startup passes 64 checks versus 22 baseline
failures, five pairs and four rejected mutants.
[Startup samples and exact identities](validation/meter-startup-comparison-2026-11-05.json).

Late Edit Mode anchor/size updates queue one out-of-combat repair of the root and
cached pane geometry. Own layout writes suppress repair reentry. The repair
uses Blizzard-provided widget-method aliases when available, preserving native
overrides and avoiding addon writes to Edit Mode snap metadata. World entry and
native layout notifications also settle placement; combat uses the existing
regen queue, and hide/cleanup invalidate stale work. Cleanup geometry itself
defers during combat. It does not reconfigure sessions or walk entry pools.

Docking passes 60 checks versus 30 failures against the actual pre-docking
checkpoint source, five pairs and eleven rejected mutants. Each ordinary/gamepad
fixture coalesces 500 restoration bursts into one wake. Modeled addon snap writes
fall from 76 to zero; source-owned metadata writes are not a performance metric.
The optional replay executes pinned native Edit Mode geometry functions. Engine
SavedFramePositionCache internals and native taint are not emulated.
[Docking samples and identities](validation/meter-reload-docking-comparison-2026-11-05.json).

The earlier feature-only layout comparison retains its original scope: 68 checks
versus 41 baseline failures, five pairs and ten rejected mutants before the
subsequent docking/startup corrections. It checks public enablement, the actual
first Meter-tab callback, original preset IDs, saved layouts, catalog limits and
backend handoff. Its simulated later frame availability tests initialization
ordering; the native TOC is not LoadOnDemand, and the fixture does not establish
that changing the CVar loads the addon.
[Feature-stage evidence](validation/native-threat-layout-comparison-2026-11-05.json).

The verified pre-docking recovery checkpoint
`Mail-auction-publication-20261105T205512Z` preserves 1,549 actual files, 122
on-disk settings and all-ref history, including uncommitted feature and concurrent
wand work. Source archive SHA256:
`c01241bfe2564ab2baabaecd4023dd06c4c17193fb211e86b3f45e1276a24b32`.
The startup and docking baseline hashes refer to those actual checkpoint files,
not to the earlier published baseline alone.

External supplement `Meter-native-settings-20261105T212227Z` preserves 38
accessible native meter/Edit Mode saved tables and layout caches. Archive
integrity passed; SHA256:
`210a34953ed1a01433edd268ec9353d68a10b02d2fc17722e9dea516113b4c9a`.
The earlier checkpoints include Config.wtf and Flux settings. Unsaved game
memory is excluded. Final read-only sync checks found all seven affected runtime
and manifest files byte-identical in each of the five client folders. This is
on-disk delivery, not proof of the loaded candidate or native acceptance.

Final combined validation passes 159 scripts and 816 Lua syntax files, with every
Lua hash and file membership unchanged across the run. It preserves the concurrent
wand/cast-bar work. The two old static center-anchor assertions now recognize the
widget alias call; the new docking fixture separately verifies real geometry.
[Complete report and source manifest](validation/meter-standalone-2026-11-05.json).

## Using and checking the new layouts

Existing preset 1 stays the default. In the Meter layout menu, presets 7 and 8
add threat beside damage/healing; preset 8 includes dispels for four panes.
Preset 9 is threat only. The editor's Threat entry can also be used in saved
layouts. These options appear for Forever's native backend without Details;
Details retains its existing presets and plugin.

Reload the final synced files before checking startup ownership, Map/other-tab
visibility and Meter docking. Inspect native timers, source windows, menus,
combat entry/exit, hidden-host reveal, all layouts and Details takeover. Test
target/targettarget, group/pet changes, scrolling and readable/opaque threat.
Repeat native skin/docking checks on Retail; other clients retain their Details
or absent-native route. Capture matched resolution, scale, profile and game state
before claiming visual parity or performance improvement.

No new game input, foreground control, profiling or settings changes are
authorized by this design record. Native rendering, taint, screenshots, memory,
latency and frame-time acceptance remain pending while WoW stays in the
background. Required native checks include reload, all layouts, combat entry and
exit, hidden-host reveal, opaque threat, scrolling, group/pet changes, target
changes, native menus and Details takeover.


## Font readiness and quiet threat follow-up

The first owned title used SetText before a font existed. Native execution and
the stricter desktop fixture reproduce FontString:SetText(): Font not set. The
exception left a partially built pane and aborted subsequent layout cleanup.
Initialize title and row fonts before any text, with shared-skin and font-fallback
paths covered. Do not replace native text APIs or suppress the error.

Readable threat now sorts by percentage first, with raw threat as fallback, as
the existing Details threat view does. Opaque rows retain stable roster order.
Combat exit clears rows, stops updates and avoids native queries; quiet startup,
events and reveal remain scan-free. A later combat wake rebuilds current facts.

Baseline `db42efb10efb0d39cf991dacc27db606000ad7b3`, runtime SHA256
`e43f742010c6398998cf8390bda055563e92e7634496bbff98f045d3f87a3488`.
Candidate runtime SHA256:
`478d82e865a9b49ccf720e60b50b7aa66154c9eabd44c2f0ab41a4be268f7cc7`.
External checkpoint Mail-auction-publication-20261105T213107Z preserves 1,554 actual
files, 160 accessible settings and all-ref history, source SHA256
`a6ffa0fee4832870a4ba2dd20c3f6afc1c2363e8f787be4ed78e5bc2558b8132`.
Unsaved game memory remains excluded; archives/settings stay outside AddOns/Git.

All 65 focused checks pass in five alternating baseline/candidate pairs; the
original baseline aborts on first construction. Five additional font-ready
reference/candidate lifecycle pairs isolate quiet-work reduction without treating
that aborted baseline as equivalent work. Total lifecycle queries fall 1,004 to 2;
500 quiet events and 500 reveals add no candidate queries. The reference has only
font initialization repaired; its exact hash is in the report. Nine semantic
mutants are rejected. [Raw pairs and identities](validation/threat-font-readiness-comparison-2026-11-05.json).

Full desktop validation passes 159 scripts / 816 Lua syntax files; all 816
source hashes and membership are unchanged across the run.
[Full source manifest](validation/meter-threat-readiness-2026-11-05.json). Native acceptance for that earlier font/tab source was pending; final OOC handoff is recorded in the shared-theme stage above.
Forever 70790 partial background checks show Map reload/session FXERR0 and layout 8
construction without Details, with scriptProfile 0. Combat, secret/taint safety,
matched visual parity, frame time and memory acceptance remain pending. Other
clients retain their previous routes and native validation limits.


### Explicit tab hide ownership

Native background checks reproduced native-hidden/threat-visible overlays on
Map, Respec and Buttons through normal tab switches. The previous Meter onHide
runs before activeTab changes, so a native callback could treat it as still
active and resurrect the views. Explicit addon Hide is now latched before
visibility enforcement; native and owned panes share that gate and only explicit
Embed/Show releases it. No native policy field or shared skin code changes.
The existing 1.40 canvas times 0.8 scale remains 112%; no resize is included.

The actual font-candidate checkpoint Mail-auction-publication-20261105T215012Z
preserves 1,555 current files, 160 settings and all-ref history; integrity passes.
Source archive SHA256:
`6616a4f3a12864b60b2a999923631943cc0b3c313459834b0abdd6eaa7d60f08`.
Owner source SHA256: `07acfae4ed9090c8e6226e140062e254cfef9ec8ca6fca64033ee71228750a8a`.

Five alternating pairs pass 429 candidate checks versus 19 baseline failures.
Four mutants are rejected. Eight configurations with 500 transitions each produce
4,000 owned and 1,000 native-root resurrections before correction and zero after.
Mixed-Always repair wakes fall 1,000 to 0; frames/content setters/entry walks/native
policy writes do not grow, and native timer dispatch counts are retained.
[Exact raw transitions and source hashes](validation/native-meter-tab-hide-comparison-2026-11-05.json).

Partial native observations so far: Forever 1.60.1/70790/interface16001, Details
absent, scriptProfile 0, Map reload root hidden/current BugTabs0, and a full threat
body/title with Fonts\ARIALN.TTF 15 OUTLINE after the font fix. Those observations
preceded the final shared-theme handoff captures. Final OOC switching now passes
as recorded below; actual owned-threat combat, secret/taint, matched pixels,
memory and frame-time checks remain inconclusive or pending. The desktop
counts and differing process wall times are not native performance results.


## One-line names and shared meter appearance

The user reported multiword names wrapping and different-looking panes. The
shared style now disables word and nonspace wrapping directly without GetText or secret
text inspection. It uses Friz 12 gold titles, ArialN 14 rows, panel gray .0941/
alpha .70 and row gray .619607/alpha .116164, including independent texture-alpha
normalization. The owned header matches native 32 logical at 0.8 scale (25.6 visual),
with centered title/body inset. Native controls/data, row height/pool and the
existing 112% canvas remain. No reserved art/font asset is copied.

Native configuration can overwrite paint. Reapply shared style after configure
and add one UpdateBackground posthook per native session where available; source
windows lacking that method receive no hook. Inactive/cleanup/Details owners do
no callback paint. Native rendering methods stay intact.

Actual pre-style checkpoint Mail-auction-publication-20261105T215820Z preserves
1,557 files, 160 settings and all-ref history, with verified ZIP/bundle integrity;
source archive SHA256:
`d07305d83bef4f45d4e50ff45a8ace8f0c977f81db57d336fa1a1dba37c779ec`.
Skin/source raw candidate SHA256:
`f8bbb7a0e690ca100c6f6bd3842fa30570191d7aba68edf73bed6db4f7f3f9da`,
`798afff478257b71e276c0e70a87d5fdca5fc16f1ef91f5c6b0c32382cd997c1`.
Native integration candidate:
`cdd1408c9d2cc2e3eb682bbcc24098c394622cac617c4979206b027fb71a5dca`.

Skin 54 and threat 69 checks pass, five matched style pairs/eight mutants; the old
skin fails 11 of 54 checks. A separate native-background stage passes 463 checks
versus 14 failures, five pairs/five mutants. In each ordinary/gamepad fixture,
configured paint is 4/4 panes versus 0/4; 1,000 native background resets restore 2/2
sessions versus 0/2, with no frame/timer/content/policy growth. Native methods stay
native and cleanup callbacks become inactive; 20 reembeds retain only two session
background hooks. Repeated paints are corrected feature work, not native CPU/FPS.
[Style pairs and setup](validation/meter-shared-style-comparison-2026-11-05.json),
[native-background pairs](validation/native-meter-background-comparison-2026-11-05.json).

Final desktop validation passes 159 scripts / 816 Lua syntax files; all 816
source hashes and membership are unchanged across the run. [Exact theme source manifest](validation/meter-theme-consistency-2026-11-05.json).
The earlier font/tab-stage 159/816 report retains its own exact source identity.
The legacy 68-check layout test now measures distinct window resources and
permanent entry hooks; repaint count is not an allocation proxy.

Post-style Forever 70790/interface16001 reload 22:06:45.511Z retains Meter/builtin 7,
Details absent, profile 0 and current BugTabs 0. Title Friz 15, native row ArialN 17.5
and false native name/value wrap flags are observed; shared header/panel fill was
visually inspected. Final OOC native tab handoff passes; actual owned-threat combat rows were not captured, so combat secret/taint and performance remain inconclusive. Preserve builtin 7 rather than the older builtin 1.
Matched pixel comparison, secret/taint, CPU, memory and frame-time acceptance
remain pending across other scenarios and clients.


### Final background native outcome

The final three runtime hashes were loaded on Forever1.60.1/70790/interface16001
at22:06:45.511UTC with Meter/builtin7, Details absent and scriptProfile0. Targeted
validated-window commands kept PC foreground, mouse, keyboard and clipboard
untouched. Map22:08:39.557, Respec22:08:58.688 and Buttons22:09:18.418 each show
native=false/threat=false. ReturnMeter22:09:39.197 shows true/true; summary
22:10:13.490 has currentBugTabs0 and the same Meter/builtin7/profile0 choice.
[Consolidated native metadata](validation/native-meter-background-checks-2026-11-05.json).

Friz15 title, ArialN17.5 native row and false native name/value wrap flags were
observed; the shared header/panel fill was visually inspected. These OOC checks
pass for the captured client/scenarios. A live owned-threat combat row was not
captured during the short fight; only pre/post states exist. Actual combat text,
secret/taint, matched pixel parity, native resource bytes/FPS and other-client
native checks remain inconclusive or pending. Earlier pending OOC handoff notes
refer to their earlier source stages, not this final candidate.


## Installed WoW Interface art references

METER-WOW-SKIN-01 follows the renewed 6 November request for the actual WoW
Interface appearance. Installed Forever Details version #Details.20261104.15400.172
is now present; the older missing-folder state is not current. Read-only source
audit uses upstream pin `cec582cfbac0254e98c393e791478d787ba413a1` plus hashes of
the actual installed files, not assumptions from an old package.

Reference the nine visible atlas regions at the source density/body anchors,
including the no-icon header and no-status footer; use Ground/DGround fills and
Accidental Presidency row font. Stock Friz titles and UI-StatusBar fill remain.
The 128-unit atlas rectangles contain transparency; shrinking the whole region
into a 32-unit header would distort the artwork. Initial owned-art resolution
must precede pooled entry paint; native and owned title font roles stay shared.

No Details/SharedMedia addon code is loaded, no installed files are edited and
no reserved art/font binaries are copied into FluxUI. The installed main license
is All rights reserved. The bundled OFL names Oswald and does not establish an
Accidental grant. These references are not an assertion of redistribution rights.
Native texture/font setter success determines readiness, not metadata existence
or a file ID. Missing paths keep the existing Flux/Blizzard fallback.

Clean baseline `a07c449b1783a7bc876943e5909c3573cfec267a`; verified external
Meter-texture-checkpoint-20261106T053635Z preserves 1,561 actual files, 175 settings
and all-ref history, source SHA256
`345f0c8fd943cc0780635ef64a470c0c31f7dddc9898ac382cde22560db527ee`.
Final source hashes, matched tests and native inspection are pending. No exact
whole-UI pixel claim follows from copying UV/anchor facts or referring to files.
Native data/controls, font-before-text, one-line/opaque text, host/tab ownership,
combat cadence, preset IDs and settings remain separate preserved contracts.


## Automatic Current requirement and supported API gap

The user explicitly chose to preserve every native feature and leave automatic
Current blocked. METER-DEFAULT-CURRENT-01 remains OPEN against the supported API
gap in audited Forever 1.60.1.70790 and Retail 12.1.5.70783. Its implementation is
frozen: no custom renderer, native/private writer, reset, automatic setting or
manual-setup completion claim. Reopen only with new user direction and supported
evidence. No runtime change or new native experiment in this batch.

The user's live `FXDM` inventory returned the eight documented methods. Corrected
`FXCV` output confirmed only enable/show-UI and reset-on-instance-entry, ending
with `FXCV DONE`. This corroborates the source API/CVar gap; it does not prove
loaded-source identity or taint cleanup. The initial helper macro concatenated
nil help and caused its own 12:27:14 RunScript error. The nil-safe correction
passed scratch checks for nil help/nil command and the user's retest. Keep it
separate from user-reported native durationSeconds:929 at 11:45:22 and
specIconID:535 at 11:45:26. Inventory after the reload request is not explicit
clean-error/combat acceptance. No native cleanup pass is claimed.

A 30-second read-only background attempt at 11:25:15 UTC was refused before any
posted message or typed character. Preserve background guards and preferences;
no runtime, settings, profiling or hardware changes. Main baseline was
`0f2e3fdaddb2105eea6afdd1058b96e85308180a`; the dated external runtime-inventory
checkpoint preserves 1,596 sources, 177 settings and all-ref history.

The [Forever native owner](https://github.com/Gethe/wow-ui-source/blob/eac30af597e5aaa43a60f6675ef5fdcea100375f/Interface/AddOns/Blizzard_DamageMeter/DamageMeter.lua#L82)
starts on Overall and its factory inherits that selection. Persisted session
configuration is private, and the native menu reaches the private setter that
failed in the actual client. The [public DamageMeter API](https://github.com/Gethe/wow-ui-source/blob/eac30af597e5aaa43a60f6675ef5fdcea100375f/Interface/AddOns/Blizzard_APIDocumentationGenerated/DamageMeterDocumentation.lua)
has eight methods: seven queries and destructive ResetAllCombatSessions, with
no session/default setter. The [Edit Mode fields](https://github.com/Gethe/wow-ui-source/blob/eac30af597e5aaa43a60f6675ef5fdcea100375f/Interface/AddOns/Blizzard_APIDocumentationGenerated/EditModeManagerConstantsDocumentation.lua#L413)
contain no session choice. [Advanced Options](https://github.com/Gethe/wow-ui-source/blob/eac30af597e5aaa43a60f6675ef5fdcea100375f/Interface/AddOns/Blizzard_SettingsDefinitions_Frame/AdvancedOptions.lua#L403)
offer enable and new-instance reset, not Current; XML has no default route.
The [Retail native owner](https://github.com/Gethe/wow-ui-source/blob/297d7aaaa736f346b3e036f38ee088eaf7f8c07f/Interface/AddOns/Blizzard_DamageMeter/DamageMeter.lua)
and corresponding API/settings paths were audited at its separate pinned commit.
[Full capability/source evidence](validation/meter-automatic-current-capability-2026-11-06.json).

An owned Current renderer cannot currently promise native combat drilldown.
Source GUIDs are conditionally secret and source queries require untainted
arguments; the [native source window](https://github.com/Gethe/wow-ui-source/blob/eac30af597e5aaa43a60f6675ef5fdcea100375f/Interface/AddOns/Blizzard_DamageMeter/DamageMeterSourceWindow.lua#L155)
passes the GUID, stores it and later compares it. Do not silently replace native
controls/source details with reduced functionality. A different design requires
explicit agreement and evidence that the required features remain available.

The removed native experiment remains rejected. Both legacy test commands are
read-only UNSUPPORTED; no further native writes or wrapper attempts. Preserve
history, settings and all existing native features. The prior safe 166-script /
823-file desktop report proves its stated source scope only.

Passive captures at 11:02:01 and 11:06:07 UTC verified the same Forever PID 37088 /
window 341447356 and host executable 70790. The game remained foreground; the
guarded reload was refused before any input. No command completed this turn.
Loaded-source identity, retained-state cleanup, ordinary combat/two-fight,
secret/taint, pixels and performance acceptance remain pending. No settings,
profiling or hardware changes were made. Keep WoW in the background.

## Threat timer and current-view diagnosis

The baseline status showed DamageDone:Overall/HealingDone:Overall, overriding
an earlier ambiguous Current reply. The later explicit native experiment changed
pane/owner/saved selection to1/1/1 but FAILED safety: changed-field metadata went
true to false, pane/owner provenance became _FluxUI and BugTabs reported2/2.
Delayed ordinary native specIconID:535 and durationSeconds:929 failures at11:20
reject that call route. Desktop original-function/field guards and the public
call boundary did not preserve native data provenance.

The entire operative test/preflight/securecallmethod block is removed. Both
`/fbm currenttest` and `/fbm currentteststatus` now return read-only UNSUPPORTED;
no native operation, no further native experiments. Automatic per-combat Current
for every existing/future meter (METER-DEFAULT-CURRENT-01) remains OPEN/unsupported.
Manual native selection is available but does not meet the automatic requirement.
Advanced AutoReset is new-instance reset, not a Current default. Do not reset
sessions/history/settings.

Safe normalized backend SHA256:
`c093068e4e1409f87684e2911ad8cf30874feba89222c8d591bb9ba184e74788`.
It is byte-equal in all five client copies. Reload is required to clear retained
tainted native objects before fresh loaded-source, ordinary refresh/combat and
BugTabs acceptance; disk sync alone is not a native taint pass. 126 no-operation/
provenance, 561 ownership and Core checks pass. Safe full 166 scripts / 823 syntax checks
passes with unchanged source hashes/membership, corpus
`826008fbce898c35a480e1f3752b1bb86e0eb59e71ecfad0d4c8247d369a8039`.
[Safe manifest](validation/meter-rejected-current-removal-2026-11-06.json). Capture-only at 10:36:31Z showed
Forever PID37088/window/Meter; the later reload guard refused before any input.
No cleaned-memory/native acceptance is claimed.
[Decisive native failure/removal](validation/meter-current-live-checks-2026-11-06.json). The prior
[166/823 experimental manifest](validation/meter-current-selection-probe-2026-11-06.json) is
historical/rejected for the configuration route. Ordinary rendering remains
native-data-owned with no restored private setter/default policy.

Elect one timer across displayed native AND owned Threat panes by physical top,
then left. Winning Threat receives eligible native formatted SetText arguments
opaquely in one owned FontString; no GetText/duration inspection. Historical OOC
text waits for the next donor update. Threat-only observed current-combat time
uses the existing0.2-second active poll; unknown hidden starts begin at first
visible observation. Stop/clear on combat end/hide/Details. No frame/event/ticker
is added; the owned FontString is feature cost. Native timer policy stays native.

Timer anchors immediately right of its title with a small gap and remaining
menu-bounded width. Keep title left anchor/baseline; Threat left justification
corrects the centered glyphs without moving its anchor. Measure only public
heading width out of combat, never actor/value/timer text; unreadable metrics
fall back to the bounded box. Native header controls and their artwork fit the
14-display-unit panel (12-unit height). Hidden Close consumes no gap. Embedded
Minimize is hidden/excluded, including its hit area, and original native state
restores out of combat. Original handlers/parents/native configuration remain
unchanged. Source panes/body resize stay native. Existing regeneration repair is
dirty-only;500 stable paints add no geometry writes/duplicate hooks or resources.
Finite/narrow headers can still clip; no native pixel acceptance is claimed.

[Header pairs](validation/meter-header-controls-comparison-2026-11-06.json):172skin/87threat checks,
five alternating checkpoint/candidate pairs/ten rejected mutants.
[Earlier heading pairs](validation/meter-heading-timer-comparison-2026-11-06.json):144/87,
five pairs/eight mutants, historical source stage. Historical operative-probe
checks127 and ownership561 passed before native rejection. [Rejected experiment manifest](validation/meter-current-selection-probe-2026-11-06.json):
166 scripts /823 syntax files, all source hashes/membership unchanged, corpus
`d53d2e5e0c0390aa18ba620a9ab30e713b221b6b952db16060a2feca9eb085ba`.
Historical rejected source SHA256s: native backend
`0531e50faae488c945dabb44b6062638791f72b0c90d508c8ee422a811a29b6e`;
skin `cbddd5bee3d13e67b3bd761136d24ace9d9cf21c62defea1a28107d6f6dc3960`;
threat `c69df568538d4101cac2fded1d7cd9b5fd83e0e28cef4eb1953ae2c1ff75d235`.
Desktop contracts do not certify native call permission, secret/taint/rendering,
clock parity or FPS. The native probe output now proves FAIL; safe cleanup,
genuine two-fight/reload, header/combat and other-client checks remain pending.

Historical native evidence:08:05:58UTC read-only checks found Overall0 for both
panes, Details false/Meter/BugTabs0. Three root UI attempts were refused before
dispatch; a later attempt posted three targeted messages at stale coordinates
after a stock-view change, then loading appeared. It selected no verified Current
option; input stopped and the view-change cause is unknown. Passive08:31 capture
showed the new-instance-reset checkbox, not two fights;09:57 showed town/Map/bags
without probe output. No extra UI input or agent-initiated reload. Preserve the
[raw stage evidence](validation/meter-current-live-checks-2026-11-06.json).
Sandbox process omission did not prove an exit; the same Forever PID37088/window
was host-verified live. Do not restore settings from older captures.

Recovery includes the actual T084055 checkpoint (1,586 sources /177 settings /
all-ref history) and the earlier verified T080249 checkpoint (1,579 sources /
177 settings; source SHA256
`403e098a8f63b1a6875e6eff2dc0ff9e5727c6bd8d97a89f497e4ae1fbcee8fd`).
Concurrent glow records/source are preserved; the captured full manifest lists
exact included source identities.

## Current native configuration boundary

The user's 07:45/07:55 specIconID and 07:57 durationSeconds warnings identify
native execution tainted by Flux. Earlier art/geometry/session fixtures do not
prove this fresh candidate safe. The candidate removes all direct native Lua
configuration/data writers: type/session selection, bar height/spacing,
class/icon flags, lock/minimize and automatic native pane creation. No verified
public AddOn-safe replacement is established for Forever 1.60.1.70790. This is a
capability limit, not permission to hide the warning, compare secret values,
reset saved settings or use securecall to claim clean provenance.

Dock already native-selected windows by their actual types. If a requested type
or additional pane does not exist, preserve the saved Flux request and show an
explicit instruction to create/select it using Blizzard controls. Use `/fbm cleanup`, create/select the requested windows through Blizzard
controls, then `/fbm embed`; `/fbm status` reports remaining gaps. Do not label
a Damage pane as Healing or silently auto-create/reconfigure it. Native row
configuration and controls remain native; exact automatic row/type setup and
whole-UI parity cannot be promised through an unverified private setter.

Native Current gives a fresh per-fight view; the new-instance-reset checkbox
has a different purpose. Preserve user-selected Current, Overall and historical
views, including the factory default Overall. An earlier forced-Overall path
was a bug; its removal does not justify blindly changing an existing Overall
selection or deleting sessions. If needed the player selects Current once via
the native controls.

| ID | Required behavior | Current status |
| --- | --- | --- |
| METER-NATIVE-OWNERSHIP-01 | No AddOn-issued native data/configuration writes or automatic pane creation; preserve native controls and explicit missing-type setup | Implemented; 26 focused checks/five pairs/five mutants and current full suite pass; native acceptance pending |
| METER-CURRENT-VIEW-01 | Preserve chosen Current/Overall/history without reset; native Current supplies per-fight view | Implemented; native controls remain authoritative; fresh native acceptance pending |
| METER-TIMER-01 | One visible native timer in the topmost then leftmost mapped native pane; native formatting/data/policy untouched | Implemented; 113 focused checks/five pairs/nine mutants and current full suite pass; native acceptance pending |

Timer election uses greatest top then least left in physical screen coordinates,
with stable fallback for unreadable geometry. It never reads/compares/converts
secret durations or supplies a replacement clock. Native text, formatting,
eligibility and cadence remain native, including an originally zero alpha.
Reserve up to 45 display units in headers out of combat; retain the left title
and native menus, aligning the timer before the session menu. The dependent
type menu gets its own Header anchor. Combat election changes alpha only.
Cleanup restores original timer/menu anchors, widths and alphas out of combat;
reactivation snapshots current native alpha. Three permanent guarded script
posthooks per session (Show/Hide/Size) become inactive after release, with no
new frames/events/timers/textures. Narrow headers can still clip text.

[Writer comparison](validation/meter-native-writer-comparison-2026-11-06.json) records the
26-check fixture, five alternating pairs/five rejected mutants and frozen backend
SHA256 `4ca339e31d5d9644b2dc821cf56f4142ce6226a08816cdf879260f06f7d49aaa`.
[Timer comparison](validation/meter-single-timer-comparison-2026-11-06.json) records the
113-check fixture, five alternating pairs/nine rejected mutants and normalized
Skin SHA256 `cb43ca5f7988f32d335090aadc4353421d78023806e7ce1430b17bafef93a650`.
Ownership561/startup64/docking60/layout71 focused checks pass; the production
Details geometry comparison covers 28,992 checks over 4,920 layouts. These are
stated desktop scopes only. Final full validation passes 162 scripts /819 Lua
syntax files, with all 819 source hashes/membership unchanged and corpus
`5b008deec37a9e32ebf53442630c19012f9ce52a78ae0e7cc46e900552b2e377`.
[Current full manifest](validation/meter-timer-native-boundary-2026-11-06.json). The first full run
failed four stale Core meter assertions; the fixture contract was reconciled
without restoring unsafe production calls. Native taint safety, exact pixels
and native performance remain unverified.

The 07:31 UTC sandbox-empty process result was incorrectly read as an exit.
Host inspection later verified the same Forever PID37088/window live. No
automatic launch/focus was issued; historical captures remain stage-specific.
Fresh loaded-source identity,
native combat/taint, exact dimensions/artwork and timer acceptance remain open.
Concurrent raid/glow source and continuity changes must remain preserved.

External Meter-timer-and-taint-checkpoint-20261106T072904Z includes 1,571 actual
source files /177 settings and all-ref history; ZIP/bundle validation passes.
Source archive SHA256:
`7dc36164c7a5abdd83e66e472990ebd560897fbd39ccc7d0aac6dd76c81d4205`.
