-- Actual options renderer and native slider widget; only engine primitives are
-- modeled. Desktop checks do not establish native event timing or pixels.
local function read(path)
    local file=assert(io.open(path,"rb"));local source=file:read("*a"):gsub("\r\n","\n");file:close();return source
end
local rendererSource=read(os.getenv("FLUX_OPTIONS_RENDER_SOURCE") or "AddonOptions/FluxOptionsRender.lua")
local widgetSource=read("AddonOptions/FluxOptionsWidgets.lua")
local checks=0
local function check(value,message)checks=checks+1;assert(value,message)end
local function near(a,b)return type(a)=="number" and math.abs(a-b)<1e-8 end
local function run(source,name,e,ns)
    local fn,message
    if _VERSION=="Lua 5.1"then fn,message=loadstring(source,name);if fn then setfenv(fn,e)end
    else fn,message=load(source,name,"t",e)end
    return assert(fn,message)("_FluxUI",ns)
end
local function fixture(source)
    local e=setmetatable({unpack=unpack or table.unpack},{__index=_G});e._G=e
    local ns,objects,sliders={},{},{}
    local methods={}
    local function object(kind,parent)
        local item=setmetatable({kind=kind,parent=parent,scripts={},points={},shown=true},{__index=methods})
        objects[#objects+1]=item;if kind=="Slider"then sliders[#sliders+1]=item end;return item
    end
    function methods:SetHeight(value)self.height=value end
    function methods:SetWidth(value)self.width=value end
    function methods:SetSize(w,h)self.width,self.height=w,h end
    function methods:GetWidth()return self.width or 150 end
    function methods:GetHeight()return self.height or 16 end
    function methods:SetPoint(...)self.points[#self.points+1]={...}end
    function methods:SetAllPoints(relative)self.allPoints=relative end
    function methods:SetTexture(value)self.texture=value end
    function methods:SetVertexColor(...)self.vertex={...}end
    function methods:SetAlpha(value)self.alpha=value end
    function methods:EnableMouse(value)self.mouse=value end
    function methods:SetJustifyH(value)self.justifyH=value end
    function methods:SetJustifyV(value)self.justifyV=value end
    function methods:SetWordWrap(value)self.wordWrap=value end
    function methods:SetText(value)self.text=value end
    function methods:SetOrientation(value)self.orientation=value end
    function methods:SetObeyStepOnDrag(value)self.obeyStep=value end
    function methods:SetValueStep(value)self.step=value end
    function methods:SetThumbTexture(texture)self.thumb=texture end
    function methods:SetScript(event,callback)self.scripts[event]=callback end
    function methods:CreateTexture()return object("Texture",self)end
    function methods:CreateFontString()return object("FontString",self)end
    function methods:GetValue()return self.value or 0 end
    function methods:SetValue(value)
        check(type(value)=="number","slider engine receives numeric values")
        if self.minimum then value=math.max(self.minimum,math.min(self.maximum,value))end
        local changed=self.value~=value;self.value=value
        if changed and self.scripts.OnValueChanged then self.scripts.OnValueChanged(self,value)end
    end
    function methods:SetMinMaxValues(minimum,maximum)
        self.minimum,self.maximum=minimum,maximum
        self.configurations=(self.configurations or 0)+1
        -- Native sliders may synchronously fire OnValueChanged when changing
        -- bounds clamps a previously displayed value. The real widget handler
        -- must see the renderer's setting guard before this engine callback.
        if self.value and (self.value<minimum or self.value>maximum)then
            self.clamps=(self.clamps or 0)+1
            self:SetValue(self.value)
        end
    end
    e.CreateFrame=function(kind,_,parent)return object(kind,parent)end
    e.LibStub=function()return nil end
    run(widgetSource,"@actual-options-widgets",e,ns)
    local add=run(source.."\nreturn AddControlRow\n","@actual-options-render",e,ns)
    local parent=object("Frame")
    local function create(option)
        local root={type="group",name="Options",args={range=option}}
        local page={root=root,embeds={}}
        local row=assert(add(page,{opt=option,path={"range"}},parent))
        local slider=sliders[#sliders]
        local text={};for _,item in ipairs(objects)do if item.parent==row and item.kind=="FontString"then text[#text+1]=item end end
        check(#text==2,"the actual slider creates its label and formatted value")
        return row,slider,text[2],root
    end
    return e,create
end
local function exercise(client,source)
    local e,create=fixture(source)
    local state={minimum=0.5,maximum=2.5,step=0.05,percent=false,value=2.4,writes=0,refreshes=0}
    -- Generic renderer callbacks are evaluated safely. AceConfig range
    -- metadata remains numeric in the registered raid option tested below.
    local option={type="range",name="Icon size",arg="range-test",
        max=function()return state.maximum end,step=function()return state.step end,isPercent=function()return state.percent end,
        desc=function()return "Current cap: "..state.maximum end,
        get=function()state.getterGuard=state.row and state.row._setting;return state.value end,
        set=function(info,value)
            check(info[0]=="FluxUI"and info[1]=="range"and info.arg=="range-test","user changes invoke the actual inherited setter contract")
            state.writes=state.writes+1;state.value=value
        end}
    option.min=function(info)check(info[1]=="range"and info.option==option,"dynamic bounds receive the actual option path");return state.minimum end
    local row,slider,valueText=create(option);state.row=row
    e.FluxOptions={RefreshOpenPage=function()state.refreshes=state.refreshes+1;row:Refresh()end}
    row:Refresh()
    check(near(slider.minimum,0.5)and near(slider.maximum,2.5)and near(slider.step,0.05),client..": callback bounds/step configure the actual slider")
    check(near(slider.value,2.4)and state.writes==0 and valueText.text=="2.40",client..": opening a range displays its getter without saving")
    check(row._desc=="Current cap: 2.5",client..": callback description is shown initially")
    local sameRow=row
    state.maximum=1.2;state.step=0.1;state.percent=true
    row:Refresh()
    check(row==sameRow and near(slider.maximum,1.2)and near(slider.step,0.1),client..": a cached row refreshes new bounds and step")
    check(slider.clamps and slider.clamps>0 and state.value==2.4 and state.writes==0,
        client..": synchronous engine clamp on range refresh never overwrites the saved getter value")
    check(near(slider.value,1.2)and valueText.text=="120%"and row._desc=="Current cap: 1.2",
        client..": refreshed display clamps and updates percentage format/description")
    state.maximum=3;state.percent=false;state.step=0.05
    local setDescription=row.SetDescription
    row.SetDescription=function(self,text)state.descriptionGuard=self._setting;return setDescription(self,text)end
    row._setting="outer-owner";row:Refresh()
    check(state.descriptionGuard=="outer-owner",client..": configuring refreshed metadata restores the previous setting guard before updating the description")
    check(state.writes==0 and state.value==2.4 and near(slider.value,2.4),client..": increasing the range reveals the saved value without migrating it")
    slider:SetValue(0.75)
    check(state.writes==1 and near(state.value,0.75)and state.refreshes==0,
        client..": actual drag handler calls the setter once and avoids rebuilding the page mid-drag")
    slider.scripts.OnMouseUp(slider)
    check(state.writes==2 and state.refreshes==1 and option._fluxSkipRefresh==nil,
        client..": actual mouse-up commits and refreshes the cached page")

    option.disabled=true;row:Refresh();slider:SetValue(0.8);slider.scripts.OnMouseUp(slider)
    check(state.writes==2 and not slider.mouse,client..": disabled sliders keep both drag and commit inert")
    option.disabled=nil

    local literal,literalSlider,literalText=create({type="range",name="Literal",min=0,max=10,step=1,isPercent=false,get=function()return 0 end})
    literal:Refresh()
    check(literalSlider.minimum==0 and literalSlider.maximum==10 and literalSlider.step==1 and literalText.text=="0",
        client..": literal bounds preserve zero and integer formatting")
    local soft,softSlider=create({type="range",name="Soft",min=-10,max=10,step=1,softMin=0,softMax=0,bigStep=0,get=function()return 7 end})
    soft:Refresh()
    check(softSlider.minimum==0 and softSlider.maximum==0 and not softSlider.obeyStep and softSlider.value==0,
        client..": literal soft bounds and zero continuous step keep their established precedence")
    local function failed()error("modeled metadata failure")end
    local fallback,fallbackSlider=create({type="range",name="Fallback",min=0,max=3,step=0.25,
        softMin=failed,softMax=failed,bigStep=failed,isPercent=failed,desc=failed,get=function()return 1.5 end})
    fallback:Refresh()
    check(fallbackSlider.minimum==0 and fallbackSlider.maximum==3 and fallbackSlider.step==0.25 and fallback._desc=="",
        client..": failed optional metadata callbacks fall back to numeric metadata without aborting refresh")
    local defaults,defaultSlider,defaultText=create({type="range",name="Defaults",min=failed,max=failed,step=failed,isPercent=function()return false end,get=function()return 0.5 end})
    defaults:Refresh()
    check(defaultSlider.minimum==0 and defaultSlider.maximum==100 and not defaultSlider.obeyStep and defaultText.text=="0.50",
        client..": failed base callbacks use established defaults and a false percent callback stays false")
end
local function numericMetadata(client,source)
    local e,create=fixture(source)
    local state={cap=2.5,value=2.4,writes=0,sync="get"}
    local option={type="range",name="Aura size",min=0.5,max=2.5,step=0.05,isPercent=false}
    option.get=function()
        if state.sync=="get"then option.max=state.cap end
        return state.value
    end
    option.desc=function()
        if state.sync=="desc"then option.max=state.cap end
        return "Fitted maximum: "..state.cap
    end
    option.set=function(_,value)state.value=value;state.writes=state.writes+1 end
    local row,slider=create(option);row:Refresh()
    check(type(option.min)=="number"and type(option.max)=="number"and type(option.step)=="number",
        client..": factory-owned numeric metadata retains the AceConfig range schema")
    check(near(slider.value,2.4)and state.writes==0,client..": initial numeric range preserves saved data")
    state.cap=1.2;row:Refresh()
    check(type(option.max)=="number"and near(slider.maximum,1.2)and near(slider.value,1.2),
        client..": cached range reads getter-updated numeric bounds before configuring the widget")
    check(state.value==2.4 and state.writes==0 and slider.clamps>0,
        client..": getter-updated numeric bounds clamp only the display despite synchronous engine callbacks")
    state.sync="desc";state.cap=0.9;option.step=0.01;row:Refresh()
    check(near(slider.maximum,0.9)and near(slider.step,0.01)and near(slider.value,0.9)
        and row._desc=="Fitted maximum: 0.9"and row.searchText:find("fitted maximum: 0.9",1,true),
        client..": description-updated numeric bounds refresh before configuring cached range/search text")
    check(state.value==2.4 and state.writes==0,client..": display/description refresh never writes legacy values above the new fitted cap")
    slider:SetValue(0.7);slider.scripts.OnMouseUp(slider)
    check(state.writes==2 and near(state.value,0.7),client..": numeric metadata retains actual drag and commit setter delivery")
end
for _,client in ipairs({"live","forever","classic","classic_era","classic_anniversary"})do
    numericMetadata(client,rendererSource);exercise(client,rendererSource)
end
local noRefresh,replacements=rendererSource:gsub('local minV = ConfigureRange%(self, option, root, path%)','local minV = 0',1)
check(replacements==1 and not pcall(numericMetadata,"live",noRefresh),"negative control rejects stale cached range bounds")
local noGuard,guardReplacements=rendererSource:gsub('    row%._setting = true\n    row:Configure','    row:Configure',1)
check(guardReplacements==1 and not pcall(numericMetadata,"live",noGuard),"negative control rejects saved-data writes from synchronous engine clamping")
local noDescription,descriptionReplacements=rendererSource:gsub('if self.SetDescription then self:SetDescription%(description%) end','-- stale description',1)
check(descriptionReplacements==1 and not pcall(numericMetadata,"live",noDescription),"negative control rejects stale cached range descriptions")
print("Options dynamic range: "..checks.." checks; complete renderer/widgets across five engine models; three rejected controls; native callbacks/rendering pending")
