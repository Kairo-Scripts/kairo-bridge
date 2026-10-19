-- qb-inventory / ps-inventory (and the fallback for other QB-style inventories) via QB player functions.
local F, Log = Kairo.Framework, Kairo.Log
local invRes = Kairo.Env.inventory.resource
local isQbox = Kairo.Env.framework.name == 'qbox'
local A = {}

local function player(src) return F.GetRaw(src) end

local function matches(info, wanted)
    if not wanted then return true end
    info = info or {}
    for k, v in pairs(wanted) do
        if info[k] ~= v then return false end
    end
    return true
end

local function amountOf(it) return it.amount or it.count or 0 end

local function normalize(it)
    return { name = it.name, label = it.label, count = amountOf(it), slot = it.slot, weight = it.weight, metadata = it.info or {} }
end

local function stacks(p, item, metadata)
    local out = {}
    for _, it in pairs(p.PlayerData.items or {}) do
        if it and it.name == item and matches(it.info, metadata) then out[#out + 1] = it end
    end
    table.sort(out, function(a, b) return (a.slot or 0) < (b.slot or 0) end)
    return out
end

function A.GetItemCount(src, item, metadata)
    local p = player(src)
    if not p then return 0 end
    local total = 0
    for _, it in ipairs(stacks(p, item, metadata)) do total = total + amountOf(it) end
    return total
end

function A.AddItem(src, item, count, metadata)
    local p = player(src)
    if not p then return false end
    return p.Functions.AddItem(item, count, false, metadata) == true
end

function A.RemoveItem(src, item, count, metadata)
    local p = player(src)
    if not p then return false end
    if not metadata then return p.Functions.RemoveItem(item, count) == true end

    local list = stacks(p, item, metadata)
    local have = 0
    for _, it in ipairs(list) do have = have + amountOf(it) end
    if have < count then return false end

    local remaining = count
    for _, it in ipairs(list) do
        if remaining <= 0 then break end
        local take = math.min(remaining, amountOf(it))
        if p.Functions.RemoveItem(item, take, it.slot) ~= true then return false end
        remaining = remaining - take
    end
    return true
end

function A.CanCarry(src, item, count)
    if not invRes then return true end
    local ok, res = pcall(function()
        local e = exports[invRes]
        return e:CanAddItem(src, item, count)
    end)
    if not ok then
        Log.debug('CanCarry: %s has no CanAddItem export, assuming true', invRes)
        return true
    end
    return res and true or false
end

function A.GetItems(src, item)
    local p = player(src)
    if not p then return {} end
    local out = {}
    for _, it in pairs(p.PlayerData.items or {}) do
        if it and it.name and (not item or it.name == item) then out[#out + 1] = normalize(it) end
    end
    return out
end

-- Shared item table (cached; cleared when qb-core restarts)
local shared
AddEventHandler('onResourceStop', function(res) if res == 'qb-core' then shared = nil end end)
local function sharedItems()
    if isQbox then return nil end
    if not shared then shared = exports['qb-core']:GetCoreObject().Shared.Items or {} end
    return shared
end

function A.GetItemDefinition(name)
    local items = sharedItems()
    local d = items and items[name]
    if not d then return nil end
    return { name = name, label = d.label, weight = d.weight, description = d.description, image = d.image or (name .. '.png') }
end
function A.ItemExists(name)
    local items = sharedItems()
    if not items then return nil end
    return items[name] ~= nil
end

function A.RegisterUsableItem(item, cb)
    local wrapped = function(src, it)
        cb(src, { name = item, slot = it and it.slot, metadata = it and it.info or {}, label = it and it.label })
    end
    if isQbox then
        exports.qbx_core:CreateUseableItem(item, wrapped)
    else
        exports['qb-core']:GetCoreObject().Functions.CreateUseableItem(item, wrapped)
    end
end

-- Stashes: the stash is described at open time. Tries qb-inventory's server export first,
-- then the legacy client-driven events (qb-inventory <2024, ps-inventory).
local stashes = {}
local legacyEvent = ('kairo:inventory:openStashLegacy:%s'):format(Kairo.Resource)

function A.RegisterStash(id, label, slots, maxWeight)
    stashes[id] = { label = label, slots = slots, maxWeight = maxWeight }
    return true
end

function A.OpenStash(src, id, opts)
    local s = stashes[id] or {}
    local cfg = {
        label = opts.label or s.label or id,
        slots = opts.slots or s.slots or 50,
        maxweight = opts.maxWeight or s.maxWeight or 100000,
    }
    if Kairo.Env.inventory.name == 'qb' then
        local ok = pcall(function()
            local e = exports['qb-inventory']
            e:OpenInventory(src, id, cfg)
        end)
        if ok then return true end
    end
    TriggerClientEvent(legacyEvent, src, id, cfg)
    return true
end

-- Shops: qb-inventory (new) exposes CreateShop / OpenShop; ps-inventory exposes the same pair but requires coords+groups.
-- Older qb-inventory has no shop export: RegisterShop reports false and the bridge falls back to BuyFromShop only.
function A.RegisterShop(id, shop)
    if not invRes then return false end
    local items = {}
    for _, it in ipairs(shop.items) do
        items[#items + 1] = { name = it.name, price = it.price, amount = it.count or 1000, slot = #items + 1 }
    end
    local ok, err = pcall(function()
        exports[invRes]:CreateShop({ name = id, label = shop.label, coords = shop.coords, items = items, slots = #items })
    end)
    if not ok then Log.debug('RegisterShop: %s has no CreateShop export (%s)', invRes, tostring(err)) end
    return ok
end
function A.OpenShop(src, id)
    return (pcall(function() exports[invRes]:OpenShop(src, id) end))
end

return A
