--[[
    Kairo.Target — Built-in Text-UI / Proximity interaction fallback.
    Used when no target resource (ox_target, qb-target, sleepless_interact) is running.
    Allows all target-registered entities, models, and zones to be interactable via TextUI + [E].
]]
local A = {}
local Log = Kairo.Log

local registry = {
    entities = {}, -- [entity] = options
    models = {},   -- [modelHash] = options
    zones = {},    -- [id] = zoneData
    globals = {
        ped = {},
        vehicle = {},
        object = {},
        player = {},
    },
}

local activeTarget = nil
local activeOption = nil
local threadRunning = false

local function ensureThread()
    if threadRunning then return end
    threadRunning = true

    CreateThread(function()
        while true do
            local sleep = 300
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)

            local closestCandidate = nil
            local closestDist = 999.0
            local bestOption = nil

            -- 1. Check Zones
            for id, zone in pairs(registry.zones) do
                local dist = #(playerCoords - zone.coords)
                local maxDist = zone.radius or (zone.size and math.max(zone.size.x, zone.size.y, zone.size.z)) or 2.0
                if dist <= maxDist and dist < closestDist then
                    -- Check options
                    for _, opt in ipairs(zone.options or {}) do
                        local optDist = opt.distance or maxDist
                        if dist <= optDist then
                            local can = true
                            if opt.groups or opt.job then
                                local F = Kairo.Framework
                                if F and F.HasJob and not F.HasJob(opt.groups or opt.job) then can = false end
                            end
                            if can and type(opt.canInteract) == 'function' then
                                can = opt.canInteract(0, dist, zone.coords, opt.name)
                            end
                            if can then
                                closestCandidate = { type = 'zone', id = id, coords = zone.coords }
                                closestDist = dist
                                bestOption = opt
                                break
                            end
                        end
                    end
                end
            end

            -- 2. Check Entities
            for ent, options in pairs(registry.entities) do
                if DoesEntityExist(ent) then
                    local entCoords = GetEntityCoords(ent)
                    local dist = #(playerCoords - entCoords)
                    if dist <= 5.0 and dist < closestDist then
                        for _, opt in ipairs(options) do
                            local maxDist = opt.distance or 2.5
                            if dist <= maxDist then
                                local can = true
                                if opt.groups or opt.job then
                                    local F = Kairo.Framework
                                    if F and F.HasJob and not F.HasJob(opt.groups or opt.job) then can = false end
                                end
                                if can and type(opt.canInteract) == 'function' then
                                    can = opt.canInteract(ent, dist, entCoords, opt.name)
                                end
                                if can then
                                    closestCandidate = { type = 'entity', entity = ent, coords = entCoords }
                                    closestDist = dist
                                    bestOption = opt
                                    break
                                end
                            end
                        end
                    end
                else
                    registry.entities[ent] = nil
                end
            end

            -- Active Interaction Handling
            if closestCandidate and bestOption then
                sleep = 0
                if activeOption ~= bestOption then
                    activeTarget = closestCandidate
                    activeOption = bestOption
                    local label = bestOption.label or 'Interact'
                    Kairo.UI.TextUI.Show(label, { key = 'E', icon = bestOption.icon })
                end

                -- Listen for [E] press (Control 38 / INPUT_CONTEXT)
                if IsControlJustPressed(0, 38) then
                    Wait(100) -- brief debounce
                    local data = {
                        entity = closestCandidate.entity,
                        coords = closestCandidate.coords,
                        distance = closestDist,
                    }
                    if type(bestOption.onSelect) == 'function' then
                        pcall(bestOption.onSelect, data)
                    elseif type(bestOption.action) == 'function' then
                        pcall(bestOption.action, closestCandidate.entity)
                    end
                end
            else
                if activeOption ~= nil then
                    activeTarget = nil
                    activeOption = nil
                    Kairo.UI.TextUI.Hide()
                end
            end

            Wait(sleep)
        end
    end)
end

function A.AddTargetEntity(entities, options)
    if type(entities) ~= 'table' then entities = { entities } end
    for _, ent in ipairs(entities) do
        if DoesEntityExist(ent) then
            registry.entities[ent] = options
        end
    end
    ensureThread()
    return true
end

function A.RemoveTargetEntity(entities, names)
    if type(entities) ~= 'table' then entities = { entities } end
    for _, ent in ipairs(entities) do
        registry.entities[ent] = nil
    end
    return true
end

function A.AddTargetModel(models, options)
    if type(models) ~= 'table' then models = { models } end
    for _, mod in ipairs(models) do
        local hash = type(mod) == 'string' and GetHashKey(mod) or mod
        registry.models[hash] = options
    end
    ensureThread()
    return true
end

function A.RemoveTargetModel(models, names)
    if type(models) ~= 'table' then models = { models } end
    for _, mod in ipairs(models) do
        local hash = type(mod) == 'string' and GetHashKey(mod) or mod
        registry.models[hash] = nil
    end
    return true
end

function A.AddBoxZone(id, coords, size, opts, options)
    registry.zones[id] = {
        type = 'box',
        coords = coords,
        size = size or vector3(2.0, 2.0, 2.0),
        options = options or {},
    }
    ensureThread()
    return true
end

function A.AddSphereZone(id, coords, radius, opts, options)
    registry.zones[id] = {
        type = 'sphere',
        coords = coords,
        radius = radius or 2.0,
        options = options or {},
    }
    ensureThread()
    return true
end

function A.RemoveZone(id)
    registry.zones[id] = nil
    return true
end

function A.AddTargetBone(bones, options)
    return false
end

function A.RemoveTargetBone(bones, names)
    return false
end

function A.AddGlobalPed(options)
    registry.globals.ped[#registry.globals.ped + 1] = options
    ensureThread()
    return true
end

function A.RemoveGlobalPed(names)
    registry.globals.ped = {}
    return true
end

function A.AddGlobalVehicle(options)
    registry.globals.vehicle[#registry.globals.vehicle + 1] = options
    ensureThread()
    return true
end

function A.RemoveGlobalVehicle(names)
    registry.globals.vehicle = {}
    return true
end

function A.AddGlobalObject(options)
    registry.globals.object[#registry.globals.object + 1] = options
    ensureThread()
    return true
end

function A.RemoveGlobalObject(names)
    registry.globals.object = {}
    return true
end

function A.AddGlobalPlayer(options)
    registry.globals.player[#registry.globals.player + 1] = options
    ensureThread()
    return true
end

function A.RemoveGlobalPlayer(names)
    registry.globals.player = {}
    return true
end

return A
