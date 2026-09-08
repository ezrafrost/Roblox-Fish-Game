-- Real Dev Product/Gamepass IDs, created in Studio's Monetization tab (Step 4.2).
-- Prices are Robux, per doc §10 - kept here for reference/UI display, not authoritative
-- (Roblox's own product info is the source of truth for actual checkout price).
local ProductConfig = {}

ProductConfig.Products = {
	PremiumEgg1 = { Id = 3708965887, Price = 49 },
	PremiumEgg5 = { Id = 3708965923, Price = 199 },
	PremiumEgg20 = { Id = 3708965958, Price = 699 },
	CoinPackSmall = { Id = 3708965990, Price = 49 },
	CoinPackMedium = { Id = 3708966044, Price = 199 },
	CoinPackLarge = { Id = 3708966065, Price = 799 },
	LuckPotion = { Id = 3708966083, Price = 99 },
	ExtraPlotSlot = { Id = 3708966115, Price = 149 },
	GuaranteedLegendaryFish = { Id = 3708966144, Price = 899 },
}

-- Gamepasses (one-time, permanent).
ProductConfig.Gamepasses = {
	DoubleGrowth = { Id = 1952678625, Price = 399 },
	VIP = { Id = 1949680255, Price = 799 },
	AutoFish = { Id = 1953260356, Price = 599 },
	DoubleCoins = { Id = 1954260290, Price = 499 },
}

return ProductConfig