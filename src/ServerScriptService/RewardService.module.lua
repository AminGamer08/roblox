local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local rewardEvent = remotesFolder:WaitForChild("RewardGranted")

local RewardService = {}
RewardService.__index = RewardService

local profileStore = DataStoreService:GetDataStore("TrendSurgeProfiles")
local playerProfiles = {}
local playerStreaks = {}

local function createLeaderstats(player, profile)
    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then
        leaderstats = Instance.new("Folder")
        leaderstats.Name = "leaderstats"
        leaderstats.Parent = player
    end

    local function getOrCreateValue(name)
        local value = leaderstats:FindFirstChild(name)
        if not value then
            value = Instance.new("IntValue")
            value.Name = name
            value.Parent = leaderstats
        end
        return value
    end

    getOrCreateValue("Clout").Value = profile.Clout
    getOrCreateValue("Followers").Value = profile.Followers
end

local function loadProfile(player)
    local success, data = pcall(function()
        return profileStore:GetAsync(player.UserId)
    end)

    if success and data then
        playerProfiles[player] = data
    else
        playerProfiles[player] = {
            Clout = 0,
            Followers = 0,
            LifetimeChallenges = 0,
        }
    end

    playerStreaks[player] = playerStreaks[player] or 0
    createLeaderstats(player, playerProfiles[player])
end

local function saveProfile(player)
    local profile = playerProfiles[player]
    if not profile then
        return
    end

    pcall(function()
        profileStore:SetAsync(player.UserId, profile)
    end)
end

function RewardService.AdjustStreak(player, didFinish)
    if didFinish then
        playerStreaks[player] = (playerStreaks[player] or 0) + 1
    else
        playerStreaks[player] = 0
    end
    return playerStreaks[player]
end

function RewardService.GetStreak(player)
    return playerStreaks[player] or 0
end

local function calculateRewards(result)
    local definition = result.definition
    if not definition then
        return 0, 0
    end

    local base = result.didFinish and 25 or 10
    local placementBonus = 0
    if result.didFinish then
        placementBonus = math.max(0, (10 - (result.placement or 10))) * 5
    end
    local streakMultiplier = 1 + (result.streak or 0) * 0.05
    local difficultyMultiplier = definition.difficulty or 1
    local rewardMultiplier = definition.rewardMultiplier or 1

    local clout = math.floor((base + placementBonus) * streakMultiplier * rewardMultiplier)
    local followers = math.floor(clout * 0.2 * difficultyMultiplier)

    return clout, followers
end

function RewardService.AwardPlayer(player, result)
    local profile = playerProfiles[player]
    if not profile then
        return
    end

    local clout, followers = calculateRewards(result)
    profile.Clout += clout
    profile.Followers += followers
    profile.LifetimeChallenges += 1

    local leaderstats = player:FindFirstChild("leaderstats")
    if leaderstats then
        local cloutValue = leaderstats:FindFirstChild("Clout")
        local followersValue = leaderstats:FindFirstChild("Followers")
        if cloutValue then
            cloutValue.Value = profile.Clout
        end
        if followersValue then
            followersValue.Value = profile.Followers
        end
    end

    rewardEvent:FireClient(player, {
        clout = clout,
        followers = followers,
        totals = {
            clout = profile.Clout,
            followers = profile.Followers,
        },
    })
end

function RewardService.ClearPlayer(player)
    saveProfile(player)
    playerProfiles[player] = nil
    playerStreaks[player] = nil
end

function RewardService.Init()
    Players.PlayerAdded:Connect(loadProfile)
    Players.PlayerRemoving:Connect(function(player)
        RewardService.ClearPlayer(player)
    end)

    for _, player in ipairs(Players:GetPlayers()) do
        task.spawn(loadProfile, player)
    end

    game:BindToClose(function()
        for player, _ in pairs(playerProfiles) do
            saveProfile(player)
        end
    end)
end

return RewardService
