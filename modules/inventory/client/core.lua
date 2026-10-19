-- core_inventory client side. Exports: getInventory, getItemCount, getItemsList.
local S = Kairo.Require('modules/inventory/shared.lua')
local RES = 'core_inventory'
local A = {}

local itemList = S.CachedList(RES, function() return exports[RES]:getItemsList() end)

function A.GetItemCount(item, metadata)
    if not metadata then
        local ok, n = pcall(function() return exports[RES]:getItemCount(item) end)
        return ok and tonumber(n) or 0
    end
    -- getInventory() can fold stacks that carry metadata into one row, so metadata counts are best-effort client side.
    -- Use the server-side Inventory.GetItemCount for anything that matters.
    local ok, inv = pcall(function() return exports[RES]:getInventory() end)
    if not ok or type(inv) ~= 'table' then return 0 end
    local total = 0
    for _, it in pairs(inv) do
        if it and it.name == item and S.Subset(it.metadata or it.info or {}, metadata) then total = total + S.AmountOf(it) end
    end
    return total
end

function A.GetItemDefinition(name) return S.Definition(name, itemList()[name]) end

-- core opens stashes server-side only: use Kairo.Inventory.OpenStash(src, id) from the server.
function A.OpenStash()
    Kairo.Log.warnOnce('core-stash', 'core_inventory stashes open from the server: call Kairo.Inventory.OpenStash(src, id) there')
    return false
end

return A
