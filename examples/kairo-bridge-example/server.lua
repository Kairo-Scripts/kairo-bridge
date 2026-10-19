Kairo.RequireVersion('1.6.0')
local F = Kairo.Framework

F.OnPlayerLoaded(function(src, player)
    print(('[example] loaded %s (%s) job=%s'):format(player.name, player.identifier, player.job and player.job.name or 'none'))
end)
F.OnPlayerUnloaded(function(src) print('[example] unloaded', src) end)
F.OnJobUpdate(function(src, job) print(('[example] job update %s -> %s (grade %d)'):format(src, job.name, job.grade)) end)
F.OnMoneyChange(function(src, account, newBal, oldBal, reason)
    print(('[example] money change: %d %s %d -> %d (%s)'):format(src, account, oldBal or 0, newBal, reason or 'none'))
end)

-- /kme  -> dump your normalized player object
RegisterCommand('kme', function(src)
    local p = F.GetPlayer(src)
    if not p then return print('[example] player not loaded') end
    print(('[example] %s | id=%s | job=%s:%d duty=%s | cash=%d bank=%d | police? %s'):format(
        p.name, p.identifier, p.job.name, p.job.grade, tostring(p.job.onDuty),
        p.money.cash, p.money.bank, tostring(F.HasJob(src, 'police'))))
end)

-- /kcash 500  -> add cash (server console only, to keep the example safe)
RegisterCommand('kcash', function(src, args)
    if src ~= 0 then return end
    local target, amount = tonumber(args[1]), tonumber(args[2])
    print('[example] AddMoney:', F.AddMoney(target, 'cash', amount, 'example'))
end, true)

-- /kjob <id> police 1 -> set job (server console only)
RegisterCommand('kjob', function(src, args)
    if src ~= 0 then return end
    print('[example] SetJob:', F.SetJob(tonumber(args[1]), args[2], tonumber(args[3]) or 0))
end, true)

-- ------------------------------------------------------------------ Phase 2: inventory
local I = Kairo.Inventory

I.RegisterItems({
    {
        name = 'kairo_demo_item', label = 'Kairo Demo Item', weight = 250, description = 'Example item from kairo-bridge-example',
        onUse = function(src, item) print(('[example] %d used %s (slot %s)'):format(src, item.name, tostring(item.slot))) end,
    },
})

-- /kitem <id> add|remove|count [n]   (server console only)
RegisterCommand('kitem', function(src, args)
    if src ~= 0 then return end
    local target, action, n = tonumber(args[1]), args[2], tonumber(args[3]) or 1
    if action == 'add' then
        print('[example] AddItem:', I.AddItem(target, 'kairo_demo_item', n, { source = 'example' }))
    elseif action == 'remove' then
        print('[example] RemoveItem:', I.RemoveItem(target, 'kairo_demo_item', n))
    else
        print('[example] count:', I.GetItemCount(target, 'kairo_demo_item'), '| image:', I.GetImagePath('kairo_demo_item'))
    end
end, true)

-- /knotifyserver <id> <message>
RegisterCommand('knotifyserver', function(src, args)
    if src ~= 0 then return end
    local target = tonumber(args[1]) or -1
    local msg = args[2] or 'Server broadcast notification!'
    Kairo.UI.Notify(target, msg, 'success', 5000)
    print(('[example] Sent notification to %s: %s'):format(tostring(target), msg))
end, true)

-- ------------------------------------------------------------------ Phase 4: Server Vehicles & Society

local V = Kairo.Vehicle
local Banking = Kairo.Banking
local DB = Kairo.DB

-- /kplate [pattern]  (server console only)
RegisterCommand('kplate', function(src, args)
    if src ~= 0 then return end
    local pattern = args[1]
    local plate = V.GeneratePlate(pattern)
    print('[example] Generated Plate:', plate, '| Taken?', V.IsPlateTaken(plate))
end, true)

-- /ksociety <society> [add|remove] [amount]  (server console only)
RegisterCommand('ksociety', function(src, args)
    if src ~= 0 then return end
    local society = args[1] or 'police'
    local action = args[2]
    local amount = tonumber(args[3]) or 1000

    if action == 'add' then
        local ok = Banking.AddSocietyMoney(society, amount, 'example deposit')
        print(('[example] Add %d to %s: %s | New balance: %d'):format(amount, society, tostring(ok), Banking.GetSocietyMoney(society)))
    elseif action == 'remove' then
        local ok = Banking.RemoveSocietyMoney(society, amount, 'example withdraw')
        print(('[example] Remove %d from %s: %s | New balance: %d'):format(amount, society, tostring(ok), Banking.GetSocietyMoney(society)))
    else
        print(('[example] Society "%s" balance: %d'):format(society, Banking.GetSocietyMoney(society)))
    end
end, true)

-- /kvehkeys <id> <plate>  (server console only)
RegisterCommand('kvehkeys', function(src, args)
    if src ~= 0 then return end
    local target, plate = tonumber(args[1]), args[2]
    if not target or not plate then return print('[example] Usage: kvehkeys <src> <plate>') end
    local ok = V.GiveKeys(target, plate)
    print(('[example] GiveKeys to %d for %s: %s'):format(target, plate, tostring(ok)))
end, true)

-- /kdbveh <identifier>  (server console only)
RegisterCommand('kdbveh', function(src, args)
    if src ~= 0 then return end
    local id = args[1]
    if not id then return print('[example] Usage: kdbveh <identifier>') end
    local list = DB.GetPlayerVehicles(id)
    print(('[example] %s owns %d vehicles'):format(id, #list))
    for i, v in ipairs(list) do
        print(('  [%d] plate=%s garage=%s stored=%s'):format(i, v.plate, tostring(v.garage), tostring(v.stored)))
    end
end, true)

-- ------------------------------------------------------------------ Phase 5: Services Commands

local Prison = Kairo.Prison
local Ambulance = Kairo.Ambulance
local Doorlock = Kairo.Doorlock

-- /kjail <id> <minutes> [reason]  (server console only)
RegisterCommand('kjail', function(src, args)
    if src ~= 0 then return end
    local target, time, reason = tonumber(args[1]), tonumber(args[2]) or 5, args[3] or 'Robbery'
    if not target then return print('[example] Usage: kjail <src> <minutes> [reason]') end
    local ok = Prison.SendToJail(target, time, reason)
    print(('[example] Jailed %d for %d mins: %s'):format(target, time, tostring(ok)))
end, true)

-- /kunjail <id>  (server console only)
RegisterCommand('kunjail', function(src, args)
    if src ~= 0 then return end
    local target = tonumber(args[1])
    if not target then return print('[example] Usage: kunjail <src>') end
    local ok = Prison.ReleaseFromJail(target)
    print(('[example] Released %d from jail: %s'):format(target, tostring(ok)))
end, true)

-- /kreviveserver <id>  (server console only)
RegisterCommand('kreviveserver', function(src, args)
    if src ~= 0 then return end
    local target = tonumber(args[1])
    if not target then return print('[example] Usage: kreviveserver <src>') end
    local ok = Ambulance.Revive(target)
    print(('[example] Revived %d: %s'):format(target, tostring(ok)))
end, true)

-- /kdoorset <doorId> <0|1>  (server console only)
RegisterCommand('kdoorset', function(src, args)
    if src ~= 0 then return end
    local door, state = args[1], tonumber(args[2]) == 1
    if not door then return print('[example] Usage: kdoorset <doorId> <1|0>') end
    local ok = Doorlock.SetState(door, state)
    print(('[example] Set door %s to %s: %s'):format(door, tostring(state), tostring(ok)))
end, true)



