local A = {}

function A.GetItemCount(item)
    local d = LocalPlayer.state['kairo:data']
    return d and d.items and d.items[item] or 0
end

function A.GetItemDefinition(name) return { name = name, label = name } end

function A.OpenStash()
    Kairo.Log.warnOnce('sa-stash', 'Standalone inventory has no stash support')
    return false
end

return A
