--[[
    Kairo.Heartbeat — Heartbeat (heartbeat.re) public-usage API. SERVER ONLY.
    The real client (cache, rate-limit handling, API key) lives in the kairo-bridge resource; this file is the thin
    proxy consumers get, so all resources share one cache/cooldown and the key is never loaded into their context.

      Kairo.Heartbeat.IsConfigured()
      Kairo.Heartbeat.GetUsage(name?, opts?)       -- adoption of a resource (default kairo-bridge), flattened
      Kairo.Heartbeat.Resource(name, opts?)        Kairo.Heartbeat.Resources(opts?)   Kairo.Heartbeat.ResourceServers(name, opts?)
      Kairo.Heartbeat.Related(name, opts?)         Kairo.Heartbeat.Momentum(opts?)    Kairo.Heartbeat.Search(q, opts?)
      Kairo.Heartbeat.Servers(opts?)  Server(joinId, opts?)  ServerResources(joinId, opts?)  Similar(joinId, opts?)
      Kairo.Heartbeat.Stats()  StatsHistory(hours?)  Regions(limit?)  Frameworks(opts?)

    Every call returns  body, err, stale  (see modules/heartbeat/server.lua). Never throws.
    Setup: server.cfg ->  set kairo_heartbeat_key "<your key>"
]]
local Log = Kairo.Log

local METHODS = {
    'IsConfigured', 'Stats', 'StatsHistory', 'Servers', 'Server', 'ServerResources', 'Similar', 'Resources',
    'Resource', 'ResourceServers', 'Related', 'Momentum', 'Regions', 'Search', 'Frameworks', 'GetUsage',
}

local H = {}

if not Kairo.IsServer then
    for _, name in ipairs(METHODS) do
        H[name] = function()
            Log.warnOnce('hb-client', 'Kairo.Heartbeat is server-only (the API key must never reach clients).')
            return nil, { code = 'server_only', message = 'Heartbeat is server-only' }
        end
    end
    return H
end

for _, name in ipairs(METHODS) do
    H[name] = function(...)
        local res = table.pack(pcall(function(...)
            return exports[Kairo.Bridge]:HeartbeatCall(name, ...)
        end, ...))
        if not res[1] then
            Log.debug('Heartbeat:%s failed: %s', name, tostring(res[2]))
            return nil, { code = 'bridge_unavailable', message = 'kairo-bridge is not running or too old (needs >= 1.2.0)' }
        end
        return table.unpack(res, 2, res.n)
    end
end

return H
