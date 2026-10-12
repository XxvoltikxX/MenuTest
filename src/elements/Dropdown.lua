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

    local function getThemeColor(colorKey, fallback)
        if themeManager and themeManager.GetColor then
            local c = themeManager:GetColor(colorKey)
            if c then return c end
        end
        return fallback
    end

    local DropdownFrame = Instance.new("Frame")
    DropdownFrame.Name = options.Name or "Dropdown"
    DropdownFrame.Size = UDim2.new(1, 0, 0, 35)
    DropdownFrame.BackgroundTransparency = 1
    DropdownFrame.ZIndex = 2
    DropdownFrame.Parent = parent

    local Main = Instance.new("TextButton")
    Main.Size = UDim2.new(1, 0, 0, 35)
    Main.BackgroundColor3 = getThemeColor("Secondary", Color3.fromRGB(18, 18, 22))
    Main.Text = ""
    Main.Parent = DropdownFrame

    Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 6)
    local Stroke = Instance.new("UIStroke", Main)
    Stroke.Color = getThemeColor("Accent", Color3.fromRGB(45, 45, 52))
    Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    local Label = Instance.new("TextLabel")
    Label.Text = options.Name
    Label.Font = Enum.Font.GothamMedium
    Label.TextSize = 12
    Label.TextColor3 = getThemeColor("Text_Secondary", Color3.fromRGB(150, 150, 160))
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
    Icon.ImageColor3 = getThemeColor("Text_Secondary", Color3.fromRGB(150, 150, 160))
    Icon.Parent = Main
    if Icons then Icons:Apply(Icon, "chevron-down") end

    if themeManager and themeManager.Register then
        themeManager:Register(Main, "BackgroundColor3", "Secondary")
        themeManager:Register(Stroke, "Color", "Accent")
        themeManager:Register(Label, "TextColor3", "Text_Secondary")
        themeManager:Register(Icon, "ImageColor3", "Text_Secondary")
    end

    local Options = options.Options or {}
    local CurrentOption = options.CurrentOption or {Options[1]}
    if options.Flag and menuConfig and menuConfig[options.Flag] ~= nil then
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
    List.BackgroundColor3 = getThemeColor("Main", Color3.fromRGB(24, 24, 28))
    List.Visible = false
    List.ZIndex = 100
    List.ClipsDescendants = true
    List.Parent = ScreenGui
    Instance.new("UICorner", List).CornerRadius = UDim.new(0, 6)
    local ListStroke = Instance.new("UIStroke", List)
    ListStroke.Color = getThemeColor("Accent", Color3.fromRGB(45, 45, 52))
    ListStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    if themeManager and themeManager.Register then
        themeManager:Register(List, "BackgroundColor3", "Main")
        themeManager:Register(ListStroke, "Color", "Accent")
    end

    local Scroll = Instance.new("ScrollingFrame")
    Scroll.Size = UDim2.new(1, 0, 1, 0)
    Scroll.BackgroundTransparency = 1
    Scroll.ScrollBarThickness = 2
    Scroll.Parent = List
    local Layout = Instance.new("UIListLayout", Scroll)

    local isOpen = false
    local function updateDropdownPosition()
        if not isOpen or not Main.Parent then return end
        local camera = workspace.CurrentCamera
        local vp = camera and camera.ViewportSize or Vector2.new(1280, 720)
        local absPos = Main.AbsolutePosition
        local absSize = Main.AbsoluteSize
        local targetH = math.min(#Options * 32, 140)
        local openUp = (absPos.Y + absSize.Y + targetH + 10 > vp.Y) and (absPos.Y - targetH - 5 >= 0)
        local posY = openUp and (absPos.Y - targetH - 5) or (absPos.Y + absSize.Y + 5)
        List.Position = UDim2.new(0, absPos.X, 0, posY)
        List.Size = UDim2.new(0, absSize.X, 0, targetH)
        Scroll.CanvasSize = UDim2.new(0, 0, 0, #Options * 32)
    end

    local function Toggle()
        isOpen = not isOpen
        List.Visible = isOpen

        if isOpen then
            if Icons then Icons:Apply(Icon, "chevron-up") end
            updateDropdownPosition()
        else
            if Icons then Icons:Apply(Icon, "chevron-down") end
        end
    end

    Main.Activated:Connect(Toggle)

    RunService.RenderStepped:Connect(function()
        if isOpen and Main.Parent then
            updateDropdownPosition()
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
            Item.Size = UDim2.new(1, 0, 0, 32)
            Item.BackgroundTransparency = 1
            Item.Text = "   " .. opt
            Item.Font = Enum.Font.Gotham
            Item.TextSize = 12
            Item.TextColor3 = getThemeColor("Text_Secondary", Color3.fromRGB(150, 150, 160))
            Item.TextXAlignment = Enum.TextXAlignment.Left
            Item.Parent = Scroll

            local isSelected = false
            for _, s in ipairs(CurrentOption) do if s == opt then isSelected = true break end end
            if isSelected then Item.TextColor3 = getThemeColor("Text", Color3.fromRGB(255, 255, 255)) end

            Item.Activated:Connect(function()
                if not options.MultipleOptions then
                    CurrentOption = {opt}
                    UpdateLabel()
                    Toggle()
                    if options.Callback then options.Callback(CurrentOption) end
                    if options.Flag and saveMenuConfig then saveMenuConfig(options.Flag, CurrentOption) end
                end
                RefreshList()
            end)
        end
    end
    RefreshList()

    if themeManager and themeManager.OnThemeChanged then
        themeManager:OnThemeChanged(function()
            UpdateLabel()
            RefreshList()
        end)
    end

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