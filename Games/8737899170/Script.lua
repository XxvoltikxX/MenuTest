-- // ==========================================================================
-- // PET SIMULATOR 99 (FLOWER GARDEN EVENT) - AUTOMATION & ESP SUITE
-- // Dedicated script for MenuTest UI Library (https://github.com/XxvoltikxX/MenuTest)
-- // PlaceId: 8737899170 / 3317771874
-- // Features: Auto Plant, Auto Insta-Grow (Can/Capsule Water), Auto Water,
-- //           Auto Claim, Water Capsule Auto-Click, Slot ESP with Highlights,
-- //           Plot Quick Selection, Garden Teleports & Anti-AFK
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
    AutoPlant = true,
    AutoInstaGrow = true,
    AutoCapsuleClick = true,
    AutoWater = false,
    AutoClaim = true,
    SeedType = "Diamond",
    CustomSeed = "",
    ActionDelay = 0.25,
    LoopDelay = 1.0,
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
local function getPlantsFolder()
    local things = Workspace:FindFirstChild("__THINGS")
    if not things then return nil end
    local inst = things:FindFirstChild("__INSTANCE_CONTAINER")
    if not inst then return nil end
    local active = inst:FindFirstChild("Active")
    if not active then return nil end
    local garden = active:FindFirstChild("FlowerGarden")
    if not garden then return nil end
    return garden:FindFirstChild("Plants")
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
    if not plot then return "Brak", nil end
    local isStage4 = plot:FindFirstChild("Stage4", true)
    local isStage3 = plot:FindFirstChild("Stage3", true)
    local isStage2 = plot:FindFirstChild("Stage2", true)
    local isStage1 = plot:FindFirstChild("Stage1", true)

    if isStage4 or isStage3 then
        return "Gotowa", (isStage4 and "Stage4" or "Stage3")
    elseif isStage2 or isStage1 then
        return "Rośnie", (isStage2 and "Stage2" or "Stage1")
    else
        return "Pusta", nil
    end
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

-- Akcje na pojedynczej działce
local function harvestSlot(slotNum)
    if not FireCustom then return false end
    local ok = pcall(function()
        FireCustom:FireServer("FlowerGarden", "ClaimPlant", tonumber(slotNum))
    end)
    if ok then
        Config.Stats.Harvested = Config.Stats.Harvested + 1
    end
    return ok
end

local function plantSlot(slotNum)
    if not InvokeCustom then return false end
    local seed = Config.SeedType
    if seed == "Własne" and #Config.CustomSeed > 0 then
        seed = Config.CustomSeed
    end
    local ok, res = pcall(function()
        return InvokeCustom:InvokeServer("FlowerGarden", "PlantSeed", tonumber(slotNum), seed)
    end)
    if ok then
        Config.Stats.Planted = Config.Stats.Planted + 1
    end
    return ok, res
end

local function instaGrowSlot(slotNum)
    if not InvokeCustom then return false end
    if Config.AutoCapsuleClick then
        clickCapsule()
        task.wait(0.08)
    end
    local ok, res = pcall(function()
        return InvokeCustom:InvokeServer("FlowerGarden", "InstaGrowSeed", tonumber(slotNum))
    end)
    if ok then
        Config.Stats.Grown = Config.Stats.Grown + 1
    end
    return ok, res
end

local function waterSlot(slotNum)
    if not InvokeCustom then return false end
    local ok, res = pcall(function()
        return InvokeCustom:InvokeServer("FlowerGarden", "WaterSeed", tonumber(slotNum))
    end)
    return ok, res
end

-- // ==========================================================================
-- // 5. GŁÓWNA PĘTLA AUTOFARM
-- // ==========================================================================
local isFarmingCycle = false
local function runFarmCycle()
    if isFarmingCycle or not Config.AutoFarmEnabled then return end
    isFarmingCycle = true

    for slot = 1, 20 do
        if not Config.AutoFarmEnabled or not _G.PS99GardenRunning then break end
        local slotKey = tostring(slot)
        if Config.FarmSlots[slotKey] then
            local plot = getPlotInstance(slot)
            local status, stage = checkPlotStatus(plot)

            -- Krok 1: Zbiór gotowych plonów
            if Config.AutoClaim and (status == "Gotowa" or stage == "Stage3" or stage == "Stage4") then
                harvestSlot(slot)
                task.wait(Config.ActionDelay)
                status, stage = checkPlotStatus(plot)
            end

            -- Krok 2: Sadzenie nowego nasiona jeśli działka pusta
            if Config.AutoPlant and (status == "Pusta" or not stage) then
                plantSlot(slot)
                task.wait(Config.ActionDelay)
                status, stage = checkPlotStatus(plot)
            end

            -- Krok 3: Insta-Grow z użyciem wody z kapsuły
            if Config.AutoInstaGrow and (status == "Rośnie" or status == "Pusta" or stage == "Stage1" or stage == "Stage2") then
                instaGrowSlot(slot)
                task.wait(Config.ActionDelay)
                status, stage = checkPlotStatus(plot)

                -- Zbiór natychmiastowy jeśli roślina od razu urosła do Stage3/4
                if Config.AutoClaim and (status == "Gotowa" or stage == "Stage3" or stage == "Stage4") then
                    harvestSlot(slot)
                    task.wait(Config.ActionDelay)
                end
            -- Krok 3b: Zwykłe podlewanie konewką jeśli wyłączono InstaGrow
            elseif Config.AutoWater and (status == "Rośnie" or stage == "Stage1" or stage == "Stage2") then
                waterSlot(slot)
                task.wait(Config.ActionDelay)
            end
        end
    end

    isFarmingCycle = false
end

task.spawn(function()
    while _G.PS99GardenRunning do
        if Config.AutoFarmEnabled then
            pcall(runFarmCycle)
        end
        task.wait(Config.LoopDelay)
    end
end)

-- // ==========================================================================
-- // 6. SYSTEM ESP DZIAŁEK (BILLBOARDGUI + HIGHLIGHT)
-- // ==========================================================================
local ESPFolder = Instance.new("Folder")
ESPFolder.Name = "PS99GardenESP"
ESPFolder.Parent = (typeof(gethui) == "function" and gethui()) or CoreGui

local ESPObjects = {}

local function createESPForPlot(slotNum, plot)
    local part = getPlotBasePart(plot)
    if not part then return nil end

    local bbg = Instance.new("BillboardGui")
    bbg.Name = "PlotESP_" .. tostring(slotNum)
    bbg.Size = UDim2.new(0, 140, 0, 46)
    bbg.AlwaysOnTop = true
    bbg.MaxDistance = 600
    bbg.Adornee = part
    bbg.Parent = ESPFolder

    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3 = Color3.fromRGB(15, 17, 26)
    bg.BackgroundTransparency = 0.3
    bg.BorderSizePixel = 0
    bg.Parent = bbg
    Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 8)
    local stroke = Instance.new("UIStroke", bg)
    stroke.Thickness = 1
    stroke.Color = Color3.fromRGB(80, 95, 145)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 18)
    title.Position = UDim2.new(0, 0, 0, 2)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextSize = 12
    title.TextColor3 = Color3.fromRGB(240, 245, 255)
    title.Text = "🌱 Działka " .. tostring(slotNum)
    title.Parent = bg

    local statusLbl = Instance.new("TextLabel")
    statusLbl.Size = UDim2.new(1, 0, 0, 22)
    statusLbl.Position = UDim2.new(0, 0, 0, 20)
    statusLbl.BackgroundTransparency = 1
    statusLbl.Font = Enum.Font.GothamMedium
    statusLbl.TextSize = 10
    statusLbl.TextColor3 = Color3.fromRGB(180, 190, 210)
    statusLbl.Text = "Sprawdzanie..."
    statusLbl.Parent = bg

    local hl = Instance.new("Highlight")
    hl.Name = "PlotHL_" .. tostring(slotNum)
    hl.Adornee = plot
    hl.FillTransparency = 0.7
    hl.OutlineTransparency = 0.3
    hl.FillColor = Color3.fromRGB(99, 102, 241)
    hl.OutlineColor = Color3.fromRGB(129, 140, 248)
    hl.Parent = ESPFolder

    return {
        Billboard = bbg,
        StatusLabel = statusLbl,
        TitleLabel = title,
        Highlight = hl,
        Plot = plot,
        Part = part,
        Slot = slotNum
    }
end

local function cleanupESP()
    for _, obj in pairs(ESPObjects) do
        if obj.Billboard then pcall(function() obj.Billboard:Destroy() end) end
        if obj.Highlight then pcall(function() obj.Highlight:Destroy() end) end
    end
    ESPObjects = {}
end

local function updateESP()
    if not Config.ESPEnabled or not _G.PS99GardenRunning then
        if #ESPObjects > 0 or ESPFolder:FindFirstChildWhichIsA("Instance") then
            cleanupESP()
        end
        return
    end

    local myPos = nil
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        myPos = LocalPlayer.Character.HumanoidRootPart.Position
    end

    for slot = 1, 20 do
        local slotKey = tostring(slot)
        local isFarming = Config.FarmSlots[slotKey]
        local shouldShow = true

        if Config.ESPMode == "Tylko Farmiące" and not isFarming then
            shouldShow = false
        end

        local obj = ESPObjects[slot]

        if not shouldShow then
            if obj then
                if obj.Billboard then obj.Billboard.Enabled = false end
                if obj.Highlight then obj.Highlight.Enabled = false end
            end
        else
            local plot = getPlotInstance(slot)
            if plot then
                if not obj or obj.Plot ~= plot then
                    if obj then
                        if obj.Billboard then pcall(function() obj.Billboard:Destroy() end) end
                        if obj.Highlight then pcall(function() obj.Highlight:Destroy() end) end
                    end
                    obj = createESPForPlot(slot, plot)
                    ESPObjects[slot] = obj
                end

                if obj then
                    local status, stage = checkPlotStatus(plot)
                    local distText = ""
                    if Config.ESPShowDistance and myPos and obj.Part then
                        local d = math.floor((obj.Part.Position - myPos).Magnitude)
                        distText = " [" .. tostring(d) .. "m]"
                    end

                    local statusText = ""
                    local col = Color3.fromRGB(160, 170, 190)
                    if status == "Gotowa" then
                        statusText = "Gotowa (" .. tostring(stage) .. ") 🌟"
                        col = Color3.fromRGB(46, 204, 113)
                    elseif status == "Rośnie" then
                        statusText = "Rośnie (" .. tostring(stage or "") .. ") ⏳"
                        col = Color3.fromRGB(241, 196, 15)
                    else
                        statusText = "Pusta (Gotowa do siania)"
                        col = Color3.fromRGB(129, 140, 248)
                    end

                    obj.Billboard.Enabled = true
                    if Config.ESPShowStatus then
                        obj.StatusLabel.Text = statusText .. distText
                        obj.StatusLabel.TextColor3 = col
                        obj.StatusLabel.Visible = true
                    else
                        obj.StatusLabel.Visible = false
                    end

                    if Config.ESPShowHighlight and obj.Highlight then
                        obj.Highlight.Enabled = true
                        obj.Highlight.FillColor = col
                        obj.Highlight.OutlineColor = col
                    elseif obj.Highlight then
                        obj.Highlight.Enabled = false
                    end
                end
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
    Name = "1. Auto Sadzenie (Auto Plant)",
    Default = Config.AutoPlant,
    Callback = function(val)
        Config.AutoPlant = val
    end
})

ModFarm:AddToggle({
    Name = "2. Auto Insta-Grow (Konewka / Kapsuła)",
    Default = Config.AutoInstaGrow,
    Callback = function(val)
        Config.AutoInstaGrow = val
    end
})

ModFarm:AddToggle({
    Name = "2b. Auto Zbieranie Wody z Kapsuły",
    Default = Config.AutoCapsuleClick,
    Callback = function(val)
        Config.AutoCapsuleClick = val
    end
})

ModFarm:AddToggle({
    Name = "2c. Zwykłe Podlewanie (Auto Water)",
    Default = Config.AutoWater,
    Callback = function(val)
        Config.AutoWater = val
    end
})

ModFarm:AddToggle({
    Name = "3. Auto Zbieranie Plonów (Auto Claim)",
    Default = Config.AutoClaim,
    Callback = function(val)
        Config.AutoClaim = val
    end
})

ModFarm:AddSlider({
    Name = "Opóźnienie Akcji",
    Min = 0.05,
    Max = 1.5,
    Step = 0.05,
    Suffix = " s",
    Default = Config.ActionDelay,
    Callback = function(val)
        Config.ActionDelay = val
    end
})

ModFarm:AddSlider({
    Name = "Opóźnienie Pętli",
    Min = 0.2,
    Max = 5.0,
    Step = 0.1,
    Suffix = " s",
    Default = Config.LoopDelay,
    Callback = function(val)
        Config.LoopDelay = val
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
    Name = "Zasadź Wszystkie Aktywne Działki",
    Callback = function()
        task.spawn(function()
            for s = 1, 20 do
                if Config.FarmSlots[tostring(s)] then
                    plantSlot(s)
                    task.wait(Config.ActionDelay)
                end
            end
        end)
    end
})

ModManual:AddButton({
    Name = "Użyj Insta-Grow na Aktywnych",
    Callback = function()
        task.spawn(function()
            for s = 1, 20 do
                if Config.FarmSlots[tostring(s)] then
                    instaGrowSlot(s)
                    task.wait(Config.ActionDelay)
                end
            end
        end)
    end
})

ModManual:AddButton({
    Name = "Podlej Aktywne Działki",
    Callback = function()
        task.spawn(function()
            for s = 1, 20 do
                if Config.FarmSlots[tostring(s)] then
                    waterSlot(s)
                    task.wait(Config.ActionDelay)
                end
            end
        end)
    end
})

ModManual:AddButton({
    Name = "Zbierz Wszystkie Dojrzałe Plony",
    Callback = function()
        task.spawn(function()
            for s = 1, 20 do
                harvestSlot(s)
                task.wait(0.05)
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
