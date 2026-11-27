-- // ==========================================================================
-- // LUMINAQHUB — UNIVERSAL
-- // Pierwsza gra w panelu: Visuals (ESP, Tracers, Nametag, Head ESP),
-- // Combat (Aimbot + FOV), Movement (WalkSpeed) oraz Settings (bind, tło).
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
local GuiService        = game:GetService("GuiService")
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
local CombatTab   = Window:CreateTab("Combat", "crosshair", 2)
local MovementTab = Window:CreateTab("Movement", "wind", 3)
local SettingsTab = Window:CreateTab("Settings", "settings", 4)

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

-- Aimbot: enabled = moduł włączony, active = faktycznie namierza (bind).
local aimCfg = {
    enabled     = false,
    active      = false,
    key         = "F",
    mode        = "Toggle", -- Toggle / Hold
    target      = "Head",   -- Head / Body
    sensitivity = 55,       -- 1-100: jak szybko celownik podąża za celem
    intensity   = 70,       -- 1-100: siła przyciągania / maks. krok
    jitter      = false,    -- mikro-drgania imitujące rękę
}

local fovCfg = {
    enabled = false, -- pokaż okrąg FOV
    radius  = 160,   -- promień wyszukiwania (px)
    color   = Color3.fromRGB(129, 140, 248),
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

-- FOV aimbota — okrąg wyszukiwania na środku ekranu
local fovCircle = Instance.new("Frame")
fovCircle.Name = "Aimbot_FOV"
fovCircle.AnchorPoint = Vector2.new(0.5, 0.5)
fovCircle.BackgroundTransparency = 1
fovCircle.BorderSizePixel = 0
fovCircle.Visible = false
fovCircle.Parent = overlayGui

Instance.new("UICorner", fovCircle).CornerRadius = UDim.new(1, 0)
local fovStroke = Instance.new("UIStroke", fovCircle)
fovStroke.Thickness = 1.5
fovStroke.Transparency = 0.2
fovStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
fovStroke.Color = fovCfg.color

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

    -- FOV — okrąg wyszukiwania aimbota
    fovCircle.Visible = fovCfg.enabled
    if fovCircle.Visible then
        local diameter = math.max((fovCfg.radius or 160) * 2, 8)
        fovCircle.Size = UDim2.fromOffset(diameter, diameter)
        fovCircle.Position = UDim2.fromOffset(viewport.X / 2, viewport.Y / 2)
        fovStroke.Color = fovCfg.color
    end

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

                -- Head ESP — kółko na głowie (skaluje się z graczem, nie rośnie z oddalaniem)
                visuals.Head.Visible = onScreen and headCfg.enabled
                if visuals.Head.Visible then
                    local sizeScale = math.clamp((headCfg.size or 18) / 18, 0.25, 3)
                    local radius = math.clamp(math.max(height, 1) * 0.11 * sizeScale, 2, 80)
                    local diameter = radius * 2

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
-- // COMBAT — AIMBOT + FOV
-- // ==========================================================================
local aimBindButton
local listeningForAimBind = false

local function refreshAimBindLabel()
    if aimBindButton then
        aimBindButton:Set("Bind aimbota: [" .. tostring(aimCfg.key) .. "]")
    end
end

local function isAimKey(input)
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return false end
    local code = input.KeyCode and input.KeyCode.Name
    return code ~= nil and code == aimCfg.key
end

local function roundStep(value)
    if value >= 0 then return math.floor(value + 0.5) end
    return math.ceil(value - 0.5)
end

local function getMousePosition()
    local ok, pos = pcall(function()
        return UserInputService:GetMouseLocation()
    end)
    if ok and pos then
        -- GetMouseLocation zwraca współrzędne z topbarem, a WorldToViewportPoint
        -- bez niego — korygujemy GUI inset, żeby delta była dokładna.
        local insetX, insetY = 0, 0
        pcall(function()
            local topLeft = GuiService:GetGuiInset()
            if topLeft then
                insetX, insetY = topLeft.X or 0, topLeft.Y or 0
            end
        end)
        return pos.X - insetX, pos.Y - insetY
    end

    local camera = Workspace.CurrentCamera
    if camera and camera.ViewportSize then
        return camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2
    end
    return nil
end

local function findAimTarget(camera, viewport)
    local centerX, centerY = viewport.X / 2, viewport.Y / 2
    local bestPos, bestDist = nil, math.max(fovCfg.radius or 160, 1)

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local _, hum, hrp, headPart = getCharacterParts(player)
            if hum and hum.Health > 0 and hrp then
                local part = (aimCfg.target == "Body" and hrp) or headPart or hrp
                if part then
                    local pos, onScreen = camera:WorldToViewportPoint(part.Position)
                    if onScreen and pos.Z and pos.Z > 0 then
                        local dx, dy = pos.X - centerX, pos.Y - centerY
                        local dist = math.sqrt(dx * dx + dy * dy)
                        if dist <= bestDist then
                            bestPos, bestDist = pos, dist
                        end
                    end
                end
            end
        end
    end

    return bestPos
end

local function updateAimbot()
    if not aimCfg.enabled or not aimCfg.active then return end
    if type(mousemoverel) ~= "function" then return end

    local camera = Workspace.CurrentCamera
    if not camera then return end
    local viewport = camera.ViewportSize
    if not viewport then return end

    local target = findAimTarget(camera, viewport)
    if not target then return end

    local mouseX, mouseY = getMousePosition()
    if not mouseX then return end

    -- Czułość: tempo podążania celownika za celem.
    local follow = 0.05 + (math.clamp(aimCfg.sensitivity, 1, 100) / 100) * 0.85
    -- Intensywność: siła przyciągania i maksymalny krok na klatkę.
    local strength = 0.15 + (math.clamp(aimCfg.intensity, 1, 100) / 100) * 0.85

    local dx = (target.X - mouseX) * follow * strength
    local dy = (target.Y - mouseY) * follow * strength

    local maxStep = math.max(1, 45 * strength)
    local dist = math.sqrt(dx * dx + dy * dy)
    if dist > maxStep then
        local k = maxStep / dist
        dx, dy = dx * k, dy * k
    end

    if aimCfg.jitter then
        dx = dx + (math.random() - 0.5) * 1.8
        dy = dy + (math.random() - 0.5) * 1.8
    end

    mousemoverel(roundStep(dx), roundStep(dy))
end

local AimbotModule = CombatTab:CreateModule({
    Name        = "Aimbot",
    Description = "Namierzanie graczy pod bindem",
    Icon        = "crosshair",
    Callback    = function(state)
        aimCfg.enabled = state
        if not state then aimCfg.active = false end
    end,
})

aimBindButton = AimbotModule:AddButton({
    Name     = "Bind aimbota: [" .. tostring(aimCfg.key) .. "]",
    Callback = function()
        if listeningForAimBind then return end
        listeningForAimBind = true
        aimBindButton:Set("Naciśnij klawisz...")

        task.delay(5, function()
            if listeningForAimBind then
                listeningForAimBind = false
                refreshAimBindLabel()
            end
        end)
    end,
})

AimbotModule:AddDropdown({
    Name          = "Aktywacja",
    Flag          = "Universal_Aimbot_Mode",
    Options       = { "Toggle", "Hold" },
    CurrentOption = { aimCfg.mode },
    Callback      = function(option)
        local value = type(option) == "table" and option[1] or option
        if value == "Toggle" or value == "Hold" then
            aimCfg.mode = value
            aimCfg.active = false
        end
    end,
})

AimbotModule:AddDropdown({
    Name          = "Cel",
    Flag          = "Universal_Aimbot_Target",
    Options       = { "Head", "Body" },
    CurrentOption = { aimCfg.target },
    Callback      = function(option)
        local value = type(option) == "table" and option[1] or option
        if value == "Head" or value == "Body" then
            aimCfg.target = value
        end
    end,
})

AimbotModule:AddSlider({
    Name     = "Czułość",
    Flag     = "Universal_Aimbot_Sensitivity",
    Range    = { 1, 100 },
    Default  = aimCfg.sensitivity,
    Step     = 1,
    Suffix   = "%",
    Callback = function(value) aimCfg.sensitivity = value end,
})

AimbotModule:AddSlider({
    Name     = "Intensywność",
    Flag     = "Universal_Aimbot_Intensity",
    Range    = { 1, 100 },
    Default  = aimCfg.intensity,
    Step     = 1,
    Suffix   = "%",
    Callback = function(value) aimCfg.intensity = value end,
})

AimbotModule:AddToggle({
    Name     = "Jitter (mikro-drgania)",
    Flag     = "Universal_Aimbot_Jitter",
    Default  = false,
    Callback = function(state) aimCfg.jitter = state end,
})

local FovModule = CombatTab:CreateModule({
    Name        = "FOV",
    Description = "Obszar wyszukiwania celu (przełącznik = pokaż okrąg)",
    Icon        = "eye",
    Callback    = function(state) fovCfg.enabled = state end,
})

FovModule:AddSlider({
    Name     = "Promień FOV",
    Flag     = "Universal_FOV_Radius",
    Range    = { 40, 600 },
    Default  = fovCfg.radius,
    Step     = 5,
    Suffix   = " px",
    Callback = function(value) fovCfg.radius = value end,
})

FovModule:AddColorPicker({
    Name     = "Kolor FOV",
    Flag     = "Universal_FOV_Color",
    Default  = fovCfg.color,
    Callback = function(color) fovCfg.color = color end,
})

-- // ==========================================================================
-- // MOVEMENT — WALKSPEED
-- // ==========================================================================
local SpeedModule = MovementTab:CreateModule({
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

local bindConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end

    -- Przechwytywanie binda menu
    if listeningForBind then
        listeningForBind = false
        local keyName = input.KeyCode and input.KeyCode.Name or "K"
        if keyName ~= "Escape" then
            Window:SetMenuKeybind(keyName)
        end
        refreshBindLabel()
        return
    end

    -- Przechwytywanie binda aimbota
    if listeningForAimBind then
        listeningForAimBind = false
        local keyName = input.KeyCode and input.KeyCode.Name or aimCfg.key
        if keyName ~= "Escape" then
            aimCfg.key = keyName
            aimCfg.active = false
        end
        refreshAimBindLabel()
        return
    end

    -- Aktywacja aimbota (pomijamy wpisywanie w polach GUI)
    if gameProcessed then return end
    if isAimKey(input) then
        if aimCfg.mode == "Hold" then
            aimCfg.active = true
        else
            aimCfg.active = not aimCfg.active
        end
    end
end)

local aimReleaseConnection = UserInputService.InputEnded:Connect(function(input)
    if aimCfg.mode ~= "Hold" then return end
    if isAimKey(input) then
        aimCfg.active = false
    end
end)

local aimConnection = RunService.RenderStepped:Connect(updateAimbot)

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
    pcall(function() aimReleaseConnection:Disconnect() end)
    pcall(function() aimConnection:Disconnect() end)
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
