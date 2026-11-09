# Hearthstone choice on Toy Box clients — 30 October 2026

## Native hover error follow-up

The user supplied a native error at `FluxSmartHearthConfig.lua:491` while
hovering the Hearthstone selector: `GetItemInfo` was nil. The Toy Box panel
had registered; its hover handler still called that deprecated global
directly. The handler now uses the already-loaded `Flux.Item.GetInfo`, which
selects the client's `C_Item.GetItemInfo` or legacy API. An uncached toy name
falls back to `C_ToyBox.GetToyInfo`; the last fallback remains "Hearthstone".
The tooltip's two help lines and opening gesture remain unchanged.

Before editing, external `hearthstone-tooltip-checkpoint-20261030` preserved
1,340 current local source files, verified Git history and two on-disk WTF
settings files while WoW was closed. The pre-fix Hearthstone file SHA-256 was
`4203981fe1900e4c5459ee8e7b08e3401649835584e81057293c7f06a0ecf7ce`;
the hover fix SHA-256 is
`f00f16ff9428b78ef9e57056c12047d6fcb948718471d34d4035f21f30e9582c`.
The focused test now passes 19 checks, including exact hover reproduction
without `GetItemInfo`, the basic item name and an uncached toy name. The
prior candidate fails at hover in that fixture. Full desktop validation passes
106 scripts and 748 Lua syntax files. Native hover, toy choice, secure use,
reload persistence, taint and frame time need a client recheck.

The user reports that the Hearthstone config window does not work on clients
with a Toy Collection and wants to choose which owned Hearthstone toy the grid
button uses. The first correction to the Toy Box flag and journal opener did
not make the panel appear. The actual load-order defect is explicit in the
TOC: `FluxSmartHearthConfig.lua` loads at line 145, while `FLUX_API` is first
created by `Core/FluxAPI/FluxAPI.lua` at line 204. The editor's first guard
therefore returned before registering its UI, saved-choice API and
`/fluxhearth` command on a normal load. The earlier desktop fixture supplied
`FLUX_API` prematurely and missed this failure.

The Toy Box capability now checks `C_ToyBox.GetToyInfo` and `PlayerHasToy`.
`hasToggleCollectionsJournal` remains a separate flag. The editor loads
using `Flux.Cap.hasToyBox`, which is initialized before its TOC entry. It loads
Blizzard_Collections through `C_AddOns.LoadAddOn` or the legacy `LoadAddOn`,
then opens the Toys tab through the available native opener. Icon display
uses the editor's resolver with `C_Item.GetItemIconByID` before
deprecated item globals, so a missing `GetItemIcon` cannot abort panel creation.
Existing account/character storage, the owned-toy list, random choice, basic Hearthstone
reset and button listener remain unchanged. Toy-capable clients that were
previously misclassified also regain the existing toy-client ring and Toy Box
button gesture. `/fluxhearth config` opens
the Toy Box; click the Hearthstone selector beside it, then an owned toy.
Right-click the selector to restore the basic Hearthstone.

Baseline HEAD: `52659bd8d22559dc0943ddd999e681d84d705d8e` (main, clean).
Baseline blobs: `Core/FluxAPI/Capabilities.lua` `641a4fe8009c440c7dce1f45dffab43e849fa04b`;
`ExtraButtonSystem/NonCombatGrid/FluxSmartHearthConfig.lua`
`42c598a04fa88ed2dbabd6f1bba1ac967276fd5b`.
Candidate SHA-256, respectively:
`ca181fce205a2705971df6300b715512ff7bab39ff88eca29919a57a2d7d30fb` and
`80ce3dfcb5751c73eb9620fd9aba21a82d17a23fc5704811bc5a7df4b0e16ca6`.
The dated external `hearthstone-checkpoint-20261030` contains a verified
1,466-entry source archive and Git history bundle. With no WoW processes
visible, two relevant on-disk WTF settings files were copied there, outside
AddOns. They were not opened, reset or added to Git.

After the user's native absence report, a second external
`hearthstone-load-order-checkpoint-20261030` preserved the current local
source (1,340 files) and verified Git history before another edit. With WoW
closed, two current on-disk WTF settings files were copied there as well;
neither settings file was modified. The
pre-follow-up Hearthstone file SHA-256 was
`80ce3dfcb5751c73eb9620fd9aba21a82d17a23fc5704811bc5a7df4b0e16ca6`;
the corrected file SHA-256 is
`4203981fe1900e4c5459ee8e7b08e3401649835584e81057293c7f06a0ecf7ce`.

The [focused source-driven regression](../tests/hearth_config_toy_collection.lua)
now follows the TOC load order and passes 17 checks: registration before
`FLUX_API` exists, no editor on clients without Toy Box, modern item-icon
resolution without the deprecated global, modern
Blizzard_Collections loading, Toy Box opening, editor visibility, owned-toy
flyout, selected toy persistence/readback, basic reset and another native
opener fallback. Its pre-fix version fails at registration. The
[full desktop report](validation/hearth-config-toy-collection-2026-10-30.json)
passes 106 scripts and 748 Lua syntax files. These are mocked UI/API checks.

Native verification remains pending on each Toy Box client: open `/fluxhearth
config` and the button's Toy Box gesture, select an owned toy, confirm the
grid icon and actual item use, reload and verify account/character choice,
switch journal tabs, then check combat/taint and frame time. Clients without
Toy Box APIs should retain their basic Hearthstone fallback. No native pixel,
secure-input or performance result is inferred from the desktop test.
