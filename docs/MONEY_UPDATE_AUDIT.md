# Money-update work audit

The Buy-to-mail investigation also inspected synchronous money/status-bar work.
This is a read-only finding against baseline
`437fda79136582282dde0f3989f3cb70c4411bad`; no money-path fix is included in the
snapshot-preparation batch.

`FluxStatusBar.lua` handles PLAYER_MONEY with UpdateGoldBar. A changed display
calls GoldLedger.OnAfterGoldBarUpdate, which saves current money. The inventory
currency listener in `FluxGoldLedger.lua` then invalidates, saves and requests
another UpdateGoldBar. Its visual signature check runs after watched-currency
and tracked-item reads. SaveCurrentMoney rebuilds character metadata and walks
the account's character rows on every call; its written `_lastSaveMoney` and
`_forceResave` fields currently provide no read-side fast path.

An external desktop helper, `gold_money_audit_20261105.lua`, executes the real
ledger/item-tracking modules and extracted production gold update/event functions.
Its SHA256 is `ae42fdfe0c7e47b224de045adde6c8cb517577eddd917e896b1908b3da0fb07a`.
The source-extraction helper and raw stdout remain outside AddOns and Git.
It models 100 changed money events followed by the registered inventory callback;
this timing is a fixture scenario, not observed native event ordering.

| Mocked workload | Result |
| --- | ---: |
| 100 money changes, three watched currencies | 200 gold updates / 200 ledger saves |
| Money / watched-currency getter reads | 400 / 800 |
| Tracked-item count reads, three items | 900 |
| Tracked-item count reads, 39 items | 11,700 |
| Character-row visits with 1,000 synthetic alts | 200,200 |
| Maximum update recursion depth / gold size writes | 1 / 0 |

Identical-display controls perform no ledger saves or character scans, but still
read watched currencies and tracked counts. These are production operation counts
on mock data, not the user's actual account size, native CPU, FPS or a freeze
attribution. The tested real layout did not reproduce geometry recursion.

A future change must preserve identity/name recovery, migration/import,
deletions, row metadata and timestamp semantics, login zero protection, logout
saving, provider handoff and every legitimate display update. Do not add a naive
money-only cache or remove a callback without testing those ownership contracts.
Native currency-header expansion events were also considered, but the inspected
source did not establish a self-invalidation loop; no speculative guard was added.
