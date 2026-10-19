-- Shared server logic for qb-core and qbx_core (both expose QB-style player objects).
return function(cfg)
    local Log = Kairo.Log
    local A = { events = Kairo.Utils.NewEmitter() }
    local accounts = { cash = 'cash', bank = 'bank' } -- 'black' has no native account in QB/Qbox

    local function normalizeJob(j)
        if type(j) ~= 'table' then return nil end
        local g = type(j.grade) == 'table' and j.grade or {}
        return {
            name = j.name, label = j.label, type = j.type,
            grade = tonumber(g.level) or 0, gradeLabel = g.name,
            onDuty = j.onduty ~= false, isBoss = j.isboss == true,
        }
    end

    local function normalizeGang(g)
        if type(g) ~= 'table' or not g.name then return nil end
        local gr = type(g.grade) == 'table' and g.grade or {}
        return { name = g.name, label = g.label, grade = tonumber(gr.level) or 0, gradeLabel = gr.name, isBoss = g.isboss == true }
    end

    local function fullName(ci)
        ci = ci or {}
        return ((ci.firstname or '') .. ' ' .. (ci.lastname or '')):match('^%s*(.-)%s*$')
    end

    local function normalize(p)
        local d = p.PlayerData
        return {
            source = d.source, identifier = d.citizenid, name = fullName(d.charinfo),
            job = normalizeJob(d.job), gang = normalizeGang(d.gang),
            money = { cash = d.money.cash or 0, bank = d.money.bank or 0 },
            metadata = d.metadata or {}, raw = p,
        }
    end

    function A.GetPlayer(src)
        local p = cfg.getPlayer(src)
        return p and normalize(p) or nil
    end
    function A.GetRaw(src) return cfg.getPlayer(src) end
    function A.IsPlayerLoaded(src) return cfg.getPlayer(src) ~= nil end
    function A.GetIdentifier(src)
        local p = cfg.getPlayer(src)
        return p and p.PlayerData.citizenid or nil
    end
    function A.GetName(src)
        local p = cfg.getPlayer(src)
        return p and fullName(p.PlayerData.charinfo) or nil
    end
    function A.GetJob(src)
        local p = cfg.getPlayer(src)
        return p and normalizeJob(p.PlayerData.job) or nil
    end
    function A.SetJob(src, name, grade)
        local p = cfg.getPlayer(src)
        if not p then return false end
        return p.Functions.SetJob(name, tonumber(grade) or 0) ~= false
    end
    function A.SetDuty(src, state)
        local p = cfg.getPlayer(src)
        if not p then return false end
        p.Functions.SetJobDuty(state == true)
        return true
    end

    function A.GetMoney(src, account)
        local p, key = cfg.getPlayer(src), accounts[account]
        if not p or not key then return 0 end
        return p.PlayerData.money[key] or 0
    end
    function A.AddMoney(src, account, amount, reason)
        local p, key = cfg.getPlayer(src), accounts[account]
        if not p then return false end
        if not key then Log.warnOnce('acct:' .. account, 'Account "%s" is not supported on %s', account, cfg.name) return false end
        return p.Functions.AddMoney(key, amount, reason or 'kairo-bridge') == true
    end
    function A.RemoveMoney(src, account, amount, reason)
        local p, key = cfg.getPlayer(src), accounts[account]
        if not p then return false end
        if not key then Log.warnOnce('acct:' .. account, 'Account "%s" is not supported on %s', account, cfg.name) return false end
        return p.Functions.RemoveMoney(key, amount, reason or 'kairo-bridge') == true
    end

    function A.GetMetadata(src, key)
        local p = cfg.getPlayer(src)
        return p and (p.PlayerData.metadata or {})[key] or nil
    end
    function A.SetMetadata(src, key, value)
        local p = cfg.getPlayer(src)
        if not p then return false end
        p.Functions.SetMetaData(key, value)
        return true
    end

    function A.HasGroup(src, group) return cfg.hasPermission(src, group) == true end

    function A.GetPlayers()
        local list = {}
        for src in pairs(cfg.getPlayers() or {}) do list[#list + 1] = tonumber(src) end
        return list
    end
    function A.GetSourceByIdentifier(identifier)
        local p = cfg.getByIdentifier(identifier)
        return p and p.PlayerData.source or nil
    end

    AddEventHandler('QBCore:Server:PlayerLoaded', function(player)
        if player and player.PlayerData then
            A.events.emit('playerLoaded', player.PlayerData.source, normalize(player))
        end
    end)
    AddEventHandler('QBCore:Server:OnPlayerUnload', function(src) A.events.emit('playerUnloaded', src) end)
    AddEventHandler('QBCore:Server:OnJobUpdate', function(src, job) A.events.emit('jobUpdate', src, normalizeJob(job)) end)
    AddEventHandler('QBCore:Server:OnMoneyChange', function(src, moneyType, amount, operation, reason)
        local p = cfg.getPlayer(src)
        local newBal = p and p.PlayerData and p.PlayerData.money and p.PlayerData.money[moneyType] or 0
        local oldBal = operation == 'add' and (newBal - amount) or (newBal + amount)
        A.events.emit('moneyChange', src, moneyType, newBal, oldBal, reason)
    end)

    return A
end
