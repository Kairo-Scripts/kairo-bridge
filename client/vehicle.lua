--[[
    kairo-bridge client vehicle synchronization handler.
]]
RegisterNetEvent('kairo:vehicle:syncLock', function(netId, status)
    if NetworkDoesNetworkIdExist(netId) then
        local veh = NetToVeh(netId)
        if DoesEntityExist(veh) then
            SetVehicleDoorsLocked(veh, status)
            SetVehicleDoorsLockedForAllPlayers(veh, status == 2)
        end
    end
end)
