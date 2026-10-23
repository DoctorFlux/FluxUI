# Secrets, protected actions and modern-client boundaries

This chapter describes current guard mechanisms, not certification against every live patch. Live Midnight and Forever require distinct paths despite shared family flags; see [02-multi-client-matrix.md](02-multi-client-matrix.md).

## Different constraints

| Constraint | Consequence |
|---|---|
| Secret/inaccessible values | A value may be accepted by display methods while unsafe for Lua comparison, branching, formatting, cache keys or traversal. |
| Protected actions/lockdown | Public inputs do not permit arbitrary secure attribute, parenting, visibility or binding changes during combat. |
| Shared Blizzard taint | Methods/hooks/state written by addon code can affect later native work. A pcall does not remove taint. |

Unknown range/usability is not known false. Secret display payload is not definitely absent. Out-of-combat work can still contaminate shared state.

## Backends and contracts

[Secrets.lua](../Core/API/Secrets.lua) exports `Flux.Secrets`/`Flux.API.Secrets`. [Secrets_Midnight.lua](../Core/API/Secrets_Midnight.lua) guards native access APIs for Retail/Forever; [Secrets_Classic.lua](../Core/API/Secrets_Classic.lua) supplies accessible stubs elsewhere. Runtime guards prevent an unfiltered Classic file replacing the restricted backend.

| Helpers | Contract |
|---|---|
| IsSecretValue/CanAccessValue | Separate checks; a secret can still be unsuitable as a Lua cache key even when access appears allowed. |
| IsSecretTable/CanAccessTable | Check traversal separately from ordinary table type. |
| SafeAccessibleString/SafeGetNumber | Return nil or fallback instead of using secret/inaccessible identity/numeric values. |
| KeepLastNumber | Retains prior usable geometry/display numbers when the latest value cannot be read. |
| SafeCompare | Nil means unsafe/unknown, distinct from false. |
| SafeEqualForCache | Unknown does not become an equal cache hit. |
| SafeBooleanTest/NormalizeTriBool | Avoid ordinary secret boolean tests and preserve unknown where needed. |
| GUID helpers | Accessible identity and guarded target/focus change detection. |
| SafeCountKey/SafeLooksEmpty | Avoid formatting/comparing secrets for caches; secret content is not definitely empty. |
| AuraUpdateInfoIsNoop/HasSecrets | Distinguish ordinary empty diffs from metadata unsafe to if-test/iterate. |

Legacy [Secrets.lua](../Core/FluxAPI/Secrets.lua) exposes related but separate globals/ns.API functions. `AurasRestricted` consults available C_Secrets APIs and modern combat state; it deliberately is not simply "not CanAccessSecrets", since a tainted context can deny broad access while specialized queries remain useful.

## Display and aura paths

Health/power adapters, including legacy functions named SafeUnitHealth, can pass raw values through. "Safe" in a name does not make the return a public Lua number.

- Frames use native text/status-bar/color/duration surfaces and guarded Lua logic, sometimes preserving a prior public layout value.
- Cooldown/charge wrappers preserve secret counts/timers and native duration objects. [Charges.lua](../Core/ButtonFX/Charges.lua) only uses public scalars for signature skips.
- Generic aura slot/index/instance reads require access. Specialized `GetPlayerAuraBySpellID` deliberately is not gated the same way: it can return a nonsecret aura or nil when broad enumeration is restricted.
- `GetAuraDuration` rejects secret/inaccessible instance IDs before querying native duration objects. Metadata helpers protect aura diff traversal.
- Button proc/cast/reticle presentation uses owned visuals and shown-face identities. Any Assisted Combat identity/highlight is provided through Blizzard APIs, not a Flux-authored rotation decision system.

See [shared services](08-shared-services.md), [unit frames](14-unit-frames.md), [raid frames](15-raid-frames.md) and [nameplates](19-nameplates.md).

## Threat distinctions

[Threat.lua](../Core/API/Threat.lua) preserves multi-return query payloads inside protected calls and separates accessible numeric operations from display passthrough. Classic /100 normalization is excluded on Midnight/Forever.

Current NamePlates.Core.IsThreatSupported requires C_NamePlate but does not exclude live Midnight; IsLevelSupported excludes live only, so Forever still has a level path. Both modern runtimes use secret guards. Forever has specific frame/nameplate/meter display paths; dedicated meter rows retain secret payloads where generic rows can be skipped. `DisplayNumber` handles readable lead sentinel values and passes secrets through to accepted displays. `GetForeverFrameDisplay` currently selects scaled percentage, with raw fallback; `GetForeverNameplateStatus` separately chooses status.

Older header comments mention raw/lead behavior that differs from current function bodies. Do not generalize one threat formula to every consumer or treat old prose as executable truth.

## Combat and secure execution

[Combat.lua](../Core/Engine/Combat.lua) defers structure to regen. [Scheduler.lua](../Core/Engine/Scheduler.lua) separates layout/display/eval/structural/inventory. Display-context repaint does not inherently require recompiling bindings.

Forever sets `hasRestrictedClosures=false`. [Restricted.lua](../Core/Engine/Restricted.lua) skips snippets/Execute/WrapScript and uses a Flux-owned event-assisted 0.2-second watcher, pausing structural operations during lockdown. Unit/pet owners can keep frames shown and fade alpha instead of attempting protected Show in combat.

[Click.lua](../Core/ButtonFX/Click.lua) separates Forever visible mouse-up hosts from key-down proxies. [MouseoverCast.lua](../Core/Engine/MouseoverCast.lua) uses click-time units on wrap clients, native checkmouseovercast on Forever. Current Forever SyncCVar skips native CVar writes; Blizzard's checkbox owns it. Older opening comments are less precise.

## Blizzard integration mechanisms

| Area | Mechanism |
|---|---|
| Settings | [Write.lua](../BlizzardSettings/Write.lua) queues curated packs while Settings is shown/in combat; suppresses Settings.SetValue/NotifyUpdate on modern Retail/Forever. Low-level CVar calls alone do not defer for the panel. |
| CVar adapters | Block selected coupled plate/raid/target-cast settings; threat bitfields have a specific allowed route. |
| Action collectors | [Action.lua](../Core/API/Action.lua) detaches/suppresses Flux registration to avoid owned scripts tainting later native entries; Forever gamepad collectors have a further no-touch policy. |
| Blizzard hiding | [Hide.lua](../Blizzard/Hide.lua) defers protected parenting and waits for Edit Mode. Removed events are not generically restored without reload. |
| Edit Mode | [legacy UI.lua](../Core/FluxAPI/UI.lua) queues post-exit layout, mutes owned selection chrome and suppresses the manager's spec-change layout event. |
| Native panel clicks | [SecureClickProxy.lua](../Core/SecureClickProxy.lua) overlays a separately parented secure click/macro button, with hover polling outside that secure button. |
| Dropdowns | [FluxBlizzardDropdown.lua](../Core/FluxBlizzardDropdown.lua) selects classic menus for Forever gamepad Flux menus. |
| Forever compatibility | [Client_Camelot.lua](../Core/Client_Camelot.lua) installs missing item/PVP/aura aliases, adapts spell rank info and parks stock ComboFrame callbacks only after runtime validation. |

Other integrations globally wrap item-identity/cursor operations and alter companion state. An addon-wide "never modifies globals/Blizzard methods" claim would be false; see [29-integrations.md](29-integrations.md) and [40-findings.md](40-findings.md).

Mock secret objects do not reproduce the full native secure engine. Live acceptance includes combat/instances, cursor and target hops, channels/empower/procs, Settings previews, Edit Mode, gamepad style/native panels and companions. A successful pcall does not alone prove a child transfer or absence of taint. See [41-verification.md](41-verification.md).