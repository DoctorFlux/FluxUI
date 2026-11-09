"""Read-only addon stress runner; output is confined to this documentation folder."""
import hashlib
import json
import pathlib
import subprocess
import time
from datetime import datetime, timezone

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parent.parent
SCRIPTS = ["context_stress.lua.txt", "secure_input_stress.lua.txt", "mouseover_target_stress.lua.txt",
           "legacy_mouseover_stress.lua.txt", "hover_children_stress.lua.txt"]
MODELED_FAILURES = {"context_stress.lua.txt": "Known reproduced invalidation-loss finding INPUT-001",
                    "hover_children_stress.lua.txt": "Known reproduced child-scan finding INPUT-002"}


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def source_manifest():
    # Neither tests nor new documents are counted as production source.
    return {p.relative_to(ROOT).as_posix(): digest(p) for p in ROOT.rglob("*")
            if p.is_file() and p.suffix.lower() in {".lua", ".xml", ".toc"}
            and p.relative_to(ROOT).parts[0] not in {".git", "Stress test doc", "tests", "docs"}}


began = datetime.now(timezone.utc).isoformat()
before = source_manifest()
results = []
for repeat in range(1, 4):
    for script in SCRIPTS:
        started = time.perf_counter()
        try:
            proc = subprocess.run(["lua", str(HERE / script)], cwd=ROOT, text=True,
                                  capture_output=True, timeout=180)
            code, output = proc.returncode, proc.stdout + proc.stderr
        except (OSError, subprocess.TimeoutExpired) as error:
            code, output = -1, str(error)
        elapsed = time.perf_counter() - started
        log = HERE / f"{pathlib.Path(script).stem}-run-{repeat}.txt"
        log.write_text(output, encoding="utf-8")
        known_finding = (script in MODELED_FAILURES and code == 1
                         and sum(line.startswith("FAIL ") for line in output.splitlines()) == 15
                         and any(line.startswith("SUMMARY ") and "failures=15" in line for line in output.splitlines())
                         and "stack traceback" not in output)
        record = {"script": script, "repeat": repeat, "exit": code,
                  "status": "PASS" if code == 0 else "FINDING" if known_finding else "ERROR",
                  "finding": MODELED_FAILURES.get(script) if code else None,
                  "desktop_wall_seconds_not_native_performance": round(elapsed, 6),
                  "log": log.name, "log_sha256": digest(log),
                  "summary": [line for line in output.splitlines() if line.startswith(("SUMMARY", "METRIC", "Utility secure", "native mouseover"))]}
        results.append(record)
        print(f"{record['status']} repeat={repeat} {script} exit={code}", flush=True)

after = source_manifest()
changed = sorted(k for k in set(before) | set(after) if before.get(k) != after.get(k))
refs = []
for branch in ["live", "forever", "classic", "classic_era", "classic_anniversary"]:
    for part in ["Blizzard_FrameXML/SecureTemplates.lua", "Blizzard_ChatFrameBase/Shared/SlashCommands.lua",
                 "Blizzard_ClickBindingUI/Blizzard_ClickBindingUI.lua"]:
        path = ROOT.parent / "__AddonsForRef" / f"wow-ui-source-{branch}" / "Interface/AddOns" / part
        if path.exists():
            refs.append({"branch_folder": branch, "path": str(path), "sha256": digest(path),
                         "identity_scope": "On-disk fixture content; current task branch pins are in parent sources report"})
report = {"captured_at_utc": began, "finished_at_utc": datetime.now(timezone.utc).isoformat(),
          "runtime": subprocess.run(["lua", "-v"], capture_output=True, text=True).stdout.strip(),
          "scope": "Desktop production-code/Blizzard-Lua simulation only; no native secret values, secure VM, taint propagation, hardware dispatch, pixels, CPU/FPS acceptance.",
          "addon_code_modified_by_runner": False, "production_sources_before": before,
          "production_sources_after": after, "source_drift_paths": changed,
          "harnesses": {name: digest(HERE / name) for name in SCRIPTS},
          "fixtures": {name: digest(ROOT / "tests" / name) for name in ["utility_secure_input.lua", "mouseover_native.lua"]},
          "blizzard_local_fixture_files": refs, "runs": results,
          "harness_syntax": [{"script": name,
                              "exit": subprocess.run(["luac", "-p", str(HERE / name)], capture_output=True, text=True).returncode}
                             for name in SCRIPTS],
          "repeat_determinism": {name: len({tuple(r["summary"]) for r in results if r["script"] == name}) == 1 for name in SCRIPTS},
          "unexpected_errors": sum(r["status"] == "ERROR" for r in results)}
(HERE / "input-stress-results.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
print(json.dumps({"runs": len(results), "unexpected_errors": report["unexpected_errors"],
                  "source_drift_paths": changed, "deterministic": all(report["repeat_determinism"].values())}))
