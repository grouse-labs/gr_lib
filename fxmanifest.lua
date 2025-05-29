fx_version 'cerulean'
game 'gta5'

author ''
description ''
version '0'
url ''

shared_script 'exports/init.lua'
server_script 'exports/**/server.lua'
client_script 'exports/**/client.lua'

files {
  'init.lua',
  'src/**/shared.lua',
  'src/**/client.lua',
  'src/enum/enums/*.lua',
  -- 'src/**/**/shared.lua',
  -- 'src/**/**/client.lua'
}

lua54 'yes'