--[[
    kairo-bridge server vehicle synchronization handler.
]]
RegisterNetEvent('kairo:vehicle:syncLock', function(netId, status)
    local src = source
    TriggerClientEvent('kairo:vehicle:syncLock', -1, netId, status)
end)
