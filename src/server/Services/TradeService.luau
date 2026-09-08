local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteNames = require(ReplicatedStorage.Shared.RemoteNames)
local PolicyServiceWrapper = require(script.Parent.PolicyServiceWrapper)

local TradeService = {}

-- Trading itself is deliberately built last (doc §12 - scams/dupes/moderation load).
-- This is only the policy gate check, wired in now so the guard already exists on
-- day one rather than getting bolted on once real trade logic eventually lands.
function TradeService.AttemptTrade(player: Player): boolean
	local status = PolicyServiceWrapper.GetCached(player)
	if not status.tradingAllowed then
		warn(("%s tried to trade but trading is restricted on their account"):format(player.Name))
		return false
	end
	return true
end

-- TEMP: Step 4.8 gate testing only, since there's no real trade UI yet to trigger
-- this through. Remove once real trading exists (post-Phase-6, per the doc).
function TradeService.Init()
	local debugAttemptTrade = ReplicatedStorage.Remotes:WaitForChild(RemoteNames.DebugAttemptTrade)
	debugAttemptTrade.OnServerInvoke = function(player: Player)
		return TradeService.AttemptTrade(player)
	end
end

return TradeService