-- // ==========================================================================
-- // PROTECTIONS — STRIKE FORCE
-- // Osobna klasa ochron dla gry Strike Force. Nie miesza się z innymi grami:
-- // każda gra ma własny plik w src/protections/<Gra>.lua i własne opcje.
-- //
-- // Opcje:
-- //   Protect Kick — blokuje Player:Kick / player.Kick po stronie klienta.
-- //   AntiBan      — blokuje Kick, game:Shutdown oraz teleport na inny place
-- //                  (typową drogę do "ban place"), nie ruszając teleportów
-- //                  w obrębie tego samego PlaceId.
-- //
-- // UWAGA: serwerowy ban/kick nie da się zablokować po stronie klienta.
-- // ==========================================================================

return function(ctx)
    ctx = ctx or {}
    local Core = ctx.Core

    local module = {
        Id          = "StrikeForce",
        Name        = "Strike Force",
        Description = "Ochrona klienta dla Strike Force",
        Options     = {},
    }

    if type(Core) ~= "table" then
        -- Bez silnika hooków opcje nadal istnieją, ale zgłoszą błąd.
        local function unsupported()
            return false, "Brak silnika hooków (Core)"
        end
        module.Options = {
            { Id = "Kick", Name = "Protect Kick", OnToggle = unsupported },
            { Id = "AntiBan", Name = "AntiBan", OnToggle = unsupported },
        }
        return module
    end

    local LocalPlayer = Core.LocalPlayer

    local kickOn = false
    local banOn = false

    local TELEPORT_METHODS = {
        Teleport = true,
        TeleportAsync = true,
        TeleportToPlaceInstance = true,
        TeleportToPrivateServer = true,
        TeleportPartyAsync = true,
    }

    local function kickNamecall(self, method)
        if method == "Kick" and self == LocalPlayer then
            return true, nil
        end
        return false
    end

    local function kickIndex(self, key)
        if key == "Kick" and self == LocalPlayer then
            return true, function() end
        end
        return false
    end

    local function banNamecall(self, method, ...)
        if method == "Kick" and self == LocalPlayer then
            return true, nil
        end
        if method == "Shutdown" and self == game then
            return true, nil
        end
        if TELEPORT_METHODS[method] then
            local placeId = select(1, ...)
            if type(placeId) == "number" and placeId ~= game.PlaceId then
                return true, nil
            end
        end
        return false
    end

    local function apply(id, namecall, index)
        local ok, err = Core.SetNamecall(id, namecall)
        if not ok then return false, err end
        if index then
            ok, err = Core.SetIndex(id, index)
            if not ok then
                Core.ClearNamecall(id)
                return false, err
            end
        end
        return true
    end

    local function remove(id)
        Core.ClearNamecall(id)
        Core.ClearIndex(id)
    end

    local function sync()
        if kickOn then
            local ok, err = apply("StrikeForce.Kick", kickNamecall, kickIndex)
            if not ok then kickOn = false; return false, err end
        else
            remove("StrikeForce.Kick")
        end

        if banOn then
            local ok, err = apply("StrikeForce.AntiBan", banNamecall, kickIndex)
            if not ok then banOn = false; return false, err end
        else
            remove("StrikeForce.AntiBan")
        end

        return true
    end

    module.Options = {
        {
            Id          = "Kick",
            Name        = "Protect Kick",
            Description = "Blokuje Player:Kick po stronie klienta",
            OnToggle    = function(state)
                local previous = kickOn
                kickOn = state == true
                local ok, err = sync()
                if not ok then
                    kickOn = previous
                    sync()
                    return false, err
                end
                return true
            end,
        },
        {
            Id          = "AntiBan",
            Name        = "AntiBan",
            Description = "Blokuje Kick, Shutdown i teleport na inny place",
            OnToggle    = function(state)
                local previous = banOn
                banOn = state == true
                local ok, err = sync()
                if not ok then
                    banOn = previous
                    sync()
                    return false, err
                end
                return true
            end,
        },
    }

    return module
end
