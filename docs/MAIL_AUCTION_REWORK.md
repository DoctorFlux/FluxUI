# Mail and auction performance work

The November request covers mailbox opening, closing, individual messages,
looting and the final Open All transition; auction posting, sales, purchases and
cancellation, including cancellation followed by mailbox entry. Preserve every
existing feature, setting, visual and configured delay on the repository's five
clients, with or without external Syndicator and Baganator. A rewrite is an
implementation option, not evidence that working code should be discarded.

This record tracks the performance work. The separate
[mail feature matrix](MAIL_INTEGRATION.md) retains its unfinished feature rows;
this investigation does not complete or remove them. The supplied
[inventory specification](../new%20docs/docs/specs/21-inventory-foundation.md)
requires one factual inventory owner and explicitly excludes auction queue
management. Blizzard continues to own posting, buying, cancellation and their
confirmation dialogs. FluxUI observes inventory facts and adds its existing
mail controls and decorations.

The renewed report explicitly includes Buy followed by delivery to the mailbox.
Track the purchase acknowledgement, closed-mailbox period, later mailbox entry
and collection as separate stages; a bag-update replay alone cannot validate
this flow.

The latest report says each purchase or cancellation makes the next operation
slower. Treat this as a growth investigation: compare operation 1, 10, 100 and
500, retained mail facts, callbacks, hooks, frames, queued work and error history.
Distinguish legitimate pending-mail ownership from unnecessary repeated work or
leaked registrations. Do not truncate pending mail or drop features to cap cost.

## Ownership and acceptance

| ID | Required behavior / owner | Current evidence and next acceptance |
| --- | --- | --- |
| ECON-01 | Native auction post, sell, buy and cancel remain responsive; `Builtin/Auctions.lua` only observes owned listings. | [Query ownership](AUCTION_QUERY_OWNERSHIP.md) corrects duplicate/foreign queries. [Staged auction preparation](BUILTIN_AUCTION_PUBLICATION.md) removes the unbudgeted final fingerprint/copy loop. Actual burst-sale/post/cancel latency remains unmeasured. |
| ECON-02 | Mail open/close and attachment capture retain complete generations; `Builtin/Mail.lua` owns built-in inbox facts. | [Staged mail preparation](BUILTIN_MAIL_PUBLICATION.md) keeps normalization within the existing 48-read/1 ms scan budget and publishes complete maps. Bounded retries and generation restart remain. Native getter costs and closing-cache validity are unknown; do not discard ownership speculatively. |
| ECON-03 | Mail actions remain sequential, respect pending native commands and the saved opening speed; `Mail/Select.lua` owns the single job. | [Wake coalescing](RAID_MAIL_AUCTION_FOLLOWUP.md) and [native command readiness](MAIL_NATIVE_COMMAND.md) pass desktop regressions. [Job lifecycle](MAIL_JOB_LIFECYCLE.md) covers final-mail cancellation and disabling its owner. Native last-two-mail, bag-full and delayed-command checks remain pending. |
| ECON-04 | Optional external Syndicator becomes the sole account-data owner when ready; `Syndicator/Adapter.lua` owns handoff. | Late-readiness guards, unchanged-snapshot checks and progressive auction batching pass desktop fixtures. Opening after handoff must issue no built-in query. [External version289 findings](EXTERNAL_SYNDICATOR_POSTING.md) separate its unfixed cold-post callback error and remaining full-copy cost. Provider-labelled fixtures do not prove native integration. |
| ECON-05 | Bag/item bursts cannot expand retry or summary ownership indefinitely; `Init.lua`, containers and summaries own these resources. | [Bounded item loading](BUILTIN_ITEM_DATA.md) and [zero-summary pruning](INVENTORY_SUMMARY_PRUNING.md) are published in `e860ce6`. Native allocation and long-session retention remain pending. |
| ECON-06 | UI consumers do necessary visible work while retaining decorations, counts and immediate interaction. | [Hidden inventory work](HIDDEN_INVENTORY_WORK.md), [metadata filtering](AUCTION_METADATA_WORK.md) and [active auction rows](AUCTION_PURCHASE_REFRESH.md) have scoped desktop evidence. Native screenshots, inputs, taint and frame times remain pending. |
| ECON-07 | All client/provider combinations preserve ownership, settings and features; diagnostics remain optional. | Exact source pins and native contracts are in [native comparison](NATIVE_MAIL_AUCTION_REFERENCE.md). Client acceptance is pending as recorded below; original Wrath is distinct and unverified. |
| ECON-08 | Consecutive Buy-to-mail and cancel-to-mail operations must not accumulate unnecessary work or registrations. | Progressive growth is user-reported; operation-count/resource curves are being investigated separately from the completed snapshot-budget fixes. Preserve every real pending item and test cleanup after collection. |

Permanent native hooks and shared event registrations remain installed where the
current architecture requires them. Their callbacks must check provider/module
ownership before doing owned work. Disabled mail modules stop future owned
actions; an already-issued server command must finish normally.

Desktop replays reproduced a final full-list fingerprint/copy/clear burst outside
the built-in scan budget, including clearing a large old attachment map when
only two money messages remain. Staged preparation addresses that owned boundary;
it does not preempt a slow native API, bound every downstream listener or prove
that the user's native freeze is cured. Temporary staging maps add peak storage;
no total CPU or memory-byte reduction is inferred from the operation counts.

The existing mirror delivered the three lifecycle runtime files byte-for-byte
to all five installed addon folders. This is on-disk delivery only; a normal
reload and a loaded-source check are still required before native acceptance.

## Client and provider coverage

| Client | Source build | Auction contract inspected | Desktop / native status |
| --- | --- | --- | --- |
| Forever | 1.60.1.70790 | Modern; runtime legacy selector retained | Mocked contracts pass; native freeze removal pending |
| Retail | 12.1.5.70783 | Modern | Mocked contracts pass; native pending |
| MoP Classic | 5.5.4.70631 | Modern | Mocked contracts pass; native pending |
| Classic Era | 1.15.9.70576 | Legacy | Mocked contracts pass; native pending |
| Anniversary | 2.5.6.70577 | Legacy / runtime selector retained | Mocked contracts pass; native pending |

Use the pinned [Blizzard source links](NATIVE_MAIL_AUCTION_REFERENCE.md), not a
moving branch or historical tuple signature. Installed external Syndicator 289
is an All Rights Reserved, read-only reference. Its auction callbacks remove
sold/cancelled identities in place; full inbox/owned-list captures can still be
synchronous. Its presence on disk does not mean it is loaded. Test the optional
provider and optional Baganator independently where their dependencies permit;
record unavailable combinations explicitly.

## Native acceptance still required

Fresh approved checks at 19:14 CET confirmed Forever 1.60.1/build70790/interface
16001 with FluxUI, external Syndicator and Baganator all loaded. The active source
was Syndicator. After byte-matching the candidate files in Forever, an approved
reload ran at 19:15:51; the 19:17 check confirmed the source and inventory marker
`20261105.1`, with scriptProfile0 before and after. Provider mail/auction caches
were both empty at the 19:18 read. No auction or mail transaction was executed;
the built-in changed paths and reported progressive freeze were not exercised.
Previous foreground windows were restored when the check changed focus.

The user now uses BugTabs 1.4.9's own capture. BugGrabberDB was nil. A diagnostic
incorrectly called a BugGrabber method after reading cache counts, causing a
probe error; it was stopped and must not be classified as a FluxUI regression.
No error history was cleared, logger preference changed or heavy capture run.

The user reported whole-game freezes with FluxUI loaded and no freezes during
an earlier unloaded comparison. Later read-only checks at 17:35 and 17:37 CET
observed a different loaded state: Forever build70790, FluxUI and Syndicator
unloaded, scriptProfile0 and no Flux globals. These observations do not establish
the state during the reported freeze. The process subsequently changed again;
later background host inspection found a new Forever process started at 17:55
CET. Those earlier observations do not establish the state during the reported
freeze; the fresh loaded/provider check above supersedes their current-state
assumption. Do not silently change addon enable flags or interpret an unloaded
run as candidate acceptance.

Keep WoW in the background and profiling off unless a new capture is agreed.
The earlier heavy capture was lost when the client exited; preferences and the
prior diagnostic root were restored. Do not repeat frame enumeration or claim
that capture as a benchmark. No live transactions were executed in this batch.

For each available client/provider combination:

1. Confirm the running build, loaded addons, Flux source revision and inventory
   source after the user's normal reload. Preserve the current profile/settings.
2. Capture matched idle, mailbox entry/exit, single-message attachment, selected
   loot and Open All runs, including the final two messages, delayed metadata,
   full bags, interruption, disable and close/reopen.
3. Separately capture posting, purchasing, cancellation-to-mail and multiple
   buyer sales both while the auction UI is open and after it is closed. Native
   transactions need suitable user-owned test items; do not invent sale events
   and report them as native operations.
4. Alternate matched baseline/candidate runs, warm up, repeat, preserve raw frame
   times and available CPU/resource/latency measurements. Record hardware,
   resolution/UI scale, settings, addon list, duration and profiler overhead using
   the [performance protocol](PERFORMANCE_PROTOCOL.md).
5. Check final item/money ownership, every attachment/filter, UI position/input,
   module/profile disable, and native errors/taint. An absence of errors alone
   does not pass latency or visual parity.

Implementation checkpoints, raw desktop samples and mutations are linked from
the two lifecycle reports. The reported long freeze remains unresolved until a
matched native candidate run demonstrates otherwise. Further rewrites require
an observed failure or measured hotspot in the affected owner, with these
requirements retained.
