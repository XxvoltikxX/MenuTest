-- // ==========================================================================
-- // MENUTEST MASTER LOADER
-- // Zawsze uruchamia LuminaqHUB — panel manualnego wyboru gry.
-- // Bez detekcji PlaceId: użytkownik sam wybiera grę z listy.
-- // Przepływ: Loader.lua -> Games/Universal.lua -> Panel wyboru gry
-- // ==========================================================================

local baseUrl = "https://raw.githubusercontent.com/XxvoltikxX/MenuTest/refs/heads/main/"

-- Cisza w produkcji: komunikaty nie zostawiają sygnatur w LogService.
local DEV = (typeof(getgenv) == "function" and getgenv()._MenuTestDevMode == true)
local function warn(...)
    if DEV then print(...) end
end

-- Wspólny magazyn sesji (ten sam klucz co w src/Stealth.lua).
local STORE_KEY = "_0x5a17"
local function getStore()
    if type(getgenv) ~= "function" then return nil end
    local env = getgenv()
    local store = env[STORE_KEY]
    if type(store) ~= "table" then
        store = {}
        env[STORE_KEY] = store
    end
    return store
end

-- Czyszczenie poprzedniej sesji bez skanowania nazw GUI.
local store = getStore()
if store then
    if type(store.windowCleanup) == "function" then pcall(store.windowCleanup) end
    if type(store.explorerCleanup) == "function" then pcall(store.explorerCleanup) end
    for _, key in ipairs({ "windowGui", "explorerGui", "loaderGui" }) do
        local gui = store[key]
        if gui then pcall(function() gui:Destroy() end) end
        store[key] = nil
    end
    store.windowCleanup, store.explorerCleanup = nil, nil
end

-- Migracja starych kluczy z poprzednich wersji (już ich nie używamy).
if typeof(getgenv) == "function" then
    local env = getgenv()
    for _, key in ipairs({ "_VoltikMenuCleanup", "_LuminaqExplorerCleanup" }) do
        local fn = env[key]
        if type(fn) == "function" then pcall(fn) end
        env[key] = nil
    end
    local oldGui = env._VoltikMenuTestGui
    if oldGui then pcall(function() oldGui:Destroy() end) end
    env._VoltikMenuTestGui = nil
    env._VoltikMenuModuleCache = nil
    env._VoltikMenuCache = nil
    env._VoltikToggleElement = nil
    env._VoltikIconsModule = nil
    env._VoltikIconsData = nil
    env._VoltikLibrary = nil
end
_G._VoltikMenuCleanup = nil
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

    -- 2. Pobieranie z GitHub HttpGet z ominięciem cache CDN (zawsze świeży raw GitHub)
    local urlList = {
        remoteUrl,
        "https://raw.githubusercontent.com/XxvoltikxX/MenuTest/main/" .. relativePath,
        remoteUrl:gsub("/refs/heads/main/", "/main/"),
        "https://cdn.jsdelivr.net/gh/XxvoltikxX/MenuTest@main/" .. relativePath
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
-- // START — PANEL WYBORU GRY
-- // ==========================================================================
if DEV then print("[Loader] Inicjalizacja...") end

local success = safeExecute("Games/Universal.lua", baseUrl .. "Games/Universal.lua")
if not success then
    warn("[Loader] KRYTYCZNY BŁĄD: Nie udało się uruchomić LuminaqHUB!")
end
