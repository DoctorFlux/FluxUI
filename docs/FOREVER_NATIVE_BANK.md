# Forever Blizzard bank ownership

The user supplied a repeated ADDON FORBIDDEN PurchaseBankTab stack and requested
that Forever use Blizzard's bank. Camelot BankFrame.SetTab invokes PurchaseFirstSlot
on opening: the native function purchases a free first character tab when available.
The local read-only source at Blizzard_UIPanels_Game/Camelot/BankFrame.lua lines199-205
matches that path. The stack proves the blocked native operation, but does not
identify the first taint write. A current pinned online fetch was unavailable;
no upstream code or API implementation was copied/replaced.

## Intentional ownership change

Forever's native BankFrame is now blacklisted by FluxUI's existing mover policy.
This skips drag handles, mouse adjustments, layout wrappers, OnShow hooks and
saved placement application. Existing saved mover records remain stored.
Inventory's BankFrame OnShow/OnHide fallback latch hooks are skipped on Forever;
BANKFRAME_OPENED/CLOSED and banker interaction events retain inventory access and
provider tracking. The classic combined bank already excludes Forever.

The junk overlay no longer registers native bank open/page/item-mixin/frame hooks
or enumerates native bank item pools on Forever. Its service treats that bank as
not a paint target; normal carried-bag junk/protection displays remain available.
The bank restock control does not parent/anchor into Forever's Blizzard bank and
does not schedule its native attach retries. Optional Baganator views retain their
existing integration; other addons are not disabled or reconfigured. Inventory
tracking, saved settings, restock data and other clients remain intact. Bank UI
movement/decorations/native restock controls are the user's intentional exception
to previous UI parity. There is no replacement bank window on Forever.

PurchaseBankTab, BankFrame mixins and purchase confirmations remain Blizzard's.
No protected API is replaced, auto-called, bypassed or hidden with broad pcall.
No bank tab was bought by these tools. Existing hooks/taint cannot be removed
from an already loaded session: sync and /reload are required before testing.
Guild-bank and void-storage callbacks remain outside scope.

## Recovery and validation

Baseline main8574e06716274d6970a79d298ab57637d72b20fe. Verified dated external
Forever-native-bank-20261105T100524Z preserves1,448 actual files (including the
pending guide edit/evidence), Git history and123 available on-disk settings.
Source ZIP SHA256:
`d886e59811e561a1fec56c3d2f003fbc5762a5b1c08d2abcd4117ba56c99145b`.
Archives remain outside AddOns; unsaved in-memory game settings are not included.

[Comparison, exact runtime hashes and raw pairs](validation/forever-native-bank-comparison-2026-11-05.json).
[Full report/source manifest](validation/forever-native-bank-2026-11-05.json).
[Behavior regression](../tests/native_forever_bank.lua).

Five alternating fresh-process pairs: baseline36 failures versus candidate0 per168
checks. Real mover catalog, junk module, inventory latch/event block and restock
attach/open functions run under mocked frames/APIs, with two Forever identity
aliases and four other client labels, each labeled builtin/Syndicator. Keyboard
mode is tested so gamepad-only suppression cannot mask the missing policy.
The checks verify no Forever bank hooks/parent writes/attach retries, while bag
hooks, other windows/clients and bank access events remain active. Provider labels
do not certify native provider handoff. Full129 scripts/784 syntax files pass.

Zero warm-up; one deterministic scenario per fresh process. Wall samples include
interpreter startup/assertions and are not native latency. No new timers/frames/
hooks or always-on profiling service; bank UI hooks/registration work are removed.
No CPU/FPS or leak improvement is claimed from the desktop checks.

## Native acceptance pending

After sync and /reload, open the same banker in Forever with mouse/keyboard first,
then gamepad UI if used. Confirm a wholly Blizzard bank window with native position,
size, tabs, bag equipment, paging, money and purchase controls. Test open/close/
reopen, character/account bank modes, ordinary bank transfers and carried-bag junk
indicators. Record exact GetBuildInfo, profile/addon list and any native error.
Use both builtin inventory and Syndicator; if Baganator is installed, distinguish
its own UI ownership from FluxUI's native-window exclusions.

The free initial-tab path must run without ADDON FORBIDDEN on an eligible character;
paid purchases require the user's intended confirmation and are not automated.
Test combat/recovery and verify bank access updates after close. Match screenshots
and check taint. No connected in-game tool is available here; candidate native
purchase/secure/pixel acceptance is pending. If the same forbidden operation remains
on a fresh reload, capture the first taint write and compare other enabled addons
rather than assuming the supplied native stack identified a culprit.
