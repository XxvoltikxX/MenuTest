local MenuLib = {}

-- // SERWISY
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

local ProtectedLocation = nil
pcall(function() ProtectedLocation = CoreGui end)
if not ProtectedLocation then
    ProtectedLocation = PlayerGui
end

-- Automatyczne czyszczenie poprzedniej sesji menu i skryptów (podpisane pod Voltik)
if typeof(getgenv) == "function" then
    if getgenv()._VoltikMenuCleanup then pcall(getgenv()._VoltikMenuCleanup); getgenv()._VoltikMenuCleanup = nil end
    if getgenv()._VoltikMenuTestGui then pcall(function() getgenv()._VoltikMenuTestGui:Destroy() end); getgenv()._VoltikMenuTestGui = nil end
end
if _G._VoltikMenuCleanup then pcall(_G._VoltikMenuCleanup); _G._VoltikMenuCleanup = nil end

local baseUrl = "https://raw.githubusercontent.com/XxvoltikxX/MenuTest/refs/heads/main/src/"

-- // SYSTEM BEZPIECZNEGO POBIERANIA (Safe HttpGet z retry oraz ominięciem cache CDN)
local function safeHttpGet(url, maxRetries, retryDelay)
    maxRetries  = maxRetries  or 3
    retryDelay  = retryDelay  or 0.5
    local cacheBuster = (url:find("%?") and "&" or "?") .. "_nocache=" .. tostring(tick()) .. "_" .. tostring(os.time()) .. "_" .. tostring(math.random(100000, 999999))
    local fetchUrl = url .. cacheBuster
    for attempt = 1, maxRetries do
        local ok, result = pcall(function()
            return game:HttpGet(fetchUrl)
        end)
        if ok and type(result) == "string" and #result > 0 then
            return true, result
        end
        warn(string.format("[MenuLib] Próba %d/%d nie powiodła się: %s", attempt, maxRetries, tostring(url)))
        if attempt < maxRetries then task.wait(retryDelay) end
    end
    return false, nil
end

-- // PAMIĘĆ PODRĘCZNA BIEŻĄCEJ SESJI (Wyłącznie w pamięci lokalnej, zapobiega zablokowaniu aktualizacji)
local SessionCache = {}
local SessionModuleCache = {}

-- Pobierz, skompiluj i uruchom skrypt z URL lub lokalnego pliku (z buforowaniem bieżącej sesji)
local function safeLoadUrl(url, fallbackValue)
    if SessionModuleCache[url] ~= nil then
        return SessionModuleCache[url]
    end

    local ok, content = false, SessionCache[url]
    if content and type(content) == "string" and #content > 0 then
        ok = true
    else
        local isDev = (typeof(getgenv) == "function" and getgenv()._MenuTestDevMode == true)
        if isDev and typeof(readfile) == "function" then
            local localRel = url:gsub("^https://raw%.githubusercontent%.com/[^/]+/[^/]+/refs/heads/[^/]+/src/", "")
            local candidates = {
                "MenuTest/src/" .. localRel,
                "src/" .. localRel,
                localRel
            }
            for _, c in ipairs(candidates) do
                if typeof(isfile) == "function" and isfile(c) then
                    local s, data = pcall(readfile, c)
                    if s and data and type(data) == "string" and #data > 0 then
                        ok, content = true, data
                        break
                    end
                end
            end
        end
        if not ok or not content then
            ok, content = safeHttpGet(url)
        end
        if ok and content then
            content = content:gsub("^\239\187\191", "")
            SessionCache[url] = content
        end
    end

    -- SPRAWDZENIE CZY TREŚĆ TO FAKTYCZNIE TEKST (zapobiega próbie kompilacji nil)
    if not ok or not content or type(content) ~= "string" or #content == 0 then
        warn("[MenuLib] Nie udało się pobrać lub treść jest pusta: " .. tostring(url))
        return fallbackValue
    end
    
    content = content:gsub("^\239\187\191", "")
    
    local chunk, compileErr = loadstring(content)
    if not chunk then
        warn("[MenuLib] Błąd kompilacji " .. tostring(url) .. ": " .. tostring(compileErr))
        return fallbackValue
    end
    
    local runOk, result = pcall(chunk)
    if not runOk then
        warn("[MenuLib] Błąd wykonania " .. tostring(url) .. ": " .. tostring(result))
        return fallbackValue
    end
    
    SessionModuleCache[url] = result
    return result
end

-- Bezpieczna (no-op) wersja konstruktora elementu używana jako fallback
local function dummyElement()
    return {}
end
local function dummyElementLoader()
    return dummyElement
end

-- Fallback Window module (nie powinien się uruchomić, ale chroni przed crashem)
local WindowModuleFallback = {
    Create = function(self, config)
        warn("[MenuLib] KRYTYCZNY BŁĄD: Window.lua nie załadował się! Używam fallbacku.")
        local dummyGui   = Instance.new("ScreenGui")
        local dummyFrame = Instance.new("Frame")
        dummyFrame.Parent = dummyGui
        return {
            ScreenGui        = dummyGui,
            MainFrame        = dummyFrame,
            MinBtn           = Instance.new("TextButton"),
            CloseBtn         = Instance.new("TextButton"),
            Tabs             = {},
            Pages            = {},
            TabObjects       = {},
            _readyCallbacks  = {},
            ShowExitModal    = function() end,
            CreateTab        = function() return {Button = Instance.new("TextButton"), Page = Instance.new("ScrollingFrame")} end,
            SelectDashboard  = function() end,
            SelectTab        = function() end,
        }
    end
}

-- // FUNKCJE POMOCNICZE
function MenuLib:GenerateID(length)
    local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local result = ""
    for i = 1, length or 12 do
        result = result .. string.sub(chars, math.random(1, #chars), math.random(1, #chars))
    end
    return result
end

local function prettyEncode(tbl)
    local result = "{\n"
    local entries = {}
    local order = {"Main", "Secondary", "Accent", "Accent2", "Success", "Text", "Text_Secondary", "Close"}
    for _, k in ipairs(order) do
        if tbl[k] then
            table.insert(entries, "\t\"" .. k .. "\": [" .. table.concat(tbl[k], ", ") .. "]")
        end
    end
    for k, v in pairs(tbl) do
        local found = false
        for _, o in ipairs(order) do if o == k then found = true; break end end
        if not found then
            table.insert(entries, "\t\"" .. k .. "\": [" .. table.concat(v, ", ") .. "]")
        end
    end
    return result .. table.concat(entries, ",\n") .. "\n}"
end

-- Funkcja precyzyjnie wykrywająca urządzenia dotykowe i mobilne
local function isMobileDevice(cfg)
    if cfg and (cfg.TestMobile or cfg.Mobile or cfg.IsMobile) then return true end
    if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled and not UserInputService.MouseEnabled then
        return true
    end
    return false
end

-- // ============================================================
-- // EKRAN INICJALIZACJI: PŁYNNA ANIMACJA LIXHUB (VISIONOS GLASS EMBLEM)
-- // ============================================================
local function createLoadingIndicator(title, isMobile)
    local screenParent
    pcall(function() screenParent = CoreGui end)
    if not screenParent then screenParent = PlayerGui end

    local loaderGui = Instance.new("ScreenGui")
    loaderGui.Name = "LixHub_LoaderSplash"
    loaderGui:SetAttribute("MenuLoaderIndicator", true)
    loaderGui.ResetOnSpawn = false
    loaderGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    loaderGui.DisplayOrder = 999999
    pcall(function() loaderGui.IgnoreGuiInset = true end)
    pcall(function() loaderGui.Parent = screenParent end)

    -- Ciemne tło winiety kinowej (Cinematic Glass Backdrop)
    local Backdrop = Instance.new("Frame")
    Backdrop.Name = "Backdrop"
    Backdrop.Size = UDim2.new(1, 0, 1, 0)
    Backdrop.BackgroundColor3 = Color3.fromRGB(5, 6, 9)
    Backdrop.BackgroundTransparency = 1
    Backdrop.BorderSizePixel = 0
    Backdrop.ZIndex = 1
    Backdrop.Parent = loaderGui

    -- Główna karta Splash LixHub
    local Splash = Instance.new("Frame")
    Splash.Name = "LixHub_Splash"
    Splash.Size = UDim2.new(0, 310, 0, 195)
    Splash.Position = UDim2.new(0.5, 0, 0.52, 0)
    Splash.AnchorPoint = Vector2.new(0.5, 0.5)
    Splash.BackgroundColor3 = Color3.fromRGB(13, 14, 21)
    Splash.BackgroundTransparency = 1
    Splash.BorderSizePixel = 0
    Splash.ClipsDescendants = true
    Splash.ZIndex = 2
    Splash.Parent = loaderGui

    Instance.new("UICorner", Splash).CornerRadius = UDim.new(0, 22)
    local SplashStroke = Instance.new("UIStroke", Splash)
    SplashStroke.Color = Color3.fromRGB(80, 95, 145)
    SplashStroke.Thickness = 1.2
    SplashStroke.Transparency = 1
    SplashStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    -- Rozświetlenie poświaty tła w karcie (Ambient Glow Gradient)
    local GlowRadial = Instance.new("Frame")
    GlowRadial.Size = UDim2.new(0, 160, 0, 160)
    GlowRadial.Position = UDim2.new(0.5, 0, 0.28, 0)
    GlowRadial.AnchorPoint = Vector2.new(0.5, 0.5)
    GlowRadial.BackgroundColor3 = Color3.fromRGB(99, 102, 241)
    GlowRadial.BackgroundTransparency = 0.92
    GlowRadial.BorderSizePixel = 0
    GlowRadial.ZIndex = 3
    GlowRadial.Parent = Splash
    Instance.new("UICorner", GlowRadial).CornerRadius = UDim.new(1, 0)

    -- // ========================================================
    -- // ORBITAL LOGO CORE (Animowany rdzeń z obracającymi się cząstkami)
    -- // ========================================================
    local LogoContainer = Instance.new("Frame")
    LogoContainer.Name = "LogoContainer"
    LogoContainer.Size = UDim2.new(0, 64, 0, 64)
    LogoContainer.Position = UDim2.new(0.5, 0, 0, 44)
    LogoContainer.AnchorPoint = Vector2.new(0.5, 0.5)
    LogoContainer.BackgroundTransparency = 1
    LogoContainer.ZIndex = 4
    LogoContainer.Parent = Splash

    -- Zewnętrzny pierścień orbitalny
    local OrbitRing = Instance.new("Frame")
    OrbitRing.Size = UDim2.new(1, 0, 1, 0)
    OrbitRing.BackgroundTransparency = 1
    OrbitRing.ZIndex = 4
    OrbitRing.Parent = LogoContainer
    Instance.new("UICorner", OrbitRing).CornerRadius = UDim.new(1, 0)
    local OrbitStroke = Instance.new("UIStroke", OrbitRing)
    OrbitStroke.Color = Color3.fromRGB(60, 70, 105)
    OrbitStroke.Thickness = 1
    OrbitStroke.Transparency = 0.55

    -- Rotator cząstek orbitalnych
    local OrbitSpinner = Instance.new("Frame")
    OrbitSpinner.Size = UDim2.new(1, 0, 1, 0)
    OrbitSpinner.BackgroundTransparency = 1
    OrbitSpinner.ZIndex = 5
    OrbitSpinner.Parent = LogoContainer

    local Satellite1 = Instance.new("Frame")
    Satellite1.Size = UDim2.new(0, 7, 0, 7)
    Satellite1.Position = UDim2.new(0.5, -3.5, 0, -3.5)
    Satellite1.BackgroundColor3 = Color3.fromRGB(99, 102, 241)
    Satellite1.BorderSizePixel = 0
    Satellite1.ZIndex = 6
    Satellite1.Parent = OrbitSpinner
    Instance.new("UICorner", Satellite1).CornerRadius = UDim.new(1, 0)
    local Sat1Stroke = Instance.new("UIStroke", Satellite1)
    Sat1Stroke.Color = Color3.fromRGB(168, 85, 247)
    Sat1Stroke.Thickness = 1.2

    local Satellite2 = Instance.new("Frame")
    Satellite2.Size = UDim2.new(0, 5, 0, 5)
    Satellite2.Position = UDim2.new(0.5, -2.5, 1, -2.5)
    Satellite2.BackgroundColor3 = Color3.fromRGB(56, 189, 248)
    Satellite2.BorderSizePixel = 0
    Satellite2.ZIndex = 6
    Satellite2.Parent = OrbitSpinner
    Instance.new("UICorner", Satellite2).CornerRadius = UDim.new(1, 0)

    -- Środkowa szklana kula monogramu LixHub
    local CoreOrb = Instance.new("Frame")
    CoreOrb.Name = "CoreOrb"
    CoreOrb.Size = UDim2.new(0, 46, 0, 46)
    CoreOrb.Position = UDim2.new(0.5, 0, 0.5, 0)
    CoreOrb.AnchorPoint = Vector2.new(0.5, 0.5)
    CoreOrb.BackgroundColor3 = Color3.fromRGB(22, 25, 38)
    CoreOrb.BorderSizePixel = 0
    CoreOrb.ZIndex = 7
    CoreOrb.Parent = LogoContainer
    Instance.new("UICorner", CoreOrb).CornerRadius = UDim.new(1, 0)

    local CoreStroke = Instance.new("UIStroke", CoreOrb)
    CoreStroke.Color = Color3.fromRGB(110, 130, 245)
    CoreStroke.Thickness = 1.2
    CoreStroke.Transparency = 0.35

    local CoreGradient = Instance.new("UIGradient", CoreOrb)
    CoreGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(36, 40, 65)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(18, 20, 32))
    })
    CoreGradient.Rotation = 45

    local CoreIcon = Instance.new("TextLabel")
    CoreIcon.Text = "L"
    CoreIcon.Font = Enum.Font.GothamBold
    CoreIcon.TextSize = 22
    CoreIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
    CoreIcon.Size = UDim2.new(1, 0, 1, 0)
    CoreIcon.BackgroundTransparency = 1
    CoreIcon.ZIndex = 8
    CoreIcon.Parent = CoreOrb

    -- // ========================================================
    -- // TYPOGRAFIA MARKI "LixHub"
    -- // ========================================================
    local TitleRow = Instance.new("Frame")
    TitleRow.Name = "TitleRow"
    TitleRow.Size = UDim2.new(1, 0, 0, 26)
    TitleRow.Position = UDim2.new(0.5, 0, 0, 96)
    TitleRow.AnchorPoint = Vector2.new(0.5, 0)
    TitleRow.BackgroundTransparency = 1
    TitleRow.ZIndex = 5
    TitleRow.Parent = Splash

    local TitleLayout = Instance.new("UIListLayout", TitleRow)
    TitleLayout.FillDirection = Enum.FillDirection.Horizontal
    TitleLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    TitleLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    TitleLayout.SortOrder = Enum.SortOrder.LayoutOrder
    TitleLayout.Padding = UDim.new(0, 5)

    local LixText = Instance.new("TextLabel")
    LixText.Name = "LixText"
    LixText.Text = "LIX"
    LixText.Font = Enum.Font.GothamBold
    LixText.TextSize = 21
    LixText.TextColor3 = Color3.fromRGB(255, 255, 255)
    LixText.AutomaticSize = Enum.AutomaticSize.X
    LixText.Size = UDim2.new(0, 0, 1, 0)
    LixText.BackgroundTransparency = 1
    LixText.LayoutOrder = 1
    LixText.ZIndex = 6
    LixText.Parent = TitleRow

    local HubBadge = Instance.new("Frame")
    HubBadge.Name = "HubBadge"
    HubBadge.Size = UDim2.new(0, 44, 0, 20)
    HubBadge.BackgroundColor3 = Color3.fromRGB(99, 102, 241)
    HubBadge.BorderSizePixel = 0
    HubBadge.LayoutOrder = 2
    HubBadge.ZIndex = 6
    HubBadge.Parent = TitleRow
    Instance.new("UICorner", HubBadge).CornerRadius = UDim.new(0, 6)

    local HbStroke = Instance.new("UIStroke", HubBadge)
    HbStroke.Color = Color3.fromRGB(168, 85, 247)
    HbStroke.Thickness = 1
    HbStroke.Transparency = 0.45

    local HubText = Instance.new("TextLabel")
    HubText.Text = "HUB"
    HubText.Font = Enum.Font.GothamBold
    HubText.TextSize = 11
    HubText.TextColor3 = Color3.fromRGB(255, 255, 255)
    HubText.Size = UDim2.new(1, 0, 1, 0)
    HubText.BackgroundTransparency = 1
    HubText.ZIndex = 7
    HubText.Parent = HubBadge

    -- // ========================================================
    -- // PŁYNNA ANIMACJA WSKAŹNIKA (LASER WAVE + FLUID PULSE DOTS)
    -- // Zamiast brzydkiego paska postępu i surowego napisu
    -- // ========================================================
    local AnimContainer = Instance.new("Frame")
    AnimContainer.Name = "AnimContainer"
    AnimContainer.Size = UDim2.new(1, 0, 0, 40)
    AnimContainer.Position = UDim2.new(0.5, 0, 0, 132)
    AnimContainer.AnchorPoint = Vector2.new(0.5, 0)
    AnimContainer.BackgroundTransparency = 1
    AnimContainer.ZIndex = 5
    AnimContainer.Parent = Splash

    -- 1. Płynna kapsuła fali laserowej (Laser Wave Beam)
    local WaveCapsule = Instance.new("Frame")
    WaveCapsule.Name = "WaveCapsule"
    WaveCapsule.Size = UDim2.new(0, 130, 0, 3)
    WaveCapsule.Position = UDim2.new(0.5, 0, 0, 10)
    WaveCapsule.AnchorPoint = Vector2.new(0.5, 0.5)
    WaveCapsule.BackgroundColor3 = Color3.fromRGB(25, 28, 42)
    WaveCapsule.BackgroundTransparency = 0.3
    WaveCapsule.BorderSizePixel = 0
    WaveCapsule.ClipsDescendants = true
    WaveCapsule.ZIndex = 6
    WaveCapsule.Parent = AnimContainer
    Instance.new("UICorner", WaveCapsule).CornerRadius = UDim.new(1, 0)

    local LaserBeam = Instance.new("Frame")
    LaserBeam.Name = "LaserBeam"
    LaserBeam.Size = UDim2.new(0, 50, 1, 0)
    LaserBeam.Position = UDim2.new(0, -50, 0, 0)
    LaserBeam.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    LaserBeam.BorderSizePixel = 0
    LaserBeam.ZIndex = 7
    LaserBeam.Parent = WaveCapsule

    local BeamGrad = Instance.new("UIGradient", LaserBeam)
    BeamGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(56, 189, 248)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(168, 85, 247)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(99, 102, 241))
    })
    BeamGrad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.5, 0),
        NumberSequenceKeypoint.new(1, 1)
    })

    -- 2. Trzy płynnie pulsujące kropki ciekłego szkła (Fluid Liquid Dots)
    local DotsRow = Instance.new("Frame")
    DotsRow.Name = "DotsRow"
    DotsRow.Size = UDim2.new(0, 48, 0, 12)
    DotsRow.Position = UDim2.new(0.5, 0, 0, 24)
    DotsRow.AnchorPoint = Vector2.new(0.5, 0.5)
    DotsRow.BackgroundTransparency = 1
    DotsRow.ZIndex = 6
    DotsRow.Parent = AnimContainer

    local DotsLayout = Instance.new("UIListLayout", DotsRow)
    DotsLayout.FillDirection = Enum.FillDirection.Horizontal
    DotsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    DotsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    DotsLayout.Padding = UDim.new(0, 8)

    local dots = {}
    for i = 1, 3 do
        local dot = Instance.new("Frame")
        dot.Size = UDim2.new(0, 5, 0, 5)
        dot.BackgroundColor3 = (i == 2) and Color3.fromRGB(168, 85, 247) or Color3.fromRGB(99, 102, 241)
        dot.BorderSizePixel = 0
        dot.ZIndex = 7
        dot.Parent = DotsRow
        Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
        table.insert(dots, dot)
    end

    -- Dynamiczna etykieta statusu gotowości (Ready Status) po ukończeniu
    local ReadyLabel = Instance.new("TextLabel")
    ReadyLabel.Name = "ReadyLabel"
    ReadyLabel.Text = ""
    ReadyLabel.Font = Enum.Font.GothamBold
    ReadyLabel.TextSize = 11
    ReadyLabel.TextColor3 = Color3.fromRGB(74, 222, 128)
    ReadyLabel.TextTransparency = 1
    ReadyLabel.Size = UDim2.new(1, 0, 0, 20)
    ReadyLabel.Position = UDim2.new(0.5, 0, 0, 16)
    ReadyLabel.AnchorPoint = Vector2.new(0.5, 0.5)
    ReadyLabel.BackgroundTransparency = 1
    ReadyLabel.ZIndex = 8
    ReadyLabel.Parent = AnimContainer

    -- // ========================================================
    -- // SILNIK PŁYNNEJ ANIMACJI W CZASIE RZECZYWISTYM (RenderStepped)
    -- // ========================================================
    local isRunning = true
    local rotAngle = 0
    local laserPos = 0
    local laserDir = 1
    local timeClock = 0

    local rs = RunService
    if not rs then
        pcall(function() rs = game:GetService("RunService") end)
    end
    local stepEvent = rs and (rs.RenderStepped or rs.Heartbeat)
    local animConn = nil

    if stepEvent then
        pcall(function()
            animConn = stepEvent:Connect(function(dt)
                if not isRunning then return end
                timeClock = timeClock + (dt or 0.016)

                -- Płynny obrót cząstek orbitalnych (120 stopni / sek)
                rotAngle = (rotAngle + (dt or 0.016) * 120) % 360
                OrbitSpinner.Rotation = rotAngle

                -- Delikatny oddech poświaty tła (Sine breathing pulse)
                local pulse = (math.sin(timeClock * 2.5) + 1) * 0.5
                GlowRadial.BackgroundTransparency = 0.90 + (pulse * 0.06)

                -- Płynny ruch lasera w kapsule (Liquid sweep)
                laserPos = laserPos + ((dt or 0.016) * 130 * laserDir)
                if laserPos > 130 then
                    laserPos = 130
                    laserDir = -1
                elseif laserPos < -50 then
                    laserPos = -50
                    laserDir = 1
                end
                LaserBeam.Position = UDim2.new(0, math.floor(laserPos), 0, 0)

                -- Falowanie 3 płynnych kropek (Staggered liquid sine wave)
                for idx, d in ipairs(dots) do
                    local dotOffset = (idx - 1) * 0.8
                    local sinVal = (math.sin(timeClock * 4 + dotOffset) + 1) * 0.5
                    d.BackgroundTransparency = 0.15 + (1 - sinVal) * 0.65
                    local dSize = 4 + (sinVal * 2.5)
                    d.Size = UDim2.new(0, dSize, 0, dSize)
                end
            end)
        end)
    end

    -- Animacja płynnego wejścia (Fade & Float In)
    TweenService:Create(Backdrop, TweenInfo.new(0.4), { BackgroundTransparency = 0.4 }):Play()
    TweenService:Create(Splash, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, 0, 0.5, 0),
        BackgroundTransparency = 0.08
    }):Play()
    TweenService:Create(SplashStroke, TweenInfo.new(0.4), { Transparency = 0.35 }):Play()

    -- // ========================================================
    -- // KONTROLER INTERFEJSU
    -- // ========================================================
    local controller = {}

    function controller:Update(progress, statusText)
        -- Bez brzydkich napisów i tradycyjnych pasków — animacja LixHub płynie sama
    end

    function controller:Done(timeText, keybindName, onFinishCallback)
        keybindName = tostring(keybindName or "K")
        local isMobileView = isMobile or (UserInputService.TouchEnabled and not UserInputService.MouseEnabled)
        local hint = isMobileView and "✓ LIXHUB GOTOWY • DOTKNIJ PRZYCISK" or ("✓ LIXHUB GOTOWY • KLAWISZ [" .. keybindName .. "]")

        -- Błysk sukcesu na rdzeniu logo
        TweenService:Create(CoreStroke, TweenInfo.new(0.2), { Color = Color3.fromRGB(74, 222, 128), Transparency = 0.1 }):Play()
        TweenService:Create(OrbitStroke, TweenInfo.new(0.2), { Color = Color3.fromRGB(74, 222, 128), Transparency = 0.3 }):Play()
        TweenService:Create(Satellite1, TweenInfo.new(0.2), { BackgroundColor3 = Color3.fromRGB(74, 222, 128) }):Play()
        TweenService:Create(Satellite2, TweenInfo.new(0.2), { BackgroundColor3 = Color3.fromRGB(74, 222, 128) }):Play()

        -- Schowaj laser i kropki, pokaż elegancką informację o klawiszu
        TweenService:Create(WaveCapsule, TweenInfo.new(0.25), { BackgroundTransparency = 1 }):Play()
        TweenService:Create(LaserBeam, TweenInfo.new(0.25), { BackgroundTransparency = 1 }):Play()
        for _, d in ipairs(dots) do
            TweenService:Create(d, TweenInfo.new(0.25), { BackgroundTransparency = 1 }):Play()
        end

        ReadyLabel.Text = hint
        TweenService:Create(ReadyLabel, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            TextTransparency = 0,
            Position = UDim2.new(0.5, 0, 0, 16)
        }):Play()

        -- Po 0.8 sekundy płynne rozejście loadera i ujawnienie menu
        task.delay(0.8, function()
            isRunning = false
            if animConn then pcall(function() animConn:Disconnect() end) end

            if onFinishCallback then
                pcall(onFinishCallback)
            end

            local twSplash = TweenService:Create(Splash, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
                Position = UDim2.new(0.5, 0, 0.46, 0),
                Size = UDim2.new(0, 330, 0, 205),
                BackgroundTransparency = 1
            })
            local twStroke = TweenService:Create(SplashStroke, TweenInfo.new(0.3), { Transparency = 1 })
            local twBackdrop = TweenService:Create(Backdrop, TweenInfo.new(0.35), { BackgroundTransparency = 1 })

            twSplash:Play()
            twStroke:Play()
            twBackdrop:Play()

            twSplash.Completed:Connect(function()
                pcall(function() loaderGui:Destroy() end)
            end)
        end)
    end

    return controller
end

-- // ============================================================
-- // GŁÓWNA FUNKCJA TWORZENIA OKNA
-- // ============================================================
function MenuLib:CreateWindow(options)
    local Config = options or {}
    local rawName = tostring(Config.Name or "Menu")
    local Name   = #rawName > 16 and string.sub(rawName, 1, 16) or rawName
    local GameId = tostring(Config.GameId or (game and (game.PlaceId or game.GameId)) or "109949693269081")
    local startTime = os.clock()
    local isMobile = isMobileDevice(Config)

    -- Uruchomienie wskaźnika procesu ładowania
    local loader = createLoadingIndicator(Name, isMobile)

    -- CLEANUP
    local Connections = {}
    local CustomCleanups = {}
    local function AddConnection(conn) table.insert(Connections, conn); return conn end
    local function Cleanup()
        for _, c in pairs(Connections) do if c then pcall(function() c:Disconnect() end) end end
        Connections = {}
        for _, fn in ipairs(CustomCleanups) do pcall(fn) end
        CustomCleanups = {}
    end

    if typeof(getgenv) == "function" then
        getgenv()._VoltikMenuCleanup = Cleanup
    end
    _G._VoltikMenuCleanup = Cleanup

    -- Szybkie współbieżne pobieranie brakujących plików w pamięci
    local preloadList = {
        baseUrl .. "Window.lua",
        baseUrl .. "Icons.lua",
        baseUrl .. "Interactions.lua",
        baseUrl .. "Sidebar.lua",
        baseUrl .. "elements/Button.lua",
        baseUrl .. "elements/Toggle.lua",
        baseUrl .. "elements/ColorPicker.lua",
        baseUrl .. "elements/Slider.lua",
        baseUrl .. "elements/Input.lua",
        baseUrl .. "elements/Dropdown.lua",
        baseUrl .. "elements/Module.lua",
        baseUrl .. "tabs/Dashboard.lua",
        baseUrl .. "tabs/Settings.lua",
    }

    local uncached = {}
    for _, url in ipairs(preloadList) do
        if not SessionCache[url] then
            table.insert(uncached, url)
        end
    end

    if #uncached > 0 then
        local finishedCount = 0
        for _, url in ipairs(uncached) do
            task.spawn(function()
                local ok, content = false, nil
                local isDev = (typeof(getgenv) == "function" and getgenv()._MenuTestDevMode == true)
                if isDev and typeof(readfile) == "function" then
                    local localRel = url:gsub("^https://raw%.githubusercontent%.com/[^/]+/[^/]+/refs/heads/[^/]+/src/", "")
                    local candidates = {
                        "MenuTest/src/" .. localRel,
                        "src/" .. localRel,
                        localRel
                    }
                    for _, c in ipairs(candidates) do
                        if typeof(isfile) == "function" and isfile(c) then
                            local s, data = pcall(readfile, c)
                            if s and data and type(data) == "string" and #data > 0 then
                                ok, content = true, data
                                break
                            end
                        end
                    end
                end
                if not ok or not content then
                    ok, content = safeHttpGet(url, 2, 0.2)
                end
                if ok and content then
                    content = content:gsub("^\239\187\191", "")
                    SessionCache[url] = content
                end
                finishedCount = finishedCount + 1
                loader:Update((finishedCount / #uncached) * 0.8, string.format("Pobieranie (%d/%d)...", finishedCount, #uncached))
            end)
        end
        local waitLimit = os.clock()
        while finishedCount < #uncached and (os.clock() - waitLimit) < 2.5 do
            task.wait(0.02)
        end
    end
    loader:Update(0.9, "Inicjalizacja UI...")

    -- USUWANIE STAREGO MENU I ODŁĄCZANIE POPRZEDNICH ZDARZEŃ (TYLKO DLA MENU VOLTIK)
    local myOwnerTag = "XxvoltikxX"
    local menuId = (Config and Config.MenuId) or "Voltik_MenuTest"
    if typeof(getgenv) == "function" and getgenv()._VoltikMenuCleanup then
        pcall(getgenv()._VoltikMenuCleanup)
        getgenv()._VoltikMenuCleanup = nil
    end
    if _G._VoltikMenuCleanup then
        pcall(_G._VoltikMenuCleanup)
        _G._VoltikMenuCleanup = nil
    end

    local searchContainers = {}
    if ProtectedLocation then table.insert(searchContainers, ProtectedLocation) end
    pcall(function() table.insert(searchContainers, CoreGui) end)
    pcall(function() table.insert(searchContainers, PlayerGui) end)

    for _, container in ipairs(searchContainers) do
        if container then
            for _, child in ipairs(container:GetChildren()) do
                if child:IsA("ScreenGui") and child ~= loaderGui and not child:GetAttribute("MenuLoaderIndicator") then
                    local isVoltikDuplicate = (child:GetAttribute("MenuOwner") == myOwnerTag)
                        or (child:GetAttribute("VoltikMenuInstance") == true)
                        or (child:GetAttribute("MenuTest_Voltik") == true)
                        or (menuId and menuId ~= "MenuInstance" and child:GetAttribute(menuId) == true)
                        or (typeof(getgenv) == "function" and child == getgenv()._VoltikMenuTestGui)

                    if isVoltikDuplicate then
                        pcall(function() child:Destroy() end)
                    end
                end
            end
        end
    end

    -- FOLDERY I MOTYWY
    local mainFolder        = Name
    local themesFolder      = mainFolder .. "/themes"
    local configsFolder     = mainFolder .. "/configs"
    local gameConfigsFolder = configsFolder .. "/" .. GameId

    if typeof(isfolder) == "function" and typeof(makefolder) == "function" then
        if not isfolder(mainFolder)          then pcall(makefolder, mainFolder) end
        if not isfolder(configsFolder)       then pcall(makefolder, configsFolder) end
        if not isfolder(gameConfigsFolder)   then pcall(makefolder, gameConfigsFolder) end
        if not isfolder(mainFolder.."/emotes") then pcall(makefolder, mainFolder.."/emotes") end
        if not isfolder(themesFolder)        then pcall(makefolder, themesFolder) end
    end
    if typeof(isfile) == "function" and typeof(writefile) == "function" then
        if not isfile(mainFolder.."/emotes/favorites.json") then
            pcall(writefile, mainFolder.."/emotes/favorites.json", "{}")
        end
    end

    local defaultThemes = {
        ["dark"] = {
            Main          = {11,  11,  15},
            Secondary     = {17,  18,  25},
            Accent        = {99,  102, 241},
            Accent2       = {28,  30,  46},
            Success       = {34,  197, 94},
            Text          = {255, 255, 255},
            Text_Secondary= {148, 163, 184},
            Close         = {244, 63,  94},
        },
        ["light"] = {
            Main          = {245, 245, 248},
            Secondary     = {232, 232, 238},
            Accent        = {195, 195, 205},
            Accent2       = {215, 215, 225},
            Success       = {45,  175, 75},
            Text          = {20,  20,  25},
            Text_Secondary= {110, 110, 125},
            Close         = {220, 55,  55},
        },
        ["midnight"] = {
            Main          = {10,  13,  20},
            Secondary     = {16,  21,  32},
            Accent        = {42,  54,  78},
            Accent2       = {25,  34,  50},
            Success       = {80,  230, 160},
            Text          = {240, 246, 255},
            Text_Secondary= {130, 148, 178},
            Close         = {235, 70,  85},
        },
        ["amethyst"] = {
            Main          = {16,  12,  24},
            Secondary     = {26,  20,  38},
            Accent        = {68,  50,  98},
            Accent2       = {40,  28,  58},
            Success       = {130, 245, 160},
            Text          = {250, 244, 255},
            Text_Secondary= {172, 150, 198},
            Close         = {235, 60,  90},
        }
    }

    for themeName, themeData in pairs(defaultThemes) do
        local path = themesFolder .. "/" .. themeName .. ".json"
        if typeof(isfile) == "function" and typeof(writefile) == "function" and not isfile(path) then
            pcall(function() writefile(path, prettyEncode(themeData)) end)
        end
    end

    local themeColors = defaultThemes["dark"]

    local menuConfig     = {}
    local configFilePath = configsFolder .. "/settings.json"
    local function loadMenuConfig()
        if typeof(isfile) == "function" and typeof(readfile) == "function" and isfile(configFilePath) then
            local s, d = pcall(function() return HttpService:JSONDecode(readfile(configFilePath)) end)
            if s and type(d) == "table" then menuConfig = d end
        end
    end
    loadMenuConfig()

    local function saveMenuConfig(flag, value)
        menuConfig[flag] = value
        if typeof(writefile) == "function" then
            pcall(function() writefile(configFilePath, HttpService:JSONEncode(menuConfig)) end)
        end
    end

    -- TWORZENIE OKNA
    local UI = safeLoadUrl(baseUrl .. "Window.lua", WindowModuleFallback):Create({
        Name           = Name,
        Tittle         = Config.Tittle   or "",
        TittlePos      = Config.TittlePos or "Left",
        Theme          = themeColors,
        MenuId         = menuId,
        GameId         = GameId,
        GenerateID     = function() return MenuLib:GenerateID() end,
        MenuConfig     = menuConfig,
        SaveMenuConfig = saveMenuConfig,
        TestMobile     = Config.TestMobile or Config.Mobile or isMobile,
        IsMobile       = isMobile,
    })

    -- Upewnij się, że ScreenGui jest bezpiecznie podpięty do ProtectedLocation
    if not UI.ScreenGui.Parent or UI.ScreenGui.Parent ~= ProtectedLocation then
        pcall(function() UI.ScreenGui.Parent = ProtectedLocation end)
    end
    UI.ScreenGui.Destroying:Connect(Cleanup)

    -- LOGIKA TOGGLE MENU I KEYBINDU
    local function resolveKeyCode(bind)
        if typeof(bind) == "EnumItem" then
            return bind, bind.Name
        elseif type(bind) == "string" and #bind > 0 then
            local s, res = pcall(function() return Enum.KeyCode[bind] end)
            if s and res then return res, bind end
        end
        return Enum.KeyCode.K, "K"
    end

    local initialBind = (menuConfig and menuConfig["MenuKeybind"]) or Config.ToggleUIKeybind or "K"
    local currentKeyCode, currentKeyName = resolveKeyCode(initialBind)

    UI.CurrentMenuKey     = currentKeyCode
    UI.CurrentMenuKeyName = currentKeyName

    function UI:SetMenuKeybind(newKey)
        local code, name = resolveKeyCode(newKey)
        currentKeyCode = code
        currentKeyName = name
        UI.CurrentMenuKey     = code
        UI.CurrentMenuKeyName = name
        if saveMenuConfig then
            saveMenuConfig("MenuKeybind", name)
        elseif menuConfig then
            menuConfig["MenuKeybind"] = name
        end
        if UI.OnMenuKeybindChanged then
            pcall(UI.OnMenuKeybindChanged, code)
        end
    end

    -- Podpięcie zunifikowanej funkcji UI:ToggleMenu do klawisza klawiatury
    AddConnection(UserInputService.InputBegan:Connect(function(input, gpe)
        if not gpe and input.KeyCode == currentKeyCode then
            if UI.ToggleMenu then
                UI:ToggleMenu()
            end
        end
    end))

    if UI.MinBtn then
        UI.MinBtn.MouseButton1Click:Connect(function()
            if UI.ToggleMenu then UI:ToggleMenu() end
        end)
    end
    if UI.CloseBtn then
        UI.CloseBtn.MouseButton1Click:Connect(function()
            if UI.ShowExitModal then UI.ShowExitModal() else UI.ScreenGui:Destroy() end
        end)
    end

    -- // ============================================================
    -- // ŁADOWANIE ELEMENTÓW (bezpieczne, z pamięci podręcznej)
    -- // ============================================================
    local ButtonElement       = safeLoadUrl(baseUrl .. "elements/Button.lua",      dummyElementLoader)
    local ToggleElement       = safeLoadUrl(baseUrl .. "elements/Toggle.lua",      dummyElementLoader)
    local ColorPickerElement  = safeLoadUrl(baseUrl .. "elements/ColorPicker.lua", dummyElementLoader)
    local SliderElement       = safeLoadUrl(baseUrl .. "elements/Slider.lua",      dummyElementLoader)
    local InputElement        = safeLoadUrl(baseUrl .. "elements/Input.lua",       dummyElementLoader)
    local DropdownElement     = safeLoadUrl(baseUrl .. "elements/Dropdown.lua",    dummyElementLoader)
    local ModuleElement       = safeLoadUrl(baseUrl .. "elements/Module.lua",      dummyElementLoader)
    local SectionElement      = safeLoadUrl(baseUrl .. "elements/Section.lua",     dummyElementLoader)

    local elementsTable = {
        Button      = ButtonElement,
        Toggle      = ToggleElement,
        ColorPicker = ColorPickerElement,
        Slider      = SliderElement,
        Input       = InputElement,
        Dropdown    = DropdownElement,
        Module      = ModuleElement,
        Section     = SectionElement,
        Category    = SectionElement,
        Icons       = UI.Icons,
    }

    -- // ============================================================
    -- // PUBLICZNE API
    -- // ============================================================
    UI.Flags = {}
    function UI:ApplyConfig(cfg)
        if type(cfg) ~= "table" then return end
        for flag, val in pairs(cfg) do
            UI.MenuConfig[flag] = val
            if UI.SaveMenuConfig then
                pcall(function() UI.SaveMenuConfig(flag, val) end)
            end
            if UI.Flags and UI.Flags[flag] and UI.Flags[flag].Set then
                pcall(function() UI.Flags[flag]:Set(val) end)
            end
        end
    end

    local WindowAPI = {}
    WindowAPI.Flags = UI.Flags
    function WindowAPI:ApplyConfig(cfg) UI:ApplyConfig(cfg) end
    function WindowAPI:OnCleanup(callback)
        if type(callback) == "function" then
            table.insert(CustomCleanups, callback)
        end
        return WindowAPI
    end
    function WindowAPI:SetAnimatedTheme(mode, intensity, speed)
        if UI and UI.SetAnimatedTheme then
            UI:SetAnimatedTheme(mode, intensity, speed)
        end
        return WindowAPI
    end
    function WindowAPI:SetGifBackground(assetId, transparency)
        if UI and UI.SetGifBackground then
            UI:SetGifBackground(assetId, transparency)
        end
        return WindowAPI
    end
    UI.WindowAPI    = WindowAPI

    UI._userTabCounter   = 2
    UI._systemTabsLoaded = false
    UI._isReady          = false
    UI._readyCallbacks   = {}

    function WindowAPI:CreateTab(name, icon, order)
        local tabOrder = order or UI._userTabCounter
        if not order then UI._userTabCounter = UI._userTabCounter + 1 end

        local TabElements = UI:CreateTab(name, icon or "layers", tabOrder)

        -- Usuwamy stary UIGridLayout jeśli istnieje w Page
        local oldGrid = TabElements.Page:FindFirstChildOfClass("UIGridLayout")
        if oldGrid then oldGrid:Destroy() end

        TabElements.Page.AutomaticCanvasSize = Enum.AutomaticSize.Y

        -- Tworzymy responsywny kontener kolumn (1 kolumna dla urządzeń mobilnych, 2 kolumny dla PC)
        local isMobile = (UI and UI.IsMobile) or isMobile

        local ColumnsContainer = Instance.new("Frame")
        ColumnsContainer.Name = "ColumnsContainer"
        ColumnsContainer.Size = UDim2.new(1, 0, 0, 0)
        ColumnsContainer.AutomaticSize = Enum.AutomaticSize.Y
        ColumnsContainer.BackgroundTransparency = 1
        ColumnsContainer.Parent = TabElements.Page

        local ColumnsLayout = Instance.new("UIListLayout")
        ColumnsLayout.FillDirection = Enum.FillDirection.Horizontal
        ColumnsLayout.Padding = UDim.new(0, isMobile and 0 or 12)
        ColumnsLayout.SortOrder = Enum.SortOrder.LayoutOrder
        ColumnsLayout.Parent = ColumnsContainer

        local LeftColumn = Instance.new("Frame")
        LeftColumn.Name = "LeftColumn"
        LeftColumn.Size = isMobile and UDim2.new(1, 0, 0, 0) or UDim2.new(0.5, -6, 0, 0)
        LeftColumn.AutomaticSize = Enum.AutomaticSize.Y
        LeftColumn.BackgroundTransparency = 1
        LeftColumn.LayoutOrder = 1
        LeftColumn.Parent = ColumnsContainer

        local LeftLayout = Instance.new("UIListLayout")
        LeftLayout.FillDirection = Enum.FillDirection.Vertical
        LeftLayout.Padding = UDim.new(0, 10)
        LeftLayout.SortOrder = Enum.SortOrder.LayoutOrder
        LeftLayout.Parent = LeftColumn

        local RightColumn = Instance.new("Frame")
        RightColumn.Name = "RightColumn"
        RightColumn.Size = isMobile and UDim2.new(1, 0, 0, 0) or UDim2.new(0.5, -6, 0, 0)
        RightColumn.Visible = not isMobile
        RightColumn.AutomaticSize = Enum.AutomaticSize.Y
        RightColumn.BackgroundTransparency = 1
        RightColumn.LayoutOrder = 2
        RightColumn.Parent = ColumnsContainer

        local RightLayout = Instance.new("UIListLayout")
        RightLayout.FillDirection = Enum.FillDirection.Vertical
        RightLayout.Padding = UDim.new(0, 10)
        RightLayout.SortOrder = Enum.SortOrder.LayoutOrder
        RightLayout.Parent = RightColumn

        local TabAPI = {}
        TabAPI.Page  = TabElements.Page
        TabAPI.LeftColumn = LeftColumn
        TabAPI.RightColumn = RightColumn

        local itemCounter = 0
        local function getNextParent()
            if isMobile then
                return LeftColumn
            end
            itemCounter = itemCounter + 1
            return (itemCounter % 2 == 1) and LeftColumn or RightColumn
        end

        function TabAPI:CreateButton(opts)
            return ButtonElement(opts, UI.ThemeManager, getNextParent(), UI.MenuConfig, UI.SaveMenuConfig, AddConnection)
        end
        function TabAPI:CreateToggle(opts)
            local inst = ToggleElement(opts, UI.ThemeManager, getNextParent(), UI.MenuConfig, UI.SaveMenuConfig, AddConnection)
            if opts and opts.Flag and UI.Flags then UI.Flags[opts.Flag] = inst end
            return inst
        end
        function TabAPI:CreateColorPicker(opts)
            local inst = ColorPickerElement(opts, UI.ThemeManager, getNextParent(), UI.MenuConfig, UI.SaveMenuConfig, AddConnection)
            if opts and opts.Flag and UI.Flags then UI.Flags[opts.Flag] = inst end
            return inst
        end
        function TabAPI:CreateSlider(opts)
            local inst = SliderElement(opts, UI.ThemeManager, getNextParent(), UI.MenuConfig, UI.SaveMenuConfig, AddConnection)
            if opts and opts.Flag and UI.Flags then UI.Flags[opts.Flag] = inst end
            return inst
        end
        function TabAPI:CreateInput(opts)
            local inst = InputElement(opts, UI.ThemeManager, getNextParent(), UI.MenuConfig, UI.SaveMenuConfig, AddConnection)
            if opts and opts.Flag and UI.Flags then UI.Flags[opts.Flag] = inst end
            return inst
        end
        function TabAPI:CreateDropdown(opts)
            local inst = DropdownElement(opts, UI.ThemeManager, getNextParent(), UI.MenuConfig, UI.SaveMenuConfig, AddConnection, UI.Icons)
            if opts and opts.Flag and UI.Flags then UI.Flags[opts.Flag] = inst end
            return inst
        end
        function TabAPI:CreateModule(opts)
            local inst = ModuleElement(opts, UI.ThemeManager, getNextParent(), UI.MenuConfig, UI.SaveMenuConfig, AddConnection, UI, elementsTable)
            if opts and opts.Flag and UI.Flags then UI.Flags[opts.Flag] = inst end
            return inst
        end
        function TabAPI:CreateSection(opts)
            local targetSide = opts and opts.Side
            local targetCol
            if isMobile then
                targetCol = LeftColumn
            elseif targetSide == "Left" then
                targetCol = LeftColumn
            elseif targetSide == "Right" then
                targetCol = RightColumn
            else
                itemCounter = itemCounter + 1
                targetCol = (itemCounter % 2 == 1) and LeftColumn or RightColumn
            end
            return SectionElement(opts, UI.ThemeManager, targetCol, UI.MenuConfig, UI.SaveMenuConfig, AddConnection, UI, elementsTable)
        end
        TabAPI.CreateCategory = TabAPI.CreateSection

        return TabAPI
    end

    function WindowAPI:Init(callback)
        if type(callback) ~= "function" then return WindowAPI end
        WindowAPI._initCallback = callback
        if UI._systemTabsLoaded then
            task.spawn(function()
                local ok, err = pcall(callback, WindowAPI)
                if not ok then warn("[MenuLib] Błąd w Init callback: " .. tostring(err)) end
                UI:SelectDashboard()
            end)
        end
        return WindowAPI
    end

    function WindowAPI:OnReady(callback)
        if type(callback) ~= "function" then return WindowAPI end
        if UI._isReady then
            task.spawn(function() pcall(callback, WindowAPI) end)
        else
            table.insert(UI._readyCallbacks, function()
                pcall(callback, WindowAPI)
            end)
        end
        return WindowAPI
    end

    -- // ============================================================
    -- // ŁADOWANIE ZAKŁADEK SYSTEMOWYCH W TLE (Dashboard i Settings)
    -- // ============================================================
    task.spawn(function()
        -- 1. Dashboard (LayoutOrder = 1) ----------------------
        local dashOk, dashErr = pcall(function()
            local DashboardModule = safeLoadUrl(baseUrl .. "tabs/Dashboard.lua", nil)
            if DashboardModule and type(DashboardModule.Render) == "function" then
                DashboardModule:Render(UI, 1, UI.Icons)
            else
                warn("[MenuLib] Dashboard.lua nie załadował się lub brak metody Render.")
            end
        end)
        if not dashOk then
            warn("[MenuLib] Błąd podczas renderowania Dashboard: " .. tostring(dashErr))
        end

        -- 2. Settings (LayoutOrder = 999) ----------------------
        local settOk, settErr = pcall(function()
            local SettingsModule = safeLoadUrl(baseUrl .. "tabs/Settings.lua", nil)
            if SettingsModule and type(SettingsModule.Render) == "function" then
                SettingsModule:Render(UI, 999, themeColors, mainFolder, ToggleElement, UI.Icons, GameId)
            else
                warn("[MenuLib] Settings.lua nie załadował się lub brak metody Render.")
            end
        end)
        if not settOk then
            warn("[MenuLib] Błąd podczas renderowania Settings: " .. tostring(settErr))
        end

        -- Zakładki systemowe załadowane
        UI._systemTabsLoaded = true

        -- 3. Uruchom Init callback użytkownika (jeśli zarejestrowany)
        if WindowAPI._initCallback then
            local ok, err = pcall(WindowAPI._initCallback, WindowAPI)
            if not ok then
                warn("[MenuLib] Błąd w Init callback: " .. tostring(err))
            end
        end

        -- 4. Oznacz bibliotekę jako gotową i uruchom OnReady callbacks
        UI._isReady = true
        for _, cb in ipairs(UI._readyCallbacks) do
            task.spawn(cb)
        end

        -- 5. Wybierz Dashboard jako domyślną zakładkę (w tle, bez mrugania)
        if UI.SelectDashboard then
            pcall(function() UI:SelectDashboard() end)
        end

        -- Zakończ proces ładowania i płynnie ujawnij menu dopiero po zniknięciu animacji LixHub
        pcall(function()
            loader:Done(string.format("%.2fs", os.clock() - startTime), UI.CurrentMenuKeyName, function()
                if UI.RevealMenu then
                    UI:RevealMenu()
                elseif UI.MainFrame then
                    UI.MainFrame.Visible = true
                end
            end)
        end)
    end)

    return WindowAPI
end

return MenuLib