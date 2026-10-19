# UI & Target Modules

Unified user interface and interactive target systems with zero external dependency requirements.

---

## 1. UI Components (`Kairo.UI`)

All UI methods automatically adapt to `ox_lib`, `qb-core`, `es_extended`, or fall back to the built-in HTML5/JS/CSS NUI layer:

### Toast Notifications
```lua
Kairo.UI.Notify('Operation successful!', 'success', 5000)
-- Shortcut:
Kairo.Notify('Low health warning!', 'warning')
```

### TextUI Pill
```lua
-- Show on screen
Kairo.TextUI.Show('Press [E] to access warehouse', 'warehouse', 'left')

-- Hide when out of range
Kairo.TextUI.Hide()
```

### Progress Bar
```lua
local finished = Kairo.ProgressBar({
    duration = 4000,
    label = 'Lockpicking...',
    canCancel = true,
    anim = {
        dict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@',
        clip = 'machinic_loop_mechandplayer',
    },
    disable = {
        move = true,
        car = true,
        combat = true,
    },
})
```

### Input Modal
```lua
local input = Kairo.Input({
    header = 'Bank Transfer',
    submitText = 'Send',
    rows = {
        { type = 'input', label = 'Recipient ID', placeholder = '1', required = true },
        { type = 'number', label = 'Amount ($)', default = 100, min = 1, max = 100000 },
    },
})

if input then
    local targetId = tonumber(input[1])
    local amount = tonumber(input[2])
end
```

### Context Menu
```lua
Kairo.ContextMenu({
    id = 'garage_menu',
    title = 'Impound Garage',
    options = {
        {
            title = 'Sultan RS (ABC 123)',
            description = 'Fee: $250 - Status: Impounded',
            icon = 'car',
            onSelect = function()
                TriggerServerEvent('garage:retrieve', 'ABC 123')
            end,
        },
    },
})
```

### Alert Confirmation Dialog
```lua
local result = Kairo.Alert({
    header = 'Confirm Deletion',
    content = 'Are you sure you want to permanently delete this vehicle?',
    centered = true,
    cancel = true,
})

if result == 'confirm' then
    -- User confirmed
end
```

---

## 2. Target System (`Kairo.Target`)

Supports `ox_target`, `qb-target`, `sleepless_target`, or the built-in **proximity fallback** (which renders `TextUI` and listens for `[E]` key press).

### Entity Interaction
```lua
Kairo.Target.AddEntity(vehicleEntity, {
    {
        name = 'trunk_search',
        icon = 'fa-solid fa-box-open',
        label = 'Search Trunk',
        distance = 2.0,
        action = function(entity)
            print('Searching vehicle trunk:', entity)
        end,
    },
})
```

### Model Targeting
```lua
Kairo.Target.AddModel({ `prop_atm_01`, `prop_atm_02` }, {
    {
        name = 'atm_use',
        icon = 'fa-solid fa-credit-card',
        label = 'Access ATM',
        distance = 1.5,
        action = function(entity)
            TriggerEvent('banking:openAtm')
        end,
    },
})
```

### Spherical / Box Interaction Zones
```lua
local zoneId = Kairo.Target.AddZone({
    name = 'duty_clockin',
    coords = vector3(441.2, -982.5, 30.6),
    radius = 1.5,
    options = {
        {
            name = 'toggle_duty',
            icon = 'fa-solid fa-clipboard-user',
            label = 'Toggle Police Duty',
            action = function()
                TriggerServerEvent('police:toggleDuty')
            end,
        },
    },
})
```
