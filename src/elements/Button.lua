return function(options, themeManager, parent, menuConfig, saveMenuConfig, addConnection)
    local TweenService = game:GetService("TweenService")

    local Button = Instance.new("TextButton")
    Button.Name = options.Name or "Button"
    Button.Text = ""
    Button.Size = UDim2.new(1, 0, 0, 42)
    Button.AutoButtonColor = false
    Button.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    Button.Parent = parent

    if themeManager and themeManager.Register then
        themeManager:Register(Button, "BackgroundColor3", "Secondary")
    end

    Instance.new("UICorner", Button).CornerRadius = UDim.new(0, 8)

    local Stroke = Instance.new("UIStroke", Button)
    Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    Stroke.Thickness = 1
    Stroke.Color = Color3.fromRGB(55, 55, 60)
    if themeManager and themeManager.Register then
        themeManager:Register(Stroke, "Color", "Accent")
    end

    local Label = Instance.new("TextLabel")
    Label.Name = "Label"
    Label.Size = UDim2.new(1, -20, 1, 0)
    Label.Position = UDim2.new(0, 10, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Font = Enum.Font.GothamMedium
    Label.TextSize = 13
    Label.Text = options.Name or "Button"
    Label.TextColor3 = Color3.fromRGB(255, 255, 255)
    Label.TextXAlignment = Enum.TextXAlignment.Center
    Label.Parent = Button
    if themeManager and themeManager.Register then
        themeManager:Register(Label, "TextColor3", "Text")
    end

    -- Smooth Hover animations
    Button.MouseEnter:Connect(function()
        TweenService:Create(Button, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(36, 36, 42)
        }):Play()
        TweenService:Create(Stroke, TweenInfo.new(0.2), {
            Color = Color3.fromRGB(85, 85, 95)
        }):Play()
    end)

    Button.MouseLeave:Connect(function()
        TweenService:Create(Button, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(25, 25, 25)
        }):Play()
        TweenService:Create(Stroke, TweenInfo.new(0.2), {
            Color = Color3.fromRGB(55, 55, 60)
        }):Play()
    end)

    if options.Callback then
        Button.MouseButton1Click:Connect(function()
            local tw = TweenService:Create(Button, TweenInfo.new(0.08), {
                BackgroundColor3 = Color3.fromRGB(48, 48, 56)
            })
            tw:Play()
            tw.Completed:Connect(function()
                TweenService:Create(Button, TweenInfo.new(0.15), {
                    BackgroundColor3 = Color3.fromRGB(36, 36, 42)
                }):Play()
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