--[[
    Kairo.Target — qb-target client adapter.
]]
local A = {}
local qb = exports['qb-target']

local function normalizeOption(opt, index)
    return {
        num = index or 1,
        type = 'client',
        icon = opt.icon or 'fas fa-hand',
        label = opt.label or 'Interact',
        targeticon = opt.icon,
        job = opt.job or opt.groups,
        action = function(entity)
            if type(opt.onSelect) == 'function' then
                opt.onSelect({
                    entity = entity,
                    coords = entity and DoesEntityExist(entity) and GetEntityCoords(entity) or nil,
                })
            elseif type(opt.action) == 'function' then
                opt.action(entity)
            end
        end,
        canInteract = function(entity, distance, data)
            if opt.job or opt.groups then
                local F = Kairo.Framework
                if F and F.HasJob and not F.HasJob(opt.job or opt.groups) then
                    return false
                end
            end
            if type(opt.canInteract) == 'function' then
                return opt.canInteract(entity, distance, entity and DoesEntityExist(entity) and GetEntityCoords(entity) or nil, opt.name)
            end
            return true
        end,
    }
end

local function normalizeOptions(options)
    local out = {}
    local maxDist = 2.5
    for i, opt in ipairs(options or {}) do
        out[i] = normalizeOption(opt, i)
        if opt.distance and opt.distance > maxDist then
            maxDist = opt.distance
        end
    end
    return out, maxDist
end

function A.AddTargetEntity(entities, options)
    local qbOpts, dist = normalizeOptions(options)
    qb:AddTargetEntity(entities, {
        options = qbOpts,
        distance = dist,
    })
    return true
end

function A.RemoveTargetEntity(entities, names)
    qb:RemoveTargetEntity(entities, names)
    return true
end

function A.AddTargetModel(models, options)
    local qbOpts, dist = normalizeOptions(options)
    qb:AddTargetModel(models, {
        options = qbOpts,
        distance = dist,
    })
    return true
end

function A.RemoveTargetModel(models, names)
    qb:RemoveTargetModel(models, names)
    return true
end

function A.AddBoxZone(id, coords, size, opts, options)
    opts = opts or {}
    size = size or vector3(2.0, 2.0, 2.0)
    local qbOpts, dist = normalizeOptions(options)
    qb:AddBoxZone(id, coords, size.x, size.y, {
        name = id,
        heading = opts.heading or 0.0,
        debugPoly = opts.debug or false,
        minZ = coords.z - (size.z / 2),
        maxZ = coords.z + (size.z / 2),
    }, {
        options = qbOpts,
        distance = dist,
    })
    return true
end

function A.AddSphereZone(id, coords, radius, opts, options)
    opts = opts or {}
    local qbOpts, dist = normalizeOptions(options)
    qb:AddCircleZone(id, coords, radius or 2.0, {
        name = id,
        debugPoly = opts.debug or false,
    }, {
        options = qbOpts,
        distance = dist,
    })
    return true
end

function A.RemoveZone(id)
    qb:RemoveZone(id)
    return true
end

function A.AddTargetBone(bones, options)
    local qbOpts, dist = normalizeOptions(options)
    qb:AddTargetBone(bones, {
        options = qbOpts,
        distance = dist,
    })
    return true
end

function A.RemoveTargetBone(bones, names)
    qb:RemoveTargetBone(bones, names)
    return true
end

function A.AddGlobalPed(options)
    local qbOpts, dist = normalizeOptions(options)
    qb:AddGlobalPed({
        options = qbOpts,
        distance = dist,
    })
    return true
end

function A.RemoveGlobalPed(names)
    qb:RemoveGlobalPed(names)
    return true
end

function A.AddGlobalVehicle(options)
    local qbOpts, dist = normalizeOptions(options)
    qb:AddGlobalVehicle({
        options = qbOpts,
        distance = dist,
    })
    return true
end

function A.RemoveGlobalVehicle(names)
    qb:RemoveGlobalVehicle(names)
    return true
end

function A.AddGlobalObject(options)
    local qbOpts, dist = normalizeOptions(options)
    qb:AddGlobalObject({
        options = qbOpts,
        distance = dist,
    })
    return true
end

function A.RemoveGlobalObject(names)
    qb:RemoveGlobalObject(names)
    return true
end

function A.AddGlobalPlayer(options)
    local qbOpts, dist = normalizeOptions(options)
    qb:AddGlobalPlayer({
        options = qbOpts,
        distance = dist,
    })
    return true
end

function A.RemoveGlobalPlayer(names)
    qb:RemoveGlobalPlayer(names)
    return true
end

return A
