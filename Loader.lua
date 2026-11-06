-- // ==========================================================================
-- // MENUTEST MASTER LOADER
-- // Automatyczny system detekcji gry i ładowania dedykowanych skryptów
-- // Przepływ: Loader.lua -> Wykrycie ID Gry -> Skrypt Gry lub Universal Suite
-- // ==========================================================================

local baseUrl = "https://raw.githubusercontent.com/XxvoltikxX/MenuTest/refs/heads/main/"

-- Usunięcie istniejącego menu oraz unieważnienie starych pamięci podręcznych (podpisane pod Voltik)
if typeof(getgenv) == "function" then
    if getgenv()._VoltikMenuCleanup then pcall(getgenv()._VoltikMenuCleanup); getgenv()._VoltikMenuCleanup = nil end
    if getgenv()._VoltikTycoonScriptCleanup then pcall(getgenv()._VoltikTycoonScriptCleanup); getgenv()._VoltikTycoonScriptCleanup = nil end
    if getgenv()._PS99GardenCleanup then pcall(getgenv()._PS99GardenCleanup); getgenv()._PS99GardenCleanup = nil end
    if getgenv()._VoltikPS99Cleanup then pcall(getgenv()._VoltikPS99Cleanup); getgenv()._VoltikPS99Cleanup = nil end
    if getgenv()._PS99HalloweenCleanup then pcall(getgenv()._PS99HalloweenCleanup); getgenv()._PS99HalloweenCleanup = nil end
    if getgenv()._VoltikMenuTestGui then pcall(function() getgenv()._VoltikMenuTestGui:Destroy() end); getgenv()._VoltikMenuTestGui = nil end
    getgenv()._VoltikMenuModuleCache = nil
    getgenv()._VoltikMenuCache = nil
    getgenv()._VoltikToggleElement = nil
    getgenv()._VoltikIconsModule = nil
    getgenv()._VoltikIconsData = nil
    getgenv()._VoltikLibrary = nil
end
if _G.PS99GardenCleanup then pcall(_G.PS99GardenCleanup); _G.PS99GardenCleanup = nil end
if _G.PS99HalloweenCleanup then pcall(_G.PS99HalloweenCleanup); _G.PS99HalloweenCleanup = nil end
if _G._VoltikPS99Cleanup then pcall(_G._VoltikPS99Cleanup); _G._VoltikPS99Cleanup = nil end
_G._VoltikMenuModuleCache = nil
_G._VoltikMenuCache = nil
_G._VoltikToggleElement = nil
_G._VoltikIconsModule = nil
_G._VoltikIconsData = nil
_G._VoltikLibrary = nil

-- Twarde czyszczenie wszelkich poprzednich GUI w CoreGui i PlayerGui (eliminuje nakładanie się zakładek)
pcall(function()
    local CoreGui = game:GetService("CoreGui")
    local Players = game:GetService("Players")
    local lp = Players.LocalPlayer
    local pg = lp and lp:FindFirstChild("PlayerGui")
    local locations = { CoreGui, pg }
    for _, loc in ipairs(locations) do
        if loc then
            for _, child in ipairs(loc:GetChildren()) do
                if child:IsA("ScreenGui") then
                    if child.Name:find("VoltikMenu") or child.Name:find("PetHub") or child.Name:find("Universal")
                       or child:GetAttribute("VoltikMenuInstance") or child:GetAttribute("MenuTest_Voltik")
                       or child:GetAttribute("MenuOwner") == "XxvoltikxX" then
                        pcall(function() child:Destroy() end)
                    end
                end
            end
        end
    end
end)

-- Funkcja bezpiecznego pobierania/ładowania kodu
local function safeExecute(relativePath, remoteUrl)
    -- 1. Próba załadowania z lokalnego dysku (tylko w jawnym trybie developerskim)
    local isDev = (typeof(getgenv) == "function" and getgenv()._MenuTestDevMode == true)
    if isDev and typeof(readfile) == "function" then
        local candidates = {
            "MenuTest/" .. relativePath,
            relativePath
        }
        for _, path in ipairs(candidates) do
            if typeof(isfile) == "function" and isfile(path) then
                local ok, data = pcall(readfile, path)
                if ok and data and #data > 0 then
                    local chunk, err = loadstring(data)
                    if chunk then
                        local runOk, runErr = pcall(chunk)
                        if runOk then
                            return true, runOk
                        else
                            warn("[Loader] Błąd wykonania lokalnego pliku " .. path .. ": " .. tostring(runErr))
                        end
                    else
                        warn("[Loader] Błąd kompilacji lokalnego pliku " .. path .. ": " .. tostring(err))
                    end
                end
            end
        end
    end

    -- 2. Pobieranie z GitHub / jsDelivr HttpGet z ominięciem cache CDN
    local urlList = {
        "https://cdn.jsdelivr.net/gh/XxvoltikxX/MenuTest@main/" .. relativePath,
        remoteUrl,
        remoteUrl:gsub("/refs/heads/main/", "/main/"),
        "https://raw.githubusercontent.com/XxvoltikxX/MenuTest/main/" .. relativePath
    }

    for _, targetUrl in ipairs(urlList) do
        local cacheBuster = (targetUrl:find("%?") and "&" or "?") .. "_nocache=" .. tostring(tick()) .. "_" .. tostring(os.time()) .. "_" .. tostring(math.random(100000, 999999))
        local ok, res = pcall(function()
            return game:HttpGet(targetUrl .. cacheBuster)
        end)
        if ok and res and #res > 0 and not res:find("404: Not Found") and not res:find("400: Invalid Request") then
            res = res:gsub("^\239\187\191", "")
            local chunk, err = loadstring(res)
            if chunk then
                local runOk, runErr = pcall(chunk)
                if runOk then
                    return true, runOk
                else
                    warn("[Loader] Błąd wykonania skryptu z URL: " .. tostring(runErr))
                end
            else
                warn("[Loader] Błąd kompilacji skryptu z URL: " .. tostring(err))
            end
        end
    end

    warn("[Loader] Nie udało się pobrać/uruchomić skryptu: " .. tostring(relativePath))
    return false, nil
end

-- // ==========================================================================
-- // LISTA OBSŁUGIWANYCH GIER
-- // Aby dodać grę, wpisz: [ID_GRY] = "Nazwa Gry"
-- // Loader automatycznie załaduje: Games/<ID_GRY>/Script.lua
-- // ==========================================================================
local Games = {
    [109949693269081] = { name = "[UPD 3.1] Tycoon, but one dropper", folder = "109949693269081" },
    ["109949693269081"] = { name = "[UPD 3.1] Tycoon, but one dropper", folder = "109949693269081" },
    [85920622393590] = { name = "Pet Simulator X Event", folder = "85920622393590" },
    ["85920622393590"] = { name = "Pet Simulator X Event", folder = "85920622393590" },
    [8737899170] = { name = "Pet Simulator 99 (Garden Event)", folder = "8737899170" },
    ["8737899170"] = { name = "Pet Simulator 99 (Garden Event)", folder = "8737899170" },
    [16498369169] = { name = "Pet sim 99 event hallowen", folder = "16498369169" },
    ["16498369169"] = { name = "Pet sim 99 event hallowen", folder = "16498369169" },
}

-- // ==========================================================================
-- // DETEKCJA GRY I URUCHOMIENIE SKRYPTU
-- // ==========================================================================
local placeId = game.PlaceId
local gameId  = game.GameId

local function findGameMatch(id)
    if not id then return nil, nil, nil end
    local strId = tostring(id):gsub("%s+", "")
    local numId = tonumber(strId)

    if numId and Games[numId] then
        local entry = Games[numId]
        return entry.folder or tostring(numId), entry.name or "Game", numId
    end
    if Games[strId] then
        local entry = Games[strId]
        return entry.folder or strId, entry.name or "Game", strId
    end

    for k, v in pairs(Games) do
        local kStr = tostring(k):gsub("%s+", "")
        if kStr == strId or (numId and tonumber(kStr) == numId) then
            if type(v) == "table" then
                return v.folder or kStr, v.name or "Game", k
            else
                return tostring(v), tostring(v), k
            end
        end
    end

    return nil, nil, nil
end

-- Możliwość ręcznego wymuszenia Universal Suite w dowolnej grze
local forceUniversal = (typeof(getgenv) == "function" and getgenv()._ForceUniversal == true) or (_G._ForceUniversal == true)
if forceUniversal then
    print("[Loader] Wymuszono uruchomienie Universal Suite...")
    safeExecute("Games/Universal.lua", baseUrl .. "Games/Universal.lua")
    return
end

-- Ścisła detekcja wyłącznie po konkretnym PlaceId (eliminuje konflikt pod-miejsc i Universe ID)
local targetFolder, targetName, rawId = findGameMatch(placeId)

print("[Loader] Inicjalizacja (v2.1-Halloween)... PlaceId: " .. tostring(placeId) .. " | GameId: " .. tostring(gameId))

if targetFolder then
    print("[Loader] Wykryto dedykowany skrypt: " .. tostring(targetName) .. " (Folder: " .. tostring(targetFolder) .. ")")
    local relPath = "Games/" .. tostring(targetFolder) .. "/Script.lua"
    local fullUrl = baseUrl .. relPath
    local success = safeExecute(relPath, fullUrl)

    if not success then
        warn("[Loader] Blad ladowania dedykowanego skryptu " .. tostring(relPath) .. ", uruchamiam Universal...")
        safeExecute("Games/Universal.lua", baseUrl .. "Games/Universal.lua")
    end
else
    local registeredList = {}
    for k, _ in pairs(Games) do
        if type(k) == "string" then table.insert(registeredList, k) end
    end
    print("[Loader] Brak dedykowanego skryptu dla PlaceId: " .. tostring(placeId) .. " (Lista gier: " .. table.concat(registeredList, ", ") .. "). Uruchamiam Universal Suite...")
    local success = safeExecute("Games/Universal.lua", baseUrl .. "Games/Universal.lua")
    if not success then
        warn("[Loader] KRYTYCZNY BLAD: Nie udalo sie uruchomic Universal Suite!")
    end
end

