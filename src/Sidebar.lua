-- // ==========================================================================
-- // MENUTEST APPLE VISIONOS / LIQUID GLASS FLOATING DOCK
-- // Styl: Półprzezroczysta pływająca kapsuła (Floating Pill Dock),
-- // zaokrąglone krawędzie (20px+ / Pill), rozmyte szkło, specular reflections.
-- // ==========================================================================

local Sidebar = {}

function Sidebar:Create(UI, theme, config, customWidth)
    local TweenService = game:GetService("TweenService")
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local LocalPlayer = Players.LocalPlayer or (Players:GetPropertyChangedSignal("LocalPlayer"):Wait() and Players.LocalPlayer)

    local Icons = UI.Icons or (typeof(getgenv) == "function" and getgenv()._MenuTestIconsModule) or _G._MenuTestIconsModule

    -- Główny kontener pływającego docka (Floating Glass Island)
    local FloatingDock = Instance.new("Frame")
    FloatingDock.Name = "VisionOS_FloatingDock"
    FloatingDock.Size = UDim2.new(1, -28, 0, 52)
    FloatingDock.Position = UDim2.new(0, 14, 0, 12)
    FloatingDock.BackgroundColor3 = Color3.fromRGB(18, 21, 33)
    FloatingDock.BackgroundTransparency = 0.22
    FloatingDock.BorderSizePixel = 0
    FloatingDock.ZIndex = 15
    FloatingDock.Parent = UI.MainFrame
    UI.Sidebar = FloatingDock

    -- Pełna kapsuła VisionOS (CornerRadius = 100px)
    local DockCorner = Instance.new("UICorner", FloatingDock)
    DockCorner.CornerRadius = UDim.new(0, 26)

    -- Specular Glass Rim (Świetlny obrys szkła z gradientem odbicia)
    local DockStroke = Instance.new("UIStroke", FloatingDock)
    DockStroke.Thickness = 1.2
    DockStroke.Color = Color3.fromRGB(140, 160, 215)
    DockStroke.Transparency = 0.45
    DockStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    local StrokeGrad = Instance.new("UIGradient", DockStroke)
    StrokeGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0.0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(0.3, Color3.fromRGB(165, 180, 252)),
        ColorSequenceKeypoint.new(0.7, Color3.fromRGB(99, 102, 241)),
        ColorSequenceKeypoint.new(1.0, Color3.fromRGB(200, 215, 255))
    })
    StrokeGrad.Rotation = 45

    -- Horizon Specular Highlight (Subtelny 1px błysk na górnej krawędzi kapsuły)
    local TopGleam = Instance.new("Frame")
    TopGleam.Name = "TopGleam"
    TopGleam.Size = UDim2.new(0.75, 0, 0, 1.5)
    TopGleam.Position = UDim2.new(0.5, 0, 0, 1)
    TopGleam.AnchorPoint = Vector2.new(0.5, 0)
    TopGleam.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    TopGleam.BackgroundTransparency = 0.5
    TopGleam.BorderSizePixel = 0
    TopGleam.ZIndex = 16
    TopGleam.Parent = FloatingDock

    local GleamGrad = Instance.new("UIGradient", TopGleam)
    GleamGrad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0.0, 1.0),
        NumberSequenceKeypoint.new(0.2, 0.4),
        NumberSequenceKeypoint.new(0.5, 0.1),
        NumberSequenceKeypoint.new(0.8, 0.4),
        NumberSequenceKeypoint.new(1.0, 1.0)
    })

    -- Wewnętrzny kontener doka z paddingiem
    local DockInner = Instance.new("Frame")
    DockInner.Name = "DockInner"
    DockInner.Size = UDim2.new(1, -20, 1, 0)
    DockInner.Position = UDim2.new(0, 10, 0, 0)
    DockInner.BackgroundTransparency = 1
    DockInner.ZIndex = 16
    DockInner.Parent = FloatingDock

    -- // =====================================================================
    -- // LEWA STRONA: BRAND ORB + TYTUŁ + VISION BADGE
    -- // =====================================================================
    local BrandSide = Instance.new("Frame")
    BrandSide.Name = "BrandSide"
    BrandSide.Size = UDim2.new(0, 195, 1, 0)
    BrandSide.Position = UDim2.new(0, 0, 0, 0)
    BrandSide.BackgroundTransparency = 1
    BrandSide.ZIndex = 17
    BrandSide.Parent = DockInner

    local BrandLayout = Instance.new("UIListLayout", BrandSide)
    BrandLayout.FillDirection = Enum.FillDirection.Horizontal
    BrandLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    BrandLayout.Padding = UDim.new(0, 8)

    -- Liquid Glass Orb
    local BrandOrb = Instance.new("Frame")
    BrandOrb.Name = "BrandOrb"
    BrandOrb.Size = UDim2.new(0, 30, 0, 30)
    BrandOrb.BackgroundColor3 = Color3.fromRGB(99, 102, 241)
    BrandOrb.BorderSizePixel = 0
    BrandOrb.ZIndex = 18
    BrandOrb.Parent = BrandSide
    Instance.new("UICorner", BrandOrb).CornerRadius = UDim.new(1, 0)

    local OrbStroke = Instance.new("UIStroke", BrandOrb)
    OrbStroke.Color = Color3.fromRGB(220, 230, 255)
    OrbStroke.Thickness = 1.2
    OrbStroke.Transparency = 0.3

    local OrbGrad = Instance.new("UIGradient", BrandOrb)
    OrbGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0.0, Color3.fromRGB(99, 102, 241)),
        ColorSequenceKeypoint.new(0.6, Color3.fromRGB(168, 85, 247)),
        ColorSequenceKeypoint.new(1.0, Color3.fromRGB(236, 72, 153))
    })
    OrbGrad.Rotation = 45

    local OrbIcon = Instance.new("ImageLabel")
    OrbIcon.Size = UDim2.new(0, 16, 0, 16)
    OrbIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
    OrbIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    OrbIcon.BackgroundTransparency = 1
    OrbIcon.ImageColor3 = Color3.fromRGB(255, 255, 255)
    OrbIcon.ZIndex = 19
    OrbIcon.Parent = BrandOrb
    if Icons and Icons.Apply then Icons:Apply(OrbIcon, "zap") end

    -- Pulsujący obrót orba
    task.spawn(function()
        local rot = 0
        while FloatingDock.Parent do
            rot = (rot + 1.2) % 360
            OrbGrad.Rotation = rot
            task.wait(0.04)
        end
    end)

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Text = config.Name or "UNIVERSAL"
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.TextSize = 13
    TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    TitleLabel.AutomaticSize = Enum.AutomaticSize.X
    TitleLabel.Size = UDim2.new(0, 0, 1, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.ZIndex = 18
    TitleLabel.Parent = BrandSide

    local GlassBadge = Instance.new("TextLabel")
    GlassBadge.Text = "VISION 3.5"
    GlassBadge.Font = Enum.Font.GothamBold
    GlassBadge.TextSize = 9
    GlassBadge.TextColor3 = Color3.fromRGB(165, 180, 252)
    GlassBadge.Size = UDim2.new(0, 64, 0, 19)
    GlassBadge.BackgroundColor3 = Color3.fromRGB(30, 34, 52)
    GlassBadge.BackgroundTransparency = 0.3
    GlassBadge.ZIndex = 18
    GlassBadge.Parent = BrandSide
    Instance.new("UICorner", GlassBadge).CornerRadius = UDim.new(1, 0)
    local GbStroke = Instance.new("UIStroke", GlassBadge)
    GbStroke.Color = Color3.fromRGB(70, 78, 115)
    GbStroke.Thickness = 1
    GbStroke.Transparency = 0.5

    -- // =====================================================================
    -- // ŚRODEK: PŁYWAJĄCY SEGMENTED PILL TAB BAR (ZAKŁADKI)
    -- // =====================================================================
    local TabList = Instance.new("ScrollingFrame")
    TabList.Name = "VisionTabBar"
    TabList.Size = UDim2.new(1, -490, 0, 36)
    TabList.Position = UDim2.new(0, 202, 0.5, 0)
    TabList.AnchorPoint = Vector2.new(0, 0.5)
    TabList.BackgroundColor3 = Color3.fromRGB(12, 14, 22)
    TabList.BackgroundTransparency = 0.5
    TabList.BorderSizePixel = 0
    pcall(function()
        TabList.ScrollingDirection = Enum.ScrollingDirection.X
    end)
    TabList.ScrollBarThickness = 0
    TabList.CanvasSize = UDim2.new(0, 0, 0, 0)
    TabList.AutomaticCanvasSize = Enum.AutomaticSize.X
    TabList.ZIndex = 17
    TabList.Parent = DockInner
    UI.TabList = TabList

    Instance.new("UICorner", TabList).CornerRadius = UDim.new(1, 0)
    local TlStroke = Instance.new("UIStroke", TabList)
    TlStroke.Color = Color3.fromRGB(45, 52, 78)
    TlStroke.Thickness = 1
    TlStroke.Transparency = 0.6

    local TlPadding = Instance.new("UIPadding", TabList)
    TlPadding.PaddingLeft = UDim.new(0, 4)
    TlPadding.PaddingRight = UDim.new(0, 4)

    local TabLayout = Instance.new("UIListLayout", TabList)
    TabLayout.FillDirection = Enum.FillDirection.Horizontal
    TabLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    TabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    TabLayout.Padding = UDim.new(0, 4)
    TabLayout.SortOrder = Enum.SortOrder.LayoutOrder

    -- // =====================================================================
    -- // PRAWA STRONA: SZUKAJKI, TELEMETRIA, PROFIL, KONTROLKI OKNA
    -- // =====================================================================
    local RightSide = Instance.new("Frame")
    RightSide.Name = "RightSide"
    RightSide.Size = UDim2.new(0, 280, 1, 0)
    RightSide.Position = UDim2.new(1, 0, 0.5, 0)
    RightSide.AnchorPoint = Vector2.new(1, 0.5)
    RightSide.BackgroundTransparency = 1
    RightSide.ZIndex = 17
    RightSide.Parent = DockInner

    local RightLayout = Instance.new("UIListLayout", RightSide)
    RightLayout.FillDirection = Enum.FillDirection.Horizontal
    RightLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    RightLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    RightLayout.Padding = UDim.new(0, 7)

    -- Szukajka Glass Capsule
    local SearchBoxContainer = Instance.new("Frame")
    SearchBoxContainer.Name = "SearchBoxContainer"
    SearchBoxContainer.Size = UDim2.new(0, 85, 0, 28)
    SearchBoxContainer.BackgroundColor3 = Color3.fromRGB(24, 28, 42)
    SearchBoxContainer.BackgroundTransparency = 0.35
    SearchBoxContainer.BorderSizePixel = 0
    SearchBoxContainer.ZIndex = 18
    SearchBoxContainer.Parent = RightSide
    Instance.new("UICorner", SearchBoxContainer).CornerRadius = UDim.new(1, 0)
    local SbStroke = Instance.new("UIStroke", SearchBoxContainer)
    SbStroke.Color = Color3.fromRGB(55, 62, 90)
    SbStroke.Thickness = 1
    SbStroke.Transparency = 0.6

    local SearchIcon = Instance.new("ImageLabel")
    SearchIcon.Size = UDim2.new(0, 12, 0, 12)
    SearchIcon.Position = UDim2.new(0, 8, 0.5, 0)
    SearchIcon.AnchorPoint = Vector2.new(0, 0.5)
    SearchIcon.BackgroundTransparency = 1
    SearchIcon.ImageColor3 = Color3.fromRGB(140, 150, 180)
    SearchIcon.ZIndex = 19
    SearchIcon.Parent = SearchBoxContainer
    if Icons and Icons.Apply then Icons:Apply(SearchIcon, "search") end

    local SearchInput = Instance.new("TextBox")
    SearchInput.Name = "SearchInput"
    SearchInput.Size = UDim2.new(1, -24, 1, 0)
    SearchInput.Position = UDim2.new(0, 22, 0, 0)
    SearchInput.BackgroundTransparency = 1
    SearchInput.Font = Enum.Font.GothamMedium
    SearchInput.Text = ""
    SearchInput.PlaceholderText = "Szukaj"
    SearchInput.PlaceholderColor3 = Color3.fromRGB(100, 110, 135)
    SearchInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    SearchInput.TextSize = 10
    SearchInput.TextXAlignment = Enum.TextXAlignment.Left
    SearchInput.ClearTextOnFocus = false
    SearchInput.ZIndex = 19
    SearchInput.Parent = SearchBoxContainer
    UI.SearchInput = SearchInput

    SearchInput.Focused:Connect(function()
        TweenService:Create(SearchBoxContainer, TweenInfo.new(0.2), { Size = UDim2.new(0, 115, 0, 28), BackgroundTransparency = 0.1 }):Play()
    end)
    SearchInput.FocusLost:Connect(function()
        TweenService:Create(SearchBoxContainer, TweenInfo.new(0.2), { Size = UDim2.new(0, 85, 0, 28), BackgroundTransparency = 0.35 }):Play()
    end)

    -- Telemetria Capsule (FPS + Ping z kropką LED)
    local TelemetryPill = Instance.new("Frame")
    TelemetryPill.Name = "TelemetryPill"
    TelemetryPill.Size = UDim2.new(0, 68, 0, 28)
    TelemetryPill.BackgroundColor3 = Color3.fromRGB(20, 23, 35)
    TelemetryPill.BackgroundTransparency = 0.4
    TelemetryPill.BorderSizePixel = 0
    TelemetryPill.ZIndex = 18
    TelemetryPill.Parent = RightSide
    Instance.new("UICorner", TelemetryPill).CornerRadius = UDim.new(1, 0)
    local TpStroke = Instance.new("UIStroke", TelemetryPill)
    TpStroke.Color = Color3.fromRGB(50, 58, 85)
    TpStroke.Thickness = 1
    TpStroke.Transparency = 0.6

    local FpsDot = Instance.new("Frame")
    FpsDot.Size = UDim2.new(0, 5, 0, 5)
    FpsDot.Position = UDim2.new(0, 8, 0.5, 0)
    FpsDot.AnchorPoint = Vector2.new(0, 0.5)
    FpsDot.BackgroundColor3 = Color3.fromRGB(52, 211, 153)
    FpsDot.BorderSizePixel = 0
    FpsDot.ZIndex = 19
    FpsDot.Parent = TelemetryPill
    Instance.new("UICorner", FpsDot).CornerRadius = UDim.new(1, 0)

    local FpsLabel = Instance.new("TextLabel")
    FpsLabel.Text = "60 FPS"
    FpsLabel.Font = Enum.Font.GothamBold
    FpsLabel.TextSize = 9
    FpsLabel.TextColor3 = Color3.fromRGB(220, 230, 250)
    FpsLabel.Size = UDim2.new(1, -16, 1, 0)
    FpsLabel.Position = UDim2.new(0, 16, 0, 0)
    FpsLabel.BackgroundTransparency = 1
    FpsLabel.TextXAlignment = Enum.TextXAlignment.Left
    FpsLabel.ZIndex = 19
    FpsLabel.Parent = TelemetryPill

    local fpsCount = 0
    local fpsTimer = tick()
    RunService.RenderStepped:Connect(function()
        fpsCount = fpsCount + 1
        if tick() - fpsTimer >= 1 then
            FpsLabel.Text = tostring(fpsCount) .. "F"
            fpsCount = 0
            fpsTimer = tick()
        end
    end)

    -- Profil gracza + Przycisk Settings (Liquid Glass Avatar Button)
    local ProfilePill = Instance.new("Frame")
    ProfilePill.Name = "ProfilePill"
    ProfilePill.Size = UDim2.new(0, 48, 0, 28)
    ProfilePill.BackgroundColor3 = Color3.fromRGB(24, 28, 42)
    ProfilePill.BackgroundTransparency = 0.35
    ProfilePill.BorderSizePixel = 0
    ProfilePill.ZIndex = 18
    ProfilePill.Parent = RightSide
    Instance.new("UICorner", ProfilePill).CornerRadius = UDim.new(1, 0)
    local PpStroke = Instance.new("UIStroke", ProfilePill)
    PpStroke.Color = Color3.fromRGB(55, 62, 90)
    PpStroke.Thickness = 1
    PpStroke.Transparency = 0.6

    local AvatarImg = Instance.new("ImageLabel")
    AvatarImg.Size = UDim2.new(0, 20, 0, 20)
    AvatarImg.Position = UDim2.new(0, 4, 0.5, 0)
    AvatarImg.AnchorPoint = Vector2.new(0, 0.5)
    AvatarImg.BackgroundColor3 = Color3.fromRGB(30, 32, 45)
    AvatarImg.BorderSizePixel = 0
    AvatarImg.ZIndex = 19
    AvatarImg.Parent = ProfilePill
    Instance.new("UICorner", AvatarImg).CornerRadius = UDim.new(1, 0)

    task.spawn(function()
        if LocalPlayer and LocalPlayer.UserId then
            local thumb, isReady = Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
            if isReady and thumb then AvatarImg.Image = thumb end
        end
    end)

    local SettingsBtn = Instance.new("ImageButton")
    SettingsBtn.Name = "SettingsBtn"
    SettingsBtn.Size = UDim2.new(0, 14, 0, 14)
    SettingsBtn.Position = UDim2.new(1, -6, 0.5, 0)
    SettingsBtn.AnchorPoint = Vector2.new(1, 0.5)
    SettingsBtn.BackgroundTransparency = 1
    SettingsBtn.ImageColor3 = Color3.fromRGB(150, 160, 190)
    SettingsBtn.ZIndex = 19
    SettingsBtn.Parent = ProfilePill
    if Icons and Icons.Apply then Icons:Apply(SettingsBtn, "settings") end
    UI.SettingsBtn = SettingsBtn
    UI.SettingsIcon = SettingsBtn

    SettingsBtn.MouseEnter:Connect(function()
        TweenService:Create(SettingsBtn, TweenInfo.new(0.25), { ImageColor3 = Color3.fromRGB(255, 255, 255), Rotation = 45 }):Play()
    end)
    SettingsBtn.MouseLeave:Connect(function()
        if not UI.IsSettingsOpen then
            TweenService:Create(SettingsBtn, TweenInfo.new(0.25), { ImageColor3 = Color3.fromRGB(150, 160, 190), Rotation = 0 }):Play()
        end
    end)
    SettingsBtn.MouseButton1Click:Connect(function()
        if UI.OpenSettings then UI:OpenSettings() end
    end)

    -- Kontener przycisków okna (VisionOS Traffic Light / Glass Dots)
    local Controls = Instance.new("Frame")
    Controls.Name = "Controls"
    Controls.Size = UDim2.new(0, 56, 1, 0)
    Controls.BackgroundTransparency = 1
    Controls.ZIndex = 18
    Controls.Parent = RightSide
    UI.Controls = Controls

    local ControlsLayout = Instance.new("UIListLayout", Controls)
    ControlsLayout.FillDirection = Enum.FillDirection.Horizontal
    ControlsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    ControlsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    ControlsLayout.Padding = UDim.new(0, 5)

    return FloatingDock, TabList
end

return Sidebar