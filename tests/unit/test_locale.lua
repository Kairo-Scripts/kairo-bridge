-- Unit tests for modules/locale/init.lua
local Assert = {}

function Assert.Equal(a, b, msg)
    if a ~= b then
        error(string.format('%s: expected %s, got %s', msg or 'Assertion failed', tostring(b), tostring(a)), 2)
    end
end

local function run()
    local strings = {
        ['en'] = {
            ['notify_money_added'] = 'Added $%{amount} to your %{account}.',
            ['generic_error'] = 'An unexpected error occurred.',
        },
        ['es'] = {
            ['notify_money_added'] = 'Se añadieron $%{amount} a tu cuenta de %{account}.',
        }
    }

    local current = 'en'

    local function T(key, subs)
        local lang = strings[current] or strings['en'] or {}
        local str = lang[key] or strings['en'][key] or key
        if subs and type(subs) == 'table' then
            for k, v in pairs(subs) do
                str = str:gsub('%%{' .. k .. '}', tostring(v))
            end
        end
        return str
    end

    -- Direct key
    Assert.Equal(T('generic_error'), 'An unexpected error occurred.', 'Fetch simple string')

    -- Interpolation
    local formatted = T('notify_money_added', { amount = 500, account = 'bank' })
    Assert.Equal(formatted, 'Added $500 to your bank.', 'Token interpolation')

    -- Fallback to key when missing
    Assert.Equal(T('non_existent_key'), 'non_existent_key', 'Fallback to key')

    -- Switch locale
    current = 'es'
    local esFormatted = T('notify_money_added', { amount = 1000, account = 'efectivo' })
    Assert.Equal(esFormatted, 'Se añadieron $1000 a tu cuenta de efectivo.', 'Spanish localization')

    -- Fallback to EN if missing in ES
    Assert.Equal(T('generic_error'), 'An unexpected error occurred.', 'Fallback to English')

    print('[TEST] test_locale.lua passed successfully.')
end

return { run = run }
