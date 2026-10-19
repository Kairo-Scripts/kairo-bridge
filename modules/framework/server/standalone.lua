-- Thin client for the standalone store that lives inside the kairo-bridge resource itself
-- (KVP is per-resource, so state must be owned by one resource and accessed via exports).
local B = 'kairo-bridge'
local A = { events = Kairo.Utils.NewEmitter() }

local function call(name, ...)
    local e = exports[B]
    return e[name](e, ...)
end

local function normalize(src, d)
    return {
        source = src, identifier = d.identifier, name = d.name,
        job = d.job, money = d.money, metadata = d.metadata or {},
    }
end

function A.GetPlayer(src) local d = call('StandaloneGet', src); return d and normalize(src, d) or nil end
function A.IsPlayerLoaded(src) return call('StandaloneGet', src) ~= nil end
function A.GetIdentifier(src) local d = call('StandaloneGet', src); return d and d.identifier or nil end
function A.GetName(src) local d = call('StandaloneGet', src); return d and d.name or nil end
function A.GetJob(src) local d = call('StandaloneGet', src); return d and d.job or nil end
function A.SetJob(src, name, grade) return call('StandaloneSetJob', src, name, tonumber(grade) or 0) end
function A.SetDuty(src, state) return call('StandaloneSetDuty', src, state == true) end

function A.GetMoney(src, account)
    local d = call('StandaloneGet', src)
    return d and d.money[account] or 0
end
function A.AddMoney(src, account, amount) return call('StandaloneAddMoney', src, account, amount) end
function A.RemoveMoney(src, account, amount) return call('StandaloneRemoveMoney', src, account, amount) end

function A.GetMetadata(src, key)
    local d = call('StandaloneGet', src)
    return d and (d.metadata or {})[key] or nil
end
function A.SetMetadata(src, key, value) return call('StandaloneSetMeta', src, key, value) end

function A.HasGroup(src, group) return IsPlayerAceAllowed(tostring(src), 'group.' .. group) end
function A.GetPlayers() return call('StandaloneGetSources') or {} end
function A.GetSourceByIdentifier(identifier) return call('StandaloneFindByIdentifier', identifier) end

AddEventHandler('kairo:server:standalone:playerLoaded', function(src, d)
    A.events.emit('playerLoaded', src, normalize(src, d))
end)
AddEventHandler('kairo:server:standalone:jobUpdate', function(src, job) A.events.emit('jobUpdate', src, job) end)
AddEventHandler('playerDropped', function() A.events.emit('playerUnloaded', source) end)

return A
