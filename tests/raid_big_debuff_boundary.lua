-- Optional BigDebuffs retains the readable-client route; it must not inspect
-- or take ownership of the new native aura containers or their secret units.
local file=assert(io.open("RaidFrame/FluxRaidFrame_BigDebuffs.lua","rb"))
local source=file:read("*a");file:close()
local checks=0
local function check(ok,message)checks=checks+1;assert(ok,message)end
local function scenario(body)
    local e=setmetatable({},{__index=_G});e._G=e
    local loader,adds,shows,reads
    adds,shows,reads=0,0,0
    e.CreateFrame=function()
        loader={RegisterEvent=function()end,SetScript=function(self,_,fn)self.event=fn end};return loader
    end
    e.FluxRaidCompat={UnitTokenValid=function()return true end}
    local function provider()
        return {db={profile={raidFrames={enabled=true}}},ShowInRaids=function()return true end,
            AddBigDebuffs=function(_,frame)
                adds=adds+1
                frame.BigDebuffs={{IsShown=function()return true end,SetSize=function(self,w,h)self.width,self.height=w,h end}}
            end,ShowBigDebuffs=function()shows=shows+1 end}
    end
    e.UnitIsPlayer=function(unit)
        reads=reads+1
        assert(unit=="party1","native/restricted unit identity must not be inspected")
        return true
    end
    assert(load(body or source,"@raid BigDebuffs integration","t",e))("_FluxUI",{})
    e.FluxRaidFrame_BigDebuffs_TryUpdate({_fluxRaidUnit=true,unit="unavailable"})
    check(reads==0,"absent optional addon does no work")
    e.BigDebuffs=provider();loader.event(loader,"ADDON_LOADED","BigDebuffs")
    local native={_fluxRaidUnit=true,unit="restricted",_fluxAuraNative=true}
    e.FluxRaidFrame_BigDebuffs_TryUpdate(native)
    check(reads==0 and adds==0 and shows==0,"native aura owner bypasses all legacy queries and attachment")
    local partial={_fluxRaidUnit=true,unit="restricted",_fluxAuraContainers={}}
    e.FluxRaidFrame_BigDebuffs_TryUpdate(partial)
    check(reads==0 and adds==0,"partial native initialization cannot enter readable aura integration")
    local icon={GetWidth=function()return 10 end,GetHeight=function()return 15 end}
    local readable={_fluxRaidUnit=true,unit="party1",debuffFrames={icon},GetName=function()return"FluxRaidGrp1Unit1"end}
    e.FluxRaidFrame_BigDebuffs_TryUpdate(readable)
    check(reads==1 and adds==1 and shows==1 and readable._fluxRaidBigDebuffsHost,"readable legacy integration remains available")
    check(readable.BigDebuffs[1].width==10 and readable.BigDebuffs[1].height==15,"external aura size follows the new compact icon bounds")
    e.BigDebuffs.db.profile.raidFrames.enabled=false
    e.FluxRaidFrame_BigDebuffs_TryUpdate(readable)
    check(reads==1 and adds==1,"disabled optional integration stops queries")
end
scenario()
local mutation,count=source:gsub("if frame%._fluxAuraNative or frame%._fluxAuraContainers then return true end","-- native ownership guard removed",1)
check(count==1 and not pcall(scenario,mutation),"negative control rejects legacy access to restricted native cells")
print("Raid BigDebuffs boundary: "..checks.." checks; native owners, late optional addon, readable compatibility and one rejected control")
