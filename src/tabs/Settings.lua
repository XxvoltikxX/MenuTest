-- // ==========================================================================
-- // MENUTEST CYBER-SETTINGS HUB (CYBER-APEX V3.0)
-- // Kompleksowe centrum zarządzania konfiguracją, motywami wizualnymi,
-- // efektami ambient FX, ochroną klienta (AntiAFK, AntiFling) oraz chmurą configów.
-- // ==========================================================================

local Settings = {}

-- Serwisy
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local baseUrl = "https://raw.githubusercontent.com/XxvoltikxX/MenuTest/refs/heads/main/src/"

local function safeLoadSub(relativePath, remoteUrl)
    local isDev = (typeof(getgenv) == "function" and getgenv()._MenuTestDevMode == true)
    if isDev and typeof(readfile) == "function" then
        local candidates = {
            "MenuTest/src/" .. relativePath,
            "src/" .. relativePath,
            relativePath
        }
        for _, c in ipairs(candidates) do
            if typeof(isfile) == "function" and isfile(c) then
                local s, data = pcall(readfile, c)
                if s and data and #data > 0 then
                    data = data:gsub("^\239\187\191", "")
                    local chunk = loadstring(data)
                    if chunk then return chunk() end
                end
            end
        end
    end
    local cacheBuster = (remoteUrl:find("%?") and "&" or "?") .. "_nocache=" .. tostring(os.time()) .. "_" .. tostring(math.random(10000, 99999))
    local ok, res = pcall(function() return game:HttpGet(remoteUrl .. cacheBuster) end)
    if ok and res then
        res = res:gsub("^\239\187\191", "")
        local chunk = loadstring(res)
        if chunk then return chunk() end
    end
    return nil
end

function Settings:Render(UI, order, theme, mainFolder, passedToggle, passedIcons, passedGameId)
    local GameId = tostring(passedGameId or (UI and UI.GameId) or (game and (game.PlaceId or game.GameId)) or "109949693269081")
    local Icons = passedIcons or (UI and UI.Icons)
    if not Icons then
        Icons = safeLoadSub("Icons.lua", baseUrl .. "Icons.lua")
    end

    local SliderElement = safeLoadSub("elements/Slider.lua", baseUrl .. "elements/Slider.lua")

    -- Rejestrujemy pełną zakładkę Settings w głównym pasku zakładek (Dock)
    local TabElements = UI:CreateTab("Settings", "settings", order or 999)
    local Page = TabElements.Page
    Page.Name = "SettingsPage"
    UI.SettingsPage = Page

    local ThemeManager = UI.ThemeManager
    if ThemeManager and ThemeManager.Register then
        ThemeManager:Register(Page, "ScrollBarImageColor3", "Accent")
    end

    local PageLayout = Page:FindFirstChildOfClass("UIListLayout") or Instance.new("UIListLayout", Page)
    PageLayout.SortOrder = Enum.SortOrder.LayoutOrder
    PageLayout.Padding = UDim.new(0, 14)

    local PagePadding = Page:FindFirstChildOfClass("UIPadding") or Instance.new("UIPadding", Page)
    PagePadding.PaddingTop = UDim.new(0, 14)
    PagePadding.PaddingRight = UDim.new(0, 18)
    PagePadding.PaddingLeft = UDim.new(0, 18)
    PagePadding.PaddingBottom = UDim.new(0, 30)

    -- Pomocnicza funkcja do tworzenia nagłówków sekcji Bento
    local function createSectionHeader(titleText, iconName, subtext)
        local SecHeader = Instance.new("Frame")
        SecHeader.Name = "SectionHeader"
        SecHeader.Size = UDim2.new(1, 0, 0, 32)
        SecHeader.BackgroundTransparency = 1

        local HLayout = Instance.new("UIListLayout", SecHeader)
        HLayout.FillDirection = Enum.FillDirection.Horizontal
        HLayout.VerticalAlignment = Enum.VerticalAlignment.Center
        HLayout.Padding = UDim.new(0, 8)

        local IconImg = Instance.new("ImageLabel")
        IconImg.Size = UDim2.new(0, 16, 0, 16)
        IconImg.BackgroundTransparency = 1
        IconImg.ImageColor3 = Color3.fromRGB(129, 140, 248)
        IconImg.Parent = SecHeader
        if Icons and Icons.Apply then Icons:Apply(IconImg, iconName) end

        local TitleLbl = Instance.new("TextLabel")
        TitleLbl.Text = titleText
        TitleLbl.Font = Enum.Font.GothamBold
        TitleLbl.TextSize = 12
        TitleLbl.TextColor3 = Color3.fromRGB(240, 245, 255)
        TitleLbl.Size = UDim2.new(0, 0, 1, 0)
        TitleLbl.AutomaticSize = Enum.AutomaticSize.X
        TitleLbl.BackgroundTransparency = 1
        TitleLbl.Parent = SecHeader

        if subtext and #subtext > 0 then
            local Dot = Instance.new("Frame")
            Dot.Size = UDim2.new(0, 3, 0, 3)
            Dot.BackgroundColor3 = Color3.fromRGB(80, 85, 110)
            Dot.BorderSizePixel = 0
            Dot.Parent = SecHeader
            Instance.new("UICorner", Dot).CornerRadius = UDim.new(1, 0)

            local SubLbl = Instance.new("TextLabel")
            SubLbl.Text = subtext
            SubLbl.Font = Enum.Font.GothamMedium
            SubLbl.TextSize = 10
            SubLbl.TextColor3 = Color3.fromRGB(130, 135, 160)
            SubLbl.Size = UDim2.new(0, 0, 1, 0)
            SubLbl.AutomaticSize = Enum.AutomaticSize.X
            SubLbl.BackgroundTransparency = 1
            SubLbl.Parent = SecHeader
        end

        return SecHeader
    end

    -- // =========================================================================
    -- // =========================================================================
    -- // 0. HERO APPLE iPHONE (iOS 18) LIQUID GLASS SHOWCASE CARD
    -- // =========================================================================
    local GlassHero = Instance.new("Frame")
    GlassHero.Name = "GlassHero"
    GlassHero.Size = UDim2.new(1, 0, 0, 74)
    GlassHero.BackgroundColor3 = Color3.fromRGB(18, 22, 32)
    GlassHero.BackgroundTransparency = 0.30
    GlassHero.BorderSizePixel = 0
    GlassHero.LayoutOrder = 0
    GlassHero.Parent = Page
    Instance.new("UICorner", GlassHero).CornerRadius = UDim.new(0, 18)

    local GhStroke = Instance.new("UIStroke", GlassHero)
    GhStroke.Color = Color3.fromRGB(48, 54, 76)
    GhStroke.Thickness = 1
    GhStroke.Transparency = 0.65

    local GhGrad = Instance.new("UIGradient", GlassHero)
    GhGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 23, 34)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(13, 15, 22))
    })

    local GhPadding = Instance.new("UIPadding", GlassHero)
    GhPadding.PaddingLeft = UDim.new(0, 16)
    GhPadding.PaddingRight = UDim.new(0, 16)
    GhPadding.PaddingTop = UDim.new(0, 12)
    GhPadding.PaddingBottom = UDim.new(0, 12)

    local GhIconBox = Instance.new("Frame")
    GhIconBox.Size = UDim2.new(0, 44, 0, 44)
    GhIconBox.Position = UDim2.new(0, 0, 0.5, 0)
    GhIconBox.AnchorPoint = Vector2.new(0, 0.5)
    GhIconBox.BackgroundColor3 = Color3.fromRGB(24, 28, 40)
    GhIconBox.BackgroundTransparency = 0.3
    GhIconBox.BorderSizePixel = 0
    GhIconBox.Parent = GlassHero
    Instance.new("UICorner", GhIconBox).CornerRadius = UDim.new(1, 0)
    local GibStroke = Instance.new("UIStroke", GhIconBox)
    GibStroke.Color = Color3.fromRGB(50, 60, 85)
    GibStroke.Thickness = 1
    GibStroke.Transparency = 0.6

    local GhIcon = Instance.new("ImageLabel")
    GhIcon.Size = UDim2.new(0, 22, 0, 22)
    GhIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
    GhIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    GhIcon.BackgroundTransparency = 1
    GhIcon.ImageColor3 = Color3.fromRGB(150, 165, 195)
    GhIcon.Parent = GhIconBox
    if Icons and Icons.Apply then Icons:Apply(GhIcon, "layers") end

    local GhTextFrame = Instance.new("Frame")
    GhTextFrame.Size = UDim2.new(1, -160, 1, 0)
    GhTextFrame.Position = UDim2.new(0, 56, 0.5, 0)
    GhTextFrame.AnchorPoint = Vector2.new(0, 0.5)
    GhTextFrame.BackgroundTransparency = 1
    GhTextFrame.Parent = GlassHero

    local GhTitle = Instance.new("TextLabel")
    GhTitle.Text = "APPLE iPHONE (iOS 27.2) LIQUID GLASS"
    GhTitle.Font = Enum.Font.GothamBold
    GhTitle.TextSize = 13
    GhTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    GhTitle.TextXAlignment = Enum.TextXAlignment.Left
    GhTitle.Size = UDim2.new(1, 0, 0, 18)
    GhTitle.BackgroundTransparency = 1
    GhTitle.Parent = GhTextFrame

    local GhSub = Instance.new("TextLabel")
    GhSub.Text = "Dynamic Island 2.0, matowe szkło Liquid Glass z iOS 27.2, krawędzie 26px squircle i przełącznik Apple Green #34C759"
    GhSub.Font = Enum.Font.GothamMedium
    GhSub.TextSize = 10
    GhSub.TextColor3 = Color3.fromRGB(150, 165, 195)
    GhSub.TextXAlignment = Enum.TextXAlignment.Left
    GhSub.Size = UDim2.new(1, 0, 0, 16)
    GhSub.Position = UDim2.new(0, 0, 0, 20)
    GhSub.BackgroundTransparency = 1
    GhSub.Parent = GhTextFrame

    -- Główny przełącznik Liquid Glass (Apple iOS Switch)
    local isLgOn = true
    if UI and UI.MenuConfig and UI.MenuConfig["LiquidGlass"] ~= nil then
        isLgOn = (UI.MenuConfig["LiquidGlass"] == true)
    end

    local GhSwitch = Instance.new("TextButton")
    GhSwitch.Size = UDim2.new(0, 52, 0, 28)
    GhSwitch.Position = UDim2.new(1, 0, 0.5, 0)
    GhSwitch.AnchorPoint = Vector2.new(1, 0.5)
    GhSwitch.BackgroundColor3 = isLgOn and Color3.fromRGB(52, 199, 89) or Color3.fromRGB(50, 54, 66)
    GhSwitch.BackgroundTransparency = 0.15
    GhSwitch.Text = ""
    GhSwitch.AutoButtonColor = false
    GhSwitch.Parent = GlassHero
    Instance.new("UICorner", GhSwitch).CornerRadius = UDim.new(1, 0)
    local GhsStroke = Instance.new("UIStroke", GhSwitch)
    GhsStroke.Color = isLgOn and Color3.fromRGB(82, 222, 118) or Color3.fromRGB(70, 75, 90)
    GhsStroke.Thickness = 1.2
    GhsStroke.Transparency = 0.35

    local GhDot = Instance.new("Frame")
    GhDot.Size = UDim2.new(0, 22, 0, 22)
    GhDot.Position = isLgOn and UDim2.new(1, -25, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
    GhDot.AnchorPoint = Vector2.new(0, 0.5)
    GhDot.BackgroundColor3 = isLgOn and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(240, 242, 250)
    GhDot.BorderSizePixel = 0
    GhDot.Parent = GhSwitch
    Instance.new("UICorner", GhDot).CornerRadius = UDim.new(1, 0)

    GhSwitch.MouseButton1Click:Connect(function()
        isLgOn = not isLgOn
        local destPos = isLgOn and UDim2.new(1, -25, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
        local destBg = isLgOn and Color3.fromRGB(52, 199, 89) or Color3.fromRGB(50, 54, 66)
        local destStrk = isLgOn and Color3.fromRGB(82, 222, 118) or Color3.fromRGB(70, 75, 90)
        local destDot = isLgOn and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(240, 242, 250)

        TweenService:Create(GhDot, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Position = destPos,
            BackgroundColor3 = destDot
        }):Play()
        TweenService:Create(GhSwitch, TweenInfo.new(0.22), { BackgroundColor3 = destBg }):Play()
        TweenService:Create(GhsStroke, TweenInfo.new(0.22), { Color = destStrk }):Play()

        if UI and UI.SetLiquidGlass then
            UI:SetLiquidGlass(isLgOn)
        end
        if UI and UI.MenuConfig then
            UI.MenuConfig["LiquidGlass"] = isLgOn
        end
        if UI and UI.SaveMenuConfig then
            pcall(function() UI.SaveMenuConfig("LiquidGlass", isLgOn) end)
        end
    end)

    -- // =========================================================================
    -- // 1. HERO SYSTEM COMMAND HUD (TELEMETRIA SILNIKA)
    -- // =========================================================================
    local HeroTile = Instance.new("Frame")
    HeroTile.Name = "HeroTile"
    HeroTile.Size = UDim2.new(1, 0, 0, 68)
    HeroTile.BackgroundColor3 = Color3.fromRGB(15, 16, 24)
    HeroTile.BorderSizePixel = 0
    HeroTile.LayoutOrder = 1
    HeroTile.Parent = Page
    Instance.new("UICorner", HeroTile).CornerRadius = UDim.new(0, 10)
    local HtStroke = Instance.new("UIStroke", HeroTile)
    HtStroke.Color = Color3.fromRGB(36, 38, 56)
    HtStroke.Thickness = 1.2

    local HtGrad = Instance.new("UIGradient", HeroTile)
    HtGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 22, 34)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(14, 15, 22))
    })

    local HtPadding = Instance.new("UIPadding", HeroTile)
    HtPadding.PaddingLeft = UDim.new(0, 16)
    HtPadding.PaddingRight = UDim.new(0, 16)
    HtPadding.PaddingTop = UDim.new(0, 12)
    HtPadding.PaddingBottom = UDim.new(0, 12)

    -- Lewa strona: Game ID i wersja
    local HtLeft = Instance.new("Frame")
    HtLeft.Size = UDim2.new(0.5, 0, 1, 0)
    HtLeft.BackgroundTransparency = 1
    HtLeft.Parent = HeroTile

    local HtTitle = Instance.new("TextLabel")
    HtTitle.Text = "SYSTEM CONFIGURATION & SECURITY"
    HtTitle.Font = Enum.Font.GothamBold
    HtTitle.TextSize = 13
    HtTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    HtTitle.TextXAlignment = Enum.TextXAlignment.Left
    HtTitle.Size = UDim2.new(1, 0, 0, 18)
    HtTitle.BackgroundTransparency = 1
    HtTitle.Parent = HtLeft

    local HtSub = Instance.new("TextLabel")
    HtSub.Text = "MenuTest Framework • Place ID: " .. GameId .. " • Sandbox Active"
    HtSub.Font = Enum.Font.GothamMedium
    HtSub.TextSize = 10
    HtSub.TextColor3 = Color3.fromRGB(130, 138, 165)
    HtSub.TextXAlignment = Enum.TextXAlignment.Left
    HtSub.Size = UDim2.new(1, 0, 0, 16)
    HtSub.Position = UDim2.new(0, 0, 0, 20)
    HtSub.BackgroundTransparency = 1
    HtSub.Parent = HtLeft

    -- Prawa strona: Kasetki telemetryczne na żywo
    local HtRight = Instance.new("Frame")
    HtRight.Size = UDim2.new(0.5, 0, 1, 0)
    HtRight.Position = UDim2.new(0.5, 0, 0, 0)
    HtRight.BackgroundTransparency = 1
    HtRight.Parent = HeroTile

    local HtRightLayout = Instance.new("UIListLayout", HtRight)
    HtRightLayout.FillDirection = Enum.FillDirection.Horizontal
    HtRightLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    HtRightLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    HtRightLayout.Padding = UDim.new(0, 8)

    local function makeHeroBadge(lblText, valText, color)
        local b = Instance.new("Frame")
        b.Size = UDim2.new(0, 0, 0, 32)
        b.AutomaticSize = Enum.AutomaticSize.X
        b.BackgroundColor3 = Color3.fromRGB(22, 24, 36)
        b.Parent = HtRight
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
        local s = Instance.new("UIStroke", b)
        s.Color = Color3.fromRGB(40, 44, 65)
        s.Thickness = 1
        local pad = Instance.new("UIPadding", b)
        pad.PaddingLeft = UDim.new(0, 10)
        pad.PaddingRight = UDim.new(0, 10)
        local lay = Instance.new("UIListLayout", b)
        lay.FillDirection = Enum.FillDirection.Vertical
        lay.VerticalAlignment = Enum.VerticalAlignment.Center

        local top = Instance.new("TextLabel")
        top.Text = lblText
        top.Font = Enum.Font.GothamMedium
        top.TextSize = 8
        top.TextColor3 = Color3.fromRGB(140, 145, 170)
        top.Size = UDim2.new(0, 0, 0, 11)
        top.AutomaticSize = Enum.AutomaticSize.X
        top.BackgroundTransparency = 1
        top.Parent = b

        local val = Instance.new("TextLabel")
        val.Text = valText
        val.Font = Enum.Font.GothamBold
        val.TextSize = 11
        val.TextColor3 = color
        val.Size = UDim2.new(0, 0, 0, 14)
        val.AutomaticSize = Enum.AutomaticSize.X
        val.BackgroundTransparency = 1
        val.Parent = b
        return val
    end

    local MemoryVal = makeHeroBadge("LUA MEMORY", "18.4 MB", Color3.fromRGB(129, 140, 248))
    local SecurityVal = makeHeroBadge("PROTECTION", "SECURE", Color3.fromRGB(16, 185, 129))

    task.spawn(function()
        while task.wait(2) do
            if not HeroTile.Parent then break end
            pcall(function()
                local mem = math.floor(gcinfo() / 1024 * 10) / 10
                MemoryVal.Text = tostring(mem) .. " MB"
            end)
        end
    end)

    -- // =========================================================================
    -- // 2. THEMES SHOWROOM (WIZUALNA GALERIA PALET)
    -- // =========================================================================
    local ThemesSection = Instance.new("Frame")
    ThemesSection.Name = "ThemesSection"
    ThemesSection.Size = UDim2.new(1, 0, 0, 0)
    ThemesSection.AutomaticSize = Enum.AutomaticSize.Y
    ThemesSection.BackgroundTransparency = 1
    ThemesSection.LayoutOrder = 2
    ThemesSection.Parent = Page

    local ThemesSecLayout = Instance.new("UIListLayout", ThemesSection)
    ThemesSecLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ThemesSecLayout.Padding = UDim.new(0, 8)

    local ThHeader = createSectionHeader("THEMES SHOWROOM", "palette", "Wybierz luksusową paletę kolorystyczną dla całego menu")
    ThHeader.LayoutOrder = 1
    ThHeader.Parent = ThemesSection

    local ThemesCard = Instance.new("Frame")
    ThemesCard.Name = "ThemesCard"
    ThemesCard.Size = UDim2.new(1, 0, 0, 0)
    ThemesCard.AutomaticSize = Enum.AutomaticSize.Y
    ThemesCard.BackgroundColor3 = Color3.fromRGB(15, 16, 24)
    ThemesCard.BorderSizePixel = 0
    ThemesCard.LayoutOrder = 2
    ThemesCard.Parent = ThemesSection
    Instance.new("UICorner", ThemesCard).CornerRadius = UDim.new(0, 10)
    local TcStroke = Instance.new("UIStroke", ThemesCard)
    TcStroke.Color = Color3.fromRGB(34, 36, 52)
    TcStroke.Thickness = 1.2

    local TcPadding = Instance.new("UIPadding", ThemesCard)
    TcPadding.PaddingLeft = UDim.new(0, 12)
    TcPadding.PaddingRight = UDim.new(0, 12)
    TcPadding.PaddingTop = UDim.new(0, 12)
    TcPadding.PaddingBottom = UDim.new(0, 12)

    local ThemesGrid = Instance.new("Frame")
    ThemesGrid.Name = "ThemesGrid"
    ThemesGrid.Size = UDim2.new(1, 0, 0, 0)
    ThemesGrid.AutomaticSize = Enum.AutomaticSize.Y
    ThemesGrid.BackgroundTransparency = 1
    ThemesGrid.Parent = ThemesCard

    local isMobile = (UI and UI.IsMobile) or (UserInputService.TouchEnabled and not UserInputService.MouseEnabled)

    local TgLayout = Instance.new("UIGridLayout", ThemesGrid)
    TgLayout.CellPadding = UDim2.new(0, 8, 0, 8)
    TgLayout.CellSize = isMobile and UDim2.new(0.5, -4, 0, 56) or UDim2.new(0.25, -6, 0, 58)
    TgLayout.SortOrder = Enum.SortOrder.LayoutOrder

    local builtins = {
        ["dark"] = {
            Name = "Dark Obsidian",
            Colors = { Main = {15, 15, 15}, Secondary = {25, 25, 25}, Accent = {99, 102, 241}, Accent2 = {40, 40, 40}, Success = {16, 185, 129}, Text = {255, 255, 255}, Text_Secondary = {160, 160, 160}, Close = {225, 29, 72} },
            Swatches = { Color3.fromRGB(15, 15, 15), Color3.fromRGB(28, 30, 42), Color3.fromRGB(99, 102, 241) }
        },
        ["midnight"] = {
            Name = "Midnight Blue",
            Colors = { Main = {10, 13, 20}, Secondary = {16, 21, 32}, Accent = {59, 130, 246}, Accent2 = {25, 34, 50}, Success = {16, 185, 129}, Text = {240, 246, 255}, Text_Secondary = {130, 148, 178}, Close = {235, 70, 85} },
            Swatches = { Color3.fromRGB(10, 13, 20), Color3.fromRGB(20, 28, 44), Color3.fromRGB(59, 130, 246) }
        },
        ["amethyst"] = {
            Name = "Amethyst Purple",
            Colors = { Main = {16, 12, 24}, Secondary = {26, 20, 38}, Accent = {168, 85, 247}, Accent2 = {40, 28, 58}, Success = {16, 185, 129}, Text = {250, 244, 255}, Text_Secondary = {172, 150, 198}, Close = {235, 60, 90} },
            Swatches = { Color3.fromRGB(16, 12, 24), Color3.fromRGB(34, 24, 48), Color3.fromRGB(168, 85, 247) }
        },
        ["cyberpunk"] = {
            Name = "Cyberpunk 2077",
            Colors = { Main = {12, 10, 20}, Secondary = {24, 16, 40}, Accent = {255, 0, 128}, Accent2 = {0, 240, 255}, Success = {0, 255, 170}, Text = {255, 255, 255}, Text_Secondary = {180, 160, 220}, Close = {255, 50, 80} },
            Swatches = { Color3.fromRGB(12, 10, 20), Color3.fromRGB(255, 0, 128), Color3.fromRGB(0, 240, 255) }
        },
        ["emerald"] = {
            Name = "Emerald Matrix",
            Colors = { Main = {10, 18, 14}, Secondary = {16, 28, 22}, Accent = {16, 185, 129}, Accent2 = {10, 80, 50}, Success = {52, 211, 153}, Text = {240, 255, 248}, Text_Secondary = {140, 185, 160}, Close = {240, 70, 70} },
            Swatches = { Color3.fromRGB(10, 18, 14), Color3.fromRGB(20, 42, 32), Color3.fromRGB(16, 185, 129) }
        },
        ["sunset"] = {
            Name = "Crimson Sunset",
            Colors = { Main = {18, 12, 16}, Secondary = {30, 18, 26}, Accent = {244, 63, 94}, Accent2 = {251, 146, 60}, Success = {255, 180, 60}, Text = {255, 245, 245}, Text_Secondary = {200, 160, 175}, Close = {255, 60, 80} },
            Swatches = { Color3.fromRGB(18, 12, 16), Color3.fromRGB(244, 63, 94), Color3.fromRGB(251, 146, 60) }
        },
        ["tokyo"] = {
            Name = "Tokyo Night",
            Colors = { Main = {15, 17, 26}, Secondary = {22, 26, 40}, Accent = {129, 140, 248}, Accent2 = {65, 72, 104}, Success = {52, 211, 153}, Text = {192, 202, 245}, Text_Secondary = {130, 140, 180}, Close = {247, 118, 142} },
            Swatches = { Color3.fromRGB(15, 17, 26), Color3.fromRGB(28, 33, 50), Color3.fromRGB(129, 140, 248) }
        },
        ["light"] = {
            Name = "Minimal Light",
            Colors = { Main = {245, 245, 248}, Secondary = {232, 232, 238}, Accent = {99, 102, 241}, Accent2 = {215, 215, 225}, Success = {16, 185, 129}, Text = {20, 20, 25}, Text_Secondary = {110, 110, 125}, Close = {220, 55, 55} },
            Swatches = { Color3.fromRGB(245, 245, 248), Color3.fromRGB(220, 220, 230), Color3.fromRGB(99, 102, 241) }
        }
    }

    local activeThemeName = (UI and UI.MenuConfig and UI.MenuConfig["SelectedTheme"]) or "dark"
    local themeCards = {}

    local function updateThemeSelection(selectedKey)
        activeThemeName = selectedKey
        if UI and UI.MenuConfig then
            UI.MenuConfig["SelectedTheme"] = selectedKey
        end
        if UI and UI.SaveMenuConfig then
            UI.SaveMenuConfig("SelectedTheme", selectedKey)
        end
        for key, card in pairs(themeCards) do
            local stroke = card:FindFirstChildOfClass("UIStroke")
            local activeBadge = card:FindFirstChild("ActiveBadge")
            local isCur = (key == selectedKey)
            if stroke then
                TweenService:Create(stroke, TweenInfo.new(0.2), {
                    Color = isCur and Color3.fromRGB(99, 102, 241) or Color3.fromRGB(36, 38, 54),
                    Thickness = isCur and 1.5 or 1
                }):Play()
            end
            if activeBadge then
                activeBadge.Visible = isCur
            end
        end
    end

    local themeOrder = {"dark", "midnight", "amethyst", "cyberpunk", "emerald", "sunset", "tokyo", "light"}
    for idx, tKey in ipairs(themeOrder) do
        local tData = builtins[tKey]
        local TCard = Instance.new("TextButton")
        TCard.Name = "Theme_" .. tKey
        TCard.BackgroundColor3 = Color3.fromRGB(20, 21, 32)
        TCard.Text = ""
        TCard.AutoButtonColor = false
        TCard.LayoutOrder = idx
        TCard.Parent = ThemesGrid
        Instance.new("UICorner", TCard).CornerRadius = UDim.new(0, 7)
        local TcCardStroke = Instance.new("UIStroke", TCard)
        TcCardStroke.Color = (tKey == activeThemeName) and Color3.fromRGB(99, 102, 241) or Color3.fromRGB(36, 38, 54)
        TcCardStroke.Thickness = (tKey == activeThemeName) and 1.5 or 1

        local CardPad = Instance.new("UIPadding", TCard)
        CardPad.PaddingLeft = UDim.new(0, 10)
        CardPad.PaddingRight = UDim.new(0, 10)
        CardPad.PaddingTop = UDim.new(0, 8)
        CardPad.PaddingBottom = UDim.new(0, 8)

        -- Swatche kolorów
        local SwatchFrame = Instance.new("Frame")
        SwatchFrame.Size = UDim2.new(1, 0, 0, 14)
        SwatchFrame.BackgroundTransparency = 1
        SwatchFrame.Parent = TCard

        local SwatchLayout = Instance.new("UIListLayout", SwatchFrame)
        SwatchLayout.FillDirection = Enum.FillDirection.Horizontal
        SwatchLayout.Padding = UDim.new(0, 5)

        for _, col in ipairs(tData.Swatches) do
            local dot = Instance.new("Frame")
            dot.Size = UDim2.new(0, 12, 0, 12)
            dot.BackgroundColor3 = col
            dot.BorderSizePixel = 0
            dot.Parent = SwatchFrame
            Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
        end

        local NameLbl = Instance.new("TextLabel")
        NameLbl.Text = tData.Name
        NameLbl.Font = Enum.Font.GothamBold
        NameLbl.TextSize = 11
        NameLbl.TextColor3 = Color3.fromRGB(235, 240, 255)
        NameLbl.TextXAlignment = Enum.TextXAlignment.Left
        NameLbl.Position = UDim2.new(0, 0, 0, 22)
        NameLbl.Size = UDim2.new(1, 0, 0, 16)
        NameLbl.BackgroundTransparency = 1
        NameLbl.TextTruncate = Enum.TextTruncate.AtEnd
        NameLbl.Parent = TCard

        local ActiveBadge = Instance.new("Frame")
        ActiveBadge.Name = "ActiveBadge"
        ActiveBadge.Size = UDim2.new(0, 8, 0, 8)
        ActiveBadge.Position = UDim2.new(1, 0, 0, 2)
        ActiveBadge.AnchorPoint = Vector2.new(1, 0)
        ActiveBadge.BackgroundColor3 = Color3.fromRGB(16, 185, 129)
        ActiveBadge.BorderSizePixel = 0
        ActiveBadge.Visible = (tKey == activeThemeName)
        ActiveBadge.Parent = TCard
        Instance.new("UICorner", ActiveBadge).CornerRadius = UDim.new(1, 0)

        themeCards[tKey] = TCard

        TCard.MouseEnter:Connect(function()
            TweenService:Create(TCard, TweenInfo.new(0.18), { BackgroundColor3 = Color3.fromRGB(26, 28, 42) }):Play()
        end)
        TCard.MouseLeave:Connect(function()
            TweenService:Create(TCard, TweenInfo.new(0.18), { BackgroundColor3 = Color3.fromRGB(20, 21, 32) }):Play()
        end)
        TCard.MouseButton1Click:Connect(function()
            ThemeManager:Apply(tData.Colors)
            updateThemeSelection(tKey)
        end)
    end

    -- // =========================================================================
    -- // 3. AMBIENT LIVE BACKGROUND FX (FALE I GLOW)
    -- // =========================================================================
    local AmbientSection = Instance.new("Frame")
    AmbientSection.Name = "AmbientSection"
    AmbientSection.Size = UDim2.new(1, 0, 0, 0)
    AmbientSection.AutomaticSize = Enum.AutomaticSize.Y
    AmbientSection.BackgroundTransparency = 1
    AmbientSection.LayoutOrder = 3
    AmbientSection.Parent = Page

    local AmbSecLayout = Instance.new("UIListLayout", AmbientSection)
    AmbSecLayout.SortOrder = Enum.SortOrder.LayoutOrder
    AmbSecLayout.Padding = UDim.new(0, 8)

    local AmbHeader = createSectionHeader("LIVE AMBIENT WAVE FX", "activity", "Wybierz gradient fali świetlnej w tle okna")
    AmbHeader.LayoutOrder = 1
    AmbHeader.Parent = AmbientSection

    local AmbientCard = Instance.new("Frame")
    AmbientCard.Name = "AmbientCard"
    AmbientCard.Size = UDim2.new(1, 0, 0, 0)
    AmbientCard.AutomaticSize = Enum.AutomaticSize.Y
    AmbientCard.BackgroundColor3 = Color3.fromRGB(15, 16, 24)
    AmbientCard.BorderSizePixel = 0
    AmbientCard.LayoutOrder = 2
    AmbientCard.Parent = AmbientSection
    Instance.new("UICorner", AmbientCard).CornerRadius = UDim.new(0, 10)
    local AmbStroke = Instance.new("UIStroke", AmbientCard)
    AmbStroke.Color = Color3.fromRGB(34, 36, 52)
    AmbStroke.Thickness = 1.2

    local AmbPad = Instance.new("UIPadding", AmbientCard)
    AmbPad.PaddingLeft = UDim.new(0, 12)
    AmbPad.PaddingRight = UDim.new(0, 12)
    AmbPad.PaddingTop = UDim.new(0, 12)
    AmbPad.PaddingBottom = UDim.new(0, 12)

    local AmbList = Instance.new("UIListLayout", AmbientCard)
    AmbList.SortOrder = Enum.SortOrder.LayoutOrder
    AmbList.Padding = UDim.new(0, 10)

    -- Preset Chips Row
    local ChipsRow = Instance.new("Frame")
    ChipsRow.Name = "ChipsRow"
    ChipsRow.Size = UDim2.new(1, 0, 0, 32)
    ChipsRow.BackgroundTransparency = 1
    ChipsRow.LayoutOrder = 1
    ChipsRow.Parent = AmbientCard

    local ChipsLayout = Instance.new("UIListLayout", ChipsRow)
    ChipsLayout.FillDirection = Enum.FillDirection.Horizontal
    ChipsLayout.Padding = UDim.new(0, 6)

    local wavePresets = {"Aurora", "Cyberpunk", "Cosmic", "Sunset", "Emerald", "None"}
    local currentWave = (UI and UI.MenuConfig and UI.MenuConfig["AnimatedTheme"]) or "Aurora"
    local waveChips = {}

    local function selectWavePreset(preset)
        currentWave = preset
        if UI and UI.SetAnimatedTheme then
            UI:SetAnimatedTheme(preset)
        end
        for p, btn in pairs(waveChips) do
            local isSel = (p == preset)
            TweenService:Create(btn, TweenInfo.new(0.18), {
                BackgroundColor3 = isSel and Color3.fromRGB(99, 102, 241) or Color3.fromRGB(22, 24, 36),
                TextColor3 = isSel and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 155, 175)
            }):Play()
            local strk = btn:FindFirstChildOfClass("UIStroke")
            if strk then
                strk.Color = isSel and Color3.fromRGB(165, 180, 252) or Color3.fromRGB(36, 38, 54)
            end
        end
    end

    for idx, preset in ipairs(wavePresets) do
        local Chip = Instance.new("TextButton")
        Chip.Name = preset
        Chip.Size = UDim2.new(0, 0, 1, 0)
        Chip.AutomaticSize = Enum.AutomaticSize.X
        Chip.BackgroundColor3 = (preset == currentWave) and Color3.fromRGB(99, 102, 241) or Color3.fromRGB(22, 24, 36)
        Chip.Text = "  " .. preset .. "  "
        Chip.Font = Enum.Font.GothamBold
        Chip.TextSize = 11
        Chip.TextColor3 = (preset == currentWave) and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 155, 175)
        Chip.AutoButtonColor = false
        Chip.LayoutOrder = idx
        Chip.Parent = ChipsRow
        Instance.new("UICorner", Chip).CornerRadius = UDim.new(0, 6)
        local CStroke = Instance.new("UIStroke", Chip)
        CStroke.Color = (preset == currentWave) and Color3.fromRGB(165, 180, 252) or Color3.fromRGB(36, 38, 54)
        CStroke.Thickness = 1

        waveChips[preset] = Chip

        Chip.MouseButton1Click:Connect(function()
            selectWavePreset(preset)
        end)
    end

    -- Sliders for intensity and speed
    if SliderElement then
        local savedInt = (UI and UI.MenuConfig and UI.MenuConfig["AnimatedThemeIntensity"]) or 12
        SliderElement({
            Name = "Live Glow Intensity",
            Min = 2,
            Max = 35,
            Default = math.floor(savedInt <= 1 and (savedInt * 100) or savedInt),
            Suffix = "%",
            Flag = "AnimatedThemeIntensity",
            Callback = function(val)
                if UI and UI.SetAnimatedTheme then
                    UI:SetAnimatedTheme(nil, val / 100, nil)
                end
            end
        }, ThemeManager, AmbientCard, UI.MenuConfig, UI.SaveMenuConfig)

        local savedSpeed = (UI and UI.MenuConfig and UI.MenuConfig["AnimatedThemeSpeed"]) or 5
        SliderElement({
            Name = "Wave Animation Speed",
            Min = 1,
            Max = 25,
            Default = math.floor(savedSpeed <= 2.5 and (savedSpeed * 10) or savedSpeed),
            Suffix = "x",
            Callback = function(val)
                if UI and UI.SetAnimatedTheme then
                    UI:SetAnimatedTheme(nil, nil, val / 10)
                end
            end
        }, ThemeManager, AmbientCard, UI.MenuConfig, UI.SaveMenuConfig)
    end

    -- // =========================================================================
    -- // 4. DEFENSE & CLIENT POWER OPTIONS (BENTO GRID TILES)
    -- // =========================================================================
    local PowerSection = Instance.new("Frame")
    PowerSection.Name = "PowerSection"
    PowerSection.Size = UDim2.new(1, 0, 0, 0)
    PowerSection.AutomaticSize = Enum.AutomaticSize.Y
    PowerSection.BackgroundTransparency = 1
    PowerSection.LayoutOrder = 4
    PowerSection.Parent = Page

    local PowerSecLayout = Instance.new("UIListLayout", PowerSection)
    PowerSecLayout.SortOrder = Enum.SortOrder.LayoutOrder
    PowerSecLayout.Padding = UDim.new(0, 8)

    local PwrHeader = createSectionHeader("CLIENT DEFENSE & POWER OPTIONS", "shield", "Zabezpieczenia sesji, bindy oraz moduły pomocnicze")
    PwrHeader.LayoutOrder = 1
    PwrHeader.Parent = PowerSection

    local PowerGrid = Instance.new("Frame")
    PowerGrid.Name = "PowerGrid"
    PowerGrid.Size = UDim2.new(1, 0, 0, 0)
    PowerGrid.AutomaticSize = Enum.AutomaticSize.Y
    PowerGrid.BackgroundTransparency = 1
    PowerGrid.LayoutOrder = 2
    PowerGrid.Parent = PowerSection

    local PgLayout = Instance.new("UIGridLayout", PowerGrid)
    PgLayout.CellPadding = UDim2.new(0, 10, 0, 10)
    PgLayout.CellSize = isMobile and UDim2.new(1, 0, 0, 68) or UDim2.new(0.5, -5, 0, 72)
    PgLayout.SortOrder = Enum.SortOrder.LayoutOrder

    local function makePowerCard(titleText, descText, iconName, defaultVal, callback)
        local Card = Instance.new("Frame")
        Card.BackgroundColor3 = Color3.fromRGB(18, 22, 34)
        Card.BackgroundTransparency = 0.35
        Card.BorderSizePixel = 0
        Card.Parent = PowerGrid
        Instance.new("UICorner", Card).CornerRadius = UDim.new(0, 14)
        local cStroke = Instance.new("UIStroke", Card)
        cStroke.Color = Color3.fromRGB(60, 72, 105)
        cStroke.Thickness = 1.2
        cStroke.Transparency = 0.55

        local cPad = Instance.new("UIPadding", Card)
        cPad.PaddingLeft = UDim.new(0, 12)
        cPad.PaddingRight = UDim.new(0, 12)
        cPad.PaddingTop = UDim.new(0, 10)
        cPad.PaddingBottom = UDim.new(0, 10)

        local IconBox = Instance.new("Frame")
        IconBox.Size = UDim2.new(0, 28, 0, 28)
        IconBox.Position = UDim2.new(0, 0, 0.5, 0)
        IconBox.AnchorPoint = Vector2.new(0, 0.5)
        IconBox.BackgroundColor3 = Color3.fromRGB(28, 33, 50)
        IconBox.BackgroundTransparency = 0.4
        IconBox.BorderSizePixel = 0
        IconBox.Parent = Card
        Instance.new("UICorner", IconBox).CornerRadius = UDim.new(0, 8)
        local ibStroke = Instance.new("UIStroke", IconBox)
        ibStroke.Color = Color3.fromRGB(70, 80, 120)
        ibStroke.Thickness = 1
        ibStroke.Transparency = 0.6

        local IcoImg = Instance.new("ImageLabel")
        IcoImg.Size = UDim2.new(0, 15, 0, 15)
        IcoImg.Position = UDim2.new(0.5, 0, 0.5, 0)
        IcoImg.AnchorPoint = Vector2.new(0.5, 0.5)
        IcoImg.BackgroundTransparency = 1
        IcoImg.ImageColor3 = Color3.fromRGB(140, 160, 250)
        IcoImg.Parent = IconBox
        if Icons and Icons.Apply then Icons:Apply(IcoImg, iconName) end

        local Title = Instance.new("TextLabel")
        Title.Text = titleText
        Title.Font = Enum.Font.GothamBold
        Title.TextSize = 12
        Title.TextColor3 = Color3.fromRGB(255, 255, 255)
        Title.TextXAlignment = Enum.TextXAlignment.Left
        Title.Position = UDim2.new(0, 36, 0, 4)
        Title.Size = UDim2.new(1, -90, 0, 16)
        Title.BackgroundTransparency = 1
        Title.Parent = Card

        local Desc = Instance.new("TextLabel")
        Desc.Text = descText
        Desc.Font = Enum.Font.GothamMedium
        Desc.TextSize = 10
        Desc.TextColor3 = Color3.fromRGB(150, 160, 185)
        Desc.TextXAlignment = Enum.TextXAlignment.Left
        Desc.TextTruncate = Enum.TextTruncate.AtEnd
        Desc.Position = UDim2.new(0, 36, 0, 22)
        Desc.Size = UDim2.new(1, -90, 0, 14)
        Desc.BackgroundTransparency = 1
        Desc.Parent = Card

        -- Pill switch
        local SwitchBtn = Instance.new("TextButton")
        SwitchBtn.Size = UDim2.new(0, 42, 0, 22)
        SwitchBtn.Position = UDim2.new(1, 0, 0.5, 0)
        SwitchBtn.AnchorPoint = Vector2.new(1, 0.5)
        SwitchBtn.BackgroundColor3 = defaultVal and Color3.fromRGB(99, 102, 241) or Color3.fromRGB(28, 33, 50)
        SwitchBtn.BackgroundTransparency = 0.3
        SwitchBtn.Text = ""
        SwitchBtn.AutoButtonColor = false
        SwitchBtn.Parent = Card
        Instance.new("UICorner", SwitchBtn).CornerRadius = UDim.new(1, 0)
        local swStroke = Instance.new("UIStroke", SwitchBtn)
        swStroke.Color = defaultVal and Color3.fromRGB(165, 180, 252) or Color3.fromRGB(60, 72, 105)
        swStroke.Thickness = 1
        swStroke.Transparency = 0.5

        local Dot = Instance.new("Frame")
        Dot.Size = UDim2.new(0, 14, 0, 14)
        Dot.Position = defaultVal and UDim2.new(1, -18, 0.5, 0) or UDim2.new(0, 4, 0.5, 0)
        Dot.AnchorPoint = Vector2.new(0, 0.5)
        Dot.BackgroundColor3 = defaultVal and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(180, 190, 215)
        Dot.BorderSizePixel = 0
        Dot.Parent = SwitchBtn
        Instance.new("UICorner", Dot).CornerRadius = UDim.new(1, 0)

        local currentVal = defaultVal
        SwitchBtn.MouseButton1Click:Connect(function()
            currentVal = not currentVal
            local destPos = currentVal and UDim2.new(1, -18, 0.5, 0) or UDim2.new(0, 4, 0.5, 0)
            local destBg = currentVal and Color3.fromRGB(99, 102, 241) or Color3.fromRGB(28, 33, 50)
            local destStrk = currentVal and Color3.fromRGB(165, 180, 252) or Color3.fromRGB(60, 72, 105)
            local destDot = currentVal and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(180, 190, 215)

            TweenService:Create(Dot, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Position = destPos,
                BackgroundColor3 = destDot
            }):Play()
            TweenService:Create(SwitchBtn, TweenInfo.new(0.2), { BackgroundColor3 = destBg }):Play()
            TweenService:Create(swStroke, TweenInfo.new(0.2), { Color = destStrk }):Play()

            if callback then callback(currentVal) end
        end)

        return Card
    end

    -- Liquid Glass Mode (Apple iPhone iOS 27.2) Toggle
    local liquidGlassDefault = true
    if UI and UI.MenuConfig and UI.MenuConfig["LiquidGlass"] ~= nil then
        liquidGlassDefault = (UI.MenuConfig["LiquidGlass"] == true)
    end
    makePowerCard("iPhone Liquid Glass", "Dynamic Island 2.0, matowe szkło Control Center i przełączniki iOS 27.2", "layers", liquidGlassDefault, function(state)
        if UI and UI.SetLiquidGlass then
            UI:SetLiquidGlass(state)
        end
        if UI and UI.MenuConfig then
            UI.MenuConfig["LiquidGlass"] = state
        end
        if UI and UI.SaveMenuConfig then
            pcall(function() UI.SaveMenuConfig("LiquidGlass", state) end)
        end
    end)

    -- AntiAFK
    local antiAfkConnection = nil
    local function enableAntiAfk()
        local speaker = Players.LocalPlayer
        if not speaker then return end
        pcall(function()
            if typeof(getconnections) == "function" then
                for _, c in pairs(getconnections(speaker.Idled)) do
                    pcall(function() c:Disable(); c:Disconnect() end)
                end
            end
        end)
        if antiAfkConnection then pcall(function() antiAfkConnection:Disconnect() end); antiAfkConnection = nil end
        antiAfkConnection = speaker.Idled:Connect(function()
            pcall(function()
                local vim = Instance.new("VirtualInputManager")
                vim:SendMouseButtonEvent(0, 0, 0, true, game, 0)
                vim:SendMouseButtonEvent(0, 0, 0, false, game, 0)
                vim:Destroy()
            end)
            pcall(function() VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new()) end)
        end)
    end
    local function disableAntiAfk()
        if antiAfkConnection then pcall(function() antiAfkConnection:Disconnect() end); antiAfkConnection = nil end
    end
    enableAntiAfk()

    makePowerCard("AntiAFK Kick Bypass", "Zapobiega rozłączeniu po 20 min bezczynności", "shield", true, function(state)
        if state then enableAntiAfk() else disableAntiAfk() end
        if UI and UI.MenuConfig then UI.MenuConfig["AntiAfk"] = state end
    end)

    -- AntiFling
    local antiFlingConnection = nil
    local function enableAntiFling()
        if antiFlingConnection then antiFlingConnection:Disconnect(); antiFlingConnection = nil end
        antiFlingConnection = RunService.Stepped:Connect(function()
            local lp = Players.LocalPlayer
            if not lp then return end
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= lp and player.Character then
                    for _, v in ipairs(player.Character:GetDescendants()) do
                        if v:IsA("BasePart") and v.CanCollide then v.CanCollide = false end
                    end
                end
            end
            if lp.Character then
                local hrp = lp.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    if hrp.AssemblyLinearVelocity and hrp.AssemblyLinearVelocity.Magnitude > 3500 then
                        hrp.AssemblyLinearVelocity = Vector3.zero
                    end
                    if hrp.AssemblyAngularVelocity and hrp.AssemblyAngularVelocity.Magnitude > 2500 then
                        hrp.AssemblyAngularVelocity = Vector3.zero
                    end
                end
            end
        end)
    end
    local function disableAntiFling()
        if antiFlingConnection then antiFlingConnection:Disconnect(); antiFlingConnection = nil end
    end
    enableAntiFling()

    makePowerCard("AntiFling Defense", "Chroni postać przed wyrzuceniem ze zderzeń", "zap", true, function(state)
        if state then enableAntiFling() else disableAntiFling() end
        if UI and UI.MenuConfig then UI.MenuConfig["AntiFling"] = state end
    end)

    -- Keybinds Overlay
    local isOverlayActive = (UI and UI.MenuConfig and UI.MenuConfig["KeybindsOverlay"] == true) or false
    makePowerCard("Keybinds HUD (Overlay)", "Wyświetla ekranową listę aktywnych bindów", "layout", isOverlayActive, function(state)
        if UI and UI.SetKeybindsOverlayVisible then
            UI:SetKeybindsOverlayVisible(state)
        end
        if UI and UI.MenuConfig then UI.MenuConfig["KeybindsOverlay"] = state end
    end)

    -- Emotes Menu
    local emoteEnabled = (UI and UI.MenuConfig and UI.MenuConfig["EmotesMenu"] == true) or false
    makePowerCard("Roblox Emotes Menu", "Pływający przycisk koła emotek i animacji", "smile", emoteEnabled, function(state)
        local mod = safeLoadSub("emotes/EmoteMenu.lua", baseUrl .. "emotes/EmoteMenu.lua")
        if mod then
            if state and mod.Load then pcall(function() mod:Load() end)
            elseif not state and mod.Unload then pcall(function() mod:Unload() end) end
        end
        if UI and UI.MenuConfig then UI.MenuConfig["EmotesMenu"] = state end
    end)

    -- Karta Menu Keybind Widget
    local KeybindCard = Instance.new("Frame")
    KeybindCard.BackgroundColor3 = Color3.fromRGB(15, 16, 24)
    KeybindCard.BorderSizePixel = 0
    KeybindCard.Parent = PowerGrid
    Instance.new("UICorner", KeybindCard).CornerRadius = UDim.new(0, 8)
    local KcStroke = Instance.new("UIStroke", KeybindCard)
    KcStroke.Color = Color3.fromRGB(34, 36, 52)
    KcStroke.Thickness = 1.2

    local KcPad = Instance.new("UIPadding", KeybindCard)
    KcPad.PaddingLeft = UDim.new(0, 12)
    KcPad.PaddingRight = UDim.new(0, 12)
    KcPad.PaddingTop = UDim.new(0, 10)
    KcPad.PaddingBottom = UDim.new(0, 10)

    local KbIcoBox = Instance.new("Frame")
    KbIcoBox.Size = UDim2.new(0, 28, 0, 28)
    KbIcoBox.Position = UDim2.new(0, 0, 0.5, 0)
    KbIcoBox.AnchorPoint = Vector2.new(0, 0.5)
    KbIcoBox.BackgroundColor3 = Color3.fromRGB(22, 24, 36)
    KbIcoBox.BorderSizePixel = 0
    KbIcoBox.Parent = KeybindCard
    Instance.new("UICorner", KbIcoBox).CornerRadius = UDim.new(0, 6)

    local KbIcoImg = Instance.new("ImageLabel")
    KbIcoImg.Size = UDim2.new(0, 15, 0, 15)
    KbIcoImg.Position = UDim2.new(0.5, 0, 0.5, 0)
    KbIcoImg.AnchorPoint = Vector2.new(0.5, 0.5)
    KbIcoImg.BackgroundTransparency = 1
    KbIcoImg.ImageColor3 = Color3.fromRGB(129, 140, 248)
    KbIcoImg.Parent = KbIcoBox
    if Icons and Icons.Apply then Icons:Apply(KbIcoImg, "command") end

    local KbTitle = Instance.new("TextLabel")
    KbTitle.Text = "Menu Toggle Keybind"
    KbTitle.Font = Enum.Font.GothamBold
    KbTitle.TextSize = 12
    KbTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    KbTitle.TextXAlignment = Enum.TextXAlignment.Left
    KbTitle.Position = UDim2.new(0, 36, 0, 4)
    KbTitle.Size = UDim2.new(1, -95, 0, 16)
    KbTitle.BackgroundTransparency = 1
    KbTitle.Parent = KeybindCard

    local KbDesc = Instance.new("TextLabel")
    KbDesc.Text = "Kliknij badge, aby przypisać nowy klawisz"
    KbDesc.Font = Enum.Font.GothamMedium
    KbDesc.TextSize = 10
    KbDesc.TextColor3 = Color3.fromRGB(130, 135, 155)
    KbDesc.TextXAlignment = Enum.TextXAlignment.Left
    KbDesc.Position = UDim2.new(0, 36, 0, 22)
    KbDesc.Size = UDim2.new(1, -95, 0, 14)
    KbDesc.BackgroundTransparency = 1
    KbDesc.Parent = KeybindCard

    local KbBadge = Instance.new("TextButton")
    KbBadge.Size = UDim2.new(0, 44, 0, 24)
    KbBadge.Position = UDim2.new(1, 0, 0.5, 0)
    KbBadge.AnchorPoint = Vector2.new(1, 0.5)
    KbBadge.BackgroundColor3 = Color3.fromRGB(26, 28, 42)
    local curK = (UI and UI.CurrentMenuKeyName) or "K"
    KbBadge.Text = "[" .. tostring(curK) .. "]"
    KbBadge.Font = Enum.Font.GothamBold
    KbBadge.TextSize = 11
    KbBadge.TextColor3 = Color3.fromRGB(165, 180, 252)
    KbBadge.AutoButtonColor = false
    KbBadge.Parent = KeybindCard
    Instance.new("UICorner", KbBadge).CornerRadius = UDim.new(0, 6)
    local KbbStroke = Instance.new("UIStroke", KbBadge)
    KbbStroke.Color = Color3.fromRGB(48, 52, 75)
    KbbStroke.Thickness = 1

    local isBindingKey = false
    KbBadge.MouseButton1Click:Connect(function()
        if isBindingKey then return end
        isBindingKey = true
        KbBadge.Text = "[...]"
        KbBadge.TextColor3 = Color3.fromRGB(255, 255, 255)
        KbbStroke.Color = Color3.fromRGB(99, 102, 241)

        local conn
        conn = UserInputService.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.Keyboard then
                conn:Disconnect()
                isBindingKey = false
                local nk = inp.KeyCode
                if nk == Enum.KeyCode.Backspace or nk == Enum.KeyCode.Delete then
                    nk = Enum.KeyCode.K
                end
                KbBadge.Text = "[" .. nk.Name .. "]"
                KbBadge.TextColor3 = Color3.fromRGB(165, 180, 252)
                KbbStroke.Color = Color3.fromRGB(48, 52, 75)
                if UI and UI.SetMenuKeybind then UI:SetMenuKeybind(nk) end
            end
        end)
    end)

    -- // =========================================================================
    -- // 5. CONFIG CLOUD & LOCAL VAULT
    -- // =========================================================================
    local ConfigsSection = Instance.new("Frame")
    ConfigsSection.Name = "ConfigsSection"
    ConfigsSection.Size = UDim2.new(1, 0, 0, 0)
    ConfigsSection.AutomaticSize = Enum.AutomaticSize.Y
    ConfigsSection.BackgroundTransparency = 1
    ConfigsSection.LayoutOrder = 5
    ConfigsSection.Parent = Page

    local CfgSecLayout = Instance.new("UIListLayout", ConfigsSection)
    CfgSecLayout.SortOrder = Enum.SortOrder.LayoutOrder
    CfgSecLayout.Padding = UDim.new(0, 8)

    local CfgHeader = createSectionHeader("CONFIG CLOUD & LOCAL VAULT", "folder", "Zarządzaj profilami ustawień lokalnie na PC oraz z chmury")
    CfgHeader.LayoutOrder = 1
    CfgHeader.Parent = ConfigsSection

    local ConfigsCard = Instance.new("Frame")
    ConfigsCard.Name = "ConfigsCard"
    ConfigsCard.Size = UDim2.new(1, 0, 0, 0)
    ConfigsCard.AutomaticSize = Enum.AutomaticSize.Y
    ConfigsCard.BackgroundColor3 = Color3.fromRGB(15, 16, 24)
    ConfigsCard.BorderSizePixel = 0
    ConfigsCard.LayoutOrder = 2
    ConfigsCard.Parent = ConfigsSection
    Instance.new("UICorner", ConfigsCard).CornerRadius = UDim.new(0, 10)
    local CcStroke = Instance.new("UIStroke", ConfigsCard)
    CcStroke.Color = Color3.fromRGB(34, 36, 52)
    CcStroke.Thickness = 1.2

    local CcPadding = Instance.new("UIPadding", ConfigsCard)
    CcPadding.PaddingLeft = UDim.new(0, 12)
    CcPadding.PaddingRight = UDim.new(0, 12)
    CcPadding.PaddingTop = UDim.new(0, 12)
    CcPadding.PaddingBottom = UDim.new(0, 12)

    local CcList = Instance.new("UIListLayout", ConfigsCard)
    CcList.SortOrder = Enum.SortOrder.LayoutOrder
    CcList.Padding = UDim.new(0, 10)

    -- Wiersz 1: Szukajka + Filtry (All / Local / Public)
    local CfgTopBar = Instance.new("Frame")
    CfgTopBar.Name = "CfgTopBar"
    CfgTopBar.Size = UDim2.new(1, 0, 0, 32)
    CfgTopBar.BackgroundTransparency = 1
    CfgTopBar.LayoutOrder = 1
    CfgTopBar.Parent = ConfigsCard

    local SearchBoxFrame = Instance.new("Frame")
    SearchBoxFrame.Size = UDim2.new(1, -170, 1, 0)
    SearchBoxFrame.BackgroundColor3 = Color3.fromRGB(20, 21, 32)
    SearchBoxFrame.Parent = CfgTopBar
    Instance.new("UICorner", SearchBoxFrame).CornerRadius = UDim.new(0, 6)
    local SbfStroke = Instance.new("UIStroke", SearchBoxFrame)
    SbfStroke.Color = Color3.fromRGB(36, 38, 54)
    SbfStroke.Thickness = 1

    local SIco = Instance.new("ImageLabel")
    SIco.Size = UDim2.new(0, 14, 0, 14)
    SIco.Position = UDim2.new(0, 8, 0.5, 0)
    SIco.AnchorPoint = Vector2.new(0, 0.5)
    SIco.BackgroundTransparency = 1
    SIco.ImageColor3 = Color3.fromRGB(120, 125, 145)
    SIco.Parent = SearchBoxFrame
    if Icons and Icons.Apply then Icons:Apply(SIco, "search") end

    local SearchInput = Instance.new("TextBox")
    SearchInput.Size = UDim2.new(1, -30, 1, 0)
    SearchInput.Position = UDim2.new(0, 26, 0, 0)
    SearchInput.BackgroundTransparency = 1
    SearchInput.PlaceholderText = "Szukaj profilu config..."
    SearchInput.PlaceholderColor3 = Color3.fromRGB(90, 95, 115)
    SearchInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    SearchInput.Font = Enum.Font.GothamMedium
    SearchInput.TextSize = 11
    SearchInput.TextXAlignment = Enum.TextXAlignment.Left
    SearchInput.ClearTextOnFocus = false
    SearchInput.Parent = SearchBoxFrame

    -- Filtry
    local FilterDock = Instance.new("Frame")
    FilterDock.Size = UDim2.new(0, 160, 1, 0)
    FilterDock.Position = UDim2.new(1, 0, 0, 0)
    FilterDock.AnchorPoint = Vector2.new(1, 0)
    FilterDock.BackgroundTransparency = 1
    FilterDock.Parent = CfgTopBar

    local FilterLay = Instance.new("UIListLayout", FilterDock)
    FilterLay.FillDirection = Enum.FillDirection.Horizontal
    FilterLay.Padding = UDim.new(0, 5)

    local activeFilter = "all"
    local filterBtns = {}

    local function makeFilterBtn(key, labelText, order)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 50, 1, 0)
        btn.BackgroundColor3 = (key == activeFilter) and Color3.fromRGB(99, 102, 241) or Color3.fromRGB(20, 21, 32)
        btn.Text = labelText
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 10
        btn.TextColor3 = (key == activeFilter) and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(140, 145, 165)
        btn.AutoButtonColor = false
        btn.LayoutOrder = order
        btn.Parent = FilterDock
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
        local bs = Instance.new("UIStroke", btn)
        bs.Color = (key == activeFilter) and Color3.fromRGB(165, 180, 252) or Color3.fromRGB(36, 38, 54)
        bs.Thickness = 1
        filterBtns[key] = btn
        return btn
    end

    makeFilterBtn("all", "All", 1)
    makeFilterBtn("local", "Local", 2)
    makeFilterBtn("public", "Cloud", 3)

    -- Wiersz 2: Zapis nowego profilu
    local SaveRow = Instance.new("Frame")
    SaveRow.Name = "SaveRow"
    SaveRow.Size = UDim2.new(1, 0, 0, 32)
    SaveRow.BackgroundTransparency = 1
    SaveRow.LayoutOrder = 2
    SaveRow.Parent = ConfigsCard

    local NameBox = Instance.new("Frame")
    NameBox.Size = UDim2.new(1, -115, 1, 0)
    NameBox.BackgroundColor3 = Color3.fromRGB(20, 21, 32)
    NameBox.Parent = SaveRow
    Instance.new("UICorner", NameBox).CornerRadius = UDim.new(0, 6)
    local NbStroke = Instance.new("UIStroke", NameBox)
    NbStroke.Color = Color3.fromRGB(36, 38, 54)
    NbStroke.Thickness = 1

    local NameInput = Instance.new("TextBox")
    NameInput.Size = UDim2.new(1, -16, 1, 0)
    NameInput.Position = UDim2.new(0, 8, 0, 0)
    NameInput.BackgroundTransparency = 1
    NameInput.PlaceholderText = "Nazwa nowego configu..."
    NameInput.PlaceholderColor3 = Color3.fromRGB(90, 95, 115)
    NameInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    NameInput.Font = Enum.Font.GothamMedium
    NameInput.TextSize = 11
    NameInput.TextXAlignment = Enum.TextXAlignment.Left
    NameInput.ClearTextOnFocus = false
    NameInput.Parent = NameBox

    local SaveBtn = Instance.new("TextButton")
    SaveBtn.Size = UDim2.new(0, 105, 1, 0)
    SaveBtn.Position = UDim2.new(1, 0, 0, 0)
    SaveBtn.AnchorPoint = Vector2.new(1, 0)
    SaveBtn.BackgroundColor3 = Color3.fromRGB(99, 102, 241)
    SaveBtn.Text = "+ Zapisz Config"
    SaveBtn.Font = Enum.Font.GothamBold
    SaveBtn.TextSize = 11
    SaveBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    SaveBtn.AutoButtonColor = false
    SaveBtn.Parent = SaveRow
    Instance.new("UICorner", SaveBtn).CornerRadius = UDim.new(0, 6)

    -- Kontener listy configów
    local CfgListContainer = Instance.new("Frame")
    CfgListContainer.Name = "CfgListContainer"
    CfgListContainer.Size = UDim2.new(1, 0, 0, 0)
    CfgListContainer.AutomaticSize = Enum.AutomaticSize.Y
    CfgListContainer.BackgroundTransparency = 1
    CfgListContainer.LayoutOrder = 3
    CfgListContainer.Parent = ConfigsCard

    local ClLayout = Instance.new("UIListLayout", CfgListContainer)
    ClLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ClLayout.Padding = UDim.new(0, 6)

    local function applyConfigData(data)
        if type(data) ~= "table" then return false end
        if UI.ApplyConfig then
            UI:ApplyConfig(data)
        else
            for k, v in pairs(data) do
                UI.MenuConfig[k] = v
                if UI.SaveMenuConfig then pcall(function() UI.SaveMenuConfig(k, v) end) end
                if UI.Flags and UI.Flags[k] and UI.Flags[k].Set then
                    pcall(function() UI.Flags[k]:Set(v) end)
                end
            end
        end
        return true
    end

    local function RenderConfigs()
        for _, c in ipairs(CfgListContainer:GetChildren()) do
            if c:IsA("Frame") or c:IsA("TextLabel") then c:Destroy() end
        end

        for fKey, btn in pairs(filterBtns) do
            local isSel = (fKey == activeFilter)
            btn.BackgroundColor3 = isSel and Color3.fromRGB(99, 102, 241) or Color3.fromRGB(20, 21, 32)
            btn.TextColor3 = isSel and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(140, 145, 165)
            local st = btn:FindFirstChildOfClass("UIStroke")
            if st then st.Color = isSel and Color3.fromRGB(165, 180, 252) or Color3.fromRGB(36, 38, 54) end
        end

        local query = SearchInput.Text:lower():gsub("^%s+", ""):gsub("%s+$", "")
        local items = {}

        -- 1. Scan Public configs
        local publicNames = {}
        if typeof(readfile) == "function" then
            local pFolders = {
                "MenuTest/src/configs/" .. GameId,
                "src/configs/" .. GameId
            }
            for _, pFolder in ipairs(pFolders) do
                if typeof(isfolder) == "function" and isfolder(pFolder) and typeof(listfiles) == "function" then
                    for _, file in ipairs(listfiles(pFolder)) do
                        if file:sub(-5) == ".json" then
                            local n = file:match("([^/\\]+)%.json$")
                            if n and not table.find(publicNames, n) then
                                table.insert(publicNames, n)
                            end
                        end
                    end
                end
            end
        end

        if activeFilter == "all" or activeFilter == "public" then
            for _, pName in ipairs(publicNames) do
                if query == "" or pName:lower():find(query, 1, true) then
                    table.insert(items, {
                        Name = pName,
                        Type = "public",
                        Load = function()
                            if typeof(readfile) == "function" then
                                local cands = {
                                    "MenuTest/src/configs/" .. GameId .. "/" .. pName .. ".json",
                                    "src/configs/" .. GameId .. "/" .. pName .. ".json",
                                    "configs/" .. GameId .. "/" .. pName .. ".json"
                                }
                                for _, c in ipairs(cands) do
                                    if typeof(isfile) == "function" and isfile(c) then
                                        local s, content = pcall(readfile, c)
                                        if s and content and #content > 0 then
                                            local decOk, decData = pcall(function() return HttpService:JSONDecode(content) end)
                                            if decOk and type(decData) == "table" then return decData end
                                        end
                                    end
                                end
                            end
                            local url = baseUrl .. "configs/" .. GameId .. "/" .. pName .. ".json"
                            local ok, res = pcall(function() return game:HttpGet(url) end)
                            if ok and res and #res > 0 then
                                local decOk, decData = pcall(function() return HttpService:JSONDecode(res) end)
                                if decOk and type(decData) == "table" then return decData end
                            end
                            return nil
                        end
                    })
                end
            end
        end

        -- 2. Scan Local configs na dysku
        local candidateFolders = {
            mainFolder .. "/configs/" .. GameId,
            mainFolder .. "/configs"
        }
        local scannedFiles = {}

        for _, lFolder in ipairs(candidateFolders) do
            if typeof(isfolder) == "function" and isfolder(lFolder) and typeof(listfiles) == "function" then
                for _, file in ipairs(listfiles(lFolder)) do
                    if file:sub(-5) == ".json" then
                        local lName = file:match("([^/\\]+)%.json$")
                        if lName and lName ~= "settings" and not scannedFiles[lName] then
                            scannedFiles[lName] = true
                            if activeFilter == "all" or activeFilter == "local" then
                                if query == "" or lName:lower():find(query, 1, true) then
                                    table.insert(items, {
                                        Name = lName,
                                        Type = "local",
                                        Path = file,
                                        Load = function()
                                            if typeof(readfile) == "function" and isfile(file) then
                                                local s, content = pcall(readfile, file)
                                                if s and content and #content > 0 then
                                                    local decOk, decData = pcall(function() return HttpService:JSONDecode(content) end)
                                                    if decOk and type(decData) == "table" then return decData end
                                                end
                                            end
                                            return nil
                                        end,
                                        Delete = function()
                                            if typeof(delfile) == "function" then pcall(delfile, file) end
                                        end
                                    })
                                end
                            end
                        end
                    end
                end
            end
        end

        if #items == 0 then
            local emptyLabel = Instance.new("TextLabel")
            emptyLabel.Size = UDim2.new(1, 0, 0, 40)
            emptyLabel.BackgroundTransparency = 1
            emptyLabel.Font = Enum.Font.GothamMedium
            emptyLabel.TextSize = 11
            emptyLabel.TextColor3 = Color3.fromRGB(130, 135, 155)
            emptyLabel.Text = (query ~= "") and ("Brak konfiguracji pasujących do: '" .. query .. "'") or "Brak zapisanych profili. Wpisz nazwę powyżej i kliknij '+ Zapisz Config'."
            emptyLabel.Parent = CfgListContainer
            return
        end

        for idx, item in ipairs(items) do
            local Card = Instance.new("Frame")
            Card.Name = item.Name
            Card.Size = UDim2.new(1, 0, 0, 38)
            Card.BackgroundColor3 = Color3.fromRGB(20, 21, 32)
            Card.LayoutOrder = idx
            Card.Parent = CfgListContainer
            Instance.new("UICorner", Card).CornerRadius = UDim.new(0, 6)
            local cStrk = Instance.new("UIStroke", Card)
            cStrk.Color = Color3.fromRGB(36, 38, 54)
            cStrk.Thickness = 1

            local CIco = Instance.new("ImageLabel")
            CIco.Size = UDim2.new(0, 15, 0, 15)
            CIco.Position = UDim2.new(0, 10, 0.5, 0)
            CIco.AnchorPoint = Vector2.new(0, 0.5)
            CIco.BackgroundTransparency = 1
            CIco.ImageColor3 = (item.Type == "public") and Color3.fromRGB(56, 189, 248) or Color3.fromRGB(129, 140, 248)
            CIco.Parent = Card
            if Icons and Icons.Apply then Icons:Apply(CIco, item.Type == "public" and "cloud" or "hard-drive") end

            local isLocal = (item.Type == "local")

            local NameLbl = Instance.new("TextLabel")
            NameLbl.Size = UDim2.new(1, isLocal and -240 or -150, 1, 0)
            NameLbl.Position = UDim2.new(0, 32, 0, 0)
            NameLbl.BackgroundTransparency = 1
            NameLbl.Font = Enum.Font.GothamBold
            NameLbl.TextSize = 12
            NameLbl.TextColor3 = Color3.fromRGB(240, 245, 255)
            NameLbl.TextXAlignment = Enum.TextXAlignment.Left
            NameLbl.TextTruncate = Enum.TextTruncate.AtEnd
            NameLbl.Text = item.Name
            NameLbl.Parent = Card

            -- Badge typu
            local Badge = Instance.new("Frame")
            Badge.Size = UDim2.new(0, 48, 0, 18)
            Badge.Position = UDim2.new(1, isLocal and -148 or -62, 0.5, 0)
            Badge.AnchorPoint = Vector2.new(1, 0.5)
            Badge.BackgroundColor3 = (item.Type == "public") and Color3.fromRGB(15, 30, 50) or Color3.fromRGB(15, 40, 25)
            Badge.Parent = Card
            Instance.new("UICorner", Badge).CornerRadius = UDim.new(0, 4)

            local Blbl = Instance.new("TextLabel")
            Blbl.Size = UDim2.new(1, 0, 1, 0)
            Blbl.BackgroundTransparency = 1
            Blbl.Font = Enum.Font.GothamBold
            Blbl.TextSize = 9
            Blbl.Text = (item.Type == "public") and "CLOUD" or "LOCAL"
            Blbl.TextColor3 = (item.Type == "public") and Color3.fromRGB(56, 189, 248) or Color3.fromRGB(52, 211, 153)
            Blbl.Parent = Badge

            if isLocal then
                local SaveItemBtn = Instance.new("TextButton")
                SaveItemBtn.Size = UDim2.new(0, 48, 0, 24)
                SaveItemBtn.Position = UDim2.new(1, -94, 0.5, 0)
                SaveItemBtn.AnchorPoint = Vector2.new(1, 0.5)
                SaveItemBtn.Text = "Save"
                SaveItemBtn.Font = Enum.Font.GothamBold
                SaveItemBtn.TextSize = 10
                SaveItemBtn.BackgroundColor3 = Color3.fromRGB(30, 32, 48)
                SaveItemBtn.TextColor3 = Color3.fromRGB(220, 225, 245)
                SaveItemBtn.AutoButtonColor = false
                SaveItemBtn.Parent = Card
                Instance.new("UICorner", SaveItemBtn).CornerRadius = UDim.new(0, 5)

                SaveItemBtn.MouseButton1Click:Connect(function()
                    local enc = HttpService:JSONEncode(UI.MenuConfig or {})
                    if typeof(writefile) == "function" and item.Path then
                        pcall(writefile, item.Path, enc)
                    end
                    SaveItemBtn.Text = "Saved!"
                    task.delay(1.2, function()
                        if SaveItemBtn and SaveItemBtn.Parent then SaveItemBtn.Text = "Save" end
                    end)
                end)
            end

            local LoadItemBtn = Instance.new("TextButton")
            LoadItemBtn.Size = UDim2.new(0, 48, 0, 24)
            LoadItemBtn.Position = UDim2.new(1, isLocal and -40 or -6, 0.5, 0)
            LoadItemBtn.AnchorPoint = Vector2.new(1, 0.5)
            LoadItemBtn.Text = "Load"
            LoadItemBtn.Font = Enum.Font.GothamBold
            LoadItemBtn.TextSize = 10
            LoadItemBtn.BackgroundColor3 = Color3.fromRGB(99, 102, 241)
            LoadItemBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            LoadItemBtn.AutoButtonColor = false
            LoadItemBtn.Parent = Card
            Instance.new("UICorner", LoadItemBtn).CornerRadius = UDim.new(0, 5)

            LoadItemBtn.MouseButton1Click:Connect(function()
                local d = item.Load()
                if d then
                    applyConfigData(d)
                    LoadItemBtn.Text = "Loaded!"
                    LoadItemBtn.BackgroundColor3 = Color3.fromRGB(16, 185, 129)
                    task.delay(1.2, function()
                        if LoadItemBtn and LoadItemBtn.Parent then
                            LoadItemBtn.Text = "Load"
                            LoadItemBtn.BackgroundColor3 = Color3.fromRGB(99, 102, 241)
                        end
                    end)
                end
            end)

            if isLocal and item.Delete then
                local DelBtn = Instance.new("TextButton")
                DelBtn.Size = UDim2.new(0, 26, 0, 24)
                DelBtn.Position = UDim2.new(1, -6, 0.5, 0)
                DelBtn.AnchorPoint = Vector2.new(1, 0.5)
                DelBtn.Text = ""
                DelBtn.BackgroundColor3 = Color3.fromRGB(225, 29, 72)
                DelBtn.AutoButtonColor = false
                DelBtn.Parent = Card
                Instance.new("UICorner", DelBtn).CornerRadius = UDim.new(0, 5)

                local DelIco = Instance.new("ImageLabel")
                DelIco.Size = UDim2.new(0, 12, 0, 12)
                DelIco.Position = UDim2.new(0.5, 0, 0.5, 0)
                DelIco.AnchorPoint = Vector2.new(0.5, 0.5)
                DelIco.BackgroundTransparency = 1
                DelIco.ImageColor3 = Color3.fromRGB(255, 255, 255)
                DelIco.Parent = DelBtn
                if Icons and Icons.Apply then Icons:Apply(DelIco, "trash-2") end

                DelBtn.MouseButton1Click:Connect(function()
                    item.Delete()
                    RenderConfigs()
                end)
            end
        end
    end

    for fKey, btn in pairs(filterBtns) do
        btn.MouseButton1Click:Connect(function()
            activeFilter = fKey
            RenderConfigs()
        end)
    end

    SearchInput:GetPropertyChangedSignal("Text"):Connect(function()
        RenderConfigs()
    end)

    SaveBtn.MouseButton1Click:Connect(function()
        local rawText = NameInput.Text:gsub("^%s+", ""):gsub("%s+$", "")
        if #rawText == 0 then
            NameInput.PlaceholderText = "Wpisz nazwę najpierw!"
            task.delay(1.5, function()
                if NameInput and NameInput.Parent then NameInput.PlaceholderText = "Nazwa nowego configu..." end
            end)
            return
        end

        local safeName = rawText:gsub("[^%w_%-%s]", ""):sub(1, 24)
        if #safeName == 0 then safeName = "Config" end

        local localConfigsFolder = mainFolder .. "/configs/" .. GameId
        if typeof(isfolder) == "function" and not isfolder(localConfigsFolder) and typeof(makefolder) == "function" then
            pcall(function()
                if not isfolder(mainFolder .. "/configs") then makefolder(mainFolder .. "/configs") end
                makefolder(localConfigsFolder)
            end)
        end

        local filePath = localConfigsFolder .. "/" .. safeName .. ".json"
        local encoded = HttpService:JSONEncode(UI.MenuConfig or {})
        if typeof(writefile) == "function" then
            writefile(filePath, encoded)
        end

        NameInput.Text = ""
        SaveBtn.Text = "Zapisano!"
        task.delay(1.2, function()
            if SaveBtn and SaveBtn.Parent then SaveBtn.Text = "+ Zapisz Config" end
        end)
        RenderConfigs()
    end)

    RenderConfigs()
end

return Settings