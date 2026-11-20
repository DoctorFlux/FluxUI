# Original World Map scene in Flux Window

20 November. Forever hosts the original map and its addon drawings. While
combat is active, the hosted map keeps its existing pins and defers quest-watch,
quest-log and quest-POI refresh events. The subscriptions resume after lockdown
and missed notifications produce one refresh. The map's original methods,
providers and pin pools still belong to Blizzard. Live taint validation is
pending. [Combat report and validation](validation/world-map-combat-2026-11-20.json).

Requirement **WORLD-MAP-SURFACE-20261116**, 16 November 2026. With **Map Pins**
enabled, Flux's battlefield view displays the original World Map scene, including
native pins, the player arrow, guide routes, areas, labels and addon drawings.
The user selected original-map reuse and shared map state so this needs no
addon dependency or list of addon-specific adapters. This supersedes the former
Retail native-only policy and the RestedXP/HBD pin-only scope.

The user previously confirmed map fill/pins, large-map key open/close,
complete-scene scaling and opacity while moving on the running Forever client.
A subsequent native regression reopened visibility: the mounted source retained
its old World Map coordinates outside the Flux clip. The 17 November anchor
recovery now validates actual placement and repairs later native positioning;
its first native reload still failed because WindowMover synchronously restored
saved World Map coordinates. The current ownership fix makes the mover yield
for preparation/embedding and cancel active gestures before saving temporary
geometry; its native reload check is pending. Prior confirmations and the historical
478-script / 1,168-file full run apply to their recorded sources only.
[Earlier source hashes and native scope](validation/world-map-surface-final-2026-11-16.json),
[current anchor recovery and scoped validation](validation/world-map-anchor-recovery-2026-11-17.json).
Other-client native checks, controller, combat/taint and CPU/FPS remain pending.

## Implementation and ownership

[FluxBattlefieldWorldMap.lua](../Battlezonemap/FluxBattlefieldWorldMap.lua) retains
the same `WorldMapFrame`, ScrollContainer, canvas, pin pools, providers, frames,
regions and addon callbacks. It mounts that original scene in an independent
clipped frame anchored to the battlefield content rectangle. Its LOW strata
places it above BACKGROUND terrain and below the MEDIUM HUD/combat blocker.
[World features](../Battlezonemap/FluxBattlefieldMapWorldFeatures.lua) owns the
existing setting and map lifecycle; optional provider/HBD routes release before
the original source is shown and cannot install over an active source owner.

Only stock window chrome is hidden while mounted; the root's large window hit
region is disabled and the original scroll/pin input remains. Source scroll
anchors, parent, dimensions, scale, draw order, mouse flags, native click policy,
chrome, alpha and renderer flags return before normal-map use. No global map API,
original OnUpdate, provider, pin-acquire method, binding, UIPanel attribute or
panel-manager table is replaced. Hooks are bounded and owned by the source frame
or existing service. Native open/close sounds, emote and zoom behavior remain
native; their wider scenarios are still acceptance checks.

Preparation keeps the source shown at alpha zero across bounded next-frame
layout reads. A never-opened source gets a temporary anchor only when it has no
anchors. Cancellation, replacement, combat and exhaustion clean up that state.
Renderer/flatten flags are captured before preparation and changed only while
the root is hidden and outside combat. This avoids the observed stale miniature
and live compositor transition. Full-map show restores the original flags first.

## Recovery after native positioning

The failing live diagnostic showed an enabled, visible mounted root at
`16,374` with the correct `697x465` logical size, while the Flux viewport was at
`1543.54,19.35`. Correct size, scale and parent did not imply a correct anchor.
The previous fit cache checked its last requested offsets and skipped the
native frame's actual points. Blizzard's panel manager can reset the root to
`UIParent` coordinates without changing its parent or size.

Fit now checks the exact root anchor and both original ScrollContainer corners,
as well as the root parent, logical size and scale. Source-owned placement
posthooks queue one deferred sync after native writes. They are inactive during
Flux's own writes, native full-map ownership, deactivation and retired-source
callbacks. Full-map handoff takes priority; combat still defers mutations.
A parent repair gets one settling pass for synchronous native OnShow layout.
Unchanged sync performs no layout writes; anchor-only repair does not resize the
native scene. No canvas hook, per-pin work, polling or driver is added.

The first anchor-only candidate still failed natively. Its new diagnostic showed
`BOTTOMLEFT:UIParent:16,374`, matching Flux WindowMover's own saved-position
writer exactly. The isolated surface fixture did not load that competing owner.
The mover's real SetPoint/SetScale hooks called Apply synchronously during Fit,
replacing the correct hosted anchor while self-write guards were active.
`Surface:OwnsLayout(frame)` now identifies only this exact source during
preparation and embedding, including combat-deferred release after deactivation.
WindowMover yields before apply/reapply/layout/input work and stops an active
proxy gesture before saving coordinates/scale. Existing hooks, saved/session
records, options and normal full-map dragging resume after layout handoff.
Combined-source regressions execute the real Engine and its permanent hooks.
Current scoped checks pass22,168 surface and315 combined-owner assertions per
Lua5.1/5.4; the exact old Engine fails the new regression. Both installed source
copies match read-only. Native reload acceptance remains pending.
`/fluxwm` now includes anchor count and the first anchor's relative frame.

## Uniform scene scale and opacity

The source's normal logical viewport is captured once per ownership period.
The map-only body retains that logical size; one outer root transform fits and
centers it inside Flux. Native player/unit pins ignore global pin scale and
compensate for canvas zoom, as do ordinary map pins. Resizing the logical canvas
therefore kept some markers large. Retaining it scales terrain, the native arrow,
ordinary pins, guide glyphs, direct text, lines and areas together. Flux resizing
changes only the outer transform, without repeated native zoom resets. No child
scan or per-pin/addon sizing override is needed.
[Three-client native and installed-guide scaling contracts](validation/world-map-uniform-scale-sources-2026-11-16.json).

Mounted native movement fading is removed only for the original source frame.
`PlayerMovementFrameFader.RemoveFrame(world)` cancels both active and deferred
entries after native OnShow; preparation remains alpha zero and the mounted map
uses alpha one. Normal full-map OnShow registers native fading again. The
`mapFade` CVar, unrelated fading frames and shared native driver are untouched.
This adds no movement listener, opacity polling or unchanged-Sync alpha writes.
[Native fader ownership contract](validation/world-map-opacity-sources-2026-11-16.json).

Source addons keep their own content, settings, filters, cadence and callbacks.
Separate popups/windows outside the map hierarchy retain their own owners.
Private child policies that explicitly bypass parent scaling remain addon-owned;
source presence cannot certify every future private renderer. No Polestar code,
guide data or artwork is copied; inspected licenses remain with their owners.

## Requirements and acceptance

| ID | Behavior | Current evidence |
|---|---|---|
| WM01 | Original native/addon map objects and updates, no dependency or adapter list | Original/late/replaced-root identities and callbacks pass; user pins/map pass |
| WM02 | Existing Map Pins and battlefield/tab lifecycle gate ownership | Actual source/fallback activation and release checks pass; broader native tab cases pending |
| WM03 | Real World Map key opens once and closes on the next press | Native toggle-method hook plus global fallback; deferred ShowUIPanel transfer; user confirms |
| WM04 | Shared map state and battlefield zone synchronization | User selected shared state; original mapID synchronization tests pass |
| WM05 | Native API, pool, callback and secure ownership preserved | No replacements/secret access; source review and guarded tests pass; native taint pending |
| WM06 | Restricted parent/layout/renderer/full-map transitions defer in combat | Source/cancellation/replacement/full-close/combat fixtures pass; native combat pending |
| WM07 | No extra polling, canvas enumeration, cloned content or duplicate addon render pass | Stable hosts/hooks, 1,000 unchanged Syncs, root-transform-only resize checks pass; native CPU/FPS pending |
| WM08 | Exact restoration and saved data | Native root/scroll anchors, dimensions, input, renderer and alpha restore checks pass; no settings reset |
| WM09 | Existing native mouse/keyboard/controller ownership | User map and key behavior pass; controller reachability/back/focus and other native inputs pending |
| WM10 | Bounded provider/HBD fallback with one owner | Actual lifecycle/stale-discovery checks pass; HBD50 toggles retain one removal hook per library |
| WM11 | Whole-scene uniform scale, including player arrow and addon content | Actual native pin/unit size methods plus six content families pass; user: all look perfect |
| WM12 | Full opacity during movement only while mounted | Actual native movement fader checks pass; user confirms opaque while moving |
| WM13 | Renderer changes happen hidden, normal renderer returns on full-map handoff | Four original flag combinations, cancellation and full-map restoration checks pass; user rendering pass |
| WM14 | Battlefield-shaped content with stock window chrome/input excluded | Exact scene/viewport geometry, stock chrome and mouse-state restoration checks pass; user map fill pass |
| WM15 | Recover actual placement and coordinate temporary hosting with WindowMover | Isolated anchor checks pass but native failure retained; real mover integration covered separately; current native reload pending |
| WM16 | Keep the original Forever scene visible through combat and defer quest event refreshes | Actual feature activation and model combat checks pass. Native quest delivery and taint pending |

A visual fixture is not native pixel, secure VM, secret-value, controller or FPS
acceptance. The final user observations establish their stated scope only. The
helper test run used BelowNormal priority; no WoW priority, profiler preference,
foreground, mouse, keyboard or clipboard control was changed by the agent.

## Client/source matrix and remaining native checks

| Target | Pinned Gethe source | Native status |
|---|---|---|
| Retail | `297d7aaaa736f346b3e036f38ee088eaf7f8c07f` / 12.1.5.70783 | Pending |
| Forever | `bebcb6bf309cf41b41bd74f8ca651e6a105b2676` / 1.60.1.70938 | Prior scene/M/opacity confirmations; current anchor recovery native reload pending |
| Classic progression | `e5d9b3a22c3f0f6f41ebac0e454f4969594261cf` / 5.5.4.70631 | Pending |
| Existing Era / Anniversary | Existing adapters/capability paths retained; no fresh branch certification | Desktop paths pass; native pending |

The host process was verified as `_forever_/Wow.exe`, PID46260, window600248958,
World of Warcraft. GetBuildInfo was not queried; Flux's diagnostic Retail label
is a family label, not evidence that this was Retail. The user performed reload,
map-key, movement and diagnostic actions. One earlier read-only background window
capture established terrain-only rendering; its private PNG remains external.

Run other clients sequentially, leaving WoW in the background. Still check broad
addon combinations/late load; reload and first load; Map/Minimap/tab/hide cycles;
window/UI scale and reference re-acquisition; zones/dungeons; pan/zoom/hover/click;
quest links and direct open calls; Escape/controller back; other UIPanels; combat
interruption/recovery; original full-map fade and profiler-off matched CPU/FPS.
Do not infer those results from the user confirmations or desktop operation counts.

## Evidence and recovery

- [Original-surface source contracts](validation/world-map-surface-sources-2026-11-16.json)
  and [map/guide sources](validation/world-map-bridge-sources-2026-11-16.json).
- [Observed failure chronology](validation/world-map-surface-blank-2026-11-16.json)
  retains the native blank/inset, diagnostic and control regressions instead of
  treating earlier passing mocks as native acceptance.
- [Initial verified source/history checkpoint](validation/world-map-bridge-checkpoint-2026-11-16.json),
  [blackout checkpoint](validation/world-map-surface-blank-checkpoint-2026-11-16.json)
  and [field-size checkpoint](validation/world-map-field-size-checkpoint-2026-11-16.json)
  are external to AddOns. Private on-disk settings metadata was inspected; no
  quiescent settings backup or settings reset is claimed.
- [Final phase results](validation/world-map-surface-final-2026-11-16.json) retain
  source identities, alternating baseline pairs, compiled harmful controls,
  native confirmations, low-priority full run and exact verification corpus.
- [WowSim evaluation](validation/wowsim-evaluation-2026-11-16.json): useful optional
  basic Lua/widget previews, but its current XML/map/framebuffer/panel/security
  stubs cannot reproduce or certify this native problem. It was assessed
  read-only; no dependencies were installed and no code was vendored.

Validation boundary: the earlier 478-script run was stable for its recorded
source corpus. Anchor recovery changes the surface and regression fixture;
current scoped results and hashes are recorded separately. Newer unrelated
work is preserved. No historical full-run or native result certifies the
current source automatically.
