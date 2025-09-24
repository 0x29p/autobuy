-- ========== SAFE INIT ==========

-- Destroy Rayfield lama
pcall(function()
    if getgenv().RayfieldWindow then
        getgenv().RayfieldWindow:Destroy()
        getgenv().RayfieldWindow = nil
    end
end)

-- Detect GUI Parent (support PC & HP)
local Players = game:GetService("Players")
local plr = Players.LocalPlayer
local GuiParent = (gethui and gethui()) or game:GetService("CoreGui") or plr:WaitForChild("PlayerGui")

-- Hapus Teleport GUI lama
pcall(function()
    if GuiParent:FindFirstChild("TeleportGUI") then
        GuiParent.TeleportGUI:Destroy()
    end
end)

-- ========== LOAD RAYFIELD ==========
local Rayfield
pcall(function()
    Rayfield = loadstring(game:HttpGetAsync("https://sirius.menu/rayfield"))()
end)

-- Fallback kalau Rayfield gagal load
if not Rayfield then
    warn("⚠️ Rayfield gagal dimuat, pakai fallback UI minimal")
    Rayfield = {
        CreateWindow = function()
            return {
                CreateTab = function()
                    return {
                        CreateSection=function()end,
                        CreateDropdown=function()end,
                        CreateToggle=function()end
                    }
                end
            }
        end
    }
end

-- Buat Window
local Window = Rayfield:CreateWindow({
    Name = "PERMANA - GAG",
    LoadingTitle = "PERMANA SCRIPT",
    LoadingSubtitle = "| GROW A GARDEN",
    ConfigurationSaving = {
       Enabled = true,
       FolderName = "XenoRayfield",
       FileName = "DefaultConfig"
    },
    KeySystem = false
})
getgenv().RayfieldWindow = Window

-- ========== SERVICES ==========
local RS = game:GetService("ReplicatedStorage")

-- Remotes
local BuySeedRemote = RS.GameEvents.BuySeedStock
local BuyGearRemote = RS.GameEvents.BuyGearStock
local BuyPetRemote = RS.GameEvents.BuyPetEgg
local BuyEventRemote = RS.GameEvents.BuyEventShopStock
local FeedRemote = RS.GameEvents.FallMarketEvent.SubmitAllPlants
local HarvestRemote = RS:WaitForChild("GameEvents"):WaitForChild("Crops")

-- ========== TELEPORT GUI ==========
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "TeleportGUI"
screenGui.Parent = GuiParent

local LocationCFrames = {
    EventCFrame = CFrame.new(-100.685043, 0.90001297, -11.6456203),
    GearShopCFrame = CFrame.new(-284.89959716796875, 2.9828338623046875, -13.92815589904785)
}

local function createOverlayButton(name, cframe, positionOffset)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0,70,0,30)
    button.AnchorPoint = Vector2.new(0.5,0)
    button.Position = positionOffset
    button.BackgroundColor3 = Color3.fromRGB(0,170,255)
    button.TextColor3 = Color3.fromRGB(255,255,255)
    button.Text = name
    button.Font = Enum.Font.SourceSansBold
    button.TextSize = 14
    button.ZIndex = 10
    button.Parent = screenGui

    button.MouseButton1Click:Connect(function()
        if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            plr.Character.HumanoidRootPart.CFrame = cframe
        end
    end)
end

local screenCenterX = 0.5
local startY = 50
createOverlayButton("MID", LocationCFrames.EventCFrame, UDim2.new(screenCenterX-0.24,0,0,startY))
createOverlayButton("GEAR", LocationCFrames.GearShopCFrame, UDim2.new(screenCenterX+0.24,0,0,startY))

-- ========== AUTO BUY TAB ==========
local AutoTab = Window:CreateTab("AUTO BUY")
AutoTab:CreateSection("Seed Shop")

local AllSeeds = {"Apple","Bamboo","Beanstalk","Blueberry","Burning Bud","Cacao","Cactus","Carrot","Coconut","Corn","Daffodil","Dragon Fruit",
                   "Elder Strawberry","Ember Lily","Giant Pinecone","Grape","Mango","Mushroom","Orange Tulip","Pepper","Pumpkin","Romanesco","Strawberry","Sugar Apple","Tomato","Watermelon"}

getgenv().AutoBuyConfig = getgenv().AutoBuyConfig or {}
getgenv().AutoBuyConfig.Seed = getgenv().AutoBuyConfig.Seed or {Selected={}, Enabled=false}
local SeedConfig = getgenv().AutoBuyConfig.Seed

local OptionsWithAll = {"All"}
for _,s in ipairs(AllSeeds) do table.insert(OptionsWithAll,s) end

AutoTab:CreateDropdown({
    Name="Pilih Seed",
    Options=OptionsWithAll,
    CurrentOption=SeedConfig.Selected,
    MultipleOptions=true,
    Flag="SeedDropdown",
    Callback=function(opts)
        if table.find(opts,"All") then
            SeedConfig.Selected = AllSeeds
        else
            SeedConfig.Selected = opts
        end
    end,
})

AutoTab:CreateToggle({
    Name="Auto Buy Seed",
    CurrentValue=SeedConfig.Enabled,
    Flag="AutoBuySeeds",
    Callback=function(state)
        SeedConfig.Enabled = state
        if state then
            task.spawn(function()
                while SeedConfig.Enabled do
                    for _,item in ipairs(SeedConfig.Selected) do
                        pcall(function()
                            BuySeedRemote:FireServer("Tier 1", item)
                        end)
                        task.wait(0.05)
                    end
                    task.wait(0.2)
                end
            end)
        end
    end,
})

-- Gear Shop
AutoTab:CreateSection("Gear Shop")
local AllGears = {"Advanced Sprinkler","Basic Sprinkler","Cleaning Spray","Cleansing Pet Shard","Favorite Tool","Harvest Tool","Levelup Lollipop","Magnifying Glass","Master Sprinkler","Medium Toy","Medium Treat","Recall Wrench","Trading Ticket","Trowel","Watering Can"}
getgenv().AutoBuyConfig.Gear = getgenv().AutoBuyConfig.Gear or {Selected={}, Enabled=false}
local GearConfig = getgenv().AutoBuyConfig.Gear

local GearOptions = {"All"}
for _,g in ipairs(AllGears) do table.insert(GearOptions,g) end

AutoTab:CreateDropdown({
    Name="Pilih Gear",
    Options=GearOptions,
    CurrentOption=GearConfig.Selected,
    MultipleOptions=true,
    Flag="GearDropdown",
    Callback=function(opts)
        if table.find(opts,"All") then
            GearConfig.Selected = AllGears
        else
            GearConfig.Selected = opts
        end
    end,
})

AutoTab:CreateToggle({
    Name="Auto Buy Gear",
    CurrentValue=GearConfig.Enabled,
    Flag="AutoBuyGear",
    Callback=function(state)
        GearConfig.Enabled = state
        if state then
            task.spawn(function()
                while GearConfig.Enabled do
                    for _,item in ipairs(GearConfig.Selected) do
                        pcall(function()
                            BuyGearRemote:FireServer(item)
                        end)
                        task.wait(0.05)
                    end
                    task.wait(0.2)
                end
            end)
        end
    end,
})

-- Pet Egg Shop
AutoTab:CreateSection("Pet Egg Shop")
local AllPets = {"Bug Egg","Common Egg","Legendary Egg","Mythical Egg","Rare Egg","Uncommon Egg"}
getgenv().AutoBuyConfig.Pet = getgenv().AutoBuyConfig.Pet or {Selected={}, Enabled=false}
local PetConfig = getgenv().AutoBuyConfig.Pet

local PetOptions = {"All"}
for _,p in ipairs(AllPets) do table.insert(PetOptions,p) end

AutoTab:CreateDropdown({
    Name="Pilih Pet Egg",
    Options=PetOptions,
    CurrentOption=PetConfig.Selected,
    MultipleOptions=true,
    Flag="PetDropdown",
    Callback=function(opts)
        if table.find(opts,"All") then
            PetConfig.Selected = AllPets
        else
            PetConfig.Selected = opts
        end
    end,
})

AutoTab:CreateToggle({
    Name="Auto Buy Pet Egg",
    CurrentValue=PetConfig.Enabled,
    Flag="AutoBuyPet",
    Callback=function(state)
        PetConfig.Enabled = state
        if state then
            task.spawn(function()
                while PetConfig.Enabled do
                    for _,item in ipairs(PetConfig.Selected) do
                        pcall(function()
                            BuyPetRemote:FireServer(item)
                        end)
                        task.wait(0.05)
                    end
                    task.wait(0.2)
                end
            end)
        end
    end,
})

-- Traveling Merchant Shop
AutoTab:CreateSection("Traveling Merchant Shop")

local AllMerchantItems = {
    "Berry Blusher Sprinkler",
    "Flower Froster Sprinkler",
    "Spice Spritzer Sprinkler",
    "Stalk Sprout Sprinkler",
    "Sweet Soaker Sprinkler",
    "Tropical Mist Sprinkler",
	"Avocado",
	"Banana",
	"Bell Pepper",
	"Cauliflower",
	"Common Summer Egg",
	"Feijoa",
	"Green Apple",
	"Kiwi",
	"Loquat",
	"Paradise Egg",
	"Pineapple",
	"Pitcher Plant"
	
}

getgenv().AutoBuyConfig.Merchant = getgenv().AutoBuyConfig.Merchant or {Selected={}, Enabled=false}
local MerchantConfig = getgenv().AutoBuyConfig.Merchant

local MerchantOptions = {"All"}
for _,m in ipairs(AllMerchantItems) do table.insert(MerchantOptions,m) end

AutoTab:CreateDropdown({
    Name="Pilih Merchant Item",
    Options=MerchantOptions,
    CurrentOption=MerchantConfig.Selected,
    MultipleOptions=true,
    Flag="MerchantDropdown",
    Callback=function(opts)
        if table.find(opts,"All") then
            MerchantConfig.Selected = AllMerchantItems
        else
            MerchantConfig.Selected = opts
        end
    end,
})

AutoTab:CreateToggle({
    Name="Auto Buy Merchant",
    CurrentValue=MerchantConfig.Enabled,
    Flag="AutoBuyMerchant",
    Callback=function(state)
        MerchantConfig.Enabled = state
        if state then
            task.spawn(function()
                while MerchantConfig.Enabled and not getgenv().AutoBuyKillSwitch.Value do
                    for _,item in ipairs(MerchantConfig.Selected) do
                        pcall(function()
                            RS.GameEvents.BuyTravelingMerchantShopStock:FireServer(item)
                        end)
                        task.wait(0.05)
                    end
                    task.wait(0.5)
                end
            end)
        end
    end,
})


---- event shop menu
-- // Remote buat beli event shop
local BuyEventRemote = game:GetService("ReplicatedStorage").GameEvents.BuyEventShopStock
local UnlockRemote = game:GetService("ReplicatedStorage").GameEvents.SaveSlotService.RememberUnlockage

-- // Tab & Section
local EventTab = Window:CreateTab("EVENT")
EventTab:CreateSection("Event Shop")

-- // Semua item event
local AllEventItems = {
    "Chipmunk","Fall Egg","Mallard","Marmot","Red Panda","Red Squirrel","Salmon","Space Squirrel","Sugar Glider","Woodpecker",
    "Acorn Bell","Acorn Lollipop","Bonfire","Firefly Jar","Golden Acorn","Harvest Basket","Leaf Blower","Maple Leaf Charm","Maple Leaf Kite","Maple Sprinkler",
    "Maple Syrup","Rake","Sky Lantern","Super Leaf Blower","Carnival Pumpkin","Fall Seed Pack","Golden Peach","Kniphofia","Maple Resin","Meyer Lemon",
    "Parsley","Turnip","Fall Crate","Fall Fountain","Fall Hay Bale","Fall Leaf Chair","Fall Wreath","Flying Kite","Maple Crate","Maple Flag","Pile Of Leaves"
}

-- // Config
getgenv().AutoBuyConfig.Event = getgenv().AutoBuyConfig.Event or {Selected={}, Enabled=false}
local EventConfig = getgenv().AutoBuyConfig.Event
getgenv().AutoBuyConfig.EventFeed = getgenv().AutoBuyConfig.EventFeed or {Enabled=false}
local EventFeedConfig = getgenv().AutoBuyConfig.EventFeed

-- // Dropdown Options
local EventOptions = {"All"}
for _,s in ipairs(AllEventItems) do
    table.insert(EventOptions, s)
end

-- // Dropdown Menu
EventTab:CreateDropdown({
    Name="Event Shop Items",
    Options=EventOptions,
    CurrentOption=EventConfig.Selected,
    MultipleOptions=true,
    Flag="EventDropdown",
    Callback=function(opts)
        if table.find(opts,"All") then
            EventConfig.Selected = AllEventItems
        else
            EventConfig.Selected = opts
        end
    end,
})

-- // Toggle Auto Buy (Fast 1 Item)
EventTab:CreateToggle({
    Name="Auto Buy Event Shop (Fast 1 Item)",
    CurrentValue=EventConfig.Enabled,
    Flag="AutoBuyEvent",
    Callback=function(state)
        EventConfig.Enabled = state
        if state then
            task.spawn(function()
                while EventConfig.Enabled do
                    local item = EventConfig.Selected[1] -- ambil item pertama dari dropdown
                    if item then
                        pcall(function()
                            -- 1. Unlock slot
                            UnlockRemote:FireServer()
                            task.wait(0.05)

                            -- 2. Beli item
                            BuyEventRemote:FireServer(item, 1)
                            print("Bought:", item)
                        end)
                    end
                    task.wait(0.1) -- delay kecil biar cepat tapi aman
                end
            end)
        end
    end,
})


-- ambil services
local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local plr = Players.LocalPlayer

-- remotes
local Crops = RS.GameEvents.Crops
local Market = RS.GameEvents.FallMarketEvent

-- cari farm player
local function GetPlayerFarm()
    for _, farm in ipairs(workspace.Farm:GetChildren()) do
        local important = farm:FindFirstChild("Important")
        if important and important:FindFirstChild("Data") and important.Data:FindFirstChild("Owner") then
            if important.Data.Owner.Value == plr.Name then
                return farm
            end
        end
    end
    return nil
end

-- ambil semua buah
local function GetAllFruits()
    local fruits = {}
    local farm = GetPlayerFarm()
    if not farm then return fruits end

    local plantsFolder = farm.Important:FindFirstChild("Plants_Physical")
    if not plantsFolder then return fruits end

    for _, plant in ipairs(plantsFolder:GetChildren()) do
        local fruitsFolder = plant:FindFirstChild("Fruits")
        if fruitsFolder then
            for _, fruit in ipairs(fruitsFolder:GetChildren()) do
                table.insert(fruits, fruit)
            end
        end
    end
    return fruits
end

-- auto harvest + feed
local function AutoHarvestAndFeedAll()
    local fruits = GetAllFruits()
    if #fruits > 0 then
        -- harus nested table di index [1]
        local args = { [1] = {} }
        for i, fruit in ipairs(fruits) do
            args[1][i] = fruit
        end

        -- HARVEST
        pcall(function()
            Crops.Collect:FireServer(unpack(args))  -- unpack(args) = args[1]
        end)

        task.wait(1)

        -- FEED KE EVENT
        pcall(function()
            Market.SubmitAllPlants:FireServer()
        end)
    end
end

-- toggle UI
EventTab:CreateSection("Auto Harvest + Feed Semua Tanaman")

EventTab:CreateToggle({
    Name = "Auto Harvest + Feed (Semua)",
    CurrentValue = false,
    Flag = "AutoHarvestFeedAll",
    Callback = function(state)
        if getgenv().AutoFeedLoop then
            getgenv().AutoFeedLoop.Running = false
        end

        if state then
            getgenv().AutoFeedLoop = {Running = true}
            local ThisLoop = getgenv().AutoFeedLoop
            task.spawn(function()
                while ThisLoop.Running do
                    AutoHarvestAndFeedAll()
                    task.wait(5)
                end
            end)
        end
    end,
})


-- ========== AUTO GARDEN TAB ==========
local GardenTab = Window:CreateTab("AUTO GARDEN")
GardenTab:CreateSection("Harvest")

getgenv().AutoBuyConfig.Garden = getgenv().AutoBuyConfig.Garden or {Enabled=false}
local GardenConfig = getgenv().AutoBuyConfig.Garden

local function GetPlayerFarm()
    local farmFolder = workspace:WaitForChild("Farm")
    for _, farm in ipairs(farmFolder:GetChildren()) do
        local important = farm:FindFirstChild("Important")
        if important and important:FindFirstChild("Data") and important.Data:FindFirstChild("Owner") then
            if important.Data.Owner.Value == plr.Name then
                return farm
            end
        end
    end
end

local function AutoHarvest()
    local farm = GetPlayerFarm()
    if not farm then return end
    local plantsFolder = farm:FindFirstChild("Important") and farm.Important:FindFirstChild("Plants_Physical")
    if not plantsFolder then return end

    for _, plant in ipairs(plantsFolder:GetChildren()) do
        local fruitsFolder = plant:FindFirstChild("Fruits")
        if fruitsFolder then
            for _, fruit in ipairs(fruitsFolder:GetChildren()) do
                pcall(function()
                    HarvestRemote.Collect:FireServer({fruit})
                end)
                task.wait(0.05)
            end
        end
    end
end

GardenTab:CreateToggle({
    Name="Auto Harvest",
    CurrentValue=GardenConfig.Enabled,
    Flag="AutoGardenHarvest",
    Callback=function(state)
        GardenConfig.Enabled = state
    end,
})

-- Loop Auto Harvest Background
task.spawn(function()
    while task.wait(0.7) do -- lebih enteng biar HP gak lag
        if GardenConfig.Enabled then
            pcall(AutoHarvest)
        end
    end
end)




--== ESP MENU ==--
