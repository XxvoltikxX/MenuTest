-- // ==========================================================================
-- // STEALTH — ukrywanie GUI przed skanerami gry
-- // 1. gethui() (jeśli executor go udostępnia) — kontener niewidoczny dla
-- //    LocalScriptów gry; dopiero potem CoreGui.
-- // 2. protect_gui / syn.protect_gui — dodatkowa ochrona, jeśli dostępna.
-- // 3. Losowe nazwy ScreenGui — bez sygnatur typu "Luminaq", "ESP", "Universal".
-- // 4. Wspólny, nieoczywisty magazyn sesji w getgenv (zamiast _Voltik*).
-- //
-- // UWAGA: to utrudnia wykrycie po stronie klienta (skanowanie PlayerGui /
-- // CoreGui). Nie ukryje zachowania serwerowego (WalkSpeed, statystyki) ani
-- // faktu użycia executora (HttpGet / loadstring / gethui).
-- // ==========================================================================

local Stealth = {}

Stealth.StoreKey = "_0x5a17"

local function randHex(len)
    local out = {}
    for i = 1, len do
        out[i] = string.format("%x", math.random(0, 15))
    end
    return table.concat(out)
end

function Stealth.RandomName(len)
    return randHex(len or 24)
end

-- Kontener, którego gra nie widzi. Celowo BEZ fallbacku do PlayerGui.
function Stealth.GetHiddenParent()
    local parent
    pcall(function()
        if type(gethui) == "function" then
            parent = gethui()
        end
    end)
    if parent then return parent end

    pcall(function()
        parent = game:GetService("CoreGui")
    end)
    return parent
end

function Stealth.Protect(gui)
    if not gui then return end
    pcall(function()
        if type(syn) == "table" and type(syn.protect_gui) == "function" then
            syn.protect_gui(gui)
        elseif type(protect_gui) == "function" then
            protect_gui(gui)
        elseif type(protectgui) == "function" then
            protectgui(gui)
        end
    end)
end

function Stealth.Adopt(gui, opts)
    opts = opts or {}

    gui.Name = opts.Name or Stealth.RandomName()
    gui.ResetOnSpawn = false
    if opts.DisplayOrder ~= nil then gui.DisplayOrder = opts.DisplayOrder end
    if opts.IgnoreGuiInset ~= nil then gui.IgnoreGuiInset = opts.IgnoreGuiInset end
    if opts.ZIndexBehavior ~= nil then gui.ZIndexBehavior = opts.ZIndexBehavior end

    -- Ochrona przed parentowaniem (kolejność ważna dla protect_gui).
    Stealth.Protect(gui)

    local parent = opts.Parent or Stealth.GetHiddenParent()
    if parent then
        pcall(function() gui.Parent = parent end)
    end
    if not gui.Parent then
        pcall(function() gui.Parent = game:GetService("CoreGui") end)
    end

    return gui.Parent ~= nil
end

function Stealth.NewScreenGui(opts)
    local gui = Instance.new("ScreenGui")
    Stealth.Adopt(gui, opts)
    return gui
end

function Stealth.StepName()
    return "r" .. randHex(18)
end

-- Wspólny magazyn między plikami (Loader / Main / Explorer / Window / gra).
function Stealth.Store()
    if type(getgenv) ~= "function" then return nil end
    local env = getgenv()
    local store = env[Stealth.StoreKey]
    if type(store) ~= "table" then
        store = {}
        env[Stealth.StoreKey] = store
    end
    return store
end

function Stealth.DestroyStored(key)
    local store = Stealth.Store()
    if not store then return end
    local gui = store[key]
    if gui then
        pcall(function() gui:Destroy() end)
    end
    store[key] = nil
end

return Stealth
