return function(options, themeManager, parent, menuConfig, saveMenuConfig)
    local function getThemeColor(colorKey, fallback)
        if themeManager and themeManager.GetColor then
            local c = themeManager:GetColor(colorKey)
            if c then return c end
        end
        return fallback
    end

    local InputFrame = Instance.new("Frame")
    InputFrame.Name = options.Name or "Input"
    InputFrame.Size = UDim2.new(1, 0, 0, 35)
    InputFrame.BackgroundTransparency = 1
    InputFrame.Parent = parent

    local Main = Instance.new("TextBox")
    Main.Size = UDim2.new(1, 0, 1, 0)
    Main.BackgroundColor3 = getThemeColor("Main", Color3.fromRGB(31, 31, 38))
    Main.Font = Enum.Font.Gotham
    Main.TextSize = 13
    Main.TextColor3 = getThemeColor("Text", Color3.fromRGB(255, 255, 255))
    Main.PlaceholderColor3 = getThemeColor("Text_Secondary", Color3.fromRGB(150, 150, 150))
    Main.TextXAlignment = Enum.TextXAlignment.Left
    Main.ClearTextOnFocus = false
    Main.Text = options.CurrentValue or ""
    Main.PlaceholderText = options.PlaceholderText or "Enter Text Here..."
    Main.Parent = InputFrame

    Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 6)
    local Stroke = Instance.new("UIStroke", Main)
    Stroke.Color = getThemeColor("Accent", Color3.fromRGB(50, 50, 60))
    Stroke.Thickness = 1
    Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    local Padding = Instance.new("UIPadding", Main)
    Padding.PaddingLeft = UDim.new(0, 10)
    Padding.PaddingRight = UDim.new(0, 10)

    if themeManager and themeManager.Register then
        themeManager:Register(Main, "BackgroundColor3", "Main")
        themeManager:Register(Main, "TextColor3", "Text")
        themeManager:Register(Main, "PlaceholderColor3", "Text_Secondary")
        themeManager:Register(Stroke, "Color", "Accent")
    end

    -- Logika
    if options.Flag and menuConfig and menuConfig[options.Flag] ~= nil then
        Main.Text = menuConfig[options.Flag]
    end

    Main.FocusLost:Connect(function(enterPressed)
        if options.Callback then options.Callback(Main.Text) end
        if options.Flag and saveMenuConfig then saveMenuConfig(options.Flag, Main.Text) end
        if options.RemoveTextAfterFocusLost then
            Main.Text = ""
        end
    end)

    local API = {}
    function API:Set(text)
        Main.Text = text
    end

    return API
end