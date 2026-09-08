export type Fish = {
	id: string,
	species: string,
	rarity: string,
	muts: { string },
	weight: number,
	growth: number,
	lastTick: number,
	caught: number,
	isPlaced: boolean?,
}

export type RarityTier = {
	Weight: number,
	Mult: number,
	Colour: Color3,
	LuckScale: number,
}

export type MutationTier = {
	Chance: number,
	Mult: number,
	Exclusive: boolean?,
}

export type ProfileSchema = {
	coins: number,
	gems: number,
	inventory: { [string]: Fish },
	tanks: { [string]: any },
	plotSlots: number,
	rods: { string },
	equippedRod: string,
	baits: { [string]: number },
	index: { [string]: any },
	unlockedZones: { string },
	stats: { totalCaught: number, rarest: string, playtime: number },
	boosts: { [string]: number },
	gamepasses: { [string]: boolean },
	purchaseHistory: { [string]: number },
	lastLogin: number,
	dailyStreak: number,
}

-- Luau requires a return value even from a types-only module.
return {}