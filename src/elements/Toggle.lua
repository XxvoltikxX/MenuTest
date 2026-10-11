return function(options, themeManager, parent, menuConfig, saveMenuConfig)
    local TweenService = game:GetService("TweenService")

    local ToggleFrame = Instance.new("TextButton")
    ToggleFrame.Name = options.Name or "Toggle"
    ToggleFrame.Size = UDim2.new(1, 0, 0, 30)
    ToggleFrame.BackgroundTransparency = 1
    ToggleFrame.Text = ""
    ToggleFrame.Parent = parent

    local Label = Instance.new("TextLabel")
    Label.Text = options.Name or "Toggle"
    Label.Font = Enum.Font.GothamMedium
    Label.TextSize = 12
    Label.TextColor3 = Color3.fromRGB(160, 160, 165)
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Size = UDim2.new(1, -45, 1, 0)
    Label.BackgroundTransparency = 1
    Label.Parent = ToggleFrame

    local Switch = Instance.new("Frame")
    Switch.Size = UDim2.new(0, 36, 0, 18)
    Switch.Position = UDim2.new(1, 0, 0.5, 0)
    Switch.AnchorPoint = Vector2.new(1, 0.5)
    Switch.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
    Switch.Parent = ToggleFrame
    Instance.new("UICorner", Switch).CornerRadius = UDim.new(1, 0)

    local SwitchStroke = Instance.new("UIStroke", Switch)
    SwitchStroke.Color = Color3.fromRGB(55, 55, 62)
    SwitchStroke.Thickness = 1
    SwitchStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    local Knob = Instance.new("Frame")
    Knob.Size = UDim2.new(0, 14, 0, 14)
    Knob.Position = UDim2.new(0, 2, 0.5, 0)
    Knob.AnchorPoint = Vector2.new(0, 0.5)
    Knob.BackgroundColor3 = Color3.fromRGB(150, 150, 160)
    Knob.Parent = Switch
    Instance.new("UICorner", Knob).CornerRadius = UDim.new(1, 0)

    local Value = options.CurrentValue or false
    if options.Default ~= nil then
        Value = options.Default
    end
    if options.Flag and menuConfig and menuConfig[options.Flag] ~= nil then
        Value = menuConfig[options.Flag]
    end

    local function Update(animate)
        local targetPos = Value and UDim2.new(1, -16, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)
        local targetSwitchBg = Value and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(35, 35, 42)
        local targetSwitchStroke = Value and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(55, 55, 62)
        local targetKnobBg = Value and Color3.fromRGB(20, 20, 24) or Color3.fromRGB(150, 150, 160)
        local targetTextColor = Value and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(160, 160, 165)

        if animate then
            pcall(function()
                TweenService:Create(Switch, TweenInfo.new(0.2), {BackgroundColor3 = targetSwitchBg}):Play()
                TweenService:Create(SwitchStroke, TweenInfo.new(0.2), {Color = targetSwitchStroke}):Play()
                TweenService:Create(Knob, TweenInfo.new(0.2), {BackgroundColor3 = targetKnobBg, Position = targetPos}):Play()
            end)
            Label.TextColor3 = targetTextColor
        else
            Switch.BackgroundColor3 = targetSwitchBg
            SwitchStroke.Color = targetSwitchStroke
            Knob.BackgroundColor3 = targetKnobBg
            Knob.Position = targetPos
            Label.TextColor3 = targetTextColor
        end
    end

    ToggleFrame.MouseButton1Click:Connect(function()
        Value = not Value
        Update(true)
        if options.Callback then options.Callback(Value) end
        if options.Flag and saveMenuConfig then saveMenuConfig(options.Flag, Value) end
    end)

    -- Inicjalizacja bez animacji (zero błędów tweenowania)
    Update(false)

    local API = {}
    function API:Set(val)
        Value = (val == true)
        Update(true)
        if options.Callback then options.Callback(Value) end
        if options.Flag and saveMenuConfig then saveMenuConfig(options.Flag, Value) end
    end
    return API
end