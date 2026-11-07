-- // ==========================================================================
-- // PET SIMULATOR 99 (HALLOWEEN EVENT) - AUTOMATION & PET SPEED SUITE
-- // Dedicated script for MenuTest UI Library (https://github.com/XxvoltikxX/MenuTest)
-- // Game ID: 16498369169
-- // Features:
-- //   1. Auto Farm (Kopanie obiektów/coins z wyborem aren: Zone 1-8 lub bieżąca)
-- //   2. Pet Speed Engine (Szybkość doskoku petów, mnożnik prędkości, instant snap, max force)
-- //   3. Auto Collect Orbits (Teleportowanie orbów bezpośrednio do gracza + instant collect)
-- //   4. Player Speed Engine (Legit, HVH, Normal, CFrame z ominięciem anty-cheata)
-- // ==========================================================================

-- // ==========================================================================
-- // 0. SPRZĄTANIE POPRZEDNIEJ INSTANCJI
-- // ==========================================================================
if typeof(getgenv) == "function" and getgenv()._PS99HalloweenCleanup then
    pcall(getgenv()._PS99HalloweenCleanup)
    getgenv()._PS99HalloweenCleanup = nil
end
if _G.PS99HalloweenCleanup then
    pcall(_G.PS99HalloweenCleanup)
    _G.PS99HalloweenCleanup = nil
end

-- // ==========================================================================
-- // 1. INICJALIZACJA BIBLIOTEKI MENUTEST
-- // ==========================================================================
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
        "https://cdn.jsdelivr.net/gh/XxvoltikxX/MenuTest@main/Main.lua",
        "https://raw.githubusercontent.com/XxvoltikxX/MenuTest/refs/heads/main/Main.lua?_t=" .. tostring(tick()) .. "_" .. tostring(math.random(100000, 999999)),
        "https://raw.githubusercontent.com/XxvoltikxX/MenuTest/main/Main.lua?_t=" .. tostring(tick()) .. "_" .. tostring(math.random(100000, 999999))
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

-- // ==========================================================================
-- // 2. SERWISY ROBLOX I ZMIENNE BIEŻĄCE
-- // ==========================================================================
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

local ScriptRunning = true
local ScriptConnections = {}

-- // ==========================================================================
-- // 3. INICJALIZACJA FRAMEWORK / LIBRARY & NETWORK
-- // ==========================================================================
local Framework = nil
local Library = nil
local ClientNetwork = nil
local NetworkFolder = ReplicatedStorage:FindFirstChild("Network")

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

pcall(function()
    ClientNetwork = require(ReplicatedStorage.Library.Client.Network)
end)

local function getThingsFolder()
    if Framework and Framework.Things then return Framework.Things end
    return Workspace:FindFirstChild("__THINGS")
end

local function fireNetwork(name, ...)
    if ClientNetwork and ClientNetwork.Fire then
        local ok = pcall(ClientNetwork.Fire, name, ...)
        if ok then return true end
    end
    if NetworkFolder then
        local rem = NetworkFolder:FindFirstChild(name)
        if rem and rem:IsA("RemoteEvent") then
            local ok = pcall(rem.FireServer, rem, ...)
            if ok then return true end
        end
    end
    return false
end

-- // ==========================================================================
-- // 4. TABELA KONFIGURACJI I STANU (STATE)
-- // ==========================================================================
local State = {
    -- 1. Auto Farm
    AutoFarmEnabled = false,
    FarmZone = "Aktualna (Najbliższa)",
    FarmPriority = "Najbliższe (Closest)",
    FarmRange = 800,
    FarmInfiniteRange = true,
    AttackDelay = 0.15,
    CurrentTarget = nil,

    -- 2. Pet Speed
    PetSpeedEnabled = false,
    PetSpeedValue = 30,
    PetInstantSnap = true,
    PetMaxForce = true,

    -- 3. Auto Collect Orbits
    OrbitCollectEnabled = false,
    OrbitTeleportToMe = true,
    OrbitInfiniteRange = true,
    OrbitRange = 1000,
    OrbitInterval = 0.1,

    -- 4. Player Speed & Jump
    PlayerSpeedEnabled = false,
    PlayerSpeedMode = "Legit",
    PlayerSpeedValue = 50,
    InfiniteJumpEnabled = false,
    JumpSpeedValue = 75,
}

-- // ==========================================================================
-- // 5. ZARZĄDZANIE PETAMI I SILNIK SZYBKOŚCI PETÓW (PET SPEED ENGINE)
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
                local mult = tonumber(State.PetSpeedValue) or 30
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

local function updateWorkspacePetsPhysics(targetPos)
    local things = getThingsFolder()
    local petsFolder = things and things:FindFirstChild("Pets")
    if not petsFolder then return end

    local mult = tonumber(State.PetSpeedValue) or 30
    local pForce = math.clamp(30000 * mult, 30000, 10000000)
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

            local offset = Vector3.new(math.random(-3, 3), 1, math.random(-3, 3))

            -- Natychmiastowy doskok do kopanego obiektu (Instant Snap)
            if targetPos and State.PetInstantSnap then
                if pet.PivotTo then
                    pcall(pet.PivotTo, pet, CFrame.new(targetPos + offset))
                elseif pet.PrimaryPart then
                    pcall(function() pet.PrimaryPart.CFrame = CFrame.new(targetPos + offset) end)
                end
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
                if targetPos then
                    bp.Position = targetPos + offset
                end
            end

            local ap = moverData.ap
            if ap and ap.Parent and State.PetSpeedEnabled then
                ap.MaxForce = 1e8
                ap.Responsiveness = math.clamp(20 * mult, 20, 200)
                ap.MaxVelocity = math.huge
                if targetPos then
                    pcall(function() ap.Position = targetPos + offset end)
                end
            end
        end
    end
end

-- // ==========================================================================
-- // 6. DETEKCJA STREF I AREN (ZONE DETECTION)
-- // ==========================================================================
local function findZoneObjects()
    local zones = {}

    local z1 = Workspace:FindFirstChild("Zone 1") or Workspace:FindFirstChild("Zone1")
    if z1 then zones["Zone 1"] = z1 end

    local things = getThingsFolder()
    if things then
        local fakeBreak = things:FindFirstChild("__FAKE_INSTANCE_BREAK_ZONES")
        if fakeBreak then
            for _, child in ipairs(fakeBreak:GetDescendants()) do
                local zNum = child.Name:match("^Zone(%d+)")
                if zNum then
                    zones["Zone " .. zNum] = child
                end
            end
        end

        local fakeGround = things:FindFirstChild("__FAKE_INSTANCE_GROUND")
        if fakeGround then
            local hg = fakeGround:FindFirstChild("HalloweenGames")
            if hg then
                for _, child in ipairs(hg:GetChildren()) do
                    local zName = "Zone " .. child.Name
                    if not zones[zName] then
                        zones[zName] = child
                    end
                end
            end
        end
    end

    return zones
end

local function getZonePosition(zObj)
    if not zObj then return nil end
    if zObj:IsA("BasePart") then return zObj.Position end
    if zObj:IsA("Model") then return zObj:GetPivot().Position end
    local pp = zObj:FindFirstChildWhichIsA("BasePart", true)
    return pp and pp.Position
end

local function getCurrentPlayerZone(zones)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return "Zone 1" end
    local pPos = hrp.Position

    local closestZone = "Zone 1"
    local closestDist = math.huge

    for zName, zObj in pairs(zones) do
        local zPos = getZonePosition(zObj)
        if zPos then
            local dist = (pPos - zPos).Magnitude
            if dist < closestDist then
                closestDist = dist
                closestZone = zName
            end
        end
    end

    return closestZone
end

local function getBreakablePosition(brk)
    if not brk then return nil end
    if brk:IsA("BasePart") then return brk.Position end
    if brk:IsA("Model") then return brk:GetPivot().Position end
    local pp = brk:FindFirstChildWhichIsA("BasePart", true)
    return pp and pp.Position
end

local function isBreakableAlive(brk)
    if not brk or not brk.Parent then return false end
    if brk:GetAttribute("Dead") == true or brk:GetAttribute("Destroyed") == true then
        return false
    end
    if brk:IsA("BasePart") then return brk.Transparency < 1 end
    if brk:IsA("Model") then
        local pp = brk.PrimaryPart or brk:FindFirstChildWhichIsA("BasePart", true)
        return pp ~= nil and pp.Transparency < 1
    end
    return true
end

local function getBreakableInfo(brk)
    local hp = brk:GetAttribute("Health") or brk:GetAttribute("hp") or 100
    local maxHp = brk:GetAttribute("MaxHealth") or brk:GetAttribute("maxHp") or hp
    local name = brk:GetAttribute("Type") or brk:GetAttribute("Name") or brk.Name
    return tostring(name), tonumber(hp) or 100, tonumber(maxHp) or 100
end

local function isBreakableInZone(brk, targetZone, zones)
    if targetZone == "Wszystkie Areny (ALL)" then
        return true
    end

    local actualTargetZone = targetZone
    if targetZone == "Aktualna (Najbliższa)" then
        actualTargetZone = getCurrentPlayerZone(zones)
    end

    -- 1. Sprawdzenie atrybutów
    for _, attr in ipairs({"Zone", "ParentID", "ZoneID", "Area", "zone"}) do
        local val = brk:GetAttribute(attr)
        if val then
            local strVal = tostring(val)
            if strVal == actualTargetZone or strVal:find(actualTargetZone:gsub("%s+", ""), 1, true) then
                return true
            end
            local numStr = actualTargetZone:match("%d+")
            if numStr and (strVal == numStr or strVal:find(numStr, 1, true)) then
                return true
            end
        end
    end

    -- 2. Sprawdzenie przestrzenne względem strefy
    local bPos = getBreakablePosition(brk)
    if not bPos then return false end

    local closestZ = nil
    local closestD = math.huge
    for zName, zObj in pairs(zones) do
        local zPos = getZonePosition(zObj)
        if zPos then
            local d = (bPos - zPos).Magnitude
            if d < closestD then
                closestD = d
                closestZ = zName
            end
        end
    end

    return (closestZ == actualTargetZone) or (closestD <= 120)
end

-- // ==========================================================================
-- // 7. LOGIKA AUTOFARM (KOPANIE OBIEKTÓW)
-- // ==========================================================================
local function findBestBreakable(zones)
    local things = getThingsFolder()
    local folder = things and things:FindFirstChild("Breakables")
    if not folder then return nil end

    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local pPos = (hrp and hrp.Position) or Vector3.zero

    local best = nil
    local bestScore = -math.huge

    local children = folder:GetChildren()
    for _, brk in ipairs(children) do
        if isBreakableAlive(brk) then
            local bPos = getBreakablePosition(brk)
            if bPos then
                local dist = (bPos - pPos).Magnitude
                if State.FarmInfiniteRange or dist <= State.FarmRange then
                    if isBreakableInZone(brk, State.FarmZone, zones) then
                        local _, hp, maxHp = getBreakableInfo(brk)
                        local score = 0
                        if State.FarmPriority == "Najbliższe (Closest)" then
                            score = -dist
                        elseif State.FarmPriority == "Najwięcej HP (Boss / Big)" then
                            score = maxHp - (dist * 0.1)
                        elseif State.FarmPriority == "Najmniej HP (Fast)" then
                            score = -hp - (dist * 0.1)
                        else
                            score = -dist
                        end

                        if score > bestScore then
                            bestScore = score
                            best = brk
                        end
                    end
                end
            end
        end
    end

    return best
end

local function attackBreakable(brk)
    if not isBreakableAlive(brk) then return end
    State.CurrentTarget = brk

    local bId = brk:GetAttribute("ID") or brk.Name
    local bPos = getBreakablePosition(brk)

    task.spawn(function()
        -- 1. Doskok petów do celu
        if State.PetSpeedEnabled and bPos then
            updateWorkspacePetsPhysics(bPos)
        end

        -- 2. Wysłanie ataku do sieci dla każdego peta
        local equipped = getEquippedPets()
        if #equipped > 0 then
            for _, uid in ipairs(equipped) do
                fireNetwork("Breakables_PlayerAttackBreakable", bId, uid)
                fireNetwork("Breakables_JoinPet", bId, uid)
            end
        else
            fireNetwork("Breakables_PlayerAttackBreakable", bId)
        end

        -- 3. ClickDetector fallback
        local cd = brk:FindFirstChildWhichIsA("ClickDetector", true)
        if cd and typeof(fireclickdetector) == "function" then
            pcall(fireclickdetector, cd)
        end
    end)
end

-- // ==========================================================================
-- // 8. AUTO COLLECT ORBITS (TELEPORT ORBÓW DO GRACZA)
-- // ==========================================================================
local function collectOrbits()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local hrpPos = hrp.Position
    local hrpCF = hrp.CFrame
    local things = getThingsFolder()
    local orbsFolder = things and things:FindFirstChild("Orbs")
    if not orbsFolder then return end

    local orbs = orbsFolder:GetChildren()
    if #orbs == 0 then return end

    local batchIds = {}
    local hasFireTouch = typeof(firetouchinterest) == "function"

    for _, orb in ipairs(orbs) do
        local orbPos = nil
        if orb:IsA("BasePart") then
            orbPos = orb.Position
            if State.OrbitInfiniteRange or (orbPos - hrpPos).Magnitude <= State.OrbitRange then
                if State.OrbitTeleportToMe then
                    orb.CanCollide = false
                    orb.CFrame = hrpCF
                    orb.Velocity = Vector3.zero
                    orb.AssemblyLinearVelocity = Vector3.zero
                end
                if hasFireTouch then
                    pcall(firetouchinterest, hrp, orb, 0)
                    pcall(firetouchinterest, hrp, orb, 1)
                end
            end
        elseif orb:IsA("Model") then
            local pp = orb.PrimaryPart or orb:FindFirstChildWhichIsA("BasePart", true)
            orbPos = (pp and pp.Position) or orb:GetPivot().Position
            if State.OrbitInfiniteRange or (orbPos - hrpPos).Magnitude <= State.OrbitRange then
                if State.OrbitTeleportToMe then
                    orb:PivotTo(hrpCF)
                    if pp then
                        pp.CanCollide = false
                        pp.Velocity = Vector3.zero
                    end
                end
                if pp and hasFireTouch then
                    pcall(firetouchinterest, hrp, pp, 0)
                    pcall(firetouchinterest, hrp, pp, 1)
                end
            end
        end

        local id = orb:GetAttribute("ID") or orb:GetAttribute("id") or tonumber(orb.Name)
        if id then
            table.insert(batchIds, id)
        end
    end

    if #batchIds > 0 then
        pcall(function()
            fireNetwork("Orbs: Collect", batchIds)
        end)
    end
end

-- // ==========================================================================
-- // 9. SYSTEM PRĘDKOŚCI GRACZA (PLAYER SPEED ENGINE)
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
        if hum then
            hum.WalkSpeed = 16
            hum.JumpPower = 50
        end
    end)
end

local function initSpeedConnections()
    if not speedHeartbeatConn then
        speedHeartbeatConn = RunService.Heartbeat:Connect(function()
            if not ScriptRunning then return end

            local char = LocalPlayer.Character
            if not char then return end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local hum = char:FindFirstChildOfClass("Humanoid")
            if not hrp or not hum then return end

            -- 1. Infinite Jump / Ciągły wyskok do góry przy trzymaniu Spacji
            if State.InfiniteJumpEnabled and UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                local upSpeed = tonumber(State.JumpSpeedValue or 75) or 75
                local curY = hrp.AssemblyLinearVelocity and hrp.AssemblyLinearVelocity.Y or hrp.Velocity.Y
                if curY < upSpeed * 0.85 then
                    hum:ChangeState(Enum.HumanoidStateType.Jumping)
                    local curVel = hrp.AssemblyLinearVelocity or hrp.Velocity
                    local newVel = Vector3.new(curVel.X, upSpeed, curVel.Z)
                    pcall(function() hrp.AssemblyLinearVelocity = newVel end)
                    pcall(function() hrp.Velocity = newVel end)
                end
            end

            -- 2. Prędkość Chodzenia (Player Speed)
            if State.PlayerSpeedEnabled then
                local targetSpeed = tonumber(State.PlayerSpeedValue or 50) or 50
                local mode = State.PlayerSpeedMode or "Legit"

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
            end
        end)
    end

    if not speedRenderConn then
        speedRenderConn = RunService.RenderStepped:Connect(function(dt)
            if not ScriptRunning then return end
            if not State.PlayerSpeedEnabled then return end

            local char = LocalPlayer.Character
            if not char then return end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local hum = char:FindFirstChildOfClass("Humanoid")
            if not hrp or not hum then return end

            local targetSpeed = tonumber(State.PlayerSpeedValue or 50) or 50
            local mode = State.PlayerSpeedMode or "Legit"

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

-- Nasłuchiwacz JumpRequest dla natychmiastowego Infinite Jump w powietrzu
local jumpRequestConn = UserInputService.JumpRequest:Connect(function()
    if not ScriptRunning then return end
    if State.InfiniteJumpEnabled then
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hum and hrp then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
            local upSpeed = tonumber(State.JumpSpeedValue or 75) or 75
            local curVel = hrp.AssemblyLinearVelocity or hrp.Velocity
            local newVel = Vector3.new(curVel.X, upSpeed, curVel.Z)
            pcall(function() hrp.AssemblyLinearVelocity = newVel end)
            pcall(function() hrp.Velocity = newVel end)
        end
    end
end)
table.insert(ScriptConnections, jumpRequestConn)

LocalPlayer.CharacterAdded:Connect(function(newChar)
    task.wait(0.2)
    local hum = newChar:WaitForChild("Humanoid", 3)
    if hum then
        if State.PlayerSpeedEnabled and (State.PlayerSpeedMode == "Normal") then
            hum.WalkSpeed = State.PlayerSpeedValue or 50
        end
        if State.InfiniteJumpEnabled then
            hum.UseJumpPower = true
            hum.JumpPower = tonumber(State.JumpSpeedValue or 75) or 75
        end
    end
end)

-- // ==========================================================================
-- // 10. GŁÓWNE PĘTLE W TLE (BACKGROUND LOOPS)
-- // ==========================================================================

-- Pętla AutoFarm
task.spawn(function()
    local cachedZones = findZoneObjects()
    local lastZoneCheck = 0

    while ScriptRunning do
        if State.AutoFarmEnabled then
            local now = tick()
            if now - lastZoneCheck > 5.0 then
                cachedZones = findZoneObjects()
                lastZoneCheck = now
            end

            local cur = State.CurrentTarget
            if not isBreakableAlive(cur) then
                cur = nil
                State.CurrentTarget = nil
            end

            if not cur then
                local target = findBestBreakable(cachedZones)
                if target and isBreakableAlive(target) then
                    attackBreakable(target)
                end
            else
                local targetPos = getBreakablePosition(cur)
                if State.PetSpeedEnabled and targetPos then
                    updateWorkspacePetsPhysics(targetPos)
                end
            end

            task.wait(State.AttackDelay or 0.15)
        else
            State.CurrentTarget = nil
            task.wait(0.5)
        end
    end
end)

-- Pętla Auto Collect Orbits (teleportowanie orbów do gracza)
task.spawn(function()
    while ScriptRunning do
        if State.OrbitCollectEnabled then
            collectOrbits()
            task.wait(State.OrbitInterval or 0.1)
        else
            task.wait(0.5)
        end
    end
end)

-- Pętla Pet Speed Engine
task.spawn(function()
    while ScriptRunning do
        if State.PetSpeedEnabled then
            pcall(hookPetSpeed)
            local targetPos = State.CurrentTarget and getBreakablePosition(State.CurrentTarget)
            pcall(updateWorkspacePetsPhysics, targetPos)
            task.wait(0.2)
        else
            task.wait(0.6)
        end
    end
end)

-- Nasłuch na nowe pety w Workspace
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
                local targetPos = State.CurrentTarget and getBreakablePosition(State.CurrentTarget)
                pcall(updateWorkspacePetsPhysics, targetPos)
            end
        end)
        table.insert(ScriptConnections, petsChildAddedConn)
    end
end
task.spawn(bindPetsFolderListener)

-- // ==========================================================================
-- // 11. INTERFEJS UŻYTKOWNIKA MENUTEST
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
    State.AutoFarmEnabled = false
    State.OrbitCollectEnabled = false
    State.PlayerSpeedEnabled = false
    State.PetSpeedEnabled = false
    State.InfiniteJumpEnabled = false
    State.CurrentTarget = nil
    pcall(function()
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.WalkSpeed = 16
            hum.JumpPower = 50
        end
    end)
end

if typeof(getgenv) == "function" then
    getgenv()._PS99HalloweenCleanup = doCleanup
end
_G.PS99HalloweenCleanup = doCleanup

if Window and Window.ScreenGui then
    Window.ScreenGui.Destroying:Connect(doCleanup)
end

-- Wyłączenie limitera AntiFling dla płynnego ruchu
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

-- --------------------------------------------------------------------------
-- ZAKŁADKA 1: AUTO FARM (KOPANIE OBIEKTÓW)
-- --------------------------------------------------------------------------
local TabFarm = Window:CreateTab("Auto Farm", "zap")

local FarmModule = TabFarm:CreateModule({
    Name = "Auto Farm Obiektów",
    Description = "Automatyczne wysyłanie petów do kopania obiektów/coins na wybranej arenie",
    Default = false,
    CurrentValue = false,
    Flag = "Halloween_AutoFarm",
    Callback = function(val)
        State.AutoFarmEnabled = val
        if not val then
            State.CurrentTarget = nil
        end
    end
})

FarmModule:AddDropdown({
    Name = "Wybór Areny / Strefy",
    Options = {
        "Aktualna (Najbliższa)",
        "Wszystkie Areny (ALL)",
        "Zone 1",
        "Zone 2",
        "Zone 3",
        "Zone 4",
        "Zone 5",
        "Zone 6",
        "Zone 7",
        "Zone 8"
    },
    CurrentOption = {"Aktualna (Najbliższa)"},
    Default = "Aktualna (Najbliższa)",
    Flag = "Halloween_FarmZone",
    Callback = function(val)
        State.FarmZone = (type(val) == "table" and val[1]) or val
        State.CurrentTarget = nil
    end
})

FarmModule:AddDropdown({
    Name = "Priorytet Celu",
    Options = {
        "Najbliższe (Closest)",
        "Wszystko (ALL)",
        "Najwięcej HP (Boss / Big)",
        "Najmniej HP (Fast)"
    },
    CurrentOption = {"Najbliższe (Closest)"},
    Default = "Najbliższe (Closest)",
    Flag = "Halloween_FarmPriority",
    Callback = function(val)
        State.FarmPriority = (type(val) == "table" and val[1]) or val
    end
})

FarmModule:AddToggle({
    Name = "Nielimitowany Zasięg (Cała Strefa)",
    Default = true,
    CurrentValue = true,
    Flag = "Halloween_FarmInfRange",
    Callback = function(val)
        State.FarmInfiniteRange = val
    end
})

FarmModule:AddSlider({
    Name = "Zasięg Farmowania (gdy limit włączony)",
    Range = { 50, 2500 },
    CurrentValue = 800,
    Min = 50,
    Max = 2500,
    Default = 800,
    Suffix = " Studs",
    Flag = "Halloween_FarmRange",
    Callback = function(val)
        State.FarmRange = val
    end
})

FarmModule:AddSlider({
    Name = "Opóźnienie Pętli Ataku (Szybkość)",
    Range = { 0.05, 1.0 },
    CurrentValue = 0.15,
    Min = 0.05,
    Max = 1.0,
    Step = 0.05,
    Default = 0.15,
    Suffix = "s",
    Flag = "Halloween_AttackDelay",
    Callback = function(val)
        State.AttackDelay = val
    end
})

-- --------------------------------------------------------------------------
-- ZAKŁADKA 2: PETY & SPEED
-- --------------------------------------------------------------------------
local TabPets = Window:CreateTab("Pety & Speed", "wind")

local PetSpeedModule = TabPets:CreateModule({
    Name = "Pet Speed (Szybkość Petów)",
    Description = "Zwiększa szybkość przemieszczania i ataku petów na obiekty do kopania",
    Default = false,
    CurrentValue = false,
    DefaultKeybind = "X",
    Flag = "Halloween_PetSpeed",
    Callback = function(state)
        State.PetSpeedEnabled = state
        if state then
            pcall(hookPetSpeed)
            local targetPos = State.CurrentTarget and getBreakablePosition(State.CurrentTarget)
            pcall(updateWorkspacePetsPhysics, targetPos)
        end
    end
})

PetSpeedModule:AddSlider({
    Name = "Mnożnik Prędkości (Speed Multiplier)",
    Range = { 1, 100 },
    CurrentValue = 30,
    Min = 1,
    Max = 100,
    Default = 30,
    Suffix = "x",
    Flag = "Halloween_PetSpeedVal",
    Callback = function(val)
        State.PetSpeedValue = val
        if State.PetSpeedEnabled then
            pcall(hookPetSpeed)
            local targetPos = State.CurrentTarget and getBreakablePosition(State.CurrentTarget)
            pcall(updateWorkspacePetsPhysics, targetPos)
        end
    end
})

PetSpeedModule:AddToggle({
    Name = "Natychmiastowy Doskok do Celu (Instant Snap)",
    Default = true,
    CurrentValue = true,
    Flag = "Halloween_PetInstantSnap",
    Callback = function(state)
        State.PetInstantSnap = state
    end
})

PetSpeedModule:AddToggle({
    Name = "Wzmocniona Fizyka Petów (Max Force)",
    Default = true,
    CurrentValue = true,
    Flag = "Halloween_PetMaxForce",
    Callback = function(state)
        State.PetMaxForce = state
        if State.PetSpeedEnabled then
            local targetPos = State.CurrentTarget and getBreakablePosition(State.CurrentTarget)
            pcall(updateWorkspacePetsPhysics, targetPos)
        end
    end
})

local SpeedModule = TabPets:CreateModule({
    Name = "Prędkość Gracza (Player Speed)",
    Description = "Zaawansowany system prędkości gracza z ochroną przed resetowaniem",
    Default = false,
    CurrentValue = false,
    DefaultKeybind = "Z",
    Flag = "Halloween_PlayerSpeed",
    Callback = function(state)
        State.PlayerSpeedEnabled = state
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
    Flag = "Halloween_SpeedMode",
    Callback = function(val)
        local selected = (type(val) == "table" and val[1]) or val
        State.PlayerSpeedMode = selected
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
    Flag = "Halloween_SpeedVal",
    Callback = function(val)
        State.PlayerSpeedValue = val
        if State.PlayerSpeedEnabled and State.PlayerSpeedMode == "Normal" then
            pcall(function()
                local char = LocalPlayer.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if hum then hum.WalkSpeed = val end
            end)
        end
    end
})

SpeedModule:AddToggle({
    Name = "Infinite Jump (Skakanie w Powietrzu / do Góry)",
    Default = false,
    CurrentValue = false,
    Flag = "Halloween_InfiniteJump",
    Callback = function(val)
        State.InfiniteJumpEnabled = val
        pcall(function()
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then
                if val then
                    hum.UseJumpPower = true
                    hum.JumpPower = tonumber(State.JumpSpeedValue or 75) or 75
                else
                    hum.JumpPower = 50
                end
            end
        end)
    end
})

SpeedModule:AddSlider({
    Name = "Jump Speed (Siła Wyskoku do Góry)",
    Range = { 30, 350 },
    CurrentValue = 75,
    Min = 30,
    Max = 350,
    Default = 75,
    Suffix = " Studs/s",
    Flag = "Halloween_JumpSpeedVal",
    Callback = function(val)
        State.JumpSpeedValue = val
        if State.InfiniteJumpEnabled then
            pcall(function()
                local char = LocalPlayer.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if hum then
                    hum.UseJumpPower = true
                    hum.JumpPower = val
                end
            end)
        end
    end
})

-- --------------------------------------------------------------------------
-- ZAKŁADKA 3: AUTO COLLECT (ORBITY)
-- --------------------------------------------------------------------------
local TabOrbs = Window:CreateTab("Auto Collect", "circle")

local OrbitModule = TabOrbs:CreateModule({
    Name = "Auto Collect Orbits",
    Description = "Automatyczne zbieranie orbów z teleportowaniem ich bezpośrednio pod postać gracza",
    Default = false,
    CurrentValue = false,
    Flag = "Halloween_CollectOrbits",
    Callback = function(val)
        State.OrbitCollectEnabled = val
    end
})

OrbitModule:AddToggle({
    Name = "Teleportuj Orbity do Mnie (Instant TP)",
    Default = true,
    CurrentValue = true,
    Flag = "Halloween_OrbitTP",
    Callback = function(val)
        State.OrbitTeleportToMe = val
    end
})

OrbitModule:AddToggle({
    Name = "Nielimitowany Zasięg (Cała Mapa)",
    Default = true,
    CurrentValue = true,
    Flag = "Halloween_OrbitInfRange",
    Callback = function(val)
        State.OrbitInfiniteRange = val
    end
})

OrbitModule:AddSlider({
    Name = "Zasięg Zbierania (gdy limit włączony)",
    Range = { 50, 3000 },
    CurrentValue = 1000,
    Min = 50,
    Max = 3000,
    Default = 1000,
    Suffix = " Studs",
    Flag = "Halloween_OrbitRange",
    Callback = function(val)
        State.OrbitRange = val
    end
})

OrbitModule:AddSlider({
    Name = "Interwał Zbierania (Szybkość Pętli)",
    Range = { 0.05, 0.5 },
    CurrentValue = 0.1,
    Min = 0.05,
    Max = 0.5,
    Step = 0.05,
    Default = 0.1,
    Suffix = "s",
    Flag = "Halloween_OrbitInterval",
    Callback = function(val)
        State.OrbitInterval = val
    end
})

print("[PetHub] Pomyslnie zaladowano zaktualizowany skrypt Pet sim 99 event hallowen!")
