local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.Shared.Types)

local RarityConfig = {}

RarityConfig.Order = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Secret" }

-- LuckScale: how much a luck multiplier affects this tier's weight.
-- 0 = unaffected (Common never gets more likely), 1 = full scaling.
RarityConfig.Tiers = {
	Common = { Weight = 1000, Mult = 1, Colour = Color3.fromRGB(180, 180, 180), LuckScale = 0 } :: Types.RarityTier,
	Uncommon = { Weight = 400, Mult = 2.5, Colour = Color3.fromRGB(85, 220, 85), LuckScale = 0.3 } :: Types.RarityTier,
	Rare = { Weight = 150, Mult = 8, Colour = Color3.fromRGB(60, 150, 255), LuckScale = 0.6 } :: Types.RarityTier,
	Epic = { Weight = 40, Mult = 30, Colour = Color3.fromRGB(180, 80, 255), LuckScale = 1.0 } :: Types.RarityTier,
	Legendary = { Weight = 8, Mult = 150, Colour = Color3.fromRGB(255, 200, 50), LuckScale = 1.0 } :: Types.RarityTier,
	Mythic = { Weight = 2, Mult = 800, Colour = Color3.fromRGB(255, 60, 60), LuckScale = 1.0 } :: Types.RarityTier,
	Secret = { Weight = 0.1, Mult = 10000, Colour = Color3.fromRGB(20, 20, 20), LuckScale = 1.0 } :: Types.RarityTier,
}

return RarityConfig