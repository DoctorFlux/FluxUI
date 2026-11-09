"""Focused applied geometry evidence; no game/settings/input/profiler writes."""
from pathlib import Path
from datetime import datetime, timezone
import hashlib
import json
import subprocess

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
checkpoint = json.loads((HERE.parent / "checkpoint.json").read_text(encoding="utf-8"))
baseline = Path(checkpoint["externalCheckpoint"]).parent / "fix-proposals-20261107T122821Z/baseline/UnitFrames/FluxUnitFrames_Shared.lua"
expected = next(row["sha256"] for row in checkpoint["files"] if row["path"] == "UnitFrames/FluxUnitFrames_Shared.lua")
assert hashlib.sha256(baseline.read_bytes()).hexdigest() == expected, "Baseline differs from pre-apply checkpoint"
runtime = [f"UnitFrames/FluxUnitFrames_{name}.lua" for name in
           ("Shared", "OptionsBridge", "Party", "PetTarget", "FocusTarget", "Pet", "TargetOfTarget")]
tests = ["tests/prediction_public_geometry.lua", "tests/public_geometry_writers.lua",
         "tests/idle_unit_geometry.lua", "tests/portrait_camera.lua", "tests/unit_power_visibility.lua",
         "tests/unit_frame_whole_scale.lua", "tests/unitframes_lifecycle_spec.lua", "tests/raid_party_frames.lua"]
consumed = runtime + tests + [str(HERE.relative_to(ROOT) / "boundary_pair.lua.txt"), str(HERE.relative_to(ROOT) / "run_geometry.py")]
def hashes():
    return {path: hashlib.sha256((ROOT / path).read_bytes()).hexdigest() for path in consumed}
def run(command):
    p = subprocess.run(command, cwd=ROOT, capture_output=True, text=True, timeout=90)
    return {"command": command, "exitCode": p.returncode, "stdout": p.stdout, "stderr": p.stderr}
before = hashes()
samples = []
for repetition in range(1, 4):
    samples.append({"repetition": repetition, "tests": [run(["lua", path]) for path in tests]})
pairs = [run(["lua", str(HERE / "boundary_pair.lua.txt"), str(baseline), "baseline"]),
         run(["lua", str(HERE / "boundary_pair.lua.txt"), "UnitFrames/FluxUnitFrames_Shared.lua", "applied"])]
syntax = [run(["luac", "-p", path]) for path in runtime + tests]
after = hashes()
out = {
    "capturedUTC": datetime.now(timezone.utc).isoformat(),
    "scope": "Actual production factories, painters, public layout owners, helpers and finite camera logic in desktop API/rectangle mocks. Artificial opaque traps; no native secret VM, taint provenance, rendering, FPS or native profiling certification.",
    "baselinePath": str(baseline), "baselineMatchesFreshCheckpointSHA256": expected,
    "findings": {"GEO-01": "APPLIED; public owned dimensions retain full-width/maxHP normalization; native validation pending",
                 "GEO-02": "APPLIED; native fill clips public 32px canvas; native pixels/taint validation pending"},
    "resourceCostPerHealthFrame": {"modernClipFrames": 3, "classicClipFrames": 2, "recurringDrivers": 0, "newEventsTimers": 0},
    "focusedAssertionsPerRepetition": {"predictionGeometry": 8460, "publicWriterRoutes": 80, "portraitGeometry": 1547, "portraitCamera": 1191, "lifecycle": 373},
    "drawOrder": "Clip exact bar frame level/inherited strata; original textures reused; ARTWORK sublevel1 shield/2 antiheal, existing edgeglow owner+4 and text owner+30 remain above owner+3 stripes.",
    "phase": "Full public canvas UV W/32,H/32 cropped natively at fill. Visible coordinate at distance x from physical fill left is x/32, including reverse overflow fill. No snapshot-dependent normalization.",
    "unknownGeometry": "All owned constructors capture public dimensions before first prediction; compatibility getters are gated. If neither owned public dimensions nor readable fallback exists, no opaque geometry setter or fabricated zero is used; that external incomplete owner is explicitly unsupported until public layout becomes available.",
    "retiredProposal": "Remaining-health-span normalization remains rejected:250px drawn60%, calc40%, absorb20% yields33.3333px versus required50px. Not applied.",
    "boundaryPairs": pairs, "samples": samples, "syntax": syntax,
    "sourcesBefore": before, "sourcesAfter": after,
    "consumedSourceDrift": [path for path in before if before[path] != after[path]],
}
out["allPassed"] = before == after and all(test["exitCode"] == 0 for sample in samples for test in sample["tests"]) and all(p["exitCode"] == 0 for p in pairs + syntax)
(HERE / "results.json").write_text(json.dumps(out, indent=2) + "\n", encoding="utf-8")
print(json.dumps({"allPassed": out["allPassed"], "repetitions": len(samples), "testsPerRepetition": len(tests), "consumedSourceDrift": out["consumedSourceDrift"]}))
for p in pairs:
    print(p["stdout"].strip())
    if p["exitCode"]: print(p["stderr"])
raise SystemExit(0 if out["allPassed"] else 1)
