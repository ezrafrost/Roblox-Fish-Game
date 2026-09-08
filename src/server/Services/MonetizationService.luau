local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local RemoteNames = require(ReplicatedStorage.Shared.RemoteNames)
local ProductConfig = require(ReplicatedStorage.Config.ProductConfig)
local BoostConfig = require(ReplicatedStorage.Config.BoostConfig)
local DataService = require(script.Parent.DataService)
local FishingService = require(script.Parent.FishingService)
local IndexService = require(script.Parent.IndexService)
local AnnounceService = require(script.Parent.AnnounceService)
local BoostService = require(script.Parent.BoostService)

local MonetizationService = {}

-- Placeholder amounts - the doc doesn't pin exact coin-pack payouts, these are
-- reasonable starting values to tune later (see doc §15 on retuning economy configs).
local COIN_PACK_AMOUNTS = {
	CoinPackSmall = 1000,
	CoinPackMedium = 5000,
	CoinPackLarge = 25000,
}

local PURCHASE_HISTORY_MAX_AGE = 90 * 24 * 60 * 60

-- Keeps purchaseHistory from growing forever. 90 days is comfortably longer than any
-- realistic duplicate-receipt retry window Roblox would need.
local function prunePurchaseHistory(profile)
	local now = os.time()
	local toRemove = {}
	for purchaseId, timestamp in pairs(profile.purchaseHistory) do
		if now - timestamp > PURCHASE_HISTORY_MAX_AGE then
			table.insert(toRemove, purchaseId)
		end
	end
	for _, purchaseId in ipairs(toRemove) do
		profile.purchaseHistory[purchaseId] = nil
	end
end

-- Rolls `count` real fish (same roll engine as casting, at the player's current
-- luck) straight into inventory, firing the same Index/Announce side effects as a
-- real catch.
local function grantEggs(player: Player, profile, count: number)
	local luck = BoostService.GetLuck(profile)
	for _ = 1, count do
		local fish = FishingService.GenerateFish("Pond", luck)
		profile.inventory[fish.id] = fish
		IndexService.RecordCatch(player, fish)
		AnnounceService.MaybeAnnounce(player, fish)
	end
end

-- Handlers keyed by Dev Product Id. Each receives (player, profile) and is expected
-- to grant the purchase; ProcessReceipt only marks it granted if the handler doesn't error.
local Handlers: { [number]: (Player, any) -> () } = {
	[ProductConfig.Products.PremiumEgg1.Id] = function(player, profile)
		grantEggs(player, profile, 1)
	end,
	[ProductConfig.Products.PremiumEgg5.Id] = function(player, profile)
		grantEggs(player, profile, 5)
	end,
	[ProductConfig.Products.PremiumEgg20.Id] = function(player, profile)
		grantEggs(player, profile, 20)
	end,
	[ProductConfig.Products.CoinPackSmall.Id] = function(_player, profile)
		profile.coins += COIN_PACK_AMOUNTS.CoinPackSmall
	end,
	[ProductConfig.Products.CoinPackMedium.Id] = function(_player, profile)
		profile.coins += COIN_PACK_AMOUNTS.CoinPackMedium
	end,
	[ProductConfig.Products.CoinPackLarge.Id] = function(_player, profile)
		profile.coins += COIN_PACK_AMOUNTS.CoinPackLarge
	end,
	[ProductConfig.Products.LuckPotion.Id] = function(_player, profile)
		profile.boosts.LuckPotion = os.time() + BoostConfig.LuckPotion.DurationSeconds
	end,
	[ProductConfig.Products.ExtraPlotSlot.Id] = function(_player, profile)
		profile.plotSlots += 1
	end,
	[ProductConfig.Products.GuaranteedLegendaryFish.Id] = function(player, profile)
		local fish = FishingService.GenerateSpecificFish("Pond", "Legendary", {})
		if fish then
			profile.inventory[fish.id] = fish
			IndexService.RecordCatch(player, fish)
			AnnounceService.MaybeAnnounce(player, fish)
		end
	end,
}

-- Roblox may call this more than once for the same purchase - must be idempotent.
-- Check purchaseHistory BEFORE granting; only record it AFTER the handler succeeds.
function MonetizationService.ProcessReceipt(receiptInfo): Enum.ProductPurchaseDecision
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local profile = DataService.GetProfile(player)
	if not profile then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	if profile.purchaseHistory[receiptInfo.PurchaseId] then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	local handler = Handlers[receiptInfo.ProductId]
	if not handler then
		warn("Unhandled product: " .. tostring(receiptInfo.ProductId))
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local ok, err = pcall(handler, player, profile)
	if not ok then
		warn("Purchase handler error: " .. tostring(err))
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	profile.purchaseHistory[receiptInfo.PurchaseId] = os.time()
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

-- TEMP: Step 4.3 idempotency testing only. Lets us invoke ProcessReceipt with a
-- fabricated receipt instead of needing the full real purchase UI flow. Remove
-- before Phase 6.
function MonetizationService.DebugSimulateReceipt(
	player: Player,
	productId: number,
	purchaseId: string
): Enum.ProductPurchaseDecision
	return MonetizationService.ProcessReceipt({
		PlayerId = player.UserId,
		ProductId = productId,
		PurchaseId = purchaseId,
	})
end

-- TEMP: Step 4.4 pruning testing only. Seeds a fake 100-day-old entry and a fresh
-- one, prunes, and returns the resulting table so the effect is directly observable
-- without waiting on a real on-join prune. Remove before Phase 6.
function MonetizationService.DebugPruneTest(player: Player)
	local profile = DataService.GetProfile(player)
	if not profile then
		return nil
	end

	profile.purchaseHistory["debug-old"] = os.time() - (100 * 24 * 60 * 60)
	profile.purchaseHistory["debug-recent"] = os.time() - 60

	prunePurchaseHistory(profile)
	return profile.purchaseHistory
end

-- TEMP: Step 4.6 luck-boost testing only. Grants a Luck Potion directly via the
-- real handler, bypassing the purchase flow entirely. Remove before Phase 6.
function MonetizationService.DebugGrantLuckPotion(player: Player): boolean
	local profile = DataService.GetProfile(player)
	if not profile then
		return false
	end
	Handlers[ProductConfig.Products.LuckPotion.Id](player, profile)
	return true
end

local function onPlayerAdded(player: Player)
	local profile = DataService.GetProfile(player)
	if profile then
		prunePurchaseHistory(profile)
	end
end

function MonetizationService.Init()
	MarketplaceService.ProcessReceipt = MonetizationService.ProcessReceipt

	Players.PlayerAdded:Connect(function(player)
		task.spawn(onPlayerAdded, player)
	end)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end

	local debugSimulateReceipt = ReplicatedStorage.Remotes:WaitForChild(RemoteNames.DebugSimulateReceipt)
	debugSimulateReceipt.OnServerInvoke = function(player: Player, productId: number, purchaseId: string)
		return MonetizationService.DebugSimulateReceipt(player, productId, purchaseId)
	end

	local debugPruneTest = ReplicatedStorage.Remotes:WaitForChild(RemoteNames.DebugPruneTest)
	debugPruneTest.OnServerInvoke = function(player: Player)
		return MonetizationService.DebugPruneTest(player)
	end

	local debugGrantLuckPotion = ReplicatedStorage.Remotes:WaitForChild(RemoteNames.DebugGrantLuckPotion)
	debugGrantLuckPotion.OnServerInvoke = function(player: Player)
		return MonetizationService.DebugGrantLuckPotion(player)
	end
end

return MonetizationService