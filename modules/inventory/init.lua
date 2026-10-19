--[[
    Kairo.Inventory — one API over ox_inventory / qb-inventory / ps-inventory / ESX native / standalone.

    SERVER
      GetItemCount(src, item, metadata?)        HasItem(src, item, count?, metadata?)
      AddItem(src, item, count, metadata?)      RemoveItem(src, item, count, metadata?)
      CanCarry(src, item, count)                GetItems(src, item?) -> { {name,label,count,slot,weight,metadata} }
      ItemExists(name)  GetItemDefinition(name) GetItemLabel(name)   GetImagePath(name)
      RegisterUsableItem(item, cb(src, item))
      RegisterItems({ ... })                    -- neutral definitions, see below
      RegisterStash(id, label, slots, maxWeight, owner?, groups?)    OpenStash(src, id, opts?)
      RegisterShop(id, { label, items = { {name, price, count?, metadata?} }, groups?, coords? })   OpenShop(src, id)
      BuyFromShop(src, id, item, count, account?) -> ok, reason      -- server-validated purchase (works on every adapter)

    CLIENT
      GetItemCount(item, metadata?)  HasItem(item, count?, metadata?)  GetItemDefinition(name)
      GetItemLabel(name)  GetImagePath(name)  OpenStash(id, opts?)

    RegisterItems accepts an array of defs (with .name) or a map name -> def:
      { name, label, weight = 100 (grams), stack = true, close = true, description, image, onUse = function(src, item) end }
    Definitions are collected by kairo-bridge, which writes ready-to-paste files to kairo-bridge/generated/
    (ox_items.lua, qb_items.lua, esx_items.sql) and warns about items missing from the active inventory.
]]
local Log, Utils = Kairo.Log, Kairo.Utils
local isServer = Kairo.IsServer
local invEnv, fwName = Kairo.Env.inventory, Kairo.Env.framework.name

local DEDICATED = { ox = true, qs = true, codem = true, tgiann = true, core = true }

local function pickAdapter()
    local inv = invEnv.name
    if DEDICATED[inv] then return inv end
    if (inv == 'qb' or inv == 'ps') and (fwName == 'qb' or fwName == 'qbox') then return 'qb' end
    if inv ~= 'none' then
        Log.warnOnce('inv-fallback', 'Inventory "%s" has no dedicated adapter; falling back to %s framework functions. Verify behaviour on your setup.', inv, fwName)
    end
    if fwName == 'esx' then return 'esx' end
    if fwName == 'qb' or fwName == 'qbox' then return 'qb' end
    return 'standalone'
end

local adapterName = pickAdapter()
local adapter = Kairo.Require(('modules/inventory/%s/%s.lua'):format(isServer and 'server' or 'client', adapterName))

local contract = isServer and {
    'GetItemCount', 'AddItem', 'RemoveItem', 'CanCarry', 'GetItems', 'ItemExists',
    'GetItemDefinition', 'RegisterUsableItem', 'RegisterStash', 'OpenStash',
} or {
    'GetItemCount', 'GetItemDefinition', 'OpenStash',
}
for _, name in ipairs(contract) do
    if type(adapter[name]) ~= 'function' then
        adapter[name] = function()
            Log.warnOnce('inv-missing:' .. name, 'Inventory adapter "%s" does not implement %s()', adapterName, name)
        end
    end
end

local Inventory = { Name = invEnv.name, Adapter = adapterName, Resource = invEnv.resource }
for k, v in pairs(adapter) do
    if type(v) == 'function' then Inventory[k] = v end
end

-- ---------------------------------------------------------------- helpers
local function cleanItem(item) return type(item) == 'string' and item ~= '' and item or nil end
local function cleanCount(n)
    n = tonumber(n)
    return n and n >= 1 and math.floor(n) or nil
end
local function cleanMeta(m) return type(m) == 'table' and next(m) ~= nil and m or nil end

function Inventory.GetItemDefinition(name)
    name = cleanItem(name)
    return name and adapter.GetItemDefinition(name) or nil
end

function Inventory.GetItemLabel(name)
    local def = Inventory.GetItemDefinition(name)
    return def and def.label or name
end

---Returns a NUI image URL for an item, or nil if no template is configured for this inventory.
function Inventory.GetImagePath(name)
    name = cleanItem(name)
    if not name then return nil end
    local key = invEnv.name ~= 'none' and invEnv.name or fwName
    local tpl = (Kairo.Config.ImagePaths or {})[key]
    if type(tpl) ~= 'string' or tpl == '' then return nil end
    local def = adapter.GetItemDefinition(name)
    return tpl:format(def and def.image or (name .. '.png'))
end

-- ---------------------------------------------------------------- wrappers
if isServer then
    function Inventory.GetItemCount(src, item, metadata)
        item = cleanItem(item)
        if not item then return 0 end
        return adapter.GetItemCount(src, item, cleanMeta(metadata)) or 0
    end

    function Inventory.HasItem(src, item, count, metadata)
        count = cleanCount(count or 1)
        if not count then return false end
        return Inventory.GetItemCount(src, item, metadata) >= count
    end

    function Inventory.AddItem(src, item, count, metadata)
        item, count = cleanItem(item), cleanCount(count)
        if not item or not count then return false end
        return adapter.AddItem(src, item, count, cleanMeta(metadata)) == true
    end

    function Inventory.RemoveItem(src, item, count, metadata)
        item, count = cleanItem(item), cleanCount(count)
        if not item or not count then return false end
        return adapter.RemoveItem(src, item, count, cleanMeta(metadata)) == true
    end

    function Inventory.CanCarry(src, item, count)
        item, count = cleanItem(item), cleanCount(count or 1)
        if not item or not count then return false end
        return adapter.CanCarry(src, item, count) ~= false
    end

    function Inventory.GetItems(src, item)
        return adapter.GetItems(src, cleanItem(item)) or {}
    end

    function Inventory.ItemExists(name)
        name = cleanItem(name)
        if not name then return false end
        return adapter.ItemExists(name) ~= false -- nil (unknown) counts as "exists"
    end

    function Inventory.RegisterUsableItem(item, cb)
        item = cleanItem(item)
        if not item or type(cb) ~= 'function' then return false end
        adapter.RegisterUsableItem(item, cb)
        return true
    end

    function Inventory.RegisterStash(id, label, slots, maxWeight, owner, groups)
        if type(id) ~= 'string' or id == '' then return false end
        return adapter.RegisterStash(id, label or id, tonumber(slots) or 50, tonumber(maxWeight) or 100000, owner, groups) ~= false
    end

    function Inventory.OpenStash(src, id, opts)
        return adapter.OpenStash(src, id, opts or {}) ~= false
    end

    -- ------------------------------------------------------------ shops
    -- The bridge keeps the neutral shop definition (used to validate purchases on every adapter) and, where the
    -- inventory has a documented shop API (ox, qb-inventory, ps-inventory), registers it natively too.
    local shops = {}
    local MAX_BUY = 1000
    local ACCOUNTS = { cash = true, bank = true }

    local function cleanShopItems(items)
        if type(items) ~= 'table' then return nil end
        local out = {}
        for _, it in ipairs(items) do
            local name, price = cleanItem(it and it.name), tonumber(it and it.price)
            if not name or not price or price < 0 then
                Log.warn('RegisterShop: skipped an item with no name or a bad price')
            else
                out[#out + 1] = {
                    name = name, price = math.floor(price),
                    count = it.count ~= nil and math.max(0, math.floor(tonumber(it.count) or 0)) or nil, -- nil = unlimited
                    metadata = cleanMeta(it.metadata),
                }
            end
        end
        return #out > 0 and out or nil
    end

    function Inventory.RegisterShop(id, def)
        if type(id) ~= 'string' or id == '' or type(def) ~= 'table' then return false end
        local items = cleanShopItems(def.items)
        if not items then
            Log.warn('RegisterShop("%s"): no valid items', id)
            return false
        end
        local shop = { id = id, label = def.label or id, items = items, groups = def.groups, coords = def.coords }
        shops[id] = shop
        if type(adapter.RegisterShop) == 'function' then
            local ok, res = Utils.SafeCall(adapter.RegisterShop, id, shop)
            shop.native = ok and res ~= false
        end
        if not shop.native then
            Log.warnOnce('shop-native:' .. adapterName, 'Inventory adapter "%s" has no native shop support. Shops are validated by the bridge: build your own UI and call Kairo.Inventory.BuyFromShop().', adapterName)
        end
        return true
    end

    function Inventory.GetShop(id) return shops[id] and Utils.DeepCopy(shops[id]) or nil end

    local function allowed(src, shop)
        if not shop.groups then return true end
        return Kairo.Framework.HasJob(src, shop.groups)
    end

    function Inventory.OpenShop(src, id)
        local shop = shops[id]
        if not shop or not shop.native or type(adapter.OpenShop) ~= 'function' then return false end
        if not allowed(src, shop) then return false end
        return adapter.OpenShop(src, id) ~= false
    end

    ---Server-authoritative purchase: validates shop, item, stock, job group and funds; refunds if the item cannot be given.
    ---@return boolean ok
    ---@return string? reason  'no_shop' | 'no_item' | 'bad_count' | 'bad_account' | 'not_allowed' | 'no_stock' | 'no_funds' | 'cannot_carry' | 'failed'
    function Inventory.BuyFromShop(src, id, item, count, account)
        local shop = shops[id]
        if not shop then return false, 'no_shop' end
        count = cleanCount(count or 1)
        if not count or count > MAX_BUY then return false, 'bad_count' end
        account = account or 'cash'
        if not ACCOUNTS[account] then return false, 'bad_account' end
        if not allowed(src, shop) then return false, 'not_allowed' end

        local entry
        for _, it in ipairs(shop.items) do
            if it.name == cleanItem(item) then entry = it break end
        end
        if not entry then return false, 'no_item' end
        if entry.count and entry.count < count then return false, 'no_stock' end

        local F = Kairo.Framework
        local total = entry.price * count
        if F.GetMoney(src, account) < total then return false, 'no_funds' end
        if not Inventory.CanCarry(src, entry.name, count) then return false, 'cannot_carry' end
        if total > 0 and not F.RemoveMoney(src, account, total, 'shop:' .. id) then return false, 'failed' end
        if not Inventory.AddItem(src, entry.name, count, entry.metadata) then
            if total > 0 then F.AddMoney(src, account, total, 'shop-refund:' .. id) end
            return false, 'failed'
        end
        if entry.count then entry.count = entry.count - count end
        return true
    end

    function Inventory.RegisterItems(items)
        if type(items) ~= 'table' then return false end
        local list = {}
        for key, def in pairs(items) do
            if type(def) == 'table' then
                local name = cleanItem(def.name) or (type(key) == 'string' and key or nil)
                if not name then
                    Log.warn('RegisterItems: skipped an entry with no name')
                else
                    list[#list + 1] = {
                        name = name,
                        label = def.label or name,
                        weight = tonumber(def.weight) or 100,
                        stack = def.stack ~= false,
                        close = def.close ~= false,
                        description = def.description or '',
                        image = def.image or (name .. '.png'),
                        useable = def.onUse ~= nil or def.useable == true,
                    }
                    if type(def.onUse) == 'function' then Inventory.RegisterUsableItem(name, def.onUse) end
                end
            end
        end
        TriggerEvent('kairo-bridge:inventory:registerItems', Kairo.Resource, list)
        return #list
    end
else
    function Inventory.GetItemCount(item, metadata)
        item = cleanItem(item)
        if not item then return 0 end
        return adapter.GetItemCount(item, cleanMeta(metadata)) or 0
    end

    function Inventory.HasItem(item, count, metadata)
        count = cleanCount(count or 1)
        if not count then return false end
        return Inventory.GetItemCount(item, metadata) >= count
    end

    function Inventory.OpenStash(id, opts)
        if type(id) ~= 'string' or id == '' then return false end
        return adapter.OpenStash(id, opts or {}) ~= false
    end
end

return Inventory
