local MutationConfig = {}

-- Rolled first, independently, and short-circuits the rest: if Rainbow hits, no
-- other mutation is added. Everything else stacks (up to a cap enforced by the roller).
MutationConfig.Exclusive = { "Rainbow" }

-- Rolled in this order (excludes Exclusive entries), stacking up to the cap.
MutationConfig.Order = { "Shiny", "Frozen", "Electric", "Golden", "Void", "Radiant" }

MutationConfig.Mutations = {
	Shiny = { Chance = 1 / 25, Mult = 2, Colour = Color3.fromRGB(255, 255, 255), Vfx = "Sparkle" },
	Frozen = { Chance = 1 / 60, Mult = 3, Colour = Color3.fromRGB(150, 220, 255), Vfx = "Mist" },
	Electric = { Chance = 1 / 100, Mult = 5, Colour = Color3.fromRGB(255, 255, 100), Vfx = "Lightning" },
	Golden = { Chance = 1 / 250, Mult = 12, Colour = Color3.fromRGB(255, 215, 0), Vfx = "Glow" },
	Void = { Chance = 1 / 1000, Mult = 40, Colour = Color3.fromRGB(40, 0, 60), Vfx = "RimLight" },
	Radiant = { Chance = 1 / 4000, Mult = 120, Colour = Color3.fromRGB(255, 240, 200), Vfx = "PointLight" },
	Rainbow = {
		Chance = 1 / 25000,
		Mult = 500,
		Colour = Color3.fromRGB(255, 0, 255),
		Vfx = "HueCycle",
		Exclusive = true,
	},
}

return MutationConfig