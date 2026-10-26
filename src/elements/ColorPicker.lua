return function(options, themeManager, parent, menuConfig, saveMenuConfig, addConnection)
    local UserInputService = game:GetService("UserInputService")
    local TweenService = game:GetService("TweenService")

    local optName = options.Name or "Color Picker"
    local optFlag = options.Flag or optName:gsub("%s+", "_")

    -- Pobranie ikon Lucide
    local Icons = (typeof(getgenv) == "function" and getgenv()._MenuTestIconsModule) or _G._MenuTestIconsModule
    if not Icons then
        pcall(function()
            local raw = game:HttpGet("https://raw.githubusercontent.com/XxvoltikxX/MenuTest/refs/heads/main/src/Icons.lua")
            if raw then
                local fn = loadstring(raw)
                if fn then Icons = fn() end
            end
        end)
    end

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

    -- Główny kontener (z pionowym UIListLayout zapobiegającym nakładaniu się nagłówka!)
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

    local FrameListLayout = Instance.new("UIListLayout", ColorPickerFrame)
    FrameListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    FrameListLayout.Padding = UDim.new(0, 0)

    if themeManager and themeManager.Register then
        themeManager:Register(ColorPickerFrame, "BackgroundColor3", "Main")
        themeManager:Register(FrameStroke, "Color", "Accent")
    end

    -- ============================================================
    -- Pasek nagłówka (Header Button) - LayoutOrder = 1
    -- ============================================================
    local HeaderBtn = Instance.new("TextButton")
    HeaderBtn.Name = "Header"
    HeaderBtn.Size = UDim2.new(1, 0, 0, 36)
    HeaderBtn.BackgroundTransparency = 1
    HeaderBtn.Text = ""
    HeaderBtn.AutoButtonColor = false
    HeaderBtn.LayoutOrder = 1
    HeaderBtn.Parent = ColorPickerFrame

    -- Ikonka Lucide (swatch-book)
    local PaletteIcon = Instance.new("ImageLabel")
    PaletteIcon.Name = "PaletteIcon"
    PaletteIcon.Size = UDim2.new(0, 16, 0, 16)
    PaletteIcon.Position = UDim2.new(0, 10, 0.5, 0)
    PaletteIcon.AnchorPoint = Vector2.new(0, 0.5)
    PaletteIcon.BackgroundTransparency = 1
    PaletteIcon.ImageColor3 = Color3.fromRGB(160, 160, 170)
    PaletteIcon.Parent = HeaderBtn

    if Icons and Icons.Apply then
        Icons:Apply(PaletteIcon, "swatch-book")
    end
    if themeManager and themeManager.Register then
        themeManager:Register(PaletteIcon, "ImageColor3", "Text_Secondary")
    end

    local Label = Instance.new("TextLabel")
    Label.Name = "Label"
    Label.Text = optName
    Label.Font = Enum.Font.GothamMedium
    Label.TextSize = 12
    Label.TextColor3 = Color3.fromRGB(180, 180, 190)
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Size = UDim2.new(1, -100, 1, 0)
    Label.Position = UDim2.new(0, 32, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Parent = HeaderBtn

    if themeManager and themeManager.Register then
        themeManager:Register(Label, "TextColor3", "Text_Secondary")
    end

    -- Proceduralny generator szachownicy (gwarantowane renderowanie przezroczystości offline i online)
    local function createCheckerboard(targetParent, rows, cols)
        local grid = Instance.new("Frame")
        grid.Name = "Checkerboard"
        grid.Size = UDim2.new(1, 0, 1, 0)
        grid.BackgroundTransparency = 1
        grid.BorderSizePixel = 0
        grid.ClipsDescendants = true
        grid.ZIndex = 1
        grid.Parent = targetParent

        local lightCol = Color3.fromRGB(225, 225, 230)
        local darkCol  = Color3.fromRGB(150, 150, 160)

        local wFrac = 1 / cols
        local hFrac = 1 / rows

        for r = 0, rows - 1 do
            for c = 0, cols - 1 do
                local sq = Instance.new("Frame")
                sq.BorderSizePixel = 0
                sq.Size = UDim2.new(wFrac, 1, hFrac, 1)
                sq.Position = UDim2.new(c * wFrac, 0, r * hFrac, 0)
                sq.BackgroundColor3 = ((r + c) % 2 == 0) and lightCol or darkCol
                sq.ZIndex = 1
                sq.Parent = grid
            end
        end
        return grid
    end

    -- Kontener podglądu koloru z obsługą przezroczystości (prawdziwa szachownica)
    local PreviewWrapper = Instance.new("Frame")
    PreviewWrapper.Name = "PreviewWrapper"
    PreviewWrapper.Size = UDim2.new(0, 38, 0, 20)
    PreviewWrapper.Position = UDim2.new(1, -30, 0.5, 0)
    PreviewWrapper.AnchorPoint = Vector2.new(1, 0.5)
    PreviewWrapper.BackgroundColor3 = Color3.fromRGB(30, 30, 36)
    PreviewWrapper.ClipsDescendants = true
    PreviewWrapper.Parent = HeaderBtn

    Instance.new("UICorner", PreviewWrapper).CornerRadius = UDim.new(0, 4)
    local PreviewStroke = Instance.new("UIStroke", PreviewWrapper)
    PreviewStroke.Color = Color3.fromRGB(70, 70, 80)
    PreviewStroke.Thickness = 1
    PreviewStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    createCheckerboard(PreviewWrapper, 2, 4)

    local PreviewColor = Instance.new("Frame")
    PreviewColor.Name = "Color"
    PreviewColor.Size = UDim2.new(1, 0, 1, 0)
    PreviewColor.BackgroundColor3 = CurrentColor
    PreviewColor.BackgroundTransparency = 1 - Alpha
    PreviewColor.BorderSizePixel = 0
    PreviewColor.ZIndex = 2
    PreviewColor.Parent = PreviewWrapper

    if themeManager and themeManager.Register then
        themeManager:Register(PreviewStroke, "Color", "Accent")
    end

    -- Ikona Lucide Chevron
    local ChevronIcon = Instance.new("ImageLabel")
    ChevronIcon.Name = "Chevron"
    ChevronIcon.Size = UDim2.new(0, 14, 0, 14)
    ChevronIcon.Position = UDim2.new(1, -8, 0.5, 0)
    ChevronIcon.AnchorPoint = Vector2.new(1, 0.5)
    ChevronIcon.BackgroundTransparency = 1
    ChevronIcon.ImageColor3 = Color3.fromRGB(150, 150, 160)
    ChevronIcon.Parent = HeaderBtn

    if Icons and Icons.Apply then
        Icons:Apply(ChevronIcon, "chevron-down")
    end
    if themeManager and themeManager.Register then
        themeManager:Register(ChevronIcon, "ImageColor3", "Text_Secondary")
    end

    -- ============================================================
    -- Sekcja rozwijana (Dropdown Content) - LayoutOrder = 2
    -- ============================================================
    local DropdownContent = Instance.new("Frame")
    DropdownContent.Name = "Content"
    DropdownContent.Size = UDim2.new(1, 0, 0, 0)
    DropdownContent.BackgroundTransparency = 1
    DropdownContent.Visible = false
    DropdownContent.ClipsDescendants = true
    DropdownContent.LayoutOrder = 2
    DropdownContent.Parent = ColorPickerFrame

    local ContentLayout = Instance.new("UIListLayout", DropdownContent)
    ContentLayout.Padding = UDim.new(0, 7)
    ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder

    local ContentPadding = Instance.new("UIPadding", DropdownContent)
    ContentPadding.PaddingLeft = UDim.new(0, 10)
    ContentPadding.PaddingRight = UDim.new(0, 10)
    ContentPadding.PaddingTop = UDim.new(0, 2)
    ContentPadding.PaddingBottom = UDim.new(0, 10)

    -- 1. Pole wyboru nasycenia i jasności (Saturation / Value 2D Box)
    local SVBox = Instance.new("Frame")
    SVBox.Name = "SVBox"
    SVBox.Size = UDim2.new(1, 0, 0, 105)
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
    PickerDot.BackgroundColor3 = CurrentColor
    PickerDot.ZIndex = 5
    PickerDot.Parent = SVBox

    Instance.new("UICorner", PickerDot).CornerRadius = UDim.new(1, 0)
    local DotStroke = Instance.new("UIStroke", PickerDot)
    DotStroke.Color = Color3.fromRGB(255, 255, 255)
    DotStroke.Thickness = 1.5

    -- Helpery dla pozycji elementów
    local function setKnobPos(knob, val)
        val = math.clamp(val, 0, 1)
        local knobHalf = 5
        local offset = (1 - val * 2) * knobHalf
        knob.Position = UDim2.new(val, offset, 0.5, 0)
    end

    local function setDotPos(sVal, vVal)
        sVal = math.clamp(sVal, 0, 1)
        vVal = math.clamp(vVal, 0, 1)
        local dotHalf = 5
        local posX = sVal
        local posY = 1 - vVal
        PickerDot.Position = UDim2.new(posX, (1 - posX * 2) * dotHalf, posY, (1 - posY * 2) * dotHalf)
    end

    -- 2. Pasek tęczowy HUE (Barwa - 0..360)
    local HueBar = Instance.new("Frame")
    HueBar.Name = "HueBar"
    HueBar.Size = UDim2.new(1, 0, 0, 16)
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
    HueKnob.Size = UDim2.new(0, 10, 1, 4)
    HueKnob.AnchorPoint = Vector2.new(0.5, 0.5)
    HueKnob.BackgroundColor3 = Color3.new(1, 1, 1)
    HueKnob.ZIndex = 5
    HueKnob.Parent = HueBar

    Instance.new("UICorner", HueKnob).CornerRadius = UDim.new(0, 3)
    local HueKnobStroke = Instance.new("UIStroke", HueKnob)
    HueKnobStroke.Color = Color3.fromRGB(70, 70, 80)
    HueKnobStroke.Thickness = 1

    -- 3. Pasek ALPHA / TRANSPARENCY (Przezroczystość z prawdziwą szachownicą)
    local AlphaBar = Instance.new("Frame")
    AlphaBar.Name = "AlphaBar"
    AlphaBar.Size = UDim2.new(1, 0, 0, 16)
    AlphaBar.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
    AlphaBar.ClipsDescendants = true
    AlphaBar.LayoutOrder = 3
    AlphaBar.Parent = DropdownContent

    Instance.new("UICorner", AlphaBar).CornerRadius = UDim.new(0, 4)
    local AlphaStroke = Instance.new("UIStroke", AlphaBar)
    AlphaStroke.Color = Color3.fromRGB(50, 50, 60)
    AlphaStroke.Thickness = 1
    AlphaStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    createCheckerboard(AlphaBar, 2, 16)

    local AlphaGradFrame = Instance.new("Frame")
    AlphaGradFrame.Name = "AlphaGradFrame"
    AlphaGradFrame.Size = UDim2.new(1, 0, 1, 0)
    AlphaGradFrame.BackgroundColor3 = CurrentColor
    AlphaGradFrame.BorderSizePixel = 0
    AlphaGradFrame.ZIndex = 2
    AlphaGradFrame.Parent = AlphaBar

    local AlphaGrad = Instance.new("UIGradient")
    AlphaGrad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0.0, 1.0),
        NumberSequenceKeypoint.new(1.0, 0.0)
    })
    AlphaGrad.Parent = AlphaGradFrame

    local AlphaKnob = Instance.new("Frame")
    AlphaKnob.Name = "AlphaKnob"
    AlphaKnob.Size = UDim2.new(0, 10, 1, 4)
    AlphaKnob.AnchorPoint = Vector2.new(0.5, 0.5)
    AlphaKnob.BackgroundColor3 = Color3.new(1, 1, 1)
    AlphaKnob.ZIndex = 5
    AlphaKnob.Parent = AlphaBar

    Instance.new("UICorner", AlphaKnob).CornerRadius = UDim.new(0, 3)
    local AlphaKnobStroke = Instance.new("UIStroke", AlphaKnob)
    AlphaKnobStroke.Color = Color3.fromRGB(70, 70, 80)
    AlphaKnobStroke.Thickness = 1

    if themeManager and themeManager.Register then
        themeManager:Register(SVStroke, "Color", "Accent")
        themeManager:Register(HueStroke, "Color", "Accent")
        themeManager:Register(AlphaStroke, "Color", "Accent")
    end

    -- ============================================================
    -- 4. Dolna sekcja: Wiersze HEX i RGB/A
    -- ============================================================
    -- Wiersz 1: Pole HEX
    local HexContainer = Instance.new("Frame")
    HexContainer.Name = "HexContainer"
    HexContainer.Size = UDim2.new(1, 0, 0, 26)
    HexContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 36)
    HexContainer.LayoutOrder = 4
    HexContainer.Parent = DropdownContent

    Instance.new("UICorner", HexContainer).CornerRadius = UDim.new(0, 5)
    local HexStroke = Instance.new("UIStroke", HexContainer)
    HexStroke.Color = Color3.fromRGB(55, 55, 65)
    HexStroke.Thickness = 1
    HexStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    local HexLabel = Instance.new("TextLabel")
    HexLabel.Name = "HexLabel"
    HexLabel.Text = "HEX:"
    HexLabel.Font = Enum.Font.GothamBold
    HexLabel.TextSize = 10
    HexLabel.TextColor3 = Color3.fromRGB(150, 150, 160)
    HexLabel.Size = UDim2.new(0, 34, 1, 0)
    HexLabel.Position = UDim2.new(0, 8, 0, 0)
    HexLabel.BackgroundTransparency = 1
    HexLabel.TextXAlignment = Enum.TextXAlignment.Left
    HexLabel.Parent = HexContainer

    local HexInput = Instance.new("TextBox")
    HexInput.Name = "HexInput"
    HexInput.Size = UDim2.new(1, -44, 1, 0)
    HexInput.Position = UDim2.new(0, 38, 0, 0)
    HexInput.BackgroundTransparency = 1
    HexInput.Font = Enum.Font.GothamMedium
    HexInput.TextSize = 11
    HexInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    HexInput.PlaceholderColor3 = Color3.fromRGB(130, 130, 140)
    HexInput.PlaceholderText = "#FFFFFF"
    HexInput.Text = "#" .. CurrentColor:ToHex():upper()
    HexInput.ClearTextOnFocus = false
    HexInput.TextXAlignment = Enum.TextXAlignment.Left
    HexInput.Parent = HexContainer

    if themeManager and themeManager.Register then
        themeManager:Register(HexContainer, "BackgroundColor3", "Secondary")
        themeManager:Register(HexStroke, "Color", "Accent")
        themeManager:Register(HexLabel, "TextColor3", "Text_Secondary")
        themeManager:Register(HexInput, "TextColor3", "Text")
    end

    -- Wiersz 2: Wartości RGB oraz Alpha w osobnych etykietach
    local ValuesRow = Instance.new("Frame")
    ValuesRow.Name = "ValuesRow"
    ValuesRow.Size = UDim2.new(1, 0, 0, 18)
    ValuesRow.BackgroundTransparency = 1
    ValuesRow.LayoutOrder = 5
    ValuesRow.Parent = DropdownContent

    local RgbLabel = Instance.new("TextLabel")
    RgbLabel.Name = "RgbLabel"
    RgbLabel.Size = UDim2.new(0.65, 0, 1, 0)
    RgbLabel.Position = UDim2.new(0, 0, 0, 0)
    RgbLabel.BackgroundTransparency = 1
    RgbLabel.Font = Enum.Font.GothamMedium
    RgbLabel.TextSize = 10
    RgbLabel.TextColor3 = Color3.fromRGB(160, 160, 170)
    RgbLabel.TextXAlignment = Enum.TextXAlignment.Left
    RgbLabel.Parent = ValuesRow

    local AlphaLabel = Instance.new("TextLabel")
    AlphaLabel.Name = "AlphaLabel"
    AlphaLabel.Size = UDim2.new(0.35, 0, 1, 0)
    AlphaLabel.Position = UDim2.new(0.65, 0, 0, 0)
    AlphaLabel.BackgroundTransparency = 1
    AlphaLabel.Font = Enum.Font.GothamMedium
    AlphaLabel.TextSize = 10
    AlphaLabel.TextColor3 = Color3.fromRGB(160, 160, 170)
    AlphaLabel.TextXAlignment = Enum.TextXAlignment.Right
    AlphaLabel.Parent = ValuesRow

    if themeManager and themeManager.Register then
        themeManager:Register(RgbLabel, "TextColor3", "Text_Secondary")
        themeManager:Register(AlphaLabel, "TextColor3", "Text_Secondary")
    end

    -- ============================================================
    -- Funkcja aktualizacji stanu i wyglądu koloru
    -- ============================================================
    local function UpdateColor(skipHexText)
        CurrentColor = Color3.fromHSV(H, S, V)
        PreviewColor.BackgroundColor3 = CurrentColor
        PreviewColor.BackgroundTransparency = 1 - Alpha
        PickerDot.BackgroundColor3 = CurrentColor

        SVBox.BackgroundColor3 = Color3.fromHSV(H, 1, 1)

        -- Pasek Alpha dostosowuje swój kolor bazowy
        AlphaGradFrame.BackgroundColor3 = CurrentColor

        local r = math.floor(CurrentColor.R * 255 + 0.5)
        local g = math.floor(CurrentColor.G * 255 + 0.5)
        local b = math.floor(CurrentColor.B * 255 + 0.5)

        if not skipHexText then
            if Alpha < 0.999 then
                local aByte = math.floor(Alpha * 255 + 0.5)
                HexInput.Text = string.format("#%s%02X", CurrentColor:ToHex():upper(), aByte)
            else
                HexInput.Text = "#" .. CurrentColor:ToHex():upper()
            end
        end

        RgbLabel.Text = string.format("RGB: %d, %d, %d", r, g, b)
        AlphaLabel.Text = string.format("Alpha: %d%%", math.floor(Alpha * 100 + 0.5))

        if options.Callback then
            pcall(options.Callback, CurrentColor, Alpha, {
                R = r, G = g, B = b, A = Alpha,
                Transparency = 1 - Alpha,
                Color = CurrentColor,
                Hex = HexInput.Text
            })
        end

        if optFlag and saveMenuConfig then
            saveMenuConfig(optFlag, { r, g, b, Alpha })
        end
    end

    -- Obsługa precyzyjnego przeciągania myszą
    local function updateSV(pos)
        local absPos = SVBox.AbsolutePosition
        local absSize = SVBox.AbsoluteSize
        local relX = math.clamp((pos.X - absPos.X) / absSize.X, 0, 1)
        local relY = math.clamp((pos.Y - absPos.Y) / absSize.Y, 0, 1)
        S = relX
        V = 1 - relY
        setDotPos(S, V)
        UpdateColor()
    end

    local function updateHue(pos)
        local absPos = HueBar.AbsolutePosition
        local absSize = HueBar.AbsoluteSize
        local relX = math.clamp((pos.X - absPos.X) / absSize.X, 0, 1)
        H = relX
        setKnobPos(HueKnob, H)
        UpdateColor()
    end

    local function updateAlpha(pos)
        local absPos = AlphaBar.AbsolutePosition
        local absSize = AlphaBar.AbsoluteSize
        local relX = math.clamp((pos.X - absPos.X) / absSize.X, 0, 1)
        Alpha = relX
        setKnobPos(AlphaKnob, Alpha)
        UpdateColor()
    end

    local draggingSV, draggingHue, draggingAlpha = false, false, false
    local scrollParent = parent:FindFirstAncestorOfClass("ScrollingFrame")

    SVBox.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            draggingSV = true
            if scrollParent then scrollParent.ScrollingEnabled = false end
            updateSV(input.Position)
        end
    end)

    HueBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            draggingHue = true
            if scrollParent then scrollParent.ScrollingEnabled = false end
            updateHue(input.Position)
        end
    end)

    AlphaBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            draggingAlpha = true
            if scrollParent then scrollParent.ScrollingEnabled = false end
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
            if draggingSV or draggingHue or draggingAlpha then
                draggingSV, draggingHue, draggingAlpha = false, false, false
                if scrollParent then scrollParent.ScrollingEnabled = true end
            end
        end
    end)
    if addConnection then addConnection(endConn) end

    -- Wpisywanie kodu HEX (z obsługą RGBA np. #FFFFFF00)
    HexInput.FocusLost:Connect(function(enterPressed)
        local raw = HexInput.Text:gsub("%s+", ""):gsub("^#", "")
        if #raw == 8 then
            local r = tonumber(raw:sub(1, 2), 16)
            local g = tonumber(raw:sub(3, 4), 16)
            local b = tonumber(raw:sub(5, 6), 16)
            local a = tonumber(raw:sub(7, 8), 16)
            if r and g and b and a then
                CurrentColor = Color3.fromRGB(r, g, b)
                Alpha = a / 255
                H, S, V = Color3.toHSV(CurrentColor)
                setDotPos(S, V)
                setKnobPos(HueKnob, H)
                setKnobPos(AlphaKnob, Alpha)
                UpdateColor(true)
                HexInput.Text = string.format("#%02X%02X%02X%02X", r, g, b, a)
                return
            end
        elseif #raw == 6 or #raw == 3 then
            local ok, parsed = pcall(function() return Color3.fromHex(raw) end)
            if ok and parsed then
                CurrentColor = parsed
                H, S, V = Color3.toHSV(CurrentColor)
                setDotPos(S, V)
                setKnobPos(HueKnob, H)
                UpdateColor(true)
                HexInput.Text = "#" .. CurrentColor:ToHex():upper()
                return
            end
        end
        HexInput.Text = "#" .. CurrentColor:ToHex():upper()
    end)

    -- Płynne rozwijanie / zwijanie (Accordion z animacją Tween)
    local isExpanded = false
    local isTweening = false
    local TARGET_CONTENT_HEIGHT = 214

    local function togglePicker()
        if isTweening then return end
        isTweening = true
        isExpanded = not isExpanded

        if isExpanded then
            DropdownContent.Visible = true
            DropdownContent.Size = UDim2.new(1, 0, 0, 0)

            TweenService:Create(ChevronIcon, TweenInfo.new(0.24, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Rotation = 180
            }):Play()

            local tw = TweenService:Create(DropdownContent, TweenInfo.new(0.24, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Size = UDim2.new(1, 0, 0, TARGET_CONTENT_HEIGHT)
            })
            tw:Play()
            tw.Completed:Connect(function()
                isTweening = false
            end)
        else
            TweenService:Create(ChevronIcon, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
                Rotation = 0
            }):Play()

            local tw = TweenService:Create(DropdownContent, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
                Size = UDim2.new(1, 0, 0, 0)
            })
            tw:Play()
            tw.Completed:Connect(function()
                if not isExpanded then
                    DropdownContent.Visible = false
                end
                isTweening = false
            end)
        end
    end

    HeaderBtn.MouseButton1Click:Connect(togglePicker)

    -- Inicjalizacja pozycji
    setDotPos(S, V)
    setKnobPos(HueKnob, H)
    setKnobPos(AlphaKnob, Alpha)
    UpdateColor(true)

    local API = {}
    function API:Set(newCol, newAlpha)
        if typeof(newCol) == "Color3" then
            CurrentColor = newCol
        elseif type(newCol) == "table" then
            CurrentColor = Color3.fromRGB(newCol[1] or 255, newCol[2] or 255, newCol[3] or 255)
            if newCol[4] ~= nil then Alpha = math.clamp(tonumber(newCol[4]) or 1, 0, 1) end
        elseif type(newCol) == "string" then
            local clean = newCol:gsub("#", "")
            if #clean == 8 then
                local a = tonumber(clean:sub(7, 8), 16)
                if a then Alpha = a / 255 end
            end
            local ok, c = pcall(function() return Color3.fromHex(clean:sub(1, 6)) end)
            if ok and c then CurrentColor = c end
        end
        if newAlpha ~= nil then
            Alpha = math.clamp(tonumber(newAlpha) or 1, 0, 1)
        end
        H, S, V = Color3.toHSV(CurrentColor)
        setDotPos(S, V)
        setKnobPos(HueKnob, H)
        setKnobPos(AlphaKnob, Alpha)
        UpdateColor()
    end
    function API:Get()
        return CurrentColor, Alpha
    end

    return API
end