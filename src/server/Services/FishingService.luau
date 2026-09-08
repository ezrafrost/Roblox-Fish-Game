local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")

local FishConfig = require(ReplicatedStorage.Config.FishConfig)
local ZoneConfig = require(ReplicatedStorage.Config.ZoneConfig)
local RarityConfig = require(ReplicatedStorage.Config.RarityConfig)
local MutationConfig = require(ReplicatedStorage.Config.MutationConfig)
local RodConfig = require(ReplicatedStorage.Config.RodConfig)
local BaitConfig = require(ReplicatedStorage.Config.BaitConfig)
local OddsCalculator = require(ReplicatedStorage.Shared.OddsCalculator)
local Types = require(ReplicatedStorage.Shared.Types)
local RemoteNames = require(ReplicatedStorage.Shared.RemoteNames)
local DataService = require(script.Parent.DataService)
local IndexService = require(script.Parent.IndexService)
local AnnounceService = require(script.Parent.AnnounceService)
local BoostService = require(script.Parent.BoostService)

local FishingService = {}
local rng = Random.new()

local CAST_COOLDOWN_SECONDS = 2
local lastCastAt: { [number]: number } = {} -- [UserId] = os.clock() of last successful cast

local MAX_MUTATIONS = 3

local function rollRarity(zoneWeights: { [string]: number }, luck: number): string
	local list, total = OddsCalculator.BuildWeights(zoneWeights, luck)
	local roll = rng:NextNumber() * total
	local acc = 0
	for _, entry in ipairs(list) do
		acc += entry.weight
		if roll <= acc then
			return entry.tier
		end
	end
	return list[#list].tier -- float-error fallback
end

local function rollSpecies(zoneId: string, rarity: string): string
	local zone = ZoneConfig[zoneId]
	local pool = zone.Species[rarity]
	if not pool or #pool == 0 then
		warn(("Zone %s has no species for rarity %s"):format(zoneId, rarity))
		pool = zone.Species.Common
	end
	return pool[rng:NextInteger(1, #pool)]
end

-- Rainbow is rolled first and is exclusive: if it hits, nothing else is added.
-- Otherwise the remaining mutations roll independently and stack, capped at 3.
local function rollMutations(mutLuck: number): { string }
	for _, id in ipairs(MutationConfig.Exclusive) do
		local m = MutationConfig.Mutations[id]
		if rng:NextNumber() < (m.Chance * mutLuck) then
			return { id }
		end
	end

	local result = {}
	for _, id in ipairs(MutationConfig.Order) do
		if #result >= MAX_MUTATIONS then
			break
		end
		local m = MutationConfig.Mutations[id]
		if rng:NextNumber() < (m.Chance * mutLuck) then
			table.insert(result, id)
		end
	end
	return result
end

-- Which zone (if any) contains a world position, by checking each Workspace.Zones
-- part's horizontal footprint. Ignores rotation/height - these are flat, unrotated
-- ground parts, so an X/Z bounding-box check is all that's needed.
local function findZoneAtPosition(position: Vector3): string?
	local zonesFolder = Workspace:FindFirstChild("Zones")
	if not zonesFolder then
		return nil
	end
	for _, zonePart in ipairs(zonesFolder:GetChildren()) do
		if zonePart:IsA("BasePart") then
			local halfSize = zonePart.Size / 2
			local relative = position - zonePart.Position
			if math.abs(relative.X) <= halfSize.X and math.abs(relative.Z) <= halfSize.Z then
				return zonePart.Name
			end
		end
	end
	return nil
end

local function rollWeight(species: string): number
	local cfg = FishConfig[species]
	-- Triangular-ish distribution: average is common, extremes are rare.
	local a = rng:NextNumber()
	local b = rng:NextNumber()
	local t = (a + b) / 2
	local w = cfg.MinWeight + (cfg.MaxWeight - cfg.MinWeight) * t
	return math.round(w * 10) / 10
end

-- The single entry point. All rolls happen here, server-side, always.
function FishingService.GenerateFish(zoneId: string, luck: number?, mutLuck: number?): Types.Fish
	local zone = ZoneConfig[zoneId]
	local rarity = rollRarity(zone.Weights, luck or 1)
	local species = rollSpecies(zoneId, rarity)

	return {
		id = HttpService:GenerateGUID(false),
		species = species,
		rarity = rarity,
		muts = rollMutations(mutLuck or 1),
		weight = rollWeight(species),
		growth = 0,
		lastTick = os.time(),
		caught = os.time(),
	}
end

-- Cooldown + zone-lock check, then roll. Invoked directly by the CastLine remote.
-- The zone is determined from the player's OWN server-tracked position - never a
-- client-supplied value - so teleporting into a locked zone's bounds is the only way
-- to even attempt fishing there, and it's still rejected unless actually unlocked.
-- baitId is optional; if supplied and actually owned, one is consumed for mutation luck.
function FishingService.OnCastLine(player: Player, baitId: string?): Types.Fish?
	local now = os.clock()
	local last = lastCastAt[player.UserId]
	if last and (now - last) < CAST_COOLDOWN_SECONDS then
		warn(("%s tried to cast before the cooldown expired"):format(player.Name))
		return nil
	end
	lastCastAt[player.UserId] = now

	local character = player.Character
	local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not humanoidRootPart then
		warn(("%s tried to cast with no character"):format(player.Name))
		return nil
	end

	local zoneId = findZoneAtPosition(humanoidRootPart.Position)
	if not zoneId then
		warn(("%s tried to cast while not standing in any zone"):format(player.Name))
		return nil
	end

	local profile = DataService.GetProfile(player)
	if not table.find(profile.unlockedZones, zoneId) then
		warn(("%s tried to cast in a locked zone (%s)"):format(player.Name, zoneId))
		return nil
	end

	local equippedRod = RodConfig[profile.equippedRod] or RodConfig.WoodenRod
	local luck = BoostService.GetLuck(profile) * equippedRod.Luck

	local mutLuck = 1
	if baitId and BaitConfig[baitId] and (profile.baits[baitId] or 0) > 0 then
		profile.baits[baitId] -= 1
		if profile.baits[baitId] <= 0 then
			profile.baits[baitId] = nil
		end
		mutLuck = BaitConfig[baitId].MutLuck
	end

	local fish = FishingService.GenerateFish(zoneId, luck, mutLuck)
	profile.inventory[fish.id] = fish
	IndexService.RecordCatch(player, fish)
	AnnounceService.MaybeAnnounce(player, fish)
	return fish
end

-- Generates a fish with an EXPLICIT rarity/mutation set instead of rolling them.
-- This is a legitimate (non-debug) API: used for guaranteed-purchase products
-- (Step 4.3+) as well as the DebugGenerateFish testing tool below. Does NOT insert
-- into inventory or fire catch side effects - callers decide whether/how to grant it.
function FishingService.GenerateSpecificFish(zoneId: string, rarity: string, muts: { string }): Types.Fish?
	if not RarityConfig.Tiers[rarity] then
		warn(("GenerateSpecificFish: %q is not a valid rarity tier"):format(tostring(rarity)))
		return nil
	end
	for _, mutationId in ipairs(muts) do
		if not MutationConfig.Mutations[mutationId] then
			warn(("GenerateSpecificFish: %q is not a valid mutation"):format(tostring(mutationId)))
			return nil
		end
	end

	local species = rollSpecies(zoneId, rarity)
	return {
		id = HttpService:GenerateGUID(false),
		species = species,
		rarity = rarity,
		muts = muts,
		weight = rollWeight(species),
		growth = 0,
		lastTick = os.time(),
		caught = os.time(),
	}
end

-- TEMP: Step 3.4 VFX testing only. Bypasses rarity/mutation rolls entirely so specific
-- (rare) mutation combos can be tested without waiting out their real odds, and fires
-- the same side effects as a real catch. Remove before Phase 6.
function FishingService.DebugGenerateFish(player: Player, rarity: string, muts: { string }): Types.Fish?
	local fish = FishingService.GenerateSpecificFish("Pond", rarity, muts)
	if not fish then
		return nil
	end

	local profile = DataService.GetProfile(player)
	profile.inventory[fish.id] = fish
	IndexService.RecordCatch(player, fish)
	AnnounceService.MaybeAnnounce(player, fish)
	return fish
end

function FishingService.Init()
	local castLine = ReplicatedStorage.Remotes:WaitForChild(RemoteNames.CastLine)
	castLine.OnServerInvoke = function(player: Player, baitId: string?)
		return FishingService.OnCastLine(player, baitId)
	end

	Players.PlayerRemoving:Connect(function(player)
		lastCastAt[player.UserId] = nil
	end)

	local debugGenerateFish = ReplicatedStorage.Remotes:WaitForChild(RemoteNames.DebugGenerateFish)
	debugGenerateFish.OnServerInvoke = function(player: Player, rarity: string, muts: { string })
		return FishingService.DebugGenerateFish(player, rarity, muts)
	end
end

return FishingService