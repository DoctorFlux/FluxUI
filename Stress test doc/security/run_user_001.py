"""USER-001 source pin comparison, fade inventory, and bounded conditional reproducer."""
from __future__ import annotations
import csv
import hashlib
import json
import pathlib
import re
import subprocess
from datetime import datetime, timezone

here = pathlib.Path(__file__).resolve().parent
root = here.parent.parent
reference = root.parent / "__AddonsForRef/wow-ui-source-forever/Interface/AddOns/Blizzard_SharedXMLBase/FrameUtil.lua"
pin = "9dc84f0d3bbae1768ac3405b3716000bd93eda06"
blob = "a1fe94ae627fe3c694d5c38df9f0d1a54eecb84d"
normalized = reference.read_bytes().replace(b"\r\n", b"\n")
actual_blob = hashlib.sha1(b"blob " + str(len(normalized)).encode() + b"\0" + normalized).hexdigest()
assert actual_blob == blob, "External reference does not match freshly fetched pinned source"
sources = [root / "UnitFrames/FluxCastBar.lua", root / "UnitFrames/FluxSwingTimer.lua", reference,
           here / "user-001-fade-repro.lua.txt"]
def hashes():
    return {str(p): hashlib.sha256(p.read_bytes()).hexdigest() for p in sources}
before = hashes()
samples = []
for index in range(3):
    r = subprocess.run(["lua", str(here / "user-001-fade-repro.lua.txt")], cwd=root,
                       capture_output=True, text=True, timeout=60)
    samples.append({"sample": index + 1, "exit": r.returncode, "stdout": r.stdout, "stderr": r.stderr})
after = hashes()
rows = []
for path in sorted(root.rglob("*.lua")):
    relative = path.relative_to(root)
    if any(part.startswith(".") or part in {"tests", "docs", "new docs", "Stress test doc"} for part in relative.parts) or path.name.startswith("_tmp"):
        continue
    for line, text in enumerate(path.read_text(encoding="utf-8-sig", errors="replace").splitlines(), 1):
        if re.search(r"\b(?:UIFrameFade\w*|UIFrameFlash\w*|FADEFRAMES|FLASHFRAMES|startAlpha|endAlpha|fadeInfo|SetAlpha|SetAlphaFromBoolean|GetAlpha|GetEffectiveAlpha)\b", text):
            rows.append({"path": relative.as_posix(), "line": line, "text": text.strip(),
                         "classification": "lexical location, not proof of taint origin"})
with (here / "user-001-alpha-inventory.csv").open("w", newline="", encoding="utf-8") as f:
    w = csv.DictWriter(f, fieldnames=list(rows[0])); w.writeheader(); w.writerows(rows)
report = {"captured_at_utc": datetime.now(timezone.utc).isoformat(), "id": "USER-001",
          "status": "CONDITIONAL_MODELED_FAILURE_REPRODUCED" if all(s["exit"] == 0 for s in samples) and before == after else "HARNESS_FAILED_OR_DRIFTED",
          "user_runtime_report": {"client": "Forever, confirmed by user", "time_as_reported": "12:31:53; timezone not established",
                                  "copies_reported": 2, "native_sink": "Blizzard_SharedXMLBase/FrameUtil.lua:427; UIFrameFade_OnUpdate defined at410",
                                  "message": "attempt to perform arithmetic on field 'startAlpha' (a secret number value, while execution tainted by '_FluxUI')",
                                  "frame_action_combat_instance_context": "Not supplied; actual frame and taint origin unresolved"},
          "source": {"repository": "Gethe/wow-ui-source", "ref": pin, "version_reference": "1.60.1.70862, not a captured runtime build",
                     "path": "Interface/AddOns/Blizzard_SharedXMLBase/FrameUtil.lua", "fresh_connector_git_blob": blob,
                     "url": f"https://github.com/Gethe/wow-ui-source/blob/{pin}/Interface/AddOns/Blizzard_SharedXMLBase/FrameUtil.lua",
                     "external_local_path": str(reference), "normalization": "CRLF to LF only", "local_git_blob_normalized": actual_blob,
                     "local_matches_fresh_pin": actual_blob == blob, "sha256_normalized": hashlib.sha256(normalized).hexdigest(),
                     "alpha_contract_blob": "07debf919e8b4d43087306d2eccfb8e18e8f2c82",
                     "alpha_contract": "SimpleFrame GetAlpha SecretReturnsForAspect Alpha, freshly fetched at same pin; setter does not certify caller-readable return",
                     "native_chat_fade_path": "Interface/AddOns/Blizzard_ChatFrameBase/Mainline/FloatingChatFrame.lua",
                     "native_chat_fade_blob": "79b858cabb85869716b8374980659bf802bf3be9",
                     "native_chat_fade_lines_retrieved": "1210-1304; shared native OUT callers are alternatives, not attribution; runtime family loading remains unobserved"},
          "model_limits": "Actual production fade-start function fragments and exact pinned native fade manager executed with mocked frames. Opaque alpha represented by table metamethod trap; not native secret-number or taint VM. Both callers are conditional candidates, not attribution.",
          "candidate_sources": [{"path": "UnitFrames/FluxCastBar.lua", "line": 1291, "rank": "leading-direct-supplier", "alpha": "self:GetAlpha() after SetAlpha(1)", "duration": "finish0.75s / interrupt0.30s"},
                                {"path": "UnitFrames/FluxSwingTimer.lua", "line": 1167, "rank": "leading-direct-supplier", "alpha": "swingFrame:GetAlpha()", "duration": "1.0s"}],
          "experiment_only": "In-memory fragment controls use known public alpha1 for cast or modeled tracked swing alpha. No production fix applied or visually accepted.",
          "assertions_per_sample": 33, "expected_failures_per_sample": 6,
          "alpha_inventory_rows": len(rows), "sources_before": before, "sources_after": after,
          "changed_sources": [p for p in before if before[p] != after[p]], "samples": samples}
(here / "user-001-fade-results.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
print(json.dumps({k: report[k] for k in ("status", "alpha_inventory_rows", "changed_sources")}, indent=2))
raise SystemExit(report["status"] != "CONDITIONAL_MODELED_FAILURE_REPRODUCED")
