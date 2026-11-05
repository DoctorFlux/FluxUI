# Consumable refresh timer — 5 November 2026

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
