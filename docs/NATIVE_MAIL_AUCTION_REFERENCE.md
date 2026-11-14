# Native mailbox and auction reference — 5 November 2026

13 November workflow follow-up: [AHR-57–64](AUCTION_RESTOCK.md#integrated-restock-workflow-13-november-2026)
rechecks MAIL_FAILED/native-command/OpenAll timer contracts at the current five
pinned source identities in [workflow evidence](validation/auction-workflow-2026-11-13.json).
Forever now uses bebcb6bf309cf41b41bd74f8ca651e6a105b2676 for this source check;
the older70790 observations below remain historical. Complete empty inbox proof
clears collection HUD; partial loaded subsets cannot clear inaccessible mail.
No native behavior/performance observation is added by these source checks.

The current [rework matrix](MAIL_AUCTION_REWORK.md) separates all requested flows,
desktop fixes and pending native checks. The loaded-state observations below
belong to the earlier approved session; later probes observed an unloaded state
and the process changed again. None verifies the current candidate or measures
the reported freeze.

The user reports the current Forever mailbox/auction freezes with Syndicator
unloaded. Installed reference code and provider-labelled desktop fixtures do not
establish the active provider. Earlier approved native reload/read-only
diagnostics separately confirmed Forever 1.60.1, build 70790, interface 16001,
FluxUI loaded and Syndicator unloaded. This source review is not a native latency
measurement or acceptance of the reported freezes.

## Pinned source scope

These are the commits already resolved for this task, rather than moving-branch
content. The mail file was fetched at every listed commit; modern or legacy
auction files were also fetched for the respective clients.

| Client/build | Commit | Native mail implementation |
| --- | --- | --- |
| Forever 1.60.1.70790 | `eac30af597e5aaa43a60f6675ef5fdcea100375f` | [MailMixin and OpenAllMailMixin](https://github.com/Gethe/wow-ui-source/blob/eac30af597e5aaa43a60f6675ef5fdcea100375f/Interface/AddOns/Blizzard_MailFrame/MailFrame.lua) |
| Retail 12.1.5.70783 | `297d7aaaa736f346b3e036f38ee088eaf7f8c07f` | [Global mail handlers and OpenAllMailMixin](https://github.com/Gethe/wow-ui-source/blob/297d7aaaa736f346b3e036f38ee088eaf7f8c07f/Interface/AddOns/Blizzard_MailFrame/MailFrame.lua) |
| MoP 5.5.4.70631 | `e5d9b3a22c3f0f6f41ebac0e454f4969594261cf` | [Classic MailFrame](https://github.com/Gethe/wow-ui-source/blob/e5d9b3a22c3f0f6f41ebac0e454f4969594261cf/Interface/AddOns/Blizzard_UIPanels_Game/Classic/MailFrame.lua) |
| Era 1.15.9.70576 | `4192ac60067fc55566182291bc67c85dd9b6794d` | [Classic MailFrame](https://github.com/Gethe/wow-ui-source/blob/4192ac60067fc55566182291bc67c85dd9b6794d/Interface/AddOns/Blizzard_UIPanels_Game/Classic/MailFrame.lua) |
| Anniversary 2.5.6.70577 | `68e0a2ec559d9761dfc4e7f864c3944f9d758a49` | [Classic MailFrame](https://github.com/Gethe/wow-ui-source/blob/68e0a2ec559d9761dfc4e7f864c3944f9d758a49/Interface/AddOns/Blizzard_UIPanels_Game/Classic/MailFrame.lua) |

The Forever/Retail mail TOCs load the mail Lua/XML pair. The Classic UI-panels
TOC includes Classic MailFrame. The inspected MoP modern-auction TOC allows its
progression game type; the Era/Anniversary legacy-auction TOCs load the Classic
auction implementation. A file also existing in a shared tree does not establish
that it loads on every client. Original Wrath and historical progression builds
are not certified by this review.

## Mail contracts and FluxUI comparison

All five inspected mail implementations use the fifth `GetInboxText` return for
invoice detection and define sixteen receive-attachment slots. FluxUI's current
Copy/Forward availability check uses the correct invoice position; its selected
loot loop uses the client receive limit, and built-in inventory capture honours
the larger receive/attachment constants. Do not hardcode twelve receive slots
from older examples.

Forever's `MAIL_INBOX_UPDATE` handler updates InboxFrame and OpenMailFrame methods;
Retail and the inspected Classic implementation call the equivalent globals.
FluxUI retains the existing method/global hook paths. The event may therefore
lead to both native painting and addon refresh work. Native painting is not an
excuse to replace those global APIs or repeatedly generate full copy/invoice text.

Every inspected native OpenAll implementation waits for
`C_Mail.IsCommandPending()` before advancing after its minimum retrieval delay.
Forever's [generated declaration](https://github.com/Gethe/wow-ui-source/blob/eac30af597e5aaa43a60f6675ef5fdcea100375f/Interface/AddOns/Blizzard_APIDocumentationGenerated/MailInfoDocumentation.lua#L51)
defines a non-nil boolean return; the corresponding declaration was also read at
the other four pins. FluxUI currently confirms its own selected action by header
or attachment changes and waits the configured OpenSpeed. Whether a header can
change while the native command remains pending needs an isolated regression and
native observation before changing that state machine. This was subsequently reproduced as a worker overlap contract failure and
corrected in the [native command readiness phase](MAIL_NATIVE_COMMAND.md).
It remains an unproven cause of the user's freeze.

FluxUI's completion notices update the existing buttons and visible row controls;
the close earnings notice reads money and prints once. Those paths do not request
a full inventory scan. The built-in inbox source already debounces updates, yields
at its frame budget and retains only complete captured generations. Existing
desktop checks do not establish the cost of the underlying native APIs.

## Auction contracts and FluxUI comparison

The pinned [Forever](https://github.com/Gethe/wow-ui-source/blob/eac30af597e5aaa43a60f6675ef5fdcea100375f/Interface/AddOns/Blizzard_AuctionHouseUI/Shared/Blizzard_AuctionHouseAuctionsFrame.lua#L190),
[Retail](https://github.com/Gethe/wow-ui-source/blob/297d7aaaa736f346b3e036f38ee088eaf7f8c07f/Interface/AddOns/Blizzard_AuctionHouseUI/Shared/Blizzard_AuctionHouseAuctionsFrame.lua#L190)
and [MoP](https://github.com/Gethe/wow-ui-source/blob/e5d9b3a22c3f0f6f41ebac0e454f4969594261cf/Interface/AddOns/Blizzard_AuctionHouseUI/Shared/Blizzard_AuctionHouseAuctionsFrame.lua#L190)
owned-list handlers reset/refresh their lists on `OWNED_AUCTIONS_UPDATED`.
Cancellation and a new bid request a native search refresh. Their data provider
reads owned records and counts; the native frame owns querying and UI selection.
The pinned [Era](https://github.com/Gethe/wow-ui-source/blob/4192ac60067fc55566182291bc67c85dd9b6794d/Interface/AddOns/Blizzard_AuctionUI/Classic/Blizzard_AuctionUI.lua#L1542)
and [Anniversary](https://github.com/Gethe/wow-ui-source/blob/68e0a2ec559d9761dfc4e7f864c3944f9d758a49/Interface/AddOns/Blizzard_AuctionUI/Classic/Blizzard_AuctionUI.lua#L1542)
legacy UI uses `AUCTION_OWNED_LIST_UPDATE` instead. FluxUI's built-in source retains
its capability-selected modern/legacy readers and bounded event-driven scanning.

Forever's [generated auction events](https://github.com/Gethe/wow-ui-source/blob/eac30af597e5aaa43a60f6675ef5fdcea100375f/Interface/AddOns/Blizzard_APIDocumentationGenerated/AuctionHouseDocumentation.lua#L1262)
mark formatted notifications and owned-list updates synchronous; the optional
auction ID in a formatted notification is nilable. That supports deferring
redundant cache work, but does not prove which callback exhausted an execution
budget. A sold notification and a full owned-list refresh are distinct scenarios.

`HasFullOwnedAuctionResults` is not a universal instruction to withhold all
visible rows. The native [item list](https://github.com/Gethe/wow-ui-source/blob/eac30af597e5aaa43a60f6675ef5fdcea100375f/Interface/AddOns/Blizzard_AuctionHouseUI/Shared/Blizzard_AuctionHouseItemList.lua#L346)
uses it to distinguish pending from empty when the result count is zero. Do not
add a blanket full-results gate based only on the function's name.

## Local Syndicator comparison and next evidence

Syndicator 289 was inspected read-only at the user's supplied Forever location.
Its license says All Rights Reserved. No code or assets were copied. Modern
sales/cancellations update matching auction IDs incrementally; cancellations and
expiry also append the returned item to cached mail. Its initial modern owned-list
query waits for the native throttle-ready event. Full owned-list rebuilding still
emits per-row callbacks, and its next-update mailbox scan still walks the inbox
synchronously. These source facts do not establish that Syndicator never lags.

FluxUI's built-in source queries on auction interaction show and already batches
subsequent listing reads. Query readiness should be measured separately from mail
closing or a sale notification. The current disabled-provider failure cannot be
attributed to the external adapter merely because that adapter also had excessive
work. No additional runtime change was made for this reference review.

Next native checks must distinguish idle mailbox open/close, invoice display,
money/item collection, posting/cancellation, and naturally observed buyer sales.
Record enabled addons, source, errors before reporter warnings and matched
CPU/frame-time samples. Preserve profiling preferences and existing diagnostics.
See [the current fixes and evidence](RAID_MAIL_AUCTION_FOLLOWUP.md) for desktop
regressions and the remaining native acceptance limits.
