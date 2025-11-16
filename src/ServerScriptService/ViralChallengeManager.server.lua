local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local ChallengeDefinitions = require(ReplicatedStorage:WaitForChild("ChallengeDefinitions"))
local RewardService = require(ServerScriptService:WaitForChild("RewardService"))
local ChallengeArenaController = require(ServerScriptService:WaitForChild("ChallengeArenaController"))

local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local trendingEvent = remotesFolder:WaitForChild("TrendingUpdated")
local challengeEvent = remotesFolder:WaitForChild("ChallengeState")

local CURRENT_CHALLENGE = nil
local CURRENT_ARENA = nil
local NEXT_ROTATION = 0
local CHALLENGE_END_TIME = 0
local ACTIVE_UPDATE = false
local characterConnections = {}

local INTERMISSION_DURATION = 20

local function broadcastTrending(challengeName)
    local definition = challengeName and ChallengeDefinitions[challengeName] or nil
    local payload = {
        key = challengeName,
        status = challengeName and "Active" or "Intermission",
    }

    if definition then
        payload.displayName = definition.displayName
        payload.description = definition.description
    else
        payload.displayName = "Intermission"
        payload.description = "Next viral challenge loading..."
    end

    trendingEvent:FireAllClients(payload)
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

local function ensureCharacter(player)
    local character = player.Character
    if not character then
        player:LoadCharacter()
        character = player.Character or player.CharacterAdded:Wait()
    end
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then
        root = character:WaitForChild("HumanoidRootPart")
    end
    return character, root
end

local function getLobbySpawns()
    local lobbyFolder = workspace:FindFirstChild("LobbySpawns")
    local cframes = {}
    if lobbyFolder then
        for _, child in lobbyFolder:GetDescendants() do
            if child:IsA("BasePart") then
                table.insert(cframes, child.CFrame)
            end
        end
    end

    if #cframes == 0 then
        table.insert(cframes, CFrame.new(0, 10, 0))
    end

    return cframes
end

local function teleportPlayerToCFrame(player, cframe)
    local _, root = ensureCharacter(player)
    root.CFrame = cframe + Vector3.new(0, 3, 0)
end

local function teleportPlayers(cframes)
    if #cframes == 0 then
        return
    end

    local players = Players:GetPlayers()
    for index, player in ipairs(players) do
        local spawnCFrame = cframes[((index - 1) % #cframes) + 1]
        teleportPlayerToCFrame(player, spawnCFrame)
    end
end

local function updateChallengeState(stateTable)
    challengeEvent:FireAllClients(stateTable)
end

local function sendResults(challengeName, definition, finishers)
    local payload = {
        status = "Results",
        challenge = challengeName,
        displayName = definition.displayName,
        finishers = {},
    }

    for placement, entry in ipairs(finishers) do
        table.insert(payload.finishers, {
            placement = placement,
            playerName = entry.player.DisplayName,
            finishTime = math.floor(entry.finishTime),
        })
    end

    updateChallengeState(payload)
end

local function returnPlayersToLobby()
    teleportPlayers(getLobbySpawns())
end

local function concludeChallenge(challengeName, definition)
    if CURRENT_CHALLENGE ~= challengeName then
        return
    end

    ACTIVE_UPDATE = false

    local finishers, nonFinishers = {}, {}
    if CURRENT_ARENA then
        finishers, nonFinishers = CURRENT_ARENA:getResults()
        CURRENT_ARENA:destroy()
        CURRENT_ARENA = nil
    end

    for placement, entry in ipairs(finishers) do
        local player = entry.player
        if player and player.Parent then
            local streak = RewardService.AdjustStreak(player, true)
            RewardService.AwardPlayer(player, {
                challenge = challengeName,
                definition = definition,
                placement = placement,
                streak = streak,
                didFinish = true,
            })
        end
    end

    for _, player in ipairs(nonFinishers) do
        if player and player.Parent then
            local streak = RewardService.AdjustStreak(player, false)
            RewardService.AwardPlayer(player, {
                challenge = challengeName,
                definition = definition,
                placement = #finishers + 1,
                streak = streak,
                didFinish = false,
            })
        end
    end

    sendResults(challengeName, definition, finishers)
    returnPlayersToLobby()

    CURRENT_CHALLENGE = nil
    CHALLENGE_END_TIME = 0
    NEXT_ROTATION = os.clock() + INTERMISSION_DURATION
    broadcastTrending(nil)
end

local function runCountdown(challengeName, definition)
    while ACTIVE_UPDATE and CURRENT_CHALLENGE == challengeName do
        local remaining = math.max(0, math.ceil(CHALLENGE_END_TIME - os.clock()))
        updateChallengeState({
            status = "Active",
            challenge = challengeName,
            displayName = definition.displayName,
            timeRemaining = remaining,
            instructions = definition.instructions,
        })
        task.wait(1)
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

    CURRENT_ARENA = ChallengeArenaController.new(challengeName, definition)
    CURRENT_ARENA:spawnArena()

    local spawnLocations = CURRENT_ARENA:getSpawnLocations()
    teleportPlayers(spawnLocations)

    for _, player in ipairs(Players:GetPlayers()) do
        CURRENT_ARENA:addParticipant(player)
    end

    ACTIVE_UPDATE = true
    CHALLENGE_END_TIME = os.clock() + definition.duration
    task.delay(definition.duration, function()
        concludeChallenge(challengeName, definition)
    end)

    task.spawn(runCountdown, challengeName, definition)
end

local function runScheduler()
    if CURRENT_CHALLENGE == nil and os.clock() >= NEXT_ROTATION then
        local challengeName = selectChallenge()
        if challengeName then
            startChallenge(challengeName)
        end
    end
end

Players.PlayerAdded:Connect(function(player)
    if characterConnections[player] then
        characterConnections[player]:Disconnect()
    end

    characterConnections[player] = player.CharacterAdded:Connect(function()
        task.defer(function()
            local arena = CURRENT_ARENA
            if CURRENT_CHALLENGE and arena then
                local spawns = arena:getSpawnLocations()
                if #spawns > 0 then
                    local spawn = spawns[((player.UserId % #spawns) + 1)]
                    teleportPlayerToCFrame(player, spawn)
                    return
                end
            end

            local lobbySpawns = getLobbySpawns()
            teleportPlayerToCFrame(player, lobbySpawns[1])
        end)
    end)

    if CURRENT_ARENA then
        CURRENT_ARENA:addParticipant(player)
    end
    if CURRENT_CHALLENGE then
        broadcastTrending(CURRENT_CHALLENGE)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    if characterConnections[player] then
        characterConnections[player]:Disconnect()
        characterConnections[player] = nil
    end

    if CURRENT_ARENA then
        CURRENT_ARENA:removeParticipant(player)
    end
end)

NEXT_ROTATION = os.clock() + INTERMISSION_DURATION
broadcastTrending(nil)
RunService.Heartbeat:Connect(runScheduler)
