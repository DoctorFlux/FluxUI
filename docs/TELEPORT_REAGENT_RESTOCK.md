# Class travel and spell-reagent preset restock

The user requested reagent detection/restocking on Forever and right-click
editing when the class travel button has no flyout. They clarified that spell
reagents, including these runes, belong in **Preset restock**, not Manual.

- One visible destination: left-click still casts. Right-click edits its required
  rune/item target using the existing reagent-row editor. Enter saves, Escape
  cancels, and zero disables purchasing without removing the preset row.
- Multiple visible destinations: right-click keeps the existing flyout and its
  reagent rows. Modifier favorites, middle-click mode changes and cast locks stay.
- Teleport and portal targets are independent. A matching rune takes priority
  when a spell has multiple costs; other required items retain their existing
  restock-list controls. Free travel gains no reagent editor.
- Soul Shards are excluded from automatic spell-reagent restock. A non-shard
  reagent is not treated as a Soul Shard merely because a summoning spell uses it.

The existing spell-reagent index already routes known reagents to Preset.
Cold rune names previously failed resolution and fell through to Manual;
uncached Soul Shards could slip through the name-only exclusion. A summoning
spell-name heuristic could also blacklist a different required item. Explicit
rune names now resolve before item data loads; Soul Shard identity is checked
by item ID. Costs still come from actual spell reagent evidence, not a table
assigning costs to spell IDs. Unreadable text does not imply a cost.

Targets keep the existing shared persistence. Detection changes classification;
saved amounts, bank flags and ordinary Manual items remain intact. No settings
reset, separate target store or destructive migration is introduced. Generic
class spell reagents use the same existing index and Preset routing. Native
spellbook flyout children were previously skipped; the index now includes only
known children, selects active overrides and deduplicates spells. The existing
Core.Spell adapter supports modern C_Flyout tables as well as legacy APIs.
Unknown children and a replaced base spell do not add inferred reagent costs.

The travel button reuses that index and a rune-tooltip fallback for cold data.
The existing spell-ready notification updates right-click availability; bag-only
pulses keep their count path. Protected click attributes update outside combat.
The shared editor restores the travel button's native count display and is
reused across modes. No new polling or recurring timer is added.

External checkpoints `Teleport-reagent-20261106T234644Z` and
`Teleport-preset-20261107T000909Z`, followed by
`Teleport-flyout-index-20261107T002634Z`, preserve actual source, all-ref history
and 179 accessible on-disk settings each. Source counts were 1,691, 1,697 and 1,700;
unsaved game memory is excluded. Archives are outside AddOns.

Validation: 130 travel checks plus 47 actual scanner/list/persistence checks;
16 faulty mutations rejected. Saved baselines fail the new requirements,
including the modern flyout adapter-only negative control. Existing cast-lock,
consumable editor and action-bar regressions pass.
Scoped replay passes all six required scripts with unchanged reagent sources.
The last whole-addon run passed 200 of 204 scripts and all 866 syntax files;
four raid-test failures and unrelated source drift prevent a whole-tree PASS.
All four runtime files match the four existing client copies (16 hashes). A
manual-copy verification stopped during active continuous sync; three later
read passes confirmed every candidate, with external destination backups.
Documentation validation also remains blocked by concurrent raid edits: one stale source-inventory entry and three verification hashes. The checker made no edits; reagent source/test hashes remain matched.

Five alternating matched pairs cover five travel capability models and two
scanner/list API shapes. In the warmed spell-cache scenario, 1,000 tooltip
scans become zero, with the same 1,000 reagent results and no steady-state frame
growth. That fixture avoids one unused scanner frame. List snapshots retain
all five saved targets while moving detected reagents to Preset and removing
the erroneous automatic Soul Shard row. Host intervals are recorded with raw
samples; they do not certify native CPU, memory, latency, rendering or FPS.

The background baseline transport completed, but its capture showed auction
and crafting panels with no visible FX marker. Native execution is inconclusive;
no further input was sent into that busy UI. Native candidate editing, secure
click phases, appearance and vendor purchasing remain pending on all clients.

- [Exact sources, regression cases and raw samples](validation/teleport-reagent-comparison-2026-11-07.json)
- [Whole-tree validation and manifest](validation/teleport-reagent-safety-2026-11-07.json)
- [Verified client synchronization](validation/teleport-reagent-client-copy-2026-11-07.json)

After closing commerce/crafting windows and leaving combat, reload. On a
character with a reagent-using travel spell, check that its rune appears once
under Preset restock with the previous quantity and bank flags. With one visible
destination, right-click, save a chosen amount, cancel another edit, and set zero;
confirm the row stays in Preset. Check both travel modes, modifier favorites and
a multi-destination flyout. Reagent-free travel and Soul Shards must not gain an
automatic reagent target. Inspect new-session errors and compare the existing
count, icon and cast behavior. Test vendor purchasing manually with the intended
automation settings; this change performs no test purchases.
