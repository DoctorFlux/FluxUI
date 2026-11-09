# Cooldown viewer defaults

8 November 2026 active goal. Accepted appearance: four user screenshots of native
Tracked Bars, Tracked Buffs, Utility and Essential settings/previews. Preserve
custom Edit Mode layouts; use new defaults only for untouched layouts, per the
user's explicit choice. The user subsequently requested Modern/Classic themselves;
after the native-preset limitation was explained, explicitly accepted editable copies and tested them successfully, then requested
**one FluxUI profile for all four groups**. The latest request also requires
creating a new FluxUI profile whenever none exists, including after deletion or
rename. Existing FluxUI profiles and other custom layouts remain unchanged.
Built-in presets stay native.

| ID | Requirement | Status |
|---|---|---|
| CDV-01 | Keep Edit Mode ownership fixes and all native features | Implemented; user Forever save/viewer pass; other native checks pending |
| CDV-02 | Default above player and class-power row without overlap | Managed-copy anchors implemented; Forever current-player geometry PASS; resource/visual cases pending |
| CDV-03 | Match four screenshot settings | Forever four native saved setting groups match; matched rendered previews pending |
| CDV-04 | Preserve custom layouts and later native edits; avoid repeated default writes | One FluxUI character layout; existing names/custom selection retained; native save ends following; verified unchanged test copies retired with recovery data |
| CDV-05 | Gate unavailable clients/characters; no polling/private aura access | Retail/Forever capability gates; unavailable clients skip; no ticker/frame/OnUpdate/private-map reads |
| CDV-06 | Matched evidence and native/pixel comparison | 202 current focused checks; five baseline/candidate pairs; earlier four harmful controls; native creation pass; remaining native/pixel acceptance pending |
| CDV-07 | Create FluxUI when absent, including after deletion/native save | Forever creation and reload retain exactly one selected FluxUI; custom-save cases pending |

| Native group | Orientation / rows / direction | Icon size / padding | Other settings |
|---|---|---|---|
| Tracked Bars | Native bar layout | 90% / 0 | Width157%; opacity100%; Always Visible; Icon And Name; Hide When Inactive; timer/tooltips on |
| Tracked Buffs | Vertical / native limit / Up | 100% / 0 | Opacity100%; Always Visible; Hide When Inactive; timer/tooltips on |
| Utility Cooldowns | Vertical / 20 / Up | 100% / 2 | Opacity100%; Always Visible; timer/tooltips on |
| Essential Cooldowns | Vertical / 20 / Up | 100% / 2 | Opacity100%; Always Visible; timer/tooltips on |

Reference placement aligns tracked bars with the player main frame; tracked buff
icons, utility and essential columns sit consecutively to its left. All bottoms
clear the player/class-resource top. Preserve native artwork and existing player,
bar and badge geometry. These accepted images do not require a new mock-up.

Fresh pins are recorded in [Edit Mode evidence](EDIT_MODE_NATIVE.md).
C_EditMode.SaveLayouts fires synchronous EDIT_MODE_LAYOUTS_UPDATED; source/API
presence does not establish that an addon-triggered native refresh remains
untainted. Do not call native Lua setting/refresh methods, mutate preset globals,
replace private maps or bypass restrictions. Cooldown settings layout data stores
tracked spells/alerts separately from Edit Mode window appearance. Verify a safe
supported settings path before enabling automatic defaults. The user reported the two-copy build worked before requesting one profile.
The user ran the unchanged public-save probe on Forever1.60.1 build70862 interface16001 and reported
metadata PASS. This supports the engine round-trip; it is not a complete native
taint/combat/visual certificate.

## Implementation and preservation

`Other/FluxCooldownDefaults.lua` builds one FluxUI layout off detached native preset data, saves through `C_EditMode.SaveLayouts` only when FluxUI is missing, and activates the new FluxUI layout only if an untouched Modern/Classic preset or verified unchanged generated test copy was active. An active custom
layout stays selected. Unknown settings, other systems, built-in presets and
existing custom layouts retain their source data. Existing Flux-named profiles
are reserved for their current owner. The native character-layout limit is
respected; insufficient space prevents the whole batch, with no partial save.

`UnitFrames/FluxClassPower.lua` supplies public out-of-combat geometry in UIParent
units. Tracked bars align with the player main frame; native 40/30/50-unit buff,
utility and essential icon columns sit to its left with 4-unit gaps. Bottoms sit
4 units above the visible player/class-resource top. Secret/unavailable geometry
defers rather than guessing. Saved widget anchor methods avoid native Edit Mode
snapping/dirty-state overrides; no native setting/refresh/visibility/aura handler
is called from Flux. Native cooldowns, tracking, alerts and tooltips stay native.

Shared events/timer/combat/Edit Mode services coalesce readiness/scale/spec/form
changes. There is no new event frame, ticker, OnUpdate or aura/power polling.
Steady geometry causes no point writes. Saving through native Edit Mode releases
only the generated FluxUI layout to the user. An existing FluxUI profile keeps
its settings, including after customization. If FluxUI is absent, the addon
creates one profile after readiness/combat/editor checks, regardless of an older
applied/customized marker. Deletion/native-save events request the existing
coalesced job. Renamed layouts remain intact; the missing FluxUI name is recreated.
Existing custom selection stays selected. Legacy retirement runs only on first
creation, and recreation preserves earlier recovery records. No failed native
write is retried automatically.
Earlier generated copies are retired only when their recorded ownership and
exact native exported data match the original preset/settings/geometry. Edited
or unverifiable copies stay intact. At most three retired test profiles remain
recoverable in _FluxUI_CharSavedVars.cooldownDefaults.retiredLayouts. Native state
versions 1/2 migrate to 3; failures and other settings are preserved.

Optional `/fluxcooldowns` reports readiness/state; `/fluxcooldowns test` performs
at most one unchanged public save per reload and records bounded metadata in the
existing character root. No profiler or native enable preference is changed.

## Evidence and remaining checks

Current presence-policy validation:202 focused checks and five alternating
baseline/candidate pairs PASS. The old owner fails the delete/recreate regression;
the candidate creates once, handles a previous native-save marker, preserves
existing custom profiles and recovery data, and does not duplicate on20 events.
Current full checkout:261 scripts/928 Lua PASS; the complete normalized
[source manifest matches](validation/cooldown-final-current-source-guard-2026-11-08.json).
Newer FluxInfoFrame/refactor work is preserved. This refresh supersedes the
earlier source/verification drift. [Full current results](validation/cooldown-final-current-full-2026-11-08.json).
The [requirement-by-requirement audit](validation/cooldown-final-audit-2026-11-08.json)
records current native settings/geometry/persistence passes and keeps custom-edit,
class-resource, visual and other-client gaps open;
the full goal is not complete. No runtime code was changed in this refresh.

- [Presence-policy raw runs/checkpoint/source identities](validation/cooldown-presence-comparison-2026-11-08.json).
- [Presence-batch full suite](validation/cooldown-presence-full-2026-11-08.json), [source guard](validation/cooldown-presence-source-guard-2026-11-08.json) and [installed source copies](validation/cooldown-presence-client-copy-2026-11-08.json).
- [Native presence check](validation/cooldown-presence-native-2026-11-08.json): Forever70862 created/selected one FluxUI after guarded reload; BugTabs0; tracker remains unclamped at top. Subsequent guarded reload PASS: exactly one selected FluxUI; BugTabs0. See the current native evidence below.
- [Original default-generation evidence](validation/cooldown-defaults-comparison-2026-11-08.json): five186-check scenarios and four rejected harmful controls. Desktop lifecycle/resource results do not establish native performance.
- [Native preset construction](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_EditMode/Shared/EditModePresetLayoutsManager.lua) and [native refresh](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_EditMode/Shared/EditModeManager.lua): presets are rebuilt from Blizzard data; modifying global preset tables is outside the safe implementation.

[Current native acceptance](validation/cooldown-native-acceptance-2026-11-09.json):
Forever70862 reload persistence, four saved setting groups and current player-bound
offsets PASS; BugTabs0 and four aura-map metadata fields secure. The initial
private settings probe used synthetic ID13; it was discarded and corrected to
the observed native enum20. Runtime code already uses the native enum.

Remaining native acceptance: matched rendered previews, class-resource geometry,
and a native custom edit/save/reload to confirm customization persists. Test deletion/recreation only with a saved
recovery copy; desktop tests cover this destructive fixture in isolation.
Check ordinary casts, auras, alerts, tooltips, class/form/resource changes and
existing action bars/badges. Compare matched screenshots and actual timings;
repeat Retail and capability-unavailable Classic cases separately. Keep the game
in the background for automated read-only inspection. Native CPU/memory/latency,
hardware/addon-list-matched A/B runs, all-client taint and pixel parity remain
unmeasured; the current work makes no FPS or lag-elimination claim.

The [remaining native acceptance blocker](validation/cooldown-native-blocker-2026-11-09.json)
is a stable background test opportunity. The latest35second wait ended without
input. Native Edit Mode has its own slash entry and Escape handler; use those
normal paths after verifying the runtime alias, preserving unsaved edits. Do not
substitute insecure direct calls to the manager's internal Lua methods.
