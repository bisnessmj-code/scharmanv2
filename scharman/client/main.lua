-- ███████╗ ██████╗██╗  ██╗ █████╗ ██████╗ ███╗   ███╗ █████╗ ███╗   ██╗
-- ██╔════╝██╔════╝██║  ██║██╔══██╗██╔══██╗████╗ ████║██╔══██╗████╗  ██║
-- ███████╗██║     ███████║███████║██████╔╝██╔████╔██║███████║██╔██╗ ██║
-- ╚════██║██║     ██╔══██║██╔══██║██╔══██╗██║╚██╔╝██║██╔══██║██║╚██╗██║
-- ███████║╚██████╗██║  ██║██║  ██║██║  ██║██║ ╚═╝ ██║██║  ██║██║ ╚████║
-- ╚══════╝ ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝
-- CLIENT - MAIN
-- ═══════════════════════════════════════════════════════════════

ESX = exports['es_extended']:getSharedObject()

-- ═══════════════════════════════════════════════════════════════
-- INITIALISATION
-- ═══════════════════════════════════════════════════════════════

CreateThread(function()
    Config.InfoPrint('Initialisation du script client...')
    
    -- Attendre que le joueur soit complètement chargé
    while not ESX.IsPlayerLoaded() do
        Wait(100)
    end
    
    Config.SuccessPrint('Script client initialisé avec succès!')
    Config.DebugPrint('Version: 1.1.0')
    Config.DebugPrint('Initialisation des modules...')
    
    -- Les modules sont initialisés dans leurs fichiers respectifs
end)

-- ═══════════════════════════════════════════════════════════════
-- COMMANDES DE DEBUG
-- ═══════════════════════════════════════════════════════════════

if Config.Debug then
    RegisterCommand('scharman_info', function()
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local heading = GetEntityHeading(ped)
        
        print('═══════════════════════════════════════════════════════════════')
        print('Position: ' .. coords.x .. ', ' .. coords.y .. ', ' .. coords.z)
        print('Heading: ' .. heading)
        print('═══════════════════════════════════════════════════════════════')
    end, false)
    
    RegisterCommand('scharman_reload', function()
        Config.InfoPrint('Rechargement du script...')
        TriggerEvent('scharman:client:reload')
    end, false)
    
    Config.InfoPrint('Commande de debug disponible: /scharman_info')
    Config.InfoPrint('Commande de debug disponible: /scharman_reload')
end

Config.DebugPrint('Fichier client/main.lua chargé avec succès')
