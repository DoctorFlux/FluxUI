# Native meter skin and standalone threat pane

The requested behavior is Blizzard damage/healing meters with the familiar
Flux Details appearance, plus a threat pane on Forever without installing or
loading Details. This extends the separately validated
[native visibility correction](METER_COMBAT_VISIBILITY.md).

## Accepted design and requirements

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
