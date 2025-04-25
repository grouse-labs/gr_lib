fx_version 'cerulean'
game 'gta5'

author ''
description ''
version '0'
url ''

server_script 'server/main.lua'

files {
  'init.lua',
  'src/**/shared.lua',
  'src/**/client.lua',
  'src/enum/enums/*.lua',
  -- 'src/**/**/shared.lua',
  -- 'src/**/**/client.lua'
}

lua54 'yes'