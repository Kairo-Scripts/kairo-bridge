--[[
    Kairo.Vehicle — Vehicle Plate Generation & Verification.
]]
local A = {}

local CHARS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
local DIGITS = '0123456789'

local function randomChar()
    local idx = math.random(1, #CHARS)
    return CHARS:sub(idx, idx)
end

local function randomDigit()
    local idx = math.random(1, #DIGITS)
    return DIGITS:sub(idx, idx)
end

---Check if a license plate is already registered to a player.
---@param plate string
---@return boolean
function A.IsPlateTaken(plate)
    if type(plate) ~= 'string' or plate == '' then return false end
    plate = plate:match('^%s*(.-)%s*$'):upper()

    local ok, db = pcall(function() return Kairo.DB end)
    if ok and db and db.IsPlateTaken then
        return db.IsPlateTaken(plate) == true
    end

    return false
end

---Generate a unique, formatted license plate.
---@param pattern? string e.g., '11AAA111', 'AAA 111'
---@return string
function A.GeneratePlate(pattern)
    pattern = pattern or Kairo.Config.PlateFormat or '11AAA111'

    for _ = 1, 30 do
        local result = {}
        for i = 1, #pattern do
            local c = pattern:sub(i, i)
            if c == '1' then
                result[#result + 1] = randomDigit()
            elseif c == 'A' or c == 'a' then
                result[#result + 1] = randomChar()
            else
                result[#result + 1] = c
            end
        end

        local plate = table.concat(result):upper()
        if #plate > 8 then plate = plate:sub(1, 8) end

        if not A.IsPlateTaken(plate) then
            return plate
        end
    end

    -- Fallback in case of extreme collision
    return ('KRO' .. math.random(10000, 99999)):sub(1, 8)
end

return A
