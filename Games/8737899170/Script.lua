--[[
    Pet Simulator 99 - Flower Garden Auto Farm, Slot ESP & AutoCollect
    GUI Library: Rayfield Gen2 (NextGen) - https://sirius.menu/gen2
    Target PlaceId: 8737899170 (Flower Garden Event)
]]

-- Zabezpieczenie przed podwójnym uruchomieniem
if _G.PS99GardenRunning and _G.PS99GardenCleanup then
    pcall(_G.PS99GardenCleanup)
end
_G.PS99GardenRunning = true

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

-- Odnalezienie Remote'ów sieciowych FlowerGarden
local Network = ReplicatedStorage:WaitForChild("Network", 10)
local InvokeCustom = Network and Network:WaitForChild("Instancing_InvokeCustomFromClient", 10)
local FireCustom = Network and Network:WaitForChild("Instancing_FireCustomFromClient", 10)
local ClickRemote = Network and Network:FindFirstChild("Click")

local ClientNetwork = nil
pcall(function()
    if ReplicatedStorage:FindFirstChild("Library") then
        local client = ReplicatedStorage.Library:FindFirstChild("Client")
        if client and client:FindFirstChild("Network") then
            ClientNetwork = require(client.Network)
        end
    end
end)

if not InvokeCustom or not FireCustom then
    warn("[PS99 Garden] Ostrzeżenie: Nie znaleziono niektórych Remote'ów Instancing!")
end

--------------------------------------------------------------------------------
-- STAN I KONFIGURACJA
--------------------------------------------------------------------------------
local Config = {
    -- Auto Farm
    AutoFarmEnabled = false,
    AutoPlant = true,
    AutoInstaGrow = true,
    AutoWater = false,
    AutoClaim = true,
    AutoCapsuleClick = true,
    SeedType = "Diamond",
    CustomSeed = "",
    ActionDelay = 0.25,
    LoopDelay = 1.0,
    FarmSlots = {
        ["1"] = true, ["2"] = true, ["3"] = true, ["4"] = true, ["5"] = true
    },

    -- ESP (Domyślnie wyłączone)
    ESPEnabled = false,
    ESPMode = "Tylko Farmiące", -- Opcje: "Tylko Farmiące", "Wszystkie (1-20)", "Wybrane Numery"
    ESPSlots = {
        ["1"] = true, ["2"] = true, ["3"] = true, ["4"] = true, ["5"] = true,
        ["6"] = true, ["7"] = true, ["8"] = true, ["9"] = true, ["10"] = true
    },
    ESPShowStatus = true,
    ESPShowDistance = true,
    ESPShowHighlight = true,

    -- Statystyki
    Stats = {
        Planted = 0,
        Grown = 0,
        Harvested = 0
    }
}

local AllSlotOptions = {}
for i = 1, 20 do
    table.insert(AllSlotOptions, tostring(i))
end

--------------------------------------------------------------------------------
-- FUNKCJE POMOCNICZE LOKALIZACJI
--------------------------------------------------------------------------------
local function getThingsFolder()
    return Workspace:FindFirstChild("__THINGS")
end

local cachedPlantsFolder = nil
local lastPlantsCheck = 0

local function getPlantsFolder()
    local now = os.clock()
    if cachedPlantsFolder and cachedPlantsFolder.Parent then
        return cachedPlantsFolder
    end
    if now - lastPlantsCheck < 1 then
        return cachedPlantsFolder
    end
    lastPlantsCheck = now

    local things = getThingsFolder()
    if things then
        local container = things:FindFirstChild("__INSTANCE_CONTAINER")
        if container then
            local active = container:FindFirstChild("Active")
            if active then
                local garden = active:FindFirstChild("FlowerGarden")
                if garden then
                    local plants = garden:FindFirstChild("Plants")
                    if plants then
                        cachedPlantsFolder = plants
                        return plants
                    end
                end
            end
        end
    end

    cachedPlantsFolder = nil
    return nil
end

local function getFlowerGardenContainer()
    local things = getThingsFolder()
    if things then
        local container = things:FindFirstChild("__INSTANCE_CONTAINER")
        if container then
            local active = container:FindFirstChild("Active")
            if active and active:FindFirstChild("FlowerGarden") then
                return active.FlowerGarden
            end
        end
    end
    return nil
end

local function getPlotInstance(slotNum)
    local plantsFolder = getPlantsFolder()
    if not plantsFolder then return nil end
    return plantsFolder:FindFirstChild("Plant" .. tostring(slotNum))
end

local function getPlotBasePart(plotInstance)
    if not plotInstance then return nil end
    if plotInstance:IsA("BasePart") then return plotInstance end
    if plotInstance.PrimaryPart then return plotInstance.PrimaryPart end

    local part = plotInstance:FindFirstChild("Part")
    if part and part:IsA("BasePart") then return part end

    return plotInstance:FindFirstChildWhichIsA("BasePart", true)
end

local function checkPlotStatus(plotInstance)
    if not plotInstance then
        return "Nieznaleziona", Color3.fromRGB(150, 150, 150)
    end

    if plotInstance:FindFirstChild("Stage3") or plotInstance:FindFirstChild("Stage4") then
        return "Gotowa do Zbioru!", Color3.fromRGB(50, 255, 100)
    elseif plotInstance:FindFirstChild("Stage1") or plotInstance:FindFirstChild("Stage2") then
        return "Rośnie...", Color3.fromRGB(255, 200, 50)
    end

    for _, child in ipairs(plotInstance:GetChildren()) do
        if child.Name:find("Stage") or child.Name:find("Mesh") or child.Name:find("Seed") then
            return "Rośnie / Zasadzone", Color3.fromRGB(255, 180, 50)
        end
    end

    return "Pusta (Gotowa)", Color3.fromRGB(80, 200, 255)
end

--------------------------------------------------------------------------------
-- POBIERANIE WODY Z KAPSUŁY (COBALT CLICK REMOTE)
--------------------------------------------------------------------------------
local CapsuleHitPos = Vector3.new(-437.83212280273438, 109.46415710449219, -1421.351318359375)
local CapsuleRay = Ray.new(
    Vector3.new(-455.88748168945312, 128.20892333984375, -1396.1763916015625),
    Vector3.new(0.4934602677822113, -0.57543015480041504, -0.65220928192138672)
)

local function clickWorldPosition(targetPos, customRay, targetInst)
    if not targetPos then return end

    local cRay = customRay
    if not cRay then
        local cam = Workspace.CurrentCamera
        local origin = cam and cam.CFrame and cam.CFrame.Position
        if not origin then
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            origin = hrp and (hrp.Position + Vector3.new(0, 2.5, 0)) or (targetPos + Vector3.new(0, 10, 0))
        end
        local diff = (targetPos - origin)
        local dirUnit = diff.Magnitude > 0.001 and diff.Unit or Vector3.new(0, -1, 0)
        cRay = Ray.new(origin, dirUnit)
    end

    -- 1. Client Network (dokładnie jak w dekompilacie gry)
    if ClientNetwork and typeof(ClientNetwork.Fire) == "function" then
        pcall(function() ClientNetwork.Fire("Click", cRay, targetPos) end)
    end

    -- 2. Network.Click RemoteEvent
    if ClickRemote and ClickRemote:IsA("RemoteEvent") then
        pcall(function() ClickRemote:FireServer(cRay, targetPos) end)
    end

    -- 3. Aktywacja ewentualnych ProximityPrompts
    if targetInst and typeof(targetInst) == "Instance" then
        for _, prompt in ipairs(targetInst:GetDescendants()) do
            if prompt:IsA("ProximityPrompt") then
                pcall(function()
                    if typeof(fireproximityprompt) == "function" then
                        fireproximityprompt(prompt)
                    end
                end)
            end
        end
    end
end

local function clickCapsule()
    -- 1. Pakiet dokładnie z Cobalt logu
    clickWorldPosition(CapsuleHitPos, CapsuleRay)

    -- 2. Promień z dynamicznej kamery
    clickWorldPosition(CapsuleHitPos, nil)

    -- 3. Wykrycie instancji kapsuły w Workspace
    local fg = getFlowerGardenContainer()
    local inc = fg and fg:FindFirstChild("Interactable") and fg.Interactable:FindFirstChild("InstaPlantIncubator")
    if inc then
        local cap = inc:FindFirstChild("capsule") or inc:FindFirstChild("Union")
        if cap and cap:IsA("BasePart") then
            clickWorldPosition(cap.Position, nil, cap)
        end
    end

    -- 4. Zdarzenia sieciowe FlowerGarden
    if InvokeCustom then
        pcall(function() InvokeCustom:InvokeServer("FlowerGarden", "UseIncubator") end)
        pcall(function() InvokeCustom:InvokeServer("FlowerGarden", "CollectWater") end)
    end
end

--------------------------------------------------------------------------------
-- SYSTEM ESP (BILLBOARD + HIGHLIGHT)
--------------------------------------------------------------------------------
local ESPObjects = {}
local ESPContainer = Instance.new("Folder")
ESPContainer.Name = "PS99_Garden_ESP_V3"
pcall(function()
    ESPContainer.Parent = CoreGui
end)
if not ESPContainer.Parent then
    ESPContainer.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

local function createPlotESP(slotNum)
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "PlotESP_" .. slotNum
    billboard.Size = UDim2.new(0, 160, 0, 55)
    billboard.StudsOffset = Vector3.new(0, 4.5, 0)
    billboard.AlwaysOnTop = true
    billboard.ResetOnSpawn = false
    billboard.Enabled = false
    billboard.Parent = ESPContainer

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundColor3 = Color3.fromRGB(15, 20, 30)
    frame.BackgroundTransparency = 0.35
    frame.BorderSizePixel = 0
    frame.Parent = billboard

    local uiCorner = Instance.new("UICorner")
    uiCorner.CornerRadius = UDim.new(0, 8)
    uiCorner.Parent = frame

    local uiStroke = Instance.new("UIStroke")
    uiStroke.Color = Color3.fromRGB(0, 200, 255)
    uiStroke.Thickness = 1.5
    uiStroke.Parent = frame

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, 0, 0.45, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 14
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.Text = "🌸 DZIAŁKA #" .. slotNum
    titleLabel.Parent = frame

    local statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "Status"
    statusLabel.Position = UDim2.new(0, 0, 0.45, 0)
    statusLabel.Size = UDim2.new(1, 0, 0.3, 0)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Font = Enum.Font.GothamMedium
    statusLabel.TextSize = 11
    statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    statusLabel.Text = "Status: Sprawdzanie..."
    statusLabel.Parent = frame

    local distLabel = Instance.new("TextLabel")
    distLabel.Name = "Distance"
    distLabel.Position = UDim2.new(0, 0, 0.75, 0)
    distLabel.Size = UDim2.new(1, 0, 0.25, 0)
    distLabel.BackgroundTransparency = 1
    distLabel.Font = Enum.Font.Gotham
    distLabel.TextSize = 10
    distLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
    distLabel.Text = "0 studs"
    distLabel.Parent = frame

    local highlight = Instance.new("Highlight")
    highlight.Name = "Highlight_" .. slotNum
    highlight.FillColor = Color3.fromRGB(0, 200, 255)
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = 0.7
    highlight.OutlineTransparency = 0.2
    highlight.Enabled = false
    highlight.Parent = nil

    ESPObjects[slotNum] = {
        Billboard = billboard,
        Highlight = highlight,
        Frame = frame,
        Stroke = uiStroke,
        TitleLabel = titleLabel,
        StatusLabel = statusLabel,
        DistLabel = distLabel
    }
end

for i = 1, 20 do
    createPlotESP(i)
end

local function isSlotActiveForESP(slotNum)
    local slotStr = tostring(slotNum)
    if Config.ESPMode == "Wszystkie (1-20)" then
        return true
    elseif Config.ESPMode == "Tylko Farmiące" then
        return Config.FarmSlots[slotStr] == true
    elseif Config.ESPMode == "Wybrane Numery" then
        return Config.ESPSlots[slotStr] == true
    end
    return false
end

local ESPUpdateConnection = RunService.RenderStepped:Connect(function()
    if not Config.ESPEnabled then
        for _, esp in pairs(ESPObjects) do
            if esp.Billboard.Enabled then
                esp.Billboard.Enabled = false
                esp.Billboard.Adornee = nil
            end
            if esp.Highlight.Enabled then
                esp.Highlight.Enabled = false
                esp.Highlight.Adornee = nil
                esp.Highlight.Parent = nil
            end
        end
        return
    end

    local myChar = LocalPlayer.Character
    local myRoot = myChar and (myChar:FindFirstChild("HumanoidRootPart") or myChar.PrimaryPart)
    local myPos = myRoot and myRoot.Position

    for slotNum = 1, 20 do
        local esp = ESPObjects[slotNum]
        if esp then
            local shouldShow = isSlotActiveForESP(slotNum)

            if shouldShow then
                local plot = getPlotInstance(slotNum)
                local part = getPlotBasePart(plot)

                if plot and part then
                    esp.Billboard.Adornee = part
                    esp.Billboard.Enabled = true

                    local statusText, statusColor = checkPlotStatus(plot)
                    esp.StatusLabel.Text = Config.ESPShowStatus and ("• " .. statusText) or ""
                    esp.StatusLabel.TextColor3 = statusColor
                    esp.Stroke.Color = statusColor

                    if Config.ESPShowDistance and myPos then
                        local dist = math.floor((part.Position - myPos).Magnitude)
                        esp.DistLabel.Text = dist .. " studs"
                        esp.DistLabel.Visible = true
                    else
                        esp.DistLabel.Visible = false
                    end

                    if Config.ESPShowHighlight then
                        esp.Highlight.Adornee = plot
                        esp.Highlight.FillColor = statusColor
                        esp.Highlight.Parent = ESPContainer
                        esp.Highlight.Enabled = true
                    else
                        esp.Highlight.Enabled = false
                        esp.Highlight.Adornee = nil
                        esp.Highlight.Parent = nil
                    end
                else
                    esp.Billboard.Enabled = false
                    esp.Billboard.Adornee = nil
                    esp.Highlight.Enabled = false
                    esp.Highlight.Adornee = nil
                    esp.Highlight.Parent = nil
                end
            else
                esp.Billboard.Enabled = false
                esp.Billboard.Adornee = nil
                esp.Highlight.Enabled = false
                esp.Highlight.Adornee = nil
                esp.Highlight.Parent = nil
            end
        end
    end
end)

--------------------------------------------------------------------------------
-- PĘTLA AUTO FARM
--------------------------------------------------------------------------------
local function getActiveSeedName()
    if Config.CustomSeed and Config.CustomSeed:gsub("%s+", "") ~= "" then
        return Config.CustomSeed:gsub("%s+", "")
    end
    return Config.SeedType or "Diamond"
end

local function getSortedFarmSlots()
    local slots = {}
    for slotStr, enabled in pairs(Config.FarmSlots) do
        if enabled then
            local num = tonumber(slotStr)
            if num then
                table.insert(slots, num)
            end
        end
    end
    table.sort(slots)
    return slots
end

task.spawn(function()
    while _G.PS99GardenRunning do
        if Config.AutoFarmEnabled then
            local slotsToFarm = getSortedFarmSlots()
            local seed = getActiveSeedName()

            for _, slotNum in ipairs(slotsToFarm) do
                if not Config.AutoFarmEnabled then break end

                -- 1. Auto Plant
                if Config.AutoPlant and InvokeCustom then
                    pcall(function()
                        InvokeCustom:InvokeServer("FlowerGarden", "PlantSeed", slotNum, seed)
                        Config.Stats.Planted = Config.Stats.Planted + 1
                    end)
                    task.wait(Config.ActionDelay)
                end

                -- 2. Auto Insta Grow (Wzrost + Klik w Kapsułę Wody)
                if Config.AutoInstaGrow then
                    -- Pobranie wody z kapsuły
                    if Config.AutoCapsuleClick then
                        pcall(clickCapsule)
                        task.wait(0.04)
                    end

                    -- Wywołanie InstaGrowSeed z serwera
                    if InvokeCustom then
                        pcall(function()
                            InvokeCustom:InvokeServer("FlowerGarden", "InstaGrowSeed", slotNum)
                            Config.Stats.Grown = Config.Stats.Grown + 1
                        end)
                    end

                    -- Aplikacja wody / kliknięcie w donicę
                    local plot = getPlotInstance(slotNum)
                    local plotPart = getPlotBasePart(plot)
                    if plotPart then
                        clickWorldPosition(plotPart.Position, nil, plot)
                    end

                    task.wait(Config.ActionDelay)
                end

                -- 2b. Auto Water (Podlewanie nasiona)
                if Config.AutoWater and InvokeCustom then
                    pcall(function()
                        InvokeCustom:InvokeServer("FlowerGarden", "WaterSeed", slotNum)
                    end)
                    local plot = getPlotInstance(slotNum)
                    local plotPart = getPlotBasePart(plot)
                    if plotPart then
                        clickWorldPosition(plotPart.Position, nil, plot)
                    end
                    task.wait(Config.ActionDelay)
                end

                -- 3. Auto Claim (Zbiór plonu)
                if Config.AutoClaim and FireCustom then
                    pcall(function()
                        FireCustom:FireServer("FlowerGarden", "ClaimPlant", slotNum)
                        Config.Stats.Harvested = Config.Stats.Harvested + 1
                    end)
                    task.wait(Config.ActionDelay)
                end
            end
        end
        task.wait(Config.LoopDelay)
    end
end)

--------------------------------------------------------------------------------
-- ANTI-AFK
--------------------------------------------------------------------------------
local AntiAFKConnection = LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

--------------------------------------------------------------------------------
-- INTERFEJS RAYFIELD GEN2
--------------------------------------------------------------------------------
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/gen2"))()

local function sendNotification(title, content, duration)
    pcall(function()
        Rayfield:Notify({
            name = title,
            title = title,
            Title = title,
            content = content,
            Content = content,
            duration = duration or 3.5,
            Duration = duration or 3.5
        })
    end)
end

local window = Rayfield:CreateWindow({
    name = "PS99 | Flower Garden Auto",
    subtitle = "Rayfield Gen2 (Garden Event)",
    sidebarLayout = true,
    configuration = {
        autoSave = false,
        autoLoad = false
    }
})

--------------------------------------------------------------------------------
-- ZAKŁADKA 1: AUTO FARM
--------------------------------------------------------------------------------
local tabFarm = window:CreateTab({
    name = "Auto Farm",
    icon = 93364949241311
})

tabFarm:CreateSection({ name = "Główne Sterowanie Farmą" })

tabFarm:CreateToggle({
    name = "Włącz Auto Farm",
    currentValue = Config.AutoFarmEnabled,
    flag = "Toggle_AutoFarm",
    callback = function(value)
        Config.AutoFarmEnabled = value
        if value then
            sendNotification("Auto Farm", "Rozpoczęto automatyczne farmienie!", 2.5)
        end
    end
})

tabFarm:CreateDropdown({
    name = "Wybierz Działki do Farmy (Sloty)",
    options = AllSlotOptions,
    currentOption = {"1", "2", "3", "4", "5"},
    multipleOptions = true,
    flag = "Dropdown_FarmSlots",
    callback = function(options)
        Config.FarmSlots = {}
        if type(options) == "table" then
            for _, slot in ipairs(options) do
                Config.FarmSlots[tostring(slot)] = true
            end
        else
            Config.FarmSlots[tostring(options)] = true
        end
    end
})

tabFarm:CreateInput({
    name = "Wpisz Numery Działek do Farmy (np. 1, 2, 5)",
    placeholderText = "Wpisz po przecinku, np. 1, 2, 5, 8",
    flag = "Input_FarmSlots",
    callback = function(text)
        if text and text:gsub("%s+", "") ~= "" then
            Config.FarmSlots = {}
            for numStr in text:gmatch("%d+") do
                local n = tonumber(numStr)
                if n and n >= 1 and n <= 20 then
                    Config.FarmSlots[tostring(n)] = true
                end
            end
            sendNotification("Sloty Farmy", "Zaktualizowano wybrane działki!", 2)
        end
    end
})

tabFarm:CreateDropdown({
    name = "Typ Nasiona (Seed)",
    options = {"Diamond", "Coin", "Gift", "Potion", "Enchant"},
    currentOption = "Diamond",
    multipleOptions = false,
    flag = "Dropdown_SeedType",
    callback = function(option)
        if type(option) == "table" then
            Config.SeedType = option[1] or "Diamond"
        else
            Config.SeedType = tostring(option)
        end
    end
})

tabFarm:CreateInput({
    name = "Własna Nazwa Nasiona",
    placeholderText = "Wpisz nazwę (np. Diamond)...",
    flag = "Input_CustomSeed",
    callback = function(text)
        Config.CustomSeed = text
    end
})

tabFarm:CreateSection({ name = "Kroki w Pętli Farmy" })

tabFarm:CreateToggle({
    name = "Krok 1: Auto Plant (Sadzenie)",
    currentValue = Config.AutoPlant,
    flag = "Toggle_AutoPlant",
    callback = function(value)
        Config.AutoPlant = value
    end
})

tabFarm:CreateToggle({
    name = "Krok 2: Auto Insta-Grow (Wzrost & Kapsuła)",
    currentValue = Config.AutoInstaGrow,
    flag = "Toggle_AutoInstaGrow",
    callback = function(value)
        Config.AutoInstaGrow = value
    end
})

tabFarm:CreateToggle({
    name = "Pobieraj Wodę z Kapsuły (Click Capsule)",
    currentValue = Config.AutoCapsuleClick,
    flag = "Toggle_AutoCapsuleClick",
    callback = function(value)
        Config.AutoCapsuleClick = value
    end
})

tabFarm:CreateToggle({
    name = "Krok 2b: Auto Water (Podlewanie konewką)",
    currentValue = Config.AutoWater,
    flag = "Toggle_AutoWater",
    callback = function(value)
        Config.AutoWater = value
    end
})

tabFarm:CreateToggle({
    name = "Krok 3: Auto Claim (Zbieranie Plonów)",
    currentValue = Config.AutoClaim,
    flag = "Toggle_AutoClaim",
    callback = function(value)
        Config.AutoClaim = value
    end
})

tabFarm:CreateSection({ name = "Opóźnienia" })

tabFarm:CreateSlider({
    name = "Opóźnienie akcji",
    range = {0.05, 1.0},
    increment = 0.05,
    suffix = "s",
    currentValue = Config.ActionDelay,
    flag = "Slider_ActionDelay",
    callback = function(value)
        Config.ActionDelay = value
    end
})

tabFarm:CreateSlider({
    name = "Pauza między pętlami",
    range = {0.2, 5.0},
    increment = 0.2,
    suffix = "s",
    currentValue = Config.LoopDelay,
    flag = "Slider_LoopDelay",
    callback = function(value)
        Config.LoopDelay = value
    end
})

--------------------------------------------------------------------------------
-- ZAKŁADKA 2: ESP DZIAŁEK
--------------------------------------------------------------------------------
local tabESP = window:CreateTab({
    name = "ESP Działek",
    icon = 93364949241311
})

tabESP:CreateSection({ name = "Główne Sterowanie ESP" })

tabESP:CreateToggle({
    name = "Włącz ESP Działek",
    currentValue = false,
    flag = "Toggle_ESPEnabled",
    callback = function(value)
        Config.ESPEnabled = value
    end
})

tabESP:CreateDropdown({
    name = "Tryb Wyświetlania ESP",
    options = {"Tylko Farmiące", "Wszystkie (1-20)", "Wybrane Numery"},
    currentOption = "Tylko Farmiące",
    multipleOptions = false,
    flag = "Dropdown_ESPMode",
    callback = function(option)
        local val = type(option) == "table" and option[1] or tostring(option)
        Config.ESPMode = val
        sendNotification("Tryb ESP", "Ustawiono: " .. val, 2)
    end
})

tabESP:CreateDropdown({
    name = "Wybierz Numery Działek (Dla trybu 'Wybrane Numery')",
    options = AllSlotOptions,
    currentOption = {"1", "2", "3", "4", "5", "6", "7", "8", "9", "10"},
    multipleOptions = true,
    flag = "Dropdown_ESPSlots",
    callback = function(options)
        Config.ESPSlots = {}
        if type(options) == "table" then
            for _, slot in ipairs(options) do
                Config.ESPSlots[tostring(slot)] = true
            end
        else
            Config.ESPSlots[tostring(options)] = true
        end
    end
})

tabESP:CreateInput({
    name = "Wpisz Numery Działek ESP (np. 1, 2, 5)",
    placeholderText = "Wpisz numery, np. 1, 2, 3, 5, 8",
    flag = "Input_ESPSlots",
    callback = function(text)
        if text and text:gsub("%s+", "") ~= "" then
            Config.ESPSlots = {}
            for numStr in text:gmatch("%d+") do
                local n = tonumber(numStr)
                if n and n >= 1 and n <= 20 then
                    Config.ESPSlots[tostring(n)] = true
                end
            end
            sendNotification("ESP Sloty", "Zaktualizowano numery ESP!", 2)
        end
    end
})

tabESP:CreateSection({ name = "Elementy Wizualne ESP" })

tabESP:CreateToggle({
    name = "Pokaż Status (Pusta / Rośnie / Gotowa)",
    currentValue = Config.ESPShowStatus,
    flag = "Toggle_ESPShowStatus",
    callback = function(value)
        Config.ESPShowStatus = value
    end
})

tabESP:CreateToggle({
    name = "Pokaż Odległość (Studs)",
    currentValue = Config.ESPShowDistance,
    flag = "Toggle_ESPShowDistance",
    callback = function(value)
        Config.ESPShowDistance = value
    end
})

tabESP:CreateToggle({
    name = "Pokaż Podświetlenie 3D (Highlight)",
    currentValue = Config.ESPShowHighlight,
    flag = "Toggle_ESPShowHighlight",
    callback = function(value)
        Config.ESPShowHighlight = value
    end
})

--------------------------------------------------------------------------------
-- ZAKŁADKA 3: TELEPORTY I NARZĘDZIA
--------------------------------------------------------------------------------
local tabUtils = window:CreateTab({
    name = "Narzędzia & Teleporty",
    icon = 93364949241311
})

tabUtils:CreateSection({ name = "Szybkie Teleporty" })

tabUtils:CreateButton({
    name = "Teleport do Donic (Grządki)",
    callback = function()
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local p1 = getPlotInstance(1) or getPlotInstance(2)
        local part = getPlotBasePart(p1)
        if hrp and part then
            hrp.CFrame = CFrame.new(part.Position + Vector3.new(0, 4, 2))
        end
    end
})

tabUtils:CreateButton({
    name = "Teleport do Kapsuły Wody (-437.83, 109.46, -1421.35)",
    callback = function()
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.CFrame = CFrame.new(-442, 112, -1418)
        end
    end
})

tabUtils:CreateSection({ name = "Akcje Ręczne" })

tabUtils:CreateButton({
    name = "Pobierz Wodę z Kapsuły Teraz (Click Capsule)",
    callback = function()
        pcall(clickCapsule)
        sendNotification("Kapsuła", "Wysłano pakiety kliknięcia w kapsułę!", 2)
    end
})

tabUtils:CreateButton({
    name = "Zbierz Wszystkie Gotowe Plony Teraz",
    callback = function()
        if FireCustom then
            for i = 1, 20 do
                pcall(function() FireCustom:FireServer("FlowerGarden", "ClaimPlant", i) end)
            end
            sendNotification("Plony", "Wysłano żądanie zbioru dla wszystkich działek!", 2)
        end
    end
})

--------------------------------------------------------------------------------
-- CZYSZCZENIE PRZY RE-EXECUTE
--------------------------------------------------------------------------------
_G.PS99GardenCleanup = function()
    _G.PS99GardenRunning = false
    if ESPUpdateConnection then
        ESPUpdateConnection:Disconnect()
        ESPUpdateConnection = nil
    end
    if AntiAFKConnection then
        AntiAFKConnection:Disconnect()
        AntiAFKConnection = nil
    end
    if ESPContainer then
        ESPContainer:Destroy()
    end
end

sendNotification("PS99 Auto", "Załadowano pomyślnie! ESP domyślnie wyłączone.", 3.5)
