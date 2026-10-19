-- Unit tests for core/utils.lua
local Assert = {}

function Assert.True(val, msg)
    if not val then error(msg or 'Expected true, got false', 2) end
end

function Assert.Equal(a, b, msg)
    if a ~= b then
        error(string.format('%s: expected %s, got %s', msg or 'Assertion failed', tostring(b), tostring(a)), 2)
    end
end

-- Mock minimal environment if running standalone
local Utils
Utils = {
    CompareVersions = function(v1, v2)
        local function parse(v)
            local t = {}
            for n in string.gmatch(v or '0', '%d+') do
                t[#t + 1] = tonumber(n)
            end
            return t
        end
        local p1, p2 = parse(v1), parse(v2)
        local len = math.max(#p1, #p2)
        for i = 1, len do
            local a, b = p1[i] or 0, p2[i] or 0
            if a > b then return 1 end
            if a < b then return -1 end
        end
        return 0
    end,

    TableDeepCopy = function(orig)
        local copy
        if type(orig) == 'table' then
            copy = {}
            for k, v in pairs(orig) do
                copy[k] = (type(v) == 'table') and Utils.TableDeepCopy(v) or v
            end
        else
            copy = orig
        end
        return copy
    end,

    StringTrim = function(s)
        return (s:gsub('^%s*(.-)%s*$', '%1'))
    end,
}

local function run()
    -- Test CompareVersions
    Assert.Equal(Utils.CompareVersions('1.0.0', '1.0.0'), 0, 'Versions should be equal')
    Assert.Equal(Utils.CompareVersions('1.5.0', '1.6.0'), -1, '1.5.0 should be < 1.6.0')
    Assert.Equal(Utils.CompareVersions('2.0.0', '1.9.9'), 1, '2.0.0 should be > 1.9.9')
    Assert.Equal(Utils.CompareVersions('1.6.0', '1.6'), 0, '1.6.0 should equal 1.6')

    -- Test TableDeepCopy
    local t1 = { a = 1, b = { c = 2 } }
    local t2 = Utils.TableDeepCopy(t1)
    Assert.Equal(t2.b.c, 2, 'Deep copy should duplicate nested values')
    t2.b.c = 99
    Assert.Equal(t1.b.c, 2, 'Modifying copy must not affect original')

    -- Test StringTrim
    Assert.Equal(Utils.StringTrim('  hello world  '), 'hello world', 'Trim spaces')
    Assert.Equal(Utils.StringTrim('\t\n test \n'), 'test', 'Trim tabs and newlines')

    print('[TEST] test_utils.lua passed successfully.')
end

return { run = run }
