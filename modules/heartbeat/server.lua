--[[
    Heartbeat API client (https://heartbeat.re) — SERVER ONLY, runs inside the kairo-bridge resource.
    Written against the Heartbeat OpenAPI spec (v1.0.0). Consumers reach it through Kairo.Heartbeat
    (see modules/heartbeat/init.lua), so every resource shares ONE cache, ONE rate-limit cooldown and the key
    never leaves the bridge.

    Every method returns:  body, err, stale
      body  = decoded JSON (`{ data = ..., observation = ... }` for most endpoints), or nil on failure
      err   = nil | { code, message, status?, apiCode?, retryIn? }
              code: not_configured | unauthorized | not_found | rate_limited | http_error | network | bad_response | bad_args
      stale = true when an expired cached copy was served because the live request failed

    Auth:  server.cfg ->  set kairo_heartbeat_key "your-key"     (use `set`, never `setr`; never put it in config.lua)
]]
local Log = Kairo.Log
local cfg = Kairo.Config.Heartbeat or {}

local KEY_CONVAR = 'kairo_heartbeat_key'
local baseUrl = ((type(cfg.BaseUrl) == 'string' and cfg.BaseUrl or ''):gsub('/+$', ''))
local ttl = math.max(30, tonumber(cfg.CacheSeconds) or 300) * 1000 -- ms, floor protects the rate limit

local SCOPES = { 'live', 'observed' }
local PERIODS = { 'day', 'current' }

local cache, inflight = {}, {}
local cooldownUntil = 0   -- GetGameTimer() ms; set after a 429
local rejectedKey = nil   -- the key value the API answered 401 for (a different key is retried)

local H = {}

-- ---------------------------------------------------------------- small helpers
local function getKey() return GetConvar(KEY_CONVAR, '') end

local function enc(s)
    return (tostring(s):gsub('[^%w%-_%.~]', function(c) return ('%%%02X'):format(c:byte()) end))
end

local function str(v) return type(v) == 'string' and v ~= '' and v or nil end
local function bool(v) if type(v) == 'boolean' then return v end end
local function int(v, min, max)
    v = tonumber(v)
    if not v then return nil end
    v = math.floor(v)
    if min and v < min then v = min end
    if max and v > max then v = max end
    return v
end
local function oneOf(v, list)
    for i = 1, #list do if list[i] == v then return v end end
end

local function buildQuery(params)
    local keys = {}
    for k, v in pairs(params) do if v ~= nil then keys[#keys + 1] = k end end
    table.sort(keys) -- stable order = stable cache key
    local parts = {}
    for _, k in ipairs(keys) do
        local v = params[k]
        if type(v) == 'boolean' then v = v and 'true' or 'false' end
        parts[#parts + 1] = enc(k) .. '=' .. enc(v)
    end
    return #parts > 0 and ('?' .. table.concat(parts, '&')) or ''
end

local function header(headers, name)
    if type(headers) ~= 'table' then return nil end
    for k, v in pairs(headers) do
        if tostring(k):lower() == name then return v end
    end
end

local function fetch(url, key)
    local p = promise.new()
    PerformHttpRequest(url, function(status, body, headers)
        p:resolve({ status = status, body = body, headers = headers })
    end, 'GET', '', {
        ['X-API-Key'] = key,
        ['Accept'] = 'application/json',
        ['User-Agent'] = ('kairo-bridge/%s'):format(Kairo.Version),
    })
    return Citizen.Await(p)
end

-- Turn a raw response into body, err. Also updates cooldown / rejected-key state.
local function interpret(res, key)
    local status = tonumber(res.status) or 0
    if status == 0 then
        return nil, { code = 'network', message = 'request failed (no response from Heartbeat)' }
    end

    local ok, decoded = pcall(json.decode, res.body or '')
    local parsed = ok and type(decoded) == 'table' and decoded or nil
    local apiErr = parsed and type(parsed.error) == 'table' and parsed.error or nil

    if status >= 200 and status < 300 then
        if not parsed then return nil, { code = 'bad_response', status = status, message = 'response was not valid JSON' } end
        return parsed
    end

    local err = { status = status, apiCode = apiErr and apiErr.code, message = apiErr and apiErr.message or ('HTTP ' .. status) }
    if status == 401 then
        rejectedKey = key
        err.code = 'unauthorized'
        err.message = 'Heartbeat rejected the API key (check kairo_heartbeat_key)'
        Log.warnOnce('hb-401:' .. key, 'Heartbeat rejected the API key. Check the kairo_heartbeat_key convar.')
    elseif status == 404 then
        err.code = 'not_found'
    elseif status == 429 then
        local wait = tonumber(header(res.headers, 'retry-after')) or 60
        cooldownUntil = GetGameTimer() + wait * 1000
        err.code, err.retryIn = 'rate_limited', wait
        Log.warn('Heartbeat rate limit hit; pausing requests for %ds', wait)
    else
        err.code = 'http_error'
    end
    return nil, err
end

---@return table|nil body, table|nil err, boolean|nil stale
local function request(path, params, fresh)
    local key = getKey()
    if key == '' then
        return nil, { code = 'not_configured', message = 'set the kairo_heartbeat_key convar in server.cfg' }
    end
    if baseUrl == '' then
        return nil, { code = 'not_configured', message = 'Config.Heartbeat.BaseUrl is empty' }
    end
    if rejectedKey == key then
        return nil, { code = 'unauthorized', message = 'API key was rejected earlier; change kairo_heartbeat_key and restart' }
    end

    local ck = path .. buildQuery(params or {})
    local hit = cache[ck]
    if hit and not fresh and hit.exp > GetGameTimer() then return hit.body end

    local now = GetGameTimer()
    if now < cooldownUntil then
        if hit then return hit.body, nil, true end
        return nil, { code = 'rate_limited', message = 'paused after a rate-limit response', retryIn = math.ceil((cooldownUntil - now) / 1000) }
    end

    -- Collapse identical concurrent requests into one HTTP call.
    if inflight[ck] then
        local p = promise.new()
        local waiters = inflight[ck]
        waiters[#waiters + 1] = p
        local r = Citizen.Await(p)
        return r.body, r.err, r.stale
    end
    inflight[ck] = {}

    local body, err, stale
    local ok, res = pcall(fetch, baseUrl .. ck, key)
    if ok then
        body, err = interpret(res, key)
    else
        err = { code = 'network', message = tostring(res) }
    end

    if body then
        cache[ck] = { body = body, exp = GetGameTimer() + ttl }
    elseif hit then
        body, err, stale = hit.body, nil, true -- serve last good copy rather than nothing
    end

    local waiters = inflight[ck]
    inflight[ck] = nil
    for _, p in ipairs(waiters) do p:resolve({ body = body, err = err, stale = stale }) end
    return body, err, stale
end

local function badArgs(msg) return nil, { code = 'bad_args', message = msg } end

-- ---------------------------------------------------------------- public API
-- opts.fresh = true skips the cache (still respects the rate-limit cooldown).

function H.IsConfigured() return getKey() ~= '' and baseUrl ~= '' end

---GET /stats — network totals
function H.Stats(opts) return request('/stats', {}, opts and opts.fresh) end

---GET /stats/history — one point per census (hours: 1-168, default 24)
function H.StatsHistory(hours, opts) return request('/stats/history', { hours = int(hours, 1, 168) }, opts and opts.fresh) end

---GET /servers
---opts: limit(<=200) offset sort(players|peak|capacity|upvotes|resources) q country game(gta5|rdr3) tag minPlayers crawledOnly scope(live|observed)
function H.Servers(opts)
    opts = opts or {}
    return request('/servers', {
        limit = int(opts.limit, 1, 200), offset = int(opts.offset, 0),
        sort = oneOf(opts.sort, { 'players', 'peak', 'capacity', 'upvotes', 'resources' }),
        q = str(opts.q), country = str(opts.country), game = oneOf(opts.game, { 'gta5', 'rdr3' }),
        tag = str(opts.tag), minPlayers = int(opts.minPlayers, 0), crawledOnly = bool(opts.crawledOnly),
        scope = oneOf(opts.scope, SCOPES),
    }, opts.fresh)
end

---GET /servers/{joinId}   opts: history(bool, 48h player history) scope
function H.Server(joinId, opts)
    opts = opts or {}
    if not str(joinId) then return badArgs('Server(joinId): joinId is required') end
    return request('/servers/' .. enc(joinId), { history = bool(opts.history), scope = oneOf(opts.scope, SCOPES) }, opts.fresh)
end

---GET /servers/{joinId}/resources
function H.ServerResources(joinId, opts)
    opts = opts or {}
    if not str(joinId) then return badArgs('ServerResources(joinId): joinId is required') end
    return request('/servers/' .. enc(joinId) .. '/resources', { scope = oneOf(opts.scope, SCOPES) }, opts.fresh)
end

---GET /servers/{joinId}/similar   opts: limit(<=25) scope
function H.Similar(joinId, opts)
    opts = opts or {}
    if not str(joinId) then return badArgs('Similar(joinId): joinId is required') end
    return request('/servers/' .. enc(joinId) .. '/similar', { limit = int(opts.limit, 1, 25), scope = oneOf(opts.scope, SCOPES) }, opts.fresh)
end

---GET /resources — leaderboard
---opts: period(day|current) limit(<=200) offset sort(reach|servers|name) q includeStock scope
function H.Resources(opts)
    opts = opts or {}
    return request('/resources', {
        period = oneOf(opts.period, PERIODS), limit = int(opts.limit, 1, 200), offset = int(opts.offset, 0),
        sort = oneOf(opts.sort, { 'reach', 'servers', 'name' }), q = str(opts.q),
        includeStock = bool(opts.includeStock), scope = oneOf(opts.scope, SCOPES),
    }, opts.fresh)
end

---GET /resources/{name}   opts: period(day|current) history(bool, <=28 days) interval(day|raw) scope
function H.Resource(name, opts)
    opts = opts or {}
    if not str(name) then return badArgs('Resource(name): name is required') end
    return request('/resources/' .. enc(name), {
        period = oneOf(opts.period, PERIODS), history = bool(opts.history),
        interval = oneOf(opts.interval, { 'day', 'raw' }), scope = oneOf(opts.scope, SCOPES),
    }, opts.fresh)
end

---GET /resources/{name}/servers   opts: limit(<=200) offset scope
function H.ResourceServers(name, opts)
    opts = opts or {}
    if not str(name) then return badArgs('ResourceServers(name): name is required') end
    return request('/resources/' .. enc(name) .. '/servers', {
        limit = int(opts.limit, 1, 200), offset = int(opts.offset, 0), scope = oneOf(opts.scope, SCOPES),
    }, opts.fresh)
end

---GET /resources/{name}/related — co-occurrence and inferred dependencies
function H.Related(name, opts)
    opts = opts or {}
    if not str(name) then return badArgs('Related(name): name is required') end
    return request('/resources/' .. enc(name) .. '/related', { scope = oneOf(opts.scope, SCOPES) }, opts.fresh)
end

---GET /resources/momentum   opts: hours(<=168) limit includeStock scope
function H.Momentum(opts)
    opts = opts or {}
    return request('/resources/momentum', {
        hours = int(opts.hours, 1, 168), limit = int(opts.limit, 1), includeStock = bool(opts.includeStock),
        scope = oneOf(opts.scope, SCOPES),
    }, opts.fresh)
end

---GET /regions — players by country
function H.Regions(limit, opts) return request('/regions', { limit = int(limit, 1) }, opts and opts.fresh) end

---GET /search (q needs >= 2 chars)   opts: limit(<=50) scope
function H.Search(q, opts)
    opts = opts or {}
    if type(q) ~= 'string' or #q < 2 then return badArgs('Search(q): q must be at least 2 characters') end
    return request('/search', { q = q, limit = int(opts.limit, 1, 50), scope = oneOf(opts.scope, SCOPES) }, opts.fresh)
end

---GET /frameworks — market share   opts: resources(bool) resourceLimit includeStock
function H.Frameworks(opts)
    opts = opts or {}
    return request('/frameworks', {
        resources = bool(opts.resources), resourceLimit = int(opts.resourceLimit, 1), includeStock = bool(opts.includeStock),
    }, opts.fresh)
end

---Convenience: adoption of one resource (default: kairo-bridge itself), flattened from the Resource schema.
---Counts default to yesterday's UTC mean (countPeriod = 'day'); pass { period = 'current' } for the latest census.
---@return table|nil usage, table|nil err
function H.GetUsage(name, opts)
    name = name or Kairo.Bridge
    local body, err, stale = H.Resource(name, opts)
    if not body then return nil, err end
    local d = type(body.data) == 'table' and body.data or body
    return {
        name = name, servers = d.servers, playerReach = d.playerReach, playersPerServer = d.playersPerServer,
        countPeriod = d.countPeriod, countAt = d.countAt, countStatus = d.countStatus,
        activeNow = d.activeNow, observation = body.observation, stale = stale or false,
    }
end

-- Methods consumers may call through the export (everything above except IsConfigured, which is exported too).
H.Methods = {
    'IsConfigured', 'Stats', 'StatsHistory', 'Servers', 'Server', 'ServerResources', 'Similar', 'Resources',
    'Resource', 'ResourceServers', 'Related', 'Momentum', 'Regions', 'Search', 'Frameworks', 'GetUsage',
}

return H
