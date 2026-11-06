-- // ==========================================================================
-- // PET SIMULATOR 99 - MASTER AUTOMATION & FLOWER GARDEN EVENT SUITE
-- // Dedicated script for MenuTest UI Library (https://github.com/XxvoltikxX/MenuTest)
-- // Game IDs: 8737899170 / 3317771874 (Pet Simulator 99 & Garden Event)
-- // Features:
-- //   1. AutoFarm Breakables (Diamonds, Chests, Safes, Crates, Presents, Coins)
-- //   2. Auto Collect (Orbs & Lootbags)
-- //   3. Player Speed Engine (Legit, Normal, CFrame, HVH) & Infinite Jump
-- //   4. Pet Speed Engine (Fast Pets, Max Force, Instant Target Snap)
-- //   5. Flower Garden AutoFarm (Plant, Insta-Grow with Capsule Water Click, Water, Claim)
-- //   6. Turbo Mode (Parallel Zero-Delay Execution) & Precise Delay Sliders
-- //   7. Slot ESP (1-20) with Status & 3D Highlight
-- //   8. Quick Slot Selection (1-20, Text Input) & Teleports & Anti-AFK
-- // ==========================================================================

-- // ==========================================================================
-- // 0. SPRZĄTANIE POPRZEDNIEJ INSTANCJI
-- // ==========================================================================
if _G._VoltikPS99Running and _G._VoltikPS99Cleanup then
    pcall(_G._VoltikPS99Cleanup)
end
if typeof(getgenv) == "function" and getgenv()._VoltikPS99Cleanup then
    pcall(getgenv()._VoltikPS99Cleanup)
end
if _G.PS99GardenCleanup then
    pcall(_G.PS99GardenCleanup)
end
_G._VoltikPS99Running = true

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
    warn("[PetHub] Nie udalo sie zaladowac biblioteki MenuTest!")
    return
end

-- // ==========================================================================
-- // 2. USŁUGI ROBLOX I REMOTY GRY
-- // ==========================================================================
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local ScriptRunning = true
local ScriptConnections = {}

-- Pet Simulator 99 Network & Remotes
local Library = nil
local Framework = nil
local NetworkFolder = nil

local function loadPS99Library()
    pcall(function()
        if ReplicatedStorage:FindFirstChild("Library") then
            Library = require(ReplicatedStorage.Library)
        end
    end)
    pcall(function()
        if ReplicatedStorage:FindFirstChild("Network") then
            NetworkFolder = ReplicatedStorage.Network
        end
    end)
    if typeof(getloadedmodules) == "function" then
        for _, mod in ipairs(getloadedmodules()) do
            if mod.Name == "Library" or mod.Name == "Framework" then
                local ok, res = pcall(require, mod)
                if ok and type(res) == "table" and (res.Network or res.Directory) then
                    Library = res
                    Framework = res
                    break
                end
            end
        end
    end
end
pcall(loadPS99Library)

-- Remote wywoływane w Pet Simulator 99
local function fireRemote(name, ...)
    local args = { ... }
    local sent = false
    if Library and Library.Network and typeof(Library.Network.Fire) == "function" then
        local ok = pcall(function() Library.Network.Fire(name, unpack(args)) end)
        if ok then sent = true end
    end
    if not sent and NetworkFolder then
        local rem = NetworkFolder:FindFirstChild(name)
        if rem and rem:IsA("RemoteEvent") then
            pcall(function() rem:FireServer(unpack(args)) end)
            sent = true
        end
    end
    if not sent and ReplicatedStorage:FindFirstChild("Network") then
        local r = ReplicatedStorage.Network:FindFirstChild(name)
        if r and r:IsA("RemoteEvent") then
            pcall(function() r:FireServer(unpack(args)) end)
            sent = true
        end
    end
    return sent
end

-- Remote specyficzne dla Flower Garden
local GardenNetwork = ReplicatedStorage:WaitForChild("Network", 10)
local InvokeCustom = GardenNetwork and GardenNetwork:WaitForChild("Instancing_InvokeCustomFromClient", 10)
local FireCustom = GardenNetwork and GardenNetwork:WaitForChild("Instancing_FireCustomFromClient", 10)
local ClickEvent = GardenNetwork and GardenNetwork:FindFirstChild("Click")

local ClientNetwork = nil
pcall(function()
    ClientNetwork = require(ReplicatedStorage.Library.Client.Network)
end)

-- // ==========================================================================
-- // 3. STAN GLOBALNY I KONFIGURACJA
-- // ==========================================================================
local State = {
    -- AutoFarm Breakables (Główna gra)
    FarmActive = false,
    FarmRange = 600,
    FarmInfiniteRange = false,
    FarmTargetType = "Wszystko (ALL)",
    FarmPriority = "ALL (Od Najlepszego do Najsłabszego)",
    FarmTypes = {
        ["Diamonds"] = true,
        ["Chest"] = true,
        ["Safe"] = true,
        ["Crate"] = true,
        ["Present"] = true,
        ["Large Coins"] = true,
        ["Coins"] = true,
    },
    FarmAnchorEnabled = false,
    FarmAnchorPos = nil,
    FarmAntiRecall = true,
    FarmInstantSnap = true,
    CurrentTargetCoin = nil,

    -- Auto Collect
    AutoOrbs = false,
    AutoLootbags = false,

    -- Player Speed
    PlayerSpeedEnabled = false,
    PlayerSpeedValue = 50,
    PlayerSpeedMode = "Legit",
    PlayerInfJump = false,

    -- Pet Speed
    PetSpeedEnabled = false,
    PetSpeedValue = 25,
    PetMaxForce = true,
    PetInstantSnap = true,

    -- Flower Garden Event
    GardenFarmEnabled = false,
    GardenFastMode = false,
    GardenAutoPlant = true,
    GardenAutoInstaGrow = true,
    GardenAutoCapsuleClick = true,
    GardenAutoWater = false,
    GardenAutoClaim = true,
    GardenSeedType = "Diamond",
    GardenCustomSeed = "",
    GardenActionDelay = 0.10,
    GardenLoopDelay = 0.50,
    GardenSlots = {
        ["1"] = true, ["2"] = true, ["3"] = true, ["4"] = true, ["5"] = true,
        ["6"] = false, ["7"] = false, ["8"] = false, ["9"] = false, ["10"] = false,
        ["11"] = false, ["12"] = false, ["13"] = false, ["14"] = false, ["15"] = false,
        ["16"] = false, ["17"] = false, ["18"] = false, ["19"] = false, ["20"] = false
    },

    -- ESP Działek
    ESPEnabled = false,
    ESPMode = "Tylko Farmiące",
    ESPShowStatus = true,
    ESPShowDistance = true,
    ESPShowHighlight = true,

    -- Utility
    AntiAFK = true,
    SelectedTPSlot = "1",

    -- Statystyki sesji ogrodu
    Stats = {
        Planted = 0,
        Grown = 0,
        Harvested = 0,
        WaterCollected = 0
    }
}

local SlotToggleAPIs = {}

-- // ==========================================================================
-- // 4. POMOCNICZE LOKALIZACJE STRUKTUR PS99
-- // ==========================================================================
local function getThingsFolder()
    if Library and Library.Things then return Library.Things end
    return Workspace:FindFirstChild("__THINGS") or Workspace:FindFirstChild("Things")
end

local cachedBreakablesFolders = {}
local lastBreakablesCheck = 0

local function getBreakablesFolders()
    local now = tick()
    if (now - lastBreakablesCheck < 5.0) and #cachedBreakablesFolders > 0 then
        local valid = true
        for _, f in ipairs(cachedBreakablesFolders) do
            if not f or not f.Parent then valid = false break end
        end
        if valid then return cachedBreakablesFolders end
    end
    lastBreakablesCheck = now

    local folders = {}
    local things = getThingsFolder()
    if things then
        local b = things:FindFirstChild("Breakables")
        if b then table.insert(folders, b) end
        local c = things:FindFirstChild("Coins")
        if c then table.insert(folders, c) end
    end
    local wBreak = Workspace:FindFirstChild("Breakables")
    if wBreak and not table.find(folders, wBreak) then table.insert(folders, wBreak) end
    local wCoins = Workspace:FindFirstChild("Coins")
    if wCoins and not table.find(folders, wCoins) then table.insert(folders, wCoins) end

    cachedBreakablesFolders = folders
    return folders
end

-- Detekcja Flower Garden w workspace
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

local function isFlowerGardenActive()
    return getPlantsFolder() ~= nil
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

-- // ==========================================================================
-- // 5. SILNIK AUTOFARM BREAKABLES (GŁÓWNY ŚWIAT PS99)
-- // ==========================================================================
local function getCoinPosition(coin)
    if not coin then return nil end
    if coin:IsA("BasePart") then return coin.Position end
    local posPart = coin:FindFirstChild("POS") or coin:FindFirstChild("Coin") or coin:FindFirstChild("Hitbox")
    if posPart and posPart:IsA("BasePart") then return posPart.Position end
    if coin:IsA("Model") then
        local pp = coin.PrimaryPart or coin:FindFirstChildWhichIsA("BasePart")
        if pp then return pp.Position end
        if coin.GetPivot then return coin:GetPivot().Position end
    end
    return nil
end

local function isCoinAlive(coin)
    if not coin or not coin.Parent then return false end
    if coin:GetAttribute("d") == true or coin:GetAttribute("Dead") == true or coin:GetAttribute("Destroyed") == true then
        return false
    end
    local hp = coin:GetAttribute("Health")
    if hp and hp <= 0 then return false end
    return getCoinPosition(coin) ~= nil
end

local function isCoinInRadius(coin, pPos, radius)
    if State.FarmInfiniteRange then return true, 0 end
    local cPos = getCoinPosition(coin)
    if not cPos then return false, math.huge end

    local checkPos = pPos
    if State.FarmAnchorEnabled and State.FarmAnchorPos then
        checkPos = State.FarmAnchorPos
    end

    local horizDist = (Vector3.new(checkPos.X, 0, checkPos.Z) - Vector3.new(cPos.X, 0, cPos.Z)).Magnitude
    local vertDist = math.abs(checkPos.Y - cPos.Y)
    local effectiveRadius = radius or State.FarmRange or 600

    if horizDist <= effectiveRadius and vertDist < 600 then
        return true, horizDist
    end
    return false, horizDist
end

local function detectCoinCategory(coin)
    if not coin then return "Coins", "Coin" end
    local rawName = tostring(coin:GetAttribute("Name") or coin:GetAttribute("CoinType") or coin:GetAttribute("Type") or coin.Name):lower()

    if rawName:find("diamond") or rawName:find("gem") then
        return "Diamonds", "Diamond"
    elseif rawName:find("chest") then
        return "Chest", "Chest"
    elseif rawName:find("safe") or rawName:find("vault") then
        return "Safe", "Safe"
    elseif rawName:find("crate") or rawName:find("barrel") or rawName:find("box") then
        return "Crate", "Crate"
    elseif rawName:find("present") or rawName:find("gift") then
        return "Present", "Present"
    elseif rawName:find("giant") or rawName:find("large") or rawName:find("big") then
        return "Large Coins", "Large Coin"
    end

    return "Coins", "Coin"
end

local DropdownToCategory = {
    ["Wszystko (ALL)"] = "ALL",
    ["Tylko Diamenty (Diamonds)"] = "Diamonds",
    ["Tylko Skrzynie (Chests)"] = "Chest",
    ["Tylko Sejfy (Safes)"] = "Safe",
    ["Tylko Skrzynki (Crates)"] = "Crate",
    ["Tylko Prezenty (Presents)"] = "Present",
    ["Tylko Duże Monety (Large)"] = "Large Coins",
    ["Tylko Zwykłe Monety (Coins)"] = "Coins",
    ["Wybrane w przełącznikach poniżej (Custom)"] = "CUSTOM",
}

local function isCoinAllowed(category)
    local selected = DropdownToCategory[State.FarmTargetType] or State.FarmTargetType
    if selected == "ALL" then return true end
    if selected == "CUSTOM" then
        return State.FarmTypes and State.FarmTypes[category] == true
    end
    return category == selected
end

local CategoryBaseScore = {
    ["Chest"]       = 800000,
    ["Diamonds"]    = 600000,
    ["Safe"]        = 400000,
    ["Present"]     = 300000,
    ["Crate"]       = 200000,
    ["Large Coins"] = 100000,
    ["Coins"]       = 50000,
}

local function evaluateCoinScore(category, hp, maxHp, dist)
    local priority = State.FarmPriority or "ALL (Od Najlepszego do Najsłabszego)"
    local baseScore = CategoryBaseScore[category] or 50000

    if priority:find("Najbliższe") then
        return 10000000 - (dist * 100)
    elseif priority:find("Najwięcej HP") then
        return (maxHp or 0) - (dist * 5)
    elseif priority:find("Najmniej HP") then
        return -(maxHp or 0) - (dist * 5)
    else
        return baseScore + ((maxHp or 0) / 50000) - (dist * 0.5)
    end
end

local function findBestCoin()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local pPos = (State.FarmAnchorEnabled and State.FarmAnchorPos) or hrp.Position

    local bestCoin = nil
    local bestScore = -math.huge

    for _, folder in ipairs(getBreakablesFolders()) do
        for _, coin in ipairs(folder:GetChildren()) do
            if isCoinAlive(coin) then
                local inRadius, dist = isCoinInRadius(coin, pPos, State.FarmRange)
                if inRadius then
                    local cat, _ = detectCoinCategory(coin)
                    if isCoinAllowed(cat) then
                        local hp = coin:GetAttribute("Health") or 100
                        local maxHp = coin:GetAttribute("MaxHealth") or hp
                        local score = evaluateCoinScore(cat, hp, maxHp, dist)
                        if score > bestScore then
                            bestScore = score
                            bestCoin = coin
                        end
                    end
                end
            end
        end
    end

    return bestCoin
end

local cachedEquippedUids = {}
local lastEquippedFetch = 0

local function getEquippedPets(force)
    local now = tick()
    if not force and (now - lastEquippedFetch < 1.0) and #cachedEquippedUids > 0 then
        return cachedEquippedUids
    end
    lastEquippedFetch = now

    local equipped = {}
    if Library and Library.PetCmds and typeof(Library.PetCmds.GetEquipped) == "function" then
        local eq = Library.PetCmds.GetEquipped(LocalPlayer, true)
        if type(eq) == "table" then
            for _, uid in ipairs(eq) do table.insert(equipped, uid) end
        end
    end
    if #equipped == 0 and Library and Library.Save and typeof(Library.Save.Get) == "function" then
        local save = Library.Save.Get()
        if save and save.Pets then
            for _, p in ipairs(save.Pets) do
                if p.e then table.insert(equipped, p.uid) end
            end
        end
    end
    if #equipped == 0 then
        local things = getThingsFolder()
        local petsFolder = things and things:FindFirstChild("Pets")
        if petsFolder then
            for _, p in ipairs(petsFolder:GetChildren()) do
                if p:GetAttribute("Owner") == LocalPlayer.Name or p.Name:find(LocalPlayer.Name, 1, true) then
                    table.insert(equipped, p.Name)
                end
            end
        end
    end

    cachedEquippedUids = equipped
    return equipped
end

local function isMyPet(pet, optionalUids)
    if not pet then return false end
    local owner = pet:GetAttribute("Owner")
    if owner and tostring(owner) == LocalPlayer.Name then return true end
    if pet.Name:find(LocalPlayer.Name, 1, true) then return true end
    local myUids = optionalUids or getEquippedPets()
    local uid = pet:GetAttribute("UID") or pet.Name
    if table.find(myUids, uid) or table.find(myUids, pet.Name) then return true end
    return false
end

local petMoverCache = setmetatable({}, { __mode = "k" })

local function updateWorkspacePetsPhysics()
    local things = getThingsFolder()
    local petsFolder = things and things:FindFirstChild("Pets")
    if not petsFolder then return end

    local mult = tonumber(State.PetSpeedValue) or 25
    local pForce = math.clamp(20000 * mult, 20000, 10000000)

    local targetCoin = State.CurrentTargetCoin
    local targetPos = (targetCoin and isCoinAlive(targetCoin) and getCoinPosition(targetCoin)) or nil
    local myUids = getEquippedPets()

    for _, pet in ipairs(petsFolder:GetChildren()) do
        if isMyPet(pet, myUids) then
            local moverData = petMoverCache[pet]
            if not moverData or not moverData.bp or not moverData.bp.Parent then
                local bp = pet:FindFirstChildWhichIsA("BodyPosition", true)
                local ap = pet:FindFirstChildWhichIsA("AlignPosition", true)
                moverData = { bp = bp, ap = ap }
                petMoverCache[pet] = moverData
            end

            local bp = moverData.bp
            if bp and bp.Parent then
                if State.PetSpeedEnabled then
                    bp.MaxForce = Vector3.new(1e8, 1e8, 1e8)
                    bp.P = pForce
                    if State.PetMaxForce or mult >= 15 then bp.D = 250 end
                end
                if targetPos and (State.FarmAntiRecall or State.FarmAnchorEnabled or State.FarmInfiniteRange) then
                    bp.Position = targetPos + Vector3.new(math.random(-2, 2), 1, math.random(-2, 2))
                end
            end

            local ap = moverData.ap
            if ap and ap.Parent and State.PetSpeedEnabled then
                ap.MaxForce = 1e8
                ap.Responsiveness = math.clamp(20 * (mult / 2), 20, 200)
            end
        end
    end
end

local function attackCoin(coin)
    if not isCoinAlive(coin) then return end
    State.CurrentTargetCoin = coin
    local coinId = coin:GetAttribute("ID") or coin.Name

    task.spawn(function()
        if State.PetSpeedEnabled and State.PetInstantSnap then
            local coinPos = getCoinPosition(coin)
            if coinPos then
                local things = getThingsFolder()
                local petsFolder = things and things:FindFirstChild("Pets")
                if petsFolder then
                    local myUids = getEquippedPets()
                    for _, pet in ipairs(petsFolder:GetChildren()) do
                        if isMyPet(pet, myUids) then
                            local bp = pet:FindFirstChildWhichIsA("BodyPosition", true)
                            local offset = Vector3.new(math.random(-3, 3), 1, math.random(-3, 3))
                            if bp then
                                bp.Position = coinPos + offset
                            elseif pet.PivotTo then
                                pet:PivotTo(CFrame.new(coinPos + offset))
                            end
                        end
                    end
                end
            end
        end

        local eq = getEquippedPets()
        if #eq > 0 then
            for _, uid in ipairs(eq) do
                fireRemote("Breakables_PlayerAttackBreakable", coinId, uid)
                fireRemote("Breakables_JoinPet", coinId, uid)
            end
        else
            fireRemote("Breakables_PlayerAttackBreakable", coinId)
        end
        fireRemote("Farm Coin", coinId)

        local cd = coin:FindFirstChildWhichIsA("ClickDetector", true)
        if cd and typeof(fireclickdetector) == "function" then
            pcall(function() fireclickdetector(cd) end)
        end
    end)
end

-- // ==========================================================================
-- // 6. AUTO COLLECT: ORBS I LOOTBAGS
-- // ==========================================================================
local function collectOrbsClean()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local things = getThingsFolder()
    local orbsFolder = things and things:FindFirstChild("Orbs")
    if not orbsFolder then return end

    local children = orbsFolder:GetChildren()
    if #children == 0 then return end

    local claimedIds = {}
    local groundCFrame = hrp.CFrame * CFrame.new(0, 5, 0)
    local groundPos = groundCFrame.Position

    for _, orb in ipairs(children) do
        table.insert(claimedIds, orb.Name)
        if orb:IsA("BasePart") then
            orb.CanCollide = false
            orb.CFrame = groundCFrame
            orb.Velocity = Vector3.zero
            local bp = orb:FindFirstChildOfClass("BodyPosition")
            if bp then
                bp.Position = groundPos
                bp.MaxForce = Vector3.new(1e7, 1e7, 1e7)
                bp.P = 50000
            end
        elseif orb:IsA("Model") then
            if orb.PivotTo then orb:PivotTo(groundCFrame)
            elseif orb.PrimaryPart then orb:SetPrimaryPartCFrame(groundCFrame) end
        end
    end

    if #claimedIds > 0 then
        fireRemote("Orbs: Collect", claimedIds)
        fireRemote("Claim Orbs", claimedIds)
    end
end

local function collectLootbagsClean()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local things = getThingsFolder()
    local lootbagsFolder = things and things:FindFirstChild("Lootbags")
    if not lootbagsFolder then return end

    local children = lootbagsFolder:GetChildren()
    if #children == 0 then return end

    local groundCFrame = hrp.CFrame * CFrame.new(0, -2, 0)
    local hasFireTouch = typeof(firetouchinterest) == "function"
    local claimed = {}

    for _, bag in ipairs(children) do
        table.insert(claimed, bag.Name)
        if bag:IsA("BasePart") then
            bag.CanCollide = false
            bag.CFrame = groundCFrame
            bag.Velocity = Vector3.zero
            if hasFireTouch then
                pcall(function()
                    firetouchinterest(hrp, bag, 0)
                    firetouchinterest(hrp, bag, 1)
                end)
            end
        elseif bag:IsA("Model") then
            local mp = bag.PrimaryPart or bag:FindFirstChildWhichIsA("BasePart")
            if bag.PivotTo then bag:PivotTo(groundCFrame)
            elseif mp then mp.CFrame = groundCFrame end
            if mp and hasFireTouch then
                pcall(function()
                    firetouchinterest(hrp, mp, 0)
                    firetouchinterest(hrp, mp, 1)
                end)
            end
        end
    end

    if #claimed > 0 then
        fireRemote("Lootbags_Claim", claimed)
    end
end

-- Pętle w tle dla breakables i collect
task.spawn(function()
    while ScriptRunning do
        if State.FarmActive then
            local target = findBestCoin()
            if target then
                attackCoin(target)
            end
        end
        task.wait(0.12)
    end
end)

task.spawn(function()
    while ScriptRunning do
        if State.AutoOrbs then pcall(collectOrbsClean) end
        if State.AutoLootbags then pcall(collectLootbagsClean) end
        task.wait(0.25)
    end
end)

-- Pętla fizyki petów
local petConn = RunService.Heartbeat:Connect(function()
    if not ScriptRunning then return end
    if State.PetSpeedEnabled then
        pcall(updateWorkspacePetsPhysics)
    end
end)
table.insert(ScriptConnections, petConn)

-- Pętla prędkości gracza
local speedConn = RunService.Heartbeat:Connect(function(dt)
    if not ScriptRunning then return end
    if State.PlayerSpeedEnabled then
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hum and hrp then
            if State.PlayerSpeedMode == "Normal" or State.PlayerSpeedMode == "Legit" then
                hum.WalkSpeed = State.PlayerSpeedValue
            elseif State.PlayerSpeedMode == "CFrame" or State.PlayerSpeedMode == "HVH" then
                if hum.MoveDirection.Magnitude > 0 then
                    local moveVector = hum.MoveDirection.Unit * (State.PlayerSpeedValue * dt)
                    hrp.CFrame = hrp.CFrame + moveVector
                end
            end
        end
    end
end)
table.insert(ScriptConnections, speedConn)

-- Infinite Jump
local jumpConn = UserInputService.JumpRequest:Connect(function()
    if State.PlayerInfJump and ScriptRunning then
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)
table.insert(ScriptConnections, jumpConn)

-- // ==========================================================================
-- // 7. LOGIKA FLOWER GARDEN EVENT (ZGODNA 1:1 Z ORYGINAŁEM)
-- // ==========================================================================
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
    State.Stats.WaterCollected = State.Stats.WaterCollected + 1
end

local function getActiveGardenSeedName()
    if State.GardenCustomSeed and State.GardenCustomSeed:gsub("%s+", "") ~= "" then
        return State.GardenCustomSeed:gsub("%s+", "")
    end
    return State.GardenSeedType or "Diamond"
end

local function getSortedGardenSlots()
    local slots = {}
    for slotStr, enabled in pairs(State.GardenSlots) do
        if enabled then
            local num = tonumber(slotStr)
            if num then table.insert(slots, num) end
        end
    end
    table.sort(slots)
    return slots
end

local function executeGardenSlotActions(slotNum, seed)
    -- 1. Auto Plant
    if State.GardenAutoPlant and InvokeCustom then
        pcall(function()
            InvokeCustom:InvokeServer("FlowerGarden", "PlantSeed", slotNum, seed)
            State.Stats.Planted = State.Stats.Planted + 1
        end)
        if not State.GardenFastMode and State.GardenActionDelay > 0 then
            task.wait(State.GardenActionDelay)
        end
    end

    -- 2. Auto Insta Grow (Woda z kapsuły + insta-grow)
    if State.GardenAutoInstaGrow and InvokeCustom then
        if State.GardenAutoCapsuleClick then
            clickCapsule()
        end
        pcall(function()
            InvokeCustom:InvokeServer("FlowerGarden", "InstaGrowSeed", slotNum)
            State.Stats.Grown = State.Stats.Grown + 1
        end)
        if not State.GardenFastMode and State.GardenActionDelay > 0 then
            task.wait(State.GardenActionDelay)
        end
    end

    -- 2b. Auto Water (Zwykłe podlewanie konewką)
    if State.GardenAutoWater and InvokeCustom then
        pcall(function()
            InvokeCustom:InvokeServer("FlowerGarden", "WaterSeed", slotNum)
        end)
        if not State.GardenFastMode and State.GardenActionDelay > 0 then
            task.wait(State.GardenActionDelay)
        end
    end

    -- 3. Auto Claim (Zbiór plonów)
    if State.GardenAutoClaim and FireCustom then
        pcall(function()
            FireCustom:FireServer("FlowerGarden", "ClaimPlant", slotNum)
            State.Stats.Harvested = State.Stats.Harvested + 1
        end)
        if not State.GardenFastMode and State.GardenActionDelay > 0 then
            task.wait(State.GardenActionDelay)
        end
    end
end

-- Główny wątek Flower Garden AutoFarm
task.spawn(function()
    while ScriptRunning do
        if State.GardenFarmEnabled then
            local slotsToFarm = getSortedGardenSlots()
            local seed = getActiveGardenSeedName()

            if State.GardenFastMode then
                if State.GardenAutoInstaGrow and State.GardenAutoCapsuleClick then
                    clickCapsule()
                end
                for _, slotNum in ipairs(slotsToFarm) do
                    if not State.GardenFarmEnabled then break end
                    task.spawn(function()
                        executeGardenSlotActions(slotNum, seed)
                    end)
                end
            else
                for _, slotNum in ipairs(slotsToFarm) do
                    if not State.GardenFarmEnabled then break end
                    executeGardenSlotActions(slotNum, seed)
                end
            end
        end

        if State.GardenLoopDelay > 0 then
            task.wait(State.GardenLoopDelay)
        else
            task.wait()
        end
    end
end)

-- // ==========================================================================
-- // 8. SYSTEM ESP DZIAŁEK OGRODU
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

    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
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
    if not State.ESPEnabled or not ScriptRunning then
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
            if State.ESPMode == "Tylko Farmiące" then
                shouldShow = (State.GardenSlots[slotStr] == true)
            end

            if shouldShow then
                local plot = getPlotInstance(slotNum)
                local part = getPlotBasePart(plot)

                if plot and part then
                    esp.Billboard.Adornee = part
                    esp.Billboard.Enabled = true

                    local statusText, statusColor = checkPlotStatus(plot)
                    local distText = ""
                    if State.ESPShowDistance and myPos then
                        local d = math.floor((part.Position - myPos).Magnitude)
                        distText = " [" .. tostring(d) .. "m]"
                    end

                    if State.ESPShowStatus then
                        esp.StatusLabel.Text = statusText .. distText
                        esp.StatusLabel.TextColor3 = statusColor
                        esp.Stroke.Color = statusColor
                        esp.StatusLabel.Visible = true
                    else
                        esp.StatusLabel.Visible = false
                    end

                    if State.ESPShowHighlight then
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
    if not ScriptRunning then return end
    espTimer = espTimer + dt
    if espTimer >= 0.15 then
        espTimer = 0
        pcall(updateESP)
    end
end)
table.insert(ScriptConnections, espConn)

-- Anti-AFK
local afkConn = LocalPlayer.Idled:Connect(function()
    if State.AntiAFK and ScriptRunning then
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    end
end)
table.insert(ScriptConnections, afkConn)

-- // ==========================================================================
-- // 9. BUDOWA INTERFEJSU UŻYTKOWNIKA (MENUTEST UI)
-- // ==========================================================================
local Window = MENU:CreateWindow({
    Name = "PetHub",
    Tittle = "Pet Simulator 99",
    TittlePos = "Center",
    ToggleUIKeybind = "K",
    TestMobile = false,
    GameId = "8737899170"
})

-- Zakładki
local TabGeneral = Window:CreateTab("Auto Farm", "zap")
local TabGarden  = Window:CreateTab("Event Ogród", "layers")
local TabSlots   = Window:CreateTab("Działki", "sliders")
local TabESP     = Window:CreateTab("ESP Działek", "eye")
local TabPlayer  = Window:CreateTab("Gracz & Pety", "user")
local TabUtils   = Window:CreateTab("Teleporty", "wind")

-- --------------------------------------------------------------------------
-- ZAKŁADKA 1: AUTOFARM GŁÓWNY (BREAKABLES / DIAMENTY / MONETY)
-- --------------------------------------------------------------------------
local ModMainFarm = TabGeneral:CreateModule({
    Name = "AutoFarm Breakables",
    Description = "Inteligentne bicie monet, diamentów, skrzyń i sejfów",
    Default = false,
    Expanded = true,
    Callback = function(val)
        State.FarmActive = val
    end
})

ModMainFarm:AddDropdown({
    Name = "Typ Celu",
    Options = {
        "Wszystko (ALL)",
        "Tylko Diamenty (Diamonds)",
        "Tylko Skrzynie (Chests)",
        "Tylko Sejfy (Safes)",
        "Tylko Skrzynki (Crates)",
        "Tylko Prezenty (Presents)",
        "Tylko Duże Monety (Large)",
        "Tylko Zwykłe Monety (Coins)",
        "Wybrane w przełącznikach poniżej (Custom)"
    },
    CurrentOption = {"Wszystko (ALL)"},
    Callback = function(opt)
        State.FarmTargetType = type(opt) == "table" and opt[1] or opt
    end
})

ModMainFarm:AddDropdown({
    Name = "Priorytet Celu",
    Options = {
        "ALL (Od Najlepszego do Najsłabszego)",
        "Najbliższe (Najmniejszy Dystans)",
        "Najwięcej HP (Maksymalne Zdrowie)",
        "Najmniej HP (Szybkie Niszczenie)"
    },
    CurrentOption = {"ALL (Od Najlepszego do Najsłabszego)"},
    Callback = function(opt)
        State.FarmPriority = type(opt) == "table" and opt[1] or opt
    end
})

ModMainFarm:AddSlider({
    Name = "Zasięg Radaru (Range)",
    Range = {50, 1500},
    Min = 50,
    Max = 1500,
    Step = 25,
    Increment = 25,
    Default = 600,
    CurrentValue = 600,
    Suffix = " studs",
    Callback = function(val)
        State.FarmRange = val
    end
})

ModMainFarm:AddToggle({
    Name = "Nieskończony Zasięg (Cała Mapa)",
    Default = false,
    Callback = function(val)
        State.FarmInfiniteRange = val
    end
})

ModMainFarm:AddToggle({
    Name = "Kotwica Pozycji Gracza (Farm w Strefie)",
    Default = false,
    Callback = function(val)
        State.FarmAnchorEnabled = val
        if val then
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then State.FarmAnchorPos = hrp.Position end
        else
            State.FarmAnchorPos = nil
        end
    end
})

local ModFarmCustomTypes = TabGeneral:CreateModule({
    Name = "Filtry Własne (Custom Targets)",
    Description = "Zaznacz typy breakables dla trybu Custom",
    Default = false,
    Expanded = false
})

ModFarmCustomTypes:AddToggle({ Name = "Diamenty (Diamonds)", Default = true, Callback = function(v) State.FarmTypes["Diamonds"] = v end })
ModFarmCustomTypes:AddToggle({ Name = "Skrzynie (Chests)", Default = true, Callback = function(v) State.FarmTypes["Chest"] = v end })
ModFarmCustomTypes:AddToggle({ Name = "Sejfy (Safes)", Default = true, Callback = function(v) State.FarmTypes["Safe"] = v end })
ModFarmCustomTypes:AddToggle({ Name = "Skrzynki (Crates)", Default = true, Callback = function(v) State.FarmTypes["Crate"] = v end })
ModFarmCustomTypes:AddToggle({ Name = "Prezenty (Presents)", Default = true, Callback = function(v) State.FarmTypes["Present"] = v end })
ModFarmCustomTypes:AddToggle({ Name = "Duże Monety (Large Coins)", Default = true, Callback = function(v) State.FarmTypes["Large Coins"] = v end })
ModFarmCustomTypes:AddToggle({ Name = "Zwykłe Monety (Coins)", Default = true, Callback = function(v) State.FarmTypes["Coins"] = v end })

local ModCollect = TabGeneral:CreateModule({
    Name = "Auto Collect (Orby & Lootbags)",
    Description = "Błyskawiczne przyciąganie i odbieranie dropu",
    Default = false,
    Expanded = true
})

ModCollect:AddToggle({
    Name = "Auto Collect Orbs",
    Default = false,
    Callback = function(val) State.AutoOrbs = val end
})

ModCollect:AddToggle({
    Name = "Auto Collect Lootbags",
    Default = false,
    Callback = function(val) State.AutoLootbags = val end
})

-- --------------------------------------------------------------------------
-- ZAKŁADKA 2: FLOWER GARDEN EVENT
-- --------------------------------------------------------------------------
local ModGarden = TabGarden:CreateModule({
    Name = "Automat Ogrodu (Flower Garden)",
    Description = "Automatyczne sadzenie, picie wody z kapsuły i zbiory",
    Default = false,
    Expanded = true,
    Callback = function(val)
        State.GardenFarmEnabled = val
    end
})

ModGarden:AddToggle({
    Name = "⚡ Tryb Turbo (Maksymalne Przyspieszenie)",
    Default = State.GardenFastMode,
    Callback = function(val)
        State.GardenFastMode = val
    end
})

ModGarden:AddDropdown({
    Name = "Rodzaj Nasiona",
    Options = {"Diamond", "Coin", "Gift", "Potion", "Enchant", "Własne"},
    CurrentOption = {State.GardenSeedType},
    Callback = function(opt)
        State.GardenSeedType = type(opt) == "table" and opt[1] or opt
    end
})

ModGarden:AddInput({
    Name = "Własne Nasiono (Custom)",
    PlaceholderText = "Wpisz dokładną nazwę nasiona...",
    Callback = function(text)
        State.GardenCustomSeed = text
    end
})

ModGarden:AddToggle({
    Name = "Krok 1: Auto Sadzenie (Auto Plant)",
    Default = State.GardenAutoPlant,
    Callback = function(val) State.GardenAutoPlant = val end
})

ModGarden:AddToggle({
    Name = "Krok 2: Auto Insta-Grow (Konewka / Kapsuła)",
    Default = State.GardenAutoInstaGrow,
    Callback = function(val) State.GardenAutoInstaGrow = val end
})

ModGarden:AddToggle({
    Name = "Krok 2b: Auto Zbieranie Wody z Kapsuły",
    Default = State.GardenAutoCapsuleClick,
    Callback = function(val) State.GardenAutoCapsuleClick = val end
})

ModGarden:AddToggle({
    Name = "Krok 2c: Zwykłe Podlewanie (Auto Water)",
    Default = State.GardenAutoWater,
    Callback = function(val) State.GardenAutoWater = val end
})

ModGarden:AddToggle({
    Name = "Krok 3: Auto Zbieranie Plonów (Auto Claim)",
    Default = State.GardenAutoClaim,
    Callback = function(val) State.GardenAutoClaim = val end
})

ModGarden:AddSlider({
    Name = "Opóźnienie Akcji",
    Range = {0, 1.0},
    Min = 0,
    Max = 1.0,
    Step = 0.01,
    Increment = 0.01,
    Precise = true,
    Decimals = 2,
    Suffix = "s",
    Default = State.GardenActionDelay,
    CurrentValue = State.GardenActionDelay,
    Callback = function(val)
        State.GardenActionDelay = tonumber(string.format("%.2f", val)) or val
    end
})

ModGarden:AddSlider({
    Name = "Pauza Między Pętlami",
    Range = {0, 5.0},
    Min = 0,
    Max = 5.0,
    Step = 0.05,
    Increment = 0.05,
    Precise = true,
    Decimals = 2,
    Suffix = "s",
    Default = State.GardenLoopDelay,
    CurrentValue = State.GardenLoopDelay,
    Callback = function(val)
        State.GardenLoopDelay = tonumber(string.format("%.2f", val)) or val
    end
})

local ModManual = TabGarden:CreateModule({
    Name = "Ręczne Akcje Ogrodu",
    Description = "Natychmiastowe wywołanie pojedynczej akcji",
    Default = false,
    Expanded = false
})

ModManual:AddButton({
    Name = "Zbierz Wodę z Kapsuły (Click)",
    Callback = function() clickCapsule() end
})

ModManual:AddButton({
    Name = "Zasadź Zaznaczone Działki",
    Callback = function()
        local slots = getSortedGardenSlots()
        local seed = getActiveGardenSeedName()
        task.spawn(function()
            for _, s in ipairs(slots) do
                if InvokeCustom then
                    pcall(function()
                        InvokeCustom:InvokeServer("FlowerGarden", "PlantSeed", s, seed)
                        State.Stats.Planted = State.Stats.Planted + 1
                    end)
                end
                if State.GardenActionDelay > 0 then task.wait(State.GardenActionDelay) end
            end
        end)
    end
})

ModManual:AddButton({
    Name = "Użyj Insta-Grow na Zaznaczonych",
    Callback = function()
        local slots = getSortedGardenSlots()
        task.spawn(function()
            for _, s in ipairs(slots) do
                if State.GardenAutoCapsuleClick then clickCapsule() end
                if InvokeCustom then
                    pcall(function()
                        InvokeCustom:InvokeServer("FlowerGarden", "InstaGrowSeed", s)
                        State.Stats.Grown = State.Stats.Grown + 1
                    end)
                end
                if State.GardenActionDelay > 0 then task.wait(State.GardenActionDelay) end
            end
        end)
    end
})

ModManual:AddButton({
    Name = "Podlej Zaznaczone Działki",
    Callback = function()
        local slots = getSortedGardenSlots()
        task.spawn(function()
            for _, s in ipairs(slots) do
                if InvokeCustom then
                    pcall(function()
                        InvokeCustom:InvokeServer("FlowerGarden", "WaterSeed", s)
                    end)
                end
                if State.GardenActionDelay > 0 then task.wait(State.GardenActionDelay) end
            end
        end)
    end
})

ModManual:AddButton({
    Name = "Zbierz Wszystkie Dojrzałe Plony",
    Callback = function()
        local slots = getSortedGardenSlots()
        task.spawn(function()
            for _, s in ipairs(slots) do
                if FireCustom then
                    pcall(function()
                        FireCustom:FireServer("FlowerGarden", "ClaimPlant", s)
                        State.Stats.Harvested = State.Stats.Harvested + 1
                    end)
                end
                if State.GardenActionDelay > 0 then task.wait(State.GardenActionDelay) end
            end
        end)
    end
})

-- --------------------------------------------------------------------------
-- ZAKŁADKA 3: DZIAŁKI (1-20)
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
            State.GardenSlots[tostring(i)] = true
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
            State.GardenSlots[tostring(i)] = false
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
            local st = (i <= 5)
            State.GardenSlots[tostring(i)] = st
            if SlotToggleAPIs[i] and SlotToggleAPIs[i].Set then
                SlotToggleAPIs[i]:Set(st)
            end
        end
    end
})

ModQuickSelect:AddButton({
    Name = "Tylko Pierwsze 10 (Działki 1-10)",
    Callback = function()
        for i = 1, 20 do
            local st = (i <= 10)
            State.GardenSlots[tostring(i)] = st
            if SlotToggleAPIs[i] and SlotToggleAPIs[i].Set then
                SlotToggleAPIs[i]:Set(st)
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
                State.GardenSlots[tostring(i)] = false
                if SlotToggleAPIs[i] and SlotToggleAPIs[i].Set then
                    SlotToggleAPIs[i]:Set(false)
                end
            end
            for numStr in text:gmatch("%d+") do
                local n = tonumber(numStr)
                if n and n >= 1 and n <= 20 then
                    State.GardenSlots[tostring(n)] = true
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
    Description = "Wybór pojedynczych slotów",
    Default = false,
    Expanded = true
})

for i = 1, 10 do
    local s = tostring(i)
    SlotToggleAPIs[i] = ModSlots1to10:AddToggle({
        Name = "Działka " .. s,
        Default = State.GardenSlots[s] or false,
        Callback = function(val) State.GardenSlots[s] = val end
    })
end

local ModSlots11to20 = TabSlots:CreateModule({
    Name = "Działki 11 do 20",
    Description = "Wybór pojedynczych slotów",
    Default = false,
    Expanded = true
})

for i = 11, 20 do
    local s = tostring(i)
    SlotToggleAPIs[i] = ModSlots11to20:AddToggle({
        Name = "Działka " .. s,
        Default = State.GardenSlots[s] or false,
        Callback = function(val) State.GardenSlots[s] = val end
    })
end

-- --------------------------------------------------------------------------
-- ZAKŁADKA 4: ESP DZIAŁEK
-- --------------------------------------------------------------------------
local ModESP = TabESP:CreateModule({
    Name = "Wizualizacja ESP",
    Description = "Status i odległość do działek",
    Default = false,
    Expanded = true,
    Callback = function(val)
        State.ESPEnabled = val
        if not val then cleanupESP() end
    end
})

ModESP:AddDropdown({
    Name = "Tryb Wyświetlania",
    Options = {"Tylko Farmiące", "Wszystkie (1-20)"},
    CurrentOption = {State.ESPMode},
    Callback = function(opt)
        State.ESPMode = type(opt) == "table" and opt[1] or opt
    end
})

ModESP:AddToggle({
    Name = "Pokaż Status Rośliny (Pusta/Rośnie/Gotowa)",
    Default = State.ESPShowStatus,
    Callback = function(val) State.ESPShowStatus = val end
})

ModESP:AddToggle({
    Name = "Pokaż Odległość (Dystans w Studs)",
    Default = State.ESPShowDistance,
    Callback = function(val) State.ESPShowDistance = val end
})

ModESP:AddToggle({
    Name = "Podświetlenie Modelu (Highlight 3D)",
    Default = State.ESPShowHighlight,
    Callback = function(val) State.ESPShowHighlight = val end
})

-- --------------------------------------------------------------------------
-- ZAKŁADKA 5: GRACZ & PETY
-- --------------------------------------------------------------------------
local ModPlayerSpeed = TabPlayer:CreateModule({
    Name = "Silnik Prędkości Gracza",
    Description = "Zwiększenie prędkości poruszania się",
    Default = false,
    Expanded = true,
    Callback = function(val) State.PlayerSpeedEnabled = val end
})

ModPlayerSpeed:AddSlider({
    Name = "Wartość Prędkości (Speed)",
    Range = {16, 250},
    Min = 16,
    Max = 250,
    Step = 1,
    Increment = 1,
    Default = 50,
    CurrentValue = 50,
    Suffix = " studs/s",
    Callback = function(val) State.PlayerSpeedValue = val end
})

ModPlayerSpeed:AddDropdown({
    Name = "Tryb Prędkości",
    Options = {"Legit", "Normal", "CFrame", "HVH"},
    CurrentOption = {"Legit"},
    Callback = function(opt)
        State.PlayerSpeedMode = type(opt) == "table" and opt[1] or opt
    end
})

ModPlayerSpeed:AddToggle({
    Name = "Infinite Jump (Nieskończony Skok)",
    Default = false,
    Callback = function(val) State.PlayerInfJump = val end
})

local ModPetSpeed = TabPlayer:CreateModule({
    Name = "Silnik Prędkości Petów",
    Description = "Zwiększenie siły fizyki i natychmiastowy przeskok petów",
    Default = false,
    Expanded = true,
    Callback = function(val) State.PetSpeedEnabled = val end
})

ModPetSpeed:AddSlider({
    Name = "Mnożnik Prędkości Petów",
    Range = {1, 100},
    Min = 1,
    Max = 100,
    Step = 1,
    Increment = 1,
    Default = 25,
    CurrentValue = 25,
    Suffix = "x",
    Callback = function(val) State.PetSpeedValue = val end
})

ModPetSpeed:AddToggle({
    Name = "Maksymalna Siła Fizyki (Max Force)",
    Default = true,
    Callback = function(val) State.PetMaxForce = val end
})

ModPetSpeed:AddToggle({
    Name = "Natychmiastowy Przeskok (Instant Snap)",
    Default = true,
    Callback = function(val) State.PetInstantSnap = val end
})

-- --------------------------------------------------------------------------
-- ZAKŁADKA 6: TELEPORTY & NARZĘDZIA
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
    Callback = function() tpToPos(Vector3.new(-442, 112, -1418)) end
})

ModTP:AddButton({
    Name = "Teleport na Środek Ogrodu",
    Callback = function() tpToPos(Vector3.new(-477, 112, -1403)) end
})

local slotOptions = {}
for i = 1, 20 do table.insert(slotOptions, tostring(i)) end

ModTP:AddDropdown({
    Name = "Wybierz Numer Działki",
    Options = slotOptions,
    CurrentOption = {State.SelectedTPSlot},
    Callback = function(opt)
        State.SelectedTPSlot = type(opt) == "table" and opt[1] or opt
    end
})

ModTP:AddButton({
    Name = "Teleportuj do Wybranej Działki",
    Callback = function()
        local plot = getPlotInstance(State.SelectedTPSlot)
        local part = getPlotBasePart(plot)
        if part then tpToPos(part.Position) end
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
            pcall(function() FireCustom:FireServer("FlowerGarden", "ClaimChest") end)
        end
    end
})

ModBonus:AddToggle({
    Name = "Anti-AFK (Ochrona przed rozłączeniem)",
    Default = State.AntiAFK,
    Callback = function(val) State.AntiAFK = val end
})

-- // ==========================================================================
-- // 10. CLEANUP HANDLER
-- // ==========================================================================
local function fullCleanup()
    ScriptRunning = false
    _G._VoltikPS99Running = false
    State.FarmActive = false
    State.GardenFarmEnabled = false
    State.ESPEnabled = false
    State.PlayerSpeedEnabled = false
    State.PetSpeedEnabled = false

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

_G._VoltikPS99Cleanup = fullCleanup
_G.PS99GardenCleanup = fullCleanup
if typeof(getgenv) == "function" then
    getgenv()._VoltikPS99Cleanup = fullCleanup
    getgenv()._PS99GardenCleanup = fullCleanup
end

if Window and Window.ScreenGui then
    Window.ScreenGui.Destroying:Connect(fullCleanup)
end
