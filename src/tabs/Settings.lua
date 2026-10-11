local Settings = {}

-- Serwisy
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")
local TweenService = game:GetService("TweenService")

local baseUrl = "https://raw.githubusercontent.com/xxCichyxx/MenuTest/refs/heads/main/src/"

local function safeLoadSub(relativePath, remoteUrl)
    if typeof(readfile) == "function" then
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
    local ok, res = pcall(function() return game:HttpGet(remoteUrl) end)
    if ok and res then
        local chunk = loadstring(res)
        if chunk then return chunk() end
    end
    return nil
end

function Settings:Render(UI, order, theme, mainFolder, passedToggle, passedIcons)
    local Icons = passedIcons or (UI and UI.Icons) or (typeof(getgenv) == "function" and getgenv()._MenuTestIconsModule) or _G._MenuTestIconsModule
    if not Icons then
        Icons = safeLoadSub("Icons.lua", baseUrl .. "Icons.lua")
        if typeof(getgenv) == "function" then getgenv()._MenuTestIconsModule = Icons end
        _G._MenuTestIconsModule = Icons
    end

    local ToggleElement = passedToggle or (typeof(getgenv) == "function" and getgenv()._MenuTestToggleElement) or _G._MenuTestToggleElement
    if not ToggleElement then
        ToggleElement = safeLoadSub("elements/Toggle.lua", baseUrl .. "elements/Toggle.lua")
        if typeof(getgenv) == "function" then getgenv()._MenuTestToggleElement = ToggleElement end
        _G._MenuTestToggleElement = ToggleElement
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
    DropdownBtn.Text = "   Select Theme..."
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

        local themesFolder = mainFolder .. "/themes"
        if isfolder(themesFolder) then
            for _, file in pairs(listfiles(themesFolder)) do
                if file:sub(-5) == ".json" then
                    local themeName = file:match("([^/\\]+)%.json$") or file:match("([^/\\]+)$")

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
    local antiAfkConnection

    ToggleElement({
        Name = "AntiAFK",
        CurrentValue = false,
        Flag = "AntiAfk",
        Callback = function(Value)
            if Value then
                if antiAfkConnection then antiAfkConnection:Disconnect() end
                antiAfkConnection = Players.LocalPlayer.Idled:Connect(function()
                    VirtualUser:CaptureController()
                    VirtualUser:ClickButton2(Vector2.new())
                end)
            else
                if antiAfkConnection then
                    antiAfkConnection:Disconnect()
                    antiAfkConnection = nil
                end
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
end

return Settings