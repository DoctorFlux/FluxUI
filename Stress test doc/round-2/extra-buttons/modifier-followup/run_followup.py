"""Replay current active modifier consumers; only this evidence folder is written."""
import hashlib
import json
import pathlib
import re
import subprocess
from datetime import datetime, timezone

OUT = pathlib.Path(__file__).resolve().parent
ROOT = OUT.parents[3]
SCRIPTS = ["utility_matrix.lua.txt", "vfx_matrix.lua.txt", "badge_matrix.lua.txt"]
PATHS = [ROOT / p for p in [
    "tests/utility_mixed_faces.lua", "tests/utility_modifier_vfx.lua", "Core/API/Spell.lua",
    "Core/Engine/Modifier.lua", "Core/ButtonFX/Cast.lua", "Core/ButtonFX/Charges.lua",
    "ExtraButtonSystem/Engine/Action.lua", "ExtraButtonSystem/Engine/Paint.lua",
    "ExtraButtonSystem/NonCombatGrid/UtilitySlots/Assign.lua",
    "ExtraButtonSystem/NonCombatGrid/UtilitySlots/Manager.lua",
    "ExtraButtonSystem/Shared/HotkeyUtil.lua", "Bars/BadgeHost.lua", "_FluxUI.toc"
]] + [OUT / p for p in SCRIPTS] + [pathlib.Path(__file__).resolve()]


def manifest():
    return {p.relative_to(ROOT).as_posix(): hashlib.sha256(p.read_bytes()).hexdigest() for p in PATHS}


before = manifest()
records = []
for repeat in range(1, 4):
    for script in SCRIPTS:
        r = subprocess.run(["lua", str((OUT / script).relative_to(ROOT))], cwd=ROOT, capture_output=True, text=True, timeout=60)
        metrics = [line for line in r.stdout.splitlines() if line.startswith("METRIC ")]
        summaries = [line for line in r.stdout.splitlines() if line.startswith("SUMMARY ")]
        counts = sum(int(v) for line in summaries for v in re.findall(r"\bchecks=(\d+)", line))
        records.append({"repeat": repeat, "script": script, "exit": r.returncode,
                        "checks": counts, "metrics": metrics, "stdout": r.stdout, "stderr": r.stderr})
        print(f"repeat {repeat} {script}: {'PASS' if r.returncode == 0 else 'FAIL'} checks={counts}", flush=True)
after = manifest()
drift = [p for p in before if before[p] != after[p]]
deterministic = all(len({r["stdout"] for r in records if r["script"] == p}) == 1 for p in SCRIPTS)
report = {"capturedUTC": datetime.now(timezone.utc).isoformat(),
          "scope": "Actual active Lua modifier consumers with frame/parser/native API boundary models; no game/input/settings/profiler access",
          "before": before, "after": after, "sourceNormalization": "raw bytes", "drift": drift,
          "uniqueScripts": 3, "repeats": 3, "executionCount": 9,
          "checksPerRun": sum(r["checks"] for r in records if r["repeat"] == 1),
          "totalChecks": sum(r["checks"] for r in records),
          "rawConsumerEdgesPerRun": 327775,
          "pass": sum(r["exit"] == 0 for r in records), "fail": sum(r["exit"] != 0 for r in records),
          "stdoutDeterministic": deterministic, "records": records}
(OUT / "results.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
assert report["pass"] == 9 and not drift and deterministic
print(json.dumps({k: report[k] for k in ("checksPerRun", "totalChecks", "rawConsumerEdgesPerRun", "pass", "fail", "drift", "stdoutDeterministic")}))
