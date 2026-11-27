-- // ==========================================================================
-- // MENUTEST MASTER LOADER
-- // Zawsze uruchamia LuminaqHUB — panel manualnego wyboru gry.
-- // Bez detekcji PlaceId: użytkownik sam wybiera grę z listy.
-- // Przepływ: Loader.lua -> Games/Universal.lua -> Panel wyboru gry
-- // ==========================================================================

local baseUrl = "https://raw.githubusercontent.com/XxvoltikxX/MenuTest/refs/heads/main/"

-- Usunięcie istniejącego menu oraz unieważnienie starych pamięci podręcznych (podpisane pod Voltik)
if typeof(getgenv) == "function" then
    if getgenv()._VoltikMenuCleanup then pcall(getgenv()._VoltikMenuCleanup); getgenv()._VoltikMenuCleanup = nil end
    if getgenv()._VoltikMenuTestGui then pcall(function() getgenv()._VoltikMenuTestGui:Destroy() end); getgenv()._VoltikMenuTestGui = nil end
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
                    if child.Name:find("VoltikMenu") or child.Name:find("PetHub") or child.Name:find("Universal") or child.Name:find("Luminaq")
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
print("[Loader] Inicjalizacja... Uruchamiam LuminaqHUB (panel wyboru gry)...")

local success = safeExecute("Games/Universal.lua", baseUrl .. "Games/Universal.lua")
if not success then
    warn("[Loader] KRYTYCZNY BŁĄD: Nie udało się uruchomić LuminaqHUB!")
end
