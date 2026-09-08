local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local RemoteNames = require(ReplicatedStorage.Shared.RemoteNames)

local PlotService = {}

local plotsFolder = Workspace:WaitForChild("Plots")
local pool: { BasePart } = {}
for _, child in ipairs(plotsFolder:GetChildren()) do
	if child:IsA("BasePart") then
		table.insert(pool, child)
	end
end
table.sort(pool, function(a, b)
	return a.Name < b.Name
end)

local assignments: { [BasePart]: Player } = {} -- plot -> owning player
local playerPlots: { [Player]: BasePart } = {} -- player -> their assigned plot

-- Finds the first free plot in the pool and assigns it to player. Returns nil
-- (and warns) if every plot is already taken - never assigns the same plot twice.
function PlotService.Assign(player: Player): BasePart?
	for _, plot in ipairs(pool) do
		if not assignments[plot] then
			assignments[plot] = player
			playerPlots[player] = plot
			plot:SetAttribute("Owner", player.UserId)
			print(("%s assigned to %s"):format(player.Name, plot.Name))
			return plot
		end
	end
	warn(("Plot pool exhausted, no free plot for %s"):format(player.Name))
	return nil
end

function PlotService.Release(player: Player)
	local plot = playerPlots[player]
	if plot then
		assignments[plot] = nil
		playerPlots[player] = nil
		plot:SetAttribute("Owner", 0)
	end
end

function PlotService.GetPlot(player: Player): BasePart?
	return playerPlots[player]
end

-- TEMP: dev-testing convenience for visiting other plots without walking. Swept
-- up along with the rest of the Debug* remotes in the Phase 6 lockdown.
function PlotService.DebugTeleportToPlot(player: Player, plotIndex: number): boolean
	local plot = pool[plotIndex]
	local character = player.Character
	if not plot or not character then
		return false
	end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not humanoidRootPart then
		return false
	end

	humanoidRootPart.CFrame = plot.CFrame + Vector3.new(0, 5, 0)
	return true
end

-- Never let a player play without a plot: if the pool is full, kick them immediately
-- rather than leaving them in a server with no plot to place tanks in.
local function assignOrKick(player: Player)
	local plot = PlotService.Assign(player)
	if not plot then
		player:Kick("This server's plots are full - please join another server.")
	end
end

function PlotService.Init()
	Players.PlayerAdded:Connect(assignOrKick)
	for _, player in Players:GetPlayers() do
		assignOrKick(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		PlotService.Release(player)
	end)

	local debugTeleportToPlot = ReplicatedStorage.Remotes:WaitForChild(RemoteNames.DebugTeleportToPlot)
	debugTeleportToPlot.OnServerInvoke = function(player: Player, plotIndex: number)
		return PlotService.DebugTeleportToPlot(player, plotIndex)
	end
end

return PlotService