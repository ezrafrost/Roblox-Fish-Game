local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteNames = require(ReplicatedStorage.Shared.RemoteNames)
local RarityConfig = require(ReplicatedStorage.Config.RarityConfig)
local MutationConfig = require(ReplicatedStorage.Config.MutationConfig)
local DataService = require(script.Parent.DataService)

local IndexService = {}

-- How "impressive" a catch is, for deciding whether it beats the current
-- best-of-species entry: rarity multiplier times every mutation multiplier stacked
-- (a Common with Rainbow still outscores a plain Legendary - matches the doc's point
-- that low-tier rarity should never feel like dead weight once mutations are in play).
local function comparisonScore(rarity: string, muts: { string }): number
	local score = RarityConfig.Tiers[rarity].Mult
	for _, mutationId in ipairs(muts) do
		score *= MutationConfig.Mutations[mutationId].Mult
	end
	return score
end

-- Called from the same code path as a successful catch. Updates caught count and
-- the best-seen rarity/mutations for that species.
function IndexService.RecordCatch(player: Player, fish)
	local profile = DataService.GetProfile(player)
	if not profile then
		return
	end

	local entry = profile.index[fish.species]
	if not entry then
		entry = { caught = 0, best = { rarity = fish.rarity, muts = fish.muts } }
		profile.index[fish.species] = entry
	end

	entry.caught += 1
	if comparisonScore(fish.rarity, fish.muts) > comparisonScore(entry.best.rarity, entry.best.muts) then
		entry.best = { rarity = fish.rarity, muts = fish.muts }
	end
end

function IndexService.GetIndex(player: Player)
	local profile = DataService.GetProfile(player)
	return profile and profile.index or {}
end

function IndexService.Init()
	local getIndex = ReplicatedStorage.Remotes:WaitForChild(RemoteNames.GetIndex)
	getIndex.OnServerInvoke = function(player: Player)
		return IndexService.GetIndex(player)
	end
end

return IndexService