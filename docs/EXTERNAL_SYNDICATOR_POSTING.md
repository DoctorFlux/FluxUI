# External Syndicator cold posting callback

On 5 November 2026, a read-only audit of installed external Syndicator 289 found
a reproducible delayed-metadata error in commodity posting. This is an external
provider defect, not a fix made by FluxUI or an attribution of the reported
freeze. The user also reproduced freezes with external Syndicator unloaded;
that independent FluxUI investigation remains necessary.

## Source identity and failure

The inspected addon is `_forever_/Interface/AddOns/Syndicator`, version 289,
All Rights Reserved. No external code or assets were copied into this repository,
modified, wrapped or replaced. FluxUI audit base: `437fda79136582282dde0f3989f3cb70c4411bad`
(published runtime `7a06b85f633d1945b7d6bf615636f486f3d7e627`).

| Installed source | SHA256 |
| --- | --- |
| `Tracking/AuctionCacheModern.lua` | `186dc61d453edf7db6839e22403ad5f3acc3845282943cf24a3e356c022d5b75` |
| `Core/Utilities.lua` | `a42765fe554490c8a3ea44b3953e01e379fb86496d1aa34398e7411f3083845c` |

`ProcessAuctionCreated` captures the commodity ID and count at lines 312–313.
For uncached metadata it registers a later callback at lines 337–339, then clears
`self.postedCommodity` at line 341. The callback's `DoItem` still reads that
cleared field for the expiration at line 324. Completion after the method returns
therefore indexes nil; a later posting could instead supply the wrong expiration.
The cached, immediate branch completes before clearing and does not hit this case.

The external item-data handler invokes its callback list before clearing the
pending entry (`Core/Utilities.lua:111–116`). An exception prevents cleanup.
Its update handler then continues requesting pending IDs every 0.4 seconds
(lines 119–140), without an attempt or elapsed-time limit. Subsequent delivered
load-result events can invoke the same failing callback again. Actual native
event timing, repeat delivery and connection to the reported warnings are unverified.

## Desktop reproduction

The external evidence helper `syndicator-289-cold-post-replay.lua` reads these
installed functions into an isolated desktop Lua process. It contains extraction
instructions and API mocks, not copies of the external implementation. Helper
SHA256: `b84ddabf8f70456f3e9c0998514498da1c21580c41aea754a97e903f45bced54`.
It remains outside active AddOns and is not part of the release.

```powershell
lua '<external-evidence-directory>/syndicator-289-cold-post-replay.lua' 'F:/World of Warcraft/_forever_/Interface/AddOns/Syndicator/'
```

| Actual-source desktop replay | Delivered load results | Callback errors | Mock load requests | Publications / rows |
| --- | ---: | ---: | ---: | ---: |
| Metadata completes after the posting handler returns | 5 | 5 | 6 | 0 / 0 |
| Metadata already cached, immediate completion control | 0 | 0 | 0 | 1 / 1 |

The delayed case reports a nil `postedCommodity` field and retains its update
handler. The cached control preserves count and expiration. These are source
operation counts, not native latency, memory, FPS or a game-performance benchmark.
No game input, profiling, settings change or auction transaction was used.

The appropriate upstream correction would capture every immutable posting field,
including expiration, before registering the delayed callback and detach completed
pending ownership before invoking callbacks. It must preserve errors and remaining
callback semantics; broad error suppression is not a remedy. No upstream message
or external addon change has been made. This external defect remains unfixed here.

## Buy-to-mail ownership

External Syndicator's modern purchase handlers add completed purchases directly
to its mail cache (`AuctionCacheModern.lua:152–155,245–303`), including while the
mailbox is closed. Cancellation/expiration removes an owned listing and adds its
item to mail; a sold listing is removed without adding its item back (169–176,
233–242). FluxUI's adapter coalesces the provider callbacks and copies provider
facts (`Inventory/Syndicator/Adapter.lua:500–531,625–646`). That path does not start
a built-in inbox scan or invent carried-bag delivery. Built-in passive item-data
owners are cleared after provider handoff (`Inventory/Init.lua:1507`), and their
event/update handlers also reject external ownership (267,309).

Full external-provider list copies and the provider's own synchronous captures
remain separate cost boundaries. Neither this posting defect nor desktop
callback batching establishes the cause or resolution of native Buy, buyer-sale,
mailbox entry/exit or final-mail freezes. Those checks remain pending for each
client with and without external Syndicator and Baganator.

## Cold owned-list callback accumulation

A separate actual-source desktop replay exercised repeated owned-list refreshes
for one item whose metadata remained unavailable. The callbacks registered in
`Tracking/AuctionCacheModern.lua:196–214` have no scan-generation ownership;
`Core/Utilities.lua:135–140` adds another waiter/request on each refresh.
At 10/100/500 refreshes, pending item IDs stayed at one but retained callbacks
and immediate mock load requests grew to 10/100/500. Delivering one later success
ran all stale callbacks against the current owned data: one native owned listing
of quantity two became 500 provider rows totaling 1,000, with 500 publications.
Pending handlers then cleaned up normally. The source hashes above still match.

This is a reproduced external callback-retention/data-duplication defect under
cold metadata, distinct from legitimate pending-mail growth and the cold posting
nil-field error. Actual native timing and responsibility for the user's freeze
remain unverified. Fresh approved checks found external Syndicator active in the
current Forever session; earlier unloaded-provider reports remain a separate case.
A private patch/regression proposal is being prepared outside AddOns and Git.
The installed reference remains untouched under the user's read-only rule;
do not deduplicate genuine Flux mail records or replace external global APIs to
conceal the provider defect.

## Remaining external-adapter copying

An exploratory desktop extension of the real adapter/scheduler harness in
`tests/auction_refresh_batching.lua` counted normalized rows copied while 500
valid provider records arrived. All final quantities remained correct.

| Provider callback delivery model | Rebuilds | Copied rows | Publications |
| --- | ---: | ---: | ---: |
| 500 owned rows in one synchronous callback burst | 1 | 500 | 1 |
| One newly resolved owned row per subsequent frame | 500 | 125,250 | 500 |
| One Buy-to-mail append per 0.21 seconds | 500 | 125,250 | 500 |

The existing bucket coalesces a single burst. Genuinely later metadata or
separated purchases still publish their new facts; those distinct publications
are expected. Rebuilding growing full lists entails cumulative copying in these
models. This is a remaining measurement target, not a proven native freeze cause
or evidence that updates may be dropped. The current built-in source changes do
not optimize this external-adapter path. These single exploratory operation
counts are not matched native performance runs or allocation-byte measurements.
