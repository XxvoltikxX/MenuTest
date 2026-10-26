-- // ==========================================================================
-- // MENUTEST ULTRA-MODERN SLIDER COMPONENT
-- // Nowoczesny, płynny suwak z gradientem wypełnienia, poświatą neonową gałki,
-- // animowanym floating tooltipem podczas przeciągania, bezpośrednią edycją
-- // wartości przez kliknięcie w plakietkę oraz wsparciem dla kroków (Step/Precision).
-- // ==========================================================================

return function(options, themeManager, parent, menuConfig, saveMenuConfig)
    local UserInputService = game:GetService("UserInputService")
    local TweenService = game:GetService("TweenService")

    options = options or {}
    local sliderName = options.Name or "Slider"
    local sliderSuffix = options.Suffix or ""
    local stepValue = options.Step or options.Increment or 1
    local precise = options.Precise or (stepValue % 1 ~= 0)
    local decimals = options.Decimals or (precise and 1 or 0)

    local Min = (options.Range and options.Range[1]) or options.Min or 0
    local Max = (options.Range and options.Range[2]) or options.Max or 100
    if Min > Max then Min, Max = Max, Min end

    local function getThemeColor(colorKey, fallback)
        if themeManager and themeManager.GetColor then
            local c = themeManager:GetColor(colorKey)
            if c then return c end
        end
        return fallback
    end

    local SliderFrame = Instance.new("Frame")
    SliderFrame.Name = "Slider_" .. sliderName
    SliderFrame.Size = UDim2.new(1, 0, 0, 56)
    SliderFrame.BackgroundColor3 = Color3.fromRGB(18, 19, 29)
    SliderFrame.BackgroundTransparency = 0.5
    SliderFrame.ClipsDescendants = false
    SliderFrame.Parent = parent

    local FrameCorner = Instance.new("UICorner", SliderFrame)
    FrameCorner.CornerRadius = UDim.new(0, 12)

    local FrameStroke = Instance.new("UIStroke", SliderFrame)
    FrameStroke.Color = Color3.fromRGB(50, 60, 90)
    FrameStroke.Thickness = 1
    FrameStroke.Transparency = 0.6
    FrameStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    local FramePadding = Instance.new("UIPadding", SliderFrame)
    FramePadding.PaddingLeft = UDim.new(0, 12)
    FramePadding.PaddingRight = UDim.new(0, 12)
    FramePadding.PaddingTop = UDim.new(0, 8)
    FramePadding.PaddingBottom = UDim.new(0, 10)

    SliderFrame.MouseEnter:Connect(function()
        TweenService:Create(FrameStroke, TweenInfo.new(0.18), { Color = Color3.fromRGB(90, 105, 155), Transparency = 0.3 }):Play()
        TweenService:Create(SliderFrame, TweenInfo.new(0.18), { BackgroundTransparency = 0.25 }):Play()
    end)
    SliderFrame.MouseLeave:Connect(function()
        TweenService:Create(FrameStroke, TweenInfo.new(0.18), { Color = Color3.fromRGB(50, 60, 90), Transparency = 0.6 }):Play()
        TweenService:Create(SliderFrame, TweenInfo.new(0.18), { BackgroundTransparency = 0.4 }):Play()
    end)

    -- Górny wiersz: Tytuł + Plakietka wartości
    local TopRow = Instance.new("Frame")
    TopRow.Name = "TopRow"
    TopRow.Size = UDim2.new(1, 0, 0, 20)
    TopRow.BackgroundTransparency = 1
    TopRow.Parent = SliderFrame

    local Label = Instance.new("TextLabel")
    Label.Name = "Label"
    Label.Text = sliderName
    Label.Font = Enum.Font.GothamBold
    Label.TextSize = 11
    Label.TextColor3 = getThemeColor("Text", Color3.fromRGB(225, 230, 245))
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Size = UDim2.new(1, -95, 1, 0)
    Label.Position = UDim2.new(0, 0, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Parent = TopRow

    -- Plakietka wartości (Apple VisionOS Value Pill Capsule)
    local ValueBadge = Instance.new("Frame")
    ValueBadge.Name = "ValueBadge"
    ValueBadge.Size = UDim2.new(0, 80, 0, 20)
    ValueBadge.Position = UDim2.new(1, 0, 0, 0)
    ValueBadge.AnchorPoint = Vector2.new(1, 0)
    ValueBadge.BackgroundColor3 = Color3.fromRGB(28, 33, 52)
    ValueBadge.BackgroundTransparency = 0.35
    ValueBadge.Parent = TopRow

    local BadgeCorner = Instance.new("UICorner", ValueBadge)
    BadgeCorner.CornerRadius = UDim.new(1, 0)

    local BadgeStroke = Instance.new("UIStroke", ValueBadge)
    BadgeStroke.Color = Color3.fromRGB(75, 88, 130)
    BadgeStroke.Thickness = 1
    BadgeStroke.Transparency = 0.5
    BadgeStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    local ValueLabel = Instance.new("TextLabel")
    ValueLabel.Name = "ValueLabel"
    ValueLabel.Font = Enum.Font.GothamBold
    ValueLabel.TextSize = 11
    ValueLabel.TextColor3 = Color3.fromRGB(165, 180, 252)
    ValueLabel.TextXAlignment = Enum.TextXAlignment.Center
    ValueLabel.Size = UDim2.new(1, 0, 1, 0)
    ValueLabel.BackgroundTransparency = 1
    ValueLabel.Parent = ValueBadge

    local ValueBox = Instance.new("TextBox")
    ValueBox.Name = "ValueBox"
    ValueBox.Font = Enum.Font.GothamBold
    ValueBox.TextSize = 11
    ValueBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    ValueBox.TextXAlignment = Enum.TextXAlignment.Center
    ValueBox.Size = UDim2.new(1, 0, 1, 0)
    ValueBox.BackgroundTransparency = 1
    ValueBox.ClearTextOnFocus = false
    ValueBox.Visible = false
    ValueBox.Parent = ValueBadge

    -- Tor suwaka (Track)
    local SliderBar = Instance.new("Frame")
    SliderBar.Name = "Track"
    SliderBar.Size = UDim2.new(1, 0, 0, 6)
    SliderBar.Position = UDim2.new(0, 0, 0, 30)
    SliderBar.BackgroundColor3 = Color3.fromRGB(12, 13, 20)
    SliderBar.ClipsDescendants = false
    SliderBar.Parent = SliderFrame

    local BarCorner = Instance.new("UICorner", SliderBar)
    BarCorner.CornerRadius = UDim.new(1, 0)

    local BarStroke = Instance.new("UIStroke", SliderBar)
    BarStroke.Color = Color3.fromRGB(30, 32, 46)
    BarStroke.Thickness = 1
    BarStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    -- Wypełnienie paska (Fill z gradientem)
    local Fill = Instance.new("Frame")
    Fill.Name = "Fill"
    Fill.Size = UDim2.new(0, 0, 1, 0)
    Fill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Fill.ClipsDescendants = false
    Fill.Parent = SliderBar

    local FillCorner = Instance.new("UICorner", Fill)
    FillCorner.CornerRadius = UDim.new(1, 0)

    local FillGradient = Instance.new("UIGradient", Fill)
    FillGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(99, 102, 241)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(168, 85, 247))
    })

    -- Gałka suwaka (Knob z efektem neonowej kropki)
    local Knob = Instance.new("Frame")
    Knob.Name = "Knob"
    Knob.Size = UDim2.new(0, 14, 0, 14)
    Knob.Position = UDim2.new(1, 0, 0.5, 0)
    Knob.AnchorPoint = Vector2.new(0.5, 0.5)
    Knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Knob.ZIndex = 5
    Knob.Parent = Fill

    local KnobCorner = Instance.new("UICorner", Knob)
    KnobCorner.CornerRadius = UDim.new(1, 0)

    local KnobStroke = Instance.new("UIStroke", Knob)
    KnobStroke.Color = Color3.fromRGB(99, 102, 241)
    KnobStroke.Thickness = 2

    local KnobGlow = Instance.new("Frame")
    KnobGlow.Name = "InnerGlow"
    KnobGlow.Size = UDim2.new(0, 6, 0, 6)
    KnobGlow.Position = UDim2.new(0.5, 0, 0.5, 0)
    KnobGlow.AnchorPoint = Vector2.new(0.5, 0.5)
    KnobGlow.BackgroundColor3 = Color3.fromRGB(99, 102, 241)
    KnobGlow.Parent = Knob
    Instance.new("UICorner", KnobGlow).CornerRadius = UDim.new(1, 0)

    -- Pływający Tooltip (Floating Bubble podczas przeciągania)
    local Tooltip = Instance.new("Frame")
    Tooltip.Name = "Tooltip"
    Tooltip.Size = UDim2.new(0, 48, 0, 22)
    Tooltip.Position = UDim2.new(0.5, 0, 0, -26)
    Tooltip.AnchorPoint = Vector2.new(0.5, 1)
    Tooltip.BackgroundColor3 = getThemeColor("Main", Color3.fromRGB(15, 15, 20))
    Tooltip.BackgroundTransparency = 1
    Tooltip.Visible = false
    Tooltip.ZIndex = 15
    Tooltip.Parent = Knob

    Instance.new("UICorner", Tooltip).CornerRadius = UDim.new(0, 6)
    local TooltipStroke = Instance.new("UIStroke", Tooltip)
    TooltipStroke.Color = getThemeColor("Accent", Color3.fromRGB(60, 60, 75))
    TooltipStroke.Thickness = 1
    TooltipStroke.Transparency = 1

    local TooltipLabel = Instance.new("TextLabel")
    TooltipLabel.Size = UDim2.new(1, 0, 1, 0)
    TooltipLabel.BackgroundTransparency = 1
    TooltipLabel.Font = Enum.Font.GothamBold
    TooltipLabel.TextSize = 10
    TooltipLabel.TextColor3 = getThemeColor("Text", Color3.fromRGB(255, 255, 255))
    TooltipLabel.TextTransparency = 1
    TooltipLabel.ZIndex = 16
    TooltipLabel.Parent = Tooltip

    -- Powiększony obszar dotykowy dla urządzeń mobilnych
    local TouchArea = Instance.new("TextButton")
    TouchArea.Name = "TouchArea"
    TouchArea.Size = UDim2.new(1, 0, 0, 32)
    TouchArea.Position = UDim2.new(0, 0, 0, 20)
    TouchArea.BackgroundTransparency = 1
    TouchArea.Text = ""
    TouchArea.ZIndex = 8
    TouchArea.Parent = SliderFrame

    local scrollParent = parent:FindFirstAncestorOfClass("ScrollingFrame")

    -- Logika wartości
    local Value = options.CurrentValue or options.Default or Min
    if options.Flag and menuConfig and menuConfig[options.Flag] ~= nil then
        Value = menuConfig[options.Flag]
    end

    local function formatValue(val)
        if decimals > 0 then
            return string.format("%." .. tostring(decimals) .. "f", val)
        else
            return tostring(math.floor(val + 0.5))
        end
    end

    local function updateThemeColors()
        Label.TextColor3 = getThemeColor("Text", Color3.fromRGB(240, 240, 245))
        ValueBadge.BackgroundColor3 = getThemeColor("Accent2", Color3.fromRGB(30, 30, 36))
        BadgeStroke.Color = getThemeColor("Accent", Color3.fromRGB(50, 50, 60))
        ValueLabel.TextColor3 = getThemeColor("Text", Color3.fromRGB(255, 255, 255))
        ValueBox.TextColor3 = getThemeColor("Text", Color3.fromRGB(255, 255, 255))
        SliderBar.BackgroundColor3 = getThemeColor("Main", Color3.fromRGB(18, 18, 22))
        BarStroke.Color = getThemeColor("Accent", Color3.fromRGB(42, 42, 50))
        Fill.BackgroundColor3 = getThemeColor("Text", Color3.fromRGB(255, 255, 255))
        Knob.BackgroundColor3 = getThemeColor("Text", Color3.fromRGB(255, 255, 255))
        KnobStroke.Color = getThemeColor("Main", Color3.fromRGB(25, 25, 30))
        KnobGlow.BackgroundColor3 = getThemeColor("Main", Color3.fromRGB(30, 30, 35))
        Tooltip.BackgroundColor3 = getThemeColor("Main", Color3.fromRGB(15, 15, 20))
        TooltipStroke.Color = getThemeColor("Accent", Color3.fromRGB(60, 60, 75))
        TooltipLabel.TextColor3 = getThemeColor("Text", Color3.fromRGB(255, 255, 255))
        FillGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, getThemeColor("Accent2", Color3.fromRGB(100, 140, 255))),
            ColorSequenceKeypoint.new(1, getThemeColor("Text", Color3.fromRGB(255, 255, 255)))
        })
    end

    if themeManager and themeManager.OnThemeChanged then
        themeManager:OnThemeChanged(function()
            updateThemeColors()
        end)
    end

    local function ApplyValue(newVal, fireCallback)
        newVal = math.clamp(newVal, Min, Max)
        if stepValue and stepValue > 0 then
            newVal = math.floor((newVal - Min) / stepValue + 0.5) * stepValue + Min
            newVal = math.clamp(newVal, Min, Max)
        end
        Value = newVal

        local percent = (Max > Min) and ((Value - Min) / (Max - Min)) or 0
        percent = math.clamp(percent, 0, 1)

        TweenService:Create(Fill, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(percent, 0, 1, 0)
        }):Play()

        local formatted = formatValue(Value)
        ValueLabel.Text = formatted .. (sliderSuffix ~= "" and (" " .. sliderSuffix) or "")
        TooltipLabel.Text = formatted

        if fireCallback ~= false then
            if options.Callback then options.Callback(Value) end
            if options.Flag and saveMenuConfig then saveMenuConfig(options.Flag, Value) end
        end
    end

    local dragging = false

    local function showTooltip()
        Tooltip.Visible = true
        TweenService:Create(Tooltip, TweenInfo.new(0.15), {BackgroundTransparency = 0.1}):Play()
        TweenService:Create(TooltipStroke, TweenInfo.new(0.15), {Transparency = 0}):Play()
        TweenService:Create(TooltipLabel, TweenInfo.new(0.15), {TextTransparency = 0}):Play()
        TweenService:Create(Knob, TweenInfo.new(0.15), {Size = UDim2.new(0, 18, 0, 18)}):Play()
    end

    local function hideTooltip()
        local tw = TweenService:Create(Tooltip, TweenInfo.new(0.2), {BackgroundTransparency = 1})
        tw:Play()
        TweenService:Create(TooltipStroke, TweenInfo.new(0.2), {Transparency = 1}):Play()
        TweenService:Create(TooltipLabel, TweenInfo.new(0.2), {TextTransparency = 1}):Play()
        TweenService:Create(Knob, TweenInfo.new(0.2), {Size = UDim2.new(0, 14, 0, 14)}):Play()
        tw.Completed:Connect(function()
            if not dragging then Tooltip.Visible = false end
        end)
    end

    local function processInput(input)
        local barX = SliderBar.AbsolutePosition.X
        local barW = SliderBar.AbsoluteSize.X
        if barW <= 0 then return end
        local pos = math.clamp((input.Position.X - barX) / barW, 0, 1)
        local calculated = Min + ((Max - Min) * pos)
        ApplyValue(calculated, true)
    end

    TouchArea.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            if scrollParent then scrollParent.ScrollingEnabled = false end
            showTooltip()
            processInput(input)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if dragging then
                dragging = false
                if scrollParent then scrollParent.ScrollingEnabled = true end
                hideTooltip()
            end
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            processInput(input)
        end
    end)

    -- Bezpośrednia edycja wartości przez kliknięcie w plakietkę (Direct typing)
    ValueBadge.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            ValueLabel.Visible = false
            ValueBox.Visible = true
            ValueBox.Text = tostring(Value)
            ValueBox:CaptureFocus()
        end
    end)

    ValueBox.FocusLost:Connect(function()
        local num = tonumber(ValueBox.Text)
        if num then
            ApplyValue(num, true)
        end
        ValueBox.Visible = false
        ValueLabel.Visible = true
    end)

    -- Inicjalizacja początkowa
    ApplyValue(Value, false)

    local API = {}
    function API:Set(val)
        ApplyValue(tonumber(val) or Min, true)
    end
    function API:GetValue()
        return Value
    end

    return API
end