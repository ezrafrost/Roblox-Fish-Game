local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RemoteNames = require(ReplicatedStorage.Shared.RemoteNames)

local RemotesSetup = {}

-- Broadcast-only remotes (no response expected) are RemoteEvents; everything else
-- defaults to a RemoteFunction since most of our remotes need a value back
-- immediately (the roll result, the new coin total, etc.), not a side channel.
local EVENT_NAMES = {
	[RemoteNames.RareCatchAnnouncement] = true,
}

function RemotesSetup.Init()
	local remotesFolder = ReplicatedStorage.Remotes
	for _, name in pairs(RemoteNames) do
		if not remotesFolder:FindFirstChild(name) then
			local className = EVENT_NAMES[name] and "RemoteEvent" or "RemoteFunction"
			local remote = Instance.new(className)
			remote.Name = name
			remote.Parent = remotesFolder
		end
	end
end

return RemotesSetup