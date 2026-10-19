---@meta
---@diagnostic disable: duplicate-set-field, lowercase-global

---@class KairoBridge
---@field Version string The semantic version of kairo-bridge.
---@field Bridge string The name of the bridge resource ('kairo-bridge').
---@field Resource string The name of the consumer resource calling the bridge.
---@field IsServer boolean True if running in server runtime.
---@field IsClient boolean True if running in client runtime.
---@field Config table Parsed configuration from config.lua.
---@field Utils KairoUtils Utility helper functions.
---@field Log KairoLogger Logging interface with color-coded tags.
---@field Env KairoEnv Environment and subsystem detection data.
---@field Framework KairoFramework Cross-framework player and core management.
---@field Inventory KairoInventory Unified inventory interactions and shops.
---@field Target KairoTarget Targeting and interaction zone system.
---@field UI KairoUI Unified user interface and dialog adapters.
---@field Vehicle KairoVehicle Vehicle properties, keys, fuel, and plates.
---@field Banking KairoBanking Bank accounts and society transactions.
---@field Society KairoSociety Society accounts management alias.
---@field DB KairoDatabase Unified oxmysql database query wrapper.
---@field Database KairoDatabase Alias for Kairo.DB.
---@field Services KairoServices Aggregated emergency and civic services.
---@field Dispatch KairoDispatch 911 / emergency dispatch adapter.
---@field Doorlock KairoDoorlock Doorlock status and toggle manager.
---@field Appearance KairoAppearance Clothing and skin appearance bridge.
---@field Phone KairoPhone Phone notifications and contacts bridge.
---@field Ambulance KairoAmbulance Healthcare, revive, and injury tracking.
---@field Prison KairoPrison Incarceration, sentencing, and release tracker.
---@field Locale KairoLocale Localization manager.
---@field TextUI KairoTextUI Quick access to TextUI functions.
Kairo = {}

---Load and cache a file from kairo-bridge into this resource's context.
---@param path string Relative path to bridge root (e.g. 'core/utils.lua')
---@return any
function Kairo.Require(path) end

---Verify that the installed kairo-bridge meets the minimum version requirement.
---@param minimum string Semantic version (e.g. '1.5.0')
---@return boolean
function Kairo.RequireVersion(minimum) end

---Display a notification to the player.
---@param message string|table Notification text or options table.
---@param notifyType? 'info'|'success'|'warning'|'error'
---@param duration? number Duration in milliseconds.
function Kairo.Notify(message, notifyType, duration) end

---Display an animated progress bar.
---@param data { duration: number, label: string, useWhileDead?: boolean, canCancel?: boolean, anim?: table, prop?: table, disable?: table }
---@return boolean completed True if completed, false if cancelled.
function Kairo.ProgressBar(data) end

---Open an interactive input dialog modal.
---@param data { header: string, submitText?: string, rows: table[] }
---@return any[]|nil values Array of row values, or nil if cancelled.
function Kairo.Input(data) end

---Open a context menu.
---@param data { id: string, title: string, options: table[] }
function Kairo.ContextMenu(data) end

---Display an alert confirmation dialog.
---@param data { header: string, content: string, centered?: boolean, cancel?: boolean }
---@return 'confirm'|'cancel'
function Kairo.Alert(data) end

---Translate a localized string key with optional token replacements.
---@param key string
---@param subs? table<string, any>
---@return string
function Kairo.T(key, subs) end

---Translate a localized string key (alias).
---@param key string
---@param subs? table<string, any>
---@return string
function Kairo._t(key, subs) end

--------------------------------------------------------------------------------
-- UTILS & LOGGER
--------------------------------------------------------------------------------

---@class KairoUtils
---@field TableDeepCopy fun(orig: table): table
---@field TableMerge fun(target: table, source: table): table
---@field StringTrim fun(s: string): string
---@field CompareVersions fun(v1: string, v2: string): number

---@class KairoLogger
---@field debug fun(fmt: string, ...: any)
---@field info fun(fmt: string, ...: any)
---@field warn fun(fmt: string, ...: any)
---@field error fun(fmt: string, ...: any)

---@class KairoEnv
---@field Framework 'esx'|'qb'|'qbox'|'standalone'
---@field Inventory 'ox'|'qb'|'ps'|'qs'|'codem'|'core'|'tgiann'|'none'
---@field Target 'ox'|'qb'|'sleepless'|'none'
---@field UI 'ox_lib'|'qb'|'esx'|'standalone'
---@field Fuel 'ox'|'cdn'|'ps'|'legacy'|'standalone'
---@field VehicleKeys 'qbx'|'qb'|'wasabi'|'renewed'|'cd'|'standalone'
---@field Banking 'renewed'|'okok'|'qb'|'esx'|'standalone'
---@field Dispatch 'ps'|'cd'|'core'|'qs'|'standalone'
---@field Doorlock 'ox'|'qb'|'rcore'|'standalone'
---@field Appearance 'illenium'|'fivem-appearance'|'qb'|'esx'|'standalone'
---@field Phone 'lb'|'qs'|'qb'|'standalone'
---@field Ambulance 'qbx'|'wasabi'|'qb'|'esx'|'standalone'
---@field Prison 'qbx'|'qb'|'rcore'|'esx'|'standalone'

--------------------------------------------------------------------------------
-- PLAYER & FRAMEWORK
--------------------------------------------------------------------------------

---@class KairoPlayer
---@field source number Server ID of the player.
---@field identifier string Unique citizen ID, license, or hex identifier.
---@field license string RockStar license string.
---@field name string Character name.
---@field job { name: string, label: string, grade: number, gradeLabel: string }
---@field gang { name: string, label: string, grade: number, gradeLabel: string }
---@field charinfo table Character personal metadata (dob, gender, etc.).
---@field GetIdentifier fun(): string
---@field GetName fun(): string
---@field GetJob fun(): table
---@field GetGang fun(): table
---@field GetMoney fun(account?: 'cash'|'bank'|'black'|string): number
---@field AddMoney fun(amount: number, account?: 'cash'|'bank'|'black'|string, reason?: string): boolean
---@field RemoveMoney fun(amount: number, account?: 'cash'|'bank'|'black'|string, reason?: string): boolean
---@field SetJob fun(name: string, grade?: number): boolean
---@field Notify fun(message: string, notifyType?: string, duration?: number)

---@class KairoFramework
---@field GetPlayer fun(source: number): KairoPlayer|nil
---@field GetPlayerByIdentifier fun(identifier: string): KairoPlayer|nil
---@field GetPlayers fun(): KairoPlayer[]
---@field GetIdentifier fun(source: number): string|nil
---@field GetName fun(source: number): string
---@field GetJob fun(source: number): { name: string, label: string, grade: number, gradeLabel: string }
---@field GetGang fun(source: number): { name: string, label: string, grade: number, gradeLabel: string }
---@field GetMoney fun(source: number, account?: 'cash'|'bank'|'black'|string): number
---@field AddMoney fun(source: number, amount: number, account?: string, reason?: string): boolean
---@field RemoveMoney fun(source: number, amount: number, account?: string, reason?: string): boolean
---@field SetJob fun(source: number, name: string, grade?: number): boolean
---@field HasPermission fun(source: number, group: string): boolean
---@field Notify fun(source: number, message: string, notifyType?: string, duration?: number)
---@field OnMoneyChange fun(callback: fun(source: number, account: string, newAmount: number, diff: number, reason?: string))

--------------------------------------------------------------------------------
-- INVENTORY
--------------------------------------------------------------------------------

---@class KairoInventory
---@field HasItem fun(source: number, item: string, count?: number): boolean
---@field GetItemCount fun(source: number, item: string): number
---@field AddItem fun(source: number, item: string, count?: number, metadata?: table): boolean
---@field RemoveItem fun(source: number, item: string, count?: number, metadata?: table): boolean
---@field GetItemData fun(item: string): { name: string, label: string, weight?: number, image?: string }
---@field CanCarryItem fun(source: number, item: string, count?: number): boolean
---@field RegisterUsableItem fun(item: string, callback: fun(source: number, item: string, data?: table))
---@field OpenStash fun(source: number, stashId: string, label?: string, maxWeight?: number, slots?: number)
---@field RegisterShop fun(shopId: string, data: { name?: string, label?: string, items: table[], blip?: table })
---@field OpenShop fun(source: number, shopId: string)
---@field BuyFromShop fun(source: number, shopId: string, item: string, count: number): boolean, string?

--------------------------------------------------------------------------------
-- TARGET
--------------------------------------------------------------------------------

---@class KairoTargetOption
---@field name? string Unique option name
---@field icon? string FontAwesome icon string
---@field label string Display label
---@field distance? number Maximum interaction distance
---@field action? fun(entity: number) Function executed on click
---@field onSelect? fun(data: table) Action alias
---@field canInteract? fun(entity: number, distance: number): boolean Condition callback

---@class KairoTarget
---@field AddEntity fun(entity: number, options: KairoTargetOption[])
---@field RemoveEntity fun(entity: number, names?: string[])
---@field AddModel fun(models: number|string|(number|string)[], options: KairoTargetOption[])
---@field RemoveModel fun(models: number|string|(number|string)[], names?: string[])
---@field AddZone fun(data: { name: string, coords: vector3, size?: vector3, radius?: number, options: KairoTargetOption[] }): string
---@field RemoveZone fun(id: string)
---@field AddGlobalPed fun(options: KairoTargetOption[])
---@field RemoveGlobalPed fun(names?: string[])
---@field AddGlobalVehicle fun(options: KairoTargetOption[])
---@field RemoveGlobalVehicle fun(names?: string[])

--------------------------------------------------------------------------------
-- UI & TEXTUI
--------------------------------------------------------------------------------

---@class KairoTextUI
---@field Show fun(text: string, icon?: string, position?: 'left'|'right'|'top'|'bottom')
---@field Hide fun()

---@class KairoUI
---@field Notify fun(message: string|table, notifyType?: string, duration?: number)
---@field ProgressBar fun(data: table): boolean
---@field TextUI KairoTextUI
---@field Input fun(data: { header: string, submitText?: string, rows: table[] }): any[]|nil
---@field ContextMenu fun(data: { id: string, title: string, options: table[] })
---@field Alert fun(data: { header: string, content: string, centered?: boolean, cancel?: boolean }): 'confirm'|'cancel'

--------------------------------------------------------------------------------
-- VEHICLE
--------------------------------------------------------------------------------

---@class KairoVehicle
---@field GetProperties fun(vehicle: number): table Complete vehicle mod and status properties.
---@field SetProperties fun(vehicle: number, props: table) Apply properties table to vehicle.
---@field GetFuel fun(vehicle: number): number Current fuel percentage (0.0 to 100.0).
---@field SetFuel fun(vehicle: number, amount: number) Set fuel level.
---@field GiveKeys fun(source: number, vehicle: number, plate?: string)
---@field RemoveKeys fun(source: number, vehicle: number, plate?: string)
---@field HasKeys fun(source: number, vehicle: number, plate?: string): boolean
---@field GeneratePlate fun(format?: string): string Generate unique plate string.
---@field IsPlateTaken fun(plate: string): boolean Check if plate exists in database.

--------------------------------------------------------------------------------
-- BANKING & SOCIETY
--------------------------------------------------------------------------------

---@class KairoBanking
---@field GetAccount fun(name: string): { name: string, balance: number }|nil
---@field AddMoney fun(name: string, amount: number, reason?: string): boolean
---@field RemoveMoney fun(name: string, amount: number, reason?: string): boolean

---@class KairoSociety : KairoBanking

--------------------------------------------------------------------------------
-- DATABASE
--------------------------------------------------------------------------------

---@class KairoDatabase
---@field Execute fun(query: string, params?: table): any Oxmysql query execute.
---@field Scalar fun(query: string, params?: table): any Returns single scalar value.
---@field Single fun(query: string, params?: table): table|nil Returns first row.
---@field Insert fun(query: string, params?: table): number Returns insert ID.
---@field Transaction fun(queries: table[], params?: table): boolean Executes transaction batch.
---@field GetPlayerVehicles fun(identifier: string): table[] Returns array of owned vehicles.
---@field GetVehicleByPlate fun(plate: string): table|nil Returns single vehicle record by plate.
---@field SaveVehicleProps fun(plate: string, props: table): boolean Updates vehicle props/mods in DB.
---@field SetVehicleStored fun(plate: string, stored: boolean, garage?: string): boolean
---@field IsPlateTaken fun(plate: string): boolean Check DB table for existing plate.

--------------------------------------------------------------------------------
-- SERVICES (DISPATCH, DOORLOCK, APPEARANCE, PHONE, AMBULANCE, PRISON)
--------------------------------------------------------------------------------

---@class KairoDispatch
---@field CreateAlert fun(data: { code: string, title: string, message?: string, coords?: vector3, jobs?: string[], sprite?: number, color?: number, scale?: number, sound?: string })

---@class KairoDoorlock
---@field GetState fun(doorId: number|string): boolean|number Returns lock state (true = locked).
---@field SetState fun(doorId: number|string, state: boolean|number)

---@class KairoAppearance
---@field GetPedAppearance fun(ped?: number): table Returns skin, hair, clothes and props table.
---@field SetPedAppearance fun(ped: number, appearance: table) Applies appearance table.
---@field OpenMenu fun(customizer?: string) Opens wardrobe or clothing customization menu.

---@class KairoPhone
---@field SendNotification fun(source: number, data: { title: string, content?: string, icon?: string, duration?: number })
---@field AddContact fun(source: number, contact: { name: string, number: string }): boolean

---@class KairoAmbulance
---@field Revive fun(source: number) Revives downed player and clears death state.
---@field Heal fun(source: number) Restores health and cures injuries.
---@field IsDead fun(source: number): boolean Check if player is unconscious or dead.
---@field SetDeathStatus fun(source: number, isDead: boolean) Update death state.

---@class KairoPrison
---@field Jail fun(source: number, time: number, reason?: string) Incarcerate player for minutes.
---@field Unjail fun(source: number) Release player from custody.
---@field IsJailed fun(source: number): boolean Check if player is serving a sentence.
---@field GetRemainingTime fun(source: number): number Remaining minutes in sentence.

---@class KairoServices
---@field Dispatch KairoDispatch
---@field Doorlock KairoDoorlock
---@field Appearance KairoAppearance
---@field Phone KairoPhone
---@field Ambulance KairoAmbulance
---@field Prison KairoPrison

--------------------------------------------------------------------------------
-- LOCALE
--------------------------------------------------------------------------------

---@class KairoLocale
---@field Register fun(lang: string, strings: table<string, string>)
---@field SetLocale fun(lang: string)
---@field T fun(key: string, subs?: table<string, any>): string
