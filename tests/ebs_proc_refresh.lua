-- SAO proc changes must wake standalone Extra Buttons during combat.
local source = assert(loadfile((arg and arg[1]) or "ExtraButtonSystem/Init.lua"))
local checks = 0
local function check(ok, why)
	checks = checks + 1
	assert(ok, why)
end

local evalHandler, glowChanged
local requests, painted = 0, 0
local inCombat = false
local Flux = {
	Client = { isForever = true },
	ButtonFX = { Glow = { OnChange = function(fn) glowChanged = fn end } },
	Scheduler = {
		Register = function(lane, fn)
			check(lane == "eval", "EBS uses its existing eval lane")
			evalHandler = fn
		end,
		Request = function(lane, token)
			check(lane == "eval" and token == "ebs.glow", "proc requests a glow-only eval")
			requests = requests + 1
			evalHandler({ [token] = true })
		end,
	},
	Module = { Register = function() end },
}
_G.SlashCmdList = {}
source("_FluxUI", { Flux = Flux })
local EBS = Flux.EBS
EBS.Paint = { FlushEval = function(tokens)
	if tokens and tokens["ebs.glow"] then
		check(inCombat, "combat proc is painted before combat ends")
		painted = painted + 1
	end
end }
EBS.Start()
check(type(glowChanged) == "function", "EBS subscribes to shared glow changes")
inCombat = true
glowChanged()
check(requests == 1 and painted == 1, "one combat proc refresh reaches standalone buttons")
_G.InCombatLockdown = function() return inCombat end
glowChanged("sao.overlay")
check(requests == 1 and painted == 2,
	"SAO screen callback paints Extra Buttons synchronously in combat")
EBS.Start()
glowChanged()
check(requests == 2 and painted == 3, "repeated Start does not duplicate subscriptions")
print("EBS combat proc refresh: " .. checks .. " checks passed")
