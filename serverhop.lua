local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local USER_FILE = "server-hop-temp_" .. LocalPlayer.UserId .. ".json"

local AllIDs = {}
local cursor = nil
local actualHour = os.date("!*t").hour

pcall(function()
	AllIDs = HttpService:JSONDecode(readfile(USER_FILE))
end)

if not AllIDs or AllIDs.hour ~= actualHour then
	AllIDs = {
		hour = actualHour,
		servers = {}
	}
	pcall(function()
		writefile(USER_FILE, HttpService:JSONEncode(AllIDs))
	end)
end

local function save()
	pcall(function()
		writefile(USER_FILE, HttpService:JSONEncode(AllIDs))
	end)
end

local function getServers(placeId)
	local url = "https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?limit=100&sortOrder=Asc"
	if cursor then
		url = url .. "&cursor=" .. cursor
	end

	local success, response = pcall(function()
		return HttpService:JSONDecode(game:HttpGet(url))
	end)

	if not success or not response then
		return nil
	end

	cursor = response.nextPageCursor
	return response.data
end

local function hop(placeId)
	while task.wait(2) do
		local servers = getServers(placeId)
		if not servers then continue end

		for _, server in ipairs(servers) do
			if server.playing < server.maxPlayers then
				if not table.find(AllIDs.servers, server.id) then
					table.insert(AllIDs.servers, server.id)
					save()

					pcall(function()
						TeleportService:TeleportToPlaceInstance(
							placeId,
							server.id,
							LocalPlayer
						)
					end)

					task.wait(5)
				end
			end
		end

		if not cursor then
			task.wait(3)
		end
	end
end

local module = {}

function module:Teleport(placeId)
	task.spawn(function()
		hop(placeId)
	end)
end

return module
