"""Read-only TOC/XML reachability and lexical security triage; no safety certification."""
from __future__ import annotations
import csv
import hashlib
import json
import pathlib
import re
from datetime import datetime, timezone

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parent.parent
manual = {
    "Mail/Select.lua": "Read native command pending gate; header identity; job generation; close/disable cancellation; extended production fixture",
    "Mail/OpenAll.lua": "Read shift override eligibility, COD/GM exclusion, handoff to shared job owner; extended production fixture",
    "Mail/QuickAttach.lua": "Read OOC/mailbox/Alt/cursor/free attachment/bound/locked gates and family-specific hooks",
    "Mail/DoNotWant.lua": "Read value confirmation header recheck, direct return/delete APIs and module-owned popup entry; native pending-command behavior open",
    "Mail/Settings.lua": "Read module profile callbacks; custom StaticPopupDialogs entry is a native provenance review surface",
    "Mail/TradeBlock.lua": "Read capture/restore BlockTrades CVar and mailbox/interaction/leave lifecycle",
    "Mail/Contacts.lua": "Read posthook SendMail records recipient and draft fields; no live content collected; native delivery and field permissions open",
    "Mail/Conveniences.lua": "Read money-subject native hook and native OpenMailFrame show callback; native provenance open",
    "Mail/CategoryAttach.lua": "Read category button callback routing through Mail.AttachBagItem guarded owner",
    "CharacterInfo/TacoTip.lua": "Read classic-paperdoll capability gate, one-time third-party/native show hooks; native provenance open",
    "CharacterInfo/PaperDollEquipFlyout.lua": "Read OOC hover gate, scoped duplicate enter guard and own flyout callbacks",
    "CharacterInfo/PaperDollSecondaryName.lua": "Read Forever post-open observer exemption plus collapse hook; other-client native show/title/size hooks",
    "CharacterInfo/PaperDollQuality.lua": "Read native item-slot update/show hook ownership; native provenance open",
    "CharacterInfo/ItemLevel.lua": "Read native PaperDoll/Character show hooks; real secret/panel behavior open",
    "CharacterInfo/StatsEra.lua": "Read client gate and ToggleCharacter posthook; own stat scripts; not full stat formula verification",
    "CharacterInfo/StatsProgression.lua": "Read mainline/Forever panel skip and ToggleCharacter hook; not full stat formula verification",
    "CharacterInfo/StatsCustomExtensions.lua": "Read pending native stat hooks and own tooltip setters; native provenance open",
    "Other/FluxDurationBars.lua": "Read native MirrorTimer_Show global replacement and mirror timer event hooks; native provenance review required",
    "Other/FluxEquipSlotFlyout.lua": "Read owned click dispatch to Candidates equip/unequip, combat entry guards and own native-template stripping",
    "Other/FluxPerfCapture.lua": "Read optional watch lifecycle, observer release and saved diagnostics preservation; diagnostics not enabled",
    "Other/FluxInputDebug.lua": "Read secret guards before inspection and diagnostic-only API; no live invocation",
    "Other/FluxLoot.lua": "Read secret guards and native events; loot/art/cursor test scope remains desktop",
    "Other/FluxChatColumnMicros.lua": "Read/existing fixture extracts durability painter; not complete native panel acceptance",
    "WindowMover/Engine.lua": "Read protected layout permission+combat/Edit Mode deferral, native hook exemptions, LOD scanning, permanent hooks and enabled lifecycle",
    "WindowMover/Catalog.lua": "Read source identities for frame ownership/exclusions; native per-frame protection unknown",
    "WindowMover/Init.lua": "Read module enable/start/disable routes and existing disabled lifecycle test",
    "Minimap/FluxMinimap.lua": "Read native OnMouseWheel replacement, right-click posthook, OOC indicators, Classic tracking script fallbacks and mail lifecycle fixture",
    "Minimap/FluxObjectiveTrackerScroll.lua": "Read combat guards, deferred dirty update, Forever ContainerMixin.Update wrapper/gamepad bypass and update hooks",
    "Minimap/FluxQuestie.lua": "Read OOC Questie layout guard, third-party timer reparent and callbacks; optional addon native behavior open",
    "Minimap/FluxBuffDebuffFrames.lua": "Read native system anchor hook and owned event callbacks; native protection open",
    "NamePlates/Core.lua": "Read native region writes/secret guards and active plate driver; work counts delegated performance audit",
    "NamePlates/Countdown.lua": "Read forbidden/access gates, opaque label and copied text, scoped host parenting; actual restrictions open",
    "Inventory/FluxEquipSlotCandidates.lua": "Read explicit OOC equip and unequip guards and container pickup adapter",
    "Inventory/FluxItemMover.lua": "Read action ownership/cursor pacing and runner stop boundary; not every 3500-line state machine transition proved",
    "Inventory/Restock/FluxRestock_Inv.lua": "Read item lock gates and native pickup/use adapters; native protected action result remains per-client",
    "Inventory/Restock/Vendor/FluxVendorBuy.lua": "Read bounded buy pass, merchant-open/slot identity/wallet checks and merchant-close cleanup",
    "Inventory/Restock/Bank/FluxBankRestock.lua": "Read bank-open, cached can-run and pending idle work cancellation boundaries; guild/void callback audits excluded",
    "Inventory/Restock/Bank/FluxBankRestockButton.lua": "Read direct native lifecycle, generation retries, visibility/parent/layering attachment; actual native behavior still open",
    "Inventory/Builtin/FluxClassicCombinedBag.lua": "Read combat guard and native item button reparent boundaries; source reachability includes Classic conditional contract",
    "Inventory/Builtin/FluxClassicCombinedBank.lua": "Read native bank hooks and owned host reparent; desktop ownership regression only",
    "Inventory/Builtin/Mail.lua": "Read SendMail/ReturnInboxItem posthook publication; native mailbox permissions open",
    "Inventory/Init.lua": "Read OOC direct bank listener and native callback installation boundaries; not every inventory callback proven",
    "BaganatorCompat/Loader.lua": "Read late-load integration ownership and delayed finalize callbacks",
    "BaganatorCompat/FluxBaganator_BankRestock.lua": "Read native/third-party lifecycle hooks and existing footer ownership scope",
    "BaganatorCompat/FluxBaganator_CategoryIcons.lua": "Read instance-only label wrappers, no Frame prototype SetWidth hook",
    "BaganatorCompat/FluxBaganator_ItemViews.lua": "Read third-party reveal/protection callback ownership",
    "BaganatorCompat/FluxBaganator_GearSetContext.lua": "Read item context overlay instance hook boundary",
    "Salvage/FluxSalvage_Overlay.lua": "Read secure overlay OOC setup, combat deferral, modifier routing, hide cleanup; extended strict-mutation fixture",
    "Salvage/FluxSalvage_Tooltip.lua": "Read combat/carried-bag/forbidden tooltip gates and native tooltip posthooks",
    "AddonOptions/FluxOptions.lua": "Read guarded binding reassignment and combat config deferral call sites; full options tree not interactively executed",
    "AddonOptions/FluxOptionsShell.lua": "Read combat panel open/toggle/refresh guards and callback lifecycle",
    "AddonOptions/FluxOptionsRender.lua": "Read own pooled widget parent/script writes and native custom popup registration",
    "AddonOptions/AceGUIWidget-FluxRestockPanel.lua": "Read own pooled row script teardown and native custom reset-tier popup entry",
    "AddonOptions/FluxOptionsActionBars_Bindings.lua": "Read explicit combat disabled/guarded binding options",
    "Core/Engine/Restricted.lua": "SEC-01; full module production experiment with original Blizzard registration source controls",
    "Core/Engine/Combat.lua": "Full module 600000 request per sample stress and midflush lockdown controls",
    "Core/SecureClickProxy.lua": "Read protected proxy OOC setup/arm/hide and independent active polling owner",
    "Binding/Core/Apply.lua": "Read OOC apply/deferred retry and native classification/slot ownership",
    "Binding/Input/FluxMouseoverKeybind.lua": "Read prepared snippets, native wrap-only restrictions, pending regen registration and hover lifecycle",
    "Blizzard/Hide.lua": "Read native script preservation, protected deferral, Edit Mode guard, multi-owner mouse restoration",
    "Respec/FluxRespec_Apply.lua": "SEC-02/03; full module production experiment with action/cancellation owner",
    "Respec/FluxRespec_ActionBars.lua": "SEC-02/03; full module pickup/place/stance/lockdown failures",
}
patterns = {
    "native_hook": r"\b(?:hooksecurefunc|HookScript)\b",
    "script_write": r"\bSetScript\s*\(",
    "protected_attribute": r"\b(?:SetAttribute|RegisterStateDriver|RegisterAttributeDriver|RegisterUnitWatch|SetBinding|SetOverrideBindingClick|SecureHandlerWrapScript)\b",
    "structural_write": r"\b(?:SetParent|SetPoint|ClearAllPoints|SetScale|SetSize|Show|Hide)\s*\(",
    "native_action": r"\b(?:PickupContainerItem|UseContainerItem|BuyMerchantItem|TakeInboxItem|TakeInboxMoney|DeleteInboxItem|ReturnInboxItem|SendMail|PlaceAction|PickupSpell|EquipItemByName|CraftSalvage)\b",
    "combat_guard": r"\b(?:InCombatLockdown|InLockdown|DeferProtected|CanChangeProtectedState|CheckAllowProtectedFunctions)\b",
    "value_access": r"\b(?:issecretvalue|canaccessvalue|canaccesstable|IsSecret|CanAccessValue)\b",
    "native_popup_table": r"\bStaticPopupDialogs\b",
}
reachable: dict[str, set[str]] = {}
seen = set()
def walk(path: pathlib.Path, condition: str):
    if not path.exists(): return
    key = path.relative_to(ROOT).as_posix()
    reachable.setdefault(key, set()).add(condition)
    marker = (key, condition)
    if marker in seen: return
    seen.add(marker)
    text = path.read_text(encoding="utf-8-sig", errors="replace")
    if path.suffix.lower() == ".toc":
        for line in text.splitlines():
            line = line.strip()
            if not line or line.startswith("#"): continue
            filename, _, suffix = line.partition("[")
            target = path.parent / filename.strip().replace("\\", "/")
            if target.suffix.lower() in (".lua", ".xml"):
                walk(target, suffix.rstrip("]").strip() if suffix else condition)
    elif path.suffix.lower() == ".xml":
        text = re.sub(r"<!--[\s\S]*?-->", "", text)
        for filename in re.findall(r"<(?:Include|Script)\b[^>]*\bfile\s*=\s*['\"]([^'\"]+)['\"]", text, re.I):
            walk(path.parent / filename.replace("\\", "/"), condition)
walk(ROOT / "_FluxUI.toc", "shared or runtime-gated")
excluded = {".git", "docs", "new docs", "tests", "Stress test doc"}
scripts = sorted(p for p in ROOT.rglob("*.lua") if not any(part in excluded or part.startswith(".") for part in p.relative_to(ROOT).parts) and not p.name.startswith("_tmp"))
tests = {p.relative_to(ROOT).as_posix(): p.read_text(encoding="utf-8-sig", errors="replace") for p in (ROOT / "tests").glob("*.lua")}
rows = []
for path in scripts:
    key = path.relative_to(ROOT).as_posix()
    text = path.read_text(encoding="utf-8-sig", errors="replace")
    locations = {name: [str(i) for i, line in enumerate(text.splitlines(), 1) if re.search(pattern, line)] for name, pattern in patterns.items()}
    row = {"path": key, "sha256_raw": hashlib.sha256(path.read_bytes()).hexdigest(),
           "toc_xml_reachable": key in reachable, "loading_conditions": "; ".join(sorted(reachable.get(key, []))),
           "review_level": "manual-boundary-review" if key in manual else "lexical-screen-only",
           "review_note": manual.get(key, "Token inventory only; strings/comments included; does not prove ownership or safety"),
           "test_lexical_references_not_coverage_proof": "; ".join(p for p, body in tests.items() if key in body or key.replace("/", "\\") in body),
           "native_acceptance": "NOT RUN; user requested simulation only"}
    row.update({name + "_lines": " ".join(indices) for name, indices in locations.items()})
    rows.append(row)
with (HERE / "module_triage.csv").open("w", newline="", encoding="utf-8") as f:
    writer = csv.DictWriter(f, fieldnames=list(rows[0])); writer.writeheader(); writer.writerows(rows)
summary = {"captured_at_utc": datetime.now(timezone.utc).isoformat(), "lua_files_screened": len(rows),
           "toc_xml_reachable_lua": sum(r["toc_xml_reachable"] for r in rows),
           "manual_boundary_reviewed": sum(r["review_level"] == "manual-boundary-review" for r in rows),
           "manual_boundary_reviewed_reachable": sum(r["review_level"] == "manual-boundary-review" and r["toc_xml_reachable"] for r in rows),
           "limitations": "Lexical inventory includes strings/comments. TOC/XML reachability preserves declared conditions but does not model every client loader branch or dynamic loading. Manual review is of named boundaries, not proof of every statement. Test references are lexical associations only. No safety PASS is assigned.",
           "scope_exclusions": "Guild-bank and void-storage callback review remains excluded by AGENTS.md. Their presence in a scanned file is not a reviewed or executed callback.",
           "groups": {group: {"files": sum(r["path"].split("/")[0] == group for r in rows),
                              "reachable": sum(r["path"].split("/")[0] == group and r["toc_xml_reachable"] for r in rows),
                              "boundary_reviewed": sum(r["path"].split("/")[0] == group and r["review_level"] == "manual-boundary-review" for r in rows)}
                      for group in sorted({r["path"].split("/")[0] for r in rows})}}
(HERE / "module_triage_summary.json").write_text(json.dumps(summary, indent=2) + "\n", encoding="utf-8")
print(json.dumps({k: summary[k] for k in ("lua_files_screened", "toc_xml_reachable_lua", "manual_boundary_reviewed", "manual_boundary_reviewed_reachable")}, indent=2))
