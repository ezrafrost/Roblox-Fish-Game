local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RarityConfig = require(ReplicatedStorage.Config.RarityConfig)

local OddsCalculator = {}

-- Returns an ordered array of {tier, weight} plus the total.
-- zoneWeights may override individual tiers; anything omitted falls back to RarityConfig's base weight.
function OddsCalculator.BuildWeights(zoneWeights: { [string]: number }, luck: number)
	local list, total = {}, 0
	for _, tier in ipairs(RarityConfig.Order) do
		local data = RarityConfig.Tiers[tier]
		local base = zoneWeights[tier] or data.Weight
		-- luck of 1.0 = no change; 2.0 doubles the rare tiers' weight (scaled per-tier by LuckScale)
		local w = base * (1 + (luck - 1) * data.LuckScale)
		if w > 0 then
			total += w
			table.insert(list, { tier = tier, weight = w })
		end
	end
	return list, total
end

-- Percentages for the disclosure UI. Sums to 100 by construction (exactly, before
-- any display rounding - float sums may drift by an epsilon).
function OddsCalculator.GetPercentages(zoneWeights: { [string]: number }, luck: number)
	local list, total = OddsCalculator.BuildWeights(zoneWeights, luck)
	local out = {}
	for _, entry in ipairs(list) do
		out[entry.tier] = (entry.weight / total) * 100
	end
	return out
end

-- Rounds percentages for display while guaranteeing the shown values still sum to
-- exactly 100 (the doc's compliance requirement). Uses the largest-remainder method:
-- round every value down to `decimals` places, then hand the leftover fractions of a
-- percent to the entries with the largest remainder, one at a time, until exact.
function OddsCalculator.GetDisplayPercentages(zoneWeights: { [string]: number }, luck: number, decimals: number?)
	decimals = decimals or 4
	local raw = OddsCalculator.GetPercentages(zoneWeights, luck)
	local scale = 10 ^ decimals

	local scaled = {}
	local flooredSum = 0
	for tier, pct in pairs(raw) do
		local exact = pct * scale
		local floored = math.floor(exact)
		table.insert(scaled, { tier = tier, floored = floored, remainder = exact - floored })
		flooredSum += floored
	end

	table.sort(scaled, function(a, b)
		return a.remainder > b.remainder
	end)

	local leftover = math.round(100 * scale) - flooredSum

	local result = {}
	for i, entry in ipairs(scaled) do
		local value = entry.floored
		if i <= leftover then
			value += 1
		end
		result[entry.tier] = value / scale
	end

	return result
end

return OddsCalculator