-- Rayfield UI + Full port of GAG logic (Standalone)
-- Paste this into your executor. Requires Rayfield loader available.

-- ====== Rayfield Loader ======
local success, Rayfield = pcall(function()
    return loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
end)
if not success or not Rayfield then
    warn("Failed to load Rayfield. Check Rayfield URL or HTTPGet access.")
    return
end

-- ====== Wait for game & player ======
while not game:IsLoaded() do task.wait() end
local Players = game:GetService("Players")
while not Players.LocalPlayer do task.wait() end
local plr = Players.LocalPlayer

-- ensure character loaded
local function getHRP()
    while not plr.Character do task.wait() end
    return plr.Character:FindFirstChild("HumanoidRootPart") or plr.Character:WaitForChild("HumanoidRootPart",9e9)
end

-- ====== Short aliases & resources ======
local httpService = game:GetService("HttpService")
local rs = game:GetService("ReplicatedStorage")
local rf = game:GetService("ReplicatedFirst")
local gameEvents = rs:WaitForChild("GameEvents")
local modules = rs:WaitForChild("Modules")

-- try-require helper for optional modules
local function tryRequire(mod)
    local ok, res = pcall(function() return require(mod) end)
    if ok then return res end
    return nil
end

-- require known modules (these were used in original GAG)
local dataService = tryRequire(modules:FindFirstChild("DataService")) or {}
local inventoryService = tryRequire(modules:FindFirstChild("InventoryService")) or {}
local seedData = (rs:FindFirstChild("Data") and tryRequire(rs.Data:FindFirstChild("SeedData"))) or {}
local petRegistry = (rs:FindFirstChild("Data") and tryRequire(rs.Data:FindFirstChild("PetRegistry"))) or {}
local MutationHandler = tryRequire(modules:FindFirstChild("MutationHandler")) or nil

-- ====== Utility functions ======
local function round(num,decimals)
    decimals = decimals or 0
    local power = 10^decimals
    return math.round(num*power)/power
end

local function safeCall(fn, ...)
    local ok, res = pcall(fn, ...)
    if not ok then
        warn("[GAG-PORT] error:", res)
    end
    return ok, res
end

-- ====== Ported GAG table (local) ======
local GAG = {}

-- ==== Load wait / finish loading helper (from original) ====
local function loadWaitSequence()
    -- this mirrors the behavior in original to ensure the player data flags are set
    while not plr:GetAttribute("Finished_Loading") do task.wait() end
    while not plr:GetAttribute("DataFullyLoaded") do task.wait() end
    while not plr:GetAttribute("Setup_Finished") do task.wait() end
    -- fire finish loading events as original
    pcall(function() game:GetService("ReplicatedStorage").GameEvents.Finish_Loading:FireServer() end)
    pcall(function() game:GetService("ReplicatedStorage").GameEvents.LoadScreenEvent:FireServer(plr) end)
    while not plr:GetAttribute("Loading_Screen_Finished") do task.wait() end
    task.wait(1)
end

-- if already finished, mimic behavior
if not plr:GetAttribute("Loading_Screen_Finished") then
    spawn(loadWaitSequence)
end

-- ====== Core API wrappers (ported from original GAG) ======
function GAG:BuySeed(seedName)
    gameEvents.BuySeedStock:FireServer(seedName)
end

function GAG:SellFruitInHand()
    gameEvents.Sell_Item:FireServer()
end

function GAG:SellAllFruitsInInventory()
    gameEvents.Sell_Inventory:FireServer()
end

function GAG:PlantSeed(seedName, plantPosition)
    gameEvents.Plant_RE:FireServer(plantPosition, seedName)
end

function GAG:PlantEggInHand(eggPosition)
    local ohString1 = "CreateEgg"
    local ohVector32 = Vector3.new(eggPosition.X,0.13552704453468323,eggPosition.Z)
    gameEvents.PetEggService:FireServer(ohString1, ohVector32)
end

function GAG:ShovelPlant(instance)
    gameEvents.Remove_Item:FireServer(instance)
end

function GAG:BuyEggFromPetEggShop(eggIndex)
    gameEvents.BuyPetEgg:FireServer(eggIndex)
end

function GAG:BuyNightEventShopItem(itemName)
    gameEvents.BuyNightEventShopStock:FireServer(itemName)
end

function GAG:BuyEventShopItem(itemName)
    gameEvents.BuyEventShopStock:FireServer(itemName)
end

function GAG:BuyCosmeticItem(itemName)
    gameEvents.BuyCosmeticItem:FireServer(itemName)
end

function GAG:BuyCosmeticCrate(crateName)
    gameEvents.BuyCosmeticCrate:FireServer(crateName)
end

function GAG:RedeemCode(code)
    gameEvents.ClaimableCodeService:FireServer("ClaimCode", code)
end

function GAG:NightQuestSubmitHeldPlant()
    gameEvents.NightQuestRemoteEvent:FireServer("SubmitHeldPlant")
end

function GAG:NightQuestSubmitAllPlants()
    gameEvents.NightQuestRemoteEvent:FireServer("SubmitAllPlants")
end

function GAG:GivePetInHand(targetPlayer)
    gameEvents.PetGiftingService:FireServer("GivePet", targetPlayer)
end

function GAG:GiftItemInHand(targetPlayer)
    -- attempts to fire proximity prompt on target player's tool/prompt
    local success, err = pcall(function()
        fireproximityprompt(targetPlayer.Character:FindFirstChildWhichIsA("ProximityPrompt", true))
    end)
    if not success then warn("Gift failed:", err) end
end

function GAG:ToggleFavoriteItem(tool)
    gameEvents.Favorite_Item:FireServer(tool)
end

function GAG:RejoinServer()
    local tpService = game:GetService("TeleportService")
    tpService.TeleportInitFailed:Connect(function(player, teleportResult, errorMessage, placeId, teleportOptions)
        tpService:Teleport(game.PlaceId)
    end)
    tpService:Teleport(game.PlaceId)
end

function GAG:FinishLoading()
    pcall(function() game:GetService("ReplicatedStorage").GameEvents.Finish_Loading:FireServer() end)
    pcall(function() game:GetService("ReplicatedStorage").GameEvents.LoadScreenEvent:FireServer(plr) end)
end

-- ====== Inventory / Data helpers (ported) ======
function GAG:GetInventory()
    local items = {}
    local ok, data = pcall(function() return dataService:GetData() end)
    if not ok or not data or not data.InventoryData then
        return items
    end
    for uuid, itemTable in pairs(data.InventoryData) do
        local inventoryItem = itemTable
        inventoryItem.UUID = uuid
        table.insert(items, inventoryItem)
    end
    return items
end

function GAG:IsInventoryFull()
    if inventoryService and inventoryService.IsMaxInventory then
        local ok, res = pcall(function() return inventoryService:IsMaxInventory() end)
        if ok then return res end
    end
    return false
end

function GAG:GetSeedShopStock()
    local ok, data = pcall(function() return dataService:GetData() end)
    if not ok or not data or not data.SeedStock then return {} end
    return data.SeedStock.Stocks
end

function GAG:GetPetEggsStock()
    local ok, data = pcall(function() return dataService:GetData() end)
    if not ok or not data or not data.PetEggStock then return {} end
    local eggs = {}
    for _,eggTable in pairs(data.PetEggStock.Stocks) do
        table.insert(eggs,{ItemName = eggTable.EggName, Stock = eggTable.Stock, MaxStock = nil})
    end
    return eggs
end

function GAG:GetNightEventShopStock()
    local ok, data = pcall(function() return dataService:GetData() end)
    if not ok or not data or not data.NightEventShopStock then return {} end
    local stocks = {}
    for itemName, stock in pairs(data.NightEventShopStock.Stocks) do
        table.insert(stocks,{ItemName=itemName, Stock=stock.Stock, MaxStock=stock.MaxStock})
    end
    return stocks
end

function GAG:GetGearStock()
    local ok, data = pcall(function() return dataService:GetData() end)
    if not ok or not data or not data.GearStock then return {} end
    local stocks = {}
    for itemName, stock in pairs(data.GearStock.Stocks) do
        table.insert(stocks,{ItemName=itemName, Stock=stock.Stock, MaxStock=stock.MaxStock})
    end
    return stocks
end

function GAG:GetCosmeticStock()
    local ok, data = pcall(function() return dataService:GetData() end)
    if not ok or not data or not data.CosmeticStock then return {CrateStocks={}, ItemStocks={}} end
    local CrateStocks, ItemStocks = {}, {}
    for stocksObjectName, stockObjects in pairs(data.CosmeticStock) do
        if stocksObjectName == "CrateStocks" then
            for i,v in ipairs(stockObjects) do
                v.ItemName = v.CrateName
                table.insert(CrateStocks,v)
            end
        elseif stocksObjectName == "ItemStocks" then
            for i,v in pairs(stockObjects) do
                v.ItemName = i
                table.insert(ItemStocks,v)
            end
        end
    end
    return {CrateStocks = CrateStocks, ItemStocks = ItemStocks}
end

function GAG:GetSavedObjects()
    local objects = {}
    local ok, data = pcall(function() return dataService:GetData() end)
    if not ok or not data or not data.SavedObjects then return objects end
    for uuid, objectTable in pairs(data.SavedObjects) do
        local object = objectTable
        object.UUID = uuid
        table.insert(objects, object)
    end
    return objects
end

-- Pet inventory helpers (ported)
function GAG:GetPetUUIDsInInventory()
    local uuids = {}
    local ok, data = pcall(function() return dataService:GetData() end)
    if not ok or not data or not data.PetsData or not data.PetsData.PetInventory then return uuids end
    for uuid,_ in pairs(data.PetsData.PetInventory.Data) do
        table.insert(uuids, uuid)
    end
    return uuids
end

function GAG:GetPetByUUID(petUUID)
    local ok, data = pcall(function() return dataService:GetData() end)
    if not ok or not data or not data.PetsData or not data.PetsData.PetInventory then return nil end
    local petInventoryItem = data.PetsData.PetInventory.Data[petUUID]
    if not petInventoryItem then return nil end
    petInventoryItem.UUID = petUUID
    setmetatable(petInventoryItem, { __index = {
        EquipPet = function(self, spawnCFrame)
            gameEvents.PetsService:FireServer("EquipPet", self.UUID, spawnCFrame)
        end,
        UnequipPet = function(self)
            gameEvents.PetsService:FireServer("UnequipPet", self.UUID)
        end,
        FeedPetItemFromHand = function(self)
            gameEvents.ActivePetService:FireServer("Feed", self.UUID)
        end
    }})
    return petInventoryItem
end

function GAG:GetPetsInInventory()
    local petItems = {}
    for _, uuid in ipairs(GAG:GetPetUUIDsInInventory()) do
        local p = GAG:GetPetByUUID(uuid)
        if p then table.insert(petItems, p) end
    end
    return petItems
end

function GAG:GetEquippedPetUUIDs()
    local ok, data = pcall(function() return dataService:GetData() end)
    if not ok or not data or not data.PetsData then return {} end
    return data.PetsData.EquippedPets or {}
end

function GAG:GetEquippedPets()
    local pets = {}
    for _, uuid in ipairs(GAG:GetEquippedPetUUIDs()) do
        local p = GAG:GetPetByUUID(uuid)
        if p then table.insert(pets, p) end
    end
    return pets
end

function GAG:GetMaxEquippedPets()
    local ok, data = pcall(function() return dataService:GetData() end)
    if not ok or not data or not data.PetsData then return 0 end
    return data.PetsData.MutableStats.MaxEquippedPets or 0
end

-- Plants & fruits helpers (ported)
do
    -- PlantData class (simplified port from original)
    local PlantData = {}
    PlantData.__index = function(t,key)
        if table.find({"Age","Weight","Item_Seed","Variant"}, key) then
            return t["_"..key] and t["_"..key].Value
        elseif table.find({"MaxAge","FruitSizeMultiplier","FruitVariantLuck","GrowRateMulti","LuckFruitSizeMultiplier","LuckFruitVariantLuck"}, key) then
            return t._instance and t._instance:GetAttribute(key)
        elseif key == "Name" then
            return t._instance and t._instance.Name
        else
            return rawget(PlantData,key) or rawget(t,key)
        end
    end

    function PlantData.new(plantInstance)
        local self = setmetatable({}, PlantData)
        self._instance = plantInstance
        self._Age = plantInstance:FindFirstChild("Grow") and plantInstance.Grow:FindFirstChild("Age") or Instance.new("NumberValue")
        self._Weight = plantInstance:FindFirstChild("Weight") or Instance.new("NumberValue")
        self._Item_Seed = plantInstance:FindFirstChild("Item_Seed") or Instance.new("NumberValue")
        self._Variant = plantInstance:FindFirstChild("Variant") or Instance.new("StringValue")
        return self
    end

    function PlantData:HasGrown()
        return self.Age and self.Age >= (self.MaxAge or 0)
    end

    function PlantData:IsHarvestableWithoutFruit()
        return not self._instance:FindFirstChild("Fruits")
    end

    function PlantData:GetFruitsData()
        local fruits = {}
        if self._instance:FindFirstChild("Fruits") then
            for _, f in ipairs(self._instance.Fruits:GetChildren()) do
                table.insert(fruits, f)
            end
        elseif self:IsHarvestableWithoutFruit() then
            table.insert(fruits, self._instance)
        end
        return fruits
    end

    GAG.PlantDataClass = PlantData
end

function GAG:GetOwnFarmFolder()
    for _, farm in ipairs(workspace.Farm:GetChildren()) do
        local ok, owner = pcall(function() return farm.Important and farm.Important.Data and farm.Important.Data.Owner and farm.Important.Data.Owner.Value end)
        if ok and owner == plr.Name then
            return farm
        end
    end
    return nil
end

function GAG:GetPlantsOnFarm()
    local plants = {}
    local farm = GAG:GetOwnFarmFolder()
    if not farm then return plants end
    local container = farm.Important and farm.Important.Plants_Physical
    if not container then return plants end
    for _, plantInstance in ipairs(container:GetChildren()) do
        local pd = GAG.PlantDataClass.new(plantInstance)
        table.insert(plants, pd)
    end
    return plants
end

function GAG:GetFruitsOnFarm()
    local fruits = {}
    for _, plant in ipairs(GAG:GetPlantsOnFarm()) do
        for _, fruitInstance in ipairs(plant:GetFruitsData()) do
            table.insert(fruits, fruitInstance)
        end
    end
    return fruits
end

function GAG:GetRandomPlantingLocation()
    local farm = GAG:GetOwnFarmFolder()
    if not farm then
        -- fallback random near player
        local hrp = getHRP()
        return hrp.Position + Vector3.new(math.random(-10,10), 0, math.random(-10,10))
    end
    local plantLocations = farm.Important and farm.Important.Plant_Locations
    if not plantLocations then
        local hrp = getHRP()
        return hrp.Position + Vector3.new(math.random(-8,8), 0, math.random(-8,8))
    end
    local plantLocation = plantLocations:GetChildren()[math.random(#plantLocations)]
    local position = plantLocation.Position
    local size = plantLocation.Size
    local randomX = position.X + (math.random() - 0.5) * size.X
    local randomZ = position.Z + (math.random() - 0.5) * size.Z
    return Vector3.new(randomX, 0.13552704453468323, randomZ)
end

function GAG:GetPetEggInstanceByUUID(uuid)
    local farm = GAG:GetOwnFarmFolder()
    if not farm then return nil end
    for _, eggInstance in ipairs(farm.Important.Objects_Physical:GetChildren()) do
        if eggInstance:GetAttribute("OBJECT_TYPE") == "PetEgg" and eggInstance:GetAttribute("OBJECT_UUID") == uuid then
            return eggInstance
        end
    end
    return nil
end

function GAG:HatchEgg(eggInstance)
    gameEvents.PetEggService:FireServer("HatchPet", eggInstance)
end

function GAG:GetSavedPetEggObjects()
    local eggs = {}
    for _, obj in ipairs(GAG:GetSavedObjects()) do
        if obj.ObjectType == "PetEgg" then
            table.insert(eggs, obj)
        end
    end
    return eggs
end

-- Mutations
function GAG:GetAllMutations()
    if MutationHandler then
        local ok, res = pcall(function() return MutationHandler:GetMutations() end)
        if ok and res then return res end
    end
    return {}
end

function GAG:CalculateFruitValueMultiplierFromMutations(fruit)
    local v294 = 1
    if fruit and fruit.MutationString and fruit.MutationString ~= "" then
        for _, mutation in ipairs(GAG:GetAllMutations()) do
            if fruit.MutationString:find(mutation.Name) then
                v294 = v294 + (mutation.ValueMulti - 1)
            end
        end
    end
    return math.max(1, v294)
end

function GAG:GetShecklesCurrency()
    local ok, data = pcall(function() return dataService:GetData() end)
    if not ok or not data then return 0 end
    return data.Sheckles or 0
end

function GAG:GetSpecialCurrency(name)
    local ok, data = pcall(function() return dataService:GetData() end)
    if not ok or not data or not data.SpecialCurrency then return -1 end
    return data.SpecialCurrency[name] or -1
end

function GAG:GetHoneyCurrency()
    return GAG:GetSpecialCurrency("Honey")
end

-- Auto accept pet gifts (re-implemented control)
local autoPetGiftsConnection = nil
function GAG:AutoAcceptPetGifts(enable)
    if enable then
        if autoPetGiftsConnection then return end
        autoPetGiftsConnection = gameEvents.GiftPet.OnClientEvent:Connect(function(uuid, fullPetName, offeringPlayer)
            gameEvents.AcceptPetGift:FireServer(true, uuid)
        end)
    else
        if autoPetGiftsConnection then
            pcall(function() autoPetGiftsConnection:Disconnect() end)
            autoPetGiftsConnection = nil
        end
    end
end

-- Teleport helper (uses LocationCFrames if available)
local LocationCFrames = {
    SellCFrame = CFrame.new(86.5854721, 2.76619363, 0.426784277, 0, 0, -1, 0, 1, 0, 1, 0, 0),
    SeedsShopCFrame = CFrame.new(86.5854721, 2.76619363, -27.0039806, 0, 0, -1, 0, 1, 0, 1, 0, 0),
    GearShopCFrame = CFrame.new(-284.41452, 2.76619363, -32.9778976, 0, 0, 1, 0, 1, -0, -1, 0, 0),
    EventCFrame = CFrame.new(-100.685043, 0.90001297, -11.6456203, 0, 1, 0, 0, 0, 1, 1, 0, 0),
    PetEggShopCFrame = CFrame.new(-285.279419, 2.99999976, -32.4928207, 0.0324875265, -9.37526856e-09, 0.999472141, 1.13912598e-07, 1, 5.67752734e-09, -0.999472141, 1.13668023e-07, 0.0324875265)
}
setmetatable(LocationCFrames, {
    __index = function(t,k)
        if k == "GardenCFrame" then
            local farm = GAG:GetOwnFarmFolder()
            if farm and farm:FindFirstChild("Spawn_Point") then
                return farm.Spawn_Point.CFrame
            end
        end
    end
})

function GAG:TeleportTo(cframe)
    local hrp = getHRP()
    if hrp and cframe then
        hrp.CFrame = cframe
    end
end

function GAG:TeleportToGarden()
    GAG:TeleportTo(LocationCFrames.GardenCFrame or (GAG:GetOwnFarmFolder() and GAG:GetOwnFarmFolder().Spawn_Point.CFrame))
end

function GAG:TeleportToSell()
    GAG:TeleportTo(LocationCFrames.SellCFrame)
end

function GAG:TeleportToSeedsShop()
    GAG:TeleportTo(LocationCFrames.SeedsShopCFrame)
end

function GAG:TeleportToPetEggShop()
    GAG:TeleportTo(LocationCFrames.PetEggShopCFrame)
end

-- ====== Now create the Rayfield UI and hook to this local GAG ======
local Window = Rayfield:CreateWindow({
    Name = "GAG Port - Full UI",
    LoadingTitle = "GAG Ported",
    LoadingSubtitle = "Rayfield UI (Standalone)",
    ConfigurationSaving = { Enabled = true, FolderName = "GAGPort", FileName = "GAGConfig" },
    KeySystem = false
})

-- state for toggles & loops
local state = {
    AutoPlant = false,
    AutoPlantInterval = 1,
    AutoHarvest = false,
    AutoHarvestInterval = 1,
    AutoSell = false,
    AutoSellInterval = 2,
    AutoBuyEggs = false,
    AutoBuyEggInterval = 5,
    AutoHatch = false,
    AutoHatchInterval = 1,
    AutoEquipLoop = false,
    AutoEquipInterval = 5,
    AutoAcceptPetGifts = false,
    ESP_Eggs = false,
    ESP_Pets = false,
    ESP_Plants = false,
}

-- helper to loop safely
local function startLoop(name, interval, fn)
    spawn(function()
        while state[name] do
            safeCall(fn)
            task.wait(interval)
        end
    end)
end

-- ====== Auto loops implementations using ported logic ======
-- AutoPlant: plant random seed from inventory
local function autoPlantStep()
    -- find seed tools in backpack or inventory via dataService fallback
    -- prefer using inventory data if available
    local seedName = nil
    local inv = GAG:GetInventory()
    for _, it in ipairs(inv) do
        local isSeed = false
        -- detect seed by type field heuristics
        if it.ItemType == "Seed" or (it.ItemData and it.ItemData.ItemName and seedData[it.ItemData.ItemName]) then
            isSeed = true
        end
        if isSeed then
            seedName = it.ItemData and it.ItemData.ItemName or it.ItemName
            break
        end
    end
    if not seedName then
        -- attempt to inspect tools in backpack
        for _, tool in ipairs(plr.Backpack:GetChildren()) do
            local itemName = tool:GetAttribute and tool:GetAttribute("ItemName")
            if itemName and seedData[itemName] then
                seedName = itemName
                break
            end
        end
    end
    if seedName then
        local pos = GAG:GetRandomPlantingLocation()
        GAG:PlantSeed(seedName, pos)
    end
end

-- AutoHarvest: pickup fruits (via proximity prompt) and shovel grown plants
local function autoHarvestStep()
    local fruits = GAG:GetFruitsOnFarm()
    for _, f in ipairs(fruits) do
        -- try to find a proximity prompt and fire it
        local prompt = nil
        if typeof(f) == "Instance" then
            prompt = f:FindFirstChildWhichIsA("ProximityPrompt", true)
            if prompt and prompt.Parent and (getHRP().Position - prompt.Parent.Position).Magnitude <= (prompt.MaxActivationDistance or 10) then
                pcall(function() fireproximityprompt(prompt) end)
            end
        end
    end
    -- shovel harvestable stand-alone plants
    for _, plant in ipairs(GAG:GetPlantsOnFarm()) do
        if plant:IsHarvestableWithoutFruit() and plant:HasGrown() then
            local inst = plant._instance
            if inst then
                local primary = inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart")
                if primary then
                    pcall(function() GAG:ShovelPlant(primary) end)
                else
                    pcall(function() GAG:ShovelPlant(inst) end)
                end
            end
        end
    end
end

-- AutoSell: Sell all fruits in inventory
local function autoSellStep()
    GAG:SellAllFruitsInInventory()
end

-- AutoBuyEggs: buy index 1 repeatedly
local function autoBuyEggsStep()
    GAG:BuyEggFromPetEggShop(1)
end

-- AutoHatch: hatch planted predictable eggs
local function autoHatchStep()
    for _, egg in ipairs(GAG:GetPlantedEggObjects and GAG:GetPlantedEggObjects() or GAG:GetSavedPetEggObjects()) do
        local inst = GAG:GetPetEggInstanceByUUID(egg.UUID)
        if inst then
            GAG:HatchEgg(inst)
        end
    end
end

-- AutoEquipLoop: equip all pets to farm spawn
local function autoEquipStep()
    local spawnCFrame = (GAG:GetOwnFarmFolder() and GAG:GetOwnFarmFolder().Spawn_Point and GAG:GetOwnFarmFolder().Spawn_Point.CFrame) or getHRP().CFrame
    for _, pet in ipairs(GAG:GetPetsInInventory()) do
        pcall(function() pet:EquipPet(spawnCFrame) end)
    end
end

-- ====== ESP Implementation (simplified) ======
local espObjs = {Eggs={}, Pets={}, Plants={}}
local function clearESP(kind)
    for _, gui in ipairs(espObjs[kind]) do
        pcall(function() gui:Destroy() end)
    end
    espObjs[kind] = {}
end

local function createBillboardOnPart(part, text)
    if not part or not part:IsA("BasePart") then return nil end
    local bb = Instance.new("BillboardGui")
    bb.Name = "GAG_ESP"
    bb.Adornee = part
    bb.AlwaysOnTop = true
    bb.Size = UDim2.new(0,140,0,30)
    bb.StudsOffset = Vector3.new(0,2.2,0)
    bb.Parent = part
    local lbl = Instance.new("TextLabel", bb)
    lbl.Size = UDim2.fromScale(1,1)
    lbl.BackgroundTransparency = 1
    lbl.Text = text or ""
    lbl.TextScaled = true
    lbl.Font = Enum.Font.SourceSansBold
    return bb
end

local function updateESPAll()
    -- Eggs
    if state.ESP_Eggs then
        clearESP("Eggs")
        local eggs = GAG:GetPlantedEggObjects and GAG:GetPlantedEggObjects() or {}
        for _, egg in ipairs(eggs) do
            local inst = GAG:GetPetEggInstanceByUUID(egg.UUID)
            if inst then
                local base = inst:IsA("Model") and (inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart")) or inst
                if base then table.insert(espObjs.Eggs, createBillboardOnPart(base, "Egg: "..(egg.Data and egg.Data.EggName or egg.EggName or "Egg"))) end
            end
        end
    else
        clearESP("Eggs")
    end
    -- Pets (simple: show equipped)
    if state.ESP_Pets then
        clearESP("Pets")
        for _, pet in ipairs(GAG:GetEquippedPets()) do
            if plr.Character and plr.Character.PrimaryPart then
                table.insert(espObjs.Pets, createBillboardOnPart(plr.Character.PrimaryPart, "Equipped Pet"))
            end
        end
    else
        clearESP("Pets")
    end
    -- Plants
    if state.ESP_Plants then
        clearESP("Plants")
        for _, plant in ipairs(GAG:GetPlantsOnFarm()) do
            local primary = plant._instance and (plant._instance.PrimaryPart or plant._instance:FindFirstChildWhichIsA("BasePart"))
            if primary then
                table.insert(espObjs.Plants, createBillboardOnPart(primary, (plant.Name or "Plant").."\nAge:"..tostring(plant.Age).."/"..tostring(plant.MaxAge)))
            end
        end
    else
        clearESP("Plants")
    end
end

-- small loop to refresh ESP periodically
task.spawn(function()
    while true do
        pcall(function()
            updateESPAll()
        end)
        task.wait(2)
    end
end)

-- ====== Build UI Tabs & Controls (hook to ported GAG) ======

-- Farm Tab
local FarmTab = Window:CreateTab("🌱 Farm")
FarmTab:CreateToggle({
    Name = "Auto Plant (random)",
    CurrentValue = false,
    Callback = function(val)
        state.AutoPlant = val
        if val then startLoop("AutoPlant", state.AutoPlantInterval, autoPlantStep) end
    end
})
FarmTab:CreateSlider({
    Name = "Auto Plant Interval (s)",
    Range = {0.2, 5},
    Increment = 0.1,
    Suffix = "s",
    CurrentValue = state.AutoPlantInterval,
    Callback = function(v) state.AutoPlantInterval = v end
})
FarmTab:CreateToggle({
    Name = "Auto Harvest",
    CurrentValue = false,
    Callback = function(val)
        state.AutoHarvest = val
        if val then startLoop("AutoHarvest", state.AutoHarvestInterval, autoHarvestStep) end
    end
})
FarmTab:CreateSlider({
    Name = "Auto Harvest Interval (s)",
    Range = {0.2, 5},
    Increment = 0.1,
    Suffix = "s",
    CurrentValue = state.AutoHarvestInterval,
    Callback = function(v) state.AutoHarvestInterval = v end
})
FarmTab:CreateToggle({
    Name = "Auto Sell",
    CurrentValue = false,
    Callback = function(val)
        state.AutoSell = val
        if val then startLoop("AutoSell", state.AutoSellInterval, autoSellStep) end
    end
})
FarmTab:CreateSlider({
    Name = "Auto Sell Interval (s)",
    Range = {0.5, 30},
    Increment = 0.5,
    Suffix = "s",
    CurrentValue = state.AutoSellInterval,
    Callback = function(v) state.AutoSellInterval = v end
})
FarmTab:CreateButton({Name="Sell All Fruits Now", Callback=function() safeCall(function() GAG:SellAllFruitsInInventory() end) end})
FarmTab:CreateButton({Name="Plant Random Seed Now", Callback=function() safeCall(autoPlantStep) end})
FarmTab:CreateButton({Name="Harvest Now", Callback=function() safeCall(autoHarvestStep) end})

-- Pet Tab
local PetTab = Window:CreateTab("🐾 Pets")
PetTab:CreateButton({Name="Equip All Pets", Callback=function() safeCall(function()
    local spawn = (GAG:GetOwnFarmFolder() and GAG:GetOwnFarmFolder().Spawn_Point and GAG:GetOwnFarmFolder().Spawn_Point.CFrame) or getHRP().CFrame
    for _, pet in ipairs(GAG:GetPetsInInventory()) do pcall(function() pet:EquipPet(spawn) end) end
end) end})
PetTab:CreateButton({Name="Unequip All Pets", Callback=function() safeCall(function()
    for _, pet in ipairs(GAG:GetEquippedPets()) do pcall(function() pet:UnequipPet() end) end
end) end})
PetTab:CreateToggle({Name="Auto Equip Loop", CurrentValue=false, Callback=function(val) state.AutoEquipLoop = val if val then startLoop("AutoEquipLoop", state.AutoEquipInterval, autoEquipStep) end end})
PetTab:CreateSlider({Name="Auto Equip Interval (s)", Range={1,60}, Increment=1, Suffix="s", CurrentValue = state.AutoEquipInterval, Callback=function(v) state.AutoEquipInterval = v end})
PetTab:CreateToggle({Name="Auto Accept Pet Gifts", CurrentValue=false, Callback=function(val) state.AutoAcceptPetGifts = val GAG:AutoAcceptPetGifts(val) end})

-- Egg Tab
local EggTab = Window:CreateTab("🥚 Eggs")
EggTab:CreateToggle({Name="Auto Buy Eggs (index 1)", CurrentValue=false, Callback=function(val) state.AutoBuyEggs = val if val then startLoop("AutoBuyEggs", state.AutoBuyEggInterval, autoBuyEggsStep) end end})
EggTab:CreateSlider({Name="Auto Buy Interval (s)", Range={1,60}, Increment=1, Suffix="s", CurrentValue=state.AutoBuyEggInterval, Callback=function(v) state.AutoBuyEggInterval = v end})
EggTab:CreateToggle({Name="Auto Hatch Planted Eggs", CurrentValue=false, Callback=function(val) state.AutoHatch = val if val then startLoop("AutoHatch", state.AutoHatchInterval, autoHatchStep) end end})
EggTab:CreateSlider({Name="Auto Hatch Interval (s)", Range={0.2,10}, Increment=0.2, Suffix="s", CurrentValue=state.AutoHatchInterval, Callback=function(v) state.AutoHatchInterval = v end})
EggTab:CreateButton({Name="Buy Egg (index 1) Now", Callback=function() safeCall(function() GAG:BuyEggFromPetEggShop(1) end) end})
EggTab:CreateButton({Name="Hatch All Planted Eggs Now", Callback=function() safeCall(autoHatchStep) end})
EggTab:CreateToggle({Name="Egg ESP", CurrentValue=false, Callback=function(val) state.ESP_Eggs = val end})

-- Shops Tab
local ShopTab = Window:CreateTab("🛒 Shops")
ShopTab:CreateButton({Name="Buy First Seed Shop Item", Callback=function() safeCall(function()
    local stocks = GAG:GetSeedShopStock()
    -- stocks might be dictionary or array-like
    if type(stocks) == "table" then
        for k,v in pairs(stocks) do
            if type(k) == "string" then
                GAG:BuySeed(k) break
            elseif v and v.ItemName then
                GAG:BuySeed(v.ItemName) break
            end
        end
    end
end) end})
ShopTab:CreateButton({Name="Buy Night Event First Item", Callback=function() safeCall(function()
    local ns = GAG:GetNightEventShopStock()
    if ns and #ns > 0 then GAG:BuyNightEventShopItem(ns[1].ItemName) end
end) end})
ShopTab:CreateButton({Name="Buy Gear First Item", Callback=function() safeCall(function()
    local gs = GAG:GetGearStock()
    if gs and #gs > 0 then GAG:BuyCosmeticItem(gs[1].ItemName) end
end) end})

-- Teleport Tab
local TpTab = Window:CreateTab("📍 Teleport")
TpTab:CreateButton({Name="Teleport to Garden", Callback=function() safeCall(function() GAG:TeleportToGarden() end) end})
TpTab:CreateButton({Name="Teleport to Pet Egg Shop", Callback=function() safeCall(function() GAG:TeleportToPetEggShop() end) end})
TpTab:CreateButton({Name="Teleport to Sell", Callback=function() safeCall(function() GAG:TeleportToSell() end) end})
TpTab:CreateButton({Name="Teleport to Seeds Shop", Callback=function() safeCall(function() GAG:TeleportToSeedsShop() end) end})
TpTab:CreateButton({Name="Rejoin Server", Callback=function() safeCall(function() GAG:RejoinServer() end) end})

-- Inventory Tab
local InvTab = Window:CreateTab("🎒 Inventory")
InvTab:CreateButton({Name="Print Inventory (console)", Callback=function()
    local inv = GAG:GetInventory()
    for i,it in ipairs(inv) do
        local name = (it.ItemData and it.ItemData.ItemName) or it.ItemName or "Unknown"
        print(i, "Name:", name, "Type:", it.ItemType or "?", "UUID:", it.UUID, "Qty:", (it.ItemData and it.ItemData.Quantity) or it.Quantity)
    end
end})
InvTab:CreateButton({Name="Sell Fruit In Hand", Callback=function() safeCall(function() GAG:SellFruitInHand() end) end})
InvTab:CreateButton({Name="Toggle Favorite For Tool In Hand", Callback=function()
    local tool = plr.Character and plr.Character:FindFirstChildWhichIsA("Tool") or plr.Backpack:FindFirstChildWhichIsA("Tool")
    if tool then safeCall(function() GAG:ToggleFavoriteItem(tool) end) else Rayfield:CreateNotification({Title="No tool", Content="Equip or hold tool then retry", Duration=3}) end
end})

-- ESP Tab
local EspTab = Window:CreateTab("👀 ESP")
EspTab:CreateToggle({Name="Egg ESP", CurrentValue=false, Callback=function(val) state.ESP_Eggs = val end})
EspTab:CreateToggle({Name="Pet ESP", CurrentValue=false, Callback=function(val) state.ESP_Pets = val end})
EspTab:CreateToggle({Name="Plant ESP", CurrentValue=false, Callback=function(val) state.ESP_Plants = val end})
EspTab:CreateButton({Name="Clear All ESP", Callback=function() clearESP("Eggs"); clearESP("Pets"); clearESP("Plants") end})

-- Utilities Tab
local UtilTab = Window:CreateTab("🔧 Utilities")
UtilTab:CreateButton({Name="Finish Loading Sequence (force)", Callback=function() safeCall(loadWaitSequence) end})
UtilTab:CreateButton({Name="List Mutations (console)", Callback=function()
    for _,m in ipairs(GAG:GetAllMutations()) do print("Mutation:", m.Name, "Multi:", m.ValueMulti) end
end})
UtilTab:CreateButton({Name="Print Sheckles & Honey", Callback=function() print("Sheckles:", GAG:GetShecklesCurrency(), "Honey:", GAG:GetHoneyCurrency()) end})
UtilTab:CreateButton({Name="Get Own Farm Folder (print)", Callback=function() print(GAG:GetOwnFarmFolder()) end})
UtilTab:CreateButton({Name="Scrape Dev Products (console)", Callback=function() 
    local ok, pages = pcall(function() 
        local ms = cloneref(game:GetService("MarketplaceService"))
        return ms:GetDeveloperProductsAsync()
    end)
    if ok and pages then
        print("Dev products returned (pages)...")
    else
        print("Failed to fetch dev products or not supported.")
    end
end})

-- Config & finish
Rayfield:LoadConfiguration()
Rayfield:CreateNotification({Title="GAG Port Ready", Content="UI + logic port loaded. Use tabs.", Duration=4})

-- cleanup on close: disable any auto features & disconnect events
Window:OnClose(function()
    -- disable loops and features
    state.AutoPlant=false; state.AutoHarvest=false; state.AutoSell=false; state.AutoBuyEggs=false; state.AutoHatch=false; state.AutoEquipLoop=false
    GAG:AutoAcceptPetGifts(false)
    clearESP("Eggs"); clearESP("Pets"); clearESP("Plants")
end)

-- END OF SCRIPT
