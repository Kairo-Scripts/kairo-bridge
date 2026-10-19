-- tgiann-inventory client side. Exports: GetPlayerItems, GetItemList.
local S = Kairo.Require('modules/inventory/shared.lua')
local RES = 'tgiann-inventory'
local A = {}

local itemList = S.CachedList(RES, function() return exports[RES]:GetItemList() end)

function A.GetItemCount(item, metadata)
    local ok, inv = pcall(function() return exports[RES]:GetPlayerItems() end)
    if not ok or type(inv) ~= 'table' then return 0 end
    local total = 0
    for k, it in pairs(inv) do
        if tonumber(k) and type(it) == 'table' and it.name == item and S.Subset(it.info or it.metadata or {}, metadata) then
            total = total + S.AmountOf(it)
        end
    end
    return total
end

function A.GetItemDefinition(name) return S.Definition(name, itemList()[name]) end

-- tgiann opens stashes server-side only: use Kairo.Inventory.OpenStash(src, id) from the server.
function A.OpenStash()
    Kairo.Log.warnOnce('tgiann-stash', 'tgiann-inventory stashes open from the server: call Kairo.Inventory.OpenStash(src, id) there')
    return false
end

return A
