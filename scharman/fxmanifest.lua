-- ███████╗ ██████╗██╗  ██╗ █████╗ ██████╗ ███╗   ███╗ █████╗ ███╗   ██╗
-- ██╔════╝██╔════╝██║  ██║██╔══██╗██╔══██╗████╗ ████║██╔══██╗████╗  ██║
-- ███████╗██║     ███████║███████║██████╔╝██╔████╔██║███████║██╔██╗ ██║
-- ╚════██║██║     ██╔══██║██╔══██║██╔══██╗██║╚██╔╝██║██╔══██║██║╚██╗██║
-- ███████║╚██████╗██║  ██║██║  ██║██║  ██║██║ ╚═╝ ██║██║  ██║██║ ╚████║
-- ╚══════╝ ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝
-- Script PED Scharman avec Interface Tablette
-- Version: 1.0.0
-- Auteur: ESX Legacy
-- Description: Script modulaire avec PED et interface NUI tablette

fx_version 'cerulean'
game 'gta5'

author 'ESX Legacy'
description 'Script PED Scharman avec Interface Tablette - Architecture Modulaire'
version '1.0.0'
lua54 'yes'

-- ═══════════════════════════════════════════════════════════════
-- SCRIPTS PARTAGÉS
-- ═══════════════════════════════════════════════════════════════
shared_scripts {
    '@es_extended/imports.lua',
    'config/*.lua'
}

-- ═══════════════════════════════════════════════════════════════
-- SCRIPTS CLIENT
-- ═══════════════════════════════════════════════════════════════
client_scripts {
    'client/main.lua',
    'client/ped.lua',
    'client/nui.lua'
}

-- ═══════════════════════════════════════════════════════════════
-- SCRIPTS SERVEUR
-- ═══════════════════════════════════════════════════════════════
server_scripts {
    'server/main.lua',
    'server/version.lua'
}

-- ═══════════════════════════════════════════════════════════════
-- INTERFACE NUI
-- ═══════════════════════════════════════════════════════════════
ui_page 'html/index.html'

files {
    'html/index.html',
    'html/css/*.css',
    'html/js/*.js',
    'html/img/*.png',
    'html/img/*.jpg'
}

-- ═══════════════════════════════════════════════════════════════
-- DÉPENDANCES
-- ═══════════════════════════════════════════════════════════════
dependencies {
    'es_extended',
    'oxmysql'
}

-- ═══════════════════════════════════════════════════════════════
-- CONFIGURATION ESCROW (si besoin)
-- ═══════════════════════════════════════════════════════════════
-- escrow_ignore {
--     'config/*.lua',
--     'README.md'
-- }
