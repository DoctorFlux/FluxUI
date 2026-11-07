# Independent review of shared-service findings

Reviewed the production implementations and their call sites after the performance audit reported two anomalies. The independent [minimal script](service_peer_review.lua.txt) and [raw output](service-peer-review-output.txt) confirm both behaviors. This supplementary review is separate from the five-harness/three-repeat totals in the input report; it does not inflate those counts. No production source was changed.

| Module | Byte SHA-256 |
|---|---|
| `Core/Engine/Scheduler.lua` | `b7f171cb84de3c28d7a68735fafdf1aeb52f677cd81c84ad78687d30e94b2a16` |
| `Core/Engine/Events.lua` | `294aae31712948ebd6cf22167f2c53912797fb00949b3487e571fd8ca1e6ebbc` |

## Inventory request lost during partial bucket drain

**Confirmed shared-service correctness defect; current ordinary feature reachability is unproven.** `Scheduler.Flush()` detaches `pending.inventory` at line 302 before calling `RunInventory`. During the first eight old callbacks, a nested `Scheduler.Request("inventory", ...)` creates a new bucket and schedules another flush. If old callbacks remain, `RunInventory` line 259 assigns its leftover bucket to `pending.inventory`, overwriting the new bucket. Both the new callback and its tokens/reasons can disappear. The already scheduled timer then drains the leftover old work, so the scheduler ends with `HasPending()==false` despite losing the new request.

Independent controls: with eight initial callbacks, the nested callback runs and its token is observed; with nine initial callbacks, all nine old callbacks run but the nested callback runs zero times and its token is never observed. There is no documented latest-wins policy for this path. Production `Request` explicitly says every request is retained in the shared bucket, while callback-bearing requests are appended individually. Therefore this is not normal token coalescing or an intentional supersession.

The source search found the current inventory callback producer in `Inventory/Syndicator/Adapter.lua:505`, `QueueAuctions()`, which is guarded by `auctionsPending` at line 501. Most inventory callers request only a token. The audit has not demonstrated how the ordinary current addon produces a bucket containing more than eight callback functions, so do not describe this as a reproduced user auction failure. It is a real API-contract loss under the tested stress input and a future integration hazard. The separate large-queue copy cost also requires sufficient callback backlog; token-only requests do not create that workload.

Future fix: retain the detached bucket's cursor or merge its remaining functions with the already created pending bucket without overwriting either. Preserve FIFO of previously queued callbacks before newer requests, merge both token/reason sets, preserve the eight-callback-per-flush budget and coalesce the wake-up timer. Avoid adding another polling owner. Regression cases: initial counts 0/1/8/9/16/17; nested callback and token-only requests; requests from inventory listeners as well as callbacks; repeated tokens and different reasons; errors; multiple levels of reentrancy; queued work eventually drains exactly once. Repeated chunks should not copy the full remaining function array each frame.

## Event subscriber skipped after self-unregistration

**Confirmed dispatch-mutation hazard; current ordinary feature reachability is unproven.** `Events.lua:116` iterates the live listener array with a numeric `for`. `Events.Unregister` removes matching entries using `table.remove` at line 174. If list `[A,B,C]` dispatches A and A unregisters itself, the array becomes `[B,C]`; the iterator advances to index 2 and runs C, skipping B. Independent output is `AC` for the first event and `BC` for the next. Without mutation, both dispatches are `ABC`. If A explicitly removes B, `AC` is the reasonable live-removal control, which also passes.

The service does not document a snapshot versus live mutation contract, nor an instruction that callbacks may not unregister. Self-removal has not logically removed B, so skipping B is a service correctness hazard rather than an intentional listener selection. However the only production use of this central `Events.Unregister` found in the source is `Context.DisarmEvents()` (`Context.lua:546` and nearby). No production call site of `Context.Unsubscribe()` was found; the audit has not shown an ordinary addon event handler triggering self-removal during central dispatch. Report the service behavior and this reachability limit separately.

Future fix: define stable listener identity through dispatch, for example registration records marked inactive immediately and compacted only after the outermost dispatch finishes. Preserve existing registration order and duplicate-registration/unregister-all behavior. A new registration should normally wait until the next event; an explicit removal before a listener's turn should prevent it running, while removing the currently running listener must leave unrelated listeners deliverable. Track nested dispatch depth so compaction cannot invalidate an outer loop. This can avoid allocating/copying a snapshot array on every high-frequency event.

Regression cases: A removes itself; B removes an earlier listener; A removes B; unregister-all; remove-and-readd; duplicate callbacks; register during dispatch; recursive same-event dispatch and cross-event recursion; handler errors; timing observer cleanup; no retained dead listener references after idle. If another mutation policy is chosen, document it before implementation and check current consumers against that policy.

These are desktop source-execution observations, with no native taint or performance acceptance. Prioritize them alongside their trigger likelihood; do not give them the same current-feature reachability evidence as INPUT-001's normal modifier/target/mouseover event ordering.
