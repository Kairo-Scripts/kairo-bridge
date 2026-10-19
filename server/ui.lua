--[[
    kairo-bridge server UI handler.
    Provides server-side notification forwarding to clients.
]]
local Log = Kairo.Log

---Send a notification to a specific client or all clients (-1).
---@param src number Target player source, or -1 for all players
---@param message string|table Notification message or table
---@param typ? string 'info' | 'success' | 'warning' | 'error'
---@param duration? number Duration in ms
local function notify(src, message, typ, duration)
    src = tonumber(src) or -1
    local data
    if type(message) == 'table' then
        data = message
    else
        data = {
            description = tostring(message),
            type = typ or 'info',
            duration = duration or 4000,
        }
    end

    TriggerClientEvent('kairo:ui:notify', src, data)
end

exports('Notify', notify)
RegisterNetEvent('kairo:server:notify', notify)
