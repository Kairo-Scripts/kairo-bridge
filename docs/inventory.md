# Inventory Module (`Kairo.Inventory`)

Provides unified item operations, metadata support, stashes, and shops across **ox_inventory**, **qb-inventory**, **ps-inventory**, **qs-inventory**, **codem-inventory**, **core_inventory**, **tgiann-inventory**, **es_extended**, and **standalone**.

---

## 1. Item Management (Server-side)

```lua
-- Checking items
local has = Kairo.Inventory.HasItem(source, 'water_bottle', 1)
local count = Kairo.Inventory.GetItemCount(source, 'water_bottle')

-- Adding items (with optional metadata)
local success = Kairo.Inventory.AddItem(source, 'id_card', 1, {
    citizenid = 'XYZ12345',
    name = 'John Doe',
})

-- Removing items
local removed = Kairo.Inventory.RemoveItem(source, 'water_bottle', 1)

-- Weight / capacity check
if Kairo.Inventory.CanCarryItem(source, 'iron_ore', 10) then
    Kairo.Inventory.AddItem(source, 'iron_ore', 10)
else
    Kairo.Framework.Notify(source, 'Inventory is full!', 'error')
end
```

---

## 2. Registering Usable Items (Server-side)

```lua
Kairo.Inventory.RegisterUsableItem('bandage', function(source, item, data)
    -- Trigger client healing animation
    TriggerClientEvent('my_resource:client:useBandage', source)
    -- Consume item
    Kairo.Inventory.RemoveItem(source, item, 1)
end)
```

---

## 3. Stashes & Shared Storage

```lua
-- Open a localized stash for the player
Kairo.Inventory.OpenStash(source, 'apartment_stash_1', 'Apartment Storage', 500000, 50)
```

---

## 4. Unified Shops System

Kairo Bridge allows registering dynamic shops with automatic native opening or built-in NUI shop interfaces:

```lua
-- Register a shop definition
Kairo.Inventory.RegisterShop('convenience_store_1', {
    name = '24/7 Supermarket',
    label = '24/7 Supermarket',
    items = {
        { name = 'bread', price = 5, amount = 100 },
        { name = 'water_bottle', price = 3, amount = 100 },
    },
})

-- Open the shop for a player
Kairo.Inventory.OpenShop(source, 'convenience_store_1')

-- Server-side purchase verification
local success, err = Kairo.Inventory.BuyFromShop(source, 'convenience_store_1', 'bread', 2)
if not success then
    Kairo.Framework.Notify(source, err or 'Purchase failed', 'error')
end
```
