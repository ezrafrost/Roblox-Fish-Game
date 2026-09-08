-- Rods scale RARITY luck (rollRarity), bought once with coins and equipped
-- persistently - unlike bait, which is a consumable per-cast resource (BaitConfig).
local RodConfig = {
	WoodenRod = { Luck = 1.0, Price = 0 },
	IronRod = { Luck = 1.2, Price = 750 },
	SteelRod = { Luck = 1.5, Price = 4000 },
	GoldenRod = { Luck = 2.0, Price = 20000 },
	DiamondRod = { Luck = 2.75, Price = 100000 },
	CelestialRod = { Luck = 4.0, Price = 500000 },
}

return RodConfig