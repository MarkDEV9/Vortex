local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local USER_FILE = "server-hop-temp_" .. LocalPlayer.UserId .. ".json"

local AllIDs = {}
local cursor = nil

local function loadData()
    local actualHour = os.date("!*t").hour
    local success, content = pcall(function() return readfile(USER_FILE) end)
    if success then
        AllIDs = HttpService:JSONDecode(content)
    end

    if not AllIDs or AllIDs.hour ~= actualHour then
        AllIDs = {
            hour = actualHour,
            servers = {}
        }
        pcall(function() writefile(USER_FILE, HttpService:JSONEncode(AllIDs)) end)
    end
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
    while true do
        loadData()
        local servers = getServers(placeId)
        
        if servers then
            for _, server in ipairs(servers) do
                if server.playing < server.maxPlayers and server.id ~= game.JobId then
                    if not table.find(AllIDs.servers, server.id) then
                        table.insert(AllIDs.servers, server.id)
                        save()

                        pcall(function()
                            TeleportService:TeleportToPlaceInstance(placeId, server.id, LocalPlayer)
                        end)
                        task.wait(1)
                    end
                end
            end
        end

        if not cursor then
            task.wait(2)
        end
        task.wait(0.1)
    end
end

local module = {}

function module:Teleport(placeId)
    task.spawn(function()
        hop(placeId)
    end)
end

return module
