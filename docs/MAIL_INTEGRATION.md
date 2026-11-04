# Built-in mail work

## Scope and source boundary (4 November 2026)

The user requested Postal-like mail behavior inside `_FluxUI` for every supported
client, chose direct implementation rather than a mock-up, and then clarified
that its buttons and settings must match Postal **1:1**. The initial Flux
controls were reshaped to the inspected Postal sizes, anchors and menu labels;
full feature behavior and native pixel parity still require work.
The installed
Postal v4.3.4 (`Postal.toc`, X-Build 663, release 2025-10-29) and the current
CurseForge project page both say **All Rights Reserved**. Its source is a
behavior reference only. No Postal Lua, localization, artwork, library or
saved-variable data is copied into FluxUI. Flux owns its implementation and
keeps the native MailFrame. The supplied `svn checkout` URL identifies that
reference; the installed copy supplies the same release for offline inspection.

Targets are the repository's five supported clients: Retail Midnight, Forever,
Classic Era, Anniversary and MoP Classic. The local Blizzard mirrors identify
Retail 12.1.0.69283, Forever 1.60.1.70425, Era 1.15.9.68808,
Anniversary 2.5.6.68775 and Classic 5.5.4.69155. Newer bundled source
inventory pins are live `d07eb00237d8891f153215db98a5df880a26cfe5`
(12.1.5.70688), forever `aff0d8cd53bf4d9ef1c1dd2786b94461a276fb16`
(1.60.1.70707), and classic `e5d9b3a22c3f0f6f41ebac0e454f4969594261cf`
(5.5.4.70631). Those inventory pins do not certify mail operation; actual
installed client builds and native validation remain separate.

The clean main baseline is `1b319d19aa00fffa7e798a66d045e55902af6706`.
A dated Git bundle is outside AddOns in the Codex visualization workspace.
Twenty available `_FluxUI.lua` settings files were copied to a private temp
checkpoint while no WoW process was visible. Existing settings are untouched.

## Requirements and implementation matrix

| ID | Observable requirement | Implementation state | Acceptance evidence / remaining work |
|---|---|---|---|
| MAIL-01 | FluxUI loads its own mail controls on all five clients without Postal installed and coexists with the native MailFrame. | Implemented in shared TOC modules. | 122-script/777-Lua desktop suite passes; native mailbox open/close, layering and taint pending. |
| MAIL-02 | Collect safe, non-COD, non-GM inbox money and attachments sequentially; never delete text mail or process a closed mailbox. | Flux Open All button and dedicated nested filter menu use a confirmed native-action worker; Blizzard Open All returns when module disabled. The worker scans all attachment slots and waits for delayed item metadata. | 17 focused Open All checks; native batch/refresh/shift override pending. |
| MAIL-03 | Select individual inbox messages and collect/return/delete only the intended selection. | Postal-shaped Open/Return controls; Shift range and Ctrl same-sender selection; selected take/return worker and internal guarded delete. | 21 focused desktop checks include sparse slots and delayed metadata; native duplicate/index-shift/bag-full test pending. |
| MAIL-04 | Provide Postal-like click shortcuts for taking mail and attaching bag items. | Alt-left bag attachment implemented using `Flux.Container`; native modified-click already takes an individual mail. | 22 focused desktop checks; native mouse/combat/taint checks pending. |
| MAIL-05 | Save account contacts, recent recipients and known alts; offer recipient completion. | Postal-sized BlackBook arrow and nested recipient menu; Blizzard autocomplete retained. Postal typing completion and some source lists pending. | 21 focused desktop checks; reload, cross-realm and provider handoff pending natively. No `Postal3DB` migration. |
| MAIL-06 | Provide quick attachment by item category, forwarding and repeat sending. | Postal-shaped category icons and text-only Forward control. Attachment forwarding and Express repeat sending pending. | 25 focused category checks; native item restrictions, attachment limits and send confirmation pending. |
| MAIL-07 | Support money entry convenience, inbox refresh, trade blocking, unwanted mail handling and message copy where client permits. | Generated money subject, mailbox gain, copy icon/window, expiry return/delete icon and scoped trade blocking implemented; native refresh retained. | 14 convenience and 8 expiry-action checks; native copy pixels, mail totals and CVar restoration pending. |
| MAIL-08 | Preserve existing inventory mail snapshot/provider ownership and all Flux settings. | No inventory implementation changes; modules read the existing character/container services. | Existing provider tests and full 122-script/777-Lua suite pass; native pending. |
| MAIL-09 | Preserve the native frame's established look; additions must not obstruct its controls. | Native MailFrame retained with Postal-shaped controls. | User chose direct implementation; five-client screenshots and input pending. |
| MAIL-10 | Match Postal v4.3.4's visible button positions, sizes, icons and labels for every module on each supported client. | Inspected anchors/sizes implemented for main menu, BlackBook, Open All, Select, QuickAttach, Forward, CarbonCopy and DoNotWant. Main arrow explicitly owns a clickable layer on all clients. | Native screenshots and pointer interaction needed to establish pixel parity on five clients. |
| MAIL-11 | Match Postal's full settings menu, defaults, submenus and profile behavior, including per-module enable/disable and saved persistence. | Main and Open All use separate dropdown frames; speed list, both free-slot menus, Express, BlackBook, QuickAttach, profile snapshots and module toggles implemented. Some Express/BlackBook settings have incomplete behavior. | 28 focused settings checks exercise the top button click, both dropdown entry points and nested levels; native menu/profiles/reload check pending. |

The current Flux slices implement contacts, recent recipients, known alts,
selected taking/returning, Open All filtering, category and Alt attachment,
text-only forwarding, copy, generated money subject, trade blocking and mailbox
gain while retaining the native MailFrame. The complete desktop suite passes
122 scripts and 777 Lua syntax files. Each subsequent slice should complete
a remaining requirement and update this matrix.
No row is considered client verified from desktop tests. Auction, guild-bank and
void-storage callbacks remain outside this scope.

## Checkpoint

Read this file, `CONTRIBUTING.md`, `docs/STATUS.md`, `docs/DECISIONS.md`,
`docs/WORK_LOG.md` and `NEXT_SESSION.md` before continuing. Reconcile actual
main revision and working tree with the source identity above. Next executable
action: native-check the implemented flows sequentially across the five clients,
then finish attachment forwarding, Express repeat sending, BlackBook completion,
and update this matrix. Current tree has uncommitted `_FluxUI.toc`, nine
`Mail/*.lua` modules, eight focused tests, this record and a desktop report.
