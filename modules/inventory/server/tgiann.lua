-- tgiann-inventory. Exports used: GetPlayerItems, CanCarryItem, AddItem, RemoveItem, GetItemList, ForceOpenInventory.
local S = Kairo.Require('modules/inventory/shared.lua')
local RES = 'tgiann-inventory'
local A = {}

local itemList = S.CachedList(RES, function() return exports[RES]:GetItemList() end)
local stashes = S.NewStashStore()

-- GetPlayerItems mixes numeric slot keys with other fields: only numeric keys are items.
local function inventory(src)
    local ok, inv = pcall(function() return exports[RES]:GetPlayerItems(src) end)
    local out = {}
    if ok and type(inv) == 'table' then
        for k, it in pairs(inv) do
            if tonumber(k) and type(it) == 'table' and it.name then out[#out + 1] = it end
        end
    end
    return out
end

local function stacks(src, item, metadata)
    local out = {}
    for _, it in ipairs(inventory(src)) do
        if it.name == item and S.Subset(it.info or it.metadata or {}, metadata) then out[#out + 1] = it end
    end
    table.sort(out, function(a, b) return (a.slot or 0) < (b.slot or 0) end)
    return out
end

function A.GetItemCount(src, item, metadata)
    local total = 0
    for _, it in ipairs(stacks(src, item, metadata)) do total = total + S.AmountOf(it) end
    return total
end

function A.CanCarry(src, item, count)
    return exports[RES]:CanCarryItem(src, item, count) and true or false
end

function A.AddItem(src, item, count, metadata)
    if not A.CanCarry(src, item, count) then return false end
    return exports[RES]:AddItem(src, item, count, nil, metadata, false) and true or false
end

function A.RemoveItem(src, item, count, metadata)
    local list = stacks(src, item, metadata)
    local have = 0
    for _, it in ipairs(list) do have = have + S.AmountOf(it) end
    if have < count then return false end
    local remaining = count
    for _, it in ipairs(list) do
        if remaining <= 0 then break end
        local take = math.min(remaining, S.AmountOf(it))
        if not exports[RES]:RemoveItem(src, item, take, it.slot) then return false end
        remaining = remaining - take
    end
    return true
end

function A.GetItems(src, item)
    local out = {}
    for _, it in ipairs(inventory(src)) do
        if (not item or it.name == item) and S.AmountOf(it) > 0 then out[#out + 1] = S.Normalize(it) end
    end
    return out
end

function A.GetItemDefinition(name) return S.Definition(name, itemList()[name]) end
function A.ItemExists(name) return itemList()[name] ~= nil end

function A.RegisterUsableItem(item, cb) S.RegisterUsable(item, cb) end

function A.RegisterStash(id, label, slots, maxWeight)
    stashes.set(id, label, slots, maxWeight)
    return true
end
function A.OpenStash(src, id, opts)
    local s = stashes.get(id) or {}
    local ok = pcall(function()
        exports[RES]:ForceOpenInventory(src, 'stash', id, {
            maxWeight = opts.maxWeight or s.maxWeight or 1000000,
            slots = opts.slots or s.slots or 50,
            label = opts.label or s.label or id,
        })
    end)
    return ok
end

return A
