local MenuLib = {}

-- // SERWISY
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

local ProtectedLocation = nil
pcall(function() ProtectedLocation = CoreGui end)
if not ProtectedLocation then
    ProtectedLocation = PlayerGui
end

-- Automatyczne czyszczenie poprzedniej sesji menu i skryptów
if typeof(getgenv) == "function" then
    if getgenv()._MenuTestCleanup then pcall(getgenv()._MenuTestCleanup); getgenv()._MenuTestCleanup = nil end
    if getgenv()._MenuTestGui then pcall(function() getgenv()._MenuTestGui:Destroy() end); getgenv()._MenuTestGui = nil end
end
if _G._MenuTestCleanup then pcall(_G._MenuTestCleanup); _G._MenuTestCleanup = nil end

local baseUrl = "https://raw.githubusercontent.com/xxCichyxx/MenuTest/refs/heads/main/src/"

-- // SYSTEM BEZPIECZNEGO POBIERANIA (Safe HttpGet z retry oraz ominięciem cache CDN)
local function safeHttpGet(url, maxRetries, retryDelay)
    maxRetries  = maxRetries  or 3
    retryDelay  = retryDelay  or 0.5
    local cacheBuster = (url:find("%?") and "&" or "?") .. "_nocache=" .. tostring(os.time()) .. "_" .. tostring(math.random(1000, 9999))
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
            SessionCache[url] = content
        end
    end

    -- SPRAWDZENIE CZY TREŚĆ TO FAKTYCZNIE TEKST (zapobiega próbie kompilacji nil)
    if not ok or not content or type(content) ~= "string" or #content == 0 then
        warn("[MenuLib] Nie udało się pobrać lub treść jest pusta: " .. tostring(url))
        return fallbackValue
    end
    
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

-- // ============================================================
-- // WSKAŹNIK PROCESU ŁADOWANIA (Elegancki HUD Toast)
-- // ============================================================
local function createLoadingIndicator(title)
    local screenParent
    pcall(function() screenParent = CoreGui end)
    if not screenParent then screenParent = PlayerGui end

    local loaderGui = Instance.new("ScreenGui")
    loaderGui.Name = "MenuLoaderToast_" .. math.random(1000, 9999)
    loaderGui:SetAttribute("MenuLoaderIndicator", true)
    loaderGui.ResetOnSpawn = false
    loaderGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    pcall(function() loaderGui.Parent = screenParent end)

    local Toast = Instance.new("Frame")
    Toast.Name = "Toast"
    Toast.Size = UDim2.new(0, 240, 0, 48)
    Toast.Position = UDim2.new(0.5, -120, 0, -60)
    Toast.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
    Toast.BackgroundTransparency = 0.1
    Toast.BorderSizePixel = 0
    Toast.ClipsDescendants = true
    Toast.Parent = loaderGui

    Instance.new("UICorner", Toast).CornerRadius = UDim.new(0, 8)
    local ToastStroke = Instance.new("UIStroke", Toast)
    ToastStroke.Color = Color3.fromRGB(55, 55, 62)
    ToastStroke.Thickness = 1.2
    ToastStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    local IconDot = Instance.new("Frame")
    IconDot.Size = UDim2.new(0, 10, 0, 10)
    IconDot.Position = UDim2.new(0, 14, 0, 15)
    IconDot.BackgroundColor3 = Color3.fromRGB(100, 180, 255)
    IconDot.BorderSizePixel = 0
    IconDot.Parent = Toast
    Instance.new("UICorner", IconDot).CornerRadius = UDim.new(1, 0)

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Text = title or "Menu"
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.TextSize = 12
    TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Position = UDim2.new(0, 32, 0, 8)
    TitleLabel.Size = UDim2.new(1, -40, 0, 14)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Parent = Toast

    local StatusLabel = Instance.new("TextLabel")
    StatusLabel.Text = "Ładowanie modułów..."
    StatusLabel.Font = Enum.Font.Gotham
    StatusLabel.TextSize = 10
    StatusLabel.TextColor3 = Color3.fromRGB(160, 160, 170)
    StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
    StatusLabel.Position = UDim2.new(0, 32, 0, 23)
    StatusLabel.Size = UDim2.new(1, -40, 0, 14)
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.Parent = Toast

    local BarBg = Instance.new("Frame")
    BarBg.Size = UDim2.new(1, 0, 0, 3)
    BarBg.Position = UDim2.new(0, 0, 1, -3)
    BarBg.BackgroundColor3 = Color3.fromRGB(32, 32, 38)
    BarBg.BorderSizePixel = 0
    BarBg.Parent = Toast

    local BarFill = Instance.new("Frame")
    BarFill.Size = UDim2.new(0, 0, 1, 0)
    BarFill.BackgroundColor3 = Color3.fromRGB(100, 180, 255)
    BarFill.BorderSizePixel = 0
    BarFill.Parent = BarBg

    TweenService:Create(Toast, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, -120, 0, 18)
    }):Play()

    local controller = {}
    function controller:Update(progress, statusText)
        progress = math.clamp(progress, 0, 1)
        if statusText then StatusLabel.Text = statusText end
        TweenService:Create(BarFill, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(progress, 0, 1, 0)
        }):Play()
    end

    function controller:Done(timeText, keybindName)
        keybindName = tostring(keybindName or "K")
        IconDot.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
        BarFill.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
        StatusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
        StatusLabel.Text = "Załadowano w " .. (timeText or "0.2s")
        TweenService:Create(BarFill, TweenInfo.new(0.08), { Size = UDim2.new(1, 0, 1, 0) }):Play()

        -- Center Splash Modal: "Loaded - Keybind For Open: keybind"
        local Splash = Instance.new("Frame")
        Splash.Name = "Splash"
        Splash.Size = UDim2.new(0, 360, 0, 115)
        Splash.Position = UDim2.new(0.5, 0, 0.52, 0)
        Splash.AnchorPoint = Vector2.new(0.5, 0.5)
        Splash.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
        Splash.BackgroundTransparency = 1
        Splash.ClipsDescendants = true
        Splash.ZIndex = 100
        Splash.Parent = loaderGui

        Instance.new("UICorner", Splash).CornerRadius = UDim.new(0, 10)
        local SplashStroke = Instance.new("UIStroke", Splash)
        SplashStroke.Color = Color3.fromRGB(65, 140, 255)
        SplashStroke.Thickness = 1.5
        SplashStroke.Transparency = 1
        SplashStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

        local SplashHeader = Instance.new("TextLabel")
        SplashHeader.Text = "✓ LOADED SUCCESSFULLY"
        SplashHeader.Font = Enum.Font.GothamBold
        SplashHeader.TextSize = 12
        SplashHeader.TextColor3 = Color3.fromRGB(100, 255, 140)
        SplashHeader.TextTransparency = 1
        SplashHeader.Size = UDim2.new(1, 0, 0, 22)
        SplashHeader.Position = UDim2.new(0, 0, 0, 14)
        SplashHeader.BackgroundTransparency = 1
        SplashHeader.ZIndex = 101
        SplashHeader.Parent = Splash

        local KeybindText = Instance.new("TextLabel")
        KeybindText.Text = "Keybind For Open: \"" .. keybindName .. "\""
        KeybindText.Font = Enum.Font.GothamBold
        KeybindText.TextSize = 16
        KeybindText.TextColor3 = Color3.fromRGB(255, 255, 255)
        KeybindText.TextTransparency = 1
        KeybindText.Size = UDim2.new(1, -20, 0, 26)
        KeybindText.Position = UDim2.new(0, 10, 0, 40)
        KeybindText.BackgroundTransparency = 1
        KeybindText.ZIndex = 101
        KeybindText.Parent = Splash

        local HintText = Instance.new("TextLabel")
        HintText.Text = "Press [" .. keybindName .. "] to toggle Menu | Change in Settings"
        HintText.Font = Enum.Font.Gotham
        HintText.TextSize = 11
        HintText.TextColor3 = Color3.fromRGB(160, 165, 180)
        HintText.TextTransparency = 1
        HintText.Size = UDim2.new(1, 0, 0, 20)
        HintText.Position = UDim2.new(0, 0, 0, 74)
        HintText.BackgroundTransparency = 1
        HintText.ZIndex = 101
        HintText.Parent = Splash

        -- Animacja wejścia
        TweenService:Create(Splash, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Position = UDim2.new(0.5, 0, 0.5, 0),
            BackgroundTransparency = 0.05
        }):Play()
        TweenService:Create(SplashStroke, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Transparency = 0
        }):Play()
        TweenService:Create(SplashHeader, TweenInfo.new(0.35), { TextTransparency = 0 }):Play()
        TweenService:Create(KeybindText, TweenInfo.new(0.35), { TextTransparency = 0 }):Play()
        TweenService:Create(HintText, TweenInfo.new(0.35), { TextTransparency = 0 }):Play()

        -- Po 1.8 sekundy płynne zniknięcie i usunięcie GUI
        task.delay(1.8, function()
            local tw1 = TweenService:Create(Splash, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
                Position = UDim2.new(0.5, 0, 0.47, 0),
                BackgroundTransparency = 1
            })
            local tw2 = TweenService:Create(SplashStroke, TweenInfo.new(0.35), { Transparency = 1 })
            local twH = TweenService:Create(SplashHeader, TweenInfo.new(0.3), { TextTransparency = 1 })
            local twK = TweenService:Create(KeybindText, TweenInfo.new(0.3), { TextTransparency = 1 })
            local twHint = TweenService:Create(HintText, TweenInfo.new(0.3), { TextTransparency = 1 })
            local twToast = TweenService:Create(Toast, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
                Position = UDim2.new(0.5, -120, 0, -60),
                BackgroundTransparency = 1
            })
            tw1:Play(); tw2:Play(); twH:Play(); twK:Play(); twHint:Play(); twToast:Play()
            tw1.Completed:Connect(function()
                loaderGui:Destroy()
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

    -- Uruchomienie wskaźnika procesu ładowania
    local loader = createLoadingIndicator(Name)

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
        getgenv()._MenuTestCleanup = Cleanup
    end
    _G._MenuTestCleanup = Cleanup

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

    -- USUWANIE STAREGO MENU I ODŁĄCZANIE POPRZEDNICH ZDARZEŃ
    local menuId = "MenuInstance"
    if typeof(getgenv) == "function" and getgenv()._MenuTestCleanup then
        pcall(getgenv()._MenuTestCleanup)
    end
    if _G._MenuTestCleanup then
        pcall(_G._MenuTestCleanup)
    end

    local searchContainers = {}
    if ProtectedLocation then table.insert(searchContainers, ProtectedLocation) end
    pcall(function() table.insert(searchContainers, CoreGui) end)
    pcall(function() table.insert(searchContainers, PlayerGui) end)

    for _, container in ipairs(searchContainers) do
        if container then
            for _, child in ipairs(container:GetChildren()) do
                if child:IsA("ScreenGui") and child ~= loaderGui and not child:GetAttribute("MenuLoaderIndicator") then
                    if child:GetAttribute(menuId)
                        or child:GetAttribute("MenuInstance")
                        or child:GetAttribute("MenuId")
                        or child.Name == "MenuScreen"
                        or child:FindFirstChild("MainFrame")
                        or child:FindFirstChild("Shadow") then
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
            Main          = {15,  15,  15},
            Secondary     = {25,  25,  25},
            Accent        = {60,  60,  60},
            Accent2       = {40,  40,  40},
            Success       = {100, 255, 100},
            Text          = {255, 255, 255},
            Text_Secondary= {160, 160, 160},
            Close         = {200, 50,  50},
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
    })

    -- Upewnij się, że ScreenGui jest bezpiecznie podpięty do ProtectedLocation
    if not UI.ScreenGui.Parent or UI.ScreenGui.Parent ~= ProtectedLocation then
        pcall(function() UI.ScreenGui.Parent = ProtectedLocation end)
    end
    UI.ScreenGui.Destroying:Connect(Cleanup)

    -- LOGIKA TOGGLE MENU I KEYBINDU
    local isVisible  = true
    local isTweening = false
    local MainFrame  = UI.MainFrame
    local CenterPos  = UDim2.new(0.5, 0, 0.5, 0)
    local HiddenPos  = UDim2.new(0, -750, 1, 20)

    -- Upewnij się, że menu jest natychmiast wyśrodkowane i widoczne
    MainFrame.Position = CenterPos
    MainFrame.Visible  = true

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

    local function toggleMenu()
        if isTweening then return end
        isTweening = true
        local target = isVisible and HiddenPos or CenterPos
        if not isVisible then MainFrame.Visible = true end
        local tw = TweenService:Create(MainFrame,
            TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut),
            {Position = target})
        tw:Play()
        tw.Completed:Connect(function()
            isVisible = not isVisible
            if not isVisible then MainFrame.Visible = false end
            isTweening = false
        end)
    end

    AddConnection(UserInputService.InputBegan:Connect(function(input, gpe)
        if not gpe and input.KeyCode == currentKeyCode then
            toggleMenu()
        end
    end))

    if UI.MinBtn   then UI.MinBtn.MouseButton1Click:Connect(toggleMenu) end
    if UI.CloseBtn then
        UI.CloseBtn.MouseButton1Click:Connect(function()
            if UI.ShowExitModal then UI.ShowExitModal() else UI.ScreenGui:Destroy() end
        end)
    end
    if UI.MobileToggle then UI.MobileToggle.MouseButton1Click:Connect(toggleMenu) end

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

    local elementsTable = {
        Button      = ButtonElement,
        Toggle      = ToggleElement,
        ColorPicker = ColorPickerElement,
        Slider      = SliderElement,
        Input       = InputElement,
        Dropdown    = DropdownElement,
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

        -- Tworzymy 2-kolumnowy responsywny kontener obok siebie
        local ColumnsContainer = Instance.new("Frame")
        ColumnsContainer.Name = "ColumnsContainer"
        ColumnsContainer.Size = UDim2.new(1, 0, 0, 0)
        ColumnsContainer.AutomaticSize = Enum.AutomaticSize.Y
        ColumnsContainer.BackgroundTransparency = 1
        ColumnsContainer.Parent = TabElements.Page

        local ColumnsLayout = Instance.new("UIListLayout")
        ColumnsLayout.FillDirection = Enum.FillDirection.Horizontal
        ColumnsLayout.Padding = UDim.new(0, 12)
        ColumnsLayout.SortOrder = Enum.SortOrder.LayoutOrder
        ColumnsLayout.Parent = ColumnsContainer

        local LeftColumn = Instance.new("Frame")
        LeftColumn.Name = "LeftColumn"
        LeftColumn.Size = UDim2.new(0.5, -6, 0, 0)
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
        RightColumn.Size = UDim2.new(0.5, -6, 0, 0)
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

        -- Upewnij się, że menu jest od razu otwarte i widoczne na środku ekranu
        MainFrame.Position = CenterPos
        MainFrame.Visible  = true
        isVisible          = true

        loader:Done(string.format("%.2fs", os.clock() - startTime), UI.CurrentMenuKeyName)

        -- 5. Wybierz Dashboard jako domyślną zakładkę.
        --    task.wait() daje Robloxowi czas na obliczenie AbsolutePosition.
        task.wait()
        UI:SelectDashboard()
    end)

    return WindowAPI
end

return MenuLib