local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RemoteNames = require(ReplicatedStorage.Shared.RemoteNames)

local AnnounceService = {}

-- Legendary+ per the doc. Highest-leverage retention feature in the whole design -
-- every server-wide rare catch should feel achievable and visible to everyone.
local ANNOUNCE_TIERS = { Legendary = true, Mythic = true, Secret = true }

local remoteEvent: RemoteEvent

function AnnounceService.MaybeAnnounce(player: Player, fish)
	if not ANNOUNCE_TIERS[fish.rarity] then
		return
	end

	remoteEvent:FireAllClients({
		playerName = player.Name,
		species = fish.species,
		rarity = fish.rarity,
		muts = fish.muts,
	})
end

function AnnounceService.Init()
	remoteEvent = ReplicatedStorage.Remotes:WaitForChild(RemoteNames.RareCatchAnnouncement)
end

return AnnounceService