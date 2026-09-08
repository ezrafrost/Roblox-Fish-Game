-- New profiles default to this shape; ProfileStore's :Reconcile() fills in any
-- fields missing from an existing saved profile (e.g. after adding a new field here).
local ProfileTemplate = {
	coins = 0,
	gems = 0,
	inventory = {}, -- [fishId] = Fish
	tanks = {}, -- [tankId] = { slot, fish = {fishId, ...}, model }
	plotSlots = 1,
	rods = { "WoodenRod" },
	equippedRod = "WoodenRod",
	baits = {}, -- [baitId] = count
	index = {}, -- [species] = { caught, best = { rarity, muts } }
	unlockedZones = { "Pond" },
	stats = { totalCaught = 0, rarest = "Common", playtime = 0 },
	boosts = {}, -- [boostId] = expiryUnix
	gamepasses = {},
	purchaseHistory = {}, -- receipt IDs, for idempotency
	lastLogin = 0,
	dailyStreak = 0,
}

return ProfileTemplate