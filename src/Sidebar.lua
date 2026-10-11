local Sidebar = {}

function Sidebar:Create(UI, theme, config)
    local SidebarFrame = Instance.new("Frame")
    SidebarFrame.Name = "Sidebar"
    SidebarFrame.Size = UDim2.new(0, 200, 1, -32)
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
    Title.TextSize = 16
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
    local AvatarContainer = Instance.new("Frame")
    AvatarContainer.Size = UDim2.new(0, 40, 0, 40)
    AvatarContainer.Position = UDim2.new(0, 15, 0.5, 0)
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
    NameFrame.Size = UDim2.new(1, -70, 1, 0) -- full height for proper vertical centering
    NameFrame.Position = UDim2.new(0, 65, 0.5, 0) -- centered vertically in profile
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
    DisplayName.TextSize = 12
    DisplayName.TextScaled = false -- Wyłączone TextScaled, żeby tekst trzymał stabilny rozmiar
    DisplayName.Size = UDim2.new(1, 0, 1, 0)
    DisplayName.Position = UDim2.new(0, 0, 0, 0)
    DisplayName.AnchorPoint = Vector2.new(0, 0)
    DisplayName.BackgroundTransparency = 1
    DisplayName.TextXAlignment = Enum.TextXAlignment.Left
    DisplayName.TextYAlignment = Enum.TextYAlignment.Center -- Idealne wyśrodkowanie w pionie obok awatara
    DisplayName.Parent = NameFrame
    UI.ThemeManager:Register(DisplayName, "TextColor3", "Text")

    return SidebarFrame, TabList
end

return Sidebar