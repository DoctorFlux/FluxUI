# Saved character recipes and crafting restock

13 November `AUCTION-FOLLOWUP-BUTTONS-20261113` / AHR-84 addresses the reported
mail-to-bank/vendor stall that appeared to need an open profession. Trusted
inventory planning is separate from native AH execution readiness; collecting
mail and the bag-storm settlement notification can advance the existing job
while the profession stays closed. A temporary missing recipe/roster reply does
not discard a previously verified character plan. Explicit owned unlearning,
changed output/material facts, another character, changed targets or price
policy still invalidate it; actual crafting rechecks the live owned profession.
Current implementation and desktop/native acceptance are tracked in
[the active requirements](AUCTION_RESTOCK.md#fast-purchases-and-usable-pending-item-buttons).

The shared profession owner adds `GetCharacterKey()`,
`GetProfessionKnowledge(names, skillLineID?)` and `GetRecipeKnowledge(descriptor)`.
The latter knowledge queries distinguish true learned/owned facts, false explicit
revocation, and nil unavailable data. Complete current-character recipe facts are
durable across sessions. Explicit modern unlearned recipe IDs are remembered in
the existing skill payload and are cleared by a verified relearn; numeric/name
aliases cannot resurrect a removed recipe or mask a complete newer record.
Unknown or foreign/linked/NPC views are not unlearning evidence. Recipe output,
minimum yield and reagent quantities remain saved plain facts, while bag state,
prices and live craft permission remain separate.

AUCTION-VENDOR-ROUTES-20261113: recipe comparison now prices vendor ingredients on AH too, chooses their actual missing invoice, and carries stable per-input routes/prices into vendor targets and the follow-up queue. Exact vendor terms preserve equal-cost recipes and wallet quantities. [Rules](AUCTION_RESTOCK.md#vendor-catalogue-observations-and-auction-discounts).

13 November `AUCTION-FOLLOWUP-20261113` /AHR-51 fixes the remaining context leak:
native GetRecipeInfo/GetRecipeSchematic results from a closed or unrelated
profession cannot reject or replace complete learned facts saved for this
character. Price comparison does not open a profession. Matching open owned data
can still invalidate an unlearned recipe, and uncertain quality outcomes require
live proof. The follow-up button carries the exact selected recipe/profession
through mail and vendor steps, then verifies live output/materials before a
player-authorized crafting batch. [Workflow](AUCTION_RESTOCK.md#follow-up-button-and-closed-profession-recipes).

13 November charge follow-up (`AUCTION-PURCHASE-CHARGES-20261113`): charge targets
are converted to whole physical outputs before recipe operations are calculated.
Ingredient quantities/yields stay physical. Existing charged restock rows protect
their own use target before supplying a recipe; material-only rows count physical
ingredients. Saved vendor plans restore the selected output's charge metadata.
Only the recipe portion of a mixed direct/material invoice spends its crafting
budget; whole-stack surplus stays included. See [purchase and charge rules](AUCTION_RESTOCK.md#purchase-identity-selection-and-charged-items).

13 November 2026, `CHARACTER-RECIPES-20261113`. The user requests remembered
recipes for auction restock and later features, the finished item's unit limit
on crafting routes, and temporary vendor restock for missing recipe ingredients.
Existing five-client scope, direct implementation and user native reproduction
remain selected. No client focus/input, manual sync, settings-file writes or
publication is part of this change.

| ID | Requirement | Current implementation |
|---|---|---|
| CRP-01 | Save learned outputs, quantities and materials per character across reloads. | Existing `FluxInvDB.professions[characterKey].bySkillLine`; versioned plain crafting facts extend each recipe. |
| CRP-02 | Reuse the same saved knowledge in AH and other features, with or without optional addons. | Shared `Flux.Inventory.Professions` queries; current character by default, explicit character-key lookup available. |
| CRP-03 | Preserve valid facts through filtered/partial scans; avoid importing foreign knowledge or guessing learned status. | Merge observations; explicit unlearn removes; unknown state is not learned; NPC/legacy linked views are ignored. |
| CRP-04 | AH can plan from saved deterministic recipes after the profession closes/reloads. | Complete saved schematic, yields and ingredient options; uncertain quality/operation results still require native proof. |
| CRP-05 | Finished-item unit cap applies to crafting, including vendor costs; explicit No limit mode controls unlimited buying. | AHR-79 supersedes the old zero-is-unlimited rule. With No limit off, zero is a real zero acquisition budget; existing shared allocations and one physical AH purchase per press remain. |
| CRP-06 | Create temporary vendor ingredient targets without changing permanent targets. | Per-character chosen-plan facts join the normal vendor list, account for bags/mail/shared ingredients, and clear on completion or invalidation. |

Open each relevant profession once after updating so FluxUI can capture its
learned recipes and complete materials. It does not open protected profession
windows from a timer. Subsequent AH visits and reloads reuse the saved facts.
All learned item recipes supported by the existing scanner are recorded, rather than an
auction-only potion/bandage database. Previously unseen recipes still require
the game's profession data to be made available.

The public shared queries are `ListAllCachedRecipes(characterKey?)`,
`ListRecipesForOutput(itemID, characterKey?)`, `GetRecipe`, `GetReagents`,
`GetOutput` and `IsLearned`. An explicit character key reads that character's
catalogue without changing current-character knowledge. Output-based lookup is
preferred for legacy recipes: their native recipe IDs are list positions.
Numeric/name aliases do not duplicate a modern recipe in catalogue queries.

Saved crafting data contains only plain ingredient/output/quality identifiers,
required slot counts/options and conservative yields. It does not persist live
craftability, an allocation's guaranteed quality, auction prices or bag ownership
as a recipe guarantee. Quality-dependent recipes remain stored for reuse, while
buying their materials requires proof of the requested output quality. An
unsupported required ingredient cannot fall back to an older incomplete plan.

The item limit constrains acquisition cost for the requested finished shortage,
including missing vendor inputs. Owned/incoming materials retain their existing
allocation rules. The explicit No limit switch removes the unit cap; zero with
the switch off is a real zero budget. Comparison with buying the finished item
still applies. Vendor ingredient prices cannot rise above the
price used in the selected plan without re-pricing at AH. Permanent vendor
targets for the same item continue independently if that happens.

Temporary plans live under the current character's
`Restock.auctionRestock.vendorCraftPlans`. Their required ingredient totals are
merged with permanent targets, with incoming craft ingredients counted once.
They survive the AH-to-vendor trip and reload. Acquired ingredients stop further
buying; crafted outputs remove the plan. Changed targets/caps, disabling crafting,
lost recipe/profession knowledge or changed vendor ingredients invalidate it.
Pure temporary vendor rows are read-only; merged rows retain the permanent
target's editing owner. Existing vendor automation/manual restock supplies the
purchases and keeps its enable/Shift/wallet/stock rules.

The new focused suite currently passes704 checks across20 client/optional-addon
models. It serializes and reloads actual profession SavedVariables, runs the
real AH queue and vendor buyer, and tests caps, aliases, foreign views, shared
inputs and mail. Seventeen harmful controls are rejected. The captured combined run passes
320 scripts/1002 syntax checks; unrelated post-run edits are recorded
separately in [evidence](validation/character-recipes-2026-11-13.json). Native persistence, grade guarantees, vendor buying, UI/controller
operation, optional-addon internals, taint and FPS are not certified by models.
The existing mouse/keyboard/controller plan remains; no controls/bindings/CVars
were added. Read-only temporary rows do not edit permanent targets.

External source/history checkpoint: `auction-restock/tab-crafting-followup/character-recipes-20261113`
(2,609 files;47 settings metadata entries; private values not copied). Pinned
client/API identities remain those in [auction restock](AUCTION_RESTOCK.md).

Five repeated matched work models record4 versus2 schematic reads per open,
4 versus2 unique-query catalogue rows, and0 versus1 closed-profession AH variants.
These deterministic counts are not native elapsed-time or FPS evidence.

Shared documentation validation was run. Its remaining failures concern
concurrent Syndicator sync source/evidence changes outside this change. All
owned recipe/restock identities still match the passing focused/control runs.
