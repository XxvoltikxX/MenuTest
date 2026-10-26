-- // ==========================================================================
-- // MENUTEST ULTRA-MODERN TOGGLE COMPONENT
-- // Nowoczesny, gładki przełącznik (pill switch) z mikropowolnym przejściem kolorów,
-- // akcentem poświaty oraz wsparciem dla bezpośredniego kliknięcia w całym obszarze wiersza.
-- // ==========================================================================

return function(options, themeManager, parent, menuConfig, saveMenuConfig, addConnection)
    local TweenService = game:GetService("TweenService")

    local function getThemeColor(colorKey, fallback)
        if themeManager and themeManager.GetColor then
            local c = themeManager:GetColor(colorKey)
            if c then return c end
        end
        return fallback
    end

    options = options or {}
    local toggleName = options.Name or "Toggle"

    local ToggleFrame = Instance.new("TextButton")
    ToggleFrame.Name = "Toggle_" .. toggleName
    ToggleFrame.Size = UDim2.new(1, 0, 0, 36)
    ToggleFrame.BackgroundTransparency = 1
    ToggleFrame.Text = ""
    ToggleFrame.AutoButtonColor = false
    ToggleFrame.Parent = parent

    local Container = Instance.new("Frame")
    Container.Name = "Container"
    Container.Size = UDim2.new(1, 0, 1, 0)
    Container.BackgroundTransparency = 1
    Container.Parent = ToggleFrame

    local Label = Instance.new("TextLabel")
    Label.Name = "Label"
    Label.Text = toggleName
    Label.Font = Enum.Font.GothamMedium
    Label.TextSize = 12
    Label.TextColor3 = getThemeColor("Text_Secondary", Color3.fromRGB(170, 170, 180))
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Size = UDim2.new(1, -55, 1, 0)
    Label.Position = UDim2.new(0, 0, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Parent = Container

    -- Pill Switch
    local Switch = Instance.new("Frame")
    Switch.Name = "Switch"
    Switch.Size = UDim2.new(0, 40, 0, 20)
    Switch.Position = UDim2.new(1, 0, 0.5, 0)
    Switch.AnchorPoint = Vector2.new(1, 0.5)
    Switch.BackgroundColor3 = getThemeColor("Accent2", Color3.fromRGB(32, 32, 40))
    Switch.Parent = Container

    local SwitchCorner = Instance.new("UICorner", Switch)
    SwitchCorner.CornerRadius = UDim.new(1, 0)

    local SwitchStroke = Instance.new("UIStroke", Switch)
    SwitchStroke.Color = getThemeColor("Accent", Color3.fromRGB(55, 55, 65))
    SwitchStroke.Thickness = 1.2
    SwitchStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    local SwitchGradient = Instance.new("UIGradient", Switch)
    SwitchGradient.Enabled = false
    SwitchGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, getThemeColor("Accent2", Color3.fromRGB(100, 140, 255))),
        ColorSequenceKeypoint.new(1, getThemeColor("Text", Color3.fromRGB(255, 255, 255)))
    })

    -- Knob (okrągły suwak)
    local Knob = Instance.new("Frame")
    Knob.Name = "Knob"
    Knob.Size = UDim2.new(0, 14, 0, 14)
    Knob.Position = UDim2.new(0, 3, 0.5, 0)
    Knob.AnchorPoint = Vector2.new(0, 0.5)
    Knob.BackgroundColor3 = getThemeColor("Text_Secondary", Color3.fromRGB(160, 160, 170))
    Knob.Parent = Switch

    Instance.new("UICorner", Knob).CornerRadius = UDim.new(1, 0)

    local Value = options.CurrentValue or false
    if options.Default ~= nil then
        Value = options.Default
    end
    if options.Flag and menuConfig and menuConfig[options.Flag] ~= nil then
        Value = menuConfig[options.Flag]
    end

    local function updateThemeColors()
        SwitchGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, getThemeColor("Accent2", Color3.fromRGB(100, 140, 255))),
            ColorSequenceKeypoint.new(1, getThemeColor("Text", Color3.fromRGB(255, 255, 255)))
        })
    end

    local function Update(animate)
        local targetPos = Value and UDim2.new(1, -17, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
        local targetSwitchBg = Value and getThemeColor("Text", Color3.fromRGB(255, 255, 255)) or getThemeColor("Accent2", Color3.fromRGB(32, 32, 40))
        local targetSwitchStroke = Value and getThemeColor("Text", Color3.fromRGB(255, 255, 255)) or getThemeColor("Accent", Color3.fromRGB(55, 55, 65))
        local targetKnobBg = Value and getThemeColor("Main", Color3.fromRGB(18, 18, 22)) or getThemeColor("Text_Secondary", Color3.fromRGB(160, 160, 170))
        local targetTextColor = Value and getThemeColor("Text", Color3.fromRGB(255, 255, 255)) or getThemeColor("Text_Secondary", Color3.fromRGB(170, 170, 180))

        if animate then
            TweenService:Create(Switch, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                BackgroundColor3 = targetSwitchBg
            }):Play()
            TweenService:Create(SwitchStroke, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Color = targetSwitchStroke
            }):Play()
            TweenService:Create(Knob, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                BackgroundColor3 = targetKnobBg,
                Position = targetPos
            }):Play()
            TweenService:Create(Label, TweenInfo.new(0.2), {
                TextColor3 = targetTextColor
            }):Play()
        else
            Switch.BackgroundColor3 = targetSwitchBg
            SwitchStroke.Color = targetSwitchStroke
            Knob.BackgroundColor3 = targetKnobBg
            Knob.Position = targetPos
            Label.TextColor3 = targetTextColor
        end
    end

    ToggleFrame.Activated:Connect(function()
        Value = not Value
        Update(true)
        if options.Callback then options.Callback(Value) end
        if options.Flag and saveMenuConfig then saveMenuConfig(options.Flag, Value) end
    end)

    if themeManager and themeManager.OnThemeChanged then
        themeManager:OnThemeChanged(function()
            updateThemeColors()
            Update(false)
        end)
    end

    updateThemeColors()
    Update(false)

    local API = {}
    function API:Set(val)
        Value = (val == true)
        Update(true)
        if options.Callback then options.Callback(Value) end
        if options.Flag and saveMenuConfig then saveMenuConfig(options.Flag, Value) end
    end
    function API:GetValue()
        return Value
    end

    return API
end