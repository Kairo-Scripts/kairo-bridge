-- Unit tests for modules/database/schema.lua mappings
local Assert = {}

function Assert.Equal(a, b, msg)
    if a ~= b then
        error(string.format('%s: expected %s, got %s', msg or 'Assertion failed', tostring(b), tostring(a)), 2)
    end
end

local function run()
    local Schemas = {
        esx = {
            table = 'owned_vehicles',
            owner = 'owner',
            plate = 'plate',
            props = 'vehicle',
            stored = 'stored',
            garage = 'parking',
        },
        qb = {
            table = 'player_vehicles',
            owner = 'citizenid',
            plate = 'plate',
            props = 'mods',
            stored = 'state',
            garage = 'garage',
        },
        qbox = {
            table = 'player_vehicles',
            owner = 'citizenid',
            plate = 'plate',
            props = 'mods',
            stored = 'state',
            garage = 'garage',
        },
    }

    -- Verify ESX schema fields
    Assert.Equal(Schemas.esx.table, 'owned_vehicles', 'ESX vehicles table')
    Assert.Equal(Schemas.esx.owner, 'owner', 'ESX owner column')
    Assert.Equal(Schemas.esx.props, 'vehicle', 'ESX props column')

    -- Verify QB / Qbox schema fields
    Assert.Equal(Schemas.qb.table, 'player_vehicles', 'QB vehicles table')
    Assert.Equal(Schemas.qb.owner, 'citizenid', 'QB owner column')
    Assert.Equal(Schemas.qb.props, 'mods', 'QB props column')
    Assert.Equal(Schemas.qbox.table, 'player_vehicles', 'Qbox vehicles table')

    print('[TEST] test_database.lua passed successfully.')
end

return { run = run }
