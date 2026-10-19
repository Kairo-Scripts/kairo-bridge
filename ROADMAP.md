# kairo-bridge roadmap

| Phase | Scope | Status |
|---|---|---|
| **1** | Core (loader, logger, detection, utils), Framework module (ESX / QB / Qbox / standalone), standalone store, `/kairostatus`, example resource | **Done** |
| **2** | Inventory: has/count/add/remove, metadata, labels + image paths, usable items, stashes, can-carry, item registration helper (neutral definition -> ox / qb / esx files). Adapters: ox, qb/ps, ESX native, standalone | **Done** (v1.1.0) |
| **2.1** | Dedicated adapters for qs, codem, tgiann, core_inventory + shops (`RegisterShop` / `OpenShop` / server-validated `BuyFromShop`; native hooks for ox, qb-inventory, ps-inventory) | **Done** (v1.3.0, needs live testing per inventory) |
| **2.2** | Heartbeat API client (`Kairo.Heartbeat`, server-only): usage stats, cached + rate-limit aware, `/kairostatus` line | **Done** (v1.2.0) |
| **3** | UI + interaction: Target (entity/model/bone/zone/global, text-UI fallback), Notify, ProgressBar, TextUI, Input, Context menu, Alert. Locale system. Adapters: ox_lib, framework-native, built-in NUI fallback | **Done** (v1.4.0) |
| **4** | Vehicles + money systems: Keys, Fuel, Garage/vehicle props, plate generation; Society/Banking; Database wrapper (oxmysql, per-framework schema map) | **Done** (v1.5.0) |
| **5** | Services: Dispatch/MDT, Doorlock, Clothing/Appearance, Phone, Ambulance/Prison hooks, framework money-change events | **Done** (v1.6.0) |
| **6** | Polish: LuaLS annotations + `.luarc.json`, docs site, test/example coverage, CI (luacheck), release workflow, versioned changelog | **Done** (v1.0.0) |

Ship order rule: a module is only added when at least one of your own scripts needs it,
so every adapter gets exercised in real use before release.
