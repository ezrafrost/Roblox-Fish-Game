local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local RemoteNames = require(ReplicatedStorage.Shared.RemoteNames)
local RarityConfig = require(ReplicatedStorage.Config.RarityConfig)

local rareCatchAnnouncement = ReplicatedStorage.Remotes:WaitForChild(RemoteNames.RareCatchAnnouncement)

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local DISPLAY_SECONDS = 4
local FADE_SECONDS = 1

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AnnouncementUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local banner = Instance.new("TextLabel")
banner.Name = "Banner"
banner.AnchorPoint = Vector2.new(0.5, 0)
banner.Position = UDim2.new(0.5, 0, 0, 20)
banner.Size = UDim2.fromOffset(600, 60)
banner.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
banner.BackgroundTransparency = 1
banner.TextTransparency = 1
banner.TextScaled = true
banner.Font = Enum.Font.GothamBold
banner.Text = ""
banner.Parent = screenGui

local activeToken = 0

rareCatchAnnouncement.OnClientEvent:Connect(function(data)
	activeToken += 1
	local myToken = activeToken

	local mutsText = ""
	if #data.muts > 0 then
		mutsText = " {" .. table.concat(data.muts, ", ") .. "}"
	end

	local tier = RarityConfig.Tiers[data.rarity]
	banner.TextColor3 = tier and tier.Colour or Color3.fromRGB(255, 0, 255)
	banner.Text = ("%s caught a %s %s%s!"):format(data.playerName, data.rarity, data.species, mutsText)
	banner.BackgroundTransparency = 0.3
	banner.TextTransparency = 0

	task.delay(DISPLAY_SECONDS, function()
		if myToken ~= activeToken then
			return -- a newer announcement took over before this one finished
		end
		local fadeOut = TweenService:Create(
			banner,
			TweenInfo.new(FADE_SECONDS),
			{ BackgroundTransparency = 1, TextTransparency = 1 }
		)
		fadeOut:Play()
	end)
end)