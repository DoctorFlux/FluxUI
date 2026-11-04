# Classic combined bank — 4 November 2026

## Requirements and scope

| ID | Requirement | Implementation | Evidence still needed |
|---|---|---|---|
| BANK-C01 | On Era and Anniversary, show the character bank's main slots and purchased bank bag contents as one expanded grid matching the existing ten-column combined bag. | `Inventory/Builtin/FluxClassicCombinedBank.lua` hosts Blizzard's live item buttons in one window, sized to the content and scaled only if the screen is shorter than the window. Before opening a newly equipped bank bag, it returns hosted buttons to their native container so Blizzard can regenerate that frame. | Native screenshot, placement, scrolling absence, item pickup and deposit. |
| BANK-C02 | Show all bank bag equipment slots, occupied and unpurchased, beside the title. Plain clicks must not toggle bank bags; hover and drag/pickup/drop remain usable. | The native six Era or seven Anniversary bag buttons are hosted in a top row. The click and drop scripts only call `PutItemInBag` with an item cursor; native drag and tooltip scripts remain. The native open-bag check overlay is suppressed because every purchased bag is already in the combined grid. Original scripts and highlight alpha are restored on release. | Native hover, empty/purchased slot color, drag out, equip, swap and combat restrictions. |
| BANK-C03 | Allow buying another bank bag slot without a tall empty footer. | The live Blizzard purchase button, slot-cost money frame and current-money frame are hosted in a single 34-pixel footer row. The purchase button and next-slot cost hide when `GetNumBankSlots` reports full or the purchased count reaches `NUM_BANKBAGSLOTS`; current money remains. Blizzard's cost, affordability, confirmation and purchase update remain authoritative. | Native purchase confirmation, insufficient funds and last-slot full state. |
| BANK-C04 | When Baganator owns bags, neither Flux custom bag nor bank window appears, including after a late load. | Both Classic UI modules check the alternative-bag owner; the bank restores all Blizzard parents/scripts and visibility, and the bag closes its combined frame on handoff. | Native early/late Baganator load and unload/reload. |
| BANK-C05 | Keep the existing bank restock control visible on the new bank window. | `FluxBankRestockButton.AttachToBank` parents and anchors the existing button at the left of the header controls while the Flux bank is shown. Its Baganator and native placements remain available. | Native button placement, drag target, auto toggle and bank restock execution. |

The bank window is deliberately limited to Era and Anniversary, the clients where Flux already owns a custom combined bag. Retail, Forever and current Classic progression keep their existing bank path. The inventory data scanner, restock, other bank types and saved variables are unchanged.

## Source and behavior

Baseline Flux main: `065fb20a7aeca84270f6d6acc2daf590b708fd14` (1 November 2026). A verified dated external Git history bundle exists outside AddOns at `C:\Users\mario\.codex\visualizations\2026\10\31\01a191bd-d58d-74a3-bbdf-1b69e0cce168\FluxUI-trinket-passive-20261101\source-history.bundle`; SHA-256 `90708215a2f172be38ba290bd20629e12d00975c84e779e3d2f4abb3382404e8`. Era and Anniversary `_FluxUI` SavedVariables are present on disk and were read-only presence checks. No settings, client, profiler or desktop input was changed.

Candidate `FluxClassicCombinedBank.lua` SHA-256 is
`8f8b8b97673d69d6302d7675774d4ad7b0f13067959bca7555acfbf2a6ca61e2`;
the companion `FluxClassicCombinedBag.lua` SHA-256 is
`8da75582c1196c7b4c538118b83d15ab39356d08eb4423828f7ba3990908c59b`.
The bank restock button adapter SHA-256 is
`cde484bee29bf59510d7bdb5db0f1387f2e3de7fe19c8ebedc0e97b13017ba12`.
A 4 November external candidate source/history checkpoint under
`C:\Users\mario\.codex\visualizations\2026\11\04\01a1a73d-edce-7aa2-bba4-8d9e42f12b89\FluxUI-classic-bank-20261104`
contains a Git bundle (SHA-256
`521307596b0c1e29ba852cd02d24b27aae48bf08fed81e621526729e4a62edc9`)
and a 1,397-file working source archive.

The inspected Gethe source mirrors are version `1.15.9.68808` (Era) and `2.5.6.68775` (Anniversary); their trees lack `.git`, so upstream commit SHAs are unresolved. Installed executables recorded in `CLIENT_MATRIX.csv` are newer (`1.15.9.70576` and `2.5.6.70577`), and exact current-client parity needs native checking. The Era loaded `Vanilla/BankFrame.lua` and XML are SHA-256 `5b0347939969ec61df2f7a96facc325d6f013802aa59901825633b0d452ead6a` and `374302eca99f100a755e50dbffd150b9d45a6bb7d099e3bfa764e1e51584c84e`; Anniversary's loaded `TBC/BankFrame.lua` and XML are `e71cc3084aaaf69b0edc85276d26906be9027123a8297594e691fe733ef84fbe` and `93967c4fdd807e5e8c994497950f3e1df89d783d305810d758323b1527a2be43`. Their TOC loads Vanilla for Era and TBC for Anniversary. Both native scripts retain the bank event owner, 28 generic bank buttons, bank bag button tooltips and purchase confirmation. No Blizzard source was copied into Flux.

The custom bank shows alongside Flux's player combined bag when the banker opens the normal bag view. It hosts native bank item buttons under frames with the original container IDs and paints their quickslot/empty/quality artwork like the existing combined bag, so native clicks, stack splitting, tooltips and cooldown updates continue. Purchased bank bags are opened in the background and their native item buttons are hosted in the same grid. Closing the bank returns every button and footer to its original parent and anchor, restores their native art, and restores background bag frame alpha/mouse state. Baganator handoff follows the same release path without closing the bank session.

## Validation and limits

The user's native trace showed `ContainerFrame_GenerateFrame` failing at
`ContainerFrame10Item1:SetPoint` when Flux opened newly equipped bank bag 9.
That button was still parented to the combined grid. The bank now restores
hosted native buttons and ghosted frame state before calling `OpenBag` for any
newly readable bank bag, then hosts the regenerated buttons again.

`lua tests/classic_combined_bank.lua` and `lua tests/classic_combined_bank.lua anniversary` each pass 33 loaded-module lifecycle checks: ten-column layout and item art, native item IDs, six/seven bank bag slots, compact purchase control and full-slot hiding, suppressed check overlay, no-toggle/drop behavior, new-bag frame regeneration, restock attachment and Baganator handoff, return of parents/scripts/art and close behavior. Separate early-Baganator checks pass in each client model. Full desktop validation is recorded in `validation/classic-combined-bank-2026-11-04.json`. These models do not certify client pixels, secure input, exact installed bank API behavior, taint or FPS.

The full desktop runner passes **114 scripts and 760 Lua syntax files** with
zero failures. `docs/tools/build_reference.py` refreshed the source inventory;
`docs/tools/validate_docs.py` passes 793 classified sources, 581 reachable
TOC/XML files, 23 SavedVariables and 13,445 local links.

On each native client, open/close the bank with zero, one and several bank bags; compare the ten-column bank layout, bank coin portrait, bag slot row and footer with the normal combined bag. Hover and drag the bank bag slots, confirm plain click never toggles a separate bag, deposit/withdraw/stack split in the main grid and bank bags, and purchase a slot only with explicit player intent. Repeat with Baganator enabled at login and after load; check restock button position, drag target, auto toggle and execution, junk overlays and Escape. Record frame time, errors, taint and screenshots with exact build/profiler settings before acceptance. No native run was available in this workspace.
