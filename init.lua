--[[
    kairo-bridge consumer import.
    In your script's fxmanifest.lua:
        dependency 'kairo-bridge'
        shared_script '@kairo-bridge/init.lua'
    Then use the global `Kairo` (Kairo.Framework, Kairo.Log, Kairo.Env, ...).
]]
local BRIDGE = 'kairo-bridge'

local existing = rawget(_G, 'Kairo')
if existing and existing.__loaded then return end

if GetResourceState(BRIDGE) == 'missing' then
    print(('^1[kairo-bridge] "%s" needs kairo-bridge but it is not installed.^7'):format(GetCurrentResourceName()))
    return
end

---@type KairoBridge
local K = {
    __loaded = true,
    Bridge = BRIDGE,
    Resource = GetCurrentResourceName(),
    IsServer = IsDuplicityVersion(),
    Version = GetResourceMetadata(BRIDGE, 'version', 0) or '0.0.0',
}
K.IsClient = not K.IsServer

---@type KairoBridge
Kairo = K

local cache = {}

local function loadChunk(path)
    local src = LoadResourceFile(BRIDGE, path)
    if not src then return nil, ('[kairo-bridge] file not found: %s'):format(path) end
    return load(src, ('@@%s/%s'):format(BRIDGE, path))
end

---Load (and cache) a file from the bridge resource into this resource's context.
function K.Require(path)
    local hit = cache[path]
    if hit ~= nil then return hit end
    local chunk, err = loadChunk(path)
    if not chunk then error(err, 2) end
    local result = chunk()
    if result == nil then result = true end
    cache[path] = result
    return result
end

K.Config = K.Require('config.lua')
K.Utils  = K.Require('core/utils.lua')
K.Log    = K.Require('core/logger.lua')

---Call at the top of a script to make sure the installed bridge is new enough.
function K.RequireVersion(minimum)
    if K.Utils.CompareVersions(K.Version, minimum) < 0 then
        K.Log.error('%s requires kairo-bridge >= %s but %s is installed. Please update the bridge.', K.Resource, minimum, K.Version)
        return false
    end
    return true
end

-- Heavier modules load on first access.
local lazy = {
    Env = 'core/detect.lua',
    Framework = 'modules/framework/init.lua',
    Inventory = 'modules/inventory/init.lua',
    Heartbeat = 'modules/heartbeat/init.lua',
    Locale = 'modules/locale/init.lua',
    Target = 'modules/target/init.lua',
    UI = 'modules/ui/init.lua',
    Vehicle = 'modules/vehicle/init.lua',
    Banking = 'modules/banking/init.lua',
    Society = 'modules/banking/society.lua',
    DB = 'modules/database/init.lua',
    Database = 'modules/database/init.lua',
    Services = 'modules/services/init.lua',
    Dispatch = 'modules/dispatch/init.lua',
    Doorlock = 'modules/doorlock/init.lua',
    Appearance = 'modules/appearance/init.lua',
    Phone = 'modules/phone/init.lua',
    Ambulance = 'modules/services/ambulance.lua',
    Prison = 'modules/services/prison.lua',
}

-- Convenient top-level shortcuts for common UI and Locale operations
function K.Notify(...) return K.UI.Notify(...) end
function K.ProgressBar(...) return K.UI.ProgressBar(...) end
function K.Input(...) return K.UI.Input(...) end
function K.ContextMenu(...) return K.UI.ContextMenu(...) end
function K.Alert(...) return K.UI.Alert(...) end
function K._t(...) return K.Locale.T(...) end
function K.T(...) return K.Locale.T(...) end
K.TextUI = setmetatable({}, {
    __index = function(_, key)
        return K.UI.TextUI[key]
    end,
})

setmetatable(K, {
    __index = function(t, key)
        local path = lazy[key]
        if not path then return nil end
        local mod = t.Require(path)
        rawset(t, key, mod)
        return mod
    end,
})

