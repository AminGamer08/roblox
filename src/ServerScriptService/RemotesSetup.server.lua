local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
if not remotesFolder then
    remotesFolder = Instance.new("Folder")
    remotesFolder.Name = "Remotes"
    remotesFolder.Parent = ReplicatedStorage
end

local remoteClasses = {
    TrendingUpdated = "RemoteEvent",
    ChallengeState = "RemoteEvent",
    RewardGranted = "RemoteEvent",
}

for name, className in pairs(remoteClasses) do
    if not remotesFolder:FindFirstChild(name) then
        local remote = Instance.new(className)
        remote.Name = name
        remote.Parent = remotesFolder
    end
end
