--[[
    Kairo.Doorlock — Door lock management system.
    Adapters: ox_doorlock, qb-doorlock, rcore_doorlock, standalone statebags.
]]
local doorlockEnv = Kairo.Env.doorlock or { name = 'standalone' }
local adapter = doorlockEnv.name

local Doorlock = {}

---Get the locked state of a door.
---@param doorId string|number
---@return boolean true if locked, false if unlocked
function Doorlock.GetState(doorId)
    if doorId == nil then return false end

    if adapter == 'ox' and exports.ox_doorlock then
        local door = exports.ox_doorlock:getDoor(doorId)
        if door then return door.state == 1 or door.state == true end
    elseif adapter == 'qb' and exports['qb-doorlock'] then
        return exports['qb-doorlock']:GetDoorState(doorId) == true
    elseif adapter == 'rcore' and exports['rcore_doorlock'] then
        return exports['rcore_doorlock']:getDoorState(doorId) == true
    end

    -- Standalone statebag check
    local st = GlobalState['kairo:door:' .. tostring(doorId)]
    if st ~= nil then return st == true end
    return false
end

---Set the locked state of a door.
---@param doorId string|number
---@param locked boolean
---@return boolean
function Doorlock.SetState(doorId, locked)
    if doorId == nil then return false end
    locked = locked == true

    if adapter == 'ox' and exports.ox_doorlock then
        exports.ox_doorlock:setDoorState(doorId, locked and 1 or 0)
        return true
    elseif adapter == 'qb' and exports['qb-doorlock'] then
        exports['qb-doorlock']:SetDoorState(doorId, locked)
        return true
    elseif adapter == 'rcore' and exports['rcore_doorlock'] then
        exports['rcore_doorlock']:setDoorState(doorId, locked)
        return true
    end

    -- Standalone statebag
    GlobalState:set('kairo:door:' .. tostring(doorId), locked, true)
    return true
end

---Toggle the locked state of a door.
---@param doorId string|number
---@return boolean The new locked state
function Doorlock.Toggle(doorId)
    local cur = Doorlock.GetState(doorId)
    local new = not cur
    Doorlock.SetState(doorId, new)
    return new
end

return Doorlock
