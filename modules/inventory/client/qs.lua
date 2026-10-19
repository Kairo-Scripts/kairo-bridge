-- qs-inventory client side. Exports: getUserInventory, Search, GetItemList.
local S = Kairo.Require('modules/inventory/shared.lua')
local RES = 'qs-inventory'
local A = {}

local itemList = S.CachedList(RES, function() return exports[RES]:GetItemList() end)

function A.GetItemCount(item, metadata)
    local ok, inv = pcall(function() return exports[RES]:getUserInventory() end)
    if ok and type(inv) == 'table' then
        local total = 0
        for _, it in pairs(inv) do
            if it and it.name == item and S.Subset(it.info or it.metadata or {}, metadata) then total = total + S.AmountOf(it) end
        end
        return total
    end
    if metadata then return 0 end
    local okSearch, n = pcall(function() return exports[RES]:Search(item) end)
    return okSearch and tonumber(n) or 0
end

function A.GetItemDefinition(name) return S.Definition(name, itemList()[name]) end

-- qs-inventory opens stashes through its QB-style events (see the server adapter). NOTE: verify on your qs version.
local function open(id, cfg)
    TriggerServerEvent('inventory:server:OpenInventory', 'stash', id, { maxweight = cfg.maxweight, slots = cfg.slots })
    TriggerEvent('inventory:client:SetCurrentStash', id)
end
RegisterNetEvent(('kairo:inventory:openStash:%s'):format(Kairo.Resource), open)

function A.OpenStash(id, opts)
    open(id, { maxweight = opts.maxWeight or 100000, slots = opts.slots or 50 })
    return true
end

return A
