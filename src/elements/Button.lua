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
    Button.Size = UDim2.new(1, 0, 0, 42)
    Button.AutoButtonColor = false
    Button.BackgroundColor3 = getThemeColor("Secondary", Color3.fromRGB(25, 25, 25))
    Button.Parent = parent

    Instance.new("UICorner", Button).CornerRadius = UDim.new(0, 8)

    local Stroke = Instance.new("UIStroke", Button)
    Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    Stroke.Thickness = 1
    Stroke.Color = getThemeColor("Accent", Color3.fromRGB(55, 55, 60))

    local Label = Instance.new("TextLabel")
    Label.Name = "Label"
    Label.Size = UDim2.new(1, -20, 1, 0)
    Label.Position = UDim2.new(0, 10, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Font = Enum.Font.GothamMedium
    Label.TextSize = 13
    Label.Text = options.Name or "Button"
    Label.TextColor3 = getThemeColor("Text", Color3.fromRGB(255, 255, 255))
    Label.TextXAlignment = Enum.TextXAlignment.Center
    Label.Parent = Button

    if themeManager and themeManager.Register then
        themeManager:Register(Button, "BackgroundColor3", "Secondary")
        themeManager:Register(Stroke, "Color", "Accent")
        themeManager:Register(Label, "TextColor3", "Text")
    end

    -- Smooth Hover animations z dynamicznymi kolorami motywu
    Button.MouseEnter:Connect(function()
        local hoverBg = getThemeColor("Accent2", Color3.fromRGB(36, 36, 42))
        local hoverStroke = getThemeColor("Text_Secondary", Color3.fromRGB(85, 85, 95))
        TweenService:Create(Button, TweenInfo.new(0.2), {BackgroundColor3 = hoverBg}):Play()
        TweenService:Create(Stroke, TweenInfo.new(0.2), {Color = hoverStroke}):Play()
    end)

    Button.MouseLeave:Connect(function()
        local normalBg = getThemeColor("Secondary", Color3.fromRGB(25, 25, 25))
        local normalStroke = getThemeColor("Accent", Color3.fromRGB(55, 55, 60))
        TweenService:Create(Button, TweenInfo.new(0.2), {BackgroundColor3 = normalBg}):Play()
        TweenService:Create(Stroke, TweenInfo.new(0.2), {Color = normalStroke}):Play()
    end)

    if options.Callback then
        Button.MouseButton1Click:Connect(function()
            local clickBg = getThemeColor("Accent", Color3.fromRGB(48, 48, 56))
            local tw = TweenService:Create(Button, TweenInfo.new(0.08), {BackgroundColor3 = clickBg})
            tw:Play()
            tw.Completed:Connect(function()
                local hoverBg = getThemeColor("Accent2", Color3.fromRGB(36, 36, 42))
                TweenService:Create(Button, TweenInfo.new(0.15), {BackgroundColor3 = hoverBg}):Play()
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