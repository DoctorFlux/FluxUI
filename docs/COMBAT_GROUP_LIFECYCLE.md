# Combat party and raid lifecycle

10 November native counterexample: the secure roster reveal remained valid, but
its ordinary power repaint reached blocked partition SetHeight/Show. Earlier
roster tests stubbed these painters; their results did not prove end-to-end child
geometry permissions. The shared path is corrected and strict production-path
coverage added. Native post-fix acceptance remains pending.
[Correction and exact evidence](POWER_PARTITION_COMBAT_JOIN.md).

9 November 2026 — COMBAT-GROUP-LIFECYCLE-20261109; REQ-RF-98, reaffirming
REQ-RF-83. The user explicitly requests checking Blizzard's implementation for
joining, leaving and every roster change during combat across all five clients.
Keep current appearance, ordering, features, settings, bindings and performance
work. This is a security/lifecycle audit, not a UI redesign.

## Blizzard's current mechanism

Current Gethe source on each client loads SecureHandlers, SecureStateDriver and
SecureGroupHeaders from Blizzard_RestrictedAddOnEnvironment. The native raid
header template inherits the secure group header. The relevant handlers are
trusted client code; ordinary addon event handlers do not gain their authority.

GROUP_ROSTER_UPDATE and UNIT_PET wake the native state manager by resetting its
timer to zero. On its next UI update it resolves registered macro state/visibility
conditions and unit watches. It does not wait for PLAYER_REGEN_ENABLED. Its
ordinary fallback sample interval is 0.2 seconds; neither that constant nor a
desktop replay establishes actual native join latency.

Visible secure headers process roster/name notifications, assign native unit
tokens, and show/hide their prepared children. Addon-created protected frames,
attributes, anchors, secure references and drivers must be prepared outside
combat. During combat, native handlers and restricted snippets own protected
visibility, assignment and layout. Textures/text/bar values remain presentation
work subject to their own access rules. Catching an error does not authorize a
protected operation or reveal a secret value.

## Flux mapping and result

No missing runtime path was found in the inspected implementation. No runtime
code changed in this audit. Existing steady-party and roster optimizations remain.

| Change during combat | Existing owner and expected result |
| --- | --- |
| Solo to party, compact mode | Prepared group1 native header reveals the parent and player/party slots. |
| Solo to party, player style | Prepared member/pet/target visibility drivers reveal the parent and existing party units. |
| Solo/party to raid | Native group conditions reveal all prepared raid headers and hide player-style party members. |
| Member joins/leaves in the same group mode | Native header/existence updates populate or retire prepared slots without new frames or unit-attribute writes from ordinary Lua. |
| Subgroup moves, roster reorder, raid shrinks/grows | Native INDEX ordering reassigns child tokens; secure attribute wrappers update joined-column positions. |
| MT/MA role changes | Prepared native role-filtered header updates membership; secure target attachment follows the assigned source token. |
| Raid to party, leave to solo | Native conditions hide raid-only/absent party buttons and their input regions. The empty container may remain alive without unit hit regions. |
| Pets or party targets appear/disappear | Existing prepared visibility/existence drivers reveal/hide the relevant children. |

All eight five-slot group headers and the forty-slot MT/MA pool are prepared even
from solo startup. Player-style party mode prepares four member/pet/target sets.
The prepared shared container uses SecureFrameTemplate. Empty raid group headers
stay shown at alpha zero while in raid: hiding them would prevent the native
visible-header roster callback from discovering a newly occupied subgroup.
Secure header callbacks reveal the hidden container before showing populated
children. Ordinary post-roster layout/settings reconciliation can be deferred;
that queue does not own the native combat reveal or removal.

The ordinary aura/health/cast/indicator work and Flux hover casting still use the
current presentation/binding owners. No global native functions are replaced, no
taint is laundered, and no private aura data is read to control protected visibility.
The audit adds one regression script and documentation only; no runtime frame,
event, hook, polling, timer, setting, driver or background service is added.

## Exact source and tests

Fifty freshly fetched source files match their exact Gethe Git blobs. This covers
version files, client-specific FrameXML TOCs, secure-environment TOCs, native
Lua handlers and group/handler/click templates. Progression loads its Mists
FrameXML TOC; Era uses Vanilla and Anniversary uses TBC. Missing generic TOC
paths were followed to their actual flavor TOCs rather than treated as removal.

| Client | Gethe commit | Source build |
| --- | --- | --- |
| Retail | `297d7aaaa736f346b3e036f38ee088eaf7f8c07f` | 12.1.5.70783 |
| Forever | `9dc84f0d3bbae1768ac3405b3716000bd93eda06` | 1.60.1.70862 |
| Classic progression | `e5d9b3a22c3f0f6f41ebac0e454f4969594261cf` | 5.5.4.70631 |
| Classic Era | `4192ac60067fc55566182291bc67c85dd9b6794d` | 1.15.9.70576 |
| Anniversary | `68e0a2ec559d9761dfc4e7f864c3944f9d758a49` | 2.5.6.70577 |

The new fixture executes the actual native group implementation, state manager,
state/attribute wrappers and Flux secure owner with real modeled parent ancestry.
It includes the complete native event-to-next-update manager, beyond the old
resolver-only replay. Each run passes 247,385 checks over 1,800 transitions:
five clients, two party styles, four callback orders and three repetitions of
15 states. Full raids, empty/sparse groups, moves, MT membership, conversions,
joins/leaves, hidden parents, pets, targets and pet battles are included.
Prepared frame capacity remains constant; ordinary presentation callbacks have
no modeled protected authority. Three repeated runs pass identically.

Six harmful controls fail: removing compact or player-style parent reveal,
leaving headers visible, skipping unit-change layout invalidation, failing to
prepare raid display, or exposing player-style party buttons in raid. Thirty
additional source-contract checks verify loading/inheritance and native event
registration/wake behavior. These are correctness/security-model checks, not
FPS, CPU, allocation or exact native scheduling measurements.
The complete suite passes274 scripts and944 Lua syntax checks. Every current Lua
hash matches its full-validation manifest; existing runtime matches the recovery
checkpoint. All25 inspected installed owner copies match through existing sync.

The external source/history checkpoint verifies 2,463 source files and all-ref
history; 43 available settings metadata entries were inspected read-only. No
private settings enter AddOns. No foreground/input, settings/profiler write,
manual sync, publication or existing-source replacement occurred.
[Machine evidence](validation/combat-group-lifecycle-2026-11-09.json) retains
source identities, raw repeated logs, controls, hashes and validation scope.

## Native limits and acceptance

Source review and desktop models cannot certify a taint-free native session.
No connected Witchcraft/native execution tool is available; the user's existing
manual test route remains. Keep WoW in the background and preserve profiling
preferences. All-client native acceptance remains NOT RUN.

The feature must have completed protected preparation before combat. Loading or
enabling previously unprepared protected UI during combat cannot safely create
those frames immediately. Existing readiness/failure paths keep native fallback
and defer construction instead of attempting forbidden protected operations.
This boundary differs from ordinary mid-combat group changes with prepared UI.

On each actual client/build: prepare while solo, enter combat, join party, grow
to five, convert/join raid, move members between groups, change leader/MT/MA,
remove/invite members, shrink, convert back and leave to solo. Verify immediate
native-update visibility/removal, no stale hit rectangles, names/units/column
order, pets/targets, hover casting, right-click menus, auras/casts/status/range,
Lua errors and taint. Repeat both party styles and retain native build, settings,
addon list and scenario evidence. Native timing/pixels/FPS/taint remain pending.
