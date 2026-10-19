local Log = {}

local prefix = ('[kairo-bridge:%s]'):format(Kairo.Resource)
local levels = { debug = 1, info = 2, warn = 3, error = 4 }
local tags = { debug = '^5DEBUG', info = '^2INFO', warn = '^3WARN', error = '^1ERROR' }
local once = {}

local function emit(level, fmt, ...)
    local min = Kairo.Config.Debug and 1 or 2
    if levels[level] < min then return end
    local msg = tostring(fmt)
    if select('#', ...) > 0 then
        local ok, formatted = pcall(string.format, msg, ...)
        if ok then
            msg = formatted
        else
            local extra = {}
            for _, v in ipairs({ ... }) do extra[#extra + 1] = tostring(v) end
            msg = msg .. ' ' .. table.concat(extra, ' ')
        end
    end
    print(('%s^7 %s %s^7'):format(tags[level], prefix, msg))
end

function Log.debug(...) emit('debug', ...) end
function Log.info(...) emit('info', ...) end
function Log.warn(...) emit('warn', ...) end
function Log.error(...) emit('error', ...) end

---Warn only the first time `key` is seen.
function Log.warnOnce(key, ...)
    if once[key] then return end
    once[key] = true
    emit('warn', ...)
end

return Log
