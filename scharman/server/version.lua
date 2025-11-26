-- ███████╗ ██████╗██╗  ██╗ █████╗ ██████╗ ███╗   ███╗ █████╗ ███╗   ██╗
-- ██╔════╝██╔════╝██║  ██║██╔══██╗██╔══██╗████╗ ████║██╔══██╗████╗  ██║
-- ███████╗██║     ███████║███████║██████╔╝██╔████╔██║███████║██╔██╗ ██║
-- ╚════██║██║     ██╔══██║██╔══██║██╔══██╗██║╚██╔╝██║██╔══██║██║╚██╗██║
-- ███████║╚██████╗██║  ██║██║  ██║██║  ██║██║ ╚═╝ ██║██║  ██║██║ ╚████║
-- ╚══════╝ ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝
-- SERVER - VERSION
-- ═══════════════════════════════════════════════════════════════

local SCRIPT_NAME = 'Scharman PED'
local SCRIPT_VERSION = '1.1.0 (CORRIGÉE)'
local SCRIPT_AUTHOR = 'ESX Legacy (Modifié)'

-- ═══════════════════════════════════════════════════════════════
-- VÉRIFICATION DES DÉPENDANCES
-- ═══════════════════════════════════════════════════════════════

local function CheckDependencies()
    Config.DebugPrint('Vérification des dépendances...')
    
    -- Vérifier ESX
    if GetResourceState('es_extended') ~= 'started' then
        Config.ErrorPrint('ESX Legacy n\'est pas démarré')
        return false
    end
    
    Config.SuccessPrint('ESX détecté et chargé')
    
    -- Vérifier oxmysql
    if GetResourceState('oxmysql') ~= 'started' then
        Config.ErrorPrint('oxmysql n\'est pas démarré')
        return false
    end
    
    Config.SuccessPrint('oxmysql détecté et démarré')
    
    return true
end

-- ═══════════════════════════════════════════════════════════════
-- AFFICHAGE DU BANNER
-- ═══════════════════════════════════════════════════════════════

local function PrintBanner()
    print('^6═══════════════════════════════════════════════════════════════^7')
    print('^2Script ' .. SCRIPT_NAME .. ' démarré avec succès!^7')
    print('^6Version:^7 ' .. SCRIPT_VERSION)
    print('^6Auteur:^7 ' .. SCRIPT_AUTHOR)
    print('^6═══════════════════════════════════════════════════════════════^7')
end

-- ═══════════════════════════════════════════════════════════════
-- INITIALISATION
-- ═══════════════════════════════════════════════════════════════

CreateThread(function()
    PrintBanner()
    
    if not CheckDependencies() then
        Config.ErrorPrint('Échec de la vérification des dépendances')
        return
    end
    
    Config.SuccessPrint('Toutes les dépendances sont OK')
end)

Config.DebugPrint('Fichier server/version.lua chargé avec succès')
