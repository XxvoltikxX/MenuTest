-- // ==========================================================================
-- // MENUTEST MASTER LOADER
-- // Automatyczny system detekcji gry i ładowania dedykowanych skryptów
-- // Przepływ: Loader.lua -> Wykrycie ID Gry -> Skrypt Gry lub Universal Suite
-- // ==========================================================================

local baseUrl = "https://raw.githubusercontent.com/xxCichyxx/MenuTest/refs/heads/main/"

-- Funkcja bezpiecznego pobierania/ładowania kodu
local function safeExecute(relativePath, remoteUrl)
    -- 1. Próba załadowania z lokalnego dysku (jeśli executor wspiera readfile)
    if typeof(readfile) == "function" then
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

    -- 2. Pobieranie z GitHub HttpGet
    local ok, res = pcall(function()
        return game:HttpGet(remoteUrl)
    end)
    if ok and res and #res > 0 then
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
-- // REJESTR OBSŁUGIWANYCH GIER
-- // Tutaj możesz bezpośrednio dodawać kolejne ID gier!
-- // ==========================================================================
local Games = {
    -- [UPD 3.1] Tycoon, but one dropper
    [109949693269081] = {
        Name = "[UPD 3.1] Tycoon, but one dropper",
        Path = "Games/109949693269081/Script.lua",
        Url  = baseUrl .. "Games/109949693269081/Script.lua"
    },

    -- Kolejne gry dodawaj według wzoru:
    -- [ID_GRY] = {
    --     Name = "Nazwa Gry",
    --     Path = "Games/ID_GRY/Script.lua",
    --     Url  = baseUrl .. "Games/ID_GRY/Script.lua"
    -- },
}

-- Próba załadowania zewnętrznego pliku Games/Games.lua (jeśli istnieje)
pcall(function()
    local ok, externalGames = safeExecute("Games/Games.lua", baseUrl .. "Games/Games.lua")
    if ok and type(externalGames) == "table" then
        for id, info in pairs(externalGames) do
            Games[id] = info
        end
    end
end)

-- // ==========================================================================
-- // DETEKCJA GRY I URUCHOMIENIE SKRYPTU
-- // ==========================================================================
local placeId = game.PlaceId
local gameId  = game.GameId

-- Sprawdzenie czy ID jest obsługiwane (zarówno jako liczba jak i string)
local matchedEntry = Games[placeId] or Games[gameId] or Games[tonumber(placeId)] or Games[tostring(placeId)]

print("==================================================")
print("🚀 [MenuTest Loader] Inicjalizacja...")
print(string.format("📌 Aktualny PlaceId: %s | GameId: %s", tostring(placeId), tostring(gameId)))

if matchedEntry then
    print(string.format("✅ Wykryto dedykowany skrypt dla gry: %s", matchedEntry.Name))
    print("⏳ Ładowanie modułów gry...")
    print("==================================================")

    local success, _ = safeExecute(matchedEntry.Path, matchedEntry.Url)
    if not success then
        warn("[Loader] Nie udało się załadować dedykowanego skryptu! Przełączanie na Universal...")
        safeExecute("Games/Universal.lua", baseUrl .. "Games/Universal.lua")
    end
else
    print("ℹ️ Brak dedykowanego skryptu pod to ID gry.")
    print("🌐 Uruchamianie Universal Suite (Render & ESP)...")
    print("==================================================")

    local success, _ = safeExecute("Games/Universal.lua", baseUrl .. "Games/Universal.lua")
    if not success then
        warn("[Loader] KRYTYCZNY BŁĄD: Nie udało się uruchomić Universal Suite!")
    end
end
