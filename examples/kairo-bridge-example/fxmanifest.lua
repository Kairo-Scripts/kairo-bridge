fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'kairo-bridge-example'
description 'Exercises Kairo.Framework and Kairo.Inventory'

dependency 'kairo-bridge'
shared_script '@kairo-bridge/init.lua'

server_script 'server.lua'
client_script 'client.lua'
