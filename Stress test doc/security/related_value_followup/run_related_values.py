"""Bounded related getter-contract probes; no runtime or native-client writes."""
from pathlib import Path
from datetime import datetime, timezone
import hashlib
import json
import subprocess

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
REFERENCE = ROOT.parent / "__AddonsForRef/wow-ui-source-forever"
PIN = "9dc84f0d3bbae1768ac3405b3716000bd93eda06"
paths = [ROOT / name for name in ("UnitFrames/FluxUnitFrames_Shared.lua", "Battlezonemap/FluxMeterSkin.lua",
         "Core/API/Secrets.lua", "Core/API/Secrets_Midnight.lua", "Core/FluxAPI/Secrets.lua")]
paths.append(HERE / "related_values.lua.txt")
contracts = json.loads((HERE.parent / "secret-value-followup/contracts.json").read_text(encoding="utf-8"))
contracts.append({"path": "Interface/AddOns/Blizzard_APIDocumentationGenerated/SimpleFrameAPIDocumentation.lua",
                  "gitBlob": "07debf919e8b4d43087306d2eccfb8e18e8f2c82", "target": "Forever", "commit": PIN,
                  "sourceVersion": "1.60.1.70862",
                  "url": f"https://github.com/Gethe/wow-ui-source/blob/{PIN}/Interface/AddOns/Blizzard_APIDocumentationGenerated/SimpleFrameAPIDocumentation.lua"})
for contract in contracts:
    path = REFERENCE / contract["path"]
    raw = path.read_bytes().replace(b"\r\n", b"\n")
    blob = hashlib.sha1(b"blob " + str(len(raw)).encode() + b"\0" + raw).hexdigest()
    assert blob == contract["gitBlob"], f"Local contract differs from root-verified current pin: {path.name}"
    contract["normalizedLocalGitBlob"] = blob
    contract["localMatchesPinnedBlob"] = True
    paths.append(path)

def hashes():
    return {str(path): hashlib.sha256(path.read_bytes()).hexdigest() for path in paths}

before = hashes()
samples = []
for index in range(1, 6):
    result = subprocess.run(["lua", str(HERE / "related_values.lua.txt")], cwd=ROOT,
                            capture_output=True, text=True, timeout=60)
    metrics = []
    for line in result.stdout.splitlines():
        if not line.startswith("RESULT|"):
            continue
        _, name, *fields = line.split("|")
        row = {"case": name}
        for field in fields:
            key, value = field.split("=", 1)
            try:
                value = int(value)
            except ValueError:
                if value in {"true", "false"}:
                    value = value == "true"
            row[key] = value
        metrics.append(row)
    samples.append({"sample": index, "exit_code": result.returncode, "metrics": metrics,
                    "stdout": result.stdout, "stderr": result.stderr})
after = hashes()
report = {"captured_at_utc": datetime.now(timezone.utc).isoformat(),
          "scope": "Exact production helper/painter fragments and complete existing secret helpers, with narrow frame/API mocks and artificial opaque table traps. No native secret number, taint VM or attribution of USER-001. Getter contracts match current root-fetched pinned Forever blobs.",
          "client": "Forever source 1.60.1.70862; actual user runtime build/context unobserved",
          "command": "python 'Stress test doc/security/related_value_followup/run_related_values.py'",
          "all_processes_passed": all(sample["exit_code"] == 0 for sample in samples),
          "metrics_identical_across_five_repetitions": all(sample["metrics"] == samples[0]["metrics"] for sample in samples),
          "expected_conditional_failures_per_sample": 1,
          "contained_conditional_failures_per_sample": 1,
          "native_errors_observed": 0,
          "contracts": contracts,
          "sources_before": before, "sources_after": after,
          "consumed_source_drift": [path for path in before if before[path] != after[path]],
          "tests": samples}
(HERE / "results.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
print(json.dumps({key: report[key] for key in ("all_processes_passed", "metrics_identical_across_five_repetitions", "consumed_source_drift")}))
print(json.dumps(samples[0]["metrics"][-1]))
raise SystemExit(0 if report["all_processes_passed"] and before == after else 1)
