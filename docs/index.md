# Kairo Bridge Documentation

> High-performance, zero-export-overhead compatibility layer for FiveM roleplay servers (ESX, QB-Core, Qbox, and Standalone).

---

## Why Kairo Bridge?

In FiveM script development, supporting multiple frameworks (ESX Legacy, QB-Core, Qbox) and resource ecosystems (ox_lib, qb-target, various fuel/key/doorlock scripts) usually results in huge spaghetti codebases filled with nested conditionals or heavy runtime `exports` calls that degrade frame times.

**Kairo Bridge** solves this permanently:
1. **Zero Export Overhead**: The bridge modules are loaded directly into the consumer resource context via `LoadResourceFile` inside `shared_script '@kairo-bridge/init.lua'`. Calling `Kairo.Inventory.AddItem(...)` incurs **zero** inter-resource RPC overhead.
2. **True Standalone Fallback**: If a server doesn't run `ox_lib` or `qb-target`, Kairo Bridge doesn't crash or fail silently. It includes a sleek, modern built-in NUI system (notifications, progress bar, input modal, context menu, alert dialog) and an adaptive distance proximity target system with zero external dependencies.
3. **Complete Subsystem Coverage**: Supports Framework, Inventory, Targeting, UI, Vehicles (50-mod properties, keys, fuel, plates), Banking/Society, Database (normalized vehicle queries), Dispatch, Doorlock, Appearance, Phone, Ambulance/Healthcare, Prison, and Localization.
4. **Developer-First**: Full LuaLS EmmyLua annotations with `.luarc.json` for rich autocomplete, parameter hints, and type-checking in VS Code, Cursor, and Neovim.

---

## Quick Navigation

- [Getting Started](getting-started.md) — How to install and consume Kairo Bridge in your resources.
- [Architecture](architecture.md) — How the zero-overhead loader and adapter pattern works.
- [Framework Module](framework.md) — Player object, jobs, gangs, money, and money-change events.
- [Inventory Module](inventory.md) — Items, metadata, stashes, and shops.
- [UI & Target Modules](ui-and-target.md) — Toast alerts, TextUI, modals, targeting, and fallbacks.
- [Vehicle Module](vehicle.md) — Properties, fuel, keys, plates, and garage persistence.
- [Banking & Database](banking-and-database.md) — Society accounts and oxmysql query abstraction.
- [Services Module](services.md) — Dispatch, Doorlock, Appearance, Phone, Ambulance, and Prison.
- [Locale Module](locale.md) — Multilingual strings and token interpolation.
