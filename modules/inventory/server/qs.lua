-- qs-inventory (Quasar). Exports used: GetItemTotalAmount, GetInventory, CanCarryItem, AddItem, RemoveItem, GetItemList.
local S = Kairo.Require('modules/inventory/shared.lua')
local RES = 'qs-inventory'
local A = {}

local itemList = S.CachedList(RES, function() return exports[RES]:GetItemList() end)
local stashes = S.NewStashStore()

local function inventory(src)
    local ok, inv = pcall(function() return exports[RES]:GetInventory(src) end)
    return ok and type(inv) == 'table' and inv or {}
end

-- Matching stacks, lowest slot first.
local function stacks(src, item, metadata)
    local out = {}
    for _, it in pairs(inventory(src)) do
        if it and it.name == item and S.Subset(it.info or it.metadata or {}, metadata) then out[#out + 1] = it end
    end
    table.sort(out, function(a, b) return (a.slot or 0) < (b.slot or 0) end)
    return out
end

function A.GetItemCount(src, item, metadata)
    if not metadata then return tonumber(exports[RES]:GetItemTotalAmount(src, item)) or 0 end
    local total = 0
    for _, it in ipairs(stacks(src, item, metadata)) do total = total + S.AmountOf(it) end
    return total
end

function A.CanCarry(src, item, count)
    return exports[RES]:CanCarryItem(src, item, count) and true or false
end

function A.AddItem(src, item, count, metadata)
    if not A.CanCarry(src, item, count) then return false end
    return exports[RES]:AddItem(src, item, count, nil, metadata) and true or false
end

function A.RemoveItem(src, item, count, metadata)
    if not metadata then
        if A.GetItemCount(src, item) < count then return false end
        return exports[RES]:RemoveItem(src, item, count) and true or false
    end
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
    for _, it in pairs(inventory(src)) do
        if it and it.name and (not item or it.name == item) and S.AmountOf(it) > 0 then out[#out + 1] = S.Normalize(it) end
    end
    return out
end

function A.GetItemDefinition(name) return S.Definition(name, itemList()[name]) end
function A.ItemExists(name) return itemList()[name] ~= nil end

function A.RegisterUsableItem(item, cb) S.RegisterUsable(item, cb) end

-- qs-inventory opens stashes through its QB-style events (client side). The server hands the config to the client
-- adapter, which fires them. NOTE: not covered by an export, so verify on your qs version.
local openEvent = ('kairo:inventory:openStash:%s'):format(Kairo.Resource)
function A.RegisterStash(id, label, slots, maxWeight)
    stashes.set(id, label, slots, maxWeight)
    return true
end
function A.OpenStash(src, id, opts)
    local s = stashes.get(id) or {}
    TriggerClientEvent(openEvent, src, id, {
        label = opts.label or s.label or id,
        slots = opts.slots or s.slots or 50,
        maxweight = opts.maxWeight or s.maxWeight or 100000,
    })
    return true
end

return A
