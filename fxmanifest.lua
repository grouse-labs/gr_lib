fx_version 'cerulean'
game 'gta5'

author 'Grouse Labs'
description 'A library of portable FiveM lua modules.'
version '1.1.0'
url 'https://github.com/grouse-labs/gr_lib'

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