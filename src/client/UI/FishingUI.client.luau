local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteNames = require(ReplicatedStorage.Shared.RemoteNames)
local RarityConfig = require(ReplicatedStorage.Config.RarityConfig)

local castLine = ReplicatedStorage.Remotes:WaitForChild(RemoteNames.CastLine)
local sellFish = ReplicatedStorage.Remotes:WaitForChild(RemoteNames.SellFish)
local getProfile = ReplicatedStorage.Remotes:WaitForChild(RemoteNames.GetProfile)
local placeFishInTank = ReplicatedStorage.Remotes:WaitForChild(RemoteNames.PlaceFishInTank)
local removeFishFromTank = ReplicatedStorage.Remotes:WaitForChild(RemoteNames.RemoveFishFromTank)

-- Phase 2 only has one tank per plot; a real tank-selection UI arrives once
-- multiple tanks are purchasable.
local DEFAULT_TANK_ID = "Tank1"

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "FishingUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local coinsLabel = Instance.new("TextLabel")
coinsLabel.Name = "CoinsLabel"
coinsLabel.AnchorPoint = Vector2.new(0, 0)
coinsLabel.Position = UDim2.new(0, 20, 0, 20)
coinsLabel.Size = UDim2.fromOffset(200, 40)
coinsLabel.BackgroundTransparency = 1
coinsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
coinsLabel.TextScaled = true
coinsLabel.TextXAlignment = Enum.TextXAlignment.Left
coinsLabel.Text = "Coins: 0"
coinsLabel.Parent = screenGui

local inventoryFrame = Instance.new("ScrollingFrame")
inventoryFrame.Name = "InventoryFrame"
inventoryFrame.AnchorPoint = Vector2.new(1, 0)
inventoryFrame.Position = UDim2.new(1, -20, 0, 20)
inventoryFrame.Size = UDim2.fromOffset(320, 300)
inventoryFrame.BackgroundTransparency = 0.5
inventoryFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
inventoryFrame.CanvasSize = UDim2.new()
inventoryFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
inventoryFrame.Parent = screenGui

local listLayout = Instance.new("UIListLayout")
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 4)
listLayout.Parent = inventoryFrame

local castButton = Instance.new("TextButton")
castButton.Name = "CastButton"
castButton.AnchorPoint = Vector2.new(0.5, 1)
castButton.Position = UDim2.new(0.5, 0, 1, -40)
castButton.Size = UDim2.fromOffset(160, 50)
castButton.Text = "Cast"
castButton.TextScaled = true
castButton.Parent = screenGui

local resultLabel = Instance.new("TextLabel")
resultLabel.Name = "ResultLabel"
resultLabel.AnchorPoint = Vector2.new(0.5, 1)
resultLabel.Position = UDim2.new(0.5, 0, 1, -100)
resultLabel.Size = UDim2.fromOffset(400, 50)
resultLabel.BackgroundTransparency = 1
resultLabel.TextScaled = true
resultLabel.Text = ""
resultLabel.Parent = screenGui

-- Falls back to a visible "something's wrong" color instead of crashing the whole
-- UI if a persisted fish somehow has an invalid rarity (e.g. old test data).
local function getRarityColour(rarity: string): Color3
	local tier = RarityConfig.Tiers[rarity]
	return tier and tier.Colour or Color3.fromRGB(255, 0, 255)
end

local function formatFishLabel(fish)
	local label = ("%s (%s) - %.1fkg"):format(fish.species, fish.rarity, fish.weight)
	if #fish.muts > 0 then
		label ..= " {" .. table.concat(fish.muts, ", ") .. "}"
	end
	if fish.isPlaced then
		label ..= " [in tank]"
	end
	return label
end

local function refreshInventory()
	local profile = getProfile:InvokeServer()
	coinsLabel.Text = "Coins: " .. profile.coins

	for _, child in ipairs(inventoryFrame:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	for fishId, fish in pairs(profile.inventory) do
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, 0, 0, 40)
		row.BackgroundTransparency = 1
		row.Parent = inventoryFrame

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(0.5, 0, 1, 0)
		label.BackgroundTransparency = 1
		label.TextColor3 = getRarityColour(fish.rarity)
		label.TextScaled = true
		label.Text = formatFishLabel(fish)
		label.Parent = row

		if fish.isPlaced then
			local removeButton = Instance.new("TextButton")
			removeButton.Size = UDim2.new(0.5, 0, 1, 0)
			removeButton.Position = UDim2.new(0.5, 0, 0, 0)
			removeButton.Text = "Remove"
			removeButton.TextScaled = true
			removeButton.Parent = row

			removeButton.MouseButton1Click:Connect(function()
				removeFishFromTank:InvokeServer(DEFAULT_TANK_ID, fishId)
				refreshInventory()
			end)
		else
			local placeButton = Instance.new("TextButton")
			placeButton.Size = UDim2.new(0.25, 0, 1, 0)
			placeButton.Position = UDim2.new(0.5, 0, 0, 0)
			placeButton.Text = "Place"
			placeButton.TextScaled = true
			placeButton.Parent = row

			placeButton.MouseButton1Click:Connect(function()
				placeFishInTank:InvokeServer(DEFAULT_TANK_ID, fishId)
				refreshInventory()
			end)

			local sellButton = Instance.new("TextButton")
			sellButton.Size = UDim2.new(0.25, 0, 1, 0)
			sellButton.Position = UDim2.new(0.75, 0, 0, 0)
			sellButton.Text = "Sell"
			sellButton.TextScaled = true
			sellButton.Parent = row

			sellButton.MouseButton1Click:Connect(function()
				sellFish:InvokeServer(fishId)
				refreshInventory()
			end)
		end
	end
end

castButton.MouseButton1Click:Connect(function()
	castButton.Active = false
	local fish = castLine:InvokeServer()
	castButton.Active = true

	if fish then
		resultLabel.TextColor3 = getRarityColour(fish.rarity)
		resultLabel.Text = formatFishLabel(fish)
		refreshInventory()
	else
		resultLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
		resultLabel.Text = "Still reeling in the line..."
	end
end)

refreshInventory()

-- Purchases (and anything else granted server-side outside a direct button click,
-- e.g. ProcessReceipt) have no client-side trigger to refresh on, so poll for them -
-- same pattern FishRenderer already uses for the same class of problem.
local REFRESH_INTERVAL = 3
task.spawn(function()
	while true do
		task.wait(REFRESH_INTERVAL)
		refreshInventory()
	end
end)