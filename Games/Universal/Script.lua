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

-- Cisza w produkcji: bez sygnatur w LogService.
local DEV = (typeof(getgenv) == "function" and getgenv()._MenuTestDevMode == true)
local function warn(...)
    if DEV then print(...) end
end

local Stealth = MENU and MENU.Stealth or nil

-- // Serwisy
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local Workspace         = game:GetService("Workspace")
local TweenService      = game:GetService("TweenService")

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
local overlayGui
if Stealth and type(Stealth.NewScreenGui) == "function" then
    overlayGui = Stealth.NewScreenGui({ DisplayOrder = 5, IgnoreGuiInset = true })
else
    overlayGui = Instance.new("ScreenGui")
    overlayGui.Name = tostring(math.random(1000000, 9999999))
    overlayGui.ResetOnSpawn = false
    overlayGui.IgnoreGuiInset = true
    overlayGui.DisplayOrder = 5
    pcall(function() overlayGui.Parent = game:GetService("CoreGui") end)
end
overlayGui.ResetOnSpawn = false
overlayGui.IgnoreGuiInset = true
overlayGui.DisplayOrder = 5
overlayGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- // ==========================================================================
-- // HUD — ARRAYLIST (aktywne moduły) + TOGGLE INFO (komunikat on/off)
-- // ==========================================================================
local hudCfg = {
    info = true,
    list = true,
    listBg     = Color3.fromRGB(15, 17, 26),
    listText   = Color3.fromRGB(244, 246, 255),
    listAccent = Color3.fromRGB(129, 140, 248),
    infoOn     = Color3.fromRGB(52, 211, 153),
    infoOff    = Color3.fromRGB(248, 113, 113),
}

local hudGui
if Stealth and type(Stealth.NewScreenGui) == "function" then
    hudGui = Stealth.NewScreenGui({ DisplayOrder = 40, IgnoreGuiInset = true })
else
    hudGui = Instance.new("ScreenGui")
    hudGui.Name = tostring(math.random(1000000, 9999999))
    hudGui.ResetOnSpawn = false
    hudGui.IgnoreGuiInset = true
    hudGui.DisplayOrder = 40
    pcall(function() hudGui.Parent = game:GetService("CoreGui") end)
end
hudGui.ResetOnSpawn = false
hudGui.IgnoreGuiInset = true
hudGui.DisplayOrder = 40
hudGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- // --------------------------------------------------------------------------
-- // POZYCJE HUD — przeciąganie myszą/dotykiem + zapis w sesji
-- // --------------------------------------------------------------------------
local hudConnections = {}

local hudSessionStore
if Stealth and type(Stealth.Store) == "function" then
    local ok, store = pcall(Stealth.Store)
    if ok and type(store) == "table" then
        hudSessionStore = store
    end
end

local function hudViewportSize()
    local cam = Workspace and Workspace.CurrentCamera
    local size = cam and cam.ViewportSize
    if size and size.X and size.Y and size.X > 0 and size.Y > 0 then
        return size
    end
    return Vector2.new(1280, 720)
end

local function saveHudPosition(key, frame)
    if not hudSessionStore then return end
    hudSessionStore.hud = hudSessionStore.hud or {}
    hudSessionStore.hud[key] = {
        x = frame.Position.X.Offset,
        y = frame.Position.Y.Offset,
    }
end

local function loadHudPosition(key)
    if not hudSessionStore or type(hudSessionStore.hud) ~= "table" then return nil end
    local pos = hudSessionStore.hud[key]
    if type(pos) == "table" and type(pos.x) == "number" and type(pos.y) == "number" then
        return pos
    end
    return nil
end

-- // Wiąże przeciąganie z ramką i zwraca funkcję dla jej dzieci (wpisy, etykiety).
local function createHudDrag(frame, key)
    local dragging = false
    local startMouseX, startMouseY = 0, 0
    local startAbsX, startAbsY = 0, 0

    local function isDragInput(input)
        local t = input and input.UserInputType
        return t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch
    end

    local function begin(input)
        if dragging or not isDragInput(input) then return end
        local mouse = UserInputService:GetMouseLocation()
        dragging = true
        startMouseX, startMouseY = mouse.X, mouse.Y
        startAbsX, startAbsY = frame.AbsolutePosition.X, frame.AbsolutePosition.Y
    end

    frame.InputBegan:Connect(begin)

    table.insert(hudConnections, UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        local t = input and input.UserInputType
        if t ~= Enum.UserInputType.MouseMovement and t ~= Enum.UserInputType.Touch then return end

        local mouse = UserInputService:GetMouseLocation()
        local viewport = hudViewportSize()
        local size = frame.AbsoluteSize
        local anchor = frame.AnchorPoint
        local width = math.max(size.X, 0)
        local height = math.max(size.Y, 0)

        local topX = math.clamp(startAbsX + (mouse.X - startMouseX), 0, math.max(viewport.X - width, 0))
        local topY = math.clamp(startAbsY + (mouse.Y - startMouseY), 0, math.max(viewport.Y - height, 0))

        frame.Position = UDim2.fromOffset(topX + anchor.X * width, topY + anchor.Y * height)
    end))

    table.insert(hudConnections, UserInputService.InputEnded:Connect(function(input)
        if not dragging or not isDragInput(input) then return end
        dragging = false
        saveHudPosition(key, frame)
    end))

    local saved = loadHudPosition(key)
    if saved then
        frame.Position = UDim2.fromOffset(saved.x, saved.y)
    end

    -- // Dla dzieci (wpisy arraylisty, etykieta/kropka toastu): podpinamy ten sam drag.
    return function(target)
        if target and target.InputBegan then
            target.InputBegan:Connect(begin)
        end
    end
end

-- Arraylist: prawy górny róg, tylko włączone moduły.
local arrayList = Instance.new("Frame")
arrayList.Name = "HUD_ArrayList"
arrayList.AnchorPoint = Vector2.new(1, 0)
arrayList.Position = UDim2.new(1, -16, 0, 16)
arrayList.AutomaticSize = Enum.AutomaticSize.XY
arrayList.BackgroundTransparency = 1
arrayList.BorderSizePixel = 0
arrayList.Visible = false
arrayList.Parent = hudGui

local dragArrayList = createHudDrag(arrayList, "list")

local arrayLayout = Instance.new("UIListLayout", arrayList)
arrayLayout.Padding = UDim.new(0, 4)
arrayLayout.SortOrder = Enum.SortOrder.LayoutOrder
arrayLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
arrayLayout.VerticalAlignment = Enum.VerticalAlignment.Top

local arrayEntries = {}
local arrayOrder = {}
local arrayActive = {}

local function refreshArrayList()
    for name, entry in pairs(arrayEntries) do
        if not arrayActive[name] then
            entry:Destroy()
            arrayEntries[name] = nil
        end
    end

    for index, name in ipairs(arrayOrder) do
        local entry = arrayEntries[name]
        if not entry then
            entry = Instance.new("TextLabel")
            entry.Name = "HUD_Entry"
            entry.BackgroundColor3 = hudCfg.listBg
            entry.BackgroundTransparency = 0.22
            entry.BorderSizePixel = 0
            entry.Size = UDim2.new(0, 0, 0, 22)
            entry.AutomaticSize = Enum.AutomaticSize.X
            entry.Font = Enum.Font.GothamBold
            entry.TextSize = 11
            entry.TextColor3 = hudCfg.listText
            entry.TextXAlignment = Enum.TextXAlignment.Right
            entry.Parent = arrayList

            local corner = Instance.new("UICorner", entry)
            corner.CornerRadius = UDim.new(0, 6)

            local padding = Instance.new("UIPadding", entry)
            padding.PaddingLeft = UDim.new(0, 8)
            padding.PaddingRight = UDim.new(0, 8)

            local entryStroke = Instance.new("UIStroke", entry)
            entryStroke.Thickness = 1
            entryStroke.Color = hudCfg.listAccent
            entryStroke.Transparency = 0.45

            dragArrayList(entry)
            arrayEntries[name] = entry
        end
        entry.Text = tostring(name)
        entry.LayoutOrder = index
        entry.Visible = true
    end

    arrayList.Visible = hudCfg.list and #arrayOrder > 0
end

-- // Odświeża kolory istniejących wpisów arraylisty po zmianie w Settings.
local function applyListColors()
    for _, entry in pairs(arrayEntries) do
        entry.BackgroundColor3 = hudCfg.listBg
        entry.TextColor3 = hudCfg.listText
        local entryStroke = entry:FindFirstChildOfClass("UIStroke")
        if entryStroke then
            entryStroke.Color = hudCfg.listAccent
        end
    end
end

-- Toggle info: krótki komunikat na dole ekranu.
local infoToast = Instance.new("Frame")
infoToast.Name = "HUD_ToggleInfo"
infoToast.AnchorPoint = Vector2.new(0.5, 1)
infoToast.Position = UDim2.new(0.5, 0, 1, -96)
infoToast.Size = UDim2.fromOffset(140, 30)
infoToast.BackgroundColor3 = Color3.fromRGB(15, 17, 26)
infoToast.BackgroundTransparency = 0.15
infoToast.BorderSizePixel = 0
infoToast.Visible = false
infoToast.Parent = hudGui

local dragInfo = createHudDrag(infoToast, "info")

local infoCorner = Instance.new("UICorner", infoToast)
infoCorner.CornerRadius = UDim.new(0, 10)

local infoStroke = Instance.new("UIStroke", infoToast)
infoStroke.Thickness = 1
infoStroke.Color = Color3.fromRGB(52, 211, 153)
infoStroke.Transparency = 0.2

local infoDot = Instance.new("Frame", infoToast)
infoDot.Name = "Dot"
infoDot.Size = UDim2.fromOffset(7, 7)
infoDot.Position = UDim2.new(0, 12, 0.5, 0)
infoDot.AnchorPoint = Vector2.new(0, 0.5)
infoDot.BackgroundColor3 = Color3.fromRGB(52, 211, 153)
infoDot.BorderSizePixel = 0
Instance.new("UICorner", infoDot).CornerRadius = UDim.new(1, 0)

local infoLabel = Instance.new("TextLabel", infoToast)
infoLabel.Name = "Label"
infoLabel.BackgroundTransparency = 1
infoLabel.Position = UDim2.new(0, 28, 0, 0)
infoLabel.Size = UDim2.new(1, -40, 1, 0)
infoLabel.Font = Enum.Font.GothamBold
infoLabel.TextSize = 12
infoLabel.TextColor3 = hudCfg.infoOn
infoLabel.TextXAlignment = Enum.TextXAlignment.Left
infoLabel.Text = ""

dragInfo(infoLabel)
dragInfo(infoDot)

local infoToken = 0
local infoMode = "on"

local function applyInfoColor(color)
    infoLabel.TextColor3 = color
    infoDot.BackgroundColor3 = color
    infoStroke.Color = color
end

-- // Odświeża kolor widocznego komunikatu po zmianie w Settings.
local function refreshInfoColors()
    if not infoToast.Visible then return end
    if infoMode == "preview" then
        applyInfoColor(hudCfg.listAccent)
    elseif infoMode == "off" then
        applyInfoColor(hudCfg.infoOff)
    else
        applyInfoColor(hudCfg.infoOn)
    end
end

local function showToggleInfo(name, state)
    if not hudCfg.info or not hudGui or not hudGui.Parent then return end

    local color = state and hudCfg.infoOn or hudCfg.infoOff
    local text = tostring(name) .. (state and "  ON" or "  OFF")

    infoToken = infoToken + 1
    local token = infoToken
    infoMode = state and "on" or "off"

    infoLabel.Text = text
    infoLabel.TextColor3 = color
    infoLabel.TextTransparency = 0
    infoDot.BackgroundColor3 = color
    infoStroke.Color = color
    infoToast.Size = UDim2.fromOffset(math.max(110, 58 + #text * 7), 30)
    infoToast.BackgroundTransparency = 0.15
    infoToast.Visible = true

    task.delay(1.3, function()
        if token ~= infoToken or not infoToast.Parent then return end
        local tween = TweenService:Create(infoToast, TweenInfo.new(0.25), { BackgroundTransparency = 1 })
        TweenService:Create(infoLabel, TweenInfo.new(0.25), { TextTransparency = 1 }):Play()
        TweenService:Create(infoStroke, TweenInfo.new(0.25), { Transparency = 1 }):Play()
        tween.Completed:Connect(function()
            if token == infoToken then
                infoToast.Visible = false
            end
        end)
        tween:Play()
    end)
end

local function hudSetModule(name, state)
    name = tostring(name)
    if state then
        if not arrayActive[name] then
            arrayActive[name] = true
            table.insert(arrayOrder, name)
        end
    else
        arrayActive[name] = nil
        for i, activeName in ipairs(arrayOrder) do
            if activeName == name then
                table.remove(arrayOrder, i)
                break
            end
        end
    end

    refreshArrayList()
    showToggleInfo(name, state)
end

-- // Podgląd HUD do ustawiania pozycji — pokazuje toggle info na 8 s,
-- // żeby można go było przeciągnąć w dowolne miejsce ekranu.
local function previewHudPosition()
    if not hudGui or not hudGui.Parent then return end

    infoToken = infoToken + 1
    local token = infoToken
    infoMode = "preview"

    infoLabel.Text = "Toggle Info — przeciągnij"
    infoLabel.TextColor3 = hudCfg.listAccent
    infoLabel.TextTransparency = 0
    infoDot.BackgroundColor3 = hudCfg.listAccent
    infoStroke.Color = hudCfg.listAccent
    infoStroke.Transparency = 0.2
    infoToast.BackgroundTransparency = 0.15
    infoToast.Size = UDim2.fromOffset(220, 30)
    infoToast.Visible = true

    task.delay(8, function()
        if token == infoToken and infoToast.Parent then
            infoToast.Visible = false
        end
    end)
end

-- // Przywraca domyślne pozycje HUD i czyści zapis w sesji.
local function resetHudPositions()
    if hudSessionStore then
        hudSessionStore.hud = nil
    end
    arrayList.Position = UDim2.new(1, -16, 0, 16)
    infoToast.Position = UDim2.new(0.5, 0, 1, -96)
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
    Callback    = function(state) espCfg.enabled = state; hudSetModule("ESP", state) end,
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
    Callback    = function(state) tracerCfg.enabled = state; hudSetModule("Tracers", state) end,
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
    Callback    = function(state) nameCfg.enabled = state; hudSetModule("Nametag", state) end,
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
    Callback    = function(state) headCfg.enabled = state; hudSetModule("Head ESP", state) end,
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

-- Histereza celu: nie przeskakuj między graczami, gdy są blisko siebie.
local lockedTarget = nil

local AIM_DEADZONE = 6 -- px od środka ekranu: tu aimbot nie rusza myszą

-- Adaptacyjne tłumienie: gdy krok zaczyna oscylować, zmniejszamy gain.
local aimGainScale = 1
local lastDirX, lastDirY = 0, 0
local lastAimPlayer = nil

local function roundStep(value)
    if value >= 0 then return math.floor(value + 0.5) end
    return math.ceil(value - 0.5)
end

-- Zwraca offset celu od środka ekranu (px). Liczymy od środka viewportu,
-- a nie od pozycji kursora — w Roblox kursor jest zablokowany i jego
-- współrzędne nie odzwierciedlają obrotu kamery (to powodowało celowanie w nogi).
local function aimOffsetOf(camera, viewport, player)
    local _, hum, hrp, headPart = getCharacterParts(player)
    if not (hum and hum.Health > 0 and hrp) then return nil end

    local part = (aimCfg.target == "Body" and hrp) or headPart or hrp
    if not part then return nil end

    local screenPos, onScreen = camera:WorldToViewportPoint(part.Position)
    if not onScreen or not screenPos.Z or screenPos.Z <= 0 then return nil end

    local dx = screenPos.X - viewport.X / 2
    local dy = screenPos.Y - viewport.Y / 2
    return dx, dy, math.sqrt(dx * dx + dy * dy)
end

local function findAimTarget(camera, viewport)
    local radius = math.max(fovCfg.radius or 160, 1)
    local bestPlayer, bestDx, bestDy, bestDist = nil, nil, nil, radius

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local dx, dy, dist = aimOffsetOf(camera, viewport, player)
            if dx and dist <= radius and dist < bestDist then
                bestPlayer, bestDx, bestDy, bestDist = player, dx, dy, dist
            end
        end
    end

    -- Histereza: trzymaj poprzedni cel, jeśli nadal jest w FOV i nieznacznie dalej.
    if lockedTarget and lockedTarget ~= bestPlayer and lockedTarget.Parent then
        local dx, dy, dist = aimOffsetOf(camera, viewport, lockedTarget)
        if dx and dist <= radius and dist <= bestDist * 1.25 then
            return dx, dy, dist, lockedTarget
        end
    end

    lockedTarget = bestPlayer
    return bestDx, bestDy, bestDist, bestPlayer
end

local function updateAimbot()
    if not aimCfg.enabled or not aimCfg.active then return end
    if type(mousemoverel) ~= "function" then return end

    local camera = Workspace.CurrentCamera
    if not camera then return end
    local viewport = camera.ViewportSize
    if not viewport then return end

    local dx, dy, dist, targetPlayer = findAimTarget(camera, viewport)
    if not dx then
        lastAimPlayer = nil
        return
    end

    -- Martwa strefa — celownik jest już na celu, nie ruszamy myszą.
    if dist <= AIM_DEADZONE then return end

    -- Gdy kierunek nagle się odwraca (przestrzelenie), tłumimy krok.
    local dirX = dx > 0 and 1 or (dx < 0 and -1 or 0)
    local dirY = dy > 0 and 1 or (dy < 0 and -1 or 0)
    if targetPlayer == lastAimPlayer then
        local flipped = (dirX ~= 0 and lastDirX ~= 0 and dirX ~= lastDirX)
            or (dirY ~= 0 and lastDirY ~= 0 and dirY ~= lastDirY)
        if flipped then
            aimGainScale = math.max(0.15, aimGainScale * 0.6)
        else
            aimGainScale = math.min(1, aimGainScale + (1 - aimGainScale) * 0.05)
        end
    else
        aimGainScale = 1
    end
    lastDirX, lastDirY, lastAimPlayer = dirX, dirY, targetPlayer

    -- Czułość: ułamek odległości pokonywany w klatce (< 1 => zawsze zbieżny).
    local sensitivity = math.clamp(aimCfg.sensitivity, 1, 100) / 100
    local intensity   = math.clamp(aimCfg.intensity, 1, 100) / 100

    local gain = (0.06 + sensitivity * 0.34) * (0.5 + intensity * 0.5) * aimGainScale
    gain = math.clamp(gain, 0.01, 0.45)

    local stepX = dx * gain
    local stepY = dy * gain

    -- Limit kroku na klatkę — im niżej, tym subtelniej i trudniej do wykrycia.
    local maxStep = 2 + intensity * 14 -- 2 .. 16 px
    local stepDist = math.sqrt(stepX * stepX + stepY * stepY)
    if stepDist > maxStep then
        local k = maxStep / stepDist
        stepX, stepY = stepX * k, stepY * k
    end

    if aimCfg.jitter then
        -- Powolne, płynne mikro-drgania imitujące rękę.
        local t = tick()
        stepX = stepX + math.sin(t * 2.4) * 0.5
        stepY = stepY + math.sin(t * 3.7 + 1.3) * 0.5
    end

    -- Zaokrąglenie do pikseli, ale poza martwą strefą nigdy nie zero
    -- (inaczej przy niskiej czułości aimbot stanąłby w miejscu).
    local moveX = roundStep(stepX)
    local moveY = roundStep(stepY)
    if moveX == 0 and math.abs(stepX) > 0.05 then moveX = stepX > 0 and 1 or -1 end
    if moveY == 0 and math.abs(stepY) > 0.05 then moveY = stepY > 0 and 1 or -1 end
    if moveX == 0 and moveY == 0 then return end

    mousemoverel(moveX, moveY)
end

local AimbotModule = CombatTab:CreateModule({
    Name        = "Aimbot",
    Description = "Namierzanie graczy pod bindem",
    Icon        = "crosshair",
    Callback    = function(state)
        aimCfg.enabled = state
        if not state then
            aimCfg.active = false
        end
        hudSetModule("Aimbot", state)
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
    Callback    = function(state) fovCfg.enabled = state; hudSetModule("FOV", state) end,
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
        hudSetModule("WalkSpeed", state)
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

SettingsTab:CreateToggle({
    Name     = "Toggle Info",
    Flag     = "Universal_HUD_Info",
    Default  = true,
    Callback = function(state)
        hudCfg.info = state
        if not state then infoToast.Visible = false end
    end,
})

SettingsTab:CreateToggle({
    Name     = "Arraylist",
    Flag     = "Universal_HUD_List",
    Default  = true,
    Callback = function(state)
        hudCfg.list = state
        refreshArrayList()
    end,
})

SettingsTab:CreateColorPicker({
    Name     = "Kolor arraylisty",
    Flag     = "Universal_HUD_ListAccent",
    Default  = hudCfg.listAccent,
    Callback = function(color)
        hudCfg.listAccent = color
        applyListColors()
        refreshInfoColors()
    end,
})

SettingsTab:CreateColorPicker({
    Name     = "Kolor tekstu arraylisty",
    Flag     = "Universal_HUD_ListText",
    Default  = hudCfg.listText,
    Callback = function(color)
        hudCfg.listText = color
        applyListColors()
    end,
})

SettingsTab:CreateColorPicker({
    Name     = "Kolor tła arraylisty",
    Flag     = "Universal_HUD_ListBg",
    Default  = hudCfg.listBg,
    Callback = function(color)
        hudCfg.listBg = color
        applyListColors()
    end,
})

SettingsTab:CreateColorPicker({
    Name     = "Toggle Info ON",
    Flag     = "Universal_HUD_InfoOn",
    Default  = hudCfg.infoOn,
    Callback = function(color)
        hudCfg.infoOn = color
        refreshInfoColors()
    end,
})

SettingsTab:CreateColorPicker({
    Name     = "Toggle Info OFF",
    Flag     = "Universal_HUD_InfoOff",
    Default  = hudCfg.infoOff,
    Callback = function(color)
        hudCfg.infoOff = color
        refreshInfoColors()
    end,
})

SettingsTab:CreateButton({
    Name     = "Ustaw pozycję HUD",
    Callback = function()
        previewHudPosition()
    end,
})

SettingsTab:CreateButton({
    Name     = "Reset pozycji HUD",
    Callback = function()
        resetHudPositions()
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

-- Losowa nazwa kroku renderowania — bez sygnatury "LuminaqAim".
local AIM_STEP_NAME = (Stealth and type(Stealth.StepName) == "function" and Stealth.StepName())
    or ("r" .. tostring(math.random(100000, 999999)))

-- Aimbot porusza myszą w RenderStepie (po kamerze, ale bez jej blokowania).
RunService:BindToRenderStep(AIM_STEP_NAME, Enum.RenderPriority.Camera.Value + 1, updateAimbot)

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
    pcall(function() RunService:UnbindFromRenderStep(AIM_STEP_NAME) end)
    pcall(function() playerRemovingConnection:Disconnect() end)

    for player in pairs(visualCache) do
        destroyPlayerVisuals(player)
    end

    pcall(function() overlayGui:Destroy() end)
    pcall(function() hudGui:Destroy() end)
    for _, connection in ipairs(hudConnections) do
        pcall(function() connection:Disconnect() end)
    end
    table.clear(hudConnections)

    local hum = getLocalHumanoid()
    if hum then
        pcall(function() hum.WalkSpeed = speedCfg.baseWalk or 16 end)
    end
end

Window:OnCleanup(cleanupAll)
