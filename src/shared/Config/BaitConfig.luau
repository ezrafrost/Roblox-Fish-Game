-- Bait scales MUTATION luck (rollMutations). Bought with coins into profile.baits
-- (a count per baitId) and consumed one-per-cast when supplied to CastLine - unlike
-- rods, which are owned once and equipped persistently (RodConfig).
local BaitConfig = {
	PlainBait = { MutLuck = 1.0, Price = 0 },
	WormBait = { MutLuck = 1.5, Price = 200 },
	ShrimpBait = { MutLuck = 2.5, Price = 1500 },
	GlowBait = { MutLuck = 4.0, Price = 8000 },
	EnchantedBait = { MutLuck = 7.0, Price = 40000 },
}

return BaitConfig