--[[
    Kairo.Vehicle — Vehicle Properties (Mods, Colors, Extras, Health, Damage).
    Cross-compatible across ox_lib, qb-core, ESX, and standalone native implementations.
]]
local Props = {}

---Get full normalized vehicle properties.
---@param vehicle number Vehicle entity handle
---@return table|nil
function Props.Get(vehicle)
    if not DoesEntityExist(vehicle) then return nil end

    -- Delegate to ox_lib if available and running
    if exports.ox_lib and exports.ox_lib.getVehicleProperties then
        local p = exports.ox_lib:getVehicleProperties(vehicle)
        if p then return p end
    end

    local colorPrimary, colorSecondary = GetVehicleColours(vehicle)
    local pearlescentColor, wheelColor = GetVehicleExtraColours(vehicle)

    local neonEnabled = {}
    for i = 0, 3 do
        neonEnabled[i + 1] = IsVehicleNeonLightEnabled(vehicle, i) == 1 or IsVehicleNeonLightEnabled(vehicle, i) == true
    end

    local extras = {}
    for id = 0, 20 do
        if DoesExtraExist(vehicle, id) then
            extras[tostring(id)] = IsVehicleExtraTurnedOn(vehicle, id) == 1
        end
    end

    local doorsBroken = {}
    for i = 0, 5 do
        doorsBroken[i + 1] = IsVehicleDoorDamaged(vehicle, i) == 1
    end

    local windowsBroken = {}
    for i = 0, 7 do
        windowsBroken[i + 1] = not IsVehicleWindowIntact(vehicle, i)
    end

    local tyresBurst = {}
    for i = 0, 7 do
        tyresBurst[i + 1] = IsVehicleTyreBurst(vehicle, i, false) == 1
    end

    local nr, ng, nb = GetVehicleNeonLightsColour(vehicle)
    local sr, sg, sb = GetVehicleTyreSmokeColor(vehicle)
    local cr, cg, cb = GetVehicleCustomPrimaryColour(vehicle)
    local c2r, c2g, c2b = GetVehicleCustomSecondaryColour(vehicle)

    local mods = {}
    for i = 0, 49 do
        mods[i] = GetVehicleMod(vehicle, i)
    end

    local plate = GetVehicleNumberPlateText(vehicle)
    if plate then plate = plate:match('^%s*(.-)%s*$') end

    return {
        model = GetEntityModel(vehicle),
        plate = plate,
        plateIndex = GetVehicleNumberPlateTextIndex(vehicle),
        bodyHealth = math.floor(GetVehicleBodyHealth(vehicle) + 0.5),
        engineHealth = math.floor(GetVehicleEngineHealth(vehicle) + 0.5),
        tankHealth = math.floor(GetVehiclePetrolTankHealth(vehicle) + 0.5),
        fuelLevel = math.floor(GetVehicleFuelLevel(vehicle) + 0.5),
        dirtLevel = math.floor(GetVehicleDirtLevel(vehicle) + 0.5),
        oilLevel = math.floor(GetVehicleOilLevel(vehicle) + 0.5),
        color1 = colorPrimary,
        color2 = colorSecondary,
        customColor1 = cr and { cr, cg, cb } or nil,
        customColor2 = c2r and { c2r, c2g, c2b } or nil,
        pearlescentColor = pearlescentColor,
        wheelColor = wheelColor,
        wheels = GetVehicleWheelType(vehicle),
        windowTint = GetVehicleWindowTint(vehicle),
        xenonColor = GetVehicleXenonLightsColor(vehicle),
        neonEnabled = neonEnabled,
        neonColor = { nr or 255, ng or 255, nb or 255 },
        tyreSmokeColor = { sr or 255, sg or 255, sb or 255 },
        extras = extras,
        modSpoilers = mods[0],
        modFrontBumper = mods[1],
        modRearBumper = mods[2],
        modSideSkirt = mods[3],
        modExhaust = mods[4],
        modFrame = mods[5],
        modGrille = mods[6],
        modHood = mods[7],
        modFender = mods[8],
        modRightFender = mods[9],
        modRoof = mods[10],
        modEngine = mods[11],
        modBrakes = mods[12],
        modTransmission = mods[13],
        modHorns = mods[14],
        modSuspension = mods[15],
        modArmor = mods[16],
        modTurbo = IsToggleModOn(vehicle, 18) == 1,
        modSmokeEnabled = IsToggleModOn(vehicle, 20) == 1,
        modXenon = IsToggleModOn(vehicle, 22) == 1,
        modFrontWheels = mods[23],
        modBackWheels = mods[24],
        modCustomTiresF = GetVehicleModVariation(vehicle, 23) == 1,
        modCustomTiresR = GetVehicleModVariation(vehicle, 24) == 1,
        modPlateHolder = mods[25],
        modVanityPlate = mods[26],
        modTrimA = mods[27],
        modOrnaments = mods[28],
        modDashboard = mods[29],
        modDial = mods[30],
        modDoorSpeaker = mods[31],
        modSeats = mods[32],
        modSteeringWheel = mods[33],
        modShifterLeavers = mods[34],
        modAPlate = mods[35],
        modSpeakers = mods[36],
        modTrunk = mods[37],
        modHydrolic = mods[38],
        modEngineBlock = mods[39],
        modAirFilter = mods[40],
        modStruts = mods[41],
        modArchCover = mods[42],
        modAerials = mods[43],
        modTrimB = mods[44],
        modTank = mods[45],
        modWindows = mods[46],
        modLivery = mods[48] ~= -1 and mods[48] or GetVehicleLivery(vehicle),
        livery = GetVehicleLivery(vehicle),
        doorsBroken = doorsBroken,
        windowsBroken = windowsBroken,
        tyresBurst = tyresBurst,
    }
end

---Apply full normalized vehicle properties to a vehicle entity.
---@param vehicle number Vehicle entity handle
---@param props table Properties table
---@return boolean
function Props.Set(vehicle, props)
    if not DoesEntityExist(vehicle) or type(props) ~= 'table' then return false end

    -- Delegate to ox_lib if available
    if exports.ox_lib and exports.ox_lib.setVehicleProperties then
        local ok = pcall(function() exports.ox_lib:setVehicleProperties(vehicle, props) end)
        if ok then return true end
    end

    SetVehicleModKit(vehicle, 0)

    if props.plate then SetVehicleNumberPlateText(vehicle, props.plate) end
    if props.plateIndex then SetVehicleNumberPlateTextIndex(vehicle, props.plateIndex) end
    if props.bodyHealth then SetVehicleBodyHealth(vehicle, props.bodyHealth + 0.0) end
    if props.engineHealth then SetVehicleEngineHealth(vehicle, props.engineHealth + 0.0) end
    if props.tankHealth then SetVehiclePetrolTankHealth(vehicle, props.tankHealth + 0.0) end
    if props.fuelLevel then SetVehicleFuelLevel(vehicle, props.fuelLevel + 0.0) end
    if props.dirtLevel then SetVehicleDirtLevel(vehicle, props.dirtLevel + 0.0) end
    if props.oilLevel then SetVehicleOilLevel(vehicle, props.oilLevel + 0.0) end

    local colorPrimary, colorSecondary = GetVehicleColours(vehicle)
    local pearlescentColor, wheelColor = GetVehicleExtraColours(vehicle)
    SetVehicleColours(vehicle, props.color1 or colorPrimary, props.color2 or colorSecondary)
    SetVehicleExtraColours(vehicle, props.pearlescentColor or pearlescentColor, props.wheelColor or wheelColor)

    if props.customColor1 then
        SetVehicleCustomPrimaryColour(vehicle, props.customColor1[1], props.customColor1[2], props.customColor1[3])
    end
    if props.customColor2 then
        SetVehicleCustomSecondaryColour(vehicle, props.customColor2[1], props.customColor2[2], props.customColor2[3])
    end

    if props.wheels then SetVehicleWheelType(vehicle, props.wheels) end
    if props.windowTint then SetVehicleWindowTint(vehicle, props.windowTint) end

    if props.neonColor then
        SetVehicleNeonLightsColour(vehicle, props.neonColor[1], props.neonColor[2], props.neonColor[3])
    end
    if props.neonEnabled then
        for i = 0, 3 do
            SetVehicleNeonLightEnabled(vehicle, i, props.neonEnabled[i + 1] == true)
        end
    end

    if props.tyreSmokeColor then
        SetVehicleTyreSmokeColor(vehicle, props.tyreSmokeColor[1], props.tyreSmokeColor[2], props.tyreSmokeColor[3])
    end

    if props.xenonColor then SetVehicleXenonLightsColor(vehicle, props.xenonColor) end

    -- Mod mapping: index -> propKey
    local modMap = {
        [0] = props.modSpoilers,
        [1] = props.modFrontBumper,
        [2] = props.modRearBumper,
        [3] = props.modSideSkirt,
        [4] = props.modExhaust,
        [5] = props.modFrame,
        [6] = props.modGrille,
        [7] = props.modHood,
        [8] = props.modFender,
        [9] = props.modRightFender,
        [10] = props.modRoof,
        [11] = props.modEngine,
        [12] = props.modBrakes,
        [13] = props.modTransmission,
        [14] = props.modHorns,
        [15] = props.modSuspension,
        [16] = props.modArmor,
        [23] = props.modFrontWheels,
        [24] = props.modBackWheels,
        [25] = props.modPlateHolder,
        [26] = props.modVanityPlate,
        [27] = props.modTrimA,
        [28] = props.modOrnaments,
        [29] = props.modDashboard,
        [30] = props.modDial,
        [31] = props.modDoorSpeaker,
        [32] = props.modSeats,
        [33] = props.modSteeringWheel,
        [34] = props.modShifterLeavers,
        [35] = props.modAPlate,
        [36] = props.modSpeakers,
        [37] = props.modTrunk,
        [38] = props.modHydrolic,
        [39] = props.modEngineBlock,
        [40] = props.modAirFilter,
        [41] = props.modStruts,
        [42] = props.modArchCover,
        [43] = props.modAerials,
        [44] = props.modTrimB,
        [45] = props.modTank,
        [46] = props.modWindows,
        [48] = props.modLivery,
    }

    for modType, modVal in pairs(modMap) do
        if modVal ~= nil then
            local customTires = (modType == 23 and props.modCustomTiresF) or (modType == 24 and props.modCustomTiresR) or false
            SetVehicleMod(vehicle, modType, modVal, customTires)
        end
    end

    if props.modTurbo ~= nil then ToggleVehicleMod(vehicle, 18, props.modTurbo) end
    if props.modSmokeEnabled ~= nil then ToggleVehicleMod(vehicle, 20, props.modSmokeEnabled) end
    if props.modXenon ~= nil then ToggleVehicleMod(vehicle, 22, props.modXenon) end
    if props.livery ~= nil then SetVehicleLivery(vehicle, props.livery) end

    if props.extras then
        for id, state in pairs(props.extras) do
            local num = tonumber(id)
            if num and DoesExtraExist(vehicle, num) then
                SetVehicleExtra(vehicle, num, state and 0 or 1)
            end
        end
    end

    if props.doorsBroken then
        for i = 0, 5 do
            if props.doorsBroken[i + 1] then SetVehicleDoorBroken(vehicle, i, true) end
        end
    end

    if props.windowsBroken then
        for i = 0, 7 do
            if props.windowsBroken[i + 1] then SmashVehicleWindow(vehicle, i) end
        end
    end

    if props.tyresBurst then
        for i = 0, 7 do
            if props.tyresBurst[i + 1] then SetVehicleTyreBurst(vehicle, i, true, 1000.0) end
        end
    end

    return true
end

return Props
