# Independent shared-service review

Read-only review of the combined Events, Scheduler, Combat and Range changes,
with Ticker inspected as Range's driver. Production files were changed only by
the root owner. [Final raw runs and source hashes](service-review-results.json)
identify the reviewed state. This is desktop control-flow evidence; native
security, secret values, frame timing and client performance remain unverified.

Three interleavings found in intermediate working versions were corrected by
the root owner before the final run:

| Interleaving | Intermediate failure | Reviewed correction / final control |
| --- | --- | --- |
| Combat regen directly flushes Scheduler before its existing zero-delay timer fires. | Two current timers drained 12 inventory callbacks in the next mocked frame after the regen batch of 8. | An epoch owns each scheduled flush; the consumed timer becomes stale. The next mocked frame drains 8. |
| An old structural callback enters combat and submits new structural work before its remaining old callbacks pause. | The general wake ran newer work before the older detached remainder: `old1,new,old2`. | One retained paused bucket and one shared wake preserve `old1,old2,new`; callback and listener variants are in the permanent regression. |
| The last callback/listener in a resumed old structural bucket enters combat again while a newer bucket already waits. | The newer bucket had no timer or Combat wake. Another regen left it stranded. | The final pending-work check registers the shared combat wake when locked and schedules a flush otherwise. A second regen now retires the newer bucket. |

The two documentation harnesses preserve independent minimal controls:

```powershell
lua 'Stress test doc/applied-fixes/security/shared-service-review.lua.txt'
lua 'Stress test doc/applied-fixes/security/shared-service-last-callback.lua.txt'
lua tests/shared_service_integrity.lua
```

The first harness also runs a fixed-seed mixed-tier stress property: **200**
scenarios, **6,199** callbacks and **7,459** assertions. It combines nested
structural/inventory requests, callback combat reentry and direct reentrant
flush attempts, checking FIFO within each tier, exactly-once execution and
eventual retirement. It passes on the final reviewed source.

The permanent integrity test passes **23,237** assertions. It also covers event
self-removal, later-handler removal, remove-all/re-add, newly added handlers,
nested dispatch, duplicates and callback errors; coalesced token-only requests;
bounded inventory/regeneration batches (10,000 jobs each; at most 16 regen jobs
per mocked frame); regeneration callback reentry; sustained
mouseover freshness and range-owner disarming.

No further actionable defect was reproduced in this bounded review. The batches
bound callback counts, not execution time: one callback can still be expensive.
Named combat jobs and structural callbacks retain their existing scheduling
contract. The 200 scenarios do not establish correctness for every external
callback, third-party error handler, or native protected-frame interaction.
