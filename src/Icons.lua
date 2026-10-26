local IconsModule = {}

-- Wbudowane awaryjne ikony Roblox Lucide (gwarantują 100% niezawodność, nawet przy opóźnieniu pobierania bazy)
local FallbackIcons = {
    ["user"]             = { id = "10747373176", rectSize = Vector2.new(36, 36), rectOffset = Vector2.new(0, 0) },
    ["eye"]              = { id = "10723346959", rectSize = Vector2.new(36, 36), rectOffset = Vector2.new(0, 0) },
    ["wrench"]           = { id = "10734983868", rectSize = Vector2.new(36, 36), rectOffset = Vector2.new(0, 0) },
    ["wind"]             = { id = "10734983400", rectSize = Vector2.new(36, 36), rectOffset = Vector2.new(0, 0) },
    ["zap"]              = { id = "10734984940", rectSize = Vector2.new(36, 36), rectOffset = Vector2.new(0, 0) },
    ["plane"]            = { id = "10734934585", rectSize = Vector2.new(36, 36), rectOffset = Vector2.new(0, 0) },
    ["box"]              = { id = "10709791437", rectSize = Vector2.new(36, 36), rectOffset = Vector2.new(0, 0) },
    ["crosshair"]        = { id = "10709798950", rectSize = Vector2.new(36, 36), rectOffset = Vector2.new(0, 0) },
    ["mouse-pointer"]    = { id = "10734898355", rectSize = Vector2.new(36, 36), rectOffset = Vector2.new(0, 0) },
    ["settings"]         = { id = "10734950309", rectSize = Vector2.new(36, 36), rectOffset = Vector2.new(0, 0) },
    ["sliders"]          = { id = "10734952409", rectSize = Vector2.new(36, 36), rectOffset = Vector2.new(0, 0) },
    ["shield"]           = { id = "10734951847", rectSize = Vector2.new(36, 36), rectOffset = Vector2.new(0, 0) },
    ["folder"]           = { id = "10723387563", rectSize = Vector2.new(36, 36), rectOffset = Vector2.new(0, 0) },
    ["layers"]           = { id = "10723415766", rectSize = Vector2.new(36, 36), rectOffset = Vector2.new(0, 0) },
    ["minus"]            = { id = "10734896206", rectSize = Vector2.new(36, 36), rectOffset = Vector2.new(0, 0) },
    ["square"]           = { id = "10734954248", rectSize = Vector2.new(36, 36), rectOffset = Vector2.new(0, 0) },
    ["maximize-2"]       = { id = "10734887852", rectSize = Vector2.new(36, 36), rectOffset = Vector2.new(0, 0) },
    ["x"]                = { id = "10747384394", rectSize = Vector2.new(36, 36), rectOffset = Vector2.new(0, 0) },
    ["arrow-down-right"] = { id = "10709790948", rectSize = Vector2.new(36, 36), rectOffset = Vector2.new(0, 0) },
    ["chevron-down"]     = { id = "10709790948", rectSize = Vector2.new(36, 36), rectOffset = Vector2.new(0, 0) },
    ["menu"]             = { id = "10734895856", rectSize = Vector2.new(36, 36), rectOffset = Vector2.new(0, 0) },
    ["sun"]              = { id = "10734961532", rectSize = Vector2.new(36, 36), rectOffset = Vector2.new(0, 0) },
    ["moon"]             = { id = "10734897102", rectSize = Vector2.new(36, 36), rectOffset = Vector2.new(0, 0) },
    ["palette"]          = { id = "10734918430", rectSize = Vector2.new(36, 36), rectOffset = Vector2.new(0, 0) },
    ["refresh-cw"]       = { id = "10734940376", rectSize = Vector2.new(36, 36), rectOffset = Vector2.new(0, 0) },
    ["arrow-up-circle"]  = { id = "10709791437", rectSize = Vector2.new(36, 36), rectOffset = Vector2.new(0, 0) }
}

-- Sprawdź pamięć podręczną; upewnij się, że nie jest pustą tabelą ani nil
local IconsData = (typeof(getgenv) == "function" and getgenv()._MenuTestIconsData) or _G._MenuTestIconsData
if type(IconsData) ~= "table" or not IconsData["48px"] then
    IconsData = nil
    if typeof(getgenv) == "function" then getgenv()._MenuTestIconsData = nil end
    _G._MenuTestIconsData = nil
end

local function loadFullIconsData()
    if IconsData and IconsData["48px"] then return IconsData end

    local content = nil
    if typeof(readfile) == "function" then
        local candidates = {
            "MenuTest/src/icons/icons.lua",
            "src/icons/icons.lua",
            "icons.lua"
        }
        for _, path in ipairs(candidates) do
            if typeof(isfile) == "function" and isfile(path) then
                local s, data = pcall(readfile, path)
                if s and data and #data > 1000 then
                    content = data
                    break
                end
            end
        end
    end

    if not content then
        local cacheBuster = "?_nocache=" .. tostring(os.time()) .. "_" .. tostring(math.random(1000, 9999))
        local url = "https://raw.githubusercontent.com/XxvoltikxX/MenuTest/refs/heads/main/src/icons/icons.lua" .. cacheBuster
        for attempt = 1, 3 do
            local ok, res = pcall(function() return game:HttpGet(url) end)
            if ok and res and type(res) == "string" and #res > 1000 and not res:find("404: Not Found") then
                content = res
                break
            end
            task.wait(0.3)
        end
    end

    if content then
        local chunk = loadstring(content)
        if chunk then
            local runOk, loaded = pcall(chunk)
            if runOk and type(loaded) == "table" and loaded["48px"] then
                IconsData = loaded
                if typeof(getgenv) == "function" then getgenv()._MenuTestIconsData = IconsData end
                _G._MenuTestIconsData = IconsData
                return IconsData
            end
        end
    end

    return nil
end

-- Pobierz bazę ikon natychmiast lub asynchronicznie
IconsData = loadFullIconsData()
if not IconsData then
    task.spawn(function()
        task.wait(1)
        loadFullIconsData()
    end)
end

function IconsModule:getIcon(name)
    if not name then return nil end
    name = string.match(string.lower(tostring(name)), "^%s*(.*)%s*$")
    
    -- 1. Sprawdź pełną bazę 48px
    if IconsData and IconsData["48px"] then
        local r = IconsData["48px"][name]
        if r then
            return {
                id = r[1],
                imageRectSize = Vector2.new(r[2][1], r[2][2]),
                imageRectOffset = Vector2.new(r[3][1], r[3][2])
            }
        end
    end

    -- 2. Sprawdź fallback natychmiastowy
    local fb = FallbackIcons[name]
    if fb then
        return {
            id = fb.id,
            imageRectSize = fb.rectSize,
            imageRectOffset = fb.rectOffset
        }
    end

    return nil
end

function IconsModule:Apply(obj, iconName)
    if not obj or not iconName then return end
    local data = self:getIcon(iconName)
    if data and (obj:IsA("ImageLabel") or obj:IsA("ImageButton")) then
        obj.Image = "rbxassetid://" .. tostring(data.id)
        if data.imageRectSize and data.imageRectSize.X > 0 then
            obj.ImageRectSize = data.imageRectSize
            obj.ImageRectOffset = data.imageRectOffset
        else
            obj.ImageRectSize = Vector2.new(0, 0)
            obj.ImageRectOffset = Vector2.new(0, 0)
        end
    else
        -- Jeśli brak ikony, spróbuj pobrać bazę w tle i zaaplikować
        task.spawn(function()
            if not IconsData then
                loadFullIconsData()
                local retryData = IconsModule:getIcon(iconName)
                if retryData and obj and obj.Parent then
                    obj.Image = "rbxassetid://" .. tostring(retryData.id)
                    if retryData.imageRectSize and retryData.imageRectSize.X > 0 then
                        obj.ImageRectSize = retryData.imageRectSize
                        obj.ImageRectOffset = retryData.imageRectOffset
                    end
                end
            end
        end)
    end
end

if typeof(getgenv) == "function" then getgenv()._MenuTestIconsModule = IconsModule end
_G._MenuTestIconsModule = IconsModule

return IconsModule