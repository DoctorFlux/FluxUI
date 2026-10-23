# Assets, localization and game data

FluxUI uses bundled textures/fonts, native Blizzard atlases and embedded game-data tables. Resources are not uniformly portable between clients: the same atlas name can refer to different artwork/layout, and data files are selected through TOC/XML gates.

## Resource families

| Location | Purpose / consumers |
|---|---|
| [Assets](../Assets) | Equipment-set shield artwork used by gear-protection/category UI. |
| [Media/ActionBar](../Media/ActionBar) | Action-button interrupt/target masks. |
| [Media/UnitFrames/Retail](../Media/UnitFrames/Retail) | Nine standalone Retail bar-fill TGAs used by Forever's Flux unit-frame display paths. Live continues to use its native atlas paths. |
| [Texture/ActionBarVFX](../Texture/ActionBarVFX) | Cast/channel fills, inner glows, completion masks, interrupt/target art and placeholder texture. Consumed by the button-effect engine's capability-specific fallbacks. |
| [Texture/borders](../Texture/borders) | Blizzard-style, glow and lightspark border resources used by border/overlay presentation. |
| [Texture](../Texture) | Raid shield, bag portrait, battlefield-map, merchant, mouse/keyboard glyphs and other shared UI art. Several glyphs have BLP/PNG/TGA/legacy variants; presence is not proof every variant is loaded. |
| [Binding media](../Binding/UI/Media/Media.lua) | Binding editor media paths and JetBrains Mono font. See provenance for embedded component attribution. |
| Native atlas/texture references | Resolved at runtime through guarded atlas/resource paths. These are client resources and do not appear as bundled files in the asset inventory. |

The exact bundled resource paths, sizes and hashes are included in [inventory.json](reference/inventory.json), alongside source metadata. The extensionless `Texture/Untitled` is inventoried as a resource artifact; no claim about active use or format is made from its filename.

## Retail fill exporter

The existing [asset README](../Media/UnitFrames/Retail/README.md) and [export_retail_unit_bars.py](tools/export_retail_unit_bars.py) describe a reproducible export from Blizzard Retail build **12.1.0.69299**, FileDataID **4642466**, atlas **2074**. These identifiers describe the recorded source asset, not a claim about the latest game build.

The exporter:

1. Accepts a local uncompressed BLP2 source sheet and verifies its exact SHA-256.
2. Extracts named Health/Mana/ManaStatus/Energy/Focus/Rage/RunicPower/ClassResourceMana/ClassResourceEnergy rectangles.
3. Resamples complete fills to power-of-two TGA dimensions with alpha handling, avoiding sheet-coordinate spill when the status bar changes fill coordinates.
4. Writes nine files to the explicit output directory or the bundled Retail fill directory.

```text
python docs/tools/export_retail_unit_bars.py UIUnitFrame2x.blp
```

This command writes runtime asset files and is **not** part of documentation validation. It was retained and not run during the docs rewrite. A changed sheet/build requires verifying atlas rectangles and provenance before changing the exporter hash; bypassing the hash check would not establish correct artwork.

## Flight data

[UnitFrames/FlightPath](../UnitFrames/FlightPath) contains client-specific XML selectors and generated route tables for mainline, mists, cata, wrath, tbc and vanilla. [FluxFlightPath](../UnitFrames/FluxFlightPath.lua) selects/queries the loaded table, adds remembered/manual faction route overrides, and supplies taxi tooltip/player cast-bar timing.

Large route datasets count as source coverage but are documented by schema/consumer and load gate rather than reproducing every numeric route in prose. A route entry's existence does not establish a recently measured travel time; overrides and estimates are separate. Missing data should remain unknown rather than be presented as a zero-second flight.

## Salvage datasets

[Salvage/Data](../Salvage/Data) provides keys, openable, nondisenchantable, disenchantable, millable, prospectable, crushable, scrappable, shatterable and transmutable classifications. The [classifier](../Salvage/FluxSalvage_Classify.lua) combines these with profession/spell/item gates, exclusions, protection and current modifier/tooltip context. Dataset membership alone is not permission to destroy an item. See [salvage](22-salvage.md).

## Localization

[CharacterInfo/Localization](../CharacterInfo/Localization) supplies English, German, Spanish, French, Italian, Korean, Russian, traditional/simplified Chinese and Brazilian Portuguese stat strings. They are consumed by the active CharacterInfo system; similarly named files in unloaded `Other/FluxCharacterStats` are legacy source.

[BuyEmAll localization](../Inventory/Restock/Vendor/BuyEmAll/Localization) contains locale modules selected by their own guards. [Binding/UI/Locale.lua](../Binding/UI/Locale.lua) retains the binding UI vocabulary/locale facade. Localized text, spell names and rank-bearing cast attributes are distinct from stable numerical IDs; persistence and matching should follow the owner's actual key contract.

No translation or data-content regeneration was performed during this documentation replacement.

## Provenance and validation

[Dependencies and provenance](90-reference-inspirations.md) records available embedded library/component attribution and distinguishes comments naming inspiration from evidence of actual imported code. Blizzard artwork remains attributed as recorded by the asset README; absence of a separate license file is not interpreted as a new permission grant.

The documentation checker compares source/resource inventory freshness and validates local links. It does not decode images, evaluate atlases, assess texture appearance in the client, or verify every flight/salvage datum against live game content. Those checks require the relevant client/build and the [verification checklist](41-verification.md).
