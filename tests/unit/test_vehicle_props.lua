-- Unit tests for vehicle property structures and sanity checking
local Assert = {}

function Assert.True(val, msg)
    if not val then error(msg or 'Expected true, got false', 2) end
end

function Assert.Equal(a, b, msg)
    if a ~= b then
        error(string.format('%s: expected %s, got %s', msg or 'Assertion failed', tostring(b), tostring(a)), 2)
    end
end

local function run()
    local sampleProps = {
        model = 1349725340,
        plate = 'TEST1234',
        plateIndex = 0,
        bodyHealth = 1000.0,
        engineHealth = 1000.0,
        fuelLevel = 100.0,
        dirtLevel = 0.0,
        color1 = 0,
        color2 = 0,
        pearlescentColor = 0,
        wheelColor = 0,
        wheels = 0,
        windowTint = -1,
        neonEnabled = { false, false, false, false },
        neonColor = { 255, 255, 255 },
        tyreSmokeColor = { 255, 255, 255 },
        modSpoilers = -1,
        modFrontBumper = -1,
        modRearBumper = -1,
        modSideSkirt = -1,
        modExhaust = -1,
        modFrame = -1,
        modGrille = -1,
        modHood = -1,
        modFender = -1,
        modRightFender = -1,
        modRoof = -1,
        modEngine = -1,
        modBrakes = -1,
        modTransmission = -1,
        modHorns = -1,
        modSuspension = -1,
        modArmor = -1,
        modTurbo = false,
        modSmokeEnabled = false,
        modXenon = false,
    }

    Assert.True(type(sampleProps.model) == 'number', 'Model must be number hash')
    Assert.Equal(sampleProps.plate, 'TEST1234', 'Plate match')
    Assert.True(sampleProps.bodyHealth >= 0, 'Body health non-negative')
    Assert.True(sampleProps.engineHealth >= 0, 'Engine health non-negative')
    Assert.True(sampleProps.fuelLevel >= 0 and sampleProps.fuelLevel <= 100, 'Fuel level range 0-100')
    Assert.True(#sampleProps.neonEnabled == 4, 'Neon enabled length 4')
    Assert.True(#sampleProps.neonColor == 3, 'Neon color RGB length 3')

    print('[TEST] test_vehicle_props.lua passed successfully.')
end

return { run = run }
