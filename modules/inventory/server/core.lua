-- core_inventory (c8re). Exports used: getInventory, getItemCount, getItems, addItem, removeItem, removeItemExact,
-- getItemsList, openInventory.
-- core has no CanCarry export (CanCarry reports "unknown" = true; addItem's return value is the real check).
-- Stack ids are reported as `slot` so they can be passed back to removeItemExact.
local S = Kairo.Require('modules/inventory/shared.lua')
local RES = 'core_inventory'
local A = {}

local itemList = S.CachedList(RES, function() return exports[RES]:getItemsList() end)
local stashes = S.NewStashStore()

-- getInventory returns one row per name (with a total) when a stack has metadata; getItems(src, name) returns
-- the individual stacks. Always expand through getItems so metadata and stack ids are exact.
local function stacksOf(src, item, metadata)
    local ok, list = pcall(function() return exports[RES]:getItems(src, item) end)
    local out = {}
    if ok and type(list) == 'table' then
        for _, it in pairs(list) do
            if type(it) == 'table' and S.Subset(it.metadata or it.info or {}, metadata) then out[#out + 1] = it end
        end
    end
    return out
end

function A.GetItemCount(src, item, metadata)
    if not metadata then return tonumber(exports[RES]:getItemCount(src, item)) or 0 end
    local total = 0
    for _, it in ipairs(stacksOf(src, item, metadata)) do total = total + S.AmountOf(it) end
    return total
end

function A.CanCarry() return true end

function A.AddItem(src, item, count, metadata)
    return exports[RES]:addItem(src, item, count, metadata) and true or false
end

function A.RemoveItem(src, item, count, metadata)
    if not metadata then
        if A.GetItemCount(src, item) < count then return false end
        exports[RES]:removeItem(src, item, count) -- no return value documented
        return true
    end
    local list = stacksOf(src, item, metadata)
    local have = 0
    for _, it in ipairs(list) do have = have + S.AmountOf(it) end
    if have < count then return false end
    local remaining = count
    for _, it in ipairs(list) do
        if remaining <= 0 then break end
        local take = math.min(remaining, S.AmountOf(it))
        if not exports[RES]:removeItemExact(src, it.id or it.slot, take) then return false end
        remaining = remaining - take
    end
    return true
end

function A.GetItems(src, item)
    local out = {}
    local ok, inv = pcall(function() return exports[RES]:getInventory(src) end)
    if not ok or type(inv) ~= 'table' then return out end
    local seen = {}
    for _, row in pairs(inv) do
        if type(row) == 'table' and row.name and (not item or row.name == item) and not seen[row.name] then
            seen[row.name] = true
            for _, it in ipairs(stacksOf(src, row.name)) do
                it.name = it.name or row.name
                out[#out + 1] = S.Normalize(it, row.label)
            end
        end
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
-- openInventory(src, id, type, slots, weight, ...) per core's docs; the weight unit core expects is not verified.
function A.OpenStash(src, id, opts)
    local s = stashes.get(id) or {}
    local ok = pcall(function()
        exports[RES]:openInventory(src, id, 'stash', opts.slots or s.slots or 50, opts.maxWeight or s.maxWeight or 100000, true, nil, false)
    end)
    return ok
end

return A
