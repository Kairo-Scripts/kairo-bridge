--[[
    kairo-bridge server services dispatcher.
    Handles client-to-server dispatch alerts and appearance persistence.
]]
RegisterNetEvent('kairo:dispatch:serverAlert', function(data)
    local src = source
    if type(data) == 'table' then
        if not data.coords then
            local ped = GetPlayerPed(src)
            if DoesEntityExist(ped) then data.coords = GetEntityCoords(ped) end
        end
        Kairo.Dispatch.SendAlert(data)
    end
end)

RegisterNetEvent('kairo:appearance:save', function(data)
    local src = source
    if type(data) == 'table' then
        Kairo.Appearance.SaveAppearance(src, data)
    end
end)
