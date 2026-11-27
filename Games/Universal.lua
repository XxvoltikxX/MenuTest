-- // ==========================================================================
-- // LUMINAQHUB — REJESTR GIER
-- // Panel wyboru gry: "Welcome to LuminaqHub" + wyszukiwarka + karty gier.
-- // Bez detekcji gry — grę wybierasz manualnie z listy.
-- //
-- // JAK DODAĆ GRĘ (po jednej, powoli):
-- //   1. Utwórz plik: Games/<ID>/Script.lua
-- //   2. Dodaj wpis do tabeli Games poniżej.
-- // Skrypt zostanie pobrany automatycznie z:
-- //   Games/<ID>/Script.lua
-- // ==========================================================================

-- 1. Załadowanie głównej biblioteki UI
local mainRaw = game:HttpGet("https://raw.githubusercontent.com/XxvoltikxX/MenuTest/refs/heads/main/Main.lua?_cb=" .. tostring(tick()) .. "_" .. tostring(os.time()) .. "_" .. tostring(math.random(100000, 999999)))
local MENU = loadstring(mainRaw:gsub("^\239\187\191", ""))()

-- 2. Serwisy
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- // ==========================================================================
-- // REJESTR GIER
-- // Schemat wpisu:
-- // {
-- //     Id          = "1234567890",       -- folder w Games/ (wymagany)
-- //     Name        = "Nazwa gry",        -- widoczne w panelu
-- //     Description = "Krótki opis",      -- opcjonalne
-- //     Icon        = "gamepad-2",        -- ikona Lucide (opcjonalne)
-- //     Tags        = { "pvp", "fps" },   -- opcjonalne
-- //     Author      = "XxvoltikxX",       -- opcjonalne
-- // }
-- // ==========================================================================
local Games = {
    -- Przyklad:
    -- {
    --     Id = "1234567890",
    --     Name = "Moja Gra",
    --     Description = "Skrypt do mojej gry",
    --     Icon = "gamepad-2",
    --     Tags = { "pvp" },
    --     Author = "XxvoltikxX",
    -- },
}

-- // ==========================================================================
-- // CICHE OCHRONY (zawsze aktywne, bez opcji w UI)
-- // ==========================================================================
local antiAfkConn = LocalPlayer.Idled:Connect(function()
    pcall(function()
        local vim = Instance.new("VirtualInputManager")
        vim:SendMouseButtonEvent(0, 0, 0, true, game, 0)
        vim:SendMouseButtonEvent(0, 0, 0, false, game, 0)
        vim:Destroy()
    end)
    pcall(function()
        local vu = game:GetService("VirtualUser")
        vu:CaptureController()
        vu:ClickButton2(Vector2.new())
    end)
end)

local antiFlingConn = RunService.Stepped:Connect(function()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    pcall(function()
        if hrp.AssemblyLinearVelocity and hrp.AssemblyLinearVelocity.Magnitude > 3500 then
            hrp.AssemblyLinearVelocity = Vector3.zero
        end
        if hrp.AssemblyAngularVelocity and hrp.AssemblyAngularVelocity.Magnitude > 2500 then
            hrp.AssemblyAngularVelocity = Vector3.zero
        end
    end)
end)

local function cleanup()
    pcall(function() antiAfkConn:Disconnect() end)
    pcall(function() antiFlingConn:Disconnect() end)
end

-- // ==========================================================================
-- // START PANELU WYBORU GRY
-- // ==========================================================================
MENU:CreateExplorer({
    Name            = "LuminaqHub",
    Games           = Games,
    BaseUrl         = "https://raw.githubusercontent.com/XxvoltikxX/MenuTest/refs/heads/main/Games/",
    ToggleUIKeybind = "K",
    OnCleanup       = cleanup,
})
