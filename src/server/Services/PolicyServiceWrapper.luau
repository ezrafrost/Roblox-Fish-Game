local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PolicyService = game:GetService("PolicyService")

local RemoteNames = require(ReplicatedStorage.Shared.RemoteNames)

local PolicyServiceWrapper = {}

export type PolicyResult = {
	randomRestricted: boolean,
	tradingAllowed: boolean,
}

local cachedResults: { [Player]: PolicyResult } = {}

-- Fails closed: if the call errors for any reason, treat the player as restricted.
-- A false positive costs one sale; a false negative is a policy violation.
function PolicyServiceWrapper.Check(player: Player): PolicyResult
	local ok, policyInfo = pcall(function()
		return PolicyService:GetPolicyInfoForPlayerAsync(player)
	end)

	if not ok then
		warn(("PolicyService check failed for %s, failing closed (restricted): %s"):format(player.Name, tostring(policyInfo)))
		return { randomRestricted = true, tradingAllowed = false }
	end

	return {
		randomRestricted = policyInfo.ArePaidRandomItemsRestricted,
		tradingAllowed = policyInfo.IsPaidItemTradingAllowed,
	}
end

-- Checked once on join and cached (policy restrictions don't change mid-session,
-- and this avoids re-hitting PolicyService on every shop open).
function PolicyServiceWrapper.GetCached(player: Player): PolicyResult
	return cachedResults[player] or { randomRestricted = true, tradingAllowed = false }
end

-- TEMP: Step 4.7 testing only. Overrides the cached result so the restricted-UI path
-- can be exercised without an actual restricted account. Remove before Phase 6.
function PolicyServiceWrapper.DebugSetOverride(player: Player, restricted: boolean)
	cachedResults[player] = { randomRestricted = restricted, tradingAllowed = not restricted }
end

function PolicyServiceWrapper.Init()
	local function onPlayerAdded(player: Player)
		cachedResults[player] = PolicyServiceWrapper.Check(player)
	end

	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end
	Players.PlayerRemoving:Connect(function(player)
		cachedResults[player] = nil
	end)

	local getPolicyStatus = ReplicatedStorage.Remotes:WaitForChild(RemoteNames.GetPolicyStatus)
	getPolicyStatus.OnServerInvoke = function(player: Player)
		return PolicyServiceWrapper.GetCached(player)
	end

	local debugSetOverride = ReplicatedStorage.Remotes:WaitForChild(RemoteNames.DebugSetPolicyOverride)
	debugSetOverride.OnServerInvoke = function(player: Player, restricted: boolean)
		PolicyServiceWrapper.DebugSetOverride(player, restricted)
		return true
	end
end

return PolicyServiceWrapper