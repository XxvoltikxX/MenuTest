-- // ==========================================================================
-- // PROTECTIONS — UNIVERSAL
-- // Osobna klasa ochron dla gry Universal (nie miesza się ze Strike Force).
-- // ==========================================================================

return function(ctx)
    ctx = ctx or {}
    local Core = ctx.Core

    local module = {
        Id          = "Universal",
        Name        = "Universal",
        Description = "Ochrona klienta dla Universal",
        Options     = {},
    }

    if type(Core) ~= "table" then
        module.Options = {
            {
                Id = "Kick",
                Name = "Protect Kick",
                OnToggle = function()
                    return false, "Brak silnika hooków (Core)"
                end,
            },
        }
        return module
    end

    local LocalPlayer = Core.LocalPlayer
    local kickOn = false

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

    local function sync()
        if kickOn then
            local ok, err = Core.SetNamecall("Universal.Kick", kickNamecall)
            if not ok then kickOn = false; return false, err end
            ok, err = Core.SetIndex("Universal.Kick", kickIndex)
            if not ok then
                Core.ClearNamecall("Universal.Kick")
                kickOn = false
                return false, err
            end
        else
            Core.ClearNamecall("Universal.Kick")
            Core.ClearIndex("Universal.Kick")
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
    }

    return module
end
