-- // ==========================================================================
-- // LUMINAQHUB — UNIVERSAL EXPLORER
-- // Nowy silnik: dashboard + wyszukiwarka scriptów + panel szczegółów.
-- // Wszystkie funkcje uniwersalne działają w KAŻDEJ grze Roblox.
-- // ==========================================================================

-- 1. Załadowanie głównej biblioteki UI
local mainRaw = game:HttpGet("https://raw.githubusercontent.com/XxvoltikxX/MenuTest/refs/heads/main/Main.lua?_cb=" .. tostring(tick()) .. "_" .. tostring(os.time()) .. "_" .. tostring(math.random(100000, 999999)))
local MENU = loadstring(mainRaw:gsub("^\239\187\191", ""))()

-- 2. Serwisy i zmienne
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local VirtualUser = nil
pcall(function() VirtualUser = game:GetService("VirtualUser") end)

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera or Workspace:FindFirstChildOfClass("Camera")

local function getCamera()
    return Workspace.CurrentCamera or Camera
end

local Connections = {}

local function connect(conn)
    table.insert(Connections, conn)
    return conn
end

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
-- // PLAYER — SPEED
-- // ==========================================================================
local speedEnabled = false
local walkSpeedValue = 50
local originalWalkSpeed = 16
local speedLoopConn = nil
local sprintActive = false
local sprintSpeedValue = 90
local sprintEnabled = false

local function ApplySpeed()
    local hum = getHumanoid()
    if not hum then return end
    if speedEnabled then
        hum.WalkSpeed = (sprintActive and sprintEnabled) and sprintSpeedValue or walkSpeedValue
    else
        hum.WalkSpeed = originalWalkSpeed
    end
end

local function SetSpeedState(state)
    speedEnabled = state == true
    local hum = getHumanoid()

    if speedEnabled then
        if hum and not speedLoopConn then
            originalWalkSpeed = hum.WalkSpeed
        end
        ApplySpeed()
        if not speedLoopConn then
            speedLoopConn = RunService.Heartbeat:Connect(function()
                if not speedEnabled then return end
                local h = getHumanoid()
                local target = (sprintActive and sprintEnabled) and sprintSpeedValue or walkSpeedValue
                if h and h.WalkSpeed ~= target then
                    h.WalkSpeed = target
                end
            end)
        end
    else
        if speedLoopConn then
            speedLoopConn:Disconnect()
            speedLoopConn = nil
        end
        if hum then
            hum.WalkSpeed = originalWalkSpeed
        end
    end
end

connect(UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe and (input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift) then
        sprintActive = true
        if speedEnabled and sprintEnabled then ApplySpeed() end
    end
end))

connect(UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
        sprintActive = false
        if speedEnabled and sprintEnabled then ApplySpeed() end
    end
end))

-- // ==========================================================================
-- // PLAYER — FLY
-- // ==========================================================================
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
    local cam = getCamera()
    local char = getCharacter()
    local hrp = getRootPart(char)
    local hum = getHumanoid(char)
    if not cam or not char or not hrp or not hum or hum.Health <= 0 then
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
        flyBG.CFrame = cam.CFrame
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

    local camCF = cam.CFrame
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
    flyEnabled = state == true
    if flyEnabled then
        if not flyConn then
            flyConn = RunService.RenderStepped:Connect(UpdateFly)
        end
    else
        if flyConn then flyConn:Disconnect(); flyConn = nil end
        CleanupFlyPhysics()
        local char = getCharacter()
        local hum = getHumanoid(char)
        if hum then hum.PlatformStand = false end
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = true end
            end
        end
    end
end

-- // ==========================================================================
-- // PLAYER — INFINITE JUMP
-- // ==========================================================================
local infJumpEnabled = false
local jumpPowerValue = 75
local originalJumpPower = 50

local function ApplyJumpPower()
    local hum = getHumanoid()
    if not hum then return end
    if infJumpEnabled then
        hum.UseJumpPower = true
        hum.JumpPower = jumpPowerValue
    else
        hum.JumpPower = originalJumpPower
    end
end

connect(UserInputService.JumpRequest:Connect(function()
    if infJumpEnabled then
        local hum = getHumanoid()
        if hum then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end))

local function SetInfJumpState(state)
    infJumpEnabled = state == true
    if infJumpEnabled then
        local hum = getHumanoid()
        if hum then originalJumpPower = hum.JumpPower end
    end
    ApplyJumpPower()
end

-- // ==========================================================================
-- // PLAYER — NOCLIP
-- // ==========================================================================
local noclipEnabled = false
local noclipConn = nil

local function SetNoclipState(state)
    noclipEnabled = state == true
    if noclipEnabled then
        if not noclipConn then
            noclipConn = RunService.Stepped:Connect(function()
                if not noclipEnabled then return end
                local char = getCharacter()
                if char then
                    for _, p in ipairs(char:GetDescendants()) do
                        if p:IsA("BasePart") and p.CanCollide then
                            p.CanCollide = false
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
        local char = getCharacter()
        if char then
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = true end
            end
        end
    end
end

-- // ==========================================================================
-- // PLAYER — CLICK TELEPORT
-- // ==========================================================================
local clickTpEnabled = false
local mouse = LocalPlayer:GetMouse()

connect(mouse.Button1Down:Connect(function()
    if clickTpEnabled and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
        local hrp = getRootPart()
        if hrp and mouse.Hit then
            hrp.CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0, 3.5, 0))
        end
    end
end))

-- // ==========================================================================
-- // RESPAWN
-- // ==========================================================================
connect(LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.6)
    if speedEnabled then ApplySpeed() end
    if infJumpEnabled then ApplyJumpPower() end
    if flyEnabled then SetFlyState(true) end
end))

-- // ==========================================================================
-- // RENDER — ESP & TRACERS
-- // ==========================================================================
local espEnabled = false
local espHighlights = true
local espChams = false
local espNames = true
local espDistance = true
local espColor = Color3.fromRGB(0, 255, 170)
local maxEspDistance = 1500

local tracersEnabled = false
local tracerFromBottom = true
local tracerColor = Color3.fromRGB(0, 220, 255)
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
    local cam = getCamera()
    if not cam then return nil end
    local vp = cam.ViewportSize
    if tracerFromBottom then
        return Vector2.new(vp.X / 2, vp.Y - 10)
    end
    local mousePos = UserInputService:GetMouseLocation()
    return Vector2.new(mousePos.X, mousePos.Y)
end

local function UpdateESP()
    if not espEnabled and not tracersEnabled then
        CleanupAllESP()
        return
    end

    local myHrp = getRootPart()
    local originPos = GetTracerOrigin()

    local cam = getCamera()
    if not cam then
        CleanupAllESP()
        return
    end

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
                            hl.Name = "LuminaqHUB_HL"
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
                            bb.Name = "LuminaqHUB_BB"
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
                        local screenPos, onScreen = cam:WorldToViewportPoint(hrp.Position)
                        if onScreen then
                            if not data.TracerLine then
                                local line = Drawing.new("Line")
                                line.Thickness = tracerThickness
                                line.Transparency = 1
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

connect(RunService.RenderStepped:Connect(function()
    pcall(UpdateESP)
end))

connect(Players.PlayerRemoving:Connect(CleanupPlayerESP))

-- // ==========================================================================
-- // RENDER — FULLBRIGHT
-- // ==========================================================================
local fullbrightEnabled = false
local oldAmbient = Lighting.Ambient
local oldBrightness = Lighting.Brightness
local oldGlobalShadows = Lighting.GlobalShadows

local function SetFullbrightState(state)
    fullbrightEnabled = state == true
    if fullbrightEnabled then
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
-- // MISC — AKCJE
-- // ==========================================================================
local function ResetCharacter()
    local hum = getHumanoid()
    if hum then hum.Health = 0 end
end

local function LowGraphics()
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

local function CopyJobId()
    pcall(function() setclipboard(tostring(game.JobId)) end)
end

local function RejoinServer()
    pcall(function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end)
end

-- // ==========================================================================
-- // MISC — OCHRONA KLIENTA
-- // ==========================================================================
local antiAfkEnabled = false
local antiAfkConnection = nil

local function SetAntiAfkState(state)
    antiAfkEnabled = state == true
    if antiAfkConnection then
        pcall(function() antiAfkConnection:Disconnect() end)
        antiAfkConnection = nil
    end
    if not antiAfkEnabled then return end

    pcall(function()
        if typeof(getconnections) == "function" then
            for _, c in pairs(getconnections(LocalPlayer.Idled)) do
                pcall(function() c:Disable(); c:Disconnect() end)
            end
        end
    end)

    antiAfkConnection = LocalPlayer.Idled:Connect(function()
        pcall(function()
            local vim = Instance.new("VirtualInputManager")
            vim:SendMouseButtonEvent(0, 0, 0, true, game, 0)
            vim:SendMouseButtonEvent(0, 0, 0, false, game, 0)
            vim:Destroy()
        end)
        if VirtualUser then
            pcall(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
        end
    end)
end

local antiFlingEnabled = false
local antiFlingConnection = nil

local function SetAntiFlingState(state)
    antiFlingEnabled = state == true
    if antiFlingConnection then
        pcall(function() antiFlingConnection:Disconnect() end)
        antiFlingConnection = nil
    end
    if not antiFlingEnabled then return end

    antiFlingConnection = RunService.Stepped:Connect(function()
        if not antiFlingEnabled then return end
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                for _, v in ipairs(player.Character:GetDescendants()) do
                    if v:IsA("BasePart") and v.CanCollide then
                        v.CanCollide = false
                    end
                end
            end
        end
        local char = getCharacter()
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            if hrp.AssemblyLinearVelocity and hrp.AssemblyLinearVelocity.Magnitude > 3500 then
                hrp.AssemblyLinearVelocity = Vector3.zero
            end
            if hrp.AssemblyAngularVelocity and hrp.AssemblyAngularVelocity.Magnitude > 2500 then
                hrp.AssemblyAngularVelocity = Vector3.zero
            end
        end
    end)
end

-- Domyślnie ochrona klienta jest aktywna (jak w starym panelu Settings)
SetAntiAfkState(true)
SetAntiFlingState(true)

-- // ==========================================================================
-- // REJESTR SCRIPTÓW DLA EXPLORERA
-- // ==========================================================================
local Scripts = {
    -- // PLAYER ---------------------------------------------------------------
    {
        Name = "WalkSpeed",
        Description = "Zwiększa prędkość poruszania się postaci. Obsługuje sprint na Shift.",
        Category = "Player",
        Tags = { "speed", "movement" },
        Icon = "zap",
        Mode = "toggle",
        Pinned = true,
        Default = false,
        OnToggle = SetSpeedState,
        Options = {
            {
                Type = "slider",
                Name = "Prędkość",
                Min = 16,
                Max = 300,
                Default = 50,
                Step = 1,
                Suffix = " studs/s",
                Callback = function(val)
                    walkSpeedValue = val
                    if speedEnabled then ApplySpeed() end
                end,
            },
            {
                Type = "toggle",
                Name = "Sprint na Shift",
                Default = false,
                Callback = function(state)
                    sprintEnabled = state
                    if speedEnabled then ApplySpeed() end
                end,
            },
            {
                Type = "slider",
                Name = "Prędkość Sprintu",
                Min = 30,
                Max = 350,
                Default = 90,
                Step = 1,
                Suffix = " studs/s",
                Callback = function(val)
                    sprintSpeedValue = val
                    if speedEnabled and sprintActive then ApplySpeed() end
                end,
            },
        },
    },
    {
        Name = "Infinite Jump",
        Description = "Pozwala skakać w powietrzu bez limitu. Możesz ustawić siłę skoku.",
        Category = "Player",
        Tags = { "jump", "movement" },
        Icon = "arrow-up-circle",
        Mode = "toggle",
        Pinned = true,
        Default = false,
        OnToggle = SetInfJumpState,
        Options = {
            {
                Type = "slider",
                Name = "Siła Skoku",
                Min = 50,
                Max = 350,
                Default = 75,
                Step = 1,
                Suffix = " power",
                Callback = function(val)
                    jumpPowerValue = val
                    if infJumpEnabled then ApplyJumpPower() end
                end,
            },
        },
    },
    {
        Name = "Flight (Fly)",
        Description = "Swobodne latanie: W, S, A, D, Space (góra), Ctrl/Shift (dół).",
        Category = "Player",
        Tags = { "fly", "movement" },
        Icon = "plane",
        Mode = "toggle",
        Pinned = true,
        Default = false,
        OnToggle = SetFlyState,
        Options = {
            {
                Type = "slider",
                Name = "Prędkość Lotu",
                Min = 10,
                Max = 300,
                Default = 60,
                Step = 1,
                Suffix = " studs/s",
                Callback = function(val)
                    flySpeed = val
                end,
            },
            {
                Type = "toggle",
                Name = "Noclip w locie",
                Default = true,
                Callback = function(state)
                    flyNoclip = state
                end,
            },
        },
    },
    {
        Name = "Noclip",
        Description = "Wyłącza kolizje ze wszystkimi ścianami i obiektami.",
        Category = "Player",
        Tags = { "noclip", "movement" },
        Icon = "box",
        Mode = "toggle",
        Pinned = true,
        Default = false,
        OnToggle = SetNoclipState,
    },
    {
        Name = "Click TP",
        Description = "Przytrzymaj Ctrl i kliknij LPM w dowolny punkt mapy, aby się teleportować.",
        Category = "Player",
        Tags = { "teleport", "movement" },
        Icon = "mouse-pointer",
        Mode = "toggle",
        Default = false,
        OnToggle = function(state)
            clickTpEnabled = state
        end,
    },

    -- // RENDER --------------------------------------------------------------
    {
        Name = "Player ESP",
        Description = "Wykrywanie graczy przez ściany, podświetlenie, nicki i dystans.",
        Category = "Render",
        Tags = { "esp", "visuals" },
        Icon = "eye",
        Mode = "toggle",
        Pinned = true,
        Default = false,
        OnToggle = function(state)
            espEnabled = state
            if not state then CleanupAllESP() end
        end,
        Options = {
            {
                Type = "toggle",
                Name = "Highlight (Obrys)",
                Default = true,
                Callback = function(state) espHighlights = state end,
            },
            {
                Type = "toggle",
                Name = "Chams (Przez ściany)",
                Default = false,
                Callback = function(state) espChams = state end,
            },
            {
                Type = "toggle",
                Name = "Nicki Graczy",
                Default = true,
                Callback = function(state) espNames = state end,
            },
            {
                Type = "toggle",
                Name = "Dystans w metrach",
                Default = true,
                Callback = function(state) espDistance = state end,
            },
            {
                Type = "slider",
                Name = "Max Zasięg",
                Min = 100,
                Max = 3000,
                Default = 1500,
                Step = 50,
                Suffix = " studs",
                Callback = function(val) maxEspDistance = val end,
            },
        },
    },
    {
        Name = "Tracers",
        Description = "Linie namierzania łączące krawędź ekranu z każdym widocznym graczem.",
        Category = "Render",
        Tags = { "tracers", "visuals" },
        Icon = "navigation",
        Mode = "toggle",
        Default = false,
        OnToggle = function(state)
            tracersEnabled = state
            if not state then CleanupAllESP() end
        end,
        Options = {
            {
                Type = "toggle",
                Name = "Linie od dołu ekranu",
                Default = true,
                Callback = function(state) tracerFromBottom = state end,
            },
            {
                Type = "slider",
                Name = "Grubość Linii",
                Min = 1,
                Max = 5,
                Default = 1.5,
                Step = 0.5,
                Suffix = " px",
                Callback = function(val) tracerThickness = val end,
            },
        },
    },
    {
        Name = "Fullbright",
        Description = "Rozświetla mapę i usuwa ciemne cienie.",
        Category = "Render",
        Tags = { "lighting", "world" },
        Icon = "sun",
        Mode = "toggle",
        Pinned = true,
        Default = false,
        OnToggle = SetFullbrightState,
    },

    -- // MISC ----------------------------------------------------------------
    {
        Name = "AntiAFK",
        Description = "Zapobiega rozłączeniu po 20 minutach bezczynności.",
        Category = "Misc",
        Tags = { "afk", "protection" },
        Icon = "shield",
        Mode = "toggle",
        Default = true,
        OnToggle = SetAntiAfkState,
    },
    {
        Name = "AntiFling",
        Description = "Chroni postać przed wyrzuceniem ze zderzeń i stabilizuje prędkość.",
        Category = "Misc",
        Tags = { "fling", "protection" },
        Icon = "zap",
        Mode = "toggle",
        Default = true,
        OnToggle = SetAntiFlingState,
    },
    {
        Name = "Reset Character",
        Description = "Natychmiastowo respawnuje Twoją postać.",
        Category = "Misc",
        Tags = { "respawn", "utility" },
        Icon = "refresh-cw",
        Mode = "action",
        Run = ResetCharacter,
    },
    {
        Name = "Low Graphics",
        Description = "Upraszcza materiały i wyłącza cienie, aby poprawić FPS.",
        Category = "Misc",
        Tags = { "fps", "optimization" },
        Icon = "cpu",
        Mode = "action",
        Run = LowGraphics,
    },
    {
        Name = "Copy JobId",
        Description = "Kopiuje identyfikator bieżącej sesji serwera do schowka.",
        Category = "Misc",
        Tags = { "server", "utility" },
        Icon = "copy",
        Mode = "action",
        Run = CopyJobId,
    },
    {
        Name = "Rejoin Server",
        Description = "Przełącza Cię z powrotem na ten sam serwer.",
        Category = "Misc",
        Tags = { "server", "utility" },
        Icon = "globe",
        Mode = "action",
        Run = RejoinServer,
    },
}

-- // ==========================================================================
-- // CLEANUP
-- // ==========================================================================
local function Cleanup()
    for _, c in ipairs(Connections) do
        pcall(function() c:Disconnect() end)
    end
    table.clear(Connections)

    if speedEnabled then pcall(function() SetSpeedState(false) end) end
    if flyEnabled then pcall(function() SetFlyState(false) end) end
    if noclipEnabled then pcall(function() SetNoclipState(false) end) end
    if infJumpEnabled then pcall(function() SetInfJumpState(false) end) end
    if fullbrightEnabled then pcall(function() SetFullbrightState(false) end) end
    if antiAfkEnabled then pcall(function() SetAntiAfkState(false) end) end
    if antiFlingEnabled then pcall(function() SetAntiFlingState(false) end) end
    pcall(CleanupAllESP)
end

-- // ==========================================================================
-- // START EXPLORERA
-- // ==========================================================================
local Explorer = MENU:CreateExplorer({
    Name = "LuminaqHUB",
    Tittle = "Welcome to LuminaqHub",
    ToggleUIKeybind = "K",
    GameId = "LuminaqHUB",
    Scripts = Scripts,
    OnCleanup = Cleanup,
})

if Explorer then
    print("[LuminaqHUB] Universal Explorer załadowany — " .. tostring(#Scripts) .. " scriptów.")
else
    warn("[LuminaqHUB] Nie udało się uruchomić explorera.")
end
