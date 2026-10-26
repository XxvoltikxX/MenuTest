return function(options, themeManager, parent, menuConfig, saveMenuConfig, addConnection)
    local TweenService = game:GetService("TweenService")

    local function getThemeColor(colorKey, fallback)
        if themeManager and themeManager.GetColor then
            local c = themeManager:GetColor(colorKey)
            if c then return c end
        end
        return fallback
    end

    local Button = Instance.new("TextButton")
    Button.Name = options.Name or "Button"
    Button.Text = ""
    Button.Size = UDim2.new(1, 0, 0, 38)
    Button.AutoButtonColor = false
    Button.BackgroundColor3 = Color3.fromRGB(22, 24, 34)
    Button.BorderSizePixel = 0
    Button.Parent = parent

    Instance.new("UICorner", Button).CornerRadius = UDim.new(0, 8)

    local Stroke = Instance.new("UIStroke", Button)
    Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    Stroke.Thickness = 1
    Stroke.Color = Color3.fromRGB(42, 45, 62)

    local ButtonGradient = Instance.new("UIGradient", Button)
    ButtonGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(25, 27, 40)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(19, 20, 30))
    })
    ButtonGradient.Rotation = 90

    local Padding = Instance.new("UIPadding", Button)
    Padding.PaddingLeft = UDim.new(0, 14)
    Padding.PaddingRight = UDim.new(0, 14)

    local Label = Instance.new("TextLabel")
    Label.Name = "Label"
    Label.Size = UDim2.new(1, -24, 1, 0)
    Label.Position = UDim2.new(0, 0, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Font = Enum.Font.GothamBold
    Label.TextSize = 12
    Label.Text = options.Name or "Button"
    Label.TextColor3 = Color3.fromRGB(241, 245, 249)
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Button

    local Arrow = Instance.new("TextLabel")
    Arrow.Name = "Arrow"
    Arrow.Size = UDim2.new(0, 18, 1, 0)
    Arrow.Position = UDim2.new(1, -18, 0, 0)
    Arrow.BackgroundTransparency = 1
    Arrow.Font = Enum.Font.GothamBold
    Arrow.Text = "→"
    Arrow.TextSize = 13
    Arrow.TextColor3 = Color3.fromRGB(129, 140, 248)
    Arrow.TextXAlignment = Enum.TextXAlignment.Right
    Arrow.Parent = Button

    -- Hover & click animations
    Button.MouseEnter:Connect(function()
        TweenService:Create(Button, TweenInfo.new(0.18), {BackgroundColor3 = Color3.fromRGB(32, 35, 52)}):Play()
        TweenService:Create(Stroke, TweenInfo.new(0.18), {Color = Color3.fromRGB(99, 102, 241)}):Play()
        TweenService:Create(Arrow, TweenInfo.new(0.18), {TextColor3 = Color3.fromRGB(192, 132, 252)}):Play()
    end)

    Button.MouseLeave:Connect(function()
        TweenService:Create(Button, TweenInfo.new(0.18), {BackgroundColor3 = Color3.fromRGB(22, 24, 34)}):Play()
        TweenService:Create(Stroke, TweenInfo.new(0.18), {Color = Color3.fromRGB(42, 45, 62)}):Play()
        TweenService:Create(Arrow, TweenInfo.new(0.18), {TextColor3 = Color3.fromRGB(129, 140, 248)}):Play()
    end)

    if options.Callback then
        Button.Activated:Connect(function()
            local tw = TweenService:Create(Button, TweenInfo.new(0.08), {BackgroundColor3 = Color3.fromRGB(48, 52, 78)})
            tw:Play()
            tw.Completed:Connect(function()
                TweenService:Create(Button, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(22, 24, 34)}):Play()
            end)
            pcall(options.Callback)
        end)
    end

    local API = {}
    function API:Set(text)
        Label.Text = text
    end
    return API
end