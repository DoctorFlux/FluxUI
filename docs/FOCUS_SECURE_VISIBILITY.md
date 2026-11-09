# Focus visibility and native menu routing

9 November 2026 · FOCUS-SECURE-VISIBILITY-20261109.

The reported empty focus frame still intercepted the world behind it on Forever.
Its compatibility path faded the frame while protected mouse children remained
shown. Disabling focus watchers could also leave a later native watch update able
to show them again. Separately, the addon-written `menu-function` attribute path
produced forbidden `FocusUnit()` calls from Blizzard's menu responders. The user
confirmed the first target-only correction worked for target, but player and
other callback menus still failed at 00:53:20.

## Ownership and behavior

The existing Restricted service now registers native visibility conditions for
focus and focus-target. Blizzard owns the complete protected frame's Show/Hide,
including its mouse children, during combat. Focus-target also requires an
existing, living focus. Re-enabling retains prepared clicks; disabling unregisters
the watch and prevents reconciliation from resurrecting it. No global APIs,
native scripts or secure restrictions are replaced. No new polling, event frame,
ticker, cache, binding, gesture or saved option is introduced.

Ordinary player, target, focus, pet, party and raid menus use Blizzard's
addon-supported `togglemenu` action. Existing menu enable/disable settings,
modified click precedence and deferred combat configuration remain. The menu
callback attribute is retained for integrations and dependent mini-frame menus.
No runtime addon Lua calls `FocusUnit` or `ClearFocus` for this correction.

The native generic menu has no arbitrary-NPC category for a dependent unit that
is neither the player's target nor a roster player/pet. Consequently,
target-of-target, focus-target and similar mini-frame menus retain their compact
callback. Their callback-based Set Focus entry can remain restricted. The user
explicitly chose **keep those menus; use native focus bindings/macros**, rather
than adding configurable secure click gestures. This is an accepted limitation,
not a claim that every callback focus entry is repaired.

Existing native keys and hardware-entered macros remain available where the
client supports focus. Examples:

```text
/focus target
/focus [@mouseover,exists]mouseover
/focus [@focustarget,exists]focustarget
/clearfocus
```

These examples do not change any existing binding. `/run FocusUnit(...)` is not
an equivalent secure macro action. Focus capability gates remain unchanged;
unsupported clients are not given an emulated focus system. Old Forever builds
where both restricted-handler probes fail retain the legacy fallback and are
not certified fixed by this batch.

## Source and recovery identity

Work stays on main at `1fd463f4de4bbff659f4e402c6f31138c49765b4`, preserving the
pre-existing dirty/untracked work. The external 20261108T232048Z checkpoint
contains 2,329 actual source files, 188 accessible on-disk settings files and an
all-ref history bundle. ZIP integrity and bundle verification passed. Unsaved
game memory is excluded; settings were not edited. Archive hashes, exact three
baseline/candidate owner hashes and raw samples are in the
[comparison](validation/focus-secure-visibility-comparison-2026-11-09.json).
Candidate identity additionally includes the complete normalized 930-file Lua
manifest in the [full report](validation/focus-secure-visibility-full-2026-11-09.json).
The [source guard](validation/focus-secure-visibility-source-guard-2026-11-09.json)
checks that the tested corpus still matches.

Twenty primary source blobs cover the native state manager, secure actions, menu
focus responders and secure slash handlers across five client branches. Every
executed body matches its pin. The read-only local Forever popup reference has an
older `ClearFocus(contextData.unit)` call; its test replay explicitly adjusts to
the pinned no-argument call. Whole-file differences are retained in the
[reference ledger](validation/focus-native-references-2026-11-09.json).
No additional reference code or assets were added to addon runtime files.

| Client | Installed executable version / build | Primary source pin | Native status for this batch |
| --- | --- | --- | --- |
| Retail | 12.1.5 / 70783 | [297d7aaaa736](https://github.com/Gethe/wow-ui-source/tree/297d7aaaa736f346b3e036f38ee088eaf7f8c07f) | Pending |
| Forever | 1.60.1 / 70862 | [9dc84f0d3bba](https://github.com/Gethe/wow-ui-source/tree/9dc84f0d3bbae1768ac3405b3716000bd93eda06) | Background reload/state/macros pass; player menu/combat macros pass by user report |
| Classic progression | 5.5.4 / 70631 | [e5d9b3a22c3f](https://github.com/Gethe/wow-ui-source/tree/e5d9b3a22c3f0f6f41ebac0e454f4969594261cf) | Pending |
| Classic Era | 1.15.9 / 70576 | [4192ac60067f](https://github.com/Gethe/wow-ui-source/tree/4192ac60067fc55566182291bc67c85dd9b6794d) | Pending; existing focus capability gate retained |
| Anniversary | 2.5.6 / 70577 | [68e0a2ec559d](https://github.com/Gethe/wow-ui-source/tree/68e0a2ec559d9761dfc4e7f864c3944f9d758a49) | Pending; existing focus capability gate retained |

Original Wrath is not installed/tested. Executable versions do not establish
native runtime acceptance on the four untested clients. All 15 installed copies
of the three changed runtime owners match through the user's continuous sync;
this task only read those other installations.

## Verification and before/after evidence

- `lua tests/focus_secure_visibility.lua`: 70 checks, five pinned native manager
  replays. Baseline observes 18 failures in 60 checks; candidate has zero. Three
  individually restored old-owner controls reject. Includes combat clear/set,
  stale/dead dependent unit, 20 repeated transitions, disabled ownership and 20
  stable re-enable requests.
- `lua tests/focus_native_menus.lua`: 670 checks across five clients. Five
  alternating baseline/candidate pairs after one excluded warm-up pair reject
  the old callback route and pass the native route. Native C execution, hardware
  context, macro conditional parser and taint rules remain modeled.
- `lua tests/unit_combat_menus.lua`: 620 checks preserving menu options,
  modified-click priority, native click casting and deferred setup.
- Full current validation: 263 scripts pass, 930 Lua files parse; no source drift.
  These are desktop correctness checks, not native security or FPS certificates.

The replay adds no frame relative to its baseline: five modeled frames per
ordinary contract and six for Forever, including existing probes. Four driver
registrations cover the two initial frames and later re-enable; 20 stable
requests add no registrations. This is a resource-count result, not a CPU or FPS
improvement. Raw sample wall times are uncontrolled desktop harness durations.
Native CPU, allocations, operation latency, frame times, matched hardware/addon
list and pixel differences were not measured; native performance is inconclusive.

On Forever 1.60.1/70862/interface 16001 a guarded background reload loaded the
new code. Focus and focus-target report native visibility ownership and real
hidden roots with invisible mouse children when empty. Player/target/focus/pet
all report native menu action attributes. A preflight verified out of combat and
no existing focus. Native `/focus [@focus,noexists] player` showed the focus and
interactive child; `/clearfocus` restored the empty, hidden state. BugTabs stayed
at zero. Exact window/executable and unchanged non-game foreground were checked
throughout. No casting, targeting, attacking, physical keyboard/mouse/clipboard
control or profiler changes occurred. Private screenshot hashes and transcribed
lines are in the [native report](validation/focus-secure-visibility-native-2026-11-09.json).

The user subsequently confirmed **player Set Focus menu and normal focus/clear
macros during combat both work without errors**. This is user acceptance, not an
automated combat trace. Target menu success was reported earlier. Physical
party/raid/pet menus, click-through behind empty focus during combat, matched
appearance and other native clients remain separate acceptance checks.

## Remaining native regression steps

1. On a focus-capable client, reload outside combat. With no focus, verify the
   world/UI behind both focus regions receives pointer input.
2. Use each ordinary frame menu to set/clear focus, including player, pet, party
   and raid where available. Check BugTabs for new errors. Keep menu opt-outs,
   native click casting and modified Flux hover bindings working.
3. During normal combat use existing `/focus` and `/clearfocus` hardware macros.
   Check real frame disappearance, returning interaction, dependent targets,
   death, and clearing focus. Do not substitute addon Lua protected API calls.
4. Outside combat toggle focus and focus-target features off/on and reload.
   Disabled roots must not reappear; enabled appearance and saved settings stay.
5. Preserve dependent mini-frame menus. Use native bindings/macros to focus
   those units; their restricted callback entry is the documented exception.
6. Repeat on other installed clients with native focus support; unsupported
   cases stay gated. Capture matched screenshots and optional matched performance
   samples separately before claiming pixel or performance acceptance.
