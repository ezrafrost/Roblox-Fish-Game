local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteNames = require(ReplicatedStorage.Shared.RemoteNames)
local RarityConfig = require(ReplicatedStorage.Config.RarityConfig)
local FishConfig = require(ReplicatedStorage.Config.FishConfig)

local getIndex = ReplicatedStorage.Remotes:WaitForChild(RemoteNames.GetIndex)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- FishConfig is a plain dict (insertion order isn't meaningful), so sort species
-- names for a stable, repeatable display order.
local speciesList = {}
for species in pairs(FishConfig) do
	table.insert(speciesList, species)
end
table.sort(speciesList)

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "IndexUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local toggleButton = Instance.new("TextButton")
toggleButton.Name = "ToggleButton"
toggleButton.AnchorPoint = Vector2.new(0, 0)
toggleButton.Position = UDim2.new(0, 20, 0, 70)
toggleButton.Size = UDim2.fromOffset(120, 40)
toggleButton.Text = "Index"
toggleButton.TextScaled = true
toggleButton.Parent = screenGui

local indexFrame = Instance.new("Frame")
indexFrame.Name = "IndexFrame"
indexFrame.AnchorPoint = Vector2.new(0.5, 0.5)
indexFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
indexFrame.Size = UDim2.fromOffset(420, 500)
indexFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
indexFrame.BackgroundTransparency = 0.2
indexFrame.Visible = false
indexFrame.Parent = screenGui

local completionLabel = Instance.new("TextLabel")
completionLabel.Name = "CompletionLabel"
completionLabel.Size = UDim2.new(1, 0, 0, 40)
completionLabel.BackgroundTransparency = 1
completionLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
completionLabel.TextScaled = true
completionLabel.Text = "Index: 0%"
completionLabel.Parent = indexFrame

local listFrame = Instance.new("ScrollingFrame")
listFrame.Name = "ListFrame"
listFrame.Position = UDim2.new(0, 0, 0, 40)
listFrame.Size = UDim2.new(1, 0, 1, -40)
listFrame.BackgroundTransparency = 1
listFrame.CanvasSize = UDim2.new()
listFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
listFrame.Parent = indexFrame

local listLayout = Instance.new("UIListLayout")
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 2)
listLayout.Parent = listFrame

local function formatEntry(species: string, entry)
	if not entry then
		return species .. ": not caught", Color3.fromRGB(120, 120, 120)
	end

	local mutsText = ""
	if #entry.best.muts > 0 then
		mutsText = " {" .. table.concat(entry.best.muts, ", ") .. "}"
	end

	local tier = RarityConfig.Tiers[entry.best.rarity]
	local colour = tier and tier.Colour or Color3.fromRGB(255, 0, 255)
	local text = ("%s: caught %d, best %s%s"):format(species, entry.caught, entry.best.rarity, mutsText)
	return text, colour
end

local function refresh()
	local index = getIndex:InvokeServer()

	for _, child in ipairs(listFrame:GetChildren()) do
		if child:IsA("TextLabel") then
			child:Destroy()
		end
	end

	local caughtCount = 0
	for _, species in ipairs(speciesList) do
		local entry = index[species]
		if entry then
			caughtCount += 1
		end

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 0, 30)
		label.BackgroundTransparency = 1
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.TextScaled = true
		label.Text, label.TextColor3 = formatEntry(species, entry)
		label.Parent = listFrame
	end

	local completion = (caughtCount / #speciesList) * 100
	completionLabel.Text = ("Index: %d/%d (%.0f%%)"):format(caughtCount, #speciesList, completion)
end

toggleButton.MouseButton1Click:Connect(function()
	indexFrame.Visible = not indexFrame.Visible
	if indexFrame.Visible then
		refresh()
	end
end)