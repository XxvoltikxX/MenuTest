return function(options, themeManager, parent, menuConfig, saveMenuConfig, addConnection)
    local UserInputService = game:GetService("UserInputService")
    local TweenService = game:GetService("TweenService")

    local optName = options.Name or "Color Picker"
    local optFlag = options.Flag or optName:gsub("%s+", "_")

    -- Pobranie początkowego koloru i alpha
    local CurrentColor = options.Default or options.Color or Color3.fromRGB(255, 255, 255)
    local Alpha = 1.0

    if options.Transparency ~= nil then
        Alpha = 1.0 - math.clamp(tonumber(options.Transparency) or 0, 0, 1)
    elseif options.Alpha ~= nil then
        Alpha = math.clamp(tonumber(options.Alpha) or 1, 0, 1)
    end

    if optFlag and menuConfig and menuConfig[optFlag] ~= nil then
        local saved = menuConfig[optFlag]
        if type(saved) == "table" then
            CurrentColor = Color3.fromRGB(saved[1] or 255, saved[2] or 255, saved[3] or 255)
            if saved[4] ~= nil then Alpha = math.clamp(tonumber(saved[4]) or 1, 0, 1) end
        elseif typeof(saved) == "Color3" then
            CurrentColor = saved
        elseif type(saved) == "string" then
            local ok, c = pcall(function() return Color3.fromHex(saved) end)
            if ok and c then CurrentColor = c end
        end
    end

    local H, S, V = Color3.toHSV(CurrentColor)

    -- Kontener nadrzędny (Inline z AutomaticSize)
    local ColorPickerFrame = Instance.new("Frame")
    ColorPickerFrame.Name = optName
    ColorPickerFrame.Size = UDim2.new(1, 0, 0, 36)
    ColorPickerFrame.AutomaticSize = Enum.AutomaticSize.Y
    ColorPickerFrame.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
    ColorPickerFrame.BackgroundTransparency = 0
    ColorPickerFrame.ClipsDescendants = true
    ColorPickerFrame.Parent = parent

    Instance.new("UICorner", ColorPickerFrame).CornerRadius = UDim.new(0, 6)
    local FrameStroke = Instance.new("UIStroke", ColorPickerFrame)
    FrameStroke.Color = Color3.fromRGB(50, 50, 58)
    FrameStroke.Thickness = 1
    FrameStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    if themeManager and themeManager.Register then
        themeManager:Register(ColorPickerFrame, "BackgroundColor3", "Main")
        themeManager:Register(FrameStroke, "Color", "Accent")
    end

    -- Pasek nagłówka (Header Button)
    local HeaderBtn = Instance.new("TextButton")
    HeaderBtn.Name = "Header"
    HeaderBtn.Size = UDim2.new(1, 0, 0, 36)
    HeaderBtn.BackgroundTransparency = 1
    HeaderBtn.Text = ""
    HeaderBtn.Parent = ColorPickerFrame

    local Label = Instance.new("TextLabel")
    Label.Name = "Label"
    Label.Text = optName
    Label.Font = Enum.Font.GothamMedium
    Label.TextSize = 12
    Label.TextColor3 = Color3.fromRGB(180, 180, 190)
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Size = UDim2.new(1, -75, 1, 0)
    Label.Position = UDim2.new(0, 10, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Parent = HeaderBtn

    if themeManager and themeManager.Register then
        themeManager:Register(Label, "TextColor3", "Text_Secondary")
    end

    -- Podgląd koloru (Color Preview)
    local PreviewBox = Instance.new("Frame")
    PreviewBox.Name = "Preview"
    PreviewBox.Size = UDim2.new(0, 36, 0, 20)
    PreviewBox.Position = UDim2.new(1, -30, 0.5, 0)
    PreviewBox.AnchorPoint = Vector2.new(1, 0.5)
    PreviewBox.BackgroundColor3 = CurrentColor
    PreviewBox.Parent = HeaderBtn

    Instance.new("UICorner", PreviewBox).CornerRadius = UDim.new(0, 4)
    local PreviewStroke = Instance.new("UIStroke", PreviewBox)
    PreviewStroke.Color = Color3.fromRGB(70, 70, 80)
    PreviewStroke.Thickness = 1
    PreviewStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    if themeManager and themeManager.Register then
        themeManager:Register(PreviewStroke, "Color", "Accent")
    end

    -- Strzałka rozwijania
    local Arrow = Instance.new("TextLabel")
    Arrow.Name = "Arrow"
    Arrow.Text = "▾"
    Arrow.Font = Enum.Font.GothamBold
    Arrow.TextSize = 12
    Arrow.TextColor3 = Color3.fromRGB(150, 150, 160)
    Arrow.Size = UDim2.new(0, 18, 1, 0)
    Arrow.Position = UDim2.new(1, -6, 0.5, 0)
    Arrow.AnchorPoint = Vector2.new(1, 0.5)
    Arrow.BackgroundTransparency = 1
    Arrow.Parent = HeaderBtn

    if themeManager and themeManager.Register then
        themeManager:Register(Arrow, "TextColor3", "Text_Secondary")
    end

    -- Sekcja rozwijana (Dropdown Content)
    local DropdownContent = Instance.new("Frame")
    DropdownContent.Name = "Content"
    DropdownContent.Size = UDim2.new(1, 0, 0, 0)
    DropdownContent.AutomaticSize = Enum.AutomaticSize.Y
    DropdownContent.BackgroundTransparency = 1
    DropdownContent.Visible = false
    DropdownContent.ClipsDescendants = true
    DropdownContent.Parent = ColorPickerFrame

    local ContentLayout = Instance.new("UIListLayout")
    ContentLayout.Padding = UDim.new(0, 8)
    ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ContentLayout.Parent = DropdownContent

    local ContentPadding = Instance.new("UIPadding")
    ContentPadding.PaddingLeft = UDim.new(0, 10)
    ContentPadding.PaddingRight = UDim.new(0, 10)
    ContentPadding.PaddingBottom = UDim.new(0, 10)
    ContentPadding.Parent = DropdownContent

    -- 1. Pole wyboru nasycenia i jasności (Saturation / Value 2D Box)
    local SVBox = Instance.new("Frame")
    SVBox.Name = "SVBox"
    SVBox.Size = UDim2.new(1, 0, 0, 115)
    SVBox.BackgroundColor3 = Color3.fromHSV(H, 1, 1)
    SVBox.ClipsDescendants = true
    SVBox.LayoutOrder = 1
    SVBox.Parent = DropdownContent

    Instance.new("UICorner", SVBox).CornerRadius = UDim.new(0, 6)
    local SVStroke = Instance.new("UIStroke", SVBox)
    SVStroke.Color = Color3.fromRGB(60, 60, 70)
    SVStroke.Thickness = 1
    SVStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    -- Gradient biały (poziomy, Saturation)
    local WhiteGradFrame = Instance.new("Frame")
    WhiteGradFrame.Size = UDim2.new(1, 0, 1, 0)
    WhiteGradFrame.BackgroundColor3 = Color3.new(1, 1, 1)
    WhiteGradFrame.BorderSizePixel = 0
    WhiteGradFrame.Parent = SVBox

    local WhiteGrad = Instance.new("UIGradient")
    WhiteGrad.Color = ColorSequence.new(Color3.new(1, 1, 1))
    WhiteGrad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0.0, 0.0),
        NumberSequenceKeypoint.new(1.0, 1.0)
    })
    WhiteGrad.Rotation = 0
    WhiteGrad.Parent = WhiteGradFrame

    -- Gradient czarny (pionowy, Brightness/Value)
    local BlackGradFrame = Instance.new("Frame")
    BlackGradFrame.Size = UDim2.new(1, 0, 1, 0)
    BlackGradFrame.BackgroundColor3 = Color3.new(0, 0, 0)
    BlackGradFrame.BorderSizePixel = 0
    BlackGradFrame.Parent = SVBox

    local BlackGrad = Instance.new("UIGradient")
    BlackGrad.Color = ColorSequence.new(Color3.new(0, 0, 0))
    BlackGrad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0.0, 1.0),
        NumberSequenceKeypoint.new(1.0, 0.0)
    })
    BlackGrad.Rotation = 90
    BlackGrad.Parent = BlackGradFrame

    -- Kropka wyboru pozycji (Picker Dot)
    local PickerDot = Instance.new("Frame")
    PickerDot.Name = "PickerDot"
    PickerDot.Size = UDim2.new(0, 12, 0, 12)
    PickerDot.AnchorPoint = Vector2.new(0.5, 0.5)
    PickerDot.Position = UDim2.new(S, 0, 1 - V, 0)
    PickerDot.BackgroundColor3 = CurrentColor
    PickerDot.ZIndex = 5
    PickerDot.Parent = SVBox

    Instance.new("UICorner", PickerDot).CornerRadius = UDim.new(1, 0)
    local DotStroke = Instance.new("UIStroke", PickerDot)
    DotStroke.Color = Color3.new(1, 1, 1)
    DotStroke.Thickness = 1.5

    -- 2. Pasek tęczowy HUE
    local HueBar = Instance.new("Frame")
    HueBar.Name = "HueBar"
    HueBar.Size = UDim2.new(1, 0, 0, 14)
    HueBar.BackgroundColor3 = Color3.new(1, 1, 1)
    HueBar.LayoutOrder = 2
    HueBar.Parent = DropdownContent

    Instance.new("UICorner", HueBar).CornerRadius = UDim.new(0, 4)
    local HueStroke = Instance.new("UIStroke", HueBar)
    HueStroke.Color = Color3.fromRGB(50, 50, 60)
    HueStroke.Thickness = 1
    HueStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    local HueGrad = Instance.new("UIGradient")
    HueGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0.00, Color3.fromHSV(0.00, 1, 1)),
        ColorSequenceKeypoint.new(0.17, Color3.fromHSV(0.17, 1, 1)),
        ColorSequenceKeypoint.new(0.33, Color3.fromHSV(0.33, 1, 1)),
        ColorSequenceKeypoint.new(0.50, Color3.fromHSV(0.50, 1, 1)),
        ColorSequenceKeypoint.new(0.67, Color3.fromHSV(0.67, 1, 1)),
        ColorSequenceKeypoint.new(0.83, Color3.fromHSV(0.83, 1, 1)),
        ColorSequenceKeypoint.new(1.00, Color3.fromHSV(1.00, 1, 1)),
    })
    HueGrad.Parent = HueBar

    local HueKnob = Instance.new("Frame")
    HueKnob.Name = "HueKnob"
    HueKnob.Size = UDim2.new(0, 8, 1, 4)
    HueKnob.AnchorPoint = Vector2.new(0.5, 0.5)
    HueKnob.Position = UDim2.new(H, 0, 0.5, 0)
    HueKnob.BackgroundColor3 = Color3.new(1, 1, 1)
    HueKnob.ZIndex = 5
    HueKnob.Parent = HueBar

    Instance.new("UICorner", HueKnob).CornerRadius = UDim.new(0, 3)
    local HueKnobStroke = Instance.new("UIStroke", HueKnob)
    HueKnobStroke.Color = Color3.fromRGB(20, 20, 20)
    HueKnobStroke.Thickness = 1

    -- 3. Pasek Alpha / Transparency
    local AlphaBar = Instance.new("Frame")
    AlphaBar.Name = "AlphaBar"
    AlphaBar.Size = UDim2.new(1, 0, 0, 14)
    AlphaBar.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
    AlphaBar.LayoutOrder = 3
    AlphaBar.Parent = DropdownContent

    Instance.new("UICorner", AlphaBar).CornerRadius = UDim.new(0, 4)
    local AlphaStroke = Instance.new("UIStroke", AlphaBar)
    AlphaStroke.Color = Color3.fromRGB(50, 50, 60)
    AlphaStroke.Thickness = 1
    AlphaStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    if themeManager and themeManager.Register then
        themeManager:Register(SVStroke, "Color", "Accent")
        themeManager:Register(HueStroke, "Color", "Accent")
        themeManager:Register(AlphaBar, "BackgroundColor3", "Secondary")
        themeManager:Register(AlphaStroke, "Color", "Accent")
    end

    local AlphaGradFrame = Instance.new("Frame")
    AlphaGradFrame.Size = UDim2.new(1, 0, 1, 0)
    AlphaGradFrame.BackgroundColor3 = CurrentColor
    AlphaGradFrame.BorderSizePixel = 0
    AlphaGradFrame.Parent = AlphaBar
    Instance.new("UICorner", AlphaGradFrame).CornerRadius = UDim.new(0, 4)

    local AlphaGrad = Instance.new("UIGradient")
    AlphaGrad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0.0, 1.0),
        NumberSequenceKeypoint.new(1.0, 0.0)
    })
    AlphaGrad.Parent = AlphaGradFrame

    local AlphaKnob = Instance.new("Frame")
    AlphaKnob.Name = "AlphaKnob"
    AlphaKnob.Size = UDim2.new(0, 8, 1, 4)
    AlphaKnob.AnchorPoint = Vector2.new(0.5, 0.5)
    AlphaKnob.Position = UDim2.new(Alpha, 0, 0.5, 0)
    AlphaKnob.BackgroundColor3 = Color3.new(1, 1, 1)
    AlphaKnob.ZIndex = 5
    AlphaKnob.Parent = AlphaBar

    Instance.new("UICorner", AlphaKnob).CornerRadius = UDim.new(0, 3)
    local AlphaKnobStroke = Instance.new("UIStroke", AlphaKnob)
    AlphaKnobStroke.Color = Color3.fromRGB(20, 20, 20)
    AlphaKnobStroke.Thickness = 1

    -- 4. Dolny wiersz z HEX oraz RGB + Alpha
    local BottomRow = Instance.new("Frame")
    BottomRow.Name = "BottomRow"
    BottomRow.Size = UDim2.new(1, 0, 0, 28)
    BottomRow.BackgroundTransparency = 1
    BottomRow.LayoutOrder = 4
    BottomRow.Parent = DropdownContent

    -- Pole HEX
    local HexContainer = Instance.new("Frame")
    HexContainer.Name = "HexContainer"
    HexContainer.Size = UDim2.new(0, 95, 1, 0)
    HexContainer.Position = UDim2.new(0, 0, 0, 0)
    HexContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 36)
    HexContainer.Parent = BottomRow
    Instance.new("UICorner", HexContainer).CornerRadius = UDim.new(0, 5)

    local HexStroke = Instance.new("UIStroke", HexContainer)
    HexStroke.Color = Color3.fromRGB(55, 55, 65)
    HexStroke.Thickness = 1
    HexStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    if themeManager and themeManager.Register then
        themeManager:Register(HexContainer, "BackgroundColor3", "Secondary")
        themeManager:Register(HexStroke, "Color", "Accent")
    end

    local HexPrefix = Instance.new("TextLabel")
    HexPrefix.Text = "HEX:"
    HexPrefix.Font = Enum.Font.GothamBold
    HexPrefix.TextSize = 10
    HexPrefix.TextColor3 = Color3.fromRGB(150, 150, 160)
    HexPrefix.Size = UDim2.new(0, 30, 1, 0)
    HexPrefix.BackgroundTransparency = 1
    HexPrefix.Parent = HexContainer

    local HexInput = Instance.new("TextBox")
    HexInput.Name = "HexInput"
    HexInput.Size = UDim2.new(1, -32, 1, 0)
    HexInput.Position = UDim2.new(0, 30, 0, 0)
    HexInput.BackgroundTransparency = 1
    HexInput.Font = Enum.Font.GothamMedium
    HexInput.TextSize = 11
    HexInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    HexInput.PlaceholderColor3 = Color3.fromRGB(130, 130, 140)
    HexInput.PlaceholderText = "#FFFFFF"
    HexInput.Text = "#" .. CurrentColor:ToHex()
    HexInput.ClearTextOnFocus = false
    HexInput.Parent = HexContainer

    if themeManager and themeManager.Register then
        themeManager:Register(HexPrefix, "TextColor3", "Text_Secondary")
        themeManager:Register(HexInput, "TextColor3", "Text")
    end

    -- Etykieta RGB & Alpha
    local RgbLabel = Instance.new("TextLabel")
    RgbLabel.Name = "RgbLabel"
    RgbLabel.Size = UDim2.new(1, -105, 1, 0)
    RgbLabel.Position = UDim2.new(0, 105, 0, 0)
    RgbLabel.BackgroundTransparency = 1
    RgbLabel.Font = Enum.Font.GothamMedium
    RgbLabel.TextSize = 10
    RgbLabel.TextColor3 = Color3.fromRGB(160, 160, 170)
    RgbLabel.TextXAlignment = Enum.TextXAlignment.Right
    RgbLabel.Text = string.format("RGB: %d, %d, %d | A: %d%%",
        math.floor(CurrentColor.R * 255 + 0.5),
        math.floor(CurrentColor.G * 255 + 0.5),
        math.floor(CurrentColor.B * 255 + 0.5),
        math.floor(Alpha * 100 + 0.5)
    )
    RgbLabel.Parent = BottomRow

    if themeManager and themeManager.Register then
        themeManager:Register(RgbLabel, "TextColor3", "Text_Secondary")
    end

    -- Aktualizacja koloru
    local function UpdateColor(skipHexText)
        CurrentColor = Color3.fromHSV(H, S, V)
        PreviewBox.BackgroundColor3 = CurrentColor
        PickerDot.BackgroundColor3 = CurrentColor
        SVBox.BackgroundColor3 = Color3.fromHSV(H, 1, 1)
        AlphaGradFrame.BackgroundColor3 = CurrentColor

        if not skipHexText then
            HexInput.Text = "#" .. CurrentColor:ToHex()
        end

        RgbLabel.Text = string.format("RGB: %d, %d, %d | A: %d%%",
            math.floor(CurrentColor.R * 255 + 0.5),
            math.floor(CurrentColor.G * 255 + 0.5),
            math.floor(CurrentColor.B * 255 + 0.5),
            math.floor(Alpha * 100 + 0.5)
        )

        if options.Callback then
            pcall(options.Callback, CurrentColor, Alpha)
        end

        if optFlag and saveMenuConfig then
            saveMenuConfig(optFlag, {
                math.floor(CurrentColor.R * 255 + 0.5),
                math.floor(CurrentColor.G * 255 + 0.5),
                math.floor(CurrentColor.B * 255 + 0.5),
                Alpha
            })
        end
    end

    -- Obsługa dokładnego klikania i przeciągania myszą
    local function updateSV(pos)
        local absPos = SVBox.AbsolutePosition
        local absSize = SVBox.AbsoluteSize
        local relX = math.clamp((pos.X - absPos.X) / absSize.X, 0, 1)
        local relY = math.clamp((pos.Y - absPos.Y) / absSize.Y, 0, 1)
        S = relX
        V = 1 - relY
        PickerDot.Position = UDim2.new(S, 0, 1 - V, 0)
        UpdateColor()
    end

    local function updateHue(pos)
        local absPos = HueBar.AbsolutePosition
        local absSize = HueBar.AbsoluteSize
        local relX = math.clamp((pos.X - absPos.X) / absSize.X, 0, 1)
        H = relX
        HueKnob.Position = UDim2.new(H, 0, 0.5, 0)
        UpdateColor()
    end

    local function updateAlpha(pos)
        local absPos = AlphaBar.AbsolutePosition
        local absSize = AlphaBar.AbsoluteSize
        local relX = math.clamp((pos.X - absPos.X) / absSize.X, 0, 1)
        Alpha = relX
        AlphaKnob.Position = UDim2.new(Alpha, 0, 0.5, 0)
        UpdateColor()
    end

    local draggingSV, draggingHue, draggingAlpha = false, false, false

    SVBox.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            draggingSV = true
            updateSV(input.Position)
        end
    end)

    HueBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            draggingHue = true
            updateHue(input.Position)
        end
    end)

    AlphaBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            draggingAlpha = true
            updateAlpha(input.Position)
        end
    end)

    local moveConn = UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            if draggingSV then
                updateSV(input.Position)
            elseif draggingHue then
                updateHue(input.Position)
            elseif draggingAlpha then
                updateAlpha(input.Position)
            end
        end
    end)
    if addConnection then addConnection(moveConn) end

    local endConn = UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            draggingSV, draggingHue, draggingAlpha = false, false, false
        end
    end)
    if addConnection then addConnection(endConn) end

    -- Wpisywanie HEX
    HexInput.FocusLost:Connect(function(enterPressed)
        local raw = HexInput.Text:gsub("%s+", ""):gsub("^#", "")
        if #raw == 6 or #raw == 3 then
            local ok, parsed = pcall(function() return Color3.fromHex(raw) end)
            if ok and parsed then
                CurrentColor = parsed
                H, S, V = Color3.toHSV(CurrentColor)
                PickerDot.Position = UDim2.new(S, 0, 1 - V, 0)
                HueKnob.Position = UDim2.new(H, 0, 0.5, 0)
                UpdateColor(true)
                HexInput.Text = "#" .. CurrentColor:ToHex()
                return
            end
        end
        HexInput.Text = "#" .. CurrentColor:ToHex()
    end)

    -- Rozwijanie / zwijanie (Inline Accordion)
    local isExpanded = false
    HeaderBtn.MouseButton1Click:Connect(function()
        isExpanded = not isExpanded
        DropdownContent.Visible = isExpanded
        Arrow.Text = isExpanded and "▴" or "▾"
    end)

    -- Inicjalizacja stanu
    UpdateColor(true)

    local API = {}
    function API:Set(newCol, newAlpha)
        if typeof(newCol) == "Color3" then
            CurrentColor = newCol
        elseif type(newCol) == "table" then
            CurrentColor = Color3.fromRGB(newCol[1] or 255, newCol[2] or 255, newCol[3] or 255)
            if newCol[4] ~= nil then Alpha = math.clamp(tonumber(newCol[4]) or 1, 0, 1) end
        elseif type(newCol) == "string" then
            local ok, c = pcall(function() return Color3.fromHex(newCol:gsub("#", "")) end)
            if ok and c then CurrentColor = c end
        end
        if newAlpha ~= nil then
            Alpha = math.clamp(tonumber(newAlpha) or 1, 0, 1)
        end
        H, S, V = Color3.toHSV(CurrentColor)
        PickerDot.Position = UDim2.new(S, 0, 1 - V, 0)
        HueKnob.Position = UDim2.new(H, 0, 0.5, 0)
        AlphaKnob.Position = UDim2.new(Alpha, 0, 0.5, 0)
        UpdateColor()
    end
    function API:Get()
        return CurrentColor, Alpha
    end

    return API
end