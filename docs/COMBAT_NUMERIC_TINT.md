# Combat numeric debuff color — capability audit, 8 November 2026

The requested result is live HP/resource values and percentages matching the
native debuff border during combat on player, target, focus and party frames.
That exact all-client result remains unimplemented for restricted aura data.

## Verified boundary

The latest Gethe branch heads were resolved again, including Retail12.1.5.70783
and Forever1.60.1.70862. Their CustomAuraButton source is the same verified blob,
9e373b9e44e352e77771eef30f058217151dbdb7. The native engine can color descendant
Textures from private debuff data. The type validator rejects FontString objects;
existing external numeric labels also fail the descendant ownership requirement.
Private children deny tainted access while auras are secret, so their resulting
colors cannot be read or copied out by addon Lua.

SetDispelTypeText is a different API: it sets a debuff symbol or a custom static
label and hides/clears it without an aura. It replaces the supplied numeric text;
it does not bind an arbitrary HP/resource font to native dispel color. The
application/duration/spell/caster text helpers render their own aura fields too.
Raw aura enumeration and GetAuraDispelTypeColor have an aura-access precondition;
a secret display return does not grant permission to acquire an aura instance.

The same native widget restriction applies to all requested frame/unit tokens.
Classic and any unrestricted combat context can keep using public known type
colors. Restricted Retail/Forever contexts retain native border color with normal
numeric text. No last-known color, fabricated type, private getter, fake Texture,
privileged callback/provenance route or extra polling is added.

## Evidence and scope

A read-only external probe executes the actual current native type validator and
ApplyDispelTypeText on owned mock FontStrings for player, target, focus and four
party tokens on both restricted client source versions.106assertions verify
Texture acceptance, FontString rejection, unchanged font color and numeric text
replacement/clearing. The existing friendly tint fixture passes13230checks.
These source-model checks do not claim native hardware/taint or visual acceptance.

No runtime files changed. No new in-addon test, frame, event, timer, cache or
saved setting was added. There was no game input, profiling, manual client sync,
branch, commit or publication. The full suite was not rerun because the runtime
is unchanged; earlier full results retain their original source scope.

[Machine evidence](validation/combat-numeric-tint-capability-2026-11-08.json) records
all five current head identities,13fresh source blobs, runtime hashes and probe
outputs. [Requirement RF96](RAID_HEALKIT_REWORK.md) stays explicitly unimplemented
until a supported font-color binding or equivalent documented display mechanism
is available. This audit must not be described as a combat text recoloring fix.
