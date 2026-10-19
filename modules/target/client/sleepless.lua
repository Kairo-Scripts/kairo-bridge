--[[
    Kairo.Target — sleepless_interact client adapter.
]]
local A = {}
local interact = exports.sleepless_interact

local function normalizeOption(opt)
    return {
        name = opt.name,
        label = opt.label or 'Interact',
        icon = opt.icon or 'fas fa-hand',
        distance = opt.distance or 2.0,
        canInteract = function(entity, distance, coords)
            if opt.groups or opt.job then
                local F = Kairo.Framework
                if F and F.HasJob and not F.HasJob(opt.groups or opt.job) then
                    return false
                end
            end
            if type(opt.canInteract) == 'function' then
                return opt.canInteract(entity, distance, coords, opt.name)
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
    interact:addLocalEntity(entities, normalizeOptions(options))
    return true
end

function A.RemoveTargetEntity(entities, names)
    interact:removeLocalEntity(entities, names)
    return true
end

function A.AddTargetModel(models, options)
    interact:addModel(models, normalizeOptions(options))
    return true
end

function A.RemoveTargetModel(models, names)
    interact:removeModel(models, names)
    return true
end

function A.AddBoxZone(id, coords, size, opts, options)
    opts = opts or {}
    interact:addBoxZone({
        name = id,
        coords = coords,
        size = size or vector3(2.0, 2.0, 2.0),
        rotation = opts.heading or 0.0,
        options = normalizeOptions(options),
    })
    return true
end

function A.AddSphereZone(id, coords, radius, opts, options)
    opts = opts or {}
    interact:addSphereZone({
        name = id,
        coords = coords,
        radius = radius or 2.0,
        options = normalizeOptions(options),
    })
    return true
end

function A.RemoveZone(id)
    interact:removeZone(id)
    return true
end

function A.AddTargetBone(bones, options)
    return false
end

function A.RemoveTargetBone(bones, names)
    return false
end

function A.AddGlobalPed(options)
    interact:addGlobalPed(normalizeOptions(options))
    return true
end

function A.RemoveGlobalPed(names)
    interact:removeGlobalPed(names)
    return true
end

function A.AddGlobalVehicle(options)
    interact:addGlobalVehicle(normalizeOptions(options))
    return true
end

function A.RemoveGlobalVehicle(names)
    interact:removeGlobalVehicle(names)
    return true
end

function A.AddGlobalObject(options)
    interact:addGlobalObject(normalizeOptions(options))
    return true
end

function A.RemoveGlobalObject(names)
    interact:removeGlobalObject(names)
    return true
end

function A.AddGlobalPlayer(options)
    interact:addGlobalPlayer(normalizeOptions(options))
    return true
end

function A.RemoveGlobalPlayer(names)
    interact:removeGlobalPlayer(names)
    return true
end

return A
