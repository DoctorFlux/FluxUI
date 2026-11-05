# Built-in cold-item request ownership — 5 November 2026

The user initially unloaded FluxUI, then reported re-enabling it and continued
whole-game freezes. Separate read-only native checks at17:35/17:37 CET found the
active Forever client reporting `_FluxUI` unloaded, no Flux namespace/revision
and scriptProfile0; Syndicator was also unloaded. This differs from the reported
enabled state. No enable flag was changed. The new code has not received native
acceptance. Confirm revision `20261105.1` after an agreed reload before treating
subsequent observations as candidate results.

This fixes reproduced built-in amplification and retained-state defects. It does
not identify the native freeze or the initiating reporter warning.

## Reproduced behavior and correction

The built-in container fallback can identify an item and quantity before full
metadata is cached. It used to create a fresh closure and issue another native
load request for every slot on every scan, even for an already pending item ID.
One failed native completion then ran all those callbacks as successful and
requested redundant bag refreshes. Its 0.4-second retry loop had no deadline and
continued after transfer to an external provider.

The existing item-data service now coalesces the first request per active item ID
and each distinct callback function. Containers reuse one callback per bag and
register that bag's ownership. Counts still come from the same item-location
fallback. Successful completion refreshes each remaining owning bag once; failed
completion does not pretend data arrived or start a failure/rescan feedback loop.
Distinct explicitly registered callbacks remain supported.

Retries use the existing frame and 0.4-second interval, with at most four native
requests per active attempt. At the eight-second deadline, checked by that frame,
active scan-pending state expires and its OnUpdate stops. Passive callbacks remain
eligible for a later successful native completion; no polling is needed for that
success. A normal scan of the same cold item with the same bag callback cannot
restart expired work. A new owner or a genuine explicit request without a bag
owner may start another bounded attempt.

Containers retain at most one last-known unresolved record per observed bag slot.
Known replacements retire obsolete item IDs, even beside a permanently ambiguous
slot; that ambiguous slot retains its own one previous owner. Observed ready data
or a confirmed empty slot clears the slot's waiter. ReadSlot and PatchSlots update
the same ownership map; bulk scans prune once after their reads. Only a positively
observed capacity trims slots beyond the new size; zero-size/unreadable bank data
does not mean empty. Other bags owning the same item ID retain their callbacks.
An item can also move into a slot whose identity is completely unreadable,
including another previously empty bag. Each bag with observed unknown slots
therefore has at most one passive completion observer. Any successful metadata
event can request its normal rescan once until the next full scan; failures do
not. Specific and bag-wide callbacks share one notification per bag. No historical
item-ID list is needed for these unidentified moves. Partial native info without
an ID also uses the existing item-location fallback when available.
The existing inventory flush, scan-pending query and owned
event/update paths clear built-in work after Syndicator takes ownership. Native
completion may be synchronous, so registration/counting precede each native call;
retry batches retain their entry identities and recheck provider ownership.

The single existing lazy frame unregisters its metadata event when neither
specific waiters nor unknown-bag observers remain, and re-registers on demand.
Both passive forms retain the event with OnUpdate stopped. An unknown-only bag
can now create that lazy frame even without an identified load request; no second
frame, timer or ticker is introduced. Missing native request APIs create no active
wait. No global API replacement, settings reset or framework is added.
Between retry intervals/deadlines, OnUpdate checks only its clock/elapsed state;
it does not walk the pending map on every rendered frame.
Closed bank observers do not schedule hidden refreshes, and the existing close
latch retires them. A later real bank scan may restore unresolved observation.

## Recovery and source identity

Baseline commit: `b664bb0b93ac566a34744aec5895e927a7a1ffff`.
The verified external `Builtin-inventory-20261105T152153Z` checkpoint contains
1,488 actual source files, 75 accessible on-disk settings and all-ref Git history.
Source ZIP SHA256:
`c2a7f2c073d38a90133cff6e5fc494164430338149ef65343ca61ab507ca537a`.
Archives/private settings remain outside AddOns/Git; unsaved memory is excluded.

Selective baseline fixtures are Init.lua SHA256
`a05221905f3a90d313209827873f3c990992d62017b5ada1067b35f270c90931`
and Containers.lua SHA256
`67a59049ac84bbbdd48ad5c57b193542fe8c3b7d04d0e42063fcbcf255673376`.
They are source fixtures, not another working addon.

## Regression and measured scope

Run from the repository root:

```powershell
lua tests/item_data_request_coalescing.lua
lua tests/item_data_request_coalescing.lua '<baseline>/Init.lua' '<baseline>/Containers.lua'
lua Inventory/_tmp_inventorylag_smoke.lua
lua tests/late_inventory.lua
lua tests/pending_mail_provider_handoff.lua
```

The regression loads the production Init/Containers service with native APIs and
frames mocked. Five client labels with built-in/provider-pending labels exercise
the shared contract, not ten native client/provider implementations. It covers
repeated cold slots, multiple IDs/bags, physical quantities, callback identity,
failed and late completion, finite retries/deadlines, repeated scans after expiry,
explicit rearming, removed owners, ambiguous slots, provider handoff, synchronous
completion/handoff, callback re-entry and unavailable APIs. It also replaces one
known slot 1,000 times beside a persistent ambiguous slot, exercises standalone
ReadSlot/PatchSlots ownership, cleans ready metadata without a completion event
and counts pending-map visits across 100 pre-interval frame updates.
Moved-item regressions cover partial and entirely unreadable destinations,
cross-bag moves in both scan orders, unknown source and destination together,
specific/wildcard coalescing, 1,000-event storms, ready observations without an
event, bank close/reopen and provider handoff.

Across ten labelled models, 100 scans of ten cold slots sharing one item ID:

| Metric | Baseline | Candidate |
| --- | ---: | ---: |
| Initial native requests | 10,000 | 10 |
| Retained callbacks before completion | 10,000 | 10 |
| Completion dirty marks / inventory requests after adding another bag | 10,200 each | 20 each |
| Native requests during the separate unavailable-data scenario | 270 | 40 |
| Retained IDs after 50 complete cold replacement scans per model | 500 | 10 |
| Retained IDs after 1,000 known-slot replacements beside an ambiguous slot | 10,020 | 20 |

The baseline fails 630 of 790 checks; the candidate passes all 790. Existing
combined inventory/mail/auction smoke passes 1,732 checks; readiness handoff and
pending-mail ownership regressions also pass. Final matched runs, mutation checks,
source hashes and full-suite validation are recorded with the release evidence.
These counters are modeled operations/retained records, not native CPU, allocation
bytes, frame time, FPS or measured transaction latency.

The unshipped intermediate 440-check implementation was archived externally
before addressing its persistent-ambiguity retention and per-frame map walks.
The final regression rejects it with 260 failures: retained IDs 10,020 versus 20,
and 100,000 pending-entry visits versus zero during the separate pre-interval
frame scenario. The original b664 implementation also performs zero visits before
its retry interval; the candidate preserves that cheap-frame behavior. Intermediate
Init.lua SHA256 is
`6fe301fc35ddfa0346435bef0a6a95a6aeed78538e6edbe32fee4b406f868d37`;
Containers.lua SHA256 is
`52e1e883fc07c5640fb2724bcbda2cd4565cca488fafbe11d905b89b71cab8b4`.

A separately archived 560-check intermediate passed the retention cases but
lost moved-item callbacks when the destination had no known identity. The final
regression rejects that version with 170 failures; callbacks in the targeted
same-bag move scenarios are restored from zero to 20, matching the original b664
baseline's 20. Cross-bag and observer cases are also required to pass. Its Init.lua
SHA256 is `5e8840f5ae57b223debdf55601140b2e51c1839ebbe4d7261a216b5b936f6b52`;
Containers.lua SHA256 is
`3665af131f3dce435e5e3bbd946fe623af244ba6af6f17af838f0d34499dabf4`.

## Limits requiring continued validation

After timeout, data can still be unavailable; the original physical-ID/count
fallback remains and successful late metadata still requests the normal rescan.
The deadline changes active-wait reporting rather than certifying complete
metadata. Repeated identical bag scans no longer create new native attempts;
explicit requests and new owners are the recovery paths when another request is
needed before a late result arrives.

Passive production ownership follows the bounded last-known slot maps, including
one prior record for each currently unreadable slot. It no longer accumulates the
history of readable slots beside an ambiguous one. Zero-capacity data preserves
that last observed slot ownership rather than erasing inaccessible bank contents.
Unknown bags retain one coalesced observer rather than every item that might have
moved there. If ambiguity persists, future successful metadata events can cause
one additional rescan per full observation cycle. This event-driven recovery has
no idle polling, but its native cost has not been measured; unrelated events are
ignored again once the bag is readable or its observer is retired.
Explicit callbacks without a bag owner retain their requested lifetime until
success or provider handoff; the only current production caller supplies a bag
owner. That explicit-consumer lifetime is not an unconditional global cache cap.
No native allocation or whole-addon memory-leak certification is implied.

Native client behavior, protected/secret-value handling, actual retry API cost and
reported freeze removal remain unverified. Preserve existing preferences and
diagnostics. Keep the current enable state until it is reconciled with the user. Read-only
identity checks above do not certify these changes; no candidate transaction
test or profiler capture was performed.

[Five matched pairs per change, raw samples, candidate hashes and12 rejected mutants](validation/builtin-inventory-comparison-2026-11-05.json).
[Final143-script/798-Lua verification and whole-source manifest](validation/builtin-inventory-2026-11-05.json).
