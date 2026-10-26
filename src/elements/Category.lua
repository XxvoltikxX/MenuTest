-- // Alias dla Section.lua
local isDev = (typeof(getgenv) == "function" and getgenv()._MenuTestDevMode == true)
if isDev and typeof(readfile) == "function" then
    local candidates = {
        "MenuTest/src/elements/Section.lua",
        "src/elements/Section.lua",
        "Section.lua"
    }
    for _, path in ipairs(candidates) do
        if typeof(isfile) == "function" and isfile(path) then
            local ok, d = pcall(readfile, path)
            if ok and d and #d > 0 then
                local chunk = loadstring(d)
                if chunk then return chunk() end
            end
        end
    end
end

local url = "https://raw.githubusercontent.com/XxvoltikxX/MenuTest/refs/heads/main/src/elements/Section.lua"
local cb = "?_nocache=" .. tostring(os.time()) .. "_" .. tostring(math.random(10000, 99999))
local ok, res = pcall(function() return game:HttpGet(url .. cb) end)
if ok and res then
    local chunk = loadstring(res)
    if chunk then return chunk() end
end

return function(...) return {} end
