# Inventory summary retention — 5 November 2026

The built-in inventory tooltip cache retained every historical bag-only item.
A partial bag rebuild cleared each cached row's bag count and repopulated current
bags, but never removed rows whose counts were now all zero. Replacing one item
repeatedly therefore grew both saved derived data and later summary traversals.
This reproduces a retention/performance defect; it does not prove the cause of
the user's native mailbox or auction freezes.

## Correction and preserved behavior

After repopulating bags, a partial character rebuild removes only rows whose
fields are all zero. Nonzero bank, mail, equipped, void and auction facts remain.
Unknown nonzero fields are retained conservatively. Pruning happens after the
current bags are restored so live rows keep their identity during count changes.
Full character rebuilds, guild/warband generation and provider callbacks retain
their existing paths. No guild-bank or void-storage callbacks were edited.

The only repository consumer is Inventory/Tooltip.lua. It already omits character
lines with no positive location counts. Queries for a pruned item return the
normal empty characters/guilds collections and warband zero; they no longer
report a false historical zero-count character owner. The public result keys,
real ownership counts, filtering, settings and rendered lines remain unchanged.
Source character records and inventories are not deleted or reset. This change
adds no event, timer, hook, frame or recurring idle work.

## Reproduction and resource measurements

Baseline main is `b664bb0b93ac566a34744aec5895e927a7a1ffff`.
Its Summaries.lua SHA256 is
`d9746bc366548f8f1ff7e95d4419aec39b471dd69973695cdd7a700520c8e217`.
Before runtime edits, external checkpoint Builtin-inventory-20261105T152153Z
preserved 1,488 actual files, 75 available on-disk settings and verified history.
ZIP integrity passed. Source archive SHA256:
`c2a7f2c073d38a90133cff6e5fc494164430338149ef65343ca61ab507ca537a`.
Private settings and archives remain outside AddOns/Git; unsaved game memory is
not included.

The regression loads the real Store and Summaries modules with isolated saved
data and native identity methods. Starting with an empty character summary,
2,000 distinct replacements of one carried slot each trigger the existing pending
summary flush through a tooltip query. Actual production summary-row iterations
are counted separately from fixture/assertion work.

| Metric | Baseline | Candidate |
| --- | --- | --- |
| Retained character summary rows | 2,000 | 1 |
| All-zero retained rows | 1,999 | 0 |
| Cached summary-row visits | 1,999,000 | 5,998 |
| Regression checks | 81, with 30 failures | 81 pass |

These are desktop table/iteration counts, not measured native memory bytes, CPU,
frame time or operation latency. Pruning adds a pass over current summary rows;
its cost remains proportional to represented ownership rather than historical
bag contents. Existing stale cache entries are cleaned when that character next
receives a partial bag summary rebuild. Unvisited offline characters are not
eagerly rewritten.

Controls cover count-only row reuse, the last carried item, each nonbag character
location, shared items, full rebuilds, offline characters, guild/warband data,
connected-realm/faction/visibility settings, missing keys and an external
Syndicator handoff. The labels do not emulate native clients or providers.

```powershell
lua tests/inventory_summary_pruning.lua
lua tests/inventory_summary_pruning.lua '<external-checkpoint>/summary-baseline.lua'
```

Five alternating pairs and three summary mutants are recorded in the shared
comparison. Final whole-addon validation passes143 scripts/798 Lua syntax files.


[Five matched pairs per change, raw samples, candidate hashes and12 rejected mutants](validation/builtin-inventory-comparison-2026-11-05.json).
[Final143-script/798-Lua verification and whole-source manifest](validation/builtin-inventory-2026-11-05.json).

## Native acceptance

The user initially unloaded FluxUI, then reported re-enabling it and continued
whole-game freezes. Separate read-only native checks at17:35/17:37 CET found the
active Forever client reporting `_FluxUI` unloaded, no Flux namespace/revision
and scriptProfile0; Syndicator was also unloaded. This differs from the reported
enabled state. No enable flag was changed. The new code has not received native
acceptance. Confirm revision `20261105.1` after an agreed reload before treating
subsequent observations as candidate results. Native Forever/other-client tooltip behavior, source-data
preservation across reload, mail/auction operation latency and long-session
retention checks remain pending. Do not equate this confirmed cache defect with
proof that all reported freezes are fixed.
