local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local RemoteNames = require(ReplicatedStorage.Shared.RemoteNames)
local FishConfig = require(ReplicatedStorage.Config.FishConfig)
local FishValue = require(ReplicatedStorage.Shared.FishValue)
local DataService = require(script.Parent.DataService)

local GrowthService = {}

local BASE_GROW_TIME = 3600 -- seconds for 0 -> 1 at 1x rate
local HEARTBEAT_INTERVAL = 30

-- Deliberately far below what active fishing pays out (a single catch can be worth
-- thousands) so passive income stays a nice-to-have, never an AFK strategy.
local PASSIVE_INCOME_RATE = 0.0001 -- coins/sec, scaled by the fish's current value

-- Never trust a raw (now - lastTick) unclamped: a DataStore anomaly or a long-idle
-- rejoin could hand a player an enormous elapsed time otherwise. 30 days is generous
-- enough that no legitimate catch-up gets cut short. This matters far more for passive
-- income than for growth - growth is self-limiting via math.min(1, ...), coins are not.
local MAX_ELAPSED_SECONDS = 30 * 24 * 60 * 60

-- Only fish placed in a tank grow or earn passive income. An unplaced fish just has
-- its clock kept current, so time spent loose never counts once it's later placed.
-- A fish keeps earning passive income after it's fully grown - only growth itself caps.
function GrowthService.Update(profile, fishId: string, now: number)
	local fish = profile.inventory[fishId]
	if not fish then
		return
	end

	if not fish.isPlaced then
		fish.lastTick = now
		return
	end

	local elapsed = now - fish.lastTick
	if elapsed <= 0 then
		return
	end
	if elapsed > MAX_ELAPSED_SECONDS then
		warn(("Clamping growth elapsed time for fish %s (was %d s)"):format(fish.id, elapsed))
		elapsed = MAX_ELAPSED_SECONDS
	end

	if fish.growth < 1 then
		local speciesTime = BASE_GROW_TIME * FishConfig[fish.species].GrowMultiplier
		fish.growth = math.min(1, fish.growth + elapsed / speciesTime)
	end

	profile.coins += FishValue.Calculate(fish) * PASSIVE_INCOME_RATE * elapsed
	fish.lastTick = now
end

-- Applies growth for every fish in a profile since it was last updated. Used both
-- for the periodic heartbeat sweep and for catching up a profile right after it loads
-- (elapsed since the player was last online, clamped the same way as any other tick).
function GrowthService.CatchUp(profile)
	local now = os.time()
	for fishId in pairs(profile.inventory) do
		GrowthService.Update(profile, fishId, now)
	end
end

-- TEMP: Step 3.7/3.8 growth testing only. Backdates a fish's clock by simulatedSeconds
-- and immediately processes one growth tick, instead of waiting out the real 30s
-- heartbeat or real wall-clock time. Remove before Phase 6.
function GrowthService.DebugAdvanceFishGrowth(player: Player, fishId: string, simulatedSeconds: number): number?
	local profile = DataService.GetProfile(player)
	local fish = profile and profile.inventory[fishId]
	if not fish then
		return nil
	end

	fish.lastTick = os.time() - simulatedSeconds
	GrowthService.Update(profile, fishId, os.time())
	return fish.growth
end

local function catchUpPlayer(player: Player)
	local profile = DataService.GetProfile(player)
	if profile then
		GrowthService.CatchUp(profile)
	end
end

function GrowthService.Init()
	local debugAdvance = ReplicatedStorage.Remotes:WaitForChild(RemoteNames.DebugAdvanceFishGrowth)
	debugAdvance.OnServerInvoke = function(player: Player, fishId: string, simulatedSeconds: number)
		return GrowthService.DebugAdvanceFishGrowth(player, fishId, simulatedSeconds)
	end

	Players.PlayerAdded:Connect(function(player)
		task.spawn(catchUpPlayer, player)
	end)
	for _, player in Players:GetPlayers() do
		task.spawn(catchUpPlayer, player)
	end

	task.spawn(function()
		while true do
			task.wait(HEARTBEAT_INTERVAL)
			for _, profileData in pairs(DataService.GetAllProfileData()) do
				GrowthService.CatchUp(profileData)
			end
		end
	end)
end

return GrowthService