-- // ==========================================================================
-- // PET SIMULATOR 99 (GARDEN EVENT) - AUTOMATION & EXPLOIT SUITE
-- // Dedicated script for MenuTest UI Library (https://github.com/XxvoltikxX/MenuTest)
-- // Features: AutoFarm Breakables, Auto Garden (Harvest/Water/Plant), Auto Collect,
-- //           Player Speed Engine, Pet Speed Engine, Garden Teleports & Utilities
-- // PlaceId: 8737899170
-- // Tabs: General, Garden
-- // ==========================================================================

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
-- // 2. USŁUGI ROBLOX I STAN SKRYPTU
-- // ==========================================================================
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer
local ScriptRunning = true
local ScriptConnections = {}

-- Globalny stan konfiguracji
local State = {
    -- AutoFarm Breakables
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
    PlayerSpeedMode = "Legit", -- "Legit", "CFrame", "Normal", "HVH"
    PlayerInfJump = false,

    -- Pet Speed
    PetSpeedEnabled = false,
    PetSpeedValue = 25,
    PetMaxForce = true,
    PetInstantSnap = true,

    -- Garden Automation
    GardenAutoHarvest = false,
    GardenHarvestDelay = 1.0,
    GardenAutoWater = false,
    GardenWaterDelay = 2.0,
    GardenAutoPlant = false,
    GardenSelectedSeed = "Diamond",
    GardenPlantDelay = 1.5,
    GardenInstaPlant = false,
    GardenInstaPlantDelay = 0.5,
    GardenActionDelay = 0.25,
    GardenLoopDelay = 0.8,
    GardenStepPlant = true,
    GardenStepInstaGrow = true,
    GardenStepWater = false,
    GardenStepClaim = true,
    GardenAutoEquipCan = true,
    GardenFarmSlots = {
        [1] = true, [2] = true, [3] = true, [4] = true, [5] = true,
        [6] = true, [7] = true, [8] = true, [9] = true, [10] = true
    },
    -- Garden ESP
    GardenESPEnabled = false,
    GardenESPMode = "Tylko Farmiące",
    GardenESPShowStatus = true,
    GardenESPShowDistance = true,
    GardenESPShowHighlight = true,
    GardenAutoClaimMerchant = false,
    GardenAutoBuySeeds = false,
}

-- Synchronizacja z _G dla kompatybilności wstecznej
_G.SpeedEnabled = _G.SpeedEnabled or false
_G.SpeedValue = _G.SpeedValue or 50
_G.SpeedMode = _G.SpeedMode or "Legit"

-- // ==========================================================================
-- // 3. PS99 FRAMEWORK, NETWORK I LOKALIZACJA STRUKTUR
-- // ==========================================================================
local Library = nil
local Framework = nil
local Network = nil
local ClientNetwork = nil

local function loadPS99Library()
    pcall(function()
        if ReplicatedStorage:FindFirstChild("Library") then
            Library = require(ReplicatedStorage.Library)
            if ReplicatedStorage.Library:FindFirstChild("Client") and ReplicatedStorage.Library.Client:FindFirstChild("Network") then
                ClientNetwork = require(ReplicatedStorage.Library.Client.Network)
            end
        end
    end)
    pcall(function()
        if ReplicatedStorage:FindFirstChild("Network") then
            Network = ReplicatedStorage.Network
        end
    end)
    if typeof(getloadedmodules) == "function" then
        for _, mod in ipairs(getloadedmodules()) do
            if mod.Name == "Library" or mod.Name == "Framework" then
                local ok, res = pcall(require, mod)
                if ok and type(res) == "table" and (res.Network or res.Directory) then
                    Library = res
                    Framework = res
                    if type(res.Network) == "table" then
                        ClientNetwork = ClientNetwork or res.Network
                    end
                    break
                end
            elseif mod.Name == "Network" and mod.Parent and mod.Parent.Name == "Client" then
                local ok, res = pcall(require, mod)
                if ok and type(res) == "table" and typeof(res.Fire) == "function" then
                    ClientNetwork = res
                end
            end
        end
    end
end
pcall(loadPS99Library)

-- Uniwersalne wywoływanie Remote'ów w Pet Simulator 99
local function fireRemote(name, ...)
    local args = { ... }
    local sent = false

    -- 1. Poprzez Library.Network.Fire
    if Library and Library.Network and typeof(Library.Network.Fire) == "function" then
        local ok = pcall(function() Library.Network.Fire(name, unpack(args)) end)
        if ok then sent = true end
    end

    -- 2. Poprzez instancję Network RemoteEvent w ReplicatedStorage
    if not sent and Network then
        local rem = Network:FindFirstChild(name)
        if rem and rem:IsA("RemoteEvent") then
            pcall(function() rem:FireServer(unpack(args)) end)
            sent = true
        end
    end

    -- 3. Sprawdzenie ReplicatedStorage.Remotes / Network
    if not sent and ReplicatedStorage:FindFirstChild("Network") then
        local r = ReplicatedStorage.Network:FindFirstChild(name)
        if r and r:IsA("RemoteEvent") then
            pcall(function() r:FireServer(unpack(args)) end)
            sent = true
        end
    end

    return sent
end

local function invokeRemote(name, ...)
    local args = { ... }

    -- 1. Library.Network.Invoke
    if Library and Library.Network and typeof(Library.Network.Invoke) == "function" then
        local ok, res = pcall(function() return Library.Network.Invoke(name, unpack(args)) end)
        if ok and res ~= nil then return res end
    end

    -- 2. Network RemoteFunction
    if Network then
        local func = Network:FindFirstChild(name)
        if func and func:IsA("RemoteFunction") then
            local ok, res = pcall(function() return func:InvokeServer(unpack(args)) end)
            if ok and res ~= nil then return res end
        end
    end

    -- 3. ReplicatedStorage.Network
    if ReplicatedStorage:FindFirstChild("Network") then
        local func = ReplicatedStorage.Network:FindFirstChild(name)
        if func and func:IsA("RemoteFunction") then
            local ok, res = pcall(function() return func:InvokeServer(unpack(args)) end)
            if ok and res ~= nil then return res end
        end
    end

    return nil
end

-- Pobieranie folderów Workspace
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

-- Pobieranie folderu Garden / Działek ogrodowych
local function getGardenFolder()
    local things = getThingsFolder()
    if things then
        local g = things:FindFirstChild("Garden") or things:FindFirstChild("Plots") or things:FindFirstChild("FlowerGarden")
        if g then return g end
        local inst = things:FindFirstChild("Instances")
        if inst then
            local gInst = inst:FindFirstChild("Garden") or inst:FindFirstChild("FlowerGarden")
            if gInst then return gInst end
        end
    end
    local map = Workspace:FindFirstChild("__MAP") or Workspace:FindFirstChild("Map")
    if map then
        local gMap = map:FindFirstChild("Garden") or map:FindFirstChild("Plots") or map:FindFirstChild("FlowerGarden")
        if gMap then return gMap end
    end
    return Workspace:FindFirstChild("Garden") or Workspace:FindFirstChild("Plots")
end

-- // ==========================================================================
-- // 4. LOGIKA AUTOFARM BREAKABLES (INTELIGENTNE FILTRY, RADAR I WYBÓR W KOLE)
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

-- Pobieranie założonych petów gracza w PS99
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

-- Weak-cache dla fizyki petów (zero alokacji w pętli)
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
        -- 0. Instant Target Snap
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

        -- 1. PS99 Breakables Network Call
        local eq = getEquippedPets()
        if #eq > 0 then
            for _, uid in ipairs(eq) do
                fireRemote("Breakables_PlayerAttackBreakable", coinId, uid)
                fireRemote("Breakables_JoinPet", coinId, uid)
            end
        else
            fireRemote("Breakables_PlayerAttackBreakable", coinId)
        end

        -- 2. Legacy / Fallback Remote
        fireRemote("Farm Coin", coinId)

        -- 3. ClickDetector fallback
        local cd = coin:FindFirstChildWhichIsA("ClickDetector", true)
        if cd and typeof(fireclickdetector) == "function" then
            pcall(function() fireclickdetector(cd) end)
        end
    end)
end

-- // ==========================================================================
-- // 5. AUTO COLLECT: ORBS I LOOTBAGS
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

-- // ==========================================================================
-- // 6. LOGIKA OGRODU (PET SIMULATOR 99: FLOWER GARDEN AUTOMATION)
-- // Oparte na strukturze instancji: workspace.__THINGS.__INSTANCE_CONTAINER.Active.FlowerGarden
-- // Remote wywołań: ReplicatedStorage.Network.Instancing_InvokeCustomFromClient
-- // ==========================================================================

local function getFlowerGardenContainer()
    local things = getThingsFolder() or Workspace:FindFirstChild("__THINGS")
    if things then
        local container = things:FindFirstChild("__INSTANCE_CONTAINER")
        if container then
            local active = container:FindFirstChild("Active")
            if active and active:FindFirstChild("FlowerGarden") then
                return active.FlowerGarden
            end
        end
        local inst = things:FindFirstChild("Instances")
        if inst and inst:FindFirstChild("FlowerGarden") then
            return inst.FlowerGarden
        end
    end
    return nil
end

local function getGardenPlantsFolder()
    local fg = getFlowerGardenContainer()
    if fg and fg:FindFirstChild("Plants") then
        return fg.Plants
    end
    return nil
end

local function getGardenRemote()
    if Network and Network:FindFirstChild("Instancing_InvokeCustomFromClient") then
        return Network.Instancing_InvokeCustomFromClient
    end
    local rs = game:GetService("ReplicatedStorage")
    if rs:FindFirstChild("Network") and rs.Network:FindFirstChild("Instancing_InvokeCustomFromClient") then
        return rs.Network.Instancing_InvokeCustomFromClient
    end
    return nil
end

local function getGardenFireRemote()
    if Network and Network:FindFirstChild("Instancing_FireCustomFromClient") then
        return Network.Instancing_FireCustomFromClient
    end
    local rs = game:GetService("ReplicatedStorage")
    if rs:FindFirstChild("Network") and rs.Network:FindFirstChild("Instancing_FireCustomFromClient") then
        return rs.Network.Instancing_FireCustomFromClient
    end
    return nil
end

-- Sadzenie nasiona w donicy (slot 1-10)
local function plantGardenSeed(slotIndex, seedName)
    local seedKey = seedName or "Coin"
    if seedKey == "Wszystkie (ALL)" or seedKey:find("ALL") then seedKey = "Diamond" end
    -- Usunięcie słowa "Seed" jeśli jest w nazwie
    seedKey = seedKey:gsub("%s*Seed%s*", ""):gsub("^%s*(.-)%s*$", "%1")
    if seedKey == "" then seedKey = "Coin" end

    local invRemote = getGardenRemote()
    if invRemote then
        pcall(function()
            invRemote:InvokeServer("FlowerGarden", "PlantSeed", slotIndex, seedKey)
        end)
    end

    local fireRem = getGardenFireRemote()
    if fireRem then
        pcall(function()
            fireRem:FireServer("FlowerGarden", "PlantSeed", slotIndex, seedKey)
        end)
    end

    -- Trigger ProximityPrompt jeśli jest w donicy
    local plantsFolder = getGardenPlantsFolder()
    local plantModel = plantsFolder and plantsFolder:FindFirstChild("Plant" .. tostring(slotIndex))
    if plantModel then
        for _, desc in ipairs(plantModel:GetDescendants()) do
            if desc:IsA("ProximityPrompt") and ((desc.ActionText or ""):lower():find("plant") or (desc.ObjectText or ""):lower():find("plant")) then
                pcall(function()
                    if typeof(fireproximityprompt) == "function" then
                        fireproximityprompt(desc)
                    end
                end)
            end
        end
    end
end

-- Zbiór dojrzałej rośliny (slot 1-20)
local function harvestGardenPlant(slotIndex)
    local fireRem = getGardenFireRemote()
    if fireRem then
        pcall(function() fireRem:FireServer("FlowerGarden", "ClaimPlant", slotIndex) end)
        pcall(function() fireRem:FireServer("FlowerGarden", "HarvestPlant", slotIndex) end)
    end

    local invRemote = getGardenRemote()
    if invRemote then
        pcall(function() invRemote:InvokeServer("FlowerGarden", "ClaimPlant", slotIndex) end)
        pcall(function() invRemote:InvokeServer("FlowerGarden", "HarvestPlant", slotIndex) end)
    end

    local plantsFolder = getGardenPlantsFolder()
    local plantModel = plantsFolder and plantsFolder:FindFirstChild("Plant" .. tostring(slotIndex))
    if plantModel then
        for _, desc in ipairs(plantModel:GetDescendants()) do
            if desc:IsA("ProximityPrompt") then
                pcall(function()
                    if typeof(fireproximityprompt) == "function" then
                        fireproximityprompt(desc)
                    end
                end)
            end
        end
    end
end

-- Podlewanie donicy (slot 1-20)
local function waterGardenPlant(slotIndex)
    local invRemote = getGardenRemote()
    if invRemote then
        pcall(function() invRemote:InvokeServer("FlowerGarden", "WaterSeed", slotIndex) end)
        pcall(function() invRemote:InvokeServer("FlowerGarden", "WaterPlant", slotIndex) end)
        pcall(function() invRemote:InvokeServer("FlowerGarden", "Water", slotIndex) end)
    end

    local fireRem = getGardenFireRemote()
    if fireRem then
        pcall(function() fireRem:FireServer("FlowerGarden", "WaterSeed", slotIndex) end)
        pcall(function() fireRem:FireServer("FlowerGarden", "WaterPlant", slotIndex) end)
    end

    local plantsFolder = getGardenPlantsFolder()
    local plantModel = plantsFolder and plantsFolder:FindFirstChild("Plant" .. tostring(slotIndex))
    if plantModel then
        for _, desc in ipairs(plantModel:GetDescendants()) do
            if desc:IsA("ProximityPrompt") and ((desc.ActionText or ""):lower():find("water") or (desc.ObjectText or ""):lower():find("water")) then
                pcall(function()
                    if typeof(fireproximityprompt) == "function" then
                        fireproximityprompt(desc)
                    end
                end)
            end
        end
    end
end

-- Błyskawiczny wzrost nasiona (InstaGrowSeed, slot 1-20)
local function instaGrowGardenPlant(slotIndex)
    local invRemote = getGardenRemote()
    if invRemote then
        pcall(function() invRemote:InvokeServer("FlowerGarden", "InstaGrowSeed", slotIndex) end)
        pcall(function() invRemote:InvokeServer("FlowerGarden", "InstaPlant", slotIndex) end)
    end

    local fireRem = getGardenFireRemote()
    if fireRem then
        pcall(function() fireRem:FireServer("FlowerGarden", "InstaGrowSeed", slotIndex) end)
    end
end

-- Funkcje pomocnicze do inspekcji działek i stanu rośliny
local function getPlotInstance(slotNum)
    local plantsFolder = getGardenPlantsFolder()
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

-- Auto Harvest wszystkich 10 donic
local function runGardenHarvest()
    for i = 1, 10 do
        harvestGardenPlant(i)
    end
end

-- Auto Water wszystkich 10 donic
local function runGardenWater()
    for i = 1, 10 do
        waterGardenPlant(i)
    end
end

-- Auto Plant wolnych donic
local function runGardenPlant()
    local seed = State.GardenSelectedSeed or "Coin"
    for i = 1, 10 do
        plantGardenSeed(i, seed)
    end
end

-- Uniwersalna funkcja kliknięcia w obiekt 3D (Network.Click z Raycastem)
local function clickWorldPosition(targetPos, optionalRay, optionalInstance)
    if not targetPos then return false end

    local clickRay = optionalRay
    if not clickRay then
        local cam = Workspace.CurrentCamera
        local origin = (cam and cam.CFrame and cam.CFrame.Position)
        if not origin then
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            origin = hrp and (hrp.Position + Vector3.new(0, 2.5, 0)) or (targetPos + Vector3.new(0, 10, 0))
        end
        local diff = (targetPos - origin)
        local dirUnit = diff.Magnitude > 0.001 and diff.Unit or Vector3.new(0, -1, 0)
        clickRay = Ray.new(origin, dirUnit)
    end

    -- 1. Poprzez ClientNetwork z ReplicatedStorage.Library.Client.Network (dokładnie jak w grze)
    if ClientNetwork and typeof(ClientNetwork.Fire) == "function" then
        pcall(function() ClientNetwork.Fire("Click", clickRay, targetPos) end)
    end

    -- 2. Poprzez ReplicatedStorage.Network.Click RemoteEvent
    pcall(function()
        local clickEvent = (Network and Network:FindFirstChild("Click"))
            or (ReplicatedStorage:FindFirstChild("Network") and ReplicatedStorage.Network:FindFirstChild("Click"))
        if clickEvent and clickEvent:IsA("RemoteEvent") then
            clickEvent:FireServer(clickRay, targetPos)
        end
    end)

    -- 3. Poprzez Library.Network.Fire
    if Library and Library.Network and typeof(Library.Network.Fire) == "function" then
        pcall(function() Library.Network.Fire("Click", clickRay, targetPos) end)
    end

    -- 4. Aktywacja ProximityPrompt jeśli obiekt go posiada
    if optionalInstance and typeof(optionalInstance) == "Instance" then
        for _, prompt in ipairs(optionalInstance:GetDescendants()) do
            if prompt:IsA("ProximityPrompt") then
                pcall(function()
                    if typeof(fireproximityprompt) == "function" then
                        fireproximityprompt(prompt)
                    end
                end)
            end
        end
    end

    return true
end

-- Lokalizacja i pobranie części kapsuły inkubatora (InstaPlantIncubator)
local function getIncubatorUnion()
    local fg = getFlowerGardenContainer()
    if fg then
        local interactable = fg:FindFirstChild("Interactable") or fg:FindFirstChild("INTERACT")
        local inc = interactable and interactable:FindFirstChild("InstaPlantIncubator")
        if inc then
            local capsule = inc:FindFirstChild("capsule")
            if capsule and capsule:IsA("BasePart") then return capsule end
            local union = inc:FindFirstChild("Union")
            if union and union:IsA("BasePart") then return union end
            local part = inc:FindFirstChildWhichIsA("BasePart")
            if part then return part end
            if inc:IsA("BasePart") then return inc end
        end
        for _, desc in ipairs(fg:GetDescendants()) do
            if desc.Name == "capsule" and desc:IsA("BasePart") then return desc end
            if desc.Name == "InstaPlantIncubator" then
                local u = desc:FindFirstChild("capsule") or desc:FindFirstChild("Union") or desc:FindFirstChildWhichIsA("BasePart")
                if u then return u end
            end
        end
    end
    return nil
end

local function getIncubatorPosition()
    local union = getIncubatorUnion()
    if union then
        return union.Position, union
    end
    -- Dokładna pozycja z najnowszego Cobalt logu od AN0N
    return Vector3.new(-437.83212280273438, 109.46415710449219, -1421.351318359375), nil
end

-- Pobranie wody z kapsuły inkubatora (InstaPlant Capsule)
local function collectWaterFromIncubator()
    -- 1. Dokładny pakiet z Cobalt logu dostarczonego przez AN0N (z kapsuły)
    local cobaltPos = Vector3.new(-437.83212280273438, 109.46415710449219, -1421.351318359375)
    local cobaltRay = Ray.new(
        Vector3.new(-455.88748168945312, 128.20892333984375, -1396.1763916015625),
        Vector3.new(0.4934602677822113, -0.57543015480041504, -0.65220928192138672)
    )
    clickWorldPosition(cobaltPos, cobaltRay)
    clickWorldPosition(cobaltPos, nil)

    -- 2. Kliknięcie obiektu kapsuły w Workspace
    local incObj = getIncubatorUnion()
    if incObj then
        clickWorldPosition(incObj.Position, nil, incObj)
        if incObj.Parent then
            local cap = incObj.Parent:FindFirstChild("capsule")
            if cap and cap ~= incObj and cap:IsA("BasePart") then
                clickWorldPosition(cap.Position, nil, cap)
            end
            local uni = incObj.Parent:FindFirstChild("Union")
            if uni and uni ~= incObj and uni:IsA("BasePart") then
                clickWorldPosition(uni.Position, nil, uni)
            end
        end
    end

    -- 3. Zapasowy punkt maszyny (-477.72)
    local altPos = Vector3.new(-477.71975708007812, 111.51129913330078, -1403.053955078125)
    clickWorldPosition(altPos, nil)

    -- 4. Dedykowane wywołania Remote dla FlowerGarden
    local invRemote = getGardenRemote()
    if invRemote then
        pcall(function() invRemote:InvokeServer("FlowerGarden", "UseIncubator") end)
        pcall(function() invRemote:InvokeServer("FlowerGarden", "CollectWater") end)
        pcall(function() invRemote:InvokeServer("FlowerGarden", "Incubator") end)
        pcall(function() invRemote:InvokeServer("FlowerGarden", "ClaimWater") end)
    end
    local fireRem = getGardenFireRemote()
    if fireRem then
        pcall(function() fireRem:FireServer("FlowerGarden", "UseIncubator") end)
        pcall(function() fireRem:FireServer("FlowerGarden", "CollectWater") end)
    end
end

-- Lokalizacja donicy / kwiatka dla danego slotu (1-10)
local function getPlantObject(slotIndex)
    local plantsFolder = getGardenPlantsFolder()
    if not plantsFolder then return nil end
    return plantsFolder:FindFirstChild("Plant" .. tostring(slotIndex))
end

local function getPlantPosition(slotIndex)
    local plant = getPlantObject(slotIndex)
    if plant then
        if plant:IsA("BasePart") then return plant.Position, plant end
        if plant.PrimaryPart then return plant.PrimaryPart.Position, plant end
        local bp = plant:FindFirstChildWhichIsA("BasePart")
        if bp then return bp.Position, plant end
        if plant.GetPivot then return plant:GetPivot().Position, plant end
    end
    return nil, nil
end

-- Automatyczne wyposażenie konewki do ręki (z plecaka)
local function equipWateringCan()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not char or not hum then return nil end

    for _, tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") and (tool.Name:lower():find("water") or tool.Name:lower():find("can") or tool.Name:lower():find("insta")) then
            return tool
        end
    end

    local backpack = LocalPlayer:FindFirstChildOfClass("Backpack") or LocalPlayer:FindFirstChild("Backpack")
    if backpack then
        for _, tool in ipairs(backpack:GetChildren()) do
            if tool:IsA("Tool") and (tool.Name:lower():find("water") or tool.Name:lower():find("can") or tool.Name:lower():find("insta")) then
                pcall(function() hum:EquipTool(tool) end)
                return tool
            end
        end
    end
    return nil
end

-- Błyskawiczny cykl Insta-Plant (kroki modułowe: Sadzenie -> Kapsuła & InstaGrow -> Podlewanie -> Zbiór)
local function runInstaPlantSlot(slotIndex, seedName)
    local seed = seedName or State.GardenSelectedSeed or "Diamond"

    -- Krok 1: Posadzenie nasiona w donicy
    if State.GardenStepPlant then
        plantGardenSeed(slotIndex, seed)
        task.wait(tonumber(State.GardenActionDelay) or 0.1)
    end

    -- Krok 2: Pobranie wody z kapsuły + InstaGrow
    if State.GardenStepInstaGrow then
        collectWaterFromIncubator()
        task.wait(0.04)

        if State.GardenAutoEquipCan then
            pcall(equipWateringCan)
        end

        local plant = getPlotInstance(slotIndex)
        local part = getPlotBasePart(plant)
        if part then
            clickWorldPosition(part.Position, nil, plant)
        end

        instaGrowGardenPlant(slotIndex)
        task.wait(tonumber(State.GardenActionDelay) or 0.1)
    end

    -- Krok 2b: Podlewanie konewką
    if State.GardenStepWater then
        waterGardenPlant(slotIndex)
        task.wait(tonumber(State.GardenActionDelay) or 0.1)
    end

    -- Krok 3: Zbiór plonu
    if State.GardenStepClaim then
        local plant = getPlotInstance(slotIndex)
        local status = checkPlotStatus(plant)
        if status:find("Gotowa") or not State.GardenStepInstaGrow then
            harvestGardenPlant(slotIndex)
            task.wait(tonumber(State.GardenActionDelay) or 0.1)
        end
    end

    -- Aktywacja konewki jeśli gracz trzyma w ręku
    local char = LocalPlayer.Character
    if char then
        for _, tool in ipairs(char:GetChildren()) do
            if tool:IsA("Tool") and (tool.Name:lower():find("water") or tool.Name:lower():find("can") or tool.Name:lower():find("insta")) then
                if tool.Activate then pcall(function() tool:Activate() end) end
            end
        end
    end
end

-- Błyskawiczny cykl Insta-Plant dla wszystkich wybranych działek (sloty 1-20)
local function runInstaPlantAll()
    local seed = State.GardenSelectedSeed or "Diamond"

    if State.GardenStepInstaGrow then
        collectWaterFromIncubator()
        task.wait(0.04)
    end

    for i = 1, 20 do
        if not ScriptRunning or not State.GardenInstaPlant then break end
        if State.GardenFarmSlots[i] == true then
            runInstaPlantSlot(i, seed)
            task.wait(tonumber(State.GardenActionDelay) or 0.05)
        end
    end
end

-- Otwieranie skrzyni FlowerGarden (InstanceChest: 3)
local function claimGardenChest()
    local fg = getFlowerGardenContainer()
    local chest = fg and fg:FindFirstChild("INTERACT") and fg.INTERACT:FindFirstChild("Chests") and fg.INTERACT.Chests:FindFirstChild("InstanceChest: 3")
    if chest then
        for _, desc in ipairs(chest:GetDescendants()) do
            if desc:IsA("ProximityPrompt") then
                pcall(function()
                    if typeof(fireproximityprompt) == "function" then
                        fireproximityprompt(desc)
                    end
                end)
            end
        end
    end
end

-- Użycie inkubatora roślin (InstaPlantIncubator)
local function useGardenIncubator()
    collectWaterFromIncubator()
end

-- // ==========================================================================
-- // 7. SYSTEM PRĘDKOŚCI GRACZA (PLAYER SPEED ENGINE)
-- // ==========================================================================
local function getMoveDirection()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum and hum.MoveDirection.Magnitude > 0 then
        return true, hum.MoveDirection
    end

    local camera = Workspace.CurrentCamera
    if not char or not char:FindFirstChild("HumanoidRootPart") or not camera then
        return false, Vector3.zero
    end

    local look = camera.CFrame.LookVector
    local moveDir = Vector3.new(look.X, 0, look.Z)
    if moveDir.Magnitude > 0 then moveDir = moveDir.Unit end

    local movement = Vector3.zero
    if UserInputService:IsKeyDown(Enum.KeyCode.W) or UserInputService:IsKeyDown(Enum.KeyCode.Up) then movement = movement + moveDir end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) or UserInputService:IsKeyDown(Enum.KeyCode.Down) then movement = movement - moveDir end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) or UserInputService:IsKeyDown(Enum.KeyCode.Right) then movement = movement + Vector3.new(-moveDir.Z, 0, moveDir.X) end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) or UserInputService:IsKeyDown(Enum.KeyCode.Left) then movement = movement + Vector3.new(moveDir.Z, 0, -moveDir.X) end

    if movement.Magnitude > 0 then return true, movement.Unit end
    return false, Vector3.zero
end

local speedHeartbeatConn = nil
local speedRenderConn = nil

local function stopSpeedConnections()
    if speedHeartbeatConn then speedHeartbeatConn:Disconnect() speedHeartbeatConn = nil end
    if speedRenderConn then speedRenderConn:Disconnect() speedRenderConn = nil end
    pcall(function()
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = 16 end
    end)
end

local function initSpeedConnections()
    if not speedHeartbeatConn then
        speedHeartbeatConn = RunService.Heartbeat:Connect(function()
            if not ScriptRunning then return end
            if not (State.PlayerSpeedEnabled or _G.SpeedEnabled) then return end

            local char = LocalPlayer.Character
            if not char then return end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local hum = char:FindFirstChildOfClass("Humanoid")
            if not hrp or not hum then return end

            local targetSpeed = tonumber(State.PlayerSpeedValue or _G.SpeedValue or 50) or 50
            local mode = State.PlayerSpeedMode or _G.SpeedMode or "Legit"

            if mode == "Normal" then
                if hum.WalkSpeed ~= targetSpeed then hum.WalkSpeed = targetSpeed end
            elseif mode == "Legit" or mode == "HVH" then
                local moving, moveDir = getMoveDirection()
                if mode == "HVH" and (UserInputService:IsKeyDown(Enum.KeyCode.Space) or hum:GetState() == Enum.HumanoidStateType.Freefall) then
                    hum.Jump = true
                end
                if moving then
                    local currentY = hrp.AssemblyLinearVelocity and hrp.AssemblyLinearVelocity.Y or hrp.Velocity.Y
                    local newVel = Vector3.new(moveDir.X * targetSpeed, currentY, moveDir.Z * targetSpeed)
                    pcall(function() hrp.AssemblyLinearVelocity = newVel end)
                    pcall(function() hrp.Velocity = newVel end)
                end
            end
        end)
        table.insert(ScriptConnections, speedHeartbeatConn)
    end

    if not speedRenderConn then
        speedRenderConn = RunService.RenderStepped:Connect(function(dt)
            if not ScriptRunning then return end
            if not (State.PlayerSpeedEnabled or _G.SpeedEnabled) then return end

            local char = LocalPlayer.Character
            if not char then return end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local hum = char:FindFirstChildOfClass("Humanoid")
            if not hrp or not hum then return end

            local targetSpeed = tonumber(State.PlayerSpeedValue or _G.SpeedValue or 50) or 50
            local mode = State.PlayerSpeedMode or _G.SpeedMode or "Legit"

            if mode == "CFrame" then
                local moving, moveDir = getMoveDirection()
                if moving then
                    local delta = (dt and dt > 0) and dt or (1 / 60)
                    hrp.CFrame = hrp.CFrame + (moveDir * (targetSpeed * delta))
                end
            end
        end)
        table.insert(ScriptConnections, speedRenderConn)
    end
end
initSpeedConnections()

-- Infinite Jump
local jumpConn = UserInputService.JumpRequest:Connect(function()
    if State.PlayerInfJump then
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)
table.insert(ScriptConnections, jumpConn)

-- Odnowienie prędkości po respawnie postaci
local charAddedConn = LocalPlayer.CharacterAdded:Connect(function(newChar)
    if State.PlayerSpeedEnabled or _G.SpeedEnabled then
        task.wait(0.2)
        local hum = newChar:WaitForChild("Humanoid", 3)
        if hum and (State.PlayerSpeedMode == "Normal") then
            hum.WalkSpeed = State.PlayerSpeedValue or 50
        end
    end
end)
table.insert(ScriptConnections, charAddedConn)

-- // ==========================================================================
-- // 8. PĘTLE GŁÓWNE (BACKGROUND WORKERS)
-- // ==========================================================================

-- Pętla AutoFarm
local retargetCounter = 0
local lastFarmPulse = 0

task.spawn(function()
    while ScriptRunning do
        if State.FarmActive then
            local current = State.CurrentTargetCoin

            if not isCoinAlive(current) then
                current = nil
                State.CurrentTargetCoin = nil
            else
                local cat, _ = detectCoinCategory(current)
                if not isCoinAllowed(cat) then
                    current = nil
                    State.CurrentTargetCoin = nil
                else
                    local char = LocalPlayer.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    local refPos = (State.FarmAnchorEnabled and State.FarmAnchorPos) or (hrp and hrp.Position)
                    if refPos and not State.FarmInfiniteRange then
                        local inRadius = isCoinInRadius(current, refPos, State.FarmRange)
                        if not inRadius then
                            current = nil
                            State.CurrentTargetCoin = nil
                        end
                    end
                end
            end

            if not current then
                local nextCoin = findBestCoin()
                if nextCoin and isCoinAlive(nextCoin) then
                    attackCoin(nextCoin)
                    lastFarmPulse = tick()
                end
            else
                -- Ograniczony keepalive pulse sieciowy (co 1.5s)
                local now = tick()
                if (now - lastFarmPulse >= 1.5) and (State.FarmAntiRecall or State.FarmInfiniteRange or State.FarmAnchorEnabled) then
                    lastFarmPulse = now
                    local coinId = current:GetAttribute("ID") or current.Name
                    local eq = getEquippedPets()
                    for _, uid in ipairs(eq) do
                        fireRemote("Breakables_PlayerAttackBreakable", coinId, uid)
                    end
                end

                retargetCounter = retargetCounter + 1
                if retargetCounter >= 6 then
                    retargetCounter = 0
                    local betterCoin = findBestCoin()
                    if betterCoin and betterCoin ~= current and isCoinAlive(betterCoin) then
                        local catCur, _ = detectCoinCategory(current)
                        local catBetter, _ = detectCoinCategory(betterCoin)
                        local hpCur = current:GetAttribute("Health") or 100
                        local maxHpCur = current:GetAttribute("MaxHealth") or hpCur
                        local hpB = betterCoin:GetAttribute("Health") or 100
                        local maxHpB = betterCoin:GetAttribute("MaxHealth") or hpB

                        local char = LocalPlayer.Character
                        local hrp = char and char:FindFirstChild("HumanoidRootPart")
                        local pPos = (State.FarmAnchorEnabled and State.FarmAnchorPos) or (hrp and hrp.Position) or Vector3.zero
                        local distCur = (pPos - (getCoinPosition(current) or pPos)).Magnitude
                        local distB = (pPos - (getCoinPosition(betterCoin) or pPos)).Magnitude

                        local sCur = evaluateCoinScore(catCur, hpCur, maxHpCur, distCur)
                        local sB = evaluateCoinScore(catBetter, hpB, maxHpB, distB)

                        if sB > (sCur + 100000) then
                            attackCoin(betterCoin)
                            lastFarmPulse = tick()
                        end
                    end
                end
            end

            task.wait(0.15)
        else
            State.CurrentTargetCoin = nil
            task.wait(0.4)
        end
    end
end)

-- Reaktywny nasłuch na zrespawnowane Breakables
local boundBreakablesFolders = {}
local function bindBreakablesListeners()
    for _, folder in ipairs(getBreakablesFolders()) do
        if not boundBreakablesFolders[folder] then
            boundBreakablesFolders[folder] = true
            local conn = folder.ChildAdded:Connect(function(child)
                if State.FarmActive and not isCoinAlive(State.CurrentTargetCoin) then
                    task.wait(0.05)
                    local best = findBestCoin()
                    if best and isCoinAlive(best) then
                        attackCoin(best)
                        lastFarmPulse = tick()
                    end
                end
            end)
            table.insert(ScriptConnections, conn)
        end
    end
end
bindBreakablesListeners()

-- Pętla Auto Collect Orbs & Lootbags
task.spawn(function()
    while ScriptRunning do
        if State.AutoOrbs then collectOrbsClean() end
        if State.AutoLootbags then collectLootbagsClean() end
        task.wait(0.25)
    end
end)

-- Pętla aktualizacji fizyki petów
task.spawn(function()
    while ScriptRunning do
        if State.PetSpeedEnabled then
            pcall(updateWorkspacePetsPhysics)
            task.wait(0.2)
        else
            task.wait(0.6)
        end
    end
end)

-- Pętle Garden Automation
task.spawn(function()
    while ScriptRunning do
        if State.GardenAutoHarvest then
            pcall(runGardenHarvest)
            task.wait(tonumber(State.GardenHarvestDelay) or 1.0)
        else
            task.wait(0.5)
        end
    end
end)

task.spawn(function()
    while ScriptRunning do
        if State.GardenAutoWater then
            pcall(runGardenWater)
            task.wait(tonumber(State.GardenWaterDelay) or 2.0)
        else
            task.wait(0.5)
        end
    end
end)

task.spawn(function()
    while ScriptRunning do
        if State.GardenAutoPlant then
            pcall(runGardenPlant)
            task.wait(tonumber(State.GardenPlantDelay) or 1.5)
        else
            task.wait(0.5)
        end
    end
end)

task.spawn(function()
    while ScriptRunning do
        if State.GardenInstaPlant then
            pcall(runInstaPlantAll)
            task.wait(tonumber(State.GardenInstaPlantDelay) or 0.5)
        else
            task.wait(0.5)
        end
    end
end)

-- // ==========================================================================
-- // ESP DZIAŁEK (BILLBOARDGUI + HIGHLIGHT 3D DLA DZIAŁEK 1-20)
-- // ==========================================================================
local CoreGui = game:GetService("CoreGui")
local ESPObjects = {}
local ESPContainer = Instance.new("Folder")
ESPContainer.Name = "MenuTest_Garden_ESP"
pcall(function() ESPContainer.Parent = CoreGui end)
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

local espRenderConn = RunService.RenderStepped:Connect(function()
    if not ScriptRunning or not State.GardenESPEnabled then
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
            local shouldShow = (State.GardenESPMode == "Wszystkie (1-20)")
                or (State.GardenESPMode == "Tylko Farmiące" and State.GardenFarmSlots[slotNum] == true)

            if shouldShow then
                local plot = getPlotInstance(slotNum)
                local part = getPlotBasePart(plot)

                if plot and part then
                    esp.Billboard.Adornee = part
                    esp.Billboard.Enabled = true

                    local statusText, statusColor = checkPlotStatus(plot)
                    esp.StatusLabel.Text = State.GardenESPShowStatus and ("• " .. statusText) or ""
                    esp.StatusLabel.TextColor3 = statusColor
                    esp.Stroke.Color = statusColor

                    if State.GardenESPShowDistance and myPos then
                        local dist = math.floor((part.Position - myPos).Magnitude)
                        esp.DistLabel.Text = dist .. " studs"
                        esp.DistLabel.Visible = true
                    else
                        esp.DistLabel.Visible = false
                    end

                    if State.GardenESPShowHighlight then
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
table.insert(ScriptConnections, espRenderConn)

-- // ==========================================================================
-- // 9. INTERFEJS UŻYTKOWNIKA MENUTEST (TABS: GENERAL & GARDEN)
-- // ==========================================================================
local Window = MENU:CreateWindow({
    Name = "PetHub",
    Tittle = "Pet Simulator 99 (Garden Event)",
    TittlePos = "Center",
    ToggleUIKeybind = "K",
    TestMobile = false,
    GameId = "8737899170"
})

if Window and Window.ScreenGui then
    Window.ScreenGui.Destroying:Connect(function()
        ScriptRunning = false
        stopSpeedConnections()
        for _, conn in ipairs(ScriptConnections) do
            pcall(function() conn:Disconnect() end)
        end
        table.clear(ScriptConnections)
        State.FarmActive = false
        State.AutoOrbs = false
        State.AutoLootbags = false
        State.PlayerSpeedEnabled = false
        State.PetSpeedEnabled = false
        State.GardenAutoHarvest = false
        State.GardenAutoWater = false
        State.GardenAutoPlant = false
        State.GardenInstaPlant = false
        State.GardenESPEnabled = false
        State.FarmAnchorEnabled = false
        State.FarmAnchorPos = nil
        State.CurrentTargetCoin = nil
        if ESPContainer then pcall(function() ESPContainer:Destroy() end) end
    end)
end

-- // ==================== ZAKŁADKA 1: GENERAL ====================
local TabGeneral = Window:CreateTab("General", "home")

-- MODUŁ: AUTOFARM
local FarmModule = TabGeneral:CreateModule({
    Name = "AutoFarm",
    Description = "Automatycznie wyszukuje i atakuje obiekty i monety w strefie",
    Default = false,
    CurrentValue = false,
    Flag = "General_AutoFarm",
    Callback = function(state)
        State.FarmActive = state
        if not state then State.CurrentTargetCoin = nil end
    end
})

FarmModule:AddSlider({
    Name = "Zasięg Farmowania",
    Range = { 100, 1500 },
    CurrentValue = 600,
    Min = 100,
    Max = 1500,
    Default = 600,
    Suffix = " studs",
    Flag = "General_FarmRange",
    Callback = function(val)
        State.FarmRange = val
        State.CurrentTargetCoin = nil
    end
})

FarmModule:AddToggle({
    Name = "Nielimitowany Zasięg (Infinite Range)",
    Description = "Atakuje obiekty na całej mapie bez ograniczenia odległości",
    Default = false,
    CurrentValue = false,
    Flag = "General_InfiniteRange",
    Callback = function(state)
        State.FarmInfiniteRange = state
    end
})

FarmModule:AddDropdown({
    Name = "Co ma kopać (Filtr Celu)",
    Description = "Wybierz jeden konkretny rodzaj obiektów lub wszystko po kolei",
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
    Default = "Wszystko (ALL)",
    CurrentValue = "Wszystko (ALL)",
    Flag = "General_FarmTargetType",
    Callback = function(val)
        State.FarmTargetType = val
        State.CurrentTargetCoin = nil
    end
})

FarmModule:AddDropdown({
    Name = "Priorytet Celu",
    Description = "Kryterium decydujące o kolejności bicia obiektów",
    Options = {
        "ALL (Od Najlepszego do Najsłabszego)",
        "Najbliższe (Najmniejsza Odległość)",
        "Najwięcej HP (Największe)",
        "Najmniej HP (Szybkie Czyszczenie)"
    },
    Default = "ALL (Od Najlepszego do Najsłabszego)",
    CurrentValue = "ALL (Od Najlepszego do Najsłabszego)",
    Flag = "General_FarmPriority",
    Callback = function(val)
        State.FarmPriority = val
        State.CurrentTargetCoin = nil
    end
})

FarmModule:AddToggle({
    Name = "Diamenty (Diamonds)",
    Default = true,
    CurrentValue = true,
    Flag = "General_TypeDiamonds",
    Callback = function(val) State.FarmTypes["Diamonds"] = val State.CurrentTargetCoin = nil end
})

FarmModule:AddToggle({
    Name = "Skrzynie (Chests)",
    Default = true,
    CurrentValue = true,
    Flag = "General_TypeChest",
    Callback = function(val) State.FarmTypes["Chest"] = val State.CurrentTargetCoin = nil end
})

FarmModule:AddToggle({
    Name = "Sejfy (Safes)",
    Default = true,
    CurrentValue = true,
    Flag = "General_TypeSafe",
    Callback = function(val) State.FarmTypes["Safe"] = val State.CurrentTargetCoin = nil end
})

FarmModule:AddToggle({
    Name = "Skrzynki Drewniane (Crates)",
    Default = true,
    CurrentValue = true,
    Flag = "General_TypeCrate",
    Callback = function(val) State.FarmTypes["Crate"] = val State.CurrentTargetCoin = nil end
})

FarmModule:AddToggle({
    Name = "Prezenty (Presents)",
    Default = true,
    CurrentValue = true,
    Flag = "General_TypePresent",
    Callback = function(val) State.FarmTypes["Present"] = val State.CurrentTargetCoin = nil end
})

FarmModule:AddToggle({
    Name = "Duże Monety (Large Coins)",
    Default = true,
    CurrentValue = true,
    Flag = "General_TypeLarge",
    Callback = function(val) State.FarmTypes["Large Coins"] = val State.CurrentTargetCoin = nil end
})

FarmModule:AddToggle({
    Name = "Zwykłe Monety (Coins)",
    Default = true,
    CurrentValue = true,
    Flag = "General_TypeCoins",
    Callback = function(val) State.FarmTypes["Coins"] = val State.CurrentTargetCoin = nil end
})

FarmModule:AddToggle({
    Name = "Lock Anchor (Kotwica Miejsca Farmu)",
    Description = "Pety kopią w wybranym punkcie nawet gdy odejdziesz na drugi koniec mapy",
    Default = false,
    CurrentValue = false,
    Flag = "General_FarmAnchor",
    Callback = function(state)
        State.FarmAnchorEnabled = state
        if state and not State.FarmAnchorPos then
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then State.FarmAnchorPos = hrp.Position end
        end
    end
})

FarmModule:AddButton({
    Name = "Ustaw Kotwicę Tutaj (Set Anchor)",
    Callback = function()
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            State.FarmAnchorPos = hrp.Position
            State.FarmAnchorEnabled = true
        end
    end
})

FarmModule:AddButton({
    Name = "Zresetuj Kotwicę (Reset Anchor)",
    Callback = function()
        State.FarmAnchorPos = nil
        State.FarmAnchorEnabled = false
    end
})

-- MODUŁ: AUTO COLLECT
local CollectModule = TabGeneral:CreateModule({
    Name = "Auto Collect",
    Description = "Błyskawiczne przyciąganie orbsów i lootbagów do postaci",
    Default = true,
    CurrentValue = true,
    Flag = "General_AutoCollectGroup"
})

CollectModule:AddToggle({
    Name = "Auto Collect Orbs",
    Description = "Błyskawicznie zbiera wszystkie kule doświadczenia i monet",
    Default = false,
    CurrentValue = false,
    Flag = "General_AutoOrbs",
    Callback = function(state) State.AutoOrbs = state end
})

CollectModule:AddToggle({
    Name = "Auto Collect LootBags",
    Description = "Przyciąga i natychmiast otwiera worki z łupami",
    Default = false,
    CurrentValue = false,
    Flag = "General_AutoLootbags",
    Callback = function(state) State.AutoLootbags = state end
})

-- MODUŁ: PLAYER SPEED
local SpeedModule = TabGeneral:CreateModule({
    Name = "Speed Player",
    Description = "Zaawansowany silnik prędkości postaci z pełnym ominięciem limitera",
    Default = false,
    CurrentValue = false,
    Flag = "General_SpeedGroup"
})

SpeedModule:AddToggle({
    Name = "Włącz Speed Gracza",
    Default = false,
    CurrentValue = false,
    Flag = "General_SpeedToggle",
    Callback = function(state)
        State.PlayerSpeedEnabled = state
        _G.SpeedEnabled = state
        if not state then
            pcall(function()
                local char = LocalPlayer.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if hum then hum.WalkSpeed = 16 end
            end)
        end
    end
})

SpeedModule:AddSlider({
    Name = "Wartość Prędkości (Speed Value)",
    Range = { 16, 250 },
    CurrentValue = 50,
    Min = 16,
    Max = 250,
    Default = 50,
    Suffix = " studs/s",
    Flag = "General_SpeedValue",
    Callback = function(val)
        State.PlayerSpeedValue = val
        _G.SpeedValue = val
    end
})

SpeedModule:AddDropdown({
    Name = "Tryb Prędkości (Speed Mode)",
    Options = { "Legit", "CFrame", "Normal", "HVH" },
    Default = "Legit",
    CurrentValue = "Legit",
    Flag = "General_SpeedMode",
    Callback = function(val)
        State.PlayerSpeedMode = val
        _G.SpeedMode = val
    end
})

SpeedModule:AddToggle({
    Name = "Infinite Jump (Nieskończony Skok)",
    Default = false,
    CurrentValue = false,
    Flag = "General_InfJump",
    Callback = function(val) State.PlayerInfJump = val end
})

-- MODUŁ: PET SPEED
local PetSpeedModule = TabGeneral:CreateModule({
    Name = "Speed Pet",
    Description = "Pety przemieszczają się natychmiast bez żadnych opóźnień",
    Default = false,
    CurrentValue = false,
    Flag = "General_PetSpeedGroup"
})

PetSpeedModule:AddToggle({
    Name = "Włącz Speed Petów",
    Default = false,
    CurrentValue = false,
    Flag = "General_PetSpeedToggle",
    Callback = function(state)
        State.PetSpeedEnabled = state
        if state then pcall(updateWorkspacePetsPhysics) end
    end
})

PetSpeedModule:AddSlider({
    Name = "Mnożnik Szybkości Petów",
    Range = { 1, 50 },
    CurrentValue = 25,
    Min = 1,
    Max = 50,
    Default = 25,
    Suffix = "x",
    Flag = "General_PetSpeedValue",
    Callback = function(val)
        State.PetSpeedValue = val
        if State.PetSpeedEnabled then pcall(updateWorkspacePetsPhysics) end
    end
})

PetSpeedModule:AddToggle({
    Name = "Natychmiastowy Doskok (Instant Snap)",
    Description = "Pety teleportują się w ułamku sekundy wprost na monetę",
    Default = true,
    CurrentValue = true,
    Flag = "General_PetInstantSnap",
    Callback = function(state) State.PetInstantSnap = state end
})

-- // ==================== ZAKŁADKA 2: GARDEN ====================
local TabGarden = Window:CreateTab("Garden", "flower")

-- MODUŁ 1: AUTO FARM OGRODU (INSTA-GROW & KIPSUŁA)
local GardenFarmModule = TabGarden:CreateModule({
    Name = "Auto Farm Ogrodu (Insta-Grow & Kapsuła)",
    Description = "Pełna automatyzacja sadzenia, wzrostu nasion, podlewania i zbierania plonów",
    Default = true,
    CurrentValue = true,
    Flag = "Garden_AutoFarmGroup"
})

GardenFarmModule:AddToggle({
    Name = "Włącz Auto Farm Ogrodu",
    Description = "Ciągły cykl sadzenia, wzrostu nasion z kapsułą i zbioru plonów",
    Default = false,
    CurrentValue = false,
    Flag = "Garden_InstaPlantToggle",
    Callback = function(state) State.GardenInstaPlant = state end
})

GardenFarmModule:AddDropdown({
    Name = "Typ Nasiona (Seed)",
    Description = "Rodzaj nasiona używany do sadzenia w działkach",
    Options = {
        "Diamond Seed",
        "Coin Seed",
        "Gift Seed",
        "Potion Seed",
        "Enchant Seed",
        "Wszystkie (ALL)"
    },
    Default = "Diamond Seed",
    CurrentValue = "Diamond Seed",
    Flag = "Garden_SelectedSeed",
    Callback = function(val) State.GardenSelectedSeed = val end
})

GardenFarmModule:AddToggle({
    Name = "Krok 1: Auto Plant (Sadzenie)",
    Description = "Automatycznie sadzi wybrane nasiono w wolnych działkach",
    Default = true,
    CurrentValue = true,
    Flag = "Garden_StepPlantToggle",
    Callback = function(val) State.GardenStepPlant = val end
})

GardenFarmModule:AddToggle({
    Name = "Krok 2: Auto Insta-Grow (Wzrost & Kapsuła)",
    Description = "Pobiera wodę z kapsuły i natychmiastowo przyspiesza wzrost nasiona",
    Default = true,
    CurrentValue = true,
    Flag = "Garden_StepInstaGrowToggle",
    Callback = function(val) State.GardenStepInstaGrow = val end
})

GardenFarmModule:AddToggle({
    Name = "Krok 2b: Auto Water (Podlewanie konewką)",
    Description = "Podlewa nasiona/rośliny przy pomocy konewki",
    Default = false,
    CurrentValue = false,
    Flag = "Garden_StepWaterToggle",
    Callback = function(val) State.GardenStepWater = val end
})

GardenFarmModule:AddToggle({
    Name = "Krok 3: Auto Claim (Zbiór Plonów)",
    Description = "Automatycznie zbiera dojrzałe kwiaty i plony",
    Default = true,
    CurrentValue = true,
    Flag = "Garden_StepClaimToggle",
    Callback = function(val) State.GardenStepClaim = val end
})

GardenFarmModule:AddToggle({
    Name = "Auto Trzymaj Konewkę (Equip Can)",
    Description = "Automatycznie wyjmuje konewkę z plecaka do ręki gracza",
    Default = true,
    CurrentValue = true,
    Flag = "Garden_AutoEquipCanToggle",
    Callback = function(state) State.GardenAutoEquipCan = state end
})

GardenFarmModule:AddSlider({
    Name = "Opóźnienie Akcji (Sekundy)",
    Range = { 0.05, 1.0 },
    CurrentValue = 0.25,
    Min = 0.05,
    Max = 1.0,
    Default = 0.25,
    Suffix = "s",
    Flag = "Garden_ActionDelay",
    Callback = function(val) State.GardenActionDelay = val end
})

GardenFarmModule:AddSlider({
    Name = "Pauza Między Pętlami (Sekundy)",
    Range = { 0.2, 5.0 },
    CurrentValue = 0.8,
    Min = 0.2,
    Max = 5.0,
    Default = 0.8,
    Suffix = "s",
    Flag = "Garden_LoopDelay",
    Callback = function(val)
        State.GardenLoopDelay = val
        State.GardenInstaPlantDelay = val
    end
})

GardenFarmModule:AddButton({
    Name = "Insta-Grow Wszystkie Wybrane Działki Teraz",
    Callback = function() pcall(runInstaPlantAll) end
})

GardenFarmModule:AddButton({
    Name = "Pobierz Wodę z Kapsuły Teraz (Click Capsule)",
    Callback = function() pcall(collectWaterFromIncubator) end
})

GardenFarmModule:AddButton({
    Name = "Zbierz Wszystkie Gotowe Plony Teraz",
    Callback = function()
        for i = 1, 20 do
            harvestGardenPlant(i)
        end
    end
})

-- MODUŁ 2: WYBÓR DZIAŁEK DO FARMY (SLOTY 1-20)
local GardenSlotsModule = TabGarden:CreateModule({
    Name = "Wybór Działek do Farmy (Sloty 1-20)",
    Description = "Zaznacz, które działki w ogrodzie mają być automatycznie obsługiwane",
    Default = false,
    CurrentValue = false,
    Flag = "Garden_SlotsGroup"
})

GardenSlotsModule:AddToggle({
    Name = "Działki 1 - 5",
    Default = true,
    CurrentValue = true,
    Flag = "Garden_SlotGroup1_5",
    Callback = function(val)
        for i = 1, 5 do State.GardenFarmSlots[i] = val end
    end
})

GardenSlotsModule:AddToggle({
    Name = "Działki 6 - 10",
    Default = true,
    CurrentValue = true,
    Flag = "Garden_SlotGroup6_10",
    Callback = function(val)
        for i = 6, 10 do State.GardenFarmSlots[i] = val end
    end
})

GardenSlotsModule:AddToggle({
    Name = "Działki 11 - 15",
    Default = false,
    CurrentValue = false,
    Flag = "Garden_SlotGroup11_15",
    Callback = function(val)
        for i = 11, 15 do State.GardenFarmSlots[i] = val end
    end
})

GardenSlotsModule:AddToggle({
    Name = "Działki 16 - 20",
    Default = false,
    CurrentValue = false,
    Flag = "Garden_SlotGroup16_20",
    Callback = function(val)
        for i = 16, 20 do State.GardenFarmSlots[i] = val end
    end
})

GardenSlotsModule:AddButton({
    Name = "Zaznacz Wszystkie Działki (1-20)",
    Callback = function()
        for i = 1, 20 do State.GardenFarmSlots[i] = true end
    end
})

GardenSlotsModule:AddButton({
    Name = "Odznacz Wszystkie Działki (1-20)",
    Callback = function()
        for i = 1, 20 do State.GardenFarmSlots[i] = false end
    end
})

-- MODUŁ 3: ESP DZIAŁEK (FLOWER GARDEN ESP)
local GardenESPModule = TabGarden:CreateModule({
    Name = "ESP Działek (Flower Garden ESP)",
    Description = "Wyświetla stan działek (Rośnie / Gotowa / Pusta) oraz dystans i ramki 3D",
    Default = false,
    CurrentValue = false,
    Flag = "Garden_ESPGroup"
})

GardenESPModule:AddToggle({
    Name = "Włącz ESP Działek",
    Description = "Pokazuje tabliczki statusu i podświetlenie działek",
    Default = false,
    CurrentValue = false,
    Flag = "Garden_ESPEnabledToggle",
    Callback = function(val) State.GardenESPEnabled = val end
})

GardenESPModule:AddDropdown({
    Name = "Tryb Wyświetlania ESP",
    Options = { "Tylko Farmiące", "Wszystkie (1-20)" },
    Default = "Tylko Farmiące",
    CurrentValue = "Tylko Farmiące",
    Flag = "Garden_ESPModeDropdown",
    Callback = function(val) State.GardenESPMode = val end
})

GardenESPModule:AddToggle({
    Name = "Pokaż Status (Pusta / Rośnie / Gotowa)",
    Default = true,
    CurrentValue = true,
    Flag = "Garden_ESPStatusToggle",
    Callback = function(val) State.GardenESPShowStatus = val end
})

GardenESPModule:AddToggle({
    Name = "Pokaż Odległość (Studs)",
    Default = true,
    CurrentValue = true,
    Flag = "Garden_ESPDistanceToggle",
    Callback = function(val) State.GardenESPShowDistance = val end
})

GardenESPModule:AddToggle({
    Name = "Pokaż Podświetlenie 3D (Highlight)",
    Default = true,
    CurrentValue = true,
    Flag = "Garden_ESPHighlightToggle",
    Callback = function(val) State.GardenESPShowHighlight = val end
})

-- MODUŁ 4: TELEPORTY I NARZĘDZIA OGRODU
local GardenUtilsModule = TabGarden:CreateModule({
    Name = "Teleporty i Narzędzia Ogrodu",
    Description = "Szybkie teleporty, obsługa inkubatora i otwieranie skrzyń FlowerGarden",
    Default = false,
    CurrentValue = false,
    Flag = "Garden_UtilsGroup"
})

GardenUtilsModule:AddButton({
    Name = "Teleportuj do Donic (Grządki)",
    Callback = function()
        local plants = getGardenPlantsFolder()
        local p1 = plants and (plants:FindFirstChild("Plant1") or plants:FindFirstChild("Plant2"))
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp and p1 then
            local pos = getCoinPosition(p1)
            if pos then hrp.CFrame = CFrame.new(pos + Vector3.new(0, 4, 2)) end
        end
    end
})

GardenUtilsModule:AddButton({
    Name = "Teleport do Kapsuły Wody (-437.83, 109.46, -1421.35)",
    Callback = function()
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.CFrame = CFrame.new(-442, 112, -1418)
        end
    end
})

GardenUtilsModule:AddButton({
    Name = "Stań przy Kapsule & Donicach (Optimal Spot)",
    Callback = function()
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            local incPos = getIncubatorPosition()
            if incPos then
                hrp.CFrame = CFrame.new(incPos + Vector3.new(-3, 2, 2))
            else
                hrp.CFrame = CFrame.new(-442, 112, -1418)
            end
        end
    end
})

GardenUtilsModule:AddButton({
    Name = "Otwórz Skrzynię Ogrodu (Claim Chest)",
    Callback = function() pcall(claimGardenChest) end
})

GardenUtilsModule:AddButton({
    Name = "Użyj Inkubatora (Use Incubator)",
    Callback = function() pcall(useGardenIncubator) end
})

GardenUtilsModule:AddButton({
    Name = "Teleport do Inkubatora (Incubator TP)",
    Callback = function()
        local fg = getFlowerGardenContainer()
        local inc = fg and fg:FindFirstChild("Interactable") and fg.Interactable:FindFirstChild("InstaPlantIncubator")
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp and inc then
            local pos = getCoinPosition(inc)
            if pos then hrp.CFrame = CFrame.new(pos + Vector3.new(0, 4, 2)) end
        end
    end
})

GardenUtilsModule:AddButton({
    Name = "Teleportuj do Sklepu Ogrodu (Merchant)",
    Callback = function()
        local fg = getFlowerGardenContainer()
        local merchant = fg and (fg:FindFirstChild("Merchant") or fg:FindFirstChild("Shop") or fg:FindFirstChild("GardenMerchant"))
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp and merchant then
            local pos = getCoinPosition(merchant)
            if pos then hrp.CFrame = CFrame.new(pos + Vector3.new(0, 4, 2)) end
        end
    end
})

-- Anti-AFK
task.spawn(function()
    local idledConn = LocalPlayer.Idled:Connect(function()
        VirtualUser:Button2Down(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
        task.wait(1)
        VirtualUser:Button2Up(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
    end)
    table.insert(ScriptConnections, idledConn)
end)

