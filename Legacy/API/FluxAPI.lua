-- FluxAPI.lua — bootstrap (modern clients only; loads first)
local addonName, ns = ...
ns.API = ns.API or {}
FluxAPICompat = FluxAPICompat or {}
FLUX_API = FLUX_API or {}

-- Shared upvalues for hot-path wrappers across Core/API modules.
ns._FluxAPICompat = ns._FluxAPICompat or {}
local H = ns._FluxAPICompat
H.addonName = addonName
H.pcall = pcall
H.tostring = tostring
H.tonumber = tonumber
H.type = type
H.select = select
H.next = next
H.GetTime = GetTime
H.strfind = string.find
H.strformat = string.format
H.strmatch = string.match
H.strlower = string.lower
H.strupper = string.upper
H.strsub = string.sub
H.strrep = string.rep
H.strgsub = string.gsub
H.mathfloor = math.floor
H.mathmax = math.max
H.mathmin = math.min
H.mathabs = math.abs
H.issecretvalue = issecretvalue or IsSecretValue
