# Wand school theme on the swing timer — 5 November 2026

## Scope and behavior

Classic Era, Anniversary and Forever keep the existing player cast-bar slot,
border, icon, label, timing, ready hold, fade and cast priority. The ranged
strip is now a real StatusBar so its progress fill can use the same
`CastBarThemes` renderer as spell casts. Its trough matches the cast bar's
0.3 gray. A wand's readable damage school selects the existing Fire, Frost,
Nature, Shadow, Arcane or Holy fill, glow, backdrop and particle settings.
Fire wands therefore use the Fire spell-cast palette and effects. Melee,
bows, guns, thrown weapons and unavailable item schools keep their ordinary
swing presentation. The Classic wand check uses the ranged equipment slot;
the earlier main-hand check could miss a normal equipped wand and label Shoot
as Auto Shot. The existing school-theme options apply; no saved variable,
default, command or new setting is added.

The school comes from the equipped item's localized damage line, using the
client's damage label and `C_Spell.GetSchoolString`. `Shoot` (5019) itself is
shared across wands and cannot establish a wand's damage school. The resolver
checks the ranged subclass with `C_Item.GetItemInfoInstant` where available,
with the existing legacy item-info fallback and an item-ID cache. It then
reads structured `C_TooltipInfo.GetInventoryItem` lines where available and
uses an owned, hidden GameTooltip on older Classic clients. It reads on item
change, retains a known result across unchanged inventory events, and retries
after `GET_ITEM_INFO_RECEIVED` when the tooltip was cold. It drops unreadable
or secret data, requires a numeric weapon-damage range so an Equip bonus cannot
misidentify the school, and restores the standard swing fill on unequip. The renderer's
existing visibility and option gates own its animation work.

## Source and checkpoint

Gethe's 5 November source inventory was pinned before implementation:

| Client | Upstream identity | Relevant contract |
|---|---|---|
| Era | [1.15.9.70576, `4192ac6`](https://github.com/Gethe/wow-ui-source/tree/4192ac60067fc55566182291bc67c85dd9b6794d) | [Shared tooltip handler](https://github.com/Gethe/wow-ui-source/blob/4192ac60067fc55566182291bc67c85dd9b6794d/Interface/AddOns/Blizzard_SharedXMLGame/Tooltip/TooltipDataHandler.lua), [school string](https://github.com/Gethe/wow-ui-source/blob/4192ac60067fc55566182291bc67c85dd9b6794d/Interface/AddOns/Blizzard_APIDocumentationGenerated/SpellDocumentation.lua) |
| Anniversary | [2.5.6.70577, `68e0a2e`](https://github.com/Gethe/wow-ui-source/tree/68e0a2ec559d9761dfc4e7f864c3944f9d758a49) | [Shared tooltip handler](https://github.com/Gethe/wow-ui-source/blob/68e0a2ec559d9761dfc4e7f864c3944f9d758a49/Interface/AddOns/Blizzard_SharedXMLGame/Tooltip/TooltipDataHandler.lua), [school string](https://github.com/Gethe/wow-ui-source/blob/68e0a2ec559d9761dfc4e7f864c3944f9d758a49/Interface/AddOns/Blizzard_APIDocumentationGenerated/SpellDocumentation.lua) |
| Forever | [1.60.1.70790, `eac30af`](https://github.com/Gethe/wow-ui-source/tree/eac30af597e5aaa43a60f6675ef5fdcea100375f) | [Structured inventory tooltip](https://github.com/Gethe/wow-ui-source/blob/eac30af597e5aaa43a60f6675ef5fdcea100375f/Interface/AddOns/Blizzard_APIDocumentationGenerated/TooltipInfoDocumentation.lua), [item-data event](https://github.com/Gethe/wow-ui-source/blob/eac30af597e5aaa43a60f6675ef5fdcea100375f/Interface/AddOns/Blizzard_APIDocumentationGenerated/ItemDocumentation.lua) |

Classic's generated TooltipInfo file has no getter declaration in these
snapshots, while its loaded shared tooltip handler maps `SetInventoryItem`
to `GetInventoryItem`. The runtime presence guard and GameTooltip fallback
account for that source boundary. Actual tooltip contents and restricted
runtime behavior still need native confirmation.

Baseline local HEAD at start: `72704d19cec2190495acb51d0ab82659e945d71a`.
The dated external checkpoint at
`C:\Users\mario\.codex\visualizations\2026\11\05\01a1ad64-d106-7c82-8deb-6b758049f22f\swing-theme-checkpoint-2026-11-05`
holds the baseline all-ref history bundle (SHA-256
`eef058fc366538474cbdfd896b6408b45b713896778c7b349997f84245478787`),
initial source copies and initial worktree status. Initial swing source SHA-256:
`81f7ddba75b0b1cc9496acbb4e6280b7fcdc2fe2fcbc06033adabfe05fba035`.
Candidate swing source SHA-256:
`517529257035f41cc06ffa46086fe2b23a5ac3c3c7f41bcd3f1ae617a05b4814`.
Candidate shared renderer SHA-256:
`12baba747eb22de911e83840e47656721aab552252dadbb936fe492d22e30575`.
Era, Anniversary and Forever `WTF/Config.wtf` files were present and checked
read-only. They were not copied while clients could be running; settings and
profiler preferences were not changed. No backup or private setting entered
AddOns or Git.

## Checks and remaining acceptance

The production-module desktop fixture checks Fire/Frost replacements, unchanged
inventory, cold item data, bow fallback, misleading Equip text and localized damage labels on all
three targets. It also checks the shared renderer's fill restoration and
secret-mask fallback. The focused cast-theme fixture passes 13,942 checks;
the full validation report is
[here](validation/swing-wand-school-2026-11-05.json). Desktop assertions do not
establish in-game pixels, taint safety, localized tooltip availability, FPS or
frame time.

Native acceptance is pending on each installed client: reload the exact
candidate; verify a Fire and Frost wand, switching wands, re-equipping the
same wand, a bow/non-wand, cold item data, and a real cast claiming/releasing
the player slot. Compare Fire wand fill, glow, backdrop and particles against
a Fire cast at the same scale and theme settings. Check the countdown and
classic move/still phase, option off/on, combat/taint, localization and a
matched frame-time capture before any performance or pixel-parity claim.
