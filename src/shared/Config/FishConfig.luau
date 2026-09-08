-- Pond roster (Phase 1 vertical slice): 10 species, one per rarity tier except
-- Common/Uncommon/Rare which get two each so the starter zone doesn't feel thin.
-- The 4 zones added in Phase 5 each get their own 13-species roster below (62 total).
local FishConfig = {
	Minnow = { BaseValue = 5, MinWeight = 0.1, MaxWeight = 0.3, AvgWeight = 0.2, GrowMultiplier = 1 },
	Bluegill = { BaseValue = 8, MinWeight = 0.2, MaxWeight = 0.5, AvgWeight = 0.35, GrowMultiplier = 1 },

	Bass = { BaseValue = 25, MinWeight = 0.5, MaxWeight = 1.5, AvgWeight = 1, GrowMultiplier = 1.1 },
	Catfish = { BaseValue = 35, MinWeight = 1, MaxWeight = 3, AvgWeight = 2, GrowMultiplier = 1.2 },

	Pike = { BaseValue = 100, MinWeight = 1.5, MaxWeight = 4, AvgWeight = 2.75, GrowMultiplier = 1.3 },
	Sturgeon = { BaseValue = 150, MinWeight = 3, MaxWeight = 8, AvgWeight = 5.5, GrowMultiplier = 1.5 },

	GoldenKoi = { BaseValue = 500, MinWeight = 1, MaxWeight = 2.5, AvgWeight = 1.75, GrowMultiplier = 1.5 },

	AncientTurtle = { BaseValue = 2000, MinWeight = 5, MaxWeight = 12, AvgWeight = 8.5, GrowMultiplier = 2 },

	KrakenSpawn = { BaseValue = 8000, MinWeight = 10, MaxWeight = 25, AvgWeight = 17.5, GrowMultiplier = 2.5 },

	VoidLeviathan = { BaseValue = 50000, MinWeight = 20, MaxWeight = 50, AvgWeight = 35, GrowMultiplier = 3 },

	-- Lake (~1.5x Pond's values)
	Perch = { BaseValue = 8, MinWeight = 0.1, MaxWeight = 0.4, AvgWeight = 0.25, GrowMultiplier = 1 },
	Crappie = { BaseValue = 10, MinWeight = 0.15, MaxWeight = 0.5, AvgWeight = 0.3, GrowMultiplier = 1 },
	Sunfish = { BaseValue = 9, MinWeight = 0.1, MaxWeight = 0.35, AvgWeight = 0.22, GrowMultiplier = 1 },
	Walleye = { BaseValue = 42, MinWeight = 0.8, MaxWeight = 2.5, AvgWeight = 1.6, GrowMultiplier = 1.1 },
	Muskie = { BaseValue = 55, MinWeight = 2, MaxWeight = 6, AvgWeight = 4, GrowMultiplier = 1.2 },
	Carp = { BaseValue = 48, MinWeight = 1.5, MaxWeight = 4, AvgWeight = 2.7, GrowMultiplier = 1.15 },
	Salmon = { BaseValue = 190, MinWeight = 2, MaxWeight = 6, AvgWeight = 4, GrowMultiplier = 1.35 },
	Steelhead = { BaseValue = 225, MinWeight = 2.5, MaxWeight = 7, AvgWeight = 4.7, GrowMultiplier = 1.4 },
	GoldenWalleye = { BaseValue = 760, MinWeight = 1.5, MaxWeight = 3.5, AvgWeight = 2.5, GrowMultiplier = 1.5 },
	SilverEel = { BaseValue = 710, MinWeight = 1, MaxWeight = 3, AvgWeight = 2, GrowMultiplier = 1.5 },
	LakeSerpent = { BaseValue = 3100, MinWeight = 8, MaxWeight = 18, AvgWeight = 13, GrowMultiplier = 2 },
	AncientPike = { BaseValue = 12500, MinWeight = 15, MaxWeight = 35, AvgWeight = 25, GrowMultiplier = 2.5 },
	CrystalLeviathan = { BaseValue = 78000, MinWeight = 30, MaxWeight = 70, AvgWeight = 50, GrowMultiplier = 3 },

	-- River (~2.5x Pond's values)
	Chub = { BaseValue = 15, MinWeight = 0.15, MaxWeight = 0.5, AvgWeight = 0.32, GrowMultiplier = 1 },
	Dace = { BaseValue = 14, MinWeight = 0.1, MaxWeight = 0.35, AvgWeight = 0.22, GrowMultiplier = 1 },
	Roach = { BaseValue = 17, MinWeight = 0.15, MaxWeight = 0.45, AvgWeight = 0.3, GrowMultiplier = 1 },
	Trout = { BaseValue = 72, MinWeight = 0.8, MaxWeight = 2.5, AvgWeight = 1.6, GrowMultiplier = 1.1 },
	Grayling = { BaseValue = 85, MinWeight = 1, MaxWeight = 3, AvgWeight = 2, GrowMultiplier = 1.15 },
	Barbel = { BaseValue = 78, MinWeight = 1.5, MaxWeight = 4, AvgWeight = 2.7, GrowMultiplier = 1.15 },
	RiverSturgeon = { BaseValue = 330, MinWeight = 4, MaxWeight = 10, AvgWeight = 7, GrowMultiplier = 1.4 },
	Taimen = { BaseValue = 370, MinWeight = 5, MaxWeight = 12, AvgWeight = 8.5, GrowMultiplier = 1.45 },
	GoldenTrout = { BaseValue = 1300, MinWeight = 1.5, MaxWeight = 3.5, AvgWeight = 2.5, GrowMultiplier = 1.5 },
	EmeraldEel = { BaseValue = 1250, MinWeight = 1, MaxWeight = 3, AvgWeight = 2, GrowMultiplier = 1.5 },
	RiverDragonfish = { BaseValue = 5200, MinWeight = 10, MaxWeight = 22, AvgWeight = 16, GrowMultiplier = 2 },
	TitanCatfish = { BaseValue = 21000, MinWeight = 25, MaxWeight = 55, AvgWeight = 40, GrowMultiplier = 2.5 },
	PhantomKraken = { BaseValue = 130000, MinWeight = 40, MaxWeight = 90, AvgWeight = 65, GrowMultiplier = 3 },

	-- Ocean (~4x Pond's values)
	Herring = { BaseValue = 24, MinWeight = 0.1, MaxWeight = 0.4, AvgWeight = 0.25, GrowMultiplier = 1 },
	Mackerel = { BaseValue = 27, MinWeight = 0.2, MaxWeight = 0.6, AvgWeight = 0.4, GrowMultiplier = 1 },
	Sardine = { BaseValue = 22, MinWeight = 0.05, MaxWeight = 0.25, AvgWeight = 0.15, GrowMultiplier = 1 },
	Snapper = { BaseValue = 110, MinWeight = 1, MaxWeight = 3, AvgWeight = 2, GrowMultiplier = 1.15 },
	Grouper = { BaseValue = 130, MinWeight = 3, MaxWeight = 8, AvgWeight = 5.5, GrowMultiplier = 1.2 },
	Barracuda = { BaseValue = 120, MinWeight = 2, MaxWeight = 5, AvgWeight = 3.5, GrowMultiplier = 1.2 },
	Tuna = { BaseValue = 520, MinWeight = 10, MaxWeight = 25, AvgWeight = 17.5, GrowMultiplier = 1.45 },
	Marlin = { BaseValue = 580, MinWeight = 15, MaxWeight = 35, AvgWeight = 25, GrowMultiplier = 1.5 },
	GoldenSwordfish = { BaseValue = 2100, MinWeight = 8, MaxWeight = 18, AvgWeight = 13, GrowMultiplier = 1.5 },
	AzureShark = { BaseValue = 1950, MinWeight = 20, MaxWeight = 45, AvgWeight = 32, GrowMultiplier = 1.5 },
	OceanTitan = { BaseValue = 8300, MinWeight = 30, MaxWeight = 60, AvgWeight = 45, GrowMultiplier = 2 },
	OceanLeviathan = { BaseValue = 33000, MinWeight = 50, MaxWeight = 100, AvgWeight = 75, GrowMultiplier = 2.5 },
	PoseidonsChosen = { BaseValue = 210000, MinWeight = 60, MaxWeight = 120, AvgWeight = 90, GrowMultiplier = 3 },

	-- AbyssalTrench (~7x Pond's values, deep sea)
	Lanternfish = { BaseValue = 40, MinWeight = 0.05, MaxWeight = 0.2, AvgWeight = 0.12, GrowMultiplier = 1 },
	Viperfish = { BaseValue = 45, MinWeight = 0.1, MaxWeight = 0.3, AvgWeight = 0.2, GrowMultiplier = 1 },
	Hatchetfish = { BaseValue = 42, MinWeight = 0.05, MaxWeight = 0.25, AvgWeight = 0.15, GrowMultiplier = 1 },
	GulperEel = { BaseValue = 190, MinWeight = 1, MaxWeight = 3, AvgWeight = 2, GrowMultiplier = 1.2 },
	Anglerfish = { BaseValue = 210, MinWeight = 1.5, MaxWeight = 4, AvgWeight = 2.7, GrowMultiplier = 1.25 },
	Fangtooth = { BaseValue = 195, MinWeight = 0.5, MaxWeight = 1.5, AvgWeight = 1, GrowMultiplier = 1.2 },
	GiantSquid = { BaseValue = 880, MinWeight = 15, MaxWeight = 35, AvgWeight = 25, GrowMultiplier = 1.5 },
	ColossalIsopod = { BaseValue = 920, MinWeight = 5, MaxWeight = 12, AvgWeight = 8.5, GrowMultiplier = 1.4 },
	AbyssalSerpent = { BaseValue = 3500, MinWeight = 20, MaxWeight = 45, AvgWeight = 32, GrowMultiplier = 1.6 },
	VoidRay = { BaseValue = 3650, MinWeight = 15, MaxWeight = 35, AvgWeight = 25, GrowMultiplier = 1.6 },
	TrenchBehemoth = { BaseValue = 14500, MinWeight = 50, MaxWeight = 100, AvgWeight = 75, GrowMultiplier = 2.2 },
	EldritchHorror = { BaseValue = 58000, MinWeight = 70, MaxWeight = 140, AvgWeight = 105, GrowMultiplier = 2.7 },
	TheKraken = { BaseValue = 360000, MinWeight = 100, MaxWeight = 200, AvgWeight = 150, GrowMultiplier = 3.5 },
}

return FishConfig