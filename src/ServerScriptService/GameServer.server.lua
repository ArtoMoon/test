local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Config"))

local playerData = {}

local function getMaxCapacity(level)
    local upgrade = Config.BagUpgrades[level]
    return upgrade and upgrade.Capacity or Config.BagUpgrades[1].Capacity
end

local function getCurrentVehicle(level)
    return Config.VehicleUpgrades[level] or Config.VehicleUpgrades[1]
end

local function getMoneyStat(player)
    local stats = player:FindFirstChild("leaderstats")
    return stats and stats:FindFirstChild("Money")
end

local function updatePlayerAttributes(player)
    local state = playerData[player]
    if not state then
        return
    end

    player:SetAttribute("BagLevel", state.BagLevel)
    player:SetAttribute("BagCapacity", getMaxCapacity(state.BagLevel))
    player:SetAttribute("InventoryCount", state.InventoryCount)
    player:SetAttribute("InventoryValue", state.InventoryValue)
    player:SetAttribute("VehicleLevel", state.VehicleLevel)
    player:SetAttribute("VehicleName", getCurrentVehicle(state.VehicleLevel).Name)
    player:SetAttribute("Pet", state.Pet)
end

local function applyMovementSpeed(player)
    local state = playerData[player]
    if not state then
        return
    end

    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        return
    end

    local vehicleSpeed = getCurrentVehicle(state.VehicleLevel).WalkSpeed
    local pet = Config.PetOptions[state.Pet] or Config.PetOptions.None
    humanoid.WalkSpeed = math.floor(vehicleSpeed * pet.SpeedMultiplier)
end

local function setupLeaderstats(player)
    local leaderstats = Instance.new("Folder")
    leaderstats.Name = "leaderstats"
    leaderstats.Parent = player

    local money = Instance.new("IntValue")
    money.Name = "Money"
    money.Parent = leaderstats

    local totalCollected = Instance.new("IntValue")
    totalCollected.Name = "TotalTrash"
    totalCollected.Parent = leaderstats
end

local function setupPlayerState(player)
    playerData[player] = {
        BagLevel = 1,
        VehicleLevel = 1,
        InventoryCount = 0,
        InventoryValue = 0,
        Pet = "None",
    }

    setupLeaderstats(player)
    updatePlayerAttributes(player)

    player.CharacterAdded:Connect(function()
        task.wait(0.1)
        applyMovementSpeed(player)
    end)
end

local function collectTrash(player, trashType)
    local state = playerData[player]
    if not state then
        return false, "No state"
    end

    local maxCapacity = getMaxCapacity(state.BagLevel)
    if state.InventoryCount >= maxCapacity then
        return false, "Bag full"
    end

    local value = Config.TrashValues[trashType]
    if not value then
        return false, "Unknown trash"
    end

    state.InventoryCount += 1
    state.InventoryValue += value

    local stats = player:FindFirstChild("leaderstats")
    if stats then
        local totalTrash = stats:FindFirstChild("TotalTrash")
        if totalTrash then
            totalTrash.Value += 1
        end
    end

    updatePlayerAttributes(player)
    return true
end

local function sellTrash(player)
    local state = playerData[player]
    if not state or state.InventoryCount == 0 then
        return false, 0
    end

    local pet = Config.PetOptions[state.Pet] or Config.PetOptions.None
    local payout = math.floor(state.InventoryValue * pet.MoneyMultiplier)

    local money = getMoneyStat(player)
    if money then
        money.Value += payout
    end

    state.InventoryCount = 0
    state.InventoryValue = 0
    updatePlayerAttributes(player)

    return true, payout
end

local function buyNextBagUpgrade(player)
    local state = playerData[player]
    if not state then
        return false, "No state"
    end

    local nextLevel = state.BagLevel + 1
    local nextUpgrade = Config.BagUpgrades[nextLevel]
    if not nextUpgrade then
        return false, "Max bag"
    end

    local money = getMoneyStat(player)
    if not money or money.Value < nextUpgrade.Cost then
        return false, "Not enough money"
    end

    money.Value -= nextUpgrade.Cost
    state.BagLevel = nextLevel
    updatePlayerAttributes(player)

    return true
end

local function buyNextVehicleUpgrade(player)
    local state = playerData[player]
    if not state then
        return false, "No state"
    end

    local nextLevel = state.VehicleLevel + 1
    local nextUpgrade = Config.VehicleUpgrades[nextLevel]
    if not nextUpgrade then
        return false, "Max vehicle"
    end

    local money = getMoneyStat(player)
    if not money or money.Value < nextUpgrade.Cost then
        return false, "Not enough money"
    end

    money.Value -= nextUpgrade.Cost
    state.VehicleLevel = nextLevel
    updatePlayerAttributes(player)
    applyMovementSpeed(player)

    return true
end

local function buyPet(player, petKey)
    local state = playerData[player]
    local pet = Config.PetOptions[petKey]
    if not state then
        return false, "No state"
    end
    if not pet then
        return false, "Pet not found"
    end
    if state.Pet == petKey then
        return false, "Already owned"
    end

    local money = getMoneyStat(player)
    if not money or money.Value < pet.Cost then
        return false, "Not enough money"
    end

    money.Value -= pet.Cost
    state.Pet = petKey
    updatePlayerAttributes(player)
    applyMovementSpeed(player)

    return true
end

local function scheduleTrashRespawn(originalPart)
    if not originalPart then
        return
    end

    local modelTemplate = originalPart:Clone()
    modelTemplate.Parent = nil

    task.delay(Config.TrashRespawnSeconds, function()
        if modelTemplate then
            modelTemplate.Parent = Workspace
            CollectionService:AddTag(modelTemplate, "Trash")
        end
    end)
end

local function hookSingleTrashPart(part)
    local prompt = part:FindFirstChildOfClass("ProximityPrompt")
    if not prompt or prompt:GetAttribute("Hooked") then
        return
    end

    prompt:SetAttribute("Hooked", true)
    prompt.Triggered:Connect(function(player)
        local trashType = part:GetAttribute("TrashType") or "PlasticBottle"
        local success = select(1, collectTrash(player, trashType))
        if success and part.Parent then
            scheduleTrashRespawn(part)
            part:Destroy()
        end
    end)
end

local function hookTrashPrompts()
    for _, part in ipairs(CollectionService:GetTagged("Trash")) do
        hookSingleTrashPart(part)
    end

    CollectionService:GetInstanceAddedSignal("Trash"):Connect(function(part)
        hookSingleTrashPart(part)
    end)
end

local function connectPrompt(partName, callback)
    local part = Workspace:FindFirstChild(partName)
    if not part then
        warn(partName .. " not found in Workspace")
        return
    end

    local prompt = part:FindFirstChildOfClass("ProximityPrompt")
    if not prompt then
        warn(partName .. " requires ProximityPrompt")
        return
    end

    prompt.Triggered:Connect(callback)
end

local function hookMainPrompts()
    connectPrompt("SellPoint", function(player)
        sellTrash(player)
    end)

    connectPrompt("BagUpgradePoint", function(player)
        buyNextBagUpgrade(player)
    end)

    connectPrompt("VehicleUpgradePoint", function(player)
        buyNextVehicleUpgrade(player)
    end)

    connectPrompt("PetShopPoint", function(player)
        buyPet(player, "BasicPet")
    end)
end

local function spawnGoldenBag()
    local spawnPoint = Workspace:FindFirstChild("GoldenBagSpawn")
    if not spawnPoint then
        warn("GoldenBagSpawn not found in Workspace")
        return
    end

    local existing = Workspace:FindFirstChild("GoldenTrashBag")
    if existing then
        existing:Destroy()
    end

    local bag = Instance.new("Part")
    bag.Name = "GoldenTrashBag"
    bag.Size = Vector3.new(2, 2, 2)
    bag.CFrame = spawnPoint.CFrame + Vector3.new(0, 1, 0)
    bag.Color = Color3.fromRGB(255, 215, 0)
    bag.Material = Enum.Material.Neon
    bag.Anchored = true
    bag.Parent = Workspace

    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText = "Collect Golden Bag"
    prompt.ObjectText = "Golden Trash"
    prompt.Parent = bag

    prompt.Triggered:Connect(function(player)
        local money = getMoneyStat(player)
        if money then
            money.Value += Config.GoldenBag.Reward
        end
        bag:Destroy()
    end)

    task.delay(Config.GoldenBag.DurationSeconds, function()
        if bag.Parent then
            bag:Destroy()
        end
    end)
end

task.spawn(function()
    while true do
        task.wait(Config.GoldenBag.SpawnIntervalSeconds)
        spawnGoldenBag()
    end
end)

Players.PlayerAdded:Connect(setupPlayerState)
Players.PlayerRemoving:Connect(function(player)
    playerData[player] = nil
end)

hookTrashPrompts()
hookMainPrompts()
