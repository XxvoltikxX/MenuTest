return function(options, themeManager, parent, menuConfig, saveMenuConfig, addConnection, passedIcons)
    local TweenService = game:GetService("TweenService")
    local RunService = game:GetService("RunService")

    local Icons = passedIcons or (typeof(getgenv) == "function" and getgenv()._MenuTestIconsModule) or _G._MenuTestIconsModule
    if not Icons then
        if typeof(readfile) == "function" then
            local s, d = pcall(readfile, "MenuTest/src/Icons.lua")
            if s and d and #d > 0 then
                local chunk = loadstring(d)
                if chunk then Icons = chunk() end
            end
        end
    end
    if not Icons then
        local ok, res = pcall(function()
            return game:HttpGet("https://raw.githubusercontent.com/xxCichyxx/MenuTest/refs/heads/main/src/Icons.lua")
        end)
        if ok and res then
            local chunk = loadstring(res)
            if chunk then Icons = chunk() end
        end
    end
    if Icons then
        if typeof(getgenv) == "function" then getgenv()._MenuTestIconsModule = Icons end
        _G._MenuTestIconsModule = Icons
    end

    local Colors = {
        Background = Color3.fromRGB(18, 18, 22),
        Stroke = Color3.fromRGB(45, 45, 52),
        Text = Color3.fromRGB(255, 255, 255),
        TextDim = Color3.fromRGB(150, 150, 160),
        Accent = Color3.fromRGB(255, 255, 255)
    }

    local DropdownFrame = Instance.new("Frame")
    DropdownFrame.Name = options.Name or "Dropdown"
    DropdownFrame.Size = UDim2.new(1, 0, 0, 35)
    DropdownFrame.BackgroundTransparency = 1
    DropdownFrame.ZIndex = 2
    DropdownFrame.Parent = parent

    local Main = Instance.new("TextButton")
    Main.Size = UDim2.new(1, 0, 0, 35)
    Main.BackgroundColor3 = Colors.Background
    Main.Text = ""
    Main.Parent = DropdownFrame

    Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 6)
    local Stroke = Instance.new("UIStroke", Main)
    Stroke.Color = Colors.Stroke
    Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    local Label = Instance.new("TextLabel")
    Label.Text = options.Name
    Label.Font = Enum.Font.GothamMedium
    Label.TextSize = 12
    Label.TextColor3 = Colors.TextDim
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Size = UDim2.new(1, -30, 1, 0)
    Label.Position = UDim2.new(0, 10, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Parent = Main

    local Icon = Instance.new("ImageLabel")
    Icon.Size = UDim2.new(0, 16, 0, 16)
    Icon.Position = UDim2.new(1, -26, 0.5, 0)
    Icon.AnchorPoint = Vector2.new(0, 0.5)
    Icon.BackgroundTransparency = 1
    Icon.ImageColor3 = Colors.TextDim
    Icon.Parent = Main
    if Icons then Icons:Apply(Icon, "chevron-down") end

    local Options = options.Options or {}
    local CurrentOption = options.CurrentOption or {Options[1]}
    if options.Flag and menuConfig[options.Flag] ~= nil then
        CurrentOption = menuConfig[options.Flag]
    end

    local function UpdateLabel()
        Label.Text = options.Name .. ": " .. table.concat(CurrentOption, ", ")
    end
    UpdateLabel()

    -- LISTA (Portal / CoreGui)
    local ScreenGui = parent:FindFirstAncestorOfClass("ScreenGui")
    local List = Instance.new("Frame")
    List.Size = UDim2.new(1, 0, 0, 0)
    List.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
    List.Visible = false
    List.ZIndex = 100
    List.ClipsDescendants = true
    List.Parent = ScreenGui
    Instance.new("UICorner", List).CornerRadius = UDim.new(0, 6)
    local ListStroke = Instance.new("UIStroke", List)
    ListStroke.Color = Colors.Stroke
    ListStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    local Scroll = Instance.new("ScrollingFrame")
    Scroll.Size = UDim2.new(1, 0, 1, 0)
    Scroll.BackgroundTransparency = 1
    Scroll.ScrollBarThickness = 2
    Scroll.Parent = List
    local Layout = Instance.new("UIListLayout", Scroll)

    local isOpen = false
    local function Toggle()
        isOpen = not isOpen
        List.Visible = isOpen

        if isOpen then
            if Icons then Icons:Apply(Icon, "chevron-up") end
            local absPos = Main.AbsolutePosition
            local absSize = Main.AbsoluteSize
            List.Position = UDim2.new(0, absPos.X, 0, absPos.Y + absSize.Y + 5)
            List.Size = UDim2.new(0, absSize.X, 0, math.min(#Options * 30, 150))
            Scroll.CanvasSize = UDim2.new(0, 0, 0, #Options * 30)
        else
            if Icons then Icons:Apply(Icon, "chevron-down") end
        end
    end

    Main.MouseButton1Click:Connect(Toggle)

    RunService.RenderStepped:Connect(function()
        if isOpen and Main.Parent then
            local absPos = Main.AbsolutePosition
            local absSize = Main.AbsoluteSize
            List.Position = UDim2.new(0, absPos.X, 0, absPos.Y + absSize.Y + 5)
        elseif isOpen and not Main.Parent then
            Toggle()
        end
    end)

    local function RefreshList()
        for _, child in pairs(Scroll:GetChildren()) do
            if child:IsA("TextButton") then child:Destroy() end
        end

        for _, opt in ipairs(Options) do
            local Item = Instance.new("TextButton")
            Item.Size = UDim2.new(1, 0, 0, 30)
            Item.BackgroundTransparency = 1
            Item.Text = "   " .. opt
            Item.Font = Enum.Font.Gotham
            Item.TextSize = 12
            Item.TextColor3 = Colors.TextDim
            Item.TextXAlignment = Enum.TextXAlignment.Left
            Item.Parent = Scroll

            local isSelected = false
            for _, s in ipairs(CurrentOption) do if s == opt then isSelected = true break end end
            if isSelected then Item.TextColor3 = Colors.Accent end

            Item.MouseButton1Click:Connect(function()
                if not options.MultipleOptions then
                    CurrentOption = {opt}
                    UpdateLabel()
                    Toggle()
                    if options.Callback then options.Callback(CurrentOption) end
                    if options.Flag then saveMenuConfig(options.Flag, CurrentOption) end
                end
                RefreshList()
            end)
        end
    end
    RefreshList()

    local API = {}
    function API:Refresh(newOptions) Options = newOptions RefreshList() end
    function API:Set(newOption)
        CurrentOption = type(newOption) == "table" and newOption or {newOption}
        UpdateLabel()
        RefreshList()
        if options.Callback then options.Callback(CurrentOption) end
        if options.Flag and saveMenuConfig then saveMenuConfig(options.Flag, CurrentOption) end
    end
    return API
end