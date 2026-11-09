"""Create fade proposal files only in the authorized external candidate folder."""
import difflib
import hashlib
import json
import pathlib
import re

here = pathlib.Path(__file__).resolve().parent
workspace = json.loads((here.parent / "workspace.json").read_text())
baseline = pathlib.Path(workspace["baselineRoot"])
candidate = pathlib.Path(workspace["candidateRoots"]["fades"])
assert candidate.resolve().is_relative_to(pathlib.Path(workspace["externalRoot"]).resolve())
expected = {x["path"]: x["sha256"] for x in workspace["files"]}
paths = ["UnitFrames/FluxCastBar.lua", "UnitFrames/FluxSwingTimer.lua"]
records, patches = [], []
for name in paths:
    original_bytes = (baseline / name).read_bytes()
    assert hashlib.sha256(original_bytes).hexdigest() == expected[name], name
    before = original_bytes.decode("utf-8").replace("\r\n", "\n")
    after = before
    if name.endswith("FluxCastBar.lua"):
        old = "UIFrameFadeOut(self, fadeDur, self:GetAlpha(), 0)"
        assert after.count(old) == 1
        after = after.replace(old, "UIFrameFadeOut(self, fadeDur, 1, 0)")
    else:
        # The final visibility/alpha branch has no effect on the boolean result.
        old = '''    -- Only block when the cast bar is actually on-screen.
    if not castBar:IsShown() or castBar:GetAlpha() <= 0.01 then
        return false
    end
    return false
'''
        assert after.count(old) == 1
        after = after.replace(old, "    return false\n")
        assert after.count("swingFrame:SetAlpha(") == 7
        after = after.replace("swingFrame:SetAlpha(", "SetSwingAlpha(")
        anchor = "local SWING_FADE_DURATION = 1.0    -- match FluxCastBar CastStop fade\n"
        helper = '''
-- Public alpha belongs to this private overlay. Native GetAlpha can be secret.
-- FrameUtil's public record gives the exact elapsed value of its last paint.
-- A new owner write retires that fade, including zero-elapsed repaint races.
local swingAlpha = 0
local swingFadeInfo

local function SetSwingAlpha(alpha)
    if swingFadeOut then
        if swingFadeTimer then swingFadeTimer:Cancel(); swingFadeTimer = nil end
        if swingFrame then UIFrameFadeRemoveFrame(swingFrame) end
        swingFadeOut = false
        swingFadeInfo = nil
    end
    swingAlpha = alpha
    if swingFrame then swingFrame:SetAlpha(alpha) end
end

local function CurrentSwingAlpha()
    local info = swingFadeInfo
    if info then
        local timer = info.fadeTimer or 0
        if timer < info.timeToFade then
            return ((info.timeToFade - timer) / info.timeToFade)
                * (info.startAlpha - info.endAlpha) + info.endAlpha
        end
        return info.endAlpha
    end
    return swingAlpha
end
'''
        assert after.count(anchor) == 1
        after = after.replace(anchor, anchor + helper)
        old = '''        UIFrameFadeRemoveFrame(swingFrame)
        SetSwingAlpha(1)
        swingFadeOut = false'''
        new = '''        UIFrameFadeRemoveFrame(swingFrame)
        swingFadeInfo = nil
        swingFadeOut = false
        SetSwingAlpha(1)'''
        assert after.count(old) == 1
        after = after.replace(old, new)
        old = '''local function FinishSwingFade()
    swingFadeOut = false
    swingFadeTimer = nil'''
        new = old + "\n    swingFadeInfo = nil"
        assert after.count(old) == 1
        after = after.replace(old, new)
        old = '''    UIFrameFadeRemoveFrame(swingFrame)
    swingFadeOut = true
    UIFrameFadeOut(swingFrame, SWING_FADE_DURATION, swingFrame:GetAlpha(), 0)'''
        new = '''    local startAlpha = CurrentSwingAlpha()
    UIFrameFadeRemoveFrame(swingFrame)
    swingFadeOut = true
    UIFrameFadeOut(swingFrame, SWING_FADE_DURATION, startAlpha, 0)
    -- This is the public record just created by our call above, not alpha
    -- recovered from the native frame. FrameUtil only advances its fadeTimer.
    local fadeInfo = swingFrame.fadeInfo
    swingFadeInfo = fadeInfo
    swingAlpha = startAlpha'''
        assert after.count(old) == 1
        after = after.replace(old, new)
        old = '''    swingFadeTimer = C_Timer.NewTimer(SWING_FADE_DURATION, function()
        if swingFadeOut then'''
        new = '''    swingFadeTimer = C_Timer.NewTimer(SWING_FADE_DURATION, function()
        if swingFadeOut and swingFadeInfo == fadeInfo then'''
        assert after.count(old) == 1
        after = after.replace(old, new)
        old = '''            swingFrame:Hide()
            SetSwingAlpha(0)'''
        new = '''            SetSwingAlpha(0)
            swingVisible = false
            swingFrame:Hide()'''
        assert after.count(old) == 1
        after = after.replace(old, new)
        old = '''        SetNativeShownOutOfRange(false)
        if swingFrame then
            swingFrame:Hide()'''
        new = '''        SetNativeShownOutOfRange(false)
        if swingFrame then
            SetSwingAlpha(0)
            swingVisible = false
            swingFrame:Hide()'''
        assert after.count(old) == 1
        after = after.replace(old, new)
    destination = candidate / name
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_bytes(after.replace("\n", "\r\n").encode() if b"\r\n" in original_bytes else after.encode())
    patches.extend(difflib.unified_diff(before.splitlines(True), after.splitlines(True), fromfile="baseline/" + name, tofile="candidate/" + name))
    records.append({"path": name, "baseline_sha256": expected[name],
                    "candidate_sha256": hashlib.sha256(destination.read_bytes()).hexdigest(),
                    "baseline_bytes": len(original_bytes), "candidate_bytes": destination.stat().st_size})
(here / "candidate.patch").write_text("".join(patches), encoding="utf-8")
(here / "candidate-identities.json").write_text(json.dumps({"baselineRoot": str(baseline), "candidateRoot": str(candidate), "files": records}, indent=2) + "\n", encoding="utf-8")
print(json.dumps({"candidateRoot": str(candidate), "files": records}, indent=2))
