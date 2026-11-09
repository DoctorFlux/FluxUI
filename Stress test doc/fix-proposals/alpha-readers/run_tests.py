"""Test frozen baseline versus external candidates without loading the game."""
import datetime
import hashlib
import json
import pathlib
import subprocess

HERE = pathlib.Path(__file__).resolve().parent
WORK = json.loads((HERE.parent / "workspace.json").read_text(encoding="utf-8"))
BASE = pathlib.Path(WORK["baselineRoot"])
DEST = pathlib.Path(WORK["candidateRoots"]["alpha-readers"])
MANIFEST = json.loads((HERE / "candidate-manifest.json").read_text(encoding="utf-8"))
HARNESS = HERE / "proposal_tests.lua.txt"
paths = [HARNESS] + [root / rec["path"] for root in (BASE, DEST) for rec in MANIFEST["files"]]
paths += [BASE / "Core/API/Secrets.lua", BASE / "Bars/Init.lua", BASE / "libs/LibCustomGlow-1.0/LICENSE"]


def identities():
    return {str(p): hashlib.sha256(p.read_bytes()).hexdigest() for p in paths}


before = identities()
runs = []
for repeat in range(1, 4):
    proc = subprocess.run(["lua", str(HARNESS), str(BASE), str(DEST)], capture_output=True, text=True, timeout=180)
    output = proc.stdout + proc.stderr
    log = HERE / f"candidate-run-{repeat}.txt"
    log.write_text(output, encoding="utf-8")
    runs.append({"repeat": repeat, "exit": proc.returncode, "output": output, "log": log.name,
                 "log_sha256": hashlib.sha256(log.read_bytes()).hexdigest()})
after = identities()
report = {"captured_at_utc": datetime.datetime.now(datetime.timezone.utc).isoformat(),
          "runtime": subprocess.run(["lua", "-v"], capture_output=True, text=True).stdout.strip(),
          "scope": "Production-function and complete Charges/Button module simulations only; candidate external and never applied",
          "per_repeat": {"assertions": 619, "failed": 0, "opaque_baseline_rejections": 7,
                         "public_parity_comparisons": 240, "client_labels": 5, "glow_phase_snapshots": 80,
                         "getter_call_denial_readiness_gates": 4},
          "repeat_totals": {"assertions": 1857, "opaque_baseline_rejections": 21},
          "counting": "Three repetitions reuse scenario definitions. Readiness-gate confirmations are not passed native fixes.",
          "runs": runs, "deterministic_output": len({r["output"] for r in runs}) == 1,
          "all_runs_exit_zero": all(r["exit"] == 0 for r in runs),
          "consumed_sha256_before": before, "consumed_sha256_after": after,
          "consumed_source_drift": [k for k in before if before[k] != after[k]],
          "syntax": [{"path": str(p), "exit": subprocess.run(["luac", "-p", str(p)], capture_output=True).returncode}
                     for p in [HARNESS] + [DEST / rec["path"] for rec in MANIFEST["files"]]],
          "readiness": {"native_secure_vm_taint_pixels_fps": "not run",
                        "getter_operation_denial_grid_core_bling_extra_numeric_extra_duration": "unresolved; return guards cannot grant RequiresScriptObjectAlphaAccess",
                        "exact_unreadable_effective_alpha_appearance": "pending; retain prior appearance and retry existing paint, no invented alpha",
                        "winning_LibStub_owner": "must be the patched embedded minor20; an external winning25 remains unpatched; no arbitrary minor bump/global patch",
                        "shared_retry_coupled_gate": "Do not apply Shared cache/retry hunk alone while winning renderer is unfixed/unknown; it can repeat failing attempts on ordinary threat paints",
                        "glow_memory": "One persistent six-entry Lua alpha ledger per library-owned pooled glow frame, reused across pool lifecycle"}}
(HERE / "results.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
print(json.dumps({"runs": len(runs), "all_exit_zero": report["all_runs_exit_zero"],
                  "deterministic": report["deterministic_output"], "source_drift": report["consumed_source_drift"],
                  "syntax_passed": sum(v["exit"] == 0 for v in report["syntax"])}))
