-- Real AH tab/Flux cells/scroll and price-editor callbacks across the five clients.
-- This models widget contracts; native clipping, pixels and controller remain unrun.
local checks, profiles = 0, 0
local function check(value, label) checks=checks+1; assert(value,label) end
local export=setmetatable({FLUX_AH_FIXTURE_EXPORT=true},{__index=_G})
local chunk=assert(loadfile("tests/auction_restock.lua","t",export));if setfenv then setfenv(chunk,export) end
local fixture=chunk()
for _,client in ipairs({"Retail","Forever","MoP","Era","Anniversary"}) do
    local legacy=client=="Era" or client=="Anniversary"
    for _,auctionator in ipairs({false,true}) do for _,syndicator in ipairs({false,true}) do
        profiles=profiles+1
        local A,st,env=fixture(legacy,auctionator,syndicator)
        st.entries={}
        for id=100,179 do
            st.entries[#st.entries+1]={itemID=id,name="Item"..id,target=10,bankCount=0}
            st.bags[id]=10
        end
        st.emit("AUCTION_HOUSE_SHOW");A.Toggle();st.drain()
        local f=A.frame
        check(legacy and f.refresh==nil or not legacy and f.refresh and f.refresh:IsShown(),
            "Scan all restock is allocated only for the modern auction house")
        check(legacy and f.help.text:find("Search then Buy",1,true) and not f.help.text:find("Scan all restock",1,true)
            or not legacy and f.help.text:find("Scan all restock",1,true),
            "old AH help describes per-item search/buy without advertising a whole-list scan")
        check(f.excess:IsShown()==legacy and f.excess:IsEnabled()==legacy,
            "whole-stack excess is available only on the old auction house")
        if not legacy then
            local savedExcess=A.Settings().allowExcessStacks
            f.excess:SetChecked(true);f.excess:Fire("OnClick")
            check(A.Settings().allowExcessStacks==savedExcess and not f.excess:GetChecked(),
                "a stale hidden modern excess control cannot change the saved legacy preference")
        end
        local function NoPurchase(label)
            check(not st.calls.quote and not st.calls.confirm and not st.calls.buyStack,label)
        end
        check(f.scroll.scrollChild==f.content and f.content.parent==f.scroll and f.scroll.mouseWheel,
            "real native scroll child owns the full Flux item grid")
        check(f.prev==nil and f.next==nil and f.page==nil and f.pageSize==nil,
            "the tab has no previous/next controls or hidden page slice")
        check(f.cols==8 and f.gridRows==4 and #f.cells==80 and f.cells[80].row and f.cells[80].row.itemID==179,
            "800x600 owner fits 32 ordinary cells and retains all eighty configured items")
        check(f.content:GetHeight()==840 and f.maxScroll==840-f.viewportHeight,
            "scroll extent includes every row and the last pending/route lines")
        check(f.cells[1].parent==f.content and f.cells[9].slotY==84 and f.cells[80].slotY==756,
            "cells wrap to subsequent flow rows inside the scrolling child")
        check(f.primary.parent==f and f.currencyGroup.gold.parent==f,
            "buy controls and the unit-price editor stay outside the scrolling content")
        local openingFrames=st.frames
        local selected=A.editorID
        f.scroll:Fire("OnMouseWheel",-1)
        check(f.scroll:GetVerticalScroll()==84 and f.scroll.nativeVerticalScroll and A.editorID==selected,
            "wheel scrolling preserves selection and the template's vertical-scroll handler")
        f.scroll:Fire("OnScrollRangeChanged")
        check(f.scroll.nativeScrollRange,"the template's range/scrollbar handler remains installed")
        f.scroll:Fire("OnMouseWheel",-1000)
        check(f.scroll:GetVerticalScroll()==f.maxScroll,"wheel scrolling clamps at the final complete item row")
        st.press(f.cells[80])
        check(A.editorID==179 and f.currencyGroup.itemID==179 and f.scroll:GetVerticalScroll()==f.maxScroll,
            "last item selects its own price editor without moving the mouse user's scroll")
        check(f.cells[80].selectionEdges[1]:IsShown() and not f.cells[1].selectionEdges[1]:IsShown(),
            "gold selection outline follows the item after scrolling")
        check(st.frames>=openingFrames and st.frames<=openingFrames+80*11,
            "first visits add only the existing per-cell decorative regions")
        local frames=st.frames
        f.cells[80]:Fire("OnClick","RightButton")
        check(f.cells[80].editBox:HasFocus() and f.cells[80].editBox:IsShown(),"right-click retains the existing target editor")
        f.cells[80].editBox:Fire("OnEscapePressed")
        check(not f.cells[80].editBox:IsShown() and not f.cells[80].editBox:HasFocus(),"Escape leaves the target editor without changing or buying an item")
        local g=f.currencyGroup
        for key,coin in pairs({gold="Gold",silver="Silver",copper="Copper"}) do
            check(g[key].coin.texture=="Interface/MoneyFrame/UI-"..coin.."Icon","each price field carries its actual currency coin")
            check(g[key].scripts.OnEnter~=nil and g[key].scripts.OnLeave~=nil,"currency coin fields retain localized hover help")
        end
        f.noLimit:SetChecked(false);st.press(f.noLimit)
        g.gold:SetText("1");g.silver:SetText("23");g.copper:SetText("45");g.gold:SetFocus();g.gold:Fire("OnEnterPressed")
        check(A.GetMaxPrice(179)==12345,"three compact coin fields save the selected item's exact unit cap")
        local limit=f.cells[80].limit.text
        check(limit:find("UI-GoldIcon",1,true) and limit:find("UI-SilverIcon",1,true) and limit:find("UI-CopperIcon",1,true),
            "the item cell displays coin symbols instead of g/s/c suffixes")
        g.gold:SetFocus();g.gold:Fire("OnTabPressed")
        check(g.silver:HasFocus() and not g.gold:HasFocus(),"Tab advances native text focus after saving the price")
        g.silver:Fire("OnTabPressed",true)
        check(g.gold:HasFocus() and not g.silver:HasFocus(),"reverse Tab returns to the prior currency field")
        g.gold:SetText("999");g.gold:Fire("OnEscapePressed")
        check(A.GetMaxPrice(179)==12345 and g.gold:GetText()=="1" and not g.gold:HasFocus(),
            "Escape restores the saved price and releases focus")
        f.scroll:SetVerticalScroll(123);A.UpdateUI()
        check(f.scroll:GetVerticalScroll()==123 and st.frames==frames,"ordinary repaint retains scrollbar position and reuses every cell")
        st.entries[1].bankCount=7;A.GetRows(true);A.UpdateUI()
        check(f.cells[1]:GetHeight()==68 and f.cells[9].slotY==94 and f.cells[17].slotY==178,
            "flow rows reserve the shared Grid bank line without overlapping the next row")
        local all=st.entries
        st.entries={all[1]};A.GetRows(true);A.UpdateUI()
        check(f.maxScroll==0 and f.scroll:GetVerticalScroll()==0 and not f.cells[2]:IsShown() and A.editorID==100,
            "shrinking the list clamps scrolling, hides surplus cells and repairs selection")
        st.entries=all;A.GetRows(true);A.UpdateUI()
        check(st.frames==frames and f.cells[80]:IsShown(),"expanding the list reuses its prior cell allocation")
        local owner=legacy and env.AuctionFrame or env.AuctionHouseFrame
        owner:SetSize(640,450);f:Fire("OnSizeChanged")
        check(f.cols==6 and f.gridRows==2 and f.scroll:GetWidth()==572 and f.cells[7].slotY==94,
            "narrow owners reflow the grid while keeping bank, route and pending lines clear")
        f.scroll:SetVerticalScroll(f.maxScroll)
        owner:SetSize(1024,768);f:Fire("OnSizeChanged")
        check(f.cols==11 and f.gridRows==6 and f.scroll:GetVerticalScroll()==f.maxScroll,
            "larger owners expose more items and clamp the prior narrow-view offset")
        NoPurchase("scrolling, selection, text editing, filtering and resizing never issue a purchase")
        local clearCalls,work=0,false
        A.Followup={HasWork=function() return work end,Refresh=function() end,Clear=function() clearCalls=clearCalls+1 end}
        A.UpdateUI();check(f.clearPending==nil,"the auction tab does not expose a Clear pending control")
        work=true;A.UpdateUI()
        check(f.clearPending==nil and clearCalls==0,"unfinished restock keeps automatic reconciliation without a manual clearing button")
        NoPurchase("pending-state repaint never clears receipts or dispatches a native purchase")
        A.Followup=nil
        f:Hide();local hiddenFrames=st.frames;A.UpdateUI()
        check(st.frames==hiddenFrames and not g.gold:HasFocus(),"hidden tab retains no active text focus or repaint allocations")
        st.reset()
        st.start(legacy and {{itemID=100,quantity=10,total=500}} or {{itemID=100,quantity=20,unitPrice=50,numOwnerItems=0}})
        f.scroll:Fire("OnMouseWheel",-1);A.UpdateUI()
        NoPurchase("a ready live offer is still not purchased by a scroll or repaint")
        st.press()
        check((st.calls.quote or st.calls.buyStack)==1,"one real Buy button press retains exactly one native purchase action")
    end end
end
print(("Auction compact scrolling tab: %d checks PASS; %d client/addon profiles; native pixels/clipping/controller/input/taint NOT RUN"):format(checks,profiles))
