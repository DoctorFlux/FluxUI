-- JetBrains Mono for Flux binding editor macro previews (Clicked parity).
-- Font file vendored from Clicked; see COPYING-CLICKED-GPL-3.0.txt.

local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
if not LSM then return end

local FONT_KEY = "JetBrains Mono Regular"
local basePath = [[Interface\AddOns\_FluxUI\Binding\UI\Media\Fonts\]]
local fontPath = basePath .. [[JetBrainsMonoNL-Regular.ttf]]

LSM:Register("font", FONT_KEY, fontPath, LSM.LOCALE_BIT_western + LSM.LOCALE_BIT_ruRU)

local Media = {}

function Media.UseMonoFont(object)
    local path = LSM:Fetch("font", FONT_KEY)
    if not path then return end
    if object and object.editBox then
        object = object.editBox
    end
    if object and object.SetFont then
        object:SetFont(path, 12, "")
    end
end

_G.FluxBindingEditorMedia = Media
