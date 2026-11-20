"""Check WoW's 60-upvalue limit using a Lua compiler's prototype listing.

Lua 5.4 listings include _ENV; keeping that within 60 is conservative for Lua
5.1. This check does not claim complete syntax/API compatibility with WoW.
"""
import argparse
import datetime
import json
import re
import subprocess
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--luac", default="luac")
    parser.add_argument("--report", type=Path)
    parser.add_argument("paths", nargs="*")
    args = parser.parse_args()
    paths = args.paths
    if not paths:
        listed = subprocess.check_output(["rg", "--files", "-g", "*.lua"], text=True)
        paths = [p.replace("\\", "/") for p in listed.splitlines()
                 if not p.replace("\\", "/").startswith("tests/")
                 and not Path(p).name.startswith("_tmp")]
    functions, failures = [], []
    for path in sorted(paths):
        result = subprocess.run([args.luac, "-l", "-p", path], capture_output=True,
                                text=True, encoding="utf-8", errors="replace")
        if result.returncode:
            failures.append({"path": path, "error": result.stderr.strip()})
            continue
        start, end = 0, 0
        for line in result.stdout.splitlines():
            header = re.match(r"(?:main|function) <.+:(\d+),(\d+)>", line)
            if header:
                start, end = map(int, header.groups())
            captures = re.search(r"\b(\d+) upvalues?\b", line)
            if captures:
                count = int(captures.group(1))
                row = {"path": path, "start": start, "end": end, "upvalues": count}
                functions.append(row)
                if count > 60:
                    failures.append(row)
    report = {"dateUTC": datetime.datetime.now(datetime.timezone.utc).isoformat(),
              "scope": "Compiler prototype upvalue limit only; includes _ENV on Lua5.4; no native/API/FPS claim",
              "files": len(paths), "functions": len(functions),
              "maximum": max((r["upvalues"] for r in functions), default=0),
              "failures": failures, "prototypes": functions}
    if args.report:
        args.report.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"WoW upvalue check: {len(paths)} files / {len(functions)} prototypes; "
          f"maximum={report['maximum']}; {len(failures)} failures (limit60)")
    for failure in failures:
        print(json.dumps(failure, ensure_ascii=True))
    return bool(failures)


if __name__ == "__main__":
    raise SystemExit(main())
