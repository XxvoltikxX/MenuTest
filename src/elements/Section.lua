-- // ==========================================================================
-- // MENUTEST SECTION & CATEGORY COMPONENT
-- // Nowoczesny, modułowy kontener kategorii z nagłówkiem, ikoną, opisem,
-- // plakietką (badge), płynnym zwijaniem/rozwijaniem oraz podziałem na kontrolki.
-- // ==========================================================================

return function(options, themeManager, parent, menuConfig, saveMenuConfig, addConnection, UI, elements)
    local TweenService = game:GetService("TweenService")
    local UserInputService = game:GetService("UserInputService")

    local function getThemeColor(colorKey, fallback)
        if themeManager and themeManager.GetColor then
            local c = themeManager:GetColor(colorKey)
            if c then return c end
        end
        return fallback
    end

    local Icons = (elements and elements.Icons) or (UI and UI.Icons)
    local SliderElement      = elements and elements.Slider
    local ToggleElement      = elements and elements.Toggle
    local DropdownElement    = elements and elements.Dropdown
    local InputElement       = elements and elements.Input
    local ColorPickerElement = elements and elements.ColorPicker
    local ButtonElement      = elements and elements.Button
    local ModuleElement      = elements and elements.Module

    options = options or {}
    local sectionName  = options.Name or options.Title or "Category"
    local sectionDesc  = options.Description or options.Desc
    local sectionIcon  = options.Icon or "folder"
    local sectionBadge = options.Badge or options.Tag
    local isCollapsible = (options.Collapsible ~= false)
    local isOpen        = (options.DefaultOpen ~= false)

    -- Kontener nadrzędny kategorii (Card Frame)
    local SectionCard = Instance.new("Frame")
    SectionCard.Name = "Category_" .. sectionName
    SectionCard.Size = UDim2.new(1, 0, 0, 0)
    SectionCard.AutomaticSize = Enum.AutomaticSize.Y
    SectionCard.BackgroundColor3 = getThemeColor("Secondary", Color3.fromRGB(22, 22, 26))
    SectionCard.BackgroundTransparency = 0.25
    SectionCard.ClipsDescendants = true
    SectionCard.Parent = parent

    local CardCorner = Instance.new("UICorner", SectionCard)
    CardCorner.CornerRadius = UDim.new(0, 10)

    local CardStroke = Instance.new("UIStroke", SectionCard)
    CardStroke.Color = getThemeColor("Accent", Color3.fromRGB(45, 45, 52))
    CardStroke.Thickness = 1.2
    CardStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    local CardLayout = Instance.new("UIListLayout", SectionCard)
    CardLayout.SortOrder = Enum.SortOrder.LayoutOrder
    CardLayout.Padding = UDim.new(0, 0)

    -- Nagłówek kategorii (Header)
    local Header = Instance.new("TextButton")
    Header.Name = "Header"
    Header.Size = UDim2.new(1, 0, 0, sectionDesc and 48 or 38)
    Header.BackgroundTransparency = 1
    Header.Text = ""
    Header.AutoButtonColor = false
    Header.LayoutOrder = 1
    Header.Parent = SectionCard

    local HeaderPadding = Instance.new("UIPadding", Header)
    HeaderPadding.PaddingLeft = UDim.new(0, 12)
    HeaderPadding.PaddingRight = UDim.new(0, 12)
    HeaderPadding.PaddingTop = UDim.new(0, 6)
    HeaderPadding.PaddingBottom = UDim.new(0, 6)

    -- Ikona kategorii
    local IconLabel = Instance.new("ImageLabel")
    IconLabel.Name = "Icon"
    IconLabel.Size = UDim2.new(0, 18, 0, 18)
    IconLabel.Position = UDim2.new(0, 0, 0.5, 0)
    IconLabel.AnchorPoint = Vector2.new(0, 0.5)
    IconLabel.BackgroundTransparency = 1
    IconLabel.ImageColor3 = getThemeColor("Text", Color3.fromRGB(255, 255, 255))
    IconLabel.Parent = Header
    if Icons and Icons.Apply then
        Icons:Apply(IconLabel, sectionIcon)
    end

    -- Kontener na teksty nagłówka
    local TextContainer = Instance.new("Frame")
    TextContainer.Name = "TextContainer"
    TextContainer.Size = UDim2.new(1, -70, 1, 0)
    TextContainer.Position = UDim2.new(0, 26, 0, 0)
    TextContainer.BackgroundTransparency = 1
    TextContainer.Parent = Header

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Name = "Title"
    TitleLabel.Text = sectionName
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.TextSize = 13
    TitleLabel.TextColor3 = getThemeColor("Text", Color3.fromRGB(255, 255, 255))
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Size = UDim2.new(1, 0, sectionDesc and 0.55 or 1, 0)
    TitleLabel.Position = UDim2.new(0, 0, 0, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Parent = TextContainer

    if sectionDesc then
        local DescLabel = Instance.new("TextLabel")
        DescLabel.Name = "Description"
        DescLabel.Text = sectionDesc
        DescLabel.Font = Enum.Font.GothamMedium
        DescLabel.TextSize = 10
        DescLabel.TextColor3 = getThemeColor("Text_Secondary", Color3.fromRGB(150, 150, 160))
        DescLabel.TextXAlignment = Enum.TextXAlignment.Left
        DescLabel.Size = UDim2.new(1, 0, 0.45, 0)
        DescLabel.Position = UDim2.new(0, 0, 0.55, 0)
        DescLabel.BackgroundTransparency = 1
        DescLabel.Parent = TextContainer
    end

    -- Prawa strona nagłówka (Badge + Chevron zwijania)
    local RightContainer = Instance.new("Frame")
    RightContainer.Name = "RightContainer"
    RightContainer.Size = UDim2.new(0, 60, 1, 0)
    RightContainer.Position = UDim2.new(1, 0, 0, 0)
    RightContainer.AnchorPoint = Vector2.new(1, 0)
    RightContainer.BackgroundTransparency = 1
    RightContainer.Parent = Header

    local RightLayout = Instance.new("UIListLayout", RightContainer)
    RightLayout.FillDirection = Enum.FillDirection.Horizontal
    RightLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    RightLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    RightLayout.Padding = UDim.new(0, 6)

    if sectionBadge then
        local BadgeFrame = Instance.new("Frame")
        BadgeFrame.Name = "Badge"
        BadgeFrame.Size = UDim2.new(0, 0, 0, 18)
        BadgeFrame.AutomaticSize = Enum.AutomaticSize.X
        BadgeFrame.BackgroundColor3 = getThemeColor("Accent2", Color3.fromRGB(40, 40, 50))
        BadgeFrame.Parent = RightContainer
        Instance.new("UICorner", BadgeFrame).CornerRadius = UDim.new(0, 5)

        local BadgePadding = Instance.new("UIPadding", BadgeFrame)
        BadgePadding.PaddingLeft = UDim.new(0, 6)
        BadgePadding.PaddingRight = UDim.new(0, 6)

        local BadgeLabel = Instance.new("TextLabel")
        BadgeLabel.Text = string.upper(tostring(sectionBadge))
        BadgeLabel.Font = Enum.Font.GothamBold
        BadgeLabel.TextSize = 9
        BadgeLabel.TextColor3 = getThemeColor("Text_Secondary", Color3.fromRGB(180, 180, 195))
        BadgeLabel.Size = UDim2.new(0, 0, 1, 0)
        BadgeLabel.AutomaticSize = Enum.AutomaticSize.X
        BadgeLabel.BackgroundTransparency = 1
        BadgeLabel.Parent = BadgeFrame
    end

    local Chevron = Instance.new("ImageLabel")
    Chevron.Name = "Chevron"
    Chevron.Size = UDim2.new(0, 16, 0, 16)
    Chevron.BackgroundTransparency = 1
    Chevron.ImageColor3 = getThemeColor("Text_Secondary", Color3.fromRGB(160, 160, 170))
    Chevron.Rotation = isOpen and 0 or -90
    Chevron.Parent = RightContainer
    if Icons and Icons.Apply then
        Icons:Apply(Chevron, "chevron-down")
    end

    -- Pasek rozdzielający nagłówek od zawartości (Divider Line z gradientem)
    local HeaderLine = Instance.new("Frame")
    HeaderLine.Name = "HeaderLine"
    HeaderLine.Size = UDim2.new(1, 0, 0, 1)
    HeaderLine.BorderSizePixel = 0
    HeaderLine.BackgroundColor3 = getThemeColor("Accent", Color3.fromRGB(45, 45, 52))
    HeaderLine.LayoutOrder = 2
    HeaderLine.Visible = isOpen
    HeaderLine.Parent = SectionCard

    local LineGradient = Instance.new("UIGradient", HeaderLine)
    LineGradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.7),
        NumberSequenceKeypoint.new(0.5, 0),
        NumberSequenceKeypoint.new(1, 0.7)
    })

    -- Kontener na kontrolki (Body)
    local ContentContainer = Instance.new("Frame")
    ContentContainer.Name = "Content"
    ContentContainer.Size = UDim2.new(1, 0, 0, 0)
    ContentContainer.AutomaticSize = Enum.AutomaticSize.Y
    ContentContainer.BackgroundTransparency = 1
    ContentContainer.Visible = isOpen
    ContentContainer.ClipsDescendants = true
    ContentContainer.LayoutOrder = 3
    ContentContainer.Parent = SectionCard

    local ContentPadding = Instance.new("UIPadding", ContentContainer)
    ContentPadding.PaddingLeft = UDim.new(0, 10)
    ContentPadding.PaddingRight = UDim.new(0, 10)
    ContentPadding.PaddingTop = UDim.new(0, 10)
    ContentPadding.PaddingBottom = UDim.new(0, 12)

    local ContentLayout = Instance.new("UIListLayout", ContentContainer)
    ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ContentLayout.Padding = UDim.new(0, 8)

    -- Obsługa rozwijania/zwijania (Accordion animation)
    local function setOpenState(state, animate)
        isOpen = state
        local targetRotation = isOpen and 0 or -90
        if animate then
            TweenService:Create(Chevron, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Rotation = targetRotation
            }):Play()
            if isOpen then
                HeaderLine.Visible = true
                ContentContainer.Visible = true
                ContentContainer.Size = UDim2.new(1, 0, 0, 0)
            else
                HeaderLine.Visible = false
                ContentContainer.Visible = false
            end
        else
            Chevron.Rotation = targetRotation
            HeaderLine.Visible = isOpen
            ContentContainer.Visible = isOpen
        end
    end

    if isCollapsible then
        Header.MouseButton1Click:Connect(function()
            setOpenState(not isOpen, true)
        end)
    end

    -- Rejestracja w ThemeManagerze
    if themeManager and themeManager.Register then
        themeManager:Register(SectionCard, "BackgroundColor3", "Secondary")
        themeManager:Register(CardStroke, "Color", "Accent")
        themeManager:Register(TitleLabel, "TextColor3", "Text")
        themeManager:Register(IconLabel, "ImageColor3", "Text")
        themeManager:Register(Chevron, "ImageColor3", "Text_Secondary")
        themeManager:Register(HeaderLine, "BackgroundColor3", "Accent")
    end

    -- // API KATEGORII
    local CategoryAPI = {}
    CategoryAPI.Card = SectionCard
    CategoryAPI.Content = ContentContainer

    function CategoryAPI:CreateModule(opts)
        if ModuleElement then
            local inst = ModuleElement(opts, themeManager, ContentContainer, menuConfig, saveMenuConfig, addConnection, UI, elements)
            if opts and opts.Flag and UI and UI.Flags then UI.Flags[opts.Flag] = inst end
            return inst
        end
    end
    CategoryAPI.AddModule = CategoryAPI.CreateModule

    function CategoryAPI:CreateToggle(opts)
        if ToggleElement then
            local inst = ToggleElement(opts, themeManager, ContentContainer, menuConfig, saveMenuConfig, addConnection)
            if opts and opts.Flag and UI and UI.Flags then UI.Flags[opts.Flag] = inst end
            return inst
        end
    end
    CategoryAPI.AddToggle = CategoryAPI.CreateToggle

    function CategoryAPI:CreateSlider(opts)
        if SliderElement then
            local inst = SliderElement(opts, themeManager, ContentContainer, menuConfig, saveMenuConfig)
            if opts and opts.Flag and UI and UI.Flags then UI.Flags[opts.Flag] = inst end
            return inst
        end
    end
    CategoryAPI.AddSlider = CategoryAPI.CreateSlider

    function CategoryAPI:CreateDropdown(opts)
        if DropdownElement then
            local inst = DropdownElement(opts, themeManager, ContentContainer, menuConfig, saveMenuConfig, addConnection, Icons)
            if opts and opts.Flag and UI and UI.Flags then UI.Flags[opts.Flag] = inst end
            return inst
        end
    end
    CategoryAPI.AddDropdown = CategoryAPI.CreateDropdown

    function CategoryAPI:CreateColorPicker(opts)
        if ColorPickerElement then
            local inst = ColorPickerElement(opts, themeManager, ContentContainer, menuConfig, saveMenuConfig, addConnection)
            if opts and opts.Flag and UI and UI.Flags then UI.Flags[opts.Flag] = inst end
            return inst
        end
    end
    CategoryAPI.AddColorPicker = CategoryAPI.CreateColorPicker

    function CategoryAPI:CreateInput(opts)
        if InputElement then
            local inst = InputElement(opts, themeManager, ContentContainer, menuConfig, saveMenuConfig, addConnection)
            if opts and opts.Flag and UI and UI.Flags then UI.Flags[opts.Flag] = inst end
            return inst
        end
    end
    CategoryAPI.AddInput = CategoryAPI.CreateInput

    function CategoryAPI:CreateButton(opts)
        if ButtonElement then
            return ButtonElement(opts, themeManager, ContentContainer, menuConfig, saveMenuConfig, addConnection)
        end
    end
    CategoryAPI.AddButton = CategoryAPI.CreateButton

    function CategoryAPI:CreateDivider(label)
        local Div = Instance.new("Frame")
        Div.Name = "Divider"
        Div.Size = UDim2.new(1, 0, 0, label and 24 or 10)
        Div.BackgroundTransparency = 1
        Div.Parent = ContentContainer

        local Line = Instance.new("Frame")
        Line.Size = UDim2.new(1, 0, 0, 1)
        Line.Position = UDim2.new(0, 0, 0.5, 0)
        Line.AnchorPoint = Vector2.new(0, 0.5)
        Line.BorderSizePixel = 0
        Line.BackgroundColor3 = getThemeColor("Accent", Color3.fromRGB(50, 50, 60))
        Line.Parent = Div

        if label then
            local Text = Instance.new("TextLabel")
            Text.Text = "  " .. tostring(label) .. "  "
            Text.Font = Enum.Font.GothamBold
            Text.TextSize = 10
            Text.TextColor3 = getThemeColor("Text_Secondary", Color3.fromRGB(150, 150, 160))
            Text.BackgroundColor3 = getThemeColor("Secondary", Color3.fromRGB(22, 22, 26))
            Text.Size = UDim2.new(0, 0, 1, 0)
            Text.AutomaticSize = Enum.AutomaticSize.X
            Text.AnchorPoint = Vector2.new(0.5, 0.5)
            Text.Position = UDim2.new(0.5, 0, 0.5, 0)
            Text.Parent = Div
        end
        return Div
    end
    CategoryAPI.AddDivider = CategoryAPI.CreateDivider

    function CategoryAPI:SetOpen(state)
        setOpenState(state, true)
    end

    return CategoryAPI
end
