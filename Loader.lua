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
    getgenv()._VoltikMenuModuleCache = nil
    getgenv()._VoltikMenuCache = nil
    getgenv()._VoltikToggleElement = nil
    getgenv()._VoltikIconsModule = nil
    getgenv()._VoltikIconsData = nil
    getgenv()._VoltikLibrary = nil
end
_G._VoltikMenuModuleCache = nil
_G._VoltikMenuCache = nil
_G._VoltikToggleElement = nil
_G._VoltikIconsModule = nil
_G._VoltikIconsData = nil
_G._VoltikLibrary = nil

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

    -- 2. Pobieranie z GitHub HttpGet z ominięciem cache CDN (próba obu gałęzi raw)
    local urlList = {
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
    [3317771874] = { name = "Pet Simulator 99 (Garden Event)", folder = "8737899170" },
    ["3317771874"] = { name = "Pet Simulator 99 (Garden Event)", folder = "8737899170" },
}

-- // ==========================================================================
-- // DETEKCJA GRY I URUCHOMIENIE SKRYPTU
-- // ==========================================================================
local placeId = game.PlaceId
local gameId  = game.GameId

local function findGameMatch(id)
    if not id then return nil, nil, nil end
    local numId = tonumber(id)
    local strId = tostring(id)
    local entry = (numId and Games[numId]) or (strId and Games[strId])
    if entry then
        if type(entry) == "table" then
            return entry.folder or tostring(id), entry.name or "Game", numId or strId
        else
            return tostring(entry), tostring(entry), numId or strId
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

local targetFolder, targetName, rawId = findGameMatch(placeId)
if not targetFolder then
    targetFolder, targetName, rawId = findGameMatch(gameId)
end

print("[Loader] Inicjalizacja... PlaceId: " .. tostring(placeId) .. " | GameId: " .. tostring(gameId))

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
    print("[Loader] Brak dedykowanego skryptu dla ID: " .. tostring(placeId) .. ", uruchamiam Universal Suite...")
    local success = safeExecute("Games/Universal.lua", baseUrl .. "Games/Universal.lua")
    if not success then
        warn("[Loader] KRYTYCZNY BLAD: Nie udalo sie uruchomic Universal Suite!")
    end
end

