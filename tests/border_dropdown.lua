-- Exercise the production Classic dropdown's swatch sizing and native menu delivery.
local f=assert(io.open("AddonOptions/FluxOptionsWidgets.lua","rb"));local s=f:read("*a"):gsub("\r\n","\n");f:close()
local body=assert(s:match("(function W.CreateDropdown%(parent%).-)\nlocal function FormatNumber"))
local checks=0
local function check(v,msg)checks=checks+1;assert(v,msg)end
local fonts,menu,width={},{}
local methods={}
function methods:SetPoint()end
function methods:SetWidth(w)self.width=w end
function methods:SetJustifyH()end
function methods:SetJustifyV()end
function methods:SetWordWrap()end
function methods:SetAlpha()end
function methods:SetText(t)self.text=t end
function methods:Hide()self.hidden=true end
function methods:GetStringWidth()
 local text=self.text or "";local icons=0
 text=text:gsub("|A:[^|]-|a",function()icons=icons+16;return ""end)
 text=text:gsub("|T[^|]-|t",function()icons=icons+80;return ""end)
 return #text*7+icons
end
function methods:HookScript()end
function methods:CreateFontString()
 local font=setmetatable({},{__index=methods});fonts[#fonts+1]=font;return font
end
local row=setmetatable({},{__index=methods})
local dropdown=setmetatable({},{__index=methods})
local env=setmetatable({W={ROW_H=40,CreateRow=function()return row end,OnAccent=function()end},
 CreateModernDropdown=function()return nil end,CreateFrame=function()return dropdown end,
 SetBlizzardDropdownText=function(_,text)dropdown.text=text end,AttachTooltip=function()end,
 UIDropDownMenu_SetWidth=function(_,w)width=w end,
 UIDropDownMenu_Initialize=function(_,fn)dropdown.initialize=fn end,
 UIDropDownMenu_CreateInfo=function()return {}end,
 UIDropDownMenu_AddButton=function(info)menu[#menu+1]=info end,
 UIDropDownMenu_SetText=function(_,t)dropdown.text=t end,
},{__index=_G})
assert(load(body,"production dropdown","t",env))()
local actual=env.W.CreateDropdown({})
local text="Border type 2  |TInterface/AddOns/_FluxUI/Texture/borders/Preview2.tga:20:80:0:0:256:64:0:256:0:64:255:255:255|t"
actual:SetGetter(function()return {{value=1,text="Border type 1"},{value=2,text=text}}end)
actual:SetValue(2)
check(width<240,"Classic width measures the swatch rather than hundreds of markup characters")
check(#fonts==2 and fonts[2].hidden,"one passive hidden measure is allocated lazily")
for i=1,10 do actual:SetValue(2)end
check(#fonts==2,"subsequent value/accent updates reuse the measure")
dropdown.initialize(nil,1)
check(menu[2].text==text and menu[2].checked,"native menu receives the original tint-aware preview and selection")
check(menu[1].topPadding==6 and menu[2].topPadding==6,"complete preview silhouettes get consistent native row spacing")
local picked
actual:SetOnChange(function(v)picked=v end)
menu[1].func()
check(picked==1 and dropdown.text=="Border type 1","selection continues through the existing native handler")
print(("Border dropdown: %d checks PASS; native font/render/controller acceptance pending"):format(checks))
