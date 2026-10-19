--[[
    Kairo.Dispatch — Emergency & Police Dispatch Alerting System.
    Adapters: ps-dispatch, cd_dispatch, core_dispatch, qs-dispatch, standalone fallback.
]]
local Log = Kairo.Log
local isServer = Kairo.IsServer
local dispatchEnv = Kairo.Env.dispatch or { name = 'standalone' }
local adapter = dispatchEnv.name

local Dispatch = {}

---Send an emergency dispatch alert to relevant service units.
---@param data table Alert data: { code, title, message, coords, job, priority, blip }
---@return boolean
function Dispatch.SendAlert(data)
    if type(data) ~= 'table' then return false end
    data.code = data.code or '10-99'
    data.title = data.title or 'Emergency Call'
    data.message = data.message or 'Suspicious activity reported.'
    data.job = data.job or 'police'
    data.priority = data.priority or 1

    if isServer then
        if adapter == 'ps' and exports['ps-dispatch'] then
            TriggerClientEvent('ps-dispatch:client:notify', -1, data)
            return true
        elseif adapter == 'cd' and exports['cd_dispatch'] then
            TriggerEvent('cd_dispatch:AddNotification', {
                job_table = type(data.job) == 'table' and data.job or { data.job },
                coords = data.coords,
                title = data.code .. ' - ' .. data.title,
                message = data.message,
                flash = 1,
                unique_id = tostring(math.random(10000, 99999)),
                blip = {
                    sprite = data.blip and data.blip.sprite or 161,
                    scale = data.blip and data.blip.scale or 1.0,
                    colour = data.blip and data.blip.color or 1,
                    flashes = true,
                    text = data.title,
                    time = data.blip and data.blip.duration or 60,
                }
            })
            return true
        elseif adapter == 'qs' then
            TriggerEvent('qs-dispatch:server:CreateDispatchCall', {
                job = data.job,
                callLocation = data.coords,
                callCode = { code = data.code, snippet = data.title },
                message = data.message,
                flasher = true,
                image = nil,
                blip = {
                    sprite = data.blip and data.blip.sprite or 161,
                    scale = data.blip and data.blip.scale or 1.0,
                    colour = data.blip and data.blip.color or 1,
                    flashes = true,
                    text = data.title,
                    time = (data.blip and data.blip.duration or 60) * 1000,
                }
            })
            return true
        end

        -- Standalone server dispatch broadcast
        local F = Kairo.Framework
        local targets = {}
        if type(data.job) == 'table' then
            for _, j in ipairs(data.job) do
                for _, s in ipairs(F.GetPlayersByJob(j, true) or {}) do targets[s] = true end
            end
        else
            for _, s in ipairs(F.GetPlayersByJob(data.job, true) or {}) do targets[s] = true end
        end

        for s in pairs(targets) do
            TriggerClientEvent('kairo:dispatch:clientAlert', s, data)
        end
        return true
    else
        -- Client-side invocation
        if adapter == 'ps' and exports['ps-dispatch'] then
            exports['ps-dispatch']:CustomAlert({
                coords = data.coords or GetEntityCoords(PlayerPedId()),
                message = data.message,
                dispatchCode = data.code,
                description = data.title,
                radius = 0,
                sprite = data.blip and data.blip.sprite or 161,
                color = data.blip and data.blip.color or 1,
                scale = data.blip and data.blip.scale or 1.0,
                length = data.blip and data.blip.duration or 3,
            })
            return true
        end

        TriggerServerEvent('kairo:dispatch:serverAlert', data)
        return true
    end
end

-- Client-side alert receiver (for standalone fallback)
if not isServer then
    RegisterNetEvent('kairo:dispatch:clientAlert', function(data)
        -- Notification toast
        Kairo.UI.Notify({
            title = ('[%s] %s'):format(data.code or '10-99', data.title or 'Dispatch Alert'),
            description = data.message,
            type = 'error',
            duration = 8000,
        })

        -- Temporary Radar Blip
        if data.coords then
            CreateThread(function()
                local blip = AddBlipForCoord(data.coords.x, data.coords.y, data.coords.z)
                SetBlipSprite(blip, data.blip and data.blip.sprite or 161)
                SetBlipScale(blip, data.blip and data.blip.scale or 1.1)
                SetBlipColour(blip, data.blip and data.blip.color or 1)
                SetBlipAsShortRange(blip, false)
                BeginTextCommandSetBlipName('STRING')
                AddTextComponentSubstringPlayerName(data.title or 'Dispatch Call')
                EndTextCommandSetBlipName(blip)

                if data.blip and data.blip.flash ~= false then
                    SetBlipFlashes(blip, true)
                end

                local duration = (data.blip and data.blip.duration or 60) * 1000
                local expire = GetGameTimer() + duration
                while GetGameTimer() < expire do
                    Wait(1000)
                end
                RemoveBlip(blip)
            end)
        end
    end)
end

return Dispatch
