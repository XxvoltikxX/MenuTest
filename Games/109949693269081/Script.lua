-- // ==========================================================================
-- // [UPD 3.1] TYCOON, BUT ONE DROPPER - ADVANCED AUTOMATION & VISUAL SUITE
-- // Dedicated script for MenuTest UI Library
-- // Categories: Player, AutoFarm, Render
-- // ==========================================================================

-- 1. Pobranie głównej biblioteki UI (MenuTest - obsługa pamięci podręcznej, offline oraz GitHub HttpGet)
local MENU = (typeof(getgenv) == "function" and getgenv()._MenuTestLibrary) or _G._MenuTestLibrary
if not MENU and typeof(readfile) == "function" then
    local ok, content = pcall(readfile, "MenuTest/Main.lua")
    if ok and content and #content > 0 then
        local chunk = loadstring(content)
        if chunk then MENU = chunk() end
    end
end
if not MENU then
    MENU = loadstring(game:HttpGet("https://raw.githubusercontent.com/xxCichyxx/MenuTest/refs/heads/main/Main.lua"))()
end
if MENU then
    if typeof(getgenv) == "function" then getgenv()._MenuTestLibrary = MENU end
    _G._MenuTestLibrary = MENU
end

-- 2. Stworzenie okna menu
local Window = MENU:CreateWindow({
    Name = "Menu Xeno UwU",
    Tittle = "[UPD 3.1] Tycoon, but one dropper",
    TittlePos = "Center",
    ToggleUIKeybind = "Insert",
    TestMobile = false,
    GameId = "109949693269081"
})

-- 3. Stworzenie wymaganych zakładek
local TabPlayer = Window:CreateTab("Player", "user")
local TabAutoFarm = Window:CreateTab("AutoFarm", "zap")
local TabRender = Window:CreateTab("Render", "eye")

-- // ==========================================================================
-- // USŁUGI ROBLOX
-- // ==========================================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Pobranie Remote'ów gry
local Remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
local ActionRemote = Remotes and Remotes:WaitForChild("Action", 10)
local NetRemote = Remotes and Remotes:WaitForChild("Net", 10)
local TrackRemote = Remotes and Remotes:WaitForChild("Track", 10)

-- Bezpieczne wywołanie RemoteFunction Action
local function SafeCallAction(actionName, ...)
    if not ActionRemote then return { ok = false } end
    local ok, res = pcall(function(...)
        return ActionRemote:InvokeServer(actionName, ...)
    end, ...)
    return ok and res or { ok = false }
end

-- // ==========================================================================
-- // FUNKCJE FORMATOWANIA LICZB I WALUTY (ZGODNE Z UTIL GRY)
-- // ==========================================================================
local suffixTable = {
    "", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc", "Ud", "Dd", "Td",
    "Qad", "Qid", "Sxd", "Spd", "Ocd", "Nod", "Vg", "Uvg", "Dvg", "Tvg", "Qavg", "Qivg",
    "Sxvg", "Spvg", "Ocvg", "Novg", "Tg", "Utg", "Dtg", "Ttg", "Qatg", "Qitg", "Sxtg",
    "Sptg", "Octg", "Notg", "Qag", "Uqag", "Dqag", "Tqag", "Qaqag", "Qiqag", "Sxqag",
    "Spqag", "Ocqag", "Noqag", "Qig", "Uqig", "Dqig", "Tqig", "Qaqig", "Qiqig", "Sxqig",
    "Spqig", "Ocqig", "Noqig", "Sxg", "Usxg", "Dsxg", "Tsxg", "Qasxg", "Qisxg", "Sxsxg",
    "Spsxg", "Ocsxg", "Nosxg", "Spg", "Uspg", "Dspg", "Tspg", "Qaspg", "Qispg", "Sxspg",
    "Spspg", "Ocspg", "Nospg", "Ocg", "Uocg", "Docg", "Tocg", "Qaocg", "Qiocg", "Sxocg",
    "Spocg", "Ococg", "Noocg", "Nog", "Unog", "Dnog", "Tnog", "Qanog", "Qinog", "Sxnog",
    "Spnog", "Ocnog", "Nonog", "Ce"
}

local function FormatNumber(val)
    local num = tonumber(val) or 0
    if num ~= num then return "0" end
    local absVal = math.abs(num)
    if absVal < 1000 then
        if absVal >= 100 or absVal == math.floor(absVal) then
            return tostring(math.floor(absVal))
        else
            return string.format("%.1f", math.floor(absVal * 10) / 10):gsub("%.0$", "")
        end
    end
    local exp = math.log10(absVal) / 3
    local floorExp = math.clamp(math.floor(exp), 1, #suffixTable - 1)
    local mantissa = absVal / (10 ^ (floorExp * 3))
    local str
    if mantissa >= 100 then
        str = tostring(math.floor(mantissa))
    elseif mantissa >= 10 then
        str = string.format("%.1f", math.floor(mantissa * 10) / 10):gsub("%.0$", "")
    else
        str = string.format("%.2f", math.floor(mantissa * 100) / 100):gsub("%.00$", ""):gsub("(%..-)0+$", "%1")
    end
    return (num < 0 and "-" or "") .. str .. (suffixTable[floorExp + 1] or "")
end

-- // ==========================================================================
-- // ZARZĄDZANIE DZIAŁKĄ (PLOT DETECTION)
-- // ==========================================================================
local function GetPlayerPlot()
    local plotId = LocalPlayer:GetAttribute("PlotId")
    local tycoons = Workspace:FindFirstChild("Tycoons")
    if not tycoons then return nil, nil end

    if plotId then
        local directPlot = tycoons:FindFirstChild("Plot" .. tostring(plotId))
        if directPlot then return directPlot, plotId end
        for _, p in ipairs(tycoons:GetChildren()) do
            if p:GetAttribute("PlotId") == plotId then
                return p, plotId
            end
        end
    end

    -- Alternatywne wykrywanie po właścicielu
    for _, p in ipairs(tycoons:GetChildren()) do
        if p:GetAttribute("Owner") == LocalPlayer.Name or p:GetAttribute("Player") == LocalPlayer.Name then
            return p, p:GetAttribute("PlotId") or p.Name:match("%d+")
        end
    end
    return nil, nil
end

local function GetPlotPads(plot)
    if not plot then return {} end
    local padsFolder = plot:FindFirstChild("Pads") or plot:FindFirstChild("Buttons")
    if not padsFolder then return {} end
    return padsFolder:GetChildren()
end

local function ParsePad(pad)
    if not pad or not pad.Parent then return nil end
    local price = pad:GetAttribute("Price") or 0
    local name = pad:GetAttribute("Item") or pad:GetAttribute("Title") or pad.Name

    local touchPart = (pad:IsA("BasePart") and pad)
        or pad:FindFirstChild("Pad")
        or pad:FindFirstChild("Button")
        or pad:FindFirstChild("Head")
        or (pad:IsA("Model") and pad.PrimaryPart)
        or pad:FindFirstChildWhichIsA("BasePart")

    if not touchPart then return nil end

    -- Ignoruj przycisk grupy o kolorze 255, 196, 56 oraz inne przyciski grupowe
    local col = touchPart.Color
    local r255 = math.floor(col.R * 255 + 0.5)
    local g255 = math.floor(col.G * 255 + 0.5)
    local b255 = math.floor(col.B * 255 + 0.5)
    if math.abs(r255 - 255) <= 6 and math.abs(g255 - 196) <= 6 and math.abs(b255 - 56) <= 6 then
        return nil
    end

    local lowerName = tostring(name):lower()
    local padName = tostring(pad.Name):lower()
    if lowerName:find("group") or padName:find("group") or lowerName:find("nagroda") or lowerName:find("reward") then
        return nil
    end

    if pad:GetAttribute("Group") or pad:GetAttribute("IsGroup") or pad:FindFirstChild("Group") then
        return nil
    end

    local income = LocalPlayer:GetAttribute("Income") or 0
    -- Kolory z gry: Zielony (76, 190, 92) do kupna, Czerwony (205, 72, 68) do uzbierania
    local isGreen = (col.G > 0.55 and col.R < 0.45 and col.B < 0.45)
    local isAffordable = (income >= price and (price > 0 or isGreen))
    local isBuyable = isAffordable or isGreen

    return {
        Instance = pad,
        TouchPart = touchPart,
        Price = price,
        Name = name,
        IsAffordable = isAffordable,
        IsBuyable = isBuyable
    }
end

-- // ==========================================================================
-- // SEKCJA 1: ZMIENNE STANU PLAYER
-- // ==========================================================================
local flyEnabled = false
local flySpeed = 75
local flyNoclip = true
local flyHover = true
local flyConn = nil
local flyBodyVelocity = nil
local flyBodyGyro = nil

local speedEnabled = false
local walkSpeedValue = 60
local speedAntiReset = true
local originalWalkSpeed = 30
local speedHeartbeatConn = nil

local infJumpEnabled = false
local jumpPowerValue = 50
local infJumpConn = nil

-- // ==========================================================================
-- // SEKCJA 2: ZMIENNE STANU AUTOFARM
-- // ==========================================================================
local autoBuyEnabled = false
local autoBuySpeedSetting = 50       -- Slider 1 - 100 (100 = 0.05s, 50 = 0.2s, 1 = 1s)
local autoBuyTouchHeight = 2.5
local autoBuyPriorityCheapest = true
local autoBuyAntiStuck = true

local autoRebirthEnabled = false
local autoRebirthInterval = 2

local autoSpinEnabled = false
local autoSpinInterval = 5

local autoPrizeEnabled = false
local autoPrizeDaily = true
local autoPrizeObby = true
local autoPrizeCrates = true

local autoQuestsEnabled = false
local autoQuestsInterval = 10

-- Anti-stuck registry
local padFailedAttempts = {}         -- [Pad] = count
local padBlacklist = {}              -- [Pad] = unblacklist_time
local lastBoughtTimestamp = tick()

-- // ==========================================================================
-- // SEKCJA 3: ZMIENNE STANU RENDER
-- // ==========================================================================
-- Lokalne efekty postaci
local orbitingStarsEnabled = false
local starsCount = 5
local starsSpeed = 3
local starsRadius = 6
local starsColor = Color3.fromRGB(255, 225, 80)
local starsFolder = nil

local orbitingRingsEnabled = false
local ringsSpeed = 4
local ringsRadius = 6
local ringsColor = Color3.fromRGB(180, 80, 255)
local ringsFolder = nil

local auraEnabled = false
local auraSize = 7
local auraColor = Color3.fromRGB(0, 210, 255)
local auraSphere = nil

local trailEnabled = false
local trailLifetime = 2.5
local trailColor = Color3.fromRGB(0, 255, 170)
local trailInstance = nil
local trailAtt0 = nil
local trailAtt1 = nil

-- ESP Graczy 3D & Tracers
local esp3DEnabled = false
local esp3DWireframe = true
local esp3DHighlights = true
local esp3DNames = true
local esp3DDistance = true
local esp3DColor = Color3.fromRGB(0, 255, 170)

local tracersEnabled = false
local tracerOriginMode = "Dół Ekranu (Bottom)"
local tracerColor = Color3.fromRGB(0, 220, 255)

local espTrackedPlayers = {}         -- [Player] = { Lines = {}, Highlight = Instance, Billboard = Instance }

-- Obby ESP
local obbyEspEnabled = false
local obbyEspHighlight = true
local obbyEspTimers = true
local obbyEspColor = Color3.fromRGB(255, 160, 40)
local obbyVisualObjects = {}

-- Plot Render
local plotRenderEnabled = false
local plotHighlightBuyable = true
local plotHighlightLocked = true
local plotShowLabels = true
local plotColorBuyable = Color3.fromRGB(76, 255, 120)
local plotColorLocked = Color3.fromRGB(235, 75, 75)
local plotVisualAdornments = {}      -- [Pad] = { Highlight = Instance, Billboard = Instance, OriginalColor = Color3 }

-- // ==========================================================================
-- // LOGIKA: PLAYER (FLY, SPEED, JUMP, TP)
-- // ==========================================================================
local function UpdateFlyMovement()
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end

    if not flyEnabled then
        if flyBodyVelocity then flyBodyVelocity:Destroy(); flyBodyVelocity = nil end
        if flyBodyGyro then flyBodyGyro:Destroy(); flyBodyGyro = nil end
        hum.PlatformStand = false
        return
    end

    if not flyBodyVelocity or flyBodyVelocity.Parent ~= hrp then
        flyBodyVelocity = Instance.new("BodyVelocity")
        flyBodyVelocity.Velocity = Vector3.zero
        flyBodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        flyBodyVelocity.Parent = hrp
    end

    if not flyBodyGyro or flyBodyGyro.Parent ~= hrp then
        flyBodyGyro = Instance.new("BodyGyro")
        flyBodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        flyBodyGyro.CFrame = Camera.CFrame
        flyBodyGyro.Parent = hrp
    end

    hum.PlatformStand = true

    -- Noclip w locie
    if flyNoclip then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end

    -- Obliczanie kierunku ruchu
    local moveDir = Vector3.zero
    local camCF = Camera.CFrame

    if UserInputService:IsKeyDown(Enum.KeyCode.W) then
        moveDir = moveDir + camCF.LookVector
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then
        moveDir = moveDir - camCF.LookVector
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then
        moveDir = moveDir - camCF.RightVector
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then
        moveDir = moveDir + camCF.RightVector
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
        moveDir = moveDir + Vector3.new(0, 1, 0)
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
        moveDir = moveDir - Vector3.new(0, 1, 0)
    end

    if moveDir.Magnitude > 0 then
        flyBodyVelocity.Velocity = moveDir.Unit * flySpeed
    else
        flyBodyVelocity.Velocity = Vector3.zero
    end
    flyBodyGyro.CFrame = camCF
end

local function SetFlyState(state)
    flyEnabled = state
    if state then
        if not flyConn then
            flyConn = RunService.RenderStepped:Connect(UpdateFlyMovement)
        end
    else
        if flyConn then flyConn:Disconnect(); flyConn = nil end
        UpdateFlyMovement()
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand = false end
    end
end

local function ApplyWalkSpeed()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        if speedEnabled then
            hum.WalkSpeed = walkSpeedValue
        else
            hum.WalkSpeed = originalWalkSpeed
        end
    end
end

local function SetSpeedState(state)
    speedEnabled = state
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum and not state then
        hum.WalkSpeed = originalWalkSpeed
    end

    if state then
        ApplyWalkSpeed()
        if not speedHeartbeatConn then
            speedHeartbeatConn = RunService.Heartbeat:Connect(function()
                if speedEnabled and speedAntiReset then
                    local h = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                    if h and h.WalkSpeed ~= walkSpeedValue then
                        h.WalkSpeed = walkSpeedValue
                    end
                end
            end)
        end
    else
        if speedHeartbeatConn then
            speedHeartbeatConn:Disconnect()
            speedHeartbeatConn = nil
        end
        ApplyWalkSpeed()
    end
end

-- Infinite Jump
UserInputService.JumpRequest:Connect(function()
    if infJumpEnabled then
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

local function ApplyJumpPower()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        if infJumpEnabled then
            hum.JumpPower = jumpPowerValue
        else
            hum.JumpPower = 50
        end
    end
end

-- Teleportacja do własnego Plotu
local function TeleportToMyPlot()
    local plot = GetPlayerPlot()
    if not plot then
        warn("[Teleport] Nie znaleziono przypisanej działki gracza!")
        return
    end

    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    -- Znajdź punkt odniesienia (Spawn, Dropper lub środek działki)
    local targetPos = nil
    local dropPart = plot:FindFirstChild("Dropper") or plot:FindFirstChild("Drop") or plot:FindFirstChild("PadStrip")
    if dropPart and dropPart:IsA("BasePart") then
        targetPos = dropPart.Position + Vector3.new(0, 4, 0)
    else
        local cf, size = plot:GetBoundingBox()
        targetPos = cf.Position + Vector3.new(0, 5, 0)
    end

    hrp.CFrame = CFrame.new(targetPos)
end

-- // ==========================================================================
-- // LOGIKA: AUTOFARM (AUTO BUY, AUTO REBIRTH, AUTO SPIN, AUTO PRIZE, AUTO QUESTS)
-- // ==========================================================================

-- 1. Auto Buy
local autoBuyThread = nil

local function CalculateBuyDelay()
    -- Mapowanie suwaka 1-100 na opóźnienie w sekundach (100 -> 0.05s, 50 -> 0.2s, 1 -> 1.0s)
    local clamped = math.clamp(autoBuySpeedSetting, 1, 100)
    return 1.0 - ((clamped - 1) / 99) * 0.95
end

local function TriggerPadTouch(hrp, touchPart)
    if not hrp or not touchPart then return end

    -- Fizyczne dotknięcie przez CFrame
    hrp.CFrame = touchPart.CFrame + Vector3.new(0, autoBuyTouchHeight, 0)

    -- Wywołanie firetouchinterest jeśli executor to wspiera (natychmiastowa symulacja)
    if typeof(firetouchinterest) == "function" then
        pcall(function()
            firetouchinterest(hrp, touchPart, 0)
            task.wait(0.01)
            firetouchinterest(hrp, touchPart, 1)
        end)
    end
end

local function ProcessAutoBuyStep()
    local plot = GetPlayerPlot()
    if not plot then return end

    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local pads = GetPlotPads(plot)
    if #pads == 0 then return end

    -- Parsowanie i filtrowanie przycisków
    local now = tick()
    local candidates = {}

    for _, p in ipairs(pads) do
        -- Sprawdzenie czarnej listy anti-stuck
        if not padBlacklist[p] or now >= padBlacklist[p] then
            local info = ParsePad(p)
            if info and info.IsBuyable then
                table.insert(candidates, info)
            end
        end
    end

    if #candidates == 0 then return end

    -- Sortowanie: najtańsze najpierw (optymalna rozbudowa)
    if autoBuyPriorityCheapest then
        table.sort(candidates, function(a, b)
            return a.Price < b.Price
        end)
    end

    local target = candidates[1]
    local targetInstance = target.Instance

    -- Zwiększ licznik prób dla tego przycisku
    padFailedAttempts[targetInstance] = (padFailedAttempts[targetInstance] or 0) + 1

    -- Sprawdzenie Anti-Stuck: jeśli przycisk nie reaguje po 3 próbach
    if autoBuyAntiStuck and padFailedAttempts[targetInstance] >= 3 then
        -- Anti-stuck: podskocz / teleportuj wyżej lub dodaj lekki offset
        hrp.CFrame = hrp.CFrame + Vector3.new(0, 5.5, 0)
        task.wait(0.05)

        -- Jeśli po 5 próbach nadal wisi, dodaj na czarną listę na 4 sekundy
        if padFailedAttempts[targetInstance] >= 5 then
            padBlacklist[targetInstance] = now + 4.0
            padFailedAttempts[targetInstance] = 0

            -- Przeskocz natychmiast na inny przycisk jeśli dostępny
            if #candidates > 1 then
                target = candidates[2]
            end
        end
    end

    TriggerPadTouch(hrp, target.TouchPart)
end

-- Detekcja pomyślnego zakupu z Net.OnClientEvent (reset prób)
if NetRemote then
    NetRemote.OnClientEvent:Connect(function(event, data)
        if event == "Bought" then
            lastBoughtTimestamp = tick()
            -- Wyczyszczenie liczników błędów po udanym zakupie
            table.clear(padFailedAttempts)
        end
    end)
end

local function StartAutoBuyLoop()
    if autoBuyThread then return end
    autoBuyThread = task.spawn(function()
        while autoBuyEnabled do
            pcall(ProcessAutoBuyStep)
            local delayTime = CalculateBuyDelay()
            task.wait(delayTime)
        end
        autoBuyThread = nil
    end)
end

-- 2. Auto Rebirth
local autoRebirthThread = nil
local function StartAutoRebirthLoop()
    if autoRebirthThread then return end
    autoRebirthThread = task.spawn(function()
        while autoRebirthEnabled do
            pcall(function()
                SafeCallAction("Rebirth")
            end)
            task.wait(autoRebirthInterval)
        end
        autoRebirthThread = nil
    end)
end

-- 3. Auto Spin
local autoSpinThread = nil
local function StartAutoSpinLoop()
    if autoSpinThread then return end
    autoSpinThread = task.spawn(function()
        while autoSpinEnabled do
            pcall(function()
                SafeCallAction("Spin")
            end)
            task.wait(autoSpinInterval)
        end
        autoSpinThread = nil
    end)
end

-- 4. Auto Prize (Daily, Obby/Power, Crates)
local autoPrizeThread = nil
local function CollectMysteryCrates()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    -- Sprawdź skrzynki i dropy w Workspace
    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj.Name:find("Crate") or obj.Name:find("Drop") or obj:GetAttribute("Mystery") then
            local p = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
            if p and (p.Position - hrp.Position).Magnitude < 300 then
                pcall(function()
                    local oldCF = hrp.CFrame
                    hrp.CFrame = p.CFrame
                    task.wait(0.1)
                    hrp.CFrame = oldCF
                end)
                break
            end
        end
    end
end

local function CheckObbyRewards()
    local world = Workspace:FindFirstChild("World")
    if not world then return end

    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local serverTime = Workspace:GetServerTimeNow()
    local obbyNext = LocalPlayer:GetAttribute("ObbyNext") or 0
    local powerNext = LocalPlayer:GetAttribute("PowerNext") or 0

    -- Obby gotowe do odbioru
    if obbyNext > 0 and serverTime >= obbyNext then
        local obby = world:FindFirstChild("Obby")
        local goal = obby and (obby:FindFirstChild("Goal") or obby:FindFirstChild("Pad") or obby:FindFirstChild("Reward"))
        local p = goal and (goal:IsA("BasePart") and goal or goal:FindFirstChildWhichIsA("BasePart"))
        if p then
            pcall(function()
                local oldCF = hrp.CFrame
                hrp.CFrame = p.CFrame + Vector3.new(0, 3, 0)
                task.wait(0.2)
                hrp.CFrame = oldCF
            end)
        end
    end

    -- PowerPlant gotowe do odbioru
    if powerNext > 0 and serverTime >= powerNext then
        local pp = world:FindFirstChild("PowerPlant")
        local goal = pp and (pp:FindFirstChild("Goal") or pp:FindFirstChild("Pad") or pp:FindFirstChild("Reward"))
        local p = goal and (goal:IsA("BasePart") and goal or goal:FindFirstChildWhichIsA("BasePart"))
        if p then
            pcall(function()
                local oldCF = hrp.CFrame
                hrp.CFrame = p.CFrame + Vector3.new(0, 3, 0)
                task.wait(0.2)
                hrp.CFrame = oldCF
            end)
        end
    end
end

local function StartAutoPrizeLoop()
    if autoPrizeThread then return end
    autoPrizeThread = task.spawn(function()
        while autoPrizeEnabled do
            -- 1. Daily i nagrody zdalne
            if autoPrizeDaily then
                pcall(function()
                    SafeCallAction("ClaimDaily")
                    SafeCallAction("Daily")
                    SafeCallAction("ClaimGroup")
                    SafeCallAction("NewsSeen")
                    SafeCallAction("StarterSeen")
                end)
            end

            -- 2. Nagrody z Obby / PowerPlant
            if autoPrizeObby then
                pcall(CheckObbyRewards)
            end

            -- 3. Mystery Crates
            if autoPrizeCrates then
                pcall(CollectMysteryCrates)
            end

            task.wait(5)
        end
        autoPrizeThread = nil
    end)
end

-- 5. Auto Quests
local autoQuestsThread = nil
local function StartAutoQuestsLoop()
    if autoQuestsThread then return end
    autoQuestsThread = task.spawn(function()
        while autoQuestsEnabled do
            pcall(function()
                SafeCallAction("Quests")
            end)
            task.wait(autoQuestsInterval)
        end
        autoQuestsThread = nil
    end)
end

-- // ==========================================================================
-- // LOGIKA: RENDER (ORBITING STARS, RINGS, AURA, TRAILS, 3D ESP, TRACERS, OBBY, PLOT)
-- // ==========================================================================

-- 1. Krążące Gwiazdy wokół lokalnej postaci
local function CleanupStars()
    if starsFolder then
        starsFolder:Destroy()
        starsFolder = nil
    end
end

local function UpdateStars(dt)
    if not orbitingStarsEnabled then
        CleanupStars()
        return
    end

    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then
        CleanupStars()
        return
    end

    if not starsFolder or starsFolder.Parent ~= Workspace then
        CleanupStars()
        starsFolder = Instance.new("Folder")
        starsFolder.Name = "LocalOrbitingStars"
        starsFolder.Parent = Workspace
    end

    local existing = starsFolder:GetChildren()
    if #existing ~= starsCount then
        CleanupStars()
        starsFolder = Instance.new("Folder")
        starsFolder.Name = "LocalOrbitingStars"
        starsFolder.Parent = Workspace

        for i = 1, starsCount do
            local star = Instance.new("Part")
            star.Name = "Star_" .. i
            star.Shape = Enum.PartType.Ball
            star.Size = Vector3.new(0.5, 0.5, 0.5)
            star.Material = Enum.Material.Neon
            star.Color = starsColor
            star.CanCollide = false
            star.Anchored = true
            star.CastShadow = false

            local light = Instance.new("PointLight", star)
            light.Color = starsColor
            light.Range = 6
            light.Brightness = 2

            star.Parent = starsFolder
        end
    end

    local t = tick() * starsSpeed
    for i, star in ipairs(starsFolder:GetChildren()) do
        local angle = t + (i * (math.pi * 2 / starsCount))
        local x = math.cos(angle) * starsRadius
        local z = math.sin(angle) * starsRadius
        local y = math.sin(angle * 2) * 1.2
        star.Position = hrp.Position + Vector3.new(x, y, z)
        star.Color = starsColor
        if star:FindFirstChildOfClass("PointLight") then
            star:FindFirstChildOfClass("PointLight").Color = starsColor
        end
    end
end

-- 2. Wirujące Pierścienie Energii wokół postaci
local function CleanupRings()
    if ringsFolder then
        ringsFolder:Destroy()
        ringsFolder = nil
    end
end

local function UpdateRings(dt)
    if not orbitingRingsEnabled then
        CleanupRings()
        return
    end

    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then
        CleanupRings()
        return
    end

    if not ringsFolder or ringsFolder.Parent ~= Workspace then
        CleanupRings()
        ringsFolder = Instance.new("Folder")
        ringsFolder.Name = "LocalOrbitingRings"
        ringsFolder.Parent = Workspace

        -- Stworzenie punktów tworzących dwa nachylone pierścienie (po 12 segmentów każdy)
        for r = 1, 2 do
            local ringModel = Instance.new("Model", ringsFolder)
            ringModel.Name = "Ring_" .. r
            for i = 1, 14 do
                local p = Instance.new("Part", ringModel)
                p.Name = "Node_" .. i
                p.Size = Vector3.new(0.35, 0.35, 0.35)
                p.Shape = Enum.PartType.Ball
                p.Material = Enum.Material.Neon
                p.Color = ringsColor
                p.CanCollide = false
                p.Anchored = true
                p.CastShadow = false
            end
        end
    end

    local t = tick() * ringsSpeed
    local r1 = ringsFolder:FindFirstChild("Ring_1")
    local r2 = ringsFolder:FindFirstChild("Ring_2")

    if r1 then
        local tilt1 = CFrame.Angles(math.rad(35), 0, math.rad(25))
        local children = r1:GetChildren()
        for i, node in ipairs(children) do
            local angle = t + (i * (math.pi * 2 / #children))
            local offset = tilt1 * Vector3.new(math.cos(angle) * ringsRadius, math.sin(angle * 2) * 0.4, math.sin(angle) * ringsRadius)
            node.Position = hrp.Position + offset
            node.Color = ringsColor
        end
    end

    if r2 then
        local tilt2 = CFrame.Angles(math.rad(-35), 0, math.rad(-25))
        local children = r2:GetChildren()
        for i, node in ipairs(children) do
            local angle = -t + (i * (math.pi * 2 / #children))
            local offset = tilt2 * Vector3.new(math.cos(angle) * ringsRadius, math.sin(angle * 2) * 0.4, math.sin(angle) * ringsRadius)
            node.Position = hrp.Position + offset
            node.Color = ringsColor
        end
    end
end

-- 3. Aura Energii wokół postaci
local function CleanupAura()
    if auraSphere then
        auraSphere:Destroy()
        auraSphere = nil
    end
end

local function UpdateAura()
    if not auraEnabled then
        CleanupAura()
        return
    end

    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then
        CleanupAura()
        return
    end

    if not auraSphere or auraSphere.Parent ~= Workspace then
        CleanupAura()
        auraSphere = Instance.new("Part")
        auraSphere.Name = "LocalCharacterAura"
        auraSphere.Shape = Enum.PartType.Ball
        auraSphere.Material = Enum.Material.ForceField
        auraSphere.Color = auraColor
        auraSphere.CanCollide = false
        auraSphere.Anchored = true
        auraSphere.CastShadow = false
        auraSphere.Parent = Workspace

        local light = Instance.new("PointLight", auraSphere)
        light.Color = auraColor
        light.Brightness = 1.5
        light.Range = 12
    end

    -- Płynny puls rozmiaru
    local pulse = math.sin(tick() * 3) * 0.4
    local currentSize = auraSize + pulse
    auraSphere.Size = Vector3.new(currentSize, currentSize, currentSize)
    auraSphere.Position = hrp.Position
    auraSphere.Color = auraColor

    local light = auraSphere:FindFirstChildOfClass("PointLight")
    if light then light.Color = auraColor end
end

-- 4. Smuga Ruchu (Trail)
local function SetTrailState(state)
    trailEnabled = state
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")

    if not state or not hrp then
        if trailInstance then trailInstance:Destroy(); trailInstance = nil end
        if trailAtt0 then trailAtt0:Destroy(); trailAtt0 = nil end
        if trailAtt1 then trailAtt1:Destroy(); trailAtt1 = nil end
        return
    end

    if not trailInstance then
        trailAtt0 = Instance.new("Attachment", hrp)
        trailAtt0.Position = Vector3.new(0, -1.5, 0.5)

        trailAtt1 = Instance.new("Attachment", hrp)
        trailAtt1.Position = Vector3.new(0, 1.5, 0.5)

        trailInstance = Instance.new("Trail")
        trailInstance.Attachment0 = trailAtt0
        trailInstance.Attachment1 = trailAtt1
        trailInstance.Lifetime = trailLifetime
        trailInstance.Color = ColorSequence.new(trailColor)
        trailInstance.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.1),
            NumberSequenceKeypoint.new(1, 1)
        })
        trailInstance.Parent = hrp
    end
end

-- 5. Player 3D ESP & Tracers
local function CleanupPlayerESP(player)
    local data = espTrackedPlayers[player]
    if data then
        if data.Highlight then data.Highlight:Destroy() end
        if data.Billboard then data.Billboard:Destroy() end
        if data.Lines then
            for _, line in ipairs(data.Lines) do
                pcall(function() line:Remove() end)
            end
        end
        if data.TracerLine then
            pcall(function() data.TracerLine:Remove() end)
        end
        espTrackedPlayers[player] = nil
    end
end

local function GetTracerOrigin()
    local vp = Camera.ViewportSize
    if tracerOriginMode:find("Bottom") then
        return Vector2.new(vp.X / 2, vp.Y - 10)
    elseif tracerOriginMode:find("Center") then
        return Vector2.new(vp.X / 2, vp.Y / 2)
    else
        local mousePos = UserInputService:GetMouseLocation()
        return Vector2.new(mousePos.X, mousePos.Y)
    end
end

local function UpdatePlayerESP()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local char = player.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")

            if char and hrp and hum and hum.Health > 0 then
                local data = espTrackedPlayers[player]
                if not data then
                    data = { Lines = {} }
                    espTrackedPlayers[player] = data
                end

                -- 1. Roblox Highlight (Chams)
                if esp3DEnabled and esp3DHighlights then
                    if not data.Highlight or data.Highlight.Parent ~= char then
                        if data.Highlight then data.Highlight:Destroy() end
                        local hl = Instance.new("Highlight")
                        hl.Name = "ESP_Highlight"
                        hl.FillColor = esp3DColor
                        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                        hl.FillTransparency = 0.55
                        hl.OutlineTransparency = 0
                        hl.Adornee = char
                        hl.Parent = char
                        data.Highlight = hl
                    else
                        data.Highlight.FillColor = esp3DColor
                        data.Highlight.Enabled = true
                    end
                elseif data.Highlight then
                    data.Highlight.Enabled = false
                end

                -- 2. 3D Billboard (Nazwa + Dystans)
                local head = char:FindFirstChild("Head")
                if esp3DEnabled and (esp3DNames or esp3DDistance) and head then
                    if not data.Billboard or data.Billboard.Parent ~= head then
                        if data.Billboard then data.Billboard:Destroy() end
                        local bb = Instance.new("BillboardGui")
                        bb.Name = "ESP_Billboard"
                        bb.Size = UDim2.new(0, 160, 0, 40)
                        bb.StudsOffset = Vector3.new(0, 2.5, 0)
                        bb.AlwaysOnTop = true
                        bb.Adornee = head

                        local lbl = Instance.new("TextLabel", bb)
                        lbl.Name = "Text"
                        lbl.Size = UDim2.new(1, 0, 1, 0)
                        lbl.BackgroundTransparency = 1
                        lbl.Font = Enum.Font.GothamBold
                        lbl.TextSize = 13
                        lbl.TextColor3 = esp3DColor
                        lbl.TextStrokeTransparency = 0.2
                        lbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)

                        bb.Parent = head
                        data.Billboard = bb
                    end

                    local dist = math.round((Camera.CFrame.Position - hrp.Position).Magnitude * 0.28)
                    local textStr = ""
                    if esp3DNames then textStr = player.DisplayName end
                    if esp3DDistance then textStr = textStr .. (esp3DNames and " " or "") .. "[" .. dist .. "m]" end
                    local lbl = data.Billboard:FindFirstChild("Text")
                    if lbl then
                        lbl.Text = textStr
                        lbl.TextColor3 = esp3DColor
                    end
                    data.Billboard.Enabled = true
                elseif data.Billboard then
                    data.Billboard.Enabled = false
                end

                -- 3. Tracers (Drawing API)
                if typeof(Drawing) == "table" and Drawing.new then
                    local hrpPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                    if tracersEnabled and onScreen then
                        if not data.TracerLine then
                            local line = Drawing.new("Line")
                            line.Thickness = 1.5
                            data.TracerLine = line
                        end
                        data.TracerLine.From = GetTracerOrigin()
                        data.TracerLine.To = Vector2.new(hrpPos.X, hrpPos.Y)
                        data.TracerLine.Color = tracerColor
                        data.TracerLine.Visible = true
                    elseif data.TracerLine then
                        data.TracerLine.Visible = false
                    end

                    -- 4. True 3D Box Wireframe (12 krawędzi)
                    if esp3DEnabled and esp3DWireframe and onScreen then
                        if #data.Lines ~= 12 then
                            for _, l in ipairs(data.Lines) do pcall(function() l:Remove() end) end
                            data.Lines = {}
                            for i = 1, 12 do
                                local l = Drawing.new("Line")
                                l.Thickness = 1.2
                                table.insert(data.Lines, l)
                            end
                        end

                        local cf, size = char:GetBoundingBox()
                        local sx, sy, sz = size.X / 2, size.Y / 2, size.Z / 2
                        local corners = {
                            cf * Vector3.new(-sx,  sy, -sz),
                            cf * Vector3.new( sx,  sy, -sz),
                            cf * Vector3.new( sx, -sy, -sz),
                            cf * Vector3.new(-sx, -sy, -sz),
                            cf * Vector3.new(-sx,  sy,  sz),
                            cf * Vector3.new( sx,  sy,  sz),
                            cf * Vector3.new( sx, -sy,  sz),
                            cf * Vector3.new(-sx, -sy,  sz),
                        }

                        local projCorners = {}
                        local allInFront = true
                        for i, corner in ipairs(corners) do
                            local p, visible = Camera:WorldToViewportPoint(corner)
                            if not visible then allInFront = false end
                            projCorners[i] = Vector2.new(p.X, p.Y)
                        end

                        if allInFront then
                            local edges = {
                                {1, 2}, {2, 6}, {6, 5}, {5, 1}, -- Górna ściana
                                {4, 3}, {3, 7}, {7, 8}, {8, 4}, -- Dolna ściana
                                {1, 4}, {2, 3}, {5, 8}, {6, 7}  -- Filary pionowe
                            }
                            for idx, edge in ipairs(edges) do
                                local line = data.Lines[idx]
                                if line then
                                    line.From = projCorners[edge[1]]
                                    line.To = projCorners[edge[2]]
                                    line.Color = esp3DColor
                                    line.Visible = true
                                end
                            end
                        else
                            for _, line in ipairs(data.Lines) do line.Visible = false end
                        end
                    else
                        for _, line in ipairs(data.Lines) do line.Visible = false end
                    end
                end
            else
                CleanupPlayerESP(player)
            end
        end
    end
end

Players.PlayerRemoving:Connect(CleanupPlayerESP)

-- 6. Obby ESP (Wykrywanie przycisków i nagród w Obby / PowerPlant)
local function CleanupObbyESP()
    for _, obj in ipairs(obbyVisualObjects) do
        if obj and obj.Parent then obj:Destroy() end
    end
    table.clear(obbyVisualObjects)
end

local function UpdateObbyESP()
    if not obbyEspEnabled then
        CleanupObbyESP()
        return
    end

    local world = Workspace:FindFirstChild("World")
    if not world then return end

    local targets = {}
    local obby = world:FindFirstChild("Obby")
    if obby then table.insert(targets, { Name = "Obby Goal", Model = obby, Attr = "ObbyNext" }) end
    local pp = world:FindFirstChild("PowerPlant")
    if pp then table.insert(targets, { Name = "PowerPlant Goal", Model = pp, Attr = "PowerNext" }) end

    local serverTime = Workspace:GetServerTimeNow()

    for _, entry in ipairs(targets) do
        local model = entry.Model
        local goal = model:FindFirstChild("Goal") or model:FindFirstChild("Pad") or model:FindFirstChild("Reward") or model:FindFirstChildWhichIsA("BasePart")
        if goal then
            local mainPart = goal:IsA("BasePart") and goal or goal:FindFirstChildWhichIsA("BasePart")
            if mainPart then
                -- Highlight
                if obbyEspHighlight and not mainPart:FindFirstChild("ObbyHighlight") then
                    local hl = Instance.new("Highlight")
                    hl.Name = "ObbyHighlight"
                    hl.Adornee = goal
                    hl.FillColor = obbyEspColor
                    hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                    hl.FillTransparency = 0.5
                    hl.Parent = mainPart
                    table.insert(obbyVisualObjects, hl)
                end

                -- Billboard z czasem
                if obbyEspTimers and not mainPart:FindFirstChild("ObbyBillboard") then
                    local bb = Instance.new("BillboardGui")
                    bb.Name = "ObbyBillboard"
                    bb.Size = UDim2.new(0, 180, 0, 45)
                    bb.StudsOffset = Vector3.new(0, 4, 0)
                    bb.AlwaysOnTop = true
                    bb.Adornee = mainPart

                    local title = Instance.new("TextLabel", bb)
                    title.Name = "Title"
                    title.Size = UDim2.new(1, 0, 0.5, 0)
                    title.BackgroundTransparency = 1
                    title.Font = Enum.Font.GothamBold
                    title.TextSize = 14
                    title.Text = "🏆 " .. entry.Name
                    title.TextColor3 = obbyEspColor
                    title.TextStrokeTransparency = 0.2

                    local status = Instance.new("TextLabel", bb)
                    status.Name = "Status"
                    status.Size = UDim2.new(1, 0, 0.5, 0)
                    status.Position = UDim2.new(0, 0, 0.5, 0)
                    status.BackgroundTransparency = 1
                    status.Font = Enum.Font.GothamMedium
                    status.TextSize = 12
                    status.TextStrokeTransparency = 0.2

                    bb.Parent = mainPart
                    table.insert(obbyVisualObjects, bb)
                end

                -- Aktualizacja tekstu statusu
                local bb = mainPart:FindFirstChild("ObbyBillboard")
                if bb then
                    local status = bb:FindFirstChild("Status")
                    if status then
                        local nextTime = LocalPlayer:GetAttribute(entry.Attr) or 0
                        local diff = nextTime - math.floor(serverTime)
                        if diff <= 0 then
                            status.Text = "✅ GOTOWE DO ODBIORU!"
                            status.TextColor3 = Color3.fromRGB(120, 255, 140)
                        else
                            status.Text = string.format("⏳ Następne za %02d:%02d", math.floor(diff / 60), diff % 60)
                            status.TextColor3 = Color3.fromRGB(255, 190, 90)
                        end
                    end
                end
            end
        end
    end
end

-- 7. Plot Render (Wizualia przycisków na własnej działce)
local function CleanupPlotRender()
    for pad, data in pairs(plotVisualAdornments) do
        if data.Highlight and data.Highlight.Parent then data.Highlight:Destroy() end
        if data.Billboard and data.Billboard.Parent then data.Billboard:Destroy() end
        if data.TouchPart and data.OriginalColor then
            pcall(function() data.TouchPart.Color = data.OriginalColor end)
        end
    end
    table.clear(plotVisualAdornments)
end

local function UpdatePlotRender()
    if not plotRenderEnabled then
        CleanupPlotRender()
        return
    end

    local plot = GetPlayerPlot()
    if not plot then return end

    local pads = GetPlotPads(plot)
    local income = LocalPlayer:GetAttribute("Income") or 0

    -- Wykryj usunięte przyciski (np. zakupione) i wyczyść
    for pad, data in pairs(plotVisualAdornments) do
        if not pad or not pad.Parent then
            if data.Highlight then data.Highlight:Destroy() end
            if data.Billboard then data.Billboard:Destroy() end
            plotVisualAdornments[pad] = nil
        end
    end

    for _, pad in ipairs(pads) do
        local info = ParsePad(pad)
        if info then
            local data = plotVisualAdornments[pad]
            if not data then
                data = {
                    TouchPart = info.TouchPart,
                    OriginalColor = info.TouchPart.Color
                }
                plotVisualAdornments[pad] = data
            end

            local isAffordable = info.IsAffordable
            local targetColor = isAffordable and plotColorBuyable or plotColorLocked

            -- Highlight na przycisk
            if (isAffordable and plotHighlightBuyable) or (not isAffordable and plotHighlightLocked) then
                if not data.Highlight or data.Highlight.Parent ~= pad then
                    if data.Highlight then data.Highlight:Destroy() end
                    local hl = Instance.new("Highlight")
                    hl.Name = "PlotPadHighlight"
                    hl.Adornee = pad
                    hl.FillTransparency = 0.4
                    hl.OutlineTransparency = 0.1
                    hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                    hl.Parent = pad
                    data.Highlight = hl
                end
                data.Highlight.FillColor = targetColor
                data.Highlight.Enabled = true
            elseif data.Highlight then
                data.Highlight.Enabled = false
            end

            -- Billboard ze statusem i ceną
            if plotShowLabels then
                if not data.Billboard or data.Billboard.Parent ~= info.TouchPart then
                    if data.Billboard then data.Billboard:Destroy() end
                    local bb = Instance.new("BillboardGui")
                    bb.Name = "PlotPadBillboard"
                    bb.Size = UDim2.new(0, 160, 0, 40)
                    bb.StudsOffset = Vector3.new(0, 2.5, 0)
                    bb.AlwaysOnTop = true
                    bb.Adornee = info.TouchPart

                    local title = Instance.new("TextLabel", bb)
                    title.Name = "Title"
                    title.Size = UDim2.new(1, 0, 0.5, 0)
                    title.BackgroundTransparency = 1
                    title.Font = Enum.Font.GothamBold
                    title.TextSize = 12
                    title.TextStrokeTransparency = 0.2

                    local priceLbl = Instance.new("TextLabel", bb)
                    priceLbl.Name = "Price"
                    priceLbl.Size = UDim2.new(1, 0, 0.5, 0)
                    priceLbl.Position = UDim2.new(0, 0, 0.5, 0)
                    priceLbl.BackgroundTransparency = 1
                    priceLbl.Font = Enum.Font.GothamMedium
                    priceLbl.TextSize = 11
                    priceLbl.TextStrokeTransparency = 0.2

                    bb.Parent = info.TouchPart
                    data.Billboard = bb
                end

                local title = data.Billboard:FindFirstChild("Title")
                local priceLbl = data.Billboard:FindFirstChild("Price")
                if title and priceLbl then
                    if isAffordable then
                        title.Text = "✅ DO KUPIENIA: " .. info.Name
                        title.TextColor3 = plotColorBuyable
                        priceLbl.Text = "$" .. FormatNumber(info.Price)
                        priceLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
                    else
                        title.Text = "🔒 " .. info.Name
                        title.TextColor3 = plotColorLocked
                        local diff = info.Price - income
                        priceLbl.Text = "$" .. FormatNumber(info.Price) .. " (Brakuje: $" .. FormatNumber(diff) .. ")"
                        priceLbl.TextColor3 = Color3.fromRGB(255, 200, 200)
                    end
                end
                data.Billboard.Enabled = true
            elseif data.Billboard then
                data.Billboard.Enabled = false
            end
        end
    end
end

-- Render loop dla efektów i ESP
RunService.RenderStepped:Connect(function(dt)
    if orbitingStarsEnabled then pcall(UpdateStars, dt) end
    if orbitingRingsEnabled then pcall(UpdateRings, dt) end
    if auraEnabled then pcall(UpdateAura) end
    if esp3DEnabled or tracersEnabled then pcall(UpdatePlayerESP) end
end)

-- Heartbeat loop dla Obby ESP i Plot Render
local renderHeartbeatTick = 0
RunService.Heartbeat:Connect(function()
    renderHeartbeatTick = renderHeartbeatTick + 1
    if renderHeartbeatTick % 10 == 0 then
        if obbyEspEnabled then pcall(UpdateObbyESP) end
        if plotRenderEnabled then pcall(UpdatePlotRender) end
    end
end)

-- // ==========================================================================
-- // BUDOWA ELEMENTÓW UI W ZAKŁADKACH
-- // ==========================================================================

-- =============================================================================
-- === ZAKŁADKA 1: PLAYER ===
-- =============================================================================

-- Moduł: Fly
local FlyMod = TabPlayer:CreateModule({
    Name = "Fly",
    Icon = "plane",
    Default = false,
    Flag = "Player_FlyEnabled",
    Callback = function(state)
        SetFlyState(state)
    end
})

FlyMod:AddSlider({
    Name = "Speed",
    Range = {10, 300},
    CurrentValue = 75,
    Suffix = " studs/s",
    Flag = "Player_FlySpeed",
    Callback = function(val)
        flySpeed = val
    end
})

FlyMod:AddToggle({
    Name = "Noclip",
    Default = true,
    Flag = "Player_FlyNoclip",
    Callback = function(state)
        flyNoclip = state
    end
})

FlyMod:AddToggle({
    Name = "Hover",
    Default = true,
    Flag = "Player_FlyHover",
    Callback = function(state)
        flyHover = state
    end
})

-- Moduł: Speed
local SpeedMod = TabPlayer:CreateModule({
    Name = "Speed",
    Icon = "zap",
    Default = false,
    Flag = "Player_SpeedEnabled",
    Callback = function(state)
        SetSpeedState(state)
    end
})

SpeedMod:AddSlider({
    Name = "WalkSpeed",
    Range = {16, 250},
    CurrentValue = 60,
    Flag = "Player_WalkSpeed",
    Callback = function(val)
        walkSpeedValue = val
        if speedEnabled then
            ApplyWalkSpeed()
        end
    end
})

SpeedMod:AddToggle({
    Name = "AntiReset",
    Default = true,
    Flag = "Player_SpeedAntiReset",
    Callback = function(state)
        speedAntiReset = state
    end
})

-- Moduł: InfJump
local JumpMod = TabPlayer:CreateModule({
    Name = "InfJump",
    Icon = "arrow-up-circle",
    Default = false,
    Flag = "Player_InfJump",
    Callback = function(state)
        infJumpEnabled = state
        ApplyJumpPower()
    end
})

JumpMod:AddSlider({
    Name = "JumpPower",
    Range = {50, 300},
    CurrentValue = 50,
    Flag = "Player_JumpPower",
    Callback = function(val)
        jumpPowerValue = val
        if infJumpEnabled then
            ApplyJumpPower()
        end
    end
})

-- Narzędzia dla gracza
TabPlayer:CreateButton({
    Name = "My Plot",
    Callback = function()
        TeleportToMyPlot()
    end
})

TabPlayer:CreateButton({
    Name = "Reset",
    Callback = function()
        SetFlyState(false)
        SetSpeedState(false)
        infJumpEnabled = false
        ApplyJumpPower()
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.WalkSpeed = originalWalkSpeed
            hum.JumpPower = 50
            hum.PlatformStand = false
        end
    end
})

-- =============================================================================
-- === ZAKŁADKA 2: AUTOFARM ===
-- =============================================================================

-- Moduł: AutoBuy
local AutoBuyMod = TabAutoFarm:CreateModule({
    Name = "AutoBuy",
    Icon = "badge-dollar-sign",
    Default = false,
    Flag = "AutoFarm_AutoBuy",
    Callback = function(state)
        autoBuyEnabled = state
        if state then
            StartAutoBuyLoop()
        end
    end
})

AutoBuyMod:AddSlider({
    Name = "Speed",
    Range = {1, 100},
    CurrentValue = 50,
    Suffix = " %",
    Flag = "AutoFarm_BuySpeed",
    Callback = function(val)
        autoBuySpeedSetting = val
    end
})

AutoBuyMod:AddToggle({
    Name = "AntiStuck",
    Default = true,
    Flag = "AutoFarm_AntiStuck",
    Callback = function(state)
        autoBuyAntiStuck = state
    end
})

AutoBuyMod:AddToggle({
    Name = "Cheapest",
    Default = true,
    Flag = "AutoFarm_PriorityCheapest",
    Callback = function(state)
        autoBuyPriorityCheapest = state
    end
})

AutoBuyMod:AddSlider({
    Name = "Height",
    Range = {1, 6},
    CurrentValue = 2,
    Suffix = " studs",
    Flag = "AutoFarm_TouchHeight",
    Callback = function(val)
        autoBuyTouchHeight = val + 0.5
    end
})

-- Moduł: AutoRebirth
local AutoRebirthMod = TabAutoFarm:CreateModule({
    Name = "AutoRebirth",
    Icon = "recycle",
    Default = false,
    Flag = "AutoFarm_AutoRebirth",
    Callback = function(state)
        autoRebirthEnabled = state
        if state then
            StartAutoRebirthLoop()
        end
    end
})

AutoRebirthMod:AddSlider({
    Name = "Interval",
    Range = {1, 10},
    CurrentValue = 2,
    Suffix = "s",
    Flag = "AutoFarm_RebirthInterval",
    Callback = function(val)
        autoRebirthInterval = val
    end
})

AutoRebirthMod:AddButton({
    Name = "Rebirth",
    Callback = function()
        pcall(function()
            SafeCallAction("Rebirth")
        end)
    end
})

-- Moduł: AutoSpin
local AutoSpinMod = TabAutoFarm:CreateModule({
    Name = "AutoSpin",
    Icon = "disc-2",
    Default = false,
    Flag = "AutoFarm_AutoSpin",
    Callback = function(state)
        autoSpinEnabled = state
        if state then
            StartAutoSpinLoop()
        end
    end
})

AutoSpinMod:AddSlider({
    Name = "Interval",
    Range = {2, 60},
    CurrentValue = 5,
    Suffix = "s",
    Flag = "AutoFarm_SpinInterval",
    Callback = function(val)
        autoSpinInterval = val
    end
})

-- Moduł: AutoPrize
local AutoPrizeMod = TabAutoFarm:CreateModule({
    Name = "AutoPrize",
    Icon = "candy",
    Default = false,
    Flag = "AutoFarm_AutoPrize",
    Callback = function(state)
        autoPrizeEnabled = state
        if state then
            StartAutoPrizeLoop()
        end
    end
})

AutoPrizeMod:AddToggle({
    Name = "Daily",
    Default = true,
    Flag = "AutoFarm_PrizeDaily",
    Callback = function(state)
        autoPrizeDaily = state
    end
})

AutoPrizeMod:AddToggle({
    Name = "Obby",
    Default = true,
    Flag = "AutoFarm_PrizeObby",
    Callback = function(state)
        autoPrizeObby = state
    end
})

AutoPrizeMod:AddToggle({
    Name = "Crates",
    Default = true,
    Flag = "AutoFarm_PrizeCrates",
    Callback = function(state)
        autoPrizeCrates = state
    end
})

-- Moduł: AutoQuests
local AutoQuestsMod = TabAutoFarm:CreateModule({
    Name = "AutoQuests",
    Icon = "clipboard",
    Default = false,
    Flag = "AutoFarm_AutoQuests",
    Callback = function(state)
        autoQuestsEnabled = state
        if state then
            StartAutoQuestsLoop()
        end
    end
})

AutoQuestsMod:AddSlider({
    Name = "Interval",
    Range = {5, 60},
    CurrentValue = 10,
    Suffix = "s",
    Flag = "AutoFarm_QuestsInterval",
    Callback = function(val)
        autoQuestsInterval = val
    end
})

-- =============================================================================
-- === ZAKŁADKA 3: RENDER ===
-- =============================================================================

-- Moduł 1: Stars
local StarsMod = TabRender:CreateModule({
    Name = "Stars",
    Icon = "sparkles",
    Default = false,
    Flag = "Render_OrbitStars",
    Callback = function(state)
        orbitingStarsEnabled = state
        if not state then CleanupStars() end
    end
})

StarsMod:AddSlider({
    Name = "Count",
    Range = {2, 12},
    CurrentValue = 5,
    Flag = "Render_StarsCount",
    Callback = function(val)
        starsCount = val
        CleanupStars()
    end
})

StarsMod:AddSlider({
    Name = "Speed",
    Range = {1, 10},
    CurrentValue = 3,
    Flag = "Render_StarsSpeed",
    Callback = function(val)
        starsSpeed = val
    end
})

StarsMod:AddSlider({
    Name = "Radius",
    Range = {3, 15},
    CurrentValue = 6,
    Suffix = " studs",
    Flag = "Render_StarsRadius",
    Callback = function(val)
        starsRadius = val
    end
})

StarsMod:AddColorPicker({
    Name = "Color",
    Default = Color3.fromRGB(255, 225, 80),
    Flag = "Render_StarsColor",
    Callback = function(col)
        starsColor = col
    end
})

-- Moduł 2: Rings
local RingsMod = TabRender:CreateModule({
    Name = "Rings",
    Icon = "rotate-cw",
    Default = false,
    Flag = "Render_OrbitRings",
    Callback = function(state)
        orbitingRingsEnabled = state
        if not state then CleanupRings() end
    end
})

RingsMod:AddSlider({
    Name = "Speed",
    Range = {1, 10},
    CurrentValue = 4,
    Flag = "Render_RingsSpeed",
    Callback = function(val)
        ringsSpeed = val
    end
})

RingsMod:AddSlider({
    Name = "Radius",
    Range = {3, 12},
    CurrentValue = 6,
    Suffix = " studs",
    Flag = "Render_RingsRadius",
    Callback = function(val)
        ringsRadius = val
    end
})

RingsMod:AddColorPicker({
    Name = "Color",
    Default = Color3.fromRGB(180, 80, 255),
    Flag = "Render_RingsColor",
    Callback = function(col)
        ringsColor = col
    end
})

-- Moduł 3: Aura
local AuraMod = TabRender:CreateModule({
    Name = "Aura",
    Icon = "sun",
    Default = false,
    Flag = "Render_Aura",
    Callback = function(state)
        auraEnabled = state
        if not state then CleanupAura() end
    end
})

AuraMod:AddSlider({
    Name = "Size",
    Range = {4, 15},
    CurrentValue = 7,
    Suffix = " studs",
    Flag = "Render_AuraSize",
    Callback = function(val)
        auraSize = val
    end
})

AuraMod:AddColorPicker({
    Name = "Color",
    Default = Color3.fromRGB(0, 210, 255),
    Flag = "Render_AuraColor",
    Callback = function(col)
        auraColor = col
    end
})

-- Moduł 4: Trail
local TrailMod = TabRender:CreateModule({
    Name = "Trail",
    Icon = "activity",
    Default = false,
    Flag = "Render_Trail",
    Callback = function(state)
        SetTrailState(state)
    end
})

TrailMod:AddSlider({
    Name = "Lifetime",
    Range = {1, 8},
    CurrentValue = 3,
    Suffix = "s",
    Flag = "Render_TrailLifetime",
    Callback = function(val)
        trailLifetime = val
        if trailInstance then trailInstance.Lifetime = val end
    end
})

TrailMod:AddColorPicker({
    Name = "Color",
    Default = Color3.fromRGB(0, 255, 170),
    Flag = "Render_TrailColor",
    Callback = function(col)
        trailColor = col
        if trailInstance then trailInstance.Color = ColorSequence.new(col) end
    end
})

-- Moduł 5: ESP
local EspMod = TabRender:CreateModule({
    Name = "ESP",
    Icon = "users",
    Default = false,
    Flag = "Render_PlayerESP",
    Callback = function(state)
        esp3DEnabled = state
        if not state then
            for player, _ in pairs(espTrackedPlayers) do
                CleanupPlayerESP(player)
            end
        end
    end
})

EspMod:AddToggle({
    Name = "3D Box",
    Default = true,
    Flag = "Render_ESPBoxWireframe",
    Callback = function(state)
        esp3DWireframe = state
    end
})

EspMod:AddToggle({
    Name = "Chams",
    Default = true,
    Flag = "Render_ESPChams",
    Callback = function(state)
        esp3DHighlights = state
    end
})

EspMod:AddToggle({
    Name = "Names",
    Default = true,
    Flag = "Render_ESPNames",
    Callback = function(state)
        esp3DNames = state
    end
})

EspMod:AddToggle({
    Name = "Distance",
    Default = true,
    Flag = "Render_ESPDistance",
    Callback = function(state)
        esp3DDistance = state
    end
})

EspMod:AddColorPicker({
    Name = "Color",
    Default = Color3.fromRGB(0, 255, 170),
    Flag = "Render_ESPColor",
    Callback = function(col)
        esp3DColor = col
    end
})

-- Moduł 6: Tracers
local TracersMod = TabRender:CreateModule({
    Name = "Tracers",
    Icon = "navigation",
    Default = false,
    Flag = "Render_Tracers",
    Callback = function(state)
        tracersEnabled = state
        if not state then
            for _, data in pairs(espTrackedPlayers) do
                if data.TracerLine then data.TracerLine.Visible = false end
            end
        end
    end
})

TracersMod:AddDropdown({
    Name = "Origin",
    Options = {"Dół Ekranu (Bottom)", "Środek Ekranu (Center)", "Myszka (Cursor)"},
    CurrentOption = {"Dół Ekranu (Bottom)"},
    Flag = "Render_TracerOrigin",
    Callback = function(opt)
        tracerOriginMode = type(opt) == "table" and opt[1] or opt
    end
})

TracersMod:AddColorPicker({
    Name = "Color",
    Default = Color3.fromRGB(0, 220, 255),
    Flag = "Render_TracerColor",
    Callback = function(col)
        tracerColor = col
    end
})

-- Moduł 7: ObbyESP
local ObbyMod = TabRender:CreateModule({
    Name = "ObbyESP",
    Icon = "flag",
    Default = false,
    Flag = "Render_ObbyESP",
    Callback = function(state)
        obbyEspEnabled = state
        if not state then CleanupObbyESP() end
    end
})

ObbyMod:AddToggle({
    Name = "Highlight",
    Default = true,
    Flag = "Render_ObbyHighlight",
    Callback = function(state)
        obbyEspHighlight = state
        if not state then CleanupObbyESP() end
    end
})

ObbyMod:AddToggle({
    Name = "Timers",
    Default = true,
    Flag = "Render_ObbyTimers",
    Callback = function(state)
        obbyEspTimers = state
        if not state then CleanupObbyESP() end
    end
})

ObbyMod:AddColorPicker({
    Name = "Color",
    Default = Color3.fromRGB(255, 160, 40),
    Flag = "Render_ObbyColor",
    Callback = function(col)
        obbyEspColor = col
    end
})

-- Moduł 8: PlotESP
local PlotMod = TabRender:CreateModule({
    Name = "PlotESP",
    Icon = "layers",
    Default = false,
    Flag = "Render_PlotRender",
    Callback = function(state)
        plotRenderEnabled = state
        if not state then CleanupPlotRender() end
    end
})

PlotMod:AddToggle({
    Name = "Buyable",
    Default = true,
    Flag = "Render_PlotHighlightBuyable",
    Callback = function(state)
        plotHighlightBuyable = state
    end
})

PlotMod:AddToggle({
    Name = "Locked",
    Default = true,
    Flag = "Render_PlotHighlightLocked",
    Callback = function(state)
        plotHighlightLocked = state
    end
})

PlotMod:AddToggle({
    Name = "Labels",
    Default = true,
    Flag = "Render_PlotShowLabels",
    Callback = function(state)
        plotShowLabels = state
        if not state then
            for _, d in pairs(plotVisualAdornments) do
                if d.Billboard then d.Billboard.Enabled = false end
            end
        end
    end
})

PlotMod:AddColorPicker({
    Name = "Buyable Color",
    Default = Color3.fromRGB(76, 255, 120),
    Flag = "Render_PlotColorBuyable",
    Callback = function(col)
        plotColorBuyable = col
    end
})

PlotMod:AddColorPicker({
    Name = "Locked Color",
    Default = Color3.fromRGB(235, 75, 75),
    Flag = "Render_PlotColorLocked",
    Callback = function(col)
        plotColorLocked = col
    end
})

-- Czyszczenie przy respawnie postaci
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    if flyEnabled then SetFlyState(true) end
    if speedEnabled then ApplyWalkSpeed() end
    if infJumpEnabled then ApplyJumpPower() end
    if trailEnabled then SetTrailState(true) end
end)

print("==================================================")
print("✅ [UPD 3.1] Tycoon, but one dropper")
print("🚀 Menu załadowane pomyślnie z biblioteki MenuTest!")
print("📌 Klawisz menu: INSERT")
print("==================================================")
