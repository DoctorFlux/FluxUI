"""Build isolated alpha-reader candidates; never writes into the live addon."""
import difflib
import hashlib
import json
import pathlib

HERE = pathlib.Path(__file__).resolve().parent
WORK = json.loads((HERE.parent / "workspace.json").read_text(encoding="utf-8"))
BASE = pathlib.Path(WORK["baselineRoot"])
DEST = pathlib.Path(WORK["candidateRoots"]["alpha-readers"])
assert DEST.resolve().is_relative_to(pathlib.Path(WORK["externalRoot"]).resolve())


def replace(text, before, after, count=1):
    assert text.count(before) == count, (before[:100], text.count(before), count)
    return text.replace(before, after)


changed = {}
name = "Bars/Blizzard.lua"
text = (BASE / name).read_text(encoding="utf-8-sig")
text = replace(text,
    '\t\tif type(frame) == "table" and frame.GetAlpha and frame.SetAlpha and frame:GetAlpha() > 0 then\n'
    '\t\t\tframe:SetAlpha(0)\n'
    '\t\tend\n',
    '\t\tif type(frame) ~= "table" or not frame.SetAlpha then return end\n'
    '\t\tif frame.GetAlpha then\n'
    '\t\t\tlocal alpha = frame:GetAlpha()\n'
    '\t\t\tlocal S = Flux.Secrets\n'
    '\t\t\tlocal secret = (S and S.IsSecretValue) or issecretvalue\n'
    '\t\t\tlocal access = (S and S.CanAccessValue) or canaccessvalue\n'
    '\t\t\tif not (secret and secret(alpha)) and (not access or access(alpha))\n'
    '\t\t\t\tand type(alpha) == "number" and alpha <= 0 then return end\n'
    '\t\tend\n'
    '\t\t-- Selected native chrome is owned suppression intent. An unreadable\n'
    '\t\t-- value cannot veto that intent; public zero still avoids repeat writes.\n'
    '\t\tframe:SetAlpha(0)\n')
changed[name] = text

name = "Bars/BadgeHost.lua"
text = (BASE / name).read_text(encoding="utf-8-sig")
text = replace(text, '\t\t\t\t\t\tif ok and type(a) == "number" and a <= 0 then\n',
    '\t\t\t\t\t\t-- The configured owned badge alpha is public even when its\n'
    '\t\t\t\t\t\t-- widget getter is restricted. Hidden/parked flags above win.\n'
    '\t\t\t\t\t\tif not ok or not CanRead(a) then a = badge._fluxBadgeAlpha end\n'
    '\t\t\t\t\t\tif CanRead(a) and type(a) == "number" and a <= 0 then\n')
changed[name] = text

name = "Core/ButtonFX/Cast.lua"
text = (BASE / name).read_text(encoding="utf-8-sig")
text = replace(text, 'local function WidgetShown(widget)\n',
    'local function ReadableAlpha(value)\n'
    '\tlocal S = Flux.Secrets\n'
    '\tlocal secret = (S and S.IsSecretValue) or issecretvalue\n'
    '\tlocal access = (S and S.CanAccessValue) or canaccessvalue\n'
    '\treturn not (secret and secret(value)) and (not access or access(value))\n'
    'end\n\nlocal function WidgetShown(widget)\n')
text = replace(text, '\t\tif ok and type(a) == "number" and a <= 0 then\n',
    '\t\tif not ok or not ReadableAlpha(a) then\n'
    '\t\t\t-- Badge alpha is configured by its owner; no alpha is inferred for\n'
    '\t\t\t-- other restricted widgets. Parked/hidden/IsShown still prune them.\n'
    '\t\t\tlocal owner = widget.FluxButton\n'
    '\t\t\ta = owner and owner._fluxBadgeAlpha\n'
    '\t\tend\n'
    '\t\tif ReadableAlpha(a) and type(a) == "number" and a <= 0 then\n')
changed[name] = text

name = "Core/ButtonFX/Charges.lua"
text = (BASE / name).read_text(encoding="utf-8-sig")
text = replace(text, '\t\tcd:SetDrawBling(false)\n\t\treturn\n\tend\n\tlocal alpha = 1\n\tif cd.GetEffectiveAlpha then\n\t\tlocal a = cd:GetEffectiveAlpha()\n\t\tif type(a) == "number" then\n\t\t\talpha = a\n\t\tend\n\tend\n\tcd:SetDrawBling(alpha > 0.4)\n',
    '\t\tcd:SetDrawBling(false)\n\t\tcd._fxBlingDeferred = nil\n\t\treturn\n\tend\n'
    '\t-- Missing legacy getter keeps its established compatibility policy.\n'
    '\t-- An existing but unreadable getter is unknown, not forced to 0 or 1.\n'
    '\tlocal alpha = 1\n'
    '\tif cd.GetEffectiveAlpha then alpha = cd:GetEffectiveAlpha() end\n'
    '\tlocal S = Flux.Secrets\n'
    '\tlocal secret = (S and S.IsSecretValue) or issecretvalue\n'
    '\tlocal access = (S and S.CanAccessValue) or canaccessvalue\n'
    '\tif (secret and secret(alpha)) or (access and not access(alpha))\n'
    '\t\tor type(alpha) ~= "number" then\n'
    '\t\tcd._fxBlingDeferred = true\n'
    '\t\treturn\n'
    '\tend\n'
    '\tcd:SetDrawBling(alpha > 0.4)\n'
    '\tcd._fxBlingDeferred = nil\n')
text = replace(text, '\t\treturn cd._fxSigShown, false\n',
    '\t\t-- Retry only a deferred appearance decision. Do not restart an\n'
    '\t\t-- unchanged native timer merely because its alpha was restricted.\n'
    '\t\tif cd._fxBlingDeferred then SetBling(cd, cd._fxSigShown == true) end\n'
    '\t\treturn cd._fxSigShown, false\n')
changed[name] = text

name = "ExtraButtonSystem/Engine/Button.lua"
text = (BASE / name).read_text(encoding="utf-8-sig")
text = replace(text, '--- Paint via Midnight duration object when available; otherwise numeric SetCooldown.\n',
    'local function PublicCooldownAlpha(cd)\n'
    '    if not cd.GetEffectiveAlpha then return 1 end -- established legacy policy\n'
    '    local alpha = cd:GetEffectiveAlpha()\n'
    '    local Flux = _G.Flux\n'
    '    local S = (Flux and Flux.Secrets) or (FluxAPICompat and FluxAPICompat.API)\n'
    '    local secret = (S and S.IsSecretValue) or issecretvalue\n'
    '    local access = (S and S.CanAccessValue) or canaccessvalue\n'
    '    if (secret and secret(alpha)) or (access and not access(alpha))\n'
    '        or type(alpha) ~= "number" then return nil end\n'
    '    return alpha\n'
    'end\n\n'
    '--- Paint via Midnight duration object when available; otherwise numeric SetCooldown.\n')
text = replace(text,
    '    local alpha = (cd.GetEffectiveAlpha and cd:GetEffectiveAlpha()) or 1\n'
    '    if cd.SetSwipeColor then pcall(cd.SetSwipeColor, cd, 0, 0, 0, alpha) end\n'
    '    if alpha > 0.4 then\n'
    '        if cd.SetDrawBling then pcall(cd.SetDrawBling, cd, true) end\n'
    '        if cd.SetDrawEdge then pcall(cd.SetDrawEdge, cd, isCharge and true or false) end\n'
    '    else\n'
    '        if cd.SetDrawBling then pcall(cd.SetDrawBling, cd, false) end\n'
    '        if cd.SetDrawEdge then pcall(cd.SetDrawEdge, cd, false) end\n'
    '    end\n',
    '    local alpha = PublicCooldownAlpha(cd)\n'
    '    -- Retain existing appearance when private; duration lifecycle continues.\n'
    '    -- The existing next paint retries, without a new timer or forced alpha.\n'
    '    if alpha ~= nil then\n'
    '        if cd.SetSwipeColor then pcall(cd.SetSwipeColor, cd, 0, 0, 0, alpha) end\n'
    '        if alpha > 0.4 then\n'
    '            if cd.SetDrawBling then pcall(cd.SetDrawBling, cd, true) end\n'
    '            if cd.SetDrawEdge then pcall(cd.SetDrawEdge, cd, isCharge and true or false) end\n'
    '        else\n'
    '            if cd.SetDrawBling then pcall(cd.SetDrawBling, cd, false) end\n'
    '            if cd.SetDrawEdge then pcall(cd.SetDrawEdge, cd, false) end\n'
    '        end\n'
    '    end\n')
text = replace(text,
    '            local alpha = (cd.GetEffectiveAlpha and cd:GetEffectiveAlpha()) or 1\n'
    '            if cd.SetSwipeColor then cd:SetSwipeColor(0, 0, 0, alpha) end\n\n'
    '            if alpha > 0.4 then\n'
    '                if cd.SetDrawEdge then cd:SetDrawEdge(drawEdge or forceShowDrawEdge) end\n'
    '                if cd.SetDrawBling then cd:SetDrawBling(true) end\n'
    '            else\n'
    '                if cd.SetDrawEdge then cd:SetDrawEdge(false) end\n'
    '                if cd.SetDrawBling then cd:SetDrawBling(false) end\n'
    '            end\n',
    '            local alpha = PublicCooldownAlpha(cd)\n'
    '            if alpha ~= nil then\n'
    '                if cd.SetSwipeColor then cd:SetSwipeColor(0, 0, 0, alpha) end\n'
    '                if alpha > 0.4 then\n'
    '                    if cd.SetDrawEdge then cd:SetDrawEdge(drawEdge or forceShowDrawEdge) end\n'
    '                    if cd.SetDrawBling then cd:SetDrawBling(true) end\n'
    '                else\n'
    '                    if cd.SetDrawEdge then cd:SetDrawEdge(false) end\n'
    '                    if cd.SetDrawBling then cd:SetDrawBling(false) end\n'
    '                end\n'
    '            end\n')
changed[name] = text

name = "libs/LibCustomGlow-1.0/LibCustomGlow-1.0.lua"
text = (BASE / name).read_text(encoding="utf-8-sig")
text = replace(text, 'local function AnimIn_OnPlay(group)\n',
    '-- Local candidate: record only this library owner\'s explicit base-alpha\n'
    '-- writes. Native animation parameters stay on their existing groups.\n'
    '-- No global hook, secret read or arbitrary shared-library minor bump.\n'
    'local function SetButtonGlowAlpha(frame, texture, alpha)\n'
    '    frame[texture]:SetAlpha(alpha)\n'
    '    frame._lCGTextureAlpha = frame._lCGTextureAlpha or {}\n'
    '    frame._lCGTextureAlpha[texture] = alpha\n'
    'end\n\nlocal function AnimIn_OnPlay(group)\n')
import re
keys = "spark|innerGlow|innerGlowOver|outerGlow|outerGlowOver|ants"
pattern = re.compile(r'\b(frame|f)\.(' + keys + r'):SetAlpha\(([^\n]*)\)')
text, writes = pattern.subn(lambda m: f'SetButtonGlowAlpha({m[1]}, "{m[2]}", {m[3]})', text)
assert writes == 21, writes
text = replace(text, 'f[texture]:GetAlpha()', 'f._lCGTextureAlpha[texture]', count=2)
text = replace(text, 'f[texture]:SetAlpha(alpha)', 'SetButtonGlowAlpha(f, texture, alpha)', count=2)
changed[name] = text

records = []
for name, text in changed.items():
    original = (BASE / name).read_bytes()
    # Preserve source newline/BOM conventions; no unrelated formatting churn.
    payload = text.replace("\n", "\r\n").encode("utf-8") if b"\r\n" in original else text.encode("utf-8")
    if original.startswith(b"\xef\xbb\xbf"):
        payload = b"\xef\xbb\xbf" + payload
    path = DEST / name
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(payload)
    before = original.decode("utf-8-sig").replace("\r\n", "\n")
    diff = "".join(difflib.unified_diff(before.splitlines(True), text.splitlines(True),
                                     fromfile="baseline/" + name, tofile="candidate/" + name))
    diff_path = HERE / (name.replace("/", "__") + ".patch")
    diff_path.write_text(diff, encoding="utf-8")
    records.append({"path": name, "baseline_sha256": hashlib.sha256(original).hexdigest(),
                    "candidate_sha256": hashlib.sha256(payload).hexdigest(), "diff": diff_path.name})
(HERE / "candidate-manifest.json").write_text(json.dumps({"baseline": str(BASE), "candidate": str(DEST),
    "files": records, "live_runtime_writes": False, "library_minor_bumped": False,
    "library_load_gate": "Only the patched embedded source winning LibStub selection is covered; external winning versions remain unpatched and not accepted",
    "unknown_effective_alpha_policy": "Continue/clear timer, retain previous appearance while private, retry on existing paint; exact opaque-alpha appearance parity remains pending"}, indent=2) + "\n", encoding="utf-8")
print(json.dumps({"candidate_files": len(records), "glow_owned_direct_alpha_writes": writes}))
