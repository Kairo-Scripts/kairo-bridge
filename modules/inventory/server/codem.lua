-- codem-inventory. Exports used: GetInventory(identifier, src), GetItemsTotalAmount, AddItem, RemoveItem, GetItemList.
-- codem has no CanCarry export and no documented stash-open export: CanCarry reports "unknown" (true) and
-- AddItem's own return value is the real check; stashes are unsupported.
local S = Kairo.Require('modules/inventory/shared.lua')
local Log = Kairo.Log
local RES = 'codem-inventory'
local A = {}

local itemList = S.CachedList(RES, function() return exports[RES]:GetItemList() end)

local function inventory(src)
    local id = Kairo.Framework.GetIdentifier(src)
    if not id then return {} end
    local ok, inv = pcall(function() return exports[RES]:GetInventory(id, src) end)
    return ok and type(inv) == 'table' and inv or {}
end

local function stacks(src, item, metadata)
    local out = {}
    for _, it in pairs(inventory(src)) do
        if it and it.name == item and S.Subset(it.info or it.metadata or {}, metadata) then out[#out + 1] = it end
    end
    table.sort(out, function(a, b) return (a.slot or 0) < (b.slot or 0) end)
    return out
end

function A.GetItemCount(src, item, metadata)
    if not metadata then return tonumber(exports[RES]:GetItemsTotalAmount(src, item)) or 0 end
    local total = 0
    for _, it in ipairs(stacks(src, item, metadata)) do total = total + S.AmountOf(it) end
    return total
end

function A.CanCarry() return true end

function A.AddItem(src, item, count, metadata)
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

function A.RegisterStash()
    Log.warnOnce('codem-stash', 'codem-inventory stashes are not bridged yet (no documented open export); use its own stash API')
    return false
end
function A.OpenStash() return false end

return A
