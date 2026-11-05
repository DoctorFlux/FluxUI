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

## Ownership and acceptance

| ID | Required behavior / owner | Current evidence and next acceptance |
| --- | --- | --- |
| ECON-01 | Native auction post, sell, buy and cancel remain responsive; `Builtin/Auctions.lua` only observes owned listings. | Duplicate show queries and queries after provider handoff are reproduced and corrected in [query ownership](AUCTION_QUERY_OWNERSHIP.md). Actual burst-sale/post/cancel latency remains unmeasured. |
| ECON-02 | Mail open/close and attachment capture retain complete generations; `Builtin/Mail.lua` owns built-in inbox facts. | Existing scan has a 48-call/1 ms per-frame budget, bounded retries and generation restart. Native getter costs and closing-cache validity are still unknown; do not delete cached ownership speculatively. |
| ECON-03 | Mail actions remain sequential, respect pending native commands and the saved opening speed; `Mail/Select.lua` owns the single job. | [Wake coalescing](RAID_MAIL_AUCTION_FOLLOWUP.md) and [native command readiness](MAIL_NATIVE_COMMAND.md) pass desktop regressions. [Job lifecycle](MAIL_JOB_LIFECYCLE.md) covers final-mail cancellation and disabling its owner. Native last-two-mail, bag-full and delayed-command checks remain pending. |
| ECON-04 | Optional external Syndicator becomes the sole account-data owner when ready; `Syndicator/Adapter.lua` owns handoff. | Existing late-readiness guards, unchanged-snapshot checks and progressive auction batching pass desktop fixtures. Opening after handoff must issue no built-in query. Provider-labelled fixtures do not prove native provider integration. |
| ECON-05 | Bag/item bursts cannot expand retry or summary ownership indefinitely; `Init.lua`, containers and summaries own these resources. | [Bounded item loading](BUILTIN_ITEM_DATA.md) and [zero-summary pruning](INVENTORY_SUMMARY_PRUNING.md) are published in `e860ce6`. Native allocation and long-session retention remain pending. |
| ECON-06 | UI consumers do necessary visible work while retaining decorations, counts and immediate interaction. | [Hidden inventory work](HIDDEN_INVENTORY_WORK.md), [metadata filtering](AUCTION_METADATA_WORK.md) and [active auction rows](AUCTION_PURCHASE_REFRESH.md) have scoped desktop evidence. Native screenshots, inputs, taint and frame times remain pending. |
| ECON-07 | All client/provider combinations preserve ownership, settings and features; diagnostics remain optional. | Exact source pins and native contracts are in [native comparison](NATIVE_MAIL_AUCTION_REFERENCE.md). Client acceptance is pending as recorded below; original Wrath is distinct and unverified. |

Permanent native hooks and shared event registrations remain installed where the
current architecture requires them. Their callbacks must check provider/module
ownership before doing owned work. Disabled mail modules stop future owned
actions; an already-issued server command must finish normally.

One remaining cost boundary needs measurement: completed-list fingerprinting
and publication in the built-in mail and auction sources traverse the complete
captured list outside the native-call scan budget. That work is linear and has
not been measured in game. It does not by itself explain a freeze with only two
money-only messages. Keep it visible for attribution rather than calling the
whole publication path frame-budgeted or rewriting it without a baseline.

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

The user reported whole-game freezes with FluxUI loaded and no freezes during
an earlier unloaded comparison. Later read-only checks at 17:35 and 17:37 CET
observed a different loaded state: Forever build70790, FluxUI and Syndicator
unloaded, scriptProfile0 and no Flux globals. These observations do not establish
the state during the reported freeze. The process subsequently changed again;
later background host inspection found a new Forever process started at 17:55
CET. No current
in-memory candidate identity has been verified. Do not silently change addon
enable flags or interpret an unloaded run as candidate acceptance.

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
