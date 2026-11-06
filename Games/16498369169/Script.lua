-- // ==========================================================================
-- // PET SIMULATOR 99 HALLOWEEN EVENT - SPEED & PET SPEED SUITE
-- // Dedicated script for MenuTest UI Library (https://github.com/XxvoltikxX/MenuTest)
-- // Features: Player Speed Boost (Legit / HVH / Normal / CFrame), Pet Speed (Fast Pets / Multiplier)
-- // Game ID: 16498369169
-- // Tab: General (Speed & Pet Speed ONLY)
-- // ==========================================================================

-- 0. Sprzatanie poprzedniej instancji skryptu Halloween
if typeof(getgenv) == "function" and getgenv()._PS99HalloweenCleanup then
    pcall(getgenv()._PS99HalloweenCleanup)
    getgenv()._PS99HalloweenCleanup = nil
end
if _G.PS99HalloweenCleanup then
    pcall(_G.PS99HalloweenCleanup)
    _G.PS99HalloweenCleanup = nil
end

-- 1. Inicjalizacja MenuTest UI Library (XxvoltikxX / MenuTest)
local isDev = (typeof(getgenv) == "function" and getgenv()._MenuTestDevMode == true)
local MENU = nil

if isDev and typeof(readfile) == "function" then
    local candidates = {
        "MenuTest/Main.lua",
        "Main.lua"
    }
    for _, path in ipairs(candidates) do
        if typeof(isfile) == "function" and isfile(path) then
            local ok, data = pcall(readfile, path)
            if ok and data and #data > 0 then
                local chunk = loadstring(data:gsub("^\239\187\191", ""))
                if chunk then
                    MENU = chunk()
                    break
                end
            end
        end
    end
end

if not MENU then
    local urls = {
        "https://raw.githubusercontent.com/XxvoltikxX/MenuTest/main/Main.lua?_t=" .. tostring(tick()) .. "_" .. tostring(math.random(100000, 999999)),
        "https://raw.githubusercontent.com/XxvoltikxX/MenuTest/refs/heads/main/Main.lua?_t=" .. tostring(tick()) .. "_" .. tostring(math.random(100000, 999999))
    }
    for _, u in ipairs(urls) do
        local ok, mainRaw = pcall(function() return game:HttpGet(u) end)
        if ok and mainRaw and #mainRaw > 0 then
            local chunk = loadstring(mainRaw:gsub("^\239\187\191", ""))
            if chunk then
                MENU = chunk()
                break
            end
        end
    end
end

if not MENU then
    warn("[PetHub] Nie udalo sie zaladowac MenuTest z GitHub! Upewnij sie, ze masz polaczenie z siecia.")
    return
end

-- // SERWISY ROBLOX
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

-- Flaga zywotnosci skryptu dla petli w tle
local ScriptRunning = true
local ScriptConnections = {}

-- // INICJALIZACJA FRAMEWORK / LIBRARY GRY (Pet Simulator X / 99)
local Framework = nil
local Library = nil

local function loadGameLibrary()
    if Framework and (Framework.Network or Framework.Things) then return Framework end
    local candidates = {
        function() return require(ReplicatedStorage.Library) end,
        function() return require(ReplicatedStorage:WaitForChild("Library", 1)) end,
        function() return require(ReplicatedStorage.Framework.Library) end,
        function() return require(ReplicatedStorage:WaitForChild("Framework", 1):WaitForChild("Library", 1)) end,
    }
    for _, fn in ipairs(candidates) do
        local ok, res = pcall(fn)
        if ok and type(res) == "table" then
            Framework = res
            Library = res
            return res
        end
    end
    if typeof(getloadedmodules) == "function" then
        for _, mod in ipairs(getloadedmodules()) do
            if mod.Name == "Library" or mod.Name == "Framework" then
                local ok, res = pcall(require, mod)
                if ok and type(res) == "table" and (res.Network or res.Directory) then
                    Framework = res
                    Library = res
                    return res
                end
            end
        end
    end
    return nil
end

pcall(loadGameLibrary)

local function getThingsFolder()
    if Framework and Framework.Things then return Framework.Things end
    return Workspace:FindFirstChild("__THINGS")
end

-- // GŁÓWNA TABELA STANU SKRYPTU (SPEED & PET SPEED ONLY)
local State = {
    -- 1. Player Speed
    PlayerSpeedEnabled = false,
    PlayerSpeedMode = "Legit",
    PlayerSpeedValue = 50,

    -- 2. Pet Speed (Szybkosc Petow)
    PetSpeedEnabled = false,
    PetSpeedValue = 25,
    PetInstantSnap = true,
    PetMaxForce = true,
}

-- // ==========================================================================
-- // 1. SYSTEM PET SPEED (SZYBKOŚĆ PRZEMIESZCZANIA I FIZYKA PETÓW)
-- // ==========================================================================
local lastEquippedFetch = 0
local cachedEquippedUids = {}

local function getEquippedPets(force)
    local now = tick()
    if not force and (now - lastEquippedFetch < 1.0) and #cachedEquippedUids > 0 then
        return cachedEquippedUids
    end
    lastEquippedFetch = now

    local equippedUids = {}
    if Framework and Framework.PetCmds and Framework.PetCmds.GetEquipped then
        local eq = Framework.PetCmds.GetEquipped(LocalPlayer, true)
        if type(eq) == "table" then
            for _, uid in ipairs(eq) do
                table.insert(equippedUids, uid)
            end
        end
    end
    if #equippedUids == 0 and Framework and Framework.Save and Framework.Save.Get then
        local save = Framework.Save.Get()
        if save and save.Pets then
            for _, p in ipairs(save.Pets) do
                if p.e then table.insert(equippedUids, p.uid) end
            end
        end
    end
    if #equippedUids == 0 then
        local things = getThingsFolder()
        local pets = things and things:FindFirstChild("Pets")
        if pets then
            for _, p in ipairs(pets:GetChildren()) do
                local owner = p:GetAttribute("Owner")
                if (owner and tostring(owner) == LocalPlayer.Name) or p.Name:find(LocalPlayer.Name, 1, true) then
                    table.insert(equippedUids, p.Name)
                end
            end
        end
    end
    cachedEquippedUids = equippedUids
    return equippedUids
end

local function isMyPet(pet, optionalUids)
    if not pet then return false end
    local owner = pet:GetAttribute("Owner")
    if owner and tostring(owner) == LocalPlayer.Name then
        return true
    end
    if pet.Name:find(LocalPlayer.Name, 1, true) then
        return true
    end
    local myUids = optionalUids or getEquippedPets()
    local uid = pet:GetAttribute("UID")
    if table.find(myUids, pet.Name) or (uid and table.find(myUids, uid)) then
        return true
    end
    for _, attr in ipairs({"OwnerName", "Player", "UserId"}) do
        local val = pet:GetAttribute(attr)
        if val == LocalPlayer.Name or val == LocalPlayer.UserId then
            return true
        end
    end
    return false
end

-- Hookowanie natywnej biblioteki Agility dla petow w Framework / Library (Pet Speed Engine)
local function hookPetSpeed()
    local targetLib = Framework or Library
    if not targetLib then return end

    local shared = targetLib.Shared
    if not shared and targetLib.Directory and targetLib.Directory.Shared then
        shared = targetLib.Directory.Shared
    end

    if shared and not shared._PetSpeedHooked then
        shared._PetSpeedHooked = true

        local origHasPower = shared.HasPower
        shared.HasPower = function(pet, powerName, ...)
            if State.PetSpeedEnabled and powerName == "Agility" then
                return true, 3
            end
            if origHasPower then
                return origHasPower(pet, powerName, ...)
            end
            return false
        end

        local origGetPowerDir = shared.GetPowerDir
        shared.GetPowerDir = function(powerName, tier, ...)
            if State.PetSpeedEnabled and powerName == "Agility" then
                local mult = tonumber(State.PetSpeedValue) or 25
                return {
                    title = "Agility III",
                    desc = "Pet moves ultra fast",
                    value = mult
                }
            end
            if origGetPowerDir then
                return origGetPowerDir(powerName, tier, ...)
            end
            return { title = "Agility", desc = "", value = 1 }
        end
    end
end
pcall(hookPetSpeed)

local petMoverCache = setmetatable({}, { __mode = "k" })

-- Wzmocnienie sily fizycznej i responsywnosci petow w Workspace
local function updateWorkspacePetsPhysics()
    local things = getThingsFolder()
    local petsFolder = things and things:FindFirstChild("Pets")
    if not petsFolder then return end

    local mult = tonumber(State.PetSpeedValue) or 25
    local pForce = math.clamp(20000 * mult, 20000, 10000000)
    local myUids = getEquippedPets()

    for _, pet in ipairs(petsFolder:GetChildren()) do
        if isMyPet(pet, myUids) then
            local moverData = petMoverCache[pet]
            if not moverData or not moverData.bp or not moverData.bp.Parent then
                local bp = pet:FindFirstChildWhichIsA("BodyPosition", true)
                local ap = pet:FindFirstChildWhichIsA("AlignPosition", true)
                moverData = { bp = bp, ap = ap }
                petMoverCache[pet] = moverData
            end

            local bp = moverData.bp
            if bp and bp.Parent then
                if State.PetSpeedEnabled then
                    bp.MaxForce = Vector3.new(1e8, 1e8, 1e8)
                    bp.P = pForce
                    if State.PetMaxForce or mult >= 15 then
                        bp.D = 250
                    end
                end
            end

            local ap = moverData.ap
            if ap and ap.Parent and State.PetSpeedEnabled then
                ap.MaxForce = 1e8
                ap.Responsiveness = math.clamp(20 * (mult / 2), 20, 200)
            end
        end
    end
end

-- // ==========================================================================
-- // 2. SYSTEM PRĘDKOŚCI GRACZA (PLAYER SPEED ENGINE)
-- // ==========================================================================
local function getMoveDirection()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum and hum.MoveDirection.Magnitude > 0 then
        return true, hum.MoveDirection
    end

    local camera = Workspace.CurrentCamera
    if not char or not char:FindFirstChild("HumanoidRootPart") or not camera then
        return false, Vector3.zero
    end

    local look = camera.CFrame.LookVector
    local moveDir = Vector3.new(look.X, 0, look.Z)
    if moveDir.Magnitude > 0 then
        moveDir = moveDir.Unit
    end

    local movement = Vector3.zero
    if UserInputService:IsKeyDown(Enum.KeyCode.W) or UserInputService:IsKeyDown(Enum.KeyCode.Up) then movement = movement + moveDir end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) or UserInputService:IsKeyDown(Enum.KeyCode.Down) then movement = movement - moveDir end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) or UserInputService:IsKeyDown(Enum.KeyCode.Right) then movement = movement + Vector3.new(-moveDir.Z, 0, moveDir.X) end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) or UserInputService:IsKeyDown(Enum.KeyCode.Left) then movement = movement + Vector3.new(moveDir.Z, 0, -moveDir.X) end

    if movement.Magnitude > 0 then
        return true, movement.Unit
    end
    return false, Vector3.zero
end

local speedHeartbeatConn = nil
local speedRenderConn = nil

local function stopSpeedConnections()
    if speedHeartbeatConn then speedHeartbeatConn:Disconnect() speedHeartbeatConn = nil end
    if speedRenderConn then speedRenderConn:Disconnect() speedRenderConn = nil end
    pcall(function()
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = 16 end
    end)
end

local function initSpeedConnections()
    if not speedHeartbeatConn then
        speedHeartbeatConn = RunService.Heartbeat:Connect(function()
            if not ScriptRunning then return end
            if not (State.PlayerSpeedEnabled or _G.SpeedEnabled) then return end

            local char = LocalPlayer.Character
            if not char then return end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local hum = char:FindFirstChildOfClass("Humanoid")
            if not hrp or not hum then return end

            local targetSpeed = tonumber(State.PlayerSpeedValue or _G.SpeedValue or 50) or 50
            local mode = State.PlayerSpeedMode or _G.SpeedMode or "Legit"

            if mode == "Normal" then
                if hum.WalkSpeed ~= targetSpeed then
                    hum.WalkSpeed = targetSpeed
                end
            elseif mode == "Legit" or mode == "HVH" then
                local moving, moveDir = getMoveDirection()
                if mode == "HVH" and (UserInputService:IsKeyDown(Enum.KeyCode.Space) or hum:GetState() == Enum.HumanoidStateType.Freefall) then
                    hum.Jump = true
                end

                if moving then
                    local currentY = hrp.AssemblyLinearVelocity and hrp.AssemblyLinearVelocity.Y or hrp.Velocity.Y
                    local newVel = Vector3.new(moveDir.X * targetSpeed, currentY, moveDir.Z * targetSpeed)
                    pcall(function() hrp.AssemblyLinearVelocity = newVel end)
                    pcall(function() hrp.Velocity = newVel end)
                end
            end
        end)
    end

    if not speedRenderConn then
        speedRenderConn = RunService.RenderStepped:Connect(function(dt)
            if not ScriptRunning then return end
            if not (State.PlayerSpeedEnabled or _G.SpeedEnabled) then return end

            local char = LocalPlayer.Character
            if not char then return end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local hum = char:FindFirstChildOfClass("Humanoid")
            if not hrp or not hum then return end

            local targetSpeed = tonumber(State.PlayerSpeedValue or _G.SpeedValue or 50) or 50
            local mode = State.PlayerSpeedMode or _G.SpeedMode or "Legit"

            if mode == "CFrame" then
                local moving, moveDir = getMoveDirection()
                if moving then
                    local delta = (dt and dt > 0) and dt or (1 / 60)
                    hrp.CFrame = hrp.CFrame + (moveDir * (targetSpeed * delta))
                end
            end
        end)
    end
end

initSpeedConnections()

LocalPlayer.CharacterAdded:Connect(function(newChar)
    if State.PlayerSpeedEnabled or _G.SpeedEnabled then
        task.wait(0.2)
        local hum = newChar:WaitForChild("Humanoid", 3)
        if hum and (State.PlayerSpeedMode == "Normal") then
            hum.WalkSpeed = State.PlayerSpeedValue or 50
        end
    end
end)

-- // ==========================================================================
-- // 3. PĘTLE W TLE (PET SPEED LOOP & LISTENERS)
-- // ==========================================================================
task.spawn(function()
    while ScriptRunning do
        if State.PetSpeedEnabled then
            pcall(hookPetSpeed)
            pcall(updateWorkspacePetsPhysics)
            task.wait(0.2)
        else
            task.wait(0.6)
        end
    end
end)

local petsChildAddedConn = nil
local function bindPetsFolderListener()
    if petsChildAddedConn then return end
    local things = getThingsFolder()
    local petsFolder = things and things:FindFirstChild("Pets")
    if petsFolder then
        petsChildAddedConn = petsFolder.ChildAdded:Connect(function(pet)
            if State.PetSpeedEnabled then
                task.wait(0.1)
                pcall(hookPetSpeed)
                pcall(updateWorkspacePetsPhysics)
            end
        end)
        table.insert(ScriptConnections, petsChildAddedConn)
    end
end
task.spawn(bindPetsFolderListener)

-- // ==========================================================================
-- // 4. INTERFEJS UŻYTKOWNIKA MENUTEST (JEDNA ZAKŁADKA "GENERAL": SPEED & PET SPEED)
-- // ==========================================================================
local Window = MENU:CreateWindow({
    Name = "PetHub",
    Tittle = "Pet sim 99 event hallowen",
    TittlePos = "Center",
    ToggleUIKeybind = "K",
    TestMobile = false,
    GameId = "16498369169"
})

local function doCleanup()
    ScriptRunning = false
    stopSpeedConnections()
    for _, conn in ipairs(ScriptConnections) do
        pcall(function() conn:Disconnect() end)
    end
    table.clear(ScriptConnections)
    State.PlayerSpeedEnabled = false
    State.PetSpeedEnabled = false
end

if typeof(getgenv) == "function" then
    getgenv()._PS99HalloweenCleanup = doCleanup
end
_G.PS99HalloweenCleanup = doCleanup

if Window and Window.ScreenGui then
    Window.ScreenGui.Destroying:Connect(doCleanup)
end

-- Wyłączenie limitera prędkości AntiFling w Settings dla płynnego biegu
task.spawn(function()
    for _ = 1, 40 do
        if Window and Window.Flags and Window.Flags["AntiFling"] then
            pcall(function()
                if Window.Flags["AntiFling"].Set then
                    Window.Flags["AntiFling"]:Set(false)
                end
            end)
            break
        end
        task.wait(0.05)
    end
end)

if Window.OnReady then
    Window:OnReady(function()
        pcall(function()
            if Window.Flags and Window.Flags["AntiFling"] and Window.Flags["AntiFling"].Set then
                Window.Flags["AntiFling"]:Set(false)
            end
        end)
    end)
end

-- Główna zakładka General
local TabGeneral = Window:CreateTab("General", "home")

-- // ==================== MODUŁ 1: SPEED (PLAYER SPEED) ====================
local SpeedModule = TabGeneral:CreateModule({
    Name = "Speed",
    Description = "Zaawansowany, płynny system prędkości gracza z ochroną przed resetowaniem",
    Default = false,
    CurrentValue = false,
    DefaultKeybind = "Z",
    Flag = "General_Speed",
    Callback = function(state)
        State.PlayerSpeedEnabled = state
        _G.SpeedEnabled = state
        if not state then
            pcall(function()
                local char = LocalPlayer.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if hum then hum.WalkSpeed = 16 end
            end)
        else
            pcall(function()
                local char = LocalPlayer.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if hum and State.PlayerSpeedMode == "Normal" then
                    hum.WalkSpeed = State.PlayerSpeedValue or 50
                end
            end)
        end
    end
})

SpeedModule:AddDropdown({
    Name = "Speed Mode",
    Options = {"Legit", "HVH", "Normal", "CFrame"},
    CurrentOption = {"Legit"},
    Default = "Legit",
    Flag = "General_SpeedMode",
    Callback = function(val)
        local selected = (type(val) == "table" and val[1]) or val
        State.PlayerSpeedMode = selected
        _G.SpeedMode = selected
        if selected ~= "Normal" then
            pcall(function()
                local char = LocalPlayer.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if hum then hum.WalkSpeed = 16 end
            end)
        elseif State.PlayerSpeedEnabled then
            pcall(function()
                local char = LocalPlayer.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if hum then hum.WalkSpeed = State.PlayerSpeedValue or 50 end
            end)
        end
    end
})

SpeedModule:AddSlider({
    Name = "Custom Speed",
    Range = { 16, 300 },
    CurrentValue = 50,
    Min = 16,
    Max = 300,
    Default = 50,
    Suffix = " Studs",
    Flag = "General_SpeedVal",
    Callback = function(val)
        State.PlayerSpeedValue = val
        _G.SpeedValue = val
        if State.PlayerSpeedEnabled and State.PlayerSpeedMode == "Normal" then
            pcall(function()
                local char = LocalPlayer.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if hum then hum.WalkSpeed = val end
            end)
        end
    end
})

-- // ==================== MODUŁ 2: PET SPEED (SZYBKOŚĆ PRZEMIESZCZANIA PETÓW) ====================
local PetSpeedModule = TabGeneral:CreateModule({
    Name = "Pet Speed",
    Description = "Zwiększa szybkość przemieszczania i ataku petów (Fast Pets)",
    Default = false,
    CurrentValue = false,
    DefaultKeybind = "X",
    Flag = "General_PetSpeed",
    Callback = function(state)
        State.PetSpeedEnabled = state
        if state then
            pcall(hookPetSpeed)
            pcall(updateWorkspacePetsPhysics)
        end
    end
})

PetSpeedModule:AddSlider({
    Name = "Mnożnik Prędkości (Speed Multiplier)",
    Range = { 1, 100 },
    CurrentValue = 25,
    Min = 1,
    Max = 100,
    Default = 25,
    Suffix = "x",
    Flag = "General_PetSpeedVal",
    Callback = function(val)
        State.PetSpeedValue = val
        if State.PetSpeedEnabled then
            pcall(hookPetSpeed)
            pcall(updateWorkspacePetsPhysics)
        end
    end
})

PetSpeedModule:AddToggle({
    Name = "Natychmiastowy Doskok do Celu (Instant Snap)",
    Default = true,
    CurrentValue = true,
    Flag = "General_PetInstantSnap",
    Callback = function(state)
        State.PetInstantSnap = state
    end
})

PetSpeedModule:AddToggle({
    Name = "Wzmocniona Fizyka Petów (Max Force)",
    Default = true,
    CurrentValue = true,
    Flag = "General_PetMaxForce",
    Callback = function(state)
        State.PetMaxForce = state
        if State.PetSpeedEnabled then
            pcall(updateWorkspacePetsPhysics)
        end
    end
})

print("[PetHub] Pomyslnie zaladowano skrypt Pet sim 99 event hallowen!")
