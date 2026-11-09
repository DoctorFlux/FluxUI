# Live Info Frame combat stats

8 November follow-up: [all-stat coverage](INFO_ALL_STATS.md) extends the display
path to spell/healing power and every other built-in key. This earlier record
retains its original narrower validation scope.

8 November 2026 — INFO-COMBAT-STATS-20261108. Requested targets: Retail and
Forever. The reported symptom was a pinned stat such as Crit showing 5% outside
combat and only 1% inside combat, while temporary combat gains must remain live.
The existing Forever restricted fallback selected melee regardless of which
category supplied the readable total. Retail could use supplemental CSC scans
whose partial result displaced the native total.

The user selected **Keep the same stat category live** when asked how to handle
restricted combined calculations. There is no new UI design or settings choice.
Remember only the winning category's identity (and Retail's spell-school index),
never its percentage. Query that source again for every update. Native readable
maxima are recomputed as soon as all channels recover. A different category
overtaking the selected category while values remain restricted is intentionally
not detected; a visible native Forever row can still supply its current total.

Retail Crit follows Blizzard's highest melee/ranged/minimum-spell-school chance.
Retail melee/ranged Crit and Haste read their native getters directly. These
providers bypass CSC's supplemental scans throughout combat and outside combat.
Existing labels, pins, saved data, fonts, order and layout rules remain. Forever
retains its existing shared Crit/Hit/Haste keys and alias migration.

Forever hit follows the selected mainhand/offhand/ranged/spell rating and
modifier pair. Ranged haste includes ammo haste. Addon Lua cannot add restricted
values: without a current native total, retain both live contributions as
`rating% + modifier%` or `ranged% + ammo%`. Public contributions are summed
normally. No known source, an unavailable selected API or an error displays `--`
instead of a lower category or an old percentage. No gear-only reconstruction,
native row setters, protected calls or secret arithmetic is introduced.

Both clients use the existing coalesced stat refresh and visible-only one-second
ticker. Retail now also subscribes on the existing event frame to combat entry,
combat exit and player spell-haste changes. No frame, timer, ticker, hook or
SavedVariables root was added. Native performance and allocation costs are not
measured by the desktop checks.

Source pins resolved on 8 November through the GitHub connector:

- Retail 12.1.5.70783: `297d7aaaa736f346b3e036f38ee088eaf7f8c07f`,
  [native calculation](https://github.com/Gethe/wow-ui-source/blob/297d7aaaa736f346b3e036f38ee088eaf7f8c07f/Interface/AddOns/Blizzard_UIPanels_Game/Mainline/PaperDollFrame.lua).
- Forever 1.60.1.70862: `9dc84f0d3bbae1768ac3405b3716000bd93eda06`,
  [native calculation](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_UIPanels_Game/Camelot/PaperDollFrameStats.lua).

The pinned PlayerScript and Unit declarations mark these stat getters
`SecretWhenUnitStatsRestricted`. FontString `SetFormattedText` explicitly allows
secret arguments from tainted callers and applies the Text secret aspect. These
are source contracts, not proof of operation in the installed native build.
Exact blobs and loading TOCs are retained in the [evidence record](validation/info-combat-stats-2026-11-08.json).

Desktop regression: `lua tests/info_combat_stats.lua` exercises real providers
and the existing text renderer for every selected category, 5→8→5 combat procs,
zero/negative haste, ammo, all four hit channels, partial CSC providers, mixed
public/opaque channels, API errors, unavailable initial sources and recovery.
The existing Forever smoke also checks merged lines and live redraw when layout
samples do not change. Full-suite results and exact hashes are in the evidence.

Native acceptance remains pending. Prior UIForever preference is retained; no
Witchcraft, UIForever automation or computer-use tool is connected this session.
When testing normally: reload outside combat, compare pinned Crit/Haste/Hit with
the native panel, enter combat with that panel closed, trigger and let a stat
proc expire, then exit combat. Repeat with the panel visible, ranged ammo haste,
spell/offhand hit and merged/integrated/minimap/vertical placements. Record actual
build, values, errors and taint; do not infer pixels, FPS or secure-VM safety from
opaque desktop tokens. WoW was left in the background with no input, settings,
profiler or diagnostic-root writes.
