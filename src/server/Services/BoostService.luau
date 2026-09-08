local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteNames = require(ReplicatedStorage.Shared.RemoteNames)
local BoostConfig = require(ReplicatedStorage.Config.BoostConfig)
local DataService = require(script.Parent.DataService)

local BoostService = {}

-- Current rarity-luck multiplier for a profile: 1 (no boost) unless an unexpired
-- Luck Potion is active. Feeds both the real roll and the live odds display, so
-- they can never show the player something different from what they'd actually get.
function BoostService.GetLuck(profile): number
	local expiry = profile.boosts.LuckPotion
	if expiry and expiry > os.time() then
		return BoostConfig.LuckPotion.LuckMultiplier
	end
	return 1
end

function BoostService.Init()
	local getMyLuck = ReplicatedStorage.Remotes:WaitForChild(RemoteNames.GetMyLuck)
	getMyLuck.OnServerInvoke = function(player: Player)
		local profile = DataService.GetProfile(player)
		return profile and BoostService.GetLuck(profile) or 1
	end
end

return BoostService