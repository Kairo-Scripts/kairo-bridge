--[[
    Kairo.UI — Unified UI & interaction layer over ox_lib, framework-native (QB / ESX), and built-in NUI fallback.

    SERVER:
      Notify(src, message, type?, duration?)
      Broadcast(message, type?, duration?)

    CLIENT:
      Notify(message, type?, duration?)
      TextUI.Show(text, opts?)
      TextUI.Hide()
      TextUI.IsOpen() -> boolean
      ProgressBar(opts) -> boolean
      Input(header, rows) -> table|nil
      ContextMenu(data)
      Alert(opts) -> 'confirm' | 'cancel'
]]
local Log = Kairo.Log
local isServer = Kairo.IsServer
local UI = {}

if isServer then
    ---Send notification from server to player (or all players if src is -1)
    ---@param src number Target player source (-1 for all)
    ---@param message string|table Message text or data table
    ---@param typ? string 'info' | 'success' | 'warning' | 'error'
    ---@param duration? number Duration in ms
    function UI.Notify(src, message, typ, duration)
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

    ---Broadcast a notification to all connected players
    ---@param message string|table
    ---@param typ? string
    ---@param duration? number
    function UI.Broadcast(message, typ, duration)
        UI.Notify(-1, message, typ, duration)
    end

    return UI
end

-- CLIENT
local uiEnv = Kairo.Env.ui or { name = 'standalone' }
local adapterName = uiEnv.name

local ok, adapter = pcall(function()
    return Kairo.Require(('modules/ui/client/%s.lua'):format(adapterName))
end)

if not ok or not adapter then
    Log.warnOnce('ui-adapter-fallback', 'UI adapter "%s" could not be loaded; falling back to standalone NUI: %s', adapterName, tostring(adapter))
    adapterName = 'standalone'
    adapter = Kairo.Require('modules/ui/client/standalone.lua')
end

UI.Name = adapterName
UI.Resource = uiEnv.resource

local contract = { 'Notify', 'TextUI', 'ProgressBar', 'Input', 'ContextMenu', 'Alert' }
for _, name in ipairs(contract) do
    if adapter[name] == nil then
        Log.warnOnce('ui-missing:' .. name, 'UI adapter "%s" does not implement %s()', adapterName, name)
        if name == 'TextUI' then
            adapter.TextUI = {
                Show = function() end,
                Hide = function() end,
                IsOpen = function() return false end,
            }
        else
            adapter[name] = function() return false end
        end
    end
end

for k, v in pairs(adapter) do
    UI[k] = v
end

return UI
