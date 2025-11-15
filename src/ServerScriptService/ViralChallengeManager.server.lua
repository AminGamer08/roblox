local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")

local ChallengeDefinitions = require(ReplicatedStorage:WaitForChild("ChallengeDefinitions"))

local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local trendingEvent = remotesFolder:FindFirstChild("TrendingUpdated")
local challengeEvent = remotesFolder:FindFirstChild("ChallengeState")

local ACTIVE_PLAYERS = {}
local CURRENT_CHALLENGE = nil
local NEXT_ROTATION = 0
local ROTATION_INTERVAL = 90

local function broadcastTrending(challengeName)
    if trendingEvent then
        trendingEvent:FireAllClients(challengeName)
    end
end

local function buildWeightedChallengeList()
    local weightedList = {}
    for key, definition in pairs(ChallengeDefinitions) do
        local baseWeight = definition.difficulty > 1 and 1 / definition.difficulty or 1
        local rewardWeight = definition.rewardMultiplier or 1
        local weight = baseWeight * rewardWeight
        table.insert(weightedList, {name = key, weight = weight})
    end
    return weightedList
end

local function selectChallenge()
    local weightedList = buildWeightedChallengeList()
    local totalWeight = 0
    for _, entry in ipairs(weightedList) do
        totalWeight += entry.weight
    end

    local randomValue = math.random() * totalWeight
    local accumulator = 0
    for _, entry in ipairs(weightedList) do
        accumulator += entry.weight
        if randomValue <= accumulator then
            return entry.name
        end
    end

    return weightedList[1] and weightedList[1].name or nil
end

local function teleportPlayersToChallenge(arenaAssetId)
    for player in pairs(ACTIVE_PLAYERS) do
        -- In Studio, replace with actual teleport logic to challenge instance.
        player:LoadCharacter()
    end
end

local function updateChallengeState(stateTable)
    if challengeEvent then
        challengeEvent:FireAllClients(stateTable)
    end
end

local function startChallenge(challengeName)
    local definition = ChallengeDefinitions[challengeName]
    if not definition then
        warn("Missing challenge definition for", challengeName)
        return
    end

    CURRENT_CHALLENGE = challengeName
    broadcastTrending(challengeName)

    teleportPlayersToChallenge(definition.arenaAssetId)
    updateChallengeState({
        status = "Active",
        challenge = challengeName,
        duration = definition.duration,
        endsAt = os.time() + definition.duration,
        instructions = definition.instructions,
    })

    task.delay(definition.duration, function()
        updateChallengeState({
            status = "Results",
            challenge = challengeName,
        })
        CURRENT_CHALLENGE = nil
    end)
end

local function queueNextRotation()
    NEXT_ROTATION = os.clock() + ROTATION_INTERVAL
end

local function runScheduler()
    if CURRENT_CHALLENGE == nil and os.clock() >= NEXT_ROTATION then
        local challengeName = selectChallenge()
        if challengeName then
            startChallenge(challengeName)
        end
        queueNextRotation()
    end
end

Players.PlayerAdded:Connect(function(player)
    ACTIVE_PLAYERS[player] = true
    if CURRENT_CHALLENGE then
        broadcastTrending(CURRENT_CHALLENGE)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    ACTIVE_PLAYERS[player] = nil
end)

queueNextRotation()

RunService.Heartbeat:Connect(runScheduler)
