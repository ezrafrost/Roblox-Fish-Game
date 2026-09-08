-- Weights = {} means "use RarityConfig's base weights unmodified" (OddsCalculator
-- falls back to RarityConfig.Tiers[tier].Weight for any tier not overridden here).
-- Later zones override this to shift odds (Common down, Legendary+ up) as the actual
-- progression reward - per the doc's own example numbers for a late-game zone.
local ZoneConfig = {
	Pond = {
		Weights = {},
		UnlockCost = 0,
		Species = {
			Common = { "Minnow", "Bluegill" },
			Uncommon = { "Bass", "Catfish" },
			Rare = { "Pike", "Sturgeon" },
			Epic = { "GoldenKoi" },
			Legendary = { "AncientTurtle" },
			Mythic = { "KrakenSpawn" },
			Secret = { "VoidLeviathan" },
		},
	},
	Lake = {
		Weights = { Common = 800, Uncommon = 420, Rare = 180, Epic = 50, Legendary = 12, Mythic = 3 },
		UnlockCost = 500,
		Species = {
			Common = { "Perch", "Crappie", "Sunfish" },
			Uncommon = { "Walleye", "Muskie", "Carp" },
			Rare = { "Salmon", "Steelhead" },
			Epic = { "GoldenWalleye", "SilverEel" },
			Legendary = { "LakeSerpent" },
			Mythic = { "AncientPike" },
			Secret = { "CrystalLeviathan" },
		},
	},
	River = {
		Weights = { Common = 600, Uncommon = 430, Rare = 210, Epic = 65, Legendary = 18, Mythic = 5 },
		UnlockCost = 2500,
		Species = {
			Common = { "Chub", "Dace", "Roach" },
			Uncommon = { "Trout", "Grayling", "Barbel" },
			Rare = { "RiverSturgeon", "Taimen" },
			Epic = { "GoldenTrout", "EmeraldEel" },
			Legendary = { "RiverDragonfish" },
			Mythic = { "TitanCatfish" },
			Secret = { "PhantomKraken" },
		},
	},
	Ocean = {
		Weights = { Common = 400, Uncommon = 420, Rare = 230, Epic = 75, Legendary = 24, Mythic = 7 },
		UnlockCost = 10000,
		Species = {
			Common = { "Herring", "Mackerel", "Sardine" },
			Uncommon = { "Snapper", "Grouper", "Barracuda" },
			Rare = { "Tuna", "Marlin" },
			Epic = { "GoldenSwordfish", "AzureShark" },
			Legendary = { "OceanTitan" },
			Mythic = { "OceanLeviathan" },
			Secret = { "PoseidonsChosen" },
		},
	},
	AbyssalTrench = {
		Weights = { Common = 200, Uncommon = 400, Rare = 250, Epic = 90, Legendary = 30, Mythic = 10 },
		UnlockCost = 50000,
		Species = {
			Common = { "Lanternfish", "Viperfish", "Hatchetfish" },
			Uncommon = { "GulperEel", "Anglerfish", "Fangtooth" },
			Rare = { "GiantSquid", "ColossalIsopod" },
			Epic = { "AbyssalSerpent", "VoidRay" },
			Legendary = { "TrenchBehemoth" },
			Mythic = { "EldritchHorror" },
			Secret = { "TheKraken" },
		},
	},
}

return ZoneConfig