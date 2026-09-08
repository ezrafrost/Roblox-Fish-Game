local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteNames = require(ReplicatedStorage.Shared.RemoteNames)
local TankConfig = require(ReplicatedStorage.Config.TankConfig)
local DataService = require(script.Parent.DataService)

local TankService = {}

local DEFAULT_TANK_ID = "Tank1"

-- Every plot starts with one Basic tank. Tanks live inside the player's own
-- profile, so "does this tank belong to the caller" is automatic: we only ever
-- index into the calling player's own profile.tanks, never another player's.
local function ensureDefaultTank(profile)
	if not next(profile.tanks) then
		profile.tanks[DEFAULT_TANK_ID] = { fish = {}, model = "Basic" }
	end
end

-- Client sends only tankId + fishId, never a position - server resolves ownership,
-- capacity, and inventory membership every single call.
function TankService.OnPlaceFish(player: Player, tankId: string, fishId: string): boolean
	local profile = DataService.GetProfile(player)
	if not profile then
		return false
	end
	ensureDefaultTank(profile)

	local tank = profile.tanks[tankId]
	if not tank then
		warn(("%s tried to place a fish in a tank they don't own (%s)"):format(player.Name, tostring(tankId)))
		return false
	end

	local fish = profile.inventory[fishId]
	if not fish then
		warn(("%s tried to place a fish they don't have (%s)"):format(player.Name, tostring(fishId)))
		return false
	end

	if fish.isPlaced then
		warn(("%s tried to place an already-placed fish (%s)"):format(player.Name, fishId))
		return false
	end

	local capacity = TankConfig[tank.model].Capacity
	if #tank.fish >= capacity then
		warn(("%s tried to place a fish in a full tank (%s)"):format(player.Name, tankId))
		return false
	end

	table.insert(tank.fish, fishId)
	fish.isPlaced = true
	return true
end

-- Pulls a fish back out of a tank and back into "loose" inventory (sellable again).
function TankService.OnRemoveFish(player: Player, tankId: string, fishId: string): boolean
	local profile = DataService.GetProfile(player)
	if not profile then
		return false
	end

	local tank = profile.tanks[tankId]
	if not tank then
		warn(("%s tried to remove a fish from a tank they don't own (%s)"):format(player.Name, tostring(tankId)))
		return false
	end

	local fish = profile.inventory[fishId]
	if not fish then
		warn(("%s tried to remove a fish they don't have (%s)"):format(player.Name, tostring(fishId)))
		return false
	end

	local index = table.find(tank.fish, fishId)
	if not index then
		warn(("%s tried to remove a fish that isn't in that tank (%s)"):format(player.Name, fishId))
		return false
	end

	table.remove(tank.fish, index)
	fish.isPlaced = false
	return true
end

function TankService.Init()
	local placeFishInTank = ReplicatedStorage.Remotes:WaitForChild(RemoteNames.PlaceFishInTank)
	placeFishInTank.OnServerInvoke = function(player: Player, tankId: string, fishId: string)
		return TankService.OnPlaceFish(player, tankId, fishId)
	end

	local removeFishFromTank = ReplicatedStorage.Remotes:WaitForChild(RemoteNames.RemoveFishFromTank)
	removeFishFromTank.OnServerInvoke = function(player: Player, tankId: string, fishId: string)
		return TankService.OnRemoveFish(player, tankId, fishId)
	end
end

return TankService