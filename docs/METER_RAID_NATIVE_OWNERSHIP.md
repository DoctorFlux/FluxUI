# Damage meter and raid-header errors — 5 November 2026

The supplied log contains 15 warnings at Forever's
`DamageMeterEntry.lua:535` comparing secret `specIconID`, and two blocked
`SecureGroupHeaders.lua:174` child creations labeled `UNKNOWN()`. The meter
stacks include Flux embed/show, type/session changes and startup layout. The
group-header stacks contain no header name or Flux caller; their original taint
writer remains unattributed.

## Meter correction

Flux replaced Blizzard entry rendering, source/spell `Init`, pooled entry methods,
session duration and root visibility methods. The wrapped `Init` re-entered addon
code immediately before native rendering compared the secret icon ID. Those
replacements and their retries are removed. Blizzard owns entry initialization,
icons, names, values, bars and duration formatting. No new secret-field wrapper,
global API replacement, privilege shim, CVar toggle or error suppression was added.

The existing green local-player name/white other-row tint remains through secure
posthooks after native session/source `InitEntry` completes, with one initial
style pass for existing rows. `isLocalPlayer` is declared `NeverSecret`; an extra
secret-value check omits styling if a different client cannot expose it. Native
functions remain intact. No per-entry hooks or repeated pool patching remain.

Blizzard's type/session setters always refresh content, even for identical
selections. Geometry updates now compare native user-selected configuration first;
actual type/session changes still use owner setters. Existing scales, grid,
panes, class colors, icons, reset commands, startup/combat deferral, Details
priority and absent-client behavior remain. A secure visibility posthook reapplies
the Flux tab/host boundary after native visibility events; it does not sanitize
the native event that already ran. Native Show/content/resize taint acceptance is
still pending. The remaining native visibility/configuration APIs are not claimed
universally safe from desktop tests.

Timer formatting now stays native rather than substituting `[--:--]` for unreadable
duration. This intentionally corrects the old renderer interception; it does not
extract restricted values. A reload is necessary to discard old in-memory method
replacements. Writing files cannot repair the running Lua session's provenance.

## Raid correction and attribution limit

The production precreation path had two independent failures:

- The owned raid container starts hidden. Showing only a child header does not
  make it effectively visible; Blizzard ignores its attribute-update seed. Flux
  nevertheless marked the pool complete.
- Generic setup seeded five children before applying MT/MA's final four rows by
  ten columns. The completion marker then prevented the intended forty-slot seed.

Precreation now runs after final header attributes. It temporarily shows the
owned container/header out of combat, restores their previous shown states and
marks completion only when the final native child exists. An externally hidden
UIParent remains hidden; an incomplete pool can retry at a later out-of-combat
configuration. No direct call/replacement of the native group updater and no
protected mutation during combat were added. Party/group/MTMA geometry, unit
assignment, options, defaults and saved data stay unchanged.

This fixes a reproduced capacity/lifecycle failure. It does **not** prove that the
two `UNKNOWN()` messages came from these headers, or that ordinary secure native
creation is always forbidden in combat. The fixture models the supplied denial
when a missing child is requested. Native error/taint attribution remains pending.

## Source, checkpoint and desktop results

Clean baseline main: `aa253cc605d3ecf43ee42f22cd79ff9d6d480d64`, preserving the
newer consumable-target work. External checkpoint
`Meter-header-errors-20261105T125630Z` contains 1,471 actual source files, verified
all-ref Git history and 127 accessible on-disk Flux settings files. Source ZIP
SHA256: `a1e6058eed0345d9f7d9ab88aaa11adc30412848db05864805d5e336991505ba`.
ZIP integrity passes; archives/settings are outside AddOns. Unsaved game memory
is not included.

[Exact source hashes, five matched pairs, mutations and environment](validation/meter-raid-ownership-comparison-2026-11-05.json).
[Full validation and source manifest](validation/meter-raid-ownership-2026-11-05.json).
[Meter regression](../tests/native_meter_ownership.lua);
[raid regression](../tests/raid_header_precreation.lua).

| Synthetic desktop scenario | Baseline | Candidate |
| --- | --- | --- |
| Meter: 50 layouts + 50 host resizes, two panes, five capability labels after embed warm-up | 1,000 type calls / 1,000 session calls / 1,000 entry-pool walks | 0 / 0 / 0 |
| Separate Forever gamepad patch retry timers | 9 | 0 |
| Raid hidden startup: upfront children / modeled denied combat child creations | 9 / 2 | 80 / 0 |
| Raid already-visible parent: upfront children / modeled denied combat child creations | 45 / 1 | 80 / 0 |
| Party upfront children; disabled upfront children | 1; 0 | 5; 0 |

Counts are identical across five alternating fresh-process pairs. Baseline fails
103 of 180 meter checks and 85 of 150 raid checks; candidates pass all 330.
Five deliberately broken variants are rejected. Full validation passes 136 scripts
and 791 Lua syntax files, including existing window, raid, provider, inventory and
consumable regressions. Native functions retained, green/white row reuse,
selection changes, tab visibility, reopen/cleanup, bounded timers, disabled work,
effective visibility and final capacities are checked using real production
modules with native frames/methods mocked.

The intended raid pools allocate more resources up front: 80 header children
(eight groups of five plus forty MT/MA slots) in the raid fixture. This bounded
tradeoff avoids modeled missing-child creation later; it is not a native memory,
startup CPU or frame-time improvement claim. Party allocates only five; disabled
allocates none. Secure posthooks are once per persistent meter/session/source
window, and become inactive after cleanup. No polling or forced GC was added.

Wall samples include process startup and assertions, not operation latency.
Native CPU, allocation, frame time, capture duration and current enabled-addon /
profile / hardware settings are unavailable. Capability labels do not certify
that all five clients ship a native damage meter. Native taint, secrets, rendering
and timing are not simulated. No foreground/input/clipboard/profiler/private
settings were controlled.

## Pinned client evidence

The user supplied Gethe's source and explicitly requested Forever plus other
clients. Meter behavior was compared on both native-meter branches. The visible
header gate and missing-child creation path were checked on all five current
source branches:

| Client | Version / source commit |
| --- | --- |
| Forever | 1.60.1.70790 / `eac30af597e5aaa43a60f6675ef5fdcea100375f` |
| Retail | 12.1.5.70783 / `297d7aaaa736f346b3e036f38ee088eaf7f8c07f` |
| MoP | 5.5.4.70631 / `e5d9b3a22c3f0f6f41ebac0e454f4969594261cf` |
| Era | 1.15.9.70576 / `4192ac60067fc55566182291bc67c85dd9b6794d` |
| Anniversary | 2.5.6.70577 / `68e0a2ec559d9761dfc4e7f864c3944f9d758a49` |

Forever's [entry rendering](https://github.com/Gethe/wow-ui-source/blob/eac30af597e5aaa43a60f6675ef5fdcea100375f/Interface/AddOns/Blizzard_DamageMeter/DamageMeterEntry.lua#L535)
matches the warning line; [session methods](https://github.com/Gethe/wow-ui-source/blob/eac30af597e5aaa43a60f6675ef5fdcea100375f/Interface/AddOns/Blizzard_DamageMeter/DamageMeterSessionWindow.lua)
show native refresh and post-initialization boundaries. The
[Forever header source](https://github.com/Gethe/wow-ui-source/blob/eac30af597e5aaa43a60f6675ef5fdcea100375f/Interface/AddOns/Blizzard_RestrictedAddOnEnvironment/SecureGroupHeaders.lua#L66)
requires effective visibility before attribute-driven allocation. Source version
matches installed executable metadata but does not replace active `GetBuildInfo`.
Original Wrath and retained/unavailable targets are not newly certified. No
third-party addon code/assets were copied or edited.

## Pending native checks

After synced files arrive, reload. Record exact build, source, profile/addons,
hardware and resolution/UI scale. Keep previous diagnostic roots/preferences.

1. Forever and Retail without Details: open Meter, cycle one/two/three-pane
   layouts, resize/split, switch tabs, hide/show host, change native type/session,
   reset out of combat and reload with Meter active. Check icons, green local
   names, white other rows, pinned local entry, source rows, values, timer, menus,
   combat recovery, gamepad and errors. Verify Details takeover separately.
2. Each client: party/raid/solo, all eight raid groups, MT/MA assignment and
   roster growth during combat after out-of-combat setup; verify secure clicks,
   target mini-cells, unit reassignment, pet battle, UIParent hide/show and feature
   disable/re-enable. Preserve original/modern Wrath distinction.
3. Match screenshots/geometry and repeat baseline/candidate startup, steady-state
   and roster/resize bursts. Optional profiling must record overhead and be
   restored. If `UNKNOWN()` remains, capture the actual header name and taint
   provenance before attributing it to this module; do not suppress the warning.
