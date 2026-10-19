local Utils = {}

---pcall wrapper that logs failures. Returns ok, ...results
function Utils.SafeCall(fn, ...)
    local res = table.pack(pcall(fn, ...))
    if not res[1] then
        Kairo.Log.error('Callback failed: %s', tostring(res[2]))
        return false
    end
    return true, table.unpack(res, 2, res.n)
end

---Call another resource's export without ever throwing. Returns ok, result
function Utils.SafeExport(resource, name, ...)
    local args = table.pack(...)
    local ok, res = pcall(function()
        local e = exports[resource]
        return e[name](e, table.unpack(args, 1, args.n))
    end)
    if not ok then
        Kairo.Log.debug('Export %s:%s failed: %s', resource, name, tostring(res))
        return false
    end
    return true, res
end

function Utils.DeepCopy(value, seen)
    if type(value) ~= 'table' then return value end
    seen = seen or {}
    if seen[value] then return seen[value] end
    local copy = {}
    seen[value] = copy
    for k, v in pairs(value) do copy[Utils.DeepCopy(k, seen)] = Utils.DeepCopy(v, seen) end
    return copy
end

---Returns -1 / 0 / 1 comparing dotted versions ("1.2.10" vs "1.3")
function Utils.CompareVersions(a, b)
    local function parts(v)
        local t = {}
        for n in tostring(v):gmatch('%d+') do t[#t + 1] = tonumber(n) end
        return t
    end
    local pa, pb = parts(a), parts(b)
    for i = 1, math.max(#pa, #pb) do
        local x, y = pa[i] or 0, pb[i] or 0
        if x ~= y then return x < y and -1 or 1 end
    end
    return 0
end

---Tiny event emitter used by framework adapters.
function Utils.NewEmitter()
    local handlers = {}
    local e = {}
    function e.on(name, cb)
        if type(cb) ~= 'function' then return end
        handlers[name] = handlers[name] or {}
        handlers[name][#handlers[name] + 1] = cb
    end
    function e.emit(name, ...)
        local list = handlers[name]
        if not list then return end
        for i = 1, #list do Utils.SafeCall(list[i], ...) end
    end
    return e
end

return Utils
