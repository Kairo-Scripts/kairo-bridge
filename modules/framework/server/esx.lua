local Log = Kairo.Log
local A = { events = Kairo.Utils.NewEmitter() }

local ESX
local function core()
    if not ESX then ESX = exports['es_extended']:getSharedObject() end
    return ESX
end
AddEventHandler('onResourceStop', function(res)
    if res == 'es_extended' then ESX = nil end
end)

local accounts = { bank = 'bank', black = 'black_money' } -- cash uses getMoney()

local function xp(src) return core().GetPlayerFromId(src) end

local function normalizeJob(j)
    if type(j) ~= 'table' then return nil end
    return {
        name = j.name, label = j.label, grade = tonumber(j.grade) or 0, gradeLabel = j.grade_label,
        onDuty = j.onDuty ~= false, isBoss = j.grade_name == 'boss',
    }
end

local function accountMoney(x, key)
    local a = x.getAccount(key)
    return a and a.money or 0
end

local function normalize(x)
    return {
        source = x.source, identifier = x.identifier, name = x.getName(),
        job = normalizeJob(x.getJob()),
        money = { cash = x.getMoney(), bank = accountMoney(x, 'bank'), black = accountMoney(x, 'black_money') },
        metadata = x.getMeta and x.getMeta() or {}, raw = x,
    }
end

function A.GetPlayer(src) local x = xp(src); return x and normalize(x) or nil end
function A.GetRaw(src) return xp(src) end
function A.IsPlayerLoaded(src) return xp(src) ~= nil end
function A.GetIdentifier(src) local x = xp(src); return x and x.identifier or nil end
function A.GetName(src) local x = xp(src); return x and x.getName() or nil end
function A.GetJob(src) local x = xp(src); return x and normalizeJob(x.getJob()) or nil end

function A.SetJob(src, name, grade)
    local x = xp(src)
    if not x then return false end
    local ok, err = pcall(x.setJob, name, tonumber(grade) or 0)
    if not ok then Log.warn('SetJob failed: %s', tostring(err)) end
    return ok
end

-- ESX has no built-in duty system on older versions; this is best-effort for ESX >= 1.10.
function A.SetDuty(src, state)
    local x = xp(src)
    if not x then return false end
    local j = x.getJob()
    local ok = pcall(x.setJob, j.name, j.grade, state == true)
    return ok
end

function A.GetMoney(src, account)
    local x = xp(src)
    if not x then return 0 end
    if account == 'cash' then return x.getMoney() end
    local key = accounts[account]
    return key and accountMoney(x, key) or 0
end
function A.AddMoney(src, account, amount, reason)
    local x = xp(src)
    if not x then return false end
    if account == 'cash' then x.addMoney(amount, reason) return true end
    local key = accounts[account]
    if not key then return false end
    x.addAccountMoney(key, amount, reason)
    return true
end
function A.RemoveMoney(src, account, amount, reason)
    local x = xp(src)
    if not x or A.GetMoney(src, account) < amount then return false end
    if account == 'cash' then x.removeMoney(amount, reason) return true end
    local key = accounts[account]
    if not key then return false end
    x.removeAccountMoney(key, amount, reason)
    return true
end

function A.GetMetadata(src, key)
    local x = xp(src)
    return x and x.getMeta and x.getMeta(key) or nil
end
function A.SetMetadata(src, key, value)
    local x = xp(src)
    if not x or not x.setMeta then return false end
    x.setMeta(key, value)
    return true
end

function A.HasGroup(src, group)
    local x = xp(src)
    if not x then return false end
    local g = x.getGroup()
    if g == group or (group == 'admin' and g == 'superadmin') then return true end
    return IsPlayerAceAllowed(tostring(src), 'group.' .. group)
end

function A.GetPlayers()
    local list = {}
    for _, x in ipairs(core().GetExtendedPlayers() or {}) do list[#list + 1] = x.source end
    return list
end
function A.GetSourceByIdentifier(identifier)
    local x = core().GetPlayerFromIdentifier(identifier)
    return x and x.source or nil
end

AddEventHandler('esx:playerLoaded', function(src, x)
    if x then A.events.emit('playerLoaded', src, normalize(x)) end
end)
AddEventHandler('esx:playerDropped', function(src) A.events.emit('playerUnloaded', src) end)
AddEventHandler('esx:setJob', function(src, job) A.events.emit('jobUpdate', src, normalizeJob(job)) end)
AddEventHandler('esx:setAccountMoney', function(src, accountName, money, reason)
    A.events.emit('moneyChange', src, accountName, money, 0, reason)
end)

return A
