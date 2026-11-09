# Default cast appearance when the school is unavailable — 31 October 2026

The user clarified that casts without an accessible magic school, including
item, physical and restricted casts, should keep their default appearance.
Target and focus already fall back this way. Blizzard's native nameplate cast
bar must remain the progress, text, shield and lifecycle owner.

## API boundary and correction

The Retail 12.1.0 and Forever 1.60.1 `UnitCastingInfo` and `UnitChannelInfo`
declarations mark cast identity as secret when spellcast restrictions apply.
The never-secret `castBarID` identifies a cast but does not provide a school.
`C_Spell.GetSpellInfo` has no school field. Therefore addon Lua cannot choose
an exact school theme for a cast whose identity is hidden from its start;
the default cast appearance is the honest fallback. Readable magic casts
continue to use the existing school themes.

The nameplate channel path used `channel and channelSpellID or castingSpellID`.
Lua boolean-tests `channelSpellID` there, which is unsafe when it is secret.
It can also borrow the next channel return field when that ID is absent.
An explicit branch now selects the channel spell ID without testing its value.
The shared `Schools.Plain` guard then discards an inaccessible ID and the
existing reset path leaves Blizzard's bar visible. No new bar, setting,
event, timer or animation path was added.

Read-only sources: [Gethe Retail unit API declaration](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/UnitDocumentation.lua),
[spell API declaration](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/SpellDocumentation.lua),
and the user-supplied [12.1.0 API changes](https://warcraft.wiki.gg/wiki/Patch_12.1.0/API_changes).
The local Retail snapshot is `12.1.0.69283` and Forever is
`1.60.1.70425`. Their unit API declaration SHA-256 identities are
`a33d4c585bc3458ab1179070778a2ebef5c324bc5c56bee9511a9fa9eee04a60`
and `a823e84f90fabe58d9ffe547ea17eae83708d451e593b4052bce002cc02ce5c1`.
No external code was copied.

Baseline main: `76ab1e2163a9cb2ea9b4b8f66144072c3d4224a9`.
`NamePlates/CastBarSchools.lua` SHA-256 before:
`2ee9e2190f5ac49fed14bdcf33f05aa1c11456c7a6631e5c5c5a613b44401411`;
after: `6ab4f652aebd2f777f80990e73aa3073ec31ba278b1998acaeb062aa00ef7556`.
The verified complete history bundle and before-edit source copies are outside
AddOns at
`C:\Users\mario\.codex\visualizations\2026\10\31\01a191a3-4b2a-7811-bb0f-2b94742680d8\FluxUI-secret-casts-20261031`.
Bundle SHA-256:
`017b306262cc696c8692175df52a4f58675f8412826906da4bc9560fa6543bb3`.
Four closed-client Config.wtf copies were already in the dated
`FluxUI-nameplate-backdrop-20261031` checkpoint. WoW was closed; no settings
were changed.

## Validation

The expanded nameplate fixture covers secret standard and channel identities
plus a missing channel ID adjacent to the empowered flag. It fails against
the baseline at the latter assertion and passes with this correction:
**56 checks** across Retail, Forever, Era and Anniversary models. The shared
school renderer fixture still passes **13,898 checks** across five models.
Combined desktop validation is in
`validation/secret-channel-fallback-2026-10-31.json`: **111 tests / 756 Lua
syntax files / zero failures**.

Native Retail/Forever secret-channel, item, physical, readable-school,
combat-taint, pixel and frame-time checks remain pending. Desktop mocks
cannot certify native secret-value semantics or visual parity.
