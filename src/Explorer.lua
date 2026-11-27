-- // ==========================================================================
-- // LUMINAQHUB — GAME PICKER
-- // Prosty panel wyboru gry: "Welcome to LuminaqHub" + wyszukiwarka + karty gier.
-- // Bez detekcji gry, bez kategorii, bez opcji — wybór jest w 100% manualny.
-- // ==========================================================================

local Explorer = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

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

local function pluralGames(n)
    n = math.floor(tonumber(n) or 0)
    if n == 1 then return "1 gra" end
    local mod10 = n % 10
    local mod100 = n % 100
    if mod10 >= 2 and mod10 <= 4 and (mod100 < 12 or mod100 > 14) then
        return tostring(n) .. " gry"
    end
    return tostring(n) .. " gier"
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
        local alive = {}
        for _, it in ipairs(Theme.items) do
            if it.obj and it.obj.Parent then
                pcall(function()
                    it.obj[it.prop] = Palette[it.role]
                end)
                table.insert(alive, it)
            end
        end
        Theme.items = alive
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
    -- // REJESTR GIER
    -- // ======================================================================
    local Games = {}
    for _, raw in ipairs(options.Games or {}) do
        if type(raw) == "table" then
            local id = tostring(raw.Id or raw.Folder or raw.Name or ("game" .. tostring(#Games + 1)))
            local tags = {}
            if type(raw.Tags) == "table" then
                for _, tag in ipairs(raw.Tags) do
                    local text = tostring(tag)
                    if text ~= "" then table.insert(tags, text) end
                end
            end
            table.insert(Games, {
                Id          = id,
                Name        = tostring(raw.Name or id),
                Description = tostring(raw.Description or ""),
                Icon        = raw.Icon or "gamepad-2",
                Tags        = tags,
                Folder      = tostring(raw.Folder or id),
                Url         = raw.Url,
                Run         = raw.Run,
                Author      = raw.Author,
            })
        end
    end

    local baseUrl = tostring(options.BaseUrl or "")

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

    local setVisible

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
    new("UIGradient", {
        Rotation = 45,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Palette.Accent),
            ColorSequenceKeypoint.new(1, Palette.Accent2),
        }),
    }, brandOrb)
    new("TextLabel", {
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

    -- Search
    local searchFrame = new("Frame", {
        Name = "Search",
        Position = UDim2.new(0.5, 50, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.new(0, 330, 0, 34),
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
        Size = UDim2.new(1, -72, 1, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        TextColor3 = Palette.Text,
        PlaceholderText = "Szukaj gry...",
        PlaceholderColor3 = Palette.Dim2,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
        Text = "",
    }, searchFrame)
    bindTheme(searchBox, "TextColor3", "Text")
    bindTheme(searchBox, "PlaceholderColor3", "Dim2")

    local clearSearchBtn = new("TextButton", {
        Name = "ClearSearch",
        Size = UDim2.fromOffset(22, 22),
        Position = UDim2.new(1, -8, 0.5, 0),
        AnchorPoint = Vector2.new(1, 0.5),
        BackgroundColor3 = Palette.Card3,
        BackgroundTransparency = 0.35,
        Text = "",
        AutoButtonColor = false,
        Visible = false,
    }, searchFrame)
    corner(clearSearchBtn, 11)
    local clearSearchIcon = new("ImageLabel", {
        Size = UDim2.fromOffset(10, 10),
        Position = UDim2.fromScale(0.5, 0.5),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        ImageColor3 = Palette.Dim,
    }, clearSearchBtn)
    bindTheme(clearSearchIcon, "ImageColor3", "Dim")
    applyIcon(clearSearchIcon, "x")

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
    -- // HERO — WELCOME
    -- // ======================================================================
    local hero = new("Frame", {
        Name = "Hero",
        Position = UDim2.new(0, 18, 0, 76),
        Size = UDim2.new(1, -36, 0, 64),
        BackgroundTransparency = 1,
    }, main)

    local welcome = new("TextLabel", {
        Name = "Welcome",
        Text = "Welcome to LuminaqHub",
        Font = Enum.Font.GothamBlack,
        TextSize = 26,
        TextColor3 = Palette.Text,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 2, 0, 0),
        Size = UDim2.new(1, -140, 0, 34),
        TextXAlignment = Enum.TextXAlignment.Left,
    }, hero)
    bindTheme(welcome, "TextColor3", "Text")

    local subtitle = new("TextLabel", {
        Name = "Subtitle",
        Text = "Wybierz grę, aby uruchomić jej skrypt. Wyszukaj tytuł powyżej.",
        Font = Enum.Font.GothamMedium,
        TextSize = 11,
        TextColor3 = Palette.Dim,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 2, 0, 38),
        Size = UDim2.new(1, -140, 0, 18),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, hero)
    bindTheme(subtitle, "TextColor3", "Dim")

    local countPill = new("Frame", {
        Name = "GameCount",
        Position = UDim2.new(1, 0, 0.5, 0),
        AnchorPoint = Vector2.new(1, 0.5),
        Size = UDim2.fromOffset(104, 28),
        BackgroundColor3 = Palette.Card,
        BackgroundTransparency = 0.4,
        BorderSizePixel = 0,
    }, hero)
    bindTheme(countPill, "BackgroundColor3", "Card")
    corner(countPill, 14)
    local countStroke = stroke(countPill, Palette.StrokeSoft, 0.5, 1)
    bindTheme(countStroke, "Color", "StrokeSoft")
    local countIcon = new("ImageLabel", {
        Size = UDim2.fromOffset(13, 13),
        Position = UDim2.new(0, 11, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundTransparency = 1,
        ImageColor3 = Palette.Accent,
    }, countPill)
    bindTheme(countIcon, "ImageColor3", "Accent")
    applyIcon(countIcon, "gamepad-2")
    local countLabel = new("TextLabel", {
        Name = "CountLabel",
        Text = pluralGames(#Games),
        Font = Enum.Font.GothamBold,
        TextSize = 10,
        TextColor3 = Palette.Text,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 32, 0, 0),
        Size = UDim2.new(1, -40, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
    }, countPill)
    bindTheme(countLabel, "TextColor3", "Text")

    -- // ======================================================================
    -- // SIATKA GIER
    -- // ======================================================================
    local gridPos = UDim2.new(0, 18, 0, 152)
    local gridSize = UDim2.new(1, -36, 1, -200)

    local grid = new("ScrollingFrame", {
        Name = "GameGrid",
        Position = gridPos,
        Size = gridSize,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = Palette.Accent,
        ScrollBarImageTransparency = 0.45,
        ScrollingDirection = Enum.ScrollingDirection.Y,
    }, main)
    pad(grid, 2, 8, 2, 8)
    new("UIGridLayout", {
        CellSize = UDim2.new(0.5, -6, 0, 104),
        CellPadding = UDim2.new(0, 12, 0, 12),
        SortOrder = Enum.SortOrder.LayoutOrder,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        VerticalAlignment = Enum.VerticalAlignment.Top,
    }, grid)

    -- Pusty stan
    local emptyState = new("Frame", {
        Name = "EmptyState",
        Position = gridPos,
        Size = gridSize,
        BackgroundTransparency = 1,
        Visible = false,
    }, main)
    local emptyBox = new("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
    }, emptyState)
    new("UIListLayout", {
        Padding = UDim.new(0, 8),
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, emptyBox)
    local emptyIcon = new("ImageLabel", {
        Size = UDim2.fromOffset(46, 46),
        BackgroundTransparency = 1,
        ImageColor3 = Palette.Dim2,
        LayoutOrder = 1,
    }, emptyBox)
    bindTheme(emptyIcon, "ImageColor3", "Dim2")
    applyIcon(emptyIcon, "gamepad-2")
    local emptyTitle = new("TextLabel", {
        Text = "Brak gier",
        Font = Enum.Font.GothamBold,
        TextSize = 15,
        TextColor3 = Palette.Text,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 22),
        LayoutOrder = 2,
    }, emptyBox)
    bindTheme(emptyTitle, "TextColor3", "Text")
    local emptyDesc = new("TextLabel", {
        Text = "Dodaj pierwszą grę w Games/Universal.lua",
        Font = Enum.Font.GothamMedium,
        TextSize = 11,
        TextColor3 = Palette.Dim,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 18),
        LayoutOrder = 3,
    }, emptyBox)
    bindTheme(emptyDesc, "TextColor3", "Dim")

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
    new("UIListLayout", {
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
        stroke(toast, success == false and Palette.Red or Palette.Green, 0.35, 1)
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
    -- // URUCHAMIANIE GRY
    -- // ======================================================================
    local launching = false

    local function resolveUrl(g)
        if g.Url and tostring(g.Url) ~= "" then
            local u = tostring(g.Url)
            if not u:match("^https?://") then
                local sep = (baseUrl ~= "" and baseUrl:sub(-1) ~= "/") and "/" or ""
                u = baseUrl .. sep .. u
            end
            return u
        end
        if baseUrl == "" then return nil end
        local sep = baseUrl:sub(-1) == "/" and "" or "/"
        return baseUrl .. sep .. tostring(g.Folder or g.Id) .. "/Script.lua"
    end

    local function launchGame(g)
        if type(g) ~= "table" then return end
        if launching then
            notify("Poczekaj — trwa uruchamianie.", false)
            return
        end
        launching = true
        notify("Uruchamiam: " .. tostring(g.Name) .. "...", true)

        local ok, err
        if type(g.Run) == "function" then
            ok, err = pcall(g.Run, g)
        else
            local url = resolveUrl(g)
            if not url then
                ok, err = false, "brak adresu skryptu"
            else
                ok, err = pcall(function()
                    local sep = url:find("?", 1, true) and "&" or "?"
                    local source = game:HttpGet(url .. sep .. "_cb=" .. tostring(tick()))
                    if type(source) ~= "string" or #source == 0 then
                        error("nie udało się pobrać skryptu")
                    end
                    local chunk, compileErr = loadstring(source)
                    if not chunk then
                        error(compileErr or "błąd kompilacji")
                    end
                    chunk()
                end)
            end
        end

        launching = false
        if cleaned then return end
        if ok then
            notify(tostring(g.Name) .. " — uruchomiono.", true)
            setVisible(false)
            -- Panel wyboru znika na dobre, żeby nie kolidował z menu uruchomionej gry
            task.delay(0.8, function()
                if not cleaned then cleanup() end
            end)
        else
            notify("Błąd: " .. tostring(err), false)
        end
    end

    -- // ======================================================================
    -- // KARTY GIER
    -- // ======================================================================
    local cardInstances = {}

    local function clearCards()
        for _, card in ipairs(cardInstances) do
            pcall(function() card:Destroy() end)
        end
        cardInstances = {}
    end

    local function buildCard(g, order)
        local card = new("TextButton", {
            Name = "Game_" .. tostring(g.Id),
            Size = UDim2.fromScale(1, 1),
            BackgroundColor3 = Palette.Card,
            BackgroundTransparency = 0.12,
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor = false,
            LayoutOrder = order,
        }, grid)
        bindTheme(card, "BackgroundColor3", "Card")
        corner(card, 14)
        local cardStroke = stroke(card, Palette.StrokeSoft, 0.5, 1)
        bindTheme(cardStroke, "Color", "StrokeSoft")
        table.insert(cardInstances, card)

        local iconFrame = new("Frame", {
            Name = "Icon",
            Size = UDim2.fromOffset(44, 44),
            Position = UDim2.new(0, 14, 0.5, 0),
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundColor3 = Palette.Card3,
            BackgroundTransparency = 0.2,
            BorderSizePixel = 0,
        }, card)
        bindTheme(iconFrame, "BackgroundColor3", "Card3")
        corner(iconFrame, 12)
        local iconImg = new("ImageLabel", {
            Size = UDim2.fromOffset(20, 20),
            Position = UDim2.fromScale(0.5, 0.5),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            ImageColor3 = Palette.Accent,
        }, iconFrame)
        bindTheme(iconImg, "ImageColor3", "Accent")
        applyIcon(iconImg, g.Icon)

        local nameLabel = new("TextLabel", {
            Text = g.Name,
            Font = Enum.Font.GothamBold,
            TextSize = 13,
            TextColor3 = Palette.Text,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 70, 0, 14),
            Size = UDim2.new(1, -186, 0, 18),
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
        }, card)
        bindTheme(nameLabel, "TextColor3", "Text")

        local descLabel = new("TextLabel", {
            Text = g.Description ~= "" and g.Description or "Brak opisu",
            Font = Enum.Font.GothamMedium,
            TextSize = 10,
            TextColor3 = Palette.Dim,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 70, 0, 34),
            Size = UDim2.new(1, -186, 0, 16),
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
        }, card)
        bindTheme(descLabel, "TextColor3", "Dim")

        local tagRow = new("Frame", {
            Name = "Tags",
            Position = UDim2.new(0, 70, 0, 56),
            Size = UDim2.new(1, -186, 0, 16),
            BackgroundTransparency = 1,
        }, card)
        new("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            Padding = UDim.new(0, 5),
            VerticalAlignment = Enum.VerticalAlignment.Center,
            SortOrder = Enum.SortOrder.LayoutOrder,
        }, tagRow)

        local shownTags = 0
        for _, tag in ipairs(g.Tags) do
            if shownTags >= 3 then break end
            shownTags = shownTags + 1
            local chip = new("Frame", {
                Size = UDim2.fromOffset(0, 15),
                AutomaticSize = Enum.AutomaticSize.X,
                BackgroundColor3 = Palette.Card3,
                BackgroundTransparency = 0.3,
                BorderSizePixel = 0,
                LayoutOrder = shownTags,
            }, tagRow)
            bindTheme(chip, "BackgroundColor3", "Card3")
            corner(chip, 7)
            pad(chip, 7, 7, 0, 0)
            new("TextLabel", {
                Text = tostring(tag),
                Font = Enum.Font.GothamMedium,
                TextSize = 9,
                TextColor3 = Palette.Dim,
                BackgroundTransparency = 1,
                Size = UDim2.fromOffset(0, 15),
                AutomaticSize = Enum.AutomaticSize.X,
                TextXAlignment = Enum.TextXAlignment.Left,
            }, chip)
        end

        if g.Author and tostring(g.Author) ~= "" then
            local authorLabel = new("TextLabel", {
                Text = "przez " .. tostring(g.Author),
                Font = Enum.Font.GothamMedium,
                TextSize = 9,
                TextColor3 = Palette.Dim2,
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 70, 0, 76),
                Size = UDim2.new(1, -186, 0, 14),
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
            }, card)
            bindTheme(authorLabel, "TextColor3", "Dim2")
        end

        local playBtn = new("TextButton", {
            Name = "Play",
            Size = UDim2.fromOffset(92, 32),
            Position = UDim2.new(1, -14, 0.5, 0),
            AnchorPoint = Vector2.new(1, 0.5),
            BackgroundColor3 = Palette.Accent,
            BackgroundTransparency = 0.05,
            Text = "",
            AutoButtonColor = false,
        }, card)
        bindTheme(playBtn, "BackgroundColor3", "Accent")
        corner(playBtn, 9)
        local playIcon = new("ImageLabel", {
            Size = UDim2.fromOffset(11, 11),
            Position = UDim2.new(0, 12, 0.5, 0),
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundTransparency = 1,
            ImageColor3 = Color3.fromRGB(255, 255, 255),
        }, playBtn)
        applyIcon(playIcon, "play")
        new("TextLabel", {
            Text = "Graj",
            Font = Enum.Font.GothamBold,
            TextSize = 11,
            TextColor3 = Color3.fromRGB(255, 255, 255),
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 30, 0, 0),
            Size = UDim2.new(1, -38, 1, 0),
            TextXAlignment = Enum.TextXAlignment.Left,
        }, playBtn)

        card.MouseEnter:Connect(function()
            TweenService:Create(card, TweenInfo.new(0.15), { BackgroundTransparency = 0 }):Play()
        end)
        card.MouseLeave:Connect(function()
            TweenService:Create(card, TweenInfo.new(0.15), { BackgroundTransparency = 0.12 }):Play()
        end)
        playBtn.MouseEnter:Connect(function()
            TweenService:Create(playBtn, TweenInfo.new(0.15), { BackgroundTransparency = 0 }):Play()
        end)
        playBtn.MouseLeave:Connect(function()
            TweenService:Create(playBtn, TweenInfo.new(0.15), { BackgroundTransparency = 0.05 }):Play()
        end)

        card.MouseButton1Click:Connect(function() launchGame(g) end)
        playBtn.MouseButton1Click:Connect(function() launchGame(g) end)

        return card
    end

    local function matches(g, query)
        if query == "" then return true end
        local haystack = table.concat({
            g.Name,
            g.Description,
            tostring(g.Author or ""),
            tostring(g.Id),
            table.concat(g.Tags, " "),
        }, " "):lower()
        return haystack:find(query, 1, true) ~= nil
    end

    local function renderGames()
        clearCards()
        local query = tostring(searchBox.Text or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")

        local shown = 0
        for _, g in ipairs(Games) do
            if matches(g, query) then
                shown = shown + 1
                buildCard(g, shown)
            end
        end

        countLabel.Text = pluralGames(#Games)
        clearSearchBtn.Visible = query ~= ""

        if #Games == 0 then
            emptyState.Visible = true
            applyIcon(emptyIcon, "gamepad-2")
            emptyTitle.Text = "Brak gier"
            emptyDesc.Text = "Dodaj pierwszą grę w Games/Universal.lua"
        elseif shown == 0 then
            emptyState.Visible = true
            applyIcon(emptyIcon, "search")
            emptyTitle.Text = "Nie znaleziono gry"
            emptyDesc.Text = "Spróbuj innej nazwy lub wyczyść wyszukiwanie."
        else
            emptyState.Visible = false
        end

        pcall(function() grid.CanvasPosition = Vector2.zero end)
    end

    connect(searchBox:GetPropertyChangedSignal("Text"):Connect(renderGames))
    clearSearchBtn.MouseButton1Click:Connect(function()
        searchBox.Text = ""
        renderGames()
    end)

    -- // ======================================================================
    -- // STEROWANIE OKNEM
    -- // ======================================================================
    local dragging = false
    local dragStart = nil
    topBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if UserInputService:GetFocusedTextBox() then return end
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
        if dragging and UserInputService:GetFocusedTextBox() then
            dragging = false
            dragStart = nil
            return
        end
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
    new("TextLabel", {
        Text = "L",
        Font = Enum.Font.GothamBlack,
        TextSize = 18,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
    }, floating)

    setVisible = function(visible)
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
            if UserInputService:GetFocusedTextBox() then return end
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
    -- // FPS
    -- // ======================================================================
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
    -- // START
    -- // ======================================================================
    renderGames()

    local api = {
        ScreenGui = gui,
        MainFrame = main,
        Games = Games,
        Cleanup = function() cleanup() end,
        Notify = function(a, b, c)
            local text = type(a) == "string" and a or b
            local success = type(a) == "string" and b or c
            notify(text, success)
        end,
        Refresh = function()
            renderGames()
        end,
        Launch = function(a, b)
            local g = type(b) == "table" and b or a
            launchGame(g)
        end,
        SetVisible = function(a, b)
            local visible = type(a) == "boolean" and a or b
            setVisible(visible)
        end,
    }

    return api
end

return Explorer
