-- // ==========================================================================
-- // MENUTEST MODULE COMPONENT (NEVERLOSE / CYBER STYLE)
-- // Luksusowa karta modułu ze zintegrowanym przełącznikiem Pill Switch,
-- // plakietką keybindu [Z], płynnym rozwijaniem pod-opcji i neonowymi akcentami.
-- // ==========================================================================

local baseUrl = "https://raw.githubusercontent.com/XxvoltikxX/MenuTest/refs/heads/main/src/"

local function safeLoadSubElement(relativePath, remoteUrl)
    local isDev = (typeof(getgenv) == "function" and getgenv()._MenuTestDevMode == true)
    if isDev and typeof(readfile) == "function" then
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
    local cacheBuster = (remoteUrl:find("%?") and "&" or "?") .. "_nocache=" .. tostring(os.time()) .. "_" .. tostring(math.random(10000, 99999))
    local ok, res = pcall(function() return game:HttpGet(remoteUrl .. cacheBuster) end)
    if ok and res then
        local chunk = loadstring(res)
        if chunk then return chunk() end
    end
    return function() return {} end
end

return function(options, themeManager, parent, menuConfig, saveMenuConfig, addConnection, UI, elements)
    local TweenService = game:GetService("TweenService")
    local UserInputService = game:GetService("UserInputService")

    -- Pobranie konstruktorów elementów z pamięci
    local SliderElement      = (elements and elements.Slider)      or safeLoadSubElement("Slider.lua",      baseUrl .. "elements/Slider.lua")
    local ToggleElement      = (elements and elements.Toggle)      or safeLoadSubElement("Toggle.lua",      baseUrl .. "elements/Toggle.lua")
    local DropdownElement    = (elements and elements.Dropdown)    or safeLoadSubElement("Dropdown.lua",    baseUrl .. "elements/Dropdown.lua")
    local InputElement       = (elements and elements.Input)       or safeLoadSubElement("Input.lua",       baseUrl .. "elements/Input.lua")
    local ColorPickerElement = (elements and elements.ColorPicker) or safeLoadSubElement("ColorPicker.lua", baseUrl .. "elements/ColorPicker.lua")
    local ButtonElement      = (elements and elements.Button)      or safeLoadSubElement("Button.lua",      baseUrl .. "elements/Button.lua")
    local Icons              = (elements and elements.Icons)       or (UI and UI.Icons)

    local function getThemeColor(colorKey, fallback)
        if themeManager and themeManager.GetColor then
            local c = themeManager:GetColor(colorKey)
            if c then return c end
        end
        return fallback
    end

    local function getColors()
        return {
            Background       = Color3.fromRGB(20, 24, 38),
            BackgroundActive = Color3.fromRGB(26, 32, 52),
            Stroke           = Color3.fromRGB(55, 65, 95),
            StrokeActive     = getThemeColor("Accent", Color3.fromRGB(129, 140, 248)),
            Text             = Color3.fromRGB(255, 255, 255),
            TextDim          = Color3.fromRGB(155, 165, 195),
            BadgeBg          = Color3.fromRGB(30, 36, 56),
            BadgeStroke      = Color3.fromRGB(70, 80, 120)
        }
    end

    local Colors = getColors()

    -- Ramka modułu (Apple VisionOS Liquid Glass Module Card)
    local ModuleFrame = Instance.new("Frame")
    ModuleFrame.Name = options.Name or "Module"
    ModuleFrame.Size = UDim2.new(1, 0, 0, 50)
    ModuleFrame.BackgroundColor3 = Colors.Background
    ModuleFrame.BackgroundTransparency = 0.35
    ModuleFrame.ClipsDescendants = true
    ModuleFrame.Parent = parent

    local Corner = Instance.new("UICorner", ModuleFrame)
    Corner.CornerRadius = UDim.new(0, 14)

    local MainStroke = Instance.new("UIStroke", ModuleFrame)
    MainStroke.Color = Colors.Stroke
    MainStroke.Thickness = 1.2
    MainStroke.Transparency = 0.6
    MainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    -- Wskaźnik LED aktywności na lewej krawędzi modułu
    local LedIndicator = Instance.new("Frame")
    LedIndicator.Name = "LedIndicator"
    LedIndicator.Size = UDim2.new(0, 4, 0, 22)
    LedIndicator.Position = UDim2.new(0, 4, 0, 14)
    LedIndicator.BackgroundColor3 = Color3.fromRGB(129, 140, 248)
    LedIndicator.BackgroundTransparency = 1
    LedIndicator.BorderSizePixel = 0
    LedIndicator.ZIndex = 12
    LedIndicator.Parent = ModuleFrame
    Instance.new("UICorner", LedIndicator).CornerRadius = UDim.new(1, 0)

    -- Nagłówek modułu
    local Header = Instance.new("Frame")
    Header.Name = "Header"
    Header.Size = UDim2.new(1, 0, 0, 50)
    Header.BackgroundTransparency = 1
    Header.Parent = ModuleFrame

    local ClickBtn = Instance.new("TextButton")
    ClickBtn.Name = "ClickBtn"
    ClickBtn.Size = UDim2.new(1, -125, 1, 0)
    ClickBtn.Position = UDim2.new(0, 0, 0, 0)
    ClickBtn.BackgroundTransparency = 1
    ClickBtn.Text = ""
    ClickBtn.ZIndex = 10
    ClickBtn.Parent = Header

    local Icon = nil
    if options.Icon and Icons then
        Icon = Instance.new("ImageLabel")
        Icon.Name = "ModuleIcon"
        Icon.Size = UDim2.new(0, 18, 0, 18)
        Icon.Position = UDim2.new(0, 14, 0.5, 0)
        Icon.AnchorPoint = Vector2.new(0, 0.5)
        Icon.BackgroundTransparency = 1
        Icon.ImageColor3 = Colors.TextDim
        Icon.ZIndex = 11
        Icon.Parent = Header
        Icons:Apply(Icon, options.Icon)
    end

    local hasDesc = options.Description and #tostring(options.Description) > 0

    local Label = Instance.new("TextLabel")
    Label.Name = "Title"
    Label.Text = options.Name or "Module"
    Label.Font = Enum.Font.GothamBold
    Label.TextSize = 13
    Label.TextColor3 = Colors.TextDim
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.TextTruncate = Enum.TextTruncate.AtEnd
    if hasDesc then
        Label.Size = UDim2.new(1, (options.Icon and -160 or -135), 0, 18)
        Label.Position = UDim2.new(0, options.Icon and 40 or 14, 0, 7)
    else
        Label.Size = UDim2.new(1, (options.Icon and -160 or -135), 1, 0)
        Label.Position = UDim2.new(0, options.Icon and 40 or 14, 0, 0)
    end
    Label.BackgroundTransparency = 1
    Label.ZIndex = 11
    Label.Parent = Header

    local DescLabel = nil
    if hasDesc then
        DescLabel = Instance.new("TextLabel")
        DescLabel.Name = "Description"
        DescLabel.Text = tostring(options.Description)
        DescLabel.Font = Enum.Font.GothamMedium
        DescLabel.TextSize = 10
        DescLabel.TextColor3 = Colors.TextDim
        DescLabel.TextXAlignment = Enum.TextXAlignment.Left
        DescLabel.TextTruncate = Enum.TextTruncate.AtEnd
        DescLabel.Size = UDim2.new(1, (options.Icon and -160 or -135), 0, 15)
        DescLabel.Position = UDim2.new(0, options.Icon and 40 or 14, 0, 26)
        DescLabel.BackgroundTransparency = 1
        DescLabel.ZIndex = 11
        DescLabel.Parent = Header
    end

    -- Prawa strona nagłówka: [Bind] [PillSwitch] [ExpandBtn]
    local ControlsFrame = Instance.new("Frame")
    ControlsFrame.Name = "ControlsFrame"
    ControlsFrame.Size = UDim2.new(0, 125, 1, 0)
    ControlsFrame.Position = UDim2.new(1, -10, 0.5, 0)
    ControlsFrame.AnchorPoint = Vector2.new(1, 0.5)
    ControlsFrame.BackgroundTransparency = 1
    ControlsFrame.ZIndex = 15
    ControlsFrame.Parent = Header

    local ControlsLayout = Instance.new("UIListLayout", ControlsFrame)
    ControlsLayout.FillDirection = Enum.FillDirection.Horizontal
    ControlsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    ControlsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    ControlsLayout.Padding = UDim.new(0, 8)

    -- Keybind Badge
    local BindBadge = Instance.new("TextButton")
    BindBadge.Name = "BindBadge"
    BindBadge.Size = UDim2.new(0, 32, 0, 22)
    BindBadge.BackgroundColor3 = Colors.BadgeBg
    BindBadge.Text = "..."
    BindBadge.TextColor3 = Colors.TextDim
    BindBadge.Font = Enum.Font.GothamBold
    BindBadge.TextSize = 10
    BindBadge.AutoButtonColor = false
    BindBadge.Parent = ControlsFrame

    Instance.new("UICorner", BindBadge).CornerRadius = UDim.new(0, 5)
    local BadgeStroke = Instance.new("UIStroke", BindBadge)
    BadgeStroke.Color = Colors.BadgeStroke
    BadgeStroke.Thickness = 1
    BadgeStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    -- Apple iPhone iOS Liquid Glass Switch
    local SwitchBtn = Instance.new("TextButton")
    SwitchBtn.Name = "SwitchBtn"
    SwitchBtn.Size = UDim2.new(0, 44, 0, 24)
    SwitchBtn.BackgroundColor3 = Color3.fromRGB(50, 54, 66)
    SwitchBtn.BackgroundTransparency = 0.2
    SwitchBtn.Text = ""
    SwitchBtn.AutoButtonColor = false
    SwitchBtn.Parent = ControlsFrame
    Instance.new("UICorner", SwitchBtn).CornerRadius = UDim.new(1, 0)

    local SwitchStroke = Instance.new("UIStroke", SwitchBtn)
    SwitchStroke.Color = Color3.fromRGB(70, 75, 90)
    SwitchStroke.Thickness = 1
    SwitchStroke.Transparency = 0.4

    local SwitchDot = Instance.new("Frame")
    SwitchDot.Name = "Dot"
    SwitchDot.Size = UDim2.new(0, 18, 0, 18)
    SwitchDot.Position = UDim2.new(0, 3, 0.5, 0)
    SwitchDot.AnchorPoint = Vector2.new(0, 0.5)
    SwitchDot.BackgroundColor3 = Color3.fromRGB(240, 242, 250)
    SwitchDot.BorderSizePixel = 0
    SwitchDot.Parent = SwitchBtn
    Instance.new("UICorner", SwitchDot).CornerRadius = UDim.new(1, 0)

    -- Dedykowany przycisk rozwijania (Chevron)
    local ExpandBtn = Instance.new("TextButton")
    ExpandBtn.Name = "ExpandBtn"
    ExpandBtn.Size = UDim2.new(0, 22, 0, 22)
    ExpandBtn.BackgroundTransparency = 1
    ExpandBtn.Text = ""
    ExpandBtn.AutoButtonColor = false
    ExpandBtn.Parent = ControlsFrame

    local ExpandIcon = Instance.new("ImageLabel")
    ExpandIcon.Name = "Icon"
    ExpandIcon.Size = UDim2.new(0, 15, 0, 15)
    ExpandIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
    ExpandIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    ExpandIcon.BackgroundTransparency = 1
    ExpandIcon.ImageColor3 = Colors.TextDim
    ExpandIcon.Parent = ExpandBtn
    if Icons and Icons.Apply then
        Icons:Apply(ExpandIcon, "chevron-down")
    end

    -- Rozdzielacz między nagłówkiem a wnętrzem opcji (Gradient Divider)
    local InnerLine = Instance.new("Frame")
    InnerLine.Name = "InnerLine"
    InnerLine.Size = UDim2.new(1, -20, 0, 1)
    InnerLine.Position = UDim2.new(0, 10, 0, 49)
    InnerLine.BorderSizePixel = 0
    InnerLine.BackgroundColor3 = Color3.fromRGB(45, 52, 78)
    InnerLine.Visible = false
    InnerLine.Parent = ModuleFrame

    local InGrad = Instance.new("UIGradient", InnerLine)
    InGrad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.8),
        NumberSequenceKeypoint.new(0.5, 0.1),
        NumberSequenceKeypoint.new(1, 0.8)
    })

    -- Kontener na opcje rozwijane (Apple VisionOS Inset Glass Sub-Card)
    local Content = Instance.new("Frame")
    Content.Name = "Content"
    Content.Position = UDim2.new(0, 8, 0, 52)
    Content.Size = UDim2.new(1, -16, 0, 0)
    Content.AutomaticSize = Enum.AutomaticSize.Y
    Content.BackgroundColor3 = Color3.fromRGB(14, 16, 26)
    Content.BackgroundTransparency = 0.45
    Content.ClipsDescendants = false
    Content.Visible = false
    Content.Parent = ModuleFrame

    Instance.new("UICorner", Content).CornerRadius = UDim.new(0, 12)
    local ContentStroke = Instance.new("UIStroke", Content)
    ContentStroke.Color = Color3.fromRGB(48, 55, 82)
    ContentStroke.Thickness = 1
    ContentStroke.Transparency = 0.6
    ContentStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    local ContentLayout = Instance.new("UIListLayout", Content)
    ContentLayout.Padding = UDim.new(0, 8)
    ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder

    local ContentPadding = Instance.new("UIPadding", Content)
    ContentPadding.PaddingLeft = UDim.new(0, 10)
    ContentPadding.PaddingRight = UDim.new(0, 10)
    ContentPadding.PaddingTop = UDim.new(0, 10)
    ContentPadding.PaddingBottom = UDim.new(0, 10)

    -- Stan modułu
    local Enabled = false
    local Expanded = false
    local Keybind = nil
    local Binding = false

    if not options.Flag then
        options.Flag = (options.Name and options.Name:gsub("%s+", "_")) or "Module"
    end

    if options.Flag and menuConfig and menuConfig[options.Flag .. "_Bind"] then
        local bindName = menuConfig[options.Flag .. "_Bind"]
        if bindName then pcall(function() Keybind = Enum.KeyCode[bindName] end) end
        if Keybind then BindBadge.Text = "[" .. Keybind.Name:sub(1, 3) .. "]" end
    end

    if not Keybind and (options.DefaultKeybind or options.Keybind) then
        local def = options.DefaultKeybind or options.Keybind
        if typeof(def) == "EnumItem" then
            Keybind = def
        elseif type(def) == "string" and #def > 0 then
            pcall(function() Keybind = Enum.KeyCode[def] end)
        end
        if Keybind then BindBadge.Text = "[" .. Keybind.Name:sub(1, 3) .. "]" end
    end

    local function UpdateVisuals(animate)
        local cur = getColors()
        local targetBg     = Enabled and cur.BackgroundActive or cur.Background
        local targetStroke = Enabled and cur.StrokeActive     or cur.Stroke
        local targetText   = Enabled and cur.Text             or cur.TextDim
        local accentCol    = cur.StrokeActive

        local time = animate and 0.22 or 0

        TweenService:Create(ModuleFrame, TweenInfo.new(time, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            BackgroundColor3 = targetBg
        }):Play()

        TweenService:Create(MainStroke, TweenInfo.new(time, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Color = targetStroke
        }):Play()

        TweenService:Create(Label, TweenInfo.new(time), { TextColor3 = targetText }):Play()

        if Icon then
            TweenService:Create(Icon, TweenInfo.new(time), {
                ImageColor3 = Enabled and Color3.fromRGB(255, 255, 255) or cur.TextDim
            }):Play()
        end

        if LedIndicator then
            TweenService:Create(LedIndicator, TweenInfo.new(time), {
                BackgroundTransparency = Enabled and 0 or 1,
                BackgroundColor3 = accentCol
            }):Play()
        end

        -- Animacja Pill Switcha Apple iOS
        local dotPos = Enabled and UDim2.new(1, -21, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
        local switchBg = Enabled and Color3.fromRGB(52, 199, 89) or Color3.fromRGB(50, 54, 66)
        local switchStrokeCol = Enabled and Color3.fromRGB(82, 222, 118) or Color3.fromRGB(70, 75, 90)
        local dotCol = Enabled and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(240, 242, 250)

        TweenService:Create(SwitchBtn, TweenInfo.new(time, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            BackgroundColor3 = switchBg
        }):Play()
        TweenService:Create(SwitchStroke, TweenInfo.new(time), { Color = switchStrokeCol }):Play()
        TweenService:Create(SwitchDot, TweenInfo.new(time, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Position = dotPos,
            BackgroundColor3 = dotCol
        }):Play()

        if not Binding then
            BindBadge.TextColor3 = Enabled and cur.Text or cur.TextDim
            BadgeStroke.Color = Enabled and accentCol or cur.BadgeStroke
        end
    end

    local function ToggleModule(forceState)
        if forceState ~= nil then Enabled = forceState else Enabled = not Enabled end
        UpdateVisuals(true)
        if options.Flag and menuConfig then
            menuConfig[options.Flag] = Enabled
        end
        if options.Callback then options.Callback(Enabled) end
    end

    local function ToggleExpand()
        Expanded = not Expanded
        Content.Visible = Expanded
        InnerLine.Visible = Expanded

        local targetHeight = Expanded and (54 + ContentLayout.AbsoluteContentSize.Y + 18) or 50
        TweenService:Create(ModuleFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Size = UDim2.new(1, 0, 0, targetHeight)
        }):Play()

        if ExpandIcon then
            TweenService:Create(ExpandIcon, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Rotation = Expanded and 180 or 0
            }):Play()
        end
    end

    local function StartBinding()
        Binding = true
        local cur = getColors()
        BindBadge.Text = "[?]"
        BindBadge.TextColor3 = cur.Text
        BadgeStroke.Color = cur.Text
    end

    ClickBtn.Activated:Connect(function()
        ToggleModule()
    end)

    SwitchBtn.Activated:Connect(function()
        ToggleModule()
    end)

    ExpandBtn.Activated:Connect(function()
        ToggleExpand()
    end)

    BindBadge.Activated:Connect(function()
        StartBinding()
    end)

    ClickBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            ToggleExpand()
        elseif input.UserInputType == Enum.UserInputType.MouseButton3 then
            StartBinding()
        end
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
                local cur = getColors()
                BindBadge.TextColor3 = Enabled and cur.Text or cur.TextDim
                BadgeStroke.Color = cur.BadgeStroke
                if options.Flag then saveMenuConfig(options.Flag .. "_Bind", Keybind and Keybind.Name or nil) end
                if UI and UI.UpdateKeybindsOverlay then UI:UpdateKeybindsOverlay() end
            elseif not gpe and Keybind and input.KeyCode == Keybind then
                ToggleModule()
            end
        end))
    end

    ContentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        if Expanded then
            local targetHeight = 54 + ContentLayout.AbsoluteContentSize.Y + 18
            ModuleFrame.Size = UDim2.new(1, 0, 0, targetHeight)
        end
    end)

    UpdateVisuals(false)

    if options.Expanded or options.DefaultExpanded then
        task.defer(function()
            if not Expanded then
                ToggleExpand()
            end
        end)
    end

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
    function API:AddSlider(opts)
        local inst = SliderElement(opts, themeManager, Content, menuConfig, saveMenuConfig)
        if opts and opts.Flag and UI and UI.Flags then UI.Flags[opts.Flag] = inst end
        return inst
    end
    function API:AddToggle(opts)
        local inst = ToggleElement(opts, themeManager, Content, menuConfig, saveMenuConfig)
        if opts and opts.Flag and UI and UI.Flags then UI.Flags[opts.Flag] = inst end
        return inst
    end
    function API:AddDropdown(opts)
        local inst = DropdownElement(opts, themeManager, Content, menuConfig, saveMenuConfig, addConnection, Icons)
        if opts and opts.Flag and UI and UI.Flags then UI.Flags[opts.Flag] = inst end
        return inst
    end
    function API:AddInput(opts)
        local inst = InputElement(opts, themeManager, Content, menuConfig, saveMenuConfig)
        if opts and opts.Flag and UI and UI.Flags then UI.Flags[opts.Flag] = inst end
        return inst
    end
    function API:AddColorPicker(opts)
        local inst = ColorPickerElement(opts, themeManager, Content, menuConfig, saveMenuConfig, addConnection)
        if opts and opts.Flag and UI and UI.Flags then UI.Flags[opts.Flag] = inst end
        return inst
    end
    function API:AddButton(opts) return ButtonElement(opts, themeManager, Content, menuConfig, saveMenuConfig, addConnection) end
    function API:Set(val) ToggleModule(val) end

    return API
end