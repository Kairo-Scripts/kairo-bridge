local A = {}

local function normalize(it)
    return { name = it.name, label = it.label, count = it.count or 0, slot = it.slot, weight = it.weight, metadata = it.metadata or {} }
end

function A.GetItemCount(src, item, metadata)
    return exports.ox_inventory:Search(src, 'count', item, metadata) or 0
end

function A.AddItem(src, item, count, metadata)
    return exports.ox_inventory:AddItem(src, item, count, metadata) and true or false
end

function A.RemoveItem(src, item, count, metadata)
    return exports.ox_inventory:RemoveItem(src, item, count, metadata) and true or false
end

function A.CanCarry(src, item, count)
    return exports.ox_inventory:CanCarryItem(src, item, count) and true or false
end

function A.GetItems(src, item)
    local out = {}
    if item then
        for _, it in pairs(exports.ox_inventory:Search(src, 'slots', item) or {}) do out[#out + 1] = normalize(it) end
    else
        for _, it in pairs(exports.ox_inventory:GetInventoryItems(src) or {}) do
            if it and it.name then out[#out + 1] = normalize(it) end
        end
    end
    return out
end

function A.GetItemDefinition(name)
    local d = exports.ox_inventory:Items(name)
    if not d then return nil end
    return {
        name = name, label = d.label, weight = d.weight, description = d.description,
        image = d.client and d.client.image or (name .. '.png'),
    }
end
function A.ItemExists(name) return exports.ox_inventory:Items(name) ~= nil end

-- NOTE: relies on ox_inventory's server-side `ox_inventory:usedItem` event (playerId, name, slot, metadata).
local usable = {}
AddEventHandler('ox_inventory:usedItem', function(src, name, slot, metadata)
    local cb = usable[name]
    if cb then Kairo.Utils.SafeCall(cb, src, { name = name, slot = slot, metadata = metadata or {} }) end
end)
function A.RegisterUsableItem(item, cb) usable[item] = cb end

function A.RegisterStash(id, label, slots, maxWeight, owner, groups)
    exports.ox_inventory:RegisterStash(id, label, slots, maxWeight, owner, groups)
    return true
end
function A.OpenStash(src, id)
    exports.ox_inventory:forceOpenInventory(src, 'stash', id)
    return true
end

-- Shops: ox_inventory's RegisterShop takes { name, inventory = { {name, price, count?, metadata?} }, groups? }.
-- NOTE: opened with the same client event community_bridge uses; verify on your ox version.
function A.RegisterShop(id, shop)
    local inventory = {}
    for _, it in ipairs(shop.items) do
        inventory[#inventory + 1] = { name = it.name, price = it.price, count = it.count, metadata = it.metadata }
    end
    exports.ox_inventory:RegisterShop(id, { name = shop.label, inventory = inventory, groups = shop.groups })
    return true
end
function A.OpenShop(src, id)
    TriggerClientEvent('ox_inventory:openInventory', src, 'shop', { type = id })
    return true
end

return A
