# Info Frame: all combat stats

8 November 2026 — INFO-ALL-STATS-20261108. The user expanded the earlier
Crit/Haste/Hit fix to every pinned stat, specifically including spell power.
Keep the earlier choice to follow the same stat category while comparisons are
restricted. Targets remain Retail and Forever; preserve Classic providers.

The display path now routes the other native stat providers through
[FluxInfoFrameStats.lua](../StatusBars/FluxInfoFrameStats.lua) before supplemental
CSC formatting or old character-panel snapshots. It reuses the existing
FontStrings, native formatted-text renderer, layout samples, visible one-second
ticker and coalesced refresh. No frame, timer, ticker, hook or saved setting was
added. The existing event frame adds ten player-unit stat registrations and
three secondary-stat registrations. Player filtering and visible/dynamic-pin
gates keep unrelated unit events from scheduling work. Additional weapon and
spell-only pins now qualify for the existing aura refresh.

Every one of the 42 built-in keys has an explicit audit disposition in the
[coverage ledger](INFO_STAT_COVERAGE.csv). Existing Crit/Haste/shared Hit retain
their previous live paths. The remaining 35 keys cover live native providers
and the unchanged public item-level/GearScore providers. Dynamic unknown rows
have a separate current-visible-player-row policy.

Spell damage follows the highest fully readable school and remembers only that
school's identity/color for later live restricted reads. Healing always queries
its current getter. Combined damage/healing respects the saved display mode,
supports compact merged lines and keeps an available component when the other
read fails. Hidden rows and `_camelotSpellSnapshot` no longer supply these live
numbers. Missing getters/read failures show unavailable, never fabricated zero
or a cached plausible total. Genuine zero remains valid.

Versatility now includes rating plus its native bonus. Leech and avoidance use
their native totals instead of rating-only bonuses. Attack-power totals now add
the already-signed negative modifier; the previous subtraction inflated a
penalty. Native spell-power-to-AP conversion follows its selected minimum school
or healing source and current conversion factor. Armor uses effective armor;
primary stats use effective values; health/power use maxima as before. Weapon
damage/speed retain mainhand/offhand/ranged readings and current units.

This implementation does not make every arbitrary stat available as an exact
single number during every restricted context:

- Addon Lua cannot add/multiply these restricted numbers. Current visible native
  rows can supply their combined totals; otherwise AP, versatility, defense and
  hit show all live signed contributions. MP5 shows the current casting rate
  multiplied by five; AP conversion shows both factors. Restricted movement
  speed shows the actual live yards/second value; public speed keeps percent.
- The verified `LuaCurveObject:Evaluate` declaration accepts secret arguments
  only when untainted. No curve arithmetic workaround, native setter, private
  row construction or protected execution route is introduced.
- A different restricted school/category overtaking the previously selected
  one is not detected until the set becomes readable. No known source at first
  restricted read yields unavailable rather than an arbitrary lower category.
- Unknown custom pins without an exposed independent getter require a currently
  visible native player row. Hidden rows, pet rows and saved numeric/text caches
  cannot establish a live value. Some native stat APIs do not exist on every
  client; unsupported stats stay unavailable.

Thus built-in source/display implementation is complete at the audited scope;
exact restricted combined totals and hidden row-only custom stats remain
capability limits. Native acceptance remains OPEN. These limits must not be
reported as universal full combat support or solved by snapshot reconstruction.

Both current branch heads were resolved on 8 November: Retail
`297d7aaaa736f346b3e036f38ee088eaf7f8c07f` (12.1.5.70783) and Forever
`9dc84f0d3bbae1768ac3405b3716000bd93eda06` (1.60.1.70862). PlayerScript/Unit
contracts, native PaperDoll calculations, curve restrictions and the FontString
secret-text sink were retained at exact blobs in the
[evidence record](validation/info-all-stats-2026-11-08.json). Installed runtime
build/caller permissions are not inferred from mirror declarations.

Validation uses the real providers, `_GetKeyText`, native-renderer argument
separation and unchanged-layout update return. `lua tests/info_all_stats.lua`
passes 645 checks, including all built-in classifications, combat gains/expiry,
stale snapshots, API failures, signed AP, conversions, compact spell/heal merging,
visible/hidden/pet/custom rows, no provider frame creation, player event routing,
100-to-one refresh coalescing and Classic exclusion. The prior 234-check combat
regression and existing Forever/layout smoke remain applicable. Five matched
baseline/candidate pairs and four deliberately faulty variants are retained.
These are desktop correctness/resource counters, not native CPU/FPS results.

Native test next: reload outside combat, pin Spell damage/healing and the
affected stats, then close the native panel and enter combat. Trigger and let
procs expire; verify each field updates through unchanged layouts. Check ranged
and offhand gear, penalties, mana regeneration, movement, public/opaque transitions
and combined compact placements. Compare native totals when the panel is visible;
test hidden custom rows as explicitly unavailable. Capture actual build/errors/
taint and matched performance separately. Prior UIForever preference is retained;
no connected Witchcraft/UIForever/computer-use tool was available for this work.
No game input, live settings, profiler or diagnostic roots were changed.
