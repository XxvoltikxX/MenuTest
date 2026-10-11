local IconsModule = {}

-- Współdzielona pamięć podręczna dla bazy ikon (nigdy nie pobieraj 147 KB dwa razy!)
local IconsData = (typeof(getgenv) == "function" and getgenv()._MenuTestIconsData) or _G._MenuTestIconsData

if not IconsData then
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
                if s and data and #data > 0 then
                    content = data
                    break
                end
            end
        end
    end
    if not content then
        local ok, res = pcall(function()
            return game:HttpGet('https://raw.githubusercontent.com/xxCichyxx/MenuTest/refs/heads/main/src/icons/icons.lua')
        end)
        if ok and res then content = res end
    end

    if content then
        local chunk = loadstring(content)
        if chunk then
            IconsData = chunk()
            if typeof(getgenv) == "function" then getgenv()._MenuTestIconsData = IconsData end
            _G._MenuTestIconsData = IconsData
        end
    end
end

function IconsModule:getIcon(name)
    if not IconsData then return nil end
    name = string.match(string.lower(name), "^%s*(.*)%s*$")
    local sizedicons = IconsData['48px']
    local r = sizedicons and sizedicons[name]
    if not r then return nil end
    return {
        id = r[1], 
        imageRectSize = Vector2.new(r[2][1], r[2][2]), 
        imageRectOffset = Vector2.new(r[3][1], r[3][2])
    }
end

function IconsModule:Apply(obj, iconName)
    if not obj then return end
    local data = self:getIcon(iconName)
    if data and (obj:IsA("ImageLabel") or obj:IsA("ImageButton")) then
        obj.Image = "rbxassetid://" .. data.id
        obj.ImageRectSize = data.imageRectSize
        obj.ImageRectOffset = data.imageRectOffset
    end
end

if typeof(getgenv) == "function" then getgenv()._MenuTestIconsModule = IconsModule end
_G._MenuTestIconsModule = IconsModule

return IconsModule