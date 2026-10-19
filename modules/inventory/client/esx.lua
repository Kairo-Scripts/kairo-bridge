local A = {}

local ESX
local function core()
    if not ESX then ESX = exports['es_extended']:getSharedObject() end
    return ESX
end
AddEventHandler('onResourceStop', function(res) if res == 'es_extended' then ESX = nil end end)

local function find(item)
    for _, it in ipairs(core().GetPlayerData().inventory or {}) do
        if it.name == item then return it end
    end
end

function A.GetItemCount(item)
    local it = find(item)
    return it and it.count or 0
end

function A.GetItemDefinition(name)
    local it = find(name)
    if not it then return nil end
    return { name = name, label = it.label, weight = it.weight, image = name .. '.png' }
end

function A.OpenStash()
    Kairo.Log.warnOnce('esx-stash', 'ESX native inventory has no stash support')
    return false
end

return A
