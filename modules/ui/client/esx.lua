--[[
    Kairo.UI — ESX UI client adapter.
    Uses ESX notifications / TextUI when available, falling back to built-in NUI.
]]
local A = {}
local bridge = 'kairo-bridge'

local ESX
local function core()
    if not ESX then
        local ok, res = pcall(function() return exports['es_extended']:getSharedObject() end)
        if ok and res then ESX = res end
    end
    return ESX
end
AddEventHandler('onResourceStop', function(res)
    if res == 'es_extended' then ESX = nil end
end)

function A.Notify(message, typ, duration)
    local text = type(message) == 'table' and (message.description or message.title or message.message) or tostring(message)
    typ = typ or (type(message) == 'table' and message.type) or 'info'
    duration = duration or (type(message) == 'table' and message.duration) or 4000

    local c = core()
    if c and c.ShowNotification then
        c.ShowNotification(text, typ, duration)
    else
        TriggerEvent('esx:showNotification', text, typ, duration)
    end
end

local isTextOpen = false
A.TextUI = {
    Show = function(text, opts)
        isTextOpen = true
        local c = core()
        if c and c.TextUI then
            c.TextUI(text, opts and opts.type or 'info')
        else
            exports[bridge]:NUI_ShowTextUI(text, opts)
        end
    end,
    Hide = function()
        isTextOpen = false
        local c = core()
        if c and c.HideUI then
            c.HideUI()
        else
            exports[bridge]:NUI_HideTextUI()
        end
    end,
    IsOpen = function()
        return isTextOpen
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
