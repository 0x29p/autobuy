local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Players = game:GetService("Players")
local plr = Players.LocalPlayer
local playerGui = plr:WaitForChild("PlayerGui")

-- Pastikan ScreenGui ada
local screenGui = playerGui:FindFirstChild("ScreenGui")
if not screenGui then
    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ScreenGui"
    screenGui.Parent = playerGui
end

-- LocationCFrames
local LocationCFrames = {
    EventCFrame = CFrame.new(-100.685043, 0.90001297, -11.6456203),  -- samping Seed
    GearShopCFrame = CFrame.new(-284.89959716796875, 2.9828338623046875, -21.92815589904785) -- samping Sell
}

local function createOverlayButton(name, cframe, positionOffset)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 70, 0, 30)
    button.AnchorPoint = Vector2.new(0.5, 0)  -- tengah horizontal
    button.Position = positionOffset
    button.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
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

-- Tombol di tengah layar horizontal
local screenCenterX = 0.5  -- tengah layar
local startY = 50           -- jarak dari atas
createOverlayButton("EVENT", LocationCFrames.EventCFrame, UDim2.new(screenCenterX - 0.24, 0, 0, startY))
createOverlayButton("GEAR", LocationCFrames.GearShopCFrame, UDim2.new(screenCenterX + 0.24, 0, 0, startY))

-- Remotes
local BuySeedRemote = RS.GameEvents.BuySeedStock
local BuyGearRemote = RS.GameEvents.BuyGearStock
local BuyPetRemote = RS.GameEvents.BuyPetEgg

-- GUI utama
local ScreenGui = Instance.new("ScreenGui", playerGui)
ScreenGui.ResetOnSpawn = false

local mainFrame = Instance.new("Frame", ScreenGui)
mainFrame.Size = UDim2.new(0,300,0,400)
mainFrame.Position = UDim2.new(0.1,0,0.2,0)
mainFrame.BackgroundColor3 = Color3.fromRGB(30,30,30)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true

-- Header
local header = Instance.new("Frame", mainFrame)
header.Size = UDim2.new(1,0,0,30)
header.BackgroundColor3 = Color3.fromRGB(50,50,50)
header.BorderSizePixel = 0

local title = Instance.new("TextLabel", header)
title.Size = UDim2.new(1,-60,1,0)
title.Position = UDim2.new(0,5,0,0)
title.BackgroundTransparency = 1
title.Text = "🌱 Main Menu"
title.TextColor3 = Color3.new(1,1,1)
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.TextXAlignment = Enum.TextXAlignment.Left

local closeBtn = Instance.new("TextButton", header)
closeBtn.Size = UDim2.new(0,30,1,0)
closeBtn.Position = UDim2.new(1,-30,0,0)
closeBtn.BackgroundColor3 = Color3.fromRGB(170,50,50)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.new(1,1,1)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 14
closeBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

-- Tombol minimize di header
local minimizeBtn = Instance.new("TextButton", header)
minimizeBtn.Size = UDim2.new(0,30,1,0)
minimizeBtn.Position = UDim2.new(1,-60,0,0) -- kiri tombol close
minimizeBtn.BackgroundColor3 = Color3.fromRGB(80,80,150)
minimizeBtn.Text = "-"
minimizeBtn.TextColor3 = Color3.new(1,1,1)
minimizeBtn.Font = Enum.Font.GothamBold
minimizeBtn.TextSize = 18

-- Tab Buttons
local tabFrame = Instance.new("Frame", mainFrame)
tabFrame.Size = UDim2.new(1,0,0,30)
tabFrame.Position = UDim2.new(0,0,0,30)
tabFrame.BackgroundTransparency = 1

local function createTabButton(text,pos)
    local btn = Instance.new("TextButton", tabFrame)
    btn.Size = UDim2.new(0,90,1,0)
    btn.Position = UDim2.new(0,pos,0,0)
    btn.BackgroundColor3 = Color3.fromRGB(70,70,70)
    btn.Text = text
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    return btn
end

local seedTabBtn = createTabButton("Seed",0)
local gearTabBtn = createTabButton("Gear",100)
local petTabBtn = createTabButton("Pet",200)

-- Content Frame
local contentFrame = Instance.new("Frame", mainFrame)
contentFrame.Size = UDim2.new(1,0,1,-60)
contentFrame.Position = UDim2.new(0,0,0,60)
contentFrame.BackgroundTransparency = 1

-- ===== Seed Frame =====
local seedShop = playerGui:WaitForChild("Seed_Shop")
local seedScrolling = seedShop.Frame.ScrollingFrame

local seedFrame = Instance.new("Frame", contentFrame)
seedFrame.Size = UDim2.new(1,0,1,0)
seedFrame.BackgroundTransparency = 1

local seedScroll = Instance.new("ScrollingFrame", seedFrame)
seedScroll.Size = UDim2.new(1,-10,1,0)
seedScroll.Position = UDim2.new(0,5,0,0)
seedScroll.BackgroundTransparency = 1
seedScroll.ScrollBarThickness = 6

local seedLayout = Instance.new("UIListLayout", seedScroll)
seedLayout.Padding = UDim.new(0,5)
seedLayout.SortOrder = Enum.SortOrder.LayoutOrder
seedLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    seedScroll.CanvasSize = UDim2.new(0,0,0,seedLayout.AbsoluteContentSize.Y + 5)
end)

-- Ambil data seed
local seedNames = {}
local lookup = {}
for _, s in pairs(seedScrolling:GetChildren()) do
    if s:IsA("Frame") then
        local name = s.Name
        if not name:lower():find("_padding") and not lookup[name:lower()] then
            table.insert(seedNames,name)
            lookup[name:lower()] = true
        end
    end
end
table.sort(seedNames,function(a,b) return a:lower()<b:lower() end)

-- Persistent config
getgenv().AutoBuyConfig = getgenv().AutoBuyConfig or {}
getgenv().AutoBuyConfig.Seed = getgenv().AutoBuyConfig.Seed or {}
local SeedSettings = getgenv().AutoBuyConfig.Seed

-- Fungsi buat tombol seed
local function createSeedButton(seedName)
    local frame = Instance.new("Frame", seedScroll)
    frame.Size = UDim2.new(1,-5,0,35)
    frame.BackgroundColor3 = Color3.fromRGB(40,40,40)
    frame.BorderSizePixel = 0

    local label = Instance.new("TextLabel", frame)
    label.Size = UDim2.new(0.5,-5,1,0)
    label.Position = UDim2.new(0,5,0,0)
    label.BackgroundTransparency = 1
    label.Text = seedName
    label.TextColor3 = Color3.new(1,1,1)
    label.Font = Enum.Font.Gotham
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left

    local buyBtn = Instance.new("TextButton", frame)
    buyBtn.Size = UDim2.new(0.25,-5,1,-4)
    buyBtn.Position = UDim2.new(0.5,0,0,2)
    buyBtn.BackgroundColor3 = Color3.fromRGB(70,120,70)
    buyBtn.Text = "Buy"
    buyBtn.TextColor3 = Color3.new(1,1,1)
    buyBtn.Font = Enum.Font.GothamBold
    buyBtn.TextSize = 13
    buyBtn.MouseButton1Click:Connect(function()
        pcall(function() BuySeedRemote:FireServer("Tier 1",seedName) end)
    end)

    local toggleBtn = Instance.new("TextButton", frame)
    toggleBtn.Size = UDim2.new(0.25,-5,1,-4)
    toggleBtn.Position = UDim2.new(0.75,0,0,2)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(100,100,100)
    toggleBtn.TextColor3 = Color3.new(1,1,1)
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.TextSize = 13

    SeedSettings[seedName] = SeedSettings[seedName] or false
    local function updateToggle()
        if SeedSettings[seedName] then
            toggleBtn.BackgroundColor3 = Color3.fromRGB(70,170,70)
            toggleBtn.Text = "ON"
            task.spawn(function()
                while SeedSettings[seedName] do
                    pcall(function() BuySeedRemote:FireServer("Tier 1",seedName) end)
                    task.wait(0.2)
                end
            end)
        else
            toggleBtn.BackgroundColor3 = Color3.fromRGB(100,100,100)
            toggleBtn.Text = "OFF"
        end
    end
    updateToggle()

    toggleBtn.MouseButton1Click:Connect(function()
        SeedSettings[seedName] = not SeedSettings[seedName]
        updateToggle()
    end)
end

for _, name in ipairs(seedNames) do
    createSeedButton(name)
end

-- ===== Gear Frame =====
local gearShop = playerGui:WaitForChild("Gear_Shop")
local gearScrolling = gearShop.Frame.ScrollingFrame

local gearFrame = Instance.new("Frame", contentFrame)
gearFrame.Size = UDim2.new(1,0,1,0)
gearFrame.BackgroundTransparency = 1
gearFrame.Visible = false

local gearScroll = Instance.new("ScrollingFrame", gearFrame)
gearScroll.Size = UDim2.new(1,-10,1,0)
gearScroll.Position = UDim2.new(0,5,0,0)
gearScroll.BackgroundTransparency = 1
gearScroll.ScrollBarThickness = 6

local gearLayout = Instance.new("UIListLayout", gearScroll)
gearLayout.Padding = UDim.new(0,5)
gearLayout.SortOrder = Enum.SortOrder.LayoutOrder
gearLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    gearScroll.CanvasSize = UDim2.new(0,0,0,gearLayout.AbsoluteContentSize.Y + 5)
end)

-- Ambil data gear
local gearNames = {}
local lookupG = {}
for _, g in pairs(gearScrolling:GetChildren()) do
    if g:IsA("Frame") then
        local name = g.Name
        if not name:lower():find("_padding") and not lookupG[name:lower()] then
            table.insert(gearNames,name)
            lookupG[name:lower()] = true
        end
    end
end
table.sort(gearNames,function(a,b) return a:lower()<b:lower() end)

-- Persistent config
getgenv().AutoBuyConfig.Gear = getgenv().AutoBuyConfig.Gear or {}
local GearSettings = getgenv().AutoBuyConfig.Gear

local function createGearButton(gearName)
    local frame = Instance.new("Frame", gearScroll)
    frame.Size = UDim2.new(1,-5,0,35)
    frame.BackgroundColor3 = Color3.fromRGB(40,40,40)
    frame.BorderSizePixel = 0

    local label = Instance.new("TextLabel", frame)
    label.Size = UDim2.new(0.5,-5,1,0)
    label.Position = UDim2.new(0,5,0,0)
    label.BackgroundTransparency = 1
    label.Text = gearName
    label.TextColor3 = Color3.new(1,1,1)
    label.Font = Enum.Font.Gotham
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left

    local buyBtn = Instance.new("TextButton", frame)
    buyBtn.Size = UDim2.new(0.25,-5,1,-4)
    buyBtn.Position = UDim2.new(0.5,0,0,2)
    buyBtn.BackgroundColor3 = Color3.fromRGB(70,120,70)
    buyBtn.Text = "Buy"
    buyBtn.TextColor3 = Color3.new(1,1,1)
    buyBtn.Font = Enum.Font.GothamBold
    buyBtn.TextSize = 13
    buyBtn.MouseButton1Click:Connect(function()
        pcall(function() BuyGearRemote:FireServer(gearName) end)
    end)

    local toggleBtn = Instance.new("TextButton", frame)
    toggleBtn.Size = UDim2.new(0.25,-5,1,-4)
    toggleBtn.Position = UDim2.new(0.75,0,0,2)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(100,100,100)
    toggleBtn.TextColor3 = Color3.new(1,1,1)
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.TextSize = 13

    GearSettings[gearName] = GearSettings[gearName] or false
    local function updateToggle()
        if GearSettings[gearName] then
            toggleBtn.BackgroundColor3 = Color3.fromRGB(70,170,70)
            toggleBtn.Text = "ON"
            task.spawn(function()
                while GearSettings[gearName] do
                    pcall(function() BuyGearRemote:FireServer(gearName) end)
                    task.wait(0.2)
                end
            end)
        else
            toggleBtn.BackgroundColor3 = Color3.fromRGB(100,100,100)
            toggleBtn.Text = "OFF"
        end
    end
    updateToggle()

    toggleBtn.MouseButton1Click:Connect(function()
        GearSettings[gearName] = not GearSettings[gearName]
        updateToggle()
    end)
end

for _, name in ipairs(gearNames) do
    createGearButton(name)
end

-- ===== Pet Frame =====
local petShop = playerGui:WaitForChild("PetShop_UI")
local petScrolling = petShop.Frame.ScrollingFrame

local petFrame = Instance.new("Frame", contentFrame)
petFrame.Size = UDim2.new(1,0,1,0)
petFrame.BackgroundTransparency = 1
petFrame.Visible = false

local petScroll = Instance.new("ScrollingFrame", petFrame)
petScroll.Size = UDim2.new(1,-10,1,0)
petScroll.Position = UDim2.new(0,5,0,0)
petScroll.BackgroundTransparency = 1
petScroll.ScrollBarThickness = 6

local petLayout = Instance.new("UIListLayout", petScroll)
petLayout.Padding = UDim.new(0,5)
petLayout.SortOrder = Enum.SortOrder.LayoutOrder
petLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    petScroll.CanvasSize = UDim2.new(0,0,0,petLayout.AbsoluteContentSize.Y + 5)
end)

-- Ambil data pet
local petNames = {}
local lookupP = {}
for _, p in pairs(petScrolling:GetChildren()) do
    if p:IsA("Frame") then
        local name = p.Name
        if not name:lower():find("_padding") and not lookupP[name:lower()] then
            table.insert(petNames,name)
            lookupP[name:lower()] = true
        end
    end
end
table.sort(petNames,function(a,b) return a:lower()<b:lower() end)

-- Persistent config
getgenv().AutoBuyConfig.Pet = getgenv().AutoBuyConfig.Pet or {}
local PetSettings = getgenv().AutoBuyConfig.Pet

-- Fungsi tombol pet
local function createPetButton(petName)
    local frame = Instance.new("Frame", petScroll)
    frame.Size = UDim2.new(1,-5,0,35)
    frame.BackgroundColor3 = Color3.fromRGB(40,40,40)
    frame.BorderSizePixel = 0

    local label = Instance.new("TextLabel", frame)
    label.Size = UDim2.new(0.5,-5,1,0)
    label.Position = UDim2.new(0,5,0,0)
    label.BackgroundTransparency = 1
    label.Text = petName
    label.TextColor3 = Color3.new(1,1,1)
    label.Font = Enum.Font.Gotham
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left

    local buyBtn = Instance.new("TextButton", frame)
    buyBtn.Size = UDim2.new(0.25,-5,1,-4)
    buyBtn.Position = UDim2.new(0.5,0,0,2)
    buyBtn.BackgroundColor3 = Color3.fromRGB(70,120,70)
    buyBtn.Text = "Buy"
    buyBtn.TextColor3 = Color3.new(1,1,1)
    buyBtn.Font = Enum.Font.GothamBold
    buyBtn.TextSize = 13
    buyBtn.MouseButton1Click:Connect(function()
        pcall(function() BuyPetRemote:FireServer(petName) end)
    end)

    local toggleBtn = Instance.new("TextButton", frame)
    toggleBtn.Size = UDim2.new(0.25,-5,1,-4)
    toggleBtn.Position = UDim2.new(0.75,0,0,2)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(100,100,100)
    toggleBtn.TextColor3 = Color3.new(1,1,1)
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.TextSize = 13

    PetSettings[petName] = PetSettings[petName] or false
    local function updateToggle()
        if PetSettings[petName] then
            toggleBtn.BackgroundColor3 = Color3.fromRGB(70,170,70)
            toggleBtn.Text = "ON"
            task.spawn(function()
                while PetSettings[petName] do
                    pcall(function() BuyPetRemote:FireServer(petName) end)
                    task.wait(0.2)
                end
            end)
        else
            toggleBtn.BackgroundColor3 = Color3.fromRGB(100,100,100)
            toggleBtn.Text = "OFF"
        end
    end
    updateToggle()

    toggleBtn.MouseButton1Click:Connect(function()
        PetSettings[petName] = not PetSettings[petName]
        updateToggle()
    end)
end

for _, name in ipairs(petNames) do
    createPetButton(name)
end

-- Tab toggle function
local function showTab(tab)
    seedFrame.Visible = tab == "Seed"
    gearFrame.Visible = tab == "Gear"
    petFrame.Visible = tab == "Pet"
end

seedTabBtn.MouseButton1Click:Connect(function() showTab("Seed") end)
gearTabBtn.MouseButton1Click:Connect(function() showTab("Gear") end)
petTabBtn.MouseButton1Click:Connect(function() showTab("Pet") end)

-- ===== Floating Minimize Button =====
local floatBtn = Instance.new("TextButton", playerGui)
floatBtn.Size = UDim2.new(0,40,0,40)
floatBtn.Position = UDim2.new(0, 20, 0.5, -20)
floatBtn.BackgroundColor3 = Color3.fromRGB(50,50,150)
floatBtn.Text = "-"
floatBtn.TextColor3 = Color3.new(1,1,1)
floatBtn.Font = Enum.Font.GothamBold
floatBtn.TextSize = 24
floatBtn.ZIndex = 10
floatBtn.AutoButtonColor = true

local minimized = false
local normalSize = mainFrame.Size
local normalPos = mainFrame.Position

local function toggleMinimize()
    minimized = not minimized
    mainFrame.Visible = not minimized
    minimizeBtn.Text = minimized and "+" or "-"
end

floatBtn.MouseButton1Click:Connect(toggleMinimize)
minimizeBtn.MouseButton1Click:Connect(toggleMinimize)

print("✅ Main Menu + Seed/Gear/Pet Auto-Buy + Minimize ✅")
