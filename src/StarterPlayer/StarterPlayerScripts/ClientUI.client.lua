local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local trendingEvent = remotesFolder:WaitForChild("TrendingUpdated")
local challengeEvent = remotesFolder:WaitForChild("ChallengeState")
local rewardEvent = remotesFolder:WaitForChild("RewardGranted")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "TrendSurgeUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local trendingFrame = Instance.new("Frame")
trendingFrame.Name = "TrendingFrame"
trendingFrame.Size = UDim2.new(0, 300, 0, 120)
trendingFrame.Position = UDim2.new(0, 20, 0, 20)
trendingFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
trendingFrame.BackgroundTransparency = 0.2
trendingFrame.Parent = screenGui

local trendingTitle = Instance.new("TextLabel")
trendingTitle.Size = UDim2.new(1, -20, 0, 30)
trendingTitle.Position = UDim2.new(0, 10, 0, 10)
trendingTitle.Text = "Trending Challenge"
trendingTitle.Font = Enum.Font.GothamBold
trendingTitle.TextSize = 22
trendingTitle.TextColor3 = Color3.new(1, 1, 1)
trendingTitle.BackgroundTransparency = 1
trendingTitle.Parent = trendingFrame

local trendingBody = Instance.new("TextLabel")
trendingBody.Size = UDim2.new(1, -20, 0, 60)
trendingBody.Position = UDim2.new(0, 10, 0, 45)
trendingBody.TextWrapped = true
trendingBody.Font = Enum.Font.Gotham
trendingBody.TextSize = 18
trendingBody.TextColor3 = Color3.new(0.9, 0.9, 0.9)
trendingBody.BackgroundTransparency = 1
trendingBody.Text = "Waiting for rotation..."
trendingBody.Parent = trendingFrame

local rewardFrame = Instance.new("Frame")
rewardFrame.Name = "RewardFrame"
rewardFrame.Size = UDim2.new(0, 280, 0, 100)
rewardFrame.Position = UDim2.new(1, -300, 0, 30)
rewardFrame.BackgroundColor3 = Color3.fromRGB(30, 10, 60)
rewardFrame.BackgroundTransparency = 0.3
rewardFrame.Visible = false
rewardFrame.Parent = screenGui

local rewardLabel = Instance.new("TextLabel")
rewardLabel.Size = UDim2.new(1, -20, 1, -20)
rewardLabel.Position = UDim2.new(0, 10, 0, 10)
rewardLabel.TextWrapped = true
rewardLabel.Font = Enum.Font.GothamSemibold
rewardLabel.TextSize = 20
rewardLabel.TextColor3 = Color3.fromRGB(255, 223, 125)
rewardLabel.BackgroundTransparency = 1
rewardLabel.Parent = rewardFrame

local activeChallengeInstructions = {}

local function updateTrendingUI(challengeName)
    if not challengeName then
        trendingBody.Text = "New rotation starting soon..."
        return
    end

    local definition = require(ReplicatedStorage.ChallengeDefinitions)[challengeName]
    if not definition then
        trendingBody.Text = "Unknown challenge"
        return
    end

    trendingBody.Text = string.format("%s\n%s", definition.displayName, definition.description)
end

local function updateChallengeState(state)
    if state.status == "Active" then
        activeChallengeInstructions = state.instructions or {}
        trendingBody.Text = string.format("%s\n%ss remaining", state.challenge, state.duration)
    elseif state.status == "Results" then
        trendingBody.Text = string.format("%s results incoming...", state.challenge)
    end
end

local function presentReward(data)
    rewardFrame.Visible = true
    rewardLabel.Text = string.format(
        "+%d Clout\n+%d Followers\nTotals: %d Clout / %d Followers",
        data.clout,
        data.followers,
        data.totals.clout,
        data.totals.followers
    )

    task.delay(5, function()
        rewardFrame.Visible = false
    end)
end

trendingEvent.OnClientEvent:Connect(updateTrendingUI)
challengeEvent.OnClientEvent:Connect(updateChallengeState)
rewardEvent.OnClientEvent:Connect(presentReward)

-- Tooltip instructions when players press H
local UserInputService = game:GetService("UserInputService")

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then
        return
    end
    if input.KeyCode == Enum.KeyCode.H then
        if #activeChallengeInstructions > 0 then
            trendingBody.Text = table.concat(activeChallengeInstructions, "\n")
        else
            trendingBody.Text = "Stay tuned for the next viral challenge!"
        end
    end
end)
