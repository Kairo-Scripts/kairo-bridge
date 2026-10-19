# kairo-bridge

Provides the complete core compatibility suite: `Kairo.Framework`, `Kairo.Inventory`, `Kairo.Target`, `Kairo.UI`, `Kairo.Vehicle`, `Kairo.Banking`, `Kairo.Database`, `Kairo.Services` (Dispatch, Doorlock, Appearance, Phone, Ambulance, Prison), `Kairo.Locale`, and `Kairo.Heartbeat`.

## Install
1. Drop `kairo-bridge` in your resources folder.
2. `ensure` it **after** your framework (and oxmysql etc.) and **before** any script that uses it.
3. Optional: edit `config.lua` to force a framework / enable debug.
4. Check it works: run `kairostatus` in the server console (in-game needs `add_ace group.admin command.kairostatus allow`).

## Use in a script
```lua
-- fxmanifest.lua
dependency 'kairo-bridge'
shared_script '@kairo-bridge/init.lua'
```
```lua
-- anywhere (client or server)
Kairo.RequireVersion('1.0.0')
local F = Kairo.Framework
```

### Server API
| Function | Notes |
|---|---|
| `F.GetPlayer(src)` | normalized: `source, identifier, name, job, gang?, money, metadata, raw` |
| `F.GetIdentifier(src)` `F.GetName(src)` `F.IsPlayerLoaded(src)` | |
| `F.GetJob(src)` | `{ name, label, type?, grade, gradeLabel, onDuty, isBoss }` |
| `F.HasJob(src, jobs, minGrade, requireDuty)` | `jobs`: `'police'`, `{'police','ems'}` or `{ police = 2, ems = 0 }` |
| `F.SetJob(src, name, grade)` `F.SetDuty(src, bool)` | |
| `F.GetMoney(src, acct)` `F.AddMoney(src, acct, n, reason)` `F.RemoveMoney(...)` | acct: `cash`, `bank`, `black`. `black` is native on ESX/standalone only |
| `F.GetMetadata(src, key)` `F.SetMetadata(src, key, value)` | |
| `F.HasGroup(src, group)` | admin/permission check |
| `F.GetPlayers()` `F.GetPlayersByJob(job, onDutyOnly)` `F.GetSourceByIdentifier(id)` | |
| `F.OnPlayerLoaded(cb)` `F.OnPlayerUnloaded(cb)` `F.OnJobUpdate(cb)` | callbacks are pcall-protected |

### Client API
`F.IsLoaded()`, `F.GetPlayerData()`, `F.GetIdentifier()`, `F.GetJob()`, `F.HasJob(jobs, minGrade, requireDuty)`,
`F.GetMoney(acct)`, `F.GetMetadata(key)`, `F.OnPlayerLoaded(cb)`, `F.OnPlayerUnloaded(cb)`, `F.OnJobUpdate(cb)`.

### Other globals
`Kairo.Env` (detection result), `Kairo.Log` (`debug/info/warn/error/warnOnce`), `Kairo.Config`,
`Kairo.Utils` (`SafeCall`, `SafeExport`, `DeepCopy`, `CompareVersions`, `NewEmitter`), `Kairo.RequireVersion(v)`.

## Inventory (`Kairo.Inventory`)

```lua
local I = Kairo.Inventory
I.HasItem(src, 'lockpick', 1)
I.AddItem(src, 'bread', 2, { quality = 90 })     -- metadata ignored on ESX native / standalone (warns once)
I.RemoveItem(src, 'bread', 1)
I.CanCarry(src, 'bread', 5)
I.GetItems(src)            -- { { name, label, count, slot, weight, metadata } }
I.GetImagePath('bread')    -- NUI url from Config.ImagePaths, or nil
I.RegisterUsableItem('bread', function(src, item) end)
I.RegisterStash('police_evidence', 'Evidence', 100, 500000, nil, { police = 0 })
I.OpenStash(src, 'police_evidence')
```
Client: `GetItemCount`, `HasItem`, `GetItemDefinition`, `GetItemLabel`, `GetImagePath`, `OpenStash`.

**Adapter selection:** `ox_inventory`, `qs-inventory`, `codem-inventory`, `tgiann-inventory`, `core_inventory` -> their own adapter
(any framework). `qb-inventory`/`ps-inventory` on QB/Qbox -> QB player functions. No inventory resource -> ESX native / QB functions /
standalone store by framework.

| | ox | qs | codem | tgiann | core | qb / ps | ESX native |
|---|---|---|---|---|---|---|---|
| metadata add / match / remove | yes | yes | yes | yes | yes | yes | no |
| CanCarry | yes | yes | always `true`* | yes | always `true`* | yes | yes |
| Stashes | yes | client events** | no | yes | yes** | yes | no |
| Native shop | yes** | no | no | no | no | qb-inventory (new) / ps** | no |

\* the inventory has no carry-check export; `AddItem` returns `false` if it genuinely cannot add. ** see "Unverified" below.
Usable items for qs/codem/tgiann/core go through the framework's usable-item registration (ESX / QB / Qbox), as those inventories hook it.
Metadata matching is a deep subset match: `{ quality = 90 }` matches a stack whose metadata contains at least that.

**Shops**
```lua
Kairo.Inventory.RegisterShop('ammunation', {
    label = 'Ammu-Nation', groups = nil,          -- groups: same shape as Framework.HasJob jobs
    items = { { name = 'ammo-9', price = 5 }, { name = 'lockpick', price = 150, count = 20 } }, -- count = limited stock
})
Kairo.Inventory.OpenShop(src, 'ammunation')       -- native UI where the inventory has one, else returns false
local ok, reason = Kairo.Inventory.BuyFromShop(src, 'ammunation', 'ammo-9', 10, 'cash')  -- 'cash' | 'bank'
```
`BuyFromShop` is server-authoritative and works on every adapter (validates shop, item, count 1-1000, stock, job group, funds, carry
space; refunds on failure). Reasons: `no_shop no_item bad_count bad_account not_allowed no_stock no_funds cannot_carry failed`.
Use it behind your own UI where there is no native shop. Stock counts live in memory and reset on restart.

**Unverified (no live server was available):** adapters were written against each inventory's documented exports and cross-checked against
the community_bridge project's export usage, but not run on real servers. Lowest confidence: qs stash events, core `openInventory` weight
unit, ox forced shop-open event, ps-inventory `CreateShop`. Run `kairostatus`, then test add/remove/metadata/stash on your inventory
before relying on it, and report what differs.

**Registering your items once**
```lua
Kairo.Inventory.RegisterItems({
    { name = 'lockpick', label = 'Lockpick', weight = 150, description = '...',
      onUse = function(src, item) end },
})
```
The bridge writes paste-ready files to `kairo-bridge/generated/` (`ox_items.lua`, `qb_items.lua`, `esx_items.sql`)
and logs which of your items are missing from the active inventory, so "item doesn't exist" tickets disappear.
Weights are grams.

Standalone mode keeps a simple name -> count inventory (optional `Config.Standalone.MaxWeight`), no metadata or stashes.
Call `Kairo.Inventory.UseItem(src, item)` from your own UI to fire usable callbacks.

## Heartbeat (`Kairo.Heartbeat`, server only)

Client for the [Heartbeat](https://heartbeat.re) public-usage API (which servers run which resources). Optional: it does nothing until you set a key.

```cfg
# server.cfg  (use `set`, NOT `setr`, and never put the key in config.lua - that file is streamed to clients)
set kairo_heartbeat_key "your-key"
```
```lua
local usage, err = Kairo.Heartbeat.GetUsage()                    -- kairo-bridge itself; GetUsage('my_script') for yours
-- usage = { name, servers, playerReach, playersPerServer, countPeriod, countAt, countStatus, activeNow, stale }
local board = Kairo.Heartbeat.Resources({ limit = 10, sort = 'reach' })
```
Every call returns `body, err, stale` and never throws. `err.code` is one of `not_configured`, `unauthorized`, `not_found`,
`rate_limited`, `http_error`, `network`, `bad_response`, `bad_args`. Responses are cached (`Config.Heartbeat.CacheSeconds`, min 30),
identical concurrent calls share one HTTP request, a 429 pauses all requests (honours `Retry-After` if sent, else 60s), and the last
good copy is served (`stale = true`) if a refresh fails. `kairostatus` shows the bridge's own adoption numbers.
Not wrapped on purpose: `/keys`, `/ownership` and `/watches` (account / webhook management, not usage data).
Counts default to yesterday's UTC mean; pass `{ period = 'current' }` for the latest census.

## UI (`Kairo.UI`)

Provides a unified UI and interaction layer across **ox_lib**, framework-native (**QB-Core**, **ESX**), and a zero-dependency **built-in NUI fallback** with modern glassmorphism.

```lua
-- Top-level shortcuts or via Kairo.UI:
Kairo.Notify('Vehicle locked.', 'success') -- or Kairo.UI.Notify(message, type, duration)
Kairo.TextUI.Show('Search Safe', { key = 'E', icon = 'fas fa-vault' })
Kairo.TextUI.Hide()

-- Interactive modals (blocking awaits):
local ok = Kairo.ProgressBar({
    duration = 5000,
    label = 'Disarming bomb...',
    canCancel = true,
    disable = { move = true, combat = true },
    anim = { dict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@', clip = 'machinic_loop_mechandplayer' }
})

local data = Kairo.Input('Customs Declaration', {
    { type = 'input', label = 'Full Name', default = 'Jane Doe' },
    { type = 'number', label = 'Cash Amount', min = 0, max = 50000 },
    { type = 'checkbox', label = 'Declaring goods', default = false },
    { type = 'select', label = 'Port of Entry', options = { 'Airport', 'Docks', 'Border' } },
}) -- returns array of values [name, cash, declaring, port] or nil if cancelled

Kairo.ContextMenu({
    id = 'boss_actions',
    title = 'Management Actions',
    options = {
        { title = 'Hire Employee', description = 'Recruit closest citizen', onSelect = function() ... end },
        { title = 'Vault Balance', description = '$54,000 in society bank', disabled = true },
    }
})

local choice = Kairo.Alert({
    header = 'Warning',
    content = 'Wiping inventory cannot be undone. Continue?',
    confirmText = 'Proceed',
    cancelText = 'Cancel',
}) -- 'confirm' | 'cancel'
```

**Server API:**
```lua
Kairo.UI.Notify(src, 'You received $500', 'success')
Kairo.UI.Broadcast('Server restarting in 15 minutes!', 'warning')
```

| Component | ox_lib | QB-Core | ESX | Standalone |
|---|---|---|---|---|
| `Notify` | `lib.notify` | `QBCore:Notify` | `esx:showNotification` | Built-in NUI card |
| `TextUI` | `lib.showTextUI` | `qb-core:DrawText` | `ESX.TextUI` | Built-in NUI pill |
| `ProgressBar` | `lib.progressBar` | `QBCore.Functions.Progressbar` | Built-in NUI | Built-in NUI bar |
| `Input` | `lib.inputDialog` | `qb-input` / Built-in NUI | Built-in NUI | Built-in NUI modal |
| `ContextMenu` | `lib.registerContext` | `qb-menu` / Built-in NUI | Built-in NUI | Built-in NUI menu |
| `Alert` | `lib.alertDialog` | Built-in NUI | Built-in NUI | Built-in NUI modal |

## Target (`Kairo.Target`)

Unified targeting and interaction system supporting **ox_target**, **qb-target**, **sleepless_interact**, and an automatic **built-in Text-UI proximity fallback**.

```lua
local T = Kairo.Target

-- Define options once with unified syntax (onSelect and action both work):
local options = {
    {
        name = 'steal_stereo',
        label = 'Steal Stereo',
        icon = 'fas fa-music',
        distance = 2.0,
        job = 'unemployed', -- or groups = { 'police', 'ambulance' }
        canInteract = function(entity, distance, coords) return true end,
        onSelect = function(data) -- data.entity, data.coords, data.distance
            print('Stealing stereo from', data.entity)
        end,
    }
}

T.AddTargetEntity(entity, options)
T.AddTargetModel({ 'prop_atm_01', 'prop_atm_02' }, options)
T.AddBoxZone('stash_zone', vector3(100.0, -200.0, 30.0), vector3(2.0, 2.0, 2.0), { heading = 0.0, debug = false }, options)
T.AddSphereZone('safe_zone', vector3(105.0, -195.0, 30.0), 3.0, { debug = false }, options)
T.AddGlobalVehicle(options)
T.AddGlobalPed(options)

-- Cleanup:
T.RemoveTargetEntity(entity)
T.RemoveTargetModel('prop_atm_01')
T.RemoveZone('stash_zone')
```

If no target resource is detected (`Env.target.name == 'none'`), Kairo's **built-in fallback** automatically scans for registered targets in proximity, displays the interaction prompt via `Kairo.TextUI`, and fires the callback upon pressing **[E]**.

## Locale (`Kairo.Locale`)

Lightweight phrase dictionary and string interpolation system with automatic fallback to `'en'`.

```lua
local L = Kairo.Locale

-- Interpolation with named tokens %{name}
L.Register('en', {
    welcome = 'Welcome back, %{name}!',
    stash_prompt = '[E] Open %{label}',
})

L.Register('fr', {
    welcome = 'Bienvenue, %{name}!',
    stash_prompt = '[E] Ouvrir %{label}',
})

L.T('welcome', { name = 'Alex' }) -- "Welcome back, Alex!"
Kairo._t('stash_prompt', { label = 'Police Evidence' }) -- "[E] Open Police Evidence"
```

## Vehicles (`Kairo.Vehicle`)

Unified vehicle management covering **Keys**, **Fuel**, **Vehicle Properties (Mods, Damage, Colors)**, and server-side **Plate Generation**.

```lua
local V = Kairo.Vehicle

-- Client: Vehicle properties (ox_lib / qb-core / ESX / native GTA)
local props = V.GetProperties(vehicle)
-- props = { plate, model, engineHealth, bodyHealth, fuelLevel, color1, color2, mods = {...}, extras = {...} }
V.SetProperties(vehicle, props)

-- Fuel: ox_fuel, cdn-fuel, ps-fuel, LegacyFuel, standalone
local fuel = V.GetFuel(vehicle)
V.SetFuel(vehicle, 100.0)

-- Keys & Locking: qbx_vehiclekeys, qb-vehiclekeys, wasabi_carlock, Renewed-Vehiclekeys, cd_garage, standalone
local hasKey = V.HasKeys(vehicle)
V.ToggleLock(vehicle) -- plays key fob anim, sound, light flash, sets door locks, and displays notify
```

**Server API:**
```lua
Kairo.Vehicle.GiveKeys(src, 'XYZ 123')     -- gives keys to a player
Kairo.Vehicle.RemoveKeys(src, 'XYZ 123')   -- revokes keys
Kairo.Vehicle.HasKeys(src, 'XYZ 123')

local plate = Kairo.Vehicle.GeneratePlate('11AAA111') -- checks database uniqueness
local taken = Kairo.Vehicle.IsPlateTaken(plate)
```

| Component | Adapters |
|---|---|
| `Keys` | `qbx_vehiclekeys`, `qb-vehiclekeys`, `wasabi_carlock`, `Renewed-Vehiclekeys`, `cd_garage`, standalone |
| `Fuel` | `ox_fuel`, `cdn-fuel`, `ps-fuel`, `LegacyFuel`, standalone native + statebags |
| `Properties` | `ox_lib`, `qb-core`, `es_extended`, standalone native |

## Society & Banking (`Kairo.Banking`, `Kairo.Society`)

Unified boss accounts and banking management.

```lua
local B = Kairo.Banking

-- Society / Boss Accounts (server):
local balance = B.GetSocietyMoney('police')
B.AddSocietyMoney('police', 5000, 'Fine payment')
B.RemoveSocietyMoney('police', 1500, 'Equipment purchase')

-- Direct Player Bank helpers (server & client):
local bankBalance = B.GetPlayerBank(src)
B.AddPlayerBank(src, 1000, 'Salary')
B.RemovePlayerBank(src, 250, 'ATM withdrawal')
```

Adapters supported: **Renewed-Banking**, **okokBanking**, **qb-management**, **qb-banking**, **esx_society** / **esx_addonaccount**, and standalone KVP storage.

## Database (`Kairo.Database` / `Kairo.DB`, server only)

Safe wrapper over `oxmysql` with **per-framework schema mapping** for vehicles and players.

```lua
local DB = Kairo.DB

-- Direct oxmysql query wrappers:
local rows = DB.Query('SELECT * FROM users WHERE group = ?', { 'admin' })
local user = DB.Single('SELECT * FROM users WHERE identifier = ?', { id })
local count = DB.Scalar('SELECT COUNT(*) FROM owned_vehicles')
local insertId = DB.Insert('INSERT INTO logs (message) VALUES (?)', { 'Server started' })
local updated = DB.Update('UPDATE users SET money = ? WHERE id = ?', { 500, 1 })

-- Per-Framework Normalized Vehicle Queries:
-- Automatically queries `player_vehicles` on QB/Qbox or `owned_vehicles` on ESX
local vehicles = DB.GetPlayerVehicles(identifier)
-- vehicles = { { plate, model, props = {...}, stored = true/false, garage, owner } }

local veh = DB.GetVehicleByPlate('XYZ 123')
DB.SaveVehicleProps('XYZ 123', newProps)
DB.SetVehicleStored('XYZ 123', true, 'pillbox')
local taken = DB.IsPlateTaken('XYZ 123')
```

## Services (`Kairo.Services`)

Unified integration layer across essential roleplay services: **Dispatch/MDT**, **Doorlocks**, **Clothing/Appearance**, **Smartphones**, **Ambulance/Medical**, and **Prison/Jail**.

Accessible as `Kairo.Services.<Module>` or via direct shortcuts: `Kairo.Dispatch`, `Kairo.Doorlock`, `Kairo.Appearance`, `Kairo.Phone`, `Kairo.Ambulance`, `Kairo.Prison`.

### Dispatch (`Kairo.Dispatch`)
Send emergency calls to police, EMS, or custom jobs:
```lua
Kairo.Dispatch.SendAlert({
    code = '10-90',
    title = 'Bank Robbery',
    message = 'Vault alarm triggered at Fleeca Bank, suspect armed.',
    coords = vector3(147.2, -1045.3, 29.3),
    job = 'police', -- or { 'police', 'sheriff' }
    priority = 1,
    blip = { sprite = 161, scale = 1.0, color = 1, flash = true, duration = 60 }
})
```
Adapters: **ps-dispatch**, **cd_dispatch**, **core_dispatch**, **qs-dispatch**, and zero-dependency standalone fallback (radar blips + `Kairo.UI.Notify`).

### Doorlock (`Kairo.Doorlock`)
```lua
local locked = Kairo.Doorlock.GetState('bank_vault')
Kairo.Doorlock.SetState('bank_vault', true) -- lock
local newState = Kairo.Doorlock.Toggle('bank_vault')
```
Adapters: **ox_doorlock**, **qb-doorlock**, **rcore_doorlock**, and standalone GlobalState.

### Appearance & Clothing (`Kairo.Appearance`)
```lua
-- Open customization menu:
Kairo.Appearance.OpenMenu()

-- Get/set appearance data:
local skin = Kairo.Appearance.GetAppearance(PlayerPedId())
Kairo.Appearance.SetAppearance(PlayerPedId(), skin)
Kairo.Appearance.ReloadSkin()
```
Adapters: **illenium-appearance**, **fivem-appearance**, **qb-clothing**, **esx_skin**, and native GTA component/prop variations.

### Phone (`Kairo.Phone`)
```lua
-- Client or Server:
Kairo.Phone.SendNotification(src, { title = 'Bank', message = 'Received $500 transfer.', icon = 'dollar-sign' })

-- Server:
Kairo.Phone.SendMail(src, { sender = 'Chief of Police', subject = 'Promotion', message = 'Congratulations!' })
Kairo.Phone.CreateInvoice(src, { title = 'Vehicle Repair', amount = 350, sender = 'Benny\'s' })
```
Adapters: **lb-phone**, **qs-smartphone** / **qs-smartphone-pro**, **qb-phone**, **npwd**, and standalone notification fallback.

### Ambulance & Medical (`Kairo.Ambulance`)
```lua
-- Client:
local dead = Kairo.Ambulance.IsDead()
Kairo.Ambulance.Revive()
Kairo.Ambulance.Heal(50)

Kairo.Ambulance.OnPlayerDeath(function() print('Player died!') end)
Kairo.Ambulance.OnPlayerRevive(function() print('Player revived!') end)

-- Server:
Kairo.Ambulance.Revive(src)
Kairo.Ambulance.Heal(src, 100)
local isDead = Kairo.Ambulance.IsDead(src)
```
Adapters: **qbx_medical**, **wasabi_ambulance**, **qb-ambulancejob**, **esx_ambulancejob**, and native health/ragdoll monitoring.

### Prison (`Kairo.Prison`, server-only)
```lua
Kairo.Prison.SendToJail(src, 10, 'Armed Robbery')
local remaining = Kairo.Prison.GetJailTime(src)
Kairo.Prison.ReleaseFromJail(src)
```
Adapters: **qbx_prison**, **qb-prison**, **rcore_prison**, **esx-qalle-jail**, and standalone Bolingbroke Penitentiary with automated sentence timers.

### Framework Money-Change Events (`Kairo.Framework.OnMoneyChange`)
Unified listener triggered whenever a player's cash, bank, or black money balance changes:
```lua
Kairo.Framework.OnMoneyChange(function(src, account, newBalance, oldBalance, reason)
    print(('Player %d %s changed from $%d to $%d (%s)'):format(src, account, oldBalance, newBalance, reason or 'n/a'))
end)
```

## Developer Experience & Polish (v1.0.0)

### 1. LuaLS Type Definitions & Autocompletion
Kairo Bridge ships with comprehensive EmmyLua type annotations in [`types/kairo.lua`](file:///c:/Projects/kairo-bridge/types/kairo.lua) and a pre-configured [`.luarc.json`](file:///c:/Projects/kairo-bridge/.luarc.json).
In VS Code, Cursor, or Neovim, simply add `kairo-bridge/types` to your workspace library to get instant auto-complete, parameter hints, and return type validation for every single method on `Kairo`.

### 2. Static Analysis & CI
- [`.luacheckrc`](file:///c:/Projects/kairo-bridge/.luacheckrc): Configured for CFX runtime globals, FiveM native functions, and oxmysql query builders.
- [`.github/workflows/ci.yml`](file:///c:/Projects/kairo-bridge/.github/workflows/ci.yml): Automated GitHub Actions pipeline verifying JavaScript syntax, running `luaparse` across all Lua files, and executing the automated unit test suite.
- [`.github/workflows/release.yml`](file:///c:/Projects/kairo-bridge/.github/workflows/release.yml): Packages clean production zip archives with SHA256 checksums on tag release (`v*`).

### 3. Automated Test Suite
Run the test runner locally or in CI:
```bash
node tests/runner.js
```
Validates all Lua and JS syntax, manifest integrity, plate formatting, version comparisons, and token replacements.

### 4. Documentation & Changelog
- Comprehensive guides available in [`docs/`](file:///c:/Projects/kairo-bridge/docs/index.md):
  - [Architecture](file:///c:/Projects/kairo-bridge/docs/architecture.md)
  - [Getting Started](file:///c:/Projects/kairo-bridge/docs/getting-started.md)
  - [Framework](file:///c:/Projects/kairo-bridge/docs/framework.md)
  - [Inventory](file:///c:/Projects/kairo-bridge/docs/inventory.md)
  - [UI & Target](file:///c:/Projects/kairo-bridge/docs/ui-and-target.md)
  - [Vehicle](file:///c:/Projects/kairo-bridge/docs/vehicle.md)
  - [Banking & Database](file:///c:/Projects/kairo-bridge/docs/banking-and-database.md)
  - [Services](file:///c:/Projects/kairo-bridge/docs/services.md)
  - [Locale](file:///c:/Projects/kairo-bridge/docs/locale.md)
- Complete version history: [`CHANGELOG.md`](file:///c:/Projects/kairo-bridge/CHANGELOG.md)

## How it works
`init.lua` loads bridge files into the **consuming resource's** context with `LoadResourceFile`
(same approach as `ox_lib`), so calls are plain local Lua with no export round-trip.
Adapters fetch the framework core object lazily and drop it when the framework resource stops.
Only standalone mode keeps state, inside the bridge resource (KVP + replicated statebag `kairo:data`).

## Adding a new provider later
1. Add one line to the registry in `core/detect.lua`.
2. Add `modules/<category>/<side>/<id>.lua` implementing the category's contract.
3. Missing functions are auto-stubbed with a one-time warning, so a half-finished adapter never crashes a consumer.

## Notes
- `config.lua` is streamed to clients, never put secrets in it.
- Standalone stores money/job/metadata per `license:` identifier. Treat it as a basic fallback, not a full economy.

