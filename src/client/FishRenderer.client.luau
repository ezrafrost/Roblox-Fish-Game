local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local RemoteNames = require(ReplicatedStorage.Shared.RemoteNames)
local RarityConfig = require(ReplicatedStorage.Config.RarityConfig)
local MutationConfig = require(ReplicatedStorage.Config.MutationConfig)
local FishValue = require(ReplicatedStorage.Shared.FishValue)

local getPlotDisplay = ReplicatedStorage.Remotes:WaitForChild(RemoteNames.GetPlotDisplay)

local plotsFolder = Workspace:WaitForChild("Plots")

-- Phase 2: static placeholder rendering only, polled on an interval, one
-- GetPlotDisplay call per owned plot. Phase 5 replaces this with a single
-- shared Heartbeat + BulkMoveTo + distance culling + real replication.
local RENDERED_FOLDER_NAME = "RenderedFish"
local REFRESH_INTERVAL = 2

-- VFX budget: at most 1 ParticleEmitter per fish (Golden-tier mutation or above),
-- and PointLights only for Radiant/Rainbow-tier, capped globally at 4 - the highest
-- -value fish win a light each refresh, everyone else still gets the particle.
local MAX_ACTIVE_LIGHTS = 4

local renderedFolder = Instance.new("Folder")
renderedFolder.Name = RENDERED_FOLDER_NAME
renderedFolder.Parent = Workspace

-- Falls back to a visible "something's wrong" color instead of crashing the whole
-- render loop if a persisted fish somehow has an invalid rarity (e.g. old test data).
local function getRarityColour(rarity: string): Color3
	local tier = RarityConfig.Tiers[rarity]
	return tier and tier.Colour or Color3.fromRGB(255, 0, 255)
end

-- The single strongest mutation present on a fish (mutations stack, but VFX is capped
-- at one emitter per fish, so only the highest-value one present decides its look).
local function getBestMutation(fish)
	local best = nil
	for _, mutationId in ipairs(fish.muts) do
		local m = MutationConfig.Mutations[mutationId]
		if not best or m.Mult > best.Mult then
			best = m
		end
	end
	return best
end

local function renderPlot(plot: BasePart, display, lightCandidates)
	local index = 0
	for _, tank in pairs(display.tanks) do
		for _, fishId in ipairs(tank.fish) do
			local fish = display.inventory[fishId]
			if fish then
				index += 1

				local part = Instance.new("Part")
				part.Name = ("Fish_%s_%s"):format(plot.Name, fishId)
				part.Anchored = true
				part.CanCollide = false
				part.CanQuery = false
				part.CanTouch = false
				part.Size = Vector3.new(1.5, 1, 3)
				part.Color = getRarityColour(fish.rarity)
				part.Material = Enum.Material.SmoothPlastic

				local column = (index - 1) % 3
				local row = math.floor((index - 1) / 3)
				local offset = Vector3.new((column - 1) * 5, plot.Size.Y / 2 + 3, row * 5)
				part.CFrame = CFrame.new(plot.Position + offset)
				part.Parent = renderedFolder

				local bestMutation = getBestMutation(fish)
				if bestMutation then
					-- Cheap distinction at every tier: tint the part to the mutation's
					-- color. No new instances, so this doesn't touch the particle budget.
					part.Color = bestMutation.Colour
				end
				if bestMutation and bestMutation.Mult >= MutationConfig.Mutations.Golden.Mult then
					local particle = Instance.new("ParticleEmitter")
					particle.Color = ColorSequence.new(bestMutation.Colour)
					particle.Lifetime = NumberRange.new(0.5, 1)
					particle.Rate = 20
					particle.Parent = part

					if bestMutation.Mult >= MutationConfig.Mutations.Radiant.Mult then
						table.insert(lightCandidates, { part = part, value = FishValue.Calculate(fish) })
					end
				end
			end
		end
	end
end

local function refresh()
	renderedFolder:ClearAllChildren()
	local lightCandidates = {}

	for _, plot in ipairs(plotsFolder:GetChildren()) do
		if plot:IsA("BasePart") then
			local ownerUserId = plot:GetAttribute("Owner")
			if ownerUserId and ownerUserId ~= 0 then
				local display = getPlotDisplay:InvokeServer(ownerUserId)
				if display then
					renderPlot(plot, display, lightCandidates)
				end
			end
		end
	end

	table.sort(lightCandidates, function(a, b)
		return a.value > b.value
	end)
	for i, candidate in ipairs(lightCandidates) do
		if i > MAX_ACTIVE_LIGHTS then
			break
		end
		local light = Instance.new("PointLight")
		light.Color = Color3.new(1, 1, 1)
		light.Range = 12
		light.Brightness = 2
		light.Parent = candidate.part
	end
end

refresh()
task.spawn(function()
	while true do
		task.wait(REFRESH_INTERVAL)
		refresh()
	end
end)