--[[
    Kairo.UI — QB-Core UI client adapter.
    Uses native QBCore / qb-input / qb-menu where available, falling back to built-in NUI.
]]
local A = {}
local bridge = 'kairo-bridge'

local QBCore
local function core()
    if not QBCore then
        local ok, res = pcall(function() return exports['qb-core']:GetCoreObject() end)
        if ok and res then QBCore = res end
    end
    return QBCore
end
AddEventHandler('onResourceStop', function(res)
    if res == 'qb-core' then QBCore = nil end
end)

local function isStarted(res)
    local s = GetResourceState(res)
    return s == 'started' or s == 'starting'
end

function A.Notify(message, typ, duration)
    local text = type(message) == 'table' and (message.description or message.title or message.message) or tostring(message)
    typ = typ or (type(message) == 'table' and message.type) or 'primary'
    if typ == 'info' then typ = 'primary' end
    duration = duration or (type(message) == 'table' and message.duration) or 4000

    local c = core()
    if c and c.Functions and c.Functions.Notify then
        c.Functions.Notify(text, typ, duration)
    else
        TriggerEvent('QBCore:Notify', text, typ, duration)
    end
end

local isTextOpen = false
A.TextUI = {
    Show = function(text, opts)
        isTextOpen = true
        if isStarted('qb-core') then
            local pos = (opts and opts.position) or 'left'
            exports['qb-core']:DrawText(text, pos)
        else
            exports[bridge]:NUI_ShowTextUI(text, opts)
        end
    end,
    Hide = function()
        isTextOpen = false
        if isStarted('qb-core') then
            exports['qb-core']:HideText()
        else
            exports[bridge]:NUI_HideTextUI()
        end
    end,
    IsOpen = function()
        return isTextOpen
    end,
}

function A.ProgressBar(opts)
    opts = opts or {}
    local c = core()
    if c and c.Functions and c.Functions.Progressbar then
        local p = promise.new()
        local name = 'kairo_prog_' .. math.random(1000, 9999)
        local duration = tonumber(opts.duration) or 3000
        local label = opts.label or 'Processing...'
        local useWhileDead = opts.useWhileDead or false
        local canCancel = opts.canCancel ~= false

        local dis = opts.disable or {}
        local disControls = {
            disableMovement = dis.move or false,
            disableCarMovement = dis.car or false,
            disableMouse = dis.mouse or false,
            disableCombat = dis.combat or false,
        }

        local anim = opts.anim and {
            animDict = opts.anim.dict,
            anim = opts.anim.clip,
            flags = opts.anim.flag or 49,
        } or nil

        local prop = opts.prop and {
            model = opts.prop.model,
            bone = opts.prop.bone,
            coords = opts.prop.pos,
            rotation = opts.prop.rot,
        } or nil

        c.Functions.Progressbar(name, label, duration, useWhileDead, canCancel, disControls, anim, prop, nil, function()
            p:resolve(true)
        end, function()
            p:resolve(false)
        end)

        return Citizen.Await(p)
    end

    return exports[bridge]:NUI_ProgressBar(opts)
end

function A.Input(header, rows)
    if isStarted('qb-input') then
        local inputs = {}
        for i, row in ipairs(rows or {}) do
            local t = row.type or 'text'
            if t == 'input' then t = 'text' end
            local qbType = (t == 'number' or t == 'password' or t == 'checkbox' or t == 'select') and t or 'text'
            local entry = {
                name = 'field_' .. i,
                text = row.label or ('Field ' .. i),
                type = qbType,
                isRequired = row.required ~= false,
                default = row.default,
            }
            if qbType == 'select' and row.options then
                entry.options = {}
                for _, opt in ipairs(row.options) do
                    if type(opt) == 'table' then
                        entry.options[#entry.options + 1] = { value = opt.value, text = opt.label or opt.value }
                    else
                        entry.options[#entry.options + 1] = { value = opt, text = tostring(opt) }
                    end
                end
            end
            inputs[#inputs + 1] = entry
        end

        local dialog = exports['qb-input']:ShowInput({
            header = header,
            submitText = 'Submit',
            inputs = inputs,
        })
        if not dialog then return nil end

        local out = {}
        for i = 1, #(rows or {}) do
            out[i] = dialog['field_' .. i]
        end
        return out
    end

    return exports[bridge]:NUI_Input(header, rows)
end

function A.ContextMenu(data)
    if isStarted('qb-menu') then
        local menu = {
            {
                header = data.title or 'Menu',
                isMenuHeader = true,
            },
        }
        for _, opt in ipairs(data.options or {}) do
            local actionEvent = 'kairo:internal:menuAction_' .. math.random(10000, 99999)
            local handler
            handler = AddEventHandler(actionEvent, function(args)
                RemoveEventHandler(handler)
                if type(opt.onSelect) == 'function' then
                    pcall(opt.onSelect, args)
                end
            end)

            menu[#menu + 1] = {
                header = opt.title,
                text = opt.description,
                icon = opt.icon,
                disabled = opt.disabled,
                params = {
                    event = actionEvent,
                    args = opt.args,
                },
            }
        end
        exports['qb-menu']:openMenu(menu)
        return true
    end

    return exports[bridge]:NUI_ContextMenu(data)
end

function A.Alert(opts)
    return exports[bridge]:NUI_Alert(opts)
end

return A
