# Raid profile completion and Medium nameplates, 30 October 2026

## Report and behavior

The user reported that Blizzard raid settings (power bars, class colors and
frame size) did not apply on first login, and requested `nameplateSize=2`
instead of `3` on all clients. Gethe's [nameplate enum](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/NamePlateConstantsDocumentation.lua)
identifies `2` as Medium and `3` as Large.

The Classic raid-profile path could return success when the active native
profile was empty or not yet registered. It now keeps `profilePending` until an
active profile exists and its option writes succeed. The native profile-loaded
event and a bounded first-world-entry retry finish the profile; completion
reapplies the full raid CVar pack because profile loading may replace earlier
values. Existing combat, Settings and Edit Mode queuing remains in the writer.
Native profile options include power bars, class colors, health text and the
existing 72-by-36 frame size. The size now applies even when Flux owns the
visible raid layout; the other Blizzard group-layout choices remain gated.

Retail and Forever continue to skip native compact-frame CVar and profile
writes through `BlizzardSettings.Write.IsSecretClient` and
`Raid.ApplyProfile`. Their Blizzard callbacks can contaminate protected raid
frame state when invoked by addon code; the existing [Edit Mode regression](../tests/edit_mode_settings.lua)
checks this guard on five modeled clients. Flux's separately owned raid frames
already default to class colors, power bars and percent health text. Native
Blizzard raid settings on protected clients still require the player's native
Settings UI; this change does not claim to apply them automatically. A later
[Flux-owned raid settings follow-up](RAID_OWNED_SETTINGS.md) makes the live
frames and preview consistently use those own options on protected clients.

The first-account defaults table and nameplate pack now both use `2`. Existing
accounts still at the old `3` default migrate once after first world entry via
the existing write queue. Other selected sizes remain unchanged. The
`FluxUI_DB.nameplateSizeDefaultV2` marker is recorded only when the current
value is already different from `3` or a write to `2` succeeds, so a failed or
deferred write can retry.

## Source identity and validation

Baseline main: `efee8006391876687898f7c90f6e0cbd8c22fb1a`.
Before/candidate SHA-256 values:

| Source | Before | Candidate |
|---|---|---|
| `FluxDefaultSettings.lua` | `d77cf8b3a67391023a2e6b463c331d35ce43cf33eb8af658b65aef743a86c12a` | `15248e8060ecd6f07bce2255c1e9a23fc766165b3b5ea4ec84b88007571d1396` |
| `BlizzardSettings/Raid.lua` | `fc07fed69eec86ad2c594a40f3c067380824653e0adbb3724a658d46e06572f4` | `5558505cd83072c0f633bd3c7f3d5f03e79a2d8a7aa1a4549e2b5897221a4159` |
| `BlizzardSettings/Nameplates.lua` | `8b464c2662a93c23e0d020b74ce0a1f43e1cb70659e1aee44c5e821c52868fed` | `fdb469bc6f26237bba72dccfb4d83401efe20172b855d239f812eae71109ad71` |

An external dated checkpoint retains all three preceding sources and verified
Git history. Available WTF files were inspected only for availability; no
private settings or game process were changed.

The [focused regression](../tests/raid_nameplate_defaults.lua) passes 15 checks
for missing/late Classic profiles, one-time profile completion, frame size
with Flux's own frames enabled, the Medium default in both sources,
old-value migration, custom size retention and
deferred/failed retry. The existing Edit Mode regression passes 363 checks
across five modeled clients and two negative controls. The [desktop report](validation/raid-nameplate-defaults-2026-10-30.json)
passes 104 scripts and 746 Lua syntax files. Desktop tests do not establish
native taint safety, pixel parity or actual client Settings values.

Native first-account and new-character checks remain pending on each client:
profile-load timing, power bars, class colors, 72-by-36 native Classic profile
size, nameplate size and combat/Settings behavior. Retail/Forever native raid
settings remain deliberately guarded pending a safe client-owned route.
