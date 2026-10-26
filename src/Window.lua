local Window = {}

-- Serwisy
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local CoreGui          = game:GetService("CoreGui")
local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")

-- // SYSTEM BEZPIECZNEGO POBIERANIA (używany do ładowania modułów wewnętrznych)
local baseUrl = "https://raw.githubusercontent.com/XxvoltikxX/MenuTest/refs/heads/main/src/"

local function safeHttpGet(url, maxRetries, retryDelay)
    maxRetries = maxRetries or 3
    retryDelay = retryDelay or 0.5
    for attempt = 1, maxRetries do
        local ok, result = pcall(function()
            return game:HttpGet(url)
        end)
        if ok and type(result) == "string" and #result > 0 then
            return true, result
        end
        warn(string.format("[Window] Próba %d/%d nie powiodła się: %s", attempt, maxRetries, tostring(url)))
        if attempt < maxRetries then task.wait(retryDelay) end
    end
    return false, nil
end

local function safeLoadUrl(url, fallbackValue)
    local ok, content = false, nil
    local isDev = (typeof(getgenv) == "function" and getgenv()._MenuTestDevMode == true)
    if isDev and typeof(readfile) == "function" then
        local localRel = url:gsub("^https://raw%.githubusercontent%.com/[^/]+/[^/]+/refs/heads/[^/]+/src/", "")
        local candidates = {
            "MenuTest/src/" .. localRel,
            "src/" .. localRel,
            localRel
        }
        for _, c in ipairs(candidates) do
            if typeof(isfile) == "function" and isfile(c) then
                local s, data = pcall(readfile, c)
                if s and data and type(data) == "string" and #data > 0 then
                    ok, content = true, data
                    break
                end
            end
        end
    end
    if not ok or not content then
        ok, content = safeHttpGet(url)
    end
    if not ok or not content then
        warn("[Window] Nie udało się pobrać: " .. tostring(url))
        return fallbackValue
    end
    local chunk, compileErr = loadstring(content)
    if not chunk then
        warn("[Window] Błąd kompilacji " .. tostring(url) .. ": " .. tostring(compileErr))
        return fallbackValue
    end
    local runOk, result = pcall(chunk)
    if not runOk then
        warn("[Window] Błąd wykonania " .. tostring(url) .. ": " .. tostring(result))
        return fallbackValue
    end
    return result
end

-- // FALLBACKI DLA MODUŁÓW WEWNĘTRZNYCH
local IconsFallback = {
    Apply = function(self, imageLabel, iconName) end
}
local InteractionsFallback = {
    MakeDraggable  = function(self, handle, target) end,
    MakeResizable  = function(self, handle, target, minW, minH) end,
}
local SidebarFallback = {
    Create = function(self, UI, theme, config)
        local SidebarFrame = Instance.new("Frame")
        SidebarFrame.Name = "Sidebar"
        SidebarFrame.Size = UDim2.new(0, 200, 1, -32)
        SidebarFrame.Position = UDim2.new(0, 0, 0, 32)
        SidebarFrame.BackgroundTransparency = 1

        local TabList = Instance.new("ScrollingFrame")
        TabList.Name = "TabList"
        TabList.Size = UDim2.new(1, 0, 1, -46)
        TabList.Position = UDim2.new(0, 0, 0, 46)
        TabList.BackgroundTransparency = 1
        TabList.BorderSizePixel = 0
        TabList.CanvasSize = UDim2.new(0, 0, 0, 0)
        TabList.AutomaticCanvasSize = Enum.AutomaticSize.Y
        TabList.ScrollBarThickness = 2
        TabList.Parent = SidebarFrame

        local Layout = Instance.new("UIListLayout")
        Layout.SortOrder = Enum.SortOrder.LayoutOrder
        Layout.Parent = TabList

        return SidebarFrame, TabList
    end
}

-- Ładowanie modułów z fallbackami
local Icons = safeLoadUrl(baseUrl .. "Icons.lua", IconsFallback)

local Interactions = safeLoadUrl(baseUrl .. "Interactions.lua", InteractionsFallback)
local SidebarModule= safeLoadUrl(baseUrl .. "Sidebar.lua",      SidebarFallback)

-- // ============================================================
-- // Window:Create
-- // ============================================================
function Window:Create(config)
    config = config or {}
    if config.Name then
        local rawName = tostring(config.Name)
        config.Name = #rawName > 16 and string.sub(rawName, 1, 16) or rawName
    end

    local UI = {}
    UI.Icons      = Icons
    UI.Tabs       = {}
    UI.Pages      = {}
    UI.TabObjects = {}      -- { Button, Page, LayoutOrder }
    UI.SelectedTab = nil
    UI.MenuConfig     = config.MenuConfig
    UI.SaveMenuConfig = config.SaveMenuConfig
    UI.GameId         = tostring(config.GameId or "109949693269081")

    -- // THEME MANAGER
    local ThemeManager = { Elements = {}, CurrentTheme = config.Theme or {}, _callbacks = {} }

    local function getColor(t)
        if not t then return Color3.fromRGB(255, 0, 255) end
        return Color3.fromRGB(unpack(t))
    end

    function ThemeManager:GetColor(colorName)
        if self.CurrentTheme and self.CurrentTheme[colorName] then
            return getColor(self.CurrentTheme[colorName])
        end
        return Color3.fromRGB(255, 255, 255)
    end

    function ThemeManager:OnThemeChanged(cb)
        if type(cb) == "function" then
            table.insert(self._callbacks, cb)
        end
    end

    function ThemeManager:Register(element, property, colorName)
        table.insert(self.Elements, {Element = element, Property = property, ColorName = colorName})
        if self.CurrentTheme and self.CurrentTheme[colorName] then
            pcall(function()
                element[property] = getColor(self.CurrentTheme[colorName])
            end)
        end
    end

    function ThemeManager:Apply(newTheme)
        self.CurrentTheme = newTheme
        local valid = {}
        for _, item in pairs(self.Elements) do
            if item.Element and item.Element.Parent then
                table.insert(valid, item)
                if self.CurrentTheme and self.CurrentTheme[item.ColorName] then
                    pcall(function()
                        TweenService:Create(item.Element, TweenInfo.new(0.25),
                            {[item.Property] = getColor(self.CurrentTheme[item.ColorName])}):Play()
                    end)
                end
            end
        end
        self.Elements = valid

        if UI.SelectedTab then
            local activeIcon = UI.SelectedTab:FindFirstChild("Icon")
            local activeLabel = UI.SelectedTab:FindFirstChild("Label")
            if activeIcon and self.CurrentTheme and self.CurrentTheme.Text then
                pcall(function()
                    TweenService:Create(activeIcon, TweenInfo.new(0.25),
                        {ImageColor3 = getColor(self.CurrentTheme.Text)}):Play()
                end)
            end
            if activeLabel and self.CurrentTheme and self.CurrentTheme.Text then
                pcall(function()
                    TweenService:Create(activeLabel, TweenInfo.new(0.25),
                        {TextColor3 = getColor(self.CurrentTheme.Text)}):Play()
                end)
            end
        end

        for _, cb in ipairs(self._callbacks) do
            pcall(cb, newTheme)
        end
    end
    UI.ThemeManager = ThemeManager

    -- // USTAWIENIA EKRANU (Wykrywanie urządzeń mobilnych / dotykowych)
    local camera = Workspace.CurrentCamera or Workspace:FindFirstChildOfClass("Camera")
    local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
    if viewport.X <= 50 or viewport.Y <= 50 then
        viewport = Vector2.new(1280, 720)
    end

    local isMobile = (config and (config.TestMobile or config.Mobile or config.IsMobile))
        or (UserInputService.TouchEnabled and not UserInputService.MouseEnabled)
        or (UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled)
        or (UserInputService.TouchEnabled and (viewport.X < 950 or viewport.Y < 550))
    local isTouch = UserInputService.TouchEnabled or isMobile
    UI.IsMobile = isMobile
    UI.IsTouch = isTouch

    local ProtectedLocation
    pcall(function() ProtectedLocation = CoreGui end)
    if not ProtectedLocation then
        ProtectedLocation = Players.LocalPlayer:WaitForChild("PlayerGui")
    end

    -- Usunięcie istniejącego ScreenGui przed stworzeniem nowego
    if typeof(getgenv) == "function" and getgenv()._MenuTestGui then
        pcall(function() getgenv()._MenuTestGui:Destroy() end)
        getgenv()._MenuTestGui = nil
    end

    local searchContainers = {}
    pcall(function() table.insert(searchContainers, CoreGui) end)
    pcall(function()
        local lp = Players.LocalPlayer
        if lp and lp:FindFirstChild("PlayerGui") then
            table.insert(searchContainers, lp.PlayerGui)
        end
    end)

    for _, container in ipairs(searchContainers) do
        if container then
            for _, child in ipairs(container:GetChildren()) do
                if child:IsA("ScreenGui") and not child:GetAttribute("MenuLoaderIndicator") then
                    if child:GetAttribute(config.MenuId or "MenuInstance")
                        or child:GetAttribute("MenuInstance")
                        or child.Name == "MenuScreen"
                        or child:FindFirstChild("MainFrame") then
                        pcall(function() child:Destroy() end)
                    end
                end
            end
        end
    end

    -- ScreenGui
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = config.GenerateID and config.GenerateID() or "MenuScreen"
    ScreenGui:SetAttribute(config.MenuId or "MenuInstance", true)
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.DisplayOrder = 10
    ScreenGui.Parent = ProtectedLocation
    UI.ScreenGui = ScreenGui

    if typeof(getgenv) == "function" then
        getgenv()._MenuTestGui = ScreenGui
    end

    -- Dynamiczny rozmiar początkowy dopasowany do ekranu
    local defaultW = 700
    local defaultH = 400
    if isMobile then
        -- Na urządzeniach mobilnych zgrabny, kompaktowy rozmiar z wygodnymi marginesami dookoła
        defaultW = math.clamp(math.floor(viewport.X * 0.72), 340, 500)
        defaultH = math.clamp(math.floor(viewport.Y * 0.74), 230, 310)
    elseif viewport.X < 750 or viewport.Y < 450 then
        defaultW = math.clamp(math.floor(viewport.X * 0.88), 360, 600)
        defaultH = math.clamp(math.floor(viewport.Y * 0.84), 250, 360)
    end

    -- Cień
    local Shadow = Instance.new("ImageLabel")
    Shadow.Name = "Shadow"
    Shadow.BackgroundTransparency = 1
    Shadow.ZIndex = 0
    Shadow.Image = "rbxassetid://10385930982"
    Shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    Shadow.ImageTransparency = 0.5
    Shadow.ScaleType = Enum.ScaleType.Slice
    Shadow.SliceCenter = Rect.new(49, 49, 50, 50)
    Shadow.Parent = ScreenGui
    UI.Shadow = Shadow

    -- MainFrame
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, defaultW, 0, defaultH)
    MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    MainFrame.BorderSizePixel = 0
    MainFrame.ClipsDescendants = true
    MainFrame.ZIndex = 1
    MainFrame.Parent = ScreenGui
    UI.MainFrame = MainFrame
    ThemeManager:Register(MainFrame, "BackgroundColor3", "Main")

    Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)
    local MainStroke = Instance.new("UIStroke", MainFrame)
    MainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    MainStroke.Thickness = 1.6
    ThemeManager:Register(MainStroke, "Color", "Accent")

    -- // ============================================================
    -- // ANIMATED BACKGROUND & LIVE THEME GIF ENGINE
    -- // ============================================================
    local BackgroundContainer = Instance.new("Frame")
    BackgroundContainer.Name = "AnimatedBackground"
    BackgroundContainer.Size = UDim2.new(1, 0, 1, 0)
    BackgroundContainer.Position = UDim2.new(0, 0, 0, 0)
    BackgroundContainer.BackgroundTransparency = 1
    BackgroundContainer.ClipsDescendants = true
    BackgroundContainer.ZIndex = 1
    BackgroundContainer.Parent = MainFrame
    UI.BackgroundContainer = BackgroundContainer

    local WaveLayer = Instance.new("Frame")
    WaveLayer.Name = "WaveLayer"
    WaveLayer.Size = UDim2.new(1.6, 0, 1.6, 0)
    WaveLayer.Position = UDim2.new(0.5, 0, 0.5, 0)
    WaveLayer.AnchorPoint = Vector2.new(0.5, 0.5)
    WaveLayer.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    WaveLayer.BackgroundTransparency = 0.90
    WaveLayer.BorderSizePixel = 0
    WaveLayer.ZIndex = 1
    WaveLayer.Parent = BackgroundContainer

    local WaveGradient = Instance.new("UIGradient", WaveLayer)
    WaveGradient.Rotation = 45

    local GifImageLayer = Instance.new("ImageLabel")
    GifImageLayer.Name = "GifImageLayer"
    GifImageLayer.Size = UDim2.new(1, 0, 1, 0)
    GifImageLayer.BackgroundTransparency = 1
    GifImageLayer.ImageTransparency = 0.88
    GifImageLayer.ScaleType = Enum.ScaleType.Crop
    GifImageLayer.Visible = false
    GifImageLayer.ZIndex = 1
    GifImageLayer.Parent = BackgroundContainer

    local animPresets = {
        ["Aurora"] = {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0.0, Color3.fromRGB(0, 240, 150)),
                ColorSequenceKeypoint.new(0.35, Color3.fromRGB(0, 180, 255)),
                ColorSequenceKeypoint.new(0.7, Color3.fromRGB(130, 40, 240)),
                ColorSequenceKeypoint.new(1.0, Color3.fromRGB(0, 20, 60))
            }),
            DefaultTransparency = 0.90
        },
        ["Cyberpunk"] = {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0.0, Color3.fromRGB(255, 0, 128)),
                ColorSequenceKeypoint.new(0.4, Color3.fromRGB(120, 0, 255)),
                ColorSequenceKeypoint.new(0.75, Color3.fromRGB(0, 240, 255)),
                ColorSequenceKeypoint.new(1.0, Color3.fromRGB(20, 10, 40))
            }),
            DefaultTransparency = 0.88
        },
        ["Cosmic"] = {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0.0, Color3.fromRGB(150, 60, 255)),
                ColorSequenceKeypoint.new(0.45, Color3.fromRGB(70, 40, 180)),
                ColorSequenceKeypoint.new(0.8, Color3.fromRGB(20, 80, 200)),
                ColorSequenceKeypoint.new(1.0, Color3.fromRGB(10, 12, 30))
            }),
            DefaultTransparency = 0.90
        },
        ["Sunset"] = {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0.0, Color3.fromRGB(255, 80, 60)),
                ColorSequenceKeypoint.new(0.35, Color3.fromRGB(255, 160, 40)),
                ColorSequenceKeypoint.new(0.7, Color3.fromRGB(180, 40, 100)),
                ColorSequenceKeypoint.new(1.0, Color3.fromRGB(30, 15, 25))
            }),
            DefaultTransparency = 0.90
        },
        ["Emerald"] = {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0.0, Color3.fromRGB(0, 255, 120)),
                ColorSequenceKeypoint.new(0.4, Color3.fromRGB(0, 180, 80)),
                ColorSequenceKeypoint.new(0.75, Color3.fromRGB(10, 80, 50)),
                ColorSequenceKeypoint.new(1.0, Color3.fromRGB(5, 20, 12))
            }),
            DefaultTransparency = 0.90
        },
        ["None"] = {
            Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 255, 255)),
            DefaultTransparency = 1.0
        }
    }

    local currentAnimMode = (config and config.AnimatedTheme) or "Aurora"
    local animSpeed = 0.5
    local animIntensity = 0.12

    local function applyAnimPreset(mode)
        local p = animPresets[mode] or animPresets["Aurora"]
        WaveGradient.Color = p.Color
        if mode == "None" then
            WaveLayer.Visible = false
        else
            WaveLayer.Visible = true
            WaveLayer.BackgroundTransparency = 1 - animIntensity
        end
    end

    applyAnimPreset(currentAnimMode)

    local animHeartbeat
    animHeartbeat = RunService.Heartbeat:Connect(function()
        if not MainFrame or not MainFrame.Parent then
            if animHeartbeat then animHeartbeat:Disconnect() end
            return
        end
        if currentAnimMode == "None" or not WaveLayer.Visible then return end
        local t = tick() * animSpeed
        WaveGradient.Offset = Vector2.new(math.sin(t * 0.4) * 0.22, math.cos(t * 0.3) * 0.22)
        WaveGradient.Rotation = (45 + math.sin(t * 0.25) * 25) % 360
    end)

    function UI:SetAnimatedTheme(mode, intensity, speed)
        if mode and animPresets[mode] then
            currentAnimMode = mode
        end
        if intensity then
            animIntensity = math.clamp(tonumber(intensity) or 0.12, 0.02, 0.35)
        end
        if speed then
            animSpeed = math.clamp(tonumber(speed) or 0.5, 0.1, 2.5)
        end
        applyAnimPreset(currentAnimMode)
        if UI.SaveMenuConfig then
            pcall(function()
                UI.SaveMenuConfig("AnimatedTheme", currentAnimMode)
                UI.SaveMenuConfig("AnimatedThemeIntensity", animIntensity)
                UI.SaveMenuConfig("AnimatedThemeSpeed", animSpeed)
            end)
        end
    end

    function UI:SetGifBackground(assetId, transparency)
        if assetId and assetId ~= "" then
            GifImageLayer.Image = assetId
            GifImageLayer.ImageTransparency = transparency or 0.88
            GifImageLayer.Visible = true
        else
            GifImageLayer.Visible = false
        end
    end

    -- TopBar
    local TopBar = Instance.new("Frame")
    TopBar.Name = "TopBar"
    TopBar.Size = UDim2.new(1, 0, 0, 32)
    TopBar.BackgroundTransparency = 1
    TopBar.ZIndex = 5
    TopBar.Parent = MainFrame
    UI.TopBar = TopBar

    if config.Tittle and config.Tittle ~= "" then
        local TopTitle = Instance.new("TextLabel")
        TopTitle.Name = "TopTitle"
        TopTitle.Text = config.Tittle
        TopTitle.Font = Enum.Font.GothamMedium
        TopTitle.TextSize = 14
        TopTitle.BackgroundTransparency = 1
        TopTitle.Size = UDim2.new(1, -115, 1, 0)
        TopTitle.Position = UDim2.new(0, 10, 0, 0)
        TopTitle.Parent = TopBar
        ThemeManager:Register(TopTitle, "TextColor3", "Text_Secondary")
        if config.TittlePos == "Center" then
            TopTitle.TextXAlignment = Enum.TextXAlignment.Center
            TopTitle.Position = UDim2.new(0, 0, 0, 0)
            TopTitle.Size = UDim2.new(1, 0, 1, 0)
            TopTitle.ZIndex = 4
        else
            TopTitle.TextXAlignment = Enum.TextXAlignment.Left
        end
    end

    -- Linia pod TopBarem
    local TopLine = Instance.new("Frame")
    TopLine.Size = UDim2.new(1, 0, 0, 1)
    TopLine.Position = UDim2.new(0, 0, 0, 32)
    TopLine.BorderSizePixel = 0
    TopLine.ZIndex = 10
    TopLine.Parent = MainFrame
    ThemeManager:Register(TopLine, "BackgroundColor3", "Accent")

    -- Sidebar (responsywna szerokość dla urządzeń mobilnych)
    local sidebarWidth = (isMobile or viewport.X < 600) and 155 or 200
    local SidebarFrame, TabList = SidebarModule:Create(UI, config.Theme, config, sidebarWidth)
    SidebarFrame.Parent = MainFrame
    UI.TabList = TabList

    -- GlobalIndicator (wskaźnik aktywnej zakładki)
    local GlobalIndicator = Instance.new("Frame")
    GlobalIndicator.Name = "GlobalIndicator"
    GlobalIndicator.Size = UDim2.new(0, 2, 0, 45)
    GlobalIndicator.Position = UDim2.new(0, 0, 0, 46)
    GlobalIndicator.BorderSizePixel = 0
    GlobalIndicator.ZIndex = 20
    GlobalIndicator.Visible = false
    GlobalIndicator.Parent = SidebarFrame
    UI.GlobalIndicator = GlobalIndicator
    ThemeManager:Register(GlobalIndicator, "BackgroundColor3", "Text")

    -- Pionowa linia oddzielająca sidebar
    local VerticalLine = Instance.new("Frame")
    VerticalLine.Size = UDim2.new(0, 1, 1, 0)
    VerticalLine.Position = UDim2.new(1, 0, 0, 0)
    VerticalLine.BorderSizePixel = 0
    VerticalLine.ZIndex = 10
    VerticalLine.Parent = SidebarFrame
    ThemeManager:Register(VerticalLine, "BackgroundColor3", "Accent")

    -- PagesContainer
    local PagesContainer = Instance.new("Frame")
    PagesContainer.Name = "PagesContainer"
    PagesContainer.Size = UDim2.new(1, -sidebarWidth, 1, -32)
    PagesContainer.Position = UDim2.new(0, sidebarWidth, 0, 32)
    PagesContainer.BackgroundTransparency = 1
    PagesContainer.ClipsDescendants = true
    PagesContainer.Parent = MainFrame
    UI.PagesContainer = PagesContainer

    -- Controls (przyciski min/max/close)
    local Controls = Instance.new("Frame")
    Controls.Name = "Controls"
    Controls.Size = UDim2.new(0, 105, 1, 0)
    Controls.Position = UDim2.new(1, -105, 0, 0)
    Controls.BackgroundTransparency = 1
    Controls.ZIndex = 6
    Controls.Parent = TopBar
    UI.Controls = Controls

    local function createIconBtn(iconName, pos)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 35, 1, 0)
        btn.Position = pos
        btn.BackgroundTransparency = 1
        btn.Text = ""
        btn.Parent = Controls

        local iconImg = Instance.new("ImageLabel")
        iconImg.Name = "Icon"
        iconImg.Size = UDim2.new(0, 17, 0, 17)
        iconImg.Position = UDim2.new(0.5, 0, 0.5, 0)
        iconImg.AnchorPoint = Vector2.new(0.5, 0.5)
        iconImg.BackgroundTransparency = 1
        iconImg.Parent = btn
        ThemeManager:Register(iconImg, "ImageColor3", "Text_Secondary")
        Icons:Apply(iconImg, iconName)
        return btn
    end

    UI.MinBtn   = createIconBtn("minus",      UDim2.new(0,  0, 0, 0))
    UI.MaxBtn   = createIconBtn("maximize-2", UDim2.new(0, 35, 0, 0))
    UI.CloseBtn = createIconBtn("x",          UDim2.new(0, 70, 0, 0))

    -- Maximize/restore
    local maximized = false
    local lastSize, lastPos

    UI.MaxBtn.MouseButton1Click:Connect(function()
        if not maximized then
            lastSize = MainFrame.Size
            lastPos  = MainFrame.Position
            pcall(function()
                TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                    Size = UDim2.new(1, -10, 1, -10),
                    Position = UDim2.new(0.5, 0, 0.5, 0)
                }):Play()
            end)
            maximized = true
            Icons:Apply(UI.MaxBtn:FindFirstChild("Icon"), "square")
            if UI.ResizeHandle then UI.ResizeHandle.Visible = false end
        else
            pcall(function()
                TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                    Size = lastSize or UDim2.new(0, defaultW, 0, defaultH),
                    Position = lastPos or UDim2.new(0.5, 0, 0.5, 0)
                }):Play()
            end)
            maximized = false
            Icons:Apply(UI.MaxBtn:FindFirstChild("Icon"), "maximize-2")
            if UI.ResizeHandle then UI.ResizeHandle.Visible = true end
        end
    end)

    -- ResizeHandle (większy na mobilce, żeby łatwo było złapać palcem)
    local handleSize = isMobile and 34 or 25
    local ResizeHandle = Instance.new("TextButton")
    ResizeHandle.Name = "ResizeHandle"
    ResizeHandle.Size = UDim2.new(0, handleSize, 0, handleSize)
    ResizeHandle.Position = UDim2.new(1, -handleSize, 1, -handleSize)
    ResizeHandle.BackgroundTransparency = 1
    ResizeHandle.Text = ""
    ResizeHandle.ZIndex = 10
    ResizeHandle.Parent = MainFrame
    UI.ResizeHandle = ResizeHandle

    local ResizeIcon = Instance.new("ImageLabel")
    ResizeIcon.Name = "Icon"
    ResizeIcon.Size = UDim2.new(0, isMobile and 18 or 15, 0, isMobile and 18 or 15)
    ResizeIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
    ResizeIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    ResizeIcon.BackgroundTransparency = 1
    ResizeIcon.Parent = ResizeHandle
    ThemeManager:Register(ResizeIcon, "ImageColor3", "Accent")
    Icons:Apply(ResizeIcon, "arrow-down-right")

    -- Minimalne wymiary okna (na telefonach można zmniejszyć do 340x230)
    local minW = isMobile and 340 or 440
    local minH = isMobile and 230 or 270
    Interactions:MakeDraggable(TopBar, MainFrame)
    Interactions:MakeResizable(ResizeHandle, MainFrame, minW, minH)

    -- Automatyczne dopasowanie, jeśli gracz obróci ekran telefonu
    if camera then
        camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
            local vp = camera.ViewportSize
            if MainFrame.AbsoluteSize.X > vp.X - 10 or MainFrame.AbsoluteSize.Y > vp.Y - 10 then
                MainFrame.Size = UDim2.new(0, math.clamp(MainFrame.AbsoluteSize.X, minW, vp.X - 16), 0, math.clamp(MainFrame.AbsoluteSize.Y, minH, vp.Y - 16))
            end
        end)
    end

    -- Cień śledzi MainFrame
    Shadow.AnchorPoint = MainFrame.AnchorPoint
    local SHADOW_OFFSET = 35
    RunService.RenderStepped:Connect(function()
        if MainFrame.Visible then
            Shadow.Position = UDim2.new(0,
                MainFrame.AbsolutePosition.X + MainFrame.AbsoluteSize.X / 2,
                0,
                MainFrame.AbsolutePosition.Y + MainFrame.AbsoluteSize.Y / 2)
            Shadow.Size = UDim2.new(0,
                MainFrame.AbsoluteSize.X + SHADOW_OFFSET * 2,
                0,
                MainFrame.AbsoluteSize.Y + SHADOW_OFFSET * 2)
        end
        Shadow.Visible = MainFrame.Visible
    end)

    -- // ============================================================
    -- // ZUNIFIKOWANA LOGIKA TOGGLE MENU DLA PC ORAZ MOBILE
    -- // ============================================================
    local isMenuVisible = true
    local currentToggleTween = nil
    local lastNormalPos = MainFrame.Position
    local HiddenPos = UDim2.new(0, -900, 0.5, 0)

    function UI:ToggleMenu(forceState)
        local target = (forceState ~= nil) and forceState or (not isMenuVisible)
        if target == isMenuVisible and not currentToggleTween then return end

        isMenuVisible = target

        if currentToggleTween then
            currentToggleTween:Cancel()
            currentToggleTween = nil
        end

        if UI.MobileToggleText then
            UI.MobileToggleText.Text = isMenuVisible and "CLOSE" or "OPEN"
            UI.MobileToggleText.TextColor3 = isMenuVisible and Color3.fromRGB(255, 100, 100) or getColor(ThemeManager.CurrentTheme.Success)
        end

        if isMenuVisible then
            MainFrame.Visible = true
            Shadow.Visible = true
            local destPos = (lastNormalPos and lastNormalPos.X.Offset > -100) and lastNormalPos or UDim2.new(0.5, 0, 0.5, 0)
            currentToggleTween = TweenService:Create(MainFrame,
                TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
                {Position = destPos})
            currentToggleTween:Play()
            currentToggleTween.Completed:Connect(function()
                currentToggleTween = nil
            end)
        else
            if MainFrame.Position.X.Offset > -100 then
                lastNormalPos = MainFrame.Position
            end
            currentToggleTween = TweenService:Create(MainFrame,
                TweenInfo.new(0.20, Enum.EasingStyle.Quart, Enum.EasingDirection.In),
                {Position = HiddenPos})
            currentToggleTween:Play()
            currentToggleTween.Completed:Connect(function()
                if not isMenuVisible then
                    MainFrame.Visible = false
                    Shadow.Visible = false
                end
                currentToggleTween = nil
            end)
        end
    end

    -- Mobile toggle (Pływający przycisk otwierania na telefonach/tabletach)
    if isTouch then
        local MobileToggle = Instance.new("TextButton")
        MobileToggle.Name = "MobileToggle"
        MobileToggle.Size = UDim2.new(0, 55, 0, 65)
        MobileToggle.Position = UDim2.new(0, 20, 0.5, -32)
        MobileToggle.BorderSizePixel = 0
        MobileToggle.Text = ""
        MobileToggle.ZIndex = 100
        MobileToggle.Parent = ScreenGui
        UI.MobileToggle = MobileToggle
        ThemeManager:Register(MobileToggle, "BackgroundColor3", "Main")
        Instance.new("UICorner", MobileToggle).CornerRadius = UDim.new(0, 10)
        local Stroke = Instance.new("UIStroke", MobileToggle)
        Stroke.Thickness = 1.5
        ThemeManager:Register(Stroke, "Color", "Accent")

        local MobileIcon = Instance.new("ImageLabel")
        MobileIcon.Name = "Icon"
        MobileIcon.Size = UDim2.new(0, 22, 0, 22)
        MobileIcon.Position = UDim2.new(0.5, 0, 0.4, 0)
        MobileIcon.AnchorPoint = Vector2.new(0.5, 0.5)
        MobileIcon.BackgroundTransparency = 1
        MobileIcon.Parent = MobileToggle
        ThemeManager:Register(MobileIcon, "ImageColor3", "Text")
        Icons:Apply(MobileIcon, "menu")

        local ToggleText = Instance.new("TextLabel")
        ToggleText.Name = "MobileToggleText"
        ToggleText.Size = UDim2.new(1, 0, 0, 20)
        ToggleText.Position = UDim2.new(0.5, 0, 0.75, 0)
        ToggleText.AnchorPoint = Vector2.new(0.5, 0.5)
        ToggleText.BackgroundTransparency = 1
        ToggleText.Text = "CLOSE"
        ToggleText.Font = Enum.Font.GothamBold
        ToggleText.TextSize = 9
        ToggleText.TextColor3 = Color3.fromRGB(255, 100, 100)
        ToggleText.Parent = MobileToggle
        UI.MobileToggleText = ToggleText

        MainFrame.Visible = true

        -- Bezkonfliktowe przeciąganie i tapnięcie: tap otwiera/zamyka menu, przeciąganie przesuwa przycisk
        Interactions:MakeDraggable(MobileToggle, MobileToggle, function()
            UI:ToggleMenu()
        end)
    end

    -- // ============================================================
    -- // KEYBINDS OVERLAY (MINECRAFT STYLE ARRAYLIST / HUD)
    -- // ============================================================
    local KeybindsOverlay = Instance.new("Frame")
    KeybindsOverlay.Name = "KeybindsOverlay"
    KeybindsOverlay.Size = UDim2.new(0, 190, 0, 0)
    KeybindsOverlay.Position = UDim2.new(1, -210, 0, 30)
    KeybindsOverlay.AutomaticSize = Enum.AutomaticSize.Y
    KeybindsOverlay.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
    KeybindsOverlay.BackgroundTransparency = 0.2
    KeybindsOverlay.Visible = false
    KeybindsOverlay.ZIndex = 50
    KeybindsOverlay.Parent = ScreenGui

    Instance.new("UICorner", KeybindsOverlay).CornerRadius = UDim.new(0, 8)
    local OverlayStroke = Instance.new("UIStroke", KeybindsOverlay)
    OverlayStroke.Color = Color3.fromRGB(60, 60, 65)
    OverlayStroke.Thickness = 1.2
    OverlayStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    local OverlayHeader = Instance.new("Frame")
    OverlayHeader.Name = "Header"
    OverlayHeader.Size = UDim2.new(1, 0, 0, 28)
    OverlayHeader.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
    OverlayHeader.Parent = KeybindsOverlay
    Instance.new("UICorner", OverlayHeader).CornerRadius = UDim.new(0, 8)

    local HeaderBottomSquare = Instance.new("Frame")
    HeaderBottomSquare.Size = UDim2.new(1, 0, 0, 6)
    HeaderBottomSquare.Position = UDim2.new(0, 0, 1, -6)
    HeaderBottomSquare.BorderSizePixel = 0
    HeaderBottomSquare.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
    HeaderBottomSquare.Parent = OverlayHeader

    local OverlayTitle = Instance.new("TextLabel")
    OverlayTitle.Text = "⌨️ Keybinds"
    OverlayTitle.Font = Enum.Font.GothamBold
    OverlayTitle.TextSize = 12
    OverlayTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    OverlayTitle.TextXAlignment = Enum.TextXAlignment.Left
    OverlayTitle.Size = UDim2.new(1, -12, 1, 0)
    OverlayTitle.Position = UDim2.new(0, 10, 0, 0)
    OverlayTitle.BackgroundTransparency = 1
    OverlayTitle.Parent = OverlayHeader

    ThemeManager:Register(KeybindsOverlay, "BackgroundColor3", "Main")
    ThemeManager:Register(OverlayStroke, "Color", "Accent")
    ThemeManager:Register(OverlayHeader, "BackgroundColor3", "Secondary")
    ThemeManager:Register(HeaderBottomSquare, "BackgroundColor3", "Secondary")
    ThemeManager:Register(OverlayTitle, "TextColor3", "Text")

    local OverlayList = Instance.new("Frame")
    OverlayList.Name = "List"
    OverlayList.Size = UDim2.new(1, 0, 0, 0)
    OverlayList.Position = UDim2.new(0, 0, 0, 28)
    OverlayList.AutomaticSize = Enum.AutomaticSize.Y
    OverlayList.BackgroundTransparency = 1
    OverlayList.Parent = KeybindsOverlay

    local OverlayListLayout = Instance.new("UIListLayout", OverlayList)
    OverlayListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    OverlayListLayout.Padding = UDim.new(0, 4)

    local OverlayListPadding = Instance.new("UIPadding", OverlayList)
    OverlayListPadding.PaddingTop = UDim.new(0, 6)
    OverlayListPadding.PaddingBottom = UDim.new(0, 8)
    OverlayListPadding.PaddingLeft = UDim.new(0, 10)
    OverlayListPadding.PaddingRight = UDim.new(0, 10)

    if Interactions and Interactions.MakeDraggable then
        Interactions:MakeDraggable(OverlayHeader, KeybindsOverlay)
    end

    UI.KeybindsOverlay = KeybindsOverlay
    UI.RegisteredModules = {}

    function UI:RegisterModule(mod)
        table.insert(UI.RegisteredModules, mod)
        UI:UpdateKeybindsOverlay()
    end

    function UI:UpdateKeybindsOverlay()
        for _, child in ipairs(OverlayList:GetChildren()) do
            if child:IsA("Frame") or child:IsA("TextLabel") then child:Destroy() end
        end

        local count = 0
        for _, mod in ipairs(UI.RegisteredModules) do
            local key = mod.GetKeybind and mod.GetKeybind()
            local isEnabled = mod.GetEnabled and mod.GetEnabled()

            if key or isEnabled then
                count = count + 1
                local item = Instance.new("Frame")
                item.Name = mod.Name
                item.Size = UDim2.new(1, 0, 0, 22)
                item.BackgroundTransparency = 1
                item.LayoutOrder = isEnabled and 1 or 2
                item.Parent = OverlayList

                local nameLbl = Instance.new("TextLabel")
                nameLbl.Text = mod.Name:gsub("%s*%b()", "")
                nameLbl.Font = isEnabled and Enum.Font.GothamBold or Enum.Font.GothamMedium
                nameLbl.TextSize = 12
                nameLbl.TextColor3 = isEnabled and ThemeManager:GetColor("Text") or ThemeManager:GetColor("Text_Secondary")
                nameLbl.TextXAlignment = Enum.TextXAlignment.Left
                nameLbl.Size = UDim2.new(1, -45, 1, 0)
                nameLbl.BackgroundTransparency = 1
                nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
                nameLbl.Parent = item

                local keyLbl = Instance.new("TextLabel")
                keyLbl.Text = key and ("[" .. tostring(key):sub(1, 3) .. "]") or "[ON]"
                keyLbl.Font = Enum.Font.GothamBold
                keyLbl.TextSize = 11
                keyLbl.TextColor3 = isEnabled and ThemeManager:GetColor("Success") or ThemeManager:GetColor("Text_Secondary")
                keyLbl.TextXAlignment = Enum.TextXAlignment.Right
                keyLbl.Size = UDim2.new(0, 45, 1, 0)
                keyLbl.Position = UDim2.new(1, -45, 0, 0)
                keyLbl.BackgroundTransparency = 1
                keyLbl.Parent = item
            end
        end

        if count == 0 then
            local emptyLbl = Instance.new("TextLabel")
            emptyLbl.Name = "Empty"
            emptyLbl.Text = "Brak aktywnych bindów\n(Kliknij Scroll na moduł)"
            emptyLbl.Font = Enum.Font.Gotham
            emptyLbl.TextSize = 11
            emptyLbl.TextColor3 = ThemeManager:GetColor("Text_Secondary")
            emptyLbl.Size = UDim2.new(1, 0, 0, 30)
            emptyLbl.BackgroundTransparency = 1
            emptyLbl.Parent = OverlayList
        end
    end

    ThemeManager:OnThemeChanged(function()
        if KeybindsOverlay.Visible then
            UI:UpdateKeybindsOverlay()
        end
    end)

    function UI:SetKeybindsOverlayVisible(visible)
        KeybindsOverlay.Visible = visible
        if visible then UI:UpdateKeybindsOverlay() end
    end

    -- Modal wyjścia
    local function ShowExitModal()
        local Overlay = Instance.new("Frame")
        Overlay.Name = "ExitOverlay"
        Overlay.Size = UDim2.new(1, 0, 1, 0)
        Overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        Overlay.BackgroundTransparency = 0.5
        Overlay.ZIndex = 100
        Overlay.Parent = MainFrame

        local Modal = Instance.new("Frame")
        Modal.Name = "ExitModal"
        Modal.Size = UDim2.new(0, 300, 0, 150)
        Modal.Position = UDim2.new(0.5, 0, 0.5, 0)
        Modal.AnchorPoint = Vector2.new(0.5, 0.5)
        Modal.BorderSizePixel = 0
        Modal.Parent = Overlay
        ThemeManager:Register(Modal, "BackgroundColor3", "Secondary")
        Instance.new("UICorner", Modal).CornerRadius = UDim.new(0, 8)
        local Stroke = Instance.new("UIStroke", Modal)
        Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        Stroke.Thickness = 1.5
        ThemeManager:Register(Stroke, "Color", "Accent")

        local Question = Instance.new("TextLabel")
        Question.Text = "Are you sure you want to exit?"
        Question.Font = Enum.Font.GothamBold
        Question.TextSize = 16
        Question.Size = UDim2.new(1, 0, 0, 80)
        Question.BackgroundTransparency = 1
        Question.Parent = Modal
        ThemeManager:Register(Question, "TextColor3", "Text")

        local function makeBtn(text, colorKey, pos)
            local btn = Instance.new("TextButton")
            btn.Text = text
            btn.Font = Enum.Font.GothamMedium
            btn.TextSize = 14
            btn.Size = UDim2.new(0, 100, 0, 35)
            btn.Position = pos
            btn.Parent = Modal
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
            ThemeManager:Register(btn, "TextColor3", "Text")
            ThemeManager:Register(btn, "BackgroundColor3", colorKey)
            return btn
        end

        local YesBtn = makeBtn("Yes", "Close",  UDim2.new(0.5, -110, 0.7, 0))
        local NoBtn  = makeBtn("No",  "Accent",  UDim2.new(0.5,   10, 0.7, 0))
        YesBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)
        NoBtn.MouseButton1Click:Connect(function()  Overlay:Destroy()   end)
    end
    UI.ShowExitModal = ShowExitModal

    -- // ============================================================
    -- // UI:SelectTab  – wybiera zakładkę i ustawia GlobalIndicator
    -- // ============================================================
    function UI:SelectTab(targetButton, immediate)
        if not targetButton then return end

        -- Jeśli otwarte były Ustawienia, zresetuj ich stan
        if UI.IsSettingsOpen then
            UI.IsSettingsOpen = false
            if UI.SettingsBtn then
                TweenService:Create(UI.SettingsBtn, TweenInfo.new(0.2), {
                    BackgroundTransparency = 1
                }):Play()
            end
            if UI.SettingsIcon then
                local dimTxt = getColor(ThemeManager.CurrentTheme.Text_Secondary)
                TweenService:Create(UI.SettingsIcon, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                    ImageColor3 = dimTxt,
                    Rotation = 0
                }):Play()
            end
        end

        -- Znajdź stronę powiązaną z przyciskiem
        local targetPage = nil
        for _, tabObj in ipairs(UI.TabObjects) do
            if tabObj.Button == targetButton then
                targetPage = tabObj.Page
                break
            end
        end
        if not targetPage then
            warn("[Window] SelectTab: nie znaleziono Page dla przycisku " .. tostring(targetButton.Name))
            return
        end

        -- Wyczyść poprzedni stan
        if UI.SelectedTab and UI.SelectedTab ~= targetButton then
            local prevIcon  = UI.SelectedTab:FindFirstChild("Icon")
            local prevLabel = UI.SelectedTab:FindFirstChild("Label")
            if prevIcon  then TweenService:Create(prevIcon,  TweenInfo.new(0.2),
                {ImageColor3 = getColor(ThemeManager.CurrentTheme.Text_Secondary)}):Play() end
            if prevLabel then TweenService:Create(prevLabel, TweenInfo.new(0.2),
                {TextColor3  = getColor(ThemeManager.CurrentTheme.Text_Secondary)}):Play() end
        end

        -- Ukryj wszystkie strony, pokaż wybraną
        for _, page in ipairs(UI.Pages) do page.Visible = false end
        targetPage.Visible = true
        UI.SelectedTab = targetButton

        -- Podświetl wybrany przycisk
        local TabIcon  = targetButton:FindFirstChild("Icon")
        local TabLabel = targetButton:FindFirstChild("Label")
        if TabIcon  then TweenService:Create(TabIcon,  TweenInfo.new(0.2),
            {ImageColor3 = getColor(ThemeManager.CurrentTheme.Text)}):Play() end
        if TabLabel then TweenService:Create(TabLabel, TweenInfo.new(0.2),
            {TextColor3  = getColor(ThemeManager.CurrentTheme.Text)}):Play() end

        -- Pozycja GlobalIndicator
        UI.GlobalIndicator.Visible = true

        local function updateIndicator()
            if not targetButton or not SidebarFrame then return end
            local relativeY = targetButton.AbsolutePosition.Y - SidebarFrame.AbsolutePosition.Y
            -- Fallback gdy layout engine jeszcze nie obliczył AbsolutePosition
            if relativeY <= 0 or targetButton.AbsolutePosition.Y == 0 then
                relativeY = 46 + (targetButton.LayoutOrder - 1) * 45
            end
            if immediate then
                UI.GlobalIndicator.Position = UDim2.new(0, 0, 0, relativeY)
            else
                TweenService:Create(UI.GlobalIndicator,
                    TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
                    {Position = UDim2.new(0, 0, 0, relativeY)}):Play()
            end
        end

        updateIndicator()
        -- Wywołaj ponownie po klatce, gdy Roblox obliczy AbsolutePosition
        task.defer(updateIndicator)
    end

    -- // ============================================================
    -- // UI:SelectDashboard  – wybiera pierwszą zakładkę (LayoutOrder=1)
    -- // ============================================================
    function UI:SelectDashboard()
        if #UI.TabObjects == 0 then
            warn("[Window] SelectDashboard: brak zakładek w UI.TabObjects!")
            return
        end

        local dashButton   = nil
        local lowestOrder  = math.huge

        for _, tabObj in ipairs(UI.TabObjects) do
            if tabObj.Button and tabObj.Button.LayoutOrder < lowestOrder then
                lowestOrder  = tabObj.Button.LayoutOrder
                dashButton   = tabObj.Button
            end
        end

        -- Dodatkowy fallback – weź pierwszy zarejestrowany tab
        if not dashButton then dashButton = UI.Tabs[1] end

        if dashButton then
            UI:SelectTab(dashButton, true)
        else
            warn("[Window] SelectDashboard: nie znaleziono przycisku Dashboard!")
        end
    end

    -- // ============================================================
    -- // UI:OpenSettings – otwiera stronę Ustawień w stylu Discord
    -- // ============================================================
    function UI:OpenSettings()
        if not UI.SettingsPage then return end
        UI.IsSettingsOpen = true

        -- Zdezaktywuj poprzednio wybraną zakładkę w sidebarze
        if UI.SelectedTab then
            UI.PreviousTab = UI.SelectedTab
            local prevIcon  = UI.SelectedTab:FindFirstChild("Icon")
            local prevLabel = UI.SelectedTab:FindFirstChild("Label")
            if prevIcon  then TweenService:Create(prevIcon,  TweenInfo.new(0.2),
                {ImageColor3 = getColor(ThemeManager.CurrentTheme.Text_Secondary)}):Play() end
            if prevLabel then TweenService:Create(prevLabel, TweenInfo.new(0.2),
                {TextColor3  = getColor(ThemeManager.CurrentTheme.Text_Secondary)}):Play() end
            UI.SelectedTab = nil
        end

        -- Ukryj wszystkie strony i pokaż SettingsPage
        for _, page in ipairs(UI.Pages) do
            page.Visible = false
        end
        UI.SettingsPage.Visible = true

        -- Ukryj wskaźnik zakładek w sidebarze
        if UI.GlobalIndicator then
            UI.GlobalIndicator.Visible = false
        end

        -- Podświetl ikonę ustawień w profilu gracza
        if UI.SettingsBtn then
            local activeBg = ThemeManager:GetColor("Accent2") or Color3.fromRGB(45, 45, 55)
            TweenService:Create(UI.SettingsBtn, TweenInfo.new(0.2), {
                BackgroundColor3 = activeBg,
                BackgroundTransparency = 0
            }):Play()
        end
        if UI.SettingsIcon then
            local activeTxt = ThemeManager:GetColor("Text") or Color3.fromRGB(255, 255, 255)
            TweenService:Create(UI.SettingsIcon, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                ImageColor3 = activeTxt,
                Rotation = 60
            }):Play()
        end
    end

    -- // ============================================================
    -- // UI:CreateTab  – tworzy przycisk i stronę zakładki
    -- // ============================================================
    function UI:CreateTab(name, icon, order)
        local tabOrder = order or (#UI.Tabs + 1)

        local TabButton = Instance.new("TextButton")
        TabButton.Name = name
        TabButton.Size = UDim2.new(1, 0, 0, 45)
        TabButton.BackgroundTransparency = 1
        TabButton.Text = ""
        TabButton.AutoButtonColor = false
        TabButton.BorderSizePixel = 0
        TabButton.LayoutOrder = tabOrder
        TabButton.Parent = TabList

        local TabIcon = Instance.new("ImageLabel")
        TabIcon.Name = "Icon"
        TabIcon.Size = UDim2.new(0, 20, 0, 20)
        TabIcon.Position = UDim2.new(0, 15, 0.5, 0)
        TabIcon.AnchorPoint = Vector2.new(0, 0.5)
        TabIcon.BackgroundTransparency = 1
        TabIcon.Parent = TabButton
        Icons:Apply(TabIcon, icon)
        ThemeManager:Register(TabIcon, "ImageColor3", "Text_Secondary")

        local TabLabel = Instance.new("TextLabel")
        TabLabel.Name = "Label"
        TabLabel.Size = UDim2.new(1, -50, 1, 0)
        TabLabel.Position = UDim2.new(0, 45, 0, 0)
        TabLabel.BackgroundTransparency = 1
        TabLabel.Font = Enum.Font.GothamMedium
        TabLabel.Text = name
        TabLabel.TextSize = 14
        TabLabel.TextXAlignment = Enum.TextXAlignment.Left
        TabLabel.Parent = TabButton
        ThemeManager:Register(TabLabel, "TextColor3", "Text_Secondary")

        local Page = Instance.new("ScrollingFrame")
        Page.Name = name .. "Page"
        Page.Size = UDim2.new(1, 0, 1, 0)
        Page.BackgroundTransparency = 1
        Page.BorderSizePixel = 0
        Page.Visible = false                       -- domyślnie ukryta; SelectDashboard otworzy właściwą
        Page.Active = true
        Page.Selectable = false
        Page.CanvasSize = UDim2.new(0, 0, 0, 0)
        Page.AutomaticCanvasSize = Enum.AutomaticSize.Y
        Page.ScrollingDirection = Enum.ScrollingDirection.Y
        Page.ScrollBarThickness = 5
        Page.ScrollBarImageTransparency = 0
        Page.VerticalScrollBarInset = Enum.ScrollBarInset.None
        Page.Parent = UI.PagesContainer
        ThemeManager:Register(Page, "ScrollBarImageColor3", "Accent")

        local PageLayout = Instance.new("UIListLayout", Page)
        PageLayout.Padding = UDim.new(0, 10)
        PageLayout.SortOrder = Enum.SortOrder.LayoutOrder

        local PagePadding = Instance.new("UIPadding", Page)
        PagePadding.PaddingLeft  = UDim.new(0, 20)
        PagePadding.PaddingTop   = UDim.new(0, 20)
        PagePadding.PaddingRight = UDim.new(0, 20)

        -- Kliknięcie przycisku zakładki
        TabButton.MouseButton1Click:Connect(function()
            UI:SelectTab(TabButton)
        end)

        table.insert(UI.Tabs,      TabButton)
        table.insert(UI.Pages,     Page)
        table.insert(UI.TabObjects, {Button = TabButton, Page = Page, LayoutOrder = tabOrder})

        return {Button = TabButton, Page = Page}
    end

    -- // ============================================================
    -- // UI:CreateModuleGrid  – siatka dla modułów
    -- // ============================================================
    function UI:CreateModuleGrid(parentPage)
        local GridFrame = Instance.new("Frame")
        GridFrame.Name = "ModuleGrid"
        GridFrame.BackgroundTransparency = 1
        GridFrame.Size = UDim2.new(1, 0, 0, 0)
        GridFrame.AutomaticSize = Enum.AutomaticSize.Y
        GridFrame.Parent = parentPage

        local GridLayout = Instance.new("UIGridLayout", GridFrame)
        GridLayout.CellPadding = UDim2.new(0, 10, 0, 10)
        GridLayout.CellSize    = UDim2.new(0, 220, 0, 50)
        GridLayout.SortOrder   = Enum.SortOrder.LayoutOrder

        return GridFrame
    end

    return UI
end

return Window