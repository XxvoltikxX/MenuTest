-- // ==========================================================================
-- // MENUTEST CYBER-SETTINGS HUB (APPLE iOS 27.2 BENTO SYSTEM)
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

    -- Rejestrujemy stronę SettingsPage bezpośrednio w kontenerze stron (otwierana przez awatar/zębatkę w docku)
    local Page = Instance.new("ScrollingFrame")
    Page.Name = "SettingsPage"
    Page.Size = UDim2.new(1, 0, 1, 0)
    Page.BackgroundTransparency = 1
    Page.BorderSizePixel = 0
    Page.Visible = false
    Page.Active = true
    Page.Selectable = false
    Page.CanvasSize = UDim2.new(0, 0, 0, 0)
    Page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Page.ScrollingDirection = Enum.ScrollingDirection.Y
    Page.ScrollBarThickness = isMobile and 3 or 5
    Page.ScrollBarImageTransparency = 0
    Page.VerticalScrollBarInset = Enum.ScrollBarInset.None
    pcall(function() Page.ElasticBehavior = Enum.ElasticBehavior.Always end)
    Page.Parent = UI.PagesContainer
    table.insert(UI.Pages, Page)
    UI.SettingsPage = Page

    local ThemeManager = UI.ThemeManager
    if ThemeManager and ThemeManager.Register then
        ThemeManager:Register(Page, "ScrollBarImageColor3", "Accent")
    end

    local PageLayout = Page:FindFirstChildOfClass("UIListLayout") or Instance.new("UIListLayout", Page)
    PageLayout.SortOrder = Enum.SortOrder.LayoutOrder
    PageLayout.Padding = UDim.new(0, 16)

    -- Przestrzeń pod dockiem górnym (72px w Window.lua + 18px tutaj = 90px całkowitej przestrzeni)
    local PagePadding = Page:FindFirstChildOfClass("UIPadding") or Instance.new("UIPadding", Page)
    PagePadding.PaddingTop = UDim.new(0, 18)
    PagePadding.PaddingRight = UDim.new(0, 18)
    PagePadding.PaddingLeft = UDim.new(0, 18)
    PagePadding.PaddingBottom = UDim.new(0, 36)

    local isMobile = (UI and UI.IsMobile) or (UserInputService.TouchEnabled and not UserInputService.MouseEnabled)

    -- Pomocnicza funkcja tworzenia standardowej karty Bento (Apple iOS Glass Card)
    local function createBentoCard(name, layoutOrder)
        local Card = Instance.new("Frame")
        Card.Name = name
        Card.Size = UDim2.new(1, 0, 0, 0)
        Card.AutomaticSize = Enum.AutomaticSize.Y
        Card.BackgroundColor3 = Color3.fromRGB(16, 20, 30)
        Card.BackgroundTransparency = 0.35
        Card.BorderSizePixel = 0
        Card.LayoutOrder = layoutOrder or 1
        Card.Parent = Page

        Instance.new("UICorner", Card).CornerRadius = UDim.new(0, 16)

        local Stroke = Instance.new("UIStroke", Card)
        Stroke.Color = Color3.fromRGB(45, 52, 75)
        Stroke.Thickness = 1
        Stroke.Transparency = 0.60
        Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

        local Pad = Instance.new("UIPadding", Card)
        Pad.PaddingLeft = UDim.new(0, 14)
        Pad.PaddingRight = UDim.new(0, 14)
        Pad.PaddingTop = UDim.new(0, 14)
        Pad.PaddingBottom = UDim.new(0, 14)

        local Lay = Instance.new("UIListLayout", Card)
        Lay.SortOrder = Enum.SortOrder.LayoutOrder
        Lay.Padding = UDim.new(0, 12)

        return Card, Lay
    end

    -- Pomocnicza funkcja nagłówka karty Bento
    local function createCardHeader(parentCard, titleText, iconName, subtext, order)
        local Header = Instance.new("Frame")
        Header.Name = "Header"
        Header.Size = UDim2.new(1, 0, 0, 28)
        Header.BackgroundTransparency = 1
        Header.LayoutOrder = order or 1
        Header.Parent = parentCard

        local HLayout = Instance.new("UIListLayout", Header)
        HLayout.FillDirection = Enum.FillDirection.Horizontal
        HLayout.VerticalAlignment = Enum.VerticalAlignment.Center
        HLayout.Padding = UDim.new(0, 8)

        local IconImg = Instance.new("ImageLabel")
        IconImg.Size = UDim2.new(0, 16, 0, 16)
        IconImg.BackgroundTransparency = 1
        IconImg.ImageColor3 = Color3.fromRGB(129, 140, 248)
        IconImg.Parent = Header
        if Icons and Icons.Apply then Icons:Apply(IconImg, iconName) end

        local TitleLbl = Instance.new("TextLabel")
        TitleLbl.Text = titleText
        TitleLbl.Font = Enum.Font.GothamBold
        TitleLbl.TextSize = 12
        TitleLbl.TextColor3 = Color3.fromRGB(240, 245, 255)
        TitleLbl.Size = UDim2.new(0, 0, 1, 0)
        TitleLbl.AutomaticSize = Enum.AutomaticSize.X
        TitleLbl.BackgroundTransparency = 1
        TitleLbl.Parent = Header

        if subtext and #subtext > 0 then
            local Dot = Instance.new("Frame")
            Dot.Size = UDim2.new(0, 3, 0, 3)
            Dot.BackgroundColor3 = Color3.fromRGB(80, 85, 110)
            Dot.BorderSizePixel = 0
            Dot.Parent = Header
            Instance.new("UICorner", Dot).CornerRadius = UDim.new(1, 0)

            local SubLbl = Instance.new("TextLabel")
            SubLbl.Text = subtext
            SubLbl.Font = Enum.Font.GothamMedium
            SubLbl.TextSize = 10
            SubLbl.TextColor3 = Color3.fromRGB(130, 138, 165)
            SubLbl.Size = UDim2.new(0, 0, 1, 0)
            SubLbl.AutomaticSize = Enum.AutomaticSize.X
            SubLbl.BackgroundTransparency = 1
            SubLbl.Parent = Header
        end

        return Header
    end

    -- =========================================================================
    -- BENTO 1: EFEKTY WIZUALNE I LOGO CLIENTA (FALE ŚWIETLNE ORAZ ZNAK WODNY)
    -- =========================================================================
    local VisualCard, _ = createBentoCard("VisualCard", 1)

    createCardHeader(VisualCard, "EFEKTY WIZUALNE I LOGO CLIENTA", "sparkles", "Dopasuj animowane fale świetlne oraz znak wodny logo w tle menu", 1)

    -- -------------------------------------------------------------------------
    -- SEKCJA 1: FALE ŚWIETLNE (AMBIENT WAVE FX)
    -- -------------------------------------------------------------------------
    local WaveSection = Instance.new("Frame")
    WaveSection.Name = "WaveSection"
    WaveSection.Size = UDim2.new(1, 0, 0, 0)
    WaveSection.AutomaticSize = Enum.AutomaticSize.Y
    WaveSection.BackgroundTransparency = 1
    WaveSection.LayoutOrder = 2
    WaveSection.Parent = VisualCard

    local WsLayout = Instance.new("UIListLayout", WaveSection)
    WsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    WsLayout.Padding = UDim.new(0, 10)

    -- 1A. Presety kolorystyczne fal świetlnych
    local WavePresetsContainer = Instance.new("Frame")
    WavePresetsContainer.Name = "WavePresetsContainer"
    WavePresetsContainer.Size = UDim2.new(1, 0, 0, 0)
    WavePresetsContainer.AutomaticSize = Enum.AutomaticSize.Y
    WavePresetsContainer.BackgroundTransparency = 1
    WavePresetsContainer.LayoutOrder = 1
    WavePresetsContainer.Parent = WaveSection

    local WpcLayout = Instance.new("UIListLayout", WavePresetsContainer)
    WpcLayout.SortOrder = Enum.SortOrder.LayoutOrder
    WpcLayout.Padding = UDim.new(0, 6)

    local WpcTitle = Instance.new("TextLabel")
    WpcTitle.Text = "Preset kolorystyczny fali:"
    WpcTitle.Font = Enum.Font.GothamBold
    WpcTitle.TextSize = 11
    WpcTitle.TextColor3 = Color3.fromRGB(180, 190, 215)
    WpcTitle.TextXAlignment = Enum.TextXAlignment.Left
    WpcTitle.Size = UDim2.new(1, 0, 0, 16)
    WpcTitle.BackgroundTransparency = 1
    WpcTitle.LayoutOrder = 1
    WpcTitle.Parent = WavePresetsContainer

    local WaveChipsGrid = Instance.new("Frame")
    WaveChipsGrid.Name = "WaveChipsGrid"
    WaveChipsGrid.Size = UDim2.new(1, 0, 0, 0)
    WaveChipsGrid.AutomaticSize = Enum.AutomaticSize.Y
    WaveChipsGrid.BackgroundTransparency = 1
    WaveChipsGrid.LayoutOrder = 2
    WaveChipsGrid.Parent = WavePresetsContainer

    local WcgLayout = Instance.new("UIGridLayout", WaveChipsGrid)
    WcgLayout.CellPadding = UDim2.new(0, 6, 0, 6)
    WcgLayout.CellSize = isMobile and UDim2.new(0.333, -4, 0, 28) or UDim2.new(0.2, -5, 0, 28)
    WcgLayout.SortOrder = Enum.SortOrder.LayoutOrder

    local wavePresets = {
        "Cyberpunk", "Aurora", "Cosmic", "Crimson", "Sunset", "Emerald", "Tokyo", "Titanium", "Rainbow", "None"
    }
    local currentWave = (UI and UI.MenuConfig and UI.MenuConfig["AnimatedTheme"]) or "Cyberpunk"
    local waveChips = {}

    local function selectWavePreset(preset)
        currentWave = preset
        if UI and UI.SetAnimatedTheme then
            UI:SetAnimatedTheme(preset)
        end
        for p, btn in pairs(waveChips) do
            local isSel = (p == preset)
            TweenService:Create(btn, TweenInfo.new(0.18), {
                BackgroundColor3 = isSel and Color3.fromRGB(99, 102, 241) or Color3.fromRGB(22, 26, 38),
                TextColor3 = isSel and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 155, 175)
            }):Play()
            local strk = btn:FindFirstChildOfClass("UIStroke")
            if strk then
                strk.Color = isSel and Color3.fromRGB(165, 180, 252) or Color3.fromRGB(42, 48, 68)
            end
        end
    end

    for idx, preset in ipairs(wavePresets) do
        local Chip = Instance.new("TextButton")
        Chip.Name = preset
        Chip.BackgroundColor3 = (preset == currentWave) and Color3.fromRGB(99, 102, 241) or Color3.fromRGB(22, 26, 38)
        Chip.Text = preset
        Chip.Font = Enum.Font.GothamBold
        Chip.TextSize = 10
        Chip.TextColor3 = (preset == currentWave) and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 155, 175)
        Chip.AutoButtonColor = false
        Chip.LayoutOrder = idx
        Chip.Parent = WaveChipsGrid
        Instance.new("UICorner", Chip).CornerRadius = UDim.new(0, 8)

        local CStroke = Instance.new("UIStroke", Chip)
        CStroke.Color = (preset == currentWave) and Color3.fromRGB(165, 180, 252) or Color3.fromRGB(42, 48, 68)
        CStroke.Thickness = 1

        waveChips[preset] = Chip

        Chip.MouseButton1Click:Connect(function()
            selectWavePreset(preset)
        end)
    end

    -- 1B. Styl ruchu fali (Motion Styles: Drift, Pulse, Vortex)
    local MotionRow = Instance.new("Frame")
    MotionRow.Name = "MotionRow"
    MotionRow.Size = UDim2.new(1, 0, 0, 0)
    MotionRow.AutomaticSize = Enum.AutomaticSize.Y
    MotionRow.BackgroundTransparency = 1
    MotionRow.LayoutOrder = 2
    MotionRow.Parent = WaveSection

    local MrLayout = Instance.new("UIListLayout", MotionRow)
    MrLayout.SortOrder = Enum.SortOrder.LayoutOrder
    MrLayout.Padding = UDim.new(0, 6)

    local MrTitle = Instance.new("TextLabel")
    MrTitle.Text = "Styl ruchu fali świetlnej:"
    MrTitle.Font = Enum.Font.GothamBold
    MrTitle.TextSize = 11
    MrTitle.TextColor3 = Color3.fromRGB(180, 190, 215)
    MrTitle.TextXAlignment = Enum.TextXAlignment.Left
    MrTitle.Size = UDim2.new(1, 0, 0, 16)
    MrTitle.BackgroundTransparency = 1
    MrTitle.LayoutOrder = 1
    MrTitle.Parent = MotionRow

    local MotionChipsRow = Instance.new("Frame")
    MotionChipsRow.Name = "MotionChipsRow"
    MotionChipsRow.Size = UDim2.new(1, 0, 0, 30)
    MotionChipsRow.BackgroundTransparency = 1
    MotionChipsRow.LayoutOrder = 2
    MotionChipsRow.Parent = MotionRow

    local McrLayout = Instance.new("UIListLayout", MotionChipsRow)
    McrLayout.FillDirection = Enum.FillDirection.Horizontal
    McrLayout.Padding = UDim.new(0, 8)

    local motionPresets = {
        { Key = "Drift",  Label = "🌊 Dryf (Drift)" },
        { Key = "Pulse",  Label = "💓 Puls (Pulse)" },
        { Key = "Vortex", Label = "🌀 Wir (Vortex)" }
    }
    local currentMotion = (UI and UI.MenuConfig and UI.MenuConfig["AnimatedThemeMotion"]) or "Drift"
    local motionBtns = {}

    local function selectMotion(key)
        currentMotion = key
        if UI and UI.SetAmbientMotion then
            UI:SetAmbientMotion(key)
        end
        for k, btn in pairs(motionBtns) do
            local isSel = (k == key)
            TweenService:Create(btn, TweenInfo.new(0.18), {
                BackgroundColor3 = isSel and Color3.fromRGB(80, 95, 210) or Color3.fromRGB(22, 26, 38),
                TextColor3 = isSel and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 155, 175)
            }):Play()
            local strk = btn:FindFirstChildOfClass("UIStroke")
            if strk then
                strk.Color = isSel and Color3.fromRGB(140, 160, 245) or Color3.fromRGB(42, 48, 68)
            end
        end
    end

    for idx, mData in ipairs(motionPresets) do
        local mBtn = Instance.new("TextButton")
        mBtn.Name = "Motion_" .. mData.Key
        mBtn.Size = UDim2.new(0.333, -6, 1, 0)
        mBtn.BackgroundColor3 = (mData.Key == currentMotion) and Color3.fromRGB(80, 95, 210) or Color3.fromRGB(22, 26, 38)
        mBtn.Text = mData.Label
        mBtn.Font = Enum.Font.GothamBold
        mBtn.TextSize = 11
        mBtn.TextColor3 = (mData.Key == currentMotion) and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 155, 175)
        mBtn.AutoButtonColor = false
        mBtn.LayoutOrder = idx
        mBtn.Parent = MotionChipsRow
        Instance.new("UICorner", mBtn).CornerRadius = UDim.new(0, 8)
        local ms = Instance.new("UIStroke", mBtn)
        ms.Color = (mData.Key == currentMotion) and Color3.fromRGB(140, 160, 245) or Color3.fromRGB(42, 48, 68)
        ms.Thickness = 1
        motionBtns[mData.Key] = mBtn

        mBtn.MouseButton1Click:Connect(function()
            selectMotion(mData.Key)
        end)
    end

    -- 1C. Suwaki fali świetlnej
    local SlidersGrid = Instance.new("Frame")
    SlidersGrid.Name = "SlidersGrid"
    SlidersGrid.Size = UDim2.new(1, 0, 0, 0)
    SlidersGrid.AutomaticSize = Enum.AutomaticSize.Y
    SlidersGrid.BackgroundTransparency = 1
    SlidersGrid.LayoutOrder = 3
    SlidersGrid.Parent = WaveSection

    local SgLayout = Instance.new("UIGridLayout", SlidersGrid)
    SgLayout.CellPadding = UDim2.new(0, 10, 0, 10)
    SgLayout.CellSize = isMobile and UDim2.new(1, 0, 0, 56) or UDim2.new(0.5, -5, 0, 56)
    SgLayout.SortOrder = Enum.SortOrder.LayoutOrder

    local Slider1Col = Instance.new("Frame", SlidersGrid)
    Slider1Col.Name = "Col1"
    Slider1Col.BackgroundTransparency = 1
    Slider1Col.Size = UDim2.new(1, 0, 1, 0)
    Slider1Col.LayoutOrder = 1

    local Slider2Col = Instance.new("Frame", SlidersGrid)
    Slider2Col.Name = "Col2"
    Slider2Col.BackgroundTransparency = 1
    Slider2Col.Size = UDim2.new(1, 0, 1, 0)
    Slider2Col.LayoutOrder = 2

    if SliderElement then
        local savedInt = (UI and UI.MenuConfig and UI.MenuConfig["AnimatedThemeIntensity"]) or 10
        SliderElement({
            Name = "Intensywność Fali",
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
        }, ThemeManager, Slider1Col, UI.MenuConfig, UI.SaveMenuConfig)

        local savedSpeed = (UI and UI.MenuConfig and UI.MenuConfig["AnimatedThemeSpeed"]) or 5
        SliderElement({
            Name = "Szybkość Animacji",
            Min = 1,
            Max = 25,
            Default = math.floor(savedSpeed <= 2.5 and (savedSpeed * 10) or savedSpeed),
            Suffix = "x",
            Callback = function(val)
                if UI and UI.SetAnimatedTheme then
                    UI:SetAnimatedTheme(nil, nil, val / 10)
                end
            end
        }, ThemeManager, Slider2Col, UI.MenuConfig, UI.SaveMenuConfig)
    end

    -- -------------------------------------------------------------------------
    -- SEPARATOR MIĘDZY FALAMI A LOGO
    -- -------------------------------------------------------------------------
    local SectionDivider = Instance.new("Frame")
    SectionDivider.Name = "SectionDivider"
    SectionDivider.Size = UDim2.new(1, 0, 0, 1)
    SectionDivider.BackgroundColor3 = Color3.fromRGB(38, 44, 62)
    SectionDivider.BorderSizePixel = 0
    SectionDivider.LayoutOrder = 3
    SectionDivider.Parent = VisualCard

    -- -------------------------------------------------------------------------
    -- SEKCJA 2: LOGO NA ŚRODKU CLIENTA (CENTER LOGO WATERMARK)
    -- -------------------------------------------------------------------------
    local WatermarkSection = Instance.new("Frame")
    WatermarkSection.Name = "WatermarkSection"
    WatermarkSection.Size = UDim2.new(1, 0, 0, 0)
    WatermarkSection.AutomaticSize = Enum.AutomaticSize.Y
    WatermarkSection.BackgroundTransparency = 1
    WatermarkSection.LayoutOrder = 4
    WatermarkSection.Parent = VisualCard

    local WmsLayout = Instance.new("UIListLayout", WatermarkSection)
    WmsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    WmsLayout.Padding = UDim.new(0, 10)

    -- 2A. Wiersz przełącznika Toggle iOS dla Logo
    local WmsHeaderRow = Instance.new("Frame")
    WmsHeaderRow.Name = "WmsHeaderRow"
    WmsHeaderRow.Size = UDim2.new(1, 0, 0, 36)
    WmsHeaderRow.BackgroundTransparency = 1
    WmsHeaderRow.LayoutOrder = 1
    WmsHeaderRow.Parent = WatermarkSection

    local WmsInfoCol = Instance.new("Frame")
    WmsInfoCol.Name = "WmsInfoCol"
    WmsInfoCol.Size = UDim2.new(1, -60, 1, 0)
    WmsInfoCol.BackgroundTransparency = 1
    WmsInfoCol.Parent = WmsHeaderRow

    local WmsTitle = Instance.new("TextLabel")
    WmsTitle.Text = "Logo na środku clienta (Znak wodny w tle)"
    WmsTitle.Font = Enum.Font.GothamBold
    WmsTitle.TextSize = 12
    WmsTitle.TextColor3 = Color3.fromRGB(240, 245, 255)
    WmsTitle.TextXAlignment = Enum.TextXAlignment.Left
    WmsTitle.Size = UDim2.new(1, 0, 0, 18)
    WmsTitle.BackgroundTransparency = 1
    WmsTitle.Parent = WmsInfoCol

    local WmsSubtitle = Instance.new("TextLabel")
    WmsSubtitle.Text = "Stylowy emblemat/herb wyświetlany pod spodem menu"
    WmsSubtitle.Font = Enum.Font.GothamMedium
    WmsSubtitle.TextSize = 10
    WmsSubtitle.TextColor3 = Color3.fromRGB(130, 140, 168)
    WmsSubtitle.TextXAlignment = Enum.TextXAlignment.Left
    WmsSubtitle.Position = UDim2.new(0, 0, 0, 18)
    WmsSubtitle.Size = UDim2.new(1, 0, 0, 16)
    WmsSubtitle.BackgroundTransparency = 1
    WmsSubtitle.Parent = WmsInfoCol

    -- Przełącznik iOS Toggle Switch
    local isWatermarkOn = true
    if UI and UI.MenuConfig and UI.MenuConfig["WatermarkEnabled"] ~= nil then
        isWatermarkOn = UI.MenuConfig["WatermarkEnabled"]
    end

    local ToggleTrack = Instance.new("TextButton")
    ToggleTrack.Name = "ToggleTrack"
    ToggleTrack.Size = UDim2.new(0, 44, 0, 24)
    ToggleTrack.Position = UDim2.new(1, 0, 0.5, 0)
    ToggleTrack.AnchorPoint = Vector2.new(1, 0.5)
    ToggleTrack.BackgroundColor3 = isWatermarkOn and Color3.fromRGB(99, 102, 241) or Color3.fromRGB(38, 44, 60)
    ToggleTrack.Text = ""
    ToggleTrack.AutoButtonColor = false
    ToggleTrack.Parent = WmsHeaderRow
    Instance.new("UICorner", ToggleTrack).CornerRadius = UDim.new(1, 0)

    local ToggleThumb = Instance.new("Frame")
    ToggleThumb.Name = "Thumb"
    ToggleThumb.Size = UDim2.new(0, 18, 0, 18)
    ToggleThumb.Position = isWatermarkOn and UDim2.new(1, -21, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
    ToggleThumb.AnchorPoint = Vector2.new(0, 0.5)
    ToggleThumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    ToggleThumb.BorderSizePixel = 0
    ToggleThumb.Parent = ToggleTrack
    Instance.new("UICorner", ToggleThumb).CornerRadius = UDim.new(1, 0)

    -- Kontener na kontrolki logo (widoczny tylko gdy logo jest włączone)
    local WatermarkControls = Instance.new("Frame")
    WatermarkControls.Name = "WatermarkControls"
    WatermarkControls.Size = UDim2.new(1, 0, 0, 0)
    WatermarkControls.AutomaticSize = Enum.AutomaticSize.Y
    WatermarkControls.BackgroundTransparency = 1
    WatermarkControls.LayoutOrder = 2
    WatermarkControls.Visible = isWatermarkOn
    WatermarkControls.Parent = WatermarkSection

    local WmcLayout = Instance.new("UIListLayout", WatermarkControls)
    WmcLayout.SortOrder = Enum.SortOrder.LayoutOrder
    WmcLayout.Padding = UDim.new(0, 10)

    local function setWatermarkEnabledState(state)
        isWatermarkOn = state
        TweenService:Create(ToggleTrack, TweenInfo.new(0.2), {
            BackgroundColor3 = isWatermarkOn and Color3.fromRGB(99, 102, 241) or Color3.fromRGB(38, 44, 60)
        }):Play()
        TweenService:Create(ToggleThumb, TweenInfo.new(0.2), {
            Position = isWatermarkOn and UDim2.new(1, -21, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
        }):Play()
        WatermarkControls.Visible = isWatermarkOn
        if UI and UI.SetWatermark then
            UI:SetWatermark(isWatermarkOn)
        end
    end

    ToggleTrack.MouseButton1Click:Connect(function()
        setWatermarkEnabledState(not isWatermarkOn)
    end)

    -- 2B. Presety logo w tle (Cyber Crest, Imperial Crown, Astral Nova, Apex Skull, Vanguard Shield, Custom)
    local LogoPresetsContainer = Instance.new("Frame")
    LogoPresetsContainer.Name = "LogoPresetsContainer"
    LogoPresetsContainer.Size = UDim2.new(1, 0, 0, 0)
    LogoPresetsContainer.AutomaticSize = Enum.AutomaticSize.Y
    LogoPresetsContainer.BackgroundTransparency = 1
    LogoPresetsContainer.LayoutOrder = 1
    LogoPresetsContainer.Parent = WatermarkControls

    local LpcLayout = Instance.new("UIListLayout", LogoPresetsContainer)
    LpcLayout.SortOrder = Enum.SortOrder.LayoutOrder
    LpcLayout.Padding = UDim.new(0, 6)

    local LpcTitle = Instance.new("TextLabel")
    LpcTitle.Text = "Wybierz styl logo w tle:"
    LpcTitle.Font = Enum.Font.GothamBold
    LpcTitle.TextSize = 11
    LpcTitle.TextColor3 = Color3.fromRGB(180, 190, 215)
    LpcTitle.TextXAlignment = Enum.TextXAlignment.Left
    LpcTitle.Size = UDim2.new(1, 0, 0, 16)
    LpcTitle.BackgroundTransparency = 1
    LpcTitle.LayoutOrder = 1
    LpcTitle.Parent = LogoPresetsContainer

    local LogoChipsGrid = Instance.new("Frame")
    LogoChipsGrid.Name = "LogoChipsGrid"
    LogoChipsGrid.Size = UDim2.new(1, 0, 0, 0)
    LogoChipsGrid.AutomaticSize = Enum.AutomaticSize.Y
    LogoChipsGrid.BackgroundTransparency = 1
    LogoChipsGrid.LayoutOrder = 2
    LogoChipsGrid.Parent = LogoPresetsContainer

    local LcgLayout = Instance.new("UIGridLayout", LogoChipsGrid)
    LcgLayout.CellPadding = UDim2.new(0, 6, 0, 6)
    LcgLayout.CellSize = isMobile and UDim2.new(0.333, -4, 0, 28) or UDim2.new(0.166, -5, 0, 28)
    LcgLayout.SortOrder = Enum.SortOrder.LayoutOrder

    local logoPresetsList = {
        { Key = "Crest",  Label = "🛡️ Crest" },
        { Key = "Crown",  Label = "👑 Crown" },
        { Key = "Star",   Label = "✨ Nova" },
        { Key = "Skull",  Label = "💀 Skull" },
        { Key = "Shield", Label = "⚔️ Shield" },
        { Key = "Custom", Label = "🛠️ Własne" }
    }

    local activeLogoPreset = (UI and UI.MenuConfig and UI.MenuConfig["WatermarkPreset"]) or "Crest"
    local logoChips = {}

    local function selectLogoPreset(key)
        activeLogoPreset = key
        if UI and UI.SetWatermark then
            UI:SetWatermark(nil, key)
        end
        for k, btn in pairs(logoChips) do
            local isSel = (k == key)
            TweenService:Create(btn, TweenInfo.new(0.18), {
                BackgroundColor3 = isSel and Color3.fromRGB(99, 102, 241) or Color3.fromRGB(22, 26, 38),
                TextColor3 = isSel and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 155, 175)
            }):Play()
            local strk = btn:FindFirstChildOfClass("UIStroke")
            if strk then
                strk.Color = isSel and Color3.fromRGB(165, 180, 252) or Color3.fromRGB(42, 48, 68)
            end
        end
    end

    for idx, lData in ipairs(logoPresetsList) do
        local lBtn = Instance.new("TextButton")
        lBtn.Name = "Logo_" .. lData.Key
        lBtn.BackgroundColor3 = (lData.Key == activeLogoPreset) and Color3.fromRGB(99, 102, 241) or Color3.fromRGB(22, 26, 38)
        lBtn.Text = lData.Label
        lBtn.Font = Enum.Font.GothamBold
        lBtn.TextSize = 10
        lBtn.TextColor3 = (lData.Key == activeLogoPreset) and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 155, 175)
        lBtn.AutoButtonColor = false
        lBtn.LayoutOrder = idx
        lBtn.Parent = LogoChipsGrid
        Instance.new("UICorner", lBtn).CornerRadius = UDim.new(0, 8)
        local ls = Instance.new("UIStroke", lBtn)
        ls.Color = (lData.Key == activeLogoPreset) and Color3.fromRGB(165, 180, 252) or Color3.fromRGB(42, 48, 68)
        ls.Thickness = 1
        logoChips[lData.Key] = lBtn

        lBtn.MouseButton1Click:Connect(function()
            selectLogoPreset(lData.Key)
        end)
    end

    -- 2C. Wiersz Własnego Asset ID dla Logo
    local CustomLogoRow = Instance.new("Frame")
    CustomLogoRow.Name = "CustomLogoRow"
    CustomLogoRow.Size = UDim2.new(1, 0, 0, 32)
    CustomLogoRow.BackgroundTransparency = 1
    CustomLogoRow.LayoutOrder = 2
    CustomLogoRow.Parent = WatermarkControls

    local ClInputBox = Instance.new("Frame")
    ClInputBox.Size = UDim2.new(1, -115, 1, 0)
    ClInputBox.BackgroundColor3 = Color3.fromRGB(20, 24, 36)
    ClInputBox.Parent = CustomLogoRow
    Instance.new("UICorner", ClInputBox).CornerRadius = UDim.new(0, 8)
    local ClStroke = Instance.new("UIStroke", ClInputBox)
    ClStroke.Color = Color3.fromRGB(42, 48, 70)
    ClStroke.Thickness = 1

    local ClIcon = Instance.new("ImageLabel")
    ClIcon.Size = UDim2.new(0, 14, 0, 14)
    ClIcon.Position = UDim2.new(0, 8, 0.5, 0)
    ClIcon.AnchorPoint = Vector2.new(0, 0.5)
    ClIcon.BackgroundTransparency = 1
    ClIcon.ImageColor3 = Color3.fromRGB(130, 140, 168)
    ClIcon.Parent = ClInputBox
    if Icons and Icons.Apply then Icons:Apply(ClIcon, "image") end

    local CustomLogoInput = Instance.new("TextBox")
    CustomLogoInput.Size = UDim2.new(1, -30, 1, 0)
    CustomLogoInput.Position = UDim2.new(0, 26, 0, 0)
    CustomLogoInput.BackgroundTransparency = 1
    local savedLogoId = (UI and UI.MenuConfig and UI.MenuConfig["WatermarkCustomId"]) or ""
    CustomLogoInput.Text = savedLogoId
    CustomLogoInput.PlaceholderText = "Wklej Roblox Asset ID własnego logo..."
    CustomLogoInput.PlaceholderColor3 = Color3.fromRGB(100, 108, 130)
    CustomLogoInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    CustomLogoInput.Font = Enum.Font.GothamMedium
    CustomLogoInput.TextSize = 11
    CustomLogoInput.TextXAlignment = Enum.TextXAlignment.Left
    CustomLogoInput.ClearTextOnFocus = false
    CustomLogoInput.Parent = ClInputBox

    local ApplyLogoBtn = Instance.new("TextButton")
    ApplyLogoBtn.Size = UDim2.new(0, 105, 1, 0)
    ApplyLogoBtn.Position = UDim2.new(1, 0, 0, 0)
    ApplyLogoBtn.AnchorPoint = Vector2.new(1, 0)
    ApplyLogoBtn.BackgroundColor3 = Color3.fromRGB(99, 102, 241)
    ApplyLogoBtn.Text = "Zastosuj Logo"
    ApplyLogoBtn.Font = Enum.Font.GothamBold
    ApplyLogoBtn.TextSize = 11
    ApplyLogoBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    ApplyLogoBtn.AutoButtonColor = false
    ApplyLogoBtn.Parent = CustomLogoRow
    Instance.new("UICorner", ApplyLogoBtn).CornerRadius = UDim.new(0, 8)

    ApplyLogoBtn.MouseButton1Click:Connect(function()
        local raw = CustomLogoInput.Text:gsub("^%s+", ""):gsub("%s+$", "")
        if #raw > 0 then
            selectLogoPreset("Custom")
            if UI and UI.SetWatermark then
                UI:SetWatermark(nil, "Custom", raw)
            end
            ApplyLogoBtn.Text = "Zastosowano!"
            task.delay(1.2, function()
                if ApplyLogoBtn and ApplyLogoBtn.Parent then ApplyLogoBtn.Text = "Zastosuj Logo" end
            end)
        end
    end)

    -- 2D. Suwaki przezroczystości oraz rozmiaru logo
    local WmsSlidersGrid = Instance.new("Frame")
    WmsSlidersGrid.Name = "WmsSlidersGrid"
    WmsSlidersGrid.Size = UDim2.new(1, 0, 0, 0)
    WmsSlidersGrid.AutomaticSize = Enum.AutomaticSize.Y
    WmsSlidersGrid.BackgroundTransparency = 1
    WmsSlidersGrid.LayoutOrder = 3
    WmsSlidersGrid.Parent = WatermarkControls

    local WsgLayout = Instance.new("UIGridLayout", WmsSlidersGrid)
    WsgLayout.CellPadding = UDim2.new(0, 10, 0, 10)
    WsgLayout.CellSize = isMobile and UDim2.new(1, 0, 0, 56) or UDim2.new(0.5, -5, 0, 56)
    WsgLayout.SortOrder = Enum.SortOrder.LayoutOrder

    local WmsSlCol1 = Instance.new("Frame", WmsSlidersGrid)
    WmsSlCol1.Name = "Col1"
    WmsSlCol1.BackgroundTransparency = 1
    WmsSlCol1.Size = UDim2.new(1, 0, 1, 0)

    local WmsSlCol2 = Instance.new("Frame", WmsSlidersGrid)
    WmsSlCol2.Name = "Col2"
    WmsSlCol2.BackgroundTransparency = 1
    WmsSlCol2.Size = UDim2.new(1, 0, 1, 0)

    if SliderElement then
        local savedTrans = (UI and UI.MenuConfig and UI.MenuConfig["WatermarkTransparency"]) or 0.90
        SliderElement({
            Name = "Przezroczystość Logo",
            Min = 50,
            Max = 98,
            Default = math.floor(savedTrans <= 1 and (savedTrans * 100) or savedTrans),
            Suffix = "%",
            Flag = "WatermarkTransparency",
            Callback = function(val)
                if UI and UI.SetWatermark then
                    UI:SetWatermark(nil, nil, nil, val / 100, nil)
                end
            end
        }, ThemeManager, WmsSlCol1, UI.MenuConfig, UI.SaveMenuConfig)

        local savedSize = (UI and UI.MenuConfig and UI.MenuConfig["WatermarkSize"]) or 220
        SliderElement({
            Name = "Rozmiar Logo (px)",
            Min = 100,
            Max = 380,
            Default = math.floor(savedSize),
            Suffix = "px",
            Flag = "WatermarkSize",
            Callback = function(val)
                if UI and UI.SetWatermark then
                    UI:SetWatermark(nil, nil, nil, nil, val)
                end
            end
        }, ThemeManager, WmsSlCol2, UI.MenuConfig, UI.SaveMenuConfig)
    end

    -- =========================================================================
    -- BENTO 2: PALETY KOLORYSTYCZNE (THEMES SHOWROOM)
    -- =========================================================================
    local ThemesCard, _ = createBentoCard("ThemesCard", 2)
    createCardHeader(ThemesCard, "PALETY KOLORYSTYCZNE", "palette", "Wybierz luksusową paletę kolorystyczną dla całego menu", 1)

    local ThemesGrid = Instance.new("Frame")
    ThemesGrid.Name = "ThemesGrid"
    ThemesGrid.Size = UDim2.new(1, 0, 0, 0)
    ThemesGrid.AutomaticSize = Enum.AutomaticSize.Y
    ThemesGrid.BackgroundTransparency = 1
    ThemesGrid.LayoutOrder = 2
    ThemesGrid.Parent = ThemesCard

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
                    Color = isCur and Color3.fromRGB(99, 102, 241) or Color3.fromRGB(38, 44, 62),
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
        TCard.BackgroundColor3 = Color3.fromRGB(20, 24, 35)
        TCard.Text = ""
        TCard.AutoButtonColor = false
        TCard.LayoutOrder = idx
        TCard.Parent = ThemesGrid
        Instance.new("UICorner", TCard).CornerRadius = UDim.new(0, 10)

        local TcCardStroke = Instance.new("UIStroke", TCard)
        TcCardStroke.Color = (tKey == activeThemeName) and Color3.fromRGB(99, 102, 241) or Color3.fromRGB(38, 44, 62)
        TcCardStroke.Thickness = (tKey == activeThemeName) and 1.5 or 1

        local CardPad = Instance.new("UIPadding", TCard)
        CardPad.PaddingLeft = UDim.new(0, 10)
        CardPad.PaddingRight = UDim.new(0, 10)
        CardPad.PaddingTop = UDim.new(0, 8)
        CardPad.PaddingBottom = UDim.new(0, 8)

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
            TweenService:Create(TCard, TweenInfo.new(0.18), { BackgroundColor3 = Color3.fromRGB(28, 33, 48) }):Play()
        end)
        TCard.MouseLeave:Connect(function()
            TweenService:Create(TCard, TweenInfo.new(0.18), { BackgroundColor3 = Color3.fromRGB(20, 24, 35) }):Play()
        end)
        TCard.MouseButton1Click:Connect(function()
            ThemeManager:Apply(tData.Colors)
            updateThemeSelection(tKey)
        end)
    end

    -- =========================================================================
    -- BENTO 3: OCHRONA KLIENTA I BINDY (CLIENT DEFENSE & POWER OPTIONS)
    -- =========================================================================
    local DefenseCard, _ = createBentoCard("DefenseCard", 3)
    createCardHeader(DefenseCard, "BEZPIECZEŃSTWO I STEROWANIE", "shield", "Ochrona sesji, bind klawisza menu i moduły pomocnicze", 1)

    local PowerGrid = Instance.new("Frame")
    PowerGrid.Name = "PowerGrid"
    PowerGrid.Size = UDim2.new(1, 0, 0, 0)
    PowerGrid.AutomaticSize = Enum.AutomaticSize.Y
    PowerGrid.BackgroundTransparency = 1
    PowerGrid.LayoutOrder = 2
    PowerGrid.Parent = DefenseCard

    local PgLayout = Instance.new("UIGridLayout", PowerGrid)
    PgLayout.CellPadding = UDim2.new(0, 10, 0, 10)
    PgLayout.CellSize = isMobile and UDim2.new(1, 0, 0, 62) or UDim2.new(0.5, -5, 0, 62)
    PgLayout.SortOrder = Enum.SortOrder.LayoutOrder

    local function makePowerCard(titleText, descText, iconName, defaultVal, callback)
        local Card = Instance.new("Frame")
        Card.BackgroundColor3 = Color3.fromRGB(20, 24, 36)
        Card.BackgroundTransparency = 0.4
        Card.BorderSizePixel = 0
        Card.Parent = PowerGrid
        Instance.new("UICorner", Card).CornerRadius = UDim.new(0, 12)

        local cStroke = Instance.new("UIStroke", Card)
        cStroke.Color = Color3.fromRGB(45, 52, 75)
        cStroke.Thickness = 1
        cStroke.Transparency = 0.65

        local cPad = Instance.new("UIPadding", Card)
        cPad.PaddingLeft = UDim.new(0, 12)
        cPad.PaddingRight = UDim.new(0, 12)
        cPad.PaddingTop = UDim.new(0, 10)
        cPad.PaddingBottom = UDim.new(0, 10)

        local IconBox = Instance.new("Frame")
        IconBox.Size = UDim2.new(0, 32, 0, 32)
        IconBox.Position = UDim2.new(0, 0, 0.5, 0)
        IconBox.AnchorPoint = Vector2.new(0, 0.5)
        IconBox.BackgroundColor3 = Color3.fromRGB(28, 34, 52)
        IconBox.BackgroundTransparency = 0.35
        IconBox.BorderSizePixel = 0
        IconBox.Parent = Card
        Instance.new("UICorner", IconBox).CornerRadius = UDim.new(0, 8)

        local IcoImg = Instance.new("ImageLabel")
        IcoImg.Size = UDim2.new(0, 16, 0, 16)
        IcoImg.Position = UDim2.new(0.5, 0, 0.5, 0)
        IcoImg.AnchorPoint = Vector2.new(0.5, 0.5)
        IcoImg.BackgroundTransparency = 1
        IcoImg.ImageColor3 = Color3.fromRGB(135, 150, 220)
        IcoImg.Parent = IconBox
        if Icons and Icons.Apply then Icons:Apply(IcoImg, iconName) end

        local Title = Instance.new("TextLabel")
        Title.Text = titleText
        Title.Font = Enum.Font.GothamBold
        Title.TextSize = 12
        Title.TextColor3 = Color3.fromRGB(255, 255, 255)
        Title.TextXAlignment = Enum.TextXAlignment.Left
        Title.Position = UDim2.new(0, 42, 0, 2)
        Title.Size = UDim2.new(1, -95, 0, 16)
        Title.BackgroundTransparency = 1
        Title.Parent = Card

        local Desc = Instance.new("TextLabel")
        Desc.Text = descText
        Desc.Font = Enum.Font.GothamMedium
        Desc.TextSize = 10
        Desc.TextColor3 = Color3.fromRGB(140, 148, 175)
        Desc.TextXAlignment = Enum.TextXAlignment.Left
        Desc.TextTruncate = Enum.TextTruncate.AtEnd
        Desc.Position = UDim2.new(0, 42, 0, 20)
        Desc.Size = UDim2.new(1, -95, 0, 14)
        Desc.BackgroundTransparency = 1
        Desc.Parent = Card

        -- Apple-style Pill Switch
        local SwitchBtn = Instance.new("TextButton")
        SwitchBtn.Size = UDim2.new(0, 44, 0, 24)
        SwitchBtn.Position = UDim2.new(1, 0, 0.5, 0)
        SwitchBtn.AnchorPoint = Vector2.new(1, 0.5)
        SwitchBtn.BackgroundColor3 = defaultVal and Color3.fromRGB(99, 102, 241) or Color3.fromRGB(34, 40, 58)
        SwitchBtn.BackgroundTransparency = 0.2
        SwitchBtn.Text = ""
        SwitchBtn.AutoButtonColor = false
        SwitchBtn.Parent = Card
        Instance.new("UICorner", SwitchBtn).CornerRadius = UDim.new(1, 0)

        local swStroke = Instance.new("UIStroke", SwitchBtn)
        swStroke.Color = defaultVal and Color3.fromRGB(140, 160, 245) or Color3.fromRGB(50, 58, 82)
        swStroke.Thickness = 1
        swStroke.Transparency = 0.5

        local Dot = Instance.new("Frame")
        Dot.Size = UDim2.new(0, 16, 0, 16)
        Dot.Position = defaultVal and UDim2.new(1, -19, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
        Dot.AnchorPoint = Vector2.new(0, 0.5)
        Dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Dot.BorderSizePixel = 0
        Dot.Parent = SwitchBtn
        Instance.new("UICorner", Dot).CornerRadius = UDim.new(1, 0)

        local currentVal = defaultVal
        SwitchBtn.MouseButton1Click:Connect(function()
            currentVal = not currentVal
            local destPos = currentVal and UDim2.new(1, -19, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
            local destBg = currentVal and Color3.fromRGB(99, 102, 241) or Color3.fromRGB(34, 40, 58)
            local destStrk = currentVal and Color3.fromRGB(140, 160, 245) or Color3.fromRGB(50, 58, 82)

            TweenService:Create(Dot, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Position = destPos
            }):Play()
            TweenService:Create(SwitchBtn, TweenInfo.new(0.2), { BackgroundColor3 = destBg }):Play()
            TweenService:Create(swStroke, TweenInfo.new(0.2), { Color = destStrk }):Play()

            if callback then callback(currentVal) end
        end)

        return Card
    end

    -- 1. AntiAFK
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

    -- 2. AntiFling
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

    -- 3. Keybinds Overlay
    local isOverlayActive = (UI and UI.MenuConfig and UI.MenuConfig["KeybindsOverlay"] == true) or false
    makePowerCard("Keybinds HUD (Overlay)", "Wyświetla ekranową listę aktywnych bindów", "layout", isOverlayActive, function(state)
        if UI and UI.SetKeybindsOverlayVisible then
            UI:SetKeybindsOverlayVisible(state)
        end
        if UI and UI.MenuConfig then UI.MenuConfig["KeybindsOverlay"] = state end
    end)

    -- 4. Emotes Menu
    local emoteEnabled = (UI and UI.MenuConfig and UI.MenuConfig["EmotesMenu"] == true) or false
    makePowerCard("Roblox Emotes Menu", "Pływający przycisk koła emotek i animacji", "smile", emoteEnabled, function(state)
        local mod = safeLoadSub("emotes/EmoteMenu.lua", baseUrl .. "emotes/EmoteMenu.lua")
        if mod then
            if state and mod.Load then pcall(function() mod:Load() end)
            elseif not state and mod.Unload then pcall(function() mod:Unload() end) end
        end
        if UI and UI.MenuConfig then UI.MenuConfig["EmotesMenu"] = state end
    end)

    -- 5. Karta Menu Keybind (Pełna szerokość dolnego paska w Bento 3)
    local KeybindRow = Instance.new("Frame")
    KeybindRow.Name = "KeybindRow"
    KeybindRow.Size = UDim2.new(1, 0, 0, 50)
    KeybindRow.BackgroundColor3 = Color3.fromRGB(20, 24, 36)
    KeybindRow.BackgroundTransparency = 0.4
    KeybindRow.LayoutOrder = 3
    KeybindRow.Parent = DefenseCard
    Instance.new("UICorner", KeybindRow).CornerRadius = UDim.new(0, 12)

    local KrStroke = Instance.new("UIStroke", KeybindRow)
    KrStroke.Color = Color3.fromRGB(45, 52, 75)
    KrStroke.Thickness = 1
    KrStroke.Transparency = 0.65

    local KrPad = Instance.new("UIPadding", KeybindRow)
    KrPad.PaddingLeft = UDim.new(0, 12)
    KrPad.PaddingRight = UDim.new(0, 12)

    local KbIcoBox = Instance.new("Frame")
    KbIcoBox.Size = UDim2.new(0, 32, 0, 32)
    KbIcoBox.Position = UDim2.new(0, 0, 0.5, 0)
    KbIcoBox.AnchorPoint = Vector2.new(0, 0.5)
    KbIcoBox.BackgroundColor3 = Color3.fromRGB(28, 34, 52)
    KbIcoBox.BackgroundTransparency = 0.35
    KbIcoBox.Parent = KeybindRow
    Instance.new("UICorner", KbIcoBox).CornerRadius = UDim.new(0, 8)

    local KbIcoImg = Instance.new("ImageLabel")
    KbIcoImg.Size = UDim2.new(0, 16, 0, 16)
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
    KbTitle.Position = UDim2.new(0, 42, 0, 8)
    KbTitle.Size = UDim2.new(1, -110, 0, 16)
    KbTitle.BackgroundTransparency = 1
    KbTitle.Parent = KeybindRow

    local KbDesc = Instance.new("TextLabel")
    KbDesc.Text = "Kliknij plakietkę po prawej, aby zarejestrować nowy skrót klawiszowy"
    KbDesc.Font = Enum.Font.GothamMedium
    KbDesc.TextSize = 10
    KbDesc.TextColor3 = Color3.fromRGB(140, 148, 175)
    KbDesc.TextXAlignment = Enum.TextXAlignment.Left
    KbDesc.Position = UDim2.new(0, 42, 0, 26)
    KbDesc.Size = UDim2.new(1, -110, 0, 14)
    KbDesc.BackgroundTransparency = 1
    KbDesc.Parent = KeybindRow

    local KbBadge = Instance.new("TextButton")
    KbBadge.Size = UDim2.new(0, 52, 0, 26)
    KbBadge.Position = UDim2.new(1, 0, 0.5, 0)
    KbBadge.AnchorPoint = Vector2.new(1, 0.5)
    KbBadge.BackgroundColor3 = Color3.fromRGB(28, 34, 50)
    local curK = (UI and UI.CurrentMenuKeyName) or "K"
    KbBadge.Text = "[" .. tostring(curK) .. "]"
    KbBadge.Font = Enum.Font.GothamBold
    KbBadge.TextSize = 11
    KbBadge.TextColor3 = Color3.fromRGB(165, 180, 252)
    KbBadge.AutoButtonColor = false
    KbBadge.Parent = KeybindRow
    Instance.new("UICorner", KbBadge).CornerRadius = UDim.new(0, 8)

    local KbbStroke = Instance.new("UIStroke", KbBadge)
    KbbStroke.Color = Color3.fromRGB(55, 64, 92)
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
                KbbStroke.Color = Color3.fromRGB(55, 64, 92)
                if UI and UI.SetMenuKeybind then UI:SetMenuKeybind(nk) end
            end
        end)
    end)

    -- =========================================================================
    -- BENTO 4: CONFIG CLOUD & LOCAL VAULT (PROFILE I CHMURA)
    -- =========================================================================
    local ConfigsCard, _ = createBentoCard("ConfigsCard", 4)
    createCardHeader(ConfigsCard, "CONFIG CLOUD & LOCAL VAULT", "folder", "Zarządzaj profilami ustawień lokalnie na PC oraz z chmury", 1)

    -- Wiersz 1: Szukajka + Filtry (All / Local / Public)
    local CfgTopBar = Instance.new("Frame")
    CfgTopBar.Name = "CfgTopBar"
    CfgTopBar.Size = UDim2.new(1, 0, 0, 34)
    CfgTopBar.BackgroundTransparency = 1
    CfgTopBar.LayoutOrder = 2
    CfgTopBar.Parent = ConfigsCard

    local SearchBoxFrame = Instance.new("Frame")
    SearchBoxFrame.Size = UDim2.new(1, -170, 1, 0)
    SearchBoxFrame.BackgroundColor3 = Color3.fromRGB(20, 24, 36)
    SearchBoxFrame.Parent = CfgTopBar
    Instance.new("UICorner", SearchBoxFrame).CornerRadius = UDim.new(0, 8)

    local SbfStroke = Instance.new("UIStroke", SearchBoxFrame)
    SbfStroke.Color = Color3.fromRGB(42, 48, 70)
    SbfStroke.Thickness = 1

    local SIco = Instance.new("ImageLabel")
    SIco.Size = UDim2.new(0, 14, 0, 14)
    SIco.Position = UDim2.new(0, 10, 0.5, 0)
    SIco.AnchorPoint = Vector2.new(0, 0.5)
    SIco.BackgroundTransparency = 1
    SIco.ImageColor3 = Color3.fromRGB(130, 138, 160)
    SIco.Parent = SearchBoxFrame
    if Icons and Icons.Apply then Icons:Apply(SIco, "search") end

    local SearchInput = Instance.new("TextBox")
    SearchInput.Size = UDim2.new(1, -34, 1, 0)
    SearchInput.Position = UDim2.new(0, 28, 0, 0)
    SearchInput.BackgroundTransparency = 1
    SearchInput.PlaceholderText = "Szukaj profilu config..."
    SearchInput.PlaceholderColor3 = Color3.fromRGB(100, 108, 130)
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
        btn.BackgroundColor3 = (key == activeFilter) and Color3.fromRGB(99, 102, 241) or Color3.fromRGB(22, 26, 38)
        btn.Text = labelText
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 10
        btn.TextColor3 = (key == activeFilter) and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(140, 145, 165)
        btn.AutoButtonColor = false
        btn.LayoutOrder = order
        btn.Parent = FilterDock
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
        local bs = Instance.new("UIStroke", btn)
        bs.Color = (key == activeFilter) and Color3.fromRGB(165, 180, 252) or Color3.fromRGB(42, 48, 70)
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
    SaveRow.Size = UDim2.new(1, 0, 0, 34)
    SaveRow.BackgroundTransparency = 1
    SaveRow.LayoutOrder = 3
    SaveRow.Parent = ConfigsCard

    local NameBox = Instance.new("Frame")
    NameBox.Size = UDim2.new(1, -120, 1, 0)
    NameBox.BackgroundColor3 = Color3.fromRGB(20, 24, 36)
    NameBox.Parent = SaveRow
    Instance.new("UICorner", NameBox).CornerRadius = UDim.new(0, 8)

    local NbStroke = Instance.new("UIStroke", NameBox)
    NbStroke.Color = Color3.fromRGB(42, 48, 70)
    NbStroke.Thickness = 1

    local NameInput = Instance.new("TextBox")
    NameInput.Size = UDim2.new(1, -16, 1, 0)
    NameInput.Position = UDim2.new(0, 8, 0, 0)
    NameInput.BackgroundTransparency = 1
    NameInput.PlaceholderText = "Nazwa nowego configu..."
    NameInput.PlaceholderColor3 = Color3.fromRGB(100, 108, 130)
    NameInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    NameInput.Font = Enum.Font.GothamMedium
    NameInput.TextSize = 11
    NameInput.TextXAlignment = Enum.TextXAlignment.Left
    NameInput.ClearTextOnFocus = false
    NameInput.Parent = NameBox

    local SaveBtn = Instance.new("TextButton")
    SaveBtn.Size = UDim2.new(0, 110, 1, 0)
    SaveBtn.Position = UDim2.new(1, 0, 0, 0)
    SaveBtn.AnchorPoint = Vector2.new(1, 0)
    SaveBtn.BackgroundColor3 = Color3.fromRGB(99, 102, 241)
    SaveBtn.Text = "+ Zapisz Config"
    SaveBtn.Font = Enum.Font.GothamBold
    SaveBtn.TextSize = 11
    SaveBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    SaveBtn.AutoButtonColor = false
    SaveBtn.Parent = SaveRow
    Instance.new("UICorner", SaveBtn).CornerRadius = UDim.new(0, 8)

    -- Kontener listy configów
    local CfgListContainer = Instance.new("Frame")
    CfgListContainer.Name = "CfgListContainer"
    CfgListContainer.Size = UDim2.new(1, 0, 0, 0)
    CfgListContainer.AutomaticSize = Enum.AutomaticSize.Y
    CfgListContainer.BackgroundTransparency = 1
    CfgListContainer.LayoutOrder = 4
    CfgListContainer.Parent = ConfigsCard

    local ClLayout = Instance.new("UIListLayout", CfgListContainer)
    ClLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ClLayout.Padding = UDim.new(0, 8)

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
            btn.BackgroundColor3 = isSel and Color3.fromRGB(99, 102, 241) or Color3.fromRGB(22, 26, 38)
            btn.TextColor3 = isSel and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(140, 145, 165)
            local st = btn:FindFirstChildOfClass("UIStroke")
            if st then st.Color = isSel and Color3.fromRGB(165, 180, 252) or Color3.fromRGB(42, 48, 70) end
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
            emptyLabel.Size = UDim2.new(1, 0, 0, 36)
            emptyLabel.BackgroundTransparency = 1
            emptyLabel.Font = Enum.Font.GothamMedium
            emptyLabel.TextSize = 11
            emptyLabel.TextColor3 = Color3.fromRGB(130, 138, 160)
            emptyLabel.Text = (query ~= "") and ("Brak konfiguracji pasujących do: '" .. query .. "'") or "Brak zapisanych profili. Wpisz nazwę powyżej i kliknij '+ Zapisz Config'."
            emptyLabel.Parent = CfgListContainer
            return
        end

        for idx, item in ipairs(items) do
            local Card = Instance.new("Frame")
            Card.Name = item.Name
            Card.Size = UDim2.new(1, 0, 0, 40)
            Card.BackgroundColor3 = Color3.fromRGB(20, 24, 36)
            Card.LayoutOrder = idx
            Card.Parent = CfgListContainer
            Instance.new("UICorner", Card).CornerRadius = UDim.new(0, 10)

            local cStrk = Instance.new("UIStroke", Card)
            cStrk.Color = Color3.fromRGB(42, 48, 70)
            cStrk.Thickness = 1

            local CIco = Instance.new("ImageLabel")
            CIco.Size = UDim2.new(0, 16, 0, 16)
            CIco.Position = UDim2.new(0, 10, 0.5, 0)
            CIco.AnchorPoint = Vector2.new(0, 0.5)
            CIco.BackgroundTransparency = 1
            CIco.ImageColor3 = (item.Type == "public") and Color3.fromRGB(56, 189, 248) or Color3.fromRGB(129, 140, 248)
            CIco.Parent = Card
            if Icons and Icons.Apply then Icons:Apply(CIco, item.Type == "public" and "cloud" or "hard-drive") end

            local isLocal = (item.Type == "local")

            local NameLbl = Instance.new("TextLabel")
            NameLbl.Size = UDim2.new(1, isLocal and -240 or -150, 1, 0)
            NameLbl.Position = UDim2.new(0, 34, 0, 0)
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
            Badge.Size = UDim2.new(0, 50, 0, 20)
            Badge.Position = UDim2.new(1, isLocal and -148 or -62, 0.5, 0)
            Badge.AnchorPoint = Vector2.new(1, 0.5)
            Badge.BackgroundColor3 = (item.Type == "public") and Color3.fromRGB(18, 32, 54) or Color3.fromRGB(18, 42, 30)
            Badge.Parent = Card
            Instance.new("UICorner", Badge).CornerRadius = UDim.new(0, 6)

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
                SaveItemBtn.Size = UDim2.new(0, 48, 0, 26)
                SaveItemBtn.Position = UDim2.new(1, -94, 0.5, 0)
                SaveItemBtn.AnchorPoint = Vector2.new(1, 0.5)
                SaveItemBtn.Text = "Save"
                SaveItemBtn.Font = Enum.Font.GothamBold
                SaveItemBtn.TextSize = 10
                SaveItemBtn.BackgroundColor3 = Color3.fromRGB(30, 36, 52)
                SaveItemBtn.TextColor3 = Color3.fromRGB(220, 225, 245)
                SaveItemBtn.AutoButtonColor = false
                SaveItemBtn.Parent = Card
                Instance.new("UICorner", SaveItemBtn).CornerRadius = UDim.new(0, 6)

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
            LoadItemBtn.Size = UDim2.new(0, 48, 0, 26)
            LoadItemBtn.Position = UDim2.new(1, isLocal and -40 or -6, 0.5, 0)
            LoadItemBtn.AnchorPoint = Vector2.new(1, 0.5)
            LoadItemBtn.Text = "Load"
            LoadItemBtn.Font = Enum.Font.GothamBold
            LoadItemBtn.TextSize = 10
            LoadItemBtn.BackgroundColor3 = Color3.fromRGB(99, 102, 241)
            LoadItemBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            LoadItemBtn.AutoButtonColor = false
            LoadItemBtn.Parent = Card
            Instance.new("UICorner", LoadItemBtn).CornerRadius = UDim.new(0, 6)

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
                DelBtn.Size = UDim2.new(0, 28, 0, 26)
                DelBtn.Position = UDim2.new(1, -6, 0.5, 0)
                DelBtn.AnchorPoint = Vector2.new(1, 0.5)
                DelBtn.Text = ""
                DelBtn.BackgroundColor3 = Color3.fromRGB(225, 29, 72)
                DelBtn.AutoButtonColor = false
                DelBtn.Parent = Card
                Instance.new("UICorner", DelBtn).CornerRadius = UDim.new(0, 6)

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