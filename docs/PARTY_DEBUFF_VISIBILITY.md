# Friendly debuff colors and party dispel visibility

10 November 2026 â€” PARTY-DEBUFF-VISIBILITY-20261110. This request authorizes this
party feature slice despite older pauses on unrelated party/raid work. It does not
resume unrelated work or authorize client control. Direct implementation and the
user's existing in-game reproduction route remain selected.

| Requirement | Implementation | Acceptance |
| --- | --- | --- |
| PDV-01: Never tint enemy target/focus frames | Attack excludes tint; friendship takes precedence over assistability; public native owners are hidden/unbound immediately in the identity/reaction event | 18,618 tint checks across five clients and current/legacy providers; exact baseline rejected |
| PDV-02: Keep friendly party/target/focus colors | Existing type palette, filters, option precedence, portrait layers and readable numeric coloring remain | Same fixture checks isolated units, reactions, missing/unknown types, restricted data and restoration |
| PDV-03: Clearer party debuff icons | Player-style party icons use four 1.5-unit rectangular color edges over a black outline, above the cooldown; native PreserveAsset retains the artwork on each client | Four edges and native sink registration checked; existing preview uses the same border helper; pixels pending |
| PDV-04: Type-colored Salvage-style glow only for dispellable party debuffs | Independent native HARMFUL|RAID slot or guarded readable filter; both party display styles; known harmful types only | 408 checks across five client models, with atlas present/absent; removal, ordinary debuffs, enemy party unit, disable, reassignment, combat and raid transitions |
| PDV-05: Preserve all-client behavior, data, input and update cadence | Existing lifecycle and settings; no gameplay timer, ticker, hook on globals or Lua OnUpdate | 11,410 aura checks, existing suite, six new baseline/harmful controls; actual native acceptance pending |

## Behavior and ownership

An assist probe can disagree with friendship/attack rules. Target/focus tint now
requires a friendly, non-attackable unit. On a hostile reaction or identity event,
the public aura containers hide and bind to none immediately, before the existing
After(0) batch. Registered restricted buttons and textures are never queried.
Friendly player/party/target/focus retain their existing tint policy. External
target/focus aura-panel icon colors are independent of this frame-chrome policy.

The clearer rectangular icon border applies to player-style party frames. Its
colored edges stay inside the clipped icon bounds, above the swipe. Preview and
readable painters use the same helper. Buffs, icon sizes, duration, stack text,
filter limits and saved transparency remain unchanged. Compact raid-style icon
styling stays with its existing renderer.

The full-party-frame glow uses Salvage's desaturated
UI-HUD-ActionBar-Proc-Loop-Flipbook, 5 columns, 6 rows, 30 frames in one second.
Missing-atlas clients pulse the existing glow-border artwork. The glow extends
eight layout units past the frame and cannot intercept input. Magic, Curse,
Disease, Poison and a dispellable Bleed use the selected client's AuraUtil palette.
Ordinary/non-dispellable debuffs can have colored icon borders but never trigger
this glow. Unknown/untyped auras cannot hide a later known dispel in the readable
path. Existing display-debuff and dispel-highlight preferences disable the effect.

Retail/Forever use a separate native slot with HARMFUL|RAID and known-type
candidate filtering, rather than revealing restricted aura data to Lua. Each full
cell prepares one additional public owner OOC so combat party joins can use existing
widgets. It binds only to friendly party/player units; raid tokens keep their old
raid-strip highlight and retire the party glow. Classic progression, Era and
Anniversary retain the readable aura owner and prepare one effect host OOC.

Forever's verified AddAuraShownAnimation binding owns animation start/stop on aura
visibility. The pinned Retail implementation lacks that binding: a prepared engine
animation on the public owner runs while the party dispel feature is enabled and
the owner is shown. Its texture remains natively gated by actual aura assignment;
no private descendant is inspected. This bounded engine loop can remain active
with no eligible dispel on Retail. It stops when the public owner hides. This is
an explicit feature cost, not an FPS optimization claim. Native verification of
animation targeting restricted textures remains required on Retail.

No new settings or visible strings are needed: the effect follows existing options
and automatic debuff-type colors. Decorative textures/hosts are noninteractive;
no controller focus stop, new binding or cursor handler is added. Existing clicks,
menus and navigation must still be checked in-game. The earlier open requirement
for restricted numeric FontString colors is unchanged; no forbidden Texture getter
or speculative private-value bridge was reintroduced.

## Sources and validation

Fresh Gethe branch pins, resolved once for this request:

| Branch | Commit |
| --- | --- |
| live | `297d7aaaa736f346b3e036f38ee088eaf7f8c07f` |
| forever | `4cd0ab752a77164f654ccbca9d0c1fe8dafceebe` |
| classic | `e5d9b3a22c3f0f6f41ebac0e454f4969594261cf` |
| classic_era | `4192ac60067fc55566182291bc67c85dd9b6794d` |
| classic_anniversary | `68e0a2ec559d9761dfc4e7f864c3944f9d758a49` |

[Source records](validation/party-debuff-visibility-sources-2026-11-10.json) contain
63 fetched files with SHA-256 and Git blob identities; 18 absent native-container
paths on Classic branches are retained separately. Sources include AuraUtil,
native container/button Lua and load paths, unit friendship/attack declarations,
and animation group/flipbook/alpha contracts. Source availability does not prove
addon operation or native rendering.

[Focused evidence](validation/party-debuff-visibility-2026-11-10.json) records two
fresh passes of the three focused scripts, exact pre-change sources rejected by
the new regressions, and four additional rejected harmful controls. No desktop
test certifies the protected VM or engine filtering. The
[full-suite report](validation/party-debuff-visibility-full-2026-11-10.json) records
298 passing scripts and 970 passing syntax checks; every current Lua file matches
the tested manifest. All changes stay on main in the existing Retail
folder. The 2,551-file source/history checkpoint is external; 61 on-disk settings
metadata entries were inspected read-only. Two concurrent inventory source edits
were detected and preserved; this task owns only three runtime files.

## Native checks still required

After reload, on each client: switch friendly target/focus to enemies with debuffs,
then back; verify no hostile frame tint even during reaction/combat changes. Apply
each dispellable type to a party member and compare with a non-dispellable debuff;
verify the glow's color, animation, removal and option disable. Check both party
styles, first combat aura/join, leave and party-to-raid conversion, scale/alpha,
icon border visibility, tooltips/clicks/controller and taint/errors. Record actual
builds, pixels and matched performance only when captured. These checks are NOT
RUN: no Witchcraft, simulator or computer-input tool is connected. WoW remains
in the background; no game input, settings/profiler writes, manual sync or
publication was performed.

## Blizzard's dispellable-only checkbox — 13 November 2026

PARTY-BLIZZARD-DISPEL-20261113 fixes the requested integration with Blizzard's
**Show Dispellable Debuffs Only** checkbox. Both player-style and compact Flux
party frames now apply the existing strict filter when either that native
`raidFramesDisplayOnlyDispellableDebuffs` CVar or Flux's existing scoped option
is enabled. Disabling the native setting restores the normal aura selection
unless Flux's option remains enabled. Actual raid/focus settings and the shared
option table retain their existing behavior. Native `showDispelDebuffs` controls
Blizzard's separate ordinary-party dispel indicator and is outside this checkbox.

| Requirement | Implementation | Acceptance |
| --- | --- | --- |
| PBD-01: Follow Blizzard's checkbox in both party styles | Per-frame read-only predicate shared by native and readable aura painters | Five client models; native group configuration and readable aura selection checked |
| PBD-02: Refresh existing icons when the checkbox changes | Existing CVar events update only party aura content; combat uses prepared public aura owners | Immediate on/off, case-insensitive names, no unrelated aura refresh or protected layout |
| PBD-03: Retain Flux options, strict filtering, previews and saved data | Native setting OR existing Flux flag; shared table untouched; active party preview refresh | Boss/priority/own non-dispellable auras excluded; party-to-raid restoration and no saved/native writes checked |

The renderer retains its earlier strict `HARMFUL|RAID` policy; Blizzard's own
classification can keep boss/role/priority exceptions. This change connects the
checkbox without replacing Flux's established strict behavior. No new control,
visible string, focus stop, event registration, frame, timer, hook or polling is
introduced. Existing preview deferral is reused. Mouse/controller interaction,
native aura secrecy, visual parity, taint and CPU/FPS checks remain NOT RUN.
Direct implementation and the existing user-native retest choice are retained.

[Source evidence](validation/party-blizzard-dispel-sources-2026-11-13.json) records
five freshly verified Gethe branch identities and the native settings/load paths.
[Validation](validation/party-blizzard-dispel-2026-11-13.json) records the exact
external source/history checkpoint, candidate identities, focused regressions
and control results. [Full desktop run](validation/party-blizzard-dispel-full-2026-11-13.json): 338 scripts
and 1,026 Lua syntax files PASS; complete current Lua manifest verified. The 418
focused checks reject the exact checkpoint and five harmful controls; documentation
validation also passes. Native acceptance is pending.
The verified checkpoint contains 2,694 source files and Git history; 183 available
on-disk settings metadata entries were inspected without copying private contents.
No foreground/input control, settings/profiler writes, manual sync or publication.

After `/reload`, enable Blizzard's checkbox and apply dispellable and ordinary
debuffs to a party member. Verify only dispellable debuffs remain in both Flux
party styles; toggle it off and verify ordinary debuffs return with Flux's own
strict option off. Repeat with the party preview, first combat aura/join and
party-to-raid conversion. Verify tooltips, clicks/controller and no taint/errors
on each installed client. These native checks remain pending.
