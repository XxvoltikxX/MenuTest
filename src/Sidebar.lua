-- // ==========================================================================
-- // MENUTEST DUAL-DECK MASTER HUB (CYBER-APEX V3.0)
-- // Architektura dwupoziomowa:
-- // Deck 1 (Titlebar 42px): Brand Logo + Status HUD Capsule + Profil VIP + Przyciski okna
-- // Deck 2 (NavDock 44px): Pełnowymiarowy, przestronny pasek zakładek (Tab Pills) + Szukajka + Telemetria
-- // ==========================================================================

local Sidebar = {}

function Sidebar:Create(UI, theme, config, customWidth)
    local TweenService = game:GetService("TweenService")
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local LocalPlayer = Players.LocalPlayer or (Players:GetPropertyChangedSignal("LocalPlayer"):Wait() and Players.LocalPlayer)

    local function getThemeColor(colorKey, fallback)
        if UI and UI.ThemeManager and UI.ThemeManager.GetColor then
            local c = UI.ThemeManager:GetColor(colorKey)
            if c then return c end
        end
        return fallback
    end

    local Icons = UI.Icons or (typeof(getgenv) == "function" and getgenv()._MenuTestIconsModule) or _G._MenuTestIconsModule

    -- Główny kontener dwupoziomowego huba (wysokość łączna: 86px)
    local MasterHub = Instance.new("Frame")
    MasterHub.Name = "MasterHub"
    MasterHub.Size = UDim2.new(1, 0, 0, 86)
    MasterHub.Position = UDim2.new(0, 0, 0, 0)
    MasterHub.BackgroundTransparency = 1
    MasterHub.BorderSizePixel = 0
    MasterHub.ZIndex = 8
    MasterHub.Parent = UI.MainFrame
    UI.Sidebar = MasterHub

    -- // =====================================================================
    -- // DECK 1: COMMAND TITLEBAR (Wysokość: 42px)
    -- // =====================================================================
    local Deck1 = Instance.new("Frame")
    Deck1.Name = "Deck1_Titlebar"
    Deck1.Size = UDim2.new(1, 0, 0, 42)
    Deck1.Position = UDim2.new(0, 0, 0, 0)
    Deck1.BackgroundColor3 = Color3.fromRGB(11, 12, 18)
    Deck1.BorderSizePixel = 0
    Deck1.ZIndex = 9
    Deck1.Parent = MasterHub

    local Deck1Divider = Instance.new("Frame")
    Deck1Divider.Name = "Deck1Divider"
    Deck1Divider.Size = UDim2.new(1, 0, 0, 1)
    Deck1Divider.Position = UDim2.new(0, 0, 1, -1)
    Deck1Divider.BorderSizePixel = 0
    Deck1Divider.BackgroundColor3 = Color3.fromRGB(25, 27, 40)
    Deck1Divider.ZIndex = 10
    Deck1Divider.Parent = Deck1

    -- Brand (Logo + Tytuł + Badge)
    local BrandContainer = Instance.new("Frame")
    BrandContainer.Name = "BrandContainer"
    BrandContainer.Size = UDim2.new(0, 220, 1, 0)
    BrandContainer.Position = UDim2.new(0, 14, 0, 0)
    BrandContainer.BackgroundTransparency = 1
    BrandContainer.ZIndex = 10
    BrandContainer.Parent = Deck1

    local BrandLayout = Instance.new("UIListLayout", BrandContainer)
    BrandLayout.FillDirection = Enum.FillDirection.Horizontal
    BrandLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    BrandLayout.Padding = UDim.new(0, 8)

    local LogoBox = Instance.new("Frame")
    LogoBox.Name = "LogoBox"
    LogoBox.Size = UDim2.new(0, 26, 0, 26)
    LogoBox.BackgroundColor3 = Color3.fromRGB(99, 102, 241)
    LogoBox.BorderSizePixel = 0
    LogoBox.ZIndex = 11
    LogoBox.Parent = BrandContainer
    Instance.new("UICorner", LogoBox).CornerRadius = UDim.new(0, 7)

    local LogoGrad = Instance.new("UIGradient", LogoBox)
    LogoGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(99, 102, 241)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(168, 85, 247))
    })
    LogoGrad.Rotation = 45

    local LogoIcon = Instance.new("ImageLabel")
    LogoIcon.Size = UDim2.new(0, 15, 0, 15)
    LogoIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
    LogoIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    LogoIcon.BackgroundTransparency = 1
    LogoIcon.ImageColor3 = Color3.fromRGB(255, 255, 255)
    LogoIcon.ZIndex = 12
    LogoIcon.Parent = LogoBox
    if Icons and Icons.Apply then Icons:Apply(LogoIcon, "zap") end

    local BrandTitle = Instance.new("TextLabel")
    BrandTitle.Text = config.Name or "UNIVERSAL"
    BrandTitle.Font = Enum.Font.GothamBold
    BrandTitle.TextSize = 13
    BrandTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    BrandTitle.AutomaticSize = Enum.AutomaticSize.X
    BrandTitle.Size = UDim2.new(0, 0, 1, 0)
    BrandTitle.BackgroundTransparency = 1
    BrandTitle.TextXAlignment = Enum.TextXAlignment.Left
    BrandTitle.ZIndex = 11
    BrandTitle.Parent = BrandContainer

    local VersionBadge = Instance.new("TextLabel")
    VersionBadge.Text = "v3.0 ELITE"
    VersionBadge.Font = Enum.Font.GothamBold
    VersionBadge.TextSize = 9
    VersionBadge.TextColor3 = Color3.fromRGB(129, 140, 248)
    VersionBadge.Size = UDim2.new(0, 58, 0, 18)
    VersionBadge.BackgroundColor3 = Color3.fromRGB(26, 28, 44)
    VersionBadge.ZIndex = 11
    VersionBadge.Parent = BrandContainer
    Instance.new("UICorner", VersionBadge).CornerRadius = UDim.new(0, 4)
    local VbStroke = Instance.new("UIStroke", VersionBadge)
    VbStroke.Color = Color3.fromRGB(45, 48, 75)
    VbStroke.Thickness = 1

    -- Środek Deck 1: Live Status Capsule
    local StatusCapsule = Instance.new("Frame")
    StatusCapsule.Name = "StatusCapsule"
    StatusCapsule.Size = UDim2.new(0, 240, 0, 22)
    StatusCapsule.Position = UDim2.new(0.5, 0, 0.5, 0)
    StatusCapsule.AnchorPoint = Vector2.new(0.5, 0.5)
    StatusCapsule.BackgroundColor3 = Color3.fromRGB(15, 17, 26)
    StatusCapsule.BorderSizePixel = 0
    StatusCapsule.ZIndex = 10
    StatusCapsule.Parent = Deck1
    Instance.new("UICorner", StatusCapsule).CornerRadius = UDim.new(1, 0)
    local ScStroke = Instance.new("UIStroke", StatusCapsule)
    ScStroke.Color = Color3.fromRGB(30, 33, 48)
    ScStroke.Thickness = 1

    local LedDot = Instance.new("Frame")
    LedDot.Size = UDim2.new(0, 6, 0, 6)
    LedDot.Position = UDim2.new(0, 10, 0.5, 0)
    LedDot.AnchorPoint = Vector2.new(0, 0.5)
    LedDot.BackgroundColor3 = Color3.fromRGB(16, 185, 129)
    LedDot.BorderSizePixel = 0
    LedDot.ZIndex = 11
    LedDot.Parent = StatusCapsule
    Instance.new("UICorner", LedDot).CornerRadius = UDim.new(1, 0)

    local StatusText = Instance.new("TextLabel")
    StatusText.Text = "SYSTEM SECURE • 0 HOOKS DETECTED"
    StatusText.Font = Enum.Font.GothamBold
    StatusText.TextSize = 9
    StatusText.TextColor3 = Color3.fromRGB(148, 163, 184)
    StatusText.Size = UDim2.new(1, -24, 1, 0)
    StatusText.Position = UDim2.new(0, 22, 0, 0)
    StatusText.BackgroundTransparency = 1
    StatusText.TextXAlignment = Enum.TextXAlignment.Left
    StatusText.ZIndex = 11
    StatusText.Parent = StatusCapsule

    -- Prawa strona Deck 1: Profil gracza + Controls (Min, Max, Close)
    local Deck1Right = Instance.new("Frame")
    Deck1Right.Name = "Deck1Right"
    Deck1Right.Size = UDim2.new(0, 245, 1, 0)
    Deck1Right.Position = UDim2.new(1, -12, 0.5, 0)
    Deck1Right.AnchorPoint = Vector2.new(1, 0.5)
    Deck1Right.BackgroundTransparency = 1
    Deck1Right.ZIndex = 10
    Deck1Right.Parent = Deck1

    local Deck1RightLayout = Instance.new("UIListLayout", Deck1Right)
    Deck1RightLayout.FillDirection = Enum.FillDirection.Horizontal
    Deck1RightLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    Deck1RightLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    Deck1RightLayout.Padding = UDim.new(0, 10)

    -- User Pill
    local UserPill = Instance.new("Frame")
    UserPill.Name = "UserPill"
    UserPill.Size = UDim2.new(0, 130, 0, 28)
    UserPill.BackgroundColor3 = Color3.fromRGB(18, 20, 30)
    UserPill.BorderSizePixel = 0
    UserPill.ZIndex = 11
    UserPill.Parent = Deck1Right
    Instance.new("UICorner", UserPill).CornerRadius = UDim.new(1, 0)
    local UpStroke = Instance.new("UIStroke", UserPill)
    UpStroke.Color = Color3.fromRGB(36, 39, 56)
    UpStroke.Thickness = 1

    local AvatarImg = Instance.new("ImageLabel")
    AvatarImg.Size = UDim2.new(0, 20, 0, 20)
    AvatarImg.Position = UDim2.new(0, 4, 0.5, 0)
    AvatarImg.AnchorPoint = Vector2.new(0, 0.5)
    AvatarImg.BackgroundColor3 = Color3.fromRGB(30, 32, 45)
    AvatarImg.BorderSizePixel = 0
    AvatarImg.ZIndex = 12
    AvatarImg.Parent = UserPill
    Instance.new("UICorner", AvatarImg).CornerRadius = UDim.new(1, 0)

    task.spawn(function()
        if LocalPlayer and LocalPlayer.UserId then
            local thumb, isReady = Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
            if isReady and thumb then AvatarImg.Image = thumb end
        end
    end)

    local NameLabel = Instance.new("TextLabel")
    NameLabel.Text = (LocalPlayer and LocalPlayer.DisplayName) or "XxVOLTIKxX"
    NameLabel.Font = Enum.Font.GothamBold
    NameLabel.TextSize = 10
    NameLabel.TextColor3 = Color3.fromRGB(241, 245, 249)
    NameLabel.Size = UDim2.new(1, -54, 1, 0)
    NameLabel.Position = UDim2.new(0, 28, 0, 0)
    NameLabel.BackgroundTransparency = 1
    NameLabel.TextXAlignment = Enum.TextXAlignment.Left
    NameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    NameLabel.ZIndex = 12
    NameLabel.Parent = UserPill

    local SettingsBtn = Instance.new("ImageButton")
    SettingsBtn.Name = "SettingsBtn"
    SettingsBtn.Size = UDim2.new(0, 15, 0, 15)
    SettingsBtn.Position = UDim2.new(1, -6, 0.5, 0)
    SettingsBtn.AnchorPoint = Vector2.new(1, 0.5)
    SettingsBtn.BackgroundTransparency = 1
    SettingsBtn.ImageColor3 = Color3.fromRGB(148, 163, 184)
    SettingsBtn.ZIndex = 12
    SettingsBtn.Parent = UserPill
    if Icons and Icons.Apply then Icons:Apply(SettingsBtn, "settings") end
    UI.SettingsBtn = SettingsBtn
    UI.SettingsIcon = SettingsBtn

    SettingsBtn.MouseEnter:Connect(function()
        TweenService:Create(SettingsBtn, TweenInfo.new(0.25), { ImageColor3 = Color3.fromRGB(255, 255, 255), Rotation = 45 }):Play()
    end)
    SettingsBtn.MouseLeave:Connect(function()
        if not UI.IsSettingsOpen then
            TweenService:Create(SettingsBtn, TweenInfo.new(0.25), { ImageColor3 = Color3.fromRGB(148, 163, 184), Rotation = 0 }):Play()
        end
    end)
    SettingsBtn.MouseButton1Click:Connect(function()
        if UI.OpenSettings then UI:OpenSettings() end
    end)

    -- Kontener przycisków okna (Controls: Min, Max, Close)
    local Controls = Instance.new("Frame")
    Controls.Name = "Controls"
    Controls.Size = UDim2.new(0, 95, 1, 0)
    Controls.BackgroundTransparency = 1
    Controls.ZIndex = 11
    Controls.Parent = Deck1Right
    UI.Controls = Controls

    local ControlsLayout = Instance.new("UIListLayout", Controls)
    ControlsLayout.FillDirection = Enum.FillDirection.Horizontal
    ControlsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    ControlsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    ControlsLayout.Padding = UDim.new(0, 5)

    -- // =====================================================================
    -- // DECK 2: NAVIGATION & TOOL DOCK (Wysokość: 44px)
    -- // =====================================================================
    local Deck2 = Instance.new("Frame")
    Deck2.Name = "Deck2_NavDock"
    Deck2.Size = UDim2.new(1, 0, 0, 44)
    Deck2.Position = UDim2.new(0, 0, 0, 42)
    Deck2.BackgroundColor3 = Color3.fromRGB(9, 10, 15)
    Deck2.BorderSizePixel = 0
    Deck2.ZIndex = 9
    Deck2.Parent = MasterHub

    local Deck2Divider = Instance.new("Frame")
    Deck2Divider.Name = "Deck2Divider"
    Deck2Divider.Size = UDim2.new(1, 0, 0, 1)
    Deck2Divider.Position = UDim2.new(0, 0, 1, -1)
    Deck2Divider.BorderSizePixel = 0
    Deck2Divider.BackgroundColor3 = Color3.fromRGB(20, 22, 32)
    Deck2Divider.ZIndex = 10
    Deck2Divider.Parent = Deck2

    -- Lewa strona: PEŁNOWYMIAROWY, PRZESTRONNY PASEK ZAKŁADEK (TAB LIST)
    local TabList = Instance.new("ScrollingFrame")
    TabList.Name = "TopTabBar"
    TabList.Size = UDim2.new(1, -280, 0, 34)
    TabList.Position = UDim2.new(0, 14, 0.5, 0)
    TabList.AnchorPoint = Vector2.new(0, 0.5)
    TabList.BackgroundTransparency = 1
    TabList.BorderSizePixel = 0
    pcall(function()
        TabList.ScrollingDirection = Enum.ScrollingDirection.X
    end)
    TabList.ScrollBarThickness = 0
    TabList.CanvasSize = UDim2.new(0, 0, 0, 0)
    TabList.AutomaticCanvasSize = Enum.AutomaticSize.X
    TabList.ZIndex = 10
    TabList.Parent = Deck2
    UI.TabList = TabList

    local TabLayout = Instance.new("UIListLayout", TabList)
    TabLayout.FillDirection = Enum.FillDirection.Horizontal
    TabLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    TabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    TabLayout.Padding = UDim.new(0, 8)
    TabLayout.SortOrder = Enum.SortOrder.LayoutOrder

    -- Prawa strona Deck 2: Wyszukiwarka + Telemetria
    local Deck2Right = Instance.new("Frame")
    Deck2Right.Name = "Deck2Right"
    Deck2Right.Size = UDim2.new(0, 260, 1, 0)
    Deck2Right.Position = UDim2.new(1, -12, 0.5, 0)
    Deck2Right.AnchorPoint = Vector2.new(1, 0.5)
    Deck2Right.BackgroundTransparency = 1
    Deck2Right.ZIndex = 10
    Deck2Right.Parent = Deck2

    local Deck2RightLayout = Instance.new("UIListLayout", Deck2Right)
    Deck2RightLayout.FillDirection = Enum.FillDirection.Horizontal
    Deck2RightLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    Deck2RightLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    Deck2RightLayout.Padding = UDim.new(0, 8)

    -- Szukajka
    local SearchBoxContainer = Instance.new("Frame")
    SearchBoxContainer.Name = "SearchBoxContainer"
    SearchBoxContainer.Size = UDim2.new(0, 140, 0, 26)
    SearchBoxContainer.BackgroundColor3 = Color3.fromRGB(16, 17, 26)
    SearchBoxContainer.BorderSizePixel = 0
    SearchBoxContainer.ZIndex = 11
    SearchBoxContainer.Parent = Deck2Right
    Instance.new("UICorner", SearchBoxContainer).CornerRadius = UDim.new(0, 6)
    local SbStroke = Instance.new("UIStroke", SearchBoxContainer)
    SbStroke.Color = Color3.fromRGB(30, 33, 48)
    SbStroke.Thickness = 1

    local SearchIcon = Instance.new("ImageLabel")
    SearchIcon.Size = UDim2.new(0, 12, 0, 12)
    SearchIcon.Position = UDim2.new(0, 7, 0.5, 0)
    SearchIcon.AnchorPoint = Vector2.new(0, 0.5)
    SearchIcon.BackgroundTransparency = 1
    SearchIcon.ImageColor3 = Color3.fromRGB(120, 125, 145)
    SearchIcon.ZIndex = 12
    SearchIcon.Parent = SearchBoxContainer
    if Icons and Icons.Apply then Icons:Apply(SearchIcon, "search") end

    local SearchInput = Instance.new("TextBox")
    SearchInput.Name = "SearchInput"
    SearchInput.Size = UDim2.new(1, -24, 1, 0)
    SearchInput.Position = UDim2.new(0, 22, 0, 0)
    SearchInput.BackgroundTransparency = 1
    SearchInput.Font = Enum.Font.GothamMedium
    SearchInput.Text = ""
    SearchInput.PlaceholderText = "Szukaj..."
    SearchInput.PlaceholderColor3 = Color3.fromRGB(90, 95, 115)
    SearchInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    SearchInput.TextSize = 11
    SearchInput.TextXAlignment = Enum.TextXAlignment.Left
    SearchInput.ClearTextOnFocus = false
    SearchInput.ZIndex = 12
    SearchInput.Parent = SearchBoxContainer
    UI.SearchInput = SearchInput

    -- Telemetria (FPS & Ping)
    local FpsBadge = Instance.new("TextLabel")
    FpsBadge.Text = "60 FPS"
    FpsBadge.Font = Enum.Font.GothamBold
    FpsBadge.TextSize = 10
    FpsBadge.TextColor3 = Color3.fromRGB(16, 185, 129)
    FpsBadge.Size = UDim2.new(0, 50, 0, 24)
    FpsBadge.BackgroundColor3 = Color3.fromRGB(16, 17, 26)
    FpsBadge.ZIndex = 11
    FpsBadge.Parent = Deck2Right
    Instance.new("UICorner", FpsBadge).CornerRadius = UDim.new(0, 6)
    local FpsStroke = Instance.new("UIStroke", FpsBadge)
    FpsStroke.Color = Color3.fromRGB(30, 33, 48)
    FpsStroke.Thickness = 1

    local PingBadge = Instance.new("TextLabel")
    PingBadge.Text = "20 ms"
    PingBadge.Font = Enum.Font.GothamBold
    PingBadge.TextSize = 10
    PingBadge.TextColor3 = Color3.fromRGB(99, 102, 241)
    PingBadge.Size = UDim2.new(0, 48, 0, 24)
    PingBadge.BackgroundColor3 = Color3.fromRGB(16, 17, 26)
    PingBadge.ZIndex = 11
    PingBadge.Parent = Deck2Right
    Instance.new("UICorner", PingBadge).CornerRadius = UDim.new(0, 6)
    local PingStroke = Instance.new("UIStroke", PingBadge)
    PingStroke.Color = Color3.fromRGB(30, 33, 48)
    PingStroke.Thickness = 1

    local fpsCount = 0
    local fpsTimer = tick()
    RunService.RenderStepped:Connect(function()
        fpsCount = fpsCount + 1
        if tick() - fpsTimer >= 1 then
            FpsBadge.Text = tostring(fpsCount) .. " FPS"
            fpsCount = 0
            fpsTimer = tick()
        end
    end)

    task.spawn(function()
        while task.wait(1.5) do
            if not MasterHub.Parent then break end
            local stat = game:GetService("Stats")
            local net = stat and stat:FindFirstChild("Network")
            local serv = net and net:FindFirstChild("ServerStatsItem")
            local pingVal = serv and serv:FindFirstChild("Data Ping")
            if pingVal then
                PingBadge.Text = string.format("%d ms", math.floor(pingVal:GetValue()))
            end
        end
    end)

    return MasterHub, TabList
end

return Sidebar