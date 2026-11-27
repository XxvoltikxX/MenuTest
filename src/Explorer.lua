-- // ==========================================================================
-- // LUMINAQHUB — EXPLORER UI
-- // Nowy silnik menu: Dashboard + wyszukiwarka scriptów + panel szczegółów.
-- // Zastępuje klasyczny układ zakładek/opcji na rzecz explorera skryptów.
-- // ==========================================================================

local Explorer = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local Stats = game:GetService("Stats")

local LocalPlayer = Players.LocalPlayer

-- // ==========================================================================
-- // PALETY
-- // ==========================================================================
local Palettes = {
    dark = {
        Bg        = Color3.fromRGB(9, 10, 15),
        Bg2       = Color3.fromRGB(13, 15, 22),
        Card      = Color3.fromRGB(18, 20, 29),
        Card2     = Color3.fromRGB(24, 27, 38),
        Card3     = Color3.fromRGB(31, 35, 49),
        Stroke    = Color3.fromRGB(47, 52, 72),
        StrokeSoft= Color3.fromRGB(35, 39, 55),
        Text      = Color3.fromRGB(244, 246, 255),
        Dim       = Color3.fromRGB(150, 158, 182),
        Dim2      = Color3.fromRGB(105, 113, 137),
        Accent    = Color3.fromRGB(129, 140, 248),
        Accent2   = Color3.fromRGB(168, 85, 247),
        Green     = Color3.fromRGB(52, 211, 153),
        Red       = Color3.fromRGB(248, 113, 113),
        Yellow    = Color3.fromRGB(251, 191, 36),
        Cyan      = Color3.fromRGB(56, 189, 248),
    },
    light = {
        Bg        = Color3.fromRGB(238, 240, 247),
        Bg2       = Color3.fromRGB(248, 249, 253),
        Card      = Color3.fromRGB(255, 255, 255),
        Card2     = Color3.fromRGB(245, 246, 251),
        Card3     = Color3.fromRGB(235, 238, 247),
        Stroke    = Color3.fromRGB(205, 210, 226),
        StrokeSoft= Color3.fromRGB(220, 224, 236),
        Text      = Color3.fromRGB(22, 25, 38),
        Dim       = Color3.fromRGB(92, 100, 124),
        Dim2      = Color3.fromRGB(130, 138, 160),
        Accent    = Color3.fromRGB(99, 102, 241),
        Accent2   = Color3.fromRGB(139, 92, 246),
        Green     = Color3.fromRGB(16, 185, 129),
        Red       = Color3.fromRGB(220, 38, 38),
        Yellow    = Color3.fromRGB(217, 119, 6),
        Cyan      = Color3.fromRGB(14, 165, 233),
    },
}

-- // ==========================================================================
-- // POMOCNIKI
-- // ==========================================================================
local function new(className, props, parent)
    local obj = Instance.new(className)
    if props then
        for k, v in pairs(props) do
            obj[k] = v
        end
    end
    if parent then
        obj.Parent = parent
    end
    return obj
end

local function corner(obj, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 12)
    c.Parent = obj
    return c
end

local function stroke(obj, color, transparency, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color
    s.Transparency = transparency or 0.45
    s.Thickness = thickness or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = obj
    return s
end

local function pad(obj, left, right, top, bottom)
    local p = Instance.new("UIPadding")
    p.PaddingLeft = UDim.new(0, left or 0)
    p.PaddingRight = UDim.new(0, right or 0)
    p.PaddingTop = UDim.new(0, top or 0)
    p.PaddingBottom = UDim.new(0, bottom or 0)
    p.Parent = obj
    return p
end

local function formatNumber(n)
    local s = tostring(math.floor(tonumber(n) or 0))
    local out = s:reverse():gsub("(%d%d%d)", "%1 "):reverse()
    return (out:gsub("^%s+", ""))
end

-- // ==========================================================================
-- // TWORZENIE
-- // ==========================================================================
function Explorer:Create(options)
    options = options or {}
    local Palette = Palettes.dark
    local Theme = { mode = "dark", items = {} }
    local Connections = {}

    local function connect(conn)
        table.insert(Connections, conn)
        return conn
    end

    local function bindTheme(obj, prop, role)
        table.insert(Theme.items, { obj = obj, prop = prop, role = role })
        obj[prop] = Palette[role]
    end

    local function applyTheme(mode)
        Theme.mode = mode
        Palette = Palettes[mode] or Palettes.dark
        for _, it in ipairs(Theme.items) do
            if it.obj and it.obj.Parent then
                pcall(function()
                    it.obj[it.prop] = Palette[it.role]
                end)
            end
        end
    end

    local Icons = options.Icons
    if not Icons then
        Icons = (typeof(getgenv) == "function" and getgenv()._MenuTestIconsModule) or _G._MenuTestIconsModule
    end
    local function applyIcon(img, name)
        if Icons and Icons.Apply then
            pcall(function()
                Icons:Apply(img, name)
            end)
        end
    end

    -- // ======================================================================
    -- // NORMALIZACJA SCRIPTÓW
    -- // ======================================================================
    local Scripts = {}
    for _, raw in ipairs(options.Scripts or {}) do
        local entry = {
            Name        = raw.Name or "Bez nazwy",
            Description = raw.Description or "",
            Category    = raw.Category or "Misc",
            Tags        = raw.Tags or {},
            Icon        = raw.Icon or "box",
            Mode        = raw.Mode or (raw.OnToggle and "toggle" or "action"),
            OnToggle    = raw.OnToggle,
            Run         = raw.Run,
            Url         = raw.Url,
            Pinned      = raw.Pinned == true,
            Options     = raw.Options,
            Default     = raw.Default == true,
            State       = raw.Default == true,
            _row        = nil,
            _detailBtn  = nil,
            _quickSwitch= nil,
        }
        table.insert(Scripts, entry)
    end

    -- // ======================================================================
    -- // SCREEN GUI
    -- // ======================================================================
    local guiParent = nil
    pcall(function() guiParent = game:GetService("CoreGui") end)
    if not guiParent then
        guiParent = LocalPlayer:WaitForChild("PlayerGui")
    end

    local gui = new("ScreenGui", {
        Name = "LuminaqHUB_Explorer",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 999,
    })
    local parented = pcall(function() gui.Parent = guiParent end)
    if not parented or not gui.Parent then
        pcall(function() gui.Parent = LocalPlayer:WaitForChild("PlayerGui") end)
    end

    local cleaned = false
    local function cleanup()
        if cleaned then return end
        cleaned = true
        for _, c in ipairs(Connections) do
            pcall(function() c:Disconnect() end)
        end
        table.clear(Connections)
        if typeof(getgenv) == "function" and getgenv()._LuminaqExplorerCleanup == cleanup then
            getgenv()._LuminaqExplorerCleanup = nil
        end
        pcall(function() gui:Destroy() end)
        if options.OnCleanup then
            pcall(options.OnCleanup)
        end
    end

    gui.Destroying:Connect(cleanup)

    if typeof(getgenv) == "function" then
        getgenv()._LuminaqExplorerCleanup = cleanup
        getgenv()._VoltikMenuTestGui = gui
    end

    -- // ======================================================================
    -- // OKNO GŁÓWNE
    -- // ======================================================================
    local W, H = 1000, 660
    local main = new("Frame", {
        Name = "Main",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.fromOffset(W, H),
        BackgroundColor3 = Palette.Bg,
        BackgroundTransparency = 0.02,
        BorderSizePixel = 0,
    }, gui)
    bindTheme(main, "BackgroundColor3", "Bg")
    corner(main, 22)
    local mainStroke = stroke(main, Palette.Stroke, 0.25, 1.2)
    bindTheme(mainStroke, "Color", "Stroke")

    local uiScale = Instance.new("UIScale")
    uiScale.Parent = main
    pcall(function()
        local vp = Workspace.CurrentCamera and Workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
        local s = math.min(1, (vp.X - 36) / W, (vp.Y - 36) / H)
        uiScale.Scale = math.clamp(s, 0.5, 1)
    end)

    -- Delikatna poświata pod oknem
    local glow = new("Frame", {
        Name = "Glow",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(1, 26, 1, 26),
        BackgroundColor3 = Palette.Accent,
        BackgroundTransparency = 0.94,
        BorderSizePixel = 0,
        ZIndex = 0,
    }, gui)
    corner(glow, 28)

    local gradientColors = {
        dark = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 22, 32)),
            ColorSequenceKeypoint.new(0.55, Color3.fromRGB(12, 13, 20)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(18, 16, 30)),
        }),
        light = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(248, 249, 253)),
            ColorSequenceKeypoint.new(0.55, Color3.fromRGB(238, 240, 247)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(245, 243, 255)),
        }),
    }

    local gradient = new("UIGradient", {
        Rotation = 25,
        Color = gradientColors.dark,
    }, main)

    -- // ======================================================================
    -- // TOP BAR
    -- // ======================================================================
    local topBar = new("Frame", {
        Name = "TopBar",
        Size = UDim2.new(1, 0, 0, 64),
        BackgroundColor3 = Palette.Bg2,
        BackgroundTransparency = 0.25,
        BorderSizePixel = 0,
    }, main)
    bindTheme(topBar, "BackgroundColor3", "Bg2")
    corner(topBar, 22)
    local topBarMask = new("Frame", {
        Name = "SquareBottom",
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.new(1, 0, 0.5, 0),
        BackgroundColor3 = Palette.Bg2,
        BackgroundTransparency = 0.25,
        BorderSizePixel = 0,
    }, topBar)
    bindTheme(topBarMask, "BackgroundColor3", "Bg2")
    local topLine = new("Frame", {
        Name = "BottomLine",
        Position = UDim2.new(0, 18, 1, -1),
        Size = UDim2.new(1, -36, 0, 1),
        BackgroundColor3 = Palette.Stroke,
        BackgroundTransparency = 0.35,
        BorderSizePixel = 0,
    }, topBar)
    bindTheme(topLine, "BackgroundColor3", "Stroke")

    -- Brand
    local brand = new("Frame", {
        Name = "Brand",
        Position = UDim2.new(0, 18, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        Size = UDim2.new(0, 205, 0, 34),
        BackgroundTransparency = 1,
    }, topBar)

    local brandOrb = new("Frame", {
        Name = "Orb",
        Size = UDim2.fromOffset(30, 30),
        Position = UDim2.new(0, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundColor3 = Palette.Accent,
        BorderSizePixel = 0,
    }, brand)
    corner(brandOrb, 15)
    local orbGradient = new("UIGradient", {
        Rotation = 45,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Palette.Accent),
            ColorSequenceKeypoint.new(1, Palette.Accent2),
        }),
    }, brandOrb)
    local orbLetter = new("TextLabel", {
        Text = "L",
        Font = Enum.Font.GothamBlack,
        TextSize = 16,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
    }, brandOrb)

    local brandText = new("TextLabel", {
        Text = "LuminaqHub",
        Font = Enum.Font.GothamBold,
        TextSize = 15,
        TextColor3 = Palette.Text,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 38, 0, 1),
        Size = UDim2.new(0, 120, 0, 18),
        TextXAlignment = Enum.TextXAlignment.Left,
    }, brand)
    bindTheme(brandText, "TextColor3", "Text")

    local proBadge = new("Frame", {
        Name = "ProBadge",
        Position = UDim2.new(0, 38, 0, 20),
        Size = UDim2.fromOffset(32, 13),
        BackgroundColor3 = Palette.Yellow,
        BackgroundTransparency = 0.75,
        BorderSizePixel = 0,
    }, brand)
    corner(proBadge, 4)
    new("TextLabel", {
        Text = "PRO",
        Font = Enum.Font.GothamBlack,
        TextSize = 8,
        TextColor3 = Palette.Yellow,
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
    }, proBadge)

    -- Nav
    local nav = new("Frame", {
        Name = "Nav",
        Position = UDim2.new(0, 224, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        Size = UDim2.new(0, 340, 0, 36),
        BackgroundColor3 = Palette.Card,
        BackgroundTransparency = 0.55,
        BorderSizePixel = 0,
    }, topBar)
    bindTheme(nav, "BackgroundColor3", "Card")
    corner(nav, 18)
    local navStroke = stroke(nav, Palette.StrokeSoft, 0.55, 1)
    bindTheme(navStroke, "Color", "StrokeSoft")
    local navLayout = new("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 4),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, nav)

    local navButtons = {}
    local activeCategory = "Dashboard"
    local navDefs = {
        { key = "Dashboard", label = "Dashboard", icon = "layout-dashboard" },
        { key = "Player", label = "Player", icon = "user" },
        { key = "Render", label = "Render", icon = "eye" },
        { key = "Misc", label = "Misc", icon = "wrench" },
    }

    -- Search
    local searchFrame = new("Frame", {
        Name = "Search",
        Position = UDim2.new(1, -430, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        Size = UDim2.new(0, 230, 0, 34),
        BackgroundColor3 = Palette.Card,
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
    }, topBar)
    bindTheme(searchFrame, "BackgroundColor3", "Card")
    corner(searchFrame, 17)
    local searchStroke = stroke(searchFrame, Palette.StrokeSoft, 0.4, 1)
    bindTheme(searchStroke, "Color", "StrokeSoft")
    local searchIcon = new("ImageLabel", {
        Size = UDim2.fromOffset(14, 14),
        Position = UDim2.new(0, 12, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundTransparency = 1,
        ImageColor3 = Palette.Dim,
    }, searchFrame)
    bindTheme(searchIcon, "ImageColor3", "Dim")
    applyIcon(searchIcon, "search")
    local searchBox = new("TextBox", {
        Name = "SearchBox",
        Position = UDim2.new(0, 34, 0, 0),
        Size = UDim2.new(1, -44, 1, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        TextColor3 = Palette.Text,
        PlaceholderText = "Szukaj scriptów...",
        PlaceholderColor3 = Palette.Dim2,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
        Text = "",
    }, searchFrame)
    bindTheme(searchBox, "TextColor3", "Text")
    bindTheme(searchBox, "PlaceholderColor3", "Dim2")

    -- FPS pill
    local fpsPill = new("Frame", {
        Name = "FpsPill",
        Position = UDim2.new(1, -124, 0.5, 0),
        AnchorPoint = Vector2.new(1, 0.5),
        Size = UDim2.new(0, 66, 0, 28),
        BackgroundColor3 = Palette.Card,
        BackgroundTransparency = 0.45,
        BorderSizePixel = 0,
    }, topBar)
    bindTheme(fpsPill, "BackgroundColor3", "Card")
    corner(fpsPill, 14)
    local fpsDot = new("Frame", {
        Size = UDim2.fromOffset(6, 6),
        Position = UDim2.new(0, 10, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundColor3 = Palette.Green,
        BorderSizePixel = 0,
    }, fpsPill)
    corner(fpsDot, 3)
    local fpsLabel = new("TextLabel", {
        Text = "60 FPS",
        Font = Enum.Font.GothamBold,
        TextSize = 10,
        TextColor3 = Palette.Green,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 20, 0, 0),
        Size = UDim2.new(1, -24, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
    }, fpsPill)

    -- Window controls
    local function makeWindowButton(iconName, xOffset, color)
        local btn = new("TextButton", {
            Size = UDim2.fromOffset(28, 28),
            Position = UDim2.new(1, xOffset, 0.5, 0),
            AnchorPoint = Vector2.new(1, 0.5),
            BackgroundColor3 = color or Palette.Card,
            BackgroundTransparency = 0.35,
            Text = "",
            AutoButtonColor = false,
        }, topBar)
        corner(btn, 9)
        local img = new("ImageLabel", {
            Size = UDim2.fromOffset(13, 13),
            Position = UDim2.fromScale(0.5, 0.5),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            ImageColor3 = Palette.Dim,
        }, btn)
        applyIcon(img, iconName)
        return btn, img
    end

    local themeBtn, themeIcon = makeWindowButton("palette", -86)
    local minBtn, minIcon = makeWindowButton("minus", -52)
    local closeBtn, closeIcon = makeWindowButton("x", -18, Palette.Red)

    -- // ======================================================================
    -- // CONTENT
    -- // ======================================================================
    local content = new("Frame", {
        Name = "Content",
        Position = UDim2.new(0, 18, 0, 76),
        Size = UDim2.new(1, -36, 1, -118),
        BackgroundTransparency = 1,
    }, main)

    local dashboardPage = new("Frame", {
        Name = "DashboardPage",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
    }, content)

    local explorerPage = new("Frame", {
        Name = "ExplorerPage",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Visible = false,
    }, content)

    -- // ======================================================================
    -- // DASHBOARD — PROFIL + STATYSTYKI
    -- // ======================================================================
    local profileCard = new("Frame", {
        Name = "ProfileCard",
        Size = UDim2.new(1, 0, 0, 104),
        BackgroundColor3 = Palette.Card,
        BackgroundTransparency = 0.28,
        BorderSizePixel = 0,
    }, dashboardPage)
    bindTheme(profileCard, "BackgroundColor3", "Card")
    corner(profileCard, 16)
    local profileStroke = stroke(profileCard, Palette.StrokeSoft, 0.45, 1)
    bindTheme(profileStroke, "Color", "StrokeSoft")

    local avatarFrame = new("Frame", {
        Name = "Avatar",
        Position = UDim2.new(0, 14, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        Size = UDim2.fromOffset(72, 72),
        BackgroundColor3 = Palette.Card3,
        BorderSizePixel = 0,
        ClipsDescendants = true,
    }, profileCard)
    bindTheme(avatarFrame, "BackgroundColor3", "Card3")
    corner(avatarFrame, 36)
    local avatarStroke = stroke(avatarFrame, Palette.Accent, 0.3, 2)
    local avatarImg = new("ImageLabel", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(LocalPlayer.UserId) .. "&w=150&h=150",
        ScaleType = Enum.ScaleType.Crop,
    }, avatarFrame)
    local onlineDot = new("Frame", {
        Size = UDim2.fromOffset(14, 14),
        Position = UDim2.new(1, -16, 1, -16),
        AnchorPoint = Vector2.new(1, 1),
        BackgroundColor3 = Palette.Green,
        BorderSizePixel = 0,
    }, avatarFrame)
    corner(onlineDot, 7)
    stroke(onlineDot, Palette.Card, 0, 2)

    local vipBadge = new("Frame", {
        Position = UDim2.new(0, 100, 0, 18),
        Size = UDim2.fromOffset(76, 18),
        BackgroundColor3 = Palette.Yellow,
        BackgroundTransparency = 0.78,
        BorderSizePixel = 0,
    }, profileCard)
    corner(vipBadge, 5)
    new("TextLabel", {
        Text = "★ VIP ELITE",
        Font = Enum.Font.GothamBold,
        TextSize = 8,
        TextColor3 = Palette.Yellow,
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
    }, vipBadge)

    local displayName = new("TextLabel", {
        Text = (LocalPlayer.DisplayName or LocalPlayer.Name):upper(),
        Font = Enum.Font.GothamBlack,
        TextSize = 18,
        TextColor3 = Palette.Text,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 182, 0, 14),
        Size = UDim2.new(0, 260, 0, 22),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, profileCard)
    bindTheme(displayName, "TextColor3", "Text")

    local handle = new("TextLabel", {
        Text = "@" .. LocalPlayer.Name,
        Font = Enum.Font.GothamMedium,
        TextSize = 11,
        TextColor3 = Palette.Dim,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 100, 0, 42),
        Size = UDim2.new(0, 260, 0, 16),
        TextXAlignment = Enum.TextXAlignment.Left,
    }, profileCard)
    bindTheme(handle, "TextColor3", "Dim")

    local accountInfo = new("TextLabel", {
        Text = "Wiek konta: " .. tostring(LocalPlayer.AccountAge) .. " dni  ·  ID: " .. tostring(LocalPlayer.UserId),
        Font = Enum.Font.GothamMedium,
        TextSize = 10,
        TextColor3 = Palette.Dim2,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 100, 0, 60),
        Size = UDim2.new(0, 300, 0, 14),
        TextXAlignment = Enum.TextXAlignment.Left,
    }, profileCard)
    bindTheme(accountInfo, "TextColor3", "Dim2")

    -- Statystyki
    local statsRow = new("Frame", {
        Name = "Stats",
        Position = UDim2.new(1, -14, 0.5, 0),
        AnchorPoint = Vector2.new(1, 0.5),
        Size = UDim2.new(0, 430, 0, 72),
        BackgroundTransparency = 1,
    }, profileCard)
    local statsLayout = new("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, statsRow)

    local function makeStatCard(order, iconName, titleText, accent)
        local card = new("Frame", {
            Size = UDim2.fromOffset(100, 64),
            BackgroundColor3 = Palette.Card2,
            BackgroundTransparency = 0.35,
            BorderSizePixel = 0,
            LayoutOrder = order,
        }, statsRow)
        bindTheme(card, "BackgroundColor3", "Card2")
        corner(card, 12)
        local s = stroke(card, Palette.StrokeSoft, 0.55, 1)
        bindTheme(s, "Color", "StrokeSoft")
        local ico = new("ImageLabel", {
            Size = UDim2.fromOffset(12, 12),
            Position = UDim2.new(0, 10, 0, 10),
            BackgroundTransparency = 1,
            ImageColor3 = accent,
        }, card)
        applyIcon(ico, iconName)
        new("TextLabel", {
            Text = titleText,
            Font = Enum.Font.GothamMedium,
            TextSize = 9,
            TextColor3 = Palette.Dim,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 26, 0, 8),
            Size = UDim2.new(1, -32, 0, 14),
            TextXAlignment = Enum.TextXAlignment.Left,
        }, card)
        local value = new("TextLabel", {
            Text = "--",
            Font = Enum.Font.GothamBold,
            TextSize = 15,
            TextColor3 = Palette.Text,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 10, 0, 32),
            Size = UDim2.new(1, -20, 0, 22),
            TextXAlignment = Enum.TextXAlignment.Left,
        }, card)
        bindTheme(value, "TextColor3", "Text")
        return value
    end

    local healthValue = makeStatCard(1, "heart", "Zdrowie", Palette.Red)
    local jumpValue   = makeStatCard(2, "arrow-up-circle", "Skok", Palette.Green)
    local pingValue   = makeStatCard(3, "wifi", "Ping", Palette.Accent)
    local speedValue  = makeStatCard(4, "zap", "Prędkość", Palette.Yellow)

    -- // ======================================================================
    -- // DASHBOARD — QUICK ACCESS + SERVER
    -- // ======================================================================
    local midRow = new("Frame", {
        Name = "MidRow",
        Position = UDim2.new(0, 0, 0, 116),
        Size = UDim2.new(1, 0, 0, 236),
        BackgroundTransparency = 1,
    }, dashboardPage)

    local quickCard = new("Frame", {
        Name = "QuickAccess",
        Size = UDim2.new(0.585, -6, 1, 0),
        BackgroundColor3 = Palette.Card,
        BackgroundTransparency = 0.28,
        BorderSizePixel = 0,
    }, midRow)
    bindTheme(quickCard, "BackgroundColor3", "Card")
    corner(quickCard, 16)
    local quickStroke = stroke(quickCard, Palette.StrokeSoft, 0.45, 1)
    bindTheme(quickStroke, "Color", "StrokeSoft")
    pad(quickCard, 14, 14, 12, 12)

    local quickHeader = new("Frame", {
        Size = UDim2.new(1, 0, 0, 22),
        BackgroundTransparency = 1,
    }, quickCard)
    local quickIcon = new("ImageLabel", {
        Size = UDim2.fromOffset(14, 14),
        Position = UDim2.new(0, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundTransparency = 1,
        ImageColor3 = Palette.Accent,
    }, quickHeader)
    applyIcon(quickIcon, "zap")
    local quickTitle = new("TextLabel", {
        Text = "Szybki Dostęp do Funkcji",
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextColor3 = Palette.Text,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 22, 0, 0),
        Size = UDim2.new(1, -22, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
    }, quickHeader)
    bindTheme(quickTitle, "TextColor3", "Text")

    local quickGrid = new("Frame", {
        Position = UDim2.new(0, 0, 0, 28),
        Size = UDim2.new(1, 0, 1, -28),
        BackgroundTransparency = 1,
    }, quickCard)
    local quickLayout = new("UIGridLayout", {
        CellSize = UDim2.new(0.5, -5, 0, 44),
        CellPadding = UDim2.new(0, 10, 0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        VerticalAlignment = Enum.VerticalAlignment.Top,
    }, quickGrid)

    local serverCard = new("Frame", {
        Name = "ServerCard",
        Position = UDim2.new(0.585, 6, 0, 0),
        Size = UDim2.new(0.415, -6, 1, 0),
        BackgroundColor3 = Palette.Card,
        BackgroundTransparency = 0.28,
        BorderSizePixel = 0,
    }, midRow)
    bindTheme(serverCard, "BackgroundColor3", "Card")
    corner(serverCard, 16)
    local serverStroke = stroke(serverCard, Palette.StrokeSoft, 0.45, 1)
    bindTheme(serverStroke, "Color", "StrokeSoft")
    pad(serverCard, 14, 14, 12, 12)

    local serverHeader = new("Frame", {
        Size = UDim2.new(1, 0, 0, 22),
        BackgroundTransparency = 1,
    }, serverCard)
    local serverIcon = new("ImageLabel", {
        Size = UDim2.fromOffset(14, 14),
        Position = UDim2.new(0, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundTransparency = 1,
        ImageColor3 = Palette.Cyan,
    }, serverHeader)
    applyIcon(serverIcon, "globe")
    local serverTitle = new("TextLabel", {
        Text = "Serwer & Świat",
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        TextColor3 = Palette.Text,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 22, 0, 0),
        Size = UDim2.new(1, -22, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
    }, serverHeader)
    bindTheme(serverTitle, "TextColor3", "Text")

    local placeLabel = new("TextLabel", {
        Text = "ID Miejsca: " .. formatNumber(game.PlaceId),
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        TextColor3 = Palette.Text,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 30),
        Size = UDim2.new(1, 0, 0, 16),
        TextXAlignment = Enum.TextXAlignment.Left,
    }, serverCard)
    bindTheme(placeLabel, "TextColor3", "Text")

    local playersLabel = new("TextLabel", {
        Text = "Gracze: " .. tostring(#Players:GetPlayers()) .. "/" .. tostring(Players.MaxPlayers) .. " w sesji",
        Font = Enum.Font.GothamMedium,
        TextSize = 10,
        TextColor3 = Palette.Dim,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 48),
        Size = UDim2.new(1, 0, 0, 14),
        TextXAlignment = Enum.TextXAlignment.Left,
    }, serverCard)
    bindTheme(playersLabel, "TextColor3", "Dim")

    local function serverButton(order, iconName, text, callback)
        local btn = new("TextButton", {
            Size = UDim2.new(1, 0, 0, 34),
            Position = UDim2.new(0, 0, 0, 70 + (order - 1) * 40),
            BackgroundColor3 = Palette.Card2,
            BackgroundTransparency = 0.35,
            Text = "",
            AutoButtonColor = false,
            LayoutOrder = order,
        }, serverCard)
        bindTheme(btn, "BackgroundColor3", "Card2")
        corner(btn, 9)
        local s = stroke(btn, Palette.StrokeSoft, 0.6, 1)
        bindTheme(s, "Color", "StrokeSoft")
        local ico = new("ImageLabel", {
            Size = UDim2.fromOffset(13, 13),
            Position = UDim2.new(0, 10, 0.5, 0),
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundTransparency = 1,
            ImageColor3 = Palette.Dim,
        }, btn)
        bindTheme(ico, "ImageColor3", "Dim")
        applyIcon(ico, iconName)
        local lbl = new("TextLabel", {
            Text = text,
            Font = Enum.Font.GothamMedium,
            TextSize = 11,
            TextColor3 = Palette.Text,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 30, 0, 0),
            Size = UDim2.new(1, -40, 1, 0),
            TextXAlignment = Enum.TextXAlignment.Left,
        }, btn)
        bindTheme(lbl, "TextColor3", "Text")
        btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundColor3 = Palette.Card3 }):Play()
        end)
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundColor3 = Palette.Card2 }):Play()
        end)
        btn.MouseButton1Click:Connect(callback)
        return btn
    end

    -- // ======================================================================
    -- // DASHBOARD — DOLNE KARTY
    -- // ======================================================================
    local bottomRow = new("Frame", {
        Name = "BottomRow",
        Position = UDim2.new(0, 0, 0, 364),
        Size = UDim2.new(1, 0, 1, -364),
        BackgroundTransparency = 1,
    }, dashboardPage)
    local bottomLayout = new("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, 10),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, bottomRow)

    local function communityCard(order, iconName, titleText, descText, accent, callback)
        local card = new("Frame", {
            Size = UDim2.new(1 / 3, -7, 1, 0),
            BackgroundColor3 = Palette.Card,
            BackgroundTransparency = 0.28,
            BorderSizePixel = 0,
            LayoutOrder = order,
        }, bottomRow)
        bindTheme(card, "BackgroundColor3", "Card")
        corner(card, 14)
        local s = stroke(card, Palette.StrokeSoft, 0.45, 1)
        bindTheme(s, "Color", "StrokeSoft")
        local ico = new("ImageLabel", {
            Size = UDim2.fromOffset(18, 18),
            Position = UDim2.new(0, 14, 0.5, 0),
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundTransparency = 1,
            ImageColor3 = accent,
        }, card)
        applyIcon(ico, iconName)
        new("TextLabel", {
            Text = titleText,
            Font = Enum.Font.GothamBold,
            TextSize = 11,
            TextColor3 = Palette.Text,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 42, 0, 12),
            Size = UDim2.new(1, -52, 0, 16),
            TextXAlignment = Enum.TextXAlignment.Left,
        }, card)
        new("TextLabel", {
            Text = descText,
            Font = Enum.Font.GothamMedium,
            TextSize = 9,
            TextColor3 = Palette.Dim,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 42, 0, 28),
            Size = UDim2.new(1, -52, 0, 14),
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
        }, card)
        local btn = new("TextButton", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            Text = "",
        }, card)
        btn.MouseButton1Click:Connect(callback)
        return card
    end

    -- // ======================================================================
    -- // EXPLORER — LISTA + SZCZEGÓŁY
    -- // ======================================================================
    local listPanel = new("Frame", {
        Name = "ListPanel",
        Size = UDim2.new(0.585, -6, 1, 0),
        BackgroundColor3 = Palette.Card,
        BackgroundTransparency = 0.28,
        BorderSizePixel = 0,
    }, explorerPage)
    bindTheme(listPanel, "BackgroundColor3", "Card")
    corner(listPanel, 16)
    local listStroke = stroke(listPanel, Palette.StrokeSoft, 0.45, 1)
    bindTheme(listStroke, "Color", "StrokeSoft")
    pad(listPanel, 14, 14, 12, 12)

    local listHeader = new("Frame", {
        Size = UDim2.new(1, 0, 0, 28),
        BackgroundTransparency = 1,
    }, listPanel)
    local listTitle = new("TextLabel", {
        Text = "Explorer Scriptów",
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextColor3 = Palette.Text,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -90, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
    }, listHeader)
    bindTheme(listTitle, "TextColor3", "Text")

    local countBadge = new("Frame", {
        Position = UDim2.new(1, -72, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        Size = UDim2.fromOffset(72, 20),
        BackgroundColor3 = Palette.Card2,
        BackgroundTransparency = 0.3,
        BorderSizePixel = 0,
    }, listHeader)
    bindTheme(countBadge, "BackgroundColor3", "Card2")
    corner(countBadge, 10)
    local countLabel = new("TextLabel", {
        Text = "0 scriptów",
        Font = Enum.Font.GothamMedium,
        TextSize = 9,
        TextColor3 = Palette.Dim,
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
    }, countBadge)
    bindTheme(countLabel, "TextColor3", "Dim")

    local listScroll = new("ScrollingFrame", {
        Name = "List",
        Position = UDim2.new(0, 0, 0, 34),
        Size = UDim2.new(1, 0, 1, -34),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = Palette.Accent,
        ScrollBarImageTransparency = 0.45,
        ScrollingDirection = Enum.ScrollingDirection.Y,
    }, listPanel)
    local listLayout = new("UIListLayout", {
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, listScroll)

    local detailPanel = new("Frame", {
        Name = "DetailPanel",
        Position = UDim2.new(0.585, 6, 0, 0),
        Size = UDim2.new(0.415, -6, 1, 0),
        BackgroundColor3 = Palette.Card,
        BackgroundTransparency = 0.28,
        BorderSizePixel = 0,
    }, explorerPage)
    bindTheme(detailPanel, "BackgroundColor3", "Card")
    corner(detailPanel, 16)
    local detailStroke = stroke(detailPanel, Palette.StrokeSoft, 0.45, 1)
    bindTheme(detailStroke, "Color", "StrokeSoft")
    pad(detailPanel, 16, 16, 14, 14)

    local detailContent = new("Frame", {
        Name = "DetailContent",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
    }, detailPanel)

    -- // ======================================================================
    -- // FOOTER
    -- // ======================================================================
    local footer = new("Frame", {
        Name = "Footer",
        Position = UDim2.new(0, 18, 1, -36),
        Size = UDim2.new(1, -36, 0, 28),
        BackgroundTransparency = 1,
    }, main)
    local footerLeft = new("TextLabel", {
        Text = "Dark Obsidian",
        Font = Enum.Font.GothamMedium,
        TextSize = 10,
        TextColor3 = Palette.Dim,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 200, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
    }, footer)
    bindTheme(footerLeft, "TextColor3", "Dim")
    local footerCenter = new("TextLabel", {
        Text = "Naciśnij [" .. tostring(options.ToggleUIKeybind or "K") .. "] aby ukryć menu",
        Font = Enum.Font.GothamMedium,
        TextSize = 10,
        TextColor3 = Palette.Dim2,
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        TextXAlignment = Enum.TextXAlignment.Center,
    }, footer)
    bindTheme(footerCenter, "TextColor3", "Dim2")
    local footerRight = new("TextLabel", {
        Text = "●  System Aktywny · Chroniony",
        Font = Enum.Font.GothamBold,
        TextSize = 10,
        TextColor3 = Palette.Green,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 240, 1, 0),
        Position = UDim2.new(1, -240, 0, 0),
        TextXAlignment = Enum.TextXAlignment.Right,
    }, footer)

    -- // ======================================================================
    -- // POWIADOMIENIA
    -- // ======================================================================
    local toastContainer = new("Frame", {
        Name = "Toasts",
        AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.new(0.5, 0, 1, -48),
        Size = UDim2.new(0, 420, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
    }, gui)
    local toastLayout = new("UIListLayout", {
        Padding = UDim.new(0, 6),
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        VerticalAlignment = Enum.VerticalAlignment.Bottom,
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, toastContainer)

    local toastOrder = 0
    local function notify(text, success)
        toastOrder = toastOrder + 1
        local toast = new("Frame", {
            Size = UDim2.new(1, 0, 0, 34),
            BackgroundColor3 = success == false and Palette.Red or Palette.Card,
            BackgroundTransparency = 0.08,
            BorderSizePixel = 0,
            LayoutOrder = toastOrder,
        }, toastContainer)
        corner(toast, 10)
        local s = stroke(toast, success == false and Palette.Red or Palette.Green, 0.35, 1)
        local dot = new("Frame", {
            Size = UDim2.fromOffset(7, 7),
            Position = UDim2.new(0, 14, 0.5, 0),
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundColor3 = success == false and Palette.Red or Palette.Green,
            BorderSizePixel = 0,
        }, toast)
        corner(dot, 4)
        new("TextLabel", {
            Text = tostring(text),
            Font = Enum.Font.GothamMedium,
            TextSize = 11,
            TextColor3 = Palette.Text,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 30, 0, 0),
            Size = UDim2.new(1, -40, 1, 0),
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
        }, toast)
        task.delay(3, function()
            if toast and toast.Parent then
                TweenService:Create(toast, TweenInfo.new(0.25), { BackgroundTransparency = 1 }):Play()
                for _, d in ipairs(toast:GetDescendants()) do
                    if d:IsA("TextLabel") then
                        TweenService:Create(d, TweenInfo.new(0.25), { TextTransparency = 1 }):Play()
                    end
                end
                task.wait(0.3)
                pcall(function() toast:Destroy() end)
            end
        end)
    end

    -- // ======================================================================
    -- // SWITCH
    -- // ======================================================================
    local function makeSwitch(parent, initial, onChange)
        local state = initial == true
        local btn = new("TextButton", {
            Size = UDim2.fromOffset(40, 22),
            BackgroundColor3 = state and Palette.Green or Palette.Card3,
            BackgroundTransparency = 0.15,
            Text = "",
            AutoButtonColor = false,
        }, parent)
        corner(btn, 11)
        local dot = new("Frame", {
            Size = UDim2.fromOffset(16, 16),
            Position = state and UDim2.new(1, -19, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BorderSizePixel = 0,
        }, btn)
        corner(dot, 8)

        local function setState(newState, fire)
            state = newState == true
            TweenService:Create(btn, TweenInfo.new(0.18), {
                BackgroundColor3 = state and Palette.Green or Palette.Card3,
            }):Play()
            TweenService:Create(dot, TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Position = state and UDim2.new(1, -19, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
            }):Play()
            if fire and onChange then
                onChange(state)
            end
        end

        btn.MouseButton1Click:Connect(function()
            setState(not state, true)
        end)

        return {
            Set = setState,
            Get = function() return state end,
            Button = btn,
        }
    end

    -- // ======================================================================
    -- // WYKONYWANIE SCRIPTÓW
    -- // ======================================================================
    local selectedEntry = nil
    local renderDetails

    local function setEntryState(entry, state, silent)
        entry.State = state == true
        if entry.OnToggle then
            local ok, err = pcall(entry.OnToggle, entry.State)
            if not ok then
                notify("Błąd: " .. tostring(err), false)
                return
            end
        end
        if entry._quickSwitch and entry._quickSwitch.Button and entry._quickSwitch.Button.Parent then
            entry._quickSwitch.Set(entry.State, false)
        end
        if entry._rowSwitch and entry._rowSwitch.Button and entry._rowSwitch.Button.Parent then
            entry._rowSwitch.Set(entry.State, false)
        end
        if not silent then
            notify(entry.Name .. (entry.State and " — włączony" or " — wyłączony"), entry.State)
        end
        if selectedEntry == entry and renderDetails then
            renderDetails(entry)
        end
    end

    local function executeEntry(entry)
        if entry.Mode == "toggle" then
            setEntryState(entry, not entry.State)
            return
        end
        if entry.Run then
            local ok, err = pcall(entry.Run)
            if ok then
                notify("Uruchomiono: " .. entry.Name, true)
            else
                notify("Błąd: " .. tostring(err), false)
            end
            return
        end
        if entry.Url then
            notify("Pobieram: " .. entry.Name .. "...", true)
            task.spawn(function()
                local url = entry.Url
                local cacheBuster = (url:find("%?") and "&" or "?") .. "_cb=" .. tostring(tick())
                local ok, code = pcall(function()
                    return game:HttpGet(url .. cacheBuster)
                end)
                if not ok or not code or #code == 0 then
                    notify("Nie udało się pobrać: " .. entry.Name, false)
                    return
                end
                local chunk, compileErr = loadstring(code)
                if not chunk then
                    notify("Błąd kompilacji: " .. tostring(compileErr), false)
                    return
                end
                local runOk, runErr = pcall(chunk)
                if runOk then
                    notify("Uruchomiono: " .. entry.Name, true)
                else
                    notify("Błąd wykonania: " .. tostring(runErr), false)
                end
            end)
            return
        end
        notify("Ten script nie ma akcji.", false)
    end

    -- // ======================================================================
    -- // SZCZEGÓŁY
    -- // ======================================================================
    local function clearChildren(obj)
        for _, child in ipairs(obj:GetChildren()) do
            if not child:IsA("UIListLayout") and not child:IsA("UIPadding") and not child:IsA("UIGridLayout") then
                child:Destroy()
            end
        end
    end

    local function makeDetailActionButton(parent, text, iconName, color, callback)
        local btn = new("TextButton", {
            Size = UDim2.new(1, 0, 0, 40),
            BackgroundColor3 = color,
            BackgroundTransparency = 0.1,
            Text = "",
            AutoButtonColor = false,
        }, parent)
        corner(btn, 10)
        local ico = new("ImageLabel", {
            Size = UDim2.fromOffset(15, 15),
            Position = UDim2.new(0, 14, 0.5, 0),
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundTransparency = 1,
            ImageColor3 = Color3.fromRGB(255, 255, 255),
        }, btn)
        applyIcon(ico, iconName)
        new("TextLabel", {
            Text = text,
            Font = Enum.Font.GothamBold,
            TextSize = 12,
            TextColor3 = Color3.fromRGB(255, 255, 255),
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 38, 0, 0),
            Size = UDim2.new(1, -48, 1, 0),
            TextXAlignment = Enum.TextXAlignment.Left,
        }, btn)
        btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundTransparency = 0 }):Play()
        end)
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundTransparency = 0.1 }):Play()
        end)
        btn.MouseButton1Click:Connect(callback)
        return btn
    end

    local function makeOptionSlider(parent, opt, order)
        local frame = new("Frame", {
            Size = UDim2.new(1, 0, 0, 48),
            BackgroundColor3 = Palette.Card2,
            BackgroundTransparency = 0.4,
            BorderSizePixel = 0,
            LayoutOrder = order,
        }, parent)
        bindTheme(frame, "BackgroundColor3", "Card2")
        corner(frame, 10)
        local lbl = new("TextLabel", {
            Text = opt.Name or "Wartość",
            Font = Enum.Font.GothamMedium,
            TextSize = 10,
            TextColor3 = Palette.Dim,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 10, 0, 6),
            Size = UDim2.new(1, -90, 0, 14),
            TextXAlignment = Enum.TextXAlignment.Left,
        }, frame)
        bindTheme(lbl, "TextColor3", "Dim")
        local valueLbl = new("TextLabel", {
            Text = "",
            Font = Enum.Font.GothamBold,
            TextSize = 10,
            TextColor3 = Palette.Accent,
            BackgroundTransparency = 1,
            Position = UDim2.new(1, -80, 0, 6),
            Size = UDim2.new(0, 70, 0, 14),
            TextXAlignment = Enum.TextXAlignment.Right,
        }, frame)

        local track = new("TextButton", {
            Position = UDim2.new(0, 10, 0, 30),
            Size = UDim2.new(1, -20, 0, 6),
            BackgroundColor3 = Palette.Card3,
            Text = "",
            AutoButtonColor = false,
        }, frame)
        bindTheme(track, "BackgroundColor3", "Card3")
        corner(track, 3)
        local fill = new("Frame", {
            Size = UDim2.new(0, 0, 1, 0),
            BackgroundColor3 = Palette.Accent,
            BorderSizePixel = 0,
        }, track)
        corner(fill, 3)
        local knob = new("Frame", {
            Size = UDim2.fromOffset(14, 14),
            Position = UDim2.new(0, 0, 0.5, 0),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BorderSizePixel = 0,
        }, track)
        corner(knob, 7)
        stroke(knob, Palette.Accent, 0, 2)

        local minVal = opt.Min or 0
        local maxVal = opt.Max or 100
        local step = opt.Step or 1
        local value = opt.Default or minVal
        local dragging = false

        local function setValue(v, fire)
            v = math.clamp(tonumber(v) or minVal, minVal, maxVal)
            if step > 0 then
                v = math.floor(v / step + 0.5) * step
            end
            value = v
            local rel = (maxVal > minVal) and ((v - minVal) / (maxVal - minVal)) or 0
            fill.Size = UDim2.new(rel, 0, 1, 0)
            knob.Position = UDim2.new(rel, 0, 0.5, 0)
            local suffix = opt.Suffix or ""
            valueLbl.Text = tostring(v) .. suffix
            if fire and opt.Callback then
                pcall(opt.Callback, v)
            end
        end

        local function updateFromInput(input)
            local rel = (input.Position.X - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1)
            setValue(minVal + math.clamp(rel, 0, 1) * (maxVal - minVal), true)
        end

        track.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                updateFromInput(input)
            end
        end)

        local changeConn = UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                updateFromInput(input)
            end
        end)
        local endConn = UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)

        track.Destroying:Connect(function()
            dragging = false
            if changeConn then changeConn:Disconnect(); changeConn = nil end
            if endConn then endConn:Disconnect(); endConn = nil end
        end)

        setValue(value, false)
        return {
            Set = setValue,
            Get = function() return value end,
        }
    end

    local function makeOptionToggle(parent, opt, order)
        local row = new("Frame", {
            Size = UDim2.new(1, 0, 0, 38),
            BackgroundColor3 = Palette.Card2,
            BackgroundTransparency = 0.4,
            BorderSizePixel = 0,
            LayoutOrder = order,
        }, parent)
        bindTheme(row, "BackgroundColor3", "Card2")
        corner(row, 10)
        local lbl = new("TextLabel", {
            Text = opt.Name or "Opcja",
            Font = Enum.Font.GothamMedium,
            TextSize = 10,
            TextColor3 = Palette.Text,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 10, 0, 0),
            Size = UDim2.new(1, -60, 1, 0),
            TextXAlignment = Enum.TextXAlignment.Left,
        }, row)
        bindTheme(lbl, "TextColor3", "Text")
        local sw = makeSwitch(row, opt.Default == true, function(state)
            if opt.Callback then pcall(opt.Callback, state) end
        end)
        sw.Button.Position = UDim2.new(1, -50, 0.5, 0)
        sw.Button.AnchorPoint = Vector2.new(0, 0.5)
        return sw
    end

    function renderDetails(entry)
        clearChildren(detailContent)
        if not entry then
            local empty = new("Frame", {
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
            }, detailContent)
            local ico = new("ImageLabel", {
                Size = UDim2.fromOffset(42, 42),
                Position = UDim2.new(0.5, 0, 0.32, 0),
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                ImageColor3 = Palette.Dim2,
            }, empty)
            applyIcon(ico, "folder")
            new("TextLabel", {
                Text = "Wybierz script z listy",
                Font = Enum.Font.GothamBold,
                TextSize = 13,
                TextColor3 = Palette.Text,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 0, 0.32, 34),
                Size = UDim2.new(1, 0, 0, 20),
            }, empty)
            new("TextLabel", {
                Text = "Wyszukaj script lub wybierz kategorię, aby zobaczyć szczegóły.",
                Font = Enum.Font.GothamMedium,
                TextSize = 10,
                TextColor3 = Palette.Dim,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 20, 0.32, 56),
                Size = UDim2.new(1, -40, 0, 30),
                TextWrapped = true,
            }, empty)
            return
        end

        local head = new("Frame", {
            Size = UDim2.new(1, 0, 0, 56),
            BackgroundTransparency = 1,
        }, detailContent)
        local iconBox = new("Frame", {
            Size = UDim2.fromOffset(46, 46),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundColor3 = Palette.Card2,
            BorderSizePixel = 0,
        }, head)
        bindTheme(iconBox, "BackgroundColor3", "Card2")
        corner(iconBox, 12)
        local bigIcon = new("ImageLabel", {
            Size = UDim2.fromOffset(22, 22),
            Position = UDim2.fromScale(0.5, 0.5),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            ImageColor3 = Palette.Accent,
        }, iconBox)
        applyIcon(bigIcon, entry.Icon)

        local nameLbl = new("TextLabel", {
            Text = entry.Name,
            Font = Enum.Font.GothamBold,
            TextSize = 15,
            TextColor3 = Palette.Text,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 58, 0, 2),
            Size = UDim2.new(1, -58, 0, 20),
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
        }, head)
        bindTheme(nameLbl, "TextColor3", "Text")

        local catLbl = new("TextLabel", {
            Text = entry.Category .. (entry.Pinned and "  ·  PINNED" or ""),
            Font = Enum.Font.GothamMedium,
            TextSize = 9,
            TextColor3 = Palette.Accent,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 58, 0, 24),
            Size = UDim2.new(1, -58, 0, 14),
            TextXAlignment = Enum.TextXAlignment.Left,
        }, head)

        local desc = new("TextLabel", {
            Text = entry.Description ~= "" and entry.Description or "Brak opisu.",
            Font = Enum.Font.GothamMedium,
            TextSize = 10,
            TextColor3 = Palette.Dim,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 0, 0, 66),
            Size = UDim2.new(1, 0, 0, 48),
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            TextWrapped = true,
        }, detailContent)
        bindTheme(desc, "TextColor3", "Dim")

        -- Tagi
        local tagY = 118
        if #entry.Tags > 0 then
            local tagRow = new("Frame", {
                Position = UDim2.new(0, 0, 0, tagY),
                Size = UDim2.new(1, 0, 0, 22),
                BackgroundTransparency = 1,
            }, detailContent)
            local tagLayout = new("UIListLayout", {
                FillDirection = Enum.FillDirection.Horizontal,
                Padding = UDim.new(0, 5),
                SortOrder = Enum.SortOrder.LayoutOrder,
            }, tagRow)
            for i, tag in ipairs(entry.Tags) do
                local tagFrame = new("Frame", {
                    Size = UDim2.fromOffset(math.max(34, #tostring(tag) * 6 + 14), 20),
                    BackgroundColor3 = Palette.Card2,
                    BackgroundTransparency = 0.3,
                    BorderSizePixel = 0,
                    LayoutOrder = i,
                }, tagRow)
                bindTheme(tagFrame, "BackgroundColor3", "Card2")
                corner(tagFrame, 10)
                new("TextLabel", {
                    Text = "#" .. tostring(tag),
                    Font = Enum.Font.GothamMedium,
                    TextSize = 9,
                    TextColor3 = Palette.Dim,
                    BackgroundTransparency = 1,
                    Size = UDim2.fromScale(1, 1),
                }, tagFrame)
            end
        end

        -- Akcja
        local actionY = 150
        local actionColor = Palette.Accent
        if entry.Mode == "toggle" then
            actionColor = entry.State and Palette.Red or Palette.Green
        end
        local actionText = "Uruchom"
        local actionIcon = "play"
        if entry.Mode == "toggle" then
            actionText = entry.State and "Wyłącz" or "Włącz"
            actionIcon = entry.State and "square" or "play"
        elseif entry.Url then
            actionText = "Pobierz i uruchom"
            actionIcon = "download"
        end

        local actionBtn = makeDetailActionButton(detailContent, actionText, actionIcon, actionColor, function()
            executeEntry(entry)
        end)
        actionBtn.Position = UDim2.new(0, 0, 0, actionY)
        entry._detailBtn = actionBtn

        -- Opcje
        if entry.Options and #entry.Options > 0 then
            local optTitle = new("TextLabel", {
                Text = "Opcje",
                Font = Enum.Font.GothamBold,
                TextSize = 11,
                TextColor3 = Palette.Text,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 0, 0, actionY + 52),
                Size = UDim2.new(1, 0, 0, 16),
                TextXAlignment = Enum.TextXAlignment.Left,
            }, detailContent)
            bindTheme(optTitle, "TextColor3", "Text")

            local optFrame = new("Frame", {
                Position = UDim2.new(0, 0, 0, actionY + 72),
                Size = UDim2.new(1, 0, 1, -(actionY + 72)),
                BackgroundTransparency = 1,
            }, detailContent)
            local optLayout = new("UIListLayout", {
                Padding = UDim.new(0, 6),
                SortOrder = Enum.SortOrder.LayoutOrder,
            }, optFrame)
            for i, opt in ipairs(entry.Options) do
                if opt.Type == "slider" then
                    makeOptionSlider(optFrame, opt, i)
                elseif opt.Type == "toggle" then
                    makeOptionToggle(optFrame, opt, i)
                end
            end
        end
    end

    -- // ======================================================================
    -- // LISTA SCRIPTÓW
    -- // ======================================================================
    local query = ""

    local function matchesQuery(entry)
        if query == "" then return true end
        local haystack = (entry.Name .. " " .. entry.Description .. " " .. entry.Category .. " " .. table.concat(entry.Tags, " ")):lower()
        return haystack:find(query, 1, true) ~= nil
    end

    local function getFilteredScripts()
        local result = {}
        for _, entry in ipairs(Scripts) do
            local catOk = (activeCategory == "All" or activeCategory == "Search" or entry.Category == activeCategory)
            if catOk and matchesQuery(entry) then
                table.insert(result, entry)
            end
        end
        return result
    end

    local function makeScriptRow(entry, order)
        entry._rowSwitch = nil
        local row = new("Frame", {
            Size = UDim2.new(1, -6, 0, 64),
            BackgroundColor3 = Palette.Card2,
            BackgroundTransparency = 0.4,
            BorderSizePixel = 0,
            LayoutOrder = order,
        }, listScroll)
        bindTheme(row, "BackgroundColor3", "Card2")
        corner(row, 12)
        local rowStroke = stroke(row, Palette.StrokeSoft, 0.55, 1)
        bindTheme(rowStroke, "Color", "StrokeSoft")

        local iconBox = new("Frame", {
            Size = UDim2.fromOffset(34, 34),
            Position = UDim2.new(0, 10, 0.5, 0),
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundColor3 = Palette.Card3,
            BorderSizePixel = 0,
        }, row)
        bindTheme(iconBox, "BackgroundColor3", "Card3")
        corner(iconBox, 9)
        local ico = new("ImageLabel", {
            Size = UDim2.fromOffset(17, 17),
            Position = UDim2.fromScale(0.5, 0.5),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            ImageColor3 = Palette.Accent,
        }, iconBox)
        applyIcon(ico, entry.Icon)

        local nameLbl = new("TextLabel", {
            Text = entry.Name,
            Font = Enum.Font.GothamBold,
            TextSize = 11,
            TextColor3 = Palette.Text,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 52, 0, 9),
            Size = UDim2.new(1, -150, 0, 16),
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
        }, row)
        bindTheme(nameLbl, "TextColor3", "Text")

        local descLbl = new("TextLabel", {
            Text = entry.Description,
            Font = Enum.Font.GothamMedium,
            TextSize = 9,
            TextColor3 = Palette.Dim,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 52, 0, 26),
            Size = UDim2.new(1, -150, 0, 14),
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
        }, row)
        bindTheme(descLbl, "TextColor3", "Dim")

        local tagLbl = new("TextLabel", {
            Text = entry.Category .. (#entry.Tags > 0 and ("  ·  " .. table.concat(entry.Tags, " ")) or ""),
            Font = Enum.Font.GothamMedium,
            TextSize = 8,
            TextColor3 = Palette.Dim2,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 52, 0, 42),
            Size = UDim2.new(1, -150, 0, 12),
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
        }, row)
        bindTheme(tagLbl, "TextColor3", "Dim2")

        if entry.Mode == "toggle" then
            local sw = makeSwitch(row, entry.State, function(state)
                setEntryState(entry, state)
            end)
            sw.Button.Position = UDim2.new(1, -12, 0.5, 0)
            sw.Button.AnchorPoint = Vector2.new(1, 0.5)
            entry._rowSwitch = sw
        else
            local runBtn = new("TextButton", {
                Size = UDim2.fromOffset(58, 26),
                Position = UDim2.new(1, -12, 0.5, 0),
                AnchorPoint = Vector2.new(1, 0.5),
                BackgroundColor3 = Palette.Accent,
                BackgroundTransparency = 0.12,
                Text = "",
                AutoButtonColor = false,
            }, row)
            corner(runBtn, 8)
            local runIcon = new("ImageLabel", {
                Size = UDim2.fromOffset(10, 10),
                Position = UDim2.new(0, 8, 0.5, 0),
                AnchorPoint = Vector2.new(0, 0.5),
                BackgroundTransparency = 1,
                ImageColor3 = Color3.fromRGB(255, 255, 255),
            }, runBtn)
            applyIcon(runIcon, "play")
            new("TextLabel", {
                Text = "Run",
                Font = Enum.Font.GothamBold,
                TextSize = 9,
                TextColor3 = Color3.fromRGB(255, 255, 255),
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 22, 0, 0),
                Size = UDim2.new(1, -26, 1, 0),
                TextXAlignment = Enum.TextXAlignment.Left,
            }, runBtn)
            runBtn.MouseButton1Click:Connect(function()
                executeEntry(entry)
            end)
        end

        local selectBtn = new("TextButton", {
            Size = UDim2.new(1, -80, 1, 0),
            BackgroundTransparency = 1,
            Text = "",
        }, row)
        selectBtn.MouseButton1Click:Connect(function()
            selectedEntry = entry
            renderDetails(entry)
            for _, s in ipairs(Scripts) do
                if s._row and s._row.Parent then
                    local isSel = (s == entry)
                    TweenService:Create(s._row, TweenInfo.new(0.15), {
                        BackgroundColor3 = isSel and Palette.Card3 or Palette.Card2,
                    }):Play()
                end
            end
        end)
        row.MouseEnter:Connect(function()
            if selectedEntry ~= entry then
                TweenService:Create(row, TweenInfo.new(0.15), { BackgroundColor3 = Palette.Card3 }):Play()
            end
        end)
        row.MouseLeave:Connect(function()
            if selectedEntry ~= entry then
                TweenService:Create(row, TweenInfo.new(0.15), { BackgroundColor3 = Palette.Card2 }):Play()
            end
        end)

        entry._row = row
        return row
    end

    local function renderList()
        clearChildren(listScroll)
        local filtered = getFilteredScripts()
        countLabel.Text = tostring(#filtered) .. (#filtered == 1 and " script" or " scriptów")
        for i, entry in ipairs(filtered) do
            makeScriptRow(entry, i)
        end
        if #filtered == 0 then
            local empty = new("Frame", {
                Size = UDim2.new(1, -6, 0, 120),
                BackgroundColor3 = Palette.Card2,
                BackgroundTransparency = 0.5,
                BorderSizePixel = 0,
            }, listScroll)
            bindTheme(empty, "BackgroundColor3", "Card2")
            corner(empty, 12)
            new("TextLabel", {
                Text = query ~= "" and ("Brak wyników dla: \"" .. query .. "\"") or "Brak scriptów w tej kategorii",
                Font = Enum.Font.GothamBold,
                TextSize = 11,
                TextColor3 = Palette.Dim,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 0, 0.35, 0),
                Size = UDim2.new(1, 0, 0, 16),
            }, empty)
            new("TextLabel", {
                Text = "Spróbuj innej frazy lub kategorii.",
                Font = Enum.Font.GothamMedium,
                TextSize = 9,
                TextColor3 = Palette.Dim2,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 0, 0.35, 20),
                Size = UDim2.new(1, 0, 0, 14),
            }, empty)
        end
    end

    -- // ======================================================================
    -- // QUICK ACCESS (DASHBOARD)
    -- // ======================================================================
    local function buildQuickAccess()
        clearChildren(quickGrid)
        local index = 0
        for _, entry in ipairs(Scripts) do
            entry._quickSwitch = nil
            if entry.Pinned then
                index = index + 1
                local row = new("Frame", {
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundColor3 = Palette.Card2,
                    BackgroundTransparency = 0.45,
                    BorderSizePixel = 0,
                    LayoutOrder = index,
                }, quickGrid)
                bindTheme(row, "BackgroundColor3", "Card2")
                corner(row, 10)
                local ico = new("ImageLabel", {
                    Size = UDim2.fromOffset(14, 14),
                    Position = UDim2.new(0, 10, 0.5, 0),
                    AnchorPoint = Vector2.new(0, 0.5),
                    BackgroundTransparency = 1,
                    ImageColor3 = Palette.Dim,
                }, row)
                bindTheme(ico, "ImageColor3", "Dim")
                applyIcon(ico, entry.Icon)
                local lbl = new("TextLabel", {
                    Text = entry.Name,
                    Font = Enum.Font.GothamMedium,
                    TextSize = 10,
                    TextColor3 = Palette.Text,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 30, 0, 0),
                    Size = UDim2.new(1, -80, 1, 0),
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                }, row)
                bindTheme(lbl, "TextColor3", "Text")

                if entry.Mode == "toggle" then
                    local sw = makeSwitch(row, entry.State, function(state)
                        setEntryState(entry, state)
                    end)
                    sw.Button.Position = UDim2.new(1, -10, 0.5, 0)
                    sw.Button.AnchorPoint = Vector2.new(1, 0.5)
                    entry._quickSwitch = sw
                else
                    local runBtn = new("TextButton", {
                        Size = UDim2.fromOffset(26, 26),
                        Position = UDim2.new(1, -10, 0.5, 0),
                        AnchorPoint = Vector2.new(1, 0.5),
                        BackgroundColor3 = Palette.Accent,
                        BackgroundTransparency = 0.12,
                        Text = "",
                        AutoButtonColor = false,
                    }, row)
                    corner(runBtn, 8)
                    local runIcon = new("ImageLabel", {
                        Size = UDim2.fromOffset(11, 11),
                        Position = UDim2.fromScale(0.5, 0.5),
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        BackgroundTransparency = 1,
                        ImageColor3 = Color3.fromRGB(255, 255, 255),
                    }, runBtn)
                    applyIcon(runIcon, "play")
                    runBtn.MouseButton1Click:Connect(function()
                        executeEntry(entry)
                    end)
                end
            end
        end
        if index == 0 then
            local empty = new("TextLabel", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = "Brak przypiętych funkcji",
                Font = Enum.Font.GothamMedium,
                TextSize = 10,
                TextColor3 = Palette.Dim2,
            }, quickGrid)
            bindTheme(empty, "TextColor3", "Dim2")
        end
    end

    -- // ======================================================================
    -- // NAWIGACJA
    -- // ======================================================================
    local function setNavActive(category)
        for key, btn in pairs(navButtons) do
            local active = (key == category)
            local bg = active and Palette.Accent or Palette.Card
            TweenService:Create(btn.Frame, TweenInfo.new(0.15), {
                BackgroundColor3 = bg,
                BackgroundTransparency = active and 0.1 or 0.55,
            }):Play()
            TweenService:Create(btn.Label, TweenInfo.new(0.15), {
                TextColor3 = active and Color3.fromRGB(255, 255, 255) or Palette.Dim,
            }):Play()
            TweenService:Create(btn.Icon, TweenInfo.new(0.15), {
                ImageColor3 = active and Color3.fromRGB(255, 255, 255) or Palette.Dim,
            }):Play()
        end
    end

    local function selectCategory(category)
        activeCategory = category
        if category == "Dashboard" then
            dashboardPage.Visible = true
            explorerPage.Visible = false
            setNavActive("Dashboard")
        else
            dashboardPage.Visible = false
            explorerPage.Visible = true
            setNavActive(category)
            renderList()
        end
    end

    for i, def in ipairs(navDefs) do
        local btn = new("TextButton", {
            Size = UDim2.new(0, 82, 0, 28),
            BackgroundColor3 = Palette.Card,
            BackgroundTransparency = 0.55,
            Text = "",
            AutoButtonColor = false,
            LayoutOrder = i,
        }, nav)
        corner(btn, 14)
        local ico = new("ImageLabel", {
            Size = UDim2.fromOffset(12, 12),
            Position = UDim2.new(0, 12, 0.5, 0),
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundTransparency = 1,
            ImageColor3 = Palette.Dim,
        }, btn)
        applyIcon(ico, def.icon)
        local lbl = new("TextLabel", {
            Text = def.label,
            Font = Enum.Font.GothamMedium,
            TextSize = 10,
            TextColor3 = Palette.Dim,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 28, 0, 0),
            Size = UDim2.new(1, -32, 1, 0),
            TextXAlignment = Enum.TextXAlignment.Left,
        }, btn)
        btn.MouseButton1Click:Connect(function()
            query = ""
            searchBox.Text = ""
            selectCategory(def.key)
        end)
        navButtons[def.key] = { Frame = btn, Label = lbl, Icon = ico }
    end

    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        query = searchBox.Text:lower():gsub("^%s+", ""):gsub("%s+$", "")
        if query ~= "" then
            activeCategory = "Search"
            dashboardPage.Visible = false
            explorerPage.Visible = true
            setNavActive(nil)
            renderList()
        else
            selectCategory(activeCategory == "Search" and "Dashboard" or activeCategory)
        end
    end)

    -- // ======================================================================
    -- // SERVER & WORLD
    -- // ======================================================================
    local function rejoinServer()
        notify("Przechodzę do tego samego serwera...", true)
        pcall(function()
            TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
        end)
    end

    local function serverHop()
        notify("Szukam wolnego serwera...", true)
        task.spawn(function()
            local ok, res = pcall(function()
                return game:HttpGet("https://games.roblox.com/v1/games/" .. tostring(game.PlaceId) .. "/servers/Public?sortOrder=Asc&limit=100")
            end)
            if not ok or not res or #res == 0 then
                notify("Nie udało się pobrać listy serwerów.", false)
                return
            end
            local decodedOk, data = pcall(function()
                return HttpService:JSONDecode(res)
            end)
            if not decodedOk or type(data) ~= "table" then
                notify("Nieprawidłowa odpowiedź serwera.", false)
                return
            end
            local candidates = {}
            for _, server in ipairs(data.data or {}) do
                local id = server.id
                local playing = tonumber(server.playing) or 0
                local maxPlayers = tonumber(server.maxPlayers) or 0
                if id and id ~= game.JobId and (maxPlayers == 0 or playing < maxPlayers) then
                    table.insert(candidates, id)
                end
            end
            if #candidates == 0 then
                notify("Brak wolnych serwerów.", false)
                return
            end
            local target = candidates[math.random(1, #candidates)]
            notify("Przechodzę na inny serwer...", true)
            pcall(function()
                TeleportService:TeleportToPlaceInstance(game.PlaceId, target, LocalPlayer)
            end)
        end)
    end

    local function copyJobId()
        pcall(function() setclipboard(tostring(game.JobId)) end)
        notify("Skopiowano JobId: " .. tostring(game.JobId), true)
    end

    serverButton(1, "refresh-cw", "Rejoin Serwera", rejoinServer)
    serverButton(2, "globe", "Server Hop (Zmień)", serverHop)
    serverButton(3, "copy", "Kopiuj JobId Sesji", copyJobId)

    -- // ======================================================================
    -- // DOLNE KARTY
    -- // ======================================================================
    communityCard(1, "message-circle", "Discord Community", "Kliknij, aby skopiować link", Palette.Accent, function()
        pcall(function() setclipboard("https://discord.gg/luminaqhub") end)
        notify("Skopiowano link do Discorda.", true)
    end)
    communityCard(2, "github", "GitHub Repository", "LuminaqHub · Open Source", Palette.Accent2, function()
        pcall(function() setclipboard("https://github.com/XxvoltikxX/MenuTest") end)
        notify("Skopiowano link do GitHub.", true)
    end)
    communityCard(3, "shield", "Status Systemu", "v1.0.0 · Chroniony", Palette.Green, function()
        notify("System aktywny · ochrona włączona", true)
    end)

    -- // ======================================================================
    -- // STATYSTYKI LIVE
    -- // ======================================================================
    local function getPing()
        local ok, value = pcall(function()
            return Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
        end)
        if ok and type(value) == "number" then
            return math.floor(value)
        end
        return 0
    end

    local function updateStats()
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            local pct = hum.MaxHealth > 0 and math.floor((hum.Health / hum.MaxHealth) * 100) or 0
            healthValue.Text = tostring(pct) .. "%"
            jumpValue.Text = string.format("%.1f", hum.JumpPower or 50)
            speedValue.Text = string.format("%.1f", hum.WalkSpeed or 16)
        else
            healthValue.Text = "--"
            jumpValue.Text = "--"
            speedValue.Text = "--"
        end
        pingValue.Text = tostring(getPing()) .. " ms"
        playersLabel.Text = "Gracze: " .. tostring(#Players:GetPlayers()) .. "/" .. tostring(Players.MaxPlayers) .. " w sesji"
    end

    updateStats()
    task.spawn(function()
        while gui.Parent do
            pcall(updateStats)
            task.wait(0.5)
        end
    end)

    -- FPS
    local frames = 0
    local frameAcc = 0
    connect(RunService.RenderStepped:Connect(function(dt)
        frames = frames + 1
        frameAcc = frameAcc + (dt or 0)
        if frameAcc >= 0.5 then
            fpsLabel.Text = tostring(math.floor(frames / frameAcc)) .. " FPS"
            frames = 0
            frameAcc = 0
        end
    end))

    -- // ======================================================================
    -- // STEROWANIE OKNEM
    -- // ======================================================================
    local dragging = false
    local dragStart = nil
    topBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = {
                x = input.Position.X,
                y = input.Position.Y,
                ox = main.Position.X.Offset,
                oy = main.Position.Y.Offset,
            }
        end
    end)
    connect(UserInputService.InputChanged:Connect(function(input)
        if dragging and dragStart and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local dx = input.Position.X - dragStart.x
            local dy = input.Position.Y - dragStart.y
            main.Position = UDim2.new(0.5, dragStart.ox + dx, 0.5, dragStart.oy + dy)
        end
    end))
    connect(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
            dragStart = nil
        end
    end))

    -- Floating restore button
    local floating = new("TextButton", {
        Name = "FloatingToggle",
        Size = UDim2.fromOffset(46, 46),
        Position = UDim2.new(0, 18, 0, 18),
        BackgroundColor3 = Palette.Accent,
        BackgroundTransparency = 0.05,
        Text = "",
        AutoButtonColor = false,
        Visible = false,
        ZIndex = 50,
    }, gui)
    corner(floating, 23)
    local floatingLetter = new("TextLabel", {
        Text = "L",
        Font = Enum.Font.GothamBlack,
        TextSize = 18,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
    }, floating)

    local function setVisible(visible)
        main.Visible = visible
        glow.Visible = visible
        floating.Visible = not visible
    end

    floating.MouseButton1Click:Connect(function()
        setVisible(true)
    end)

    -- Keybind
    local keyName = options.ToggleUIKeybind or "K"
    local keyEnum = Enum.KeyCode[keyName] or Enum.KeyCode.K
    connect(UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == keyEnum then
            if searchBox:IsFocused() then return end
            setVisible(not main.Visible)
        end
    end))

    -- Przyciski okna
    minBtn.MouseButton1Click:Connect(function()
        setVisible(false)
    end)
    closeBtn.MouseButton1Click:Connect(function()
        cleanup()
    end)
    themeBtn.MouseButton1Click:Connect(function()
        applyTheme(Theme.mode == "dark" and "light" or "dark")
        gradient.Color = gradientColors[Theme.mode] or gradientColors.dark
        footerLeft.Text = Theme.mode == "dark" and "Dark Obsidian" or "Light Pearl"
        notify("Motyw: " .. footerLeft.Text, true)
    end)

    -- Hover dla przycisków okna
    for _, btn in ipairs({ themeBtn, minBtn, closeBtn }) do
        btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundTransparency = 0.05 }):Play()
        end)
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundTransparency = 0.35 }):Play()
        end)
    end

    -- // ======================================================================
    -- // START
    -- // ======================================================================
    buildQuickAccess()
    selectCategory("Dashboard")
    renderList()
    renderDetails(nil)

    local api = {
        ScreenGui = gui,
        MainFrame = main,
        Cleanup = function() cleanup() end,
        Notify = function(a, b, c)
            local text = type(a) == "string" and a or b
            local success = type(a) == "string" and b or c
            notify(text, success)
        end,
        Refresh = function()
            buildQuickAccess()
            renderList()
            if selectedEntry then renderDetails(selectedEntry) end
        end,
        SelectCategory = function(a, b)
            local category = type(a) == "string" and a or b
            selectCategory(category)
        end,
        SetVisible = function(a, b)
            local visible = type(a) == "boolean" and a or b
            setVisible(visible)
        end,
    }

    return api
end

return Explorer
