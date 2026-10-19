--[[
    Kairo.Phone — Smartphone Integrations (Notifications, Mails, Invoices).
    Adapters: lb-phone, qs-smartphone, qb-phone, standalone UI fallback.
]]
local isServer = Kairo.IsServer
local phoneEnv = Kairo.Env.phone or { name = 'standalone' }
local adapter = phoneEnv.name

local Phone = {}

---Send a phone push notification.
---@param src? number Player source (required if called on server)
---@param data table Notification data: { title, message, icon?, duration? }
---@return boolean
function Phone.SendNotification(src, data)
    if not isServer then
        data = src -- on client, first argument is data
    end
    if type(data) ~= 'table' then return false end
    local title = data.title or 'Phone'
    local message = data.message or ''

    if isServer then
        src = tonumber(src)
        if not src then return false end

        if adapter == 'lb' and exports['lb-phone'] then
            exports['lb-phone']:SendNotification(src, {
                title = title,
                content = message,
                icon = data.icon or 'bell',
                duration = data.duration or 5000,
            })
            return true
        elseif adapter == 'qs' then
            TriggerClientEvent('qs-smartphone:client:notify', src, {
                title = title,
                text = message,
                duration = data.duration or 5000,
            })
            return true
        elseif adapter == 'qb' then
            TriggerClientEvent('qb-phone:client:CustomNotification', src, title, message, data.icon or 'fas fa-phone', '#2563eb', data.duration or 5000)
            return true
        end

        -- Standalone fallback
        Kairo.UI.Notify(src, { title = title, description = message, type = 'info', duration = data.duration or 5000 })
        return true
    else
        -- Client-side
        if adapter == 'lb' and exports['lb-phone'] then
            exports['lb-phone']:SendNotification({
                title = title,
                content = message,
                icon = data.icon or 'bell',
                duration = data.duration or 5000,
            })
            return true
        end

        Kairo.UI.Notify({ title = title, description = message, type = 'info', duration = data.duration or 5000 })
        return true
    end
end

---Send an email to a player's in-game smartphone.
---@param src number Player source
---@param data table { sender, subject, message }
---@return boolean
function Phone.SendMail(src, data)
    if not isServer then return false end
    src = tonumber(src)
    if not src or type(data) ~= 'table' then return false end

    local sender = data.sender or 'System'
    local subject = data.subject or 'No Subject'
    local message = data.message or ''

    if adapter == 'lb' and exports['lb-phone'] then
        local num = exports['lb-phone']:GetEquippedPhoneNumber(src)
        if num then
            exports['lb-phone']:SendMail({
                to = num,
                sender = sender,
                subject = subject,
                message = message,
            })
            return true
        end
    elseif adapter == 'qs' then
        TriggerClientEvent('qs-smartphone:client:sendNewMail', src, {
            sender = sender,
            subject = subject,
            message = message,
        })
        return true
    elseif adapter == 'qb' then
        TriggerClientEvent('qb-phone:client:NewMailNotify', src, {
            sender = sender,
            subject = subject,
            message = message,
        })
        return true
    end

    Phone.SendNotification(src, { title = 'New Email: ' .. subject, message = ('From: %s\n%s'):format(sender, message) })
    return true
end

---Send a bill / invoice to a player.
---@param src number Target player source
---@param data table { title, amount, sender, account }
---@return boolean
function Phone.CreateInvoice(src, data)
    if not isServer then return false end
    src = tonumber(src)
    if not src or type(data) ~= 'table' then return false end

    local title = data.title or 'Invoice'
    local amount = tonumber(data.amount) or 100
    local sender = data.sender or 'Business'

    if adapter == 'lb' and exports['lb-phone'] then
        return exports['lb-phone']:CreateInvoice(src, amount, title) == true
    end

    Phone.SendNotification(src, {
        title = 'Bill Received: ' .. title,
        message = ('Amount: $%d | From: %s'):format(amount, sender),
        duration = 8000,
    })
    return true
end

return Phone
