# Equipped trinket tint correction — 31 October 2026

## 13 November follow-up: intermittent dark faces and cooldown overlays

Task `TRINKET-DARKENING-20261113` restores the accepted appearance directly;
the existing direct-implementation and user-native-reproduction choices apply.
There are no new controls, strings, settings or interaction designs.

The integrated production-owner/painter/cooldown-cache fixture reproduces three
stale-state paths: release restores a pre-press dark tint after usability has
become ready; removing and re-equipping the same item leaves an empty-slot tint
behind a cached white palette; slot cooldown refreshes and item-ID cooldown
refreshes can disagree or bypass each other's timer cache.

- `TD-01`: held presses keep the original shade and 0.62 factor while following
  the painter's newest public usability/range color; release restores that color.
- `TD-02`: changing equipped item identity, including empty slots, clears the
  old press and uses the existing paint-cache invalidation service. Re-equipping
  the same ready on-use item restores full color. Passive trinkets stay dim.
- `TD-03`: equipped managed faces use the inventory slot's cooldown through the
  same shared painter/cache on every refresh. Real use/shared/swap cooldowns stay
  visible; ready slots clear old swipes. Ordinary items keep item-ID cooldowns.
- `TD-04`: legacy cooldown widgets retain their direct fallback, recognize
  `WCooldown`, and clear disabled timers even without the global helper.

The secure `/use 13|14` actions, flyout, swap queue, bindings, layout, assets,
saved roots and update cadence remain owned by their existing services. The
change adds no frame, event, timer, hook or polling loop. Controller assessment:
tint and swipe are decorative and add no focus or input target; existing
activation/flyout routes remain. Actual gamepad reachability and native focus,
paired press/release and combat operation remain untested.

The external pre-edit source ZIP (2,627 actual files), complete Git bundle and
seven Retail settings metadata entries were verified before runtime edits.
Private values are outside AddOns; the client/profiler/settings were not changed.
Exact checkpoint/candidate source hashes are in
[evidence](validation/trinket-darkening-2026-11-13.json), with the recovery identity
in [checkpoint](validation/trinket-darkening-checkpoint-2026-11-13.json).

The focused integrated fixture passes 245 checks across five desktop client
models. Exact checkpoint sources fail 55 assertions; five separate regressions
are rejected. Existing 10-check usability and 1,563-check press fixtures pass.
The wider run passes 321 scripts and 1,003 syntax files; its later focused test
refresh is recorded explicitly in the report. These are desktop behavior checks,
not native rendering, taint, secure input, FPS or memory measurements.

Fresh Gethe source pins: Retail `297d7aaaa736f346b3e036f38ee088eaf7f8c07f`
(12.1.5.70783), Forever `bebcb6bf309cf41b41bd74f8ca651e6a105b2676`
(1.60.1.70938), Classic progression `e5d9b3a22c3f0f6f41ebac0e454f4969594261cf`
(5.5.4.70631). The native PaperDoll path uses `GetInventoryItemCooldown` and
the FrameXML cooldown helper clears disabled/zero timers. Loaded TOC paths,
public color contracts and upstream blob identities appear in the
[15 source records](validation/trinket-darkening-sources-2026-11-13.json).
Existing Era/Anniversary compatibility is retained; no fresh source certification
or native acceptance is claimed for those clients.

Native acceptance is **NOT RUN**: no connected client execution tool is available.
After `/reload`, verify both equipped slots while ready and during an actual use,
shared or equipment-swap cooldown. Check usability changing while a key/mouse
press is held, mouse/wheel release and hidden-menu cleanup, passive/empty faces,
removal/re-equipping the same item, bag flyout, combat queue and controller input.
Keep WoW in the background; input reproduction belongs to the user. No new native
build, pixels, persistence, combat/taint, FPS or long-session memory result exists.

## 1 November follow-up: passive trinkets

The user clarified that equipped trinkets without an on-use effect should be
dim. The first correction also brightened passive trinkets, which was not the
intended rule. The equipped-face path now requires a readable item-use spell;
without one it paints inactive, even if `IsUsableItem` returns true. Ready
on-use trinkets remain bright, and a genuinely unusable use spell stays dark.
The revised loaded-paint fixture passes 10 checks and rejects the published
baseline at the passive trinket. The isolated published-source suite passes
112 tests/757 Lua syntax files in
`validation/trinket-passive-2026-11-01.json`. Baseline main was
`db5c3288047bdedf9080f71e18cb6ae6a3c485d1`; Paint baseline SHA-256 was
`e4993da8bed4033673aad9bb600a1a73f5965bfe3f068b3b933053b178782079`
and candidate SHA-256 is
`d6e089f508c97bba4c15fe53c3b1acc317085d7ade3d46d7828ebb54c87bab90`.
A verified complete Git bundle, source copy and closed Retail `Config.wtf`
are outside AddOns at
`C:\Users\mario\.codex\visualizations\2026\10\31\01a191bd-d58d-74a3-bbdf-1b69e0cce168\FluxUI-trinket-passive-20261101`;
bundle SHA-256 is
`90708215a2f172be38ba290bd20629e12d00975c84e779e3d2f4abb3382404e8`.
Native pixels, clicks, taint and frame time remain pending.

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
