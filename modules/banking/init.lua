--[[
    Kairo.Banking — Unified Banking & Society Module.
]]
local Banking = {}

Banking.Society = Kairo.Require('modules/banking/society.lua')

-- Forward common society methods directly onto Banking
Banking.GetSocietyMoney = Banking.Society.GetMoney
Banking.AddSocietyMoney = Banking.Society.AddMoney
Banking.RemoveSocietyMoney = Banking.Society.RemoveMoney

---Get player bank balance via Framework.
---@param src? number Player source (server-side only)
---@return number
function Banking.GetPlayerBank(src)
    local F = Kairo.Framework
    if Kairo.IsServer then
        return F.GetMoney(src, 'bank') or 0
    else
        return F.GetMoney('bank') or 0
    end
end

---Add money to player bank via Framework.
---@param src number Player source (server-side only)
---@param amount number
---@param reason? string
---@return boolean
function Banking.AddPlayerBank(src, amount, reason)
    if not Kairo.IsServer then return false end
    return Kairo.Framework.AddMoney(src, 'bank', amount, reason or 'banking')
end

---Remove money from player bank via Framework.
---@param src number Player source (server-side only)
---@param amount number
---@param reason? string
---@return boolean
function Banking.RemovePlayerBank(src, amount, reason)
    if not Kairo.IsServer then return false end
    return Kairo.Framework.RemoveMoney(src, 'bank', amount, reason or 'banking')
end

return Banking
