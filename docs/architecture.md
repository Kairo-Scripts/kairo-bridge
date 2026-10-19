# Architecture & Design Principles

## 1. Zero-Export Consumer Loading

Most FiveM compatibility bridges rely on CFX exports:
```lua
-- Traditional approach (Costly cross-boundary Lua-C-Lua serialization on every call)
exports['some_bridge']:AddItem(source, 'bread', 1)
```

In high-traffic servers with hundreds of players and inventory transactions or tick-based interactions, exports create noticeable overhead.

### How Kairo Bridge Works
`kairo-bridge` uses `LoadResourceFile(BRIDGE, path)`:
```lua
-- Inside @kairo-bridge/init.lua:
function K.Require(path)
    local hit = cache[path]
    if hit ~= nil then return hit end
    local chunk, err = loadChunk(path)
    if not chunk then error(err, 2) end
    local result = chunk()
    cache[path] = result
    return result
end
```

When your resource includes `shared_script '@kairo-bridge/init.lua'`, all bridge module functions are executed **directly inside your resource's Lua state**.
- **0** cross-resource export calls
- **0** argument serialization penalties
- Maximum execution speed and minimal GC pressure

---

## 2. Lazy Module Resolution

Heavy modules are not loaded immediately on resource start. Instead, `Kairo` uses an `__index` metatable:

```lua
local lazy = {
    Framework = 'modules/framework/init.lua',
    Inventory = 'modules/inventory/init.lua',
    Target    = 'modules/target/init.lua',
    UI        = 'modules/ui/init.lua',
    Vehicle   = 'modules/vehicle/init.lua',
    Banking   = 'modules/banking/init.lua',
    DB        = 'modules/database/init.lua',
    Services  = 'modules/services/init.lua',
    -- ...
}
```

If your resource only uses `Kairo.UI.Notify`, the database, vehicle props, and phone modules are never loaded into memory.

---

## 3. The Adapter Pattern

Every module follows a strict adapter design pattern:
1. `init.lua`: Detects which third-party resource is running using `core/detect.lua` or `config.lua` overrides.
2. Selects the appropriate adapter file (e.g., `client/ox.lua`, `client/qb.lua`, `client/fallback.lua`).
3. If no third-party resource is installed, gracefully routes calls to the built-in standalone fallback.

### Subsystem Fallback Matrix

| Subsystem | Primary Third-Party Adapters | Fallback Implementation |
|---|---|---|
| **UI** | `ox_lib`, `qb-core`, `es_extended` | Built-in NUI HTML5/JS/CSS layer (`html/`) |
| **Target** | `ox_target`, `qb-target`, `sleepless_target` | Adaptive proximity TextUI + `[E]` listener |
| **Vehicle Fuel** | `ox_fuel`, `cdn-fuel`, `ps-fuel`, `LegacyFuel` | Native entity statebag `fuel` |
| **Vehicle Keys** | `qbx_vehiclekeys`, `qb-vehiclekeys`, `wasabi_carlock`, `renewed`, `cd_garage` | Metadata / statebag keys |
| **Society / Banking** | `Renewed-Banking`, `okokBanking`, `qb-management`, `esx_society` | Standalone KVP JSON accounts |
| **Database** | `oxmysql` per-framework schema translation | Direct oxmysql normalized wrappers |
| **Dispatch** | `ps-dispatch`, `cd_dispatch`, `core_dispatch`, `qs-dispatch` | Standalone flashing GPS blip + audio toast |
| **Doorlock** | `ox_doorlock`, `qb-doorlock`, `rcore_doorlock` | Standalone synchronized `GlobalState` doors |
| **Appearance** | `illenium-appearance`, `fivem-appearance`, `qb-clothing`, `esx_skin` | Native GTA ped drawable/prop variations |
| **Phone** | `lb-phone`, `qs-smartphone`, `qb-phone` | Standalone notification fallback |
| **Ambulance** | `qbx_medical`, `wasabi_ambulance`, `qb-ambulancejob`, `esx_ambulancejob` | Native revive/health status sync |
| **Prison** | `qbx_prison`, `qb-prison`, `rcore_prison`, `esx-qalle-jail` | Standalone Bolingbroke Penitentiary sentence timers |
