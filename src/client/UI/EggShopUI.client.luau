local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local RemoteNames = require(ReplicatedStorage.Shared.RemoteNames)
local ProductConfig = require(ReplicatedStorage.Config.ProductConfig)
local RarityConfig = require(ReplicatedStorage.Config.RarityConfig)
local ZoneConfig = require(ReplicatedStorage.Config.ZoneConfig)
local OddsCalculator = require(ReplicatedStorage.Shared.OddsCalculator)

local getMyLuck = ReplicatedStorage.Remotes:WaitForChild(RemoteNames.GetMyLuck)
local getPolicyStatus = ReplicatedStorage.Remotes:WaitForChild(RemoteNames.GetPolicyStatus)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- All three egg tiers roll from the same Pond weight table (only the roll COUNT
-- differs), so they share one odds panel rather than each needing its own.
local EGG_PRODUCTS = {
	{ key = "PremiumEgg1", label = "Premium Egg x1" },
	{ key = "PremiumEgg5", label = "Premium Egg x5" },
	{ key = "PremiumEgg20", label = "Premium Egg x20" },
}

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "EggShopUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local toggleButton = Instance.new("TextButton")
toggleButton.Name = "ToggleButton"
toggleButton.AnchorPoint = Vector2.new(0, 0)
toggleButton.Position = UDim2.new(0, 20, 0, 120)
toggleButton.Size = UDim2.fromOffset(120, 40)
toggleButton.Text = "Shop"
toggleButton.TextScaled = true
toggleButton.Parent = screenGui

local shopFrame = Instance.new("Frame")
shopFrame.Name = "ShopFrame"
shopFrame.AnchorPoint = Vector2.new(0.5, 0.5)
shopFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
shopFrame.Size = UDim2.fromOffset(420, 280)
shopFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
shopFrame.BackgroundTransparency = 0.2
shopFrame.Visible = false
shopFrame.Parent = screenGui

-- Normal catalogue: eggs (paid random items) + Luck Potion (probability modifier).
-- Hidden entirely for PolicyService-restricted players.
local normalItemsFrame = Instance.new("Frame")
normalItemsFrame.Name = "NormalItems"
normalItemsFrame.Size = UDim2.new(1, 0, 1, 0)
normalItemsFrame.BackgroundTransparency = 1
normalItemsFrame.Parent = shopFrame

local normalLayout = Instance.new("UIListLayout")
normalLayout.SortOrder = Enum.SortOrder.LayoutOrder
normalLayout.Padding = UDim.new(0, 6)
normalLayout.Parent = normalItemsFrame

-- Restricted catalogue: the guaranteed-purchase alternative, per the doc's policy
-- compliance requirement. Shown ONLY for restricted players, in place of the above.
local restrictedItemsFrame = Instance.new("Frame")
restrictedItemsFrame.Name = "RestrictedItems"
restrictedItemsFrame.Size = UDim2.new(1, 0, 1, 0)
restrictedItemsFrame.BackgroundTransparency = 1
restrictedItemsFrame.Visible = false
restrictedItemsFrame.Parent = shopFrame

local restrictedLayout = Instance.new("UIListLayout")
restrictedLayout.SortOrder = Enum.SortOrder.LayoutOrder
restrictedLayout.Padding = UDim.new(0, 6)
restrictedLayout.Parent = restrictedItemsFrame

local restrictedNotice = Instance.new("TextLabel")
restrictedNotice.Size = UDim2.new(1, -20, 0, 40)
restrictedNotice.BackgroundTransparency = 1
restrictedNotice.TextColor3 = Color3.fromRGB(200, 200, 200)
restrictedNotice.TextScaled = true
restrictedNotice.TextWrapped = true
restrictedNotice.Text = "Random items aren't available on your account. Direct purchase instead:"
restrictedNotice.Parent = restrictedItemsFrame

-- Odds disclosure panel. A visible "Details" button opens this - not a bare (i) icon.
local oddsFrame = Instance.new("Frame")
oddsFrame.Name = "OddsFrame"
oddsFrame.AnchorPoint = Vector2.new(0.5, 0.5)
oddsFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
oddsFrame.Size = UDim2.fromOffset(420, 380)
oddsFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
oddsFrame.BackgroundTransparency = 0.1
oddsFrame.Visible = false
oddsFrame.Parent = screenGui

local oddsTitle = Instance.new("TextLabel")
oddsTitle.Size = UDim2.new(1, 0, 0, 40)
oddsTitle.BackgroundTransparency = 1
oddsTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
oddsTitle.TextScaled = true
oddsTitle.Text = "Odds per egg opened"
oddsTitle.Parent = oddsFrame

local oddsList = Instance.new("Frame")
oddsList.Position = UDim2.new(0, 10, 0, 40)
oddsList.Size = UDim2.new(1, -20, 1, -110)
oddsList.BackgroundTransparency = 1
oddsList.Parent = oddsFrame

local oddsListLayout = Instance.new("UIListLayout")
oddsListLayout.SortOrder = Enum.SortOrder.LayoutOrder
oddsListLayout.Parent = oddsList

local disclaimerLabel = Instance.new("TextLabel")
disclaimerLabel.Position = UDim2.new(0, 10, 1, -66)
disclaimerLabel.Size = UDim2.new(1, -20, 0, 30)
disclaimerLabel.BackgroundTransparency = 1
disclaimerLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
disclaimerLabel.TextScaled = true
disclaimerLabel.TextWrapped = true
disclaimerLabel.Text = ""
disclaimerLabel.Parent = oddsFrame

local closeOddsButton = Instance.new("TextButton")
closeOddsButton.AnchorPoint = Vector2.new(0.5, 1)
closeOddsButton.Position = UDim2.new(0.5, 0, 1, -10)
closeOddsButton.Size = UDim2.fromOffset(140, 36)
closeOddsButton.Text = "Close Details"
closeOddsButton.TextScaled = true
closeOddsButton.Parent = oddsFrame

local function showOdds()
	for _, child in ipairs(oddsList:GetChildren()) do
		if child:IsA("TextLabel") then
			child:Destroy()
		end
	end

	-- Fetched live from the server every time this opens (and while it stays open,
	-- see the poll loop below) so an active Luck Potion is always reflected accurately -
	-- never a static "+Luck!" badge that could drift from the player's true odds.
	local luck = getMyLuck:InvokeServer()
	local percentages = OddsCalculator.GetDisplayPercentages(ZoneConfig.Pond.Weights, luck, 4)
	local sum = 0
	for _, tier in ipairs(RarityConfig.Order) do
		local pct = percentages[tier] or 0
		sum += pct

		local row = Instance.new("TextLabel")
		row.Size = UDim2.new(1, 0, 0, 28)
		row.BackgroundTransparency = 1
		row.TextXAlignment = Enum.TextXAlignment.Left
		row.TextScaled = true
		row.TextColor3 = RarityConfig.Tiers[tier].Colour
		row.Text = ("%s: %.4f%%"):format(tier, pct)
		row.Parent = oddsList
	end

	local luckNote = if luck > 1 then (" (Luck Potion active: %gx)"):format(luck) else ""
	disclaimerLabel.Text = ("Total: %.4f%%. Odds are per egg opened.%s"):format(sum, luckNote)

	shopFrame.Visible = false
	oddsFrame.Visible = true
end

local function addRow(parent: Instance, label: string, price: number, onBuy: () -> (), showDetails: boolean)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, -20, 0, 50)
	row.BackgroundTransparency = 1
	row.Parent = parent

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(showDetails and 0.5 or 0.75, 0, 1, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextScaled = true
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Text = ("%s - %d R$"):format(label, price)
	nameLabel.Parent = row

	if showDetails then
		local detailsButton = Instance.new("TextButton")
		detailsButton.Size = UDim2.new(0.25, 0, 1, 0)
		detailsButton.Position = UDim2.new(0.5, 0, 0, 0)
		detailsButton.Text = "Details"
		detailsButton.TextScaled = true
		detailsButton.Parent = row
		detailsButton.MouseButton1Click:Connect(showOdds)
	end

	local buyButton = Instance.new("TextButton")
	buyButton.Size = UDim2.new(0.25, 0, 1, 0)
	buyButton.Position = UDim2.new(0.75, 0, 0, 0)
	buyButton.Text = "Buy"
	buyButton.TextScaled = true
	buyButton.Parent = row
	buyButton.MouseButton1Click:Connect(onBuy)
end

for _, entry in ipairs(EGG_PRODUCTS) do
	local product = ProductConfig.Products[entry.key]
	addRow(normalItemsFrame, entry.label, product.Price, function()
		MarketplaceService:PromptProductPurchase(player, product.Id)
	end, true)
end

local luckPotion = ProductConfig.Products.LuckPotion
addRow(normalItemsFrame, "Luck Potion (15 min)", luckPotion.Price, function()
	MarketplaceService:PromptProductPurchase(player, luckPotion.Id)
end, false)

local guaranteedFish = ProductConfig.Products.GuaranteedLegendaryFish
addRow(restrictedItemsFrame, "Guaranteed Legendary Fish", guaranteedFish.Price, function()
	MarketplaceService:PromptProductPurchase(player, guaranteedFish.Id)
end, false)

local function refreshShopAccess()
	local status = getPolicyStatus:InvokeServer()
	normalItemsFrame.Visible = not status.randomRestricted
	restrictedItemsFrame.Visible = status.randomRestricted
end

toggleButton.MouseButton1Click:Connect(function()
	shopFrame.Visible = not shopFrame.Visible
	oddsFrame.Visible = false
	if shopFrame.Visible then
		refreshShopAccess()
	end
end)

closeOddsButton.MouseButton1Click:Connect(function()
	oddsFrame.Visible = false
	shopFrame.Visible = true
end)

-- Keep the odds live while the panel is left open, in case a Luck Potion activates
-- or expires mid-view (per the doc: displayed odds must dynamically update, not just
-- on open).
local ODDS_REFRESH_INTERVAL = 3
task.spawn(function()
	while true do
		task.wait(ODDS_REFRESH_INTERVAL)
		if oddsFrame.Visible then
			showOdds()
		end
	end
end)