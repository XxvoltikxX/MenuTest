-- // ==========================================================================
-- // MENUTEST UNIVERSAL SUITE
-- // Zaawansowany, uniwersalny pakiet narzędzi działający w KAŻDEJ grze Roblox.
-- // Zakładki: Player (Speed, Fly, InfJump, Noclip, ClickTP), Render (ESP, Tracers, World), Misc
-- // W pełni zintegrowany z systemem nowoczesnych kategorii, sliderów i motywów.
-- // ==========================================================================

-- 1. Załadowanie głównej biblioteki UI
local MENU = loadstring(game:HttpGet("https://raw.githubusercontent.com/XxvoltikxX/MenuTest/refs/heads/main/Main.lua"))()

-- 2. Stworzenie okna głównego
local Window = MENU:CreateWindow({
    Name = "Universal",
    Tittle = "Universal Suite",
    TittlePos = "Center",
    ToggleUIKeybind = "K",
    TestMobile = false,
    GameId = "Universal"
})

-- 3. Inicjalizacja zakładek
local TabPlayer = Window:CreateTab("Player", "user")
local TabRender = Window:CreateTab("Render", "eye")
local TabMisc   = Window:CreateTab("Misc", "wrench")

-- // ==========================================================================
-- // SERWISY I ZMIENNE ROBLOX
-- // ==========================================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera or Workspace:FindFirstChildOfClass("Camera")

local function getCharacter()
    return LocalPlayer and LocalPlayer.Character
end

local function getHumanoid(char)
    char = char or getCharacter()
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function getRootPart(char)
    char = char or getCharacter()
    return char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso"))
end

-- // ==========================================================================
-- // STAN I LOGIKA GRACZA (PLAYER)
-- // ==========================================================================

-- 1. SPEED
local speedEnabled = false
local walkSpeedValue = 50
local originalWalkSpeed = 16
local speedLoopConn = nil
local sprintActive = false
local sprintSpeedValue = 90
local sprintEnabled = false

local function ApplySpeed()
    local hum = getHumanoid()
    if hum then
        if speedEnabled then
            hum.WalkSpeed = (sprintActive and sprintEnabled) and sprintSpeedValue or walkSpeedValue
        else
            hum.WalkSpeed = originalWalkSpeed
        end
    end
end

local function SetSpeedState(state)
    speedEnabled = state
    local hum = getHumanoid()
    if hum and not state then
        originalWalkSpeed = 16
    end
    ApplySpeed()

    if state then
        if not speedLoopConn then
            speedLoopConn = RunService.Heartbeat:Connect(function()
                if speedEnabled then
                    local h = getHumanoid()
                    if h and h.WalkSpeed ~= ((sprintActive and sprintEnabled) and sprintSpeedValue or walkSpeedValue) then
                        h.WalkSpeed = (sprintActive and sprintEnabled) and sprintSpeedValue or walkSpeedValue
                    end
                end
            end)
        end
    else
        if speedLoopConn then
            speedLoopConn:Disconnect()
            speedLoopConn = nil
        end
        ApplySpeed()
    end
end

-- Obsługa sprintu z Shiftem
UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe and (input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift) then
        sprintActive = true
        if speedEnabled and sprintEnabled then ApplySpeed() end
    end
end)

UserInputService.InputEnded:Connect(function(input, gpe)
    if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
        sprintActive = false
        if speedEnabled and sprintEnabled then ApplySpeed() end
    end
end)

-- 2. FLY
local flyEnabled = false
local flySpeed = 60
local flyNoclip = true
local flyConn = nil
local flyBV = nil
local flyBG = nil

local function CleanupFlyPhysics()
    if flyBV then pcall(function() flyBV:Destroy() end); flyBV = nil end
    if flyBG then pcall(function() flyBG:Destroy() end); flyBG = nil end
end

local function UpdateFly()
    local char = getCharacter()
    local hrp = getRootPart(char)
    local hum = getHumanoid(char)
    if not char or not hrp or not hum or hum.Health <= 0 then
        CleanupFlyPhysics()
        return
    end

    if not flyBV or flyBV.Parent ~= hrp then
        CleanupFlyPhysics()
        flyBV = Instance.new("BodyVelocity")
        flyBV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        flyBV.Velocity = Vector3.zero
        flyBV.Parent = hrp

        flyBG = Instance.new("BodyGyro")
        flyBG.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        flyBG.P = 9e4
        flyBG.CFrame = Camera.CFrame
        flyBG.Parent = hrp
    end

    hum.PlatformStand = true

    if flyNoclip then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end

    local camCF = Camera.CFrame
    local moveDir = Vector3.zero

    if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + camCF.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - camCF.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - camCF.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + camCF.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
        moveDir = moveDir - Vector3.new(0, 1, 0)
    end

    if moveDir.Magnitude > 0 then
        flyBV.Velocity = moveDir.Unit * flySpeed
    else
        flyBV.Velocity = Vector3.zero
    end
    flyBG.CFrame = camCF
end

local function SetFlyState(state)
    flyEnabled = state
    if state then
        if not flyConn then
            flyConn = RunService.RenderStepped:Connect(UpdateFly)
        end
    else
        if flyConn then flyConn:Disconnect(); flyConn = nil end
        CleanupFlyPhysics()
        local hum = getHumanoid()
        if hum then hum.PlatformStand = false end
    end
end

-- 3. INFINITE JUMP
local infJumpEnabled = false
local jumpPowerValue = 75
local originalJumpPower = 50

local function ApplyJumpPower()
    local hum = getHumanoid()
    if hum then
        if infJumpEnabled then
            hum.UseJumpPower = true
            hum.JumpPower = jumpPowerValue
        else
            hum.JumpPower = originalJumpPower
        end
    end
end

UserInputService.JumpRequest:Connect(function()
    if infJumpEnabled then
        local hum = getHumanoid()
        if hum then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

-- 4. NOCLIP
local noclipEnabled = false
local noclipConn = nil

local function SetNoclipState(state)
    noclipEnabled = state
    if state then
        if not noclipConn then
            noclipConn = RunService.Stepped:Connect(function()
                if noclipEnabled then
                    local char = getCharacter()
                    if char then
                        for _, p in ipairs(char:GetDescendants()) do
                            if p:IsA("BasePart") and p.CanCollide then
                                p.CanCollide = false
                            end
                        end
                    end
                end
            end)
        end
    else
        if noclipConn then
            noclipConn:Disconnect()
            noclipConn = nil
        end
    end
end

-- 5. CLICK TELEPORT (Ctrl + Click)
local clickTpEnabled = false
local mouse = LocalPlayer:GetMouse()

mouse.Button1Down:Connect(function()
    if clickTpEnabled and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
        local hrp = getRootPart()
        if hrp and mouse.Hit then
            hrp.CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0, 3.5, 0))
        end
    end
end)

-- Obsługa respawnu gracza
LocalPlayer.CharacterAdded:Connect(function(newChar)
    task.wait(0.6)
    if speedEnabled then ApplySpeed() end
    if infJumpEnabled then ApplyJumpPower() end
    if flyEnabled then SetFlyState(true) end
end)

-- // ==========================================================================
-- // STAN I LOGIKA WIZUALIÓW (RENDER & ESP)
-- // ==========================================================================
local espEnabled = false
local espHighlights = true
local espChams = false
local espNames = true
local espDistance = true
local espColor = Color3.fromRGB(0, 255, 170)
local espAlpha = 1.0
local maxEspDistance = 1500

local tracersEnabled = false
local tracerOriginMode = "Dół Ekranu (Bottom)"
local tracerColor = Color3.fromRGB(0, 220, 255)
local tracerAlpha = 1.0
local tracerThickness = 1.5

local trackedPlayers = {}

local function CleanupPlayerESP(player)
    local data = trackedPlayers[player]
    if data then
        if data.Highlight and data.Highlight.Parent then data.Highlight:Destroy() end
        if data.Billboard and data.Billboard.Parent then data.Billboard:Destroy() end
        if data.TracerLine then pcall(function() data.TracerLine:Remove() end) end
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

    local myHrp = getRootPart()
    local originPos = GetTracerOrigin()

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local char = player.Character
            local hrp = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso"))
            local hum = char and char:FindFirstChildOfClass("Humanoid")

            if char and hrp and hum and hum.Health > 0 then
                local dist = myHrp and (hrp.Position - myHrp.Position).Magnitude or 0

                if dist <= maxEspDistance then
                    local data = trackedPlayers[player]
                    if not data then
                        data = {}
                        trackedPlayers[player] = data
                    end

                    -- Highlight / Chams
                    if espEnabled and espHighlights then
                        if not data.Highlight or data.Highlight.Parent ~= char then
                            if data.Highlight then data.Highlight:Destroy() end
                            local hl = Instance.new("Highlight")
                            hl.Name = "MenuTest_HL"
                            hl.Adornee = char
                            hl.FillTransparency = espChams and 0.4 or 1.0
                            hl.OutlineTransparency = 0
                            hl.OutlineColor = espColor
                            hl.FillColor = espColor
                            hl.DepthMode = espChams and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
                            hl.Parent = char
                            data.Highlight = hl
                        else
                            data.Highlight.OutlineColor = espColor
                            data.Highlight.FillColor = espColor
                            data.Highlight.FillTransparency = espChams and 0.4 or 1.0
                            data.Highlight.DepthMode = espChams and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
                            data.Highlight.Enabled = true
                        end
                    elseif data.Highlight then
                        data.Highlight.Enabled = false
                    end

                    -- Billboard Name & Distance
                    if espEnabled and (espNames or espDistance) then
                        if not data.Billboard or data.Billboard.Parent ~= hrp then
                            if data.Billboard then data.Billboard:Destroy() end
                            local bb = Instance.new("BillboardGui")
                            bb.Name = "MenuTest_BB"
                            bb.Adornee = hrp
                            bb.Size = UDim2.new(0, 160, 0, 36)
                            bb.StudsOffset = Vector3.new(0, 3.2, 0)
                            bb.AlwaysOnTop = true
                            bb.Parent = hrp

                            local lbl = Instance.new("TextLabel", bb)
                            lbl.Name = "Info"
                            lbl.Size = UDim2.new(1, 0, 1, 0)
                            lbl.BackgroundTransparency = 1
                            lbl.Font = Enum.Font.GothamBold
                            lbl.TextSize = 12
                            lbl.TextColor3 = espColor
                            lbl.TextStrokeTransparency = 0
                            lbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                            data.Billboard = bb
                            data.Label = lbl
                        end

                        if data.Label then
                            local textParts = {}
                            if espNames then table.insert(textParts, player.DisplayName or player.Name) end
                            if espDistance then table.insert(textParts, string.format("[%d m]", math.floor(dist))) end
                            data.Label.Text = table.concat(textParts, " ")
                            data.Label.TextColor3 = espColor
                            data.Billboard.Enabled = true
                        end
                    elseif data.Billboard then
                        data.Billboard.Enabled = false
                    end

                    -- Tracers (Drawing API)
                    if tracersEnabled and Drawing then
                        local screenPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                        if onScreen then
                            if not data.TracerLine then
                                local line = Drawing.new("Line")
                                line.Thickness = tracerThickness
                                line.Transparency = tracerAlpha
                                data.TracerLine = line
                            end
                            data.TracerLine.Visible = true
                            data.TracerLine.From = originPos
                            data.TracerLine.To = Vector2.new(screenPos.X, screenPos.Y)
                            data.TracerLine.Color = tracerColor
                            data.TracerLine.Thickness = tracerThickness
                        elseif data.TracerLine then
                            data.TracerLine.Visible = false
                        end
                    elseif data.TracerLine then
                        data.TracerLine.Visible = false
                    end
                else
                    CleanupPlayerESP(player)
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

-- // ==========================================================================
-- // STAN I LOGIKA ŚWIATA (LIGHTING & FULLBRIGHT)
-- // ==========================================================================
local fullbrightEnabled = false
local oldAmbient = Lighting.Ambient
local oldBrightness = Lighting.Brightness
local oldClockTime = Lighting.ClockTime
local oldGlobalShadows = Lighting.GlobalShadows

local function SetFullbrightState(state)
    fullbrightEnabled = state
    if state then
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        Lighting.Brightness = 2
        Lighting.GlobalShadows = false
    else
        Lighting.Ambient = oldAmbient
        Lighting.Brightness = oldBrightness
        Lighting.GlobalShadows = oldGlobalShadows
    end
end

-- // ==========================================================================
-- // BUDOWA INTERFEJSU UŻYTKOWNIKA (KATEGORIE I KONTROLKI)
-- // ==========================================================================

-- =============================================================================
-- === ZAKŁADKA 1: PLAYER ===
-- =============================================================================
local CatMovement = TabPlayer:CreateCategory({
    Name = "Movement & Speed",
    Icon = "wind",
    Description = "Zarządzanie prędkością poruszania się oraz sprintem",
    Badge = "MOBILITY",
    Side = "Left"
})

local SpeedMod = CatMovement:CreateModule({
    Name = "WalkSpeed",
    Icon = "zap",
    Description = "Zwiększa prędkość poruszania się postaci",
    Default = false,
    DefaultKeybind = "Z",
    Flag = "Universal_Speed",
    Callback = function(state)
        SetSpeedState(state)
    end
})

SpeedMod:AddSlider({
    Name = "Prędkość",
    Min = 16,
    Max = 300,
    Default = 50,
    Step = 1,
    Suffix = " studs/s",
    Flag = "Universal_SpeedVal",
    Callback = function(val)
        walkSpeedValue = val
        if speedEnabled then ApplySpeed() end
    end
})

SpeedMod:AddToggle({
    Name = "Sprint na Shift",
    Default = false,
    Flag = "Universal_SprintEnabled",
    Callback = function(state)
        sprintEnabled = state
    end
})

SpeedMod:AddSlider({
    Name = "Prędkość Sprintu",
    Min = 30,
    Max = 350,
    Default = 90,
    Step = 1,
    Suffix = " studs/s",
    Flag = "Universal_SprintSpeedVal",
    Callback = function(val)
        sprintSpeedValue = val
        if speedEnabled and sprintActive then ApplySpeed() end
    end
})

local JumpMod = CatMovement:CreateModule({
    Name = "Infinite Jump",
    Icon = "arrow-up-circle",
    Description = "Pozwala skakać w powietrzu bez limitu",
    Default = false,
    DefaultKeybind = "J",
    Flag = "Universal_InfJump",
    Callback = function(state)
        infJumpEnabled = state
        ApplyJumpPower()
    end
})

JumpMod:AddSlider({
    Name = "Siła Skoku",
    Min = 50,
    Max = 350,
    Default = 75,
    Step = 1,
    Suffix = " power",
    Flag = "Universal_JumpPowerVal",
    Callback = function(val)
        jumpPowerValue = val
        if infJumpEnabled then ApplyJumpPower() end
    end
})

local CatPhysics = TabPlayer:CreateCategory({
    Name = "Flight & Noclip",
    Icon = "plane",
    Description = "Swobodne latanie w przestrzeni oraz przenikanie przez ściany",
    Badge = "PHYSICS",
    Side = "Right"
})

local FlyMod = CatPhysics:CreateModule({
    Name = "Flight (Fly)",
    Icon = "plane",
    Description = "Sterowanie: W, S, A, D, Space (góra), Ctrl/Shift (dół)",
    Default = false,
    DefaultKeybind = "F",
    Flag = "Universal_Fly",
    Callback = function(state)
        SetFlyState(state)
    end
})

FlyMod:AddSlider({
    Name = "Prędkość Lotu",
    Min = 10,
    Max = 300,
    Default = 60,
    Step = 1,
    Suffix = " studs/s",
    Flag = "Universal_FlySpeed",
    Callback = function(val)
        flySpeed = val
    end
})

FlyMod:AddToggle({
    Name = "Noclip w locie",
    Default = true,
    Flag = "Universal_FlyNoclip",
    Callback = function(state)
        flyNoclip = state
    end
})

local NoclipMod = CatPhysics:CreateModule({
    Name = "Noclip",
    Icon = "box",
    Description = "Wyłącza kolizje ze wszystkimi ścianami i obiektami",
    Default = false,
    DefaultKeybind = "V",
    Flag = "Universal_Noclip",
    Callback = function(state)
        SetNoclipState(state)
    end
})

local CatUtilities = TabPlayer:CreateCategory({
    Name = "Shortcuts & Teleport",
    Icon = "crosshair",
    Description = "Narzędzia teleportacji i awaryjnego resetu postaci",
    Badge = "SHORTCUTS",
    Side = "Right"
})

local ClickTpMod = CatUtilities:CreateModule({
    Name = "Click TP",
    Icon = "mouse-pointer",
    Description = "Przytrzymaj Ctrl i kliknij LPM w dowolny punkt mapy",
    Default = false,
    Flag = "Universal_ClickTP",
    Callback = function(state)
        clickTpEnabled = state
    end
})

CatUtilities:AddButton({
    Name = "Reset Postaci (Respawn)",
    Callback = function()
        local hum = getHumanoid()
        if hum then hum.Health = 0 end
    end
})

-- =============================================================================
-- === ZAKŁADKA 2: RENDER ===
-- =============================================================================
local CatVisuals = TabRender:CreateCategory({
    Name = "Player Visuals (ESP)",
    Icon = "eye",
    Description = "Wykrywanie graczy przez ściany, podświetlenie i dystans",
    Badge = "ESP",
    Side = "Left"
})

local ESPMod = CatVisuals:CreateModule({
    Name = "Player ESP",
    Icon = "eye",
    Default = false,
    DefaultKeybind = "H",
    Flag = "Universal_ESP",
    Callback = function(state)
        espEnabled = state
        if not state then CleanupAllESP() end
    end
})

ESPMod:AddToggle({
    Name = "Highlight (Obrys)",
    Default = true,
    Flag = "Universal_ESPHighlight",
    Callback = function(state)
        espHighlights = state
    end
})

ESPMod:AddToggle({
    Name = "Chams (Przez ściany)",
    Default = false,
    Flag = "Universal_ESPChams",
    Callback = function(state)
        espChams = state
    end
})

ESPMod:AddToggle({
    Name = "Nicki Graczy",
    Default = true,
    Flag = "Universal_ESPNames",
    Callback = function(state)
        espNames = state
    end
})

ESPMod:AddToggle({
    Name = "Dystans w metrach",
    Default = true,
    Flag = "Universal_ESPDistance",
    Callback = function(state)
        espDistance = state
    end
})

ESPMod:AddColorPicker({
    Name = "Kolor ESP",
    Default = Color3.fromRGB(0, 255, 170),
    Flag = "Universal_ESPColor",
    Callback = function(col)
        espColor = col
    end
})

CatVisuals:AddSlider({
    Name = "Max Zasięg Renderu",
    Min = 100,
    Max = 3000,
    Default = 1500,
    Step = 50,
    Suffix = " studs",
    Flag = "Universal_MaxDist",
    Callback = function(val)
        maxEspDistance = val
    end
})

local CatTracers = TabRender:CreateCategory({
    Name = "Tracers & Beams",
    Icon = "crosshair",
    Description = "Wektory namierzania łączące gracza z celami na ekranie",
    Badge = "TRACERS",
    Side = "Right"
})

local TracerMod = CatTracers:CreateModule({
    Name = "Tracers",
    Icon = "navigation",
    Default = false,
    Flag = "Universal_Tracers",
    Callback = function(state)
        tracersEnabled = state
        if not state then CleanupAllESP() end
    end
})

TracerMod:AddDropdown({
    Name = "Punkt Początkowy",
    Options = {"Dół Ekranu (Bottom)", "Środek Ekranu (Center)", "Kursor (Mouse)"},
    Default = "Dół Ekranu (Bottom)",
    Flag = "Universal_TracerOrigin",
    Callback = function(selected)
        tracerOriginMode = type(selected) == "table" and selected[1] or selected
    end
})

TracerMod:AddColorPicker({
    Name = "Kolor Linii",
    Default = Color3.fromRGB(0, 220, 255),
    Flag = "Universal_TracerColor",
    Callback = function(col)
        tracerColor = col
    end
})

CatTracers:AddSlider({
    Name = "Grubość Linii",
    Min = 1,
    Max = 5,
    Default = 1.5,
    Step = 0.5,
    Suffix = " px",
    Flag = "Universal_TracerThickness",
    Callback = function(val)
        tracerThickness = val
    end
})

-- =============================================================================
-- === ZAKŁADKA 3: MISC ===
-- =============================================================================
local CatLighting = TabMisc:CreateCategory({
    Name = "World & Lighting",
    Icon = "sun",
    Description = "Ustawienia oświetlenia mapy, dnia/nocy oraz cieni",
    Badge = "WORLD",
    Side = "Left"
})

local FullbrightMod = CatLighting:CreateModule({
    Name = "Fullbright",
    Icon = "sun",
    Description = "Rozświetla mapę i usuwa ciemne cienie",
    Default = false,
    Flag = "Universal_Fullbright",
    Callback = function(state)
        SetFullbrightState(state)
    end
})

CatLighting:AddSlider({
    Name = "Pora Dnia (Godzina)",
    Min = 0,
    Max = 24,
    Default = 14,
    Step = 0.5,
    Suffix = " h",
    Flag = "Universal_ClockTime",
    Callback = function(val)
        Lighting.ClockTime = val
    end
})

CatLighting:AddSlider({
    Name = "Pole Widzenia (FOV)",
    Min = 60,
    Max = 120,
    Default = 70,
    Step = 1,
    Suffix = "°",
    Flag = "Universal_FOV",
    Callback = function(val)
        Camera.FieldOfView = val
    end
})

local CatClient = TabMisc:CreateCategory({
    Name = "Client & Session",
    Icon = "wrench",
    Description = "Zarządzanie połączeniem z serwerem i optymalizacją",
    Badge = "SESSION",
    Side = "Right"
})

CatClient:AddButton({
    Name = "Dołącz ponownie (Rejoin)",
    Callback = function()
        pcall(function()
            TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
        end)
    end
})

CatClient:AddButton({
    Name = "Optymalizacja FPS (Low Gfx)",
    Callback = function()
        pcall(function()
            Lighting.GlobalShadows = false
            Lighting.FogEnd = 9e9
            for _, v in ipairs(Workspace:GetDescendants()) do
                if v:IsA("BasePart") and not v:IsA("MeshPart") then
                    v.Material = Enum.Material.SmoothPlastic
                end
            end
        end)
    end
})

print("[Universal Suite] Pomyślnie załadowano pełny pakiet Universal.")