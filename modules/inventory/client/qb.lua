local isQbox = Kairo.Env.framework.name == 'qbox'
local A = {}

local QBCore
local function core()
    if not QBCore then QBCore = exports['qb-core']:GetCoreObject() end
    return QBCore
end
AddEventHandler('onResourceStop', function(res) if res == 'qb-core' then QBCore = nil end end)

local function playerData()
    if isQbox then return exports.qbx_core:GetPlayerData() end
    return core().Functions.GetPlayerData()
end

function A.GetItemCount(item, metadata)
    local d = playerData()
    local total = 0
    for _, it in pairs(d and d.items or {}) do
        if it and it.name == item then
            local ok = true
            for k, v in pairs(metadata or {}) do
                if (it.info or {})[k] ~= v then ok = false break end
            end
            if ok then total = total + (it.amount or it.count or 0) end
        end
    end
    return total
end

function A.GetItemDefinition(name)
    if isQbox then return nil end
    local d = core().Shared.Items[name]
    if not d then return nil end
    return { name = name, label = d.label, weight = d.weight, description = d.description, image = d.image or (name .. '.png') }
end

local function openLegacy(id, cfg)
    TriggerServerEvent('inventory:server:OpenInventory', 'stash', id, { maxweight = cfg.maxweight, slots = cfg.slots })
    TriggerEvent('inventory:client:SetCurrentStash', id)
end

-- Server-driven open (Inventory.OpenStash on the server) lands here for legacy inventories.
RegisterNetEvent(('kairo:inventory:openStashLegacy:%s'):format(Kairo.Resource), openLegacy)

function A.OpenStash(id, opts)
    openLegacy(id, { maxweight = opts.maxWeight or 100000, slots = opts.slots or 50 })
    return true
end

return A
