-- // ==========================================================================
-- // PROTECT KICK — blokada wyrzucania z gry (strona klienta)
-- // Blokuje wywołania Player:Kick / player.Kick wykonywane przez skrypty gry
-- // oraz inne skrypty w kliencie. Hook instaluje się raz, a włączanie i
-- // wyłączanie odbywa się flagą (bez zdejmowania hooka).
-- //
-- // UWAGA: nie da się zablokować kicka wysłanego bezpośrednio z serwera.
-- // Ten moduł chroni wyłącznie przed kickiem wywołanym po stronie klienta.
-- // ==========================================================================

local ProtectKick = {}

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local enabled = false
local hooksInstalled = false
local oldNamecall = nil
local oldIndex = nil

local function getNamecallMethod()
    local ok, method = pcall(function()
        return getnamecallmethod()
    end)
    if ok and type(method) == "string" then
        return method
    end
    return nil
end

local function installHooks()
    if hooksInstalled then return true end
    if type(hookmetamethod) ~= "function" then return false end

    local okNamecall = pcall(function()
        oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
            if enabled and getNamecallMethod() == "Kick" and self == LocalPlayer then
                return nil
            end
            return oldNamecall(self, ...)
        end)
    end)
    if not okNamecall then return false end

    -- Osobny hook __index blokuje wywołania w stylu player.Kick(player, msg).
    pcall(function()
        oldIndex = hookmetamethod(game, "__index", function(self, key)
            if enabled and key == "Kick" and self == LocalPlayer then
                return function() end
            end
            return oldIndex(self, key)
        end)
    end)

    hooksInstalled = true
    return true
end

function ProtectKick.IsEnabled()
    return enabled
end

function ProtectKick.Enable()
    if not installHooks() then
        return false, "executor nie wspiera hookmetamethod"
    end
    enabled = true
    return true
end

function ProtectKick.Disable()
    enabled = false
    return true
end

function ProtectKick.Toggle(state)
    if state == nil then state = not enabled end
    if state then
        return ProtectKick.Enable()
    end
    return ProtectKick.Disable()
end

return ProtectKick
