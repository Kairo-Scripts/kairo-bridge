local A = { events = Kairo.Utils.NewEmitter() }
local KEY = 'kairo:data'
local last = LocalPlayer.state[KEY]

local function data() return LocalPlayer.state[KEY] end

function A.IsLoaded() return data() ~= nil end
function A.GetPlayerData() return data() end
function A.GetIdentifier() local d = data(); return d and d.identifier or nil end
function A.GetJob() local d = data(); return d and d.job or nil end
function A.GetMoney(account) local d = data(); return d and d.money[account] or 0 end
function A.GetMetadata(key) local d = data(); return d and d.metadata and d.metadata[key] or nil end

local function jobChanged(a, b)
    if not a or not b then return a ~= b end
    return a.name ~= b.name or a.grade ~= b.grade or a.onDuty ~= b.onDuty
end

AddStateBagChangeHandler(KEY, nil, function(bagName, _, value)
    if not value or GetPlayerFromStateBagName(bagName) ~= PlayerId() then return end
    local old = last
    last = value
    if not old then
        A.events.emit('playerLoaded', value)
    elseif jobChanged(old.job, value.job) then
        A.events.emit('jobUpdate', value.job)
    end
end)

return A
