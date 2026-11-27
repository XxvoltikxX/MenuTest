-- // ==========================================================================
-- // PROTECTIONS CORE — wspólny silnik hooków dla klas ochron gier
-- // Jeden hook __namecall i __index obsługuje wszystkie gry; każda gra ma
-- // własną klasę w src/protections/<Gra>.lua i rejestruje swoje handlery.
-- //
-- // Kontrakt handlera __namecall:
-- //   fn(self, method, ...) -> true, wynik   (blokuje i zwraca wynik)
-- //                         -> false          (przepuszcza dalej)
-- //
-- // Kontrakt handlera __index:
-- //   fn(self, key) -> true, wartość          (nadpisuje odczyt)
-- //                 -> false                 (przepuszcza dalej)
-- // ==========================================================================

local Core = {}

local Players = game:GetService("Players")
Core.LocalPlayer = Players.LocalPlayer

local namecallHandlers = {}
local indexHandlers = {}
local namecallOrder = {}
local indexOrder = {}

local installed = false
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

local function install()
    if installed then return true end
    if type(hookmetamethod) ~= "function" then return false end

    local ok = pcall(function()
        oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
            local method = getNamecallMethod()
            for _, id in ipairs(namecallOrder) do
                local handler = namecallHandlers[id]
                if handler then
                    local handled, result = handler(self, method, ...)
                    if handled then return result end
                end
            end
            return oldNamecall(self, ...)
        end)
    end)
    if not ok then return false end

    pcall(function()
        oldIndex = hookmetamethod(game, "__index", function(self, key)
            for _, id in ipairs(indexOrder) do
                local handler = indexHandlers[id]
                if handler then
                    local handled, result = handler(self, key)
                    if handled then return result end
                end
            end
            return oldIndex(self, key)
        end)
    end)

    installed = true
    return true
end

local function register(handlers, order, id, fn)
    if type(fn) ~= "function" then return false, "handler musi być funkcją" end
    if not install() then return false, "executor nie wspiera hookmetamethod" end
    if not handlers[id] then
        table.insert(order, id)
    end
    handlers[id] = fn
    return true
end

local function unregister(handlers, order, id)
    handlers[id] = nil
    for i = #order, 1, -1 do
        if order[i] == id then
            table.remove(order, i)
        end
    end
end

function Core.SetNamecall(id, fn)
    return register(namecallHandlers, namecallOrder, id, fn)
end

function Core.ClearNamecall(id)
    unregister(namecallHandlers, namecallOrder, id)
end

function Core.SetIndex(id, fn)
    return register(indexHandlers, indexOrder, id, fn)
end

function Core.ClearIndex(id)
    unregister(indexHandlers, indexOrder, id)
end

function Core.ClearAll(prefix)
    prefix = tostring(prefix or "")
    local ids = {}
    for id in pairs(namecallHandlers) do
        if prefix == "" or tostring(id):sub(1, #prefix) == prefix then
            table.insert(ids, id)
        end
    end
    for _, id in ipairs(ids) do Core.ClearNamecall(id) end

    ids = {}
    for id in pairs(indexHandlers) do
        if prefix == "" or tostring(id):sub(1, #prefix) == prefix then
            table.insert(ids, id)
        end
    end
    for _, id in ipairs(ids) do Core.ClearIndex(id) end
end

function Core.IsSupported()
    return type(hookmetamethod) == "function"
end

function Core.Installed()
    return installed
end

return Core
