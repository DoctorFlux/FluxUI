# Equipped trinket tint correction — 31 October 2026

The user observed that equipped trinkets with a use effect stayed dark while
alive and off cooldown after the combat grid tint update. This is a separate
shared-paint path: the trinket menu presents `/use 13` and `/use 14` as managed
item faces, but the generic item-usability fallback only recognizes bag
ownership. An equipped trinket is outside that bag snapshot, so a false
`IsUsableItem` result can leave a ready trinket dark.

The painter now recognizes a trinket menu face that has both its inventory
slot and managed equipped item ID. For that face, it uses the existing
owned-item fallback. A genuinely unusable use spell remains dark, and an
ordinary unowned item macro still follows its original rule. The combat grid
mana gem and healthstone retain their death, empty-charge and live-item tint.
No trinket secure action, slot visibility, count, cooldown, keybind, saved
data or recurring driver changed.

## Source and validation

Baseline main commit: `3940fc41efdfed800277fcd4da0f6c02e698df5d`.
Baseline `ExtraButtonSystem/Engine/Paint.lua` SHA-256:
`a354bfe241eaa3259bb8d661e18f8df4c49e1f4cef4e9a5db8010e440606f4f1`.
Candidate SHA-256:
`e4993da8bed4033673aad9bb600a1a73f5965bfe3f068b3b933053b178782079`.
The unchanged trinket owner `ExtraButtonSystem/TrinketMenu/FluxTrinketMenu.lua`
SHA-256 is `3ab177e4885568df30d2a1a813e4412194e73af4344ba42be29468e53e21d355`.
A verified complete Git bundle, pre-edit source copies and three closed-client
`Config.wtf` copies are outside AddOns at
`C:\Users\mario\.codex\visualizations\2026\10\31\01a191bd-d58d-74a3-bbdf-1b69e0cce168\FluxUI-trinket-usability-20261031`.
Bundle SHA-256:
`a8de46aecb783ba89ae399145655bcc5b280f23b9b09781022f32742ddacf94e`.
On-disk Retail saved variables were inspected read-only; WoW was closed.

`tests/trinket_equipped_usability.lua` executes the loaded painter for a
ready equipped trinkets in both slots, a passive trinket, a genuinely
unusable use spell, recovery, an ordinary unowned macro and combat gem
controls. It fails against the baseline at the ready trinket and passes 8
candidate checks. The prior 14-check combat gem
and healthstone fixture and existing trinket press fixture also pass. The
isolated published-source desktop report passes 112 tests and 757 Lua syntax
files with zero failures in `validation/trinket-equipped-usability-2026-10-31.json`.

Native acceptance remains pending. On each supported client, check equipped
on-use and passive trinkets while alive and ready, on cooldown, dead and
revived. Confirm bag flyout color, secure `/use` clicks, keybinds, cooldown
swipes, swap queue, gem/stone tint, pixels and combat taint. Desktop fixtures
do not certify native rendering, secure input, taint safety or FPS; collect
matched native frame-time samples before a performance claim.
