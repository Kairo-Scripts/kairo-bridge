return function(cfg)
    local A = { events = Kairo.Utils.NewEmitter() }

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

    local function normalize(d)
        local ci = d.charinfo or {}
        return {
            identifier = d.citizenid,
            name = ((ci.firstname or '') .. ' ' .. (ci.lastname or '')):match('^%s*(.-)%s*$'),
            job = normalizeJob(d.job), gang = normalizeGang(d.gang),
            money = { cash = (d.money or {}).cash or 0, bank = (d.money or {}).bank or 0 },
            metadata = d.metadata or {},
        }
    end

    function A.IsLoaded() return LocalPlayer.state.isLoggedIn == true end
    function A.GetPlayerData()
        local d = cfg.getPlayerData()
        return d and d.citizenid and normalize(d) or nil
    end
    function A.GetIdentifier() local d = cfg.getPlayerData(); return d and d.citizenid or nil end
    function A.GetJob() local d = cfg.getPlayerData(); return d and normalizeJob(d.job) or nil end
    function A.GetMoney(account)
        local d = cfg.getPlayerData()
        return d and d.money and d.money[account] or 0
    end
    function A.GetMetadata(key)
        local d = cfg.getPlayerData()
        return d and d.metadata and d.metadata[key] or nil
    end

    RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
        CreateThread(function()
            Wait(0) -- let the framework finish updating PlayerData first
            A.events.emit('playerLoaded', A.GetPlayerData())
        end)
    end)
    RegisterNetEvent('QBCore:Client:OnPlayerUnload', function() A.events.emit('playerUnloaded') end)
    RegisterNetEvent('QBCore:Client:OnJobUpdate', function(job) A.events.emit('jobUpdate', normalizeJob(job)) end)

    return A
end
