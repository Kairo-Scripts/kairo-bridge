-- codem-inventory client side. Exports: GetClientPlayerInventory, GetItemList.
local S = Kairo.Require('modules/inventory/shared.lua')
local RES = 'codem-inventory'
local A = {}

local itemList = S.CachedList(RES, function() return exports[RES]:GetItemList() end)

function A.GetItemCount(item, metadata)
    local ok, inv = pcall(function() return exports[RES]:GetClientPlayerInventory() end)
    if not ok or type(inv) ~= 'table' then return 0 end
    local total = 0
    for _, it in pairs(inv) do
        if it and it.name == item and S.Subset(it.info or it.metadata or {}, metadata) then total = total + S.AmountOf(it) end
    end
    return total
end

function A.GetItemDefinition(name) return S.Definition(name, itemList()[name]) end

function A.OpenStash()
    Kairo.Log.warnOnce('codem-stash', 'codem-inventory stashes are not bridged yet')
    return false
end

return A
