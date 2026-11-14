# Unit-frame debuff colors in combat

9 November 2026 — DEBUFF-COMBAT-COLORS-20261109; follow-up to REQ-RF-92.
The user reports incomplete numeric debuff colors and portrait borders during
combat and explicitly requires all clients using Gethe/wow-ui-source.
The follow-up at 13:45:15 reports a native forbidden-object failure in the attempted
numeric color bridge. That runtime failure rejects the earlier desktop-only result.
No new UI design or mock-up is needed.

The scope remains friendly player, player-style party1–4 and friendly target/focus.
Preserve the current effective dispellable-only option/CVar precedence, unknown-type
exclusion, aura icons, unit isolation, colors, backgrounds, fills and saved data.
Retail, Forever, Classic progression, Era and Anniversary are all required.

## Changes

DEBUFF-FORBIDDEN-READ-20261109 removes the attempted native Texture color bridge,
its retained Texture reference, prepared color state and both forbidden getter
operations. The reported stack reaches GetVertexColor at line146 of the rejected
candidate; the next IsVisible call would also access a restricted descendant.
Addon creation of the Texture and secret-return annotations do not grant access.
No pcall suppression, native hook or alternate descendant getter replaces it.

Numeric text uses guarded readable aura types and restores normal colors while
aura access is restricted. Readable combat types still work on clients/contexts
that expose them. The original requirement for restricted numeric type colors
on Retail/Forever remains OPEN. The inspected native API supports dispel-colored
Textures and dispel-type text content; no supported binding was found for applying
that private type color to the existing independent HP/resource FontStrings.
GetAuraDispelTypeColor also requires unit-aura access; it cannot establish access
that the caller lacks. Do not substitute stale or invented colors.

The portrait's combat painter raises its border above the old overlay level.
The overlay now parents to that border, so native parent level inheritance keeps
the debuff overlay above the combat border through entry and exit. No runtime
private-button level edits, new frames, events, hooks, timers or polling are added.
The portrait background retains the existing combat policy.

Clients without the native container/color capabilities retain the guarded
readable painter and client display table. Its portrait overlay inherits the same
border layer fix. No restricted-data fallback guesses a type.

## Sources and checks

[Pinned source contracts](validation/debuff-combat-upstream-2026-11-09.json)
retain 30 public source files and 28 checked contracts. Resolved branch SHAs:

| Client | Gethe commit |
| --- | --- |
| Retail | `297d7aaaa736f346b3e036f38ee088eaf7f8c07f` |
| Forever | `9dc84f0d3bbae1768ac3405b3716000bd93eda06` |
| Classic progression | `e5d9b3a22c3f0f6f41ebac0e454f4969594261cf` |
| Era | `4192ac60067fc55566182291bc67c85dd9b6794d` |
| Anniversary | `68e0a2ec559d9761dfc4e7f864c3944f9d758a49` |

The earlier inference from GetVertexColor/IsVisible secret-return annotations to
registered Texture accessibility was invalid. The user's native failure establishes
that this registered descendant is forbidden to the calling addon context.
The report did not supply a client/build; do not infer one from its stack.
Six additional pinned files in the [follow-up evidence](validation/debuff-forbidden-comparison-2026-11-09.json)
retain the unit-aura precondition and text/texture option contracts.
The local Retail AddDispelTypeTexture implementation has an older insertion/helper
body; the required Texture validation and four secret aspects match the pin.
No index-return assumption is used.

[Original regression comparison](validation/debuff-combat-comparison-2026-11-09.json)
is retained as rejected evidence: its mock incorrectly allowed registered Texture
getters during restriction. Its 17,104 checks did not establish native correctness.
The [corrected comparison](validation/debuff-forbidden-comparison-2026-11-09.json)
enforces inherited forbidden access on registered Textures as well as buttons.
Five rejected-candidate runs reproduce the forbidden-object error, five corrected
runs pass and three harmful controls are rejected. The full focused suite passes
17,050 checks across five client models/current and legacy providers, including
restricted aura changes/removal/identity, normal text restoration, independent native
border ownership, portrait level inheritance and zero transition frame allocations.

[Corrected full validation](validation/debuff-forbidden-full-2026-11-09.json)
records the current suite. These checks establish desktop behavior only.
No registered native Texture reads, color selectors or prepared color objects
remain. Existing readable aura scans/coalescing and native border owners remain.
Native CPU, FPS, allocations, taint and post-correction acceptance are unmeasured.

[Follow-up recovery checkpoint](validation/debuff-forbidden-checkpoint-2026-11-09.json)
verifies 2,411 current source files and all-ref history externally; 120 settings
metadata entries were inspected read-only. Existing options work is preserved.
No game input, settings/profiler writes, manual synchronization or publication.

## Native acceptance still required

No connected Witchcraft/native execution tool is available. The user's existing
in-game testing route remains; do not claim a native pass from these fixtures.
After the existing synchronization and a reload on each client, confirm the
reported error is gone. Restricted numeric type colors remain unresolved:

1. Apply/remove Magic, Curse, Disease, Poison and Bleed where available on player
   and friendly party units. Check HP/resource values and percentages and the
   portrait border before combat, in combat, after dispel/expiry and after combat.
   Expect normal numeric text whenever the client restricts aura access.
2. Change friendly target/focus while different units carry different debuffs.
   Check no cross-unit color leakage, including target-self aliases and clearing.
3. Toggle the existing dispellable-only/debuff options and verify strict filtering,
   missing/unknown types, hostile transitions and hidden frames restore correctly.
4. Compare native pixels, inspect Lua/forbidden-action errors and taint, and retain
   separate build/settings/scenario evidence. Real combat and native frame time
   remain pending on all five clients. Leave WoW behind the user's active window.

## Supported route audit — renewed request

DEBUFF-BINDING-AUDIT-20261109 rechecked all five branch heads through the connected
GitHub tools. The commits/builds match the table above: Retail70783, Forever70862,
Classic progression70631, Era70576 and Anniversary70577. Thirty-five freshly fetched
public files are retained outside AddOns with exact SHA256 values in the
[audit evidence](validation/debuff-binding-audit-2026-11-09.json).

The requested behavior is unchanged: existing numeric health/resource values and
percentages must use the same dispel color as borders during combat on all clients.
The existing source does not supply a verified supported implementation for the
restricted Retail/Forever case. This is still an unresolved requirement.

| Route inspected | Finding |
| --- | --- |
| Border's native dispel painter | AddDispelTypeTexture requires a Texture. Executing the pinned validator rejects a FontString. |
| Native dispel-type text | The native method writes mapped content or a dispel symbol. Its options do not bind dispel color to independent health/resource text. |
| Aura animations | Native validation requires the animation target to be the aura button or a descendant. An external health/resource FontString is rejected before adoption. |
| Reading the border's color/visibility | The user's13:45:15 error already establishes forbidden access. Neither getter was retried. |
| Direct aura-color query | GetAuraDispelTypeColor requires unit-aura access. Its existence grants no permission to query otherwise inaccessible auras. |
| Duration text binding | Its seven color/format properties are temporal; none represents dispel type, health or power. Synthetic-duration and format setters do not accept secret arguments from tainted execution. |
| Offscreen/mask display | No verified live-FontString color binding is supplied. ApplySnapshot requires a target Texture; its declaration cannot justify calls involving a forbidden target. No speculative renderer was installed. |

The important native contracts are the
[Texture-only registration](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_AuraContainer/Blizzard_CustomAuraButton.lua#L112),
[animation target validation](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_AuraContainer/Blizzard_AuraContainerUtil.lua#L366),
[dispel text options](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_APIDocumentationGenerated/AuraContainerUtilDocumentation.lua#L268)
and [temporal binding properties](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_APIDocumentationGenerated/DurationTextBindingSharedDocumentation.lua#L6).

Sixteen desktop checks execute the actual pinned Retail/Forever Lua validators
and inspect the relevant source declarations. Existing focused17,050checks pass;
owned runtime/test hashes are unchanged from the forbidden-read correction.
No production code, saved data, native state, settings or profiler preferences
changed. These checks do not prove every possible engine technique impossible;
they establish why the inspected routes cannot be claimed as a supported fix.
Native border/portrait checks remain pending and the all-client numeric color
requirement remains OPEN. A supported native FontString dispel-color binding or
another independently verified engine route is still needed.
