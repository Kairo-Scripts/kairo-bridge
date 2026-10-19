local QBCore
local function core()
    if not QBCore then QBCore = exports['qb-core']:GetCoreObject() end
    return QBCore
end
AddEventHandler('onResourceStop', function(res)
    if res == 'qb-core' then QBCore = nil end
end)

return Kairo.Require('modules/framework/client/qb_family.lua')({
    getPlayerData = function() return core().Functions.GetPlayerData() end,
})
