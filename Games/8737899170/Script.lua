-- // ==========================================================================
-- // PET SIMULATOR 99 (FLOWER GARDEN EVENT) - AUTOMATION & ESP SUITE
-- // Dedicated script for MenuTest UI Library (https://github.com/XxvoltikxX/MenuTest)
-- // PlaceId: 8737899170 / 3317771874
-- // Features: Ultra-fast Auto Plant, Auto Insta-Grow (Can/Capsule Water),
-- //           Auto Water, Auto Claim, Turbo Mode, Fully Configurable Action &
-- //           Loop Delays, Slot ESP with Highlights, Quick Select, Teleports & Anti-AFK
-- // ==========================================================================

-- // ==========================================================================
-- // 0. SPRZĄTANIE POPRZEDNIEJ INSTANCJI
-- // ==========================================================================
if _G.PS99GardenRunning and _G.PS99GardenCleanup then
    pcall(_G.PS99GardenCleanup)
end
if typeof(getgenv) == "function" and getgenv()._PS99GardenCleanup then
    pcall(getgenv()._PS99GardenCleanup)
end
_G.PS99GardenRunning = true

-- // ==========================================================================
-- // 1. INICJALIZACJA BIBLIOTEKI MENUTEST
-- // ==========================================================================
local isDev = (typeof(getgenv) == "function" and getgenv()._MenuTestDevMode == true)
local MENU = nil

if isDev and typeof(readfile) == "function" then
    local candidates = {
        "MenuTest/Main.lua",
        "Main.lua"
    }
    for _, path in ipairs(candidates) do
        if typeof(isfile) == "function" and isfile(path) then
            local ok, data = pcall(readfile, path)
            if ok and data and #data > 0 then
                local chunk = loadstring(data:gsub("^\239\187\191", ""))
                if chunk then
                    MENU = chunk()
                    break
                end
            end
        end
    end
end

if not MENU then
    local urls = {
        "https://raw.githubusercontent.com/XxvoltikxX/MenuTest/main/Main.lua?_t=" .. tostring(tick()) .. "_" .. tostring(math.random(100000, 999999)),
        "https://raw.githubusercontent.com/XxvoltikxX/MenuTest/refs/heads/main/Main.lua?_t=" .. tostring(tick()) .. "_" .. tostring(math.random(100000, 999999))
    }
    for _, u in ipairs(urls) do
        local ok, mainRaw = pcall(function() return game:HttpGet(u) end)
        if ok and mainRaw and #mainRaw > 0 then
            local chunk = loadstring(mainRaw:gsub("^\239\187\191", ""))
            if chunk then
                MENU = chunk()
                break
            end
        end
    end
end

if not MENU then
    warn("[GardenHub] Nie udalo sie zaladowac biblioteki MenuTest!")
    return
end

-- // ==========================================================================
-- // 2. USŁUGI ROBLOX I REMOTY GRY
-- // ==========================================================================
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

-- Odnalezienie Remote'ów Pet Simulator 99
local Network = ReplicatedStorage:WaitForChild("Network", 10)
local InvokeCustom = Network and Network:WaitForChild("Instancing_InvokeCustomFromClient", 10)
local FireCustom = Network and Network:WaitForChild("Instancing_FireCustomFromClient", 10)
local ClickEvent = Network and Network:FindFirstChild("Click")

local ClientNetwork = nil
pcall(function()
    ClientNetwork = require(ReplicatedStorage.Library.Client.Network)
end)

-- // ==========================================================================
-- // 3. KONFIGURACJA I STAN GLOBALNY
-- // ==========================================================================
local Config = {
    -- Auto Farm
    AutoFarmEnabled = false,
    FastMode = false,
    AutoPlant = true,
    AutoInstaGrow = true,
    AutoCapsuleClick = true,
    AutoWater = false,
    AutoClaim = true,
    SeedType = "Diamond",
    CustomSeed = "",
    ActionDelay = 0.10,
    LoopDelay = 0.50,
    FarmSlots = {
        ["1"] = true, ["2"] = true, ["3"] = true, ["4"] = true, ["5"] = true,
        ["6"] = false, ["7"] = false, ["8"] = false, ["9"] = false, ["10"] = false,
        ["11"] = false, ["12"] = false, ["13"] = false, ["14"] = false, ["15"] = false,
        ["16"] = false, ["17"] = false, ["18"] = false, ["19"] = false, ["20"] = false
    },

    -- ESP Działek
    ESPEnabled = false,
    ESPMode = "Tylko Farmiące", -- "Tylko Farmiące", "Wszystkie (1-20)"
    ESPShowStatus = true,
    ESPShowDistance = true,
    ESPShowHighlight = true,

    -- Utility
    AntiAFK = true,
    SelectedTPSlot = "1",

    -- Statystyki
    Stats = {
        Planted = 0,
        Grown = 0,
        Harvested = 0,
        WaterCollected = 0
    }
}

local SlotToggleAPIs = {}
local ScriptConnections = {}

-- // ==========================================================================
-- // 4. FUNKCJE POMOCNICZE I DETEKCJA ELEMENTÓW OGRODU
-- // ==========================================================================
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

    local things = Workspace:FindFirstChild("__THINGS")
    if not things then return nil end
    local inst = things:FindFirstChild("__INSTANCE_CONTAINER")
    if not inst then return nil end
    local active = inst:FindFirstChild("Active")
    if not active then return nil end
    local garden = active:FindFirstChild("FlowerGarden")
    if not garden then return nil end
    local plants = garden:FindFirstChild("Plants")
    if plants then
        cachedPlantsFolder = plants
        return plants
    end
    return nil
end

local function getPlotInstance(slotNum)
    local plants = getPlantsFolder()
    if not plants then return nil end
    local s = tostring(slotNum)
    return plants:FindFirstChild("Plant" .. s)
        or plants:FindFirstChild("Plant " .. s)
        or plants:FindFirstChild(s)
end

local function getPlotBasePart(plot)
    if not plot then return nil end
    if plot:IsA("BasePart") then return plot end
    if plot.PrimaryPart then return plot.PrimaryPart end
    local soil = plot:FindFirstChild("Soil", true)
        or plot:FindFirstChild("Pot", true)
        or plot:FindFirstChild("Base", true)
        or plot:FindFirstChildWhichIsA("BasePart", true)
    return soil
end

local function checkPlotStatus(plot)
    if not plot then return "Nieznaleziona", Color3.fromRGB(150, 150, 150) end

    if plot:FindFirstChild("Stage3") or plot:FindFirstChild("Stage4") then
        return "Gotowa do Zbioru!", Color3.fromRGB(50, 255, 100)
    elseif plot:FindFirstChild("Stage1") or plot:FindFirstChild("Stage2") then
        return "Rośnie...", Color3.fromRGB(255, 200, 50)
    end

    for _, child in ipairs(plot:GetChildren()) do
        if child.Name:find("Stage") or child.Name:find("Mesh") or child.Name:find("Seed") then
            return "Rośnie / Zasadzone", Color3.fromRGB(255, 180, 50)
        end
    end

    return "Pusta (Gotowa)", Color3.fromRGB(80, 200, 255)
end

-- Pobieranie wody / kliknięcie na kapsułę (InstaPlant Incubator)
local function clickCapsule()
    local origin = Vector3.new(-455.88748168945312, 128.20892333984375, -1396.1763916015625)
    local dir = Vector3.new(0.4934602677822113, -0.57543015480041504, -0.65220928192138672)
    local hitPos = Vector3.new(-437.83212280273438, 109.46415710449219, -1421.351318359375)

    local incubator = nil
    pcall(function()
        incubator = Workspace.__THINGS.__INSTANCE_CONTAINER.Active.FlowerGarden.Interactable.InstaPlantIncubator.Union
    end)
    if incubator and incubator:IsA("BasePart") then
        hitPos = incubator.Position
        if Workspace.CurrentCamera then
            local camPos = Workspace.CurrentCamera.CFrame.Position
            origin = camPos
            dir = (hitPos - camPos).Unit
        end
    end

    if ClickEvent then
        pcall(function()
            ClickEvent:FireServer(Ray.new(origin, dir), hitPos)
        end)
    end
    if ClientNetwork and type(ClientNetwork.Fire) == "function" then
        pcall(function()
            ClientNetwork.Fire("Click", Ray.new(origin, dir), hitPos)
        end)
    end
    Config.Stats.WaterCollected = Config.Stats.WaterCollected + 1
end

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

-- // ==========================================================================
-- // 5. AKCJE FARMOWANIA NA DZIAŁKACH (ZGODNE Z ORYGINAŁEM)
-- // ==========================================================================
local function executeSlotActions(slotNum, seed)
    -- 1. Auto Plant (Sadzenie)
    if Config.AutoPlant and InvokeCustom then
        pcall(function()
            InvokeCustom:InvokeServer("FlowerGarden", "PlantSeed", slotNum, seed)
            Config.Stats.Planted = Config.Stats.Planted + 1
        end)
        if not Config.FastMode and Config.ActionDelay > 0 then
            task.wait(Config.ActionDelay)
        end
    end

    -- 2. Auto Insta Grow (Pobranie wody z kapsuły + podlanie przyspieszające)
    if Config.AutoInstaGrow and InvokeCustom then
        if Config.AutoCapsuleClick then
            clickCapsule()
        end
        pcall(function()
            InvokeCustom:InvokeServer("FlowerGarden", "InstaGrowSeed", slotNum)
            Config.Stats.Grown = Config.Stats.Grown + 1
        end)
        if not Config.FastMode and Config.ActionDelay > 0 then
            task.wait(Config.ActionDelay)
        end
    end

    -- 2b. Auto Water (Zwykłe podlewanie konewką)
    if Config.AutoWater and InvokeCustom then
        pcall(function()
            InvokeCustom:InvokeServer("FlowerGarden", "WaterSeed", slotNum)
        end)
        if not Config.FastMode and Config.ActionDelay > 0 then
            task.wait(Config.ActionDelay)
        end
    end

    -- 3. Auto Claim (Zbiór plonów)
    if Config.AutoClaim and FireCustom then
        pcall(function()
            FireCustom:FireServer("FlowerGarden", "ClaimPlant", slotNum)
            Config.Stats.Harvested = Config.Stats.Harvested + 1
        end)
        if not Config.FastMode and Config.ActionDelay > 0 then
            task.wait(Config.ActionDelay)
        end
    end
end

-- Główna pętla Auto Farm
task.spawn(function()
    while _G.PS99GardenRunning do
        if Config.AutoFarmEnabled then
            local slotsToFarm = getSortedFarmSlots()
            local seed = getActiveSeedName()

            if Config.FastMode then
                -- TRYB TURBO: Błyskawiczne równoległe wywołanie wszystkich wybranych slotów
                if Config.AutoInstaGrow and Config.AutoCapsuleClick then
                    clickCapsule()
                end
                for _, slotNum in ipairs(slotsToFarm) do
                    if not Config.AutoFarmEnabled then break end
                    task.spawn(function()
                        executeSlotActions(slotNum, seed)
                    end)
                end
            else
                -- TRYB STANDARDOWY: Sekwencyjny z precyzyjnym czasem ActionDelay
                for _, slotNum in ipairs(slotsToFarm) do
                    if not Config.AutoFarmEnabled then break end
                    executeSlotActions(slotNum, seed)
                end
            end
        end

        if Config.LoopDelay > 0 then
            task.wait(Config.LoopDelay)
        else
            task.wait()
        end
    end
end)

-- // ==========================================================================
-- // 6. SYSTEM ESP DZIAŁEK (BILLBOARDGUI + HIGHLIGHT)
-- // ==========================================================================
local ESPFolder = Instance.new("Folder")
ESPFolder.Name = "PS99GardenESP"
ESPFolder.Parent = (typeof(gethui) == "function" and gethui()) or CoreGui

local ESPObjects = {}

local function createPlotESP(slotNum)
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "PlotESP_" .. tostring(slotNum)
    billboard.Size = UDim2.new(0, 140, 0, 46)
    billboard.AlwaysOnTop = true
    billboard.MaxDistance = 600
    billboard.Enabled = false
    billboard.Parent = ESPFolder

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundColor3 = Color3.fromRGB(15, 17, 26)
    frame.BackgroundTransparency = 0.3
    frame.BorderSizePixel = 0
    frame.Parent = billboard

    local uiCorner = Instance.new("UICorner", frame)
    uiCorner.CornerRadius = UDim.new(0, 8)

    local uiStroke = Instance.new("UIStroke", frame)
    uiStroke.Thickness = 1.2
    uiStroke.Color = Color3.fromRGB(80, 95, 145)

    local titleLabel = Instance.new("TextLabel", frame)
    titleLabel.Size = UDim2.new(1, 0, 0, 18)
    titleLabel.Position = UDim2.new(0, 0, 0, 2)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 12
    titleLabel.TextColor3 = Color3.fromRGB(240, 245, 255)
    titleLabel.Text = "🌱 Działka " .. tostring(slotNum)

    local statusLabel = Instance.new("TextLabel", frame)
    statusLabel.Size = UDim2.new(1, 0, 0, 22)
    statusLabel.Position = UDim2.new(0, 0, 0, 20)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Font = Enum.Font.GothamMedium
    statusLabel.TextSize = 10
    statusLabel.TextColor3 = Color3.fromRGB(180, 190, 210)
    statusLabel.Text = "Sprawdzanie..."

    local highlight = Instance.new("Highlight")
    highlight.Name = "PlotHL_" .. tostring(slotNum)
    highlight.FillColor = Color3.fromRGB(99, 102, 241)
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
        StatusLabel = statusLabel
    }
end

for i = 1, 20 do
    createPlotESP(i)
end

local function cleanupESP()
    for _, esp in pairs(ESPObjects) do
        if esp.Billboard then
            esp.Billboard.Enabled = false
            esp.Billboard.Adornee = nil
        end
        if esp.Highlight then
            esp.Highlight.Enabled = false
            esp.Highlight.Adornee = nil
            esp.Highlight.Parent = nil
        end
    end
end

local function updateESP()
    if not Config.ESPEnabled or not _G.PS99GardenRunning then
        cleanupESP()
        return
    end

    local myChar = LocalPlayer.Character
    local myRoot = myChar and (myChar:FindFirstChild("HumanoidRootPart") or myChar.PrimaryPart)
    local myPos = myRoot and myRoot.Position

    for slotNum = 1, 20 do
        local esp = ESPObjects[slotNum]
        if esp then
            local slotStr = tostring(slotNum)
            local shouldShow = true
            if Config.ESPMode == "Tylko Farmiące" then
                shouldShow = (Config.FarmSlots[slotStr] == true)
            end

            if shouldShow then
                local plot = getPlotInstance(slotNum)
                local part = getPlotBasePart(plot)

                if plot and part then
                    esp.Billboard.Adornee = part
                    esp.Billboard.Enabled = true

                    local statusText, statusColor = checkPlotStatus(plot)
                    local distText = ""
                    if Config.ESPShowDistance and myPos then
                        local d = math.floor((part.Position - myPos).Magnitude)
                        distText = " [" .. tostring(d) .. "m]"
                    end

                    if Config.ESPShowStatus then
                        esp.StatusLabel.Text = statusText .. distText
                        esp.StatusLabel.TextColor3 = statusColor
                        esp.Stroke.Color = statusColor
                        esp.StatusLabel.Visible = true
                    else
                        esp.StatusLabel.Visible = false
                    end

                    if Config.ESPShowHighlight then
                        esp.Highlight.Adornee = plot
                        esp.Highlight.FillColor = statusColor
                        esp.Highlight.OutlineColor = statusColor
                        esp.Highlight.Parent = ESPFolder
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
end

local espTimer = 0
local espConn = RunService.Heartbeat:Connect(function(dt)
    if not _G.PS99GardenRunning then return end
    espTimer = espTimer + dt
    if espTimer >= 0.15 then
        espTimer = 0
        pcall(updateESP)
    end
end)
table.insert(ScriptConnections, espConn)

-- // ==========================================================================
-- // 7. ANTI-AFK
-- // ==========================================================================
local afkConn = LocalPlayer.Idled:Connect(function()
    if Config.AntiAFK and _G.PS99GardenRunning then
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    end
end)
table.insert(ScriptConnections, afkConn)

-- // ==========================================================================
-- // 8. BUDOWA INTERFEJSU UŻYTKOWNIKA (MENUTEST UI)
-- // ==========================================================================
local Window = MENU:CreateWindow({
    Name = "PetHub",
    Tittle = "Pet Simulator 99 (Garden Event)",
    TittlePos = "Center",
    ToggleUIKeybind = "K",
    TestMobile = false,
    GameId = "8737899170"
})

-- Zakładki
local TabGarden = Window:CreateTab("Auto Farm", "zap")
local TabSlots  = Window:CreateTab("Działki", "sliders")
local TabESP    = Window:CreateTab("ESP Działek", "eye")
local TabUtils  = Window:CreateTab("Teleporty", "wind")

-- --------------------------------------------------------------------------
-- ZAKŁADKA 1: AUTO FARM
-- --------------------------------------------------------------------------
local ModFarm = TabGarden:CreateModule({
    Name = "Główny Automat (Auto Farm)",
    Description = "Zarządzanie pętlą sadzenia, insta-grow i zbioru",
    Default = false,
    Expanded = true,
    Callback = function(val)
        Config.AutoFarmEnabled = val
    end
})

ModFarm:AddToggle({
    Name = "⚡ Tryb Turbo (Maksymalne Przyspieszenie)",
    Default = Config.FastMode,
    Callback = function(val)
        Config.FastMode = val
    end
})

ModFarm:AddDropdown({
    Name = "Rodzaj Nasiona",
    Options = {"Diamond", "Coin", "Gift", "Potion", "Enchant", "Własne"},
    CurrentOption = {Config.SeedType},
    Callback = function(opt)
        Config.SeedType = type(opt) == "table" and opt[1] or opt
    end
})

ModFarm:AddInput({
    Name = "Własne Nasiono (Custom)",
    PlaceholderText = "Wpisz dokładną nazwę nasiona...",
    Callback = function(text)
        Config.CustomSeed = text
    end
})

ModFarm:AddToggle({
    Name = "Krok 1: Auto Sadzenie (Auto Plant)",
    Default = Config.AutoPlant,
    Callback = function(val)
        Config.AutoPlant = val
    end
})

ModFarm:AddToggle({
    Name = "Krok 2: Auto Insta-Grow (Konewka / Kapsuła)",
    Default = Config.AutoInstaGrow,
    Callback = function(val)
        Config.AutoInstaGrow = val
    end
})

ModFarm:AddToggle({
    Name = "Krok 2b: Auto Zbieranie Wody z Kapsuły",
    Default = Config.AutoCapsuleClick,
    Callback = function(val)
        Config.AutoCapsuleClick = val
    end
})

ModFarm:AddToggle({
    Name = "Krok 2c: Zwykłe Podlewanie (Auto Water)",
    Default = Config.AutoWater,
    Callback = function(val)
        Config.AutoWater = val
    end
})

ModFarm:AddToggle({
    Name = "Krok 3: Auto Zbieranie Plonów (Auto Claim)",
    Default = Config.AutoClaim,
    Callback = function(val)
        Config.AutoClaim = val
    end
})

ModFarm:AddSlider({
    Name = "Opóźnienie Akcji",
    Range = {0, 1.0},
    Min = 0,
    Max = 1.0,
    Step = 0.01,
    Increment = 0.01,
    Precise = true,
    Decimals = 2,
    Suffix = "s",
    Default = Config.ActionDelay,
    CurrentValue = Config.ActionDelay,
    Callback = function(val)
        Config.ActionDelay = tonumber(string.format("%.2f", val)) or val
    end
})

ModFarm:AddSlider({
    Name = "Pauza Między Pętlami",
    Range = {0, 5.0},
    Min = 0,
    Max = 5.0,
    Step = 0.05,
    Increment = 0.05,
    Precise = true,
    Decimals = 2,
    Suffix = "s",
    Default = Config.LoopDelay,
    CurrentValue = Config.LoopDelay,
    Callback = function(val)
        Config.LoopDelay = tonumber(string.format("%.2f", val)) or val
    end
})

-- Moduł ręcznych akcji
local ModManual = TabGarden:CreateModule({
    Name = "Ręczne Akcje (Manual)",
    Description = "Błyskawiczne wywołanie poszczególnych akcji",
    Default = false,
    Expanded = false
})

ModManual:AddButton({
    Name = "Zbierz Wodę z Kapsuły (Click)",
    Callback = function()
        clickCapsule()
    end
})

ModManual:AddButton({
    Name = "Zasadź Zaznaczone Działki",
    Callback = function()
        local slots = getSortedFarmSlots()
        local seed = getActiveSeedName()
        task.spawn(function()
            for _, s in ipairs(slots) do
                if InvokeCustom then
                    pcall(function()
                        InvokeCustom:InvokeServer("FlowerGarden", "PlantSeed", s, seed)
                        Config.Stats.Planted = Config.Stats.Planted + 1
                    end)
                end
                if Config.ActionDelay > 0 then task.wait(Config.ActionDelay) end
            end
        end)
    end
})

ModManual:AddButton({
    Name = "Użyj Insta-Grow na Zaznaczonych",
    Callback = function()
        local slots = getSortedFarmSlots()
        task.spawn(function()
            for _, s in ipairs(slots) do
                if Config.AutoCapsuleClick then clickCapsule() end
                if InvokeCustom then
                    pcall(function()
                        InvokeCustom:InvokeServer("FlowerGarden", "InstaGrowSeed", s)
                        Config.Stats.Grown = Config.Stats.Grown + 1
                    end)
                end
                if Config.ActionDelay > 0 then task.wait(Config.ActionDelay) end
            end
        end)
    end
})

ModManual:AddButton({
    Name = "Podlej Zaznaczone Działki",
    Callback = function()
        local slots = getSortedFarmSlots()
        task.spawn(function()
            for _, s in ipairs(slots) do
                if InvokeCustom then
                    pcall(function()
                        InvokeCustom:InvokeServer("FlowerGarden", "WaterSeed", s)
                    end)
                end
                if Config.ActionDelay > 0 then task.wait(Config.ActionDelay) end
            end
        end)
    end
})

ModManual:AddButton({
    Name = "Zbierz Wszystkie Dojrzałe Plony",
    Callback = function()
        local slots = getSortedFarmSlots()
        task.spawn(function()
            for _, s in ipairs(slots) do
                if FireCustom then
                    pcall(function()
                        FireCustom:FireServer("FlowerGarden", "ClaimPlant", s)
                        Config.Stats.Harvested = Config.Stats.Harvested + 1
                    end)
                end
                if Config.ActionDelay > 0 then task.wait(Config.ActionDelay) end
            end
        end)
    end
})

-- --------------------------------------------------------------------------
-- ZAKŁADKA 2: WYBÓR DZIAŁEK (1-20)
-- --------------------------------------------------------------------------
local ModQuickSelect = TabSlots:CreateModule({
    Name = "Szybki Wybór Działek",
    Description = "Zaznacz lub odznacz grupy działek",
    Default = false,
    Expanded = true
})

ModQuickSelect:AddButton({
    Name = "Zaznacz Wszystkie (1-20)",
    Callback = function()
        for i = 1, 20 do
            Config.FarmSlots[tostring(i)] = true
            if SlotToggleAPIs[i] and SlotToggleAPIs[i].Set then
                SlotToggleAPIs[i]:Set(true)
            end
        end
    end
})

ModQuickSelect:AddButton({
    Name = "Odznacz Wszystkie",
    Callback = function()
        for i = 1, 20 do
            Config.FarmSlots[tostring(i)] = false
            if SlotToggleAPIs[i] and SlotToggleAPIs[i].Set then
                SlotToggleAPIs[i]:Set(false)
            end
        end
    end
})

ModQuickSelect:AddButton({
    Name = "Tylko Pierwsze 5 (Działki 1-5)",
    Callback = function()
        for i = 1, 20 do
            local state = (i <= 5)
            Config.FarmSlots[tostring(i)] = state
            if SlotToggleAPIs[i] and SlotToggleAPIs[i].Set then
                SlotToggleAPIs[i]:Set(state)
            end
        end
    end
})

ModQuickSelect:AddButton({
    Name = "Tylko Pierwsze 10 (Działki 1-10)",
    Callback = function()
        for i = 1, 20 do
            local state = (i <= 10)
            Config.FarmSlots[tostring(i)] = state
            if SlotToggleAPIs[i] and SlotToggleAPIs[i].Set then
                SlotToggleAPIs[i]:Set(state)
            end
        end
    end
})

ModQuickSelect:AddInput({
    Name = "Wpisz Numery Działek (np. 1, 2, 5, 8)",
    PlaceholderText = "Wpisz numery po przecinku...",
    Callback = function(text)
        if text and text:gsub("%s+", "") ~= "" then
            for i = 1, 20 do
                Config.FarmSlots[tostring(i)] = false
                if SlotToggleAPIs[i] and SlotToggleAPIs[i].Set then
                    SlotToggleAPIs[i]:Set(false)
                end
            end
            for numStr in text:gmatch("%d+") do
                local n = tonumber(numStr)
                if n and n >= 1 and n <= 20 then
                    Config.FarmSlots[tostring(n)] = true
                    if SlotToggleAPIs[n] and SlotToggleAPIs[n].Set then
                        SlotToggleAPIs[n]:Set(true)
                    end
                end
            end
        end
    end
})

local ModSlots1to10 = TabSlots:CreateModule({
    Name = "Działki 1 do 10",
    Description = "Wybór pojedynczych slotów ogrodowych",
    Default = false,
    Expanded = true
})

for i = 1, 10 do
    local s = tostring(i)
    SlotToggleAPIs[i] = ModSlots1to10:AddToggle({
        Name = "Działka " .. s,
        Default = Config.FarmSlots[s] or false,
        Callback = function(val)
            Config.FarmSlots[s] = val
        end
    })
end

local ModSlots11to20 = TabSlots:CreateModule({
    Name = "Działki 11 do 20",
    Description = "Wybór pojedynczych slotów ogrodowych",
    Default = false,
    Expanded = true
})

for i = 11, 20 do
    local s = tostring(i)
    SlotToggleAPIs[i] = ModSlots11to20:AddToggle({
        Name = "Działka " .. s,
        Default = Config.FarmSlots[s] or false,
        Callback = function(val)
            Config.FarmSlots[s] = val
        end
    })
end

-- --------------------------------------------------------------------------
-- ZAKŁADKA 3: ESP DZIAŁEK
-- --------------------------------------------------------------------------
local ModESP = TabESP:CreateModule({
    Name = "Wizualizacja ESP",
    Description = "Status i odległość do działek",
    Default = false,
    Expanded = true,
    Callback = function(val)
        Config.ESPEnabled = val
        if not val then
            cleanupESP()
        end
    end
})

ModESP:AddDropdown({
    Name = "Tryb Wyświetlania",
    Options = {"Tylko Farmiące", "Wszystkie (1-20)"},
    CurrentOption = {Config.ESPMode},
    Callback = function(opt)
        Config.ESPMode = type(opt) == "table" and opt[1] or opt
    end
})

ModESP:AddToggle({
    Name = "Pokaż Status Rośliny (Pusta/Rośnie/Gotowa)",
    Default = Config.ESPShowStatus,
    Callback = function(val)
        Config.ESPShowStatus = val
    end
})

ModESP:AddToggle({
    Name = "Pokaż Odległość (Dystans w Studs)",
    Default = Config.ESPShowDistance,
    Callback = function(val)
        Config.ESPShowDistance = val
    end
})

ModESP:AddToggle({
    Name = "Podświetlenie Modelu (Highlight 3D)",
    Default = Config.ESPShowHighlight,
    Callback = function(val)
        Config.ESPShowHighlight = val
    end
})

-- --------------------------------------------------------------------------
-- ZAKŁADKA 4: TELEPORTY I OPCJE
-- --------------------------------------------------------------------------
local ModTP = TabUtils:CreateModule({
    Name = "Teleporty Ogrodu",
    Description = "Błyskawiczne przemieszczanie się po mapie",
    Default = false,
    Expanded = true
})

local function tpToPos(pos)
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        char.HumanoidRootPart.CFrame = CFrame.new(pos) + Vector3.new(0, 3, 0)
    end
end

ModTP:AddButton({
    Name = "Teleport do Kapsuły Wody (InstaPlant)",
    Callback = function()
        tpToPos(Vector3.new(-442, 112, -1418))
    end
})

ModTP:AddButton({
    Name = "Teleport na Środek Ogrodu",
    Callback = function()
        tpToPos(Vector3.new(-477, 112, -1403))
    end
})

local slotOptions = {}
for i = 1, 20 do table.insert(slotOptions, tostring(i)) end

ModTP:AddDropdown({
    Name = "Wybierz Numer Działki",
    Options = slotOptions,
    CurrentOption = {Config.SelectedTPSlot},
    Callback = function(opt)
        Config.SelectedTPSlot = type(opt) == "table" and opt[1] or opt
    end
})

ModTP:AddButton({
    Name = "Teleportuj do Wybranej Działki",
    Callback = function()
        local plot = getPlotInstance(Config.SelectedTPSlot)
        local part = getPlotBasePart(plot)
        if part then
            tpToPos(part.Position)
        end
    end
})

local ModBonus = TabUtils:CreateModule({
    Name = "Dodatki & Skrzynki",
    Description = "Darmowe nagrody i zabezpieczenia",
    Default = false,
    Expanded = true
})

ModBonus:AddButton({
    Name = "Odbierz Darmową Skrzynkę (Free Chest)",
    Callback = function()
        if FireCustom then
            pcall(function()
                FireCustom:FireServer("FlowerGarden", "ClaimChest")
            end)
        end
    end
})

ModBonus:AddToggle({
    Name = "Anti-AFK (Ochrona przed rozłączeniem)",
    Default = Config.AntiAFK,
    Callback = function(val)
        Config.AntiAFK = val
    end
})

-- // ==========================================================================
-- // 9. CLEANUP HANDLER
-- // ==========================================================================
local function fullCleanup()
    _G.PS99GardenRunning = false
    Config.AutoFarmEnabled = false
    Config.ESPEnabled = false
    for _, conn in ipairs(ScriptConnections) do
        if conn and typeof(conn) == "RBXScriptConnection" and conn.Connected then
            pcall(function() conn:Disconnect() end)
        end
    end
    cleanupESP()
    if ESPFolder then
        pcall(function() ESPFolder:Destroy() end)
    end
end

_G.PS99GardenCleanup = fullCleanup
if typeof(getgenv) == "function" then
    getgenv()._PS99GardenCleanup = fullCleanup
end

if Window and Window.ScreenGui then
    Window.ScreenGui.Destroying:Connect(fullCleanup)
end
