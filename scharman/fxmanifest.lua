fx_version 'cerulean'
game 'gta5'

author 'ESX Legacy (Modifié)'
description 'Script PED Scharman avec Interface Tablette + Course Poursuite 1v1 V2.0.1 CORRIGÉ'
version '2.0.1'
lua54 'yes'

shared_scripts {
    '@es_extended/imports.lua',
    'config/config.lua',
    'config/course_poursuite.lua'
}

client_scripts {
    'client/main.lua',
    'client/ped.lua',
    'client/nui.lua',
    'client/course_poursuite.lua'
}

server_scripts {
    'server/main.lua',
    'server/version.lua',
    'server/course_poursuite.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/css/style.css',
    'html/js/script.js'
}

dependencies {
    'es_extended',
    'oxmysql'
}
