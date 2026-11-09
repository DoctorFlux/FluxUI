"""Run standalone addon checks; no WoW client or SavedVariables are modified."""
import argparse
import hashlib
import json
import pathlib
import subprocess
import sys
import time
from datetime import datetime, timezone

parser = argparse.ArgumentParser()
parser.add_argument("--output", type=pathlib.Path)
parser.add_argument("--sync-docs", action="store_true", help="Update the generated documentation verification index")
args = parser.parse_args()
root = pathlib.Path(__file__).resolve().parent.parent
lua_files = sorted(p.relative_to(root) for p in root.rglob("*.lua")
                   if not any(part.startswith(".") for part in p.relative_to(root).parts)
                   and p.name != "_tmp_striplines.lua")
syntax = []
for offset in range(0, len(lua_files), 50):
    batch = lua_files[offset:offset + 50]
    result = subprocess.run(["luac", "-p", *map(str, batch)], cwd=root, capture_output=True, text=True)
    if result.returncode:
        for path in batch:
            one = subprocess.run(["luac", "-p", str(path)], cwd=root, capture_output=True, text=True)
            if one.returncode:
                syntax.append({"path": path.as_posix(), "output": one.stdout + one.stderr})
scripts = sorted(set(p for p in lua_files if (p.name.startswith("_tmp_") and "smoke" in p.name)
                     or p.parts[0] == "tests"))
checks = []
for path in scripts:
    began = time.perf_counter()
    try:
        result = subprocess.run(["lua", str(path)], cwd=root, capture_output=True, text=True, timeout=90)
        status, output = result.returncode, result.stdout + result.stderr
    except (subprocess.TimeoutExpired, OSError) as error:
        status, output = -1, str(error)
    record = {"path": path.as_posix(), "exit": status,
              "wallSeconds": round(time.perf_counter() - began, 4), "output": output[-18000:]}
    checks.append(record)
    print(f"{'PASS' if status == 0 else 'FAIL'} {path.as_posix()}", flush=True)
manifest = [{"path": p.as_posix(), "sha256": hashlib.sha256((root / p).read_bytes().replace(b"\r\n", b"\n")).hexdigest()}
            for p in lua_files]
report = {"runtime": subprocess.run(["lua", "-v"], capture_output=True, text=True).stdout.strip(),
          "scope": "Desktop Lua mocks/source checks only; native secure VM, real secret values, rendering and client performance unverified.",
          "syntaxFiles": len(lua_files), "syntaxFailures": syntax, "tests": checks,
          "pass": sum(r["exit"] == 0 for r in checks), "fail": sum(r["exit"] != 0 for r in checks),
          "manifest": manifest}
if args.output:
    output_path = args.output if args.output.is_absolute() else root / args.output
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
if args.sync_docs:
    evidence = {
        "captured_at_utc": datetime.now(timezone.utc).isoformat(), "runtime": report["runtime"], "evidence_level": report["scope"],
        "source_hash_normalization": "CRLF to LF; all other bytes, including BOM, preserved",
        "publishable_lua_files": len(lua_files),
        "lua_corpus_sha256": hashlib.sha256(json.dumps(manifest, sort_keys=True, separators=(",", ":")).encode()).hexdigest(),
        "syntax_check": {"command": "luac -p (batches; individual checks after batch failure)",
                         "passed": len(lua_files) - len(syntax), "failed": len(syntax)},
        "smoke_scripts": len(checks), "smoke_passed": report["pass"], "smoke_failed": report["fail"],
        "results": [{"path": t["path"], "exitCode": t["exit"], "output": t["output"]} for t in checks],
        "lua_corpus": manifest,
        "native_client_tests": "Not run; docs/43-startup-optimization.md records required scenarios",
    }
    (root / "docs/reference/verification.json").write_text(json.dumps(evidence, indent=2) + "\n", encoding="utf-8")
print(f"Syntax: {len(lua_files)} files, {len(syntax)} failures; tests: {report['pass']} pass, {report['fail']} fail")
sys.exit(bool(syntax or report["fail"]))
