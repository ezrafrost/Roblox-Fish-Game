-- Single source of truth for remote names, so client/server never hardcode strings.
local RemoteNames = {
	CastLine = "CastLine",
	SellFish = "SellFish",
	GetProfile = "GetProfile",
	DebugForceSave = "DebugForceSave",
	PlaceFishInTank = "PlaceFishInTank",
	RemoveFishFromTank = "RemoveFishFromTank",
	GetPlotDisplay = "GetPlotDisplay",
	DebugTeleportToPlot = "DebugTeleportToPlot",
	DebugGenerateFish = "DebugGenerateFish",
	GetIndex = "GetIndex",
	DebugAdvanceFishGrowth = "DebugAdvanceFishGrowth",
	RareCatchAnnouncement = "RareCatchAnnouncement",
	DebugSimulateReceipt = "DebugSimulateReceipt",
	DebugPruneTest = "DebugPruneTest",
	GetMyLuck = "GetMyLuck",
	DebugGrantLuckPotion = "DebugGrantLuckPotion",
	GetPolicyStatus = "GetPolicyStatus",
	DebugSetPolicyOverride = "DebugSetPolicyOverride",
	DebugAttemptTrade = "DebugAttemptTrade",
	UnlockZone = "UnlockZone",
	BuyRod = "BuyRod",
	EquipRod = "EquipRod",
	BuyBait = "BuyBait",
}

return RemoteNames