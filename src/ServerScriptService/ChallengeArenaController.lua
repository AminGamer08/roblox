local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

local ArenaController = {}
ArenaController.__index = ArenaController

local function getOrCreateFolder(parent, name)
    local folder = parent:FindFirstChild(name)
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = name
        folder.Parent = parent
    end
    return folder
end

function ArenaController.new(challengeKey, definition)
    local self = setmetatable({}, ArenaController)
    self.challengeKey = challengeKey
    self.definition = definition
    self.template = nil
    self.arenaModel = nil
    self.connections = {}
    self.startTime = 0
    self.completions = {}
    self.participants = {}
    return self
end

function ArenaController:loadTemplate()
    if self.template then
        return self.template
    end

    local arenasFolder = ServerStorage:FindFirstChild("Arenas")
    if not arenasFolder then
        error("ServerStorage.Arenas folder is missing. Import the arena models before starting the server.")
    end

    local modelName = self.definition.arenaModelName or self.challengeKey
    local model = arenasFolder:FindFirstChild(modelName)
    if not model then
        error(string.format("Missing arena model '%s' inside ServerStorage.Arenas", modelName))
    end

    self.template = model
    return self.template
end

function ArenaController:spawnArena()
    local template = self:loadTemplate()
    self.arenaModel = template:Clone()
    self.arenaModel.Name = string.format("%sArena", self.challengeKey)

    local workspaceFolder = getOrCreateFolder(workspace, "ActiveArenas")
    self.arenaModel.Parent = workspaceFolder

    self.startTime = os.clock()
    self:registerParticipants()
    self:wireGoals()
    self:wireHazards()
end

function ArenaController:getSpawnLocations()
    if not self.arenaModel then
        return {}
    end

    local folderName = self.definition.spawnFolderName or "Spawns"
    local spawnFolder = self.arenaModel:FindFirstChild(folderName)
    local spawns = {}
    if spawnFolder then
        for _, child in spawnFolder:GetDescendants() do
            if child:IsA("BasePart") then
                table.insert(spawns, child.CFrame)
            end
        end
    end
    return spawns
end

function ArenaController:registerParticipants()
    for _, player in ipairs(Players:GetPlayers()) do
        self:addParticipant(player)
    end
end

function ArenaController:addParticipant(player)
    self.participants[player] = {
        finished = false,
        finishTime = nil,
    }
end

function ArenaController:removeParticipant(player)
    self.participants[player] = nil
end

function ArenaController:handleFinish(player)
    local participant = self.participants[player]
    if not participant or participant.finished then
        return
    end

    participant.finished = true
    participant.finishTime = os.clock() - self.startTime
    self.completions[player] = participant.finishTime
end

function ArenaController:wireGoals()
    local folderName = self.definition.goalFolderName or "GoalPads"
    local goalFolder = self.arenaModel:FindFirstChild(folderName)
    if not goalFolder then
        return
    end

    for _, descendant in goalFolder:GetDescendants() do
        if descendant:IsA("BasePart") then
            table.insert(self.connections, descendant.Touched:Connect(function(hit)
                local character = hit.Parent
                if not character then
                    return
                end
                local player = Players:GetPlayerFromCharacter(character)
                if not player then
                    return
                end
                self:handleFinish(player)
            end))
        end
    end
end

function ArenaController:wireHazards()
    local folderName = self.definition.hazardFolderName or "Hazards"
    local hazardFolder = self.arenaModel:FindFirstChild(folderName)
    if not hazardFolder then
        return
    end

    for _, descendant in hazardFolder:GetDescendants() do
        if descendant:IsA("BasePart") then
            table.insert(self.connections, descendant.Touched:Connect(function(hit)
                local character = hit.Parent
                if not character then
                    return
                end
                local humanoid = character:FindFirstChildWhichIsA("Humanoid")
                if humanoid then
                    humanoid.Health = 0
                end
            end))
        end
    end
end

function ArenaController:getResults()
    local ordered = {}
    for player, finishTime in pairs(self.completions) do
        table.insert(ordered, {player = player, finishTime = finishTime})
    end
    table.sort(ordered, function(a, b)
        return a.finishTime < b.finishTime
    end)

    local finishers = {}
    for placement, data in ipairs(ordered) do
        finishers[placement] = {
            player = data.player,
            finishTime = data.finishTime,
        }
    end

    local nonFinishers = {}
    for player, info in pairs(self.participants) do
        if not info.finished and player and player.Parent then
            table.insert(nonFinishers, player)
        end
    end

    return finishers, nonFinishers
end

function ArenaController:destroy()
    for _, connection in ipairs(self.connections) do
        connection:Disconnect()
    end
    self.connections = {}

    if self.arenaModel then
        self.arenaModel:Destroy()
        self.arenaModel = nil
    end
end

return ArenaController
