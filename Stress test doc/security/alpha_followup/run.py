"""Bounded alpha-family follow-up. Writes only this new documentation folder."""
from __future__ import annotations
import csv
import hashlib
import json
import pathlib
import re
import subprocess
from datetime import datetime, timezone

here = pathlib.Path(__file__).resolve().parent
root = here.parents[2]
reference = root.parent / "__AddonsForRef/wow-ui-source-forever/Interface/AddOns/Blizzard_SharedXMLBase/FrameUtil.lua"
data = reference.read_bytes().replace(b"\r\n", b"\n")
blob = hashlib.sha1(b"blob " + str(len(data)).encode() + b"\0" + data).hexdigest()
assert blob == "a1fe94ae627fe3c694d5c38df9f0d1a54eecb84d", "Native source drift from reused verified pin"
source_names = ["UnitFrames/FluxSwingTimer.lua", "Core/ButtonFX/Charges.lua", "Core/ButtonFX/Cast.lua",
                "ExtraButtonSystem/Engine/Button.lua", "ExtraButtonSystem/Engine/Style.lua", "Bars/BadgeHost.lua",
                "Bars/Blizzard.lua", "UnitFrames/FluxUnitFrames_Shared.lua", "libs/LibCustomGlow-1.0/LibCustomGlow-1.0.lua",
                "Stress test doc/security/alpha_followup/repro.lua.txt"]
sources = {p: root / p for p in source_names}
sources["external/Gethe/forever/FrameUtil.lua"] = reference
def hashes():
    return {name: hashlib.sha256(path.read_bytes()).hexdigest() for name, path in sources.items()}
before = hashes()
samples = []
for index in range(3):
    result = subprocess.run(["lua", str(here / "repro.lua.txt")], cwd=root,
                            capture_output=True, text=True, timeout=60)
    samples.append({"sample": index + 1, "exit": result.returncode,
                    "stdout": result.stdout, "stderr": result.stderr})
after = hashes()
family = []
getter_rows = []
aliases = []
screened = 0
for path in sorted(root.rglob("*")):
    if path.suffix.lower() not in {".lua", ".xml"}:
        continue
    relative = path.relative_to(root)
    if any(p.startswith(".") or p in {"tests", "docs", "new docs", "Stress test doc"} for p in relative.parts) or path.name.startswith("_tmp"):
        continue
    screened += 1
    for number, line in enumerate(path.read_text(encoding="utf-8-sig", errors="replace").splitlines(), 1):
        if re.search(r"\b(?:UIFrameFade\w*|UIFrameFlash\w*|FADEFRAMES|FLASHFRAMES)\b", line):
            family.append({"path": relative.as_posix(), "line": number, "text": line.strip()})
            if "=" in line and re.search(r"\bUIFrame(?:Fade|Flash)\w*\b\s*=|=\s*(?:_G\.)?UIFrame(?:Fade|Flash)\w*\b", line):
                aliases.append({"path": relative.as_posix(), "line": number, "text": line.strip()})
        if re.search(r"\bGet(?:Effective)?Alpha\b", line):
            getter_rows.append({"path": relative.as_posix(), "line": number, "text": line.strip()})
for name, rows in [("fade_family_inventory.csv", family), ("getter_review_locations.csv", getter_rows)]:
    with (here / name).open("w", newline="", encoding="utf-8") as file:
        writer = csv.DictWriter(file, fieldnames=["path", "line", "text"])
        writer.writeheader(); writer.writerows(rows)
report = {"captured_at_utc": datetime.now(timezone.utc).isoformat(),
          "status": "CONDITIONAL_ALPHA_FAILURES_REPRODUCED" if all(s["exit"] == 0 for s in samples) and before == after else "FAILED_OR_DRIFTED",
          "scope": "Production function fragments plus exact native manager with mock objects; unreadable alpha is a trapped table and scoped type() returns number. No native secret/taint VM, client frame attribution or whole-current-addon acceptance.",
          "user_error_recurrence_context": {"id": "USER-001", "client": "Forever as confirmed by user", "counts_by_reported_time": {"12:31:53": 2, "12:32:26": 1, "13:05:58": 2, "13:09:17": 2},
                                            "consolidated_count": 7, "duplicate_paste_blocks_not_recounted": True,
                                            "action_combat_instance_frame": "Unknown; user does not know preceding action; no further question needed"},
          "source_pin": {"ref": "9dc84f0d3bbae1768ac3405b3716000bd93eda06", "reference_version_not_runtime_capture": "1.60.1.70862",
                         "FrameUtil_git_blob": blob, "source_provenance": "Reuses verified source metadata in ../user-001-fade-results.json; normalized external file checked before this run",
                         "FrameUtil_url": "https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_SharedXMLBase/FrameUtil.lua"},
          "assertions_per_process": 125, "processes": 3,
          "finding_ids": ["ALPHA-01", "ALPHA-02", "ALPHA-03", "ALPHA-04", "ALPHA-05", "ALPHA-06"],
          "conditional_alpha_comparison_sites": 7, "loaded_library_conditional_arithmetic_sites": 2,
          "extra_legacy_only_comparison_site": 1, "expected_consumer_failures_per_process": 10,
          "native_family_controls": "IN/OUT default endpoints pass; opaque endpoints fail during interpolation then retire without requeue; .30s at .05s updates yielded5 errors and empty queue by1s; plain native flash completes",
          "busy_return_equivalence_controls_per_process": 84,
          "scan": {"lua_xml_files": screened, "fade_family_rows": len(family), "fade_family_source_files": sorted({r["path"] for r in family}),
                   "direct_named_alias_or_global_replacement_candidates": aliases, "getter_rows": len(getter_rows),
                   "limitations": "Lexical scanning includes comments/strings and does not resolve arbitrary reflection or dynamically composed names. Unloaded and client-gated sites are classified separately in report."},
          "sources_before": before, "sources_after": after,
          "changed_consumed_sources": [name for name in before if before[name] != after[name]],
          "concurrent_external_changes": "Root records other runtime/test changes; no full current-addon immutability or suite claim is made here.",
          "samples": samples}
(here / "results.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
print(json.dumps({k: report[k] for k in ("status", "assertions_per_process", "expected_consumer_failures_per_process", "changed_consumed_sources")}, indent=2))
print(json.dumps(report["scan"], indent=2))
raise SystemExit(report["status"] != "CONDITIONAL_ALPHA_FAILURES_REPRODUCED")
