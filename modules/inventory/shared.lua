--[[
    Helpers shared by the inventory adapters (loaded with Kairo.Require, so one copy per resource context).
    Nothing here talks to a specific inventory.
]]
local S = {}

---Deep "subset" match: every key in `wanted` must exist in `have` with an equal value (tables compared recursively).
---A nil/empty `wanted` matches everything.
local function subset(have, wanted)
    if wanted == nil then return true end
    if type(wanted) ~= 'table' then return have == wanted end
    if type(have) ~= 'table' then return false end
    for k, v in pairs(wanted) do
        if not subset(have[k], v) then return false end
    end
    return true
end
S.Subset = subset

---@return number the stack size, whatever the inventory calls it
function S.AmountOf(it)
    return tonumber(it and (it.amount or it.count)) or 0
end

---Per-resource cache for an inventory's item list. Exports re-serialise the whole table on every call,
---so adapters fetch it once and drop it when the inventory resource restarts.
---@param resource string inventory resource name
---@param fetch fun(): table|nil
---@return fun(): table
function S.CachedList(resource, fetch)
    local cache
    AddEventHandler('onResourceStop', function(res) if res == resource then cache = nil end end)
    return function()
        if cache then return cache end
        local ok, list = pcall(fetch)
        if ok and type(list) == 'table' and next(list) ~= nil then cache = list end
        return (ok and type(list) == 'table') and list or {}
    end
end

---Build a { name, label, weight, description, image } definition from a raw item-list entry.
function S.Definition(name, d)
    if type(d) ~= 'table' then return nil end
    return {
        name = name,
        label = d.label or name,
        weight = tonumber(d.weight) or 0,
        description = d.description or '',
        image = d.image or (name .. '.png'),
    }
end

---Normalize one raw inventory entry. `idField` lets core_inventory report its own stack id as the slot.
function S.Normalize(it, label)
    return {
        name = it.name,
        label = it.label or label or it.name,
        count = S.AmountOf(it),
        slot = it.slot or it.id,
        weight = it.weight,
        metadata = it.info or it.metadata or {},
    }
end

if Kairo.IsServer then
    ---Usable items for qs / codem / tgiann / core are registered through the *framework*, not the inventory
    ---(these inventories hook the framework's usable-item callbacks). `cb(src, { name, slot, metadata, label })`.
    function S.RegisterUsable(item, cb)
        local fw = Kairo.Env.framework.name
        local function fire(src, it)
            it = type(it) == 'table' and it or {}
            Kairo.Utils.SafeCall(cb, src, {
                name = item, slot = it.slot, label = it.label,
                metadata = it.info or it.metadata or {},
            })
        end
        if fw == 'esx' then
            local ESX = exports['es_extended']:getSharedObject()
            -- ESX >= 1.10 calls back (playerId, itemName, itemData); older versions (playerId, itemName).
            ESX.RegisterUsableItem(item, function(src, _, data) fire(src, data) end)
            return true
        elseif fw == 'qb' then
            exports['qb-core']:GetCoreObject().Functions.CreateUseableItem(item, function(src, it) fire(src, it) end)
            return true
        elseif fw == 'qbox' then
            exports.qbx_core:CreateUseableItem(item, function(src, it) fire(src, it) end)
            return true
        end
        Kairo.Log.warnOnce('inv-usable-fw', 'Usable items need ESX, QB or Qbox with %s; "%s" was not registered', Kairo.Env.inventory.name, item)
        return false
    end

    ---Stash definitions kept by the bridge for inventories that take the config at open time.
    function S.NewStashStore()
        local store = {}
        return {
            set = function(id, label, slots, maxWeight) store[id] = { label = label, slots = slots, maxWeight = maxWeight } end,
            get = function(id) return store[id] end,
        }
    end
end

return S
