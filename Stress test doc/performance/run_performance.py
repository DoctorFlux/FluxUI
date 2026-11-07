"""Read-only production inspection and desktop Lua stress replay; writes here only."""
from __future__ import annotations
import csv
import hashlib
import importlib.util
import json
from pathlib import Path
import subprocess
import sys
import time
from collections import Counter
from datetime import datetime, timezone

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
sys.dont_write_bytecode = True
spec = importlib.util.spec_from_file_location("flux_source_inventory", ROOT / "docs/tools/source_inventory.py")
inventory = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = inventory
spec.loader.exec_module(inventory)

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

graph = inventory.load_graph()
active = {rel: rec for rel, rec in graph["reachable"].items() if rel.endswith(".lua")}
baseline = {rel: digest(ROOT / rel) for rel in sorted(active) if (ROOT / rel).is_file()}
sites, modules = [], {}
for rel in sorted(baseline):
    path = ROOT / rel
    source = path.read_text(encoding="utf-8-sig", errors="replace")
    ts = inventory.tokens(source)
    counts = Counter()
    for i, token in enumerate(ts):
        name = token.value
        if i + 1 >= len(ts) or ts[i + 1].value != "(" or (i and ts[i - 1].value == "function"):
            continue
        category = None
        if name in {"SetScript", "HookScript"}:
            args = inventory.call_args(source, ts, i)
            if args and inventory.literal(args[0]) == "OnUpdate":
                category = "on_update_detach" if len(args) > 1 and args[1].strip() == "nil" else "on_update_hook" if name == "HookScript" else "on_update_attach"
        elif name == "NewTicker":
            category = "ticker_create"
        elif name in {"After", "NewTimer"}:
            category = "timer_schedule"
        elif name in {"RegisterEvent", "RegisterUnitEvent"}:
            category = "native_event_register"
        elif name == "hooksecurefunc":
            category = "secure_posthook"
        elif name in {"Register", "Add", "Subscribe"}:
            context = "".join(t.value for t in ts[max(0, i - 8):i])
            if any(owner in context for owner in ("Events.", "Ev.", "Ticker.", "Scheduler.", "Modifier.")):
                category = "shared_service_subscribe"
        if not category:
            continue
        args = inventory.call_args(source, ts, i)
        counts[category] += 1
        sites.append({"path": rel, "line": inventory.line_at(source, token.start), "category": category,
                      "call": name, "arguments": " | ".join(args).replace("\n", " ")[:240],
                      "loaded_clients": ";".join(active[rel]["clients"]), "raw_sha256": baseline[rel],
                      "ownership": "bundled library" if rel.startswith("libs/") else "addon"})
    module = rel.split("/")[0] if "/" in rel else "root"
    row = modules.setdefault(module, {"module": module, "loaded_lua_files": 0, "loaded_lua_lines": 0, **{k: 0 for k in (
        "on_update_attach", "on_update_hook", "on_update_detach", "ticker_create", "timer_schedule",
        "native_event_register", "secure_posthook", "shared_service_subscribe")}})
    row["loaded_lua_files"] += 1
    row["loaded_lua_lines"] += len(source.splitlines())
    for key, value in counts.items():
        row[key] += value

def write_csv(name, rows, keys=None):
    with (HERE / name).open("w", encoding="utf-8", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=keys or list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)

write_csv("driver-sites.csv", sites)
write_csv("module-summary.csv", [modules[k] for k in sorted(modules)])
inspection = {"captured_at_utc": datetime.now(timezone.utc).isoformat(),
              "scope": "TOC/XML reachable Lua only; all configured game-type load paths are recorded. Lexical driver sites are candidates, not active resources or measured hotspots.",
              "counts": {"loaded_lua_files": len(baseline), "driver_candidate_sites": len(sites), "modules": len(modules)},
              "load_graph_missing": graph.get("missing", []),
              "raw_source_sha256": baseline,
              "module_totals": [modules[k] for k in sorted(modules)]}
(HERE / "source-inventory.json").write_text(json.dumps(inspection, indent=2) + "\n", encoding="utf-8")

runs = []
for script in ("stress_services.lua.txt", "stress_raid_scaling.lua.txt", "stress_hotloops.lua.txt", "stress_auction_sustained.lua.txt"):
    for repetition in range(1, 6):
        started = time.perf_counter()
        process = subprocess.run(["lua", str(HERE / script)], cwd=ROOT, capture_output=True, text=True, timeout=120)
        metrics = []
        for line in process.stdout.splitlines():
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
        runs.append({"script": script, "script_sha256": digest(HERE / script), "repetition": repetition,
                     "exit_code": process.returncode,
                     "desktop_wall_seconds": round(time.perf_counter() - started, 5),
                     "metrics": metrics, "stdout": process.stdout, "stderr": process.stderr})
        print(f"{script} repetition {repetition}: exit={process.returncode}, cases={len(metrics) - 1}", flush=True)

after = {rel: digest(ROOT / rel) for rel in baseline}
drift = [rel for rel in baseline if baseline[rel] != after[rel]]
identical = {}
for script in sorted({run["script"] for run in runs}):
    group = [run for run in runs if run["script"] == script]
    identical[script] = all(run["metrics"] == group[0]["metrics"] for run in group)
report = {"captured_at_utc": datetime.now(timezone.utc).isoformat(),
          "scope": "Unchanged production modules/source slices executed in desktop Lua with mocked widgets and APIs. Counts measure these modeled calls only; not native CPU/FPS, rendering, genuine secrets, secure input or taint safety.",
          "runtime": subprocess.run(["lua", "-v"], capture_output=True, text=True).stdout.strip(),
          "repetitions": 5, "tests": runs,
          "all_processes_passed": all(run["exit_code"] == 0 for run in runs),
          "deterministic_metrics_across_repetitions": identical,
          "production_source_drift": drift,
          "before_raw_source_sha256": baseline,
          "after_changed_raw_source_sha256": {rel: after[rel] for rel in drift},
          "harness_corrections": ["Initial raid harness called health API query count 'paints' and expected one; real status text and health bar make two health queries per member. Corrected to count StatusBar:SetValue writes and report health_queries separately. This was a harness expectation error, not an addon failure."]}
(HERE / "performance-results.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
print(json.dumps({"all_processes_passed": report["all_processes_passed"], "metrics_identical": identical,
                  "production_source_drift": drift, "inventory": inspection["counts"]}, indent=2))
sys.exit(0 if report["all_processes_passed"] else 1)
