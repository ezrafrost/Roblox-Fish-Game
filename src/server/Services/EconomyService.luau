local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteNames = require(ReplicatedStorage.Shared.RemoteNames)
local FishValue = require(ReplicatedStorage.Shared.FishValue)
local ZoneConfig = require(ReplicatedStorage.Config.ZoneConfig)
local RodConfig = require(ReplicatedStorage.Config.RodConfig)
local BaitConfig = require(ReplicatedStorage.Config.BaitConfig)
local DataService = require(script.Parent.DataService)

local EconomyService = {}

-- Recomputes the fish's value from the server's own stored record and ignores
-- any client-sent value entirely, per the doc's anti-exploit requirement.
function EconomyService.OnSellFish(player: Player, fishId: string): number?
	local profile = DataService.GetProfile(player)
	local fish = profile.inventory[fishId]
	if not fish then
		warn(("%s tried to sell a fish they don't have (%s)"):format(player.Name, tostring(fishId)))
		return nil
	end

	if fish.isPlaced then
		warn(("%s tried to sell a fish that's placed in a tank (%s)"):format(player.Name, fishId))
		return nil
	end

	local value = FishValue.Calculate(fish)
	profile.coins += value
	profile.inventory[fishId] = nil

	return profile.coins
end

-- Zone gating (Step 5.1) would otherwise be a permanent wall with no way through it -
-- this is the coin-spending complement that actually unlocks a locked zone.
function EconomyService.OnUnlockZone(player: Player, zoneId: string): boolean
	local zone = ZoneConfig[zoneId]
	if not zone then
		warn(("%s tried to unlock an unknown zone (%s)"):format(player.Name, tostring(zoneId)))
		return false
	end

	local profile = DataService.GetProfile(player)
	if table.find(profile.unlockedZones, zoneId) then
		return true
	end

	if profile.coins < zone.UnlockCost then
		warn(("%s tried to unlock %s without enough coins"):format(player.Name, zoneId))
		return false
	end

	profile.coins -= zone.UnlockCost
	table.insert(profile.unlockedZones, zoneId)
	return true
end

-- Rods are owned once (coins) and equipped persistently - the RodConfig.Luck
-- multiplier only applies while equipped, matching the doc's core loop
-- ("Coins -> better rods (luck)").
function EconomyService.OnBuyRod(player: Player, rodId: string): boolean
	local rod = RodConfig[rodId]
	if not rod then
		warn(("%s tried to buy an unknown rod (%s)"):format(player.Name, tostring(rodId)))
		return false
	end

	local profile = DataService.GetProfile(player)
	if table.find(profile.rods, rodId) then
		return true
	end

	if profile.coins < rod.Price then
		warn(("%s tried to buy %s without enough coins"):format(player.Name, rodId))
		return false
	end

	profile.coins -= rod.Price
	table.insert(profile.rods, rodId)
	return true
end

function EconomyService.OnEquipRod(player: Player, rodId: string): boolean
	if not RodConfig[rodId] then
		warn(("%s tried to equip an unknown rod (%s)"):format(player.Name, tostring(rodId)))
		return false
	end

	local profile = DataService.GetProfile(player)
	if not table.find(profile.rods, rodId) then
		warn(("%s tried to equip a rod they don't own (%s)"):format(player.Name, rodId))
		return false
	end

	profile.equippedRod = rodId
	return true
end

-- Bait is a consumable resource (count per baitId), unlike rods - see FishingService.OnCastLine.
function EconomyService.OnBuyBait(player: Player, baitId: string, count: number): boolean
	local bait = BaitConfig[baitId]
	if not bait then
		warn(("%s tried to buy an unknown bait (%s)"):format(player.Name, tostring(baitId)))
		return false
	end
	count = math.max(1, math.floor(count or 1))

	local profile = DataService.GetProfile(player)
	local totalCost = bait.Price * count
	if profile.coins < totalCost then
		warn(("%s tried to buy %dx %s without enough coins"):format(player.Name, count, baitId))
		return false
	end

	profile.coins -= totalCost
	profile.baits[baitId] = (profile.baits[baitId] or 0) + count
	return true
end

function EconomyService.Init()
	local sellFish = ReplicatedStorage.Remotes:WaitForChild(RemoteNames.SellFish)
	sellFish.OnServerInvoke = function(player: Player, fishId: string)
		return EconomyService.OnSellFish(player, fishId)
	end

	local unlockZone = ReplicatedStorage.Remotes:WaitForChild(RemoteNames.UnlockZone)
	unlockZone.OnServerInvoke = function(player: Player, zoneId: string)
		return EconomyService.OnUnlockZone(player, zoneId)
	end

	local buyRod = ReplicatedStorage.Remotes:WaitForChild(RemoteNames.BuyRod)
	buyRod.OnServerInvoke = function(player: Player, rodId: string)
		return EconomyService.OnBuyRod(player, rodId)
	end

	local equipRod = ReplicatedStorage.Remotes:WaitForChild(RemoteNames.EquipRod)
	equipRod.OnServerInvoke = function(player: Player, rodId: string)
		return EconomyService.OnEquipRod(player, rodId)
	end

	local buyBait = ReplicatedStorage.Remotes:WaitForChild(RemoteNames.BuyBait)
	buyBait.OnServerInvoke = function(player: Player, baitId: string, count: number)
		return EconomyService.OnBuyBait(player, baitId, count)
	end
end

return EconomyService