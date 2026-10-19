local F = Kairo.Framework
local UI = Kairo.UI
local Target = Kairo.Target
local Locale = Kairo.Locale

F.OnPlayerLoaded(function(p) print('[example:client] loaded', p and p.name) end)
F.OnJobUpdate(function(job) print('[example:client] job ->', job and job.name, job and job.grade) end)

RegisterCommand('kclient', function()
    if not F.IsLoaded() then return print('[example:client] not loaded') end
    local j = F.GetJob()
    print(('[example:client] job=%s grade=%d cash=%d'):format(j.name, j.grade, F.GetMoney('cash')))
end)

RegisterCommand('kitemclient', function()
    local I = Kairo.Inventory
    print(('[example:client] kairo_demo_item x%d (%s)'):format(I.GetItemCount('kairo_demo_item'), I.GetItemLabel('kairo_demo_item')))
end)

-- ------------------------------------------------------------------ Phase 3: UI & Target examples

-- /knotify [type] [message]
RegisterCommand('knotify', function(_, args)
    local typ = args[1] or 'info'
    local msg = args[2] or ('This is a test ' .. typ .. ' notification!')
    UI.Notify({
        title = typ:upper(),
        description = msg,
        type = typ,
        duration = 5000,
    })
end)

-- /ktextui
local textOpen = false
RegisterCommand('ktextui', function()
    textOpen = not textOpen
    if textOpen then
        UI.TextUI.Show('Interact with NPC', { key = 'E', icon = 'interact' })
    else
        UI.TextUI.Hide()
    end
end)

-- /kprogress
RegisterCommand('kprogress', function()
    print('[example:client] Starting progress...')
    local success = UI.ProgressBar({
        duration = 4000,
        label = 'Lockpicking safe...',
        canCancel = true,
        disable = { move = true, combat = true },
    })
    print('[example:client] Progress result:', success)
    UI.Notify({
        title = 'Progress Finished',
        description = success and 'Action completed!' or 'Action cancelled.',
        type = success and 'success' or 'error',
    })
end)

-- /kinput
RegisterCommand('kinput', function()
    CreateThread(function()
        local result = UI.Input('Vehicle Registration', {
            { type = 'input', label = 'Owner Name', placeholder = 'e.g. John Doe', default = 'John' },
            { type = 'number', label = 'Age', min = 18, max = 99, default = 25 },
            { type = 'select', label = 'Vehicle Class', options = { 'Sedan', 'SUV', 'Sports', 'Motorcycle' } },
            { type = 'checkbox', label = 'Insured', default = true },
        })
        if not result then
            print('[example:client] Input cancelled')
            UI.Notify('Form was cancelled.', 'warning')
        else
            print('[example:client] Input result:', json.encode(result))
            UI.Notify(('Registered %s (%s, %d)'):format(result[1], result[3], result[2]), 'success')
        end
    end)
end)

-- /kmenu
RegisterCommand('kmenu', function()
    UI.ContextMenu({
        id = 'example_actions',
        title = 'Actions Menu',
        subtitle = 'Choose an action to perform',
        options = {
            {
                title = 'Inspect Vehicle',
                description = 'Check vehicle status and oil level',
                icon = 'fas fa-wrench',
                onSelect = function()
                    UI.Notify('You inspected the vehicle.', 'info')
                end,
            },
            {
                title = 'Lockpick Vehicle',
                description = 'Attempt to pick the lock',
                icon = 'fas fa-key',
                onSelect = function()
                    ExecuteCommand('kprogress')
                end,
            },
            {
                title = 'Impound Vehicle (Police)',
                description = 'Requires police job grade 2',
                icon = 'fas fa-shield',
                disabled = not F.HasJob('police', 2),
                onSelect = function()
                    UI.Notify('Impounded vehicle.', 'success')
                end,
            },
        },
    })
end)

-- /kalert
RegisterCommand('kalert', function()
    CreateThread(function()
        local res = UI.Alert({
            header = 'Confirm Action',
            content = 'Are you sure you want to proceed with this operation?',
            confirmText = 'Proceed',
            cancelText = 'Abort',
        })
        print('[example:client] Alert decision:', res)
        UI.Notify('You chose: ' .. tostring(res), res == 'confirm' and 'success' or 'error')
    end)
end)

-- /ktarget
RegisterCommand('ktarget', function()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local zoneId = 'demo_zone_' .. math.random(100, 999)

    Target.AddSphereZone(zoneId, coords, 3.0, { debug = true }, {
        {
            name = 'interact_demo',
            label = 'Demo Interaction Zone',
            icon = 'fas fa-star',
            distance = 3.0,
            onSelect = function(data)
                UI.Notify('Interacted with target zone ' .. zoneId, 'success')
            end,
        },
    })
    UI.Notify('Created target zone ' .. zoneId .. ' at your position! Walk near it to interact.', 'info')
end)

-- /klocale
RegisterCommand('klocale', function()
    print('[example:client] Current Locale:', Locale.GetLocale())
    print('[example:client] Translated interact:', Locale.T('interact'))
    print('[example:client] Translated press_to_interact:', Locale.T('press_to_interact', { label = 'Search Trash' }))
    UI.Notify(Locale.T('press_to_interact', { label = 'Search Trash' }), 'info')
end)

-- ------------------------------------------------------------------ Phase 4: Vehicles & Keys

local V = Kairo.Vehicle

-- /kvehprops
RegisterCommand('kvehprops', function()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 then
        local coords = GetEntityCoords(ped)
        veh = GetClosestVehicle(coords.x, coords.y, coords.z, 5.0, 0, 71)
    end
    if veh == 0 then return UI.Notify('No vehicle nearby', 'error') end

    local props = V.GetProperties(veh)
    print('[example:client] Vehicle props:', json.encode(props))
    UI.Notify(('Plate: %s | Fuel: %d%% | Body: %d'):format(props.plate, props.fuelLevel, props.bodyHealth), 'info')
end)

-- /kfuel [amount]
RegisterCommand('kfuel', function(_, args)
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 then return UI.Notify('Must be inside a vehicle', 'error') end

    local amount = tonumber(args[1])
    if amount then
        V.SetFuel(veh, amount)
        UI.Notify(('Fuel set to %d%%'):format(amount), 'success')
    else
        local cur = V.GetFuel(veh)
        UI.Notify(('Current fuel: %d%%'):format(math.floor(cur)), 'info')
    end
end)

-- /klock
RegisterCommand('klock', function()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 then
        local coords = GetEntityCoords(ped)
        veh = GetClosestVehicle(coords.x, coords.y, coords.z, 5.0, 0, 71)
    end
    if veh == 0 then return UI.Notify('No vehicle nearby', 'error') end

    V.ToggleLock(veh)
end)

-- ------------------------------------------------------------------ Phase 5: Services Examples

local S = Kairo.Services
local Dispatch = Kairo.Dispatch
local Appearance = Kairo.Appearance
local Ambulance = Kairo.Ambulance
local Phone = Kairo.Phone

Ambulance.OnPlayerDeath(function()
    print('[example:client] Player died!')
    UI.Notify('You are incapacitated.', 'error', 6000)
end)

Ambulance.OnPlayerRevive(function()
    print('[example:client] Player revived!')
    UI.Notify('You have been revived.', 'success', 4000)
end)

-- /kdispatch
RegisterCommand('kdispatch', function()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    Dispatch.SendAlert({
        code = '10-90',
        title = 'Store Robbery',
        message = 'Alarm triggered at 24/7 Supermarket, suspect armed.',
        coords = coords,
        job = 'police',
        priority = 1,
    })
    UI.Notify('Dispatch alert dispatched!', 'info')
end)

-- /kclothing
RegisterCommand('kclothing', function()
    Appearance.OpenMenu()
end)

-- /krevive
RegisterCommand('krevive', function()
    Ambulance.Revive()
end)

-- /kphone
RegisterCommand('kphone', function()
    Phone.SendNotification({
        title = 'Bank Notice',
        message = 'Direct deposit of $2,500 has cleared.',
        icon = 'dollar-sign',
        duration = 5000,
    })
end)


