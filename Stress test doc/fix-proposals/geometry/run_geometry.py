"""Repeated frozen-baseline/proposal comparisons, without touching live code."""
from pathlib import Path
from datetime import datetime, timezone
import hashlib
import json
import subprocess

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
workspace = json.loads((HERE.parent / "workspace.json").read_text(encoding="utf-8"))
candidate_meta = json.loads((HERE / "candidate.json").read_text(encoding="utf-8"))
files = {name: Path(candidate_meta[name]) for name in ("baseline", "candidate")}
files["rejected_experiment"] = Path(candidate_meta["rejected_experiment"])
prior_results = HERE / "results.json"
initial_results = HERE / "initial-matched-epoch-results.json"
if prior_results.exists() and not initial_results.exists():
    initial_results.write_bytes(prior_results.read_bytes())
live = ROOT / "UnitFrames/FluxUnitFrames_Shared.lua"
def digest(path): return hashlib.sha256(path.read_bytes()).hexdigest()
before = {name: digest(path) for name, path in files.items()}
live_before = digest(live)
samples = []
for repetition in range(1, 6):
    for variant, path, threat_only in (("baseline_geometry", files["baseline"], False),
                                      ("native_span_experiment", files["rejected_experiment"], False),
                                      ("baseline_threat", files["baseline"], True),
                                      ("selected_threat", files["candidate"], True)):
        command = ["lua", str(HERE / "test_candidate.lua.txt"), str(path)]
        if threat_only:
            command.append("--threat-only")
        result = subprocess.run(command,
                                cwd=ROOT, capture_output=True, text=True, timeout=60)
        metrics = []
        for line in result.stdout.splitlines():
            if not line.startswith(("RESULT|", "LIMIT|")):
                continue
            kind, case, *fields = line.split("|")
            row = {"kind": kind, "case": case}
            for field in fields:
                key, value = field.split("=", 1)
                try: value = int(value)
                except ValueError:
                    if value in {"true", "false"}: value = value == "true"
                row[key] = value
            metrics.append(row)
        samples.append({"variant": variant, "repetition": repetition, "exit_code": result.returncode,
                        "metrics": metrics, "stdout": result.stdout, "stderr": result.stderr})
after = {name: digest(path) for name, path in files.items()}
syntax = subprocess.run(["luac", "-p", str(files["candidate"])], cwd=ROOT, capture_output=True, text=True)
def section(path, first, last):
    text = path.read_text(encoding="utf-8"); start = text.index(first); stop = text.index(last, start + len(first))
    return text[start:stop]
unchanged_tiling = section(files["baseline"], "local function RefreshTiledOverlayTexCoords", "local function RefreshAbsorbShieldOverlay") == section(files["candidate"], "local function RefreshTiledOverlayTexCoords", "local function RefreshAbsorbShieldOverlay")
upstream = json.loads((HERE.parent / "upstream.json").read_text(encoding="utf-8"))
reference = ROOT.parent / "__AddonsForRef/wow-ui-source-forever/Interface/AddOns/Blizzard_APIDocumentationGenerated"
contracts = []
for row in upstream["geometryContracts"]:
    raw = (reference / row["name"]).read_bytes().replace(b"\r\n", b"\n")
    blob = hashlib.sha1(b"blob " + str(len(raw)).encode() + b"\0" + raw).hexdigest()
    assert blob == row["gitBlob"], "Pinned geometry contract changed"
    contracts.append({**row, "normalized_local_blob": blob, "matches_current_pin": True})
accepted = (all(sample["exit_code"] == 0 for sample in samples if sample["variant"] == "selected_threat")
            and all(sample["exit_code"] != 0 for sample in samples if sample["variant"] == "baseline_threat")
            and before == after and syntax.returncode == 0)
counterexamples = [metric for sample in samples if sample["variant"] == "native_span_experiment"
                   for metric in sample["metrics"] if metric["case"] == "desynchronized_health_fill"]
rejected = len(counterexamples) == 5 and all(metric["matches_existing"] is False for metric in counterexamples)
report = {"captured_at_utc": datetime.now(timezone.utc).isoformat(),
          "scope": "Exact production function fragments from frozen baseline/isolated candidate. Mock native StatusBar geometry and artificial opaque traps; no native secret VM, combat/taint or pixel certification.",
          "selected_threat_cache_baseline_rejected_candidate_passed": accepted,
          "selected_Shared_ready_to_apply_independently": False,
          "selected_Shared_gate": "Matching patched winning LCG and its ownership/readiness checks; otherwise changed retry semantics could increase repeated failed starts.",
          "GEO-01_ready_to_apply": False,
          "GEO-01_native_span_rejected_by_counterexample": rejected,
          "GEO-01_selected_geometry_change": False,
          "candidate_syntax_exit": syntax.returncode, "candidate_syntax_output": syntax.stdout + syntax.stderr,
          "sources_before": before, "sources_after": after,
          "live_Shared_sha256_before": live_before, "live_Shared_sha256_after": digest(live),
          "live_Shared_unchanged_during_test": live_before == digest(live),
          "GEO-02_source_unchanged": unchanged_tiling,
          "contracts": contracts,
          "candidate_path": str(files["candidate"]), "rejected_experiment_path": str(files["rejected_experiment"]), "tests": samples,
          "prior_conditional_results": "initial-matched-epoch-results.json retained unchanged; its native-span successes assumed health-fill/calculator epoch agreement and are not feature-parity acceptance.",
          "unresolved": ["Other existing UpdateFillPosition paths still reject inaccessible geometry in the explicit layered opaque model.",
                         "Opaque geometry with no GetMissingHealth method is explicitly unsupported; public geometry uses the retained compatibility path.",
                         "Native anchor/StatusBar fill pixels, secrecy/provenance and exact tiled-art frequency are not certified."]}
(HERE / "results.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
print(json.dumps({key: report[key] for key in ("selected_threat_cache_baseline_rejected_candidate_passed", "GEO-01_native_span_rejected_by_counterexample", "GEO-01_ready_to_apply", "candidate_syntax_exit", "GEO-02_source_unchanged", "live_Shared_unchanged_during_test")}))
for variant in ("baseline_geometry", "native_span_experiment", "baseline_threat", "selected_threat"):
    print(variant, json.dumps(next(sample for sample in samples if sample["variant"] == variant)["metrics"][-1]))
raise SystemExit(0 if accepted and rejected else 1)
