-- // ==========================================================================
-- // MENUTEST MASTER HEADER & NAVIGATION BAR (CYBER-APEX STYLE)
-- // Pełnowymiarowy, luksusowy panel górny zastępujący toporny boczny sidebar.
-- // Zawiera: Branding ze świecącym badge'em, poziomy pasek zakładek (Tab Pills),
-- // kartę użytkownika z awatarem i statusem online oraz przyciski sterujące oknem.
-- // ==========================================================================

local Sidebar = {}

function Sidebar:Create(UI, theme, config, customWidth)
    local TweenService = game:GetService("TweenService")
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):Wait() and Players.LocalPlayer

    local function getThemeColor(colorKey, fallback)
        if UI and UI.ThemeManager and UI.ThemeManager.GetColor then
            local c = UI.ThemeManager:GetColor(colorKey)
            if c then return c end
        end
        return fallback
    end

    local Icons = UI.Icons or (typeof(getgenv) == "function" and getgenv()._MenuTestIconsModule) or _G._MenuTestIconsModule

    -- Główna ramka nagłówka (Master Header Bar)
    local HeaderFrame = Instance.new("Frame")
    HeaderFrame.Name = "MasterHeader"
    HeaderFrame.Size = UDim2.new(1, 0, 0, 52)
    HeaderFrame.Position = UDim2.new(0, 0, 0, 0)
    HeaderFrame.BackgroundColor3 = getThemeColor("Main", Color3.fromRGB(12, 13, 19))
    HeaderFrame.BackgroundTransparency = 0.05
    HeaderFrame.BorderSizePixel = 0
    HeaderFrame.ZIndex = 8
    HeaderFrame.Parent = UI.MainFrame
    UI.Sidebar = HeaderFrame -- zachowanie referencji dla kompatybilności wstecznej

    -- Subtelna pozioma linia oddzielająca nagłówek od treści
    local HeaderDivider = Instance.new("Frame")
    HeaderDivider.Name = "HeaderDivider"
    HeaderDivider.Size = UDim2.new(1, 0, 0, 1)
    HeaderDivider.Position = UDim2.new(0, 0, 1, -1)
    HeaderDivider.BorderSizePixel = 0
    HeaderDivider.BackgroundColor3 = getThemeColor("Accent", Color3.fromRGB(35, 36, 50))
    HeaderDivider.ZIndex = 10
    HeaderDivider.Parent = HeaderFrame
    if UI.ThemeManager then UI.ThemeManager:Register(HeaderDivider, "BackgroundColor3", "Accent") end

    -- =========================================================================
    -- 1. BRANDING (LOGO + TYTUŁ + BADGE)
    -- =========================================================================
    local BrandContainer = Instance.new("Frame")
    BrandContainer.Name = "BrandContainer"
    BrandContainer.Size = UDim2.new(0, 200, 1, 0)
    BrandContainer.Position = UDim2.new(0, 14, 0, 0)
    BrandContainer.BackgroundTransparency = 1
    BrandContainer.ZIndex = 9
    BrandContainer.Parent = HeaderFrame

    local BrandLayout = Instance.new("UIListLayout", BrandContainer)
    BrandLayout.FillDirection = Enum.FillDirection.Horizontal
    BrandLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    BrandLayout.Padding = UDim.new(0, 10)

    -- Zaokrąglona kasetka z logo
    local LogoBox = Instance.new("Frame")
    LogoBox.Name = "LogoBox"
    LogoBox.Size = UDim2.new(0, 32, 0, 32)
    LogoBox.BackgroundColor3 = Color3.fromRGB(99, 102, 241)
    LogoBox.BorderSizePixel = 0
    LogoBox.ZIndex = 10
    LogoBox.Parent = BrandContainer

    local LogoCorner = Instance.new("UICorner", LogoBox)
    LogoCorner.CornerRadius = UDim.new(0, 8)

    local LogoGradient = Instance.new("UIGradient", LogoBox)
    LogoGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(99, 102, 241)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(168, 85, 247))
    })
    LogoGradient.Rotation = 45

    local LogoIcon = Instance.new("ImageLabel")
    LogoIcon.Name = "LogoIcon"
    LogoIcon.Size = UDim2.new(0, 18, 0, 18)
    LogoIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
    LogoIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    LogoIcon.BackgroundTransparency = 1
    LogoIcon.ImageColor3 = Color3.fromRGB(255, 255, 255)
    LogoIcon.ZIndex = 11
    LogoIcon.Parent = LogoBox
    if Icons and Icons.Apply then
        Icons:Apply(LogoIcon, "zap")
    end

    -- Napis Brandu
    local TextBlock = Instance.new("Frame")
    TextBlock.Name = "TextBlock"
    TextBlock.Size = UDim2.new(0, 150, 0, 34)
    TextBlock.BackgroundTransparency = 1
    TextBlock.ZIndex = 10
    TextBlock.Parent = BrandContainer

    local TextBlockLayout = Instance.new("UIListLayout", TextBlock)
    TextBlockLayout.FillDirection = Enum.FillDirection.Vertical
    TextBlockLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    TextBlockLayout.Padding = UDim.new(0, 1)

    local BrandTitle = Instance.new("TextLabel")
    BrandTitle.Name = "Title"
    BrandTitle.Font = Enum.Font.GothamBold
    BrandTitle.TextSize = 14
    BrandTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    BrandTitle.TextXAlignment = Enum.TextXAlignment.Left
    BrandTitle.Size = UDim2.new(1, 0, 0, 16)
    BrandTitle.BackgroundTransparency = 1
    BrandTitle.ZIndex = 11
    BrandTitle.Text = config.Name or "UNIVERSAL"
    BrandTitle.Parent = TextBlock
    if UI.ThemeManager then UI.ThemeManager:Register(BrandTitle, "TextColor3", "Text") end

    local BrandSubtitle = Instance.new("TextLabel")
    BrandSubtitle.Name = "Subtitle"
    BrandSubtitle.Font = Enum.Font.GothamMedium
    BrandSubtitle.TextSize = 10
    BrandSubtitle.TextColor3 = Color3.fromRGB(129, 140, 248)
    BrandSubtitle.TextXAlignment = Enum.TextXAlignment.Left
    BrandSubtitle.Size = UDim2.new(1, 0, 0, 14)
    BrandSubtitle.BackgroundTransparency = 1
    BrandSubtitle.ZIndex = 11
    BrandSubtitle.Text = "SUITE • v2.5 ELITE"
    BrandSubtitle.Parent = TextBlock

    -- =========================================================================
    -- 2. POZIOMY PASEK ZAKŁADEK (TAB PILLS CONTAINER)
    -- =========================================================================
    local TabList = Instance.new("ScrollingFrame")
    TabList.Name = "TopTabBar"
    TabList.Size = UDim2.new(1, -440, 0, 38)
    TabList.Position = UDim2.new(0, 215, 0.5, 0)
    TabList.AnchorPoint = Vector2.new(0, 0.5)
    TabList.BackgroundTransparency = 1
    TabList.BorderSizePixel = 0
    TabList.ScrollingDirection = Enum.ScrollingDirection.Horizontal
    TabList.ScrollBarThickness = 0
    TabList.CanvasSize = UDim2.new(0, 0, 0, 0)
    TabList.AutomaticCanvasSize = Enum.AutomaticSize.X
    TabList.ZIndex = 9
    TabList.Parent = HeaderFrame
    UI.TabList = TabList

    local TabLayout = Instance.new("UIListLayout", TabList)
    TabLayout.FillDirection = Enum.FillDirection.Horizontal
    TabLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    TabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    TabLayout.Padding = UDim.new(0, 6)
    TabLayout.SortOrder = Enum.SortOrder.LayoutOrder

    local TabPadding = Instance.new("UIPadding", TabList)
    TabPadding.PaddingLeft = UDim.new(0, 4)
    TabPadding.PaddingRight = UDim.new(0, 4)

    -- =========================================================================
    -- 3. PRAWA STRONA: PROFIL + PRZYCISKI OKNA
    -- =========================================================================
    local RightContainer = Instance.new("Frame")
    RightContainer.Name = "RightContainer"
    RightContainer.Size = UDim2.new(0, 215, 1, 0)
    RightContainer.Position = UDim2.new(1, -10, 0.5, 0)
    RightContainer.AnchorPoint = Vector2.new(1, 0.5)
    RightContainer.BackgroundTransparency = 1
    RightContainer.ZIndex = 9
    RightContainer.Parent = HeaderFrame

    local RightLayout = Instance.new("UIListLayout", RightContainer)
    RightLayout.FillDirection = Enum.FillDirection.Horizontal
    RightLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    RightLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    RightLayout.Padding = UDim.new(0, 10)

    -- Karta użytkownika (User Capsule)
    local UserPill = Instance.new("Frame")
    UserPill.Name = "UserPill"
    UserPill.Size = UDim2.new(0, 115, 0, 30)
    UserPill.BackgroundColor3 = Color3.fromRGB(18, 19, 28)
    UserPill.BorderSizePixel = 0
    UserPill.ZIndex = 10
    UserPill.Parent = RightContainer

    local PillCorner = Instance.new("UICorner", UserPill)
    PillCorner.CornerRadius = UDim.new(1, 0)

    local PillStroke = Instance.new("UIStroke", UserPill)
    PillStroke.Color = Color3.fromRGB(38, 40, 58)
    PillStroke.Thickness = 1

    -- Awatar
    local AvatarImg = Instance.new("ImageLabel")
    AvatarImg.Name = "Avatar"
    AvatarImg.Size = UDim2.new(0, 22, 0, 22)
    AvatarImg.Position = UDim2.new(0, 4, 0.5, 0)
    AvatarImg.AnchorPoint = Vector2.new(0, 0.5)
    AvatarImg.BackgroundColor3 = Color3.fromRGB(30, 32, 45)
    AvatarImg.BorderSizePixel = 0
    AvatarImg.ZIndex = 11
    AvatarImg.Parent = UserPill
    Instance.new("UICorner", AvatarImg).CornerRadius = UDim.new(1, 0)

    task.spawn(function()
        if LocalPlayer and LocalPlayer.UserId then
            local thumbType = Enum.ThumbnailType.HeadShot
            local thumbSize = Enum.ThumbnailSize.Size48x48
            local content, isReady = Players:GetUserThumbnailAsync(LocalPlayer.UserId, thumbType, thumbSize)
            if isReady and content then
                AvatarImg.Image = content
            end
        end
    end)

    -- Status Online Dot
    local OnlineDot = Instance.new("Frame")
    OnlineDot.Name = "OnlineDot"
    OnlineDot.Size = UDim2.new(0, 7, 0, 7)
    OnlineDot.Position = UDim2.new(1, -2, 1, -2)
    OnlineDot.AnchorPoint = Vector2.new(1, 1)
    OnlineDot.BackgroundColor3 = Color3.fromRGB(16, 185, 129)
    OnlineDot.BorderSizePixel = 0
    OnlineDot.ZIndex = 12
    OnlineDot.Parent = AvatarImg
    Instance.new("UICorner", OnlineDot).CornerRadius = UDim.new(1, 0)

    -- Nick gracza
    local NameLabel = Instance.new("TextLabel")
    NameLabel.Name = "Username"
    NameLabel.Font = Enum.Font.GothamBold
    NameLabel.TextSize = 10
    NameLabel.TextColor3 = Color3.fromRGB(241, 245, 249)
    NameLabel.TextXAlignment = Enum.TextXAlignment.Left
    NameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    NameLabel.Size = UDim2.new(1, -56, 1, 0)
    NameLabel.Position = UDim2.new(0, 32, 0, 0)
    NameLabel.BackgroundTransparency = 1
    NameLabel.ZIndex = 11
    NameLabel.Text = (LocalPlayer and LocalPlayer.DisplayName) or "XxVOLTIKxX"
    NameLabel.Parent = UserPill

    -- Przycisk Settings (koło zębate)
    local SettingsBtn = Instance.new("ImageButton")
    SettingsBtn.Name = "SettingsBtn"
    SettingsBtn.Size = UDim2.new(0, 16, 0, 16)
    SettingsBtn.Position = UDim2.new(1, -6, 0.5, 0)
    SettingsBtn.AnchorPoint = Vector2.new(1, 0.5)
    SettingsBtn.BackgroundTransparency = 1
    SettingsBtn.ImageColor3 = Color3.fromRGB(148, 163, 184)
    SettingsBtn.ZIndex = 11
    SettingsBtn.Parent = UserPill
    if Icons and Icons.Apply then
        Icons:Apply(SettingsBtn, "settings")
    end
    UI.SettingsBtn = SettingsBtn
    UI.SettingsIcon = SettingsBtn

    SettingsBtn.MouseEnter:Connect(function()
        TweenService:Create(SettingsBtn, TweenInfo.new(0.25), {
            ImageColor3 = Color3.fromRGB(255, 255, 255),
            Rotation = 45
        }):Play()
    end)
    SettingsBtn.MouseLeave:Connect(function()
        if not UI.IsSettingsOpen then
            TweenService:Create(SettingsBtn, TweenInfo.new(0.25), {
                ImageColor3 = Color3.fromRGB(148, 163, 184),
                Rotation = 0
            }):Play()
        end
    end)
    SettingsBtn.MouseButton1Click:Connect(function()
        if UI.OpenSettings then
            UI:OpenSettings()
        end
    end)

    -- Kontener przycisków okna (Controls: Min, Close)
    local Controls = Instance.new("Frame")
    Controls.Name = "Controls"
    Controls.Size = UDim2.new(0, 70, 1, 0)
    Controls.BackgroundTransparency = 1
    Controls.ZIndex = 10
    Controls.Parent = RightContainer
    UI.Controls = Controls

    local ControlsLayout = Instance.new("UIListLayout", Controls)
    ControlsLayout.FillDirection = Enum.FillDirection.Horizontal
    ControlsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    ControlsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    ControlsLayout.Padding = UDim.new(0, 5)

    return HeaderFrame, TabList
end

return Sidebar