-- // ==========================================================================
-- // MENUTEST APPLE iPHONE (iOS 27.2) LIQUID GLASS FLOATING DOCK
-- // Styl: Dynamic Island 2.0, tafla akrylowego szkła Liquid Glass z iOS 27.2,
-- // zaokrąglone krawędzie (Squircle / Capsule), specular reflections i Apple Green #34C759.
-- // ==========================================================================

local Sidebar = {}

function Sidebar:Create(UI, theme, config, customWidth)
    local TweenService = game:GetService("TweenService")
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local LocalPlayer = Players.LocalPlayer or (Players:GetPropertyChangedSignal("LocalPlayer"):Wait() and Players.LocalPlayer)

    local Icons = UI.Icons or (typeof(getgenv) == "function" and getgenv()._MenuTestIconsModule) or _G._MenuTestIconsModule

    -- Główny kontener pływającego docka (Apple iPhone Glass Dock)
    local FloatingDock = Instance.new("Frame")
    FloatingDock.Name = "iPhone_FloatingDock"
    FloatingDock.Size = UDim2.new(1, -28, 0, 52)
    FloatingDock.Position = UDim2.new(0, 14, 0, 12)
    FloatingDock.BackgroundColor3 = Color3.fromRGB(18, 20, 28)
    FloatingDock.BackgroundTransparency = 0.20
    FloatingDock.BorderSizePixel = 0
    FloatingDock.ZIndex = 15
    FloatingDock.Parent = UI.MainFrame
    UI.Sidebar = FloatingDock

    -- Pełna kapsuła Apple iPhone (CornerRadius = 26px)
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
    BrandSide.Size = UDim2.new(0, 160, 1, 0)
    BrandSide.Position = UDim2.new(0, 0, 0, 0)
    BrandSide.BackgroundTransparency = 1
    BrandSide.ClipsDescendants = true
    BrandSide.ZIndex = 17
    BrandSide.Parent = DockInner

    local BrandLayout = Instance.new("UIListLayout", BrandSide)
    BrandLayout.FillDirection = Enum.FillDirection.Horizontal
    BrandLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    BrandLayout.Padding = UDim.new(0, 6)

    -- Apple Liquid Glass Orb (Green iOS Glow)
    local BrandOrb = Instance.new("Frame")
    BrandOrb.Name = "BrandOrb"
    BrandOrb.Size = UDim2.new(0, 26, 0, 26)
    BrandOrb.BackgroundColor3 = Color3.fromRGB(52, 199, 89)
    BrandOrb.BorderSizePixel = 0
    BrandOrb.ZIndex = 18
    BrandOrb.Parent = BrandSide
    Instance.new("UICorner", BrandOrb).CornerRadius = UDim.new(1, 0)

    local OrbStroke = Instance.new("UIStroke", BrandOrb)
    OrbStroke.Color = Color3.fromRGB(200, 255, 220)
    OrbStroke.Thickness = 1.2
    OrbStroke.Transparency = 0.3

    local OrbGrad = Instance.new("UIGradient", BrandOrb)
    OrbGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0.0, Color3.fromRGB(52, 199, 89)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(48, 209, 88)),
        ColorSequenceKeypoint.new(1.0, Color3.fromRGB(0, 199, 255))
    })
    OrbGrad.Rotation = 45

    local OrbIcon = Instance.new("ImageLabel")
    OrbIcon.Size = UDim2.new(0, 14, 0, 14)
    OrbIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
    OrbIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    OrbIcon.BackgroundTransparency = 1
    OrbIcon.ImageColor3 = Color3.fromRGB(255, 255, 255)
    OrbIcon.ZIndex = 19
    OrbIcon.Parent = BrandOrb
    if Icons and Icons.Apply then Icons:Apply(OrbIcon, "layers") end

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
    TitleLabel.TextSize = 12
    TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    TitleLabel.TextTruncate = Enum.TextTruncate.AtEnd
    TitleLabel.AutomaticSize = Enum.AutomaticSize.X
    TitleLabel.Size = UDim2.new(0, 0, 1, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.ZIndex = 18
    TitleLabel.Parent = BrandSide

    local GlassBadge = Instance.new("TextLabel")
    GlassBadge.Text = "27.2"
    GlassBadge.Font = Enum.Font.GothamBold
    GlassBadge.TextSize = 9
    GlassBadge.TextColor3 = Color3.fromRGB(52, 199, 89)
    GlassBadge.Size = UDim2.new(0, 36, 0, 17)
    GlassBadge.BackgroundColor3 = Color3.fromRGB(20, 36, 28)
    GlassBadge.BackgroundTransparency = 0.25
    GlassBadge.ZIndex = 18
    GlassBadge.Parent = BrandSide
    Instance.new("UICorner", GlassBadge).CornerRadius = UDim.new(1, 0)
    local GbStroke = Instance.new("UIStroke", GlassBadge)
    GbStroke.Color = Color3.fromRGB(52, 199, 89)
    GbStroke.Thickness = 1
    GbStroke.Transparency = 0.5

    -- // =====================================================================
    -- // ŚRODEK: PŁYWAJĄCY SEGMENTED PILL TAB BAR (ZAKŁADKI)
    -- // =====================================================================
    local TabList = Instance.new("ScrollingFrame")
    TabList.Name = "VisionTabBar"
    TabList.Size = UDim2.new(1, -458, 0, 32)
    TabList.Position = UDim2.new(0, 166, 0.5, 0)
    TabList.AnchorPoint = Vector2.new(0, 0.5)
    TabList.BackgroundColor3 = Color3.fromRGB(12, 14, 22)
    TabList.BackgroundTransparency = 0.5
    TabList.BorderSizePixel = 0
    TabList.ClipsDescendants = true
    pcall(function()
        TabList.ScrollingDirection = Enum.ScrollingDirection.X
        TabList.ElasticBehavior = Enum.ElasticBehavior.Always
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
    -- // PRAWA STRONA: SZUKAJKI, DYNAMIC ISLAND, PROFIL, KONTROLKI OKNA
    -- // =====================================================================
    local RightSide = Instance.new("Frame")
    RightSide.Name = "RightSide"
    RightSide.Size = UDim2.new(0, 284, 1, 0)
    RightSide.Position = UDim2.new(1, 0, 0.5, 0)
    RightSide.AnchorPoint = Vector2.new(1, 0.5)
    RightSide.BackgroundTransparency = 1
    RightSide.ZIndex = 17
    RightSide.Parent = DockInner

    local RightLayout = Instance.new("UIListLayout", RightSide)
    RightLayout.FillDirection = Enum.FillDirection.Horizontal
    RightLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    RightLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    RightLayout.SortOrder = Enum.SortOrder.LayoutOrder
    RightLayout.Padding = UDim.new(0, 6)

    -- Szukajka Glass Capsule
    local SearchBoxContainer = Instance.new("Frame")
    SearchBoxContainer.Name = "SearchBoxContainer"
    SearchBoxContainer.Size = UDim2.new(0, 68, 0, 28)
    SearchBoxContainer.BackgroundColor3 = Color3.fromRGB(24, 28, 42)
    SearchBoxContainer.BackgroundTransparency = 0.35
    SearchBoxContainer.BorderSizePixel = 0
    SearchBoxContainer.LayoutOrder = 1
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
        TweenService:Create(SearchBoxContainer, TweenInfo.new(0.2), { Size = UDim2.new(0, 105, 0, 28), BackgroundTransparency = 0.1 }):Play()
    end)
    SearchInput.FocusLost:Connect(function()
        TweenService:Create(SearchBoxContainer, TweenInfo.new(0.2), { Size = UDim2.new(0, 80, 0, 28), BackgroundTransparency = 0.35 }):Play()
    end)

    -- // =====================================================================
    -- // APPLE iPHONE DYNAMIC ISLAND (Pill z wycięciem kamery + wskaźnikami)
    -- // =====================================================================
    local DynamicIsland = Instance.new("Frame")
    DynamicIsland.Name = "DynamicIsland"
    DynamicIsland.Size = UDim2.new(0, 84, 0, 28)
    DynamicIsland.BackgroundColor3 = Color3.fromRGB(8, 9, 14)
    DynamicIsland.BackgroundTransparency = 0.05
    DynamicIsland.BorderSizePixel = 0
    DynamicIsland.ClipsDescendants = true
    DynamicIsland.LayoutOrder = 2
    DynamicIsland.ZIndex = 18
    DynamicIsland.Parent = RightSide
    Instance.new("UICorner", DynamicIsland).CornerRadius = UDim.new(1, 0)

    local DiStroke = Instance.new("UIStroke", DynamicIsland)
    DiStroke.Color = Color3.fromRGB(70, 75, 95)
    DiStroke.Thickness = 1
    DiStroke.Transparency = 0.55

    -- Apple TrueDepth Camera Sensor Cutout
    local CameraCutout = Instance.new("Frame")
    CameraCutout.Name = "CameraCutout"
    CameraCutout.Size = UDim2.new(0, 7, 0, 7)
    CameraCutout.Position = UDim2.new(0, 7, 0.5, 0)
    CameraCutout.AnchorPoint = Vector2.new(0, 0.5)
    CameraCutout.BackgroundColor3 = Color3.fromRGB(20, 22, 32)
    CameraCutout.BorderSizePixel = 0
    CameraCutout.ZIndex = 19
    CameraCutout.Parent = DynamicIsland
    Instance.new("UICorner", CameraCutout).CornerRadius = UDim.new(1, 0)

    local CameraLens = Instance.new("Frame")
    CameraLens.Size = UDim2.new(0, 3, 0, 3)
    CameraLens.Position = UDim2.new(0.5, 0, 0.5, 0)
    CameraLens.AnchorPoint = Vector2.new(0.5, 0.5)
    CameraLens.BackgroundColor3 = Color3.fromRGB(8, 10, 16)
    CameraLens.BorderSizePixel = 0
    CameraLens.ZIndex = 20
    CameraLens.Parent = CameraCutout
    Instance.new("UICorner", CameraLens).CornerRadius = UDim.new(1, 0)

    -- Apple Privacy Green Indicator LED
    local PrivacyDot = Instance.new("Frame")
    PrivacyDot.Name = "PrivacyDot"
    PrivacyDot.Size = UDim2.new(0, 4, 0, 4)
    PrivacyDot.Position = UDim2.new(0, 18, 0.5, 0)
    PrivacyDot.AnchorPoint = Vector2.new(0, 0.5)
    PrivacyDot.BackgroundColor3 = Color3.fromRGB(52, 199, 89)
    PrivacyDot.BorderSizePixel = 0
    PrivacyDot.ZIndex = 19
    PrivacyDot.Parent = DynamicIsland
    Instance.new("UICorner", PrivacyDot).CornerRadius = UDim.new(1, 0)

    local FpsLabel = Instance.new("TextLabel")
    FpsLabel.Name = "FpsLabel"
    FpsLabel.Text = "60 FPS"
    FpsLabel.Font = Enum.Font.GothamBold
    FpsLabel.TextSize = 9
    FpsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    FpsLabel.Size = UDim2.new(1, -26, 1, 0)
    FpsLabel.Position = UDim2.new(0, 26, 0, 0)
    FpsLabel.BackgroundTransparency = 1
    FpsLabel.TextXAlignment = Enum.TextXAlignment.Left
    FpsLabel.ZIndex = 19
    FpsLabel.Parent = DynamicIsland

    -- Interaktywna animacja rozwijania Dynamic Island (iOS Spring Feel)
    local isHovered = false
    local currentPing = "24ms"
    DynamicIsland.MouseEnter:Connect(function()
        isHovered = true
        TweenService:Create(DynamicIsland, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 114, 0, 28)
        }):Play()
        TweenService:Create(DiStroke, TweenInfo.new(0.2), { Color = Color3.fromRGB(52, 199, 89), Transparency = 0.3 }):Play()
    end)
    DynamicIsland.MouseLeave:Connect(function()
        isHovered = false
        TweenService:Create(DynamicIsland, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 84, 0, 28)
        }):Play()
        TweenService:Create(DiStroke, TweenInfo.new(0.2), { Color = Color3.fromRGB(70, 75, 95), Transparency = 0.55 }):Play()
    end)

    local fpsCount = 0
    local fpsTimer = tick()
    RunService.RenderStepped:Connect(function()
        fpsCount = fpsCount + 1
        if tick() - fpsTimer >= 1 then
            if isHovered then
                FpsLabel.Text = tostring(fpsCount) .. "F • " .. currentPing
            else
                FpsLabel.Text = tostring(fpsCount) .. " FPS"
            end
            fpsCount = 0
            fpsTimer = tick()
        end
    end)

    -- Profil gracza + Przycisk Settings (Liquid Glass Avatar Button)
    local ProfilePill = Instance.new("Frame")
    ProfilePill.Name = "ProfilePill"
    ProfilePill.Size = UDim2.new(0, 44, 0, 28)
    ProfilePill.BackgroundColor3 = Color3.fromRGB(24, 28, 42)
    ProfilePill.BackgroundTransparency = 0.35
    ProfilePill.BorderSizePixel = 0
    ProfilePill.LayoutOrder = 3
    ProfilePill.ZIndex = 18
    ProfilePill.Parent = RightSide
    Instance.new("UICorner", ProfilePill).CornerRadius = UDim.new(1, 0)
    local PpStroke = Instance.new("UIStroke", ProfilePill)
    PpStroke.Color = Color3.fromRGB(55, 62, 90)
    PpStroke.Thickness = 1
    PpStroke.Transparency = 0.6

    local AvatarImg = Instance.new("ImageLabel")
    AvatarImg.Size = UDim2.new(0, 20, 0, 20)
    AvatarImg.Position = UDim2.new(0, 3, 0.5, 0)
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
    SettingsBtn.Size = UDim2.new(0, 13, 0, 13)
    SettingsBtn.Position = UDim2.new(1, -5, 0.5, 0)
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

    -- Kontener przycisków okna (Apple Window Controls na samym prawym brzegu)
    local Controls = Instance.new("Frame")
    Controls.Name = "Controls"
    Controls.Size = UDim2.new(0, 78, 1, 0)
    Controls.BackgroundTransparency = 1
    Controls.LayoutOrder = 4
    Controls.ZIndex = 18
    Controls.Parent = RightSide
    UI.Controls = Controls

    local ControlsLayout = Instance.new("UIListLayout", Controls)
    ControlsLayout.FillDirection = Enum.FillDirection.Horizontal
    ControlsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    ControlsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    ControlsLayout.Padding = UDim.new(0, 4)

    -- // Automatyczne responsywne skalowanie nagłówka (Mobile / Compact Viewports)
    local function updateResponsiveHeader()
        local dockW = FloatingDock.AbsoluteSize.X
        if dockW <= 0 then
            dockW = (UI.MainFrame and UI.MainFrame.AbsoluteSize.X or 860) - 28
        end
        local isNarrow = (dockW < 680) or UI.IsMobile
        if isNarrow then
            DynamicIsland.Visible = false
            SearchBoxContainer.Visible = (dockW >= 550)
            GlassBadge.Visible = (dockW >= 580)
            local rightW = (dockW >= 550 and 190 or 122)
            local leftW = (dockW >= 580 and 150 or 110)
            RightSide.Size = UDim2.new(0, rightW, 1, 0)
            BrandSide.Size = UDim2.new(0, leftW, 1, 0)
            TabList.Position = UDim2.new(0, leftW + 6, 0.5, 0)
            TabList.Size = UDim2.new(1, -(leftW + rightW + 12), 0, 32)
        else
            DynamicIsland.Visible = true
            SearchBoxContainer.Visible = true
            GlassBadge.Visible = true
            RightSide.Size = UDim2.new(0, 284, 1, 0)
            BrandSide.Size = UDim2.new(0, 160, 1, 0)
            TabList.Position = UDim2.new(0, 166, 0.5, 0)
            TabList.Size = UDim2.new(1, -458, 0, 32)
        end
    end
    FloatingDock:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateResponsiveHeader)
    task.defer(updateResponsiveHeader)

    return FloatingDock, TabList
end

return Sidebar