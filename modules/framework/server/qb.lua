local QBCore
local function core()
    if not QBCore then QBCore = exports['qb-core']:GetCoreObject() end
    return QBCore
end

AddEventHandler('onResourceStop', function(res)
    if res == 'qb-core' then QBCore = nil end
end)

return Kairo.Require('modules/framework/server/qb_family.lua')({
    name = 'qb',
    getPlayer = function(src) return core().Functions.GetPlayer(src) end,
    getPlayers = function() return core().Functions.GetQBPlayers() end,
    getByIdentifier = function(id) return core().Functions.GetPlayerByCitizenId(id) end,
    hasPermission = function(src, group) return core().Functions.HasPermission(src, group) end,
})
