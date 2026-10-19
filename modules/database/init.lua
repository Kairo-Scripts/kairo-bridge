--[[
    Kairo.Database (Kairo.DB) — Server-side database wrapper with per-framework schema mapping.
    Wraps oxmysql safely and provides high-level queries for player vehicles and accounts.
]]
local Log = Kairo.Log
local DB = {}

if not Kairo.IsServer then
    Log.warnOnce('db-client', 'Kairo.Database is a server-only module; client calls are no-ops.')
    return DB
end

local schema = Kairo.Require('modules/database/schema.lua')
DB.Schema = schema

---Check if the database resource (oxmysql) is started and responsive.
---@return boolean
function DB.Ready()
    local s = GetResourceState('oxmysql')
    return s == 'started'
end

-- =============================================================================
-- Core oxmysql Safe Wrappers
-- =============================================================================

function DB.Query(query, params)
    if not DB.Ready() then
        Log.warnOnce('db-not-ready', 'oxmysql is not running; Database queries cannot execute.')
        return {}
    end
    local ok, res = pcall(function()
        if exports.oxmysql.query_async then
            return exports.oxmysql:query_async(query, params or {})
        else
            return exports.oxmysql:query(query, params or {})
        end
    end)
    if not ok then
        Log.error('DB.Query failed: %s | Query: %s', tostring(res), tostring(query))
        return {}
    end
    return res or {}
end

function DB.Single(query, params)
    if not DB.Ready() then return nil end
    local ok, res = pcall(function()
        if exports.oxmysql.single_async then
            return exports.oxmysql:single_async(query, params or {})
        else
            return exports.oxmysql:single(query, params or {})
        end
    end)
    if not ok then
        Log.error('DB.Single failed: %s | Query: %s', tostring(res), tostring(query))
        return nil
    end
    return res
end

function DB.Scalar(query, params)
    if not DB.Ready() then return nil end
    local ok, res = pcall(function()
        if exports.oxmysql.scalar_async then
            return exports.oxmysql:scalar_async(query, params or {})
        else
            return exports.oxmysql:scalar(query, params or {})
        end
    end)
    if not ok then
        Log.error('DB.Scalar failed: %s | Query: %s', tostring(res), tostring(query))
        return nil
    end
    return res
end

function DB.Insert(query, params)
    if not DB.Ready() then return nil end
    local ok, res = pcall(function()
        if exports.oxmysql.insert_async then
            return exports.oxmysql:insert_async(query, params or {})
        else
            return exports.oxmysql:insert(query, params or {})
        end
    end)
    if not ok then
        Log.error('DB.Insert failed: %s | Query: %s', tostring(res), tostring(query))
        return nil
    end
    return res
end

function DB.Update(query, params)
    if not DB.Ready() then return 0 end
    local ok, res = pcall(function()
        if exports.oxmysql.update_async then
            return exports.oxmysql:update_async(query, params or {})
        else
            return exports.oxmysql:update(query, params or {})
        end
    end)
    if not ok then
        Log.error('DB.Update failed: %s | Query: %s', tostring(res), tostring(query))
        return 0
    end
    return res or 0
end

function DB.Transaction(queries, params)
    if not DB.Ready() then return false end
    local ok, res = pcall(function()
        if exports.oxmysql.transaction_async then
            return exports.oxmysql:transaction_async(queries, params)
        else
            return exports.oxmysql:transaction(queries, params)
        end
    end)
    if not ok then
        Log.error('DB.Transaction failed: %s', tostring(res))
        return false
    end
    return res == true
end

-- =============================================================================
-- Schema-Aware Normalized Vehicle Queries
-- =============================================================================

local function parseProps(raw)
    if type(raw) == 'table' then return raw end
    if type(raw) == 'string' and raw ~= '' then
        local ok, data = pcall(json.decode, raw)
        if ok and type(data) == 'table' then return data end
    end
    return {}
end

---Get all vehicles owned by an identifier across any framework schema.
---@param identifier string Player citizenid or license identifier
---@return table Array of normalized vehicle objects
function DB.GetPlayerVehicles(identifier)
    if type(identifier) ~= 'string' or identifier == '' then return {} end
    local vMap = schema.Vehicles
    local sql = ('SELECT * FROM `%s` WHERE `%s` = ?'):format(vMap.table, vMap.owner)
    local rows = DB.Query(sql, { identifier })

    local out = {}
    for _, row in ipairs(rows or {}) do
        local rawProps = row[vMap.props]
        local props = parseProps(rawProps)
        out[#out + 1] = {
            plate = row[vMap.plate] or props.plate,
            model = props.model,
            props = props,
            stored = (row[vMap.stored] == 1 or row[vMap.stored] == true),
            garage = row[vMap.garage] or 'pillbox',
            owner = row[vMap.owner],
        }
    end
    return out
end

---Get a single vehicle by plate across any framework schema.
---@param plate string
---@return table|nil
function DB.GetVehicleByPlate(plate)
    if type(plate) ~= 'string' or plate == '' then return nil end
    plate = plate:match('^%s*(.-)%s*$'):upper()
    local vMap = schema.Vehicles
    local sql = ('SELECT * FROM `%s` WHERE `%s` = ? LIMIT 1'):format(vMap.table, vMap.plate)
    local row = DB.Single(sql, { plate })
    if not row then return nil end

    local props = parseProps(row[vMap.props])
    return {
        plate = row[vMap.plate] or props.plate,
        model = props.model,
        props = props,
        stored = (row[vMap.stored] == 1 or row[vMap.stored] == true),
        garage = row[vMap.garage] or 'pillbox',
        owner = row[vMap.owner],
    }
end

---Save updated vehicle properties to the database for a plate.
---@param plate string
---@param props table
---@return boolean
function DB.SaveVehicleProps(plate, props)
    if type(plate) ~= 'string' or type(props) ~= 'table' then return false end
    plate = plate:match('^%s*(.-)%s*$'):upper()
    local vMap = schema.Vehicles
    local encoded = json.encode(props)
    local sql = ('UPDATE `%s` SET `%s` = ? WHERE `%s` = ?'):format(vMap.table, vMap.props, vMap.plate)
    local affected = DB.Update(sql, { encoded, plate })
    return affected > 0
end

---Update vehicle stored state and garage location.
---@param plate string
---@param stored boolean|number
---@param garage? string
---@return boolean
function DB.SetVehicleStored(plate, stored, garage)
    if type(plate) ~= 'string' then return false end
    plate = plate:match('^%s*(.-)%s*$'):upper()
    local vMap = schema.Vehicles
    local stateVal = (stored == true or stored == 1) and 1 or 0
    garage = garage or 'pillbox'

    local sql = ('UPDATE `%s` SET `%s` = ?, `%s` = ? WHERE `%s` = ?'):format(vMap.table, vMap.stored, vMap.garage, vMap.plate)
    local affected = DB.Update(sql, { stateVal, garage, plate })
    return affected > 0
end

---Check if a license plate exists in the player vehicles table.
---@param plate string
---@return boolean
function DB.IsPlateTaken(plate)
    if type(plate) ~= 'string' or plate == '' then return false end
    plate = plate:match('^%s*(.-)%s*$'):upper()
    local vMap = schema.Vehicles
    local sql = ('SELECT 1 FROM `%s` WHERE `%s` = ? LIMIT 1'):format(vMap.table, vMap.plate)
    local found = DB.Scalar(sql, { plate })
    return found ~= nil
end

return DB
