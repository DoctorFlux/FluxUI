# Combat grid conjured-item usability — 31 October 2026

The user observed that the mana gem and healthstone faces stayed bright while
the other combat grid items darkened when the character died. They also asked
that the same usability tint work in other unusable states.

## Cause and correction

The mana gem path forced `usable = true` for its item and castsequence faces.
The healthstone path used the shared item check, which changes a false item
result back to true whenever an owned stack is in the inventory snapshot.
That fallback protects loading screens, but it can mask a real unusable result
after bags settle. A ready item-use spell charge could then override false.

The two combat faces now use the live item usability result once the bag
snapshot is reliable. Death or ghost state wins even when the native item API
reports an owned item as usable. The existing life events repaint the tint on
death and revival. Empty-use/charge handling and the unreliable-bag hold remain.
No slot visibility, secure action, binding, count, saved variable or cadence
changed. The shared item path for other buttons is untouched.

## Source and validation

Baseline main: `9543cd79e6f8cc0513540a29051d286573fc4ea7`.
Baseline `ExtraButtonSystem/Engine/Paint.lua` SHA-256:
`8f473fcdd408d02e3b919f6847c51df407691f25aee48639580e996bb2861f63`.
Candidate SHA-256:
`a354bfe241eaa3259bb8d661e18f8df4c49e1f4cef4e9a5db8010e440606f4f1`.
A verified complete Git bundle and pre-edit Paint copy are outside AddOns at
`C:\Users\mario\.codex\visualizations\2026\10\31\01a191bd-d58d-74a3-bbdf-1b69e0cce168\FluxUI-combat-usability-20261031`.
Bundle SHA-256:
`22f2228dd9985961e0ab9986c0aa6cb54615914e1f77b275627782a924049cea`.
The on-disk Retail saved-variable file was inspected read-only. WoW was closed;
no settings or profiler preference was changed.

`tests/combat_grid_conjured_usability.lua` executes the loaded paint function
against usable, dead, ghost, revived, situationally unusable, empty,
castsequence and unreliable-bag scenarios. It fails against the baseline at
the dead gem and passes 14 candidate checks. The existing bar source contract
was updated to require live item and life-state handling. Full desktop
validation passes 111 tests and 756 Lua syntax files with zero failures in
`validation/combat-grid-conjured-usability-2026-10-31.json`.

Native acceptance remains pending. Sequentially on each supported client,
check gem and healthstone tint beside potion/bandage while alive, dead, ghost,
revived, full health/mana, on cooldown, at zero and replenished charges, and
during a zone-load bag hold. Confirm counts, secure clicks, hotkeys, tooltip,
visibility, pixel match and combat taint. Desktop checks do not establish
native pixels, secure input, taint safety or FPS; collect matched native
frame-time samples before a performance claim.
