-- // ==========================================================================
-- // GAMES REGISTRY - LISTA OBSŁUGIWANYCH GIER
-- // Tutaj możesz dodawać kolejne ID gier i ścieżki do ich dedykowanych skryptów.
-- // ==========================================================================

local baseUrl = "https://raw.githubusercontent.com/xxCichyxx/MenuTest/refs/heads/main/Games/"

local Games = {
    -- ID Gry: [UPD 3.1] Tycoon, but one dropper
    [109949693269081] = {
        Name = "[UPD 3.1] Tycoon, but one dropper",
        Path = "Games/109949693269081/Script.lua",
        Url  = baseUrl .. "109949693269081/Script.lua",
    },

    -- Przykład dodawania nowej gry w przyszłości:
    -- [123456789] = {
    --     Name = "Moja Nowa Gra",
    --     Path = "Games/123456789/Script.lua",
    --     Url  = baseUrl .. "123456789/Script.lua",
    -- },
}

return Games
