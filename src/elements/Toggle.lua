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
    ToggleFrame.Size = UDim2.new(1, 0, 0, 38)
    ToggleFrame.BackgroundColor3 = Color3.fromRGB(22, 26, 40)
    ToggleFrame.BackgroundTransparency = 0.4
    ToggleFrame.Text = ""
    ToggleFrame.AutoButtonColor = false
    ToggleFrame.Parent = parent

    local FrameCorner = Instance.new("UICorner", ToggleFrame)
    FrameCorner.CornerRadius = UDim.new(0, 12)

    local FrameStroke = Instance.new("UIStroke", ToggleFrame)
    FrameStroke.Color = Color3.fromRGB(50, 60, 90)
    FrameStroke.Thickness = 1
    FrameStroke.Transparency = 0.6
    FrameStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    local FramePadding = Instance.new("UIPadding", ToggleFrame)
    FramePadding.PaddingLeft = UDim.new(0, 12)
    FramePadding.PaddingRight = UDim.new(0, 12)
    FramePadding.PaddingTop = UDim.new(0, 4)
    FramePadding.PaddingBottom = UDim.new(0, 4)

    local Container = Instance.new("Frame")
    Container.Name = "Container"
    Container.Size = UDim2.new(1, 0, 1, 0)
    Container.BackgroundTransparency = 1
    Container.Parent = ToggleFrame

    -- Status LED Dot
    local LedDot = Instance.new("Frame")
    LedDot.Name = "LedDot"
    LedDot.Size = UDim2.new(0, 6, 0, 6)
    LedDot.Position = UDim2.new(0, 0, 0.5, 0)
    LedDot.AnchorPoint = Vector2.new(0, 0.5)
    LedDot.BackgroundColor3 = Color3.fromRGB(50, 52, 70)
    LedDot.BorderSizePixel = 0
    LedDot.Parent = Container
    Instance.new("UICorner", LedDot).CornerRadius = UDim.new(1, 0)

    local Label = Instance.new("TextLabel")
    Label.Name = "Label"
    Label.Text = toggleName
    Label.Font = Enum.Font.GothamBold
    Label.TextSize = 11
    Label.TextColor3 = Color3.fromRGB(170, 175, 195)
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Size = UDim2.new(1, -60, 1, 0)
    Label.Position = UDim2.new(0, 14, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Parent = Container

    -- Apple VisionOS Liquid Pill Switch
    local Switch = Instance.new("Frame")
    Switch.Name = "Switch"
    Switch.Size = UDim2.new(0, 42, 0, 22)
    Switch.Position = UDim2.new(1, 0, 0.5, 0)
    Switch.AnchorPoint = Vector2.new(1, 0.5)
    Switch.BackgroundColor3 = Color3.fromRGB(28, 33, 50)
    Switch.BackgroundTransparency = 0.3
    Switch.Parent = Container

    local SwitchCorner = Instance.new("UICorner", Switch)
    SwitchCorner.CornerRadius = UDim.new(1, 0)

    local SwitchStroke = Instance.new("UIStroke", Switch)
    SwitchStroke.Color = Color3.fromRGB(60, 72, 105)
    SwitchStroke.Thickness = 1
    SwitchStroke.Transparency = 0.5
    SwitchStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    local SwitchGradient = Instance.new("UIGradient", Switch)
    SwitchGradient.Enabled = false
    SwitchGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(99, 102, 241)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(168, 85, 247))
    })

    -- Knob (okrągły suwak)
    local Knob = Instance.new("Frame")
    Knob.Name = "Knob"
    Knob.Size = UDim2.new(0, 14, 0, 14)
    Knob.Position = UDim2.new(0, 4, 0.5, 0)
    Knob.AnchorPoint = Vector2.new(0, 0.5)
    Knob.BackgroundColor3 = Color3.fromRGB(160, 165, 185)
    Knob.Parent = Switch
    Instance.new("UICorner", Knob).CornerRadius = UDim.new(1, 0)

    ToggleFrame.MouseEnter:Connect(function()
        TweenService:Create(FrameStroke, TweenInfo.new(0.18), { Color = Color3.fromRGB(65, 70, 105) }):Play()
        TweenService:Create(ToggleFrame, TweenInfo.new(0.18), { BackgroundTransparency = 0.25 }):Play()
    end)
    ToggleFrame.MouseLeave:Connect(function()
        TweenService:Create(FrameStroke, TweenInfo.new(0.18), { Color = Color3.fromRGB(34, 36, 52) }):Play()
        TweenService:Create(ToggleFrame, TweenInfo.new(0.18), { BackgroundTransparency = 0.5 }):Play()
    end)

    local Value = options.CurrentValue or false
    if options.Default ~= nil then
        Value = options.Default
    end
    if options.Flag and menuConfig and menuConfig[options.Flag] ~= nil then
        Value = menuConfig[options.Flag]
    end

    local function updateThemeColors()
        SwitchGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, getThemeColor("Accent", Color3.fromRGB(99, 102, 241))),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(168, 85, 247))
        })
    end

    local function Update(animate)
        local targetPos = Value and UDim2.new(1, -18, 0.5, 0) or UDim2.new(0, 4, 0.5, 0)
        local targetSwitchBg = Value and (getThemeColor("Accent") or Color3.fromRGB(99, 102, 241)) or Color3.fromRGB(30, 31, 44)
        local targetSwitchStroke = Value and Color3.fromRGB(129, 140, 248) or Color3.fromRGB(48, 50, 70)
        local targetKnobBg = Value and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(160, 165, 185)
        local targetTextColor = Value and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(170, 175, 195)
        local targetLedColor = Value and Color3.fromRGB(16, 185, 129) or Color3.fromRGB(50, 52, 70)

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
            TweenService:Create(LedDot, TweenInfo.new(0.2), {
                BackgroundColor3 = targetLedColor
            }):Play()
        else
            Switch.BackgroundColor3 = targetSwitchBg
            SwitchStroke.Color = targetSwitchStroke
            Knob.BackgroundColor3 = targetKnobBg
            Knob.Position = targetPos
            Label.TextColor3 = targetTextColor
            LedDot.BackgroundColor3 = targetLedColor
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