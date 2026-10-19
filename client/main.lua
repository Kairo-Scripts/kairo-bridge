exports('IsReady', function() return true end)
exports('GetVersion', function() return Kairo.Version end)

-- Standalone mode: tell the server this player is in-session so it can load their data.
if Kairo.Env.framework.name == 'standalone' then
    CreateThread(function()
        while not NetworkIsSessionStarted() do Wait(250) end
        while not NetworkIsPlayerActive(PlayerId()) do Wait(250) end
        TriggerServerEvent('kairo:standalone:ready')
    end)
end
