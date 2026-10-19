# Vehicle Module (`Kairo.Vehicle`)

Handles complete vehicle properties serialization, fuel adapters, vehicle key management, plate generation, and database garage persistence.

---

## 1. Vehicle Properties (`props.lua`)

Kairo Bridge handles 50+ GTA vehicle modifications and condition properties, compatible with both ESX (`owned_vehicles.vehicle`) and QB/Qbox (`player_vehicles.mods`):

```lua
-- Retrieve properties from a client vehicle entity
local props = Kairo.Vehicle.GetProperties(vehicleEntity)

-- Modify or inspect
print('Plate:', props.plate)
print('Engine Health:', props.engineHealth)
print('Primary Color:', props.color1)

-- Apply properties back to a vehicle
Kairo.Vehicle.SetProperties(vehicleEntity, props)
```

---

## 2. Fuel Management

Adapts across `ox_fuel`, `cdn-fuel`, `ps-fuel`, `LegacyFuel`, or falls back to native entity statebag (`Entity(veh).state.fuel`):

```lua
-- Get fuel level (returns number 0.0 - 100.0)
local fuel = Kairo.Vehicle.GetFuel(vehicleEntity)

-- Set fuel level
Kairo.Vehicle.SetFuel(vehicleEntity, 100.0)
```

---

## 3. Vehicle Keys

Adapts across `qbx_vehiclekeys`, `qb-vehiclekeys`, `wasabi_carlock`, `Renewed-Vehiclekeys`, `cd_garage`, or metadata keys:

```lua
-- Give keys to a player (Client or Server)
Kairo.Vehicle.GiveKeys(source, vehicleEntity, plate)

-- Remove keys
Kairo.Vehicle.RemoveKeys(source, vehicleEntity, plate)

-- Check if player holds keys
if Kairo.Vehicle.HasKeys(source, vehicleEntity, plate) then
    print('Player has access to this vehicle!')
end
```

---

## 4. Plate Generator & Uniqueness

Generates plates adhering to configurable masks (`config.lua` `PlateFormat: '11AAA111'`) and verifies against the server database:

```lua
-- Generate a unique plate (Server-side)
local plate = Kairo.Vehicle.GeneratePlate()
print('Generated unique plate:', plate)

-- Check if a plate is registered in the database
if Kairo.Vehicle.IsPlateTaken('ABC 1234') then
    print('Plate already exists in DB!')
end
```
