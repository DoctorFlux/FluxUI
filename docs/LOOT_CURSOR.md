# Cursor loot and fast pickup — 30 October 2026

Delayed-source correction (30 October): a mob/chest loot session now keeps its
opening cursor position for 30 seconds after LOOT_CLOSED. Captured item links
and stack counts route late self-loot chat to the matching session, even after
another source has been opened; slot and chat reports of the same pickup still
produce one row. Captured currency IDs and money slot types similarly route
late currency and money messages. When FasterLoot empties a window before a
slot link can be captured, one unmatched item message may use that window's
saved origin. Sessions are bounded to 32 and expire after 30 seconds. This
does not change the three-second time a visible alert stays on screen.

The desktop fixture covers two closed sources with reversed late item chat,
ten-second-late chat after a slot alert, an uncaptured FasterLoot window,
late currency and money after another source, and expiry before later bag
gains. Full validation passes **108 scripts / 752 Lua syntax files**:
[result](validation/loot-delayed-source-full-2026-10-30.json).
[Exact runtime hashes](validation/loot-delayed-source-source-hashes-2026-10-30.json)
identify the candidate against main `57a252e0e2b467cf7788c3f52aa5d1dd8d83779e`.
Pre-edit source was preserved outside AddOns in
`flux-loot-before-delayed-source-20261030.zip` (SHA256
`4A408D72331229F1EE185D0D0C0EF6083E283D9DD2BCF65F8CC19571FE2B4864`)
beside the verified history bundle. WoW chat does not supply a loot-source
identity for an uncaptured slot or linkless currency line; if several such
sources remain pending, the oldest eligible session is used and placement
can be ambiguous. Native event order, placement, UI scale, taint, pixels and
frame time remain pending on all five clients.

Cursor-position correction (30 October): the user wants loot to remain where
the cursor was when the mob was looted, even after moving the cursor. The
previous `Show` path read `GetCursorPosition` for every alert and moved one
shared anchor, so a later item or a second loot batch could move earlier
rows. FluxLoot now captures an origin when LOOT_READY/LOOT_OPENED starts a
loot window. Slot, item-chat, money and currency rows from that window use
that origin; LOOT_OPENED does not resample after LOOT_READY. Each row retains
its origin in UIParent coordinates, so a new loot window can start elsewhere
without moving still-visible rows. Bonus/group-roll alerts and Preview use
the cursor position at their own alert event. The snapshot is at the native
loot event, whose timing relative to the physical click awaits client proof.

The focused fixture moves the cursor between LOOT_READY, LOOT_OPENED, slot,
chat and LOOT_CLOSED events, then starts another overlapping loot window.
It checks both batches stay at their original coordinates and later currency
chat uses the first window's origin. Full desktop validation passes **108
scripts / 752 Lua syntax files**, zero failures:
[raw result](validation/loot-cursor-pin-full-2026-10-30.json).
[Exact runtime hashes](validation/loot-cursor-pin-source-hashes-2026-10-30.json)
identify this candidate against main `57a252e0e2b467cf7788c3f52aa5d1dd8d83779e`.
Pre-edit source was preserved outside AddOns in
`flux-loot-before-cursor-pin-20261030.zip` (SHA256
`E5DD06156DB5EDFF1E35C3B4941F4957933AA2D3C890BCF992565CA30856CD4C`)
beside the verified history bundle. Native position, pixel, taint and
frame-time checks remain pending on five clients. Unrelated stance work in
the shared worktree was preserved.


Loot-source correction (30 October): the user reports alerts for items they
create or otherwise receive in bags. Crafted (`LOOT_ITEM_CREATED_SELF`) and
pushed/rewarded (`LOOT_ITEM_PUSHED_SELF`) chat lines are no longer accepted.
Ordinary self-loot chat now requires a matching captured loot session, with a
bounded fallback for slots emptied before capture. Direct loot-slot clears,
bonus rolls and won group rolls remain valid loot. Currency chat is shown
only during that same loot-window period unless a captured currency ID matches
a pending session; currency slot links are not treated as item rows. The
one-second grace covers linkless chat emitted just after LOOT_CLOSED;
a separate currency gain in that interval could still look like loot, and
native event ordering remains to be checked. Money already uses only native
"You loot" / split-loot messages and is unchanged. No bag-update scanner or
new setting was added.

The focused desktop fixture checks crafted and pushed gains both inside and
outside a loot window, ordinary bag gain outside, direct slot loot, bonus/
group rolls, currency inside/outside/just after the window, and currency
slot exclusion. Full desktop validation passes **108 scripts / 752 Lua syntax
files**, zero failures: [raw result](validation/loot-source-filter-full-2026-10-30.json).
[Exact runtime hashes](validation/loot-source-filter-source-hashes-2026-10-30.json)
identify the candidate against main `57a252e0e2b467cf7788c3f52aa5d1dd8d83779e`.
The pre-edit source was preserved outside AddOns in
`flux-loot-before-source-filter-20261030.zip` (SHA256
`4050CF47DB98740AC9C4A64A74EB1E3242D90A1795C0B42779454CD791FD5B00`);
the dated Git history bundle verified with SHA256
`3CCA4322B0D86E4D61FDF1D8509D43951EC0C9CC9C8047CCD352369D7009F9CC`.
Native source classification, event order, pixels, taint and frame time are
pending across the five supported clients. Unrelated stance work in the
shared worktree was preserved.


AceDB callback correction (30 October): the user supplied a native startup
stack trace at `Other/FluxLoot.lua:402`. FluxLoot passed the database table
as CallbackHandler's receiver, shifting the event name into a table argument.
The handler now registers `FluxLoot` as receiver, the event string second,
and `FluxLoot.Refresh` as the method, matching existing FluxOptions usage.
Expected result: login emits no callback registration error, and profile
change/copy/reset refreshes loot event ownership. The focused fixture first
reproduced the old registration failure and passes with the fix; it also
invokes profile change, copy and reset callbacks. Full desktop validation passes 107 scripts
and 751 Lua syntax files with no failures:
[raw result](validation/loot-callback-fix-full-2026-10-30.json).
[Candidate runtime hashes](validation/loot-callback-fix-source-hashes-2026-10-30.json)
identify the corrected source. The pre-fix uncommitted source was preserved
outside AddOns in `flux-loot-before-callback-fix-20261030.zip`, SHA256
`A92D826A9F9D4612E9087CA29C8F4251ED76A5C2A7E32B14064E47D918879785`,
beside the verified Git history bundle. Native post-fix login and profile
switching remain pending on all five clients; the user's stack proves the
pre-fix failure only.

Money alert follow-up (30 October): the prior money row repeated the localized
chat sentence with a generic coin icon and gold-colored text. A received-money
message now parses the client's own money templates and shows only nonzero
denominations as white numbers followed by gold/silver/copper coin symbols.
The leading icon is copper below 1 silver, silver from 1 silver to below 1
gold, and gold from 1 gold upward. Unmatched or zero money messages produce
no row. This reuses the same MoneyFrame coin art as Flux vendor chat; item and
currency alert styles are unchanged. The focused desktop fixture covers
99 copper, exactly 1 silver, 99 silver 99 copper, exactly 1 gold, mixed
denominations, a localized plural form, a guild message whose amount is the
second formatted field, white number color and non-loot chat.
Full desktop validation passes 107 scripts / 751 Lua syntax files with zero
failures: [result](validation/loot-coin-art-full-2026-10-30.json).
[Exact runtime hashes](validation/loot-coin-art-source-hashes-2026-10-30.json)
identify this candidate. The pre-edit source and history are preserved in the
external `flux-loot-before-coin-art-20261030.zip` (SHA256
`57C4F452467D79AF2E8CA01246CFC949D9B3186CBEA562A28F8C07388B52CFFE`)
and verified Git bundle. Native locale strings, coin art, color, pixels and
frame time remain pending on all five supported clients.

Default follow-up (30 October): Fast loot and cursor alerts both default on
for all five supported clients. The duration control reads **Disappear after
(seconds)** and defaults to 3 seconds. Existing saved choices are preserved.
The installed FasterLoot still owns pickup while it is loaded; the Flux fast
path takes over when that separate addon is disabled. The pre-follow-up
source is preserved in the dated external
`flux-loot-before-defaults-20261030.zip` archive (SHA256
`6DC240D3B1D35BE4A5288E27BD2DA6ACC3B4A0B506257ABA31C0C1E774D51C45`)
beside the verified Git history bundle. The focused desktop fixture now
checks the actual default table, duration control and three-second expiry.
The full desktop runner passes 107 scripts and 751 Lua syntax files with no
failures: [follow-up result](validation/loot-cursor-defaults-full-2026-10-30.json).
[Follow-up runtime hashes](validation/loot-cursor-defaults-source-hashes-2026-10-30.json)
identify the exact candidate; native checks remain pending.

## Player behavior

The **Tools → Loot** page offers independent Fast loot and Show loot at cursor
switches. The latter has money, currency, minimum item quality (All to Epic),
2–8 second duration and Preview controls. Up to three non-clickable rows show
beside the cursor's position at the pickup; older rows expire. Settings use
the existing AceDB profile. Both switches default on across the five supported
clients, and the duration defaults to 3 seconds. If the separate FasterLoot
addon is loaded, it owns fast pickup regardless of the Flux switch. To control
fast pickup from FluxUI, disable the separate FasterLoot addon in the game's
addon list.

Fast pickup follows the existing FasterLoot logic: LOOT_READY, Auto Loot
modifier, 0.3-second guard, TSM destroy-button guard, reverse slot order.
It does not change the loot window, Auto Loot CVar or secure click bindings.
Alerts capture loot slots before pickup, reconcile slot clears with self loot
chat, and use chat as a fallback when another addon empties the window first.
The display uses the existing Flux item service. Money parses the client's
localized message into coin symbols; currency retains localized text. Disabled alerts unregister their events,
hide their rows and clear their transient capture state. The visible-only
OnUpdate expires at most three rows and stops when all rows expire.

## Sources and ownership

- Baseline: clean local main `b68f2545fa53e83a7eb8482b73e2c0569ecdcc38`.
  Verified external Git bundle at
  `C:\Users\mario\.codex\visualizations\2026\10\30\01a18e07-9feb-70f0-b8c4-361d32bca360\flux-loot-baseline-20261030.bundle`,
  SHA256 `796523715D5AE09B5C314FB1F2504E438A40FE01F9EFB0B507988A48A6782ED3`.
  The present Retail account FluxUI saved variables were inspected read-only;
  no loot settings existed. No WoW process was visible. No settings were changed.
- Initial candidate identity: [five runtime file SHA256 hashes](validation/loot-cursor-source-hashes-2026-10-30.json)
  against that baseline. The follow-up candidate is identified above.
- [FasterLoot local source](../../FasterLoot/FasterLoot.lua), version
  `20261016`, SHA256 `5A1863A2C27DF5FEA5BD44E6C5DB089816604FDEA81722F54C5E1650B1F2A2B0`;
  TOC SHA256 `6E8AB034DD044877023FEAD889AB18DD69BAE7FA53D427BD27373A812ECBE0EF`.
  Inspected read-only; license not supplied, no code copied.
- [Looti repository](https://github.com/FinMckinnon/Looti), version `4.1.2`
  TOC blob `364ee2113888702b4f0fd8d38f7cf3cba24ea082`;
  [event source](https://github.com/FinMckinnon/Looti/blob/main/Notifications/Looti_Events.lua)
  blob `f4df46b288611c05c600ec0d0239d69f1ead3378`;
  [chat source](https://github.com/FinMckinnon/Looti/blob/main/Notifications/Looti_Chat.lua)
  blob `e0443b2864af703ebaa4182faa47c1cd6bd5f406`.
  Looti is MIT, copyright 2025–2026 Finlay McKinnon. This implementation
  uses its event coverage as a reference and keeps independent code and data.

## Checks and limits

`lua tests/loot_cursor.lua` passes event, duplicate, repeated pickup,
rarity, money, currency, toggle and fast pickup checks. The full desktop
runner passes 107 scripts and 751 Lua syntax files with zero failures:
[raw desktop result](validation/loot-cursor-full-2026-10-30.json).
The tested event model uses mocked client APIs. Native loot speed, frame
time, FPS, pixels, locale format variants, secure behavior and taint remain
pending on Era, Anniversary, MoP Classic, Retail Midnight and Forever. Test
sequentially in a background client, including the external FasterLoot on/off
case, group rolls and a rapid batch of identical items.
