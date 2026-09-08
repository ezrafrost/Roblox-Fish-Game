local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

local RemoteNames = require(ReplicatedStorage.Shared.RemoteNames)
local ProfileTemplate = require(ReplicatedStorage.Config.ProfileTemplate)
local ProfileStore = require(ServerScriptService.ServerPackages.ProfileStore)

local DataService = {}

local PlayerStore = ProfileStore.New("PlayerData_v1", ProfileTemplate)
local profiles: { [Player]: typeof(PlayerStore:StartSessionAsync()) } = {}

local function onPlayerAdded(player: Player)
	local profile = PlayerStore:StartSessionAsync(`{player.UserId}`, {
		Cancel = function()
			return player.Parent ~= Players
		end,
	})

	if profile ~= nil then
		profile:AddUserId(player.UserId)
		profile:Reconcile()

		profile.OnSessionEnd:Connect(function()
			profiles[player] = nil
			player:Kick("Profile session ended - please rejoin")
		end)

		if player.Parent == Players then
			profiles[player] = profile
		else
			-- Player left before the session finished starting.
			profile:EndSession()
		end
	else
		player:Kick("Profile load failed - please rejoin")
	end
end

local function onPlayerRemoving(player: Player)
	local profile = profiles[player]
	if profile ~= nil then
		profile:EndSession()
	end
end

-- Returns the plain data table (matches ProfileTemplate's shape). The live
-- ProfileStore session object never leaves this module. Yields briefly if the
-- profile hasn't finished loading yet (e.g. a remote fired right on join).
function DataService.GetProfile(player: Player)
	local profile = profiles[player]
	local waited = 0
	while not profile and player.Parent == Players and waited < 10 do
		task.wait(0.1)
		waited += 0.1
		profile = profiles[player]
	end
	return profile and profile.Data or nil
end

-- Snapshot of every currently-loaded profile's data table, keyed by player.
-- Used by GrowthService's periodic sweep - never exposed to clients.
function DataService.GetAllProfileData(): { [Player]: any }
	local result = {}
	for player, profile in pairs(profiles) do
		result[player] = profile.Data
	end
	return result
end

-- Read-only view of another (or the caller's own) player's plot for rendering:
-- only tanks + the placed subset of inventory, never coins/purchase history/etc.
function DataService.GetPlotDisplay(ownerUserId: number)
	local targetPlayer = Players:GetPlayerByUserId(ownerUserId)
	if not targetPlayer then
		return nil
	end

	local profile = DataService.GetProfile(targetPlayer)
	if not profile then
		return nil
	end

	local placedInventory = {}
	for fishId, fish in pairs(profile.inventory) do
		if fish.isPlaced then
			placedInventory[fishId] = fish
		end
	end

	return { tanks = profile.tanks, inventory = placedInventory }
end

-- TEMP: Step 2.3 persistence stress testing only. Forces an immediate save so
-- tests don't have to wait out the auto-save interval. Remove before Phase 6
-- (see the doc's "lock down debug remotes before publish" step).
function DataService.DebugForceSave(player: Player): boolean
	local profile = profiles[player]
	if not profile then
		return false
	end
	profile:Save()
	return true
end

function DataService.Init()
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end
	Players.PlayerRemoving:Connect(onPlayerRemoving)

	local getProfile = ReplicatedStorage.Remotes:WaitForChild(RemoteNames.GetProfile)
	getProfile.OnServerInvoke = function(player: Player)
		return DataService.GetProfile(player)
	end

	local debugForceSave = ReplicatedStorage.Remotes:WaitForChild(RemoteNames.DebugForceSave)
	debugForceSave.OnServerInvoke = function(player: Player)
		return DataService.DebugForceSave(player)
	end

	local getPlotDisplay = ReplicatedStorage.Remotes:WaitForChild(RemoteNames.GetPlotDisplay)
	getPlotDisplay.OnServerInvoke = function(_player: Player, ownerUserId: number)
		return DataService.GetPlotDisplay(ownerUserId)
	end
end

return DataService