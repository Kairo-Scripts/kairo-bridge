local Log, Env = Kairo.Log, Kairo.Env
local resourceName = GetCurrentResourceName()
local ready = false

exports('IsReady', function() return ready end)
exports('GetVersion', function() return Kairo.Version end)
exports('GetEnvironment', function()
    return {
        framework = Env.framework.name, inventory = Env.inventory.name, target = Env.target.name,
        version = Kairo.Version,
    }
end)

-- ------------------------------------------------------------ status command
local function consumers()
    local list = {}
    for i = 0, GetNumResources() - 1 do
        local res = GetResourceByFindIndex(i)
        if res and res ~= resourceName and GetResourceState(res) == 'started' then
            local uses = false
            for n = 0, GetNumResourceMetadata(res, 'dependency') - 1 do
                if GetResourceMetadata(res, 'dependency', n) == resourceName then uses = true break end
            end
            if not uses then
                for n = 0, GetNumResourceMetadata(res, 'shared_script') - 1 do
                    if (GetResourceMetadata(res, 'shared_script', n) or ''):find('@' .. resourceName, 1, true) then uses = true break end
                end
            end
            if uses then list[#list + 1] = res end
        end
    end
    return list
end

local function invAdapter()
    local ok, inv = pcall(function() return Kairo.Inventory end)
    return ok and inv and inv.Adapter or 'error (see console)'
end

local function heartbeatLine()
    local ok, hb = pcall(function() return Kairo.Heartbeat end)
    if not ok or not hb then return '  heartbeat : unavailable' end
    if not hb.IsConfigured() then return '  heartbeat : not configured (set kairo_heartbeat_key in server.cfg)' end
    local usage, err = hb.GetUsage()
    if not usage then
        if err and err.code == 'not_found' then return ('  heartbeat : %s is not listed on Heartbeat yet'):format(Kairo.Bridge) end
        return ('  heartbeat : error - %s'):format(err and (err.message or err.code) or 'unknown')
    end
    return ('  heartbeat : %s server(s), %s player reach [%s%s]'):format(
        tostring(usage.servers == nil and 'n/a' or usage.servers), tostring(usage.playerReach == nil and 'n/a' or usage.playerReach),
        tostring(usage.countPeriod or '?'), usage.stale and ', stale' or '')
end

RegisterCommand('kairostatus', function(src)
    local lines = {
        ('kairo-bridge v%s'):format(Kairo.Version),
        ('  framework : %s (%s)%s'):format(Env.framework.name, Env.framework.resource or '-', Env.framework.forced and ' [forced]' or ''),
        ('  inventory : %s (%s) -> adapter: %s, %d registered item(s)'):format(Env.inventory.name, Env.inventory.resource or '-', invAdapter(), (function() local n = 0 for _ in pairs(Kairo.ItemRegistry or {}) do n = n + 1 end return n end)()),
        ('  target    : %s (%s) -> adapter: %s'):format(Env.target.name, Env.target.resource or '-', Env.target.name ~= 'none' and Env.target.name or 'fallback (text-ui)'),
        ('  ui        : %s (%s) -> adapter: %s'):format(Env.ui.name, Env.ui.resource or '-', Env.ui.name),
        ('  vehicle   : keys=%s, fuel=%s'):format(Env.keys.name, Env.fuel.name),
        ('  banking   : %s (%s)'):format(Env.banking.name, Env.banking.resource or '-'),
        ('  database  : %s (%s)'):format(Env.database.name, Env.database.resource or '-'),
        ('  services  : dispatch=%s, door=%s, app=%s, phone=%s, med=%s, jail=%s'):format(
            Env.dispatch.name, Env.doorlock.name, Env.appearance.name,
            Env.phone.name, Env.ambulance.name, Env.prison.name),
        ('  locale    : %s'):format(Kairo.Config.Locale or 'en'),
        ('  debug     : %s'):format(tostring(Kairo.Config.Debug)),
    }
    lines[#lines + 1] = heartbeatLine()
    local used = consumers()
    lines[#lines + 1] = ('  consumers : %d %s'):format(#used, #used > 0 and ('(' .. table.concat(used, ', ') .. ')') or '')
    for _, line in ipairs(lines) do
        if src == 0 then print(line) else TriggerClientEvent('chat:addMessage', src, { args = { 'kairo', line } }) end
    end
end, true) -- restricted: needs ACE command.kairostatus

-- ------------------------------------------------------------ optional update check
local url = Kairo.Config.VersionCheckUrl
if type(url) == 'string' and url ~= '' then
    PerformHttpRequest(url, function(status, body)
        if status ~= 200 then return end
        local ok, data = pcall(json.decode, body)
        local latest = ok and type(data) == 'table' and data.version
        if latest and Kairo.Utils.CompareVersions(Kairo.Version, latest) < 0 then
            Log.warn('Update available: %s -> %s', Kairo.Version, latest)
        end
    end, 'GET')
end

ready = true
Log.info('v%s ready | framework=%s inventory=%s target=%s', Kairo.Version, Env.framework.name, Env.inventory.name, Env.target.name)
TriggerEvent('kairo-bridge:ready')
