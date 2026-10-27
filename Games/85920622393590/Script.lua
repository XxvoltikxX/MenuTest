-- // ==========================================================================
-- // PET SIMULATOR X / 99 EVENT - AUTOMATION SUITE
-- // Dedicated script for MenuTest UI Library (https://github.com/XxvoltikxX/MenuTest)
-- // Features: AutoFarm, Auto Collect (Orbs & LootBags), Speed (SpeedScript)
-- // Game ID: 85920622393590
-- // Tab: General
-- // ==========================================================================

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

-- Bezpieczne pobranie Things i Map
local function getThingsFolder()
    if Framework and Framework.Things then return Framework.Things end
    return Workspace:FindFirstChild("__THINGS")
end

local function getMapFolder()
    return Workspace:FindFirstChild("__MAP")
end

-- // GŁÓWNA TABELA STANU SKRYPTU
local State = {
    -- 1. AutoFarm
    FarmActive = false,
    FarmRange = 600,
    CurrentTargetCoin = nil,

    -- Wybór celu i priorytetu farmowania
    FarmTargetType = "Wszystkie (ALL)",     -- Pojedynczy cel lub "Wszystkie (ALL)"
    FarmPriority = "ALL (Od Najlepszego do Najsłabszego)", -- Tryb sortowania
    FarmAreaOnly = false,                   -- Ograniczenie do strefy (domyślnie wyłączone)

    -- Filtry poszczególnych rodzajów obiektów (używane gdy FarmTargetType to ALL)
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
    PlayerSpeedValue = 16,

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

-- Cache danych monet (Network / Upvalues)
local CoinsCache = {}

-- Bezpieczne pobranie wszystkich folderów z monetami/obiektami (Coins i Breakables w __THINGS oraz Workspace)
local function getCoinsFolders()
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

-- Precyzyjna weryfikacja obecności monety w kołowym promieniu wokół gracza (2D X-Z circle)
local function isCoinInRadius(coin, pPos, radius)
    local cPos = getCoinPosition(coin)
    if not cPos then return false, math.huge end

    local horizDist = (Vector3.new(pPos.X, 0, pPos.Z) - Vector3.new(cPos.X, 0, cPos.Z)).Magnitude
    local vertDist = math.abs(pPos.Y - cPos.Y)

    if horizDist <= radius and vertDist < 300 then
        return true, horizDist
    end
    return false, horizDist
end

local function scanCoinsUpvalues()
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

-- Pobranie informacji o monecie (ID, nazwa, zdrowie, max zdrowie)
local function getCoinInfo(coin)
    local coinId = coin:GetAttribute("ID") or coin.Name
    local coinName = coin:GetAttribute("Name") or coin:GetAttribute("CoinName") or coin:GetAttribute("Type")
    local hp = coin:GetAttribute("Health")
    local maxHp = coin:GetAttribute("MaxHealth")

    if (not coinName or coinName == "") and CoinsCache[coinId] then
        local entry = CoinsCache[coinId]
        coinName = entry.n or entry.name
        hp = hp or entry.h
        maxHp = maxHp or entry.mh
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

    if not coinName or coinName == "" then
        coinName = coin.Name
    end

    return coinId, coinName, hp or 100, maxHp or hp or 100
end

-- Klasyfikacja obiektów do kategorii
local function getCoinCategory(coinName)
    local name = string.lower(coinName or "")
    if name:find("tiny coin") or name:find("tiny_coin") then
        return "Tiny Coins"
    elseif name:find("large coin") or name:find("large_coin") or name:find("giant coin") then
        return "Large Coins"
    elseif name:find("small chest") or name:find("small_chest") then
        return "Small Chest"
    elseif name:find("chest") then
        return "Chest"
    elseif name:find("vault") then
        return "Vault"
    elseif name:find("safe") then
        return "Safe"
    elseif name:find("crate") or name:find("barrel") or name:find("box") then
        return "Crate"
    elseif name:find("present") or name:find("gift") then
        return "Present"
    elseif name:find("diamond") or name:find("gem") then
        return "Diamonds"
    elseif name:find("coin") then
        return "Coins"
    end
    return "Other"
end

-- Mapowanie wyboru z Dropdowna na klucz kategorii
local DropdownToCategory = {
    ["Wszystkie (ALL)"] = "ALL",
    ["Vault (Skarbce)"] = "Vault",
    ["Chest (Wielkie Skrzynie)"] = "Chest",
    ["Small Chest (Małe Skrzynie)"] = "Small Chest",
    ["Safe (Sejfy)"] = "Safe",
    ["Crate (Skrzynki drewniane)"] = "Crate",
    ["Present (Prezenty)"] = "Present",
    ["Diamonds (Diamenty)"] = "Diamonds",
    ["Large Coins (Duże Monety)"] = "Large Coins",
    ["Coins (Zwykłe Monety)"] = "Coins",
    ["Tiny Coins (Małe Monety)"] = "Tiny Coins",
}

-- Weryfikacja czy dany rodzaj obiektu jest dopuszczony do farmowania
local function isCoinAllowed(category)
    local selectedTarget = State.FarmTargetType or "Wszystkie (ALL)"
    local targetCategory = DropdownToCategory[selectedTarget] or selectedTarget

    if targetCategory and targetCategory ~= "ALL" then
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
    local pPos = hrp.Position

    local bestCoin = nil
    local bestScore = -math.huge
    local currentMap = State.DetectedMap or "Spawn"
    local currentLower = string.lower(currentMap)

    local folders = getCoinsFolders()
    for _, folder in ipairs(folders) do
        for _, coin in ipairs(folder:GetChildren()) do
            if isCoinAlive(coin) then
                local inRadius, dist = isCoinInRadius(coin, pPos, State.FarmRange)
                if inRadius then
                    local _, coinName, hp, maxHp = getCoinInfo(coin)
                    local category = getCoinCategory(coinName)

                    if isCoinAllowed(category) then
                        local isAllowedArea = true
                        if State.FarmAreaOnly and currentMap ~= "Spawn" then
                            local coinArea = coin:GetAttribute("Area")
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

-- Pomocnicza funkcja: pobranie UID wszystkich założonych petów gracza
local function getEquippedPets()
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
                if p:GetAttribute("Owner") == LocalPlayer.Name or p.Name:find(LocalPlayer.Name) then
                    table.insert(equippedUids, p.Name)
                end
            end
        end
    end
    return equippedUids
end

-- Asynchroniczne atakowanie monety petami
local function attackCoin(coin)
    if not isCoinAlive(coin) then return end
    State.CurrentTargetCoin = coin

    local coinId = coin:GetAttribute("ID") or coin.Name

    task.spawn(function()
        -- 1. Game Native Signal
        if Framework and Framework.Signal and Framework.Signal.Fire then
            pcall(function()
                Framework.Signal.Fire("Group Select Coin", coin)
            end)
        end

        -- 2. Game Native Network Fire
        if Framework and Framework.Network and Framework.Network.Fire then
            pcall(function()
                Framework.Network.Fire("Select Coin", coin.Name, true)
            end)
        end

        -- 3. Direct Network Invoke (Join Coin + Farm Coin)
        if Framework and Framework.Network and Framework.Network.Invoke then
            pcall(function()
                local equippedUids = getEquippedPets()
                if #equippedUids > 0 then
                    Framework.Network.Invoke("Join Coin", coinId, equippedUids)
                    for _, uid in ipairs(equippedUids) do
                        Framework.Network.Fire("Farm Coin", coinId, uid)
                    end
                end
            end)
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
    if not things then return end
    local orbsFolder = things:FindFirstChild("Orbs")
    if not orbsFolder then return end

    local claimedIds = {}
    local groundCFrame = hrp.CFrame * CFrame.new(0, 10, 0)
    local groundPos = groundCFrame.Position

    for _, orb in ipairs(orbsFolder:GetChildren()) do
        table.insert(claimedIds, orb.Name)

        if orb:IsA("BasePart") then
            orb.CanCollide = false
            pcall(function() orb.CanTouch = true end)
            orb.CFrame = groundCFrame
            pcall(function() orb.AssemblyLinearVelocity = Vector3.zero end)
            orb.Velocity = Vector3.zero

            local bp = orb:FindFirstChildOfClass("BodyPosition")
            if bp then
                bp.Position = groundPos
                bp.MaxForce = Vector3.new(1e7, 1e7, 1e7)
                bp.P = 50000
            end
        elseif orb:IsA("Model") then
            for _, part in ipairs(orb:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                    pcall(function() part.CanTouch = true end)
                    pcall(function() part.AssemblyLinearVelocity = Vector3.zero end)
                    part.Velocity = Vector3.zero
                end
            end
            if orb.PivotTo then
                orb:PivotTo(groundCFrame)
            elseif orb.PrimaryPart then
                orb:SetPrimaryPartCFrame(groundCFrame)
            end
        end
    end

    if #claimedIds > 0 and Framework and Framework.Network then
        pcall(function()
            Framework.Network.Fire("Claim Orbs", claimedIds)
        end)
    end
end

local function collectLootbagsClean()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local things = getThingsFolder()
    if not things then return end
    local lootbagsFolder = things:FindFirstChild("Lootbags")
    if not lootbagsFolder then return end

    local groundCFrame = hrp.CFrame * CFrame.new(0, -2.5, 0)

    for _, bag in ipairs(lootbagsFolder:GetChildren()) do
        if bag:IsA("BasePart") then
            bag.CanCollide = false
            pcall(function() bag.CanTouch = true end)
            bag.CFrame = groundCFrame
            pcall(function() bag.AssemblyLinearVelocity = Vector3.zero end)
            bag.Velocity = Vector3.zero

            if typeof(firetouchinterest) == "function" then
                pcall(function()
                    firetouchinterest(hrp, bag, 0)
                    firetouchinterest(hrp, bag, 1)
                end)
            end
        elseif bag:IsA("Model") then
            local mainPart = bag.PrimaryPart or bag:FindFirstChildWhichIsA("BasePart")
            for _, part in ipairs(bag:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                    pcall(function() part.CanTouch = true end)
                    pcall(function() part.AssemblyLinearVelocity = Vector3.zero end)
                    part.Velocity = Vector3.zero
                end
            end

            if bag.PivotTo then
                bag:PivotTo(groundCFrame)
            elseif bag.PrimaryPart then
                bag:SetPrimaryPartCFrame(groundCFrame)
            end

            if mainPart and typeof(firetouchinterest) == "function" then
                pcall(function()
                    firetouchinterest(hrp, mainPart, 0)
                    firetouchinterest(hrp, mainPart, 1)
                end)
            end
        end
    end
end

-- // ==========================================================================
-- // 4. SYSTEM PRĘDKOŚCI GRACZA
-- // ==========================================================================
local function isPlayerMoving()
    local char = LocalPlayer.Character
    local camera = Workspace.CurrentCamera
    if not char or not char:FindFirstChild("HumanoidRootPart") or not camera then
        return false, Vector3.new()
    end

    local look = camera.CFrame.LookVector
    local moveDir = Vector3.new(look.X, 0, look.Z)
    if moveDir.Magnitude > 0 then
        moveDir = moveDir.Unit
    end

    local movement = Vector3.new()
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then movement = movement + moveDir end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then movement = movement - moveDir end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then movement = movement + Vector3.new(-moveDir.Z, 0, moveDir.X) end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then movement = movement + Vector3.new(moveDir.Z, 0, -moveDir.X) end

    if movement.Magnitude > 0 then
        return true, movement.Unit
    end
    return false, Vector3.new()
end

-- // ==========================================================================
-- // 5. PĘTLE W TLE (BACKGROUND LOOPS)
-- // ==========================================================================

-- Pętla AutoFarm
local retargetCounter = 0
task.spawn(function()
    while ScriptRunning do
        if State.FarmActive then
            local current = State.CurrentTargetCoin

            if not isCoinAlive(current) then
                current = nil
                State.CurrentTargetCoin = nil
            else
                local _, cName = getCoinInfo(current)
                local cat = getCoinCategory(cName)
                if not isCoinAllowed(cat) then
                    current = nil
                    State.CurrentTargetCoin = nil
                else
                    local char = LocalPlayer.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local inRadius = isCoinInRadius(current, hrp.Position, State.FarmRange)
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
                end
            else
                retargetCounter = retargetCounter + 1
                if retargetCounter >= 6 then
                    retargetCounter = 0
                    local betterCoin = findBestCoin()
                    if betterCoin and betterCoin ~= current and isCoinAlive(betterCoin) then
                        local char = LocalPlayer.Character
                        local hrp = char and char:FindFirstChild("HumanoidRootPart")
                        local pPos = hrp and hrp.Position or Vector3.zero

                        local _, curName, curHp, curMaxHp = getCoinInfo(current)
                        local _, bName, bHp, bMaxHp = getCoinInfo(betterCoin)
                        local curPos = getCoinPosition(current) or pPos
                        local bPos = getCoinPosition(betterCoin) or pPos

                        local curScore = evaluateCoinScore(getCoinCategory(curName), curHp, curMaxHp, (pPos - curPos).Magnitude)
                        local bScore = evaluateCoinScore(getCoinCategory(bName), bHp, bMaxHp, (pPos - bPos).Magnitude)

                        if bScore > (curScore + 150000) then
                            attackCoin(betterCoin)
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
local function bindCoinsRespawnListeners()
    for _, folder in ipairs(getCoinsFolders()) do
        if not folder:GetAttribute("AutoFarmListenerBound") then
            folder:SetAttribute("AutoFarmListenerBound", true)
            folder.ChildAdded:Connect(function(child)
                if State.FarmActive and not isCoinAlive(State.CurrentTargetCoin) then
                    task.wait(0.05)
                    local best = findBestCoin()
                    if best and isCoinAlive(best) then
                        attackCoin(best)
                    end
                end
            end)
        end
    end
end
bindCoinsRespawnListeners()

-- Pętla cyklicznego odświeżania bazy danych monet
task.spawn(function()
    while ScriptRunning do
        if State.FarmActive then
            bindCoinsRespawnListeners()
            pcall(function()
                if Framework and Framework.Network and Framework.Network.Invoke then
                    local allCoins = Framework.Network.Invoke("Get Coins")
                    if type(allCoins) == "table" then
                        for id, data in pairs(allCoins) do
                            CoinsCache[tostring(id)] = data
                        end
                    end
                end
            end)
            scanCoinsUpvalues()
        end
        task.wait(4.0)
    end
end)

-- Pętla Auto Collect Orbs
task.spawn(function()
    while ScriptRunning do
        if State.AutoOrbs then
            collectOrbsClean()
            task.wait(0.1)
        else
            task.wait(0.5)
        end
    end
end)

-- Pętla Auto Collect LootBags
task.spawn(function()
    while ScriptRunning do
        if State.AutoLootbags then
            collectLootbagsClean()
            task.wait(0.1)
        else
            task.wait(0.5)
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

-- Pętla fizyki gracza (RenderStepped)
local speedConn
speedConn = RunService.RenderStepped:Connect(function()
    if not ScriptRunning then
        if speedConn then speedConn:Disconnect() end
        return
    end

    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") or not character:FindFirstChild("Humanoid") then return end

    local hrp = character.HumanoidRootPart
    local humanoid = character.Humanoid

    if State.PlayerSpeedEnabled or _G.SpeedEnabled then
        if humanoid:GetState() == Enum.HumanoidStateType.None then
            humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
        humanoid.PlatformStand = false

        local moving, direction = isPlayerMoving()
        local targetSpeed = State.PlayerSpeedValue or _G.SpeedValue or 16

        if moving then
            if State.PlayerSpeedMode == "Normal" then
                humanoid.WalkSpeed = targetSpeed
            elseif State.PlayerSpeedMode == "CFrame" then
                hrp.CFrame = hrp.CFrame + (direction * (targetSpeed / 50))
            elseif State.PlayerSpeedMode == "Legit" or State.PlayerSpeedMode == "HVH" then
                if State.PlayerSpeedMode == "HVH" and UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                    humanoid.Jump = true
                end
                hrp.Velocity = Vector3.new(direction.X * targetSpeed, hrp.Velocity.Y, direction.Z * targetSpeed)
            end
        else
            if State.PlayerSpeedMode == "Legit" or State.PlayerSpeedMode == "HVH" then
                hrp.Velocity = Vector3.new(0, hrp.Velocity.Y, 0)
            end
        end
    else
        if humanoid.PlatformStand then
            humanoid.PlatformStand = false
            humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
    end
end)

-- // ==========================================================================
-- // 6. INTERFEJS UŻYTKOWNIKA MENUTEST (JEDNA GŁÓWNA ZAKŁADKA "GENERAL")
-- // ==========================================================================

local Window = MENU:CreateWindow({
    Name = "PetHub",
    Tittle = "Pet Simulator X Event",
    TittlePos = "Center",
    ToggleUIKeybind = "K",
    TestMobile = false,
    GameId = "85920622393590"
})

-- Sprzątanie pętli po zniszczeniu okna
if Window and Window.ScreenGui then
    Window.ScreenGui.Destroying:Connect(function()
        ScriptRunning = false
        if speedConn then speedConn:Disconnect() end
        State.FarmActive = false
        State.AutoOrbs = false
        State.AutoLootbags = false
        State.PlayerSpeedEnabled = false
    end)
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

FarmModule:AddDropdown({
    Name = "Docelowy Typ Obiektu",
    Options = {
        "Wszystkie (ALL)",
        "Vault (Skarbce)",
        "Chest (Wielkie Skrzynie)",
        "Small Chest (Małe Skrzynie)",
        "Safe (Sejfy)",
        "Crate (Skrzynki drewniane)",
        "Present (Prezenty)",
        "Diamonds (Diamenty)",
        "Large Coins (Duże Monety)",
        "Coins (Zwykłe Monety)",
        "Tiny Coins (Małe Monety)"
    },
    CurrentOption = {"Wszystkie (ALL)"},
    Default = "Wszystkie (ALL)",
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
        "Najmniej HP (Szybkie Czyszczenie)",
        "Tylko Wybrany Typ"
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
    end
})

FarmModule:AddToggle({
    Name = "Farm Chest (Wielkie Skrzynie)",
    Default = true,
    CurrentValue = true,
    Flag = "General_Farm_Chest",
    Callback = function(state)
        State.FarmTypes["Chest"] = state
    end
})

FarmModule:AddToggle({
    Name = "Farm Small Chest (Małe Skrzynie)",
    Default = true,
    CurrentValue = true,
    Flag = "General_Farm_SmallChest",
    Callback = function(state)
        State.FarmTypes["Small Chest"] = state
    end
})

FarmModule:AddToggle({
    Name = "Farm Safe (Sejfy)",
    Default = true,
    CurrentValue = true,
    Flag = "General_Farm_Safe",
    Callback = function(state)
        State.FarmTypes["Safe"] = state
    end
})

FarmModule:AddToggle({
    Name = "Farm Crate (Skrzynki drewniane)",
    Default = true,
    CurrentValue = true,
    Flag = "General_Farm_Crate",
    Callback = function(state)
        State.FarmTypes["Crate"] = state
    end
})

FarmModule:AddToggle({
    Name = "Farm Present (Prezenty)",
    Default = true,
    CurrentValue = true,
    Flag = "General_Farm_Present",
    Callback = function(state)
        State.FarmTypes["Present"] = state
    end
})

FarmModule:AddToggle({
    Name = "Farm Diamonds (Diamenty)",
    Default = true,
    CurrentValue = true,
    Flag = "General_Farm_Diamonds",
    Callback = function(state)
        State.FarmTypes["Diamonds"] = state
    end
})

FarmModule:AddToggle({
    Name = "Farm Large Coins (Duże Monety)",
    Default = true,
    CurrentValue = true,
    Flag = "General_Farm_LargeCoins",
    Callback = function(state)
        State.FarmTypes["Large Coins"] = state
    end
})

FarmModule:AddToggle({
    Name = "Farm Coins (Zwykłe Monety)",
    Default = true,
    CurrentValue = true,
    Flag = "General_Farm_Coins",
    Callback = function(state)
        State.FarmTypes["Coins"] = state
    end
})

FarmModule:AddToggle({
    Name = "Farm Tiny Coins (Małe Monety)",
    Default = true,
    CurrentValue = true,
    Flag = "General_Farm_TinyCoins",
    Callback = function(state)
        State.FarmTypes["Tiny Coins"] = state
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
    Description = "Zaawansowany system prędkości gracza z SpeedScript",
    Default = false,
    CurrentValue = false,
    DefaultKeybind = "Z",
    Flag = "General_Speed",
    Callback = function(state)
        State.PlayerSpeedEnabled = state
        _G.SpeedEnabled = state
        if not state then
            pcall(function()
                LocalPlayer.Character.Humanoid.WalkSpeed = 16
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
    end
})

SpeedModule:AddSlider({
    Name = "Custom Speed",
    Range = { 0, 300 },
    CurrentValue = 16,
    Min = 0,
    Max = 300,
    Default = 16,
    Suffix = " Studs",
    Flag = "General_SpeedVal",
    Callback = function(val)
        State.PlayerSpeedValue = val
        _G.SpeedValue = val
    end
})

-- // ==========================================================================
-- // 7. SYSTEM ZDALNYCH MASZYN I ULEPSZEŃ (REMOTE MACHINES & UPGRADES ENGINE)
-- // WRAZ Z BEZSZWOWYM SYSTEMEM GHOST DISTANCE BYPASS (ELIMINACJA BŁĘDU ODLEGŁOŚCI)
-- // ==========================================================================

local GhostBypassEnabled = true
local GhostAnchorEnabled = false
local IsBypassing = false
local CurrentOpenMachine = nil
local CurrentOpenPad = nil
local AnchorOriginalHrpCF = nil
local AnchorOriginalCamCF = nil
local AnchorOriginalCamType = nil

local MachineRemoteMap = {
    -- Fuse Pets
    ["fuse pets"] = "Fuse Pets",
    ["fuse pet"] = "Fuse Pets",
    ["fuse"] = "Fuse Pets",
    ["fusing"] = "Fuse Pets",
    ["fuse machine"] = "Fuse Pets",
    ["fuse machine: fuse"] = "Fuse Pets",
    ["use fuse pets"] = "Fuse Pets",
    ["use fuse machine"] = "Fuse Pets",

    -- Gold Machine
    ["gold pets"] = "Gold Machine",
    ["gold pet"] = "Gold Machine",
    ["golden pets"] = "Gold Machine",
    ["golden pet"] = "Gold Machine",
    ["use golden machine"] = "Gold Machine",
    ["use gold machine"] = "Gold Machine",
    ["make golden"] = "Gold Machine",
    ["make gold"] = "Gold Machine",
    ["golden"] = "Gold Machine",
    ["gold"] = "Gold Machine",
    ["gold machine"] = "Gold Machine",

    -- Rainbow Machine
    ["rainbow pets"] = "Rainbow Machine",
    ["rainbow pet"] = "Rainbow Machine",
    ["use rainbow machine"] = "Rainbow Machine",
    ["make rainbow"] = "Rainbow Machine",
    ["rainbow"] = "Rainbow Machine",
    ["rainbow machine"] = "Rainbow Machine",

    -- Dark Matter Machine
    ["convert to dark matter"] = "Dark Matter",
    ["dark matter"] = "Dark Matter",
    ["darkmatter"] = "Dark Matter",
    ["claim dark matter"] = "Dark Matter",
    ["dark matter machine"] = "Dark Matter",
    ["use dark matter machine"] = "Dark Matter",

    -- Huge Machine
    ["use huge machine"] = "Huge Machine",
    ["huge machine"] = "Huge Machine",
    ["huge-a-tron"] = "Huge Machine",
    ["huge"] = "Huge Machine",

    -- Upgrade Station
    ["buy upgrade"] = "Upgrade Station",
    ["upgrade"] = "Upgrade Station",
    ["upgrades"] = "Upgrade Station",
    ["upgrade station"] = "Upgrade Station",

    -- Bank
    ["deposit"] = "Bank",
    ["withdraw"] = "Bank",
    ["invite to bank"] = "Bank",
    ["bank"] = "Bank",

    -- Pet Collection / Index
    ["pet collection"] = "Pet Collection Machine",
    ["index"] = "Pet Collection Machine",
    ["claim collection reward"] = "Pet Collection Machine",
    ["pet collection machine"] = "Pet Collection Machine"
}

local function matchMachineByRemote(remoteName)
    if not remoteName then return nil end
    local low = tostring(remoteName):lower()
    if MachineRemoteMap[low] then
        return MachineRemoteMap[low]
    end
    for pattern, mName in pairs(MachineRemoteMap) do
        if low:find(pattern, 1, true) then
            return mName
        end
    end
    -- Fallback po słowach kluczowych
    if low:find("fuse") then
        return "Fuse Pets"
    elseif low:find("gold") then
        return "Gold Machine"
    elseif low:find("rainbow") then
        return "Rainbow Machine"
    elseif low:find("dark") and low:find("matter") then
        return "Dark Matter"
    elseif low:find("huge") then
        return "Huge Machine"
    elseif low:find("upgrade") then
        return "Upgrade Station"
    elseif low:find("bank") then
        return "Bank"
    elseif low:find("collection") or low:find("index") then
        return "Pet Collection Machine"
    end
    return nil
end

local function getMachineForInvocation(self, method, ...)
    local args = { ... }
    local candidates = {}

    if typeof(self) == "Instance" then
        table.insert(candidates, self.Name)
    end
    for i = 1, math.min(#args, 3) do
        if type(args[i]) == "string" then
            table.insert(candidates, args[i])
        end
    end

    for _, cName in ipairs(candidates) do
        local matched = matchMachineByRemote(cName)
        if matched then
            return matched
        end
    end

    if CurrentOpenMachine then
        return CurrentOpenMachine
    end

    return nil
end

local function findInteractiveMachine(name)
    local map = getMapFolder() or Workspace:FindFirstChild("__MAP")
    if not map then return nil end

    -- 1. Bezpośrednio w __MAP.Interactive
    local interactive = map:FindFirstChild("Interactive")
    if interactive then
        local m = interactive:FindFirstChild(name)
        if m then return m end
        for _, child in ipairs(interactive:GetChildren()) do
            if child.Name:lower() == name:lower() or child.Name:lower():find(name:lower(), 1, true) then
                return child
            end
        end
    end

    -- 2. Wewnątrz poszczególnych stref (__MAP.Areas)
    local areas = map:FindFirstChild("Areas")
    if areas then
        for _, area in ipairs(areas:GetChildren()) do
            local aInteractive = area:FindFirstChild("Interactive") or area
            local m = aInteractive:FindFirstChild(name)
            if m then return m end
            for _, child in ipairs(aInteractive:GetChildren()) do
                if child.Name:lower() == name:lower() or child.Name:lower():find(name:lower(), 1, true) then
                    return child
                end
            end
        end
    end

    -- 3. Wyszukiwanie w całym Workspace
    return Workspace:FindFirstChild(name, true)
end

local function getMachinePad(machine)
    if not machine then return nil end
    local direct = {
        machine:FindFirstChild("Pad"),
        machine:FindFirstChild("Center"),
        machine:FindFirstChild("Base"),
        machine:FindFirstChild("IndexPart"),
        machine:FindFirstChild("Platform")
    }
    for _, part in ipairs(direct) do
        if part and part:IsA("BasePart") then return part end
    end
    for _, child in ipairs(machine:GetDescendants()) do
        if child:IsA("BasePart") and (child.Name:lower() == "pad" or child.Name:lower():find("pad") or child.Name:lower() == "center") then
            return child
        end
    end
    if machine:IsA("BasePart") then return machine end
    if machine:IsA("Model") then
        return machine.PrimaryPart or machine:FindFirstChildWhichIsA("BasePart")
    end
    return nil
end

-- // GŁÓWNY SILNIK GHOST BYPASS (BEZSZWOWY MICRO-PULS BEZ RUSZANIA EKRANU GRACZA)
local function executeWithGhostBypass(machineName, callback)
    if not GhostBypassEnabled then
        return callback()
    end
    if IsBypassing then
        return callback()
    end

    local char = LocalPlayer.Character
    local hrp = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso"))
    local machine = findInteractiveMachine(machineName)
    local pad = getMachinePad(machine)

    if not hrp or not pad then
        return callback()
    end

    local dist = (hrp.Position - pad.Position).Magnitude
    -- Jeśli gracz już stoi blisko maszyny (mniej niż 14 studs), wykonaj bezpośrednio
    if dist <= 14 then
        return callback()
    end

    IsBypassing = true

    -- 1. Zamrożenie widoku kamery — gracz nie widzi żadnego szarpnięcia ekranu
    local camera = Workspace.CurrentCamera or Workspace:FindFirstChildOfClass("Camera")
    local oldCamType = camera and camera.CameraType
    local oldCamCF = camera and camera.CFrame
    local oldHrpCF = hrp.CFrame
    local oldVel = hrp.AssemblyLinearVelocity or Vector3.zero

    if camera and oldCamCF then
        camera.CameraType = Enum.CameraType.Scriptable
        camera.CFrame = oldCamCF
    end

    -- 2. Chwilowy przeskok na podest maszyny
    local targetCF = pad.CFrame * CFrame.new(0, 3, 0)
    hrp.CFrame = targetCF
    pcall(function()
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
    end)

    -- 3. Odczekanie 160ms na wysłanie i zatwierdzenie pakietu replikacji fizyki przez serwer
    task.wait(0.16)

    -- Ponowne upewnienie się pozycji przed samym wywołaniem remote
    if hrp then
        hrp.CFrame = targetCF
    end

    -- 4. Wykonanie oryginalnego zapytania do serwera (Fuse, Gold, Rainbow itp.)
    local success, res = pcall(callback)

    -- 5. Odczekanie 80ms na zarejestrowanie transakcji przez silnik gry
    task.wait(0.08)

    -- 6. Błyskawiczny powrót postaci na dokładnie to samo miejsce
    if hrp and oldHrpCF then
        hrp.CFrame = oldHrpCF
        pcall(function()
            hrp.AssemblyLinearVelocity = oldVel
        end)
    end

    -- 7. Przywrócenie trybu kamery
    if camera and oldCamType then
        task.defer(function()
            task.wait(0.04)
            if camera then
                camera.CameraType = oldCamType
                if oldCamCF then camera.CFrame = oldCamCF end
            end
        end)
    end

    IsBypassing = false

    if success then
        return res
    else
        warn("[PetHub GhostBypass] Błąd remote: " .. tostring(res))
        return nil
    end
end

-- Podpięcie do Framework.Network / Library.Network gry
local function hookNetworkFramework()
    local net = (Framework and Framework.Network) or (Library and Library.Network)
    if not net then
        pcall(loadGameLibrary)
        net = (Framework and Framework.Network) or (Library and Library.Network)
    end
    if not net then return end

    if type(net.Invoke) == "function" and not net._GhostHookedInvoke then
        local rawInvoke = net.Invoke
        net._GhostHookedInvoke = true
        net.Invoke = function(name, ...)
            local targetMachine = matchMachineByRemote(name)
            if targetMachine and GhostBypassEnabled then
                local args = { ... }
                return executeWithGhostBypass(targetMachine, function()
                    return rawInvoke(name, unpack(args))
                end)
            end
            return rawInvoke(name, ...)
        end
    end

    if type(net.Fire) == "function" and not net._GhostHookedFire then
        local rawFire = net.Fire
        net._GhostHookedFire = true
        net.Fire = function(name, ...)
            local targetMachine = matchMachineByRemote(name)
            if targetMachine and GhostBypassEnabled then
                local args = { ... }
                return executeWithGhostBypass(targetMachine, function()
                    return rawFire(name, unpack(args))
                end)
            end
            return rawFire(name, ...)
        end
    end
end

pcall(hookNetworkFramework)

-- Zaawansowane hooki metametod (jeśli executor je wspiera)
pcall(function()
    if typeof(hookmetamethod) == "function" and typeof(checkcaller) == "function" and typeof(getnamecallmethod) == "function" then
        local oldNamecall = nil
        oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
            local method = getnamecallmethod()
            if not checkcaller() and (method == "InvokeServer" or method == "FireServer") then
                local targetMachine = getMachineForInvocation(self, method, ...)
                if targetMachine and GhostBypassEnabled then
                    local args = { ... }
                    return executeWithGhostBypass(targetMachine, function()
                        return oldNamecall(self, unpack(args))
                    end)
                end
            end
            return oldNamecall(self, ...)
        end)

        local oldIndex = nil
        oldIndex = hookmetamethod(game, "__index", function(self, key)
            if not checkcaller() and key == "Position" and typeof(self) == "Instance" and self:IsA("BasePart") then
                if CurrentOpenPad and (self == CurrentOpenPad or self.Name:lower():find("pad")) then
                    local char = LocalPlayer.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        return hrp.Position
                    end
                elseif CurrentOpenPad and (self.Name == "HumanoidRootPart" or self.Name == "Torso") then
                    return CurrentOpenPad.Position
                end
            end
            return oldIndex(self, key)
        end)
    end
end)

-- Bezpośredni hook na RemoteFunction/RemoteEvent (fallback dla executorów bez namecall)
pcall(function()
    if typeof(hookfunction) == "function" and typeof(checkcaller) == "function" then
        local testRf = Instance.new("RemoteFunction")
        local rawInvokeServer = testRf.InvokeServer
        testRf:Destroy()

        if rawInvokeServer then
            local oldInvoke = nil
            oldInvoke = hookfunction(rawInvokeServer, function(self, ...)
                if not checkcaller() then
                    local targetMachine = getMachineForInvocation(self, "InvokeServer", ...)
                    if targetMachine and GhostBypassEnabled then
                        local args = { ... }
                        return executeWithGhostBypass(targetMachine, function()
                            return oldInvoke(self, unpack(args))
                        end)
                    end
                end
                return oldInvoke(self, ...)
            end)
        end
    end
end)

-- Automatyczne tłumienie okienka błędu ("You're too far from the machine")
local function setupPopupAutoDismiss()
    local pGui = LocalPlayer:FindFirstChildOfClass("PlayerGui") or LocalPlayer:FindFirstChild("PlayerGui")
    if not pGui then return end

    local function checkAndDismiss(obj)
        if not obj then return end
        if obj:IsA("TextLabel") or obj:IsA("TextButton") then
            local txt = tostring(obj.Text or ""):lower()
            if txt:find("too far") or txt:find("za daleko") then
                local frame = obj:FindFirstChildAncestorWhichIsA("Frame") or obj:FindFirstChildAncestorWhichIsA("ScreenGui")
                if frame then
                    local okBtn = frame:FindFirstChild("Dobrze", true) or frame:FindFirstChild("Ok", true) or frame:FindFirstChild("Yes", true) or frame:FindFirstChild("Close", true)
                    if okBtn and (okBtn:IsA("TextButton") or okBtn:IsA("ImageButton")) then
                        pcall(function()
                            if typeof(firesignal) == "function" and okBtn.MouseButton1Click then
                                firesignal(okBtn.MouseButton1Click)
                            elseif typeof(getconnections) == "function" then
                                for _, c in ipairs(getconnections(okBtn.MouseButton1Click)) do c:Fire() end
                            end
                        end)
                    end
                    pcall(function() frame.Visible = false end)
                end
            end
        end
    end

    pGui.DescendantAdded:Connect(function(descendant)
        task.defer(function()
            pcall(checkAndDismiss, descendant)
        end)
    end)
end

pcall(setupPopupAutoDismiss)

local function openRemoteMachine(machineName, extraKeywords)
    CurrentOpenMachine = machineName
    local machine = findInteractiveMachine(machineName)
    local char = LocalPlayer.Character
    local hrp = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso"))
    local pad = getMachinePad(machine)
    if pad then CurrentOpenPad = pad end

    local opened = false

    -- 1. Ghost Anchor mode (ciągły pobyt na padzie z zamrożoną kamerą gracza)
    if GhostAnchorEnabled and pad and hrp then
        local camera = Workspace.CurrentCamera or Workspace:FindFirstChildOfClass("Camera")
        if camera and not AnchorOriginalCamCF then
            AnchorOriginalCamType = camera.CameraType
            AnchorOriginalCamCF = camera.CFrame
            AnchorOriginalHrpCF = hrp.CFrame
            camera.CameraType = Enum.CameraType.Scriptable
            camera.CFrame = AnchorOriginalCamCF
        end
        hrp.CFrame = pad.CFrame * CFrame.new(0, 3, 0)
        pcall(function()
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
        end)
    end

    -- 2. firetouchinterest na Padzie maszyny
    if pad and hrp and typeof(firetouchinterest) == "function" then
        pcall(function()
            firetouchinterest(hrp, pad, 0)
            task.delay(0.25, function()
                pcall(function() firetouchinterest(hrp, pad, 1) end)
            end)
            opened = true
        end)
    end

    -- 3. Wywołanie Framework Signal & GUI (BIG Games native framework)
    local keywords = extraKeywords or { machineName }
    local fw = Framework or Library
    if fw then
        for _, kw in ipairs(keywords) do
            pcall(function()
                if fw.Signal and fw.Signal.Fire then
                    fw.Signal.Fire("Open " .. kw)
                    fw.Signal.Fire(kw)
                end
            end)
            pcall(function()
                if fw.GUI and fw.GUI.Open then
                    fw.GUI.Open(kw)
                end
            end)
        end
    end

    -- 4. Wymuszenie widoczności Frame w PlayerGui
    local pGui = LocalPlayer:FindFirstChildOfClass("PlayerGui") or LocalPlayer:FindFirstChild("PlayerGui")
    if pGui then
        pcall(function()
            local mainGui = pGui:FindFirstChild("Main") or pGui:FindFirstChild("GUI")
            local searchRoots = { mainGui and (mainGui:FindFirstChild("Frames") or mainGui), pGui }
            for _, root in ipairs(searchRoots) do
                if root then
                    for _, child in ipairs(root:GetChildren()) do
                        local cName = child.Name:lower()
                        for _, kw in ipairs(keywords) do
                            if cName:find(kw:lower(), 1, true) then
                                if child:IsA("GuiObject") then
                                    child.Visible = true
                                    opened = true
                                elseif child:IsA("ScreenGui") then
                                    child.Enabled = true
                                    opened = true
                                end
                            end
                        end
                    end
                end
            end
        end)
    end

    return opened
end

local function closeRemoteMachine(machineName, extraKeywords)
    if CurrentOpenMachine == machineName then
        CurrentOpenMachine = nil
        CurrentOpenPad = nil
    end

    local machine = findInteractiveMachine(machineName)
    local char = LocalPlayer.Character
    local hrp = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso"))
    local pad = getMachinePad(machine)

    -- Przywrócenie pozycji i kamery z Ghost Anchor mode
    if AnchorOriginalHrpCF and hrp then
        hrp.CFrame = AnchorOriginalHrpCF
        AnchorOriginalHrpCF = nil
    end

    local camera = Workspace.CurrentCamera or Workspace:FindFirstChildOfClass("Camera")
    if camera and AnchorOriginalCamCF and AnchorOriginalCamType then
        task.defer(function()
            task.wait(0.04)
            if camera then
                camera.CameraType = AnchorOriginalCamType
                camera.CFrame = AnchorOriginalCamCF
            end
            AnchorOriginalCamCF = nil
            AnchorOriginalCamType = nil
        end)
    end

    if pad and hrp and typeof(firetouchinterest) == "function" then
        pcall(function()
            firetouchinterest(hrp, pad, 1)
        end)
    end

    local keywords = extraKeywords or { machineName }
    local fw = Framework or Library
    if fw and fw.GUI and fw.GUI.Close then
        for _, kw in ipairs(keywords) do
            pcall(function()
                fw.GUI.Close(kw)
            end)
        end
    end

    local pGui = LocalPlayer:FindFirstChildOfClass("PlayerGui") or LocalPlayer:FindFirstChild("PlayerGui")
    if pGui then
        pcall(function()
            local mainGui = pGui:FindFirstChild("Main") or pGui:FindFirstChild("GUI")
            local searchRoots = { mainGui and (mainGui:FindFirstChild("Frames") or mainGui), pGui }
            for _, root in ipairs(searchRoots) do
                if root then
                    for _, child in ipairs(root:GetChildren()) do
                        local cName = child.Name:lower()
                        for _, kw in ipairs(keywords) do
                            if cName:find(kw:lower(), 1, true) then
                                if child:IsA("GuiObject") then
                                    child.Visible = false
                                end
                            end
                        end
                    end
                end
            end
        end)
    end
end

local function teleportToMachine(machineName)
    local machine = findInteractiveMachine(machineName)
    if not machine then
        warn("[PetHub] Nie znaleziono maszyny: " .. tostring(machineName))
        return false
    end

    local pad = getMachinePad(machine)
    local targetCFrame = nil
    if pad and pad:IsA("BasePart") then
        targetCFrame = pad.CFrame * CFrame.new(0, 3, 0)
    elseif machine:IsA("Model") then
        targetCFrame = machine:GetPivot() * CFrame.new(0, 3, 0)
    end

    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp and targetCFrame then
        hrp.CFrame = targetCFrame
        return true
    end
    return false
end

-- // ==========================================================================
-- // 8. DEDYKOWANA ZAKŁADKA "MACHINES" (WSZYSTKIE MASZYNY I ULEPSZENIA W GRZE)
-- // ==========================================================================
local TabMachines = Window:CreateTab("Machines", "wrench")

-- 0. GHOST DISTANCE BYPASS (MASTER TOGGLE)
local BypassModule = TabMachines:CreateModule({
    Name = "Ghost Distance Bypass",
    Description = "Eliminuje błąd 'Za daleko od maszyny' podczas Fuse, Gold i Rainbow bez ruszania kamery",
    Default = true,
    CurrentValue = true,
    Flag = "Machines_GhostDistanceBypass",
    Callback = function(state)
        GhostBypassEnabled = state
    end
})

BypassModule:AddToggle({
    Name = "Ghost Anchor (Ciągły Freeze na Czas Fuzji)",
    Description = "Trzyma postać na maszynie przy otwartym menu i zamraża kamerę na Twoim miejscu",
    Default = false,
    CurrentValue = false,
    Flag = "Machines_GhostAnchorMode",
    Callback = function(state)
        GhostAnchorEnabled = state
    end
})


-- 1. GOLD MACHINE
local GoldModule = TabMachines:CreateModule({
    Name = "Gold Machine",
    Description = "Zdalne tworzenie złotych petów (6x Zwykły -> 1x Gold)",
    Default = false,
    CurrentValue = false,
    DefaultKeybind = "G",
    Flag = "Machines_GoldMachine",
    Callback = function(state)
        if state then
            openRemoteMachine("Gold Machine", {"Golden", "Gold", "Gold Machine"})
        else
            closeRemoteMachine("Gold Machine", {"Golden", "Gold", "Gold Machine"})
        end
    end
})

GoldModule:AddButton({
    Name = "Otwórz Gold Machine",
    Callback = function()
        openRemoteMachine("Gold Machine", {"Golden", "Gold", "Gold Machine"})
    end
})

GoldModule:AddButton({
    Name = "Zamknij Gold Machine",
    Callback = function()
        closeRemoteMachine("Gold Machine", {"Golden", "Gold", "Gold Machine"})
    end
})

GoldModule:AddButton({
    Name = "Teleportuj do Gold Machine",
    Callback = function()
        teleportToMachine("Gold Machine")
    end
})

-- 2. RAINBOW MACHINE
local RainbowModule = TabMachines:CreateModule({
    Name = "Rainbow Machine",
    Description = "Zdalne tworzenie tęczowych petów (6x Gold -> 1x Rainbow)",
    Default = false,
    CurrentValue = false,
    DefaultKeybind = "R",
    Flag = "Machines_RainbowMachine",
    Callback = function(state)
        if state then
            openRemoteMachine("Rainbow Machine", {"Rainbow", "Rainbow Machine"})
        else
            closeRemoteMachine("Rainbow Machine", {"Rainbow", "Rainbow Machine"})
        end
    end
})

RainbowModule:AddButton({
    Name = "Otwórz Rainbow Machine",
    Callback = function()
        openRemoteMachine("Rainbow Machine", {"Rainbow", "Rainbow Machine"})
    end
})

RainbowModule:AddButton({
    Name = "Zamknij Rainbow Machine",
    Callback = function()
        closeRemoteMachine("Rainbow Machine", {"Rainbow", "Rainbow Machine"})
    end
})

RainbowModule:AddButton({
    Name = "Teleportuj do Rainbow Machine",
    Callback = function()
        teleportToMachine("Rainbow Machine")
    end
})

-- 3. PET COLLECTION MACHINE (INDEX)
local IndexModule = TabMachines:CreateModule({
    Name = "Pet Collection (Index)",
    Description = "Katalog wszystkich petów w grze (Index) bez podchodzenia",
    Default = false,
    CurrentValue = false,
    DefaultKeybind = "B",
    Flag = "Machines_PetCollectionIndex",
    Callback = function(state)
        if state then
            openRemoteMachine("Pet Collection Machine", {"Collection", "Index", "Pet Collection"})
        else
            closeRemoteMachine("Pet Collection Machine", {"Collection", "Index", "Pet Collection"})
        end
    end
})

IndexModule:AddButton({
    Name = "Otwórz Menu Indexu",
    Callback = function()
        openRemoteMachine("Pet Collection Machine", {"Collection", "Index", "Pet Collection"})
    end
})

IndexModule:AddButton({
    Name = "Zamknij Menu Indexu",
    Callback = function()
        closeRemoteMachine("Pet Collection Machine", {"Collection", "Index", "Pet Collection"})
    end
})

IndexModule:AddButton({
    Name = "Teleportuj do Maszyny Indexu",
    Callback = function()
        teleportToMachine("Pet Collection Machine")
    end
})

-- 4. FUSE PETS
local FuseModule = TabMachines:CreateModule({
    Name = "Fuse Pets",
    Description = "Zdalne łączenie od 3 do 12 petów w nową, rzadszą postać",
    Default = false,
    CurrentValue = false,
    DefaultKeybind = "F",
    Flag = "Machines_FusePets",
    Callback = function(state)
        if state then
            openRemoteMachine("Fuse Pets", {"Fuse", "Fuse Pets"})
        else
            closeRemoteMachine("Fuse Pets", {"Fuse", "Fuse Pets"})
        end
    end
})

FuseModule:AddButton({
    Name = "Otwórz Fuse Pets",
    Callback = function()
        openRemoteMachine("Fuse Pets", {"Fuse", "Fuse Pets"})
    end
})

FuseModule:AddButton({
    Name = "Zamknij Fuse Pets",
    Callback = function()
        closeRemoteMachine("Fuse Pets", {"Fuse", "Fuse Pets"})
    end
})

FuseModule:AddButton({
    Name = "Teleportuj do Fuse Pets",
    Callback = function()
        teleportToMachine("Fuse Pets")
    end
})

-- 5. DARK MATTER & UPGRADE STATION
local UpgradeModule = TabMachines:CreateModule({
    Name = "Dark Matter & Upgrade Station",
    Description = "Maszyna Dark Matter oraz ulepszenia statystyk gracza (Player Upgrades)",
    Default = false,
    CurrentValue = false,
    Flag = "Machines_DarkMatterUpgrades",
    Callback = function(state)
        if state then
            openRemoteMachine("Upgrade Station", {"Upgrade Station", "Upgrades", "Player Upgrades"})
        else
            closeRemoteMachine("Upgrade Station", {"Upgrade Station", "Upgrades", "Player Upgrades"})
        end
    end
})

UpgradeModule:AddButton({
    Name = "Otwórz Dark Matter Machine",
    Callback = function()
        openRemoteMachine("Dark Matter", {"Dark Matter", "DarkMatter", "Dark Matter Machine"})
    end
})

UpgradeModule:AddButton({
    Name = "Otwórz Upgrade Station",
    Callback = function()
        openRemoteMachine("Upgrade Station", {"Upgrade Station", "Upgrades", "Player Upgrades"})
    end
})

UpgradeModule:AddButton({
    Name = "Teleportuj do Upgrade Station",
    Callback = function()
        teleportToMachine("Upgrade Station")
    end
})

UpgradeModule:AddButton({
    Name = "Teleportuj do Dark Matter",
    Callback = function()
        teleportToMachine("Dark Matter")
    end
})

-- 6. HUGE MACHINE & BANK
local HugeBankModule = TabMachines:CreateModule({
    Name = "Huge Machine, Bank & Nagrody",
    Description = "Zdalny dostęp do Huge Machine, banku oraz darmowych nagród VIP/Rank",
    Default = false,
    CurrentValue = false,
    Flag = "Machines_HugeBankModule",
    Callback = function(state)
        if state then
            openRemoteMachine("Huge Machine", {"Huge Machine", "Huge", "Huge Convert"})
        else
            closeRemoteMachine("Huge Machine", {"Huge Machine", "Huge", "Huge Convert"})
        end
    end
})

HugeBankModule:AddButton({
    Name = "Otwórz Huge Machine",
    Callback = function()
        openRemoteMachine("Huge Machine", {"Huge Machine", "Huge", "Huge Convert"})
    end
})

HugeBankModule:AddButton({
    Name = "Otwórz Bank",
    Callback = function()
        openRemoteMachine("Bank", {"Bank", "My Bank"})
    end
})

HugeBankModule:AddButton({
    Name = "Odbierz Rank & VIP Rewards",
    Callback = function()
        openRemoteMachine("Rank Rewards", {"Rank Rewards", "Rewards", "Rank"})
        task.wait(0.2)
        openRemoteMachine("VIP Rewards", {"VIP Rewards", "VIP"})
    end
})

HugeBankModule:AddButton({
    Name = "Teleportuj do Huge Machine",
    Callback = function()
        teleportToMachine("Huge Machine")
    end
})

HugeBankModule:AddButton({
    Name = "Teleportuj do Banku",
    Callback = function()
        teleportToMachine("Bank")
    end
})

print("[PetHub] Pomyślnie załadowano skrypt Pet Simulator X Event!")
