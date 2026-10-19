--[[
    Kairo.Target — ox_target client adapter.
]]
local A = {}
local ox = exports.ox_target

local function normalizeOption(opt)
    return {
        name = opt.name,
        label = opt.label or 'Interact',
        icon = opt.icon or 'fas fa-hand',
        distance = opt.distance or 2.0,
        groups = opt.groups or opt.job,
        canInteract = function(entity, distance, coords, name, bone)
            if opt.groups or opt.job then
                local F = Kairo.Framework
                if F and F.HasJob and not F.HasJob(opt.groups or opt.job) then
                    return false
                end
            end
            if type(opt.canInteract) == 'function' then
                return opt.canInteract(entity, distance, coords, name, bone)
            end
            return true
        end,
        onSelect = function(data)
            if type(opt.onSelect) == 'function' then
                opt.onSelect(data)
            elseif type(opt.action) == 'function' then
                opt.action(data and data.entity)
            end
        end,
    }
end

local function normalizeOptions(options)
    local out = {}
    for i, opt in ipairs(options or {}) do
        out[i] = normalizeOption(opt)
    end
    return out
end

function A.AddTargetEntity(entities, options)
    ox:addLocalEntity(entities, normalizeOptions(options))
    return true
end

function A.RemoveTargetEntity(entities, names)
    ox:removeLocalEntity(entities, names)
    return true
end

function A.AddTargetModel(models, options)
    ox:addModel(models, normalizeOptions(options))
    return true
end

function A.RemoveTargetModel(models, names)
    ox:removeModel(models, names)
    return true
end

function A.AddBoxZone(id, coords, size, opts, options)
    opts = opts or {}
    ox:addBoxZone({
        name = id,
        coords = coords,
        size = size or vector3(2.0, 2.0, 2.0),
        rotation = opts.heading or opts.rotation or 0.0,
        debug = opts.debug or false,
        options = normalizeOptions(options),
    })
    return true
end

function A.AddSphereZone(id, coords, radius, opts, options)
    opts = opts or {}
    ox:addSphereZone({
        name = id,
        coords = coords,
        radius = radius or 2.0,
        debug = opts.debug or false,
        options = normalizeOptions(options),
    })
    return true
end

function A.RemoveZone(id)
    ox:removeZone(id)
    return true
end

function A.AddTargetBone(bones, options)
    -- ox_target supports bones inside entity options or global entity
    return false
end

function A.RemoveTargetBone(bones, names)
    return false
end

function A.AddGlobalPed(options)
    ox:addGlobalPed(normalizeOptions(options))
    return true
end

function A.RemoveGlobalPed(names)
    ox:removeGlobalPed(names)
    return true
end

function A.AddGlobalVehicle(options)
    ox:addGlobalVehicle(normalizeOptions(options))
    return true
end

function A.RemoveGlobalVehicle(names)
    ox:removeGlobalVehicle(names)
    return true
end

function A.AddGlobalObject(options)
    ox:addGlobalObject(normalizeOptions(options))
    return true
end

function A.RemoveGlobalObject(names)
    ox:removeGlobalObject(names)
    return true
end

function A.AddGlobalPlayer(options)
    ox:addGlobalPlayer(normalizeOptions(options))
    return true
end

function A.RemoveGlobalPlayer(names)
    ox:removeGlobalPlayer(names)
    return true
end

return A
