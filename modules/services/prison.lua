--[[
    Kairo.Services.Prison (Kairo.Prison) — Jail & Prison Incarceration System.
    Adapters: qbx_prison, qb-prison, rcore_prison, esx-qalle-jail, standalone Bolingbroke Penitentiary.
]]
local isServer = Kairo.IsServer
local jailEnv = Kairo.Env.prison or { name = 'standalone' }
local adapter = jailEnv.name

local Prison = {}
local jailedPlayers = {} -- [src] = remainingMinutes

local PRISON_CELL = vector4(1680.1, 2513.0, 45.5, 0.0)
local PRISON_FREED = vector4(1846.6, 2585.9, 45.7, 270.0)

if isServer then
    ---Send a player to prison.
    ---@param src number Player source
    ---@param timeInMinutes number Incarceration duration in minutes
    ---@param reason? string
    ---@return boolean
    function Prison.SendToJail(src, timeInMinutes, reason)
        src = tonumber(src)
        timeInMinutes = math.max(1, math.floor(tonumber(timeInMinutes) or 5))
        if not src then return false end

        if adapter == 'qbx' and exports.qbx_prison then
            exports.qbx_prison:jailPlayer(src, timeInMinutes)
            return true
        elseif adapter == 'qb' then
            TriggerClientEvent('prison:client:Enter', src, timeInMinutes)
            return true
        elseif adapter == 'rcore' and exports['rcore_prison'] then
            exports['rcore_prison']:jailPlayer(src, timeInMinutes)
            return true
        elseif adapter == 'esx' then
            TriggerClientEvent('esx-qalle-jail:jailPlayer', src, timeInMinutes)
            return true
        end

        -- Standalone incarceration
        jailedPlayers[src] = timeInMinutes
        Player(src).state:set('kairo:jailTime', timeInMinutes, true)
        TriggerClientEvent('kairo:prison:teleport', src, PRISON_CELL)
        Kairo.UI.Notify(src, ('You have been jailed for %d minutes: %s'):format(timeInMinutes, reason or 'Unspecified'), 'error', 10000)
        return true
    end

    ---Release a player from jail early.
    ---@param src number
    ---@return boolean
    function Prison.ReleaseFromJail(src)
        src = tonumber(src)
        if not src then return false end

        if adapter == 'qb' then
            TriggerClientEvent('prison:client:Leave', src)
            return true
        end

        jailedPlayers[src] = nil
        Player(src).state:set('kairo:jailTime', 0, true)
        TriggerClientEvent('kairo:prison:teleport', src, PRISON_FREED)
        Kairo.UI.Notify(src, 'You have been released from prison.', 'success')
        return true
    end

    ---Get remaining jail time in minutes.
    ---@param src number
    ---@return number
    function Prison.GetJailTime(src)
        src = tonumber(src)
        if not src then return 0 end
        return jailedPlayers[src] or (Player(src).state['kairo:jailTime']) or 0
    end

    -- Standalone jail countdown thread
    CreateThread(function()
        while true do
            Wait(60000) -- every minute
            for src, remaining in pairs(jailedPlayers) do
                if GetPlayerPing(src) > 0 then
                    local newTime = remaining - 1
                    if newTime <= 0 then
                        Prison.ReleaseFromJail(src)
                    else
                        jailedPlayers[src] = newTime
                        Player(src).state:set('kairo:jailTime', newTime, true)
                        Kairo.UI.Notify(src, ('Remaining sentence: %d minute(s)'):format(newTime), 'info', 5000)
                    end
                else
                    jailedPlayers[src] = nil
                end
            end
        end
    end)

    return Prison
end

-- CLIENT
RegisterNetEvent('kairo:prison:teleport', function(coords)
    local ped = PlayerPedId()
    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do Wait(10) end
    SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, false)
    if coords.w then SetEntityHeading(ped, coords.w) end
    Wait(500)
    DoScreenFadeIn(500)
end)

return Prison
