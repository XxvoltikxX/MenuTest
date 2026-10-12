-- // ==========================================================================
-- // MenuTest - EmoteMenu Controller Module
-- // Manages the full Emotes & Animations Overlay System (OpenEmote + Emotes)
-- // ==========================================================================

local EmoteMenu = {}

local baseUrl = "https://raw.githubusercontent.com/xxCichyxx/MenuTest/refs/heads/main/src/emotes/"

local function sendNotification(title, content)
    local sent = false
    if typeof(getgenv) == "function" and getgenv().Notify then
        pcall(function()
            getgenv().Notify({
                Title = title,
                Content = content,
                Duration = 5
            })
            sent = true
        end)
    end
    if not sent then
        pcall(function()
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = title,
                Text = content,
                Duration = 5
            })
        end)
    end
end

local function safeLoadSub(relPath, remoteUrl)
    local isDev = (typeof(getgenv) == "function" and getgenv()._MenuTestDevMode == true)
    if isDev and typeof(readfile) == "function" then
        local candidates = {
            "MenuTest/src/emotes/" .. relPath,
            "src/emotes/" .. relPath,
            "MenuTest/src/" .. relPath,
            "src/" .. relPath,
            relPath
        }
        for _, c in ipairs(candidates) do
            if typeof(isfile) == "function" and isfile(c) then
                local s, data = pcall(readfile, c)
                if s and data and #data > 0 then
                    local chunk = loadstring(data)
                    if chunk then return chunk() end
                end
            end
        end
    end
    local cacheBuster = (remoteUrl:find("%?") and "&" or "?") .. "_nocache=" .. tostring(os.time()) .. "_" .. tostring(math.random(10000, 99999))
    local ok, res = pcall(function() return game:HttpGet(remoteUrl .. cacheBuster) end)
    if ok and res then
        local chunk = loadstring(res)
        if chunk then return chunk() end
    end
    return nil
end

local isLoaded = false

function EmoteMenu:Load()
    isLoaded = true
    _G.MenuTest_EmotesEnabled = true

    -- Ensure Roblox Emotes Menu is enabled in StarterGui
    pcall(function()
        game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu, true)
    end)

    if _G.MenuTest_EmotesController and _G.MenuTest_EmotesController.Enable then
        pcall(function() _G.MenuTest_EmotesController.Enable() end)
        sendNotification("MenuTest | Emotes", "Emotes Menu wlaczone! Wcisnij [.] lub uzyj przycisku HUD")
        return _G.MenuTest_EmotesController
    end

    -- First time loading: execute Emotes.lua (which also loads OpenEmote.lua, SettingsLib, Notify)
    local controller = safeLoadSub("Emotes.lua", baseUrl .. "Emotes.lua")
    if controller and typeof(controller) == "table" and controller.Enable then
        pcall(function() controller.Enable() end)
    end

    sendNotification("MenuTest | Emotes", "Emotes Menu zaladowane! Wcisnij [.] lub uzyj przycisku HUD")
    return controller or _G.MenuTest_EmotesController
end

function EmoteMenu:Unload()
    isLoaded = false
    _G.MenuTest_EmotesEnabled = false

    if _G.MenuTest_EmotesController and _G.MenuTest_EmotesController.Disable then
        pcall(function() _G.MenuTest_EmotesController.Disable() end)
    else
        pcall(function()
            local GuiService = game:GetService("GuiService")
            GuiService:SetEmotesMenuOpen(false)
        end)
        if _G.MenuTest_OpenEmoteGui then
            _G.MenuTest_OpenEmoteGui.Enabled = false
        end
    end
    sendNotification("MenuTest | Emotes", "Emotes Menu wylaczone")
end

function EmoteMenu:Toggle(state)
    if state then
        return EmoteMenu:Load()
    else
        return EmoteMenu:Unload()
    end
end

return EmoteMenu
