return function(options, themeManager, parent, menuConfig, saveMenuConfig)
    local UserInputService = game:GetService("UserInputService")
    local TweenService = game:GetService("TweenService")

    local SliderFrame = Instance.new("Frame")
    SliderFrame.Name = options.Name or "Slider"
    SliderFrame.Size = UDim2.new(1, 0, 0, 46)
    SliderFrame.BackgroundTransparency = 1
    SliderFrame.Parent = parent

    -- Opis (po lewej na górze)
    local Label = Instance.new("TextLabel")
    Label.Text = options.Name or "Slider"
    Label.Font = Enum.Font.GothamMedium
    Label.TextSize = 12
    Label.TextColor3 = Color3.fromRGB(160, 160, 165)
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Size = UDim2.new(0.6, 0, 0, 20)
    Label.Position = UDim2.new(0, 0, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Parent = SliderFrame

    -- Wartość + Suffix (po prawej na górze)
    local ValueLabel = Instance.new("TextLabel")
    ValueLabel.Font = Enum.Font.GothamBold
    ValueLabel.TextSize = 12
    ValueLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    ValueLabel.TextXAlignment = Enum.TextXAlignment.Right
    ValueLabel.Size = UDim2.new(0.4, 0, 0, 20)
    ValueLabel.Position = UDim2.new(0.6, 0, 0, 0)
    ValueLabel.BackgroundTransparency = 1
    ValueLabel.Parent = SliderFrame

    -- Tło suwaka
    local SliderBar = Instance.new("Frame")
    SliderBar.Size = UDim2.new(1, 0, 0, 8)
    SliderBar.Position = UDim2.new(0, 0, 0, 26)
    SliderBar.BackgroundColor3 = Color3.fromRGB(16, 16, 20)
    SliderBar.Parent = SliderFrame
    Instance.new("UICorner", SliderBar).CornerRadius = UDim.new(1, 0)

    local BarStroke = Instance.new("UIStroke", SliderBar)
    BarStroke.Color = Color3.fromRGB(45, 45, 52)
    BarStroke.Thickness = 1
    BarStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    -- Wypełnienie (Biały akcent pasujący do Dashboardu)
    local Fill = Instance.new("Frame")
    Fill.Size = UDim2.new(0, 0, 1, 0)
    Fill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Fill.Parent = SliderBar
    Instance.new("UICorner", Fill).CornerRadius = UDim.new(1, 0)

    -- Gałka (Knob)
    local Knob = Instance.new("Frame")
    Knob.Size = UDim2.new(0, 14, 0, 14)
    Knob.Position = UDim2.new(1, 0, 0.5, 0)
    Knob.AnchorPoint = Vector2.new(0.5, 0.5)
    Knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Knob.Parent = Fill
    Instance.new("UICorner", Knob).CornerRadius = UDim.new(1, 0)

    local KnobStroke = Instance.new("UIStroke", Knob)
    KnobStroke.Color = Color3.fromRGB(35, 35, 40)
    KnobStroke.Thickness = 1.5

    -- Logika
    local Min = options.Range[1]
    local Max = options.Range[2]
    local Value = options.CurrentValue or Min
    if options.Flag and menuConfig[options.Flag] ~= nil then
        Value = menuConfig[options.Flag]
    end

    local function Update(val)
        Value = math.clamp(val, Min, Max)
        local percent = (Value - Min) / (Max - Min)
        Fill.Size = UDim2.new(percent, 0, 1, 0)
        ValueLabel.Text = tostring(Value) .. (options.Suffix or "")

        if options.Callback then options.Callback(Value) end
        if options.Flag then saveMenuConfig(options.Flag, Value) end
    end

    local dragging = false
    SliderBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            local pos = math.clamp((input.Position.X - SliderBar.AbsolutePosition.X) / SliderBar.AbsoluteSize.X, 0, 1)
            local newVal = math.floor(Min + ((Max - Min) * pos))
            Update(newVal)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local pos = math.clamp((input.Position.X - SliderBar.AbsolutePosition.X) / SliderBar.AbsoluteSize.X, 0, 1)
            local newVal = math.floor(Min + ((Max - Min) * pos))
            Update(newVal)
        end
    end)

    Update(Value)

    local API = {}
    function API:Set(val) Update(val) end
    return API
end