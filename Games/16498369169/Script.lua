-- // ==========================================================================
-- // PET SIMULATOR 99 HALLOWEEN EVENT - AUTOMATION SUITE
-- // Dedicated script for MenuTest UI Library (https://github.com/XxvoltikxX/MenuTest)
-- // Features: AutoFarm, Auto Collect (Orbs & LootBags), Player Speed, Pet Speed (Fast Pets)
-- // Game ID: 16498369169
-- // Tab: General
-- // ==========================================================================

-- 0. Sprzątanie poprzedniej instancji skryptu Halloween
if typeof(getgenv) == "function" and getgenv()._PS99HalloweenCleanup then
    pcall(getgenv()._PS99HalloweenCleanup)
    getgenv()._PS99HalloweenCleanup = nil
end
if _G.PS99HalloweenCleanup then
    pcall(_G.PS99HalloweenCleanup)
    _G.PS99HalloweenCleanup = nil
end

-- 1. Inicjalizacja MenuTest UI Library (XxvoltikxX / MenuTest)
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
    warn("[PetHub] Nie udało się załadować MenuTest z GitHub! Upewnij się, że masz połączenie z siecią.")
    return
end

-- // SERWISY ROBLOX
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

-- Flaga żywotności skryptu dla pętli w tle
local ScriptRunning = true

-- // INICJALIZACJA FRAMEWORK / LIBRARY GRY (Pet Simulator X / 99)
local Framework = nil
local Library = nil

local function loadGameLibrary()
    if Framework and (Framework.Network or Framework.Things) then return Framework end
    local candidates = {
        function() return require(ReplicatedStorage.Library) end,
        function() return require(ReplicatedStorage:WaitForChild("Library", 1)) end,
        function() return require(ReplicatedStorage.Framework.Library) end,
        function() return require(ReplicatedStorage:WaitForChild("Framework", 1):WaitForChild("Library", 1)) end,
    }
    for _, fn in ipairs(candidates) do
        local ok, res = pcall(fn)
        if ok and type(res) == "table" then
            Framework = res
            Library = res
            return res
        end
    end
    if typeof(getloadedmodules) == "function" then
        for _, mod in ipairs(getloadedmodules()) do
            if mod.Name == "Library" or mod.Name == "Framework" then
                local ok, res = pcall(require, mod)
                if ok and type(res) == "table" and (res.Network or res.Directory) then
                    Framework = res
                    Library = res
                    return res
                end
            end
        end
    end
    return nil
end

pcall(loadGameLibrary)
pcall(function()
    if Framework and Framework.Settings then Framework.Settings.CoinGrabDistance = math.huge end
    if Library and Library.Settings then Library.Settings.CoinGrabDistance = math.huge end
end)

-- Bezpieczne pobranie Things i Map
local function getThingsFolder()
    if Framework and Framework.Things then return Framework.Things end
    return Workspace:FindFirstChild("__THINGS")
end

local function getMapFolder()
    return Workspace:FindFirstChild("__MAP")
end

-- // POMOCNICZE FUNKCJE SIECIOWE (ODPORNE NA WIELKOŚĆ LITER I BEZPOŚREDNIE REMOTES)
local function fireRemote(name, ...)
    local called = false
    if Framework and Framework.Network and Framework.Network.Fire then
        local ok = pcall(Framework.Network.Fire, name, ...)
        if ok then
            called = true
        else
            local ok2 = pcall(Framework.Network.Fire, string.lower(name), ...)
            if ok2 then called = true end
        end
    end
    if not called then
        local things = getThingsFolder()
        local remotes = things and things:FindFirstChild("__REMOTES")
        if remotes then
            local r = remotes:FindFirstChild(name) or remotes:FindFirstChild(string.lower(name))
            if r and r:IsA("RemoteEvent") then
                pcall(r.FireServer, r, ...)
            end
        end
    end
end

local function invokeRemote(name, ...)
    if Framework and Framework.Network and Framework.Network.Invoke then
        local ok, res = pcall(Framework.Network.Invoke, name, ...)
        if ok and res ~= nil then return res end
        local ok2, res2 = pcall(Framework.Network.Invoke, string.lower(name), ...)
        if ok2 and res2 ~= nil then return res2 end
    end
    local things = getThingsFolder()
    local remotes = things and things:FindFirstChild("__REMOTES")
    if remotes then
        local r = remotes:FindFirstChild(name) or remotes:FindFirstChild(string.lower(name))
        if r and r:IsA("RemoteFunction") then
            local ok, res = pcall(r.InvokeServer, r, ...)
            if ok and res ~= nil then return res end
        end
    end
    return nil
end

-- // GŁÓWNA TABELA STANU SKRYPTU
local State = {
    -- 1. AutoFarm
    FarmActive = false,
    FarmRange = 600,
    FarmInfiniteRange = true,                              -- Nielimitowany zasięg (brak ograniczenia do pozycji gracza)
    FarmAnchorEnabled = false,                             -- Blokada pozycji farmu (farmienie wybranego punktu/strefy)
    FarmAnchorPos = nil,                                  -- Zapisana pozycja Vector3 centrum farmu
    FarmAnchorArea = nil,                                 -- Zapisana nazwa strefy farmu
    FarmAntiRecall = true,                                -- Blokada powrotu petów do gracza (Stay At Target / No Leash)
    CurrentTargetCoin = nil,

    -- Wybór celu i priorytetu farmowania
    FarmTargetType = "Wszystko (ALL)",                     -- Wybór celu lub "Wszystko (ALL)"
    FarmPriority = "ALL (Od Najlepszego do Najsłabszego)", -- Tryb sortowania
    FarmAreaOnly = false,                                   -- Ograniczenie do strefy (domyślnie wyłączone)

    -- Filtry poszczególnych rodzajów obiektów (używane gdy FarmTargetType to ALL lub Custom)
    FarmTypes = {
        ["Vault"] = true,
        ["Chest"] = true,
        ["Small Chest"] = true,
        ["Safe"] = true,
        ["Crate"] = true,
        ["Present"] = true,
        ["Diamonds"] = true,
        ["Large Coins"] = true,
        ["Coins"] = true,
        ["Tiny Coins"] = true,
        ["Other"] = true,
    },

    -- 2. Auto Collect
    AutoOrbs = false,
    AutoLootbags = false,

    -- 3. Player Speed (SpeedScript gracza)
    PlayerSpeedEnabled = false,
    PlayerSpeedMode = "Legit",
    PlayerSpeedValue = 50,

    -- 4. Pet Speed (Szybkość Petów)
    PetSpeedEnabled = false,
    PetSpeedValue = 25,
    PetInstantSnap = true,
    PetMaxForce = true,

    -- Cache aktualnej mapy dla AutoFarmu
    DetectedMap = "Spawn",
}

-- // ==========================================================================
-- // 1. DETEKCJA AKTUALNEJ MAPY (WERYFIKACJA STREFY DLA AUTOFARMU)
-- // ==========================================================================
local function detectCurrentMap()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return "Spawn" end
    local pPos = hrp.Position

    local mapFolder = getMapFolder()
    if not mapFolder then return "Spawn" end

    -- Sprawdzanie Boxes (__MAP.Boxes)
    local boxes = mapFolder:FindFirstChild("Boxes")
    if boxes then
        local closestBox = nil
        local closestDist = math.huge
        for _, box in ipairs(boxes:GetChildren()) do
            local bPos = nil
            if box:IsA("BasePart") then
                bPos = box.Position
            elseif box:IsA("Model") then
                bPos = box:GetPivot().Position
            end
            if bPos then
                local dist = (Vector3.new(pPos.X, 0, pPos.Z) - Vector3.new(bPos.X, 0, bPos.Z)).Magnitude
                if dist < closestDist then
                    closestDist = dist
                    closestBox = box.Name
                end
            end
        end
        if closestBox and closestDist < 350 then
            return closestBox
        end
    end

    -- Sprawdzanie Areas (__MAP.Areas)
    local areas = mapFolder:FindFirstChild("Areas")
    if areas then
        local closestArea = nil
        local closestDist = math.huge
        for _, area in ipairs(areas:GetChildren()) do
            local aPos = nil
            if area:IsA("BasePart") then
                aPos = area.Position
            elseif area:IsA("Model") then
                aPos = area:GetPivot().Position
            end
            if aPos then
                local dist = (Vector3.new(pPos.X, 0, pPos.Z) - Vector3.new(aPos.X, 0, aPos.Z)).Magnitude
                if dist < closestDist then
                    closestDist = dist
                    closestArea = area.Name
                end
            end
        end
        if closestArea and closestDist < 400 then
            return closestArea
        end
    end

    return "Spawn"
end

-- // ==========================================================================
-- // 2. LOGIKA AUTOFARM (INTELIGENTNA KLASYFIKACJA I PRECYZYJNY WYBÓR W KOLE PROMIENIA)
-- // ==========================================================================

-- Śledzenie połączeń do bezpiecznego sprzątania
local ScriptConnections = {}

-- Cache danych monet (Network / Upvalues)
local CoinsCache = {}

-- Bezpieczne pobranie wszystkich folderów z monetami/obiektami (z buforem TTL)
local cachedCoinFolders = {}
local lastCoinFoldersCheck = 0

local function getCoinsFolders()
    local now = tick()
    if (now - lastCoinFoldersCheck < 5.0) and #cachedCoinFolders > 0 then
        local allValid = true
        for _, f in ipairs(cachedCoinFolders) do
            if not f or not f.Parent then
                allValid = false
                break
            end
        end
        if allValid then return cachedCoinFolders end
    end
    lastCoinFoldersCheck = now

    local folders = {}
    local things = getThingsFolder() or Workspace:FindFirstChild("__THINGS")
    if things then
        local c = things:FindFirstChild("Coins")
        if c then table.insert(folders, c) end
        local b = things:FindFirstChild("Breakables")
        if b then table.insert(folders, b) end
    end
    local wCoins = Workspace:FindFirstChild("Coins")
    if wCoins and not table.find(folders, wCoins) then table.insert(folders, wCoins) end
    local wBreak = Workspace:FindFirstChild("Breakables")
    if wBreak and not table.find(folders, wBreak) then table.insert(folders, wBreak) end
    cachedCoinFolders = folders
    return folders
end

-- Uniwersalne pobieranie dokładnej pozycji obiektu/monety
local function getCoinPosition(coin)
    if not coin then return nil end
    if coin:IsA("BasePart") then
        return coin.Position
    end
    local posPart = coin:FindFirstChild("POS")
    if posPart and posPart:IsA("BasePart") then
        return posPart.Position
    end
    local coinPart = coin:FindFirstChild("Coin")
    if coinPart then
        if coinPart:IsA("BasePart") then
            return coinPart.Position
        elseif coinPart:IsA("Model") then
            local pp = coinPart.PrimaryPart or coinPart:FindFirstChildWhichIsA("BasePart")
            if pp then return pp.Position end
            if coinPart.GetPivot then return coinPart:GetPivot().Position end
        end
    end
    if coin:IsA("Model") then
        local pp = coin.PrimaryPart or coin:FindFirstChildWhichIsA("BasePart")
        if pp then return pp.Position end
        if coin.GetPivot then return coin:GetPivot().Position end
    end
    local anyPart = coin:FindFirstChildWhichIsA("BasePart", true)
    if anyPart then
        return anyPart.Position
    end
    return nil
end

-- Precyzyjna weryfikacja czy moneta jest żywa (odfiltrowuje niszczone lub martwe obiekty)
local function isCoinAlive(coin)
    if not coin or not coin.Parent then return false end
    if coin:GetAttribute("d") == true or coin:GetAttribute("Dead") == true or coin:GetAttribute("Destroyed") == true then
        return false
    end
    local hp = coin:GetAttribute("Health")
    if hp and hp <= 0 then
        return false
    end
    local pos = getCoinPosition(coin)
    if not pos then
        return false
    end
    return true
end

-- Precyzyjna weryfikacja obecności monety w kołowym promieniu wokół gracza lub bazy farmu (2D X-Z circle)
local function isCoinInRadius(coin, pPos, radius)
    if State.FarmInfiniteRange then
        return true, 0
    end

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

-- Jednorazowe przeszukanie GC przy starcie (nigdy w pętli cyklicznej, aby nie zapychać RAM-u)
local hasScannedUpvalues = false
local function scanCoinsUpvalues()
    if hasScannedUpvalues then return end
    hasScannedUpvalues = true
    pcall(function()
        if typeof(getgc) ~= "function" then return end
        for _, fn in pairs(getgc(true)) do
            if type(fn) == "function" then
                local isExec = false
                if typeof(isexecutorclosure) == "function" and isexecutorclosure(fn) then isExec = true end
                if not isExec then
                    local s = ""
                    pcall(function() s = debug.info(fn, "s") or "" end)
                    if s:find("Coins") then
                        local uvs = nil
                        pcall(function() uvs = debug.getupvalues(fn) end)
                        if type(uvs) == "table" then
                            for _, uv in pairs(uvs) do
                                if type(uv) == "table" then
                                    local k, v = next(uv)
                                    if type(v) == "table" and (v.n or v.p or v.h) then
                                        for cid, data in pairs(uv) do
                                            CoinsCache[tostring(cid)] = data
                                        end
                                        return
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end)
end

-- Aktywne pobieranie listy monet przez Network (z automatycznym zwalnianiem pamięci nieistniejących obiektów)
local lastCoinsFetch = 0
local function fetchCoinsFromNetwork(force)
    local now = tick()
    if not force and (now - lastCoinsFetch < 10.0) then return end
    lastCoinsFetch = now

    pcall(function()
        local allCoins = invokeRemote("Get Coins")
        if type(allCoins) == "table" then
            local freshCache = {}
            for id, data in pairs(allCoins) do
                freshCache[tostring(id)] = data
            end
            CoinsCache = freshCache
        end
    end)
end

-- Jednorazowe pobranie bazy na starcie skryptu
task.spawn(function()
    fetchCoinsFromNetwork(true)
    task.wait(1.0)
    scanCoinsUpvalues()
end)

-- Głębokie rozpoznawanie kategorii obiektu bezpośrednio z instancji w Workspace
local function detectCategoryFromInstance(coin)
    if not coin then return nil, nil end

    for _, attr in ipairs({"CoinType", "Type", "Name", "CoinName", "n", "Category"}) do
        local val = coin:GetAttribute(attr)
        if val and type(val) == "string" and not tonumber(val) and #val > 0 then
            local vLow = string.lower(val)
            if vLow:find("diamond") or vLow:find("gem") then return "Diamonds", val
            elseif vLow:find("vault") then return "Vault", val
            elseif vLow:find("small chest") or vLow:find("small_chest") then return "Small Chest", val
            elseif vLow:find("chest") then return "Chest", val
            elseif vLow:find("safe") then return "Safe", val
            elseif vLow:find("crate") or vLow:find("barrel") or vLow:find("box") then return "Crate", val
            elseif vLow:find("present") or vLow:find("gift") then return "Present", val
            elseif vLow:find("large coin") or vLow:find("large_coin") or vLow:find("giant coin") then return "Large Coins", val
            elseif vLow:find("tiny coin") or vLow:find("tiny_coin") then return "Tiny Coins", val
            elseif vLow:find("coin") then return "Coins", val
            end
        end
    end

    for _, child in ipairs(coin:GetDescendants()) do
        local cName = string.lower(child.Name)
        if cName:find("diamond") or cName:find("gem") then
            return "Diamonds", child.Name
        elseif cName:find("small chest") or cName:find("small_chest") then
            return "Small Chest", child.Name
        elseif cName:find("chest") then
            return "Chest", child.Name
        elseif cName:find("vault") then
            return "Vault", child.Name
        elseif cName:find("safe") then
            return "Safe", child.Name
        elseif cName:find("crate") or cName:find("barrel") or cName:find("box") then
            return "Crate", child.Name
        elseif cName:find("present") or cName:find("gift") then
            return "Present", child.Name
        elseif cName:find("large coin") or cName:find("giant coin") then
            return "Large Coins", child.Name
        elseif cName:find("tiny coin") then
            return "Tiny Coins", child.Name
        end

        if child:IsA("TextLabel") and child.Text and #child.Text > 0 then
            local t = string.lower(child.Text)
            if t:find("diamond") or t:find("gem") then return "Diamonds", child.Text
            elseif t:find("small chest") then return "Small Chest", child.Text
            elseif t:find("chest") then return "Chest", child.Text
            elseif t:find("vault") then return "Vault", child.Text
            elseif t:find("safe") then return "Safe", child.Text
            elseif t:find("crate") then return "Crate", child.Text
            elseif t:find("present") then return "Present", child.Text
            end
        end
    end

    return nil, nil
end

-- Pobranie informacji o monecie (ID, nazwa, zdrowie, max zdrowie)
local function getCoinInfo(coin)
    local coinId = coin:GetAttribute("ID") or coin.Name
    local coinName = coin:GetAttribute("Name") or coin:GetAttribute("CoinName") or coin:GetAttribute("Type")
    local hp = coin:GetAttribute("Health")
    local maxHp = coin:GetAttribute("MaxHealth")

    local entry = CoinsCache[tostring(coinId)] or CoinsCache[tonumber(coinId)]
    if entry then
        coinName = entry.n or entry.name or entry.Name or entry.CoinType or coinName
        hp = hp or entry.h or entry.health
        maxHp = maxHp or entry.mh or entry.maxHealth or hp
    end

    if not coinName or coinName == "" or tonumber(coinName) then
        local coinChild = coin:FindFirstChild("Coin")
        if coinChild then
            local cName = coinChild:GetAttribute("Name") or coinChild:GetAttribute("CoinType") or coinChild.Name
            if cName and not tonumber(cName) and cName ~= "Coin" then
                coinName = cName
            end
        end
    end

    if not coinName or coinName == "" or tonumber(coinName) then
        local detectedCat, detectedName = detectCategoryFromInstance(coin)
        if detectedName then
            coinName = detectedName
        elseif detectedCat then
            coinName = detectedCat
        else
            coinName = coin.Name
        end
    end

    return coinId, coinName, hp or 100, maxHp or hp or 100
end

-- Klasyfikacja obiektów do kategorii
local function getCoinCategory(coinName, coinInstance)
    local name = string.lower(tostring(coinName or ""))

    if #name == 0 or tonumber(name) or name == "coin" then
        if coinInstance then
            local cat = detectCategoryFromInstance(coinInstance)
            if cat then return cat end
        end
    end

    if name:find("diamond") or name:find("gem") then
        return "Diamonds"
    elseif name:find("vault") then
        return "Vault"
    elseif name:find("small chest") or name:find("small_chest") then
        return "Small Chest"
    elseif name:find("chest") then
        return "Chest"
    elseif name:find("safe") then
        return "Safe"
    elseif name:find("crate") or name:find("barrel") or name:find("box") then
        return "Crate"
    elseif name:find("present") or name:find("gift") then
        return "Present"
    elseif name:find("tiny coin") or name:find("tiny_coin") then
        return "Tiny Coins"
    elseif name:find("large coin") or name:find("large_coin") or name:find("giant coin") then
        return "Large Coins"
    elseif name:find("coin") then
        return "Coins"
    end

    if coinInstance then
        local cat = detectCategoryFromInstance(coinInstance)
        if cat then return cat end
    end

    return "Coins"
end

-- Mapowanie wyboru z Dropdowna na klucz kategorii
local DropdownToCategory = {
    ["Wszystko (ALL)"] = "ALL",
    ["Wszystkie (ALL)"] = "ALL",
    ["Tylko Diamenty (Diamonds)"] = "Diamonds",
    ["Diamonds (Diamenty)"] = "Diamonds",
    ["Tylko Skrzynie (Wszystkie skrzynie)"] = "AllChests",
    ["Tylko Wielkie Skrzynie (Big Chests)"] = "Chest",
    ["Chest (Wielkie Skrzynie)"] = "Chest",
    ["Tylko Małe Skrzynie (Small Chests)"] = "Small Chest",
    ["Small Chest (Małe Skrzynie)"] = "Small Chest",
    ["Tylko Skarbce (Vaults)"] = "Vault",
    ["Vault (Skarbce)"] = "Vault",
    ["Tylko Sejfy (Safes)"] = "Safe",
    ["Safe (Sejfy)"] = "Safe",
    ["Tylko Skrzynki (Crates)"] = "Crate",
    ["Crate (Skrzynki drewniane)"] = "Crate",
    ["Tylko Prezenty (Presents)"] = "Present",
    ["Present (Prezenty)"] = "Present",
    ["Tylko Duże Monety (Large Coins)"] = "Large Coins",
    ["Large Coins (Duże Monety)"] = "Large Coins",
    ["Tylko Zwykłe Monety (Coins)"] = "Coins",
    ["Coins (Zwykłe Monety)"] = "Coins",
    ["Tylko Małe Monety (Tiny Coins)"] = "Tiny Coins",
    ["Tiny Coins (Małe Monety)"] = "Tiny Coins",
    ["Wybrane w przełącznikach poniżej (Custom)"] = "CUSTOM",
}

-- Weryfikacja czy dany rodzaj obiektu jest dopuszczony do farmowania
local function isCoinAllowed(category)
    local selectedTarget = State.FarmTargetType or "Wszystko (ALL)"
    local targetCategory = DropdownToCategory[selectedTarget] or selectedTarget

    if targetCategory == "ALL" then
        return true
    elseif targetCategory == "CUSTOM" then
        if State.FarmTypes and State.FarmTypes[category] ~= nil then
            return State.FarmTypes[category] == true
        end
        return false
    elseif targetCategory == "AllChests" then
        return category == "Chest" or category == "Small Chest"
    elseif targetCategory and targetCategory ~= "" then
        return category == targetCategory
    end

    if State.FarmTypes and State.FarmTypes[category] ~= nil then
        return State.FarmTypes[category] == true
    end

    return true
end

-- Bazowa wartość kategorii (Hierarchia od najlepszego do najsłabszego)
local CategoryBaseScore = {
    ["Vault"]       = 1000000,
    ["Chest"]       = 800000,
    ["Diamonds"]    = 600000,
    ["Small Chest"] = 500000,
    ["Safe"]        = 400000,
    ["Present"]     = 300000,
    ["Crate"]       = 200000,
    ["Large Coins"] = 100000,
    ["Coins"]       = 50000,
    ["Tiny Coins"]  = 10000,
    ["Other"]       = 5000,
}

local function evaluateCoinScore(category, hp, maxHp, dist)
    local priority = State.FarmPriority or "ALL (Od Najlepszego do Najsłabszego)"
    local baseScore = CategoryBaseScore[category] or 5000

    if priority == "Najbliższe (Najmniejsza Odległość)" or priority:find("Najbliższe") then
        return 10000000 - (dist * 100)
    elseif priority == "Najwięcej HP (Największe / Bossy)" or priority:find("Najwięcej HP") then
        return (maxHp or 0) - (dist * 5)
    elseif priority == "Najmniej HP (Szybkie Czyszczenie)" or priority:find("Najmniej HP") then
        return -(maxHp or 0) - (dist * 5)
    else
        local score = baseScore
        score = score + ((maxHp or 0) / 50000)
        score = score - (dist * 0.5)
        return score
    end
end

-- Główny algorytm wyszukiwania najlepszej monety w pełnym promieniu koła
local function findBestCoin()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local pPos = (State.FarmAnchorEnabled and State.FarmAnchorPos) or hrp.Position

    local bestCoin = nil
    local bestScore = -math.huge
    local currentMap = (State.FarmAnchorEnabled and State.FarmAnchorArea) or State.DetectedMap or "Spawn"
    local currentLower = string.lower(currentMap)

    local folders = getCoinsFolders()
    for _, folder in ipairs(folders) do
        for _, coin in ipairs(folder:GetChildren()) do
            if isCoinAlive(coin) then
                local inRadius, dist = isCoinInRadius(coin, pPos, State.FarmRange)
                if inRadius then
                    local _, coinName, hp, maxHp = getCoinInfo(coin)
                    local category = getCoinCategory(coinName, coin)

                    if isCoinAllowed(category) then
                        local isAllowedArea = true
                        if State.FarmAreaOnly and currentMap ~= "Spawn" then
                            local coinArea = coin:GetAttribute("Area")
                            if not coinArea and CoinsCache[coin.Name] then
                                coinArea = CoinsCache[coin.Name].a
                            end
                            local coinNameLower = string.lower(coinName)
                            if coinArea and coinArea ~= "" then
                                isAllowedArea = string.lower(coinArea):find(currentLower, 1, true) ~= nil
                            else
                                isAllowedArea = coinNameLower:find(currentLower, 1, true) ~= nil
                            end
                        end

                        if isAllowedArea then
                            local score = evaluateCoinScore(category, hp, maxHp, dist)
                            if score > bestScore then
                                bestScore = score
                                bestCoin = coin
                            end
                        end
                    end
                end
            end
        end
    end

    return bestCoin
end

-- Pomocnicza funkcja: pobranie UID wszystkich założonych petów gracza (z buforem TTL)
local cachedEquippedUids = {}
local lastEquippedFetch = 0

local function getEquippedPets(force)
    local now = tick()
    if not force and (now - lastEquippedFetch < 1.0) and #cachedEquippedUids > 0 then
        return cachedEquippedUids
    end
    lastEquippedFetch = now

    local equippedUids = {}
    if Framework and Framework.PetCmds and Framework.PetCmds.GetEquipped then
        local eq = Framework.PetCmds.GetEquipped(LocalPlayer, true)
        if type(eq) == "table" then
            for _, uid in ipairs(eq) do
                table.insert(equippedUids, uid)
            end
        end
    end
    if #equippedUids == 0 and Framework and Framework.Save and Framework.Save.Get then
        local save = Framework.Save.Get()
        if save and save.Pets then
            for _, p in ipairs(save.Pets) do
                if p.e then table.insert(equippedUids, p.uid) end
            end
        end
    end
    if #equippedUids == 0 then
        local things = getThingsFolder() or Workspace:FindFirstChild("__THINGS")
        local petsFolder = things and things:FindFirstChild("Pets")
        if petsFolder then
            for _, p in ipairs(petsFolder:GetChildren()) do
                if p:GetAttribute("Owner") == LocalPlayer.Name or p.Name:find(LocalPlayer.Name, 1, true) then
                    table.insert(equippedUids, p.Name)
                end
            end
        end
    end
    cachedEquippedUids = equippedUids
    return equippedUids
end

-- Weryfikacja czy dany pet w workspace należy do gracza
local function isMyPet(pet, optionalUids)
    if not pet then return false end
    local owner = pet:GetAttribute("Owner")
    if owner and tostring(owner) == LocalPlayer.Name then
        return true
    end
    if pet.Name:find(LocalPlayer.Name, 1, true) then
        return true
    end
    local myUids = optionalUids or getEquippedPets()
    local uid = pet:GetAttribute("UID")
    if table.find(myUids, pet.Name) or (uid and table.find(myUids, uid)) then
        return true
    end
    for _, attr in ipairs({"OwnerName", "Player", "UserId"}) do
        local val = pet:GetAttribute(attr)
        if val == LocalPlayer.Name or val == LocalPlayer.UserId then
            return true
        end
    end
    return false
end

-- Hookowanie natywnej biblioteki Agility dla petów w Framework / Library (Pet Speed Engine)
local function hookPetSpeed()
    local targetLib = Framework or Library
    if not targetLib then return end

    local shared = targetLib.Shared
    if not shared and targetLib.Directory and targetLib.Directory.Shared then
        shared = targetLib.Directory.Shared
    end

    if shared and not shared._PetSpeedHooked then
        shared._PetSpeedHooked = true

        local origHasPower = shared.HasPower
        shared.HasPower = function(pet, powerName, ...)
            if State.PetSpeedEnabled and powerName == "Agility" then
                return true, 3
            end
            if origHasPower then
                return origHasPower(pet, powerName, ...)
            end
            return false
        end

        local origGetPowerDir = shared.GetPowerDir
        shared.GetPowerDir = function(powerName, tier, ...)
            if State.PetSpeedEnabled and powerName == "Agility" then
                local mult = tonumber(State.PetSpeedValue) or 25
                return {
                    title = "Agility III",
                    desc = "Pet moves ultra fast",
                    value = mult
                }
            end
            if origGetPowerDir then
                return origGetPowerDir(powerName, tier, ...)
            end
            return { title = "Agility", desc = "", value = 1 }
        end
    end
end
pcall(hookPetSpeed)

local petMoverCache = setmetatable({}, { __mode = "k" })

-- Wzmocnienie siły fizycznej i responsywności petów w Workspace (Brak lagów za graczem i blokada powrotu)
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
                    if State.PetMaxForce or mult >= 15 then
                        bp.D = 250
                    end
                end
                -- Zabezpieczenie przed powrotem petów (Anti-Recall / Tether Lock na odległość)
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

-- Asynchroniczne atakowanie monety petami
local function attackCoin(coin)
    if not isCoinAlive(coin) then return end
    State.CurrentTargetCoin = coin

    local coinId = coin:GetAttribute("ID") or coin.Name

    task.spawn(function()
        -- 0. Natychmiastowy doskok petów do monety (Instant Target Snap)
        if State.PetSpeedEnabled and State.PetInstantSnap then
            local coinPos = getCoinPosition(coin)
            if coinPos then
                local things = getThingsFolder()
                local petsFolder = things and things:FindFirstChild("Pets")
                if petsFolder then
                    for _, pet in ipairs(petsFolder:GetChildren()) do
                        if isMyPet(pet) then
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

        -- 1. Game Native Signal
        if Framework and Framework.Signal and Framework.Signal.Fire then
            pcall(function()
                Framework.Signal.Fire("Group Select Coin", coin)
            end)
        end

        -- 2. Game Native Network Fire
        fireRemote("Select Coin", coin.Name, true)

        -- 3. Direct Network Invoke (Join Coin + Farm Coin)
        local equippedUids = getEquippedPets()
        if #equippedUids > 0 then
            invokeRemote("Join Coin", coinId, equippedUids)
            for _, uid in ipairs(equippedUids) do
                fireRemote("Farm Coin", coinId, uid)
            end
        end

        -- 4. ClickDetector fallback
        local cd = coin:FindFirstChildWhichIsA("ClickDetector", true)
        if cd and typeof(fireclickdetector) == "function" then
            pcall(function()
                fireclickdetector(cd)
            end)
        end
    end)
end

-- // ==========================================================================
-- // 3. AUTO COLLECT: ORBS ORAZ LOOTBAGS
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
    local groundCFrame = hrp.CFrame * CFrame.new(0, 10, 0)
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
            if orb.PivotTo then
                orb:PivotTo(groundCFrame)
            elseif orb.PrimaryPart then
                orb:SetPrimaryPartCFrame(groundCFrame)
            end
        end
    end

    if #claimedIds > 0 then
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

    local groundCFrame = hrp.CFrame * CFrame.new(0, -2.5, 0)
    local hasFireTouch = typeof(firetouchinterest) == "function"

    for _, bag in ipairs(children) do
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
            local mainPart = bag.PrimaryPart or bag:FindFirstChildWhichIsA("BasePart")
            if bag.PivotTo then
                bag:PivotTo(groundCFrame)
            elseif mainPart then
                mainPart.CFrame = groundCFrame
            end

            if mainPart and hasFireTouch then
                pcall(function()
                    firetouchinterest(hrp, mainPart, 0)
                    firetouchinterest(hrp, mainPart, 1)
                end)
            end
        end
    end
end

-- // ==========================================================================
-- // 4. SYSTEM PRĘDKOŚCI GRACZA (SPEED ENGINE)
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
    if moveDir.Magnitude > 0 then
        moveDir = moveDir.Unit
    end

    local movement = Vector3.zero
    if UserInputService:IsKeyDown(Enum.KeyCode.W) or UserInputService:IsKeyDown(Enum.KeyCode.Up) then movement = movement + moveDir end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) or UserInputService:IsKeyDown(Enum.KeyCode.Down) then movement = movement - moveDir end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) or UserInputService:IsKeyDown(Enum.KeyCode.Right) then movement = movement + Vector3.new(-moveDir.Z, 0, moveDir.X) end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) or UserInputService:IsKeyDown(Enum.KeyCode.Left) then movement = movement + Vector3.new(moveDir.Z, 0, -moveDir.X) end

    if movement.Magnitude > 0 then
        return true, movement.Unit
    end
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
                if hum.WalkSpeed ~= targetSpeed then
                    hum.WalkSpeed = targetSpeed
                end
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
    end
end

initSpeedConnections()

LocalPlayer.CharacterAdded:Connect(function(newChar)
    if State.PlayerSpeedEnabled or _G.SpeedEnabled then
        task.wait(0.2)
        local hum = newChar:WaitForChild("Humanoid", 3)
        if hum and (State.PlayerSpeedMode == "Normal") then
            hum.WalkSpeed = State.PlayerSpeedValue or 50
        end
    end
end)

-- // ==========================================================================
-- // 5. PĘTLE W TLE (BACKGROUND LOOPS)
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
                local _, cName = getCoinInfo(current)
                local cat = getCoinCategory(cName, current)
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
                -- Ograniczony keepalive pulse sieciowy (co 1.5s zamiast spamu co 0.15s)
                local now = tick()
                if (now - lastFarmPulse >= 1.5) and (State.FarmAntiRecall or State.FarmInfiniteRange or State.FarmAnchorEnabled) then
                    lastFarmPulse = now
                    local coinId = current:GetAttribute("ID") or current.Name
                    local eq = getEquippedPets()
                    for _, uid in ipairs(eq) do
                        fireRemote("Farm Coin", coinId, uid)
                    end
                end

                retargetCounter = retargetCounter + 1
                if retargetCounter >= 6 then
                    retargetCounter = 0
                    local betterCoin = findBestCoin()
                    if betterCoin and betterCoin ~= current and isCoinAlive(betterCoin) then
                        local char = LocalPlayer.Character
                        local hrp = char and char:FindFirstChild("HumanoidRootPart")
                        local pPos = (State.FarmAnchorEnabled and State.FarmAnchorPos) or (hrp and hrp.Position) or Vector3.zero

                        local _, curName, curHp, curMaxHp = getCoinInfo(current)
                        local _, bName, bHp, bMaxHp = getCoinInfo(betterCoin)
                        local curPos = getCoinPosition(current) or pPos
                        local bPos = getCoinPosition(betterCoin) or pPos

                        local curScore = evaluateCoinScore(getCoinCategory(curName, current), curHp, curMaxHp, (pPos - curPos).Magnitude)
                        local bScore = evaluateCoinScore(getCoinCategory(bName, betterCoin), bHp, bMaxHp, (pPos - bPos).Magnitude)

                        if bScore > (curScore + 150000) then
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

-- Reaktywny nasłuch na natychmiastowe respawny obiektów (ChildAdded)
local boundCoinsFolders = {}
local function bindCoinsRespawnListeners()
    for _, folder in ipairs(getCoinsFolders()) do
        if not boundCoinsFolders[folder] then
            boundCoinsFolders[folder] = true
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
bindCoinsRespawnListeners()

-- Pętla cyklicznego odświeżania bazy danych monet (co 10s zamiast 1.5s bez obciążania pamięci)
task.spawn(function()
    while ScriptRunning do
        if State.FarmActive then
            bindCoinsRespawnListeners()
            fetchCoinsFromNetwork()
        end
        task.wait(10.0)
    end
end)

-- Pętla Auto Collect Orbs (zoptymalizowany interwał 0.25s)
task.spawn(function()
    while ScriptRunning do
        if State.AutoOrbs then
            collectOrbsClean()
            task.wait(0.25)
        else
            task.wait(0.6)
        end
    end
end)

-- Pętla Auto Collect LootBags (zoptymalizowany interwał 0.25s)
task.spawn(function()
    while ScriptRunning do
        if State.AutoLootbags then
            collectLootbagsClean()
            task.wait(0.25)
        else
            task.wait(0.6)
        end
    end
end)

-- Pętla cyklicznej detekcji mapy dla AutoFarmu
task.spawn(function()
    while ScriptRunning do
        State.DetectedMap = detectCurrentMap()
        task.wait(1.0)
    end
end)

-- Pętla aktualizacji fizyki i szybkości petów (Pet Speed Engine Loop)
task.spawn(function()
    while ScriptRunning do
        if State.PetSpeedEnabled then
            pcall(hookPetSpeed)
            pcall(updateWorkspacePetsPhysics)
            task.wait(0.2)
        else
            task.wait(0.6)
        end
    end
end)

-- Nasłuch na nowo zrespawnowane pety gracza w Workspace
local petsChildAddedConn = nil
local function bindPetsFolderListener()
    if petsChildAddedConn then return end
    local things = getThingsFolder()
    local petsFolder = things and (things:FindFirstChild("Pets") or things:WaitForChild("Pets", 5))
    if petsFolder then
        petsChildAddedConn = petsFolder.ChildAdded:Connect(function(child)
            if State.PetSpeedEnabled then
                task.wait(0.1)
                pcall(updateWorkspacePetsPhysics)
            end
        end)
        table.insert(ScriptConnections, petsChildAddedConn)
    end
end
task.spawn(bindPetsFolderListener)

-- // ==========================================================================
-- // 6. INTERFEJS UŻYTKOWNIKA MENUTEST (JEDNA GŁÓWNA ZAKŁADKA "GENERAL")
-- // ==========================================================================

local Window = MENU:CreateWindow({
    Name = "PetHub",
    Tittle = "Pet sim 99 event hallowen",
    TittlePos = "Center",
    ToggleUIKeybind = "K",
    TestMobile = false,
    GameId = "16498369169"
})

local function doCleanup()
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
    State.FarmAnchorEnabled = false
    State.FarmAnchorPos = nil
    State.FarmAnchorArea = nil
    State.CurrentTargetCoin = nil
end

if typeof(getgenv) == "function" then
    getgenv()._PS99HalloweenCleanup = doCleanup
end
_G.PS99HalloweenCleanup = doCleanup

-- Sprzątanie pętli i połączeń po zniszczeniu okna
if Window and Window.ScreenGui then
    Window.ScreenGui.Destroying:Connect(doCleanup)
end

-- Wyłączenie limitera prędkości AntiFling w Settings dla płynnego biegu
task.spawn(function()
    for _ = 1, 40 do
        if Window and Window.Flags and Window.Flags["AntiFling"] then
            pcall(function()
                if Window.Flags["AntiFling"].Set then
                    Window.Flags["AntiFling"]:Set(false)
                end
            end)
            break
        end
        task.wait(0.05)
    end
end)

if Window.OnReady then
    Window:OnReady(function()
        pcall(function()
            if Window.Flags and Window.Flags["AntiFling"] and Window.Flags["AntiFling"].Set then
                Window.Flags["AntiFling"]:Set(false)
            end
        end)
    end)
end

-- Główna zakładka General
local TabGeneral = Window:CreateTab("General", "home")

-- // ==================== MODUŁ 1: AUTOFARM ====================
local FarmModule = TabGeneral:CreateModule({
    Name = "AutoFarm",
    Description = "Automatycznie wyszukuje i atakuje wybrane obiekty w strefie",
    Default = false,
    CurrentValue = false,
    Flag = "General_AutoFarm",
    Callback = function(state)
        State.FarmActive = state
        if not state then
            State.CurrentTargetCoin = nil
        end
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
    Default = true,
    CurrentValue = true,
    Flag = "General_FarmInfiniteRange",
    Callback = function(state)
        State.FarmInfiniteRange = state
        State.CurrentTargetCoin = nil
    end
})

FarmModule:AddToggle({
    Name = "Zablokuj Miejsce Farmu (Lock Anchor)",
    Default = false,
    CurrentValue = false,
    Flag = "General_FarmAnchor",
    Callback = function(state)
        State.FarmAnchorEnabled = state
        if state then
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                State.FarmAnchorPos = hrp.Position
                State.FarmAnchorArea = State.DetectedMap or detectCurrentMap()
            end
        else
            State.FarmAnchorPos = nil
            State.FarmAnchorArea = nil
        end
        State.CurrentTargetCoin = nil
    end
})

FarmModule:AddToggle({
    Name = "Zabezpieczenie przed Powrotem Petów (Anti-Recall)",
    Default = true,
    CurrentValue = true,
    Flag = "General_FarmAntiRecall",
    Callback = function(state)
        State.FarmAntiRecall = state
    end
})

FarmModule:AddDropdown({
    Name = "Co ma kopać (Wybór Celu)",
    Options = {
        "Wszystko (ALL)",
        "Tylko Diamenty (Diamonds)",
        "Tylko Skrzynie (Wszystkie skrzynie)",
        "Tylko Wielkie Skrzynie (Big Chests)",
        "Tylko Małe Skrzynie (Small Chests)",
        "Tylko Skarbce (Vaults)",
        "Tylko Sejfy (Safes)",
        "Tylko Skrzynki (Crates)",
        "Tylko Prezenty (Presents)",
        "Tylko Duże Monety (Large Coins)",
        "Tylko Zwykłe Monety (Coins)",
        "Tylko Małe Monety (Tiny Coins)",
        "Wybrane w przełącznikach poniżej (Custom)"
    },
    CurrentOption = {"Wszystko (ALL)"},
    Default = "Wszystko (ALL)",
    Flag = "General_FarmTargetType",
    Callback = function(val)
        local selected = (type(val) == "table" and val[1]) or val
        State.FarmTargetType = selected
        State.CurrentTargetCoin = nil
    end
})

FarmModule:AddDropdown({
    Name = "Priorytet Wyboru (Tryb)",
    Options = {
        "ALL (Od Najlepszego do Najsłabszego)",
        "Najbliższe (Najmniejsza Odległość)",
        "Najwięcej HP (Największe / Bossy)",
        "Najmniej HP (Szybkie Czyszczenie)"
    },
    CurrentOption = {"ALL (Od Najlepszego do Najsłabszego)"},
    Default = "ALL (Od Najlepszego do Najsłabszego)",
    Flag = "General_FarmPriority",
    Callback = function(val)
        local selected = (type(val) == "table" and val[1]) or val
        State.FarmPriority = selected
        State.CurrentTargetCoin = nil
    end
})

FarmModule:AddToggle({
    Name = "Tylko Moja Strefa (Area Only)",
    Default = false,
    CurrentValue = false,
    Flag = "General_FarmAreaOnly",
    Callback = function(state)
        State.FarmAreaOnly = state
        State.CurrentTargetCoin = nil
    end
})

FarmModule:AddToggle({
    Name = "Farm Vault (Skarbce)",
    Default = true,
    CurrentValue = true,
    Flag = "General_Farm_Vault",
    Callback = function(state)
        State.FarmTypes["Vault"] = state
        State.CurrentTargetCoin = nil
    end
})

FarmModule:AddToggle({
    Name = "Farm Chest (Wielkie Skrzynie)",
    Default = true,
    CurrentValue = true,
    Flag = "General_Farm_Chest",
    Callback = function(state)
        State.FarmTypes["Chest"] = state
        State.CurrentTargetCoin = nil
    end
})

FarmModule:AddToggle({
    Name = "Farm Small Chest (Małe Skrzynie)",
    Default = true,
    CurrentValue = true,
    Flag = "General_Farm_SmallChest",
    Callback = function(state)
        State.FarmTypes["Small Chest"] = state
        State.CurrentTargetCoin = nil
    end
})

FarmModule:AddToggle({
    Name = "Farm Safe (Sejfy)",
    Default = true,
    CurrentValue = true,
    Flag = "General_Farm_Safe",
    Callback = function(state)
        State.FarmTypes["Safe"] = state
        State.CurrentTargetCoin = nil
    end
})

FarmModule:AddToggle({
    Name = "Farm Crate (Skrzynki drewniane)",
    Default = true,
    CurrentValue = true,
    Flag = "General_Farm_Crate",
    Callback = function(state)
        State.FarmTypes["Crate"] = state
        State.CurrentTargetCoin = nil
    end
})

FarmModule:AddToggle({
    Name = "Farm Present (Prezenty)",
    Default = true,
    CurrentValue = true,
    Flag = "General_Farm_Present",
    Callback = function(state)
        State.FarmTypes["Present"] = state
        State.CurrentTargetCoin = nil
    end
})

FarmModule:AddToggle({
    Name = "Farm Diamonds (Diamenty)",
    Default = true,
    CurrentValue = true,
    Flag = "General_Farm_Diamonds",
    Callback = function(state)
        State.FarmTypes["Diamonds"] = state
        State.CurrentTargetCoin = nil
    end
})

FarmModule:AddToggle({
    Name = "Farm Large Coins (Duże Monety)",
    Default = true,
    CurrentValue = true,
    Flag = "General_Farm_LargeCoins",
    Callback = function(state)
        State.FarmTypes["Large Coins"] = state
        State.CurrentTargetCoin = nil
    end
})

FarmModule:AddToggle({
    Name = "Farm Coins (Zwykłe Monety)",
    Default = true,
    CurrentValue = true,
    Flag = "General_Farm_Coins",
    Callback = function(state)
        State.FarmTypes["Coins"] = state
        State.CurrentTargetCoin = nil
    end
})

FarmModule:AddToggle({
    Name = "Farm Tiny Coins (Małe Monety)",
    Default = true,
    CurrentValue = true,
    Flag = "General_Farm_TinyCoins",
    Callback = function(state)
        State.FarmTypes["Tiny Coins"] = state
        State.CurrentTargetCoin = nil
    end
})

-- // ==================== MODUŁ 2: AUTO COLLECT ====================
local CollectModule = TabGeneral:CreateModule({
    Name = "Auto Collect",
    Description = "Automatyczne zbieranie Orbs i LootBags bez blokowania postaci",
    Default = false,
    CurrentValue = false,
    Flag = "General_AutoCollect",
    Callback = function(state)
        State.AutoOrbs = state
        State.AutoLootbags = state
    end
})

CollectModule:AddToggle({
    Name = "Zbieraj Orby (Orbs)",
    Default = true,
    CurrentValue = true,
    Flag = "General_CollectOrbs",
    Callback = function(state)
        State.AutoOrbs = state
    end
})

CollectModule:AddToggle({
    Name = "Zbieraj Worki (LootBags)",
    Default = true,
    CurrentValue = true,
    Flag = "General_CollectLootbags",
    Callback = function(state)
        State.AutoLootbags = state
    end
})

-- // ==================== MODUŁ 3: SPEED (SPEEDSCRIPT) ====================
local SpeedModule = TabGeneral:CreateModule({
    Name = "Speed",
    Description = "Zaawansowany, płynny system prędkości gracza z ochroną przed resetowaniem",
    Default = false,
    CurrentValue = false,
    DefaultKeybind = "Z",
    Flag = "General_Speed",
    Callback = function(state)
        State.PlayerSpeedEnabled = state
        _G.SpeedEnabled = state
        if not state then
            pcall(function()
                local char = LocalPlayer.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if hum then hum.WalkSpeed = 16 end
            end)
        else
            pcall(function()
                local char = LocalPlayer.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if hum and State.PlayerSpeedMode == "Normal" then
                    hum.WalkSpeed = State.PlayerSpeedValue or 50
                end
            end)
        end
    end
})

SpeedModule:AddDropdown({
    Name = "Speed Mode",
    Options = {"Legit", "HVH", "Normal", "CFrame"},
    CurrentOption = {"Legit"},
    Default = "Legit",
    Flag = "General_SpeedMode",
    Callback = function(val)
        local selected = (type(val) == "table" and val[1]) or val
        State.PlayerSpeedMode = selected
        _G.SpeedMode = selected
        if selected ~= "Normal" then
            pcall(function()
                local char = LocalPlayer.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if hum then hum.WalkSpeed = 16 end
            end)
        elseif State.PlayerSpeedEnabled then
            pcall(function()
                local char = LocalPlayer.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if hum then hum.WalkSpeed = State.PlayerSpeedValue or 50 end
            end)
        end
    end
})

SpeedModule:AddSlider({
    Name = "Custom Speed",
    Range = { 16, 300 },
    CurrentValue = 50,
    Min = 16,
    Max = 300,
    Default = 50,
    Suffix = " Studs",
    Flag = "General_SpeedVal",
    Callback = function(val)
        State.PlayerSpeedValue = val
        _G.SpeedValue = val
        if State.PlayerSpeedEnabled and State.PlayerSpeedMode == "Normal" then
            pcall(function()
                local char = LocalPlayer.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if hum then hum.WalkSpeed = val end
            end)
        end
    end
})

-- // ==================== MODUŁ 4: PET SPEED (SZYBKOŚĆ PRZEMIESZCZANIA PETÓW) ====================
local PetSpeedModule = TabGeneral:CreateModule({
    Name = "Pet Speed",
    Description = "Zwiększa szybkość przemieszczania i ataku petów (Fast Pets)",
    Default = false,
    CurrentValue = false,
    DefaultKeybind = "X",
    Flag = "General_PetSpeed",
    Callback = function(state)
        State.PetSpeedEnabled = state
        if state then
            pcall(hookPetSpeed)
            pcall(updateWorkspacePetsPhysics)
        end
    end
})

PetSpeedModule:AddSlider({
    Name = "Mnożnik Prędkości (Speed Multiplier)",
    Range = { 1, 100 },
    CurrentValue = 25,
    Min = 1,
    Max = 100,
    Default = 25,
    Suffix = "x",
    Flag = "General_PetSpeedVal",
    Callback = function(val)
        State.PetSpeedValue = val
        if State.PetSpeedEnabled then
            pcall(hookPetSpeed)
            pcall(updateWorkspacePetsPhysics)
        end
    end
})

PetSpeedModule:AddToggle({
    Name = "Natychmiastowy Doskok do Celu (Instant Snap)",
    Default = true,
    CurrentValue = true,
    Flag = "General_PetInstantSnap",
    Callback = function(state)
        State.PetInstantSnap = state
    end
})

PetSpeedModule:AddToggle({
    Name = "Wzmocniona Fizyka Petów (Max Force)",
    Default = true,
    CurrentValue = true,
    Flag = "General_PetMaxForce",
    Callback = function(state)
        State.PetMaxForce = state
        if State.PetSpeedEnabled then
            pcall(updateWorkspacePetsPhysics)
        end
    end
})

-- // ==========================================================================

print("[PetHub] Pomyslnie zaladowano skrypt Pet sim 99 event hallowen!")
