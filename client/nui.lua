--[[
    kairo-bridge built-in NUI controller.
    Runs inside the kairo-bridge resource context to handle NUI callbacks and focus management.
]]
local activePromise = nil
local activeMenuCallback = nil
local activeMenuData = nil
local isTextUIOpen = false

local function closeFocus()
    SetNuiFocus(false, false)
end

-- =============================================================================
-- NUI Callbacks
-- =============================================================================
RegisterNUICallback('inputSubmit', function(data, cb)
    closeFocus()
    cb('ok')
    if activePromise then
        local p = activePromise
        activePromise = nil
        p:resolve(data and data.values or {})
    end
end)

RegisterNUICallback('inputCancel', function(_, cb)
    closeFocus()
    cb('ok')
    if activePromise then
        local p = activePromise
        activePromise = nil
        p:resolve(nil)
    end
end)

RegisterNUICallback('menuSelect', function(data, cb)
    closeFocus()
    cb('ok')
    local p = activePromise
    activePromise = nil
    local menuCb = activeMenuCallback
    activeMenuCallback = nil

    if activeMenuData and data and data.index then
        local opt = (activeMenuData.options or {})[data.index]
        if opt and type(opt.onSelect) == 'function' then
            pcall(opt.onSelect, opt.args or data.args)
        end
    end
    activeMenuData = nil

    if menuCb then pcall(menuCb, data) end
    if p then p:resolve(data) end
end)

RegisterNUICallback('menuClose', function(data, cb)
    closeFocus()
    cb('ok')
    local p = activePromise
    activePromise = nil
    activeMenuCallback = nil
    activeMenuData = nil
    if p then p:resolve(nil) end
end)

RegisterNUICallback('alertConfirm', function(_, cb)
    closeFocus()
    cb('ok')
    if activePromise then
        local p = activePromise
        activePromise = nil
        p:resolve('confirm')
    end
end)

RegisterNUICallback('alertCancel', function(_, cb)
    closeFocus()
    cb('ok')
    if activePromise then
        local p = activePromise
        activePromise = nil
        p:resolve('cancel')
    end
end)

RegisterNUICallback('progressComplete', function(_, cb)
    cb('ok')
    if activePromise then
        local p = activePromise
        activePromise = nil
        p:resolve(true)
    end
end)

RegisterNUICallback('progressCancel', function(_, cb)
    cb('ok')
    if activePromise then
        local p = activePromise
        activePromise = nil
        p:resolve(false)
    end
end)

-- =============================================================================
-- Public Interface
-- =============================================================================
local NUI = {}

function NUI.Notify(data)
    if type(data) == 'string' then
        data = { message = data }
    end
    SendNUIMessage({
        action = 'notify',
        data = data,
    })
end

function NUI.ShowTextUI(text, opts)
    opts = opts or {}
    isTextUIOpen = true
    SendNUIMessage({
        action = 'showTextUI',
        data = {
            text = text,
            key = opts.key or 'E',
            icon = opts.icon,
        },
    })
end

function NUI.HideTextUI()
    isTextUIOpen = false
    SendNUIMessage({
        action = 'hideTextUI',
    })
end

function NUI.IsTextUIOpen()
    return isTextUIOpen
end

function NUI.ProgressBar(opts)
    opts = opts or {}
    local duration = tonumber(opts.duration) or 3000
    local label = opts.label or 'Processing...'

    local p = promise.new()
    activePromise = p

    SendNUIMessage({
        action = 'progressBar',
        data = {
            duration = duration,
            label = label,
        },
    })

    -- Optional anim/control disable thread
    if opts.disable or opts.anim then
        CreateThread(function()
            local ped = PlayerPedId()
            if opts.anim and opts.anim.dict and opts.anim.clip then
                RequestAnimDict(opts.anim.dict)
                while not HasAnimDictLoaded(opts.anim.dict) do Wait(10) end
                TaskPlayAnim(ped, opts.anim.dict, opts.anim.clip, 8.0, -8.0, -1, opts.anim.flag or 49, 0, false, false, false)
            end

            local start = GetGameTimer()
            while (GetGameTimer() - start) < duration and activePromise == p do
                Wait(0)
                if opts.canCancel ~= false and IsControlJustPressed(0, 73) then -- X key to cancel
                    SendNUIMessage({ action = 'cancelProgressBar' })
                    break
                end
                if opts.disable then
                    if opts.disable.move then
                        DisableControlAction(0, 30, true) -- D-pad left / right
                        DisableControlAction(0, 31, true) -- D-pad up / down
                        DisableControlAction(0, 36, true) -- Left Ctrl (Duck)
                    end
                    if opts.disable.car then
                        DisablePlayerFiring(ped, true)
                        DisableControlAction(0, 75, true) -- Exit vehicle
                    end
                    if opts.disable.combat then
                        DisableControlAction(0, 24, true) -- Attack
                        DisableControlAction(0, 257, true) -- Attack 2
                        DisableControlAction(0, 25, true) -- Aim
                    end
                end
            end

            if opts.anim and opts.anim.dict and opts.anim.clip then
                StopAnimTask(ped, opts.anim.dict, opts.anim.clip, 1.0)
            end
        end)
    end

    local result = Citizen.Await(p)
    return result == true
end

function NUI.Input(header, rows)
    closeFocus()
    local p = promise.new()
    activePromise = p
    SetNuiFocus(true, true)

    SendNUIMessage({
        action = 'openInput',
        data = {
            header = header,
            rows = rows or {},
        },
    })

    return Citizen.Await(p)
end

function NUI.ContextMenu(data, cb)
    closeFocus()
    activeMenuData = data
    activeMenuCallback = cb
    local p = promise.new()
    activePromise = p
    SetNuiFocus(true, true)

    -- Send to NUI without functions
    local clientOptions = {}
    for i, opt in ipairs(data.options or {}) do
        clientOptions[i] = {
            title = opt.title,
            description = opt.description,
            icon = opt.icon,
            disabled = opt.disabled,
            args = opt.args,
        }
    end

    SendNUIMessage({
        action = 'openMenu',
        data = {
            id = data.id,
            title = data.title,
            subtitle = data.subtitle,
            parent = data.parent,
            options = clientOptions,
        },
    })

    return Citizen.Await(p)
end

function NUI.Alert(opts)
    closeFocus()
    opts = opts or {}
    local p = promise.new()
    activePromise = p
    SetNuiFocus(true, true)

    SendNUIMessage({
        action = 'openAlert',
        data = {
            header = opts.header or 'Alert',
            content = opts.content or '',
            confirmText = opts.confirmText or 'Confirm',
            cancelText = opts.cancelText or 'Cancel',
            cancel = opts.cancel ~= false,
        },
    })

    return Citizen.Await(p)
end

-- Server notification listener
RegisterNetEvent('kairo:ui:notify', function(data)
    NUI.Notify(data)
end)

-- Exports
exports('NUI_Notify', NUI.Notify)
exports('NUI_ShowTextUI', NUI.ShowTextUI)
exports('NUI_HideTextUI', NUI.HideTextUI)
exports('NUI_IsTextUIOpen', NUI.IsTextUIOpen)
exports('NUI_ProgressBar', NUI.ProgressBar)
exports('NUI_Input', NUI.Input)
exports('NUI_ContextMenu', NUI.ContextMenu)
exports('NUI_Alert', NUI.Alert)

return NUI
