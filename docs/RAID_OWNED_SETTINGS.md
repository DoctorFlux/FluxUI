# Raid settings on protected clients, 30 October 2026

The user reported that Blizzard raid power bars, class colors, and frame size
were not set at first login. They chose to retain the Retail/Forever taint guard.
Gethe's [compact raid profile source](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_CUFProfiles/Blizzard_CompactUnitFrameProfiles.lua)
routes native raid CVars into Blizzard compact-frame callbacks. The
[Settings definitions](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_SettingsDefinitions_Frame/Mainline/InterfaceOverrides.lua)
expose those CVars in Blizzard's Interface UI. The locally reproduced Edit
Mode error is documented in [native mouse suppression](49-native-mouse-suppression.md).
Addon writes to these native settings remain guarded on Retail and Forever.

Flux-owned secure raid cells already have separate account/character options.
Their defaults enable class-colored health bars and power bars, use percent
health text, and size members from the 72-pixel width and 36-pixel base height
with existing scales of 1 and 1.2. Initial world entry and option changes
apply these tunables through `FluxRaid_ApplyOptionsFromDB`, with combat work
deferred through the existing queue. The live health text and power bar chrome
now honor those own options even when native CVars disagree. The synthetic
raid preview also reads Flux's options for class colors, power bars, health
text, buffs, and debuffs on protected clients. Classic retains native CVar and
profile behavior.

This changes the appearance of **Flux's frames**, not the values shown in
Blizzard's Interface Settings. If Flux raid frames are disabled, Blizzard's
frames use the player's own native settings. No safe addon-owned route to set
those Blizzard values has been established with the guard retained.

## Source identity and validation

The dated external checkpoint `raid-owned-settings-checkpoint-20261030`
preserves the three pre-edit sources and a verified Git history bundle.
Available WTF settings were checked for presence; no private data was copied
or changed.

| Source | Before SHA-256 | Candidate SHA-256 |
|---|---|---|
| `RaidFrame/FluxRaidVisuals.lua` | `76623e13293080e5173c036e304b0cb4833a553b2a4ef322cc468802f6b078aa` | `eb6fb2ff4b074ddfe52beb1d5f6b4f2ca3ce3f216191364fff695142859fd003` |
| `RaidFrame/FluxRaidUnit.lua` | `6ce37a98ef63d1f1a5a47709e21a519e50e2c198724265bb624689ff50386150` | `3783ce13f258c6b1e9766e68e2c401288baba6c77a5f96faa6db7b170a4c797a` |
| `RaidFrame/FluxRaidPreview.lua` | `3b0c70d905c3ec7656d2203342d39e7d36378b4ed0620e29c38768f1857dd820` | `7d8eabb81864c1038f561db7e1db790a90f7c1580973291c9932cb41a4d0afe3` |

The [focused test](../tests/raid_owned_settings.lua) passes nine checks for
protected-client ownership and retained Classic behavior. Existing raid
startup, raid aura smoke, and Edit Mode guard tests pass. The
[desktop report](validation/raid-owned-settings-2026-10-30.json) passes 105
scripts and 747 Lua syntax files. Native first-account, new-character,
real-raid, combat, Edit Mode, pixel, and performance acceptance remains
pending on every relevant client. Desktop tests cannot establish native taint
safety or Blizzard Settings values.
