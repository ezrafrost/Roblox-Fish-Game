local ReplicatedStorage = game:GetService("ReplicatedStorage")
local FishConfig = require(ReplicatedStorage.Config.FishConfig)
local RarityConfig = require(ReplicatedStorage.Config.RarityConfig)
local MutationConfig = require(ReplicatedStorage.Config.MutationConfig)
local Types = require(ReplicatedStorage.Shared.Types)

local FishValue = {}

-- finalValue = BaseValue x rarity.Mult x weight-variance x Π(mutation mults) x growth bonus.
-- Growth term is always 1 until Phase 3's GrowthService starts advancing fish.growth.
function FishValue.Calculate(fish: Types.Fish): number
	local cfg = FishConfig[fish.species]
	local rarity = RarityConfig.Tiers[fish.rarity]
	if not cfg or not rarity then
		warn(("FishValue: fish %s has an invalid species/rarity (%s/%s)"):format(fish.id, tostring(fish.species), tostring(fish.rarity)))
		return 0
	end

	local value = cfg.BaseValue * rarity.Mult
	value *= (0.5 + (fish.weight / cfg.AvgWeight) * 0.5)

	for _, mutationId in ipairs(fish.muts) do
		value *= MutationConfig.Mutations[mutationId].Mult
	end

	value *= (1 + fish.growth * 2)

	return math.floor(value)
end

return FishValue