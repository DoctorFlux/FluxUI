# Cursor loot and fast pickup — 30 October 2026

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
