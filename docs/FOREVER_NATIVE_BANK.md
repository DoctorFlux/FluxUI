# Forever Blizzard bank ownership

7 November default Blizzard bank direct UI lifecycle (BANK-NATIVE-06): user
renews the no-Baganator close/layering fix. Source audit proves a missed path:
restock inventory fireCloseIfGone suppresses its private close callback while
Bank.IsOpen stays true. Earlier tests always delivered that callback. The bank
button now uses BANKFRAME_OPENED/CLOSED directly through the existing shared
Flux.Events dispatcher for native UI, independent of that inventory latch. A raw
close hides immediately, invalidates delayed attaches and blocks manual/stale
inventory-open resurrection until the next real open. Private callbacks remain
for Baganator and as fallback if direct registration is unavailable. Two native
subscriptions, no new frame/timer/ticker/polling or native-script hook.
Native layering now uses at least HIGH and the highest parent/search/panel/close/
NineSlice strata; level clears those children as well as the root. Native parent
and left-of-search position remain. GetControl exposes the actual owned widget
for diagnostics; no command/settings change. Baganator footer remains intact.
1780 production checks across five clients/both owners/cold-warm merchant/direct-
events-fallback modes PASS. Includes suppressed inventory close, stale shown
flags, stale open callbacks, HIGH/DIALOG children and reopen. Native ownership168,
visible Baganator260 and combined33 per Era/Anniversary PASS. Prior checkpoint
rejects. Fresh Gethe Forever9dc84f0d3bbae1768ac3405b3716000bd93eda06 (1.60.1.70862)
verifies close function/events/search owner. Native visuals/open-close/purchase/
combat/taint/FPS remain pending; actual hovered-frame evidence still unavailable.
Fresh external source/history/45 on-disk settings metadata verified. No game,
foreground, WTF/profiler or manual-sync operation.
[Evidence](validation/bank-direct-lifecycle-2026-11-07.json).

7 November native bank owner investigation (BANK-NATIVE-05): user confirms
Forever after /reload still shows the control behind/detached from the window
and not disappearing on close. BANK-NATIVE-04 native acceptance is REJECTED;
its desktop checks do not establish actual-client behavior. No further runtime
layout change made yet. Read-only host enumeration confirms two running
_forever_/Wow.exe clients; installed bank source matches current workspace hash.
Available saved BugTabs has no bank/restock error entry, but is not live state.
The current source already parents its native control to BankFrame, making the
actual hovered frame/owner identity necessary before another speculative fix.
User requested to type /fstack, hover the visible restock control and provide
frame names, then disable /fstack. Await this evidence. No connected Witchcraft,
UIForever or computer-use tool exists; no foreground/mouse/keyboard/clipboard
control, game input or WTF/profiler writes. Fresh source/history checkpoint and
45 settings metadata entries verified outside AddOns. Native placement/layering/
hide/taint remain unresolved; preserve the Baganator footer and newer party work.

7 November native bank attachment (BANK-NATIVE-04): user reports the no-Baganator
button below the window and detached during opening/closing. Forever's control
was deliberately a UIParent sibling; it now uses the native BankFrame parent and
existing inside left-of-search anchor, inheriting visibility, movement and scale.
This supersedes the earlier UIParent parent restriction for this owned control.
Native scripts, purchases, mover and item decoration exclusions remain. Visible
ancestor checks hide stale/unattached controls on all clients. Existing two open
retries keep their cadence but use a close/reopen generation token, so stale
callbacks cannot resurrect a closed control. No new frame/event/hook/timer/ticker.
Baganator's full-size inside footer and existing settings/commands are retained.
828 production checks across5 clients/both owners/cold+warm merchants PASS,
including parent hide/show without callbacks, close/reopen retries, explicit
hidden-bank attachment and a shown frame under a hidden owner. Prior checkpoint
rejects; current code passes. Native ownership168/visibleBaganator260/combined33
per Era/Anniversary PASS. Fresh dated source/history/45 settings metadata entries
verified externally; no game/WTF/profiler/manual-sync operation. Existing pinned
Gethe9dc84f0d3bbae1768ac3405b3716000bd93eda06 source retains search/template evidence.
Native candidate placement/open-close/purchase/combat/taint/FPS remain pending;
no connected native tool.
[Evidence](validation/bank-native-attachment-2026-11-07.json).

7 November bank restock slot follow-up (BANK-ICON-02): user rejects the first
icon-only fix and the Forever outside-window placement. Baganator843's toolbar
uses32x22 buttons; resizing only the hit rectangle left fixed64px merchant slot
art at its36px design size. The whole36px control now scales uniformly to the
shorter toolbar edge, including icon, frame, highlight/push and auto toggle.
Native/combined handoff resets scale1. Transfer/Sort/Customise references work.
Forever remains an addon-owned UIParent child but is visually inside BankFrame,
RIGHT of button to LEFT of BankItemSearchBox,4px gap, vertically centered; this
supersedes the previous external TOPRIGHT placement. Native bank hierarchy,
scripts/purchase/movement/decorations stay untouched. Fresh Gethe Forever source
9dc84f0d3bbae1768ac3405b3716000bd93eda06 (1.60.1.70862) verifies Mainline template
and Camelot loading/search owner. Baganator read-only reference retains rights.
358 production geometry/lifecycle checks PASS across5 clients/both bag owners/
cold+warm merchant; prior checkpoint rejects. Native ownership168 and combined33
per Era/Anniversary PASS. Native candidate pixels/input/taint/FPS remain pending;
user screenshot reproductions retained; no connected client tool or game input.
External fresh source/history verified;45 on-disk settings metadata read-only.
No new frame/event/hook/timer/ticker. Existing bounded retries/click/drop/tooltip/
auto settings retained.
[Evidence](validation/bank-restock-slot-2026-11-07.json).

7 November update: the user now requests the bank restock button on every client
with and without Baganator. The restock control is available beside the native
Forever bank as an addon-owned UIParent child anchored outside its controls.
Only the previous restock suppression/retry exclusion below is superseded;
native BankFrame parenting, scripts, movement, purchase and decoration exclusions
remain. Candidate native visual/input/taint verification is pending. See
[bank icon evidence](validation/bank-restock-icon-2026-11-07.json).

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
