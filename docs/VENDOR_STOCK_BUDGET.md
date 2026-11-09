# Finite merchant stock budget — BUG-006

## Failure and correction

The quantity helper capped requests only when `numAvailable > 0`, so a zero-stock
entry was treated as uncapped. Separately, queued purchases reused the original
finite stock value without reserving quantities already submitted. Repeated buys
could exceed that snapshot's stock, submit rejected requests and add those requests
to the vendor total even though no goods arrived.

The production queue replay demonstrates both failures. With stock 3, max stack 2
and target 10, the baseline submits five requests for two units each. Only the first
request succeeds in the modeled merchant: two units arrive, four requests fail,
and the queue accounts for 50 copper rather than the accepted 10. Duplicate targets
sharing the same index entry and queues continued by bag events expose the same
reused-budget problem. A sold-out entry can also queue through the existing partial-
affordability path when the listed full purchase is unaffordable.

[FluxVendorBuy.lua](../Inventory/Restock/Vendor/FluxVendorBuy.lua) now treats every
nonnegative availability value as a cap. After submitting a purchase, it deducts
the requested quantity from the finite budget on that shared index entry. Later
requests using that entry therefore share the remaining budget. Zero stops buying;
the `-1` unlimited sentinel and the helper's existing nil-metadata behavior remain.

This budget reserves submitted requests; it does not acknowledge native acceptance.
Refreshing the index replaces entries with newly observed stock. Stock changes by
other players, delayed acknowledgements, rejected requests for unrelated reasons,
and unchanged-ID price changes remain separate cases. The correction neither polls
live stock nor introduces another transaction service. A normal new request after
an index refresh can use replenished stock, as covered by the regression.

## Identities, references and recovery

- Baseline commit `0d05acc3f56235d34dfa8dd699155a9e9f40147e`, tree
  `d482d14b17a63345ceaeea8ea2b5e6be1bed9f19`.
- Candidate runtime `b505bb880aeefbab414d957d8d7fbee6820c20a8`, tree
  `cc067974b724c82188d52f24a9800ad485ca261e`.
- [Baseline identity](validation/vendor-stock-baseline-identity-2026-10-29.json)
  verifies all 727 Lua files against the prior 86-script full report before reusing
  that complete baseline. A nonloaded fixture retains the actual pre-edit buyer.
- [Recovery](RECOVERY.md) records the fresh verified 10:54 UTC source/history/private
  settings checkpoint, made outside AddOns with WoW closed.
- Read-only Blizzard source 12.1.0.69283 treats zero availability separately from
  usability/purchasability in MerchantFrame.lua. Its generated MerchantItemInfo
  structure declares numeric availability with default zero. The existing bundled
  bulk-buy code also caps zero stock. Exact reference hashes are in the comparison
  JSON. This source snapshot predates installed clients and provides no new native
  acceptance; no code or assets were copied from it.

## Reproduction and measured results

The existing [merchant regression](../tests/vendor_slot_identity.lua) now supports
focused stock/identity groups while default execution runs both. It executes the
production module and merchant events with native shop/inventory/timers modeled.

```powershell
lua tests/vendor_slot_identity.lua --stock-only --source tests/fixtures/vendor_stock_before.txt --measure
lua tests/vendor_slot_identity.lua --stock-only
lua tests/vendor_slot_identity.lua --identity-only
lua tests/vendor_slot_identity.lua
python tests/run_validation.py --output docs/validation/vendor-stock-full-2026-10-29.json --sync-docs
```

Stock baseline: **177 checks, 39 failures**. Stock candidate: **177 checks, zero
failures**. Existing identity controls retain **660 passes**; combined execution
passes **837 checks**. The [full candidate suite](validation/vendor-stock-full-2026-10-29.json)
passes **86 scripts and 727 syntax files**, zero failures. The existing junk smoke
also passes. Baseline measure mode deliberately exits zero to retain failed samples.

Five alternating fresh-process pairs cover ten stock/affordability scenarios on
each of legacy tuple and modern table APIs. Each fixture warms open state for 0.6
modeled seconds, then builds/settles the index for 0.05 seconds. Capture runs the
queue to idle and dispatches 100 settled bag pulses. Replenishment/close controls and
direct nil/zero/negative/positive helper cases are checked separately. Capture is
operation bounded, not a native timed benchmark. All per-case count ranges are zero.

| Scenario, each API model | Before | After |
|---|---:|---:|
| Zero stock, target 10/max stack 2: rejected calls | 5 | 0 |
| Same: accounted copper, actual spend zero | 50 | 0 |
| Stock 3, target 10/max stack 2: rejected calls | 4 | 0 |
| Same: units obtained | 2 | 3 |
| Same: accounted / actual copper | 50 / 10 | 15 / 15 |
| Stock 10 across bag-driven passes: rejected calls | 2 | 0 |
| Same: accounted / actual copper | 60 / 50 | 50 / 50 |
| Shared-entry stock 3: rejected calls | 5 | 0 |
| Same: units obtained | 2 | 3 |
| Unlimited stock: 40 purchases / passes | 40 / 5 | 40 / 5 |
| Additional merchant-info reads after index warm-up | 0 | 0 |
| Event frames retained | 1 | 1 |

Finite/unlimited partial-gold and currency/item-cost controls retain their expected
accepted quantities. The unlimited sentinel is retained. There is no new timer,
frame, native query or UI layout change. These counters do not measure Lua CPU or
allocations. All money values above are simulated fixture data, not native losses.

[Raw baseline](validation/vendor-stock-baseline-2026-10-29.txt),
[candidate](validation/vendor-stock-candidate-2026-10-29.txt) and
[matched comparison](validation/vendor-stock-comparison-2026-10-29.json) retain the
commands, source/configuration hashes, samples, variation and read-only references.
Environment: Windows 10.0.26200, Lua/luac 5.4.6, Python 3.10.6, i7-12700F/20 logical
processors; GPU/RAM and native build/settings/addon list unavailable. Profilers off.
Process durations include harness/startup work. Native CPU, allocations, latency,
frame times, FPS and visual/secure acceptance are **pending**; no speedup is claimed.

## Required native checks — pending

Follow [client validation](CLIENT_VALIDATION.md) and the [performance protocol](PERFORMANCE_PROTOCOL.md).
Record exact build, hardware, addon versions, profile/targets, resolution/UI scale,
graphics and profiler settings. Preserve code/settings before comparing revisions
sequentially in this same addon identity.

1. At a controlled inexpensive limited-stock merchant, compare zero, one, and several
   remaining units with a target above stock and max-stack boundaries. Verify actual
   bag gain, stock display, error messages and the final vendor total agree.
2. Exercise targets spanning more than eight purchase calls, manual/tier overlap,
   limited gold, and available alternate-currency/item costs. Compare unlimited-stock
   quantities and cadence against baseline. Confirm duplicate entries do not each
   reuse the same finite budget.
3. Refresh normally after stock replenishes, issue a new request, and verify only
   remaining target quantities are bought. Close/reopen the merchant and check that
   stale requests do not resume. Observe real delayed/rejected acknowledgements
   separately; retain those cases as pending unless naturally reproduced.
4. Capture matched screenshots of the unchanged controls and stock/total display;
   check input/combat/taint and permitted API access. Run five matched startup/idle/
   purchase-burst pairs, preserving raw CPU/resources/latency where available and
   unprofiled frame captures with profiler overhead accounted for.

No native client row advances from desktop results. Auction, guild-bank and
void-storage callback audits remain deferred.
