local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")

local FILE_NAME = "server-hop-" .. LocalPlayer.UserId .. ".json"

local AllIDs = {}
local foundAnything = nil
local actualHour = os.date("!*t").hour

pcall(function()
	AllIDs = HttpService:JSONDecode(readfile(FILE_NAME))
end)

if AllIDs[1] ~= actualHour then
	AllIDs = {actualHour}
	pcall(function()
		writefile(FILE_NAME, HttpService:JSONEncode(AllIDs))
	end)
end

local function save()
	pcall(function()
		writefile(FILE_NAME, HttpService:JSONEncode(AllIDs))
	end)
end

local function TPReturner(placeId)
	local url = "https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?sortOrder=Asc&limit=100"
	if foundAnything then
		url = url .. "&cursor=" .. foundAnything
	end

	local Site = HttpService:JSONDecode(game:HttpGet(url))
	foundAnything = Site.nextPageCursor

	for _, v in pairs(Site.data) do
		if v.playing < v.maxPlayers then
			local id = tostring(v.id)

			if not table.find(AllIDs, id) then
				table.insert(AllIDs, id)
				save()
				TeleportService:TeleportToPlaceInstance(placeId, id, LocalPlayer)
				return true
			end
		end
	end

	return false
end

local module = {}

function module:Teleport(placeId)
	while task.wait(1) do
		pcall(function()
			local success = TPReturner(placeId)

			if not success and not foundAnything then
				foundAnything = nil
			end
		end)
	end
end

return module
