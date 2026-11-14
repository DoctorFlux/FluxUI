# Built-in target and focus tracking

10 November 2026, `MINIMAP-TRACKING-20261110`. The user requests the behavior of
the installed ForeverMinimapTarget in FluxUI, for supported clients whose normal
tracking menu omits these choices. The existing five-client scope remains Retail,
Forever, Classic progression, Era and Anniversary. Prior direct implementation
and user in-game reproduction choices are retained. No foreground/input operation
or client settings write is authorized or required by this implementation.

## Requirements and acceptance

| Requirement | Implementation | Evidence / remaining acceptance |
|---|---|---|
| REQ-MT-01: integrate without a required companion | TOC loads `FluxMinimapTracking.lua`; shared Flux lifecycle, DB, event and timer services | Desktop lifecycle and full TOC checks; native reload pending |
| REQ-MT-02: restore only available hidden native Target/Focus filters | Resolve actual tracking filters by enum identity, skip missing metadata; inspect existing menu recursively to avoid duplicate rows | Retail/Forever full pinned native menu-generator replay; Classic inert checks |
| REQ-MT-03: retain preferences per character across world entries | `_FluxUI_CharSavedVars.minimapTracking`; Target defaults true; Focus remains unmanaged until explicitly chosen; explicit false preserved | Reload, world reset, reordered indices and delayed-choice checks |
| REQ-MT-04: preserve native ownership, presentation and integrations | Show-all stays native; normal native rows and optional filters stay native; localized native names/icons; standalone companion owns behavior when loaded | Show-all, nested menu, future native choice and companion checks; native pixels pending |
| REQ-MT-05: bounded lifecycle and safe unsupported clients | Full capability and native no-tracking game-rule gates; one shared world subscription and menu modifier; one managed 3-second retry per transition, older callbacks invalidated | No new frames/tickers/OnUpdate/global hooks; unsupported clients have no subscriptions/timers/settings writes; native combat/taint/performance pending |
| REQ-MT-06: preserve settings and controller operation | No existing setting overwritten, reset or private file imported; ordinary native menu checkboxes reuse native navigation, select/back, focus and hints | Persistence and malformed-data desktop checks; native controller acquisition/select/back in normal and embedded map pending |

## Behavior and usage

Open the existing minimap tracking menu and use Target or Focus where supplied
by the running client. Each checkbox reflects current native state. Choices are
character-specific, independent of Flux's layout scope. Target initially turns
on; Focus initially keeps the client's state. An explicit off choice survives
reload and loading screens. The bounded retry reads the latest preferences and
resolves current indices; it cannot replay an older captured choice onto a
different tracking spell. Other tracking filters retain their current behavior.

The native tracking menu is the settings surface for these native filters; no
second options page, slash command, binding, marker overlay or custom controller
navigation layer is introduced. All new visible text comes from Blizzard's
localized tracking metadata; there are no addon-owned English-only labels.
Native menu text width accommodates localized names. Actual localized layout,
controller and mouse input remain untested in the client.

`minimapTrackingShowAll` is never changed. With it enabled, Blizzard retains the
menu and tracking state; Flux's saved normal-mode choices remain dormant. Returning
to normal mode restores them on the next world entry or explicit checkbox change.
Ordinary external changes are not fought by a continuous tracking-event listener.

ForeverMinimapTarget is an optional ordering dependency, not a requirement. When
enabled/loaded, Flux's implementation stays dormant, preserving the companion's
menu, defaults, saved data and lifecycle without duplicate rows. Disable that
standalone addon and reload to use the built-in implementation. Flux never
disables it or rewrites/imports its private character DB. The built-in preferences
start in Flux's own existing character root when first used.

## Exact source scope and limitations

Fresh branch resolution on 10 November verified these Gethe commits:

| Client | Commit | Mirror version | Result |
|---|---|---|---|
| Retail | `297d7aaaa736f346b3e036f38ee088eaf7f8c07f` | 12.1.5.70783 | Modern filter API; normal menu hides Target/Focus; engine enumeration still required |
| Forever | `9dc84f0d3bbae1768ac3405b3716000bd93eda06` | 1.60.1.70862 | Modern filter API; Camelot normal-menu policy hides Target; Focus requires actual runtime enumeration |
| Classic progression | `e5d9b3a22c3f0f6f41ebac0e454f4969594261cf` | 5.5.4.70631 | No `GetTrackingFilter` in pinned tracking API; built-in module inactive |
| Era | `4192ac60067fc55566182291bc67c85dd9b6794d` | 1.15.9.70576 | Same API boundary; native tracking unchanged |
| Anniversary | `68e0a2ec559d9761dfc4e7f864c3944f9d758a49` | 2.5.6.70577 | Same API boundary; native tracking unchanged |

The enum names alone do not prove a client can display unit markers. This module
does not invent marker coordinates or backport unavailable engine features to
Classic. Retail's source labels Focus among removed filters, so its enum declaration
is especially insufficient: no Focus control is added without a real tracking
entry. Native filter operation and actual marker visibility remain pending even
where desktop contract checks pass. Installed `GetBuildInfo()` was not captured.

The [source ledger](validation/minimap-tracking-sources-2026-11-10.json) identifies
33 source records / 26 exact unique Git blobs, including generated signatures,
TOC load selection, Mainline/Camelot menu policy, full native menu generators and
menu description APIs. Exact cache files remain outside AddOns.

ForeverMinimapTarget v1.0.1, Ashtar Senior, was inspected read-only from the path
supplied by the user. Its TOC declares GPL-3.0-or-later. Flux's module is independently
implemented against the native APIs and existing Flux services; no addon source,
icon or saved data was copied. The reference identity is recorded in the evidence.

## Validation and recovery

The dated external checkpoint verifies 2,510 source files and complete Git history;
46 settings metadata entries were inspected read-only. No quiescent WTF backup is
claimed. Archives, upstream caches, private metadata and mutation controls remain
outside AddOns. See [checkpoint](validation/minimap-tracking-checkpoint-2026-11-10.json).

The focused regression executes production Flux code and optionally the complete
pinned Retail/Forever `OnLoad` and tracking-menu generator. Three fresh runs pass
412 checks each; eight harmful controls are rejected. The complete desktop suite
passes 280 scripts and 952 Lua syntax checks, with focused final-source checks and
exact identities recorded in [evidence](validation/minimap-tracking-2026-11-10.json).

In-game acceptance: with the standalone disabled, reload, open tracking, verify
the supported choices and localized icons in both normal and embedded minimap;
toggle each independently, reload and change zones; exercise show-all and the
existing None action; check another character, tracking spells and missing Focus;
verify controller focus/select/back, combat/no-tracking rules, errors/taint and
actual marker visibility. These native checks, pixel parity and matched frame-time
measurements are **NOT RUN**. No FPS or native performance improvement is claimed.
The earlier paused party/raid work remains paused.

The user confirms a running program synchronizes the Retail FluxUI folder to the
other clients and explicitly requests updates to Retail only. All task writes
stay in this existing Retail repository (with recovery/evidence caches external).
No manual client installation or synchronization is performed. Reload after the
user's sync completes; the enabled standalone still retains ownership by design.
