# Changelog

All notable changes to `kairo-bridge` will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.0] - 2026-10-19

### Initial Public Release
First full, production-ready release of **kairo-bridge**, providing a unified, high-performance compatibility layer across ESX, QB-Core, Qbox, and Standalone.

### Core Architecture
- **Zero Export Overhead**: Bridge modules are loaded directly into consumer contexts via `LoadResourceFile` inside `shared_script '@kairo-bridge/init.lua'`, eliminating inter-resource RPC overhead.
- **Dynamic Lazy-Loading**: Heavy submodules load only when first accessed, minimizing memory and execution time.
- **Automatic Environment Detection**: Dynamically inspects running resources across 14 subsystem categories (`core/detect.lua`).
- **Server Diagnostic Command**: `/kairostatus` server command reporting detected frameworks, active adapters, and system health.

### Modules Included

#### 1. Framework (`Kairo.Framework`)
- Unified `KairoPlayer` object wrapper across ESX, QB-Core, Qbox, and Standalone.
- Standardized methods for player data, jobs, gangs, money accounts (`cash`, `bank`, `black`), and administrative permissions.
- **Money-Change Event Listener**: `Kairo.Framework.OnMoneyChange` hooking both bridge operations and native framework events (`QBCore:Server:OnMoneyChange`, `esx:setAccountMoney`).

#### 2. Inventory (`Kairo.Inventory`)
- Multi-inventory adapters: `ox_inventory`, `qb-inventory`, `ps-inventory`, `qs-inventory`, `codem-inventory`, `core_inventory`, `tgiann-inventory`, `es_extended`, and standalone persistence.
- Standardized item operations: `HasItem`, `GetItemCount`, `AddItem`, `RemoveItem`, `GetItemData`, `CanCarryItem`.
- Server-side usable items (`RegisterUsableItem`) and stashes (`OpenStash`).
- Unified Shop System: Shop registration, native or NUI menu opening, and server-validated purchases (`RegisterShop`, `OpenShop`, `BuyFromShop`).

#### 3. Interaction & Targeting (`Kairo.Target`)
- Multi-target adapters: `ox_target`, `qb-target`, `sleepless_target`.
- **Built-in Standalone Fallback**: Adaptive proximity scanning with `TextUI` prompt and key interaction (`[E]`) requiring zero third-party dependencies.
- Standardized interaction targets for entities, models, zones, and global peds/vehicles.

#### 4. UI Layer (`Kairo.UI`)
- Adapters for `ox_lib`, `qb-core`, and `es_extended`.
- **Zero-Dependency Built-in NUI Fallback**: Clean dark-mode HTML5/CSS/JS layer (`html/`) supporting:
  - Toast notifications with automatic queueing and dismissal.
  - TextUI pills with icon support.
  - Progress bars with animation playback and task freezing.
  - Input modals with multi-row field types (text, number, select).
  - Interactive context menus.
  - Alert confirmation dialogs.

#### 5. Vehicles & Garages (`Kairo.Vehicle`)
- **50-Mod Vehicle Properties**: Complete serialization and application of vehicle mods, colors, neons, health, and status (`props.lua`).
- Fuel adapters for `ox_fuel`, `cdn-fuel`, `ps-fuel`, `LegacyFuel`, and statebags.
- Vehicle keys adapters for `qbx_vehiclekeys`, `qb-vehiclekeys`, `wasabi_carlock`, `Renewed-Vehiclekeys`, `cd_garage`, and metadata keys.
- Unique plate generator with customizable masks (`11AAA111`) and database duplicate verification.

#### 6. Society & Banking (`Kairo.Banking` / `Kairo.Society`)
- Multi-banking compatibility with `Renewed-Banking`, `okokBanking`, `qb-management`, `esx_society`/`addonaccount`, and standalone KVP accounts.

#### 7. Database Abstraction (`Kairo.DB`)
- Unified `oxmysql` query helper: `Execute`, `Scalar`, `Single`, `Insert`, and `Transaction`.
- Cross-framework schema normalization for player vehicles (`GetPlayerVehicles`, `GetVehicleByPlate`, `SaveVehicleProps`, `SetVehicleStored`, `IsPlateTaken`).

#### 8. Civic & Emergency Services (`Kairo.Services`)
- **Dispatch**: Multi-adapter support for `ps-dispatch`, `cd_dispatch`, `core_dispatch`, `qs-dispatch`, and standalone flashing radar blips.
- **Doorlock**: Support for `ox_doorlock`, `qb-doorlock`, `rcore_doorlock`, and standalone `GlobalState`.
- **Appearance**: Seamless interface across `illenium-appearance`, `fivem-appearance`, `qb-clothing`, `esx_skin`, and native ped drawables.
- **Phone**: Notification and contacts bridge for `lb-phone`, `qs-smartphone`, `qb-phone`, and standalone fallback.
- **Ambulance & Healthcare**: Support for `qbx_medical`, `wasabi_ambulance`, `qb-ambulancejob`, `esx_ambulancejob`, and native health/revive state sync.
- **Prison & Incarceration**: Support for `qbx_prison`, `qb-prison`, `rcore_prison`, `esx-qalle-jail`, and standalone sentence tracking.

#### 9. Localization (`Kairo.Locale`)
- Multi-language registration, dynamic switching, token interpolation (`%{name}`), and fallback to English.

#### 10. Developer Polish & Tooling
- Full LuaLS / EmmyLua type definitions in `types/kairo.lua`.
- Preconfigured `.luarc.json` for IDE autocomplete in VS Code, Cursor, and Neovim.
- Luacheck configuration (`.luacheckrc`).
- Automated CI pipeline (`.github/workflows/ci.yml`) and release packaging (`.github/workflows/release.yml`).
- Automated unit test suite (`tests/runner.js` and `tests/unit/`).
- Full documentation suite in `docs/`.
