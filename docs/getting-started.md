# Getting Started

## 1. Installation

1. Download the latest release from the Releases page or clone into your server's `resources` directory:
   ```bash
   cd resources
   git clone https://github.com/Kairo-Scripts/kairo-bridge.git kairo-bridge
   ```
2. Ensure `kairo-bridge` starts before any resource that consumes it in your `server.cfg`:
   ```cfg
   ensure oxmysql # (if using database features)
   ensure kairo-bridge
   ensure your-resource
   ```

---

## 2. Consuming Kairo Bridge in Your Resource

In your resource's `fxmanifest.lua`, add:

```lua
fx_version 'cerulean'
game 'gta5'
lua54 'yes'

dependency 'kairo-bridge'
shared_script '@kairo-bridge/init.lua'

client_scripts {
    'client/main.lua',
}

server_scripts {
    'server/main.lua',
}
```

Now, the `Kairo` global is available anywhere in your client and server scripts!

---

## 3. Basic Usage Example

### Client Script (`client/main.lua`)
```lua
-- Toast Notification
Kairo.Notify('Welcome to the server!', 'success', 5000)

-- TextUI
Kairo.TextUI.Show('Press [E] to talk to the clerk', 'comment', 'left')

-- Progress Bar with animation
local success = Kairo.ProgressBar({
    duration = 5000,
    label = 'Repairing vehicle...',
    canCancel = true,
    anim = {
        dict = 'mini@repair',
        clip = 'fixing_a_ped',
    },
})

if success then
    Kairo.Notify('Vehicle repaired!', 'success')
end
```

### Server Script (`server/main.lua`)
```lua
-- Money & Framework
RegisterCommand('givebonus', function(source, args)
    local player = Kairo.Framework.GetPlayer(source)
    if not player then return end

    player.AddMoney(500, 'bank', 'Monthly bonus')
    player.Notify('You received a $500 bonus!', 'success')
end, false)

-- Inventory
RegisterCommand('checkbread', function(source)
    local count = Kairo.Inventory.GetItemCount(source, 'bread')
    Kairo.Framework.Notify(source, ('You have %d bread in your bag.'):format(count), 'info')
end, false)
```

---

## 4. LuaLS IDE Setup (Autocomplete & Types)

To get full IDE autocompletion and type-checking in VS Code:
1. Install the **Lua** extension by `sumneko`.
2. In your workspace's `.luarc.json`, add `@kairo-bridge/types` or point to `kairo-bridge`:
   ```json
   {
     "workspace.library": [
       "path/to/kairo-bridge/types"
     ]
   }
   ```
Whenever you type `Kairo.` or `player.`, all available fields and methods with full documentation will autocomplete automatically!
