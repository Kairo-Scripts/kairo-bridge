--[[
    Kairo.Framework — one API over ESX / QB / Qbox / standalone.

    SERVER
      GetPlayer(src) -> player|nil      GetIdentifier(src)   GetName(src)
      GetJob(src)                       SetJob(src, name, grade)   SetDuty(src, bool)
      HasJob(src, jobs, minGrade, requireDuty)
      GetMoney(src, account)            AddMoney(src, account, amount, reason)   RemoveMoney(...)
      GetMetadata(src, key)             SetMetadata(src, key, value)
      HasGroup(src, group)              IsPlayerLoaded(src)
      GetPlayers()                      GetPlayersByJob(job, onDutyOnly)
      GetSourceByIdentifier(identifier)
      OnPlayerLoaded(cb(src, player))   OnPlayerUnloaded(cb(src))   OnJobUpdate(cb(src, job))

    CLIENT
      IsLoaded()  GetPlayerData()  GetIdentifier()  GetJob()  HasJob(jobs, minGrade, requireDuty)
      GetMoney(account)  GetMetadata(key)
      OnPlayerLoaded(cb(player))  OnPlayerUnloaded(cb())  OnJobUpdate(cb(job))

    accounts: 'cash' | 'bank' | 'black'
    job shape: { name, label, type?, grade, gradeLabel, onDuty, isBoss }
]]
local env = Kairo.Env.framework
local Log, Utils = Kairo.Log, Kairo.Utils
local isServer = Kairo.IsServer

local adapter = Kairo.Require(('modules/framework/%s/%s.lua'):format(isServer and 'server' or 'client', env.name))

local contract = isServer and {
    'GetPlayer', 'GetIdentifier', 'GetName', 'GetJob', 'SetJob', 'SetDuty',
    'GetMoney', 'AddMoney', 'RemoveMoney', 'GetMetadata', 'SetMetadata',
    'HasGroup', 'IsPlayerLoaded', 'GetPlayers', 'GetSourceByIdentifier',
} or {
    'IsLoaded', 'GetPlayerData', 'GetIdentifier', 'GetJob', 'GetMoney', 'GetMetadata',
}

for _, name in ipairs(contract) do
    if type(adapter[name]) ~= 'function' then
        adapter[name] = function()
            Log.warnOnce('missing:' .. name, 'Framework adapter "%s" does not implement %s()', env.name, name)
        end
    end
end

local Framework = { Name = env.name, Resource = env.resource, IsStandalone = env.name == 'standalone' }
for k, v in pairs(adapter) do
    if k ~= 'events' then Framework[k] = v end
end

local events = adapter.events or Utils.NewEmitter()
function Framework.OnPlayerLoaded(cb) events.on('playerLoaded', cb) end
function Framework.OnPlayerUnloaded(cb) events.on('playerUnloaded', cb) end
function Framework.OnJobUpdate(cb) events.on('jobUpdate', cb) end
function Framework.OnMoneyChange(cb) events.on('moneyChange', cb) end

-- ---------------------------------------------------------------- helpers
local VALID_ACCOUNTS = { cash = true, bank = true, black = true }
local function account(a)
    a = type(a) == 'string' and a:lower() or nil
    if a and VALID_ACCOUNTS[a] then return a end
    Log.warn('Invalid money account "%s" (use cash, bank or black)', tostring(a))
    return nil
end

local function amountOf(n)
    n = tonumber(n)
    if not n or n <= 0 then return nil end
    return math.floor(n)
end

---jobs: 'police' | { 'police', 'ambulance' } | { police = 2, ambulance = 0 }
local function matchJob(job, jobs, minGrade, requireDuty)
    if not job then return false end
    if requireDuty and not job.onDuty then return false end
    local grade = tonumber(job.grade) or 0
    if type(jobs) == 'string' then
        return job.name == jobs and grade >= (minGrade or 0)
    end
    if type(jobs) == 'table' then
        for k, v in pairs(jobs) do
            if type(k) == 'number' then
                if v == job.name and grade >= (minGrade or 0) then return true end
            elseif k == job.name and grade >= (tonumber(v) or 0) then
                return true
            end
        end
    end
    return false
end

-- ---------------------------------------------------------------- wrappers
if isServer then
    local raw = { GetMoney = adapter.GetMoney, AddMoney = adapter.AddMoney, RemoveMoney = adapter.RemoveMoney }

    function Framework.GetMoney(src, acc)
        acc = account(acc)
        if not acc then return 0 end
        return raw.GetMoney(src, acc) or 0
    end

    function Framework.AddMoney(src, acc, amount, reason)
        acc, amount = account(acc), amountOf(amount)
        if not acc or not amount then return false end
        local oldBal = raw.GetMoney(src, acc) or 0
        local ok = raw.AddMoney(src, acc, amount, reason) == true
        if ok then
            local newBal = raw.GetMoney(src, acc) or (oldBal + amount)
            events.emit('moneyChange', src, acc, newBal, oldBal, reason)
        end
        return ok
    end

    function Framework.RemoveMoney(src, acc, amount, reason)
        acc, amount = account(acc), amountOf(amount)
        if not acc or not amount then return false end
        local oldBal = raw.GetMoney(src, acc) or 0
        local ok = raw.RemoveMoney(src, acc, amount, reason) == true
        if ok then
            local newBal = raw.GetMoney(src, acc) or (oldBal - amount)
            events.emit('moneyChange', src, acc, newBal, oldBal, reason)
        end
        return ok
    end

    function Framework.HasJob(src, jobs, minGrade, requireDuty)
        return matchJob(adapter.GetJob(src), jobs, minGrade, requireDuty)
    end

    function Framework.GetPlayersByJob(jobName, onDutyOnly)
        local out = {}
        for _, src in ipairs(adapter.GetPlayers() or {}) do
            local job = adapter.GetJob(src)
            if job and job.name == jobName and (not onDutyOnly or job.onDuty) then
                out[#out + 1] = src
            end
        end
        return out
    end
else
    local rawMoney = adapter.GetMoney

    function Framework.GetMoney(acc)
        acc = account(acc)
        if not acc then return 0 end
        return rawMoney(acc) or 0
    end

    function Framework.HasJob(jobs, minGrade, requireDuty)
        return matchJob(adapter.GetJob(), jobs, minGrade, requireDuty)
    end
end

if env.name ~= 'standalone' and env.state ~= 'started' and env.state ~= 'starting' then
    Log.warn('Framework "%s" is %s. Make sure %s starts before this resource.', env.name, tostring(env.state), tostring(env.resource))
end

return Framework
