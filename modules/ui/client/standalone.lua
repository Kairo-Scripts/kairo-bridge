--[[
    Kairo.UI — Standalone / Built-in NUI fallback adapter.
    Uses kairo-bridge's built-in NUI exports for 100% zero-dependency UI.
]]
local A = {}
local bridge = 'kairo-bridge'

function A.Notify(message, typ, duration)
    local data
    if type(message) == 'table' then
        data = message
    else
        data = { description = tostring(message), type = typ or 'info', duration = duration or 4000 }
    end
    exports[bridge]:NUI_Notify(data)
end

A.TextUI = {
    Show = function(text, opts)
        exports[bridge]:NUI_ShowTextUI(text, opts)
    end,
    Hide = function()
        exports[bridge]:NUI_HideTextUI()
    end,
    IsOpen = function()
        return exports[bridge]:NUI_IsTextUIOpen()
    end,
}

function A.ProgressBar(opts)
    return exports[bridge]:NUI_ProgressBar(opts)
end

function A.Input(header, rows)
    return exports[bridge]:NUI_Input(header, rows)
end

function A.ContextMenu(data)
    return exports[bridge]:NUI_ContextMenu(data)
end

function A.Alert(opts)
    return exports[bridge]:NUI_Alert(opts)
end

return A
