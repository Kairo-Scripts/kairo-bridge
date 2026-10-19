return Kairo.Require('modules/framework/server/qb_family.lua')({
    name = 'qbox',
    getPlayer = function(src) return exports.qbx_core:GetPlayer(src) end,
    getPlayers = function() return exports.qbx_core:GetQBPlayers() end,
    getByIdentifier = function(id) return exports.qbx_core:GetPlayerByCitizenId(id) end,
    hasPermission = function(src, group) return exports.qbx_core:HasPermission(src, group) end,
})
