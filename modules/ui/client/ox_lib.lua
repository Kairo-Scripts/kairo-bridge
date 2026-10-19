--[[
    Kairo.UI — ox_lib client adapter.
]]
local A = {}

function A.Notify(message, typ, duration)
    local data
    if type(message) == 'table' then
        data = message
    else
        data = {
            description = tostring(message),
            type = typ or 'info',
            duration = duration or 4000,
        }
    end
    if exports.ox_lib and exports.ox_lib.notify then
        exports.ox_lib:notify(data)
    else
        -- Fallback to standalone NUI if ox_lib export not directly accessible
        exports['kairo-bridge']:NUI_Notify(data)
    end
end

A.TextUI = {
    Show = function(text, opts)
        if exports.ox_lib and exports.ox_lib.showTextUI then
            exports.ox_lib:showTextUI(text, opts)
        else
            exports['kairo-bridge']:NUI_ShowTextUI(text, opts)
        end
    end,
    Hide = function()
        if exports.ox_lib and exports.ox_lib.hideTextUI then
            exports.ox_lib:hideTextUI()
        else
            exports['kairo-bridge']:NUI_HideTextUI()
        end
    end,
    IsOpen = function()
        if exports.ox_lib and exports.ox_lib.isTextUIOpen then
            return exports.ox_lib:isTextUIOpen() == true
        end
        return exports['kairo-bridge']:NUI_IsTextUIOpen()
    end,
}

function A.ProgressBar(opts)
    if exports.ox_lib and exports.ox_lib.progressBar then
        local oxOpts = {
            duration = opts.duration or 3000,
            label = opts.label or 'Processing...',
            useWhileDead = opts.useWhileDead or false,
            canCancel = opts.canCancel ~= false,
            disable = opts.disable or {},
            anim = opts.anim,
            prop = opts.prop,
        }
        return exports.ox_lib:progressBar(oxOpts) == true
    end
    return exports['kairo-bridge']:NUI_ProgressBar(opts)
end

function A.Input(header, rows)
    if exports.ox_lib and exports.ox_lib.inputDialog then
        return exports.ox_lib:inputDialog(header, rows)
    end
    return exports['kairo-bridge']:NUI_Input(header, rows)
end

function A.ContextMenu(data)
    if exports.ox_lib and exports.ox_lib.registerContext and exports.ox_lib.showContext then
        local id = data.id or ('kairo_menu_' .. math.random(10000, 99999))
        local oxContext = {
            id = id,
            title = data.title or 'Menu',
            menu = data.parent,
            options = {},
        }
        for _, opt in ipairs(data.options or {}) do
            oxContext.options[#oxContext.options + 1] = {
                title = opt.title,
                description = opt.description,
                icon = opt.icon,
                disabled = opt.disabled,
                onSelect = opt.onSelect and function()
                    opt.onSelect(opt.args)
                end or nil,
                args = opt.args,
            }
        end
        exports.ox_lib:registerContext(oxContext)
        exports.ox_lib:showContext(id)
        return true
    end
    return exports['kairo-bridge']:NUI_ContextMenu(data)
end

function A.Alert(opts)
    if exports.ox_lib and exports.ox_lib.alertDialog then
        return exports.ox_lib:alertDialog(opts)
    end
    return exports['kairo-bridge']:NUI_Alert(opts)
end

return A
