# Edit Mode native ownership

8 November 2026 — EDIT-MODE-NATIVE-20261108.

Saving a Forever Edit Mode profile produced a compact-party health-color error,
followed by recurring Cooldown Viewer private-map errors attributed to FluxUI.
After the corrections, the user's normal save/viewer retest reports no new
errors. This does not conclusively locate the first taint source or certify
every client.

The tooltip positioner used native Lua point overrides that write snapping and
the manager's anchor-dirty state, including inside Enter/Exit callbacks. It now
uses the saved widget methods and the existing editor/combat queues. Native
movable/user-placed/layout flags are untouched. Ordinary combat tooltips retain
their owner and BOTTOMLEFT/TOPLEFT +0/+30 position.

The old global specialization-event opt-out is removed; Blizzard's original unit
event/filter remains. Its legacy public helper now only reports readiness.
Player/target/focus/pet/cast selectors are muted only for active Flux replacements;
their original alpha and independent click/motion states return with native
frames. Other native systems retain their controls.

Optional /fluxinput edit records field security metadata without reading health
colors or private aura-map contents. Only two snapshots are retained separately
from prior input evidence. Performance-capture completion now preserves both
diagnostic roots alongside spike-watch evidence. No new frame/event/ticker or
OnUpdate registration is added; the tooltip Enter callback is removed.

The verified external Edit-mode-native-20261108T201644Z checkpoint contains2,291
actual sources, all-ref history and188 accessible on-disk settings. Main remains
at1fd463f4de4bbff659f4e402c6f31138c49765b4 plus preserved user changes.
[Exact four-owner hashes and raw samples](validation/edit-mode-native-comparison-2026-11-08.json)
record five alternating pairs and three isolated old-owner controls, plus five
profiler-retention pairs. Candidate295 checks pass; old sources reject. Existing
recovery215/settings363/native-mouse2545/bar43 checks pass.
[Full259 scripts and924 syntax files pass](validation/edit-mode-native-full-2026-11-08.json),
with no [Lua drift](validation/edit-mode-native-source-guard-2026-11-08.json).

Per client model, the same startup/editor/dialog/close/combat scenario reduces
tooltip override calls274->0, point calls276->18, native spec unregisters1->0 and
movable/user-placed writes2->0, retaining3 saves and5 resets. These are bounded
desktop dispatch counts, not native CPU, allocation, latency, frame-time or FPS
measurements. Harness wall times are not addon performance. Snapshots use weak
keys and primitive selector state; optional metadata retains two samples.

[Twenty installed runtime copies match](validation/edit-mode-native-client-copy-2026-11-08.json).
[Twenty-two primary blobs](validation/edit-mode-native-references-2026-11-08.json)
cover ownership/security; all60 selected native method bodies used in the fixture
match fresh pins exactly. Source presence is separate from native feature loading.
The Cooldown Viewer TOC permits standard/camelot, and its map rejects tainted
access. No native map, refresh/save method, frame script, API or profile is replaced.

[Forever evidence](validation/edit-mode-native-forever-2026-11-08.json) records the
user-operated successful save/viewer result and nine secure metadata fields.
On-disk edit snapshots were absent, so loaded GetBuildInfo/profile/addon list and
comprehensive security acceptance remain uninstrumented. Background guards
refused commands before input; a read-only capture retained foreground. No
automatic save, reload, settings/profiler/clipboard/focus or gameplay action ran.
Other clients, sustained combat, pixels and native performance remain pending.

For remaining acceptance, reload outside combat; create/save/cancel/switch/reload
layouts and change specialization. Test mixed Flux/native unit-frame choices,
native selectors/resize, viewers and auras, boss/arena frames, overlays, talking
head, loot and combat tooltips. Capture /fluxinput edit before/after, reload to
save, and inspect fresh BugTabs/taint errors. Repeat on installed Retail12.1.5.70783,
Forever1.60.1.70862, progression5.5.4.70631, Era1.15.9.70576 and
Anniversary2.5.6.70577 where supported. Original Wrath is not installed/tested.
