--[[
    Kairo.Vehicle — Vehicle Keys server module.
    Adapters: qbx_vehiclekeys, qb-vehiclekeys, wasabi_carlock, Renewed-Vehiclekeys, standalone.
]]
local A = {}
local keysEnv = Kairo.Env.keys or { name = 'standalone' }
local adapter = keysEnv.name
local serverKeyStore = {} -- [identifier] = { [plate] = true }

local function cleanPlate(p)
    if type(p) ~= 'string' then return '' end
    return p:match('^%s*(.-)%s*$')
end

function A.GiveKeys(src, vehicleOrPlate)
    src = tonumber(src)
    if not src then return false end

    local plate = ''
    local entity = 0
    if type(vehicleOrPlate) == 'string' then
        plate = cleanPlate(vehicleOrPlate)
    elseif type(vehicleOrPlate) == 'number' and DoesEntityExist(vehicleOrPlate) then
        entity = vehicleOrPlate
        plate = cleanPlate(GetVehicleNumberPlateText(vehicleOrPlate))
    end
    if plate == '' then return false end

    if adapter == 'qbx' and exports.qbx_vehiclekeys then
        exports.qbx_vehiclekeys:GiveKeys(src, plate)
        return true
    elseif adapter == 'qb' then
        TriggerClientEvent('qb-vehiclekeys:client:AddKeys', src, plate)
        return true
    elseif adapter == 'wasabi' and exports.wasabi_carlock then
        exports.wasabi_carlock:giveKeys(src, plate)
        return true
    elseif adapter == 'renewed' and exports['Renewed-Vehiclekeys'] then
        exports['Renewed-Vehiclekeys']:addKey(src, plate)
        return true
    end

    -- Standalone handling
    local id = Kairo.Framework.GetIdentifier(src)
    if id then
        serverKeyStore[id] = serverKeyStore[id] or {}
        serverKeyStore[id][plate] = true
    end

    if entity ~= 0 and DoesEntityExist(entity) then
        local st = Entity(entity).state
        if st and id then st:set('kairo:keyOwner', id, true) end
    end

    TriggerClientEvent('kairo:vehicle:grantKeys', src, plate)
    return true
end

function A.RemoveKeys(src, vehicleOrPlate)
    src = tonumber(src)
    if not src then return false end

    local plate = ''
    if type(vehicleOrPlate) == 'string' then
        plate = cleanPlate(vehicleOrPlate)
    elseif type(vehicleOrPlate) == 'number' and DoesEntityExist(vehicleOrPlate) then
        plate = cleanPlate(GetVehicleNumberPlateText(vehicleOrPlate))
    end
    if plate == '' then return false end

    if adapter == 'qbx' and exports.qbx_vehiclekeys then
        exports.qbx_vehiclekeys:RemoveKeys(src, plate)
        return true
    elseif adapter == 'qb' then
        TriggerClientEvent('qb-vehiclekeys:client:RemoveKeys', src, plate)
        return true
    elseif adapter == 'renewed' and exports['Renewed-Vehiclekeys'] then
        exports['Renewed-Vehiclekeys']:removeKey(src, plate)
        return true
    end

    local id = Kairo.Framework.GetIdentifier(src)
    if id and serverKeyStore[id] then
        serverKeyStore[id][plate] = nil
    end

    TriggerClientEvent('kairo:vehicle:revokeKeys', src, plate)
    return true
end

function A.HasKeys(src, vehicleOrPlate)
    src = tonumber(src)
    if not src then return false end

    local plate = ''
    if type(vehicleOrPlate) == 'string' then
        plate = cleanPlate(vehicleOrPlate)
    elseif type(vehicleOrPlate) == 'number' and DoesEntityExist(vehicleOrPlate) then
        plate = cleanPlate(GetVehicleNumberPlateText(vehicleOrPlate))
    end

    local id = Kairo.Framework.GetIdentifier(src)
    if id and serverKeyStore[id] and serverKeyStore[id][plate] then
        return true
    end

    return false
end

return A
