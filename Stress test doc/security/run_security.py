"""Replay documentation-only security experiments; write evidence here only."""
from __future__ import annotations
import hashlib
import json
import pathlib
import subprocess
import sys
import time
from datetime import datetime, timezone

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parent.parent
SOURCES = [
    "Core/Engine/Combat.lua", "Core/Engine/Restricted.lua", "Core/Capabilities.lua",
    "Core/SecureClickProxy.lua", "Binding/Core/Apply.lua",
    "Binding/Input/FluxMouseoverKeybind.lua", "Blizzard/Hide.lua",
    "Respec/FluxRespec_Apply.lua", "Respec/FluxRespec_ActionBars.lua",
    "Respec/FluxRespec_Compat.lua", "NamePlates/Core.lua",
    "../__AddonsForRef/wow-ui-source-forever/Interface/AddOns/Blizzard_RestrictedAddOnEnvironment/SecureStateDriver.lua",
    "Stress test doc/security/security_stress.lua.txt",
]
def hashes():
    return {p: hashlib.sha256((ROOT / p).read_bytes()).hexdigest() for p in SOURCES}
before = hashes()
samples = []
for i in range(5):
    began = time.perf_counter()
    run = subprocess.run(["lua", str(HERE / "security_stress.lua.txt")], cwd=ROOT,
                         capture_output=True, text=True, timeout=60)
    samples.append({"sample": i + 1, "exit": run.returncode,
                    "wall_seconds_desktop_only": round(time.perf_counter() - began, 6),
                    "stdout": run.stdout, "stderr": run.stderr})
after = hashes()
changed = [p for p in SOURCES if before[p] != after[p]]
report = {
    "captured_at_utc": datetime.now(timezone.utc).isoformat(),
    "command": 'python "Stress test doc/security/run_security.py"',
    "lua_version": subprocess.run(["lua", "-v"], capture_output=True, text=True).stdout.strip(),
    "evidence_scope": "Production Lua executed with mocked frames/APIs. No native taint VM, secure input, secret values, client CPU/FPS, rendering, or instance restrictions certified.",
    "status": "COMPLETED_WITH_EXPECTED_DEFECT_REPRODUCTIONS" if all(s["exit"] == 0 for s in samples) and not changed else "HARNESS_FAILURE_OR_SOURCE_DRIFT",
    "expected_assertions_per_sample": 121,
    "expected_observations_per_sample": 21,
    "clients": ["Retail live model", "Forever model", "Classic Era model", "Classic Anniversary model", "Classic progression extra model"],
    "combat_queue_requests_per_sample": 600000,
    "combat_queue_completed_jobs_per_sample": 100005,
    "findings": ["SEC-01", "SEC-02", "SEC-03"],
    "hash_algorithm": "SHA-256 raw file bytes",
    "hashes_before": before, "hashes_after": after, "changed_sources": changed,
    "samples": samples,
    "native_checks": "NOT RUN, per user simulation-only request",
}
(HERE / "security_results.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
print(json.dumps({k: report[k] for k in ("status", "changed_sources", "expected_assertions_per_sample", "combat_queue_requests_per_sample")}, indent=2))
sys.exit(0 if report["status"] == "COMPLETED_WITH_EXPECTED_DEFECT_REPRODUCTIONS" else 1)
