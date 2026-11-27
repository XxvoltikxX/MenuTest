-- // ==========================================================================
-- // LUMINAQHUB — UNIVERSAL
-- // Pierwsza gra w panelu: ESP, Tracers, Nametag, Head ESP,
-- // WalkSpeed (Velocity / CFrame) oraz ustawienia (bind menu, tło GIF/Pictures).
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

-- // ==========================================================================
-- // DRAWING (ESP / TRACERS / NAMETAG / HEAD ESP)
-- // ==========================================================================
local DrawingLib = nil
pcall(function() DrawingLib = Drawing end)
local hasDrawing = (DrawingLib ~= nil and type(DrawingLib.new) == "function")

if not hasDrawing then
    warn("[Universal] Drawing API niedostępne — ESP działa w trybie Highlight, pozostałe efekty 2D są wyłączone.")
end

local espCache = {}

local function removeDrawing(obj)
    if not obj then return end
    pcall(function()
        if obj.Remove then obj:Remove() end
    end)
end

local function clearPlayerDrawing(player)
    local cache = espCache[player]
    if not cache then return end
    removeDrawing(cache.Box)
    removeDrawing(cache.Line)
    removeDrawing(cache.Name)
    removeDrawing(cache.Head)
    espCache[player] = nil
end

local function getPlayerDrawing(player)
    local cache = espCache[player]
    if cache then return cache end
    if not hasDrawing then return nil end

    cache = {}
    local ok = pcall(function()
        cache.Box  = DrawingLib.new("Square")
        cache.Line = DrawingLib.new("Line")
        cache.Name = DrawingLib.new("Text")
        cache.Head = DrawingLib.new("Circle")
    end)
    if not ok then return nil end

    pcall(function()
        cache.Box.Thickness   = 1
        cache.Box.Filled      = false
        cache.Box.Transparency = 0
    end)
    pcall(function()
        cache.Line.Thickness = 1
        cache.Line.Transparency = 0
    end)
    pcall(function()
        cache.Name.Size    = 13
        cache.Name.Center  = true
        cache.Name.Outline = true
        cache.Name.Font    = 2
        cache.Name.Transparency = 0
    end)
    pcall(function()
        cache.Head.Thickness = 1.5
        cache.Head.Filled    = false
        cache.Head.NumSides  = 32
    end)

    espCache[player] = cache
    return cache
end

-- Fallback: Highlight, gdy executor nie ma Drawing API
local highlightCache = {}

local function clearPlayerHighlight(player)
    local hl = highlightCache[player]
    if hl then
        pcall(function() hl:Destroy() end)
        highlightCache[player] = nil
    end
end

local function updateHighlights()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local char = player.Character
            local hl = highlightCache[player]

            if espCfg.enabled and char then
                if not hl or hl.Parent ~= char then
                    clearPlayerHighlight(player)
                    local newHl = Instance.new("Highlight")
                    newHl.Name = "LuminaqESP"
                    newHl.FillTransparency = 1
                    newHl.OutlineTransparency = 0
                    pcall(function() newHl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop end)
                    newHl.Parent = char
                    highlightCache[player] = newHl
                    hl = newHl
                end
                pcall(function() hl.OutlineColor = espCfg.color end)
            elseif hl then
                clearPlayerHighlight(player)
            end
        end
    end
end

local function updateDrawingESP()
    local camera = Workspace.CurrentCamera
    if not camera then return end
    local viewport = camera.ViewportSize

    -- Usuń rysunki graczy, którzy wyszli
    for player in pairs(espCache) do
        if not player.Parent then
            clearPlayerDrawing(player)
        end
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local _, hum, hrp, head = getCharacterParts(player)
            local alive = hum and hum.Health > 0 and hrp and head

            local wanted = espCfg.enabled or tracerCfg.enabled or nameCfg.enabled or headCfg.enabled
            local cache = wanted and getPlayerDrawing(player) or espCache[player]

            if alive and cache then
                local headPos = head.Position + Vector3.new(0, 0.6, 0)
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

                if cache.Box then
                    cache.Box.Visible = onScreen and espCfg.enabled
                    if cache.Box.Visible then
                        cache.Box.Color = espCfg.color
                        cache.Box.Position = Vector2.new(leftX, topY)
                        cache.Box.Size = Vector2.new(width, height)
                    end
                end

                if cache.Line then
                    cache.Line.Visible = onScreen and tracerCfg.enabled
                    if cache.Line.Visible then
                        cache.Line.Color = tracerCfg.color
                        cache.Line.From = Vector2.new(viewport.X / 2, viewport.Y)
                        cache.Line.To = Vector2.new(topX, bottomY)
                    end
                end

                if cache.Name then
                    cache.Name.Visible = onScreen and nameCfg.enabled
                    if cache.Name.Visible then
                        cache.Name.Color = nameCfg.color
                        cache.Name.Text = nameCfg.showDistance
                            and string.format("%s [%dm]", player.Name, math.floor(distance))
                            or player.Name
                        cache.Name.Position = Vector2.new(topX, topY - 18)
                    end
                end

                if cache.Head then
                    cache.Head.Visible = onScreen and headCfg.enabled
                    if cache.Head.Visible then
                        cache.Head.Color = headCfg.color
                        cache.Head.Radius = headCfg.size
                        cache.Head.Position = Vector2.new(headScreen.X, headScreen.Y)
                    end
                end
            elseif cache then
                if cache.Box then cache.Box.Visible = false end
                if cache.Line then cache.Line.Visible = false end
                if cache.Name then cache.Name.Visible = false end
                if cache.Head then cache.Head.Visible = false end
            end
        end
    end
end

local function updateVisuals()
    if hasDrawing then
        updateDrawingESP()
    else
        updateHighlights()
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
    clearPlayerDrawing(player)
    clearPlayerHighlight(player)
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

    for player in pairs(espCache) do
        clearPlayerDrawing(player)
    end
    for player in pairs(highlightCache) do
        clearPlayerHighlight(player)
    end

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
