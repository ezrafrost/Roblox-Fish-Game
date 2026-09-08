local RemotesSetup = require(script.Bootstrap.RemotesSetup)
RemotesSetup.Init()

local DataService = require(script.Services.DataService)
DataService.Init()

local IndexService = require(script.Services.IndexService)
IndexService.Init()

local AnnounceService = require(script.Services.AnnounceService)
AnnounceService.Init()

local BoostService = require(script.Services.BoostService)
BoostService.Init()

local FishingService = require(script.Services.FishingService)
FishingService.Init()

local EconomyService = require(script.Services.EconomyService)
EconomyService.Init()

local PlotService = require(script.Services.PlotService)
PlotService.Init()

local TankService = require(script.Services.TankService)
TankService.Init()

local GrowthService = require(script.Services.GrowthService)
GrowthService.Init()

local MonetizationService = require(script.Services.MonetizationService)
MonetizationService.Init()

local PolicyServiceWrapper = require(script.Services.PolicyServiceWrapper)
PolicyServiceWrapper.Init()

local TradeService = require(script.Services.TradeService)
TradeService.Init()

-- Dev diagnostic: on server start, sample the fishing roll distribution for a
-- couple of rods and print the realised rarity frequencies. Used to sanity-check
-- OddsCalculator's weights while tuning the economy - not a gameplay system.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RarityConfig = require(ReplicatedStorage.Config.RarityConfig)
local RodConfig = require(ReplicatedStorage.Config.RodConfig)

local function sampleDistribution(zoneId: string, luck: number, sampleSize: number)
	local counts = {}
	for _ = 1, sampleSize do
		local fish = FishingService.GenerateFish(zoneId, luck)
		counts[fish.rarity] = (counts[fish.rarity] or 0) + 1
	end
	for _, tier in ipairs(RarityConfig.Order) do
		local count = counts[tier] or 0
		print(("  %s = %d / %d = %.4f%%"):format(tier, count, sampleSize, (count / sampleSize) * 100))
	end
end

local SAMPLE_SIZE = 50000
print(("WoodenRod (luck=%.1f) baseline:"):format(RodConfig.WoodenRod.Luck))
sampleDistribution("Pond", RodConfig.WoodenRod.Luck, SAMPLE_SIZE)
print(("GoldenRod (luck=%.1f):"):format(RodConfig.GoldenRod.Luck))
sampleDistribution("Pond", RodConfig.GoldenRod.Luck, SAMPLE_SIZE)