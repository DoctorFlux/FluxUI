# Dependencies, ports and reference provenance

Runtime dependencies, embedded libraries, explicit ports and design references are different relationships. Local comments establish attribution/intent, not a complete historical or license audit. See [assets](34-assets.md), [source coverage](30-source-coverage.md) and [integrations](29-integrations.md).

## Runtime companions and embedded libraries

[_FluxUI.toc](../_FluxUI.toc) lists Blizzard_UnitFrame and Blizzard_CompactRaidFrames as optional dependencies. A Camelot-filtered dependency metadata entry names Blizzard_CombatLog. External companions are discovered at runtime; [Core/Optional.lua](../Core/Optional.lua) probes Syndicator, Baganator, Details, BigDebuffs, TacoTip, ConsolePort, Questie, Masque and Clicked. A probe is not proof of a complete integration. Syndicator readiness is separate from loaded state. The dated [reference manifest](REFERENCE_MANIFEST.csv) records inspected versions and license evidence.

| Loaded code | Role/provenance |
|---|---|
| [LibStub](../libs/LibStub/LibStub.lua) | Versioned library registry. |
| [Unfit](../libs/Unfit-1.0/Unfit-1.0.lua) | Item suitability; attribution/embedding terms are in its header. |
| [LibCustomGlow](../libs/LibCustomGlow-1.0/LibCustomGlow-1.0.lua) | Glow rendering; credits LibButtonGlow work; local [MIT license](../libs/LibCustomGlow-1.0/LICENSE). |
| [CallbackHandler](../libs/CallbackHandler-1.0/CallbackHandler-1.0.lua) | Library callback support. |
| [LibKeyBound](../libs/LibKeyBound-1.0/lib.xml) | Hover-and-key binding mode; authorship/version in source. |
| AceAddon/AceDB/AceDBOptions/AceEvent/AceConsole/AceGUI/AceConfig | Addon/profile/options/widget services loaded through XML. |
| [C_Everywhere](../libs/C_Everywhere/C_Everywhere.xml) | Economy API compatibility; included Tests.lua currently immediately returns. |
| [CustomSearch](../libs/CustomSearch-1.0/CustomSearch-1.0.lua) | Search parsing; local attribution/embedding terms. |
| [ItemSearch](../libs/ItemSearch-1.3/ItemSearch-1.3.xml) | Item query API/filters. |
| [SecureTabs](../libs/SecureTabs-2.0/SecureTabs-2.0.lua) | Tab support with local distribution header. |

Other library directories, including LibActionButton, LibButtonGlow, LibClassicSpellActionCount, LibDualSpec and LibDBIcon, are not automatically active. Check TOC/XML reachability; installed addons can separately provide libraries through LibStub.

## Explicit source relationships

| Area | Local evidence |
|---|---|
| Binding strings | [Locale.lua](../Binding/UI/Locale.lua) identifies verbatim Clicked enUS keys and Flux additions. |
| Binding UI/media | Adapted widgets/media and Clicked-style vocabulary coexist with Flux-owned current document/compile/placement layers. Installed Clicked does not own this state. |
| Secure click/effects | [Click.lua](../Core/ButtonFX/Click.lua) calls its ButtonForge-derived contract verbatim; other Core comments cite ButtonForge icon/rank/cooldown/checked/event patterns. |
| Vendor bulk purchase | [FluxBuyEmAll.lua](../Inventory/Restock/Vendor/BuyEmAll/FluxBuyEmAll.lua) identifies a BuyEmAllClassic port, with local XML/localization. |
| Chat copy | [FluxChatCopyPaste.lua](../Other/FluxChatCopyPaste.lua) identifies a ChatCopyPaste port and named authors. |
| Equip flyout | [FluxEquipSlotFlyout.lua](../Other/FluxEquipSlotFlyout.lua) describes ItemRack-style behavior and a copied docking table. |
| Flight route data | [FluxFlightPath.lua](../UnitFrames/FluxFlightPath.lua) and the per-client data headers credit RestedXP Guides, CC BY-NC-SA 4.0, adapted for FluxUI. |
| Salvage | [FluxSalvage.lua](../Salvage/FluxSalvage.lua) says Molinari-style; that alone establishes an interaction comparison, not complete ancestry. |
| Flyouts | TOC names a UFO pattern; active code is FlyoutEngine, not leftover Flyout files. |
| Bars | TOC names an Ellesmere-style engine/preserved Flux visuals; old concept docs named Bartender4. Exact upstream ancestry is not inferred from style comments. |

Earlier documentation also cited Scrap/Restocker, Syndicator/Baganator and TPerl as product references. Those comparisons can explain intent, but loaded source defines current behavior. The previous blanket "intent only/no vendoring" wording did not reflect embedded libraries and explicit ports.

No complete pinned upstream revision manifest was found. This documents known local evidence without inferring every similar feature's origin.

## Blizzard references and asset tooling

Comments name reference trees wow-ui-source-classic_era, classic_anniversary, classic, live and forever. These names describe comparisons, not automatically present dependencies or version guarantees.

[export_retail_unit_bars.py](tools/export_retail_unit_bars.py) records nine standalone fill exports from Blizzard FileDataID 4642466, build 12.1.0.69299, atlas 2074 and an exact SHA-256. It validates the BLP input and writes alpha-aware resampled power-of-two TGA files, defaulting to Media/UnitFrames/Retail. It is an asset-production utility, not a read-only docs check.

The [asset index](34-assets.md) covers textures/fonts/localization/data. This docs pass preserves vendor/runtime/license files.
