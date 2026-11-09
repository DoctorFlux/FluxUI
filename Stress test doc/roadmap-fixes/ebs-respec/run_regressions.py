"""Replay frozen pre-change source and current production; no native game actions."""
import hashlib
import json
import pathlib
import subprocess
import time
import zipfile
from datetime import datetime, timezone

OUT = pathlib.Path(__file__).resolve().parent
ROOT = OUT.parents[2]
CHECKPOINT = json.loads((OUT.parent / "checkpoint.json").read_text())
ARCHIVE = pathlib.Path(CHECKPOINT["externalCheckpoint"]) / "source.zip"
BASELINE = ARCHIVE.parent.parent / "roadmap-fixes-ebs-respec-baseline"
BASELINE.mkdir(exist_ok=True)
with zipfile.ZipFile(ARCHIVE) as archive:
    for member in archive.infolist():
        destination = (BASELINE / member.filename).resolve()
        if not destination.is_relative_to(BASELINE.resolve()):
            raise RuntimeError("unsafe archive member")
    archive.extractall(BASELINE)

TESTS = [
    "tests/respec_equipment_completion.lua", "tests/respec_timer_ownership.lua",
    "tests/mount_vendor_cache.lua", "tests/buttonfx_paint_recovery.lua",
    "tests/respec_actionbar_completion.lua", "tests/respec_section_results.lua",
    "tests/alpha_reader_safety.lua", "tests/badge_cooldown_secrets.lua",
    "tests/utility_secure_input.lua", "tests/utility_mixed_faces.lua",
    "tests/utility_pet_faces.lua", "tests/utility_modifier_vfx.lua",
    "tests/consumable_usability.lua", "tests/consumable_zero_reset.lua",
    "tests/consumable_refresh_timer.lua", "tests/consumable_aura_advance.lua",
    "tests/idle_bars.lua", "tests/teleport_cast_work.lua",
    "ExtraButtonSystem/NonCombatGrid/Buttons/_tmp_mountitemsmoke.lua",
]
REJECTIONS = [
    ("R2-CORE-04", TESTS[0], "missing"),
    ("R2-CORE-05", TESTS[0], "cancel"),
    ("R2-CORE-01", TESTS[1], "picker"),
    ("R2-CORE-03-spec", TESTS[1], "spec"),
    ("R2-CORE-03-learn", TESTS[1], "learn"),
    ("R2-EBS-02", TESTS[2], "locale"),
    ("R2-EBS-03", TESTS[2], "cache"),
    ("R2-EBS-05", TESTS[2], "timers"),
    ("R2-EBS-01", TESTS[3], "legacy"),
    ("R2-EBS-04", TESTS[3], "charges"),
    ("R2-EBS-06", TESTS[3], "reticle"),
]
OWNED = list(json.loads((OUT / "source-freeze.json").read_text())["after"])
SOURCES = sorted(set(
    OWNED + TESTS + [p.relative_to(ROOT).as_posix() for folder in
                    ("Core/ButtonFX", "ExtraButtonSystem", "Respec")
                    for p in (ROOT / folder).rglob("*.lua")]
    + ["Core/Engine/Modifier.lua", "Core/API/Secrets.lua", "_FluxUI.toc",
       "Bars/BadgeHost.lua", "Core/ThreatGlow.lua"]
))
SOURCES = [p for p in SOURCES if (ROOT / p).is_file()]


def hashes():
    return {p: hashlib.sha256((ROOT / p).read_bytes()).hexdigest() for p in SOURCES}


def run(path, *args):
    started = time.perf_counter()
    completed = subprocess.run(["lua", str(ROOT / path), *map(str, args)], cwd=ROOT,
                               capture_output=True, text=True, timeout=90)
    return {"test": path, "args": list(map(str, args)), "exit": completed.returncode,
            "seconds": round(time.perf_counter() - started, 6),
            "stdout": completed.stdout, "stderr": completed.stderr}


before = hashes()
baseline_records = []
for finding, path, selection in REJECTIONS:
    original = run(path, BASELINE, selection)
    fixed = run(path, ROOT, selection)
    passed = original["exit"] != 0 and fixed["exit"] == 0
    baseline_records.append({"finding": finding, "oldRejectedNewAccepted": passed,
                             "baseline": original, "current": fixed})
    print(f"REJECTION {finding}: {'PASS' if passed else 'FAIL'}", flush=True)
records = []
for repeat in range(1, 4):
    for path in TESTS:
        result = run(path)
        result["repeat"] = repeat
        records.append(result)
        print(f"{repeat}: {'PASS' if result['exit'] == 0 else 'FAIL'} {path}", flush=True)
after = hashes()
drift = {p: {"before": before[p], "after": after[p]} for p in before if before[p] != after[p]}
varying = [path for path in TESTS if len({record["stdout"] for record in records if record["test"] == path}) != 1]
report = {"capturedUTC": datetime.now(timezone.utc).isoformat(), "checkpoint": str(ARCHIVE),
          "baseline": str(BASELINE), "sourceBefore": before, "sourceAfter": after,
          "drift": drift, "rejections": baseline_records, "records": records,
          "uniqueScripts": len(TESTS), "repeats": 3, "executionCount": len(records),
          "pass": sum(r["exit"] == 0 for r in records),
          "fail": sum(r["exit"] != 0 for r in records), "varyingStdout": varying,
          "scope": "Desktop Lua API models; no native taint, secure permission, pixels, FPS, or frame time claim."}
(OUT / "results.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
print(json.dumps({key: report[key] for key in ("uniqueScripts", "executionCount", "pass", "fail", "varyingStdout", "drift")}))
raise SystemExit(bool(report["fail"] or not all(r["oldRejectedNewAccepted"] for r in baseline_records)
                      or any(path in OWNED for path in drift)))
