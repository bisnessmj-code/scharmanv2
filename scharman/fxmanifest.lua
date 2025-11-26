-- ███████╗██╗  ██╗███╗   ███╗ █████╗ ███╗   ██╗██╗███████╗███████╗███████╗████████╗
-- ██╔════╝╚██╗██╔╝████╗ ████║██╔══██╗████╗  ██║██║██╔════╝██╔════╝██╔════╝╚══██╔══╝
-- █████╗   ╚███╔╝ ██╔████╔██║███████║██╔██╗ ██║██║█████╗  █████╗  ███████╗   ██║   
-- ██╔══╝   ██╔██╗ ██║╚██╔╝██║██╔══██║██║╚██╗██║██║██╔══╝  ██╔══╝  ╚════██║   ██║   
-- ██║     ██╔╝ ██╗██║ ╚═╝ ██║██║  ██║██║ ╚████║██║██║     ███████╗███████║   ██║   
-- ╚═╝     ╚═╝  ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝╚═╝     ╚══════╝╚══════╝   ╚═╝   

fx_version 'cerulean'
game 'gta5'

author 'ESX Legacy (Modifié)'
description 'Script PED Scharman avec Interface Tablette + Course Poursuite 1v1 V2.0'
version '2.0.0'
lua54 'yes'

-- ═══════════════════════════════════════════════════════════════
-- SCRIPTS PARTAGÉS
-- ═══════════════════════════════════════════════════════════════
shared_scripts {
    '@es_extended/imports.lua',
    'config/config.lua',
    'config/course_poursuite.lua'
}

-- ═══════════════════════════════════════════════════════════════
-- SCRIPTS CLIENT
-- ═══════════════════════════════════════════════════════════════
client_scripts {
    'client/main.lua',
    'client/ped.lua',
    'client/nui.lua',
    'client/course_poursuite.lua' -- ✅ V2.0 AMÉLIORÉ
}

-- ═══════════════════════════════════════════════════════════════
-- SCRIPTS SERVEUR
-- ═══════════════════════════════════════════════════════════════
server_scripts {
    'server/main.lua',
    'server/version.lua',
    'server/course_poursuite.lua'
}

-- ═══════════════════════════════════════════════════════════════
-- INTERFACE NUI
-- ═══════════════════════════════════════════════════════════════
ui_page 'html/index.html'

files {
    'html/index.html',      -- ✅ V2.0 NOUVEAU (Décompte + Blocage)
    'html/css/style.css',   -- ✅ V2.0 AMÉLIORÉ (Animations)
    'html/js/script.js'     -- ✅ V2.0 AMÉLIORÉ (Logique)
}

-- ═══════════════════════════════════════════════════════════════
-- DÉPENDANCES
-- ═══════════════════════════════════════════════════════════════
dependencies {
    'es_extended',
    'oxmysql'
}

-- ═══════════════════════════════════════════════════════════════
-- CHANGELOG V2.0
-- ═══════════════════════════════════════════════════════════════
-- [AJOUTÉ] Décompte 3-2-1-GO avec animations
-- [AJOUTÉ] Interface de blocage véhicule avec timer
-- [AJOUTÉ] Zone de guerre immédiate au spawn
-- [AJOUTÉ] Colonne de lumière rouge visible
-- [AJOUTÉ] Blips de zone sur la map
-- [AMÉLIORÉ] Nettoyage complet des entités
-- [AMÉLIORÉ] Gestion des threads optimisée
-- [AMÉLIORÉ] Système de suppression des véhicules
-- [AMÉLIORÉ] Reset des variables à la fin
-- [CORRIGÉ] Problèmes de spawn véhicule
-- [CORRIGÉ] Synchronisation des buckets
-- ═══════════════════════════════════════════════════════════════
