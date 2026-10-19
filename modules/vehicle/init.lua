--[[
    Kairo.Vehicle — Unified vehicle systems (Keys, Fuel, Properties, Plate Generation).

    SERVER:
      GiveKeys(src, vehicle|plate)      RemoveKeys(src, vehicle|plate)
      HasKeys(src, vehicle|plate)
      GeneratePlate(pattern?)           IsPlateTaken(plate)
      SetFuel(vehicle, amount)          GetFuel(vehicle)

    CLIENT:
      GetProperties(vehicle)            SetProperties(vehicle, props)
      GetFuel(vehicle)                  SetFuel(vehicle, amount)
      HasKeys(vehicle|plate)            SetLock(vehicle, status)
      ToggleLock(vehicle)
]]
local isServer = Kairo.IsServer
local Vehicle = {}

-- Load common properties helper
Vehicle.Props = Kairo.Require('modules/vehicle/props.lua')
Vehicle.GetProperties = Vehicle.Props.Get
Vehicle.SetProperties = Vehicle.Props.Set

if isServer then
    local keys = Kairo.Require('modules/vehicle/server/keys.lua')
    local plate = Kairo.Require('modules/vehicle/server/plate.lua')

    Vehicle.GiveKeys = keys.GiveKeys
    Vehicle.RemoveKeys = keys.RemoveKeys
    Vehicle.HasKeys = keys.HasKeys

    Vehicle.GeneratePlate = plate.GeneratePlate
    Vehicle.IsPlateTaken = plate.IsPlateTaken

    function Vehicle.SetFuel(entity, amount)
        if not DoesEntityExist(entity) then return false end
        amount = math.min(100.0, math.max(0.0, tonumber(amount) or 100.0))
        Entity(entity).state:set('kairo:fuel', amount, true)
        return true
    end

    function Vehicle.GetFuel(entity)
        if not DoesEntityExist(entity) then return 100.0 end
        local st = Entity(entity).state
        return (st and st['kairo:fuel']) or 100.0
    end

    return Vehicle
end

-- CLIENT
local fuel = Kairo.Require('modules/vehicle/client/fuel.lua')
local keys = Kairo.Require('modules/vehicle/client/keys.lua')

Vehicle.GetFuel = fuel.GetFuel
Vehicle.SetFuel = fuel.SetFuel

Vehicle.HasKeys = keys.HasKeys
Vehicle.SetLock = keys.SetVehicleLock
Vehicle.ToggleLock = keys.ToggleVehicleLock

return Vehicle
