local Sidebar = {}

function Sidebar:Create(UI, theme, config, customWidth)
    local TweenService = game:GetService("TweenService")
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):Wait() and Players.LocalPlayer

    local sidebarW = customWidth or (config and config.SidebarWidth) or 210
    local isCompact = sidebarW <= 170

    local function getThemeColor(colorKey, fallback)
        if UI and UI.ThemeManager and UI.ThemeManager.GetColor then
            local c = UI.ThemeManager:GetColor(colorKey)
            if c then return c end
        end
        return fallback
    end

    local Icons = UI.Icons or (typeof(getgenv) == "function" and getgenv()._MenuTestIconsModule) or _G._MenuTestIconsModule

    -- Główna ramka sidebara z ciemnym tłem i delikatnym oddzieleniem
    local SidebarFrame = Instance.new("Frame")
    SidebarFrame.Name = "Sidebar"
    SidebarFrame.Size = UDim2.new(0, sidebarW, 1, 0)
    SidebarFrame.Position = UDim2.new(0, 0, 0, 0)
    SidebarFrame.BackgroundColor3 = getThemeColor("Main", Color3.fromRGB(13, 13, 17))
    SidebarFrame.BackgroundTransparency = 0.15
    SidebarFrame.BorderSizePixel = 0
    SidebarFrame.ZIndex = 5
    SidebarFrame.Parent = UI.MainFrame
    UI.Sidebar = SidebarFrame
    if UI.ThemeManager then UI.ThemeManager:Register(SidebarFrame, "BackgroundColor3", "Main") end

    -- Subtelna pionowa linia oddzielająca sidebar od treści
    local SidebarDivider = Instance.new("Frame")
    SidebarDivider.Name = "SidebarDivider"
    SidebarDivider.Size = UDim2.new(0, 1, 1, 0)
    SidebarDivider.Position = UDim2.new(1, -1, 0, 0)
    SidebarDivider.BorderSizePixel = 0
    SidebarDivider.BackgroundColor3 = getThemeColor("Accent", Color3.fromRGB(35, 36, 46))
    SidebarDivider.ZIndex = 10
    SidebarDivider.Parent = SidebarFrame
    if UI.ThemeManager then UI.ThemeManager:Register(SidebarDivider, "BackgroundColor3", "Accent") end

    -- =========================================================================
    -- 1. BRANDING & LOGO HEADER (GÓRNY LOGOTYP)
    -- =========================================================================
    local BrandHeader = Instance.new("Frame")
    BrandHeader.Name = "BrandHeader"
    BrandHeader.Size = UDim2.new(1, 0, 0, 56)
    BrandHeader.Position = UDim2.new(0, 0, 0, 0)
    BrandHeader.BackgroundTransparency = 1
    BrandHeader.Parent = SidebarFrame

    local BrandPadding = Instance.new("UIPadding", BrandHeader)
    BrandPadding.PaddingLeft = UDim.new(0, 14)
    BrandPadding.PaddingRight = UDim.new(0, 14)
    BrandPadding.PaddingTop = UDim.new(0, 12)
    BrandPadding.PaddingBottom = UDim.new(0, 8)

    -- Kasetka z logo z gradientem akcentowym
    local LogoBadge = Instance.new("Frame")
    LogoBadge.Name = "LogoBadge"
    LogoBadge.Size = UDim2.new(0, 32, 0, 32)
    LogoBadge.Position = UDim2.new(0, 0, 0.5, 0)
    LogoBadge.AnchorPoint = Vector2.new(0, 0.5)
    LogoBadge.BackgroundColor3 = getThemeColor("Accent", Color3.fromRGB(99, 102, 241))
    LogoBadge.BorderSizePixel = 0
    LogoBadge.Parent = BrandHeader
    Instance.new("UICorner", LogoBadge).CornerRadius = UDim.new(0, 8)

    local LogoGradient = Instance.new("UIGradient", LogoBadge)
    LogoGradient.Rotation = 45
    LogoGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(99, 102, 241)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(168, 85, 247))
    })

    local LogoIcon = Instance.new("ImageLabel")
    LogoIcon.Name = "Icon"
    LogoIcon.Size = UDim2.new(0, 18, 0, 18)
    LogoIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
    LogoIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    LogoIcon.BackgroundTransparency = 1
    LogoIcon.ImageColor3 = Color3.fromRGB(255, 255, 255)
    LogoIcon.Parent = LogoBadge
    if Icons and Icons.Apply then
        Icons:Apply(LogoIcon, "zap")
    end

    local BrandTextFrame = Instance.new("Frame")
    BrandTextFrame.Name = "BrandText"
    BrandTextFrame.Size = UDim2.new(1, -42, 1, 0)
    BrandTextFrame.Position = UDim2.new(0, 40, 0, 0)
    BrandTextFrame.BackgroundTransparency = 1
    BrandTextFrame.Parent = BrandHeader

    local rawName = tostring(config.Name or config.Title or "UNIVERSAL")
    local BrandTitle = Instance.new("TextLabel")
    BrandTitle.Name = "Title"
    BrandTitle.Text = string.upper(rawName)
    BrandTitle.Font = Enum.Font.GothamBold
    BrandTitle.TextSize = 13
    BrandTitle.TextColor3 = getThemeColor("Text", Color3.fromRGB(255, 255, 255))
    BrandTitle.TextXAlignment = Enum.TextXAlignment.Left
    BrandTitle.Size = UDim2.new(1, 0, 0, 16)
    BrandTitle.Position = UDim2.new(0, 0, 0, 1)
    BrandTitle.BackgroundTransparency = 1
    BrandTitle.Parent = BrandTextFrame
    if UI.ThemeManager then UI.ThemeManager:Register(BrandTitle, "TextColor3", "Text") end

    local BrandSubtitle = Instance.new("TextLabel")
    BrandSubtitle.Name = "Subtitle"
    BrandSubtitle.Text = "SUITE • v2.4"
    BrandSubtitle.Font = Enum.Font.GothamBold
    BrandSubtitle.TextSize = 9
    BrandSubtitle.TextColor3 = getThemeColor("Accent", Color3.fromRGB(129, 140, 248))
    BrandSubtitle.TextXAlignment = Enum.TextXAlignment.Left
    BrandSubtitle.Size = UDim2.new(1, 0, 0, 12)
    BrandSubtitle.Position = UDim2.new(0, 0, 0, 18)
    BrandSubtitle.BackgroundTransparency = 1
    BrandSubtitle.Parent = BrandTextFrame

    -- Pasek separatora pod logiem z gradientem
    local HeaderSep = Instance.new("Frame")
    HeaderSep.Name = "HeaderSep"
    HeaderSep.Size = UDim2.new(1, -28, 0, 1)
    HeaderSep.Position = UDim2.new(0, 14, 0, 56)
    HeaderSep.BorderSizePixel = 0
    HeaderSep.BackgroundColor3 = getThemeColor("Accent", Color3.fromRGB(35, 36, 46))
    HeaderSep.Parent = SidebarFrame

    -- =========================================================================
    -- 2. LISTA ZAKŁADEK (TAB PILLS CONTAINER)
    -- =========================================================================
    local TabList = Instance.new("ScrollingFrame")
    TabList.Name = "TabList"
    TabList.Size = UDim2.new(1, 0, 1, -128)
    TabList.Position = UDim2.new(0, 0, 0, 64)
    TabList.BackgroundTransparency = 1
    TabList.BorderSizePixel = 0
    TabList.CanvasSize = UDim2.new(0, 0, 0, 0)
    TabList.AutomaticCanvasSize = Enum.AutomaticSize.Y
    TabList.ScrollBarThickness = 2
    TabList.ScrollBarImageColor3 = Color3.fromRGB(60, 60, 75)
    TabList.ScrollingDirection = Enum.ScrollingDirection.Y
    TabList.ClipsDescendants = true
    TabList.Parent = SidebarFrame
    UI.TabList = TabList

    local TabPadding = Instance.new("UIPadding", TabList)
    TabPadding.PaddingLeft = UDim.new(0, 10)
    TabPadding.PaddingRight = UDim.new(0, 10)
    TabPadding.PaddingTop = UDim.new(0, 4)
    TabPadding.PaddingBottom = UDim.new(0, 8)

    local TabListLayout = Instance.new("UIListLayout", TabList)
    TabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    TabListLayout.Padding = UDim.new(0, 6)

    -- =========================================================================
    -- 3. KARTA PROFILU GRACZA (USER CARD NA DOLE)
    -- =========================================================================
    local ProfileFrame = Instance.new("Frame")
    ProfileFrame.Name = "ProfileFrame"
    ProfileFrame.Size = UDim2.new(1, -20, 0, 50)
    ProfileFrame.Position = UDim2.new(0, 10, 1, -10)
    ProfileFrame.AnchorPoint = Vector2.new(0, 1)
    ProfileFrame.BackgroundColor3 = getThemeColor("Secondary", Color3.fromRGB(18, 18, 24))
    ProfileFrame.BorderSizePixel = 0
    ProfileFrame.ZIndex = 8
    ProfileFrame.Parent = SidebarFrame
    Instance.new("UICorner", ProfileFrame).CornerRadius = UDim.new(0, 10)

    local ProfileStroke = Instance.new("UIStroke", ProfileFrame)
    ProfileStroke.Color = getThemeColor("Accent", Color3.fromRGB(38, 38, 50))
    ProfileStroke.Thickness = 1
    ProfileStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    -- Kontener na awatar z zieloną kropką statusu
    local AvatarContainer = Instance.new("Frame")
    AvatarContainer.Size = UDim2.new(0, 34, 0, 34)
    AvatarContainer.Position = UDim2.new(0, 8, 0.5, 0)
    AvatarContainer.AnchorPoint = Vector2.new(0, 0.5)
    AvatarContainer.BackgroundTransparency = 1
    AvatarContainer.Parent = ProfileFrame

    local Avatar = Instance.new("ImageLabel")
    Avatar.Name = "Avatar"
    Avatar.Size = UDim2.new(1, 0, 1, 0)
    Avatar.BackgroundTransparency = 1
    Avatar.Image = "rbxthumb://type=AvatarHeadShot&id=" .. (LocalPlayer and LocalPlayer.UserId or 1) .. "&w=150&h=150"
    Avatar.Parent = AvatarContainer
    Instance.new("UICorner", Avatar).CornerRadius = UDim.new(1, 0)

    local StatusDot = Instance.new("Frame")
    StatusDot.Name = "StatusDot"
    StatusDot.Size = UDim2.new(0, 9, 0, 9)
    StatusDot.Position = UDim2.new(1, -2, 1, -2)
    StatusDot.AnchorPoint = Vector2.new(1, 1)
    StatusDot.BackgroundColor3 = Color3.fromRGB(34, 197, 94)
    StatusDot.BorderSizePixel = 0
    StatusDot.ZIndex = 2
    StatusDot.Parent = AvatarContainer
    Instance.new("UICorner", StatusDot).CornerRadius = UDim.new(1, 0)
    local StatusStroke = Instance.new("UIStroke", StatusDot)
    StatusStroke.Color = Color3.fromRGB(18, 18, 24)
    StatusStroke.Thickness = 1.5

    -- Dane gracza
    local NameFrame = Instance.new("Frame")
    NameFrame.Name = "NameFrame"
    NameFrame.Size = UDim2.new(1, -85, 1, 0)
    NameFrame.Position = UDim2.new(0, 48, 0.5, 0)
    NameFrame.AnchorPoint = Vector2.new(0, 0.5)
    NameFrame.BackgroundTransparency = 1
    NameFrame.Parent = ProfileFrame

    local displayName = LocalPlayer and LocalPlayer.DisplayName or "User"
    local userName = LocalPlayer and LocalPlayer.Name or "Player"
    local nameToShow = #displayName <= 12 and displayName or userName

    local DisplayName = Instance.new("TextLabel")
    DisplayName.Name = "DisplayName"
    DisplayName.Text = nameToShow
    DisplayName.Font = Enum.Font.GothamBold
    DisplayName.TextSize = 11
    DisplayName.TextColor3 = getThemeColor("Text", Color3.fromRGB(255, 255, 255))
    DisplayName.TextTruncate = Enum.TextTruncate.AtEnd
    DisplayName.TextXAlignment = Enum.TextXAlignment.Left
    DisplayName.Size = UDim2.new(1, 0, 0, 14)
    DisplayName.Position = UDim2.new(0, 0, 0, 9)
    DisplayName.BackgroundTransparency = 1
    DisplayName.Parent = NameFrame

    local RoleBadge = Instance.new("TextLabel")
    RoleBadge.Name = "Role"
    RoleBadge.Text = "PREMIUM"
    RoleBadge.Font = Enum.Font.GothamBold
    RoleBadge.TextSize = 8
    RoleBadge.TextColor3 = Color3.fromRGB(168, 85, 247)
    RoleBadge.TextXAlignment = Enum.TextXAlignment.Left
    RoleBadge.Size = UDim2.new(1, 0, 0, 12)
    RoleBadge.Position = UDim2.new(0, 0, 0, 25)
    RoleBadge.BackgroundTransparency = 1
    RoleBadge.Parent = NameFrame

    -- Przycisk Ustawień (zębatka w prawym rogu profilu)
    local SettingsBtn = Instance.new("TextButton")
    SettingsBtn.Name = "SettingsBtn"
    SettingsBtn.Size = UDim2.new(0, 28, 0, 28)
    SettingsBtn.Position = UDim2.new(1, -7, 0.5, 0)
    SettingsBtn.AnchorPoint = Vector2.new(1, 0.5)
    SettingsBtn.BackgroundColor3 = Color3.fromRGB(26, 26, 36)
    SettingsBtn.BackgroundTransparency = 1
    SettingsBtn.Text = ""
    SettingsBtn.AutoButtonColor = false
    SettingsBtn.Parent = ProfileFrame
    Instance.new("UICorner", SettingsBtn).CornerRadius = UDim.new(0, 6)

    local SettingsIcon = Instance.new("ImageLabel")
    SettingsIcon.Name = "Icon"
    SettingsIcon.Size = UDim2.new(0, 16, 0, 16)
    SettingsIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
    SettingsIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    SettingsIcon.BackgroundTransparency = 1
    SettingsIcon.ImageColor3 = Color3.fromRGB(150, 150, 165)
    SettingsIcon.Parent = SettingsBtn
    if Icons and Icons.Apply then
        Icons:Apply(SettingsIcon, "settings")
    end

    SettingsBtn.MouseEnter:Connect(function()
        if not UI.IsSettingsOpen then
            TweenService:Create(SettingsBtn, TweenInfo.new(0.2), { BackgroundTransparency = 0 }):Play()
            TweenService:Create(SettingsIcon, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                ImageColor3 = Color3.fromRGB(255, 255, 255),
                Rotation = 35
            }):Play()
        end
    end)

    SettingsBtn.MouseLeave:Connect(function()
        if not UI.IsSettingsOpen then
            TweenService:Create(SettingsBtn, TweenInfo.new(0.2), { BackgroundTransparency = 1 }):Play()
            TweenService:Create(SettingsIcon, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                ImageColor3 = Color3.fromRGB(150, 150, 165),
                Rotation = 0
            }):Play()
        end
    end)

    SettingsBtn.MouseButton1Click:Connect(function()
        if UI.IsSettingsOpen then
            if UI.PreviousTab and UI.SelectTab then
                UI:SelectTab(UI.PreviousTab)
            elseif UI.SelectDashboard then
                UI:SelectDashboard()
            end
        else
            if UI.OpenSettings then UI:OpenSettings() end
        end
    end)

    UI.SettingsBtn = SettingsBtn
    UI.SettingsIcon = SettingsIcon

    return SidebarFrame, TabList
end

return Sidebar