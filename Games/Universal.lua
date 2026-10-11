-- // ==========================================================================
-- // UNIVERSAL SUITE - LIGHTWEIGHT RENDER & ESP MODULE
-- // Dedicated Universal Script for MenuTest UI Library
-- // Category: Render (Player ESP, Chams, Billboards, Tracers)
-- // ==========================================================================

-- 1. Pobranie biblioteki UI
local MENU = loadstring(game:HttpGet("https://raw.githubusercontent.com/xxCichyxx/MenuTest/refs/heads/main/Main.lua"))()

-- 2. Stworzenie okna
local Window = MENU:CreateWindow({
    Name = "Universal",
    Tittle = "Universal Suite",
    TittlePos = "Center",
    ToggleUIKeybind = "Insert",
    TestMobile = false,
    GameId = "Universal"
})

-- 3. Zakładka Render
local TabRender = Window:CreateTab("Render", "eye")

-- // Serwisy
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- // Zmienne ESP
local espEnabled = false
local espBoxWireframe = true
local espHighlights = true
local espNames = true
local espDistance = true
local espColor = Color3.fromRGB(0, 255, 170)
local espAlpha = 1.0

local tracersEnabled = false
local tracerOriginMode = "Dół Ekranu (Bottom)"
local tracerColor = Color3.fromRGB(0, 220, 255)
local tracerAlpha = 1.0

local trackedPlayers = {}

local function CleanupPlayerESP(player)
    local data = trackedPlayers[player]
    if data then
        if data.Highlight and data.Highlight.Parent then data.Highlight:Destroy() end
        if data.Billboard and data.Billboard.Parent then data.Billboard:Destroy() end
        if data.Lines then
            for _, line in ipairs(data.Lines) do
                pcall(function() line:Remove() end)
            end
        end
        if data.TracerLine then
            pcall(function() data.TracerLine:Remove() end)
        end
        trackedPlayers[player] = nil
    end
end

local function CleanupAllESP()
    for player, _ in pairs(trackedPlayers) do
        CleanupPlayerESP(player)
    end
    table.clear(trackedPlayers)
end

local function GetTracerOrigin()
    local vp = Camera.ViewportSize
    if tracerOriginMode:find("Bottom") then
        return Vector2.new(vp.X / 2, vp.Y - 10)
    elseif tracerOriginMode:find("Center") then
        return Vector2.new(vp.X / 2, vp.Y / 2)
    else
        local mousePos = UserInputService:GetMouseLocation()
        return Vector2.new(mousePos.X, mousePos.Y)
    end
end

local function UpdateESP()
    if not espEnabled and not tracersEnabled then
        CleanupAllESP()
        return
    end

    local originPos = GetTracerOrigin()

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local char = player.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")

            if char and hrp and hum and hum.Health > 0 then
                local data = trackedPlayers[player]
                if not data then
                    data = { Lines = {} }
                    trackedPlayers[player] = data
                end

                local screenPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                local dist = math.floor((hrp.Position - Camera.CFrame.Position).Magnitude)

                -- 1. Chams (Highlight)
                if espEnabled and espHighlights and espAlpha > 0.005 then
                    if not data.Highlight or data.Highlight.Parent ~= char then
                        if data.Highlight then data.Highlight:Destroy() end
                        local hl = Instance.new("Highlight")
                        hl.Name = "UniversalESP_Highlight"
                        hl.Adornee = char
                        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                        hl.Parent = char
                        data.Highlight = hl
                    end
                    data.Highlight.FillColor = espColor
                    data.Highlight.FillTransparency = 1 - (espAlpha * 0.5)
                    data.Highlight.OutlineTransparency = 1 - espAlpha
                    data.Highlight.Enabled = true
                elseif data.Highlight then
                    data.Highlight.Enabled = false
                end

                -- 2. BillboardGui (Names & Distance)
                if espEnabled and (espNames or espDistance) and espAlpha > 0.005 then
                    if not data.Billboard or data.Billboard.Parent ~= hrp then
                        if data.Billboard then data.Billboard:Destroy() end
                        local bb = Instance.new("BillboardGui")
                        bb.Name = "UniversalESP_Billboard"
                        bb.Size = UDim2.new(0, 150, 0, 36)
                        bb.StudsOffset = Vector3.new(0, 3.2, 0)
                        bb.AlwaysOnTop = true
                        bb.Adornee = hrp

                        local nameLbl = Instance.new("TextLabel", bb)
                        nameLbl.Name = "Name"
                        nameLbl.Size = UDim2.new(1, 0, 0.5, 0)
                        nameLbl.BackgroundTransparency = 1
                        nameLbl.Font = Enum.Font.GothamBold
                        nameLbl.TextSize = 12

                        local distLbl = Instance.new("TextLabel", bb)
                        distLbl.Name = "Dist"
                        distLbl.Size = UDim2.new(1, 0, 0.5, 0)
                        distLbl.Position = UDim2.new(0, 0, 0.5, 0)
                        distLbl.BackgroundTransparency = 1
                        distLbl.Font = Enum.Font.GothamMedium
                        distLbl.TextSize = 10

                        bb.Parent = hrp
                        data.Billboard = bb
                    end

                    local nameLbl = data.Billboard:FindFirstChild("Name")
                    local distLbl = data.Billboard:FindFirstChild("Dist")
                    if nameLbl then
                        nameLbl.Text = espNames and player.DisplayName or ""
                        nameLbl.TextColor3 = espColor
                        nameLbl.TextTransparency = 1 - espAlpha
                        nameLbl.TextStrokeTransparency = 0.2 + (0.8 * (1 - espAlpha))
                    end
                    if distLbl then
                        distLbl.Text = espDistance and (tostring(dist) .. " studs") or ""
                        distLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
                        distLbl.TextTransparency = 1 - espAlpha
                        distLbl.TextStrokeTransparency = 0.2 + (0.8 * (1 - espAlpha))
                    end
                    data.Billboard.Enabled = true
                elseif data.Billboard then
                    data.Billboard.Enabled = false
                end

                -- 3. Tracers (Drawing API jeśli dostępne)
                if tracersEnabled and onScreen and typeof(Drawing) == "table" and Drawing.new and tracerAlpha > 0.005 then
                    if not data.TracerLine then
                        local l = Drawing.new("Line")
                        l.Thickness = 1.5
                        data.TracerLine = l
                    end
                    data.TracerLine.Visible = true
                    data.TracerLine.From = originPos
                    data.TracerLine.To = Vector2.new(screenPos.X, screenPos.Y)
                    data.TracerLine.Color = tracerColor
                    data.TracerLine.Transparency = tracerAlpha
                elseif data.TracerLine then
                    data.TracerLine.Visible = false
                end
            else
                CleanupPlayerESP(player)
            end
        end
    end
end

RunService.RenderStepped:Connect(function()
    pcall(UpdateESP)
end)

Players.PlayerRemoving:Connect(CleanupPlayerESP)

-- // Budowa UI Modułu Render
local ESPMod = TabRender:CreateModule({
    Name = "Player ESP",
    Icon = "eye",
    Default = false,
    Flag = "Universal_ESP",
    Callback = function(state)
        espEnabled = state
        if not state then
            for _, d in pairs(trackedPlayers) do
                if d.Highlight then d.Highlight.Enabled = false end
                if d.Billboard then d.Billboard.Enabled = false end
            end
        end
    end
})

ESPMod:AddToggle({
    Name = "Chams",
    Default = true,
    Flag = "Universal_ESPChams",
    Callback = function(state)
        espHighlights = state
    end
})

ESPMod:AddToggle({
    Name = "Names",
    Default = true,
    Flag = "Universal_ESPNames",
    Callback = function(state)
        espNames = state
    end
})

ESPMod:AddToggle({
    Name = "Distance",
    Default = true,
    Flag = "Universal_ESPDistance",
    Callback = function(state)
        espDistance = state
    end
})

ESPMod:AddColorPicker({
    Name = "Color",
    Default = Color3.fromRGB(0, 255, 170),
    Flag = "Universal_ESPColor",
    Callback = function(col, alpha)
        espColor = col
        espAlpha = (alpha ~= nil and alpha) or 1.0
    end
})

-- Moduł: Tracers
local TracerMod = TabRender:CreateModule({
    Name = "Tracers",
    Icon = "navigation",
    Default = false,
    Flag = "Universal_Tracers",
    Callback = function(state)
        tracersEnabled = state
        if not state then
            for _, d in pairs(trackedPlayers) do
                if d.TracerLine then d.TracerLine.Visible = false end
            end
        end
    end
})

TracerMod:AddDropdown({
    Name = "Origin",
    Options = {"Dół Ekranu (Bottom)", "Środek (Center)", "Kursor (Mouse)"},
    Default = "Dół Ekranu (Bottom)",
    Flag = "Universal_TracerOrigin",
    Callback = function(selected)
        tracerOriginMode = type(selected) == "table" and selected[1] or selected
    end
})

TracerMod:AddColorPicker({
    Name = "Color",
    Default = Color3.fromRGB(0, 220, 255),
    Flag = "Universal_TracerColor",
    Callback = function(col, alpha)
        tracerColor = col
        tracerAlpha = (alpha ~= nil and alpha) or 1.0
    end
})

print("==================================================")
print("✅ Universal Suite załadowany pomyślnie!")
print("📌 Kategoria: Render (Player ESP & Tracers)")
print("📌 Klawisz menu: INSERT")
print("==================================================")
