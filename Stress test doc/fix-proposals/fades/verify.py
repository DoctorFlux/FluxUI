"""Record proposal-only paired tests, rejection controls and unchanged source IDs."""
from __future__ import annotations
import hashlib
import json
import pathlib
import re
import subprocess
from datetime import datetime, timezone

here = pathlib.Path(__file__).resolve().parent
live = here.parents[2]
ws = json.loads((here.parent / "workspace.json").read_text())
baseline = pathlib.Path(ws["baselineRoot"])
candidate = pathlib.Path(ws["candidateRoots"]["fades"])
refs = live.parent / "__AddonsForRef"
native = refs / "wow-ui-source-forever/Interface/AddOns/Blizzard_SharedXMLBase/FrameUtil.lua"
raw = native.read_bytes().replace(b"\r\n", b"\n")
blob = hashlib.sha1(b"blob " + str(len(raw)).encode() + b"\0" + raw).hexdigest()
assert blob == "a1fe94ae627fe3c694d5c38df9f0d1a54eecb84d"
names = ["UnitFrames/FluxCastBar.lua", "UnitFrames/FluxSwingTimer.lua"]
sources = {str(p): p for p in [*(baseline / n for n in names), *(candidate / n for n in names),
                             *(live / n for n in names), native, here / "verify.lua.txt", here / "run_existing.lua.txt"]}
for texture in (live / "Texture/CastBarSchools").glob("*.tga"):
    sources[str(texture)] = texture
def hashes():
    return {name: hashlib.sha256(path.read_bytes()).hexdigest() for name, path in sources.items()}
before = hashes()
def run(cmd, cwd=baseline):
    p = subprocess.run(cmd, cwd=cwd, capture_output=True, text=True, timeout=90)
    return {"command": cmd, "cwd": str(cwd), "exit": p.returncode, "stdout": p.stdout, "stderr": p.stderr}
focused_command = ["lua", str(here / "verify.lua.txt"), str(baseline), str(candidate), str(native)]
focused = [run(focused_command) for _ in range(5)]
mutations = []
for name, expected in [("swing-force-one", "restart has no alpha jump"), ("swing-drop-record", "restart has no alpha jump"),
                       ("cast-restore-getter", "candidate cast fade never reads native alpha"),
                       ("busy-restore-getter", "OPAQUE_ALPHA_GETTER"),
                       ("swing-stale-timer", "stale historical timer hides replacement")]:
    r = run(focused_command + [name])
    r["mutation"], r["expected_rejection"] = name, expected
    r["rejected_for_expected_reason"] = r["exit"] != 0 and expected in (r["stdout"] + r["stderr"])
    mutations.append(r)
existing = []
for source in (baseline, candidate):
    for test in ("tests/castbar_school_themes.lua", "tests/castbar_timer_sync.lua"):
        record = run(["lua", str(here / "run_existing.lua.txt"), str(source), test, str(refs), str(live)])
        record["variant"] = "baseline" if source == baseline else "candidate"
        existing.append(record)
syntax = run(["luac", "-p", *(str(candidate / n) for n in names)])
after = hashes()
counts = {}
for name in names:
    pair = {}
    for label, directory in (("baseline", baseline), ("candidate", candidate)):
        text = (directory / name).read_text(encoding="utf-8")
        pair[label] = {token: len(re.findall(r"\b" + token + r"\b", text)) for token in
                       ("CreateFrame", "RegisterEvent", "RegisterUnitEvent", "HookScript", "SetScript", "NewTimer", "NewTicker", "UIFrameFadeOut", "GetAlpha")}
    counts[name] = pair
report = {"captured_at_utc": datetime.now(timezone.utc).isoformat(), "proposal": "fades",
          "status": "PROPOSED_NOT_APPLIED", "baselineRoot": str(baseline), "candidateRoot": str(candidate),
          "native_source": {"ref": "9dc84f0d3bbae1768ac3405b3716000bd93eda06", "version_reference_not_runtime_capture": "1.60.1.70862", "FrameUtil_git_blob": blob},
          "scope": "Frozen external baseline and external candidate function fragments/full existing mock fixtures. Pinned native fade Lua executes with mocked frames/timers/opaque getter; no native secret/secure VM or pixel acceptance. USER-001 actual frame attribution unresolved.",
          "focused_checks_per_process": 1017, "focused_processes": 5,
          "baseline_rejections_per_process": 4, "focused": focused, "mutations": mutations,
          "intentional_ownership_checks_per_process": 8,
          "intentional_ownership_fixes": "New private owner write retires old fade; hide/disable/re-enable no longer keeps hidden queued fade; old timer completion cannot hide a replacement fade; zero-elapsed repaint cannot overwrite new owner write",
          "recommendation": "Cast known endpoint and redundant busy read are minimal first candidates; broader Swing public-state ownership prototype remains held for native acceptance",
          "existing_fixtures": existing, "syntax": syntax, "token_inventory_not_runtime_cost": counts,
          "hashes_before": before, "hashes_after": after,
          "changed_consumed_sources": [p for p in before if before[p] != after[p]],
          "live_pair_matches_frozen_baseline": {name: (live / name).read_bytes() == (baseline / name).read_bytes() for name in names},
          "native_checks": "Pending per client; no game/input/WTF/profiler operation performed"}
success = all(r["exit"] == 0 for r in focused + existing + [syntax]) and all(r["rejected_for_expected_reason"] for r in mutations) and before == after
report["verification"] = "PASS_WITH_NATIVE_LIMITS" if success else "FAILED_OR_DRIFTED"
(here / "results.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
print(json.dumps({k: report[k] for k in ("verification", "focused_checks_per_process", "baseline_rejections_per_process", "changed_consumed_sources", "live_pair_matches_frozen_baseline")}, indent=2))
for r in mutations:
    print(r["mutation"], r["rejected_for_expected_reason"], (r["stderr"] or r["stdout"]).splitlines()[:1])
for r in existing:
    print(r["variant"], r["command"][3], r["exit"], r["stdout"][-400:])
raise SystemExit(not success)
