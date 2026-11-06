# Consumable refresh timer — 5 November 2026

## Immediate advance after aura gain — 6 November 2026

The button now advances to the next eligible configured item on the player
`UNIT_AURA` event when the preferred item changes, including after Well Fed
food or a temporary weapon enchant is applied. This selection change bypasses
the former 200 ms coalescing wait and update debounce. Unchanged aura events
still avoid an action rewrite. During combat the protected item change remains
queued until combat ends. If unit-scoped aura event registration is unavailable,
the button registers the ordinary `UNIT_AURA` event so older clients still
receive player aura changes.

Baseline main `ef813e0738fa69927bc4694123aea59c8dc2add6` waited for the
coalesced update and did not register a fallback in the legacy fixture. Five
paired loaded-module runs reproduce that baseline (11 checks each) and pass
the candidate (22 checks each) for modern and legacy aura APIs, immediate next
selection, unchanged aura events, combat deferral, and combat exit. The prior
refresh-timer and weapon-target fixtures pass 35 and 30 checks; all 845 Lua
files pass syntax checking. These are desktop results, not native latency,
secure-input, taint, pixel, or FPS measurements.
[Raw paired runs](validation/consumable-aura-advance-comparison-2026-11-06.json).

The prechange all-ref history bundle
`FluxUI-consumable-aura-advance-prechange-20261106.bundle` was verified outside
AddOns. `Consumables.lua` SHA256 changed from
`b0cf2c2ea787fc897e97470566ef29cc9b80f995b4dae0bf7ae88340cf37fd40`
to `3a4d889bde12f1675d3b43581bcb8d9a05bccbfe45a1519081f77078e22f9871`.
Installed Retail and Forever settings were inspected for presence read-only;
no settings or profiler preferences were changed. Native acceptance is pending
on Retail, Forever, Era, Anniversary, and Classic progression: consume food
with another configured item following it, observe the button at aura gain,
repeat with a weapon enchant, then check combat deferral and reload.

## Well Fed follow-up — 6 November 2026

Configured Well Fed food could show no refresh timer when the active food aura
used a spell ID outside the two hard-coded IDs. The fallback index scan also
stopped when the shared aura wrapper declined a readable player aura. The food
lookup now tries the client index API when that wrapper returns no aura, scans
for Well Fed, retains the complete aura duration/expiration/time modifier, and
reuses a discovered public spell ID on later checks. It also recognizes the
client's localized `WELL_FED` name when that string is available. The existing
refresh deadline (`expiration − threshold × time modifier`) is used without a
separate food timer. Restricted/secret aura values still cannot produce a
numeric countdown.

The focused loaded-module fixture first fails on main
`582d868e23c2513ef63251dd0b294df073cfd5c5` because configured food
cannot find an alternate Well Fed aura. With the fix it passes 35 checks:
alternate aura detection, learned ID reuse, a 25 minute food timer for a 30
minute buff with a 5 minute threshold, config/button countdowns, and clearing
the config countdown at the threshold. The weapon-target fixture passes 30
checks, and all 844 Lua files pass syntax checking. The documentation checker
still reports stale generated inventory for this change and concurrent raid
work, plus an unrelated missing raid validation link; no generated references
were rewritten during this isolated fix. The verified external history bundle
`FluxUI-well-fed-timer-prechange-20261106.bundle` preserves the prechange
main refs. `Consumables.lua` SHA256 changed from
`2cf0e95e831374f6b0f12de4f8e09703ed8816ee8f3a1cd854d884ab8543c6d2`
to `b0cf2c2ea787fc897e97470566ef29cc9b80f995b4dae0bf7ae88340cf37fd40`;
the focused fixture changed from
`2ecc3e511100e7e2471049018ee671b4b4b13c281220f2bd9c6ba7b85fe15c79`
to `c47cf1b9cc29c5722a7e2ca9810cbecfb7356d8683e352aacb05febc1afbc540`.
Retail, Forever, Era, Anniversary, and progression settings were
inspected for presence read-only; none were reset or copied. Native client
acceptance is pending. On each client, equip real Well Fed food, verify the
active buff above/at/below the threshold in the config and button, then repeat
after a reload, in combat, and with another food spell ID. Record the exact
food/aura IDs, build, and any errors before claiming native parity.

## Rule

The Consumables button and its config cells now show time until an active
buff becomes eligible to refresh: `buff remaining − refresh threshold`. For a
30 minute buff and a 5 minute threshold, the timer and swipe run for 25
minutes. They clear when 5 minutes of the buff remain; the buff itself has
not expired, and the item can be selected to refresh it. The item’s own
cooldown, including Chronoboon's separate item cooldown, retains its existing
behavior. The config tooltip may still report actual buff remaining under
that explicit label.

One shared `GetRefreshTimerInfo` result supplies the button countdown, wisp
lock swipe, and config cell timer. It uses the public aura expiration and
time modifier to place the deadline, and ignores a full-buff duration object
that would extend past the refresh point. If expiration is restricted as a
secret, no invented numeric timer is shown. Clearing an expired refresh
timer repaints the button's normal cooldown state. The refresh threshold
setting and buff eligibility rules remain unchanged. Editing the threshold
while the config is open refreshes its cell timers immediately.

## Evidence and limits

Baseline main: `2c0e7b89e3faa5b6d551a0130c5d499ed665fc2a`.
Baseline/candidate SHA256 for `Consumables.lua`:
`b4d5100232a8e1e0f86d72145c44faa3e7ef2d9d5ed7ea76a2b1fa551c5586f4` /
`2cf0e95e831374f6b0f12de4f8e09703ed8816ee8f3a1cd854d884ab8543c6d2`;
for `FluxConsumablesGridUI.lua`:
`3aacc36ada1de09ee891067cb2cdb77fa82111d309026377fee337ccc5353301` /
`a444bc60318885cdd833f72f39dab26a56c561e475839e1692e4b37c4ea9c28f`.
Baseline/candidate SHA256 for `ConsumablesConfig.lua`:
`6a5620341e7794e454b64dc317a7680d03cdd336cdafc02d47e4d5fb8806ea98` /
`694a0badbb554bc637f2eea3fb752f1e76965a99e8f4644adef49112134d160b`.
The verified all-ref `FluxUI-consumable-refresh-timer-prechange-20261105.bundle`
is outside AddOns and Git. Retail and Forever settings files were present and
inspected read-only; the previous external settings archive remains available.
No WoW process was found or controlled, and profiler preferences were untouched.

Five paired loaded-module fixtures reproduce the old full-buff timer (14
checks) and pass the candidate refresh timer (24 checks), including the
threshold boundary, time modifier, secret expiration, wisp swipe, config
cell, live threshold edit, button countdown, and Chronoboon control.
[Raw pairs and hashes](validation/consumable-refresh-timer-comparison-2026-11-05.json).
The [full desktop validation](validation/consumable-refresh-timer-2026-11-05.json)
passes 150 scripts and 805 Lua syntax files. During the work, a concurrent
mail/auction commit advanced main from `2c0e7b8` to `7f47a56`; the comparison
record separates the baseline source identity from the head at capture, and
the validation manifest records exact file hashes. These mocks do not
establish native pixels, secure behavior, taint safety, or frame time.

Native acceptance remains pending on Retail, Forever, Era, Anniversary, and
supported progression clients. Check a real buff above, at, and below the
threshold; change the threshold while the config is open; check the main
button, config cells, wisp lock, weapon enchant, Chronoboon, item cooldown,
reload, combat, tooltip, and visual layout. Capture build, addon list,
profile, UI scale, errors, profiler mode, and matched frame time before any
performance claim.
