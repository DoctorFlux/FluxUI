-- Flux-themed AceGUI frame appearance (mirrors FluxOptions config window).

local Theme = {}
_G.FluxBindingEditorTheme = Theme

function Theme.ApplyAceFrame(aceWidget)
    if not aceWidget then return end
    local f = aceWidget.frame
    if not f then return end

    local br, bg, bb = 0.65, 0.65, 0.65
    local dr, dg, db = 0.08, 0.08, 0.1
    local mode = "class"
    if FluxBorder and FluxBorder.GetThemedVertexRGB and FluxBorder.GetThemedBackdropFillRGB and FluxBorder.GetAccentMode then
        br, bg, bb = FluxBorder:GetThemedVertexRGB()
        dr, dg, db = FluxBorder:GetThemedBackdropFillRGB()
        mode = FluxBorder:GetAccentMode()
    elseif FluxBorder and FluxBorder.GetAccentColor then
        br, bg, bb, mode = FluxBorder:GetAccentColor()
        if mode ~= "atlas" then
            dr, dg, db = br * 0.4, bg * 0.4, bb * 0.4
        end
    end

    if f.SetBackdropColor then
        f:SetBackdropColor(dr, dg, db, 1)
    end
    if f.SetBackdropBorderColor then
        f:SetBackdropBorderColor(br * 0.55, bg * 0.55, bb * 0.55, 1)
    end

    local hdrR, hdrG, hdrB
    if mode == "atlas" and FluxBorder and FluxBorder.IsUntintedAtlasAccent and FluxBorder:IsUntintedAtlasAccent() then
        hdrR, hdrG, hdrB = 0.45, 0.55, 0.85
    else
        hdrR = math.min(br * 0.42 + dr * 0.58, 1)
        hdrG = math.min(bg * 0.42 + dg * 0.58, 1)
        hdrB = math.min(bb * 0.42 + db * 0.58, 1)
    end
    if aceWidget.titlebg and aceWidget.titlebg.SetVertexColor then
        aceWidget.titlebg:SetVertexColor(hdrR, hdrG, hdrB)
    end
    if aceWidget.titlebg_l and aceWidget.titlebg_l.SetVertexColor then
        aceWidget.titlebg_l:SetVertexColor(hdrR, hdrG, hdrB)
    end
    if aceWidget.titlebg_r and aceWidget.titlebg_r.SetVertexColor then
        aceWidget.titlebg_r:SetVertexColor(hdrR, hdrG, hdrB)
    end
    if aceWidget.statusbg then
        if aceWidget.statusbg.SetBackdropColor then
            aceWidget.statusbg:SetBackdropColor(dr * 0.92 + br * 0.08, dg * 0.92 + bg * 0.08, db * 0.92 + bb * 0.08, 1)
        end
        if aceWidget.statusbg.SetBackdropBorderColor then
            aceWidget.statusbg:SetBackdropBorderColor(br * 0.5, bg * 0.5, bb * 0.5, 1)
        end
    end
end

function Theme.ApplyCompactLabelFont(widget, fontObject)
    fontObject = fontObject or GameFontHighlightSmall
    if not widget or not widget.label then return end
    local fs = widget.label
    if fontObject and fs.SetFontObject then
        pcall(fs.SetFontObject, fs, fontObject)
    end
end
