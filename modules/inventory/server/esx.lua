local F, Log = Kairo.Framework, Kairo.Log
local A = {}

local ESX
local function core()
    if not ESX then ESX = exports['es_extended']:getSharedObject() end
    return ESX
end
AddEventHandler('onResourceStop', function(res) if res == 'es_extended' then ESX = nil end end)

local function xp(src) return F.GetRaw(src) end

local function warnMeta(metadata)
    if metadata then Log.warnOnce('esx-meta', 'ESX native inventory has no item metadata support; metadata is ignored') end
end

function A.GetItemCount(src, item, metadata)
    warnMeta(metadata)
    local x = xp(src)
    local it = x and x.getInventoryItem(item)
    return it and it.count or 0
end

function A.CanCarry(src, item, count)
    local x = xp(src)
    return x ~= nil and x.canCarryItem(item, count) == true
end

function A.AddItem(src, item, count, metadata)
    warnMeta(metadata)
    local x = xp(src)
    if not x or not x.canCarryItem(item, count) then return false end
    x.addInventoryItem(item, count)
    return true
end

function A.RemoveItem(src, item, count, metadata)
    warnMeta(metadata)
    local x = xp(src)
    local it = x and x.getInventoryItem(item)
    if not it or it.count < count then return false end
    x.removeInventoryItem(item, count)
    return true
end

function A.GetItems(src, item)
    local x = xp(src)
    local out = {}
    if not x then return out end
    for _, it in ipairs(x.getInventory() or {}) do
        if it.count and it.count > 0 and (not item or it.name == item) then
            out[#out + 1] = { name = it.name, label = it.label, count = it.count, weight = it.weight, metadata = {} }
        end
    end
    return out
end

local items
AddEventHandler('onResourceStop', function(res) if res == 'es_extended' then items = nil end end)
local function itemTable()
    if not items then items = core().Items end
    return items
end

function A.GetItemDefinition(name)
    local d = itemTable() and itemTable()[name]
    if not d then return nil end
    return { name = name, label = d.label, weight = d.weight, image = name .. '.png' }
end
function A.ItemExists(name)
    local t = itemTable()
    if not t then return nil end
    return t[name] ~= nil
end

function A.RegisterUsableItem(item, cb)
    core().RegisterUsableItem(item, function(src)
        cb(src, { name = item, metadata = {} })
    end)
end

function A.RegisterStash()
    Log.warnOnce('esx-stash', 'ESX native inventory has no stash support; use ox_inventory for stashes')
    return false
end
function A.OpenStash() return false end

return A
