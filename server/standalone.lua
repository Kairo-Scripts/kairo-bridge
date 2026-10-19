-- In-bridge player store for servers running with no framework.
if Kairo.Env.framework.name ~= 'standalone' then return end

local Log = Kairo.Log
local cfg = Kairo.Config.Standalone
local loaded = {} -- src -> data

local function kvpKey(id) return 'kairo:player:' .. id end

local function identifierOf(src)
    return GetPlayerIdentifierByType(src, 'license') or GetPlayerIdentifier(src, 0)
end

local function buildJob(name, grade)
    local def = cfg.Jobs and cfg.Jobs[name]
    return {
        name = name,
        label = def and def.label or name,
        grade = grade,
        gradeLabel = def and def.grades and def.grades[grade] or tostring(grade),
        onDuty = true,
        isBoss = def and def.bossGrade ~= nil and grade >= def.bossGrade or false,
    }
end

local function save(d)
    SetResourceKvp(kvpKey(d.identifier), json.encode({ job = d.job, money = d.money, metadata = d.metadata, items = d.items }))
end

local function publish(src, d)
    Player(src).state:set('kairo:data', {
        identifier = d.identifier, name = d.name, job = d.job, money = d.money, metadata = d.metadata, items = d.items,
    }, true)
end

local function persist(src, d)
    save(d)
    publish(src, d)
end

local function loadPlayer(src)
    local id = identifierOf(src)
    if not id then Log.error('No identifier found for player %s', src) return end

    local dj = cfg.DefaultJob
    local d = {
        identifier = id, name = GetPlayerName(src),
        job = buildJob(dj.name, dj.grade),
        money = { cash = cfg.StartingMoney.cash, bank = cfg.StartingMoney.bank, black = cfg.StartingMoney.black },
        metadata = {}, items = {},
    }
    d.job.label, d.job.gradeLabel = dj.label, dj.gradeLabel

    local raw = GetResourceKvpString(kvpKey(id))
    if raw then
        local ok, saved = pcall(json.decode, raw)
        if ok and type(saved) == 'table' then
            d.job = saved.job or d.job
            for k, v in pairs(saved.money or {}) do d.money[k] = v end
            d.metadata = saved.metadata or {}
            d.items = saved.items or {}
        end
    end

    loaded[src] = d
    publish(src, d)
    TriggerEvent('kairo:server:standalone:playerLoaded', src, d)
end

RegisterNetEvent('kairo:standalone:ready', function()
    local src = source
    if not loaded[src] then loadPlayer(src) end
end)

AddEventHandler('playerDropped', function()
    local src = source
    SetTimeout(0, function() loaded[src] = nil end) -- let other resources read data during their own dropped handlers
end)

-- ------------------------------------------------------------ exports (all keyed by server id)
exports('StandaloneGet', function(src) return loaded[src] end)

exports('StandaloneGetSources', function()
    local list = {}
    for src in pairs(loaded) do list[#list + 1] = src end
    return list
end)

exports('StandaloneFindByIdentifier', function(identifier)
    for src, d in pairs(loaded) do
        if d.identifier == identifier then return src end
    end
end)

exports('StandaloneAddMoney', function(src, account, amount)
    local d = loaded[src]
    if not d or type(amount) ~= 'number' or amount <= 0 or d.money[account] == nil then return false end
    d.money[account] = d.money[account] + amount
    persist(src, d)
    return true
end)

exports('StandaloneRemoveMoney', function(src, account, amount)
    local d = loaded[src]
    if not d or type(amount) ~= 'number' or amount <= 0 or d.money[account] == nil then return false end
    if d.money[account] < amount then return false end
    d.money[account] = d.money[account] - amount
    persist(src, d)
    return true
end)

exports('StandaloneSetJob', function(src, name, grade)
    local d = loaded[src]
    if not d or type(name) ~= 'string' then return false end
    d.job = buildJob(name, tonumber(grade) or 0)
    persist(src, d)
    TriggerEvent('kairo:server:standalone:jobUpdate', src, d.job)
    return true
end)

exports('StandaloneSetDuty', function(src, state)
    local d = loaded[src]
    if not d then return false end
    d.job.onDuty = state == true
    persist(src, d)
    TriggerEvent('kairo:server:standalone:jobUpdate', src, d.job)
    return true
end)

exports('StandaloneSetMeta', function(src, key, value)
    local d = loaded[src]
    if not d or type(key) ~= 'string' then return false end
    d.metadata[key] = value
    persist(src, d)
    return true
end)

-- ------------------------------------------------------------ inventory (name -> count)
local function totalWeight(d)
    local w, reg = 0, Kairo.ItemRegistry or {}
    for name, count in pairs(d.items) do
        local def = reg[name]
        w = w + (def and def.weight or 0) * count
    end
    return w
end

local function canCarry(d, name, count)
    local max = cfg.MaxWeight or 0
    if max <= 0 then return true end
    local def = (Kairo.ItemRegistry or {})[name]
    return totalWeight(d) + (def and def.weight or 0) * count <= max
end

exports('StandaloneItemCount', function(src, name)
    local d = loaded[src]
    return d and d.items[name] or 0
end)

exports('StandaloneItemList', function(src)
    local d = loaded[src]
    return d and d.items or {}
end)

exports('StandaloneItemCanCarry', function(src, name, count)
    local d = loaded[src]
    return d ~= nil and canCarry(d, name, count)
end)

exports('StandaloneItemAdd', function(src, name, count)
    local d = loaded[src]
    if not d or type(name) ~= 'string' or type(count) ~= 'number' or count < 1 then return false end
    if not canCarry(d, name, count) then return false end
    d.items[name] = (d.items[name] or 0) + count
    persist(src, d)
    return true
end)

exports('StandaloneItemRemove', function(src, name, count)
    local d = loaded[src]
    if not d or type(name) ~= 'string' or type(count) ~= 'number' or count < 1 then return false end
    local have = d.items[name] or 0
    if have < count then return false end
    d.items[name] = have - count > 0 and have - count or nil
    persist(src, d)
    return true
end)
