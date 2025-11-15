local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ChallengeDefinitions = require(ReplicatedStorage:WaitForChild("ChallengeDefinitions"))
local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local rewardEvent = remotesFolder:FindFirstChild("RewardGranted")

local playerProfiles = {}
local profileStore = DataStoreService:GetDataStore("TrendSurgeProfiles")

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
end

local function saveProfile(player)
    local profile = playerProfiles[player]
    if not profile then
        return
    end

    local success, err = pcall(function()
        profileStore:SetAsync(player.UserId, profile)
    end)

    if not success then
        warn("Failed to save profile for", player, err)
    end
end

local function calculateRewards(result)
    local definition = ChallengeDefinitions[result.challenge]
    if not definition then
        return 0, 0
    end

    local base = 25
    local placementBonus = math.max(0, (10 - (result.placement or 10))) * 5
    local streakMultiplier = 1 + (result.streak or 0) * 0.05
    local difficultyMultiplier = definition.difficulty or 1
    local rewardMultiplier = definition.rewardMultiplier or 1

    local clout = math.floor((base + placementBonus) * streakMultiplier * rewardMultiplier)
    local followers = math.floor(clout * 0.2 * difficultyMultiplier)

    return clout, followers
end

local function awardPlayer(player, result)
    local profile = playerProfiles[player]
    if not profile then
        return
    end

    local clout, followers = calculateRewards(result)
    profile.Clout += clout
    profile.Followers += followers
    profile.LifetimeChallenges += 1

    if rewardEvent then
        rewardEvent:FireClient(player, {
            clout = clout,
            followers = followers,
            totals = {
                clout = profile.Clout,
                followers = profile.Followers,
            },
        })
    end
end

Players.PlayerAdded:Connect(loadProfile)
Players.PlayerRemoving:Connect(function(player)
    saveProfile(player)
    playerProfiles[player] = nil
end)

return {
    AwardPlayer = awardPlayer,
    SaveProfile = saveProfile,
}
