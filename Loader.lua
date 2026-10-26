-- // ==========================================================================
-- // MENUTEST MASTER LOADER
-- // Automatyczny system detekcji gry i ładowania dedykowanych skryptów
-- // Przepływ: Loader.lua -> Wykrycie ID Gry -> Skrypt Gry lub Universal Suite
-- // ==========================================================================

local baseUrl = "https://raw.githubusercontent.com/XxvoltikxX/MenuTest/refs/heads/main/"

-- Usunięcie istniejącego menu oraz unieważnienie starych pamięci podręcznych
if typeof(getgenv) == "function" then
    if getgenv()._MenuTestCleanup then pcall(getgenv()._MenuTestCleanup) end
    if getgenv()._TycoonScriptCleanup then pcall(getgenv()._TycoonScriptCleanup) end
    getgenv()._MenuTestModuleCache = nil
    getgenv()._MenuTestCache = nil
    getgenv()._MenuTestToggleElement = nil
    getgenv()._MenuTestIconsModule = nil
    getgenv()._MenuTestIconsData = nil
    getgenv()._MenuTestLibrary = nil
end
_G._MenuTestModuleCache = nil
_G._MenuTestCache = nil
_G._MenuTestToggleElement = nil
_G._MenuTestIconsModule = nil
_G._MenuTestIconsData = nil
_G._MenuTestLibrary = nil

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
                        return true, chunk()
                    else
                        warn("[Loader] Błąd kompilacji lokalnego pliku " .. path .. ": " .. tostring(err))
                    end
                end
            end
        end
    end

    -- 2. Pobieranie z GitHub HttpGet z ominięciem cache CDN
    local cacheBuster = (remoteUrl:find("%?") and "&" or "?") .. "_nocache=" .. tostring(tick()) .. "_" .. tostring(os.time()) .. "_" .. tostring(math.random(100000, 999999))
    local ok, res = pcall(function()
        return game:HttpGet(remoteUrl .. cacheBuster)
    end)
    if ok and res and #res > 0 then
        res = res:gsub("^\239\187\191", "")
        local chunk, err = loadstring(res)
        if chunk then
            return true, chunk()
        else
            warn("[Loader] Błąd kompilacji skryptu z URL: " .. tostring(err))
        end
    else
        warn("[Loader] Nie udało się pobrać skryptu z URL: " .. tostring(remoteUrl))
    end

    return false, nil
end

-- // ==========================================================================
-- // LISTA OBSŁUGIWANYCH GIER
-- // Aby dodać grę, wpisz: [ID_GRY] = "Nazwa Gry"
-- // Loader automatycznie załaduje: Games/<ID_GRY>/Script.lua
-- // ==========================================================================
local Games = {
    [109949693269081] = "[UPD 3.1] Tycoon, but one dropper",
    ["109949693269081"] = "[UPD 3.1] Tycoon, but one dropper",
}

-- // ==========================================================================
-- // DETEKCJA GRY I URUCHOMIENIE SKRYPTU
-- // ==========================================================================
local placeId = game.PlaceId
local gameId  = game.GameId

local function findGameMatch(id)
    if not id then return nil, nil end
    local numId = tonumber(id)
    local strId = tostring(id)
    if numId and Games[numId] then return numId, Games[numId] end
    if strId and Games[strId] then return numId or strId, Games[strId] end
    return nil, nil
end

-- Możliwość ręcznego wymuszenia Universal Suite w dowolnej grze
local forceUniversal = (typeof(getgenv) == "function" and getgenv()._ForceUniversal == true) or (_G._ForceUniversal == true)
if forceUniversal then
    print("[Loader] Wymuszono uruchomienie Universal Suite...")
    safeExecute("Games/Universal.lua", baseUrl .. "Games/Universal.lua")
    return
end

local matchedId, matchedName = findGameMatch(placeId)
if not matchedId then
    matchedId, matchedName = findGameMatch(gameId)
end

print("Loading...")

if matchedId then
    print("[Loader] Wykryto gre: " .. tostring(matchedName) .. " (" .. tostring(matchedId) .. ")")
    local relPath = "Games/" .. tostring(matchedId) .. "/Script.lua"
    local fullUrl = baseUrl .. relPath
    local success, _ = safeExecute(relPath, fullUrl)

    if not success then
        print("[Loader] Ladowanie awaryjne Universal Suite...")
        safeExecute("Games/Universal.lua", baseUrl .. "Games/Universal.lua")
    end
else
    print("[Loader] Brak dedykowanego skryptu, uruchamiam Universal Suite...")
    local success, _ = safeExecute("Games/Universal.lua", baseUrl .. "Games/Universal.lua")
    if not success then
        warn("[Loader] KRYTYCZNY BLAD: Nie udalo sie uruchomic Universal Suite!")
    end
end

