fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'kairo-bridge'
author 'Kairo'
description 'Compatibility layer for ESX, QB-Core, Qbox and standalone'
version '1.0.0'

ui_page 'html/index.html'

shared_scripts { 'init.lua' }
server_scripts {
    'server/main.lua',
    'server/inventory.lua',
    'server/heartbeat.lua',
    'server/standalone.lua',
    'server/ui.lua',
    'server/vehicle.lua',
    'server/services.lua',
}
client_scripts {
    'client/main.lua',
    'client/nui.lua',
    'client/vehicle.lua',
}

-- Everything the consumer-side loader reads must be listed here so clients can load it.
files {
    'init.lua',
    'config.lua',
    'core/*.lua',
    'locales/*.lua',
    'modules/**/*.lua',
    'types/*.lua',
    'html/**/*',
}
