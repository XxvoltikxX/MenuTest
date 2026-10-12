local Sidebar = {}

function Sidebar:Create(UI, theme, config, customWidth)
    local sidebarW = customWidth or (config and config.SidebarWidth) or 200
    local isCompact = sidebarW <= 170

    local SidebarFrame = Instance.new("Frame")
    SidebarFrame.Name = "Sidebar"
    SidebarFrame.Size = UDim2.new(0, sidebarW, 1, -32)
    SidebarFrame.Position = UDim2.new(0, 0, 0, 32)
    SidebarFrame.BackgroundTransparency = 1
    SidebarFrame.Parent = UI.MainFrame
    UI.Sidebar = SidebarFrame

    -- // GÓRNA CZĘŚĆ (Tytuł i Linia)
    local Title = Instance.new("TextLabel")
    Title.Name = "Title"
    local rawName = tostring(config.Name or "X HUB")
    Title.Text = #rawName > 16 and string.sub(rawName, 1, 16) or rawName
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = isCompact and 13 or 16
    Title.Size = UDim2.new(1, 0, 0, 45)
    Title.BackgroundTransparency = 1
    Title.Parent = SidebarFrame
    UI.ThemeManager:Register(Title, "TextColor3", "Text")

    local TitleLine = Instance.new("Frame")
    TitleLine.Size = UDim2.new(1, 0, 0, 1)
    TitleLine.Position = UDim2.new(0, 0, 0, 45)
    TitleLine.BorderSizePixel = 0
    TitleLine.ZIndex = 10
    TitleLine.Parent = SidebarFrame
    UI.ThemeManager:Register(TitleLine, "BackgroundColor3", "Accent")

    -- // LISTA ZAKŁADEK (SCROLLING FRAME)
    local TabList = Instance.new("ScrollingFrame")
    TabList.Name = "TabList"
    TabList.Size = UDim2.new(1, 0, 1, -106)
    TabList.Position = UDim2.new(0, 0, 0, 46)
    TabList.BackgroundTransparency = 1
    TabList.BorderSizePixel = 0
    TabList.CanvasSize = UDim2.new(0, 0, 0, 0)
    TabList.AutomaticCanvasSize = Enum.AutomaticSize.Y
    TabList.ScrollBarThickness = 2
    TabList.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 80)
    TabList.Parent = SidebarFrame
    TabList.ClipsDescendants = true
    UI.TabList = TabList

    local TabListLayout = Instance.new("UIListLayout")
    TabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    TabListLayout.Padding = UDim.new(0, 0)
    TabListLayout.Parent = TabList

    -- // DOLNA CZĘŚĆ (Profil)
    local ProfileFrame = Instance.new("Frame")
    ProfileFrame.Name = "ProfileFrame"
    ProfileFrame.Size = UDim2.new(1, 0, 0, 60)
    ProfileFrame.Position = UDim2.new(0, 0, 1, 0)
    ProfileFrame.AnchorPoint = Vector2.new(0, 1)
    ProfileFrame.BackgroundTransparency = 1
    ProfileFrame.Parent = SidebarFrame

    local ProfileLine = Instance.new("Frame")
    ProfileLine.Size = UDim2.new(1, 0, 0, 1)
    ProfileLine.Position = UDim2.new(0, 0, 0, 0)
    ProfileLine.BorderSizePixel = 0
    ProfileLine.ZIndex = 10
    ProfileLine.Parent = ProfileFrame
    UI.ThemeManager:Register(ProfileLine, "BackgroundColor3", "Accent")

    -- Kontener na awatar (dla maski)
    local avatarSize = isCompact and 32 or 40
    local AvatarContainer = Instance.new("Frame")
    AvatarContainer.Size = UDim2.new(0, avatarSize, 0, avatarSize)
    AvatarContainer.Position = UDim2.new(0, isCompact and 8 or 15, 0.5, 0)
    AvatarContainer.AnchorPoint = Vector2.new(0, 0.5)
    AvatarContainer.BackgroundTransparency = 1
    AvatarContainer.Parent = ProfileFrame

    -- BEZPIECZNE POBRANIE GRACZA
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):Wait() and Players.LocalPlayer

    local Avatar = Instance.new("ImageLabel")
    Avatar.Name = "Avatar"
    Avatar.Size = UDim2.new(1, 0, 1, 0)
    Avatar.BackgroundTransparency = 1
    Avatar.Image = "rbxthumb://type=AvatarHeadShot&id=" .. (LocalPlayer and LocalPlayer.UserId or 1) .. "&w=150&h=150"
    Avatar.Parent = AvatarContainer

    -- Zaokrąglenie awatara
    local AvatarCorner = Instance.new("UICorner")
    AvatarCorner.CornerRadius = UDim.new(1, 0)
    AvatarCorner.Parent = Avatar

    local NameFrame = Instance.new("Frame")
    NameFrame.Name = "NameFrame"
    local nameFrameLeft = isCompact and 46 or 65
    local nameFrameRightSpace = isCompact and -78 or -112
    NameFrame.Size = UDim2.new(1, nameFrameRightSpace, 1, 0)
    NameFrame.Position = UDim2.new(0, nameFrameLeft, 0.5, 0)
    NameFrame.AnchorPoint = Vector2.new(0, 0.5)
    NameFrame.BackgroundTransparency = 1
    NameFrame.Parent = ProfileFrame

    -- Dynamic display name handling
    local displayName = LocalPlayer and LocalPlayer.DisplayName or "User"
    local userName = LocalPlayer and LocalPlayer.Name or "Player"
    local nameToShow = displayName
    if #displayName > 12 then
        nameToShow = userName
    end
    local DisplayName = Instance.new("TextLabel")
    DisplayName.Name = "DisplayName"
    DisplayName.Text = nameToShow
    DisplayName.Font = Enum.Font.GothamBold
    DisplayName.TextSize = isCompact and 11 or 12
    DisplayName.TextScaled = false
    DisplayName.TextTruncate = Enum.TextTruncate.AtEnd
    DisplayName.Size = UDim2.new(1, 0, 1, 0)
    DisplayName.Position = UDim2.new(0, 0, 0, 0)
    DisplayName.AnchorPoint = Vector2.new(0, 0)
    DisplayName.BackgroundTransparency = 1
    DisplayName.TextXAlignment = Enum.TextXAlignment.Left
    DisplayName.TextYAlignment = Enum.TextYAlignment.Center
    DisplayName.Parent = NameFrame
    UI.ThemeManager:Register(DisplayName, "TextColor3", "Text")

    -- // Przycisk Ustawień w stylu Discord (Zębatka Lucide)
    local TweenService = game:GetService("TweenService")
    local Icons = UI.Icons or (typeof(getgenv) == "function" and getgenv()._MenuTestIconsModule) or _G._MenuTestIconsModule

    local settingsBtnSize = isCompact and 28 or 32
    local SettingsBtn = Instance.new("TextButton")
    SettingsBtn.Name = "SettingsBtn"
    SettingsBtn.Size = UDim2.new(0, settingsBtnSize, 0, settingsBtnSize)
    SettingsBtn.Position = UDim2.new(1, isCompact and -6 or -10, 0.5, 0)
    SettingsBtn.AnchorPoint = Vector2.new(1, 0.5)
    SettingsBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
    SettingsBtn.BackgroundTransparency = 1
    SettingsBtn.Text = ""
    SettingsBtn.AutoButtonColor = false
    SettingsBtn.Parent = ProfileFrame

    Instance.new("UICorner", SettingsBtn).CornerRadius = UDim.new(0, 6)

    local SettingsIcon = Instance.new("ImageLabel")
    SettingsIcon.Name = "Icon"
    SettingsIcon.Size = UDim2.new(0, 18, 0, 18)
    SettingsIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
    SettingsIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    SettingsIcon.BackgroundTransparency = 1
    SettingsIcon.ImageColor3 = Color3.fromRGB(160, 160, 170)
    SettingsIcon.Parent = SettingsBtn

    if Icons and Icons.Apply then
        Icons:Apply(SettingsIcon, "settings")
    end
    UI.ThemeManager:Register(SettingsIcon, "ImageColor3", "Text_Secondary")

    SettingsBtn.MouseEnter:Connect(function()
        if not UI.IsSettingsOpen then
            local hoverBg = UI.ThemeManager:GetColor("Accent2") or Color3.fromRGB(40, 40, 50)
            local hoverTxt = UI.ThemeManager:GetColor("Text") or Color3.fromRGB(255, 255, 255)
            TweenService:Create(SettingsBtn, TweenInfo.new(0.2), {
                BackgroundColor3 = hoverBg,
                BackgroundTransparency = 0
            }):Play()
            TweenService:Create(SettingsIcon, TweenInfo.new(0.2), {
                ImageColor3 = hoverTxt,
                Rotation = 25
            }):Play()
        end
    end)

    SettingsBtn.MouseLeave:Connect(function()
        if not UI.IsSettingsOpen then
            local dimTxt = UI.ThemeManager:GetColor("Text_Secondary") or Color3.fromRGB(160, 160, 170)
            TweenService:Create(SettingsBtn, TweenInfo.new(0.2), {
                BackgroundTransparency = 1
            }):Play()
            TweenService:Create(SettingsIcon, TweenInfo.new(0.2), {
                ImageColor3 = dimTxt,
                Rotation = 0
            }):Play()
        end
    end)

    SettingsBtn.MouseButton1Click:Connect(function()
        if UI.IsSettingsOpen then
            if UI.PreviousTab and UI.SelectTab then
                UI:SelectTab(UI.PreviousTab)
            elseif UI.SelectDashboard then
                UI:SelectDashboard()
            end
        else
            if UI.OpenSettings then UI:OpenSettings() end
        end
    end)

    UI.SettingsBtn = SettingsBtn
    UI.SettingsIcon = SettingsIcon

    return SidebarFrame, TabList
end

return Sidebar