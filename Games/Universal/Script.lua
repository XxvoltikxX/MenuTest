-- // ==========================================================================
-- // LUMINAQHUB — UNIVERSAL
-- // Pierwsza gra w panelu: ESP, Tracers, Nametag, Head ESP,
-- // WalkSpeed (Velocity / CFrame) oraz ustawienia (bind menu, tło GIF/Pictures).
-- //
-- // Visuals działają na własnej nakładce ScreenGui (Frames), więc nie wymagają
-- // Drawing API — ramki, linie i kółka renderują się w każdym executorze.
-- // ==========================================================================

local mainUrl = "https://raw.githubusercontent.com/XxvoltikxX/MenuTest/refs/heads/main/Main.lua?_cb="
    .. tostring(tick()) .. "_" .. tostring(os.time()) .. "_" .. tostring(math.random(100000, 999999))

local MENU = loadstring(game:HttpGet(mainUrl):gsub("^\239\187\191", ""))()

-- // Serwisy
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local Workspace         = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

-- // ==========================================================================
-- // OKNO GRY
-- // ==========================================================================
local Window = MENU:CreateWindow({
    Name            = "Universal",
    ToggleUIKeybind = "K",
    HideDashboard   = true, -- bez starego dashboardu — tylko zakładki gry
})

if not Window then
    warn("[Universal] Nie udało się utworzyć okna.")
    return
end

local VisualsTab  = Window:CreateTab("Visuals", "eye", 1)
local PlayerTab   = Window:CreateTab("Player", "user", 2)
local SettingsTab = Window:CreateTab("Settings", "settings", 3)

-- // ==========================================================================
-- // STAN FUNKCJI
-- // ==========================================================================
local espCfg = {
    enabled  = false,
    color    = Color3.fromRGB(129, 140, 248),
}

local tracerCfg = {
    enabled = false,
    color   = Color3.fromRGB(56, 189, 248),
}

local nameCfg = {
    enabled      = false,
    color        = Color3.fromRGB(244, 246, 255),
    showDistance = true,
}

local headCfg = {
    enabled = false,
    color   = Color3.fromRGB(52, 211, 153),
    size    = 18,
}

local speedCfg = {
    enabled  = false,
    mode     = "Velocity",
    value    = 60,
    baseWalk = 16,
}

-- // ==========================================================================
-- // POMOCNIKI GRACZA
-- // ==========================================================================
local function getCharacterParts(player)
    local char = player and player.Character
    if not char then return nil end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local head = char:FindFirstChild("Head")
    return char, hum, hrp, head
end

local function getLocalHumanoid()
    local _, hum = getCharacterParts(LocalPlayer)
    return hum
end

local function atan2(y, x)
    if math.atan2 then
        return math.atan2(y, x)
    end
    return math.atan(y, x)
end

-- // ==========================================================================
-- // NAKŁADKA ESP (ScreenGui + Frames — bez Drawing API)
-- // ==========================================================================
local overlayGui = Instance.new("ScreenGui")
overlayGui.Name = "Universal_ESP"
overlayGui.ResetOnSpawn = false
overlayGui.IgnoreGuiInset = true
overlayGui.DisplayOrder = 5
overlayGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local parentedOk = pcall(function()
    overlayGui.Parent = game:GetService("CoreGui")
end)
if not parentedOk or not overlayGui.Parent then
    pcall(function()
        overlayGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end)
end

local visualCache = {}

local function createPlayerVisuals()
    local box = Instance.new("Frame")
    box.Name = "ESP_Box"
    box.BackgroundTransparency = 1
    box.BorderSizePixel = 0
    box.Visible = false
    box.Parent = overlayGui

    local boxStroke = Instance.new("UIStroke", box)
    boxStroke.Thickness = 1.5
    boxStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    local tracer = Instance.new("Frame")
    tracer.Name = "ESP_Tracer"
    tracer.AnchorPoint = Vector2.new(0.5, 0.5)
    tracer.BorderSizePixel = 0
    tracer.Visible = false
    tracer.Parent = overlayGui

    local nameTag = Instance.new("TextLabel")
    nameTag.Name = "ESP_Name"
    nameTag.BackgroundTransparency = 1
    nameTag.AnchorPoint = Vector2.new(0.5, 1)
    nameTag.Size = UDim2.fromOffset(260, 18)
    nameTag.Font = Enum.Font.GothamBold
    nameTag.TextSize = 12
    nameTag.TextStrokeTransparency = 0.35
    nameTag.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    nameTag.TextXAlignment = Enum.TextXAlignment.Center
    nameTag.TextTruncate = Enum.TextTruncate.AtEnd
    nameTag.Visible = false
    nameTag.Parent = overlayGui

    local head = Instance.new("Frame")
    head.Name = "ESP_Head"
    head.BackgroundTransparency = 1
    head.AnchorPoint = Vector2.new(0.5, 0.5)
    head.BorderSizePixel = 0
    head.Visible = false
    head.Parent = overlayGui

    Instance.new("UICorner", head).CornerRadius = UDim.new(1, 0)
    local headStroke = Instance.new("UIStroke", head)
    headStroke.Thickness = 1.5
    headStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    return {
        Box        = box,
        BoxStroke  = boxStroke,
        Tracer     = tracer,
        Name       = nameTag,
        Head       = head,
        HeadStroke = headStroke,
    }
end

local function hidePlayerVisuals(visuals)
    if not visuals then return end
    visuals.Box.Visible = false
    visuals.Tracer.Visible = false
    visuals.Name.Visible = false
    visuals.Head.Visible = false
end

local function destroyPlayerVisuals(player)
    local visuals = visualCache[player]
    if not visuals then return end
    visualCache[player] = nil
    for _, obj in ipairs({ visuals.Box, visuals.Tracer, visuals.Name, visuals.Head }) do
        pcall(function() obj:Destroy() end)
    end
end

local function updateVisuals()
    local camera = Workspace.CurrentCamera
    if not camera then return end
    local viewport = camera.ViewportSize

    -- Usuń nakładki graczy, którzy wyszli z serwera
    for player in pairs(visualCache) do
        if not player.Parent then
            destroyPlayerVisuals(player)
        end
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local _, hum, hrp, headPart = getCharacterParts(player)
            local alive = hum and hum.Health > 0 and hrp and headPart

            local wanted = espCfg.enabled or tracerCfg.enabled or nameCfg.enabled or headCfg.enabled
            local visuals = visualCache[player]
            if wanted and not visuals then
                visuals = createPlayerVisuals()
                visualCache[player] = visuals
            end

            if alive and visuals then
                local headPos = headPart.Position + Vector3.new(0, 0.6, 0)
                local footPos = hrp.Position - Vector3.new(0, 3, 0)

                local headScreen, headOn = camera:WorldToViewportPoint(headPos)
                local footScreen, footOn = camera:WorldToViewportPoint(footPos)

                local onScreen = headOn and footOn and headScreen.Z > 0 and footScreen.Z > 0
                local topX, topY = headScreen.X, headScreen.Y
                local bottomY = footScreen.Y
                local height = math.max(bottomY - topY, 1)
                local width = height * 0.55
                local leftX = topX - (width / 2)

                local distance = (camera.CFrame.Position - hrp.Position).Magnitude

                -- ESP — prostokąt wokół gracza
                visuals.Box.Visible = onScreen and espCfg.enabled
                if visuals.Box.Visible then
                    visuals.Box.Position = UDim2.fromOffset(leftX, topY)
                    visuals.Box.Size = UDim2.fromOffset(width, height)
                    visuals.BoxStroke.Color = espCfg.color
                end

                -- Tracers — linia od dołu ekranu do stóp gracza
                visuals.Tracer.Visible = onScreen and tracerCfg.enabled
                if visuals.Tracer.Visible then
                    local fromX, fromY = viewport.X / 2, viewport.Y
                    local toX, toY = topX, bottomY
                    local dx, dy = toX - fromX, toY - fromY
                    local length = math.sqrt(dx * dx + dy * dy)

                    visuals.Tracer.Position = UDim2.fromOffset((fromX + toX) / 2, (fromY + toY) / 2)
                    visuals.Tracer.Size = UDim2.fromOffset(math.max(length, 1), 1.5)
                    visuals.Tracer.Rotation = math.deg(atan2(dy, dx))
                    visuals.Tracer.BackgroundColor3 = tracerCfg.color
                end

                -- Nametag — nazwa (i dystans) nad głową
                visuals.Name.Visible = onScreen and nameCfg.enabled
                if visuals.Name.Visible then
                    visuals.Name.Text = nameCfg.showDistance
                        and string.format("%s [%dm]", player.Name, math.floor(distance))
                        or player.Name
                    visuals.Name.TextColor3 = nameCfg.color
                    visuals.Name.Position = UDim2.fromOffset(topX, topY - 4)
                end

                -- Head ESP — kółko na głowie
                visuals.Head.Visible = onScreen and headCfg.enabled
                if visuals.Head.Visible then
                    local diameter = math.max(headCfg.size * 2, 4)
                    visuals.Head.Size = UDim2.fromOffset(diameter, diameter)
                    visuals.Head.Position = UDim2.fromOffset(headScreen.X, headScreen.Y)
                    visuals.HeadStroke.Color = headCfg.color
                end
            elseif visuals then
                hidePlayerVisuals(visuals)
            end
        end
    end
end

-- // ==========================================================================
-- // VISUALS — MODUŁY
-- // ==========================================================================
local ESPModule = VisualsTab:CreateModule({
    Name        = "ESP",
    Description = "Ramka wokół graczy",
    Icon        = "box",
    Callback    = function(state) espCfg.enabled = state end,
})
ESPModule:AddColorPicker({
    Name     = "Kolor ESP",
    Flag     = "Universal_ESP_Color",
    Default  = espCfg.color,
    Callback = function(color) espCfg.color = color end,
})

local TracerModule = VisualsTab:CreateModule({
    Name        = "Tracers",
    Description = "Linie od dołu ekranu",
    Icon        = "crosshair",
    Callback    = function(state) tracerCfg.enabled = state end,
})
TracerModule:AddColorPicker({
    Name     = "Kolor tracerów",
    Flag     = "Universal_Tracer_Color",
    Default  = tracerCfg.color,
    Callback = function(color) tracerCfg.color = color end,
})

local NametagModule = VisualsTab:CreateModule({
    Name        = "Nametag",
    Description = "Nazwa i dystans gracza",
    Icon        = "user",
    Callback    = function(state) nameCfg.enabled = state end,
})
NametagModule:AddColorPicker({
    Name     = "Kolor nazwy",
    Flag     = "Universal_Nametag_Color",
    Default  = nameCfg.color,
    Callback = function(color) nameCfg.color = color end,
})
NametagModule:AddToggle({
    Name     = "Pokaż dystans",
    Flag     = "Universal_Nametag_Distance",
    Default  = true,
    Callback = function(state) nameCfg.showDistance = state end,
})

local HeadModule = VisualsTab:CreateModule({
    Name        = "Head ESP",
    Description = "Okrąg na głowie gracza",
    Icon        = "eye",
    Callback    = function(state) headCfg.enabled = state end,
})
HeadModule:AddColorPicker({
    Name     = "Kolor head ESP",
    Flag     = "Universal_Head_Color",
    Default  = headCfg.color,
    Callback = function(color) headCfg.color = color end,
})
HeadModule:AddSlider({
    Name     = "Rozmiar",
    Flag     = "Universal_Head_Size",
    Range    = { 4, 48 },
    Default  = headCfg.size,
    Step     = 1,
    Suffix   = " px",
    Callback = function(value) headCfg.size = value end,
})

-- // ==========================================================================
-- // PLAYER — WALKSPEED
-- // ==========================================================================
local SpeedModule = PlayerTab:CreateModule({
    Name        = "WalkSpeed",
    Description = "Prędkość poruszania się",
    Icon        = "zap",
    Callback    = function(state)
        speedCfg.enabled = state
        local hum = getLocalHumanoid()
        if state then
            if hum then speedCfg.baseWalk = hum.WalkSpeed end
        elseif hum then
            hum.WalkSpeed = speedCfg.baseWalk or 16
        end
    end,
})

SpeedModule:AddDropdown({
    Name          = "Tryb",
    Flag          = "Universal_Speed_Mode",
    Options       = { "Velocity", "CFrame" },
    CurrentOption = { speedCfg.mode },
    Callback      = function(option)
        local value = type(option) == "table" and option[1] or option
        if value == "Velocity" or value == "CFrame" then
            speedCfg.mode = value
        end
    end,
})

SpeedModule:AddSlider({
    Name     = "Prędkość",
    Flag     = "Universal_Speed_Value",
    Range    = { 16, 500 },
    Default  = speedCfg.value,
    Step     = 1,
    Suffix   = " spd",
    Callback = function(value) speedCfg.value = value end,
})

-- // ==========================================================================
-- // SETTINGS — BIND MENU + TŁO
-- // ==========================================================================
local bindButton
local listeningForBind = false

local function refreshBindLabel()
    local current = Window:GetMenuKeybind()
    if bindButton then
        bindButton:Set("Bind menu: [" .. tostring(current) .. "]")
    end
end

bindButton = SettingsTab:CreateButton({
    Name     = "Bind menu: [" .. tostring(Window:GetMenuKeybind()) .. "]",
    Callback = function()
        if listeningForBind then return end
        listeningForBind = true
        bindButton:Set("Naciśnij klawisz...")

        task.delay(5, function()
            if listeningForBind then
                listeningForBind = false
                refreshBindLabel()
            end
        end)
    end,
})

local backgroundModes = { "Pictures", "GIF" }
local presetOrder = select(1, Window:GetBackgroundPresets())
local currentMode, currentPreset, currentTransparency = Window:GetMenuBackground()

SettingsTab:CreateDropdown({
    Name          = "Tryb tła",
    Flag          = "Universal_Background_Mode",
    Options       = backgroundModes,
    CurrentOption = { currentMode or "Pictures" },
    Callback      = function(option)
        local value = type(option) == "table" and option[1] or option
        Window:SetMenuBackground(value, nil, nil)
    end,
})

SettingsTab:CreateDropdown({
    Name          = "Wygląd tła",
    Flag          = "Universal_Background_Preset",
    Options       = presetOrder,
    CurrentOption = { currentPreset or "Aurora Flow" },
    Callback      = function(option)
        local value = type(option) == "table" and option[1] or option
        Window:SetMenuBackground(nil, value, nil)
    end,
})

SettingsTab:CreateSlider({
    Name     = "Przezroczystość tła",
    Flag     = "Universal_Background_Transparency",
    Range    = { 0, 85 },
    Default  = math.floor((tonumber(currentTransparency) or 0.30) * 100),
    Step     = 1,
    Suffix   = "%",
    Callback = function(value)
        Window:SetMenuBackground(nil, nil, value / 100)
    end,
})

SettingsTab:CreateButton({
    Name     = "Następny wygląd",
    Callback = function()
        Window:CycleMenuBackground()
    end,
})

-- // ==========================================================================
-- // PĘTLE
-- // ==========================================================================
local renderConnection = RunService.RenderStepped:Connect(updateVisuals)

local speedConnection = RunService.Heartbeat:Connect(function(dt)
    if not speedCfg.enabled then return end

    local _, hum, hrp = getCharacterParts(LocalPlayer)
    if not hum or not hrp then return end

    if speedCfg.mode == "CFrame" then
        hum.WalkSpeed = 0
        local direction = hum.MoveDirection or Vector3.new(0, 0, 0)
        if direction.Magnitude > 0 then
            hrp.CFrame = hrp.CFrame + (direction * speedCfg.value * (dt or 0))
        end
    else
        hum.WalkSpeed = speedCfg.value
    end
end)

local bindConnection = UserInputService.InputBegan:Connect(function(input)
    if not listeningForBind then return end
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end

    listeningForBind = false
    local keyName = input.KeyCode and input.KeyCode.Name or "K"
    if keyName == "Escape" then
        refreshBindLabel()
        return
    end

    Window:SetMenuKeybind(keyName)
    refreshBindLabel()
end)

local playerRemovingConnection = Players.PlayerRemoving:Connect(function(player)
    destroyPlayerVisuals(player)
end)

-- // ==========================================================================
-- // SPRZĄTANIE
-- // ==========================================================================
local cleanedUp = false

local function cleanupAll()
    if cleanedUp then return end
    cleanedUp = true

    pcall(function() renderConnection:Disconnect() end)
    pcall(function() speedConnection:Disconnect() end)
    pcall(function() bindConnection:Disconnect() end)
    pcall(function() playerRemovingConnection:Disconnect() end)

    for player in pairs(visualCache) do
        destroyPlayerVisuals(player)
    end

    pcall(function() overlayGui:Destroy() end)

    local hum = getLocalHumanoid()
    if hum then
        pcall(function() hum.WalkSpeed = speedCfg.baseWalk or 16 end)
    end
end

Window:OnCleanup(cleanupAll)

-- Dodatkowe zabezpieczenie: sprzątanie także przy zniszczeniu GUI okna
pcall(function()
    local gui = getgenv and getgenv()._VoltikMenuTestGui
    if gui then
        gui.Destroying:Connect(cleanupAll)
    end
end)
