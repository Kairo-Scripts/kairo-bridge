--[[
    Kairo.Services — Unified Services Bundle.
    Combines Dispatch, Doorlock, Appearance, Phone, Ambulance & Prison modules.
]]
local Services = {}

Services.Dispatch   = Kairo.Require('modules/dispatch/init.lua')
Services.Doorlock   = Kairo.Require('modules/doorlock/init.lua')
Services.Appearance = Kairo.Require('modules/appearance/init.lua')
Services.Phone      = Kairo.Require('modules/phone/init.lua')
Services.Ambulance  = Kairo.Require('modules/services/ambulance.lua')
Services.Prison     = Kairo.Require('modules/services/prison.lua')

return Services
