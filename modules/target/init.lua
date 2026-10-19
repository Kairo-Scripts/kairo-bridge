--[[
    Kairo.Target — Unified targeting & interaction layer over ox_target, qb-target, sleepless_interact,
    and built-in Text-UI proximity fallback.

    CLIENT:
      AddTargetEntity(entities, options)       RemoveTargetEntity(entities, names?)
      AddTargetModel(models, options)          RemoveTargetModel(models, names?)
      AddBoxZone(id, coords, size, opts, options)
      AddSphereZone(id, coords, radius, opts, options)
      RemoveZone(id)
      AddTargetBone(bones, options)            RemoveTargetBone(bones, names?)
      AddGlobalPed(options)                    RemoveGlobalPed(names?)
      AddGlobalVehicle(options)                RemoveGlobalVehicle(names?)
      AddGlobalObject(options)                 RemoveGlobalObject(names?)
      AddGlobalPlayer(options)                 RemoveGlobalPlayer(names?)

    Options shape:
      {
        name = 'action_name',
        label = 'Interact',
        icon = 'fas fa-hand',
        distance = 2.0,
        job = 'police',                        -- or groups = { 'police', 'ambulance' }
        canInteract = function(entity, distance, coords, name, bone) return true end,
        onSelect = function(data) end,         -- data = { entity, coords, distance }
        action = function(entity) end,         -- alternate callback syntax supported
      }
]]
local Log = Kairo.Log
local isServer = Kairo.IsServer
local Target = {}

if isServer then
    Log.warnOnce('target-server', 'Kairo.Target is a client-side module; server-side calls are no-ops.')
    return Target
end

local targetEnv = Kairo.Env.target or { name = 'none' }
local adapterName = targetEnv.name

if adapterName == 'none' or adapterName == nil or adapterName == '' then
    adapterName = 'fallback'
end

local ok, adapter = pcall(function()
    return Kairo.Require(('modules/target/client/%s.lua'):format(adapterName))
end)

if not ok or not adapter then
    Log.warnOnce('target-adapter-fallback', 'Target adapter "%s" could not be loaded; falling back to proximity TextUI: %s', adapterName, tostring(adapter))
    adapterName = 'fallback'
    adapter = Kairo.Require('modules/target/client/fallback.lua')
end

Target.Name = targetEnv.name
Target.Adapter = adapterName
Target.Resource = targetEnv.resource

local contract = {
    'AddTargetEntity', 'RemoveTargetEntity',
    'AddTargetModel', 'RemoveTargetModel',
    'AddBoxZone', 'AddSphereZone', 'RemoveZone',
    'AddTargetBone', 'RemoveTargetBone',
    'AddGlobalPed', 'RemoveGlobalPed',
    'AddGlobalVehicle', 'RemoveGlobalVehicle',
    'AddGlobalObject', 'RemoveGlobalObject',
    'AddGlobalPlayer', 'RemoveGlobalPlayer',
}

for _, name in ipairs(contract) do
    if type(adapter[name]) ~= 'function' then
        adapter[name] = function()
            Log.warnOnce('target-missing:' .. name, 'Target adapter "%s" does not implement %s()', adapterName, name)
            return false
        end
    end
    Target[name] = adapter[name]
end

return Target
