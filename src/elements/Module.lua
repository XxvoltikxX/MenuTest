-- Fast pre-load helper with local readfile support (tylko jako fallback)
local function safeLoadSubElement(relativePath, remoteUrl)
    if typeof(readfile) == "function" then
        local candidates = {
            "MenuTest/src/elements/" .. relativePath,
            "src/elements/" .. relativePath,
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
    return loadstring(game:HttpGet(remoteUrl))()
end

local baseUrl = "https://raw.githubusercontent.com/xxCichyxx/MenuTest/refs/heads/main/src/"

return function(options, themeManager, parent, menuConfig, saveMenuConfig, addConnection, UI, elements)
    local TweenService = game:GetService("TweenService")
    local UserInputService = game:GetService("UserInputService")

    -- Współdzielone instancje elementów (błyskawiczne ładowanie z pamięci)
    local SliderElement      = (elements and elements.Slider)      or safeLoadSubElement("Slider.lua",      baseUrl .. "elements/Slider.lua")
    local ToggleElement      = (elements and elements.Toggle)      or safeLoadSubElement("Toggle.lua",      baseUrl .. "elements/Toggle.lua")
    local DropdownElement    = (elements and elements.Dropdown)    or safeLoadSubElement("Dropdown.lua",    baseUrl .. "elements/Dropdown.lua")
    local InputElement       = (elements and elements.Input)       or safeLoadSubElement("Input.lua",       baseUrl .. "elements/Input.lua")
    local ColorPickerElement = (elements and elements.ColorPicker) or safeLoadSubElement("ColorPicker.lua", baseUrl .. "elements/ColorPicker.lua")
    local ButtonElement      = (elements and elements.Button)      or safeLoadSubElement("Button.lua",      baseUrl .. "elements/Button.lua")
    local Icons              = (elements and elements.Icons)       or (UI and UI.Icons) or (typeof(getgenv) == "function" and getgenv()._MenuTestIconsModule) or _G._MenuTestIconsModule

    if not Icons then
        if typeof(readfile) == "function" then
            local s, d = pcall(readfile, "MenuTest/src/Icons.lua")
            if s and d and #d > 0 then
                local chunk = loadstring(d)
                if chunk then Icons = chunk() end
            end
        end
        if not Icons then
            local ok, res = pcall(function() return game:HttpGet(baseUrl .. "Icons.lua") end)
            if ok and res then
                local chunk = loadstring(res)
                if chunk then Icons = chunk() end
            end
        end
        if Icons then
            if typeof(getgenv) == "function" then getgenv()._MenuTestIconsModule = Icons end
            _G._MenuTestIconsModule = Icons
        end
    end

    local Colors = {
        Background      = Color3.fromRGB(25, 25, 25),
        BackgroundActive= Color3.fromRGB(32, 32, 38),
        Stroke          = Color3.fromRGB(55, 55, 60),
        StrokeActive    = Color3.fromRGB(255, 255, 255),
        Text            = Color3.fromRGB(255, 255, 255),
        TextDim         = Color3.fromRGB(160, 160, 165),
        BadgeBg         = Color3.fromRGB(35, 35, 42),
        BadgeStroke     = Color3.fromRGB(55, 55, 62)
    }

    local ModuleFrame = Instance.new("Frame")
    ModuleFrame.Name = options.Name or "Module"
    ModuleFrame.Size = UDim2.new(1, 0, 0, 50)
    ModuleFrame.BackgroundColor3 = Colors.Background
    ModuleFrame.ClipsDescendants = true
    ModuleFrame.Parent = parent

    local Corner = Instance.new("UICorner", ModuleFrame)
    Corner.CornerRadius = UDim.new(0, 8)

    local MainStroke = Instance.new("UIStroke", ModuleFrame)
    MainStroke.Color = Colors.Stroke
    MainStroke.Thickness = 1
    MainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    local Header = Instance.new("Frame")
    Header.Name = "Header"
    Header.Size = UDim2.new(1, 0, 0, 50)
    Header.BackgroundTransparency = 1
    Header.Parent = ModuleFrame

    local ClickBtn = Instance.new("TextButton")
    ClickBtn.Name = "ClickBtn"
    ClickBtn.Size = UDim2.new(1, 0, 1, 0)
    ClickBtn.BackgroundTransparency = 1
    ClickBtn.Text = ""
    ClickBtn.ZIndex = 10
    ClickBtn.Parent = Header

    local Icon = nil
    if options.Icon and Icons then
        Icon = Instance.new("ImageLabel")
        Icon.Size = UDim2.new(0, 20, 0, 20)
        Icon.Position = UDim2.new(0, 14, 0.5, 0)
        Icon.AnchorPoint = Vector2.new(0, 0.5)
        Icon.BackgroundTransparency = 1
        Icon.ImageColor3 = Colors.TextDim
        Icon.ZIndex = 11
        Icon.Parent = Header
        Icons:Apply(Icon, options.Icon)
    end

    local Label = Instance.new("TextLabel")
    Label.Text = options.Name or "Module"
    Label.Font = Enum.Font.GothamMedium
    Label.TextSize = 13
    Label.TextColor3 = Colors.TextDim
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.TextTruncate = Enum.TextTruncate.AtEnd
    Label.Size = UDim2.new(1, (options.Icon and -100 or -75), 1, 0)
    Label.Position = UDim2.new(0, options.Icon and 42 or 14, 0, 0)
    Label.BackgroundTransparency = 1
    Label.ZIndex = 11
    Label.Parent = Header

    -- Keybind Badge na prawym brzegu
    local BindBadge = Instance.new("TextButton")
    BindBadge.Name = "BindBadge"
    BindBadge.Size = UDim2.new(0, 36, 0, 22)
    BindBadge.Position = UDim2.new(1, -12, 0.5, 0)
    BindBadge.AnchorPoint = Vector2.new(1, 0.5)
    BindBadge.BackgroundColor3 = Colors.BadgeBg
    BindBadge.Text = "..."
    BindBadge.TextColor3 = Colors.TextDim
    BindBadge.Font = Enum.Font.GothamBold
    BindBadge.TextSize = 11
    BindBadge.ZIndex = 12
    BindBadge.Parent = Header

    Instance.new("UICorner", BindBadge).CornerRadius = UDim.new(0, 5)
    local BadgeStroke = Instance.new("UIStroke", BindBadge)
    BadgeStroke.Color = Colors.BadgeStroke
    BadgeStroke.Thickness = 1
    BadgeStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    local BadgePadding = Instance.new("UIPadding", BindBadge)
    BadgePadding.PaddingLeft = UDim.new(0, 6)
    BadgePadding.PaddingRight = UDim.new(0, 6)

    -- Kontener na opcje rozwijane
    local Content = Instance.new("Frame")
    Content.Name = "Content"
    Content.Position = UDim2.new(0, 0, 0, 50)
    Content.Size = UDim2.new(1, 0, 0, 0)
    Content.AutomaticSize = Enum.AutomaticSize.Y
    Content.BackgroundTransparency = 1
    Content.ClipsDescendants = true
    Content.Visible = false
    Content.Parent = ModuleFrame

    local ContentLayout = Instance.new("UIListLayout")
    ContentLayout.Padding = UDim.new(0, 8)
    ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ContentLayout.Parent = Content

    local ContentPadding = Instance.new("UIPadding")
    ContentPadding.PaddingLeft = UDim.new(0, 14)
    ContentPadding.PaddingRight = UDim.new(0, 14)
    ContentPadding.PaddingBottom = UDim.new(0, 14)
    ContentPadding.Parent = Content

    -- Stan
    local Enabled = options.Default or false
    local Expanded = false
    local Keybind = nil
    local Binding = false

    if options.Flag and menuConfig[options.Flag] ~= nil then
        Enabled = menuConfig[options.Flag]
    end
    if options.Flag and menuConfig[options.Flag .. "_Bind"] then
        local bindName = menuConfig[options.Flag .. "_Bind"]
        if bindName then pcall(function() Keybind = Enum.KeyCode[bindName] end) end
        if Keybind then BindBadge.Text = "[" .. Keybind.Name:sub(1, 3) .. "]" end
    end

    local function UpdateVisuals(instant)
        if Enabled then
            if instant then
                MainStroke.Color = Colors.StrokeActive
                MainStroke.Thickness = 1.6
                Label.TextColor3 = Colors.Text
                Label.Font = Enum.Font.GothamBold
                if Icon then Icon.ImageColor3 = Colors.Text end
                ModuleFrame.BackgroundColor3 = Colors.BackgroundActive
            else
                TweenService:Create(MainStroke, TweenInfo.new(0.25), {
                    Color = Colors.StrokeActive,
                    Thickness = 1.6
                }):Play()
                TweenService:Create(Label, TweenInfo.new(0.2), {TextColor3 = Colors.Text}):Play()
                Label.Font = Enum.Font.GothamBold
                if Icon then TweenService:Create(Icon, TweenInfo.new(0.2), {ImageColor3 = Colors.Text}):Play() end
                TweenService:Create(ModuleFrame, TweenInfo.new(0.2), {BackgroundColor3 = Colors.BackgroundActive}):Play()
            end
        else
            if instant then
                MainStroke.Color = Colors.Stroke
                MainStroke.Thickness = 1
                Label.TextColor3 = Colors.TextDim
                Label.Font = Enum.Font.GothamMedium
                if Icon then Icon.ImageColor3 = Colors.TextDim end
                ModuleFrame.BackgroundColor3 = Colors.Background
            else
                TweenService:Create(MainStroke, TweenInfo.new(0.25), {
                    Color = Colors.Stroke,
                    Thickness = 1
                }):Play()
                TweenService:Create(Label, TweenInfo.new(0.2), {TextColor3 = Colors.TextDim}):Play()
                Label.Font = Enum.Font.GothamMedium
                if Icon then TweenService:Create(Icon, TweenInfo.new(0.2), {ImageColor3 = Colors.TextDim}):Play() end
                TweenService:Create(ModuleFrame, TweenInfo.new(0.2), {BackgroundColor3 = Colors.Background}):Play()
            end
        end

        if UI and UI.UpdateKeybindsOverlay then
            UI:UpdateKeybindsOverlay()
        end
    end

    local function ToggleModule(forceState)
        if forceState ~= nil then Enabled = forceState else Enabled = not Enabled end
        UpdateVisuals(false)
        if options.Flag then saveMenuConfig(options.Flag, Enabled) end
        if options.Callback then options.Callback(Enabled) end
    end

    local function StartBinding()
        Binding = true
        BindBadge.Text = "[?]"
        BindBadge.TextColor3 = Color3.fromRGB(255, 255, 255)
        BadgeStroke.Color = Color3.fromRGB(255, 255, 255)
    end

    -- Obsługa kliknięć:
    -- MouseButton1: Włącz / Wyłącz
    -- MouseButton2: Rozwiń / Zwiń opcje modułu
    -- MouseButton3 (Scroll): Bindowanie klawisza!
    ClickBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            ToggleModule()
        elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
            Expanded = not Expanded
            Content.Visible = Expanded

            local targetHeight = Expanded and (50 + ContentLayout.AbsoluteContentSize.Y + 20) or 50
            TweenService:Create(ModuleFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Size = UDim2.new(1, 0, 0, targetHeight)
            }):Play()
        elseif input.UserInputType == Enum.UserInputType.MouseButton3 then
            StartBinding()
        end
    end)

    BindBadge.MouseButton1Click:Connect(function()
        StartBinding()
    end)

    if addConnection then
        addConnection(UserInputService.InputBegan:Connect(function(input, gpe)
            if Binding and input.UserInputType == Enum.UserInputType.Keyboard then
                if input.KeyCode == Enum.KeyCode.Backspace or input.KeyCode == Enum.KeyCode.Delete then
                    Keybind = nil
                    BindBadge.Text = "..."
                else
                    Keybind = input.KeyCode
                    BindBadge.Text = "[" .. input.KeyCode.Name:sub(1, 3) .. "]"
                end
                Binding = false
                BindBadge.TextColor3 = Colors.TextDim
                BadgeStroke.Color = Colors.BadgeStroke
                if options.Flag then saveMenuConfig(options.Flag .. "_Bind", Keybind and Keybind.Name or nil) end
                if UI and UI.UpdateKeybindsOverlay then UI:UpdateKeybindsOverlay() end
            elseif not gpe and Keybind and input.KeyCode == Keybind then
                ToggleModule()
            end
        end))
    end

    ContentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        if Expanded then
            local targetHeight = 50 + ContentLayout.AbsoluteContentSize.Y + 20
            ModuleFrame.Size = UDim2.new(1, 0, 0, targetHeight)
        end
    end)

    UpdateVisuals(true)

    -- Rejestracja w UI dla Keybinds Overlay
    if UI and UI.RegisterModule then
        UI:RegisterModule({
            Name = options.Name or "Module",
            GetEnabled = function() return Enabled end,
            GetKeybind = function() return Keybind and Keybind.Name or nil end,
            Toggle = function(state) ToggleModule(state) end
        })
    end

    local API = {}
    function API:AddSlider(opts) return SliderElement(opts, themeManager, Content, menuConfig, saveMenuConfig) end
    function API:AddToggle(opts) return ToggleElement(opts, themeManager, Content, menuConfig, saveMenuConfig) end
    function API:AddDropdown(opts) return DropdownElement(opts, themeManager, Content, menuConfig, saveMenuConfig, addConnection, Icons) end
    function API:AddInput(opts) return InputElement(opts, themeManager, Content, menuConfig, saveMenuConfig) end
    function API:AddColorPicker(opts) return ColorPickerElement(opts, themeManager, Content, menuConfig, saveMenuConfig) end
    function API:AddButton(opts) return ButtonElement(opts, themeManager, Content, menuConfig, saveMenuConfig, addConnection) end
    function API:Set(val) ToggleModule(val) end

    return API
end