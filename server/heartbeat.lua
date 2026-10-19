-- Heartbeat API client host. Loads the client once inside the bridge and exposes it to consumers via an export.
local H = Kairo.Require('modules/heartbeat/server.lua')
rawset(Kairo, 'Heartbeat', H) -- the bridge itself talks to the client directly

local allowed = {}
for _, name in ipairs(H.Methods) do allowed[name] = true end

exports('HeartbeatCall', function(method, ...)
    if not allowed[method] then
        return nil, { code = 'bad_args', message = ('unknown Heartbeat method "%s"'):format(tostring(method)) }
    end
    return H[method](...)
end)

if H.IsConfigured() then
    Kairo.Log.debug('Heartbeat API enabled (cache %ss)', tostring(Kairo.Config.Heartbeat and Kairo.Config.Heartbeat.CacheSeconds or 300))
end
