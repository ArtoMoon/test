local Config = {}

Config.TrashValues = {
    PlasticBottle = 1,
    Can = 2,
    Cardboard = 3,
    TrashBag = 5,
    ElectronicWaste = 10,
    Laptop = 20,
    Phone = 15,
}

Config.BagUpgrades = {
    { Name = "Kucuk Canta", Capacity = 10, Cost = 0 },
    { Name = "Buyuk Canta", Capacity = 25, Cost = 150 },
    { Name = "Dev Canta", Capacity = 50, Cost = 500 },
    { Name = "Ultra Canta", Capacity = 100, Cost = 1500 },
}

Config.VehicleUpgrades = {
    { Name = "Yuru", WalkSpeed = 16, Cost = 0 },
    { Name = "Scooter", WalkSpeed = 20, Cost = 250 },
    { Name = "Bisiklet", WalkSpeed = 24, Cost = 600 },
    { Name = "Motor", WalkSpeed = 28, Cost = 1200 },
    { Name = "Cop Arabasi", WalkSpeed = 34, Cost = 3000 },
}

Config.PetOptions = {
    None = { Name = "Petsiz", Cost = 0, MoneyMultiplier = 1.0, SpeedMultiplier = 1.0 },
    BasicPet = { Name = "Basic Pet", Cost = 800, MoneyMultiplier = 1.10, SpeedMultiplier = 1.05 },
}

Config.TrashRespawnSeconds = 35

Config.GoldenBag = {
    Reward = 100,
    SpawnIntervalSeconds = 180,
    DurationSeconds = 30,
}

return Config
