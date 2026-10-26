-- // ==========================================================================
-- // MENUTEST DASHBOARD - CYBER-COMMAND CENTER (PRO ELITE SUITE)
-- // Kompleksowy, dynamiczny pulpit dowodzenia:
-- // 1. Hero Player HUD: Awatar, Ranga VIP, Nick, Live Vitals (Speed, Jump, HP, Ping)
-- // 2. Quick-Access Matrix: 6 interaktywnych szybkich przełączników (Speed, Fly, Jump, ESP, Bright, Noclip)
-- // 3. Server & World Operations: Telemetria serwera, Rejoin, Server Hop, Kopiuj JobId
-- // 4. Community & Links: Kapsułki społeczności z natychmiastowym kopiowaniem
-- // ==========================================================================

local Dashboard = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer

local function getLocalVersion()
    if typeof(readfile) == "function" then
        local ok, content = pcall(readfile, "MenuTest/version.txt")
        if ok and content and #content > 0 then
            return content:gsub("^%s*(.-)%s*$", "%1")
        end
        local ok2, content2 = pcall(readfile, "version.txt")
        if ok2 and content2 and #content2 > 0 then
            return content2:gsub("^%s*(.-)%s*$", "%1")
        end
    end
    return "3.0.0"
end

function Dashboard:Render(UI, order, passedIcons)
    local Icons = passedIcons or (UI and UI.Icons) or (typeof(getgenv) == "function" and getgenv()._MenuTestIconsModule) or _G._MenuTestIconsModule
    local ThemeManager = UI.ThemeManager

    local TabElements = UI:CreateTab("Dashboard", "layout-dashboard", order or 1)
    local Page = TabElements.Page

    -- Stylizacja scrollbara i układu strony
    Page.ScrollBarThickness = 2
    Page.ScrollBarImageColor3 = Color3.fromRGB(99, 102, 241)
    Page.CanvasSize = UDim2.new(0, 0, 0, 0)
    Page.AutomaticCanvasSize = Enum.AutomaticSize.Y

    local PagePadding = Page:FindFirstChildOfClass("UIPadding") or Instance.new("UIPadding", Page)
    PagePadding.PaddingTop = UDim.new(0, 12)
    PagePadding.PaddingBottom = UDim.new(0, 20)
    PagePadding.PaddingLeft = UDim.new(0, 14)
    PagePadding.PaddingRight = UDim.new(0, 14)

    local PageLayout = Page:FindFirstChildOfClass("UIListLayout") or Instance.new("UIListLayout", Page)
    PageLayout.SortOrder = Enum.SortOrder.LayoutOrder
    PageLayout.Padding = UDim.new(0, 14)

    -- // =====================================================================
    -- // 1. HERO PLAYER HUD CARD (Apple VisionOS Liquid Glass Panel)
    -- // =====================================================================
    local HeroCard = Instance.new("Frame")
    HeroCard.Name = "HeroPlayerCard"
    HeroCard.Size = UDim2.new(1, 0, 0, 92)
    HeroCard.BackgroundColor3 = Color3.fromRGB(18, 22, 34)
    HeroCard.BackgroundTransparency = 0.35
    HeroCard.BorderSizePixel = 0
    HeroCard.LayoutOrder = 1
    HeroCard.Parent = Page

    Instance.new("UICorner", HeroCard).CornerRadius = UDim.new(0, 20)
    local HeroStroke = Instance.new("UIStroke", HeroCard)
    HeroStroke.Color = Color3.fromRGB(110, 130, 185)
    HeroStroke.Thickness = 1.2
    HeroStroke.Transparency = 0.55

    local HeroGradient = Instance.new("UIGradient", HeroCard)
    HeroGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(24, 28, 44)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(14, 16, 26))
    })
    HeroGradient.Rotation = 90

    -- Lewa strona: Awatar z obwódką i wskaźnikiem online
    local AvatarFrame = Instance.new("Frame")
    AvatarFrame.Name = "AvatarFrame"
    AvatarFrame.Size = UDim2.new(0, 60, 0, 60)
    AvatarFrame.Position = UDim2.new(0, 16, 0.5, 0)
    AvatarFrame.AnchorPoint = Vector2.new(0, 0.5)
    AvatarFrame.BackgroundColor3 = Color3.fromRGB(24, 26, 38)
    AvatarFrame.BorderSizePixel = 0
    AvatarFrame.Parent = HeroCard
    Instance.new("UICorner", AvatarFrame).CornerRadius = UDim.new(1, 0)

    local AvatarStroke = Instance.new("UIStroke", AvatarFrame)
    AvatarStroke.Color = Color3.fromRGB(99, 102, 241)
    AvatarStroke.Thickness = 1.8

    local AvatarImg = Instance.new("ImageLabel")
    AvatarImg.Name = "AvatarImg"
    AvatarImg.Size = UDim2.new(1, -4, 1, -4)
    AvatarImg.Position = UDim2.new(0.5, 0, 0.5, 0)
    AvatarImg.AnchorPoint = Vector2.new(0.5, 0.5)
    AvatarImg.BackgroundTransparency = 1
    AvatarImg.Parent = AvatarFrame
    Instance.new("UICorner", AvatarImg).CornerRadius = UDim.new(1, 0)

    task.spawn(function()
        if LocalPlayer and LocalPlayer.UserId then
            local thumb, isReady = Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
            if isReady and thumb then AvatarImg.Image = thumb end
        end
    end)

    local OnlineDot = Instance.new("Frame")
    OnlineDot.Name = "OnlineDot"
    OnlineDot.Size = UDim2.new(0, 13, 0, 13)
    OnlineDot.Position = UDim2.new(1, -2, 1, -2)
    OnlineDot.AnchorPoint = Vector2.new(1, 1)
    OnlineDot.BackgroundColor3 = Color3.fromRGB(16, 185, 129)
    OnlineDot.BorderSizePixel = 0
    OnlineDot.Parent = AvatarFrame
    Instance.new("UICorner", OnlineDot).CornerRadius = UDim.new(1, 0)
    local DotStroke = Instance.new("UIStroke", OnlineDot)
    DotStroke.Color = Color3.fromRGB(13, 14, 21)
    DotStroke.Thickness = 2

    -- Informacje o graczu
    local InfoContainer = Instance.new("Frame")
    InfoContainer.Name = "InfoContainer"
    InfoContainer.Size = UDim2.new(0, 260, 1, -20)
    InfoContainer.Position = UDim2.new(0, 88, 0.5, 0)
    InfoContainer.AnchorPoint = Vector2.new(0, 0.5)
    InfoContainer.BackgroundTransparency = 1
    InfoContainer.Parent = HeroCard

    local InfoLayout = Instance.new("UIListLayout", InfoContainer)
    InfoLayout.FillDirection = Enum.FillDirection.Vertical
    InfoLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    InfoLayout.Padding = UDim.new(0, 3)

    local NameRow = Instance.new("Frame")
    NameRow.Size = UDim2.new(1, 0, 0, 20)
    NameRow.BackgroundTransparency = 1
    NameRow.Parent = InfoContainer

    local NameRowLayout = Instance.new("UIListLayout", NameRow)
    NameRowLayout.FillDirection = Enum.FillDirection.Horizontal
    NameRowLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    NameRowLayout.Padding = UDim.new(0, 8)

    local DisplayNameLabel = Instance.new("TextLabel")
    DisplayNameLabel.Text = (LocalPlayer and LocalPlayer.DisplayName) or "Gracz"
    DisplayNameLabel.Font = Enum.Font.GothamBold
    DisplayNameLabel.TextSize = 15
    DisplayNameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    DisplayNameLabel.AutomaticSize = Enum.AutomaticSize.X
    DisplayNameLabel.Size = UDim2.new(0, 0, 1, 0)
    DisplayNameLabel.BackgroundTransparency = 1
    DisplayNameLabel.TextXAlignment = Enum.TextXAlignment.Left
    DisplayNameLabel.Parent = NameRow

    local VipPill = Instance.new("Frame")
    VipPill.Size = UDim2.new(0, 72, 0, 18)
    VipPill.BackgroundColor3 = Color3.fromRGB(245, 158, 11)
    VipPill.BackgroundTransparency = 0.85
    VipPill.BorderSizePixel = 0
    VipPill.Parent = NameRow
    Instance.new("UICorner", VipPill).CornerRadius = UDim.new(0, 5)
    local VipStroke = Instance.new("UIStroke", VipPill)
    VipStroke.Color = Color3.fromRGB(245, 158, 11)
    VipStroke.Thickness = 1

    local VipText = Instance.new("TextLabel")
    VipText.Text = "👑 VIP ELITE"
    VipText.Font = Enum.Font.GothamBold
    VipText.TextSize = 9
    VipText.TextColor3 = Color3.fromRGB(251, 191, 36)
    VipText.Size = UDim2.new(1, 0, 1, 0)
    VipText.BackgroundTransparency = 1
    VipText.Parent = VipPill

    local UsernameLabel = Instance.new("TextLabel")
    UsernameLabel.Text = "@" .. ((LocalPlayer and LocalPlayer.Name) or "Nieznany")
    UsernameLabel.Font = Enum.Font.GothamMedium
    UsernameLabel.TextSize = 11
    UsernameLabel.TextColor3 = Color3.fromRGB(148, 163, 184)
    UsernameLabel.Size = UDim2.new(1, 0, 0, 14)
    UsernameLabel.BackgroundTransparency = 1
    UsernameLabel.TextXAlignment = Enum.TextXAlignment.Left
    UsernameLabel.Parent = InfoContainer

    local AccountAgeLabel = Instance.new("TextLabel")
    AccountAgeLabel.Text = string.format("Wiek konta: %d dni • ID: %d", (LocalPlayer and LocalPlayer.AccountAge) or 0, (LocalPlayer and LocalPlayer.UserId) or 0)
    AccountAgeLabel.Font = Enum.Font.Gotham
    AccountAgeLabel.TextSize = 10
    AccountAgeLabel.TextColor3 = Color3.fromRGB(100, 116, 139)
    AccountAgeLabel.Size = UDim2.new(1, 0, 0, 14)
    AccountAgeLabel.BackgroundTransparency = 1
    AccountAgeLabel.TextXAlignment = Enum.TextXAlignment.Left
    AccountAgeLabel.Parent = InfoContainer

    -- Prawa strona: 4 kasetki z parametrami gracza na żywo
    local GaugesContainer = Instance.new("Frame")
    GaugesContainer.Name = "GaugesContainer"
    GaugesContainer.Size = UDim2.new(1, -360, 1, -20)
    GaugesContainer.Position = UDim2.new(1, -16, 0.5, 0)
    GaugesContainer.AnchorPoint = Vector2.new(1, 0.5)
    GaugesContainer.BackgroundTransparency = 1
    GaugesContainer.Parent = HeroCard

    local GaugesLayout = Instance.new("UIListLayout", GaugesContainer)
    GaugesLayout.FillDirection = Enum.FillDirection.Horizontal
    GaugesLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    GaugesLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    GaugesLayout.Padding = UDim.new(0, 10)

    local function createLiveGauge(title, defaultVal, iconName, accentColor)
        local Gauge = Instance.new("Frame")
        Gauge.Size = UDim2.new(0, 95, 1, 0)
        Gauge.BackgroundColor3 = Color3.fromRGB(18, 20, 30)
        Gauge.BorderSizePixel = 0
        Gauge.Parent = GaugesContainer
        Instance.new("UICorner", Gauge).CornerRadius = UDim.new(0, 8)

        local GStroke = Instance.new("UIStroke", Gauge)
        GStroke.Color = Color3.fromRGB(34, 37, 52)
        GStroke.Thickness = 1

        local GIcon = Instance.new("ImageLabel")
        GIcon.Size = UDim2.new(0, 14, 0, 14)
        GIcon.Position = UDim2.new(0, 8, 0, 8)
        GIcon.BackgroundTransparency = 1
        GIcon.ImageColor3 = accentColor or Color3.fromRGB(99, 102, 241)
        GIcon.Parent = Gauge
        if Icons and Icons.Apply then Icons:Apply(GIcon, iconName) end

        local GTitle = Instance.new("TextLabel")
        GTitle.Text = title
        GTitle.Font = Enum.Font.GothamMedium
        GTitle.TextSize = 10
        GTitle.TextColor3 = Color3.fromRGB(148, 163, 184)
        GTitle.Size = UDim2.new(1, -28, 0, 14)
        GTitle.Position = UDim2.new(0, 26, 0, 8)
        GTitle.BackgroundTransparency = 1
        GTitle.TextXAlignment = Enum.TextXAlignment.Left
        GTitle.Parent = Gauge

        local GVal = Instance.new("TextLabel")
        GVal.Text = defaultVal
        GVal.Font = Enum.Font.GothamBold
        GVal.TextSize = 13
        GVal.TextColor3 = Color3.fromRGB(241, 245, 249)
        GVal.Size = UDim2.new(1, -16, 0, 20)
        GVal.Position = UDim2.new(0, 8, 1, -26)
        GVal.BackgroundTransparency = 1
        GVal.TextXAlignment = Enum.TextXAlignment.Left
        GVal.Parent = Gauge

        return GVal
    end

    local ValSpeed = createLiveGauge("Prędkość", "16.0", "zap", Color3.fromRGB(245, 158, 11))
    local ValJump  = createLiveGauge("Skok", "50.0", "arrow-up-circle", Color3.fromRGB(16, 185, 129))
    local ValHP    = createLiveGauge("Zdrowie", "100%", "heart", Color3.fromRGB(239, 68, 68))
    local ValPing  = createLiveGauge("Ping", "20 ms", "activity", Color3.fromRGB(99, 102, 241))

    -- Pętla odświeżania statystyk gracza na żywo
    local gaugeConn
    gaugeConn = RunService.Heartbeat:Connect(function()
        if not HeroCard.Parent then
            if gaugeConn then gaugeConn:Disconnect() end
            return
        end
        local char = LocalPlayer and LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            ValSpeed.Text = string.format("%.1f", hum.WalkSpeed)
            ValJump.Text  = string.format("%.1f", hum.UseJumpPower and hum.JumpPower or hum.JumpHeight)
            local hpPercent = math.clamp(math.floor((hum.Health / math.max(1, hum.MaxHealth)) * 100), 0, 100)
            ValHP.Text = tostring(hpPercent) .. "%"
            ValHP.TextColor3 = hpPercent > 40 and Color3.fromRGB(241, 245, 249) or Color3.fromRGB(239, 68, 68)
        end
        local stat = game:GetService("Stats")
        local net = stat and stat:FindFirstChild("Network")
        local serv = net and net:FindFirstChild("ServerStatsItem")
        local pingVal = serv and serv:FindFirstChild("Data Ping")
        if pingVal then
            ValPing.Text = string.format("%d ms", math.floor(pingVal:GetValue()))
        end
    end)

    -- // =====================================================================
    -- // 2. BENTO ROW: SZYBKIE FUNKCJE (MATRIX) ORAZ SERWER & ŚWIAT
    -- // =====================================================================
    local BentoRow = Instance.new("Frame")
    BentoRow.Name = "BentoRow"
    BentoRow.Size = UDim2.new(1, 0, 0, 240)
    BentoRow.BackgroundTransparency = 1
    BentoRow.LayoutOrder = 2
    BentoRow.Parent = Page

    local BentoLayout = Instance.new("UIListLayout", BentoRow)
    BentoLayout.FillDirection = Enum.FillDirection.Horizontal
    BentoLayout.Padding = UDim.new(0, 14)

    -- =========================================================================
    -- KOLUMNA LEWA: SZYBKIE CHEATY (MATRIX TOGGLES)
    -- =========================================================================
    local QuickMatrixCard = Instance.new("Frame")
    QuickMatrixCard.Name = "QuickMatrixCard"
    QuickMatrixCard.Size = UDim2.new(0.58, -7, 1, 0)
    QuickMatrixCard.BackgroundColor3 = Color3.fromRGB(18, 22, 34)
    QuickMatrixCard.BackgroundTransparency = 0.35
    QuickMatrixCard.BorderSizePixel = 0
    QuickMatrixCard.Parent = BentoRow
    Instance.new("UICorner", QuickMatrixCard).CornerRadius = UDim.new(0, 18)
    local QmStroke = Instance.new("UIStroke", QuickMatrixCard)
    QmStroke.Color = Color3.fromRGB(90, 105, 150)
    QmStroke.Thickness = 1.2
    QmStroke.Transparency = 0.55

    local QmPadding = Instance.new("UIPadding", QuickMatrixCard)
    QmPadding.PaddingTop = UDim.new(0, 12)
    QmPadding.PaddingBottom = UDim.new(0, 12)
    QmPadding.PaddingLeft = UDim.new(0, 14)
    QmPadding.PaddingRight = UDim.new(0, 14)

    -- Nagłówek kolumny
    local QmHeader = Instance.new("Frame")
    QmHeader.Size = UDim2.new(1, 0, 0, 24)
    QmHeader.BackgroundTransparency = 1
    QmHeader.Parent = QuickMatrixCard

    local QmHeaderIcon = Instance.new("ImageLabel")
    QmHeaderIcon.Size = UDim2.new(0, 16, 0, 16)
    QmHeaderIcon.Position = UDim2.new(0, 0, 0.5, 0)
    QmHeaderIcon.AnchorPoint = Vector2.new(0, 0.5)
    QmHeaderIcon.BackgroundTransparency = 1
    QmHeaderIcon.ImageColor3 = Color3.fromRGB(99, 102, 241)
    QmHeaderIcon.Parent = QmHeader
    if Icons and Icons.Apply then Icons:Apply(QmHeaderIcon, "zap") end

    local QmHeaderTitle = Instance.new("TextLabel")
    QmHeaderTitle.Text = "Szybki Dostęp do Funkcji"
    QmHeaderTitle.Font = Enum.Font.GothamBold
    QmHeaderTitle.TextSize = 13
    QmHeaderTitle.TextColor3 = Color3.fromRGB(241, 245, 249)
    QmHeaderTitle.Size = UDim2.new(1, -90, 1, 0)
    QmHeaderTitle.Position = UDim2.new(0, 24, 0, 0)
    QmHeaderTitle.BackgroundTransparency = 1
    QmHeaderTitle.TextXAlignment = Enum.TextXAlignment.Left
    QmHeaderTitle.Parent = QmHeader

    local QmBadge = Instance.new("TextLabel")
    QmBadge.Text = "⚡ 1-CLICK"
    QmBadge.Font = Enum.Font.GothamBold
    QmBadge.TextSize = 9
    QmBadge.TextColor3 = Color3.fromRGB(99, 102, 241)
    QmBadge.Size = UDim2.new(0, 60, 0, 18)
    QmBadge.Position = UDim2.new(1, -60, 0.5, 0)
    QmBadge.AnchorPoint = Vector2.new(1, 0.5)
    QmBadge.BackgroundColor3 = Color3.fromRGB(30, 31, 48)
    QmBadge.Parent = QmHeader
    Instance.new("UICorner", QmBadge).CornerRadius = UDim.new(0, 4)

    -- Siatka 6 szybkich przełączników
    local MatrixGrid = Instance.new("Frame")
    MatrixGrid.Name = "MatrixGrid"
    MatrixGrid.Size = UDim2.new(1, 0, 1, -34)
    MatrixGrid.Position = UDim2.new(0, 0, 0, 34)
    MatrixGrid.BackgroundTransparency = 1
    MatrixGrid.Parent = QuickMatrixCard

    local GridUIGrid = Instance.new("UIGridLayout", MatrixGrid)
    GridUIGrid.CellSize = UDim2.new(0.5, -6, 0.333, -6)
    GridUIGrid.CellPadding = UDim2.new(0, 8, 0, 8)
    GridUIGrid.SortOrder = Enum.SortOrder.LayoutOrder

    local function createQuickToggle(name, iconName, keybind, onToggle)
        local Tile = Instance.new("TextButton")
        Tile.Name = "Tile_" .. name
        Tile.BackgroundColor3 = Color3.fromRGB(18, 19, 28)
        Tile.BorderSizePixel = 0
        Tile.Text = ""
        Tile.AutoButtonColor = false
        Tile.Parent = MatrixGrid
        Instance.new("UICorner", Tile).CornerRadius = UDim.new(0, 8)

        local TStroke = Instance.new("UIStroke", Tile)
        TStroke.Color = Color3.fromRGB(32, 34, 48)
        TStroke.Thickness = 1

        local TIcon = Instance.new("ImageLabel")
        TIcon.Size = UDim2.new(0, 16, 0, 16)
        TIcon.Position = UDim2.new(0, 10, 0.5, 0)
        TIcon.AnchorPoint = Vector2.new(0, 0.5)
        TIcon.BackgroundTransparency = 1
        TIcon.ImageColor3 = Color3.fromRGB(148, 163, 184)
        TIcon.Parent = Tile
        if Icons and Icons.Apply then Icons:Apply(TIcon, iconName) end

        local TTitle = Instance.new("TextLabel")
        TTitle.Text = name
        TTitle.Font = Enum.Font.GothamMedium
        TTitle.TextSize = 11
        TTitle.TextColor3 = Color3.fromRGB(226, 232, 240)
        TTitle.Size = UDim2.new(1, -78, 1, 0)
        TTitle.Position = UDim2.new(0, 32, 0, 0)
        TTitle.BackgroundTransparency = 1
        TTitle.TextXAlignment = Enum.TextXAlignment.Left
        TTitle.TextTruncate = Enum.TextTruncate.AtEnd
        TTitle.Parent = Tile

        local SwitchPill = Instance.new("Frame")
        SwitchPill.Size = UDim2.new(0, 34, 0, 18)
        SwitchPill.Position = UDim2.new(1, -10, 0.5, 0)
        SwitchPill.AnchorPoint = Vector2.new(1, 0.5)
        SwitchPill.BackgroundColor3 = Color3.fromRGB(30, 32, 46)
        SwitchPill.BorderSizePixel = 0
        SwitchPill.Parent = Tile
        Instance.new("UICorner", SwitchPill).CornerRadius = UDim.new(1, 0)

        local SwitchKnob = Instance.new("Frame")
        SwitchKnob.Size = UDim2.new(0, 12, 0, 12)
        SwitchKnob.Position = UDim2.new(0, 3, 0.5, 0)
        SwitchKnob.AnchorPoint = Vector2.new(0, 0.5)
        SwitchKnob.BackgroundColor3 = Color3.fromRGB(148, 163, 184)
        SwitchKnob.BorderSizePixel = 0
        SwitchKnob.Parent = SwitchPill
        Instance.new("UICorner", SwitchKnob).CornerRadius = UDim.new(1, 0)

        local isEnabled = false
        local function updateVisual(state)
            isEnabled = state
            if state then
                TweenService:Create(SwitchPill, TweenInfo.new(0.2), { BackgroundColor3 = Color3.fromRGB(99, 102, 241) }):Play()
                TweenService:Create(SwitchKnob, TweenInfo.new(0.2), {
                    Position = UDim2.new(1, -15, 0.5, 0),
                    BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                }):Play()
                TweenService:Create(TStroke, TweenInfo.new(0.2), { Color = Color3.fromRGB(99, 102, 241) }):Play()
                TweenService:Create(TIcon, TweenInfo.new(0.2), { ImageColor3 = Color3.fromRGB(255, 255, 255) }):Play()
            else
                TweenService:Create(SwitchPill, TweenInfo.new(0.2), { BackgroundColor3 = Color3.fromRGB(30, 32, 46) }):Play()
                TweenService:Create(SwitchKnob, TweenInfo.new(0.2), {
                    Position = UDim2.new(0, 3, 0.5, 0),
                    BackgroundColor3 = Color3.fromRGB(148, 163, 184)
                }):Play()
                TweenService:Create(TStroke, TweenInfo.new(0.2), { Color = Color3.fromRGB(32, 34, 48) }):Play()
                TweenService:Create(TIcon, TweenInfo.new(0.2), { ImageColor3 = Color3.fromRGB(148, 163, 184) }):Play()
            end
        end

        Tile.MouseButton1Click:Connect(function()
            local newState = not isEnabled
            updateVisual(newState)
            if onToggle then pcall(onToggle, newState) end
        end)

        return updateVisual
    end

    -- Wbudowane autonomiczne szybkie cheaty
    local speedActive = false
    local speedLoop = nil
    createQuickToggle("Speed Boost", "zap", "B", function(state)
        speedActive = state
        local char = LocalPlayer and LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = state and 50 or 16 end
        if state then
            if not speedLoop then
                speedLoop = RunService.Heartbeat:Connect(function()
                    if speedActive then
                        local c = LocalPlayer and LocalPlayer.Character
                        local h = c and c:FindFirstChildOfClass("Humanoid")
                        if h and h.WalkSpeed ~= 50 then h.WalkSpeed = 50 end
                    end
                end)
            end
        else
            if speedLoop then speedLoop:Disconnect(); speedLoop = nil end
        end
    end)

    local infJumpActive = false
    local infJumpConn = nil
    createQuickToggle("Infinite Jump", "arrow-up-circle", "J", function(state)
        infJumpActive = state
        if state then
            if not infJumpConn then
                infJumpConn = UserInputService.JumpRequest:Connect(function()
                    if infJumpActive then
                        local char = LocalPlayer and LocalPlayer.Character
                        local hum = char and char:FindFirstChildOfClass("Humanoid")
                        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
                    end
                end)
            end
        else
            if infJumpConn then infJumpConn:Disconnect(); infJumpConn = nil end
        end
    end)

    local noclipActive = false
    local noclipLoop = nil
    createQuickToggle("Noclip Walls", "box", "V", function(state)
        noclipActive = state
        if state then
            if not noclipLoop then
                noclipLoop = RunService.Stepped:Connect(function()
                    if noclipActive then
                        local char = LocalPlayer and LocalPlayer.Character
                        if char then
                            for _, part in ipairs(char:GetDescendants()) do
                                if part:IsA("BasePart") and part.CanCollide then
                                    part.CanCollide = false
                                end
                            end
                        end
                    end
                end)
            end
        else
            if noclipLoop then noclipLoop:Disconnect(); noclipLoop = nil end
        end
    end)

    local fullbrightActive = false
    local oldBright, oldClock, oldAmbient
    createQuickToggle("Fullbright", "sun", "L", function(state)
        fullbrightActive = state
        if state then
            oldBright = Lighting.Brightness
            oldClock = Lighting.ClockTime
            oldAmbient = Lighting.Ambient
            Lighting.Brightness = 2
            Lighting.ClockTime = 14
            Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        else
            if oldBright then Lighting.Brightness = oldBright end
            if oldClock then Lighting.ClockTime = oldClock end
            if oldAmbient then Lighting.Ambient = oldAmbient end
        end
    end)

    local espActive = false
    local espFolder = nil
    createQuickToggle("Player ESP", "eye", "H", function(state)
        espActive = state
        if state then
            if not espFolder then
                espFolder = Instance.new("Folder")
                espFolder.Name = "MenuTest_ESP_Folder"
                pcall(function() espFolder.Parent = game:GetService("CoreGui") end)
                if not espFolder.Parent then espFolder.Parent = workspace end
            end
            local function addBox(player)
                if player == LocalPlayer then return end
                task.spawn(function()
                    while espActive and player and player.Parent do
                        local char = player.Character
                        local hrp = char and char:FindFirstChild("HumanoidRootPart")
                        if hrp and not hrp:FindFirstChild("MenuTest_Highlight") then
                            local hl = Instance.new("Highlight")
                            hl.Name = "MenuTest_Highlight"
                            hl.FillColor = Color3.fromRGB(99, 102, 241)
                            hl.FillTransparency = 0.5
                            hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                            hl.OutlineTransparency = 0
                            hl.Adornee = char
                            hl.Parent = hrp
                        end
                        task.wait(1.5)
                    end
                end)
            end
            for _, p in ipairs(Players:GetPlayers()) do addBox(p) end
            Players.PlayerAdded:Connect(addBox)
        else
            if espFolder then pcall(function() espFolder:Destroy() end); espFolder = nil end
            for _, p in ipairs(Players:GetPlayers()) do
                local c = p.Character
                if c then
                    local hl = c:FindFirstChild("MenuTest_Highlight", true)
                    if hl then hl:Destroy() end
                end
            end
        end
    end)

    local flyActive = false
    local flyBodyVel, flyBodyGyro, flyConn
    createQuickToggle("Flight (Fly)", "plane", "F", function(state)
        flyActive = state
        local char = LocalPlayer and LocalPlayer.Character
        local root = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso"))
        if not root then return end
        if state then
            local camera = workspace.CurrentCamera
            flyBodyVel = Instance.new("BodyVelocity")
            flyBodyVel.Velocity = Vector3.new(0, 0, 0)
            flyBodyVel.MaxForce = Vector3.new(9e9, 9e9, 9e9)
            flyBodyVel.Parent = root

            flyBodyGyro = Instance.new("BodyGyro")
            flyBodyGyro.CFrame = root.CFrame
            flyBodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
            flyBodyGyro.Parent = root

            flyConn = RunService.RenderStepped:Connect(function()
                if not flyActive or not root or not root.Parent then return end
                local moveDir = Vector3.new()
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + camera.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - camera.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - camera.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + camera.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir = moveDir - Vector3.new(0, 1, 0) end

                flyBodyVel.Velocity = moveDir.Magnitude > 0 and (moveDir.Unit * 60) or Vector3.new(0, 0, 0)
                flyBodyGyro.CFrame = camera.CFrame
            end)
        else
            if flyConn then flyConn:Disconnect(); flyConn = nil end
            if flyBodyVel then flyBodyVel:Destroy(); flyBodyVel = nil end
            if flyBodyGyro then flyBodyGyro:Destroy(); flyBodyGyro = nil end
        end
    end)

    -- =========================================================================
    -- KOLUMNA PRAWA: SERWER & ŚWIAT (TELEMETRIA I AKCJE)
    -- =========================================================================
    local ServerCard = Instance.new("Frame")
    ServerCard.Name = "ServerCard"
    ServerCard.Size = UDim2.new(0.42, -7, 1, 0)
    ServerCard.BackgroundColor3 = Color3.fromRGB(18, 22, 34)
    ServerCard.BackgroundTransparency = 0.35
    ServerCard.BorderSizePixel = 0
    ServerCard.Parent = BentoRow
    Instance.new("UICorner", ServerCard).CornerRadius = UDim.new(0, 18)
    local ScStroke = Instance.new("UIStroke", ServerCard)
    ScStroke.Color = Color3.fromRGB(90, 105, 150)
    ScStroke.Thickness = 1.2
    ScStroke.Transparency = 0.55

    local ScPadding = Instance.new("UIPadding", ServerCard)
    ScPadding.PaddingTop = UDim.new(0, 12)
    ScPadding.PaddingBottom = UDim.new(0, 12)
    ScPadding.PaddingLeft = UDim.new(0, 14)
    ScPadding.PaddingRight = UDim.new(0, 14)

    local ScHeader = Instance.new("Frame")
    ScHeader.Size = UDim2.new(1, 0, 0, 24)
    ScHeader.BackgroundTransparency = 1
    ScHeader.Parent = ServerCard

    local ScIcon = Instance.new("ImageLabel")
    ScIcon.Size = UDim2.new(0, 16, 0, 16)
    ScIcon.Position = UDim2.new(0, 0, 0.5, 0)
    ScIcon.AnchorPoint = Vector2.new(0, 0.5)
    ScIcon.BackgroundTransparency = 1
    ScIcon.ImageColor3 = Color3.fromRGB(56, 189, 248)
    ScIcon.Parent = ScHeader
    if Icons and Icons.Apply then Icons:Apply(ScIcon, "globe") end

    local ScTitle = Instance.new("TextLabel")
    ScTitle.Text = "Serwer & Świat"
    ScTitle.Font = Enum.Font.GothamBold
    ScTitle.TextSize = 13
    ScTitle.TextColor3 = Color3.fromRGB(241, 245, 249)
    ScTitle.Size = UDim2.new(1, -24, 1, 0)
    ScTitle.Position = UDim2.new(0, 24, 0, 0)
    ScTitle.BackgroundTransparency = 1
    ScTitle.TextXAlignment = Enum.TextXAlignment.Left
    ScTitle.Parent = ScHeader

    local ScContent = Instance.new("Frame")
    ScContent.Size = UDim2.new(1, 0, 1, -30)
    ScContent.Position = UDim2.new(0, 0, 0, 30)
    ScContent.BackgroundTransparency = 1
    ScContent.Parent = ServerCard

    local ScLayout = Instance.new("UIListLayout", ScContent)
    ScLayout.FillDirection = Enum.FillDirection.Vertical
    ScLayout.Padding = UDim.new(0, 8)

    -- Gra & PlaceId
    local GameInfoFrame = Instance.new("Frame")
    GameInfoFrame.Size = UDim2.new(1, 0, 0, 38)
    GameInfoFrame.BackgroundColor3 = Color3.fromRGB(18, 19, 28)
    GameInfoFrame.BorderSizePixel = 0
    GameInfoFrame.Parent = ScContent
    Instance.new("UICorner", GameInfoFrame).CornerRadius = UDim.new(0, 6)

    local GiTitle = Instance.new("TextLabel")
    GiTitle.Text = "ID Miejsca: " .. tostring(game.PlaceId)
    GiTitle.Font = Enum.Font.GothamBold
    GiTitle.TextSize = 11
    GiTitle.TextColor3 = Color3.fromRGB(241, 245, 249)
    GiTitle.Size = UDim2.new(1, -16, 0, 16)
    GiTitle.Position = UDim2.new(0, 8, 0, 4)
    GiTitle.BackgroundTransparency = 1
    GiTitle.TextXAlignment = Enum.TextXAlignment.Left
    GiTitle.Parent = GameInfoFrame

    local GiSub = Instance.new("TextLabel")
    GiSub.Text = string.format("Gracze: %d / %d w sesji", #Players:GetPlayers(), Players.MaxPlayers or 0)
    GiSub.Font = Enum.Font.Gotham
    GiSub.TextSize = 10
    GiSub.TextColor3 = Color3.fromRGB(148, 163, 184)
    GiSub.Size = UDim2.new(1, -16, 0, 14)
    GiSub.Position = UDim2.new(0, 8, 0, 20)
    GiSub.BackgroundTransparency = 1
    GiSub.TextXAlignment = Enum.TextXAlignment.Left
    GiSub.Parent = GameInfoFrame

    -- Akcje serwerowe (Rejoin, Server Hop, Kopiuj JobId)
    local function createServerActionBtn(btnName, btnIcon, onClick)
        local Btn = Instance.new("TextButton")
        Btn.Size = UDim2.new(1, 0, 0, 32)
        Btn.BackgroundColor3 = Color3.fromRGB(22, 24, 35)
        Btn.BorderSizePixel = 0
        Btn.Text = ""
        Btn.AutoButtonColor = false
        Btn.Parent = ScContent
        Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 6)
        local bStroke = Instance.new("UIStroke", Btn)
        bStroke.Color = Color3.fromRGB(36, 38, 54)
        bStroke.Thickness = 1

        local bIcon = Instance.new("ImageLabel")
        bIcon.Size = UDim2.new(0, 13, 0, 13)
        bIcon.Position = UDim2.new(0, 10, 0.5, 0)
        bIcon.AnchorPoint = Vector2.new(0, 0.5)
        bIcon.BackgroundTransparency = 1
        bIcon.ImageColor3 = Color3.fromRGB(148, 163, 184)
        bIcon.Parent = Btn
        if Icons and Icons.Apply then Icons:Apply(bIcon, btnIcon) end

        local bLabel = Instance.new("TextLabel")
        bLabel.Text = btnName
        bLabel.Font = Enum.Font.GothamBold
        bLabel.TextSize = 11
        bLabel.TextColor3 = Color3.fromRGB(226, 232, 240)
        bLabel.Size = UDim2.new(1, -30, 1, 0)
        bLabel.Position = UDim2.new(0, 30, 0, 0)
        bLabel.BackgroundTransparency = 1
        bLabel.TextXAlignment = Enum.TextXAlignment.Left
        bLabel.Parent = Btn

        Btn.MouseEnter:Connect(function()
            TweenService:Create(Btn, TweenInfo.new(0.18), { BackgroundColor3 = Color3.fromRGB(32, 34, 52) }):Play()
            TweenService:Create(bLabel, TweenInfo.new(0.18), { TextColor3 = Color3.fromRGB(255, 255, 255) }):Play()
        end)
        Btn.MouseLeave:Connect(function()
            TweenService:Create(Btn, TweenInfo.new(0.18), { BackgroundColor3 = Color3.fromRGB(22, 24, 35) }):Play()
            TweenService:Create(bLabel, TweenInfo.new(0.18), { TextColor3 = Color3.fromRGB(226, 232, 240) }):Play()
        end)
        Btn.MouseButton1Click:Connect(function()
            if onClick then pcall(onClick) end
        end)
    end

    createServerActionBtn("Rejoin Serwera", "rotate-ccw", function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end)

    createServerActionBtn("Server Hop (Zmień)", "compass", function()
        pcall(function()
            local servers = HttpService:JSONDecode(game:HttpGet(string.format("https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=Asc&limit=10", tostring(game.PlaceId))))
            if servers and servers.data then
                for _, s in ipairs(servers.data) do
                    if s.id ~= game.JobId and s.playing < s.maxPlayers then
                        TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, LocalPlayer)
                        break
                    end
                end
            end
        end)
    end)

    createServerActionBtn("Kopiuj JobId Sesji", "clipboard", function()
        if typeof(setclipboard) == "function" then
            setclipboard(game.JobId)
        end
    end)

    -- // =====================================================================
    -- // 3. BOTTOM ROW: SPOŁECZNOŚĆ, KOD ŹRÓDŁOWY I STATUS SYSTEMU
    -- // =====================================================================
    local BottomRow = Instance.new("Frame")
    BottomRow.Name = "BottomRow"
    BottomRow.Size = UDim2.new(1, 0, 0, 52)
    BottomRow.BackgroundTransparency = 1
    BottomRow.LayoutOrder = 3
    BottomRow.Parent = Page

    local BottomLayout = Instance.new("UIListLayout", BottomRow)
    BottomLayout.FillDirection = Enum.FillDirection.Horizontal
    BottomLayout.Padding = UDim.new(0, 14)

    local function createLinkPill(title, sub, iconName, urlToCopy)
        local Pill = Instance.new("TextButton")
        Pill.Size = UDim2.new(0.333, -10, 1, 0)
        Pill.BackgroundColor3 = Color3.fromRGB(20, 24, 38)
        Pill.BackgroundTransparency = 0.35
        Pill.BorderSizePixel = 0
        Pill.Text = ""
        Pill.AutoButtonColor = false
        Pill.Parent = BottomRow
        Instance.new("UICorner", Pill).CornerRadius = UDim.new(1, 0)
        local pStroke = Instance.new("UIStroke", Pill)
        pStroke.Color = Color3.fromRGB(60, 72, 105)
        pStroke.Thickness = 1
        pStroke.Transparency = 0.55

        local pIcon = Instance.new("ImageLabel")
        pIcon.Size = UDim2.new(0, 20, 0, 20)
        pIcon.Position = UDim2.new(0, 14, 0.5, 0)
        pIcon.AnchorPoint = Vector2.new(0, 0.5)
        pIcon.BackgroundTransparency = 1
        pIcon.ImageColor3 = Color3.fromRGB(99, 102, 241)
        pIcon.Parent = Pill
        if Icons and Icons.Apply then Icons:Apply(pIcon, iconName) end

        local pTitle = Instance.new("TextLabel")
        pTitle.Text = title
        pTitle.Font = Enum.Font.GothamBold
        pTitle.TextSize = 12
        pTitle.TextColor3 = Color3.fromRGB(241, 245, 249)
        pTitle.Size = UDim2.new(1, -44, 0, 16)
        pTitle.Position = UDim2.new(0, 42, 0, 10)
        pTitle.BackgroundTransparency = 1
        pTitle.TextXAlignment = Enum.TextXAlignment.Left
        pTitle.Parent = Pill

        local pSub = Instance.new("TextLabel")
        pSub.Text = sub
        pSub.Font = Enum.Font.Gotham
        pSub.TextSize = 10
        pSub.TextColor3 = Color3.fromRGB(148, 163, 184)
        pSub.Size = UDim2.new(1, -44, 0, 14)
        pSub.Position = UDim2.new(0, 42, 0, 26)
        pSub.BackgroundTransparency = 1
        pSub.TextXAlignment = Enum.TextXAlignment.Left
        pSub.Parent = Pill

        Pill.MouseEnter:Connect(function()
            TweenService:Create(Pill, TweenInfo.new(0.2), { BackgroundColor3 = Color3.fromRGB(20, 22, 34) }):Play()
            TweenService:Create(pStroke, TweenInfo.new(0.2), { Color = Color3.fromRGB(99, 102, 241) }):Play()
        end)
        Pill.MouseLeave:Connect(function()
            TweenService:Create(Pill, TweenInfo.new(0.2), { BackgroundColor3 = Color3.fromRGB(13, 14, 21) }):Play()
            TweenService:Create(pStroke, TweenInfo.new(0.2), { Color = Color3.fromRGB(34, 36, 52) }):Play()
        end)
        Pill.MouseButton1Click:Connect(function()
            if urlToCopy and typeof(setclipboard) == "function" then
                setclipboard(urlToCopy)
                pSub.Text = "Skopiowano do schowka!"
                pSub.TextColor3 = Color3.fromRGB(16, 185, 129)
                task.delay(1.5, function()
                    pSub.Text = sub
                    pSub.TextColor3 = Color3.fromRGB(148, 163, 184)
                end)
            end
        end)
    end

    createLinkPill("Discord Community", "Kliknij, aby skopiować link", "users", "https://dsc.gg/xeno-scripts-pl")
    createLinkPill("GitHub Repository", "MenuTest Open Source", "github", "https://github.com/XxvoltikxX/MenuTest")
    createLinkPill("Status Systemu", "v" .. getLocalVersion() .. " • Chroniony", "shield-check", "https://github.com/XxvoltikxX/MenuTest")
end

return Dashboard