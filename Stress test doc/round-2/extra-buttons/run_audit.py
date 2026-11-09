"""Read-only addon execution; write evidence only beside this script."""
import hashlib
import json
import pathlib
import subprocess
import sys
import time
from datetime import datetime, timezone

OUT = pathlib.Path(__file__).resolve().parent
ROOT = OUT.parents[2]
TESTS = [
    "tests/utility_secure_input.lua", "tests/utility_mixed_faces.lua",
    "tests/utility_pet_faces.lua", "tests/utility_modifier_vfx.lua",
    "tests/consumable_zero_reset.lua", "tests/consumable_restock_clicks.lua",
    "tests/consumable_weapon_targets.lua", "tests/consumable_aura_advance.lua",
    "tests/consumable_config_visibility.lua", "tests/consumable_refresh_timer.lua",
    "tests/syndicator_consumable_updates.lua", "tests/restock_charge_bank_iterator.lua",
    "tests/extra_startup.lua", "tests/alpha_reader_safety.lua",
    "tests/badge_cooldown_secrets.lua", "tests/forever_badge_combat_row_swap.lua",
    "tests/forever_sao_badge_preparation.lua", "tests/idle_bars.lua",
    "tests/teleport_cast_work.lua",
    "ExtraButtonSystem/Engine/_tmp_consumablesmoke.lua",
    "ExtraButtonSystem/NonCombatGrid/Buttons/_tmp_mountitemsmoke.lua",
    "ExtraButtonSystem/CombatGrid/Buttons/_tmp_ammosmoke.lua",
    "Stress test doc/round-2/extra-buttons/ebs_round2.lua.txt",
    "Stress test doc/round-2/extra-buttons/reticle_disabled.lua.txt",
    "Stress test doc/round-2/extra-buttons/mount_timer.lua.txt",
]
AUDIT_ONLY = "--audit-only" in sys.argv
RUN_TESTS = [p for p in TESTS if p.startswith("Stress test doc/")] if AUDIT_ONLY else TESTS
SOURCES = sorted(set(
    list(ROOT.joinpath("ExtraButtonSystem").rglob("*.lua"))
    + list(ROOT.joinpath("Core/ButtonFX").rglob("*.lua"))
    + [ROOT / "Bars/BadgeHost.lua"]
    + [ROOT / "_FluxUI.toc", ROOT / "Core/API/Secrets.lua", ROOT / "Core/Engine/Modifier.lua"]
    + [ROOT / p for p in TESTS]
    + list(ROOT.joinpath("tests/fixtures").glob("*.txt"))
))


def manifest():
    return {p.relative_to(ROOT).as_posix(): hashlib.sha256(p.read_bytes()).hexdigest() for p in SOURCES}


before = manifest()
records = []
for repeat in range(1, 4):
    for path in RUN_TESTS:
        start = time.perf_counter()
        r = subprocess.run(["lua", path], cwd=ROOT, capture_output=True, text=True, timeout=90)
        record = {"repeat": repeat, "path": path, "exit": r.returncode,
                  "seconds": round(time.perf_counter() - start, 6),
                  "stdout": r.stdout, "stderr": r.stderr}
        if path.endswith("ebs_round2.lua.txt") and r.returncode == 0:
            record["semanticResults"] = json.loads(next(line[7:] for line in r.stdout.splitlines() if line.startswith("RESULT ")))
        records.append(record)
        print(f"{repeat}: {'PASS' if r.returncode == 0 else 'FAIL'} {path}", flush=True)
after = manifest()
drift = [p for p in before if before[p] != after[p]]
varying = [path for path in RUN_TESTS if len({r["stdout"] for r in records if r["path"] == path}) != 1]
deterministic = not varying
report = {"capturedUTC": datetime.now(timezone.utc).isoformat(),
          "scope": "Actual Lua in desktop mocks; no native gameplay/input/taint/pixels/FPS.",
          "sourceNormalization": "raw bytes", "before": before, "after": after, "drift": drift,
          "uniqueTestScripts": len(RUN_TESTS), "repeats": 3, "executionCount": len(records),
          "pass": sum(r["exit"] == 0 for r in records), "fail": sum(r["exit"] != 0 for r in records),
          "stdoutDeterministic": deterministic, "varyingStdoutPaths": varying, "records": records}
(OUT / ("audit-results.json" if AUDIT_ONLY else "results.json")).write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
print(json.dumps({k: report[k] for k in ("uniqueTestScripts", "executionCount", "pass", "fail", "drift", "stdoutDeterministic")}))
raise SystemExit(bool(report["fail"] or drift))
