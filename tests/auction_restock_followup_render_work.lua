-- Real renderer/widget-call work across unchanged, count-only and settle paints.
-- These are deterministic desktop calls, not native frame latency or FPS.
local checks, trials = 0, 0
local function check(value, label) checks=checks+1;assert(value,label) end
local root=os.getenv("FLUX_AH_ROOT") or "."
local env=setmetatable({FLUX_FOLLOWUP_UI_FIXTURE_EXPORT=true},{__index=_G})
local load=assert(loadfile(root.."/tests/auction_restock_followup_ui.lua","t",env))
if setfenv then setfenv(load,env) end
local Fixture,State=load()
local measure=os.getenv("FLUX_RENDER_WORK_MEASURE_ONLY")=="1"
local fields={"SetPoint","ClearAllPoints","SetSize","SetFont","SetTexture","SetText","Show","Hide","SetEnabled","EnableMouseWheel","Sort","ArtLookup","AtlasLookup","TipClear","TipShow","TipHide"}
local function Snapshot(st)
    local result={}
    for _,key in ipairs(fields) do result[#result+1]=key.."="..(st.work[key] or 0) end
    return table.concat(result,",")
end
local function NoWork(st,keys,label)
    if measure then return end
    for _,key in ipairs(keys) do check((st.work[key] or 0)==0,label..": "..key) end
end
local geometry={"SetPoint","ClearAllPoints","SetSize","SetFont","SetTexture","Show","Hide","EnableMouseWheel","Sort","ArtLookup","AtlasLookup"}
for _,client in ipairs({"Retail","Forever","MoP","Era","Anniversary"}) do
    for trial=1,3 do
        trials=trials+1
        local F,st=Fixture(client=="Retail" or client=="Forever")
        local state=State("vendor",5);st.state=state;st.context.vendor=true;F.Refresh()
        F.icons[3]:Fire("OnEnter")
        st.work={};local starts,stops=st.starts,st.stops
        for _=1,50 do local next=State("vendor",5);next.canAct=true;F.Paint(next) end
        print(("RENDER_WORK %s trial=%d phase=unchanged %s"):format(client,trial,Snapshot(st)))
        NoWork(st,fields,"unchanged publication changes no native art/geometry/text")
        check(st.starts==starts and st.stops==stops and F.frame:IsShown(),"unchanged item actions keep their proc owner and visible frame")

        state.canAct=true;st.work={}
        for _=1,50 do state.items[1003]=state.items[1003]+1;state.quantity=state.quantity+1;F.Paint(state) end
        print(("RENDER_WORK %s trial=%d phase=quantity %s"):format(client,trial,Snapshot(st)))
        NoWork(st,geometry,"quantity publication updates badges without layout/glow churn")
        if not measure then check(st.work.SetText==100,"fifty count updates change only fifty badges and captions") end
        check(F.icons[3].count.text=="54" and st.tipLines[1]=="54 Item1003","changed badge and hovered item tooltip remain current")

        -- Metadata may become available without a new item identity or geometry.
        st.work={};st.iconOverrides[1003]=777;st.nameOverrides[1003]="Loaded item";F.Paint(state)
        if not measure then
            check(st.work.SetTexture==1 and not st.work.SetSize and not st.work.SetFont,"late metadata changes the one item image without reflow")
            check(st.work.TipClear==1 and st.tipLines[1]=="54 Loaded item","late item names update the hovered tooltip")
        end

        local settled={kind="crafting",name="Bandage",quantity=2,items={[200]=6},canAct=false}
        F.Paint(settled);local button=F.button;st.work={}
        settled.settling=true
        for _=1,10 do F.Paint(settled) end
        check(F.frame:IsShown() and F.button==button and button.itemID==200 and button.count.text=="6"
            and not button.enabled and st.glows()==0,"a known settling craft stays visible on the same disabled item button")
        NoWork(st,fields,"unchanged settling publication keeps item display stable")
        settled.settling=nil;settled.items[200],settled.quantity=3,1;F.Paint(settled)
        check(F.frame:IsShown() and F.button==button and button.count.text=="3","trusted craft output updates the retained button without hide/show")
        if not measure then check(not st.work.Hide and not st.work.Show,"craft output publication does not flicker its host or item") end
        F.Paint(nil);check(not F.frame:IsShown() and st.glows()==0,"trusted completion hides immediately and retires private art")
        st.work={};for _=1,50 do F.Paint(nil) end
        print(("RENDER_WORK %s trial=%d phase=hidden %s"):format(client,trial,Snapshot(st)))
        NoWork(st,fields,"completed idle publications do not repeat retirement")
    end
end
print(("Auction follow-up render work: %d checks PASS; %d matched client trials; native pixels/latency/controller/taint/FPS NOT RUN"):format(checks,trials))
