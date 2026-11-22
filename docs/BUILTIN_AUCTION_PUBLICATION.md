# Built-in auction snapshot preparation — 5 November 2026

## Sold listings with the Auction House closed

On 22 November the player reported that a buyer-found notification left the
listing in the built-in inventory after the sale. When FluxUI owns inventory,
Retail, Forever and Classic progression use Blizzard's `AuctionSold` auction
ID to remove exactly one saved listing and publish the corrected counts and
locations. The sale creates no item attachment, and the handler performs no
native auction query. The ID stays excluded from older scan results until a
subsequent owned-list update while the window is open.

Classic Era and Anniversary receive the localized item name in Blizzard's typed
notification. A matching legacy system message can use the same path. A closed
sale removes a listing when exactly one saved row matches and the names are
known. Identical names or missing names defer to the next authoritative owner
list. Legacy owner rows marked sold are excluded even while Blizzard displays
them as pending delivery. A sale correction preserves the order and metadata of
the surviving records, including older sparse saves. Syndicator retains
ownership when its provider is ready.

The selected source revisions declare the typed event with an optional ID on
[Retail 12.1.5.70961](https://github.com/Gethe/wow-ui-source/blob/ab5cb850a3f65e742959e379c4689353a2f4549f/Interface/AddOns/Blizzard_APIDocumentationGenerated/AuctionHouseDocumentation.lua#L1248),
[Forever 1.60.1.71037](https://github.com/Gethe/wow-ui-source/blob/734f065329cff4992835b01a84f210a297db91b6/Interface/AddOns/Blizzard_APIDocumentationGenerated/AuctionHouseDocumentation.lua#L1264)
and [Classic progression 5.5.4.71060](https://github.com/Gethe/wow-ui-source/blob/e171ae99b8e582ce9547bd8fc87054fe2e348f20/Interface/AddOns/Blizzard_APIDocumentationGenerated/AuctionHouseDocumentation.lua#L1197).
Retail and Forever route it outside the Auction House. The loaded Classic
progression UIParent has no registration, so its closed-window delivery to
addons needs native confirmation.
[Retail router](https://github.com/Gethe/wow-ui-source/blob/ab5cb850a3f65e742959e379c4689353a2f4549f/Interface/AddOns/Blizzard_Game/Mainline/EventRouting.lua#L15),
[Forever router](https://github.com/Gethe/wow-ui-source/blob/734f065329cff4992835b01a84f210a297db91b6/Interface/AddOns/Blizzard_Game/Mainline/EventRouting.lua#L15),
[Classic progression UIParent](https://github.com/Gethe/wow-ui-source/blob/e171ae99b8e582ce9547bd8fc87054fe2e348f20/Interface/AddOns/Blizzard_UIParent/Mists/UIParent.lua#L138).

The Era and Anniversary UIParents register the event globally and format its
item-name argument for chat. Their legacy owner rows expose sold status in
return 16 and provide no auction ID.
[Era 1.15.9.70576 router](https://github.com/Gethe/wow-ui-source/blob/4192ac60067fc55566182291bc67c85dd9b6794d/Interface/AddOns/Blizzard_UIParent/Vanilla/UIParent.lua#L792),
[Era owner rows](https://github.com/Gethe/wow-ui-source/blob/4192ac60067fc55566182291bc67c85dd9b6794d/Interface/AddOns/Blizzard_AuctionUI/Classic/Blizzard_AuctionUI.lua#L1713),
[Anniversary 2.5.6.70577 router](https://github.com/Gethe/wow-ui-source/blob/68e0a2ec559d9761dfc4e7f864c3944f9d758a49/Interface/AddOns/Blizzard_UIParent/TBC/UIParent.lua#L800),
[Anniversary owner rows](https://github.com/Gethe/wow-ui-source/blob/68e0a2ec559d9761dfc4e7f864c3944f9d758a49/Interface/AddOns/Blizzard_AuctionUI/Classic/Blizzard_AuctionUI.lua#L1713).

The external `fluxui-sold-auction-before-20261122T082204Z` checkpoint verifies
15 source and continuity files, complete main history at `1e992c4` and 44
on-disk settings metadata entries. Auctions.lua SHA-256 changed from
`b0e9e407d70d616f2c0a65a575d5d20a5bd17672d7b88f44c75a3ea048c3f797` to
`d8266787b2ec7c79780f0494cab5d9699cd1b7d9ebf9f1ae8f893714ec60b0e8`.
All five installed files compile and match the candidate hash. The archived
source reproduces 54 failures in each of three paired replays. The candidate
passes 6,264 checks across ten client/provider profiles in each replay. Maximum modeled scan work
stays at 104 with zero reentry errors and zero new normalized rows on unchanged
scans. A confirmed sale rebuilds the saved auction snapshot once. The normal
owned-scan path retains its 32-read and 1 ms budgets. Real sale delivery and
native timing remain pending. [Client checks](CLIENT_VALIDATION.md#built-in-sold-auction-counts).

## Reproduced work and failure

The native owned-row scan limited each update to 32 reads or approximately 1 ms,
but its final ApplyList fingerprinted the complete list, cleared the published index
and allocated every normalized snapshot record in one update. A real-module replay
with 5,000 rows kept native reads at 20–21 per simulated update, then performed
5,000 fingerprint iterations; a changed list also cleared and created 5,000 rows.
Fifty simultaneous owner updates correctly coalesced to one scan, but did not
bound that final preparation. This is a reproduced Lua work boundary, not proof
of the reported native whole-game freeze.

A second reproduced failure occurs when a native count/row getter synchronously
delivers an owner update, close or provider handoff. The old callback could keep
using a discarded global scan, publish the wrong count generation or continue
reading after ownership ended. Row-triggered refresh and close caused nil-scan
errors in the baseline replay.

## Change and invariants

The same scan job now prepares its private normalized index and counts after
each accepted native row, before checking the existing time/row budget. Comparing
ID, quantity and auction ID against the last accepted list replaces the final
fingerprint loop and concat. Auction IDs retain the original numeric/string
coercion when their values differ. Original equality intentionally ignores links,
expiry, icons and quality alone; this change does not silently add publications
for metadata-only updates. Saved listing fields remain unchanged.

Unchanged normalized rows reuse their previous records without mutation. The
last accepted list is the same table already assigned to the character ledger;
no additional persistent row-string array is introduced. Completed changed jobs
swap their index/count maps, increment generation and notify once. Unchanged jobs
leave the published maps, generation, saved list and notifications alone. The
first empty capture still publishes; subsequent empty captures are unchanged.

The auction region object stays stable. Its internal byIndex map now changes
identity on a changed completed generation. This intentional internal ownership
change permits atomic publication without an unbounded copying loop. Repository
inspection found only inventory producers and on-demand Index readers of this
map; GetSnapshot exposes bags/bank/warband/equipment, not auctions. Public counts,
Find results, locations and generation readers continue to use completed data.
Incomplete generations never modify the published maps or their records.

Each native source-fact getter returns to a local job-identity and provider check
before any further source read, preparation or publication. Legacy reads also
check between the primary item getter and its optional missing-ID link fallback;
ordinary fallback data remains supported. Reentrant refresh preserves its newer
queued generation; close discards the old job; source handoff stops owned work.
The existing 0.15 s quiet time, 0.6 s maximum debounce, 32-row/1 ms budget, native
query trigger/latch, active-row filtering and close/reopen behavior remain.
There is no new frame, timer, poller, global replacement, setting or framework.

## Exact baseline and desktop checks

Baseline: `437fda79136582282dde0f3989f3cb70c4411bad`; Auctions.lua SHA256
`7737d3b022b03c334b3f914854472be1ffbfe4faddbf0da7f660da2eb82b0c8a`.
The verified external Mail-auction-publication-20261105T173546Z checkpoint covers
1,503 actual files, 122 accessible on-disk settings and all-ref history. Source
archive SHA256:
`4921e61d4bce4f648bd95b428f7a0acea9eb11dfc99b0c66d1d5b32fd9a31f48`.
Private settings and selective baseline fixtures remain outside AddOns and Git.

```powershell
lua tests/builtin_auction_publication.lua
lua tests/builtin_auction_publication.lua '<checkpoint>/Auctions-baseline.lua'
lua tests/auction_query_ownership.lua
lua tests/deferred_inventory_handoff.lua
lua Inventory/_tmp_inventorylag_smoke.lua
```

The focused regression loads the real auction source and public Index reader.
Five client labels, each standalone/provider-pending, exercise 1,024-row initial,
unchanged and changed 50-event bursts; coherent private preparation; saved fields;
metadata equality and auction identity; first/repeated empty lists; slow getters;
profiler absence; filtered rows; count/row getter reentry; legacy missing-ID link
fallback and its close/handoff/refresh guards; between-frame restart;
close and reopen. Provider readiness and native API behavior are mocked; labels
are not independent native-client or real Syndicator acceptance.

| Metered scope across the ten models | Baseline | Candidate |
| --- | ---: | ---: |
| Unchanged-completion fingerprint row visits | 10,240 | 0 |
| Maximum metered operations in one update | 5,216 | 104 |
| New normalized records during identical refreshes | 0 | 0 |
| Getter-triggered refresh/close Lua errors | 20 | 0 |
| Initial plus changed-list publications | 20 | 20 |

The work metric counts mocked native reads, numeric conversions, fingerprint
iterations, normalized-map writes and clears. It is deliberately not a count of
every Lua instruction or a native time estimate. Mocked native reads cost 0.02 ms,
numeric conversions/clears 0.005 ms and map writes/fingerprint visits 0.01 ms in
the budget clock. A separate slow-getter case uses 0.6 ms/read. The candidate
passes 5,884 checks; the exact baseline fails 144 of 5,436 dynamic checks. Totals
differ because incomplete-generation checks run once per simulated update.
Existing query ownership passes 628, deferred handoff 210 and inventory smoke
1,732 checks. The [raw comparison](validation/builtin-publication-comparison-2026-11-05.json)
records five alternating pairs per scenario and eight rejected mutations across
both sources. The [full report](validation/builtin-publication-2026-11-05.json)
passes 147 scripts and 802 Lua syntax checks and identifies the complete corpus.

## Limits and native acceptance

Staging adds a temporary index/count map during every scan, including unchanged
ones; it trades peak map storage and incremental work for removal of the final
full-list preparation burst. Changed scans can reuse unchanged normalized rows.
No total allocation-byte, retained-memory-byte or overall CPU reduction is claimed.
An individual native getter can itself exceed the budget; this code cannot
preempt it. Store.MarkPending and inventory listeners retain their existing work
and must not be described as bounded by this scan. Repeated invalidations still
restart an incomplete scan as before rather than publishing partial ownership.

This affects built-in owned-list observation, not Blizzard buying/posting/selling
or cancellation commands. Buy-to-mail delivery and mail collection are separate
stages. Native auction operations, mailbox transitions, frame times, memory/leak
behavior, secure behavior, taint and pixel parity remain pending across the five
pinned clients and provider/bag combinations in [the flow record](MAIL_AUCTION_REWORK.md).
No game input, enable-flag change or profiling was used for this work. Keep the
game in the background; no freeze cure is established by these desktop results.
