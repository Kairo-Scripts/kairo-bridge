--[[
    Kairo.Vehicle — Fuel client adapter.
    Adapters: ox_fuel, cdn-fuel, ps-fuel, LegacyFuel, standalone native.
]]
local A = {}
local fuelEnv = Kairo.Env.fuel or { name = 'standalone' }
local adapter = fuelEnv.name

function A.GetFuel(vehicle)
    if not DoesEntityExist(vehicle) then return 0.0 end

    if adapter == 'ox' and exports.ox_fuel then
        return exports.ox_fuel:GetFuel(vehicle) or 0.0
    elseif adapter == 'cdn' and exports['cdn-fuel'] then
        return exports['cdn-fuel']:GetFuel(vehicle) or 0.0
    elseif adapter == 'ps' and exports['ps-fuel'] then
        return exports['ps-fuel']:GetFuel(vehicle) or 0.0
    elseif adapter == 'legacy' and exports['LegacyFuel'] then
        return exports['LegacyFuel']:GetFuel(vehicle) or 0.0
    end

    -- Standalone / native fallback
    local state = Entity(vehicle).state
    if state and state['kairo:fuel'] ~= nil then
        return state['kairo:fuel']
    end
    return GetVehicleFuelLevel(vehicle) or 100.0
end

function A.SetFuel(vehicle, amount)
    if not DoesEntityExist(vehicle) then return false end
    amount = tonumber(amount) or 100.0
    amount = math.min(100.0, math.max(0.0, amount))

    if adapter == 'ox' and exports.ox_fuel then
        exports.ox_fuel:SetFuel(vehicle, amount)
        return true
    elseif adapter == 'cdn' and exports['cdn-fuel'] then
        exports['cdn-fuel']:SetFuel(vehicle, amount)
        return true
    elseif adapter == 'ps' and exports['ps-fuel'] then
        exports['ps-fuel']:SetFuel(vehicle, amount)
        return true
    elseif adapter == 'legacy' and exports['LegacyFuel'] then
        exports['LegacyFuel']:SetFuel(vehicle, amount)
        return true
    end

    -- Standalone native
    SetVehicleFuelLevel(vehicle, amount + 0.0)
    local state = Entity(vehicle).state
    if state then
        state:set('kairo:fuel', amount, true)
    end
    return true
end

return A
