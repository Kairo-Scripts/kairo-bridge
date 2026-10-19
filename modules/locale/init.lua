--[[
    Kairo.Locale — Lightweight, zero-dependency locale & phrase interpolation system.

    Usage:
        Kairo.Locale.T('press_to_interact', { label = 'Open Safe' })
        Kairo.Locale('confirm')
        Kairo.Locale.Register('fr', { confirm = 'Confirmer', cancel = 'Annuler' })
        Kairo.Locale.SetLocale('fr')
]]
local Log = Kairo.Log
local currentLocale = Kairo.Config.Locale or 'en'
local dictionaries = {}

local Locale = {}

-- Load default English dictionary from locales/en.lua
local ok, enDict = pcall(function() return Kairo.Require('locales/en.lua') end)
if ok and type(enDict) == 'table' then
    dictionaries['en'] = enDict
else
    dictionaries['en'] = {}
end

---Register or extend phrases for a language code.
---@param lang string Language identifier (e.g., 'en', 'fr', 'es')
---@param phrases table Key-value table of phrase strings
function Locale.Register(lang, phrases)
    if type(lang) ~= 'string' or type(phrases) ~= 'table' then return false end
    lang = lang:lower()
    dictionaries[lang] = dictionaries[lang] or {}
    for k, v in pairs(phrases) do
        dictionaries[lang][k] = v
    end
    return true
end

---Set the current active locale.
---@param lang string
function Locale.SetLocale(lang)
    if type(lang) ~= 'string' or lang == '' then return false end
    currentLocale = lang:lower()
    return true
end

---Get the current active locale.
---@return string
function Locale.GetLocale()
    return currentLocale
end

---Get all registered phrases for a language (or current locale if omitted).
---@param lang? string
---@return table
function Locale.GetAll(lang)
    lang = (lang or currentLocale):lower()
    return dictionaries[lang] or dictionaries['en'] or {}
end

---Translate a key with optional variable interpolation.
---@param key string Phrase key
---@param data? table|string|number Data for interpolation (named %{var} or indexed %s)
---@return string
function Locale.T(key, data)
    if type(key) ~= 'string' then return tostring(key) end
    local dict = dictionaries[currentLocale] or dictionaries['en'] or {}
    local phrase = dict[key] or (dictionaries['en'] and dictionaries['en'][key]) or key

    if data == nil then
        return phrase
    end

    if type(data) == 'table' then
        -- Interpolate %{key}
        phrase = phrase:gsub('%%{(%w+)}', function(var)
            return data[var] ~= nil and tostring(data[var]) or ('%{' .. var .. '}')
        end)
        -- Also support string.format if integer array is passed
        if #data > 0 then
            pcall(function()
                phrase = string.format(phrase, table.unpack(data))
            end)
        end
    else
        pcall(function()
            phrase = string.format(phrase, data)
        end)
    end

    return phrase
end

setmetatable(Locale, {
    __call = function(_, key, data)
        return Locale.T(key, data)
    end,
})

return Locale
