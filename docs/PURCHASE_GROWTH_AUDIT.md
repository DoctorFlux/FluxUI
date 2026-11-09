# Progressive purchase/cancellation lag audit — 5 November 2026

The user reports that every Buy or Cancel adds more lag to the next operation.
This is distinct from a single large snapshot completion. Four scoped production
replays therefore checked operations 10, 100 and 500 for retained subscriptions,
hooks, frames, timers, cache rows and subsequent work. They did not reproduce
growing resource ownership in the tested standalone pipeline or decorations.
Provider-ready mail reconciliation does repeat increasing work as its actual
mail facts grow. Neither finding certifies the whole addon or identifies the
cause of the native freeze.

The pipeline replay used the working mail/auction candidates based on
`437fda79136582282dde0f3989f3cb70c4411bad`. Their raw SHA256 identities were
Mail.lua `e01251d91221f5d2d5d70bf3a069fb6632c1dc94991ad93c87782532526156ff`
and Auctions.lua
`ec02d39d3e83815e57775596272854f967a0183a39009efaa547a61c972aee6a`.
The existing adapter source was unchanged:
`d242e0c07e789197335bde1d0deb27586c41b6fad24560add6846452408df561`.
Subsequent unrelated consumable fixes do not establish native acceptance of
these paths. [Snapshot preparation evidence](BUILTIN_MAIL_PUBLICATION.md) records
the separate before/after work reduction.

## Scoped repeated-operation results

The pipeline loads real Init, Scheduler, Containers, Index, Bags, Mail, Auctions,
Watch and Adapter modules. Native APIs, Store, provider state and frame scheduling
are mocks. Only two diagnostic inventory listeners are attached. Each operation
adds one future attachment mail, delivers the relevant auction/mail/money events,
and advances one simulated second. The mailbox remains closed. Buy preserves one
owned listing; Cancel removes it. These are event/fact models, not invocations of
Blizzard purchase or cancellation commands.

Forever, Retail and Era models each run standalone/provider-ready and Buy/Cancel
variants, for twelve models. Their GetBuildInfo mock uses versions 1.16.0, 12.0.1
and 1.15.9 respectively, all with build string 70000; these are fixture selectors,
not observed native builds or compatibility acceptance. At all three checkpoints:

| Scope | Observed behavior |
| --- | --- |
| Standalone closed mailbox | Zero inbox source scans, including while future mail grows to 500 messages |
| Standalone resources | 3 frames, 2 mail hooks, 2 inventory listeners, zero pending timers and active update scripts; subscriptions remain 43 on Forever and 44 on Retail |
| Standalone subsequent Buy | 1 owned-row source read and 2 numeric conversions at operations 10/100/500 |
| Standalone subsequent Cancel | Zero owned rows/read work after cancellation; no increasing subscriptions or callbacks |
| Provider-ready resources | 9 callback registrations, 1 frame after first dispatch, zero mail hooks, 2 inventory listeners, zero pending timers/active update scripts; subscriptions remain 17 on Forever |
| Provider-ready subsequent operation | 4 timers created and 2 listener calls per settled operation, constant at 10/100/500 |
| Provider-ready growing mail facts | Buy numeric conversions 42/402/2,002; Cancel 40/400/2,000 at 10/100/500 mail rows |

The later mailbox visit is measured separately: standalone opening of the
500-message inbox performs 8,500 budgeted header/attachment-slot reads. Transition
to the final two messages, removal and close returns the snapshot to zero rows
without growing resource counts. No native take command or transaction completion
was simulated. This result distinguishes observation during Buy/Cancel from later
mail opening/looting; it cannot validate the native last-mail freeze.

The native bag decoration replay loads the real JunkOverlay module with one
visible bag and hidden-parent/hidden bag frames, then repeatedly changes the
visible slot and requests repaint/hooks. Across Era, Anniversary, Mists, Retail
and Forever models, checkpoints 10/100/500 retain 9 fixture frames, 2 textures,
4 method hooks, 5 script hooks and zero pending timers. Subsequent visible item
reads stay 2 on the Classic layout and 1 on the unified layout; hidden reads stay
zero. The original visibility assertions pass 65 checks. Alternative bag UI still
bypasses this native overlay. Fixture frame counts include test-created objects.

The AlreadyKnown replay uses real Retail/Classic modules, a three-row active
auction view and a retained 1,003-row pool. Five client labels under both provider
labels retain 1 frame on Retail/2 on the Classic module, 2 hooks and 1 known-cache
entry. Each later update still visits 3 active rows and classifies 1 unknown item;
500 repeated addon-loaded notifications do not add hooks. The original assertions
pass 156 checks. The active rows reuse the same known/unknown IDs; this does not
bound the positive cache after browsing many different known items. Provider
labels do not load or certify the real external addon.

The metadata replay loads the real item classifier, reagent resolver and native
event router. Five client labels under both provider labels receive 500 distinct
unrequested metadata completions, with both event forms per ID. Checkpoints
10/100/500 retain 2 frames and zero timers; item names, full item-info reads,
container walks, junk/selector invalidations and unsolicited item-info cache rows
all remain zero. All 230 assertions pass. Requested item completion and visible
container harvesting are still exercised by the original fixture.

## Adapter work as real mail facts grow

An independent helper extends the existing production Adapter/Scheduler harness
in `tests/auction_refresh_batching.lua`. It meters actual normalized map writes
and source/map iterator visits, rather than estimating work from a replacement
algorithm. Each mocked purchase appends one real provider mail fact, emits
MailCacheUpdate and allows that operation's debounce/dispatch to finish.

| Completed purchases / current mail facts | Cumulative normalized rows copied | Rows copied by current operation | Cumulative source-row visits |
| --- | ---: | ---: | ---: |
| 10 | 55 | 10 | 110 |
| 100 | 5,050 | 100 | 10,100 |
| 500 | 125,250 | 500 | 250,500 |

This confirms repeated full-list work in the current adapter: settled purchases
grow both the provider's legitimate mail list and the amount recopied by the next
operation. The retained normalized rows equal 10/100/500 actual current mail
facts; no extra historical rows were found. Provider callbacks remain 9, the
native event-handler count 1, the scheduler inventory-listener count 1, drained
pending timers zero and scheduler pending false at every checkpoint. These
resource counts describe this smaller harness, not the pipeline's two-listener
configuration above.

Cancellation controls start with N owned listings and move one listing at a time
to mail. At N=10/100/500, copying both changed snapshots costs N rows for every
operation: cumulative copies are 100/10,000/250,000 after all N cancellations.
At the end, retained mail is N and retained owned auctions zero. Resource counts
remain stable. In this control the same-size total facts create constant
per-operation copying, rather than progressive callback/resource accumulation.

This is a justified future optimization target for the provider-ready path, not
a demonstrated explanation of standalone lag. Native provider callback cadence,
transaction/network timing and full-addon listener costs remain unmeasured. The
installed provider was not loaded into these desktop helpers or modified.

## External artifacts

Helpers contain generated mock data only. All helpers and raw stdout below live
outside AddOns/Git under the verified external
`Mail-auction-publication-20261105T173546Z` checkpoint. Each helper loads current
production files by absolute workspace path; reproducing the recorded result
requires the source identities above, not an arbitrary future checkout.

| Basename | SHA256 |
| --- | --- |
| repeated-purchase-readonly.lua | `8a6c02410c3f0281ec2c81945a278ca1ae4690b9af058f54c6d0f63f6c1fe918` |
| repeated-purchase-readonly.txt | `4f2b28e11c7188d7f4628eaf82bd4b75e1f2afbf004fb507fe2158ca5a8046af` |
| repeated-bag-decoration-readonly.lua | `5bf7c70d57d67f989890d7426338e2c44b260ef9701f1db9ff3f8287146b54a3` |
| repeated-bag-decoration-readonly.txt | `5dc698ad194d5dd0d93aa62a65111bd3ccbf369461d72eda1fcd57e5d0fbba11` |
| repeated-known-decoration-readonly.lua | `55174e5835a262331472650eb2fa580bf67ca2b4dc7b7676dbaff61a498a2a2b` |
| repeated-known-decoration-readonly.txt | `fa51ca574e62a220fb8206842d3546f1b1df45bc4cf0e7d584a21c42625b20c2` |
| repeated-metadata-readonly.lua | `e3a1996b7009baf257d94c0669dcfd750e61ef564e7b2d2439038211ff9711a0` |
| repeated-metadata-readonly.txt | `ef0b1f75495c4dcff25524826ceb6c10ddfb592962df484efbcc4b91f48abc22` |
| fanout-adapter-growth.lua | `3efe1a7692cb17611f8d063d97246686f99c1616c7a763fc5321e6451b921304` |
| fanout-adapter-growth.txt | `c1bc9c1241d10ce3dedd43cf1113aa2388c66fa8b149d64165271f57bf4c1235` |

## Native state and limits

A separately approved Forever reload at 19:15:51 CET confirmed build 70790,
source Syndicator, FluxUI/Syndicator/Baganator loaded and scriptProfile 0 before
and after. Its current mail/owned-auction caches were both empty. No matching
purchase, cancellation or mailbox transaction was performed. That establishes
loaded state only and is the wrong scenario for acceptance of this lag report.
The native client ledger records that separate check.

These replays exclude Summaries/Tooltip and the full inventory listener fanout,
real provider/network timing, third-party rendering and Blizzard command dispatch.
Pipeline resource samples follow a one-second settle and do not bound pending
work during an actual native stall or an event storm that never settles.
They count stated resources and operations, not every Lua instruction or native
CPU, allocation bytes, retained-memory bytes, frame time or FPS. Flat mock frame
and hook counts are not a native memory-leak certificate. User characters, account
data and installed third-party files were not modified by this audit. Installed
Syndicator remains read-only; a separately prepared private candidate is not
evidence of an installed fix. Whole-addon/native progressive freeze causation and
client/provider/bag combinations remain pending in
[the flow record](MAIL_AUCTION_REWORK.md).
