local A = { events = Kairo.Utils.NewEmitter() }

local ESX
local function core()
    if not ESX then ESX = exports['es_extended']:getSharedObject() end
    return ESX
end
AddEventHandler('onResourceStop', function(res)
    if res == 'es_extended' then ESX = nil end
end)

local function normalizeJob(j)
    if type(j) ~= 'table' then return nil end
    return {
        name = j.name, label = j.label, grade = tonumber(j.grade) or 0, gradeLabel = j.grade_label,
        onDuty = j.onDuty ~= false, isBoss = j.grade_name == 'boss',
    }
end

local function normalize(d)
    if type(d) ~= 'table' or not d.job then return nil end
    local money = { cash = d.money or 0, bank = 0, black = 0 }
    for _, acc in ipairs(d.accounts or {}) do
        if acc.name == 'bank' then money.bank = acc.money
        elseif acc.name == 'black_money' then money.black = acc.money
        elseif acc.name == 'money' then money.cash = acc.money end
    end
    local name = ((d.firstName or '') .. ' ' .. (d.lastName or '')):match('^%s*(.-)%s*$')
    return {
        identifier = d.identifier,
        name = name ~= '' and name or GetPlayerName(PlayerId()),
        job = normalizeJob(d.job), money = money, metadata = d.metadata or {},
    }
end

function A.IsLoaded() return core().IsPlayerLoaded() end
function A.GetPlayerData() return normalize(core().GetPlayerData()) end
function A.GetIdentifier() local d = A.GetPlayerData(); return d and d.identifier or nil end
function A.GetJob() local d = A.GetPlayerData(); return d and d.job or nil end
function A.GetMoney(account) local d = A.GetPlayerData(); return d and d.money[account] or 0 end
function A.GetMetadata(key) local d = A.GetPlayerData(); return d and d.metadata[key] or nil end

RegisterNetEvent('esx:playerLoaded', function(xPlayer)
    A.events.emit('playerLoaded', normalize(xPlayer))
end)
RegisterNetEvent('esx:onPlayerLogout', function() A.events.emit('playerUnloaded') end)
RegisterNetEvent('esx:setJob', function(job) A.events.emit('jobUpdate', normalizeJob(job)) end)

return A
