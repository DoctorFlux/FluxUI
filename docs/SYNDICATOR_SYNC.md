# Syndicator data continuity — 13 November 2026

`SYNDICATOR-SYNC-20261113` implements the user's request to retain Syndicator's
data when the companion is disabled and update its stale data after standalone
FluxUI use. It retains the existing Retail, Forever, Mists, Era and Anniversary
paths. It adds automatic data continuity, with no new UI, setting or command.
The existing direct-implementation and user-native-reproduction choices remain.

| Requirement | Implemented behavior | Acceptance |
| --- | --- | --- |
| SYN-SYNC-01 | While Syndicator owns inventory, save its complete live data root, including other characters, guilds, account data and deletions. | Alias and mutation tests; native SavedVariables serialization pending. |
| SYN-SYNC-02 | Import a detached built-in ledger once after leaving Syndicator; later standalone reloads retain their own changes. | Enable/disable/reload cycle tests; native reload cycle pending. |
| SYN-SYNC-03 | Reconcile proven newer built-in regions into unchanged external data; preserve independent external changes, deletions and current live cash/tokens. | Three-way conflict, deletion, first-encounter and Ready tests. |
| SYN-SYNC-04 | Translate container IDs, slot offsets, dense empties, capacities, list identity and metadata without resetting saved data. | Legacy/modern-bank, empty-list, capacity, mail and auction tests; native companion appearance pending. |
| SYN-SYNC-05 | Reuse provider ownership with no synchronization polling, recurring timer, new frame or per-cache-update account copy. | Traversal/subscription counters and repeated desktop transition measurements; native performance pending. |

## Storage and ownership

[`Inventory/Syndicator/Sync.lua`](../Inventory/Syndicator/Sync.lua) owns bridge
metadata under `FluxUIInventoryDB.SyndicatorSync`, version 1. Its `data` field
references the live `SYNDICATOR_DATA` version 2 root while the companion owns
inventory. Existing Syndicator writes therefore update the saved mirror directly.
This includes changes to alternate-character mail and replacement or deletion of
nested records; synchronization does not subscribe to each cache callback.

When the built-in store next initializes, `Restore` converts the mirror into
detached `Characters`, `Guilds` and `Warband` records, clears derived summaries
and queues their normal rebuild. It clears the persisted `active` marker. This
conversion happens once for that transition; later standalone reloads do not
reimport the old mirror over newer scans. The original external-format mirror
remains frozen as the common ancestor for the next reconciliation.

At Syndicator's existing Ready handoff, `Bind` reconciles before the adapter
rebuilds its snapshots and then reattaches the live mirror. The existing provider
continues to own live scanning. Built-in and Syndicator scanners are not enabled
together for synchronization. Unsupported external schemas remain untouched.

Writes mark the existing summary queues and send a bounded set of existing
callbacks at that transition. A changed current character receives full
Bag/Equipment/Currency refreshes. Each changed character receives
`MailCacheUpdate` to invalidate account-search caches, including changes outside
mail. Alternate-character bag callbacks are deliberately avoided: Baganator
treats their character argument as the live character. Changed account-bank
records receive Bank/Currency refreshes. These transition notifications add no
cache subscriptions or recurring work; guild-bank and void callbacks remain
unchanged.

## Freshness and compatibility

Syndicator 290 stores no scan/update timestamps. Mail/auction expiration times
cannot establish when an inventory snapshot was observed. Reconciliation uses
exact data comparison, separately by field and container:

- If external data still matches the frozen ancestor and built-in data changed,
  the built-in value can update it.
- If the external value changed independently, preserve that external value.
  Relative chronology is unknown when both sides changed.
- On first encounter, preserve existing external data whose age cannot be
  established. Missing local-only entities can seed the external store.
- A missing external entity that existed in the ancestor is a deletion; do not
  resurrect it. Native current-character money and currencies already observed
  before Ready retain authority over saved values.

Container mapping comes from Syndicator's exported constants, saved with the
ancestor. Legacy bank arrays, modern `bankTabs[].slots`, account-bank tabs and
equipment slot offsets convert to the existing built-in shape. Exports retain
dense empty slots and known capacities, including empty or removed carried bags.
Unpurchased empty bank IDs must not create phantom tabs. Existing entity/root
references and provider-only metadata remain owned by Syndicator. Changed
external summaries use its existing version 5 pending queues; full character
invalidations use numeric `1`.

List conversion retains auction IDs, expiry and available item metadata. Built-in
mail intentionally avoids fetching item links during inbox scans. When only an
ordinary item ID is known, export supplies a minimal ordinary-item hyperlink for
Syndicator's summary key parser. It does not invent unknown pet species or item
variant identity. Existing known metadata is retained where the identity matches;
native companion rendering and metadata completion still require verification.
Guild-bank and void-storage callbacks remain unchanged.

## Evidence and remaining native checks

[`tests/syndicator_sync.lua`](../tests/syndicator_sync.lua) exercises the real
bridge and Store/Adapter handoff across five desktop client models. It covers
separate serialized roots, repeated transitions, independent edits, deletions,
metadata, empty regions, capacities and harmful controls. Its larger-account
measurements report transition work separately from synthetic serialization.
Focused validation passes 309 checks, including three harmful controls. The full
320-script / 1,002-Lua syntax suite snapshot passes and all task sources still
match that snapshot. A concurrent unrelated trinket recovery test appeared after
runner enumeration and now passes 200 checks after its separate source changes;
whole-workspace suite freshness remains with that separate work. A 103-character desktop model records
five transition samples separately from synthetic serialization.
The [validation record](validation/syndicator-sync-2026-11-13.json) records final
source identities, raw samples and the complete suite outcome. Desktop results
do not establish native serialization, FPS, taint safety or pixel parity.

The read-only reference is Syndicator 290 by plusmouse at
`F:\World of Warcraft\_forever_\Interface\AddOns\Syndicator`, All Rights Reserved,
copyright 2023–2026. Its implementation was inspected for the data contract; no
third-party source was copied. A verified external checkpoint preserves 2,612
actual source files and all-ref history at
`26f886e3ea5371b196ab235d2dace0c156002285`; 58 settings metadata entries were
inspected without copying or changing private contents. The checkpoint is outside
AddOns at `syndicator-sync-checkpoint` in this task's external visualization folder.

Native acceptance remains pending: with Syndicator enabled, change current and
alternate-character data and log out/reload; disable it and verify retained
counts, bank/mail/auction data and gold. Make standalone changes, reload again,
then re-enable an unchanged Syndicator store and verify the updates. Independently
changed external records and deletions must survive. Verify Baganator views,
empty/resized bags, purchased bank tabs, item metadata, transactions and repeated
reloads on each client. Measure matched native startup/interaction work with the
same addon list and profiler preferences. Leave WoW in the background and use
the user's existing reproduction route. No client control, on-disk settings or
profiler writes, manual installation synchronization or publication occurred.
