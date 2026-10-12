--[[
    MenuTest - Modern Emote Settings Library
    Styled to match Universal Suite / MenuTest Design System
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local Player = Players.LocalPlayer
if not Player then
    Player = Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
end

local function ColorToHex(c)
    return string.format("#%02x%02x%02x", math.round(c.R*255), math.round(c.G*255), math.round(c.B*255))
end

local function HexToColor(hex)
    local success, result = pcall(function()
        hex = hex:gsub("#", "")
        return Color3.fromRGB(tonumber(hex:sub(1,2), 16), tonumber(hex:sub(3,4), 16), tonumber(hex:sub(5,6), 16))
    end)
    return success and result or nil
end

local function GetUIContainer()
    local success, coreGui = pcall(function() return CoreGui end)
    if success and coreGui and typeof(gethui) == "function" then
        local h = gethui()
        if h then return h end
    end
    if success and coreGui and coreGui:FindFirstChild("RobloxGui") then
        return coreGui.RobloxGui
    end
    return Player:WaitForChild("PlayerGui")
end

local Theme = {
    Background = Color3.fromRGB(15, 15, 18),
    Sidebar = Color3.fromRGB(18, 18, 22),
    Header = Color3.fromRGB(20, 20, 24),
    Card = Color3.fromRGB(22, 22, 27),
    CardBorder = Color3.fromRGB(34, 34, 42),
    Border = Color3.fromRGB(35, 35, 44),
    Divider = Color3.fromRGB(28, 28, 35),
    Accent = Color3.fromRGB(16, 185, 129), -- Emerald green
    AccentGlow = Color3.fromRGB(5, 150, 105),
    Text = Color3.fromRGB(240, 240, 245),
    TextMuted = Color3.fromRGB(140, 140, 152),
    TextDim = Color3.fromRGB(90, 90, 100),
    Danger = Color3.fromRGB(239, 68, 68),
    DangerHover = Color3.fromRGB(220, 38, 38),
    FontRegular = Enum.Font.Gotham,
    FontMedium = Enum.Font.GothamMedium,
    FontBold = Enum.Font.GothamBold,
    CornerRadius = UDim.new(0, 10),
    CardCorner = UDim.new(0, 8),
    ButtonCorner = UDim.new(0, 6)
}

local LucideSprites = {
    ["x"]             = { 16898613869, Vector2.new(48, 48), Vector2.new(869, 906) },
    ["minus"]         = { 16898613613, Vector2.new(48, 48), Vector2.new(771, 196) },
    ["settings"]      = { 16898613777, Vector2.new(48, 48), Vector2.new(771, 257) },
    ["sliders"]       = { 16898613777, Vector2.new(48, 48), Vector2.new(404, 771) },
    ["gamepad"]       = { 16898613353, Vector2.new(48, 48), Vector2.new(967, 759) },
    ["palette"]       = { 16898613613, Vector2.new(48, 48), Vector2.new(453, 918) },
    ["film"]          = { 16898613353, Vector2.new(48, 48), Vector2.new(710, 771) },
    ["clapperboard"]  = { 16898613044, Vector2.new(48, 48), Vector2.new(257, 869) },
    ["layers"]        = { 16898613509, Vector2.new(48, 48), Vector2.new(98, 967) },
    ["book"]          = { 16898612819, Vector2.new(48, 48), Vector2.new(820, 612) },
    ["folder"]        = { 16898613353, Vector2.new(48, 48), Vector2.new(404, 967) },
    ["archive"]       = { 16898612629, Vector2.new(48, 48), Vector2.new(918, 49) },
    ["user"]          = { 16898613869, Vector2.new(48, 48), Vector2.new(661, 869) },
    ["chevron-right"] = { 16898612819, Vector2.new(48, 48), Vector2.new(869, 759) },
    ["check"]         = { 16898612819, Vector2.new(48, 48), Vector2.new(710, 869) }
}

local function applyLucide(img, name)
    if not img then return end
    local IconsMod = (typeof(getgenv) == "function" and getgenv()._MenuTestIconsModule) or _G._MenuTestIconsModule
    if IconsMod and IconsMod.Apply then
        local ok = pcall(function() IconsMod:Apply(img, name) end)
        if ok and img.Image and img.Image ~= "" then return end
    end
    local d = LucideSprites[name]
    if d and (img:IsA("ImageLabel") or img:IsA("ImageButton")) then
        img.Image = "rbxassetid://" .. tostring(d[1])
        img.ImageRectSize = d[2]
        img.ImageRectOffset = d[3]
    end
end

local TabIconNames = {
    ["General"]   = "settings",
    ["Buttons"]   = "gamepad",
    ["Theme"]     = "palette",
    ["Animation"] = "film",
    ["Page"]      = "layers",
    ["Backup"]    = "folder"
}

local SettingsUI = Instance.new("ScreenGui")
SettingsUI.Name = "MenuTest_EmoteSettings"
SettingsUI.ResetOnSpawn = false
SettingsUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
SettingsUI.DisplayOrder = 99990
pcall(function()
    SettingsUI.Parent = GetUIContainer()
end)

local UIScale = Instance.new("UIScale")
UIScale.Parent = SettingsUI
local function UpdateUIScale()
    local cam = workspace.CurrentCamera
    if not cam then return end
    local viewport = cam.ViewportSize
    local width = viewport.X
    local height = viewport.Y
    if width <= 0 or height <= 0 then return end
    local scale = math.min(width / 1280, height / 720)
    scale = math.clamp(scale, 0.75, 1.1)
    UIScale.Scale = scale
end
UpdateUIScale()
if workspace.CurrentCamera then
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(UpdateUIScale)
end

local Lib = {}

function Lib:Tween(obj, info, goal)
    local tween = TweenService:Create(obj, info, goal)
    tween:Play()
    return tween
end

function Lib:Create(className, properties, children)
    local obj = Instance.new(className)
    for k, v in pairs(properties or {}) do
        obj[k] = v
    end
    for _, child in ipairs(children or {}) do
        child.Parent = obj
    end
    return obj
end

-- ==================== MODERN COLOR PICKER ====================
local PickerFrame = nil
function Lib:OpenPicker(default, callback, includeAlpha)
    if PickerFrame then PickerFrame:Destroy() PickerFrame = nil end

    local current = default or Color3.fromRGB(255, 255, 255)
    local currentAlpha = 1
    local h, s, v = current:ToHSV()

    PickerFrame = Lib:Create("Frame", {
        Name = "ColorPickerModal",
        Parent = SettingsUI,
        BackgroundColor3 = Theme.Background,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(300, includeAlpha and 360 or 320),
        ZIndex = 5000,
        BorderSizePixel = 0
    }, {
        Lib:Create("UICorner", {CornerRadius = Theme.CornerRadius}),
        Lib:Create("UIStroke", {Color = Theme.Border, Thickness = 1})
    })

    -- Header
    local pHeader = Lib:Create("Frame", {
        Parent = PickerFrame,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 36)
    }, {
        Lib:Create("TextLabel", {
            Text = "Color Picker",
            Font = Theme.FontBold,
            TextSize = 13,
            TextColor3 = Theme.Text,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 14, 0, 0),
            Size = UDim2.new(1, -50, 1, 0),
            TextXAlignment = Enum.TextXAlignment.Left
        }),
        Lib:Create("TextButton", {
            Name = "CloseBtn",
            Text = "✕",
            Font = Theme.FontBold,
            TextSize = 14,
            TextColor3 = Theme.TextMuted,
            BackgroundTransparency = 1,
            Position = UDim2.new(1, -32, 0, 4),
            Size = UDim2.fromOffset(26, 26)
        })
    })
    pHeader.CloseBtn.MouseButton1Click:Connect(function()
        if PickerFrame then PickerFrame:Destroy() PickerFrame = nil end
    end)

    -- Swatch Preview
    local swatch = Lib:Create("Frame", {
        Parent = PickerFrame,
        BackgroundColor3 = current,
        Position = UDim2.new(0, 14, 0, 42),
        Size = UDim2.new(1, -28, 0, 32)
    }, {
        Lib:Create("UICorner", {CornerRadius = Theme.ButtonCorner}),
        Lib:Create("UIStroke", {Color = Theme.CardBorder, Thickness = 1})
    })

    -- Hue Slider
    local hueBg = Lib:Create("Frame", {
        Parent = PickerFrame,
        BackgroundColor3 = Color3.fromRGB(255, 0, 0),
        Position = UDim2.new(0, 14, 0, 84),
        Size = UDim2.new(1, -28, 0, 20)
    }, {
        Lib:Create("UICorner", {CornerRadius = UDim.new(0, 4)}),
        Lib:Create("UIGradient", {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
                ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
                ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
                ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
                ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))
            })
        })
    })

    local hueKnob = Lib:Create("Frame", {
        Parent = hueBg,
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        Size = UDim2.fromOffset(6, 24),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(h, 0, 0.5, 0)
    }, {
        Lib:Create("UICorner", {CornerRadius = UDim.new(0, 3)}),
        Lib:Create("UIStroke", {Color = Color3.fromRGB(0, 0, 0), Thickness = 1})
    })

    -- Saturation/Value Slider
    local satBg = Lib:Create("Frame", {
        Parent = PickerFrame,
        BackgroundColor3 = Color3.fromHSV(h, 1, 1),
        Position = UDim2.new(0, 14, 0, 114),
        Size = UDim2.new(1, -28, 0, 20)
    }, {
        Lib:Create("UICorner", {CornerRadius = UDim.new(0, 4)}),
        Lib:Create("UIGradient", {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                ColorSequenceKeypoint.new(1, Color3.fromHSV(h, 1, 1))
            })
        })
    })

    local satKnob = Lib:Create("Frame", {
        Parent = satBg,
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        Size = UDim2.fromOffset(6, 24),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(s, 0, 0.5, 0)
    }, {
        Lib:Create("UICorner", {CornerRadius = UDim.new(0, 3)}),
        Lib:Create("UIStroke", {Color = Color3.fromRGB(0, 0, 0), Thickness = 1})
    })

    -- Brightness/Value Slider
    local valBg = Lib:Create("Frame", {
        Parent = PickerFrame,
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        Position = UDim2.new(0, 14, 0, 144),
        Size = UDim2.new(1, -28, 0, 20)
    }, {
        Lib:Create("UICorner", {CornerRadius = UDim.new(0, 4)}),
        Lib:Create("UIGradient", {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
                ColorSequenceKeypoint.new(1, Color3.fromHSV(h, s, 1))
            })
        })
    })

    local valKnob = Lib:Create("Frame", {
        Parent = valBg,
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        Size = UDim2.fromOffset(6, 24),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(v, 0, 0.5, 0)
    }, {
        Lib:Create("UICorner", {CornerRadius = UDim.new(0, 3)}),
        Lib:Create("UIStroke", {Color = Color3.fromRGB(0, 0, 0), Thickness = 1})
    })

    -- Hex and RGB Inputs row
    local inputsRow = Lib:Create("Frame", {
        Parent = PickerFrame,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 14, 0, 176),
        Size = UDim2.new(1, -28, 0, 32)
    })

    local hexBox = Lib:Create("TextBox", {
        Parent = inputsRow,
        BackgroundColor3 = Theme.Card,
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(0.48, 0, 1, 0),
        Font = Theme.FontMedium,
        TextSize = 12,
        TextColor3 = Theme.Text,
        Text = ColorToHex(current),
        ClearTextOnFocus = false
    }, {
        Lib:Create("UICorner", {CornerRadius = Theme.ButtonCorner}),
        Lib:Create("UIStroke", {Color = Theme.CardBorder, Thickness = 1})
    })

    local rgbLabel = Lib:Create("TextLabel", {
        Parent = inputsRow,
        BackgroundColor3 = Theme.Card,
        Position = UDim2.new(0.52, 0, 0, 0),
        Size = UDim2.new(0.48, 0, 1, 0),
        Font = Theme.FontMedium,
        TextSize = 11,
        TextColor3 = Theme.TextMuted,
        Text = string.format("%d, %d, %d", math.round(current.R*255), math.round(current.G*255), math.round(current.B*255))
    }, {
        Lib:Create("UICorner", {CornerRadius = Theme.ButtonCorner}),
        Lib:Create("UIStroke", {Color = Theme.CardBorder, Thickness = 1})
    })

    local function updateColor(newH, newS, newV)
        h = math.clamp(newH or h, 0, 1)
        s = math.clamp(newS or s, 0, 1)
        v = math.clamp(newV or v, 0, 1)
        current = Color3.fromHSV(h, s, v)
        swatch.BackgroundColor3 = current
        hueKnob.Position = UDim2.new(h, 0, 0.5, 0)
        satKnob.Position = UDim2.new(s, 0, 0.5, 0)
        valKnob.Position = UDim2.new(v, 0, 0.5, 0)
        satBg.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
        hexBox.Text = ColorToHex(current)
        rgbLabel.Text = string.format("%d, %d, %d", math.round(current.R*255), math.round(current.G*255), math.round(current.B*255))
    end

    local function bindSlider(frame, onDrag)
        local dragging = false
        frame.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                local percent = math.clamp((input.Position.X - frame.AbsolutePosition.X) / frame.AbsoluteSize.X, 0, 1)
                onDrag(percent)
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local percent = math.clamp((input.Position.X - frame.AbsolutePosition.X) / frame.AbsoluteSize.X, 0, 1)
                onDrag(percent)
            end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)
    end

    bindSlider(hueBg, function(p) updateColor(p, s, v) end)
    bindSlider(satBg, function(p) updateColor(h, p, v) end)
    bindSlider(valBg, function(p) updateColor(h, s, p) end)

    hexBox.FocusLost:Connect(function()
        local col = HexToColor(hexBox.Text)
        if col then
            local nH, nS, nV = col:ToHSV()
            updateColor(nH, nS, nV)
        else
            hexBox.Text = ColorToHex(current)
        end
    end)

    -- Action Buttons (Apply / Cancel)
    local actionsRow = Lib:Create("Frame", {
        Parent = PickerFrame,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 14, 1, -44),
        Size = UDim2.new(1, -28, 0, 32)
    })

    local applyBtn = Lib:Create("TextButton", {
        Parent = actionsRow,
        BackgroundColor3 = Theme.Accent,
        Position = UDim2.new(0.52, 0, 0, 0),
        Size = UDim2.new(0.48, 0, 1, 0),
        Font = Theme.FontBold,
        TextSize = 12,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Text = "Apply"
    }, {
        Lib:Create("UICorner", {CornerRadius = Theme.ButtonCorner})
    })

    local cancelBtn = Lib:Create("TextButton", {
        Parent = actionsRow,
        BackgroundColor3 = Theme.Card,
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(0.48, 0, 1, 0),
        Font = Theme.FontMedium,
        TextSize = 12,
        TextColor3 = Theme.TextMuted,
        Text = "Cancel"
    }, {
        Lib:Create("UICorner", {CornerRadius = Theme.ButtonCorner}),
        Lib:Create("UIStroke", {Color = Theme.CardBorder, Thickness = 1})
    })

    applyBtn.MouseButton1Click:Connect(function()
        if callback then callback(current, currentAlpha) end
        if PickerFrame then PickerFrame:Destroy() PickerFrame = nil end
    end)

    cancelBtn.MouseButton1Click:Connect(function()
        if PickerFrame then PickerFrame:Destroy() PickerFrame = nil end
    end)
end

-- ==================== MAIN WINDOW STRUCTURE ====================
local MainFrame = Lib:Create("Frame", {
    Name = "MainFrame",
    Parent = SettingsUI,
    BackgroundColor3 = Theme.Background,
    BorderSizePixel = 0,
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(580, 400),
    ClipsDescendants = true
}, {
    Lib:Create("UICorner", {CornerRadius = Theme.CornerRadius}),
    Lib:Create("UIStroke", {Color = Theme.Border, Thickness = 1})
})
MainFrame.Visible = false

-- Draggable Header
local Header = Lib:Create("Frame", {
    Name = "Header",
    Parent = MainFrame,
    BackgroundColor3 = Theme.Header,
    BorderSizePixel = 0,
    Position = UDim2.new(0, 0, 0, 0),
    Size = UDim2.new(1, 0, 0, 38)
}, {
    Lib:Create("Frame", {
        Name = "Divider",
        BackgroundColor3 = Theme.Divider,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 1, -1),
        Size = UDim2.new(1, 0, 0, 1)
    })
})

-- Header Title
Lib:Create("TextLabel", {
    Name = "Title",
    Parent = Header,
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 16, 0, 0),
    Size = UDim2.new(1, -120, 1, 0),
    Font = Theme.FontBold,
    TextSize = 13,
    TextColor3 = Theme.Text,
    Text = "Emote Settings",
    TextXAlignment = Enum.TextXAlignment.Left
})

-- Window Controls (Minimize, Close)
local Controls = Lib:Create("Frame", {
    Name = "Controls",
    Parent = Header,
    BackgroundTransparency = 1,
    Position = UDim2.new(1, -85, 0, 0),
    Size = UDim2.new(0, 80, 1, 0)
}, {
    Lib:Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder
    })
})

local MinimizeBtn = Lib:Create("TextButton", {
    Name = "Minimize",
    Parent = Controls,
    BackgroundColor3 = Color3.fromRGB(35, 35, 45),
    BackgroundTransparency = 1,
    Size = UDim2.fromOffset(26, 26),
    Text = "",
    LayoutOrder = 1
}, {
    Lib:Create("UICorner", {CornerRadius = UDim.new(0, 5)})
})

local MinIcon = Lib:Create("ImageLabel", {
    Name = "Icon",
    Parent = MinimizeBtn,
    BackgroundTransparency = 1,
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(13, 13),
    ImageColor3 = Theme.TextMuted
})
applyLucide(MinIcon, "minus")

local CloseBtn = Lib:Create("TextButton", {
    Name = "Close",
    Parent = Controls,
    BackgroundColor3 = Color3.fromRGB(220, 50, 50),
    BackgroundTransparency = 1,
    Size = UDim2.fromOffset(26, 26),
    Text = "",
    LayoutOrder = 2
}, {
    Lib:Create("UICorner", {CornerRadius = UDim.new(0, 5)})
})

local CloseIcon = Lib:Create("ImageLabel", {
    Name = "Icon",
    Parent = CloseBtn,
    BackgroundTransparency = 1,
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(13, 13),
    ImageColor3 = Theme.TextMuted
})
applyLucide(CloseIcon, "x")

MinimizeBtn.MouseEnter:Connect(function()
    Lib:Tween(MinimizeBtn, TweenInfo.new(0.15), {BackgroundTransparency = 0.5})
    MinIcon.ImageColor3 = Theme.Text
end)
MinimizeBtn.MouseLeave:Connect(function()
    Lib:Tween(MinimizeBtn, TweenInfo.new(0.15), {BackgroundTransparency = 1})
    MinIcon.ImageColor3 = Theme.TextMuted
end)

CloseBtn.MouseEnter:Connect(function()
    Lib:Tween(CloseBtn, TweenInfo.new(0.15), {BackgroundTransparency = 0.2})
    CloseIcon.ImageColor3 = Color3.fromRGB(255, 255, 255)
end)
CloseBtn.MouseLeave:Connect(function()
    Lib:Tween(CloseBtn, TweenInfo.new(0.15), {BackgroundTransparency = 1})
    CloseIcon.ImageColor3 = Theme.TextMuted
end)

local isMinimized = false
local defaultWindowHeight = 400
MinimizeBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        Lib:Tween(MainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.fromOffset(580, 38)
        })
    else
        Lib:Tween(MainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.fromOffset(580, defaultWindowHeight)
        })
    end
end)

CloseBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
end)

-- Window Dragging Logic
local Dragging, DragStart, StartPos
Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        Dragging = true
        DragStart = input.Position
        StartPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then Dragging = false end
        end)
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) and Dragging then
        local delta = (input.Position - DragStart) / UIScale.Scale
        MainFrame.Position = UDim2.new(StartPos.X.Scale, StartPos.X.Offset + delta.X, StartPos.Y.Scale, StartPos.Y.Offset + delta.Y)
    end
end)

-- ==================== LEFT SIDEBAR ====================
local Sidebar = Lib:Create("Frame", {
    Name = "Sidebar",
    Parent = MainFrame,
    BackgroundColor3 = Theme.Sidebar,
    BorderSizePixel = 0,
    Position = UDim2.new(0, 0, 0, 38),
    Size = UDim2.new(0, 145, 1, -38)
}, {
    Lib:Create("Frame", {
        Name = "RightBorder",
        BackgroundColor3 = Theme.Divider,
        BorderSizePixel = 0,
        Position = UDim2.new(1, -1, 0, 0),
        Size = UDim2.new(0, 1, 1, 0)
    })
})

-- Sidebar Header Label
Lib:Create("TextLabel", {
    Name = "SidebarHeader",
    Parent = Sidebar,
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 14, 0, 10),
    Size = UDim2.new(1, -28, 0, 20),
    Font = Theme.FontBold,
    TextSize = 11,
    TextColor3 = Theme.TextDim,
    Text = "CATEGORIES",
    TextXAlignment = Enum.TextXAlignment.Left
})

-- Sidebar Tabs Container
local NavContainer = Lib:Create("ScrollingFrame", {
    Name = "NavContainer",
    Parent = Sidebar,
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    Position = UDim2.new(0, 8, 0, 34),
    Size = UDim2.new(1, -16, 1, -86),
    CanvasSize = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    ScrollBarThickness = 0,
    ScrollingDirection = Enum.ScrollingDirection.Y
}, {
    Lib:Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        Padding = UDim.new(0, 4),
        SortOrder = Enum.SortOrder.LayoutOrder
    })
})

-- Bottom Profile Card (matching Universal Suite)
local ProfileCard = Lib:Create("Frame", {
    Name = "ProfileCard",
    Parent = Sidebar,
    BackgroundColor3 = Theme.Sidebar,
    BorderSizePixel = 0,
    Position = UDim2.new(0, 0, 1, -50),
    Size = UDim2.new(1, -1, 0, 50)
}, {
    Lib:Create("Frame", {
        Name = "TopDivider",
        BackgroundColor3 = Theme.Divider,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(1, 0, 0, 1)
    })
})

local AvatarImage = Lib:Create("ImageLabel", {
    Name = "Avatar",
    Parent = ProfileCard,
    BackgroundColor3 = Theme.Card,
    BorderSizePixel = 0,
    Position = UDim2.new(0, 12, 0.5, -14),
    Size = UDim2.fromOffset(28, 28),
    Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(Player.UserId) .. "&w=150&h=150"
}, {
    Lib:Create("UICorner", {CornerRadius = UDim.new(0, 14)}),
    Lib:Create("UIStroke", {Color = Theme.CardBorder, Thickness = 1})
})

Lib:Create("TextLabel", {
    Name = "PlayerName",
    Parent = ProfileCard,
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 48, 0, 10),
    Size = UDim2.new(1, -75, 0, 16),
    Font = Theme.FontBold,
    TextSize = 11,
    TextColor3 = Theme.Text,
    Text = Player.DisplayName or Player.Name,
    TextTruncate = Enum.TextTruncate.AtEnd,
    TextXAlignment = Enum.TextXAlignment.Left
})

Lib:Create("TextLabel", {
    Name = "Username",
    Parent = ProfileCard,
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 48, 0, 26),
    Size = UDim2.new(1, -75, 0, 14),
    Font = Theme.FontRegular,
    TextSize = 9,
    TextColor3 = Theme.TextMuted,
    Text = "@" .. Player.Name,
    TextTruncate = Enum.TextTruncate.AtEnd,
    TextXAlignment = Enum.TextXAlignment.Left
})

-- Gear / Settings Icon in profile card
local ProfileGear = Lib:Create("ImageButton", {
    Name = "ProfileGear",
    Parent = ProfileCard,
    BackgroundTransparency = 1,
    Position = UDim2.new(1, -26, 0.5, -7),
    Size = UDim2.fromOffset(14, 14),
    ImageColor3 = Theme.TextMuted
})
applyLucide(ProfileGear, "settings")

-- ==================== RIGHT CONTENT PAGES CONTAINER ====================
local ContentArea = Lib:Create("Frame", {
    Name = "ContentArea",
    Parent = MainFrame,
    BackgroundColor3 = Theme.Background,
    BorderSizePixel = 0,
    Position = UDim2.new(0, 145, 0, 38),
    Size = UDim2.new(1, -145, 1, -38)
})

local TabContainers = {}
local TabButtons = {}
local ActiveTab = nil
local Components = {}

-- CreateTab Method
local function CreateTab(name, order)
    local isFirst = (order == 1) or (ActiveTab == nil)

    local TabContainer = Lib:Create("ScrollingFrame", {
        Name = name .. "Page",
        Parent = ContentArea,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(1, 0, 1, 0),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = Color3.fromRGB(45, 45, 54),
        ScrollBarImageTransparency = 0.2,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        Visible = isFirst,
        AutomaticCanvasSize = Enum.AutomaticSize.Y
    }, {
        Lib:Create("UIPadding", {
            PaddingTop = UDim.new(0, 14),
            PaddingBottom = UDim.new(0, 14),
            PaddingLeft = UDim.new(0, 14),
            PaddingRight = UDim.new(0, 14)
        }),
        Lib:Create("UIListLayout", {
            Padding = UDim.new(0, 8),
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            SortOrder = Enum.SortOrder.LayoutOrder
        })
    })

    -- Sidebar Nav Button
    local TabBtn = Lib:Create("TextButton", {
        Name = name,
        Parent = NavContainer,
        BackgroundColor3 = isFirst and Color3.fromRGB(26, 26, 32) or Color3.fromRGB(18, 18, 22),
        BackgroundTransparency = isFirst and 0 or 1,
        Size = UDim2.new(1, 0, 0, 34),
        Font = Theme.FontMedium,
        Text = "",
        LayoutOrder = order or 1
    }, {
        Lib:Create("UICorner", {CornerRadius = Theme.ButtonCorner})
    })

    -- Left Accent Bar indicator
    local Indicator = Lib:Create("Frame", {
        Name = "Indicator",
        Parent = TabBtn,
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0.5, -9),
        Size = UDim2.new(0, 3, 0, 18),
        Visible = isFirst
    }, {
        Lib:Create("UICorner", {CornerRadius = UDim.new(0, 2)})
    })

    -- Icon
    local TabIcon = Lib:Create("ImageLabel", {
        Name = "Icon",
        Parent = TabBtn,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0.5, -8),
        Size = UDim2.fromOffset(16, 16),
        ImageColor3 = isFirst and Color3.fromRGB(255, 255, 255) or Theme.TextMuted
    })
    local iconKey = TabIconNames[name] or "settings"
    applyLucide(TabIcon, iconKey)

    -- Label
    local TabLabel = Lib:Create("TextLabel", {
        Name = "Label",
        Parent = TabBtn,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 34, 0, 0),
        Size = UDim2.new(1, -38, 1, 0),
        Font = Theme.FontMedium,
        TextSize = 12,
        TextColor3 = isFirst and Color3.fromRGB(255, 255, 255) or Theme.TextMuted,
        Text = name:gsub("%d", ""),
        TextXAlignment = Enum.TextXAlignment.Left
    })

    local function setActiveVisual(active)
        if active then
            Lib:Tween(TabBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(26, 26, 32), BackgroundTransparency = 0})
            Indicator.Visible = true
            TabIcon.ImageColor3 = Color3.fromRGB(255, 255, 255)
            TabLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        else
            Lib:Tween(TabBtn, TweenInfo.new(0.2), {BackgroundTransparency = 1})
            Indicator.Visible = false
            TabIcon.ImageColor3 = Theme.TextMuted
            TabLabel.TextColor3 = Theme.TextMuted
        end
    end

    TabBtn.MouseEnter:Connect(function()
        if ActiveTab ~= name then
            Lib:Tween(TabBtn, TweenInfo.new(0.15), {BackgroundTransparency = 0.5, BackgroundColor3 = Color3.fromRGB(22, 22, 28)})
            TabLabel.TextColor3 = Theme.Text
            TabIcon.ImageColor3 = Theme.Text
        end
    end)

    TabBtn.MouseLeave:Connect(function()
        if ActiveTab ~= name then
            Lib:Tween(TabBtn, TweenInfo.new(0.15), {BackgroundTransparency = 1})
            TabLabel.TextColor3 = Theme.TextMuted
            TabIcon.ImageColor3 = Theme.TextMuted
        end
    end)

    TabBtn.MouseButton1Click:Connect(function()
        if ActiveTab == name then return end
        for tName, container in pairs(TabContainers) do
            container.Visible = (tName == name)
        end
        for tName, btnData in pairs(TabButtons) do
            btnData.setActive(tName == name)
        end
        ActiveTab = name
    end)

    TabContainers[name] = TabContainer
    TabButtons[name] = {
        Button = TabBtn,
        setActive = setActiveVisual
    }

    if isFirst then
        ActiveTab = name
    end

    return TabContainer
end

-- ==================== MODERN UI COMPONENTS ====================

function Components:AddItem(parent, title, description)
    local hasDesc = description and description ~= "" and description ~= " "
    local ItemContainer = Lib:Create("Frame", {
        Name = title,
        Parent = parent,
        BackgroundColor3 = Theme.Card,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, hasDesc and 54 or 42)
    }, {
        Lib:Create("UICorner", {CornerRadius = Theme.CardCorner}),
        Lib:Create("UIStroke", {Color = Theme.CardBorder, Thickness = 1})
    })

    local TitleLabel = Lib:Create("TextLabel", {
        Name = "Title",
        Parent = ItemContainer,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 14, 0, hasDesc and 8 or 0),
        Size = UDim2.new(0.68, 0, 0, hasDesc and 20 or 42),
        Font = Theme.FontMedium,
        Text = title,
        TextColor3 = Theme.Text,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd
    })

    if hasDesc then
        Lib:Create("TextLabel", {
            Name = "Desc",
            Parent = ItemContainer,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 14, 0, 27),
            Size = UDim2.new(0.68, 0, 0, 18),
            Font = Theme.FontRegular,
            Text = description,
            TextColor3 = Theme.TextMuted,
            TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd
        })
    end

    return ItemContainer
end

function Components:AddToggle(container, title, description, default, callback)
    local ItemContainer = Components:AddItem(container, title, description)
    local state = default or false

    local ToggleBg = Lib:Create("TextButton", {
        Name = "ToggleSwitch",
        Parent = ItemContainer,
        BackgroundColor3 = state and Theme.Accent or Color3.fromRGB(36, 36, 44),
        BorderSizePixel = 0,
        Position = UDim2.new(1, -52, 0.5, -11),
        Size = UDim2.fromOffset(40, 22),
        Text = "",
        AutoButtonColor = false
    }, {
        Lib:Create("UICorner", {CornerRadius = UDim.new(0, 11)}),
        Lib:Create("UIStroke", {
            Color = state and Theme.AccentGlow or Color3.fromRGB(50, 50, 60),
            Thickness = 1
        })
    })

    local Knob = Lib:Create("Frame", {
        Name = "Knob",
        Parent = ToggleBg,
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8),
        Size = UDim2.fromOffset(16, 16)
    }, {
        Lib:Create("UICorner", {CornerRadius = UDim.new(0, 8)})
    })

    local stroke = ToggleBg:FindFirstChildOfClass("UIStroke")

    local function updateVisuals(newState)
        state = newState
        local targetColor = state and Theme.Accent or Color3.fromRGB(36, 36, 44)
        local strokeColor = state and Theme.AccentGlow or Color3.fromRGB(50, 50, 60)
        local targetPos = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)

        Lib:Tween(ToggleBg, TweenInfo.new(0.2), {BackgroundColor3 = targetColor})
        if stroke then
            Lib:Tween(stroke, TweenInfo.new(0.2), {Color = strokeColor})
        end
        Lib:Tween(Knob, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = targetPos})
    end

    ToggleBg.MouseButton1Click:Connect(function()
        local newState = not state
        updateVisuals(newState)
        if callback then callback(newState) end
    end)

    return {
        SetState = function(newState)
            updateVisuals(newState)
            if callback then callback(newState) end
        end
    }
end

function Components:AddDropdown(container, title, options, default, callback)
    local ItemContainer = Components:AddItem(container, title, "")
    options = options or {}
    local current = default or options[1] or "Select"

    local DropBtn = Lib:Create("TextButton", {
        Name = "DropButton",
        Parent = ItemContainer,
        BackgroundColor3 = Color3.fromRGB(28, 28, 35),
        BorderSizePixel = 0,
        Position = UDim2.new(1, -135, 0.5, -14),
        Size = UDim2.fromOffset(122, 28),
        Font = Theme.FontMedium,
        Text = tostring(current) .. "  ▼",
        TextColor3 = Theme.Text,
        TextSize = 11,
        AutoButtonColor = false
    }, {
        Lib:Create("UICorner", {CornerRadius = Theme.ButtonCorner}),
        Lib:Create("UIStroke", {Color = Theme.CardBorder, Thickness = 1})
    })

    local FloatingList = nil

    local function closeFloatingList()
        if FloatingList then
            FloatingList:Destroy()
            FloatingList = nil
        end
    end

    local function openFloatingList()
        closeFloatingList()

        FloatingList = Lib:Create("Frame", {
            Name = "DropdownMenu",
            Parent = SettingsUI,
            BackgroundColor3 = Theme.Background,
            BorderSizePixel = 0,
            Position = UDim2.new(0, DropBtn.AbsolutePosition.X / UIScale.Scale, 0, (DropBtn.AbsolutePosition.Y + DropBtn.AbsoluteSize.Y + 4) / UIScale.Scale),
            Size = UDim2.fromOffset(122, math.min(#options * 28 + 36, 160)),
            ZIndex = 3000,
            ClipsDescendants = true
        }, {
            Lib:Create("UICorner", {CornerRadius = Theme.ButtonCorner}),
            Lib:Create("UIStroke", {Color = Theme.Border, Thickness = 1})
        })

        local SearchBox = Lib:Create("TextBox", {
            Name = "SearchBox",
            Parent = FloatingList,
            BackgroundColor3 = Theme.Card,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 6, 0, 6),
            Size = UDim2.new(1, -12, 0, 22),
            Font = Theme.FontRegular,
            PlaceholderText = "Search...",
            PlaceholderColor3 = Theme.TextDim,
            Text = "",
            TextColor3 = Theme.Text,
            TextSize = 10,
            ClearTextOnFocus = false
        }, {
            Lib:Create("UICorner", {CornerRadius = UDim.new(0, 4)}),
            Lib:Create("UIStroke", {Color = Theme.CardBorder, Thickness = 1})
        })

        local OptionsScroll = Lib:Create("ScrollingFrame", {
            Name = "OptionsScroll",
            Parent = FloatingList,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 4, 0, 32),
            Size = UDim2.new(1, -8, 1, -36),
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = Color3.fromRGB(50, 50, 60)
        }, {
            Lib:Create("UIListLayout", {
                Padding = UDim.new(0, 2),
                SortOrder = Enum.SortOrder.LayoutOrder
            })
        })

        local function renderOptions(filter)
            for _, c in ipairs(OptionsScroll:GetChildren()) do
                if c:IsA("TextButton") then c:Destroy() end
            end
            local f = (filter or ""):lower()
            for _, opt in ipairs(options) do
                local optStr = tostring(opt)
                if f == "" or optStr:lower():find(f, 1, true) then
                    local isSelected = (optStr == tostring(current))
                    local b = Lib:Create("TextButton", {
                        Parent = OptionsScroll,
                        BackgroundColor3 = isSelected and Theme.Accent or Theme.Card,
                        BackgroundTransparency = isSelected and 0 or 1,
                        BorderSizePixel = 0,
                        Size = UDim2.new(1, 0, 0, 24),
                        Font = isSelected and Theme.FontBold or Theme.FontRegular,
                        Text = "  " .. optStr,
                        TextColor3 = isSelected and Color3.fromRGB(255, 255, 255) or Theme.Text,
                        TextSize = 11,
                        TextXAlignment = Enum.TextXAlignment.Left
                    }, {
                        Lib:Create("UICorner", {CornerRadius = UDim.new(0, 4)})
                    })

                    b.MouseEnter:Connect(function()
                        if optStr ~= tostring(current) then
                            b.BackgroundTransparency = 0.5
                            b.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
                        end
                    end)
                    b.MouseLeave:Connect(function()
                        if optStr ~= tostring(current) then
                            b.BackgroundTransparency = 1
                        end
                    end)

                    b.MouseButton1Click:Connect(function()
                        current = opt
                        DropBtn.Text = tostring(current) .. "  ▼"
                        closeFloatingList()
                        if callback then callback(current) end
                    end)
                end
            end
        end

        SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
            renderOptions(SearchBox.Text)
        end)
        renderOptions("")
    end

    DropBtn.MouseButton1Click:Connect(function()
        if FloatingList then
            closeFloatingList()
        else
            openFloatingList()
        end
    end)

    return {
        SetValue = function(val)
            current = val
            DropBtn.Text = tostring(val) .. "  ▼"
        end,
        Refresh = function(newOptions)
            options = newOptions or {}
            if #options > 0 and not table.find(options, current) then
                current = options[1]
                DropBtn.Text = tostring(current) .. "  ▼"
            end
        end,
        Button = DropBtn
    }
end

function Components:AddButton(container, title, callback)
    local isDanger = title:lower():find("clean") or title:lower():find("delete") or title:lower():find("reset")
    local Btn = Lib:Create("TextButton", {
        Name = title .. "Btn",
        Parent = container,
        BackgroundColor3 = isDanger and Theme.Danger or Color3.fromRGB(32, 32, 40),
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 34),
        Font = Theme.FontBold,
        Text = title,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 12,
        AutoButtonColor = false
    }, {
        Lib:Create("UICorner", {CornerRadius = Theme.ButtonCorner}),
        Lib:Create("UIStroke", {
            Color = isDanger and Color3.fromRGB(185, 28, 28) or Theme.CardBorder,
            Thickness = 1
        })
    })

    Btn.MouseEnter:Connect(function()
        Lib:Tween(Btn, TweenInfo.new(0.15), {
            BackgroundColor3 = isDanger and Theme.DangerHover or Color3.fromRGB(42, 42, 54)
        })
    end)
    Btn.MouseLeave:Connect(function()
        Lib:Tween(Btn, TweenInfo.new(0.15), {
            BackgroundColor3 = isDanger and Theme.Danger or Color3.fromRGB(32, 32, 40)
        })
    end)

    Btn.MouseButton1Click:Connect(function()
        if callback then callback() end
    end)

    return Btn
end

function Components:AddInput(container, title, placeholder, default, callback)
    local ItemContainer = Components:AddItem(container, title, "")
    local InputBox = Lib:Create("TextBox", {
        Name = "InputBox",
        Parent = ItemContainer,
        BackgroundColor3 = Color3.fromRGB(26, 26, 32),
        BorderSizePixel = 0,
        Position = UDim2.new(1, -145, 0.5, -13),
        Size = UDim2.fromOffset(132, 26),
        Font = Theme.FontRegular,
        PlaceholderText = placeholder or "Type here...",
        PlaceholderColor3 = Theme.TextDim,
        Text = default or "",
        TextColor3 = Theme.Text,
        TextSize = 11,
        ClearTextOnFocus = false
    }, {
        Lib:Create("UICorner", {CornerRadius = Theme.ButtonCorner}),
        Lib:Create("UIStroke", {Color = Theme.CardBorder, Thickness = 1})
    })

    InputBox.FocusLost:Connect(function()
        if callback then callback(InputBox.Text) end
    end)

    return {
        SetValue = function(val)
            InputBox.Text = tostring(val or "")
        end
    }
end

function Components:AddSection(container, title)
    local SectionFrame = Lib:Create("Frame", {
        Name = "Section_" .. title,
        Parent = container,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 26)
    }, {
        Lib:Create("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 4, 0, 4),
            Size = UDim2.new(1, -8, 1, -4),
            Font = Theme.FontBold,
            Text = title:upper(),
            TextColor3 = Theme.TextDim,
            TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left
        }),
        Lib:Create("Frame", {
            Name = "Line",
            BackgroundColor3 = Theme.Divider,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 4, 1, -1),
            Size = UDim2.new(1, -8, 0, 1)
        })
    })
    return SectionFrame
end

function Components:AddTextArea(container, title, placeholder, default, callback)
    local ItemContainer = Components:AddItem(container, title, "")
    ItemContainer.Size = UDim2.new(1, 0, 0, 70)

    local TextArea = Lib:Create("TextBox", {
        Name = "TextArea",
        Parent = ItemContainer,
        BackgroundColor3 = Color3.fromRGB(26, 26, 32),
        BorderSizePixel = 0,
        Position = UDim2.new(0, 12, 0, 26),
        Size = UDim2.new(1, -24, 0, 36),
        Font = Theme.FontRegular,
        PlaceholderText = placeholder or "",
        PlaceholderColor3 = Theme.TextDim,
        Text = default or "",
        TextColor3 = Theme.Text,
        TextSize = 11,
        ClearTextOnFocus = false,
        MultiLine = true,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top
    }, {
        Lib:Create("UICorner", {CornerRadius = Theme.ButtonCorner}),
        Lib:Create("UIStroke", {Color = Theme.CardBorder, Thickness = 1})
    })

    TextArea.FocusLost:Connect(function()
        if callback then callback(TextArea.Text) end
    end)

    return TextArea
end

function Components:AddIconButton(container, imageId, callback)
    local imgFormatted = tostring(imageId):find("rbxassetid://") and tostring(imageId) or ("rbxassetid://" .. tostring(imageId))
    local BtnHolder = Lib:Create("ImageButton", {
        Parent = container,
        BackgroundColor3 = Color3.fromRGB(28, 28, 36),
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(30, 30),
        Image = imgFormatted,
        ImageColor3 = Theme.TextMuted,
        AutoButtonColor = false
    }, {
        Lib:Create("UICorner", {CornerRadius = Theme.ButtonCorner}),
        Lib:Create("UIStroke", {Color = Theme.CardBorder, Thickness = 1})
    })

    BtnHolder.MouseEnter:Connect(function()
        Lib:Tween(BtnHolder, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(38, 38, 48), ImageColor3 = Color3.fromRGB(255, 255, 255)})
    end)
    BtnHolder.MouseLeave:Connect(function()
        Lib:Tween(BtnHolder, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(28, 28, 36), ImageColor3 = Theme.TextMuted})
    end)

    BtnHolder.MouseButton1Click:Connect(function()
        if callback then callback() end
    end)

    return BtnHolder
end

function Components:AddFolder(container, title)
    local FolderCard = Lib:Create("Frame", {
        Name = "Folder_" .. title,
        Parent = container,
        BackgroundColor3 = Theme.Card,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 38),
        ClipsDescendants = true
    }, {
        Lib:Create("UICorner", {CornerRadius = Theme.CardCorner}),
        Lib:Create("UIStroke", {Color = Theme.CardBorder, Thickness = 1})
    })

    local HeaderBtn = Lib:Create("TextButton", {
        Name = "HeaderBtn",
        Parent = FolderCard,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 38),
        Font = Theme.FontMedium,
        Text = "",
        AutoButtonColor = false
    })

    Lib:Create("TextLabel", {
        Parent = HeaderBtn,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 14, 0, 0),
        Size = UDim2.new(1, -45, 1, 0),
        Font = Theme.FontBold,
        TextSize = 12,
        TextColor3 = Theme.Text,
        Text = title,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    local Chevron = Lib:Create("TextLabel", {
        Parent = HeaderBtn,
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -30, 0, 0),
        Size = UDim2.new(0, 20, 1, 0),
        Font = Theme.FontBold,
        TextSize = 11,
        TextColor3 = Theme.TextMuted,
        Text = "▼"
    })

    local Content = Lib:Create("Frame", {
        Name = "Content",
        Parent = FolderCard,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 8, 0, 38),
        Size = UDim2.new(1, -16, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y
    }, {
        Lib:Create("UIListLayout", {
            Padding = UDim.new(0, 6),
            SortOrder = Enum.SortOrder.LayoutOrder
        }),
        Lib:Create("UIPadding", {
            PaddingBottom = UDim.new(0, 8)
        })
    })

    local expanded = false
    HeaderBtn.MouseButton1Click:Connect(function()
        expanded = not expanded
        Chevron.Text = expanded and "▲" or "▼"
        if expanded then
            FolderCard.AutomaticSize = Enum.AutomaticSize.Y
        else
            FolderCard.AutomaticSize = Enum.AutomaticSize.None
            FolderCard.Size = UDim2.new(1, 0, 0, 38)
        end
    end)

    return Content
end

function Components:AddColorPicker(container, title, default, callback)
    local ItemContainer = Components:AddItem(container, title, "")
    local color = default or Color3.fromRGB(255, 255, 255)

    local SwatchBtn = Lib:Create("TextButton", {
        Name = "ColorSwatch",
        Parent = ItemContainer,
        BackgroundColor3 = color,
        BorderSizePixel = 0,
        Position = UDim2.new(1, -54, 0.5, -11),
        Size = UDim2.fromOffset(40, 22),
        Text = "",
        AutoButtonColor = false
    }, {
        Lib:Create("UICorner", {CornerRadius = Theme.ButtonCorner}),
        Lib:Create("UIStroke", {Color = Theme.CardBorder, Thickness = 1})
    })

    SwatchBtn.MouseButton1Click:Connect(function()
        Lib:OpenPicker(color, function(newC, newA)
            color = newC
            SwatchBtn.BackgroundColor3 = color
            if callback then callback(color, newA) end
        end)
    end)

    return {
        SetValue = function(c)
            color = c or color
            SwatchBtn.BackgroundColor3 = color
        end
    }
end

function Components:AddInputWithColor(container, title, placeholder, defaultText, defaultColor, callback)
    local ItemContainer = Components:AddItem(container, title, "")
    ItemContainer.Size = UDim2.new(1, 0, 0, 52)
    local color = defaultColor or Color3.fromRGB(255, 255, 255)
    local text = defaultText or ""

    local InputBox = Lib:Create("TextBox", {
        Parent = ItemContainer,
        BackgroundColor3 = Color3.fromRGB(26, 26, 32),
        BorderSizePixel = 0,
        Position = UDim2.new(0, 14, 0, 22),
        Size = UDim2.new(1, -74, 0, 24),
        Font = Theme.FontRegular,
        PlaceholderText = placeholder or "",
        PlaceholderColor3 = Theme.TextDim,
        Text = text,
        TextColor3 = Theme.Text,
        TextSize = 11,
        ClearTextOnFocus = false
    }, {
        Lib:Create("UICorner", {CornerRadius = Theme.ButtonCorner}),
        Lib:Create("UIStroke", {Color = Theme.CardBorder, Thickness = 1})
    })

    local SwatchBtn = Lib:Create("TextButton", {
        Parent = ItemContainer,
        BackgroundColor3 = color,
        BorderSizePixel = 0,
        Position = UDim2.new(1, -50, 0, 22),
        Size = UDim2.fromOffset(36, 24),
        Text = "",
        AutoButtonColor = false
    }, {
        Lib:Create("UICorner", {CornerRadius = Theme.ButtonCorner}),
        Lib:Create("UIStroke", {Color = Theme.CardBorder, Thickness = 1})
    })

    SwatchBtn.MouseButton1Click:Connect(function()
        Lib:OpenPicker(color, function(newC)
            color = newC
            SwatchBtn.BackgroundColor3 = color
            if callback then callback(InputBox.Text, color) end
        end)
    end)

    InputBox.FocusLost:Connect(function()
        if callback then callback(InputBox.Text, color) end
    end)

    return {
        SetValue = function(t, c)
            text = t or text
            color = c or color
            InputBox.Text = text
            SwatchBtn.BackgroundColor3 = color
        end
    }
end

function Components:AddAssetColor(container, title, placeholder, defaultText, defaultColor, callback)
    return Components:AddInputWithColor(container, title, placeholder, defaultText, defaultColor, callback)
end

local Library = {
    UI = SettingsUI,
    MainFrame = MainFrame,
    CreateTab = CreateTab,
    AddToggle = function(...) return Components:AddToggle(...) end,
    AddDropdown = function(...) return Components:AddDropdown(...) end,
    AddColorPicker = function(...) return Components:AddColorPicker(...) end,
    AddButton = function(...) return Components:AddButton(...) end,
    AddInput = function(...) return Components:AddInput(...) end,
    AddSection = function(...) return Components:AddSection(...) end,
    AddTextArea = function(...) return Components:AddTextArea(...) end,
    AddIconButton = function(...) return Components:AddIconButton(...) end,
    AddFolder = function(...) return Components:AddFolder(...) end,
    AddItem = function(...) return Components:AddItem(...) end,
    AddInputWithColor = function(...) return Components:AddInputWithColor(...) end,
    AddAssetColor = function(...) return Components:AddAssetColor(...) end,
    OpenPicker = function(...) return Lib:OpenPicker(...) end,
    Create = function(self, ...) return Lib:Create(...) end,
    Tween = function(self, ...) return Lib:Tween(...) end
}

return Library
