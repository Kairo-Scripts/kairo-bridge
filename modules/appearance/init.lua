--[[
    Kairo.Appearance — Clothing, Skin & Ped Appearance Management.
    Adapters: illenium-appearance, fivem-appearance, qb-clothing, esx_skin, standalone native GTA.
]]
local isServer = Kairo.IsServer
local appEnv = Kairo.Env.appearance or { name = 'standalone' }
local adapter = appEnv.name

local Appearance = {}

if isServer then
    function Appearance.GetAppearance(src)
        src = tonumber(src)
        if not src then return nil end

        if adapter == 'illenium' and exports['illenium-appearance'] then
            return exports['illenium-appearance']:getPlayerAppearance(src)
        elseif adapter == 'fivem-appearance' and exports['fivem-appearance'] then
            return exports['fivem-appearance']:getPlayerAppearance(src)
        end

        local p = Kairo.Framework.GetPlayer(src)
        return p and p.metadata and p.metadata.skin or nil
    end

    function Appearance.SaveAppearance(src, data)
        src = tonumber(src)
        if not src or type(data) ~= 'table' then return false end

        if adapter == 'illenium' and exports['illenium-appearance'] then
            exports['illenium-appearance']:setPlayerAppearance(src, data)
            return true
        end

        return Kairo.Framework.SetMetadata(src, 'skin', data)
    end

    return Appearance
end

-- CLIENT

---Open the clothing / appearance customization menu.
function Appearance.OpenMenu()
    if adapter == 'illenium' and exports['illenium-appearance'] then
        local config = {
            ped = true,
            headBlend = true,
            faceFeatures = true,
            headOverlays = true,
            components = true,
            props = true,
            tattoos = true,
        }
        exports['illenium-appearance']:startPlayerCustomization(function(appearance)
            if appearance then
                TriggerServerEvent('kairo:appearance:save', appearance)
            end
        end, config)
        return true
    elseif adapter == 'fivem-appearance' and exports['fivem-appearance'] then
        exports['fivem-appearance']:startPlayerCustomization(function(appearance)
            if appearance then
                TriggerServerEvent('kairo:appearance:save', appearance)
            end
        end)
        return true
    elseif adapter == 'qb' then
        TriggerEvent('qb-clothing:client:openMenu')
        return true
    elseif adapter == 'esx' then
        TriggerEvent('esx_skin:openSaveableMenu')
        return true
    end

    Kairo.UI.Notify('No clothing menu available on standalone.', 'warning')
    return false
end

---Get normalized appearance/clothing data for a ped.
---@param ped? number
---@return table|nil
function Appearance.GetAppearance(ped)
    ped = ped or PlayerPedId()
    if not DoesEntityExist(ped) then return nil end

    if (adapter == 'illenium' or adapter == 'fivem-appearance') and exports['illenium-appearance'] then
        return exports['illenium-appearance']:getPedAppearance(ped)
    elseif adapter == 'fivem-appearance' and exports['fivem-appearance'] then
        return exports['fivem-appearance']:getPedAppearance(ped)
    end

    -- Standalone native GTA components & props
    local components = {}
    for i = 0, 11 do
        components[i] = {
            component = i,
            drawable = GetPedDrawableVariation(ped, i),
            texture = GetPedTextureVariation(ped, i),
        }
    end

    local props = {}
    for i = 0, 7 do
        props[i] = {
            prop = i,
            drawable = GetPedPropIndex(ped, i),
            texture = GetPedPropTextureIndex(ped, i),
        }
    end

    return {
        model = GetEntityModel(ped),
        components = components,
        props = props,
    }
end

---Apply appearance/clothing data to a ped.
---@param ped? number
---@param data table
---@return boolean
function Appearance.SetAppearance(ped, data)
    ped = ped or PlayerPedId()
    if not DoesEntityExist(ped) or type(data) ~= 'table' then return false end

    if (adapter == 'illenium' or adapter == 'fivem-appearance') and exports['illenium-appearance'] then
        exports['illenium-appearance']:setPedAppearance(ped, data)
        return true
    elseif adapter == 'fivem-appearance' and exports['fivem-appearance'] then
        exports['fivem-appearance']:setPedAppearance(ped, data)
        return true
    elseif adapter == 'esx' and data.skin then
        TriggerEvent('skinchanger:loadSkin', data.skin)
        return true
    end

    -- Standalone native component apply
    if data.components then
        for _, c in pairs(data.components) do
            if c.component and c.drawable then
                SetPedComponentVariation(ped, c.component, c.drawable, c.texture or 0, 0)
            end
        end
    end
    if data.props then
        for _, p in pairs(data.props) do
            if p.prop and p.drawable then
                if p.drawable == -1 then
                    ClearPedProp(ped, p.prop)
                else
                    SetPedPropIndex(ped, p.prop, p.drawable, p.texture or 0, true)
                end
            end
        end
    end

    return true
end

---Reload and re-apply the player's saved appearance.
function Appearance.ReloadSkin()
    if adapter == 'illenium' and exports['illenium-appearance'] then
        TriggerEvent('illenium-appearance:client:reloadSkin')
        return true
    elseif adapter == 'fivem-appearance' and exports['fivem-appearance'] then
        TriggerEvent('fivem-appearance:client:reloadSkin')
        return true
    elseif adapter == 'qb' then
        TriggerEvent('qb-clothing:client:loadPlayerClothing')
        return true
    elseif adapter == 'esx' then
        ESX = exports['es_extended']:getSharedObject()
        if ESX and ESX.TriggerServerCallback then
            ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin)
                TriggerEvent('skinchanger:loadSkin', skin)
            end)
        end
        return true
    end

    return false
end

return Appearance
