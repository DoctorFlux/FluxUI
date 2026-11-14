# Craftable bandage and potion tiers — 9 November 2026

`CRAFT-TIER-FALLBACK-20261109`: the user reports missing bandage and potion
buttons despite having materials for a lower tier. Auto must show when any
known recipe is affordable, and prefer the highest ranked affordable tier.
This request supersedes the previous top-recipe-only rule.

The loaded owner is `Inventory/Craft.lua` at TOC line 117. Its selector used
only the first sorted recipe and returned nil when that recipe lacked materials.
It now walks the existing sorted list and stops at the first affordable recipe.
Restore strength and the existing Engineering/stack/item-ID tie breaks still
determine priority. Knowing a stronger recipe cannot block a weaker affordable
one. Learned-recipe filtering and complete bag-only reagent requirements remain.

The existing shared result supplies Auto visibility, right-click bindings,
tooltips and click dispatch for bandages, healing potions and mana potions.
No other runtime owner changed. The leftover FluxInv scanner is not loaded and
remains untouched. Forever First Aid routing, ordinary owned-item selection,
mana relevance, Off/Always, combat deferral, click locks, restock commands,
appearance and saved data retain their existing paths.

The bag-generation cache and full recipe dependency set remain. Material gain
for a currently unaffordable stronger tier still triggers promotion. Selection
adds at most one walk over the already computed recipe list per invalidation;
no extra recipe-list build, polling, frames, events, hooks or timers are added.

The dated external source ZIP was checked against all 2,417 actual source
files; the history bundle was verified. Read-only on-disk settings metadata
covered 116 files. No live settings backup is claimed. See the
[checkpoint](validation/craft-tier-checkpoint-2026-11-09.json).

`tests/consumable_craft_visibility.lua` now runs 1,609 checks across the existing
five client models and both builtin/Syndicator inventory providers. It covers
lower-tier fallback, a missing second high-tier reagent, promotion while both
tiers are affordable, depletion back to the lower tier, tooltip identity,
legacy/modern single-craft dispatch, duplicate presses, bag-generation caching,
full dependencies, bank/warband exclusion and explicit visibility modes. Existing
owned-output/metadata, live-zero, Forever profession and disabled-work checks
are retained. The obsolete source assertions requiring top-only selection were
removed from the bars smoke; the behavioral regression replaces that contract.

Three alternating matched pairs each reject the exact old source with 540
failures and pass the candidate with zero failures. Reagent transitions add no
main item rebinds or frames; repeated reads reuse the recipe cache. Host wall
times in the [raw comparison](validation/craft-tier-comparison-2026-11-09.json)
are diagnostics, with no native timing or FPS conclusion. The existing 620-check
craft identity and 1,475-check consumable suites also pass.

Sources: no Blizzard API or signature changed. The
[source record](validation/craft-tier-sources-2026-11-09.json) retains the bundled
Retail `297d7aaaa736f346b3e036f38ee088eaf7f8c07f`, Forever
`eac30af597e5aaa43a60f6675ef5fdcea100375f`, and progression
`e5d9b3a22c3f0f6f41ebac0e454f4969594261cf` CraftRecipe declarations. Latest branch
heads could not be verified through GitHub API/git access. These are dated
source declarations, not new client access or operation certification.

All five [installed source copies](validation/craft-tier-client-copies-2026-11-09.json)
match through the existing sync. No manual synchronization, game input,
settings/profiler writes or publication occurred. The existing direct-implementation
and Witchcraft in-game preferences are retained. No connected Witchcraft/native
interaction tool is available; native pixels, physical clicks, taint and
performance remain pending for every client.

After an ordinary out-of-combat reload, open the relevant profession once if
its learned recipes have not been cached. With Auto enabled and no carried
output, retain materials only for a lower learned bandage/healing/mana potion:
the button should show, name that tier in its crafting tooltip and craft it on
right-click. Add the stronger tier's complete materials: the tooltip and next
craft should promote. Spend those materials until only the lower tier is
affordable: the button should remain available and craft the lower tier.
Remove all affordable materials: Auto should hide unless a usable output is
carried. Verify Off/Always and ordinary owned-item use; record build, profile,
recipe/item IDs, inventory provider and any native error.

Full validation passes all 272 scripts and 942 Lua syntax files. The three owned
source/test files match the pre-run manifest and saved report. Four unrelated
options files changed concurrently and were preserved; their current syntax and
260 rework/2,514 navigation checks also pass. Whole-corpus identity therefore
is not claimed; exact differences and follow-up hashes are in the source guard.

Full runner and source guard:
[validation](validation/craft-tier-full-2026-11-09.json),
[source guard](validation/craft-tier-source-guard-2026-11-09.json).

The full runner was repeated with current options work: all 272 scripts and
942 syntax files pass again. Owned craft/runtime/test hashes remain unchanged;
concurrent options differences are recorded separately.
[Second complete report](validation/craft-tier-current-full-2026-11-09.json).

The final [documentation check](validation/craft-tier-documentation-2026-11-09.json)
reports four stale records for concurrently edited options_navigation/options_rework
test fixtures. They changed again after the second full run and inventory rebuild.
Their edits are preserved. This does not change the exact validated craft sources;
current whole-working-tree documentation acceptance remains pending.
