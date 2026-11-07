"""Write review-only staged diffs from the frozen baseline and candidate files."""
import difflib
import hashlib
import json
from pathlib import Path

folder = Path(__file__).resolve().parent
workspace = json.loads((folder.parent / "workspace.json").read_text())
base = Path(workspace["baselineRoot"])
candidate = Path(workspace["candidateRoots"]["fades"])
first, second, identities = [], [], []
for name in ["UnitFrames/FluxCastBar.lua", "UnitFrames/FluxSwingTimer.lua"]:
    raw = (base / name).read_bytes()
    old = raw.decode("utf-8").replace("\r\n", "\n")
    new = (candidate / name).read_text(encoding="utf-8")
    if name.endswith("FluxCastBar.lua"):
        minimal = old.replace("UIFrameFadeOut(self, fadeDur, self:GetAlpha(), 0)", "UIFrameFadeOut(self, fadeDur, 1, 0)")
    else:
        block = "    -- Only block when the cast bar is actually on-screen.\n    if not castBar:IsShown() or castBar:GetAlpha() <= 0.01 then\n        return false\n    end\n    return false\n"
        assert old.count(block) == 1
        minimal = old.replace(block, "    return false\n")
    first.extend(difflib.unified_diff(old.splitlines(True), minimal.splitlines(True), fromfile="a/" + name, tofile="b/" + name))
    second.extend(difflib.unified_diff(minimal.splitlines(True), new.splitlines(True), fromfile="a/" + name, tofile="b/" + name))
    payload = minimal.replace("\n", "\r\n").encode("utf-8") if b"\r\n" in raw else minimal.encode("utf-8")
    identities.append({"path": name, "baseline_sha256": hashlib.sha256(raw).hexdigest(),
                       "minimal_stage_sha256": hashlib.sha256(payload).hexdigest(),
                       "prototype_stage_sha256": hashlib.sha256((candidate / name).read_bytes()).hexdigest()})
(folder / "01-minimal-first.patch").write_text("".join(first), encoding="utf-8")
(folder / "02-swing-ownership-prototype.patch").write_text("".join(second), encoding="utf-8")
(folder / "review-stages.json").write_text(json.dumps({"patch_order": ["01-minimal-first.patch", "02-swing-ownership-prototype.patch"],
                                                       "application": "NOT APPLIED; review only", "stages": identities}, indent=2) + "\n", encoding="utf-8")
print(json.dumps(identities, indent=2))
