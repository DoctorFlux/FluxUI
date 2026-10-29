# Queued vendor purchase identity — BUG-005

## Failure and intended behavior

The restock queue keeps a merchant slot, item ID and purchase metadata across bag
events. Before this change, RunBuyPass used the stored slot without resolving its
current item. Replacing/removing that listing between passes could buy an unrelated
item or submit a purchase for an empty slot. Refreshing the merchant index did not
repair existing queue entries, which retain their old metadata/slot references.

The regression runs production [FluxVendorBuy.lua](../Inventory/Restock/Vendor/FluxVendorBuy.lua)
through its public manual-restock entrypoint and real event handlers. A 12-target
queue submits eight valid purchases in its first pass. Before the next bag pulse,
slot 9 changes to an unrelated item and slot 10 disappears. The baseline submits
both invalid purchases; the unchanged trailing targets still complete. The same
failure occurs before and after the debounced index rebuild, for manual/tier entries
and both merchant-info/identity API models. A separate case changes the next listing
inside a synchronous purchase callback and exposes the same unchecked-slot path.

The intended behavior is to submit a queued purchase only while the slot resolves
to its requested item ID. The fix reuses ResolveMerchantSlotItemID in the existing
invalid-task condition. Missing/mismatched listings are discarded before quantity
calculation, wallet deduction, reporting or purchase. Valid tasks retain their
existing budget, order, cadence, quantity math and UI refresh paths.

Moved/missing targets are not silently credited or automatically relocated in the
current queue. A fresh normal restock request after index refresh resolves the
current listing and remaining bag need. The test verifies that recovery without
duplicating targets already bought. Price/stock changes for an unchanged item ID
and asynchronous purchase acknowledgement remain separate investigations.

## Sources and recovery

- Baseline commit `07b11ce66c1b9efd70752f70f15a8e3f88fa63eb`, tree
  `ddd388fb8c69d8650efb485f1d9b95d0512f7e3e`.
- Runtime candidate `cdd752abd060588bc1602e880d997a60dd0b34a9`, tree
  `d18478f458e670f18931c070a00d53a708387fee`.
- [Baseline identity](validation/vendor-slot-baseline-identity-2026-10-29.json)
  verifies all 726 prior Lua hashes before reusing the 85-script full baseline.
  The retained nonloaded fixture preserves the actual pre-edit runtime source.
- [Recovery](RECOVERY.md) records the fresh 10:40 UTC source/history/private-settings
  checkpoint outside AddOns, completed with WoW closed. No settings were reset.

## Desktop validation and matched operation counts

```powershell
lua tests/vendor_slot_identity.lua --identity-only --source tests/fixtures/vendor_buy_slot_before.txt --measure
lua tests/vendor_slot_identity.lua --identity-only
lua Inventory/Restock/Junk/_tmp_junksmoke.lua
python tests/run_validation.py --output docs/validation/vendor-slot-full-2026-10-29.json --sync-docs
```

The baseline reports **36 failures in 660 checks**. Candidate passes all **660**;
the existing junk regression also passes. The [complete candidate suite](validation/vendor-slot-full-2026-10-29.json)
passes **86 scripts and 727 Lua syntax files**, zero failures. Baseline measure mode
deliberately retains failures while exiting zero; ordinary candidate execution must
pass normally. No native client was run.

Five alternating fresh-process baseline/candidate pairs cover legacy tuple and
modern table merchant information, direct item-ID and link-only identity, manual
and tier targets, and pulses before/after index refresh. Startup advances 0.6 modeled
seconds, builds the index, then advances 0.05 seconds before purchase scenarios.
Capture is operation bounded: four remaining tail tasks, or 40 stable targets over
five passes followed by 100 settled pulses. Four same-pass mutation cases are
additional correctness controls. All measured per-case count ranges are zero.

| Per changed-tail fixture, each of 16 cases | Baseline | Candidate |
|---|---:|---:|
| Wrong-item purchase calls | 1 | 0 |
| Missing-listing purchase calls | 1 | 0 |
| Unintended copper spent in the fixture | 800 | 0 |
| Correct trailing purchases | 2 | 2 |
| Total submitted calls | 4 | 2 |

| Stable 40-target fixture | Baseline | Candidate |
|---|---:|---:|
| Purchase calls | 40 | 40 |
| Bag-driven passes | 5 | 5 |
| Maximum calls per pass | 8 | 8 |
| Additional direct identity reads, direct-ID models | 0 | 40 |
| Additional link reads, link-only models | 0 | 40 |
| Reused event frames | 1 | 1 |

This is a correctness guard with measurable lookup overhead, not a speedup claim.
Direct-ID models also try one link fallback for the missing listing in changed-tail
cases. The 800-copper amount is simulated test data, not an observed native loss.
CPU, memory/allocations, native operation latency, frame times and FPS were not
measured. Whole-process times in the JSON include startup and harness execution.

[Raw baseline](validation/vendor-slot-baseline-2026-10-29.txt),
[candidate](validation/vendor-slot-candidate-2026-10-29.txt) and
[comparison](validation/vendor-slot-comparison-2026-10-29.json) retain commands,
source/configuration hashes, samples and variation. Environment: Windows 10.0.26200,
Lua/luac 5.4.6, Python 3.10.6, i7-12700F/20 logical processors. GPU/RAM, native addon
list/profile/settings and native client build are unavailable for these desktop
fixtures. Result: **PASS for modeled outcomes; native acceptance pending**.

## Native checks — pending

Follow the [client matrix](CLIENT_VALIDATION.md) and [performance protocol](PERFORMANCE_PROTOCOL.md).
Record GetBuildInfo, addon versions, profile/targets, hardware, resolution, UI scale,
graphics and profiler settings. Use the same addon identity sequentially and
preserve current code/settings before any baseline comparison.

1. At a controlled inexpensive merchant, compare ordinary manual/automatic restock
   with stable listings: exact target quantities, batches, money, partial affordability,
   alternate costs, tier selection, UI totals and merchant close. Capture matched
   screenshots and geometry for the unchanged restock controls.
2. Where a normal merchant/listing interaction can reproduce a listing change while
   a queue remains, verify that no replacement item is bought and no empty listing
   is submitted. Test both delayed and completed merchant-index refresh. Do not
   replace native APIs or manipulate live data to force the condition; unavailable
   listing-change cases remain pending.
3. Refresh the normal merchant index and issue another restock request. Confirm
   remaining/moved targets resolve correctly and already acquired quantities are
   not purchased again. Close/reopen and check that stale sessions do not resume.
4. Verify input/combat/taint behavior and actual API accessibility on each supported
   client. Run five matched baseline/candidate startup, settled idle and purchase
   bursts with equivalent targets and stock, recording raw CPU/resources/latency
   where available. Repeat unprofiled frame captures and account for profiler cost.

No visual, protected-input, secret-value, taint or native performance pass is inferred
from these desktop checks. The deferred auction/guild-bank/void callback scope is
unchanged.

The test now also covers [finite stock budgets](VENDOR_STOCK_BUDGET.md). Use
`--identity-only` to reproduce this report's original 660-check group with the
current harness; historical raw samples retain their original commands/test hashes.
