--[[
    Kairo.Society — Society & Boss business account management.
    Adapters: Renewed-Banking, okokBanking, qb-management, esx_addonaccount/esx_society, standalone.
]]
local Society = {}
local Log = Kairo.Log
local bankingEnv = Kairo.Env.banking or { name = 'standalone' }
local adapter = bankingEnv.name

local function cleanName(name)
    if type(name) ~= 'string' then return '' end
    return name:gsub('^society_', ''):lower()
end

---Get the current balance of a society account.
---@param societyName string e.g., 'police', 'ambulance', 'mechanic'
---@return number
function Society.GetMoney(societyName)
    societyName = cleanName(societyName)
    if societyName == '' then return 0 end

    if adapter == 'renewed' and exports['Renewed-Banking'] then
        return exports['Renewed-Banking']:getAccountMoney(societyName) or 0
    elseif adapter == 'okok' and exports['okokBanking'] then
        local acc = exports['okokBanking']:GetAccount(societyName)
        return (acc and acc.amount) or 0
    elseif adapter == 'qb' then
        if exports['qb-management'] and exports['qb-management'].GetAccount then
            return exports['qb-management']:GetAccount(societyName) or 0
        elseif exports['qb-banking'] and exports['qb-banking'].GetAccountBalance then
            return exports['qb-banking']:GetAccountBalance(societyName) or 0
        end
    elseif adapter == 'esx' then
        local p = promise.new()
        TriggerEvent('esx_addonaccount:getSharedAccount', 'society_' .. societyName, function(acc)
            p:resolve(acc and acc.money or 0)
        end)
        local ok, res = pcall(Citizen.Await, p)
        return (ok and res) or 0
    end

    -- Standalone KVP storage
    local stored = GetResourceKvpInt('kairo:society:' .. societyName)
    return stored or 0
end

---Add funds to a society account.
---@param societyName string
---@param amount number
---@param reason? string
---@return boolean
function Society.AddMoney(societyName, amount, reason)
    societyName = cleanName(societyName)
    amount = tonumber(amount)
    if societyName == '' or not amount or amount <= 0 then return false end
    amount = math.floor(amount)

    if adapter == 'renewed' and exports['Renewed-Banking'] then
        return exports['Renewed-Banking']:addAccountMoney(societyName, amount) == true
    elseif adapter == 'okok' and exports['okokBanking'] then
        return exports['okokBanking']:AddMoney(societyName, amount) == true
    elseif adapter == 'qb' then
        if exports['qb-management'] and exports['qb-management'].AddMoney then
            exports['qb-management']:AddMoney(societyName, amount)
            return true
        end
    elseif adapter == 'esx' then
        local p = promise.new()
        TriggerEvent('esx_addonaccount:getSharedAccount', 'society_' .. societyName, function(acc)
            if acc then
                acc.addMoney(amount)
                p:resolve(true)
            else
                p:resolve(false)
            end
        end)
        local ok, res = pcall(Citizen.Await, p)
        return ok and res == true
    end

    -- Standalone KVP
    local cur = Society.GetMoney(societyName)
    SetResourceKvpInt('kairo:society:' .. societyName, cur + amount)
    return true
end

---Remove funds from a society account.
---@param societyName string
---@param amount number
---@param reason? string
---@return boolean
function Society.RemoveMoney(societyName, amount, reason)
    societyName = cleanName(societyName)
    amount = tonumber(amount)
    if societyName == '' or not amount or amount <= 0 then return false end
    amount = math.floor(amount)

    local current = Society.GetMoney(societyName)
    if current < amount then return false end

    if adapter == 'renewed' and exports['Renewed-Banking'] then
        return exports['Renewed-Banking']:removeAccountMoney(societyName, amount) == true
    elseif adapter == 'okok' and exports['okokBanking'] then
        return exports['okokBanking']:RemoveMoney(societyName, amount) == true
    elseif adapter == 'qb' then
        if exports['qb-management'] and exports['qb-management'].RemoveMoney then
            return exports['qb-management']:RemoveMoney(societyName, amount) == true
        end
    elseif adapter == 'esx' then
        local p = promise.new()
        TriggerEvent('esx_addonaccount:getSharedAccount', 'society_' .. societyName, function(acc)
            if acc and acc.money >= amount then
                acc.removeMoney(amount)
                p:resolve(true)
            else
                p:resolve(false)
            end
        end)
        local ok, res = pcall(Citizen.Await, p)
        return ok and res == true
    end

    -- Standalone KVP
    SetResourceKvpInt('kairo:society:' .. societyName, current - amount)
    return true
end

return Society
