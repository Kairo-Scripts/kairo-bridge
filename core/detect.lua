--[[
    Resource detection. Each category lists candidates in priority order.
    To support a new resource, add one line here and (later) an adapter file.
]]
local Config = Kairo.Config
local Log = Kairo.Log

local registry = {
    framework = {
        default = 'standalone',
        override = Config.Framework,
        order = {
            { id = 'qbox', resource = 'qbx_core' }, -- must come before qb
            { id = 'qb',   resource = 'qb-core' },
            { id = 'esx',  resource = 'es_extended' },
        },
    },
    inventory = {
        default = 'none',
        override = Config.Inventory,
        order = {
            { id = 'ox',     resource = 'ox_inventory' },
            { id = 'qs',     resource = 'qs-inventory' },
            { id = 'codem',  resource = 'codem-inventory' },
            { id = 'tgiann', resource = 'tgiann-inventory' },
            { id = 'core',   resource = 'core_inventory' },
            { id = 'ps',     resource = 'ps-inventory' },
            { id = 'qb',     resource = 'qb-inventory' },
        },
    },
    target = {
        default = 'none',
        override = Config.Target,
        order = {
            { id = 'ox',        resource = 'ox_target' },
            { id = 'sleepless', resource = 'sleepless_interact' },
            { id = 'qb',        resource = 'qb-target' },
        },
    },
    ui = {
        default = 'standalone',
        override = Config.UI,
        order = {
            { id = 'ox_lib', resource = 'ox_lib' },
            { id = 'qb',     resource = 'qb-core' },
            { id = 'esx',    resource = 'es_extended' },
        },
    },
    fuel = {
        default = 'standalone',
        override = Config.Fuel,
        order = {
            { id = 'ox',     resource = 'ox_fuel' },
            { id = 'cdn',    resource = 'cdn-fuel' },
            { id = 'ps',     resource = 'ps-fuel' },
            { id = 'legacy', resource = 'LegacyFuel' },
        },
    },
    keys = {
        default = 'standalone',
        override = Config.VehicleKeys,
        order = {
            { id = 'qbx',     resource = 'qbx_vehiclekeys' },
            { id = 'qb',      resource = 'qb-vehiclekeys' },
            { id = 'wasabi',  resource = 'wasabi_carlock' },
            { id = 'renewed', resource = 'Renewed-Vehiclekeys' },
            { id = 'cd',      resource = 'cd_garage' },
        },
    },
    banking = {
        default = 'standalone',
        override = Config.Banking,
        order = {
            { id = 'renewed', resource = 'Renewed-Banking' },
            { id = 'okok',    resource = 'okokBanking' },
            { id = 'qb',      resource = 'qb-management' },
            { id = 'qb',      resource = 'qb-banking' },
            { id = 'esx',     resource = 'esx_society' },
            { id = 'esx',     resource = 'esx_addonaccount' },
        },
    },
    database = {
        default = 'none',
        order = {
            { id = 'oxmysql', resource = 'oxmysql' },
        },
    },
    dispatch = {
        default = 'standalone',
        override = Config.Dispatch,
        order = {
            { id = 'ps',   resource = 'ps-dispatch' },
            { id = 'cd',   resource = 'cd_dispatch' },
            { id = 'core', resource = 'core_dispatch' },
            { id = 'qs',   resource = 'qs-dispatch' },
        },
    },
    doorlock = {
        default = 'standalone',
        override = Config.Doorlock,
        order = {
            { id = 'ox',    resource = 'ox_doorlock' },
            { id = 'qb',    resource = 'qb-doorlock' },
            { id = 'rcore', resource = 'rcore_doorlock' },
        },
    },
    appearance = {
        default = 'standalone',
        override = Config.Appearance,
        order = {
            { id = 'illenium',        resource = 'illenium-appearance' },
            { id = 'fivem-appearance', resource = 'fivem-appearance' },
            { id = 'qb',              resource = 'qb-clothing' },
            { id = 'esx',             resource = 'esx_skin' },
            { id = 'rcore',           resource = 'rcore_clothes' },
        },
    },
    phone = {
        default = 'standalone',
        override = Config.Phone,
        order = {
            { id = 'lb',   resource = 'lb-phone' },
            { id = 'qs',   resource = 'qs-smartphone-pro' },
            { id = 'qs',   resource = 'qs-smartphone' },
            { id = 'qb',   resource = 'qb-phone' },
            { id = 'npwd', resource = 'npwd' },
        },
    },
    ambulance = {
        default = 'standalone',
        override = Config.Ambulance,
        order = {
            { id = 'qbx',    resource = 'qbx_medical' },
            { id = 'wasabi', resource = 'wasabi_ambulance' },
            { id = 'qb',     resource = 'qb-ambulancejob' },
            { id = 'esx',    resource = 'esx_ambulancejob' },
        },
    },
    prison = {
        default = 'standalone',
        override = Config.Prison,
        order = {
            { id = 'qbx',   resource = 'qbx_prison' },
            { id = 'qb',    resource = 'qb-prison' },
            { id = 'rcore', resource = 'rcore_prison' },
            { id = 'esx',   resource = 'esx-qalle-jail' },
        },
    },
}

local function running(resource)
    local s = GetResourceState(resource)
    return s == 'started' or s == 'starting'
end

local function resolve(category, def)
    local override = def.override
    if override and override ~= 'auto' then
        for _, entry in ipairs(def.order) do
            if entry.id == override then
                if not running(entry.resource) then
                    Log.warn('%s forced to "%s" but %s is %s', category, override, entry.resource, GetResourceState(entry.resource))
                end
                return { name = entry.id, resource = entry.resource, state = GetResourceState(entry.resource), forced = true }
            end
        end
        if override == def.default then
            return { name = def.default, state = 'n/a', forced = true }
        end
        Log.warn('Unknown %s override "%s", falling back to auto-detect', category, tostring(override))
    end

    for _, entry in ipairs(def.order) do
        if running(entry.resource) then
            return { name = entry.id, resource = entry.resource, state = GetResourceState(entry.resource) }
        end
    end
    return { name = def.default, state = 'n/a' }
end

local env = {}
for category, def in pairs(registry) do
    env[category] = resolve(category, def)
end

Log.debug('Detected fw=%s inv=%s target=%s ui=%s fuel=%s keys=%s bank=%s db=%s dispatch=%s door=%s app=%s phone=%s med=%s jail=%s',
    env.framework.name, env.inventory.name, env.target.name, env.ui.name,
    env.fuel.name, env.keys.name, env.banking.name, env.database.name,
    env.dispatch.name, env.doorlock.name, env.appearance.name, env.phone.name, env.ambulance.name, env.prison.name)
return env
