"""Create an isolated Shared.lua candidate from the frozen external baseline."""
from pathlib import Path
import difflib
import hashlib
import json

HERE = Path(__file__).resolve().parent
WORKSPACE = json.loads((HERE.parent / "workspace.json").read_text(encoding="utf-8"))
BASE = Path(WORKSPACE["baselineRoot"])
CANDIDATE = Path(WORKSPACE["candidateRoots"]["geometry"])
RELATIVE = "UnitFrames/FluxUnitFrames_Shared.lua"
original = (BASE / RELATIVE).read_bytes()
expected = next(row["sha256"] for row in WORKSPACE["files"] if row["path"] == RELATIVE)
assert hashlib.sha256(original).hexdigest() == expected, "Frozen baseline hash changed"
newline = "\r\n" if b"\r\n" in original else "\n"
source = original.decode("utf-8").replace("\r\n", "\n")
edits = [
    ("GEO-01/access-contract-comment", """        -- 12.0+ Path: All numeric values may be secret.
        -- Arithmetic on secrets produces secrets (safe); only comparisons
        -- (>, <, ==) error.  Wrap comparisons in pcall; pass secrets
        -- directly to widget APIs (SetValue, SetMinMaxValues, SetPoint).
""", """        -- Native numeric getters may return values addon Lua cannot inspect.
        -- Access is operation-specific; pcall does not make a value readable.
        -- Keep opaque health/absorb amounts on permitted StatusBar sinks and
        -- use native anchors with public offsets for their presentation.
"""),
    ("GEO-01/width-gate", """            local barWidth = healthBar:GetWidth()

            if not dead and barWidth > 0 then
""", """            local barWidth = healthBar:GetWidth()
            local publicWidth = not ValueIsSecret(barWidth) and type(barWidth) == "number"

            if not dead and (not publicWidth or barWidth > 0) then
"""),
    ("GEO-01/native-remaining-span", """                    bar:SetPoint("TOPLEFT", healthTex, "TOPRIGHT", 0, 0)
                    bar:SetPoint("BOTTOMLEFT", healthTex, "BOTTOMRIGHT", 0, 0)
                    bar:SetWidth(barWidth)
                    pcall(bar.SetMinMaxValues, bar, 0, maxHP)
                    pcall(bar.SetValue, bar, clampedAbsorb)
""", """                    bar:SetPoint("TOPLEFT", healthTex, "TOPRIGHT", 0, 0)
                    if publicWidth and type(healCalc.GetMissingHealth) ~= "function" then
                        -- Preserve the existing public-geometry path on older calculators.
                        bar:SetPoint("BOTTOMLEFT", healthTex, "BOTTOMRIGHT", 0, 0)
                        bar:SetWidth(barWidth)
                        pcall(bar.SetMinMaxValues, bar, 0, maxHP)
                    else
                        bar:SetPoint("BOTTOMRIGHT", healthBar, "BOTTOMRIGHT", 0, 0)
                        -- The native span is missing-health pixels. Normalizing by
                        -- native missing health preserves the former full-width fill
                        -- without forwarding secret geometry to SetWidth.
                        local missingHealth = healCalc:GetMissingHealth()
                        pcall(bar.SetMinMaxValues, bar, 0, missingHealth)
                    end
                    pcall(bar.SetValue, bar, clampedAbsorb)
"""),
    ("ALPHA-06/commit-glow-cache-after-success", """    shell._fluxThreatGlowBand = band
    -- Prefer LCG so we can tint yellow→red; frameLevel arg must clear the border (+10).
    if LCG and LCG.ButtonGlow_Start then
        pcall(LCG.ButtonGlow_Start, shell, color, 0.25, 16)
    elseif LBG and LBG.ShowOverlayGlow then
        pcall(LBG.ShowOverlayGlow, shell)
    end
    ThreatBarRaiseGlowAboveBorder(shell)
""", """    -- Prefer LCG so we can tint yellow→red; frameLevel arg must clear the border (+10).
    local applied = false
    if LCG and LCG.ButtonGlow_Start then
        applied = pcall(LCG.ButtonGlow_Start, shell, color, 0.25, 16)
    elseif LBG and LBG.ShowOverlayGlow then
        applied = pcall(LBG.ShowOverlayGlow, shell)
    end
    if applied then shell._fluxThreatGlowBand = band end
    ThreatBarRaiseGlowAboveBorder(shell)
"""),
]
experiment = source
for name, before, after in edits:
    assert experiment.count(before) == 1, f"Expected unique frozen hunk: {name}"
    experiment = experiment.replace(before, after, 1)
# Reject the geometric change as a recommendation: a separately updating health
# fill can disagree with the calculator epoch. Keep it in a separate external
# experiment root so the selected candidate cannot accidentally apply it.
experiment_root = Path(WORKSPACE["externalRoot"]) / "experiments/geometry-native-span"
experiment_path = experiment_root / RELATIVE
experiment_path.parent.mkdir(parents=True, exist_ok=True)
experiment_path.write_bytes(experiment.replace("\n", newline).encode("utf-8"))
experiment_diff = "".join(difflib.unified_diff(source.splitlines(keepends=True), experiment.splitlines(keepends=True),
                                             fromfile="baseline/" + RELATIVE, tofile="REJECTED-native-span/" + RELATIVE))
(HERE / "rejected-native-span.diff").write_text(experiment_diff, encoding="utf-8")
changed = source
selected_edits = []
for name, before, after in edits:
    if name in {"GEO-01/access-contract-comment", "ALPHA-06/commit-glow-cache-after-success"}:
        changed = changed.replace(before, after, 1)
        selected_edits.append(name)
destination = CANDIDATE / RELATIVE
destination.parent.mkdir(parents=True, exist_ok=True)
destination.write_bytes(changed.replace("\n", newline).encode("utf-8"))
diff = "".join(difflib.unified_diff(source.splitlines(keepends=True), changed.splitlines(keepends=True),
                                   fromfile="baseline/" + RELATIVE, tofile="candidate/" + RELATIVE))
(HERE / "candidate.diff").write_text(diff, encoding="utf-8")
report = {"baseline": str(BASE / RELATIVE), "candidate": str(destination),
          "baseline_raw_sha256": expected, "candidate_raw_sha256": hashlib.sha256(destination.read_bytes()).hexdigest(),
          "selected_status": "GATED_WITH_PATCHED_WINNING_LCG_NOT_FOR_INDEPENDENT_APPLICATION",
          "edits": selected_edits,
          "GEO-01": "HELD. Native-span experiment rejected for stale health fill versus calculator epoch mismatch; selected candidate has no geometric change.",
          "rejected_experiment": str(experiment_path),
          "rejected_experiment_sha256": hashlib.sha256(experiment_path.read_bytes()).hexdigest(),
          "GEO-02": "No source change: exact native tiling frequency/appearance unresolved.",
          "ALPHA-06": "Threat cache commit hunk supplied by alpha-reader agent; application is gated on the matching patched winning LCG ownership/readiness. An unpatched higher-version winner could produce more repeated failing starts."}
(HERE / "candidate.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
print(json.dumps(report, indent=2))
