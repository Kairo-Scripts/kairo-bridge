--[[
    Kairo.Services.Ambulance (Kairo.Ambulance) — Healthcare, Death & Revive Hooks.
    Adapters: qbx_medical, wasabi_ambulance, qb-ambulancejob, esx_ambulancejob, standalone native.
]]
local isServer = Kairo.IsServer
local medEnv = Kairo.Env.ambulance or { name = 'standalone' }
local adapter = medEnv.name

local Ambulance = {}
local events = Kairo.Utils.NewEmitter()

Ambulance.OnPlayerDeath = function(cb) events.on('death', cb) end
Ambulance.OnPlayerRevive = function(cb) events.on('revive', cb) end

if isServer then
    ---Revive a player.
    ---@param src number
    ---@return boolean
    function Ambulance.Revive(src)
        src = tonumber(src)
        if not src then return false end

        if adapter == 'qbx' and exports.qbx_medical then
            exports.qbx_medical:Revive(src)
            return true
        elseif adapter == 'qb' then
            TriggerClientEvent('hospital:client:Revive', src)
            return true
        elseif adapter == 'esx' then
            TriggerClientEvent('esx_ambulancejob:revive', src)
            return true
        end

        TriggerClientEvent('kairo:medical:revive', src)
        return true
    end

    ---Heal a player.
    ---@param src number
    ---@param amount? number
    ---@return boolean
    function Ambulance.Heal(src, amount)
        src = tonumber(src)
        if not src then return false end
        TriggerClientEvent('kairo:medical:heal', src, amount or 100)
        return true
    end

    ---Check if a player is dead.
    ---@param src number
    ---@return boolean
    function Ambulance.IsDead(src)
        src = tonumber(src)
        if not src then return false end

        local p = Kairo.Framework.GetPlayer(src)
        if p and p.metadata then
            return p.metadata.isdead == true or p.metadata.inlaststand == true
        end
        return Player(src).state.isDead == true
    end

    return Ambulance
end

-- CLIENT

---Check if local player is dead or unconscious.
---@return boolean
function Ambulance.IsDead()
    local ped = PlayerPedId()
    if IsEntityDead(ped) or IsPedFatallyInjured(ped) then return true end

    if adapter == 'qbx' and exports.qbx_medical then
        return exports.qbx_medical:isDead() == true
    end

    local d = Kairo.Framework.GetPlayerData()
    if d and d.metadata then
        return d.metadata.isdead == true or d.metadata.inlaststand == true
    end

    return LocalPlayer.state.isDead == true
end

---Revive the local player ped.
function Ambulance.Revive()
    if adapter == 'qbx' then
        TriggerEvent('qbx_medical:client:playerRevived')
        return true
    elseif adapter == 'qb' then
        TriggerEvent('hospital:client:Revive')
        return true
    elseif adapter == 'esx' then
        TriggerEvent('esx_ambulancejob:revive')
        return true
    end

    -- Standalone native revive
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, heading, true, false)
    SetEntityHealth(ped, 200)
    ClearPedBloodDamage(ped)
    ClearPedTasksImmediately(ped)
    events.emit('revive')
    return true
end

---Heal the local player ped.
---@param amount? number
function Ambulance.Heal(amount)
    amount = tonumber(amount) or 100
    local ped = PlayerPedId()
    local cur = GetEntityHealth(ped)
    SetEntityHealth(ped, math.min(200, cur + amount))
    return true
end

-- Native health monitor thread for death & revive event emitting
CreateThread(function()
    local wasDead = false
    while true do
        Wait(500)
        local dead = Ambulance.IsDead()
        if dead and not wasDead then
            wasDead = true
            events.emit('death')
        elseif not dead and wasDead then
            wasDead = false
            events.emit('revive')
        end
    end
end)

RegisterNetEvent('kairo:medical:revive', function()
    Ambulance.Revive()
end)

RegisterNetEvent('kairo:medical:heal', function(amount)
    Ambulance.Heal(amount)
end)

return Ambulance
