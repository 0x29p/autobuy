-- ========== TELEPORT GUI 
local Players = game:GetService("Players")
local plr = Players.LocalPlayer

-- hapus GUI lama biar gak dobel kalau execute ulang
local guiParent = (GuiParent) or (plr:FindFirstChild("PlayerGui")) or game:GetService("CoreGui")
local old = guiParent:FindFirstChild("TeleportGUI")
if old then old:Destroy() end

-- buat ScreenGui baru
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "TeleportGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = guiParent

-- daftar lokasi teleport (urut sesuai permintaan)
local LocationCFrames = {
    MID      = CFrame.new(-97.25802612304688, 2.3972654342651367, -11.649102210998535),
    GearShop = CFrame.new(-284.899597, 2.9828338, -13.9281559),
    PetShop  = CFrame.new(-283.82830810546875, 3, -1.4449647665023804), -- update posisi baru
    Mutasi   = CFrame.new(-285.30731201171875, 3, 8.226550102233887),
    Ascend   = CFrame.new(123.45048522949219, 3.2272911071777344, 165.5633087158203),
}

-- ukuran & posisi tombol compact
local BUTTON_WIDTH_SCALE  = 0.075   -- agak ramping (7.5% lebar layar)
local BUTTON_HEIGHT_SCALE = 0.035   -- agak kecil (3.5% tinggi layar)
local START_Y_SCALE       = 0.12    -- lebih naik (biar gak tabrakan sama tombol Shop)
local GAP_Y_SCALE         = 0.048   -- jarak antar tombol
local BUTTON_X            = 0.005   -- geser lebih kiri (lebih rapat ke tepi layar)

-- fungsi buat tombol dengan warna custom
local function createButton(name, cframe, order)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(BUTTON_WIDTH_SCALE, 0, BUTTON_HEIGHT_SCALE, 0)
    button.AnchorPoint = Vector2.new(0, 0)
    button.Position = UDim2.new(BUTTON_X, 0, START_Y_SCALE + (order-1) * GAP_Y_SCALE, 0)

    -- default warna
    local bgColor = Color3.fromRGB(0, 170, 255) -- biru
    local textColor = Color3.fromRGB(255, 255, 255)

    -- warna khusus per tombol
    if name:lower():find("gear") then
        bgColor = Color3.fromRGB(0, 200, 0)      -- hijau
    elseif name:lower():find("pet") then
        bgColor = Color3.fromRGB(255, 200, 0)    -- kuning
        textColor = Color3.fromRGB(0, 0, 0)      -- hitam biar jelas
    elseif name:lower():find("mutasi") then
        bgColor = Color3.fromRGB(160, 60, 255)   -- ungu
    elseif name:lower():find("ascend") then
        bgColor = Color3.fromRGB(0, 200, 0)      -- hijau
        textColor = Color3.fromRGB(255, 255, 0)  -- tulisan kuning
    end

    button.BackgroundColor3 = bgColor
    button.BorderSizePixel = 0
    button.TextColor3 = textColor
    button.Text = name
    button.Font = Enum.Font.SourceSansBold
    button.TextScaled = true
    button.ZIndex = 10
    button.Parent = screenGui

    button.MouseButton1Click:Connect(function()
        local char = plr.Character or plr.CharacterAdded:Wait()
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.CFrame = cframe
        end
    end)
end

-- generate tombol sesuai urutan tabel
local i = 1
for name, cframe in pairs(LocationCFrames) do
    createButton(name, cframe, i)
    i += 1
end
