--[[
    Kairo.Vehicle — Vehicle Keys client adapter.
    Adapters: qbx_vehiclekeys, qb-vehiclekeys, wasabi_carlock, Renewed-Vehiclekeys, cd_garage, standalone.
]]
local A = {}
local keysEnv = Kairo.Env.keys or { name = 'standalone' }
local adapter = keysEnv.name
local localKeys = {}

local function cleanPlate(p)
    if type(p) ~= 'string' then return '' end
    return p:match('^%s*(.-)%s*$')
end

function A.HasKeys(vehicleOrPlate)
    local plate = ''
    local vehicle = 0

    if type(vehicleOrPlate) == 'string' then
        plate = cleanPlate(vehicleOrPlate)
    elseif type(vehicleOrPlate) == 'number' and DoesEntityExist(vehicleOrPlate) then
        vehicle = vehicleOrPlate
        plate = cleanPlate(GetVehicleNumberPlateText(vehicleOrPlate))
    end

    if adapter == 'qbx' and exports.qbx_vehiclekeys then
        return exports.qbx_vehiclekeys:HasKeys(vehicle ~= 0 and vehicle or plate) == true
    elseif adapter == 'qb' and exports['qb-vehiclekeys'] then
        return exports['qb-vehiclekeys']:HasKeys(plate) == true
    elseif adapter == 'wasabi' and exports.wasabi_carlock then
        return exports.wasabi_carlock:haveKeys(vehicle ~= 0 and vehicle or plate) == true
    elseif adapter == 'renewed' and exports['Renewed-Vehiclekeys'] then
        return exports['Renewed-Vehiclekeys']:hasKey(vehicle ~= 0 and vehicle or plate) == true
    elseif adapter == 'cd' and exports['cd_garage'] then
        return exports['cd_garage']:GetKeys(plate) == true
    end

    -- Standalone check
    if localKeys[plate] then return true end
    if vehicle ~= 0 and DoesEntityExist(vehicle) then
        local st = Entity(vehicle).state
        local myId = Kairo.Framework.GetIdentifier()
        if st and st['kairo:keyOwner'] == myId then return true end
    end

    return false
end

function A.SetVehicleLock(vehicle, status)
    if not DoesEntityExist(vehicle) then return false end
    SetVehicleDoorsLocked(vehicle, status)
    SetVehicleDoorsLockedForAllPlayers(vehicle, status == 2)
    return true
end

function A.ToggleVehicleLock(vehicle)
    if not DoesEntityExist(vehicle) then return nil end
    local plate = cleanPlate(GetVehicleNumberPlateText(vehicle))
    if not A.HasKeys(vehicle) then
        Kairo.UI.Notify('You do not have keys to this vehicle.', 'error')
        return nil
    end

    local cur = GetVehicleDoorLockStatus(vehicle)
    local newStatus = (cur == 2 or cur == 4) and 1 or 2 -- 1 = unlocked, 2 = locked

    -- Play key fob animation
    local ped = PlayerPedId()
    local dict = 'anim@mp_player_intmenu@key_fob@'
    RequestAnimDict(dict)
    local timer = GetGameTimer() + 500
    while not HasAnimDictLoaded(dict) and GetGameTimer() < timer do Wait(10) end
    if HasAnimDictLoaded(dict) then
        TaskPlayAnim(ped, dict, 'fob_click', 8.0, -8.0, -1, 49, 0, false, false, false)
        RemoveAnimDict(dict)
    end

    -- Light flash & audio
    SetVehicleLights(vehicle, 2)
    PlaySoundFrontend(-1, 'BUTTON', 'MP_PROPERTIES_ELEVATOR_DOORS', 1)
    SetTimeout(300, function()
        if DoesEntityExist(vehicle) then SetVehicleLights(vehicle, 0) end
    end)

    A.SetVehicleLock(vehicle, newStatus)
    local isLocked = newStatus == 2
    Kairo.UI.Notify(isLocked and 'Vehicle locked.' or 'Vehicle unlocked.', isLocked and 'warning' or 'success')

    TriggerServerEvent('kairo:vehicle:syncLock', VehToNet(vehicle), newStatus)
    return isLocked
end

-- Server key grant event listener
RegisterNetEvent('kairo:vehicle:grantKeys', function(plate)
    plate = cleanPlate(plate)
    if plate ~= '' then localKeys[plate] = true end
end)

RegisterNetEvent('kairo:vehicle:revokeKeys', function(plate)
    plate = cleanPlate(plate)
    if plate ~= '' then localKeys[plate] = nil end
end)

return A
