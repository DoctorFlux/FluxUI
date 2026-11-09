# Combat consumable junk uses current carried tiers

8 November 2026, JUNK-CARRIED-COMBAT-20261108. For each of bandages, healing
potions and mana potions, retain the highest usable tier actually carried.
Only a strictly better usable output in bags can make a lower tier automatic
junk. Equal tiers under different IDs remain useful. Remove the last better
copy and the remaining tier becomes useful again, including before a delayed
inventory provider publishes its new snapshot.

A better recipe, sufficient materials, previously owned output, vendor stock,
bank/warband stock or saved reference is not a carried upgrade. Finished items
crafted through Alchemy, First Aid or Tailoring use exactly the same rule as loot.
Craft selection/profession routing is unchanged: Forever healing-potion crafts
still use First Aid, with existing other-client Alchemy and bandage routes.

Existing explicit Junk/Useful choices and manual restock protection retain their
precedence. Low-level and inferior-tier options remain independent: an enabled
low-level rule can still junk a sufficiently old lower tier if an actual carried
upgrade exists, even with inferior marking disabled. Turning both rules off
retains those items. Food/water/conjure rules, gray junk, equipment, restock targets,
purchasing thresholds, binding behavior and saved data are preserved.

The failure had two sources: inferior marking used a remembered/vendor tier
rather than current bags, and the independent low-level rule could still junk
the current best tier after its inferior mark was removed. Stale direct marks,
partial item-class metadata, pending vendor upgrades and inferior availability/iterator counts also needed
the same carried-upgrade requirement. The user clarification supersedes the
supplied vendor specification's memory-based combat-junk behavior; that memory
remains available for purchasing and the existing food/water policy.

Three owners changed: tier Match supplies a separate junk reference, Inferior
uses it for marking and pending upgrade evaluation, and FluxJunk gates automatic
rules, stale marks, display, inferior availability and queue counts consistently.
The existing seller rechecks these verdicts immediately before each sale.
Candidate lists reuse the existing tier-reference cache with fixed per-kind keys;
inventory/metadata generations invalidate them. Ownership/usability remain live.
Sorted candidates equal to or below the item cannot justify junk and need no
replacement-count query. No new event, hook, frame, timer, polling service,
profile reset or saved root was introduced.

The recovery checkpoint Combat-consumable-junk-20261108T101813Z contains 2,264
actual source files, 188 accessible on-disk settings and verified Git history.
Unsaved game memory is excluded. No game input, reload, real transaction,
settings/profiler change, commit or push was performed in this batch.

Desktop acceptance: 1,020 checks across five client adapter models, immediate and
delayed-provider publication, and all three combat kinds. These execute real tier,
junk/display/mark and asynchronous seller owners. Native facts/classification
are mocked; this fixture does not run external Syndicator or real recipes. The
full runner also exercises the existing real Craft/visibility and provider owners.
Five alternating baseline/final pairs reject the baseline with 720 failures and
pass the candidate. Four controls reject old junk rules, old pending reference,
old availability and omitted live ownership. Five additional matched pairs check
the redundant-count control: 6,000 highest-tier replacement-count queries become
zero, with zero warm bag walks in both. Counts have zero run-to-run variation.

Across the full 30-scenario transition sequence, bag-map reads increase from
3,150 to 3,585 and live-count queries from 2,580 to 2,955 for the stronger policy.
Simulated sales change from 60 to 30: only lower tiers are sold after a real
upgrade. These are operation counts, not native CPU/allocation/FPS results.
Host wall times are retained but uncontrolled; native costs remain unmeasured.

The final full runner passes 255/255 scripts and 920 Lua syntax files with an
unchanged source corpus. Earlier runs saw independent debuff-tint source/test
changes; their newer work was retained and the final pass supersedes those mixed
runs. All three owned sources and this regression match their recorded candidate
hashes. All 12 destination source copies match through the user's continuous
sync; no manual sync was performed.

Native acceptance remains pending. Connected background client-test tools are
unavailable; the background-only rule is preserved. On each available client,
after a normal out-of-combat reload, record build, profile, addon list and item/
recipe IDs, then check the Junk preview/coin marks:

1. Carry only a lower potion/bandage tier. Keep better items in bank and better
   recipes learned/affordable: the carried tier must stay useful.
2. Loot or craft a strictly better usable tier. The new highest tier stays useful;
   lower tiers follow the enabled automatic rules. Check equal tiers and a higher
   item of another kind too.
3. Consume, bank or otherwise remove the last better copy. The remaining best
   tier must become useful. Check live ownership before provider publication.
4. Repeat with/without Syndicator/Baganator, each relevant profession/client route,
   manual Useful/Junk/restock overrides and automatic-rule toggles. Test any real
   selling only with chosen expendable items. Check BugTabs for new errors.

Reproduction from addon root: `lua tests/combat_consumable_junk.lua`.

- [Matched samples and controls](validation/combat-consumable-junk-comparison-2026-11-08.json)
- [Complete-run outputs](validation/combat-consumable-junk-full-2026-11-08.json)
- [Source guard and independent changes](validation/combat-consumable-junk-source-guard-2026-11-08.json)
- [Existing client copies](validation/combat-consumable-junk-client-copy-2026-11-08.json)
