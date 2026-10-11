local Settings = {}

-- Serwisy
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")
local TweenService = game:GetService("TweenService")

local baseUrl = "https://raw.githubusercontent.com/xxCichyxx/MenuTest/refs/heads/main/src/"

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
                    local chunk = loadstring(data)
                    if chunk then return chunk() end
                end
            end
        end
    end
    local cacheBuster = (remoteUrl:find("%?") and "&" or "?") .. "_nocache=" .. tostring(os.time()) .. "_" .. tostring(math.random(10000, 99999))
    local ok, res = pcall(function() return game:HttpGet(remoteUrl .. cacheBuster) end)
    if ok and res then
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

    local ToggleElement = passedToggle
    if not ToggleElement then
        ToggleElement = safeLoadSub("elements/Toggle.lua", baseUrl .. "elements/Toggle.lua")
    end

    -- Ensure WindowAPI is available before creating Settings tab
    local TabAPI
    if UI.WindowAPI and typeof(UI.WindowAPI.CreateTab) == "function" then
        TabAPI = UI.WindowAPI:CreateTab("Settings", "settings", order or 999)
    else
        warn("[Settings] UI.WindowAPI is unavailable; cannot create Settings tab.")
        return
    end
    local Page = TabAPI.Page -- Pobieramy stronę z obiektu API

    local ThemeManager = UI.ThemeManager

    local function getColor(colorTable)
        return Color3.fromRGB(unpack(colorTable))
    end

    local PageLayout = Page:FindFirstChildOfClass("UIListLayout")
    if PageLayout then
        PageLayout.SortOrder = Enum.SortOrder.LayoutOrder
        PageLayout.Padding = UDim.new(0, 20)
    end

    local PagePadding = Instance.new("UIPadding")
    PagePadding.PaddingTop = UDim.new(0, 20)
    PagePadding.PaddingRight = UDim.new(0, 20)
    PagePadding.Parent = Page

    -- Sekcja: Themes (LayoutOrder = 1)
    local ThemesSection = Instance.new("Frame")
    ThemesSection.Name = "ThemesSection"
    ThemesSection.Size = UDim2.new(1, -40, 0, 0)
    ThemesSection.AutomaticSize = Enum.AutomaticSize.Y
    ThemesSection.BackgroundTransparency = 1
    ThemesSection.LayoutOrder = 1
    ThemesSection.ZIndex = 10
    ThemesSection.Parent = Page

    local ThemesHeader = Instance.new("TextLabel")
    ThemesHeader.Text = "THEMES"
    ThemesHeader.Font = Enum.Font.GothamBold
    ThemesHeader.TextSize = 12
    ThemesHeader.Size = UDim2.new(1, 0, 0, 20)
    ThemesHeader.BackgroundTransparency = 1
    ThemesHeader.TextXAlignment = Enum.TextXAlignment.Left
    ThemesHeader.Parent = ThemesSection
    ThemeManager:Register(ThemesHeader, "TextColor3", "Text_Secondary")

    local ThemesContainer = Instance.new("Frame")
    ThemesContainer.Name = "Container"
    ThemesContainer.Size = UDim2.new(1, 0, 0, 50)
    ThemesContainer.Position = UDim2.new(0, 0, 0, 25)
    ThemesContainer.Parent = ThemesSection
    ThemesContainer.ZIndex = 10
    ThemeManager:Register(ThemesContainer, "BackgroundColor3", "Secondary")

    Instance.new("UICorner", ThemesContainer).CornerRadius = UDim.new(0, 6)
    local ThemesStroke = Instance.new("UIStroke", ThemesContainer)
    ThemesStroke.Thickness = 1
    ThemesStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    ThemeManager:Register(ThemesStroke, "Color", "Accent")

    local RefreshBtn = Instance.new("TextButton")
    RefreshBtn.Size = UDim2.new(0, 140, 0, 30)
    RefreshBtn.Position = UDim2.new(0, 10, 0.5, 0)
    RefreshBtn.AnchorPoint = Vector2.new(0, 0.5)
    RefreshBtn.Text = "   Refresh Themes"
    RefreshBtn.Font = Enum.Font.GothamMedium
    RefreshBtn.TextSize = 14
    RefreshBtn.TextXAlignment = Enum.TextXAlignment.Left
    RefreshBtn.Parent = ThemesContainer
    ThemeManager:Register(RefreshBtn, "BackgroundColor3", "Accent")
    ThemeManager:Register(RefreshBtn, "TextColor3", "Text")
    Instance.new("UICorner", RefreshBtn).CornerRadius = UDim.new(0, 6)

    local RefreshIcon = Instance.new("ImageLabel")
    RefreshIcon.Size = UDim2.new(0, 16, 0, 16)
    RefreshIcon.Position = UDim2.new(1, -10, 0.5, 0)
    RefreshIcon.AnchorPoint = Vector2.new(1, 0.5)
    RefreshIcon.BackgroundTransparency = 1
    RefreshIcon.Parent = RefreshBtn
    ThemeManager:Register(RefreshIcon, "ImageColor3", "Text")
    Icons:Apply(RefreshIcon, "refresh-cw")

    local Dropdown = Instance.new("Frame")
    Dropdown.Size = UDim2.new(1, -170, 0, 30)
    Dropdown.Position = UDim2.new(0, 160, 0.5, 0)
    Dropdown.AnchorPoint = Vector2.new(0, 0.5)
    Dropdown.ZIndex = 20
    Dropdown.Parent = ThemesContainer
    ThemeManager:Register(Dropdown, "BackgroundColor3", "Main")
    Instance.new("UICorner", Dropdown).CornerRadius = UDim.new(0, 6)

    local DropdownBtn = Instance.new("TextButton")
    DropdownBtn.Size = UDim2.new(1, 0, 1, 0)
    DropdownBtn.BackgroundTransparency = 1
    DropdownBtn.Text = "   dark"
    DropdownBtn.Font = Enum.Font.Gotham
    DropdownBtn.TextSize = 14
    DropdownBtn.TextXAlignment = Enum.TextXAlignment.Left
    DropdownBtn.ZIndex = 21
    DropdownBtn.Parent = Dropdown
    ThemeManager:Register(DropdownBtn, "TextColor3", "Text")

    local DropdownIcon = Instance.new("ImageLabel")
    DropdownIcon.Size = UDim2.new(0, 16, 0, 16)
    DropdownIcon.Position = UDim2.new(1, -10, 0.5, 0)
    DropdownIcon.AnchorPoint = Vector2.new(1, 0.5)
    DropdownIcon.BackgroundTransparency = 1
    DropdownIcon.ZIndex = 21
    DropdownIcon.Parent = Dropdown
    ThemeManager:Register(DropdownIcon, "ImageColor3", "Text_Secondary")
    Icons:Apply(DropdownIcon, "chevron-down")

    ThemesSection.ClipsDescendants = false
    ThemesContainer.ClipsDescendants = false
    Dropdown.ClipsDescendants = false

    local DropdownList = Instance.new("ScrollingFrame")
    DropdownList.Size = UDim2.new(1, 0, 0, 0)
    DropdownList.Position = UDim2.new(0, 0, 1, 5)
    DropdownList.CanvasSize = UDim2.new(0, 0, 0, 0)
    DropdownList.ScrollBarThickness = 2
    DropdownList.BackgroundTransparency = 1
    DropdownList.Visible = false
    DropdownList.ZIndex = 30
    DropdownList.Parent = Dropdown

    local ListBg = Instance.new("Frame")
    ListBg.Size = UDim2.new(1, 0, 0, 0)
    ListBg.Position = UDim2.new(0, 0, 1, 5)
    ListBg.Visible = false
    ListBg.ZIndex = 29
    ListBg.Parent = Dropdown
    ThemeManager:Register(ListBg, "BackgroundColor3", "Main")
    Instance.new("UICorner", ListBg).CornerRadius = UDim.new(0, 6)
    local ListStroke = Instance.new("UIStroke", ListBg)
    ListStroke.Thickness = 1
    ListStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    ThemeManager:Register(ListStroke, "Color", "Accent")

    local ListLayout = Instance.new("UIListLayout")
    ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ListLayout.Parent = DropdownList

    local isDropdownOpen = false

    local function ToggleDropdown()
        isDropdownOpen = not isDropdownOpen
        DropdownList.Visible = isDropdownOpen
        ListBg.Visible = isDropdownOpen

        if isDropdownOpen then
            local count = #DropdownList:GetChildren() - 1
            local height = math.min(count * 30, 150)
            DropdownList.Size = UDim2.new(1, 0, 0, height)
            ListBg.Size = UDim2.new(1, 0, 0, height)
            DropdownList.CanvasSize = UDim2.new(0, 0, 0, count * 30)
            Icons:Apply(DropdownIcon, "chevron-up")
        else
            Icons:Apply(DropdownIcon, "chevron-down")
        end
    end

    DropdownBtn.MouseButton1Click:Connect(ToggleDropdown)

    local function LoadThemes()
        for _, child in pairs(DropdownList:GetChildren()) do
            if child:IsA("TextButton") then child:Destroy() end
        end

        local count = 0
        local function addThemeItem(themeName, callback)
            count = count + 1
            local Item = Instance.new("TextButton")
            Item.Size = UDim2.new(1, 0, 0, 30)
            Item.BackgroundTransparency = 1
            Item.Text = "   " .. themeName
            Item.Font = Enum.Font.Gotham
            Item.TextSize = 14
            Item.TextXAlignment = Enum.TextXAlignment.Left
            Item.ZIndex = 31
            Item.Parent = DropdownList
            ThemeManager:Register(Item, "TextColor3", "Text")

            Item.MouseButton1Click:Connect(function()
                DropdownBtn.Text = "   " .. themeName
                ToggleDropdown()
                callback()
            end)
        end

        local themesFolder = mainFolder .. "/themes"
        if typeof(isfolder) == "function" and isfolder(themesFolder) and typeof(listfiles) == "function" then
            for _, file in pairs(listfiles(themesFolder)) do
                if file:sub(-5) == ".json" then
                    local themeName = file:match("([^/\\]+)%.json$") or file:match("([^/\\]+)$")
                    addThemeItem(themeName, function()
                        local success, data = pcall(function()
                            return HttpService:JSONDecode(readfile(file))
                        end)
                        if success and type(data) == "table" then
                            ThemeManager:Apply(data)
                        end
                    end)
                end
            end
        end

        if count == 0 then
            local builtins = {
                ["dark"] = { Main = {15, 15, 15}, Secondary = {25, 25, 25}, Accent = {60, 60, 60}, Accent2 = {40, 40, 40}, Success = {100, 255, 100}, Text = {255, 255, 255}, Text_Secondary = {160, 160, 160}, Close = {200, 50, 50} },
                ["light"] = { Main = {245, 245, 248}, Secondary = {232, 232, 238}, Accent = {195, 195, 205}, Accent2 = {215, 215, 225}, Success = {45, 175, 75}, Text = {20, 20, 25}, Text_Secondary = {110, 110, 125}, Close = {220, 55, 55} },
                ["midnight"] = { Main = {10, 13, 20}, Secondary = {16, 21, 32}, Accent = {42, 54, 78}, Accent2 = {25, 34, 50}, Success = {80, 230, 160}, Text = {240, 246, 255}, Text_Secondary = {130, 148, 178}, Close = {235, 70, 85} },
                ["amethyst"] = { Main = {16, 12, 24}, Secondary = {26, 20, 38}, Accent = {68, 50, 98}, Accent2 = {40, 28, 58}, Success = {130, 245, 160}, Text = {250, 244, 255}, Text_Secondary = {172, 150, 198}, Close = {235, 60, 90} }
            }
            for _, tName in ipairs({"dark", "light", "midnight", "amethyst"}) do
                addThemeItem(tName, function()
                    if builtins[tName] then ThemeManager:Apply(builtins[tName]) end
                end)
            end
        end
    end

    RefreshBtn.MouseButton1Click:Connect(function()
        LoadThemes()
        local tween = TweenService:Create(RefreshIcon, TweenInfo.new(0.5), {Rotation = 360})
        tween:Play()
        tween.Completed:Connect(function() RefreshIcon.Rotation = 0 end)
    end)

    LoadThemes()

    -- Sekcja: Other Settings (LayoutOrder = 2)
    local SettingsSection = Instance.new("Frame")
    SettingsSection.Name = "SettingsSection"
    SettingsSection.Size = UDim2.new(1, -40, 0, 0)
    SettingsSection.AutomaticSize = Enum.AutomaticSize.Y
    SettingsSection.BackgroundTransparency = 1
    SettingsSection.LayoutOrder = 2
    SettingsSection.ZIndex = 1
    SettingsSection.Parent = Page

    local SettingsHeader = Instance.new("TextLabel")
    SettingsHeader.Text = "OPTIONS"
    SettingsHeader.Font = Enum.Font.GothamBold
    SettingsHeader.TextSize = 12
    SettingsHeader.Size = UDim2.new(1, 0, 0, 20)
    SettingsHeader.BackgroundTransparency = 1
    SettingsHeader.TextXAlignment = Enum.TextXAlignment.Left
    SettingsHeader.Parent = SettingsSection
    ThemeManager:Register(SettingsHeader, "TextColor3", "Text_Secondary")

    local SettingsContainer = Instance.new("Frame")
    SettingsContainer.Name = "Container"
    SettingsContainer.Size = UDim2.new(1, 0, 0, 0)
    SettingsContainer.AutomaticSize = Enum.AutomaticSize.Y
    SettingsContainer.Position = UDim2.new(0, 0, 0, 25)
    SettingsContainer.Parent = SettingsSection
    ThemeManager:Register(SettingsContainer, "BackgroundColor3", "Secondary")

    Instance.new("UICorner", SettingsContainer).CornerRadius = UDim.new(0, 6)
    local SettingsStroke = Instance.new("UIStroke", SettingsContainer)
    SettingsStroke.Thickness = 1
    SettingsStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    ThemeManager:Register(SettingsStroke, "Color", "Accent")

    -- // ZMIANA: Używamy UIGridLayout dla opcji
    local SettingsGridLayout = Instance.new("UIGridLayout")
    SettingsGridLayout.CellSize = UDim2.new(0.5, -5, 0, 35)
    SettingsGridLayout.CellPadding = UDim2.new(0, 10, 0, 10)
    SettingsGridLayout.SortOrder = Enum.SortOrder.LayoutOrder
    SettingsGridLayout.Parent = SettingsContainer

    local SettingsPadding = Instance.new("UIPadding")
    SettingsPadding.PaddingTop = UDim.new(0, 10)
    SettingsPadding.PaddingBottom = UDim.new(0, 10)
    SettingsPadding.PaddingLeft = UDim.new(0, 10)
    SettingsPadding.PaddingRight = UDim.new(0, 10)
    SettingsPadding.Parent = SettingsContainer

    -- AntiAFK & Keybinds Overlay wewnątrz SettingsContainer
    local antiAfkConnection = nil
    local function enableAntiAfk()
        if antiAfkConnection then antiAfkConnection:Disconnect() end
        antiAfkConnection = Players.LocalPlayer.Idled:Connect(function()
            pcall(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
        end)
    end
    local function disableAntiAfk()
        if antiAfkConnection then
            antiAfkConnection:Disconnect()
            antiAfkConnection = nil
        end
    end

    -- Włącz AntiAFK natychmiast od startu sesji
    enableAntiAfk()
    if UI.MenuConfig then
        UI.MenuConfig["AntiAfk"] = true
    end

    ToggleElement({
        Name = "AntiAFK",
        CurrentValue = true,
        Default = true,
        Flag = "AntiAfk",
        Callback = function(Value)
            if Value then
                enableAntiAfk()
            else
                disableAntiAfk()
            end
        end,
    }, ThemeManager, SettingsContainer, UI.MenuConfig, UI.SaveMenuConfig, UI.AddConnection)

    -- Keybinds Overlay (Minecraft style)
    local isOverlayActive = false
    if UI.MenuConfig and UI.MenuConfig["KeybindsOverlay"] ~= nil then
        isOverlayActive = UI.MenuConfig["KeybindsOverlay"]
    end
    if UI.SetKeybindsOverlayVisible then
        UI:SetKeybindsOverlayVisible(isOverlayActive)
    end

    ToggleElement({
        Name = "Keybinds",
        CurrentValue = isOverlayActive,
        Flag = "KeybindsOverlay",
        Callback = function(Value)
            if UI.SetKeybindsOverlayVisible then
                UI:SetKeybindsOverlayVisible(Value)
            end
        end,
    }, ThemeManager, SettingsContainer, UI.MenuConfig, UI.SaveMenuConfig, UI.AddConnection)

    -- Przycisk konfiguracji klawisza otwierania Menu (Menu Keybind)
    -- Stylizowany spójnie z motywem (dynamiczne kolory ThemeManager)
    local KeybindWidget = Instance.new("TextButton")
    KeybindWidget.Name = "MenuKeybindWidget"
    KeybindWidget.Size = UDim2.new(0.5, -5, 0, 35)
    KeybindWidget.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    KeybindWidget.BackgroundTransparency = 0
    KeybindWidget.Text = ""
    KeybindWidget.Parent = SettingsContainer
    Instance.new("UICorner", KeybindWidget).CornerRadius = UDim.new(0, 8)

    local KeybindStroke = Instance.new("UIStroke", KeybindWidget)
    KeybindStroke.Color = Color3.fromRGB(55, 55, 60)
    KeybindStroke.Thickness = 1
    KeybindStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    local KeybindLabel = Instance.new("TextLabel")
    KeybindLabel.Name = "Label"
    KeybindLabel.Text = "Menu Keybind"
    KeybindLabel.Font = Enum.Font.GothamMedium
    KeybindLabel.TextSize = 12
    KeybindLabel.TextColor3 = Color3.fromRGB(220, 220, 225)
    KeybindLabel.TextXAlignment = Enum.TextXAlignment.Left
    KeybindLabel.Size = UDim2.new(1, -90, 1, 0)
    KeybindLabel.Position = UDim2.new(0, 10, 0, 0)
    KeybindLabel.BackgroundTransparency = 1
    KeybindLabel.Parent = KeybindWidget

    local KeybindBadge = Instance.new("TextLabel")
    KeybindBadge.Name = "Badge"
    local initialKey = (UI and UI.CurrentMenuKeyName) or "K"
    KeybindBadge.Text = "[" .. initialKey .. "]"
    KeybindBadge.Font = Enum.Font.GothamBold
    KeybindBadge.TextSize = 11
    KeybindBadge.TextColor3 = Color3.fromRGB(160, 160, 165)
    KeybindBadge.Size = UDim2.new(0, 36, 0, 22)
    KeybindBadge.AutomaticSize = Enum.AutomaticSize.X
    KeybindBadge.Position = UDim2.new(1, -10, 0.5, 0)
    KeybindBadge.AnchorPoint = Vector2.new(1, 0.5)
    KeybindBadge.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
    KeybindBadge.Parent = KeybindWidget
    Instance.new("UICorner", KeybindBadge).CornerRadius = UDim.new(0, 5)

    local BadgeStroke = Instance.new("UIStroke", KeybindBadge)
    BadgeStroke.Color = Color3.fromRGB(55, 55, 62)
    BadgeStroke.Thickness = 1
    BadgeStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    local BadgePad = Instance.new("UIPadding")
    BadgePad.PaddingLeft = UDim.new(0, 6)
    BadgePad.PaddingRight = UDim.new(0, 6)
    BadgePad.Parent = KeybindBadge

    ThemeManager:Register(KeybindWidget, "BackgroundColor3", "Main")
    ThemeManager:Register(KeybindStroke, "Color", "Accent")
    ThemeManager:Register(KeybindLabel, "TextColor3", "Text")
    ThemeManager:Register(KeybindBadge, "BackgroundColor3", "Secondary")
    ThemeManager:Register(KeybindBadge, "TextColor3", "Text_Secondary")
    ThemeManager:Register(BadgeStroke, "Color", "Accent")

    local function updateBadgeNormal()
        KeybindBadge.TextColor3 = ThemeManager:GetColor("Text_Secondary") or Color3.fromRGB(160, 160, 165)
        KeybindBadge.BackgroundColor3 = ThemeManager:GetColor("Secondary") or Color3.fromRGB(35, 35, 42)
        BadgeStroke.Color = ThemeManager:GetColor("Accent") or Color3.fromRGB(55, 55, 62)
    end
    local function updateBadgeBinding()
        KeybindBadge.TextColor3 = ThemeManager:GetColor("Text") or Color3.fromRGB(255, 255, 255)
        KeybindBadge.BackgroundColor3 = ThemeManager:GetColor("Accent2") or Color3.fromRGB(45, 45, 55)
        BadgeStroke.Color = ThemeManager:GetColor("Text") or Color3.fromRGB(100, 100, 110)
    end

    local isBinding = false
    KeybindWidget.MouseButton1Click:Connect(function()
        if isBinding then return end
        isBinding = true
        KeybindBadge.Text = "[...]"
        updateBadgeBinding()

        local bindConn
        bindConn = game:GetService("UserInputService").InputBegan:Connect(function(input, gpe)
            if input.UserInputType == Enum.UserInputType.Keyboard then
                bindConn:Disconnect()
                isBinding = false
                local newKey = input.KeyCode
                if newKey == Enum.KeyCode.Backspace or newKey == Enum.KeyCode.Delete then
                    newKey = Enum.KeyCode.K
                end
                KeybindBadge.Text = "[" .. newKey.Name .. "]"
                updateBadgeNormal()
                if UI and UI.SetMenuKeybind then
                    UI:SetMenuKeybind(newKey)
                end
            end
        end)
    end)

    if UI then
        UI.OnMenuKeybindChanged = function(newKey)
            local kName = (typeof(newKey) == "EnumItem" and newKey.Name) or tostring(newKey)
            KeybindBadge.Text = "[" .. kName .. "]"
            updateBadgeNormal()
        end
    end

    if ThemeManager and ThemeManager.OnThemeChanged then
        ThemeManager:OnThemeChanged(function()
            if not isBinding then
                updateBadgeNormal()
            end
        end)
    end

    -- ============================================================
    -- Sekcja: Configs (LayoutOrder = 3)
    -- ============================================================
    local ConfigsSection = Instance.new("Frame")
    ConfigsSection.Name = "ConfigsSection"
    ConfigsSection.Size = UDim2.new(1, -40, 0, 0)
    ConfigsSection.AutomaticSize = Enum.AutomaticSize.Y
    ConfigsSection.BackgroundTransparency = 1
    ConfigsSection.LayoutOrder = 3
    ConfigsSection.ZIndex = 1
    ConfigsSection.Parent = Page

    local ConfigsHeader = Instance.new("TextLabel")
    ConfigsHeader.Text = "CONFIGS"
    ConfigsHeader.Font = Enum.Font.GothamBold
    ConfigsHeader.TextSize = 12
    ConfigsHeader.Size = UDim2.new(1, 0, 0, 20)
    ConfigsHeader.BackgroundTransparency = 1
    ConfigsHeader.TextXAlignment = Enum.TextXAlignment.Left
    ConfigsHeader.Parent = ConfigsSection
    ThemeManager:Register(ConfigsHeader, "TextColor3", "Text_Secondary")

    local ConfigsContainer = Instance.new("Frame")
    ConfigsContainer.Name = "Container"
    ConfigsContainer.Size = UDim2.new(1, 0, 0, 0)
    ConfigsContainer.AutomaticSize = Enum.AutomaticSize.Y
    ConfigsContainer.Position = UDim2.new(0, 0, 0, 25)
    ConfigsContainer.Parent = ConfigsSection
    ThemeManager:Register(ConfigsContainer, "BackgroundColor3", "Secondary")

    Instance.new("UICorner", ConfigsContainer).CornerRadius = UDim.new(0, 6)
    local ConfigsStroke = Instance.new("UIStroke", ConfigsContainer)
    ConfigsStroke.Thickness = 1
    ConfigsStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    ThemeManager:Register(ConfigsStroke, "Color", "Accent")

    local ConfigsListLayout = Instance.new("UIListLayout")
    ConfigsListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ConfigsListLayout.Padding = UDim.new(0, 8)
    ConfigsListLayout.Parent = ConfigsContainer

    local ConfigsPadding = Instance.new("UIPadding")
    ConfigsPadding.PaddingTop = UDim.new(0, 10)
    ConfigsPadding.PaddingBottom = UDim.new(0, 10)
    ConfigsPadding.PaddingLeft = UDim.new(0, 10)
    ConfigsPadding.PaddingRight = UDim.new(0, 10)
    ConfigsPadding.Parent = ConfigsContainer

    -- Row 1: Search & Filter Tabs
    local TopBar = Instance.new("Frame")
    TopBar.Name = "TopBar"
    TopBar.Size = UDim2.new(1, 0, 0, 32)
    TopBar.BackgroundTransparency = 1
    TopBar.LayoutOrder = 1
    TopBar.Parent = ConfigsContainer

    local SearchBoxFrame = Instance.new("Frame")
    SearchBoxFrame.Name = "SearchBox"
    SearchBoxFrame.Size = UDim2.new(1, -170, 1, 0)
    SearchBoxFrame.Position = UDim2.new(0, 0, 0, 0)
    ThemeManager:Register(SearchBoxFrame, "BackgroundColor3", "Main")
    Instance.new("UICorner", SearchBoxFrame).CornerRadius = UDim.new(0, 6)
    local SearchStroke = Instance.new("UIStroke", SearchBoxFrame)
    SearchStroke.Thickness = 1
    SearchStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    ThemeManager:Register(SearchStroke, "Color", "Accent")
    SearchBoxFrame.Parent = TopBar

    local SearchIcon = Instance.new("ImageLabel")
    SearchIcon.Size = UDim2.new(0, 16, 0, 16)
    SearchIcon.Position = UDim2.new(0, 8, 0.5, 0)
    SearchIcon.AnchorPoint = Vector2.new(0, 0.5)
    SearchIcon.BackgroundTransparency = 1
    SearchIcon.Parent = SearchBoxFrame
    ThemeManager:Register(SearchIcon, "ImageColor3", "Text_Secondary")
    Icons:Apply(SearchIcon, "search")

    local SearchInput = Instance.new("TextBox")
    SearchInput.Size = UDim2.new(1, -30, 1, 0)
    SearchInput.Position = UDim2.new(0, 26, 0, 0)
    SearchInput.BackgroundTransparency = 1
    SearchInput.PlaceholderText = "Search configs..."
    SearchInput.Text = ""
    SearchInput.Font = Enum.Font.Gotham
    SearchInput.TextSize = 13
    SearchInput.TextXAlignment = Enum.TextXAlignment.Left
    ThemeManager:Register(SearchInput, "TextColor3", "Text")
    ThemeManager:Register(SearchInput, "PlaceholderColor3", "Text_Secondary")
    SearchInput.Parent = SearchBoxFrame

    -- Filter Tabs (All / Local / Public)
    local FilterContainer = Instance.new("Frame")
    FilterContainer.Name = "FilterContainer"
    FilterContainer.Size = UDim2.new(0, 162, 1, 0)
    FilterContainer.Position = UDim2.new(1, -162, 0, 0)
    FilterContainer.BackgroundTransparency = 1
    FilterContainer.Parent = TopBar

    local FilterListLayout = Instance.new("UIListLayout")
    FilterListLayout.FillDirection = Enum.FillDirection.Horizontal
    FilterListLayout.Padding = UDim.new(0, 4)
    FilterListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    FilterListLayout.Parent = FilterContainer

    local activeFilter = "all"
    local filterButtons = {}

    local function createFilterTab(filterKey, filterLabel, order)
        local btn = Instance.new("TextButton")
        btn.Name = filterKey
        btn.Size = UDim2.new(0, 50, 1, 0)
        btn.Text = filterLabel
        btn.Font = Enum.Font.GothamMedium
        btn.TextSize = 11
        btn.LayoutOrder = order
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
        btn.Parent = FilterContainer
        filterButtons[filterKey] = btn
        return btn
    end

    local allTabBtn    = createFilterTab("all", "All", 1)
    local localTabBtn  = createFilterTab("local", "Local", 2)
    local publicTabBtn = createFilterTab("public", "Public", 3)

    -- Row 2: Save New Local Config
    local SaveBar = Instance.new("Frame")
    SaveBar.Name = "SaveBar"
    SaveBar.Size = UDim2.new(1, 0, 0, 32)
    SaveBar.BackgroundTransparency = 1
    SaveBar.LayoutOrder = 2
    SaveBar.Parent = ConfigsContainer

    local NameBoxFrame = Instance.new("Frame")
    NameBoxFrame.Name = "NameBox"
    NameBoxFrame.Size = UDim2.new(1, -108, 1, 0)
    NameBoxFrame.Position = UDim2.new(0, 0, 0, 0)
    ThemeManager:Register(NameBoxFrame, "BackgroundColor3", "Main")
    Instance.new("UICorner", NameBoxFrame).CornerRadius = UDim.new(0, 6)
    local NameStroke = Instance.new("UIStroke", NameBoxFrame)
    NameStroke.Thickness = 1
    NameStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    ThemeManager:Register(NameStroke, "Color", "Accent")
    NameBoxFrame.Parent = SaveBar

    local NameInput = Instance.new("TextBox")
    NameInput.Size = UDim2.new(1, -16, 1, 0)
    NameInput.Position = UDim2.new(0, 8, 0, 0)
    NameInput.BackgroundTransparency = 1
    NameInput.PlaceholderText = "New config name..."
    NameInput.Text = ""
    NameInput.Font = Enum.Font.Gotham
    NameInput.TextSize = 13
    NameInput.TextXAlignment = Enum.TextXAlignment.Left
    ThemeManager:Register(NameInput, "TextColor3", "Text")
    ThemeManager:Register(NameInput, "PlaceholderColor3", "Text_Secondary")
    NameInput.Parent = NameBoxFrame

    local SaveBtn = Instance.new("TextButton")
    SaveBtn.Name = "SaveBtn"
    SaveBtn.Size = UDim2.new(0, 100, 1, 0)
    SaveBtn.Position = UDim2.new(1, -100, 0, 0)
    SaveBtn.Text = "Save Config"
    SaveBtn.Font = Enum.Font.GothamMedium
    SaveBtn.TextSize = 12
    ThemeManager:Register(SaveBtn, "BackgroundColor3", "Accent")
    ThemeManager:Register(SaveBtn, "TextColor3", "Text")
    Instance.new("UICorner", SaveBtn).CornerRadius = UDim.new(0, 6)
    SaveBtn.Parent = SaveBar

    -- Row 3: Configs List (ScrollingFrame)
    local ListFrame = Instance.new("ScrollingFrame")
    ListFrame.Name = "ListFrame"
    ListFrame.Size = UDim2.new(1, 0, 0, 155)
    ListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    ListFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    ListFrame.ScrollBarThickness = 2
    ListFrame.BackgroundTransparency = 1
    ListFrame.LayoutOrder = 3
    ListFrame.Parent = ConfigsContainer

    local ListCardsLayout = Instance.new("UIListLayout")
    ListCardsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ListCardsLayout.Padding = UDim.new(0, 6)
    ListCardsLayout.Parent = ListFrame

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
        for _, c in ipairs(ListFrame:GetChildren()) do
            if c:IsA("Frame") or c:IsA("TextLabel") then c:Destroy() end
        end

        for fKey, btn in pairs(filterButtons) do
            if fKey == activeFilter then
                ThemeManager:Register(btn, "BackgroundColor3", "Accent")
                ThemeManager:Register(btn, "TextColor3", "Text")
            else
                ThemeManager:Register(btn, "BackgroundColor3", "Main")
                ThemeManager:Register(btn, "TextColor3", "Text_Secondary")
            end
        end

        local query = SearchInput.Text:lower():gsub("^%s+", ""):gsub("%s+$", "")
        local items = {}

        -- 1. Scan Public configs dla danego GameId (src/configs/<GameId>/)
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
                                            if decOk and type(decData) == "table" then
                                                return decData
                                            end
                                        end
                                    end
                                end
                            end
                            local url = baseUrl .. "configs/" .. GameId .. "/" .. pName .. ".json"
                            local ok, res = pcall(function() return game:HttpGet(url) end)
                            if ok and res and #res > 0 then
                                local decOk, decData = pcall(function() return HttpService:JSONDecode(res) end)
                                if decOk and type(decData) == "table" then
                                    return decData
                                end
                            end
                            return nil
                        end
                    })
                end
            end
        end

        -- 2. Scan Local configs na PC dla tego GameId
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
                                                    if decOk and type(decData) == "table" then
                                                        return decData
                                                    end
                                                end
                                            end
                                            return nil
                                        end,
                                        Delete = function()
                                            if typeof(delfile) == "function" then
                                                pcall(delfile, file)
                                            end
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
            emptyLabel.Size = UDim2.new(1, -20, 0, 48)
            emptyLabel.Position = UDim2.new(0, 10, 0, 10)
            emptyLabel.BackgroundTransparency = 1
            emptyLabel.Font = Enum.Font.GothamMedium
            emptyLabel.TextSize = 12
            emptyLabel.TextWrapped = true

            if query ~= "" then
                emptyLabel.Text = "Brak konfiguracji pasujących do: '" .. query .. "'"
            elseif activeFilter == "public" then
                emptyLabel.Text = "Brak publicznych konfiguracji Online dla gry (ID: " .. GameId .. ").\nMożesz stworzyć i zapisać własny config w sekcji Local."
            elseif activeFilter == "local" then
                emptyLabel.Text = "Brak lokalnych konfiguracji na PC dla gry (ID: " .. GameId .. ").\nWpisz nazwę powyżej i kliknij 'Save Config'."
            else
                emptyLabel.Text = "Brak konfiguracji dla gry (ID: " .. GameId .. ").\nWpisz nazwę powyżej i zapisz swój własny config na PC!"
            end

            ThemeManager:Register(emptyLabel, "TextColor3", "Text_Secondary")
            emptyLabel.Parent = ListFrame
            return
        end

        for idx, item in ipairs(items) do
            local Card = Instance.new("Frame")
            Card.Name = item.Name
            Card.Size = UDim2.new(1, 0, 0, 36)
            Card.LayoutOrder = idx
            ThemeManager:Register(Card, "BackgroundColor3", "Main")
            Instance.new("UICorner", Card).CornerRadius = UDim.new(0, 6)

            local CardStroke = Instance.new("UIStroke", Card)
            CardStroke.Thickness = 1
            CardStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            ThemeManager:Register(CardStroke, "Color", "Accent")
            Card.Parent = ListFrame

            local CardIcon = Instance.new("ImageLabel")
            CardIcon.Size = UDim2.new(0, 16, 0, 16)
            CardIcon.Position = UDim2.new(0, 10, 0.5, 0)
            CardIcon.AnchorPoint = Vector2.new(0, 0.5)
            CardIcon.BackgroundTransparency = 1
            CardIcon.Parent = Card
            ThemeManager:Register(CardIcon, "ImageColor3", "Text_Secondary")
            Icons:Apply(CardIcon, item.Type == "public" and "cloud" or "hard-drive")

            local NameLabel = Instance.new("TextLabel")
            NameLabel.Size = UDim2.new(1, -190, 1, 0)
            NameLabel.Position = UDim2.new(0, 34, 0, 0)
            NameLabel.BackgroundTransparency = 1
            NameLabel.Font = Enum.Font.GothamMedium
            NameLabel.TextSize = 13
            NameLabel.TextXAlignment = Enum.TextXAlignment.Left
            NameLabel.Text = item.Name
            ThemeManager:Register(NameLabel, "TextColor3", "Text")
            NameLabel.Parent = Card

            local Badge = Instance.new("Frame")
            Badge.Size = UDim2.new(0, 48, 0, 18)
            Badge.Position = UDim2.new(1, item.Type == "local" and -95 or -65, 0.5, 0)
            Badge.AnchorPoint = Vector2.new(1, 0.5)
            Badge.BackgroundColor3 = item.Type == "public" and Color3.fromRGB(25, 40, 70) or Color3.fromRGB(25, 60, 35)
            Instance.new("UICorner", Badge).CornerRadius = UDim.new(0, 4)
            Badge.Parent = Card

            local BadgeLabel = Instance.new("TextLabel")
            BadgeLabel.Size = UDim2.new(1, 0, 1, 0)
            BadgeLabel.BackgroundTransparency = 1
            BadgeLabel.Font = Enum.Font.GothamBold
            BadgeLabel.TextSize = 10
            BadgeLabel.Text = item.Type == "public" and "PUBLIC" or "LOCAL"
            BadgeLabel.TextColor3 = item.Type == "public" and Color3.fromRGB(130, 190, 255) or Color3.fromRGB(130, 255, 160)
            BadgeLabel.Parent = Badge

            local LoadBtn = Instance.new("TextButton")
            LoadBtn.Size = UDim2.new(0, 52, 0, 24)
            LoadBtn.Position = UDim2.new(1, item.Type == "local" and -36 or -6, 0.5, 0)
            LoadBtn.AnchorPoint = Vector2.new(1, 0.5)
            LoadBtn.Text = "Load"
            LoadBtn.Font = Enum.Font.GothamMedium
            LoadBtn.TextSize = 11
            ThemeManager:Register(LoadBtn, "BackgroundColor3", "Accent")
            ThemeManager:Register(LoadBtn, "TextColor3", "Text")
            Instance.new("UICorner", LoadBtn).CornerRadius = UDim.new(0, 4)
            LoadBtn.Parent = Card

            LoadBtn.MouseButton1Click:Connect(function()
                local data = item.Load()
                if data then
                    applyConfigData(data)
                    LoadBtn.Text = "Loaded!"
                    task.delay(1.2, function()
                        if LoadBtn and LoadBtn.Parent then LoadBtn.Text = "Load" end
                    end)
                else
                    LoadBtn.Text = "Error"
                    task.delay(1.2, function()
                        if LoadBtn and LoadBtn.Parent then LoadBtn.Text = "Load" end
                    end)
                end
            end)

            if item.Type == "local" and item.Delete then
                local DelBtn = Instance.new("TextButton")
                DelBtn.Size = UDim2.new(0, 24, 0, 24)
                DelBtn.Position = UDim2.new(1, -6, 0.5, 0)
                DelBtn.AnchorPoint = Vector2.new(1, 0.5)
                DelBtn.Text = "✕"
                DelBtn.Font = Enum.Font.GothamBold
                DelBtn.TextSize = 11
                ThemeManager:Register(DelBtn, "BackgroundColor3", "Close")
                ThemeManager:Register(DelBtn, "TextColor3", "Text")
                Instance.new("UICorner", DelBtn).CornerRadius = UDim.new(0, 4)
                DelBtn.Parent = Card

                DelBtn.MouseButton1Click:Connect(function()
                    item.Delete()
                    RenderConfigs()
                end)
            end
        end
    end

    allTabBtn.MouseButton1Click:Connect(function() activeFilter = "all"; RenderConfigs() end)
    localTabBtn.MouseButton1Click:Connect(function() activeFilter = "local"; RenderConfigs() end)
    publicTabBtn.MouseButton1Click:Connect(function() activeFilter = "public"; RenderConfigs() end)
    SearchInput:GetPropertyChangedSignal("Text"):Connect(function() RenderConfigs() end)

    SaveBtn.MouseButton1Click:Connect(function()
        local rawText = NameInput.Text:gsub("^%s+", ""):gsub("%s+$", "")
        if #rawText == 0 then
            NameInput.PlaceholderText = "Enter name first!"
            task.delay(1.5, function()
                if NameInput and NameInput.Parent then NameInput.PlaceholderText = "New config name..." end
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
        SaveBtn.Text = "Saved!"
        task.delay(1.2, function()
            if SaveBtn and SaveBtn.Parent then SaveBtn.Text = "Save Config" end
        end)
        RenderConfigs()
    end)

    RenderConfigs()
end

return Settings