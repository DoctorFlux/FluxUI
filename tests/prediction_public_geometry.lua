-- Actual health-bar factory, partition ledger and prediction painters. The
-- synthetic native rectangles/opaque values do not certify native pixels/taint.
local f=assert(io.open("UnitFrames/FluxUnitFrames_Shared.lua","rb"));local source=f:read("*a"):gsub("\r\n","\n");f:close()
local function cut(first,last)
    local a=assert(source:find(first,1,true),first);return source:sub(a,assert(source:find(last,a+#first,true),last)-1)
end
local checks=0
local function check(v,label)checks=checks+1;assert(v,label)end
local function near(a,b)return type(a)=="number"and math.abs(a-b)<1e-7 end
local body="local addonName,ns=...;local UF,API=ns.UnitFrames,ns.API\n"
    ..cut('local TEXTURE_BAR =','local FluxPowerBarColor')
    ..cut('local ATLAS_RAID_SHIELD_FILL =','--- HP/power text layout')
    ..cut('local function AtlasExists(name)','local function PlayerDeadOrGhost(unit)')
    ..cut('local function ApplyHealthBarArt(health)','-- Blizzard raid-frame absorb assets')
    ..cut('local MAX_INCOMING_HEAL_OVERFLOW','-- AFK: safe boolean + display rules')
    ..cut('function UF.CreateHealthBar(frame)','-- Health bar tint.')
    ..cut('function UF.GetFluxStylePartitionHealthHeight','-- Event Handling')
    .."\nreturn {tile=RefreshTiledOverlayTexCoords,geometry=PredictionGeometry}"
local function boot(client,opaque,petRaised)
    local s={objects={},values={},opaque=opaque,reads=0,forbidden=0,opaqueOps=0,now=0,health=60,max=100,absorb=20,heal=8,antiheal=5,dead=false}
    local e=setmetatable({},{__index=_G});e._G=e
    local function secret(v)
        local function denied()s.opaqueOps=s.opaqueOps+1;error("opaque operation")end
        local t=setmetatable({secret=true},{__lt=denied,__le=denied,__add=denied,__sub=denied,__mul=denied,__div=denied})
        s.values[t]=v;return t
    end
    local function opaqueAmount(v)return opaque and secret(v)or v end
    local function decode(v)return s.values[v]or v end
    s.decode,s.secret=decode,secret
    local api={isMidnight=client=="live"or client=="forever",IsSecretValue=function(v)return type(v)=="table"and rawget(v,"secret")==true end,
        CanAccessValue=function()return true end,SafeGetNumber=function(v,d)return type(v)=="number"and v or d or 0 end,
        UnitGetDetailedHealPrediction=function()end,SafeUnitGetIncomingHeals=function(_,unit)return unit and 5 or s.heal end,
        SafeUnitGetTotalAbsorbs=function()return s.absorb end,SafeUnitGetTotalHealAbsorbs=function()return s.antiheal end}
    local uf={UsesHudUnitBars=function()return api.isMidnight end,GetHudBarTexture=function(v)return v end,
        FrameUsesPortraitLayout=function()return false end,UpdateAtlasBorder=function()end,UpdateOuterBorder=function()end,
        UpdateFramePartitionSeparators=function()end,LayoutThreatBar=function()end}
    local ns={API=api,UnitFrames=uf,AnimatedHealthLossMixin={OnLoad=function()end}}
    local methods={}
    local function object(kind,parent)
        local o=setmetatable({kind=kind,parent=parent,shown=true,width=0,height=0,level=40,points={},scripts={},uvWrites=0},{__index=methods})
        s.objects[#s.objects+1]=o;return o
    end
    local function public(v)if api.IsSecretValue(v)then s.forbidden=s.forbidden+1;error("opaque geometry write")end end
    function methods:SetWidth(v)public(v);self.width=v end
    function methods:SetHeight(v)public(v);self.height=v end
    function methods:SetSize(w,h)public(w);public(h);self.width,self.height=w,h end
    function methods:GetWidth()s.reads=s.reads+1;return opaque and secret(self.width)or self.width end
    function methods:GetHeight()s.reads=s.reads+1;return opaque and secret(self.height)or self.height end
    function methods:SetParent(p)self.parent=p end
    function methods:GetParent()return self.parent end
    function methods:SetPoint(p,r,rp,x,y)public(x);public(y);self.points[p]={r,rp,x,y}end
    function methods:ClearAllPoints()self.points={}end
    function methods:SetAllPoints(r)self.allPoints=r end
    function methods:SetFrameLevel(v)self.level=v end
    function methods:GetFrameLevel()return self.level end
    function methods:SetFrameStrata(v)self.strata=v end
    function methods:GetFrameStrata()return self.strata or(self.parent and self.parent:GetFrameStrata())or"MEDIUM"end
    function methods:SetDrawLayer(layer,sublevel)self.layer,self.sublevel=layer,sublevel end
    function methods:GetNumPoints()local n=0;for _ in pairs(self.points)do n=n+1 end;return n end
    function methods:IsEventRegistered(k)return self.events and self.events[k]end
    function methods:RegisterEvent(k)self.events=self.events or{};self.events[k]=true end
    function methods:SetClipsChildren(v)self.clips=v end
    function methods:EnableMouse(v)self.mouse=v end
    function methods:SetScript(k,v)check(k~="OnUpdate","geometry adds no recurring driver");self.scripts[k]=v end
    function methods:SetTexCoord(...)self.uv={...};self.uvWrites=self.uvWrites+1 end
    function methods:SetTexture(v)self.asset=v;return true end
    function methods:SetAtlas(v)self.asset=v end
    function methods:SetStatusBarTexture(v)self.texture=self.texture or object("Texture",self);self.texture.asset=v end
    function methods:GetStatusBarTexture()return self.texture end
    function methods:SetMinMaxValues(a,b)self.minimum,self.maximum=a,b end
    function methods:GetMinMaxValues()return self.minimum or 0,self.maximum or 100 end
    function methods:SetValue(v)self.value=v end
    function methods:GetValue()return self.value or s.health end
    function methods:CreateTexture(_,layer,_,sublevel)local t=object("Texture",self);t.layer,t.sublevel=layer,sublevel;return t end
    function methods:CreateFontString()return object("FontString",self)end
    function methods:Show()self.shown=true end
    function methods:Hide()self.shown=false end
    function methods:SetShown(v)self.shown=v end
    function methods:SetAlpha(v)self.alpha=v end
    function methods:IsShown()return self.shown end
    for _,name in ipairs({"SetStatusBarColor","SetVertexColor","SetBlendMode","SetReverseFill","SetFont","SetTextColor","SetShadowColor","SetShadowOffset","SetJustifyH","SetText","SetFormattedText","SetHorizTile","SetVertTile"})do
        methods[name]=function(self,...)self[name.."Args"]={...}end
    end
    e.CreateFrame=function(kind,_,parent)check(not s.combat,"all geometry frames precreated outside combat");return object(kind,parent)end
    e.Mixin=function(target,mixin)for k,v in pairs(mixin)do target[k]=v end end
    e.C_Texture={GetAtlasInfo=function()return {}end}
    e.UnitIsDeadOrGhost=function()return s.dead end
    e.IsFluxUnitFrame=function()return true end
    e.InCombatLockdown=function()return s.combat end
    e.UnitGetTotalAbsorbs=function()return opaqueAmount(s.absorb)end
    e.FluxUnitFrames_GetHealthPartitionPct=function()return .6 end
    e.SetTextureWithAddressModeOptions=function(texture,asset,_,x,y)texture.asset=asset;texture.wrapX,texture.wrapY=x,y end
    e.TextureKitConstants={IgnoreAtlasSize=false,AddressModeWrap="REPEAT",AddressModeClamp="CLAMP"}
    local exports=assert(load(body,"@production-public-prediction","t",e))("_FluxUI",ns)
    local frame=object("Button");frame.unit="player"
    frame._fluxPublicFrameLevel=40
    uf.RecordFrameDimensions(frame,250,100);frame:SetSize(250,100)
    if petRaised then
        ns.PlayerFrame=object("Button");ns.PlayerFrame._fluxPublicFrameLevel=40
        uf.CreateBaseFrame=function()return frame end
        local file=assert(io.open("UnitFrames/FluxUnitFrames_Pet.lua","rb"));local pet=file:read("*a"):gsub("\r\n","\n");file:close()
        local begin=assert(pet:find('    local frame = UF.CreateBaseFrame("pet"',1,true))
        local finish=assert(pet:find('    -- Configure portrait position',begin,true))
        assert(load("local _,ns=...;local UF=ns.UnitFrames;local frameWidth,frameHeight=250,100\n"..pet:sub(begin,finish-1),"@production-pet-pre-health-level","t",e))("_FluxUI",ns)
    end
    local health=uf.CreateHealthBar(frame)
    frame.Power=object("StatusBar",frame)
    local calc={mode=0,GetIncomingHeals=function()return opaqueAmount(s.heal),opaqueAmount(5),opaqueAmount(math.max(s.heal-5,0)),false end,
        GetHealAbsorbs=function()return opaqueAmount(s.antiheal),false end,
        SetDamageAbsorbClampMode=function(self,v)self.mode=v end,
        GetDamageAbsorbs=function(self)return opaqueAmount(math.min(s.absorb,self.mode==1 and(s.max-s.health)or s.max)),false end}
    health.healCalc=calc;health:SetMinMaxValues(0,100);health:SetValue(s.health)
    s.frame,s.health,s.uf,s.exports,s.env,s.object=frame,health,uf,exports,e,object
    return s
end
local modernClips,classicClips=0,0
for _,client in ipairs({"era","anniversary","live","forever"})do
    local raised=boot(client,false,true)
    check(raised.frame.level==70 and raised.health.level==72,"real pet raise before health construction preserves parent+2 layering")
    check(raised.health.TextOverlay.level==100,"real pet text overlay preserves parent+30 priority")
    -- Restricted numeric and geometry getters are modeled on Live/Forever.
    -- Classic retains its ordinary readable-health contract.
    for _,opaque in ipairs({false,true})do
        local s=boot(client,opaque and(client=="live"or client=="forever"))
        local frame,h,uf=s.frame,s.health,s.uf
        check(s.reads==0,"first owned construction needs no native dimension getter")
        local expectedClips=(client=="live"or client=="forever")and 3 or 2
        local clips=0
        for _,bar in pairs({forward=frame.totalAbsorbBar,overflow=frame.absorbOverflow,antiheal=frame.healAbsorbBar})do
            local overlay=bar and(bar.shieldOverlay or bar.absorbOverlay)
            if overlay then
                local clip=overlay._fluxTileClip
                check(clip and clip.parent==bar and clip.clips and clip.mouse==false,"owned native clip constructed under its bar")
                check(overlay.parent==clip and clip.points.TOPLEFT and clip.points.BOTTOMRIGHT,"texture canvas cropped by native fill anchors")
                check(clip.level==bar.level and clip:GetFrameStrata()==bar:GetFrameStrata(),"clip preserves original bar level and inherited strata")
                check(overlay.layer=="ARTWORK"and overlay.sublevel==(bar==frame.healAbsorbBar and 2 or 1),"reparent retains original artwork layer and sublevel")
                check(h.TextOverlay.level>clip.level and frame.overAbsorbGlow.parent.level>clip.level,"text and edge glow retain original priority above stripes")
                clips=clips+1
            end
        end
        check(clips==expectedClips,"exact clip allocation count")
        if client=="live"or client=="forever"then modernClips=modernClips+clips else classicClips=classicClips+clips end
        local count=#s.objects
        for _,width in ipairs({35,250,960})do
            for _,height in ipairs({35,100,150})do
                for _,only in ipairs({false,true})do
                    frame._fluxHealthBarOnly=only
                    uf.RecordFrameDimensions(frame,width,height);frame:SetSize(width,height)
                    local hw,hh=uf.SyncPublicHealthGeometry(frame)
                    check(hw==width-4 and hh>0,"first paint resolves public writer dimensions before native reads")
                    uf.UpdateFramePartition(frame)
                    local actualHeight=h.points.BOTTOMRIGHT and(height-4)or h.height
                    check(near(actualHeight,hh),"ledger height equals actual production partition geometry")
                    check(h.points.TOPLEFT[3]==(frame.barAreaLeft or 2),"partition keeps original public left inset")
                    for _,hp in ipairs({0,25,60,100})do
                        s.health=hp;h:SetValue(hp);s.antiheal=5;s.heal=8
                        uf.UpdateHealPrediction(frame)
                        for _,bar in pairs({forward=frame.totalAbsorbBar,overflow=frame.absorbOverflow,antiheal=frame.healAbsorbBar})do
                            local overlay=bar and(bar.shieldOverlay or bar.absorbOverlay)
                            if overlay and overlay.shown then
                                check(overlay.width==hw and overlay.height==hh,"tile canvas follows exact public health dimensions")
                                check(near(overlay.uv[2],hw/32)and near(overlay.uv[4],hh/32),"32 logical pixel tile frequency")
                                for _,fraction in ipairs({0,.1,.5,1})do
                                    local x=hw*fraction
                                    check(near(overlay.uv[2]*x/hw,x/32),"native cropped UV retains stripe phase for any fill width")
                                end
                            end
                        end
                        check(s.forbidden==0,"all prediction layers reject opaque geometry writes")
                    end
                end
            end
        end
        check(#s.objects==count,"repeated layout/heal changes reuse all clip resources")
        -- Partition-only option edits must resize already visible stripes now,
        -- without waiting for another health/prediction event.
        uf.UpdateHealPrediction(frame)
        for _,height in ipairs({44,84,144})do
            uf.RecordFrameDimensions(frame,304,height);frame:SetSize(304,height)
            uf.UpdateFramePartition(frame)
            for _,bar in pairs({frame.totalAbsorbBar,frame.absorbOverflow,frame.healAbsorbBar})do
                local overlay=bar.shieldOverlay or bar.absorbOverlay
                if overlay.shown then
                    check(overlay.width==300 and overlay.height==h._fluxPublicHeight,"active canvas follows layout without prediction event")
                    check(near(overlay.uv[4],h._fluxPublicHeight/32),"partition-only resize preserves vertical stripe frequency")
                end
            end
        end
        -- Match the complete power partition, including additional power,
        -- resource-hidden bars and the party resource-height adjustment.
        frame._fluxHealthBarOnly=false;frame.AdditionalPower=s.object("StatusBar",frame)
        count=#s.objects
        for _,additional in ipairs({false,true})do for _,main in ipairs({false,true})do for _,partyScale in ipairs({.5,.8,1.5})do
            frame.isAdditionalPowerShown=additional;frame._fluxHasMainPower=main
            frame._fluxPartyMember=true;frame._fluxPartyPowerHeightScale=partyScale
            uf.RecordFrameDimensions(frame,250,100);frame:SetSize(250,100)
            local _,planned=uf.SyncPublicHealthGeometry(frame);uf.UpdateFramePartition(frame)
            check(near(planned,h.height)and near(planned,h._fluxPublicHeight),"first-paint plan equals all real power partitions")
        end end end
        frame._fluxPartyMember=nil;frame.isAdditionalPowerShown=false;frame._fluxHasMainPower=true
        uf.UpdateFramePartition(frame)
        s.combat=true
        uf.UpdateFramePartition(frame);uf.UpdateHealPrediction(frame)
        s.combat=false
        check(#s.objects==count,"combat, positive layers and relayout create no additional frame")
        -- Keep the already drawn 60% Health fill separate from a newer 40%
        -- calculator snapshot. The original full width/maxHP normalization is
        -- 300*20/100=60px, independent of the remaining Health span.
        if client=="live"or client=="forever"then
            frame._fluxHealthBarOnly=true;uf.RecordFrameDimensions(frame,304,84);frame:SetSize(304,84);uf.UpdateFramePartition(frame)
            h:SetValue(60);s.health=40;s.absorb=20;uf.UpdateHealPrediction(frame)
            local bar=frame.totalAbsorbBar
            check(near(bar.width*s.decode(bar.value)/s.decode(bar.maximum),60),"different native health/calculator epochs retain full-width normalization")
            local ov=frame.absorbOverflow.shieldOverlay
            local fillPixels=300*.2;local physicalLeft=300-fillPixels
            check(frame.absorbOverflow.SetReverseFillArgs[1]==true,"overflow native reverse fill is retained")
            for _,offset in ipairs({0,1,16,fillPixels})do
                local physicalX=physicalLeft+offset
                check(near((physicalX-physicalLeft)*ov.uv[2]/ov.width,offset/32),"reverse fill visible physical-left stripe phase matches original reset phase")
            end
        end
        -- Setter failures do not commit a stale UV cache; a later paint retries
        -- the same public geometry without another clip allocation.
        local overlay=frame.healAbsorbBar.absorbOverlay
        overlay:Show();local realSetTexCoord=overlay.SetTexCoord;local attempts=0
        overlay.SetTexCoord=function(self,...)attempts=attempts+1;if attempts==1 then error("transient UV failure")end;return realSetTexCoord(self,...)end
        overlay._fluxTileWidth=nil;s.exports.tile(overlay,32)
        check(overlay._fluxTileWidth==nil,"failed UV does not commit geometry cache")
        s.exports.tile(overlay,32);check(attempts==2 and overlay._fluxTileWidth==h._fluxPublicWidth,"same layout retries and commits after success")
        overlay.SetTexCoord=nil
        local reads=s.reads
        for i=1,100 do uf.UpdateHealPrediction(frame)end
        check(s.reads==reads,"steady prediction paints need no child geometry getter")
        check(s.opaqueOps==0,"all restricted positive layers avoid opaque arithmetic and comparisons")
        check(frame.healAbsorbBar.absorbOverlay.SetVertexColorArgs==nil,"stripe artwork tint is retained")
    end
end
print(("Prediction public geometry: %d checks; modern clips=%d classic clips=%d; all layers, first paint, scale dimensions, native clipping/32px math; native pixels/taint pending")
    :format(checks,modernClips,classicClips))
