# Consumable charge scan with an open bank — 5 November 2026

## Trigger and correction

The user supplied a native stack at 19:19:57 while opening the Consumables
config. `FluxConsumablesGridUI.GetChargeAwareCount` asked the restock registry
whether a configured item uses charges. `ScanOwnedMaxCharges` reached
`FluxRestock.Inv.Bank.ForEachSlot` at `FluxRestockList.lua:1307`, but that method
does not exist on the restock bank adapter. It exists on a different
`FluxInv.Bank` object. `FluxRestock.Inv.Bank.IsOpen()` can be true for the
Blizzard or Baganator bank view, exposing this mismatch and stopping the grid
as it builds configured cells.

The scanner now uses the adapter's `ForEachOpenStack({ bank = true,
warband = true }, callback)` contract. It still checks bag slots, includes
matching live bank and supported warband stacks when open, and retains the
largest charge count. A partially loaded adapter without the iterator leaves
the bag result available rather than crashing. There is no saved-data change,
new ticker, event, protected action, or visual change. This corrects the
runtime exception that the earlier config visibility fix did not cover.

## Source and verification

Baseline main is `d71f2b9ef0d6675870ab3f12f3d0d0c79bd91b68`. Baseline
`FluxRestockList.lua` SHA256 is
`b8a31fbabfdd8e79e313b0e1ff736a699aa42d05ba7fb29bec0ca2550b8ed611`;
candidate SHA256 is
`2193301d557d4e659a3d285adf663a727f4aa7a6cb445f397e77bd5764e61222`.
The verified all-ref `FluxUI-charge-scan-prechange-20261105.bundle` is outside
AddOns and Git under the dated visualization directory. Retail and Forever
on-disk `_FluxUI.lua` settings were inspected read-only; the prior external
settings archive remains available. No WoW process was found during this
desktop run, and no game input or profiler preference was changed.

Five paired loaded-module runs reproduce the baseline open-bank nil call and
pass the candidate: closed-bank bag counts, open-bank matching and unrelated
items, character/warband iterator options, cached maximum, and missing-iterator
fallback. [Raw comparison and hashes](validation/restock-charge-bank-iterator-comparison-2026-11-05.json).
The [full desktop validation](validation/restock-charge-bank-iterator-2026-11-05.json)
passes 149 scripts and 804 Lua syntax files. That worktree also contained
uncommitted mail/auction changes; its manifest records exact file hashes and
does not certify a separate clean-checkout run. Harness wall times are process
timings, not addon CPU or FPS.

Native acceptance remains pending for Retail, Forever, Era, Anniversary, and
supported progression clients. Reopen the Consumables config with a charge
item while the character bank and Baganator bank are open, then with the bank
closed. Confirm every configured icon remains visible, no error recurs, and
counts, tooltip target, secure click, and combat behavior are correct. Capture
build, addons, profile, UI scale, errors, pixels, and matched frame time before
any performance or visual claim.
