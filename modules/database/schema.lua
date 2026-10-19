--[[
    Kairo.Database — Per-Framework Database Schema Mapping.
    Maps tables and columns for vehicles and players between ESX, QB-Core, Qbox, and Standalone.
]]
local fwName = Kairo.Env.framework.name

local schemas = {
    qb = {
        vehicles = {
            table = 'player_vehicles',
            owner = 'citizenid',
            plate = 'plate',
            props = 'mods',
            stored = 'state',
            garage = 'garage',
            fuel = 'fuel',
            engine = 'engine',
            body = 'body',
        },
        players = {
            table = 'players',
            identifier = 'citizenid',
            money = 'money',
            charinfo = 'charinfo',
            job = 'job',
        },
    },
    qbox = {
        vehicles = {
            table = 'player_vehicles',
            owner = 'citizenid',
            plate = 'plate',
            props = 'mods',
            stored = 'state',
            garage = 'garage',
            fuel = 'fuel',
            engine = 'engine',
            body = 'body',
        },
        players = {
            table = 'players',
            identifier = 'citizenid',
            money = 'money',
            charinfo = 'charinfo',
            job = 'job',
        },
    },
    esx = {
        vehicles = {
            table = 'owned_vehicles',
            owner = 'owner',
            plate = 'plate',
            props = 'vehicle',
            stored = 'stored',
            garage = 'parking',
            fuel = nil,
            engine = nil,
            body = nil,
        },
        players = {
            table = 'users',
            identifier = 'identifier',
            money = 'accounts',
            job = 'job',
            job_grade = 'job_grade',
        },
    },
    standalone = {
        vehicles = {
            table = 'kairo_vehicles',
            owner = 'owner',
            plate = 'plate',
            props = 'props',
            stored = 'stored',
            garage = 'garage',
            fuel = 'fuel',
            engine = 'engine',
            body = 'body',
        },
        players = {
            table = 'kairo_players',
            identifier = 'identifier',
            money = 'money',
            job = 'job',
        },
    },
}

local activeSchema = schemas[fwName] or schemas.standalone

return {
    Name = fwName,
    Vehicles = activeSchema.vehicles,
    Players = activeSchema.players,
}
