local A = {}

function A.GetItemCount(item, metadata)
    return exports.ox_inventory:Search('count', item, metadata) or 0
end

function A.GetItemDefinition(name)
    local d = exports.ox_inventory:Items(name)
    if not d then return nil end
    return { name = name, label = d.label, weight = d.weight, description = d.description, image = d.client and d.client.image or (name .. '.png') }
end

function A.OpenStash(id)
    exports.ox_inventory:openInventory('stash', id)
    return true
end

return A
