-- luacheck configuration for kairo-bridge

std = 'lua54'
max_line_length = 200

-- Ignore FiveM runtime dynamic globals and non-critical warnings
ignore = {
    '111', -- Setting non-standard global variable (framework bridges)
    '113', -- Accessing undefined variable (FiveM runtime provides all natives dynamically)
    '211', -- Unused variable
    '212', -- Unused argument
    '213', -- Unused loop variable
    '231', -- Variable is set but never accessed
    '311', -- Value assigned to variable is unused
    '631', -- Line is too long
}


-- Global variables provided by CFX runtime and FiveM native engine
globals = {
    -- Bridge namespace
    'Kairo',
    'Config',

    -- CFX / Citizen core
    'Citizen',
    'exports',
    'vector2',
    'vector3',
    'vector4',
    'quat',
    'GlobalState',
    'LocalPlayer',
    'Player',
    'Entity',

    -- Event & thread management
    'RegisterNetEvent',
    'RegisterServerEvent',
    'RegisterNUICallback',
    'AddEventHandler',
    'RemoveEventHandler',
    'TriggerEvent',
    'TriggerClientEvent',
    'TriggerServerEvent',
    'CreateThread',
    'CreateThreadNow',
    'Wait',
    'SetTimeout',

    -- Resource environment
    'GetCurrentResourceName',
    'GetResourceState',
    'GetResourceMetadata',
    'LoadResourceFile',
    'SaveResourceFile',
    'IsDuplicityVersion',
    'json',
    'performHttpRequest',

    -- NUI
    'SendNUIMessage',
    'SetNuiFocus',
    'SetNuiFocusKeepInput',

    -- FiveM Native functions
    'PlayerPedId',
    'GetEntityCoords',
    'GetEntityHeading',
    'SetEntityCoords',
    'SetEntityHeading',
    'DoesEntityExist',
    'DeleteEntity',
    'GetVehiclePedIsIn',
    'GetVehicleNumberPlateText',
    'SetVehicleNumberPlateText',
    'SetVehicleDoorsLocked',
    'GetVehicleDoorLockStatus',
    'NetworkGetEntityFromNetworkId',
    'NetworkGetNetworkIdFromEntity',
    'NetworkGetEntityIsNetworked',
    'TaskPlayAnim',
    'ClearPedTasks',
    'ClearPedTasksImmediately',
    'RequestAnimDict',
    'HasAnimDictLoaded',
    'AttachEntityToEntity',
    'DeleteObject',
    'AddBlipForCoord',
    'SetBlipSprite',
    'SetBlipColour',
    'SetBlipScale',
    'SetBlipAsShortRange',
    'SetBlipFlashes',
    'BeginTextCommandSetBlipName',
    'AddTextComponentSubstringPlayerName',
    'EndTextCommandSetBlipName',
    'RemoveBlip',
    'GetEntityHealth',
    'SetEntityHealth',
    'SetEntityInvincible',
    'NetworkResurrectLocalPlayer',
    'IsPedDeadOrDying',
    'IsPedFatallyInjured',
    'GetGameTimer',
    'GetPedPropIndex',
    'GetPedPropTextureIndex',
    'SetPedPropIndex',
    'ClearPedProp',
    'GetPedDrawableVariation',
    'GetPedTextureVariation',
    'SetPedComponentVariation',
    'GetNumberOfPedDrawableVariations',
    'GetNumberOfPedTextureVariations',
    'GetNumberOfPedPropDrawableVariations',
    'GetNumberOfPedPropTextureVariations',
}

files['modules/database/**'] = {
    globals = {
        'MySQL',
    }
}
