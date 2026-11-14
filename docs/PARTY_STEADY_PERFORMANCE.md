# Party frame steady-state performance

9 November 2026 — PARTY-STEADY-PERFORMANCE-20261109; REQ-RF-97.
The user still reports substantial lag while grouped after the earlier
[roster optimization](GROUP_ROSTER_PERFORMANCE.md). This follow-up addresses
ongoing traffic in player-style party frames. Compact party/raid dispatch,
binding registration, secure visibility and roster batching remain unchanged.
Retail, Forever, Classic progression, Era and Anniversary remain required.

## Runtime changes and preservation

The shared dispatcher refreshed the complete name/class/spec/PvP/border layout
on health/resource traffic at up to four times per second per member. The party
wrapper also ran a full pet paint on every event, including heal prediction,
and reapplied text modes/cast cover after unrelated events. A global UNIT_PET
notification repainted every visible member and pet regardless of its owner.

The party wrapper now sends health, maximum health, power, resource type and
prediction events directly to the existing shared painters. Those painters
retain status colors, values, loss animation, absorbs, resource effects and
resource-presence partition changes. There is no new health/resource throttle,
value cache or secret-number comparison. Pet prediction events now reach the
prediction painter instead of repainting health. HP-only pets still omit power.

Full chrome refreshes remain on identity, availability, settings, world/show and
roster changes. Explicit level, faction, classification, specialization, inspect
completion and player-level events keep metadata current without bar polling.
Leader/loot/marker events run the shared indicator painter immediately. Combat
flags update bars, status, threat and portrait tint without reloading the model
or rebuilding geometry. UNIT_PET refreshes only its prepared owner/pet pair;
opaque owner tokens are rejected before comparison. Unchanged power text modes
reuse their prepared anchors, including secure pet-layout transitions.

Cast show/hide hooks still cover and restore the name/level. Aura eligibility,
size, duration, width, transparency, dispel filters and native ownership are
unchanged. Range events/fallback cadence, threat colors, ready checks, targets,
class/spec/PvP/level/loot/raid icons, click menus and hover casting remain.
No defaults, settings roots, geometry, art or optional integrations changed.
No event frame, hook, timer, ticker or polling service is added; explicit cold
event subscriptions reuse the existing member/pet frames. Protected roster,
pet layout and visibility drivers are untouched.

## Matched evidence

[Machine evidence](validation/party-steady-performance-2026-11-09.json) retains
exact before/candidate hashes, raw samples, eight rejected harmful controls,
all 51 verified Gethe Git blobs, full validation and read-only installed-copy
checks. The external source/history checkpoint verified 2,456 files and all-ref
history; 43 available settings metadata entries were inspected without reading
their private content into the repository. Existing dirty work is preserved.

Five alternating before/after pairs replay the same changing health/power,
prediction and aura traffic over four members and four visible pets in five
client models. The ten-second timeline is simulated; wall-clock/native work is
not measured. Every pair has identical counters, with zero counter variation:

| Addon operation in the replay | Before | After |
| --- | ---: | ---: |
| Full outer-border/name/icon refreshes | 936 | 0 |
| Pet font/style passes | 800 | 0 |
| Cast-cover recalculations | 1,640 | 0 |
| Power text anchor writes | 3,280 | 0 |
| Text-mode applications | 2,440 | 1,200 |
| Health paints | 1,200 | 800 |
| Power paints | 400 | 400 |
| Prediction paints | 800 | 1,200 |
| Aura updates | 40 | 40 |

The 400 removed health paints are replaced by the correct 400 pet prediction
updates. Every changing member/pet health and member resource sample still
reaches its frame. Counts model visual sinks; a production full border also
does font/geometry work omitted by those sinks. They are neither native call
totals nor estimates of FPS, CPU, memory or frame-time improvement.

The focused fixture passes 305 checks and executes actual pinned native
UnitFrame/PartyMemberFrame event handlers as contract evidence. Existing 1,035
party/focus checks and 163 roster-performance checks pass. The complete suite
passes 273 scripts and 943 Lua syntax files. All five installed runtime copies
match through existing user sync; no manual copying was performed.

Resolved Gethe revisions/builds are Retail `297d7aaaa736f346b3e036f38ee088eaf7f8c07f`
(70783), Forever `9dc84f0d3bbae1768ac3405b3716000bd93eda06` (70862), Classic
`e5d9b3a22c3f0f6f41ebac0e454f4969594261cf` (70631), Era
`4192ac60067fc55566182291bc67c85dd9b6794d` (70576), Anniversary
`68e0a2ec559d9761dfc4e7f864c3944f9d758a49` (70577).
TOCs select Mainline for Retail/Forever, Classic for the other three; Forever
also loads its Camelot override. Source dispatch separates prediction from
portrait updates and gates pet refresh by owner. Source contracts do not prove
addon permissions, the native secure VM or real secret-value behavior.

## Native acceptance still pending

No connected Witchcraft/native execution or profiling tool is available. Keep
the user's existing manual test route and WoW in the background. No foreground,
mouse, keyboard, clipboard, settings/profiler writes or publication occurred.

After normal sync and reload, compare the same party/client/build/addon/profile
with and without pets: idle, healing/damage, resource spending, casts, auras,
range/status changes and repeated invites. Confirm portraits, names, metadata,
ready checks, target strips, bar text, loss/absorb effects and hover/menu input.
Check combat joins/leaves/group moves and pet summons/dismissals, then inspect
Lua errors/taint. Actual latency, CPU, memory, frame-time, pixels and combat
safety remain unmeasured on all five clients. The desktop pass does not establish
that the user's lag is fully resolved; capture native matched samples if it persists.


## Mid-combat group visibility reaffirmed

The user's follow-up requires party/raid to appear as soon as they join, including
in combat (existing REQ-RF-83). Fresh pinned SecureHandlers, SecureStateDriver,
SecureGroupHeaders and SecureTemplates bring this audit to 51 exact source blobs.
The actual source replay passes 255,908 secure wrap/state/roster/click checks;
1,035 party checks pass again using that same verified cache. Cases include a
hidden container, solo startup, combat joins/growth/leaves, party-to-raid
conversion, group moves, pets and target acquisition, without protected writes
or allocations from ordinary addon combat handlers in the model.

No additional runtime fix was needed: OOC preparation covers future groups even
while solo. Native group/existence drivers reveal the already-prepared parent
and appropriate headers/member/pet/target buttons. Queued ordinary layout/options
work does not own or delay that native reveal. The performance change leaves
those drivers and pools intact. Actual client join latency and taint acceptance
remain pending; do not interpret the modeled replay as an in-game pass.
